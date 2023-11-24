import os


name = os.getenv("name")

def main(request):
    
    return f'name of function is {name}'
