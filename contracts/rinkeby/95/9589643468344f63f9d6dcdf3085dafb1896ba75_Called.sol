/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.4.9;

contract Called {
    address public caller;
    
    function Test() {
        caller = msg.sender;
    }
}

contract Caller {
    Called public called;
    
    function Caller(address _called) {
        called = Called(_called);
    }
    
    function Go() {
        called.Test();
    }
}