/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// File: contracts/Balance.sol


pragma solidity >=0.7.0 <0.9.0;    
contract Balance{
    mapping(address => uint256) balances;
    function balanceOf(address account) public view  returns (uint256) {
        return balances[account];
    }
}