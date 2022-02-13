/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/******************************************/
/*       IERC20 starts here               */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/******************************************/
/*        GreenGenesis starts here        */
/******************************************/

contract GreenGenesis {

    IERC20 public GREEN; 
    IERC20 public DINO;

    uint256 public unlockPeriod = 36000;
    uint256 public unlockShift = unlockPeriod / 4;
    uint256 public swapRatio = 25;
    uint256 public startBlock;
    uint256 public endBlock;

    mapping (address => Allocation) public allocations;

    struct Allocation {
        uint256 sharePerBlock;
        uint256 lastWithdrawalBlock;
    }

    event SwapIn(address user, uint256 amountIn, uint256 disbursement, uint256 allocation);
    event Withdraw(address user, uint256 amountOut);

    /**
     * @dev Populate allocations.
     */
    constructor(address _DINO, address _GREEN)
    {
        DINO = IERC20(_DINO);
        GREEN = IERC20(_GREEN);
        startBlock = block.number - unlockShift;
        endBlock = startBlock + unlockPeriod;
    }

    /**
     * @dev Swap DINO to GREEN.
     */
    function swapIn(uint256 amount) external 
    {
        require(amount > 0, "Empty amount.");
        uint256 disbursement;
        uint256 sharePerBlock;
        uint256 unlockedBlock;
        DINO.transferFrom(msg.sender, address(this), amount);
        // initialize last withdrawal block
        if (allocations[msg.sender].lastWithdrawalBlock == 0) {
            if (block.number > endBlock) {
                unlockedBlock = endBlock;
            } else {
                unlockedBlock = block.number;
            }
            allocations[msg.sender].lastWithdrawalBlock = unlockedBlock;
        } else {
            withdrawShare();
        }

        uint256 withdrawnBlocks = unlockedBlock - startBlock;
        uint256 outstandingBlocks = endBlock - unlockedBlock;

        disbursement = amount / unlockPeriod * withdrawnBlocks;
        sharePerBlock = (amount - disbursement) / outstandingBlocks / swapRatio; 
        allocations[msg.sender].sharePerBlock += sharePerBlock;
        GREEN.transfer(msg.sender, disbursement / swapRatio);

        emit SwapIn(msg.sender, amount, disbursement / swapRatio, sharePerBlock * outstandingBlocks);
    }

    function getSwapIn(uint256 amount) external view returns(uint256, uint256)
    {
        uint256 disbursement;
        uint256 sharePerBlock;
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }

        uint256 withdrawnBlocks = unlockedBlock - startBlock;
        uint256 outstandingBlocks = endBlock - unlockedBlock;

        disbursement = amount / unlockPeriod * withdrawnBlocks;
        sharePerBlock = (amount - disbursement) / outstandingBlocks / swapRatio; 

        return (disbursement / swapRatio, sharePerBlock * outstandingBlocks);
    }

    /**
     * @dev Withdraw all unlocked shares.
     */
    function withdrawShare() public
    {
        require(allocations[msg.sender].lastWithdrawalBlock < endBlock, "All shares have already been claimed.");
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        uint256 tempLastWithdrawalBlock = allocations[msg.sender].lastWithdrawalBlock;
        allocations[msg.sender].lastWithdrawalBlock = unlockedBlock;                    // Avoid reentrancy
        uint256 unlockedShares = allocations[msg.sender].sharePerBlock * (unlockedBlock - tempLastWithdrawalBlock);
        GREEN.transfer(msg.sender, unlockedShares);

        emit Withdraw(msg.sender, unlockedShares);
    }

    /**
     * @dev Get the remaining balance of a shareholder's total outstanding shares.
     */
    function getOutstandingShares() external view returns(uint256)
    {
        return allocations[msg.sender].sharePerBlock * (endBlock - allocations[msg.sender].lastWithdrawalBlock);
    }

    /**
     * @dev Get the balance of a shareholder's claimable shares.
     */
    function getUnlockedShares() external view returns(uint256)
    {
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        return allocations[msg.sender].sharePerBlock * (unlockedBlock - allocations[msg.sender].lastWithdrawalBlock);
    }

    /**
     * @dev Get the withdrawn shares of a shareholder.
     */
    function getWithdrawnShares() external view returns(uint256)
    {
        return allocations[msg.sender].sharePerBlock * (allocations[msg.sender].lastWithdrawalBlock - startBlock);
    }
}