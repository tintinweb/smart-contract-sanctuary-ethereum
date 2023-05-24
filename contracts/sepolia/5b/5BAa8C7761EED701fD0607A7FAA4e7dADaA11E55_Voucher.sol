/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

pragma solidity ^0.8.0;


contract Voucher {

    mapping(address => uint256) public balances;
   
    constructor() {
        balances[msg.sender] = 100;
    }

    function transfer(address _to, uint256 _amount) external {
        require(balances[msg.sender] >= _amount, "not enough funds");
        // decrease sender's balance by _amount
        balances[msg.sender] -= _amount;
        // increase receiver's balance by _amount
        balances[_to] += _amount;
    }


}