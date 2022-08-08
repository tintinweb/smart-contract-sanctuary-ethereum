/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

pragma solidity ^0.8.7;

contract Transactions {

    function directTx() public view returns(address, address) {
        return (msg.sender, tx.origin);
    }

    function internalTx() public view returns(address, address) {
        return this.iAmExternal();
    }

    function iAmExternal() external view returns(address, address) {
        return (msg.sender, tx.origin);
    }

}