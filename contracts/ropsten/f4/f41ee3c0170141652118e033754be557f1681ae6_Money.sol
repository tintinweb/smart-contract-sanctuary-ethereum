/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Money{

    string bank_name;
    address payable founder;

    struct Person{
        string name;
        uint256 balance;
        uint256 interest;
    }

    mapping(address=>Person) address_person;

    event event_add_balance(address name, uint256 totalBalance, uint256 interest);

    constructor(string memory name){
        bank_name = name;
        founder = payable(msg.sender);
    }

    function Store(address addressName, uint256 value) external{
        address_person[addressName].balance += value;
        address_person[addressName].interest = address_person[addressName].balance * 10 / 100;
        emit event_add_balance(addressName, address_person[addressName].balance, address_person[addressName].interest);
    }
 
    fallback() external payable {
    }
    
    receive() external payable {
        
    }

    modifier isBoss(address sender){
        require(sender == founder, "You are not the founder");
        _;
    }

    function Destroy() external isBoss(msg.sender){
        selfdestruct(founder);
    }
}