pragma solidity ^0.8.15;

//Contract - Basic Math operations
//Interface for the contract
interface iMathExtended {

    function add(uint256 _value1, uint256 _value2) external returns (uint256);

    function mulDiv(uint256 _value1, uint256 _value2, uint256 _value3) external returns (uint256);

    function addBulk(uint256[] memory _values) external returns (uint256);

    function isPrime(uint256 _value) external returns (bool);

    function getGcd(uint256 _value1, uint256 _value2) external returns (uint256);

    function swapAwesome(uint256 _value1, uint256 _value2) external returns (uint256 _val1, uint256 _val2);
}

contract MathExtended is iMathExtended {
    // uint256 public res; //State Variable

    //Takes two integers and returns their sum.
    function add(uint256 _value1, uint256 _value2) override public pure returns (uint256) {
        return _value1 + _value2; 
    }

    //Multiplies the first two numbers and returns the result divided by _value3.
    function mulDiv(uint256 _value1, uint256 _value2, uint256 _value3) override public pure returns (uint256) {
        require(_value3>0, "Value 3 cannot be 0"); //Conditon for 1/0 
       
        uint resMultiply=_value1*_value2;
        // res=(resMultiply*10000)/_value3; //Through state variable
        // return res;

        return ((resMultiply*10000)/_value3);
    }

    //Returns sum of uint array.
    function addBulk(uint256[] memory _values) override public pure returns (uint256) {
        uint i;
        uint sum = 0;
    
        for(i = 0; i < _values.length; i++)
            sum = sum + _values[i];
        return sum;
    }

    //Returns true if _value is a prime number.
    function isPrime(uint256 _value) override public pure returns (bool) {
         uint i;

         for (i = 2; i < _value; i++) {
            if (_value % i == 0) { // 10%5==0
                return false;
            }
        }
        return true;
    }
    
    //Returns the greatest common divisor of two numbers.
    function getGcd(uint256 _value1, uint256 _value2) override public pure returns (uint256){
        uint i;
        uint gcd;

        if(_value1==_value2) {
            return _value1;
        }
        else {
            for (i = 1; i <= _value1 && i <= _value2; i++) {

            // check if is factor of both integers
                if( _value1 % i == 0 && _value2 % i == 0) {
                gcd = i;
                }
            }
            return gcd;
        }
    }

    //Swaps the values of passed two numbers without using any helper variable.
    function swapAwesome(uint256 _value1, uint256 _value2) override public pure returns (uint256, uint256) {
        //val1=10, val2=20

        _value1 = _value1 + _value2;//val1 = 30 (10+20)    
        _value2 = _value1 - _value2;//val2 = 10 (30-20)    
        _value1 = _value1 - _value2;//val1 = 20 (30-10)    

        return (_value1,_value2);
    }

}