import collections
import string

# Read the file and process text
def most_frequent_word(filename):
    with open(filename, 'r', encoding='utf-8') as file:
        text = file.read().lower()  # Convert to lowercase
        text = text.translate(str.maketrans('', '', string.punctuation))  # Remove punctuation
        words = text.split()
    
    # Count occurrences of each word
    word_counts = collections.Counter(words)
    most_common_word, max_count = word_counts.most_common(1)[0]
    
    return most_common_word, max_count

# Usage
filename = "q1_words.txt"
most_common_word, count = most_frequent_word(filename)
print(f"Most frequent word: '{most_common_word}' (occurs {count} times)")
