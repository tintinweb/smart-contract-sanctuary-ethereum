/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

pragma solidity ^0.8.0;

interface ConsumerInterface {
  function pushReport(uint256 payload) external;

  function purgeReports() external;

  function addProvider(address) external;

  event ProviderReportPushed(address indexed provider, uint256 payload, uint256 timestamp);
}

contract Consumer is ConsumerInterface {
    uint256 public lastUpdated = 0;
    uint256 public cooldown = 60 * 60 * 24; // 24 hours

    function pushReport(uint256 payload) external override {
        require(lastUpdated + cooldown <= block.timestamp, "not cooled down");
        lastUpdated = block.timestamp;
        emit ProviderReportPushed(msg.sender, payload, block.timestamp);
    }

    function purgeReports() external override {}

    function addProvider(address) external override {}
}