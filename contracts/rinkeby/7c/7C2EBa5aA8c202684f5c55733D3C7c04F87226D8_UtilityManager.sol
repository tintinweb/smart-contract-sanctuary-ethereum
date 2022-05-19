// SPDX-License-Identifier: NONE
pragma solidity 0.8.7;


contract UtilityManager {

    struct Schema {
        uint256 stakedAmount;
        uint256 claimedAmount;
        uint256 unclaimedAmount;
        uint256 totalValueLocked;
        uint256 pendingRewards;
    }

    Schema public details;
    address public fossilToken;
    address public dinoPool;
    address public liquidityMiningManager;
    address public contractOwner;

    modifier onlyAllowedAddresses() {
        require(
            msg.sender == fossilToken ||
            msg.sender == dinoPool ||
            msg.sender == liquidityMiningManager ||
            msg.sender == contractOwner
        );
        _;
    }

    constructor() {
        contractOwner = msg.sender;
    }

    // Initializes different contract addresses
    function setContractAddress(
        address _fossilToken,
        address _dinoPool,
        address _liquidityMiningManager
    ) external {
        require(msg.sender == contractOwner, "Not the contract owner!");
        fossilToken = _fossilToken;
        dinoPool = _dinoPool;
        liquidityMiningManager = _liquidityMiningManager;
    }

    // Updates staked amount
    function updateStakedAmount(
        uint256 _amount
    ) external onlyAllowedAddresses {
        details.stakedAmount += _amount;
    }

    // Updates claimed amount
    function updateClaimedAmount(
        uint256 _amount
    ) external onlyAllowedAddresses {
        details.claimedAmount += _amount;
    }

    // Updates unclaimed amount
    function updateUnclaimedAmount(
        uint256 _amount, 
        uint256 _operation
    ) external onlyAllowedAddresses {
        if (_operation == 1) {
            details.unclaimedAmount += _amount;
        } else {
            require(details.unclaimedAmount >= _amount, "Subtraction underfows!");
            details.unclaimedAmount -= _amount;
        }
    }

    // Updates total value locked for specific token
    function updateTotalValueLockedAmount(
        uint256 _amount, 
        uint256 _operation
    ) external onlyAllowedAddresses {
        if (_operation == 1){
            details.totalValueLocked += _amount;
        }
        else {
            require(details.totalValueLocked >= _amount, "Subtraction underfows!");
            details.totalValueLocked -= _amount;
        }
    }

    // Updates pending rewards
    function updatePendingRewards(
        uint256 _amount, 
        uint256 _operation
    ) external onlyAllowedAddresses {
        if (_operation == 1) {
            details.pendingRewards += _amount;
        } else {
            require(details.pendingRewards >= _amount, "Subtraction underfows!");
            details.pendingRewards -= _amount;
        }
    }

}