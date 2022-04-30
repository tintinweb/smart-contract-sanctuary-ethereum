/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// File: SharedWallet.sol

/*
 * @title: SharedWallet.
 * @author: Anthony (fps) https://github.com/fps8k .
 *
 *
 * @dev: 
 * Build a shared wallet Solidity smart contract. 
 * The owner of this contract can add and remove other owners and temporarily disable owners. 
 * Anyone can deposit ETH into the contract.
 * However to withdraw ETH more then one owner needs to approve the transaction.
*/


contract SharedWallet
{
    
    struct Withrawals
    {
        uint256 pending;
        uint256 approvals;
    }


    address private owner;
    mapping(address => bool) private owners;

    mapping(address => Withrawals) private withdrawals;

    bool locked;



    constructor()
    {
        owner = 0x5e078E6b545cF88aBD5BB58d27488eF8BE0D2593;                              // Production
        // owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;                                 // Development
    }


    modifier isValidSender()
    {
        require(msg.sender != address(0), "! Caller Address");
        _;
    }


    modifier noReEntrance()
    {
        require(!locked, "No Re-entrace");
        locked = true;
        _;
        locked = false;
    }


    function isOwner(address _address) private view returns(bool)
    {
        return ((_address == owner) || (owners[_address] == true));
    }


    fallback() external payable{}
    receive() external payable{}




    function addOwner(address new_owner) public isValidSender
    {
        require(msg.sender == owner, "! Owner");
		require(new_owner != address(0), "New address is 0 address");
        owners[new_owner] = true;
    }




    function removeOwner(address _owner) public isValidSender
    {
        require(msg.sender == owner, "! Owner");
		require(_owner != address(0), "Address is 0 address");
        delete owners[_owner];
    }




    function deposit() public payable isValidSender noReEntrance {}


    function withdraw(uint256 _amount) public isValidSender noReEntrance
    {
        require(withdrawals[msg.sender].pending == 0, "You have a pending withdrawal.");                 // No Pending withdrawal.
        require(_amount < address(this).balance, "Amount >= Balance");

        withdrawals[msg.sender].pending = _amount;
        withdrawals[msg.sender].approvals = 0;
    }




    function approveWithdrawal(address _address) public payable isValidSender noReEntrance
    {
        require(isOwner(msg.sender), "Not an owner");
        require(_address != address(0), "! Valid Address");
        require(msg.sender != _address, "You cannot approve your withdrawal");
        require(withdrawals[_address].pending > 0, "No pending withdrawals");

        withdrawals[_address].approvals += 1;

        if (withdrawals[_address].approvals >= 2)
        {
            payable(_address).transfer(withdrawals[_address].pending);
            delete withdrawals[_address];
        }
    }




    function closeWithdrawal() public isValidSender
    {
        require(withdrawals[msg.sender].pending > 0, "You have no pending withdrawal.");                 // Pending withdrawal.
        delete withdrawals[msg.sender];
    }




    function viewWithdrawals(address _address) public view isValidSender returns(uint256)
    {
        require(_address != address(0), "! Valid Address");
        require(isOwner(msg.sender), "Not an owner");

        return withdrawals[_address].pending;
    }
}