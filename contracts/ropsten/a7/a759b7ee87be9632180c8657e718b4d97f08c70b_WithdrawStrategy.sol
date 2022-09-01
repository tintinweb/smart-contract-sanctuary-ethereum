// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IWithdrawStrategy {
    function maxWithdraw(address owner) external view returns (uint256);

    function onWithdraw(
        address sender,
        uint256 amount,
        address receiver,
        address owner
    ) external returns (bool, uint256);

    function onRedeem(
        address sender,
        uint256 amount,
        address receiver,
        address owner
    ) external returns (bool, uint256);

    function previewWithdrawFee(uint256 assetsBeforeFee) external view returns (uint256);

    function previewRedeemFee(uint256 shares) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IWithdrawStrategy} from "IWithdrawStrategy.sol";

contract WithdrawStrategy is IWithdrawStrategy {
    function maxWithdraw(address) external pure returns (uint256) {
        return type(uint256).max;
    }

    function onWithdraw(
        address,
        uint256,
        address,
        address
    ) external pure returns (bool, uint256) {
        return (true, 0);
    }

    function onRedeem(
        address,
        uint256,
        address,
        address
    ) external pure returns (bool, uint256) {
        return (true, 0);
    }

    function previewRedeemFee(uint256) external pure returns (uint256) {
        return 0;
    }

    function previewWithdrawFee(uint256) external pure returns (uint256) {
        return 0;
    }
}