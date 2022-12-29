/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// File: ooooo.sol


pragma solidity ^0.8.12;

contract catchedeer {

    function simlpe() public payable {
    }
    
    function withdraw() public {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }
}