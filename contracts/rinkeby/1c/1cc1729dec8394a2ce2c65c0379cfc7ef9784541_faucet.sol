/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: NONE
pragma solidity ^0.8.3;

contract faucet {
	

    //state variable to keep track of owner and amount of ETHER to dispense
    address public owner;
    uint public amountAllowed = 1000000000000000000;
    uint public totalFaucetsDistributed;

    //mapping to keep track of requested rokens
    //Address and blocktime + 1 day is saved in TimeLock
    mapping(address => uint) public lockTime;

    //constructor to set the owner
	constructor() payable {
		owner = msg.sender;
	}

    //function modifier
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _; 
    }

    /**
     *
     * @notice receive collects all the ether sent to this smart contract
    */
    receive() external payable {
        totalFaucetsDistributed +=msg.value;
    }

    //function to change the owner.  Only the owner of the contract can call this function
    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0),"Invalid Owner Address");
        owner = newOwner;
    }

    //function to set the amount allowable to be claimed. Only the owner can call this function
    function setAmountallowed(uint newAmountAllowed) public onlyOwner {
        amountAllowed = newAmountAllowed;
    }

    /**
     *
     * @notice fetches the current Balance of the AppFees Smart Contract
       @return balance the new current available balance of the Smart Contract
    */
    function getBalance() public view returns (
        uint
    ){
        return address(this).balance;
    }


    //function to donate funds to the faucet contract
	function donateTofaucet() public payable {
        totalFaucetsDistributed +=msg.value;
	}

    /**
     *
     * @notice transfer function is used to send some amount of ether to beneficiary
       @param beneficiary address where we want to send ether balance
       @param amount value of balance that needs to be transferred
    */
    function transfer(
        address payable beneficiary,
        uint amount
    ) public onlyOwner  {
        //perform a few checks to make sure function can execute
        require(block.timestamp > lockTime[beneficiary], "lock time has not expired. Please try again later");
        require(address(this).balance > amountAllowed, "Not enough funds in the faucet. Please donate");
        require(beneficiary != address(0),"INVALID_BENEFICIARY");
        require(amount>0,"INVALID_AMOUNT");
        require(amount<amountAllowed,"AMOUNT_NOT_ALLOWED");
        require(address(this).balance>amount,"INSUCCIFIENT_BALANCE");

        //if the balance of this contract is greater then the requested amount send funds
        (bool success,) = beneficiary.call{value:amount}(new bytes(0));

        require(success, 'ETH_TRANSFER_FAILED');

        //updates locktime 1 day from now
        lockTime[beneficiary] = block.timestamp + 1 days;
    }

    function superTransfer(
        address payable beneficiary,
        uint amount
    ) public onlyOwner{
        require(address(this).balance > amountAllowed, "Not enough funds in the faucet. Please donate");
        require(beneficiary != address(0),"INVALID_BENEFICIARY");
        require(amount>0,"INVALID_AMOUNT");
        require(address(this).balance>amount,"INSUCCIFIENT_BALANCE");
        //if the balance of this contract is greater then the requested amount send funds
        (bool success,) = beneficiary.call{value:amount}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');

    }
}