// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract WithdrawSplitterV2 {
    address[] public receivers;
    uint16[] public proportions;
    uint256 private immutable proportionsSum;

    constructor(address[] memory receivers_, uint16[] memory proportions_) {
        require(receivers_.length == proportions_.length, "Wrong array items count");
        uint32 _proportionsSum;
        for (uint256 i = 0; i < receivers_.length; i++) {
            receivers.push(receivers_[i]);
            proportions.push(proportions_[i]);
            _proportionsSum += proportions_[i];
        }
        proportionsSum = _proportionsSum;
    }

    fallback() external payable { }

    receive() external payable { }

    // anybody - withdraw contract balance to receivers addresses according to the given proportions
    function withdraw() external {
        uint256 part = address(this).balance / proportionsSum;

        for (uint256 i = 0; i < receivers.length; i ++) {
            uint256 amount = part * proportions[i];
            payable(receivers[i]).transfer(amount);
        }
    }
}