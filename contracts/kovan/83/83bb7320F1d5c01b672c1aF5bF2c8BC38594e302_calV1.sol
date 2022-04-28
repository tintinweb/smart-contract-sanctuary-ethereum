pragma solidity >0.8.0;

contract calV1 {

    uint public sum;
    uint public mul;
    
    function add(uint _a, uint _b) external returns(uint){
        sum = _a + _b ;
        return sum;
    }

    function mulip(uint _a, uint _b) external returns(uint){
        mul = _a * _b ;
        return mul;
    }
}