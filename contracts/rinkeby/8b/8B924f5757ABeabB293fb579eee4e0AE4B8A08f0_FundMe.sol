/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;



// File: FundMe.sol

//This contract is a crowdfunding contract where the contract accept funds from different addresses
//for a specific course. This funds can only be withdrawn by the address that deployed the contract
//After withdraw, the fund balance is set to zero while the address array is also set to zero
contract FundMe {
    //this is the address that deployed this contract
    address public Owner;

    constructor() public {
        Owner = msg.sender;
    }

    //the sender's addresses are mapped to the value sent
    mapping(address => uint256) public addressToAmount;
    //this store the array of addresses that have funded the contract
    address[] public sendersAddresses;

    function receiveFunds() public payable {
        //this maps the sender's address to its value
        addressToAmount[msg.sender] += msg.value;
        sendersAddresses.push(msg.sender);
    }

    //transfer the token from address of this contract
    modifier onlyOwner() {
        require(msg.sender == Owner, "you ain't the owner, fuck you!");
        _;
    }

    //this withdraw function can only be called by the contract deployer== owner of the contract
    function withdrawFunds() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

        for (
            uint256 funderIndex = 0;
            funderIndex < sendersAddresses.length;
            funderIndex++
        ) {
            address funder = sendersAddresses[funderIndex];
            addressToAmount[funder] = 0;
        }
        sendersAddresses = new address[](0);
    }

    // this function returns the number of times(in case same address funded multiple times)
    //the crowdfunding contract has been funded

    function number_Of_times_Funded() public view returns (uint256) {
        return (sendersAddresses.length);
    }
}