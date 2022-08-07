/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

pragma solidity ^0.8.15;

contract bank{
    mapping(address=>uint256) balances;
    address public donor_recipient;

    constructor(address donee){
        donor_recipient = donee;
    }

    function deposit() payable public{
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public{
        require(balances[msg.sender]>amount);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function check_balance(address account) public view returns(uint256){
        return balances[account];
    }

    function check_recipient() public view returns(address){
        return donor_recipient;
    }




}