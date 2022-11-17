/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Airtime {
    //State Variables
    address public immutable i_owner;

    //Custom Errors
    error Airtime__Unauthorised();
    error Airtime__SendEth();

    //Events
    event airtimeBought(uint256 indexed amount, string indexed phoneNo, address indexed buyer);
    event withdrawn(uint256 amount, address owner);

    //Receive and Fallback Functions
    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

    //Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Airtime__Unauthorised();
        }
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    function buyAirtime(string memory _phoneNo) external payable {
        if (msg.value <= 0) {
            revert Airtime__SendEth();
        }
        emit airtimeBought(msg.value, _phoneNo, msg.sender);
    }

    function withdraw() external onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
        emit withdrawn(amount, msg.sender);
    }
}