greeting: public(String[100])

@external
def __init__():
    self.greeting = "Hello World!"

@external
def greet() -> String[100]:
    return self.greeting