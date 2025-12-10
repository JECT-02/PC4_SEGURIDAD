import re
from collections import Counter
import sys

# Force UTF-8 output for console
sys.stdout.reconfigure(encoding='utf-8')

def get_factors(n):
    factors = set()
    for i in range(2, int(n**0.5) + 1):
        if n % i == 0:
            factors.add(i)
            factors.add(n // i)
    return factors

def kasiski_examination(ciphertext, min_seq_len=3):
    seq_map = {}
    for i in range(len(ciphertext) - min_seq_len):
        seq = ciphertext[i:i+min_seq_len]
        if seq not in seq_map:
            seq_map[seq] = []
        seq_map[seq].append(i)
    
    distances = []
    for seq, positions in seq_map.items():
        if len(positions) > 1:
            for i in range(len(positions) - 1):
                distances.append(positions[i+1] - positions[i])
    
    all_factors = Counter()
    for d in distances:
        for f in get_factors(d):
            if 3 <= f <= 20: 
                all_factors[f] += 1
                
    return all_factors.most_common()

def solve_key(ciphertext, key_len):
    # SPANISH letter frequencies (approximate)
    spanish_freqs = {
        'A': 0.1253, 'B': 0.0142, 'C': 0.0468, 'D': 0.0586, 'E': 0.1368, 'F': 0.0069,
        'G': 0.0101, 'H': 0.0070, 'I': 0.0625, 'J': 0.0044, 'K': 0.0002, 'L': 0.0497,
        'M': 0.0315, 'N': 0.0671, 'O': 0.0868, 'P': 0.0251, 'Q': 0.0088, 'R': 0.0687,
        'S': 0.0798, 'T': 0.0463, 'U': 0.0393, 'V': 0.0090, 'W': 0.0001, 'X': 0.0022,
        'Y': 0.0090, 'Z': 0.0052
    }
    # Normalize
    total = sum(spanish_freqs.values())
    for k in spanish_freqs:
        spanish_freqs[k] /= total
    
    key = []
    for i in range(key_len):
        coset = ciphertext[i::key_len]
        coset_len = len(coset)
        cnt = Counter(coset)
        
        best_chi = float('inf')
        best_shift = 0
        
        for shift in range(26):
            chi_sq = 0
            for char_val in range(26):
                char = chr(char_val + ord('A'))
                shifted_char = chr(((char_val + shift) % 26) + ord('A'))
                observed = cnt[shifted_char]
                expected = spanish_freqs[char] * coset_len
                # Simple Chi-Squared
                chi_sq += ((observed - expected) ** 2) / (expected + 1e-9)
            
            if chi_sq < best_chi:
                best_chi = chi_sq
                best_shift = shift
        
        key.append(chr(best_shift + ord('A')))
    
    return "".join(key)

def decrypt(ciphertext, key):
    plaintext = []
    key_len = len(key)
    for i, char in enumerate(ciphertext):
        if not char.isalpha():
            plaintext.append(char)
            continue
        shift = ord(key[i % key_len]) - ord('A')
        plain_val = (ord(char) - ord('A') - shift) % 26
        plaintext.append(chr(plain_val + ord('A')))
    return "".join(plaintext)

# Main execution
with open("ciphertext.txt", "r") as f:
    text = f.read().replace('\n', '').replace(' ', '').upper()

factors = kasiski_examination(text)
print("Factors:", factors[:5])

if not factors:
    print("No factors found. Defaulting to guess?")
    # Fallback to a range
    likely_lens = [4, 5, 6, 7, 8, 9]
else:
    likely_lens = [f[0] for f in factors[:3]]

with open("results.txt", "w", encoding='utf-8') as res:
    for L in likely_lens:
        key = solve_key(text, L)
        pt = decrypt(text, key)
        print(f"Len {L} Key: {key}")
        print(f"Sample: {pt[:60]}")
        res.write(f"Len: {L}\nKey: {key}\nPlaintext: {pt}\n\n")

print("Done. Check results.txt")
