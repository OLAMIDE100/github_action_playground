import os
from loader import call_name,call_age


name = os.getenv("name")
age =  os.getenv("age")

def main(request):
    
    return f'{call_name(name)} and {call_age(age)}'
