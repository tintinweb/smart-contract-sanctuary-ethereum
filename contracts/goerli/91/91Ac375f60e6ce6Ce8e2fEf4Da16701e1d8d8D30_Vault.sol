/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
//import "hardhat/console.sol";

// deployed to Goerli at 0x7C8973fE68ae535164B14AbBbEb1d46D30537354
// modified and deployed to Goerli at 0x91Ac375f60e6ce6Ce8e2fEf4Da16701e1d8d8D30

contract Vault {

    // Event to emit when donation is made
    event newDonation(
        address indexed from,
        uint256 timestamp,
        uint amount,
        string name
    );

    // donation struct
    struct donation{
        address from;
        uint256 timestamp;
        uint amount; 
        string name;
    }

    // payable address can receive Ether
    address payable public owner;

    // List of all donations
    donation[] donations; 

    // Payable contract can receive Ether
    constructor(){
        owner = payable(msg.sender);
    }

    // keep track of who deposited which ether
    mapping(address => uint) balances; 

    /**
     * @dev donation into vault
     * @param _name name of company 
     */
    function donate(string memory _name) public payable{
        require(msg.value > 0, "Must donation more than 0 eth");

        // update amount of ether donated by donor 
        balances[msg.sender] += msg.value; 

        // Add donation to storage
        donations.push(donation(
            msg.sender,
            block.timestamp,
            msg.value,
            _name
        ));

        // Emit a log event when a new donation is made
        emit newDonation(
            msg.sender,
            block.timestamp,
            msg.value,
            _name
        );
    }

    /**
     * @dev transfer Ether from vault to address
     * @param recipient address to send Ether
     */
    function sendEther(address payable recipient) public {
        
        recipient.transfer(1 ether); 
    }

    /**
     * @dev returns array of donations made to vault
     */
    function getDonations() public view returns(donation[] memory){
        return donations;
    }

    /**
     * @dev returns balance of vault 
     */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
   
}