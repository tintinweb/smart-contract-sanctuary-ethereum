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

    uint256 public constant MAX_AMOUNT_PER_ADDRESS = 1000 ether;

    uint256 public totalClaimed;

    uint256 public immutable startBlock;

    IERC20 public immutable token;
    /**feesharing address**/
    IStakeFor public stakingPool;

    mapping(address => uint256) public claimed; // wallet -> amount claimed
    mapping(address => bool) public signers;

    constructor(
        IStakeFor pool_,
        IERC20 token_,
        address signer_,
        uint256 startBlock_
    ) {
        stakingPool = pool_;
        token = token_;
        startBlock = startBlock_;
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
        require(totalAmount <= MAX_AMOUNT_PER_ADDRESS, 'Claim: amount exceeds maximum');

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
}