/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// File: contracts/test.sol



pragma solidity >= 0.6.0;

contract test {
    
    uint public salesStartTimestamp = 1655740800;
    uint public salesStartTimestamp2 = 1655734727;
    event timeNow(uint time);
    function isSalesActive() public view returns (bool) {
        return salesStartTimestamp <= block.timestamp;
    }

    function isSalesActive2() public view returns (bool) {
        return salesStartTimestamp2 <= block.timestamp;
    }
}