/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// File: mocks/MockWrappedSynthr.sol



pragma solidity ^0.8.10;

contract MockWrappedSynthr {
    mapping(bytes32 => mapping(address => uint256)) public collateralByIssuer;

    address public collateralLZAggregator;
    constructor(address _collateralLZAggregator) {
        collateralLZAggregator = _collateralLZAggregator;
    }

    modifier onlyCollateralAggregator() {
        require(msg.sender == collateralLZAggregator, "Caller is not the aggregator");
        _;
    }

    // Receiving message from aggregator
    function depositCollateral(address account, uint256 amount, bytes32 collateralKey) external onlyCollateralAggregator {
        collateralByIssuer[collateralKey][account] += amount;
    }

    function withdrawCollateral(address account, uint256 amount, bytes32 collateralKey) external onlyCollateralAggregator {
        collateralByIssuer[collateralKey][account] -= amount;
    }

    function setCollateralLZAggregator(address _collateralLZAggregator) external {
        collateralLZAggregator = _collateralLZAggregator;
    }
}