/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

//pragma solidity >=0.7.0 <0.9.0;

pragma solidity ^0.8.13;

contract test {
    address public owner;
    uint public uiPubA = 0;
    uint public uiPubB = 0;
//WORKS    string public strThis = "Hello,  \u0041 World!";
    string public strThis = "Hello,  \u202e World!"; // YES!!!!!
    string public strThis2 = "BEARS, \u202e A B C D";

    constructor () {
//        require(msg.value == 1 ether);
        owner = msg.sender;
//        myfunc(/*\u202e */ 12, 23);
    }

    function myfunc(uint a, uint b) public {
        uiPubA = a;
        uiPubB = b;
    }

}