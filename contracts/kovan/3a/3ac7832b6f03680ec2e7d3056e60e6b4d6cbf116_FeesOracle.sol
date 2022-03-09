// SPDX-License-Identifier: MIT
pragma solidity = 0.8.9;

import "./Ownable.sol";

//solhint-disable-line
contract FeesOracle is Ownable {

    uint256 private stakedFee;
    uint256 private revenueFee;

    constructor(uint256 stakedFee_, uint256 revenueFee_) {
        stakedFee = stakedFee_;
        revenueFee = revenueFee_;
    }

    // Main Functions
    function updateStakedFee(uint256 newFee) external virtual onlyOwner {
        stakedFee = newFee;
    }

    function updateRevenueFee(uint256 newFee) external virtual onlyOwner {
        revenueFee = newFee;
    }

    // Getters

    function deployStakedFee() external view virtual returns (uint256) {
        return stakedFee;
    }

    function deployRevenueFee() external view virtual returns (uint256) {
        return revenueFee;
    }
}