/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity >=0.7.0 <0.9.0;

contract getBalance {
    function getBalances(address addr) public view returns(uint ) {
        return addr.balance;
    }
}