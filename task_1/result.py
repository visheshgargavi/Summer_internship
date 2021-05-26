import joblib
num = int(input('Enter year of experience:'))
model = joblib.load('marks.pk1')
print(model.predict[[num]])
