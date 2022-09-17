/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.13;


contract FrameATM{

    mapping (address => bool) _hasWithdrawn;

    receive() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getFunds() external{
        require(address(this).balance >= 0.12 ether);
        require(!_hasWithdrawn[msg.sender], "Already got funds, leave some for the rest of the players");
        bool success = payable(msg.sender).send(0.12 ether);
        require(success, "Couldn't give you funds :(");
    }
    
    function next() external pure returns(string memory nextStep){
        return "https://rinkeby.etherscan.io/address/0xe6e213fadb75860be84e3e30f47fab5797ac2b67";
    }
    


}