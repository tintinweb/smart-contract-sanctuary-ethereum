/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract SNXAggregator {
    address private _owner;

    // Mock values
    uint80 private _roundId;
    int256 private _answer;
    uint256 private _startedAt;
    uint256 private _updatedAt;
    uint80 private _answeredInRound;

    constructor(address __owner) {
        _owner = __owner;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    function owner() external view returns(address) {
        return _owner;
    }

    function setOwner(address __owner) public onlyOwner {
        require(__owner != address(0), "ZERO ADDRESS value");
        _owner = __owner;
    }

    function setRoundId(uint80 __roundId) external onlyOwner {
        _roundId = __roundId;
    }

    function setAnswer(int256 __answer) external onlyOwner {
        _answer = __answer;
    }

    function setUpdatedAt(uint256 __updatedAt) external onlyOwner {
        _updatedAt = __updatedAt;
    }

    function setAnsweredInRound(uint80 __answeredInRound) external onlyOwner {
        _answeredInRound = __answeredInRound;
    }

    function latestRoundData() public view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        return (_roundId, _answer, _startedAt, _updatedAt, _answeredInRound);
    }
}