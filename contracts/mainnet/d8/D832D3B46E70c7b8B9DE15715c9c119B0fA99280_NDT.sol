// SPDX-License-Identifier: MIT

/// @title NDT

pragma solidity 0.8.9;

import {ERC20} from "./ERC20.sol";

contract NDT is ERC20 {
    constructor(
        address community,
        address communityGrowth,
        address investors,
        address team,
        address advisors,
        address futureDevelopment,
        address ecosystemFunds
    ) ERC20("Nannda Token", "NDT") {
        /// @notice Mint for Community 56.0 million NDT
        /// @dev NDTCommunitySupplier Contract
        _mint(community, 560e23);

        /// @notice Mint for Community Growth 10.0 million NDT
        /// @dev Safe Wallet
        _mint(communityGrowth, 100e23);

        /// @notice Mint for Investors 8.0 million NDT
        /// @dev Vesting Contract
        _mint(investors, 80e23);

        /// @notice Mint for Investors 20.0 million NDT
        /// @dev Vesting Contract
        _mint(team, 200e23);

        /// @notice Mint for Investors 0.5 million NDT
        /// @dev Vesting Contract
        _mint(advisors, 5e23);

        /// @notice Mint for Investors 3.5 million NDT
        /// @dev Vesting Contract
        _mint(futureDevelopment, 35e23);

        /// @notice Mint for Ecosystem Funds 2.0 million NDT
        /// @dev Vesting Contract
        _mint(ecosystemFunds, 20e23);
    }
}