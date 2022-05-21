/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity 0.8.13;

contract checkBalance {
    function getBalance(address _addCheck) external view returns (uint) {
        return _addCheck.balance;
    }
}