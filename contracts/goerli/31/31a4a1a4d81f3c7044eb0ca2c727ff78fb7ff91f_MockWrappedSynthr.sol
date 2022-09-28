/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// File: interfaces/ICollateralAggregator.sol



pragma solidity ^0.8.0;

interface ICollateralAggregator {
    function sendDeposit(address _account, uint256 amount, bytes32 collateralKey) external;
    function sendWithdraw(address _account, uint256 amount, bytes32 collateralKey) external;
}
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

    // updating its own collateral and send message to other chain
    function depositCollateral(uint256 amount, bytes32 collateralKey) external {
        collateralByIssuer[collateralKey][msg.sender] += amount;

        ICollateralAggregator(collateralLZAggregator).sendDeposit(msg.sender, amount, collateralKey);
    }

    function withdrawCollateral(uint256 amount, bytes32 collateralKey) external {
        collateralByIssuer[collateralKey][msg.sender] -= amount;

        ICollateralAggregator(collateralLZAggregator).sendWithdraw(msg.sender, amount, collateralKey);
    }

    // Receiving message from aggregator
    function lzDepositCollateral(address account, uint256 amount, bytes32 collateralKey) external onlyCollateralAggregator {
        collateralByIssuer[collateralKey][account] += amount;
    }

    function lzWithdrawCollateral(address account, uint256 amount, bytes32 collateralKey) external onlyCollateralAggregator {
        collateralByIssuer[collateralKey][account] -= amount;
    }

    function setCollateralLZAggregator(address _collateralLZAggregator) external {
        collateralLZAggregator = _collateralLZAggregator;
    }
}