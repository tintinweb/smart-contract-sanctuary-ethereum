// SPDX-License-Identifier: UNLICENSED
// Copyright (c) 2022 Crypto Barter - All rights reserved
// cryptobarter.io
// @title RevenueFactory
// @notice Provides functions to create a copy of  Revenue Claim contract
// @author Anibal Catalan <[email protected]>

pragma solidity = 0.8.9;

import "./Clones.sol";
import "./RevenueClaim.sol";
import "./FeesOracle.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

//solhint-disable-line
contract RevenueFactory is Ownable, ReentrancyGuard {

    uint32 private claimablesRevenue;
    address private cryptobarter;
    address private feeOracle;
    mapping(uint256 => address) internal revenues;

    constructor(address cryptobarter_, address feeOracle_) Ownable() {
        require(cryptobarter_ != address(0), "cryptobarter address should not be 0");
        require(feeOracle_ != address(0), "feeOracle address should not be 0");
        cryptobarter = cryptobarter_;
        feeOracle = feeOracle_;
    }

    // Main Function

    function revenueShare(
        address implementation
        , address nft
        , address rewardToken
        , uint256 revenue
        , bytes32 root
        , uint64 blockNumber
    ) external virtual payable nonReentrant onlyOwner 
    {
        require(msg.value >= FeesOracle(feeOracle).deployRevenueFee(), "invalid fee");
        require(_safeTransferEth(msg.value), "transfer fee fails");
        require(root[0] != 0, "empty root");
        require(
            rewardToken != address(0)
            && nft != address(0)
            && implementation != address(0)
            , "address should not be 0"
        );
        require(revenue > 0 && blockNumber > 0, "should be greater than 0");
        address clone = Clones.clone(implementation);
        _transferFrom(rewardToken, clone, revenue); 
        RevenueClaim(clone).initialize(nft, rewardToken, revenue, root, blockNumber);
        claimablesRevenue += 1;
        revenues[claimablesRevenue] = clone;
        emit Cloned(clone, rewardToken, revenue);
    }

    receive() external payable {
        revert("directly eth transfers are not allowed");
    }

    fallback() external payable {
        revert("directly eth transfers are not allowed");
    }

    // Getters
    function claimables() external view virtual returns (uint32) {
        return claimablesRevenue;
    }

    function revenuesAddress(uint256 id) external view virtual returns (address) {
        return revenues[id];
    }


    // Internal Functions
    function _safeTransferEth(uint256 amount) internal virtual returns (bool) {
        (bool sent, ) = cryptobarter.call{value: amount}("");
        return sent;
    }

    function _transferFrom(address token, address to, uint256 amount) internal virtual returns (bool) {
        require(to != address(0), "must be valid address");
        require(amount > 0, "you must send something");
        SafeERC20.safeTransferFrom(IERC20(token), owner(), to, amount);
        return true;
    }

    // Event
    event Cloned(address indexed clone, address indexed rewardToken, uint256 indexed amount);
}