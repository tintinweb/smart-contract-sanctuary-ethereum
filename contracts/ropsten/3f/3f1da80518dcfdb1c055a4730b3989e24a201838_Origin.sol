/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

pragma solidity 0.8.13;

contract Origin {
    function getOrigin() public view returns(address) {
        return tx.origin;
    }
    function getSender() public view returns(address) {
        return msg.sender;
    }
}