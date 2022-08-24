/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity ^0.7.6;
pragma abicoder v2;

// File: IERC20.sol

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: IGPv2Settlement.sol

interface IGPv2Settlement {
    function setPreSignature(bytes calldata orderUid, bool signed) external;

    function filledAmount(bytes calldata orderUid)
        external
        view
        returns (uint256);
}

// File: MilkmanStateHelper.sol

interface IMilkman {
    function swaps(bytes32 _swapID) external view returns (bytes memory);
}

/// @title Milkman State Helper
/// @dev Helper contract that can be used by off-chain bots to fetch the state of a Milkman swap.
contract MilkmanStateHelper {
    enum SwapState {
        NULL,
        REQUESTED,
        PAIRED,
        PAIRED_AND_UNPAIRABLE,
        PAIRED_AND_EXECUTED
    }

    IMilkman public constant milkman = IMilkman(0x3E40B8c9FcBf02a26Ff1c5d88f525AEd00755575);

    IGPv2Settlement internal constant settlement =
        IGPv2Settlement(0x9008D19f58AAbD9eD0D60971565AA8510560ab41);

    function getState(bytes32 _swapID) external view returns (SwapState) {
        bytes memory _swapData = milkman.swaps(_swapID);

        if (_swapData.length == 0) {
            return SwapState.NULL;
        } else if (_swapData.length == 32 && _swapData[31] == bytes1(uint8(1))) {
            return SwapState.REQUESTED;
        }

        (uint256 _blockNumberWhenPaired, bytes memory _orderUid) = abi.decode(
            _swapData,
            (uint256, bytes)
        );

        if (settlement.filledAmount(_orderUid) != 0) {
            return SwapState.PAIRED_AND_EXECUTED;
        } else if (block.number >= _blockNumberWhenPaired + 50) {
            return SwapState.PAIRED_AND_UNPAIRABLE;
        } else {
            return SwapState.PAIRED;
        }
    }
}