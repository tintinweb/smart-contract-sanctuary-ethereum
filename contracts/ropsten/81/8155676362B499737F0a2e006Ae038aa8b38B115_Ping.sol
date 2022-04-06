/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

pragma solidity ^0.4.17;
contract Ping {
    event Pong(uint256 pong);
    uint256 public pings;
    function ping(uint256 value) external {
        pings++;
        Pong(pings + value);
    }
}