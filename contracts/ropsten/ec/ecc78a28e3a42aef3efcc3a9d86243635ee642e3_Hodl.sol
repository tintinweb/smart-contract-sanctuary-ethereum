/**
 *Submitted for verification at Etherscan.io on 2022-02-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Hodl{
    string  public owner_name;
    address payable public owner_address;
    uint start;
    uint year=365;
    struct account{
        string name;
        uint256 balance;
        uint256 withdrawn;
    }

    mapping(address=>account) address_account;

    function AddBalance(uint256 value) public {
        address payable user = payable(msg.sender);
        address_account[user].balance += value;
    }

    function CheckBalance () public view returns(uint256){
        address payable user = payable(msg.sender);
        return address_account[user].balance;
    }


    constructor(string memory name){
        owner_name = name;
        owner_address= payable(msg.sender);
        start=block.timestamp;
    }

    fallback() external payable {
        require(block.timestamp <= start + year * 1 days,"It is too early!");
    }
    
    receive() external payable {
        require(block.timestamp <= start + year * 1 days,"It is too early!");
    }

    function ReleaseFunds() external{
        require(block.timestamp >= start + year * 1 days,"It is too early!");
        selfdestruct(owner_address);
    }
}