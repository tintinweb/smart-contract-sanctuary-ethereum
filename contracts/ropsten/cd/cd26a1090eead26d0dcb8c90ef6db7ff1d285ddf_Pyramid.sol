/**
 *Submitted for verification at Etherscan.io on 2022-05-29
*/

// SPDX-License-Identifier: GPL-3.0
// Complier 8.0
// BSON356110

pragma solidity >=0.7.0 <0.9.0;

contract Pyramid{

    event event_deposit(address my_address,uint256 my_principal);
    event event_withdraw(address my_address, uint256 my_balance);

    string public my_name;
    uint256 public my_principal;
    address payable public my_address;
    uint256 start;
    
    constructor(string memory name, uint256 principal){
        my_name = name;
        my_principal = principal;
        my_address = payable(msg.sender);
        start = block.timestamp;
        emit event_deposit(my_address, my_principal);
    }
    

    modifier IsOwner(){
        require(msg.sender == my_address, "You are not the owner!!");
        _;
    }
    
    function getMyBalance() public view returns (uint256){
        uint256 balance = my_principal;
        uint256 periods = (block.timestamp - start)/60/60/24;
        // 單利: 終值 = 本金 * (1 + 利率*期數)
        // periods = periods + 70;
        balance = my_principal * (1 + periods*10/100);
        return balance;
    }

    function Withdraw() external IsOwner{
        uint256 my_balance = getMyBalance();
        emit event_withdraw(my_address, my_balance);
        selfdestruct(my_address);
    }

}