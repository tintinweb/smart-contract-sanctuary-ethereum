/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.8.3;

contract Count{

    // uint public x=5;
    // uint public y=5;

    // function add() public returns(uint){
    //     uint result = x + y;
    //     return result;
    // }
    // function sub() public returns(uint){
    //     uint result = x - y;
    //     return result;
    // }
    // function mul() public returns(uint){
    //     uint result = x * y;
    //     return result;
    // }
    // function divide() public returns(uint){
    //     uint result = x / y;
    //     return result;
    // }

    event publish(string, uint);

    function add(uint x, uint y) public returns(uint){
        uint result = x + y;
        emit publish("The addition is:",result);
        return result;
    }
    function sub(uint x, uint y) public returns(uint){
        uint result = x - y;
        emit publish("The subtraction is:",result);
        return result;
    }
    function mul(uint x, uint y) public returns(uint){
        uint result = x * y;
        emit publish("The multiply is:",result);
        return result;
    }
    function divide(uint x, uint y) public returns(uint){
        uint result = x / y;
        emit publish("The division is:",result);
        return result;
    }
}