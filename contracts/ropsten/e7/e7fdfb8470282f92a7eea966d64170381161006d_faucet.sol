/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma solidity >=0.7.0 <0.9.0;

contract faucet {

    address public owner;
    uint256 public amountAllowed = 1;

    mapping(address => uint256) public lockTime;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }


    //function to set the amount allowable to be claimed. Only the owner can call this function
    function setAmountallowed(uint newAmountAllowed) public onlyOwner {
        amountAllowed = newAmountAllowed;
    }

    //function to donate funds to the faucet contract
	function donateTofaucet() public payable {
	}

    //function to send tokens from faucet to an address
    function requestTokens(address payable _requestor) public payable {

        //perform a few checks to make sure function can execute
        require(block.timestamp > lockTime[msg.sender], "lock time has not expired. Please try again later");
        require(address(this).balance > amountAllowed, "Not enough funds in the faucet. Please donate");

        //if the balance of this contract is greater then the requested amount send funds
        _requestor.transfer(amountAllowed);        
 
        //updates locktime 1 day from now
        lockTime[msg.sender] = block.timestamp + 1 days;
    }
}