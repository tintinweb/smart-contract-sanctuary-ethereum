/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

pragma solidity ^0.8.7;


contract toto {
    uint256 private vipPass;

    function rand(string memory _password, address sender, uint256 timestamp, uint256 difficulty, uint256 vipPass, uint256 balances) public returns (uint256) {
        return uint(keccak256(abi.encodePacked(
        sender,
        timestamp,
        difficulty,
        vipPass,
        balances,
        _password)));

    }
    

    
}