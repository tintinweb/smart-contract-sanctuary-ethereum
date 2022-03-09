// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Crypto Barter - All rights reserved
// cryptobarter.io
// @title StakedShareFactory
// @notice Provides functions to create a copy of  StakedShare contract
// @author Anibal Catalan <[email protected]>

pragma solidity = 0.8.9;

import "./Clones.sol";
import "./StakedShare.sol";
import "./FeesOracle.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

//solhint-disable-line
contract StakedShareFactory is Ownable, ReentrancyGuard {

    uint32 private revenueProjects;
    address private cryptobarter;
    address private feeOracle;

    constructor(address cryptobarter_, address feeOracle_) Ownable() {
        require(cryptobarter_ != address(0), "cryptobarter address should not be 0");
        require(feeOracle_ != address(0), "feeOracle address should not be 0");
        cryptobarter = cryptobarter_;
        feeOracle = feeOracle_;
    }

    // Main Function

    function stakedShare(address implementation, address projectToken, string memory name, string memory symbol, string memory logo) external virtual payable nonReentrant onlyOwner {
        require(implementation != address(0), "implementation should not be address 0");
        require(projectToken != address(0), "reward token should not be address 0");
        require(msg.value == FeesOracle(feeOracle).deployStakedFee(), "invalid fee");
        require(_safeTransferEth(msg.value), "transfer fee fails");
        address clone = Clones.clone(implementation);
        StakedShare(clone).initialize(projectToken, name, symbol, logo);
        revenueProjects += 1;
        emit Cloned(clone, projectToken);
    }

    // Getters
    function projects() external view virtual returns (uint32) {
        return revenueProjects;
    }

    // Internal Functions
    function _safeTransferEth(uint256 amount) internal virtual returns (bool) {
        (bool sent, ) = cryptobarter.call{value: amount}("");
        return sent;
    }

    receive() external payable {
        revert("directly eth transfers are not allowed");
    }

    fallback() external payable {
        revert("directly eth transfers are not allowed");
    }

    // Event
    event Cloned(address indexed clone, address indexed projectToken);
}