import os
import pandas as pd
from pytube import extract
import re
import string
import pickle
import nltk
import nltk.sentiment.util
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer 

from sklearn.metrics import accuracy_score

from keras.preprocessing.text import Tokenizer
from keras.preprocessing.sequence import pad_sequences
from tensorflow import keras

import xgboost

sw = stopwords.words('english')
lemmatizer = WordNetLemmatizer()

## get YouTube ID
def getID(url):
    print("Getting YouTube ID...")
    return extract.video_id(url)

## download comments
def downloadComments(videoID):
    print("Downloading Comments...")
    os.system("youtube-comment-downloader --youtubeid=" + videoID + " --output Comments/" + videoID + ".json")

# function to clean comments
def clean_text(text):
    
    # remove symbols and Emojis
    text = text.lower()
    text = re.sub('@', '', text)
    text = re.sub('\[.*?\]', '', text)
    text = re.sub('https?://\S+|www\.\S+', '', text)
    text = re.sub('<.*?>+', '', text)
    text = re.sub('[%s]' % re.escape(string.punctuation), '', text)
    text = re.sub('\n', '', text)
    text = re.sub('\w*\d\w*', '', text)
    text = re.sub(r"[^a-zA-Z ]+", "", text)
    
    # tokenize the data
    text = nltk.word_tokenize(text)
    
    # lemmatize
    text = [lemmatizer.lemmatize(t) for t in text]
    text = [lemmatizer.lemmatize(t, 'v') for t in text]
    
    # mark Negation
    tokens_neg_marked = nltk.sentiment.util.mark_negation(text)
    
    # remove stopwords
    text = [t for t in tokens_neg_marked
             if t.replace("_NEG", "").isalnum() and
             t.replace("_NEG", "") not in sw]
    
    return text

def getSentenceTrain():
    # open sentences_train file
    sentences_train_f = open('../Deep learning/pickles/sentences_train.pickle', "rb")
    sentences_train = pickle.load(sentences_train_f)
    sentences_train_f.close()
    return sentences_train

# open pickle file
# randFor_71_f = open('../Shallow machine learning/pickles/randFor_71.pickle', "rb")
# randFor_train = pickle.load(randFor_71_f)
# randFor_71_f.close()

SGD_74_f = open('../Shallow machine learning/pickles/SGD_74.pickle', "rb")
SGD_train = pickle.load(SGD_74_f)
SGD_74_f.close()

# XGB_74_f = open('../Shallow machine learning/pickles/XGB_74.pickle', "rb")
# XGB_train = pickle.load(XGB_74_f)
# XGB_74_f.close()

logreg_79_f = open('../Shallow machine learning/pickles/logreg_79.pickle', "rb")
logreg_train = pickle.load(logreg_79_f)
logreg_79_f.close()

# get saved CNN model
model = keras.models.load_model("../Deep learning/CNN_82")

def vote(test_point, _test):
    print("Voting on video effectivess...\n")
    pos_weighting = []
    result = ''
    confidence = 0
    algos_score = 0
    
    algorithms = [
            #  {'name': 'Random Forest', 'accuracy': 0.71*100, 'trained': randFor_train},
             {'name': 'SGD', 'accuracy': 0.74*100, 'trained': SGD_train},
            #  {'name': 'XGBoost', 'accuracy':  0.74*100, 'trained': XGB_train},
             {'name': 'Logistic Regression', 'accuracy': 0.79*100, 'trained': logreg_train},
             {'name': 'CNN', 'accuracy': 0.82*100, 'trained': model}
        ]
    
    for algo in algorithms:
        weight = algo['accuracy']
        algos_score += weight
        if algo['name'] == "CNN":
            pred = algo['trained'].predict(_test)
            if pred[0][0] > 0.5:
                pos_weighting.append(weight)
            print("CNN voted for: effective" if pred[0][0]>0.5 else "CNN voted for: ineffective")
        else:
            pred = algo['trained'].predict(test_point)
            if pred == 'pos':
                pos_weighting.append(weight)
            print(algo['name'] + " voted for: effective" if pred=='pos' else algo['name'] + " voted for: ineffective")

    pos_result = sum(pos_weighting)/algos_score
    if pos_result < 0.5:
        result = 'ineffective'
        confidence = 1-pos_result
    else:
        result = 'effective'
        confidence = pos_result
        
    print("\nThis video is \033[1m" + result + "\033[0m with a confidence of \033[1m" + str(round(confidence*100,2)) + "% \033[0m")

def quantizeEffectiveness(url):
    # 1. Get YouTube ID
    videoID = getID(url)
    
    # 2. Download comments
    downloadComments(videoID)
    
    # 3. Clean comments
    print("Cleaning Comments...")
    df = pd.read_json('Comments/'+ videoID + '.json', lines=True)
    df['text'] = df['text'].apply(lambda x: clean_text(x))

    all_words = []        
    for i in range(len(df)):
        all_words = all_words + df['text'][i]

    df_csv = pd.DataFrame(all_words)
    df_csv.to_csv('Processed Comments/' + videoID + '_all_words.csv', index=False)
    
    # 4. Create test dataframe
    test = pd.DataFrame([[videoID]], columns=['VideoID'])
    
    # 5. Get documents (pre-processd comments)
    test_documents = []
    comment = pd.read_csv("Processed Comments/" + videoID + "_all_words.csv")
    test_documents.append(list(comment["0"]))
    test['cleaned'] = test_documents
    test['cleaned_string'] = [' '.join(map(str, l)) for l in test['cleaned']]
    
    # 6. Get ML test point
    test_point = test.cleaned_string
    test_sentence = test['cleaned_string'].values
    
    # 7. Get trained sentences
    sentences_train = getSentenceTrain()
    
    # 8. Tokenize the data
    print("Tokenizing the data...")
    tokenizer = Tokenizer(num_words=5000)
    tokenizer.fit_on_texts(sentences_train)
    
    # 9. Get DL test point
    _test = pad_sequences(tokenizer.texts_to_sequences(test_sentence), padding='post', maxlen=100)
    
    # 10. Vote on video effectiveness
    vote(test_point,_test)


if __name__ == '__main__':
    quantizeEffectiveness("https://www.youtube.com/watch?v=3p51wKUuwOU")
