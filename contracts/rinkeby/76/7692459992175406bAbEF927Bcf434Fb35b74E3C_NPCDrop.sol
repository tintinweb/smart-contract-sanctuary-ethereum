// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
pragma abicoder v2;

import './Ownable.sol';
import './Pausable.sol';
import './IERC20.sol';
import './SafeERC20.sol';
import './ECDSA.sol';
import './IStakeFor.sol';

contract NPCDrop is Ownable, Pausable {
    using SafeERC20 for IERC20;

    event Airdrop(address receiver, uint256 amount);
    event SignerUpdate(address signer, bool isRemoval);
    event StakingPoolUpdate(address pool);
    event NewRewardManager( address rewardManager,address user);


    uint256 public totalClaimed;

    uint256 public immutable startBlock;
    address public REWARDMANAGER;
    IERC20 public immutable token;
    /**feesharing address**/
    IStakeFor public stakingPool;

    mapping(address => uint256) public claimed; // wallet -> amount claimed
    mapping(address => bool) public signers;

    constructor(
        IStakeFor pool_,
        IERC20 token_,
        address signer_,
        uint256 startBlock_,
        address rewardManager_
    ) {
        stakingPool = pool_;
        token = token_;
        startBlock = startBlock_;
        REWARDMANAGER = rewardManager_;
        if (signer_ != address(0)) {
            signers[signer_] = true;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateStakingPool(IStakeFor pool_) external onlyOwner {
        stakingPool = pool_;
        emit StakingPoolUpdate(address(pool_));
    }

    function updateSigners(address[] memory toAdd, address[] memory toRemove) external onlyOwner {
        for (uint256 i = 0; i < toAdd.length; i++) {
            signers[toAdd[i]] = true;
            emit SignerUpdate(toAdd[i], false);
        }
        for (uint256 i = 0; i < toRemove.length; i++) {
            delete signers[toRemove[i]];
            emit SignerUpdate(toRemove[i], true);
        }
    }

    function claim(
        uint256 totalAmount,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool staking
    ) external whenNotPaused {
        require(block.number >= startBlock, 'Claim: wait for start');
        uint256 amount = totalAmount - claimed[msg.sender];
        require(amount > 0, 'Claim: nothing to send');
        bytes32 hash = keccak256(abi.encode(msg.sender, totalAmount));
        address signer = ECDSA.recover(hash, v, r, s);
        require(signers[signer], 'Claim: signature error');

        claimed[msg.sender] = totalAmount;

        if (staking) {
            require(address(stakingPool) != address(0), 'Cannot stake to address(0)');
            token.approve(address(stakingPool), amount);
            require(stakingPool.depositFor(msg.sender, amount), 'Claim: deposit failed');
        } else {
            token.safeTransfer(msg.sender, amount);
        }

        totalClaimed += amount;
        emit Airdrop(msg.sender, amount);
    }


    function claimForOneKey(
        uint256 totalAmount,
        address user,
        bool staking
    ) external whenNotPaused {
        require(msg.sender == REWARDMANAGER,"msg.sender must be REWARDMANAGER");
        require(block.number >= startBlock, 'Claim: wait for start');
        uint256 amount = totalAmount - claimed[user];
        require(amount > 0, 'Claim: nothing to send');

        claimed[user] = totalAmount;

        if (staking) {
            require(address(stakingPool) != address(0), 'Cannot stake to address(0)');
            token.approve(address(stakingPool), amount);
            require(stakingPool.depositFor(user, amount), 'Claim: deposit failed');
        } else {
            token.safeTransfer(user, amount);
        }

        totalClaimed += amount;
        emit Airdrop(user, amount);
    }
    function updateRewardManager(address rewardManager) external onlyOwner {
        REWARDMANAGER = rewardManager;
        emit NewRewardManager( rewardManager,msg.sender);
    }
}