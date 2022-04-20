/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

pragma solidity ^0.8.0;

interface ConsumerInterface {
  function pushReport(uint256 payload) external;

  function purgeReports() external;

  function addProvider(address) external;

  event ProviderReportPushed(address indexed provider, uint256 payload, uint256 timestamp);
}

contract Consumer is ConsumerInterface {
    function pushReport(uint256 payload) external override {
        emit ProviderReportPushed(msg.sender, payload, block.timestamp);
    }

    function purgeReports() external override {}

    function addProvider(address) external override {}
}