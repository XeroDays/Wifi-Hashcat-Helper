#!/usr/bin/env python3
"""
Generate Hashcat rules for appending space + numbers 0-9999.
Format: $ $X for single digits, $ $X$Y for two digits, etc.
Each digit must be separated by $ for Hashcat to parse correctly.
"""

rules = []

# Single digits: 0-9
for i in range(10):
    rules.append(f'$ ${i}')

# Two digits: 00-99
for i in range(100):
    tens = i // 10
    ones = i % 10
    rules.append(f'$ ${tens}${ones}')

# Three digits: 000-999
for i in range(1000):
    hundreds = i // 100
    tens = (i // 10) % 10
    ones = i % 10
    rules.append(f'$ ${hundreds}${tens}${ones}')

# Four digits: 0000-9999
for i in range(10000):
    thousands = i // 1000
    hundreds = (i // 100) % 10
    tens = (i // 10) % 10
    ones = i % 10
    rules.append(f'$ ${thousands}${hundreds}${tens}${ones}')

# Write to file
output_file = 'space_rules_fixed.txt'
with open(output_file, 'w', encoding='utf-8') as f:
    for rule in rules:
        f.write(rule + '\n')

print(f"Generated {len(rules)} rules and saved to {output_file}")
print(f"First few rules: {rules[:5]}")
print(f"Last few rules: {rules[-5:]}")
