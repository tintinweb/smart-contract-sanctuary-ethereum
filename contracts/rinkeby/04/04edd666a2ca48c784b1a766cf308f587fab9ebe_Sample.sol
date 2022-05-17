/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

pragma solidity ^0.8.1;

contract Sample{
    int public no = 1;
    uint public no1 = 2;
    string public hi = 'hello were one i am fine here';
    uint public addition = 23 + 23;

    string public hello = 'hii bro';


    function hel() public view returns(string memory){
        return hello;
    }

    function he(string memory hel) public pure returns(string memory){
        return hel;
    }

    int[] public array;

    function add(int num) public{
        array.push(num);
    }
    
    function del() public{
        array.pop();
    }

}