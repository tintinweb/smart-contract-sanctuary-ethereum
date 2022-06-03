/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

pragma solidity ^0.8;

contract Depo {
    constructor(address owner) {
         owner = payable(msg.sender);
    }

    error LowValue();
    error Denied(address caller);

    mapping(address => uint256) public balances;

    function deposit() public payable {
        if(msg.value == 0) revert LowValue();
        balances[msg.sender] = balances[msg.sender] + msg.value;
    
    }

    function withdraw(uint256 _amount) public {
        uint256 amount = balances[msg.sender];
        if(_amount > amount) revert Denied(msg.sender);
        balances[msg.sender] = balances[msg.sender] - _amount;

       payable(msg.sender).transfer(_amount);
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    } 


}