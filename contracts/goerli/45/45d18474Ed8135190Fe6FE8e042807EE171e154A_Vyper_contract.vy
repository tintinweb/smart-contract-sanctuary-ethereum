# @version 0.3.0

# TODO: Consider how many ITERATIONS are needed. GAS vs precision.
# TODO: Add break condition based on tolerance. (_sqrt)
# TODO: Add necessary reverts (eg. -ve sqrt ?)


SCALE: constant(int256) = 10**18
ITERATIONS: constant(int256) = 100

e: constant(int256)   = 2718281828459045235 # 18 decimal places
LOG2E: constant(int256) = 1442695040888963407 # log_2(e) to 18 decimal places 

# NB: ONE is equal to SCALE. Different variables are used for readability.
ONE: constant(int256)  = 1000000000000000000
TWO: constant(int256)  = 2000000000000000000
HALF: constant(int256) =  500000000000000000


event Value:
    x: int256


@pure
@internal
def _sqrt(x: int256) -> int256:

    assert x > 0, "Value must be positive."

    x_i: int256 = x

    for i in range(ITERATIONS):
        # Extra scale cancels out. Important to avoid loss of precision during division.
        x_i = (x_i + (x*SCALE/x_i)) / 2

    return x_i

@view
@external
def square_root(x: int256) -> int256:
    #NB: Vyper has builtin function named sqrt(decimal)
    return self._sqrt(x)


@pure
@internal
def _log2(_x: int256) -> int256:
    # Iterative approximation: https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation

    assert _x > 0, "Value must be positive."


    sign: int256 = 1
    x: int256 = _x
    if x < ONE:
        # Logic for log(1/x) = -log(x)
        sign = -1
        x = (SCALE*SCALE) / x

    # Evaluate integer part
    result: int256 = 0
    n: int256 = x
    for i in range(ITERATIONS):
        if n >= TWO:
            result += 1
            n /= 2
        else:
            break

    y: int256 = x / (2 ** result)

    result *= SCALE
    
    if y == ONE:
        # x is some multiple multiple of two, there is no fractional part
        return result * sign

    # Evaluate fractional part
    delta: int256 = HALF
    for i in range(ITERATIONS):

        y = (y*y / SCALE)

        if y >= TWO:
            result += delta
            y /= 2

        delta /= 2
        if delta <= 0:
            break

    return result * sign


@view
@external
def log_2(x: int256) -> int256:
    # NB: log2 is a reserved word
    return self._log2(x)


@view
@internal
def _ln(x: int256) -> int256:
    # Change of base formula
    return self._log2(x)*SCALE / LOG2E


@view
@external
def ln(x: int256) -> int256:
    return self._ln(x)



@pure
@internal
def _exp(x: int256) -> int256:
    # Calculate exponent of e
    # x is scaled
    # Use Maclaurin expansion

    result: int256 = ONE
    term: int256 = x
    for i in range(1, 50):
        result += term
        
        # Calculate next term
        term *= x
        term /= SCALE
        term /= (i+1)

    return result


@view
@external
def exponent(x: int256) -> int256:
    # NB: exp is reserved word
    return self._exp(x)



@view
@internal
def _N(_x: int256) -> int256:
    """
    Approximation of the standard normal cdf.
    Abramowitz and Stegun formula 7.1.26
    """

    # Constants used to calculate error function
    a2 : int256 = - 284496736000000000 # -0.284496736
    a1 : int256 =   254829592000000000 #  0.254829592
    a3 : int256 =  1421413741000000000 #  1.421413741
    a4 : int256 = -1453152027000000000 # -1.453152027
    a5 : int256 =  1061405429000000000 #  1.061405429
    p  : int256 =   327591100000000000 #  0.3275911

    sign : int256 = 1
    if (_x <= 0):
        sign = -1

    # Use x/sqrt(2) as the input for the error function
    x: int256 = abs(_x) * SCALE / self._sqrt(TWO)

    # Calculate error function
    t   : int256 = (ONE*SCALE) / (ONE + (p*x)/SCALE)
    erf : int256 = ONE - (((((a5*t/SCALE + a4)*t/SCALE) + a3)*t/SCALE + a2)*t/SCALE + a1)*t / self._exp(x*x/SCALE)
    
    
    # at1: int256 = (a1 * t)
    # at2: int256 = (a2 * t**2) / (SCALE)
    # at3: int256 = (a3 * t**3) / (SCALE**2)
    # at4: int256 = (a4 * (t**2) / SCALE) * ((t**2) / SCALE) / (SCALE)# Avoid overflow error
    # at5: int256 = a5 * ((t**3) / (SCALE**2)) * ((t**2) / (SCALE)) / (SCALE) # Avoid overflow error

    # # erf : int256 = ONE - (a1*t/SCALE + a2*(t**2)/(SCALE**2) + a3*(t**3)/(SCALE**3) + a4*(t**4)/(SCALE**4) + a5*(t**5)/(SCALE**5)) / self._exp(abs_x*abs_x/SCALE)
    # erf: int256 = ONE - (at1 + at2 + at3 + at4 + at5) / self._exp(abs_x*abs_x/SCALE)


    # Convert error function to normal distribution
    # N(x) = [ 1 + erf(x/sqrt(2)) ] / 2
    y : int256 = ( sign*erf + ONE) / 2
    
    return y


@view
@external
def N(x: int256) -> int256:
    return self._N(x)


@view
@internal
def _d1(s: int256, k: int256, r: int256, t: int256, v: int256) -> int256:
    
    term1: int256 = self._ln(s*SCALE/k)
    term2: int256 = (r + (v*v)/TWO) * t / SCALE
    
    denominator: int256 = v * self._sqrt(t) / SCALE
    
    return (term1 + term2) * SCALE / denominator


@view
@internal
def _d2(s: int256, k: int256, r: int256, t: int256, v: int256) -> int256:
    return self._d1(s, k, r, t, v) - (v * self._sqrt(t)) / SCALE


@view
@external
def black_scholes_call(s: int256, k: int256, r: int256, t: int256, v: int256) -> int256:
    
    log Value(ONE)

    d1: int256 = self._d1(s, k, r, t, v)
    d2: int256 = self._d2(s, k, r, t, v)

    term1: int256 = s * self._N(d1) / SCALE
    log Value(r * t / SCALE)
    term2: int256 = k * self._N(d2) / (self._exp(r * t / SCALE))
    
    return term1 - term2


@view
@external
def black_scholes_put(s: int256, k: int256, r: int256, t: int256, v: int256) -> int256:
    
    d1: int256 = self._d1(s, k, r, t, v)
    d2: int256 = self._d2(s, k, r, t, v)

    term1: int256 = k * (self._exp(-r * t / SCALE)) * self._N(-d2) / SCALE
    term2: int256 = s * self._N(-d1)
    
    return (term1 - term2) / SCALE