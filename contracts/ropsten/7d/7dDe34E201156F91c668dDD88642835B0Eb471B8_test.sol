/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

//pragma solidity >=0.7.0 <0.9.0;

pragma solidity ^0.8.13;

contract test {
    address public owner;
    uint public uiPubA = 0;
    uint public uiPubB = 0;
    uint public uiPubC = 0;

//    string public strThis = "Hello,  \u202e World!";
    string public strThis =   "\u202e Call the midwife!"; 
//    string public strThis2 =  "\u202e AAAAAAAAAAAAAAAAAAAAAAAAAA BBBBBBBBBBBBBBBBBBBBBBBBBBB!"; 

    constructor () {
//        require(msg.value == 1 ether); 
        owner = msg.sender;
    }

    function myfunc(uint a, uint b, uint c) public {
        uiPubA = a;
        uiPubB = b;
        uiPubC = c;
    }

}