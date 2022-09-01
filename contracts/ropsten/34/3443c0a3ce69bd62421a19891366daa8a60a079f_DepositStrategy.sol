// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDepositStrategy {
    function onDeposit(
        address sender,
        uint256 amount,
        address receiver
    ) external returns (bool, uint256);

    function onMint(
        address sender,
        uint256 amount,
        address receiver
    ) external returns (bool, uint256);

    function previewDepositFee(uint256 assetsBeforeFee) external view returns (uint256 fee);

    function previewMintFee(uint256 assetsBeforeFee) external view returns (uint256 fee);

    function maxDeposit(address sender) external view returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IDepositStrategy} from "IDepositStrategy.sol";

contract DepositStrategy is IDepositStrategy {
    function onDeposit(
        address,
        uint256,
        address
    ) external pure returns (bool, uint256) {
        return (true, 0);
    }

    function onMint(
        address,
        uint256,
        address
    ) external pure returns (bool, uint256) {
        return (true, 0);
    }

    function previewDepositFee(uint256) external pure returns (uint256) {
        return 0;
    }

    function previewMintFee(uint256) external pure returns (uint256) {
        return 0;
    }

    function maxDeposit(address) external pure returns (uint256) {
        return type(uint256).max;
    }
}