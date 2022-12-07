// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Utils.sol";
import "./StructureData.sol";
//import "hardhat/console.sol"; 

library OptionLifecycle {
    using SafeERC20 for IERC20;
    using Utils for uint128;
    using Utils for uint256;  
    using StructureData for StructureData.UserState; 

    //physical withdraw
    function withdraw(
        address _target,
        uint256 _amount,
        address _contractAddress
    ) external {
        require(_amount > 0, "!amt");
        if (
            _contractAddress ==
            address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
        ) {
            payable(_target).transfer(_amount);
        } else {
            IERC20(_contractAddress).safeTransfer(_target, _amount);
        }
    }
 
    function initiateWithrawStorage(
        StructureData.VaultState storage _vault,
        address _user,
        uint256 _amountToRedeem
    ) external {
        rollToNextRoundIfNeeded(_vault);
        require(_vault.currentRound > 1, "Nothing to redeem");

        StructureData.UserState storage state = _vault.userStates[_user]; 
        _vault.userStates[_user] = recalcState(
            _vault,
            state,
            _vault.currentRound
        );

        state = _vault.userStates[_user];

        uint256 maxInstantRedeemable =
            uint256(state.expiredAmount) - state.expiredQueuedRedeemAmount;
        uint256 maxRedeemable =
            maxInstantRedeemable + state.onGoingAmount -
                state.onGoingQueuedRedeemAmount;
        require(_amountToRedeem <= maxRedeemable, "Not enough to redeem");

        //check if the sold amount is expired or not
        //1. withdraw initiated before the sold option expired (buyer not providing the expiry level yet)
        //user could terminate all the sold options, and selling options
        //user would be able to redeem all the sold options after expiry and all the selling option after next expiry
        uint256 price =
            _vault.currentRound > 2
                ? _vault.depositPriceAfterExpiryPerRound[
                    _vault.currentRound - 2
                ]
                : 0;
         
        if (price == 0) {
            //first redeem from the sold options
            if (_amountToRedeem <= maxInstantRedeemable) {
                uint256 expiredQueuedRedeemAmount =
                    _amountToRedeem + state.expiredQueuedRedeemAmount;
                Utils.assertUint128(expiredQueuedRedeemAmount);
                state.expiredQueuedRedeemAmount = uint128(
                    expiredQueuedRedeemAmount
                );
                uint256 totalExpiredQueuedRedeemAmount =
                    _amountToRedeem + _vault.expired.queuedRedeemAmount;
                Utils.assertUint128(totalExpiredQueuedRedeemAmount);
                _vault.expired.queuedRedeemAmount = uint128(
                    totalExpiredQueuedRedeemAmount
                );
            } else {
                uint256 amountToRemdeemNextRound =
                    _amountToRedeem - maxInstantRedeemable;
                state.expiredQueuedRedeemAmount = state.expiredAmount;
                uint256 onGoingQueuedRedeemAmount =
                    amountToRemdeemNextRound +
                        state.onGoingQueuedRedeemAmount;
                Utils.assertUint128(onGoingQueuedRedeemAmount);
                state.onGoingQueuedRedeemAmount = uint128(
                    onGoingQueuedRedeemAmount
                );
                _vault.expired.queuedRedeemAmount = uint128(
                    uint256(_vault.expired.queuedRedeemAmount) + 
                        maxInstantRedeemable
                );
                _vault.onGoing.queuedRedeemAmount = uint128(
                    uint256(_vault.onGoing.queuedRedeemAmount) + 
                        amountToRemdeemNextRound
                );
            }
        }
        //2. withdraw initiated after the sold option expired (expiry level specified)
        //user could terminate all the selling options
        //user would be able to redeem all the selling options after next expiry
        else {
            uint256 onGoingQueuedRedeemAmount =
                _amountToRedeem + state.onGoingQueuedRedeemAmount;
            Utils.assertUint128(onGoingQueuedRedeemAmount);
            state.onGoingQueuedRedeemAmount = uint128(
                onGoingQueuedRedeemAmount
            );
            uint256 totalOnGoingQueuedRedeemAmount =
                _amountToRedeem + _vault.onGoing.queuedRedeemAmount;
            Utils.assertUint128(totalOnGoingQueuedRedeemAmount);
            _vault.onGoing.queuedRedeemAmount = uint128(
                totalOnGoingQueuedRedeemAmount
            );
        }
    }

    function cancelWithrawStorage(
        StructureData.VaultState storage _vault,
        address _user,
        uint256 _amountToRedeemToCancel
    ) external {
        rollToNextRoundIfNeeded(_vault);
        require(_vault.currentRound > 1, "Nothing to cancel redeem");

        StructureData.UserState storage state = _vault.userStates[_user];
        _vault.userStates[_user] = recalcState(
            _vault,
            state,
            _vault.currentRound
        );
        state = _vault.userStates[_user];

        uint256 expiredQueuedRedeemAmount = state.expiredQueuedRedeemAmount;
        uint256 onGoingQueuedRedeemAmount = state.onGoingQueuedRedeemAmount;
        require(
            _amountToRedeemToCancel <=
                expiredQueuedRedeemAmount + onGoingQueuedRedeemAmount,
            "Not enough to cancel redeem"
        );
        if (_amountToRedeemToCancel <= expiredQueuedRedeemAmount) {
            state.expiredQueuedRedeemAmount = uint128(
                expiredQueuedRedeemAmount - _amountToRedeemToCancel
            );
            _vault.expired.queuedRedeemAmount = uint128(
                uint256(_vault.expired.queuedRedeemAmount) - 
                    _amountToRedeemToCancel
            );
            return;
        }
        state.expiredQueuedRedeemAmount = 0;
        _vault.expired.queuedRedeemAmount = uint128(
            uint256(_vault.expired.queuedRedeemAmount) -
                expiredQueuedRedeemAmount
        );
        uint256 onGoingQueuedRedeeemAmountToCancel =
            _amountToRedeemToCancel - expiredQueuedRedeemAmount;
        state.onGoingQueuedRedeemAmount = uint128(
            onGoingQueuedRedeemAmount - onGoingQueuedRedeeemAmountToCancel
        );
        _vault.onGoing.queuedRedeemAmount = uint128(
            uint256(_vault.onGoing.queuedRedeemAmount) - 
                onGoingQueuedRedeeemAmountToCancel
        );
    }

    function withdrawStorage(
        StructureData.VaultState storage _vaultState,
        address _user,
        uint256 _amount
    ) external {
        rollToNextRoundIfNeeded(_vaultState);

        StructureData.UserState storage state = _vaultState.userStates[_user];
        _vaultState.userStates[_user] = recalcState(
            _vaultState,
            state,
            _vaultState.currentRound
        );
        state = _vaultState.userStates[_user];

        uint256 redeemed = state.redeemed;
        if (state.redeemed >= _amount) {
            state.redeemed = uint128(redeemed - _amount);
            _vaultState.totalRedeemed = uint128(
                uint256(_vaultState.totalRedeemed) - _amount
            );
            return;
        }

        //then withdraw the pending
        uint256 pendingAmountToWithdraw = _amount - redeemed;
        require(
            state.pending >= pendingAmountToWithdraw,
            "Not enough to withdraw"
        );
        _vaultState.totalRedeemed = uint128(
            uint256(_vaultState.totalRedeemed) - redeemed
        );
        _vaultState.totalPending = uint128(
            uint256(_vaultState.totalPending) - pendingAmountToWithdraw
        );
        state.redeemed = 0;
        state.pending = uint128(
            uint256(state.pending) - pendingAmountToWithdraw
        );
    }

    function depositFor(
        StructureData.VaultState storage _vaultState,
        address _user,
        uint256 _amount
    ) external {
        rollToNextRoundIfNeeded(_vaultState);

        StructureData.UserState storage state = _vaultState.userStates[_user]; 
        _vaultState.userStates[_user] = recalcState(
            _vaultState,
            state,
            _vaultState.currentRound
        );
        state = _vaultState.userStates[_user]; 

        uint256 newTVL =
            _amount
                 + _vaultState.totalPending
                 + _vaultState.onGoing.amount
                 + _vaultState.expired.amount
                 - _vaultState.expired.queuedRedeemAmount;
        uint256 newUserPending = _amount + state.pending;
        require(newTVL <= _vaultState.maxCapacity, "Exceeds capacity");
        Utils.assertUint128(newUserPending);
        state.pending = uint128(newUserPending);
        uint256 newTotalPending = _amount + _vaultState.totalPending;
        Utils.assertUint128(newTotalPending);
        _vaultState.totalPending = uint128(newTotalPending);
    }

    //calculate the real round number based on epoch period(vault round would only be physically updated when there is relevant chain operation) 
    function getRealRound(StructureData.VaultState storage _vaultState)
        public
        view
        returns (uint32, uint16)
    {
        if (
            _vaultState.cutOffAt > block.timestamp ||
            _vaultState.currentRound == 0
        ) {
            return (_vaultState.cutOffAt, _vaultState.currentRound);
        }
        uint256 cutOffAt = _vaultState.cutOffAt;
        uint256 currentRound = _vaultState.currentRound;
        while (cutOffAt <= block.timestamp) {
            currentRound++;
            uint32 nextStartOverride = _vaultState.nextPeriodStartOverrides[uint16(currentRound)]; 
            if (nextStartOverride != 0) {
                cutOffAt = nextStartOverride;
            }
            else {
                cutOffAt = uint256(_vaultState.periodLength) + cutOffAt;
            } 
            require(cutOffAt <= type(uint32).max, "Overflow cutOffAt");
        }
        return (uint32(cutOffAt), uint16(currentRound));
    }

    //physically update the vault data 
    function rollToNextRoundIfNeeded(
        StructureData.VaultState storage _vaultState
    ) public {
        if (
            _vaultState.cutOffAt > block.timestamp ||
            _vaultState.currentRound == 0
        ) {
            return;
        }
        (uint32 cutOffAt, uint16 currentRound) = getRealRound(_vaultState);
        uint256 lastUpdateRound = _vaultState.currentRound;
        uint256 pending = _vaultState.totalPending;
        _vaultState.totalPending = 0;
        while (lastUpdateRound < currentRound) {
            StructureData.OptionState memory onGoing = _vaultState.onGoing;

            _vaultState.onGoing = StructureData.OptionState({
                amount: uint128(pending),
                queuedRedeemAmount: 0,
                strike: 0,
                premiumRate: 0,
                buyerAddress: address(0)
            });
            pending = 0;
            //premium not sent, simply bring it to next round as if the buyer lost the premium
            if (lastUpdateRound > 1 && _vaultState.expired.amount > 0) {
                uint104 premiumRate =
                    _vaultState.expired.buyerAddress == address(0)
                        ? 0
                        : _vaultState.expired.premiumRate;
                uint256 expiredAmount =
                    uint256(_vaultState.expired.amount).withPremium(
                        premiumRate
                    );
                uint256 expiredRedeemAmount =
                    uint256(_vaultState.expired.queuedRedeemAmount).withPremium(
                        premiumRate
                    );
                uint256 onGoingAmount =
                    uint256(_vaultState.onGoing.amount) + expiredAmount - 
                        expiredRedeemAmount;
                Utils.assertUint128(onGoingAmount);
                _vaultState.onGoing.amount = uint128(onGoingAmount);
                uint256 totalRedeemed =
                    uint256(_vaultState.totalRedeemed) + expiredRedeemAmount;
                Utils.assertUint128(totalRedeemed);
                _vaultState.totalRedeemed = uint128(totalRedeemed);
                _vaultState.depositPriceAfterExpiryPerRound[
                    uint16(lastUpdateRound - 2)
                ] = premiumRate  >  0 ? (Utils.RATIOMULTIPLIER + premiumRate) : 0;
                _vaultState.expiryLevelSkipped[uint16(lastUpdateRound - 2)] = true;
            }
            _vaultState.expired = onGoing; 
            lastUpdateRound = lastUpdateRound + 1;
        }

        _vaultState.cutOffAt = cutOffAt;
        _vaultState.currentRound = currentRound;
    }

     //calculate the real vault state 
    function recalcVault(StructureData.VaultState storage _vaultState)
        public
        view
        returns (StructureData.VaultSnapShot memory)
    {
        StructureData.VaultSnapShot memory snapShot =
            StructureData.VaultSnapShot({
                totalPending: _vaultState.totalPending,
                totalRedeemed: _vaultState.totalRedeemed,
                cutOffAt: _vaultState.cutOffAt,
                currentRound: _vaultState.currentRound,
                maxCapacity: _vaultState.maxCapacity,
                onGoing: _vaultState.onGoing,
                expired: _vaultState.expired
            });
        if (
            _vaultState.cutOffAt > block.timestamp ||
            _vaultState.currentRound == 0
        ) {
            return snapShot;
        }

        (uint32 cutOffAt, uint16 currentRound) = getRealRound(_vaultState);
        uint256 lastUpdateRound = _vaultState.currentRound;
        while (lastUpdateRound < currentRound) {
            StructureData.OptionState memory onGoing = snapShot.onGoing;
            snapShot.onGoing = StructureData.OptionState({
                amount: snapShot.totalPending,
                queuedRedeemAmount: 0,
                strike: 0,
                premiumRate: 0,
                buyerAddress: address(0)
            });

            //premium not sent, simply bring it to next round
            if (lastUpdateRound > 1 && snapShot.expired.amount > 0) {
                uint104 premiumRate =
                    snapShot.expired.buyerAddress == address(0)
                        ? 0
                        : snapShot.expired.premiumRate;
                uint256 expiredAmount =
                    uint256(snapShot.expired.amount).withPremium(premiumRate);
                uint256 expiredRedeemAmount =
                    uint256(snapShot.expired.queuedRedeemAmount).withPremium(
                        premiumRate
                    );
                uint256 onGoingAmount =
                    uint256(snapShot.onGoing.amount) + expiredAmount - 
                        expiredRedeemAmount;
                Utils.assertUint128(onGoingAmount);
                snapShot.onGoing.amount = uint128(onGoingAmount);
                uint256 totalRedeemed =
                    uint256(snapShot.totalRedeemed) + expiredRedeemAmount;
                Utils.assertUint128(totalRedeemed);
                snapShot.totalRedeemed = uint128(totalRedeemed);
            }
            snapShot.expired = onGoing;
            snapShot.totalPending = 0;
            lastUpdateRound = lastUpdateRound + 1;
        }

        snapShot.totalPending = 0;
        snapShot.cutOffAt = cutOffAt;
        snapShot.currentRound = currentRound;
        return snapShot;
    }

    //both premiumRate and depositPriceAfterExpiryPerRound are using 8 decimals as ratio
    function getDepositPriceAfterExpiryPerRound(
        StructureData.VaultState storage _vaultState,
        uint16 _round,
        uint16 _latestRound
    ) internal view returns (uint256, bool) {
        uint256 price = _vaultState.depositPriceAfterExpiryPerRound[_round]; 
        //expiry level specified
        if (price > 0) return (price, !_vaultState.expiryLevelSkipped[_round]);
        //expiry level overdued, use premiumRate
        if (
            _latestRound > _round + 2 &&
            _vaultState.currentRound == _round + 1 &&
            _vaultState.onGoing.premiumRate > 0 &&
            _vaultState.onGoing.buyerAddress != address(0)
        ) {
            return (
                Utils.RATIOMULTIPLIER + _vaultState.onGoing.premiumRate,
                false
            );
        }
        if (
            _latestRound > _round + 2 &&
            _vaultState.currentRound == _round + 2 &&
            _vaultState.expired.premiumRate > 0 &&
            _vaultState.expired.buyerAddress != address(0)
        ) {
            return (
                Utils.RATIOMULTIPLIER + _vaultState.expired.premiumRate,
                false
            );
        }

        //aggregate preivous non-sold round with current sold-round
        if (
            _latestRound > _round + 1 &&
            _vaultState.currentRound == _round + 2 &&
            _vaultState.onGoing.buyerAddress != address(0) &&
            _vaultState.expired.buyerAddress == address(0)
        ) {
            return (Utils.RATIOMULTIPLIER, true);
        }
        return (0, false);
    }

    //calculate the real user state
    function recalcState(
        StructureData.VaultState storage _vaultState,
        StructureData.UserState storage _userState,
        uint16 _currentRound
    ) public view returns (StructureData.UserState memory) {
        uint256 onGoingAmount = _userState.onGoingAmount;
        uint256 expiredAmount = _userState.expiredAmount;
        uint256 expiredQueuedRedeemAmount =
            _userState.expiredQueuedRedeemAmount;
        uint256 onGoingQueuedRedeemAmount =
            _userState.onGoingQueuedRedeemAmount;
        uint256 lastUpdateRound = _userState.lastUpdateRound;
        uint256 pendingAmount = _userState.pending;
        uint256 redeemed = _userState.redeemed;
        bool expiredAmountCaculated = lastUpdateRound == _currentRound && _userState.expiredAmountCaculated;
        //catch up the userState with the latest
        //Basically it's by increasing/decreasing the onGoing amount based on each round's status.
        //expired amount is a temporary state for expiry level settlement
        //One time step a: accumulate pending to on-going once, and then clear it out
        //One time step b: accumulate expiredQueuedRedeemAmount to redeemed, reduce it from expired, and then clear it out
        //One time step c: copy onGoingQueuedRedeemAmount to expiredQueuedRedeemAmount, and then clear it out
        //Set on-going -> adjust expired -> accummulate expired to new on-going -> move old on-going to expired 
        if (lastUpdateRound > 2 && !_userState.expiredAmountCaculated) {
            (uint256 price, bool expiryLevelSpecified) =
                getDepositPriceAfterExpiryPerRound(
                    _vaultState,
                    uint16(lastUpdateRound - 2),
                    _currentRound
                );
            if (price > 0) {  
                if (expiredAmount > 0) {
                    expiredAmount = expiredAmount * price /
                        Utils.RATIOMULTIPLIER;
                    expiredQueuedRedeemAmount = expiredQueuedRedeemAmount
                         * price / Utils.RATIOMULTIPLIER;
                    if (expiryLevelSpecified) {
                        onGoingAmount = onGoingAmount + expiredAmount - 
                            expiredQueuedRedeemAmount;
                        expiredAmount = 0;                    
                        redeemed = redeemed + expiredQueuedRedeemAmount;
                        expiredQueuedRedeemAmount = 0;
                    } 
                } else { 
                    onGoingAmount = onGoingAmount * price /  
                        Utils.RATIOMULTIPLIER; 
                }
                if (lastUpdateRound == _currentRound) {
                    expiredAmountCaculated = true;
                }
            }
        }

        while (lastUpdateRound < _currentRound) {
            uint256 oldOnGoing = onGoingAmount;

            //set on-going
            //One time step a
            onGoingAmount = pendingAmount;
            pendingAmount = 0;

            onGoingAmount = onGoingAmount + expiredAmount - 
                expiredQueuedRedeemAmount;
            expiredAmount = oldOnGoing;

            //One time step b
            redeemed = redeemed + expiredQueuedRedeemAmount;

            //One time step c
            expiredQueuedRedeemAmount = onGoingQueuedRedeemAmount;
            onGoingQueuedRedeemAmount = 0;

            lastUpdateRound = lastUpdateRound + 1;

            if (lastUpdateRound <= 2) continue;
            (uint256 price, bool expiryLevelSpecified) =
                getDepositPriceAfterExpiryPerRound(
                    _vaultState,
                    uint16(lastUpdateRound - 2),
                    _currentRound
                );

            if (price > 0) { 
                if (expiredAmount > 0) {
                    expiredAmount = expiredAmount * price / 
                        Utils.RATIOMULTIPLIER;
                    expiredQueuedRedeemAmount = expiredQueuedRedeemAmount
                        * price / Utils.RATIOMULTIPLIER;
                    if (expiryLevelSpecified) {
                        onGoingAmount = onGoingAmount + expiredAmount -
                            expiredQueuedRedeemAmount;
                        expiredAmount = 0;                    
                        redeemed = redeemed + expiredQueuedRedeemAmount;
                        expiredQueuedRedeemAmount = 0;
                    } 

                } else {
                    if (
                        _userState.pending > 0 &&
                        _userState.lastUpdateRound == lastUpdateRound - 1
                    ) {
                        onGoingAmount = onGoingAmount - _userState.pending;
                    }
                    onGoingAmount = onGoingAmount * price /
                       Utils.RATIOMULTIPLIER;
                    if (
                        _userState.pending > 0 &&
                        _userState.lastUpdateRound == lastUpdateRound - 1
                    ) {
                        onGoingAmount = onGoingAmount + _userState.pending;
                    }
                } 
                if (lastUpdateRound == _currentRound) {
                    expiredAmountCaculated = true;
                }
            }
        }

        Utils.assertUint128(pendingAmount);
        Utils.assertUint128(redeemed);
        Utils.assertUint128(expiredAmount);
        Utils.assertUint128(expiredQueuedRedeemAmount);
        Utils.assertUint128(onGoingAmount);
        Utils.assertUint128(onGoingQueuedRedeemAmount);
        StructureData.UserState memory updatedUserState =
            StructureData.UserState({
                lastUpdateRound: _currentRound,
                pending: uint128(pendingAmount),
                redeemed: uint128(redeemed),
                expiredAmount: uint128(expiredAmount),
                expiredQueuedRedeemAmount: uint128(expiredQueuedRedeemAmount),
                onGoingAmount: uint128(onGoingAmount),
                onGoingQueuedRedeemAmount: uint128(onGoingQueuedRedeemAmount),
                expiredAmountCaculated: expiredAmountCaculated
            });

        return updatedUserState;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library StructureData { 
    
 
    //information that won't change
    struct VaultDefinition { 
        uint8 assetAmountDecimals; 
        address asset;
        address underlying; 
        bool callOrPut; //call for collateral -> stablecoin; put for stablecoin->collateral;  
    } 

    struct OptionState {
        uint128 amount; //total deposits
        uint128 queuedRedeemAmount;  //deposts stop autoroll into next round
        uint128 strike;
        uint104 premiumRate;
        address buyerAddress; 
    }
 
    struct VaultState { 
        uint128 totalPending; //deposits for queued round
        uint128 totalRedeemed; //redeemded but not withdrawn yet
        uint16 currentRound; //queued round number, start from 1 for first round
        uint32 cutOffAt;  //cut off time for next round
        uint32 periodLength; //default periodLength
        uint128 maxCapacity;  //max deposits to accept  

        StructureData.OptionState onGoing; //data for current round
        StructureData.OptionState expired;  //data for previous round when new epoch is started and expiry level not specified yet
        mapping(uint16 => uint32) nextPeriodStartOverrides; //default to to next friday 8:00am utc, if missing
        mapping(uint16 => uint256) depositPriceAfterExpiryPerRound; //how much per deposit worth by ratio for each expired round
        //is expiry level overdued? since if the expiry level is not specified within a whole epoch, the option becomes of no value by default
        mapping(uint16 => bool) expiryLevelSkipped; 
        //user deposit/withdraw states
        mapping(address=>StructureData.UserState) userStates;
        //whitelisted traders
        
    }
 
    
    //similar to VaultState
    struct UserState {
        uint128 pending;
        uint128 redeemed;
        uint128 expiredAmount;
        uint128 expiredQueuedRedeemAmount;
        uint128 onGoingAmount;
        uint128 onGoingQueuedRedeemAmount;
        uint16 lastUpdateRound; //last round number when user deposit/withdraw/redeem
        bool expiredAmountCaculated; //is the expiry level specified when last updated
    }
 
    //current vault state
    struct VaultSnapShot {
        uint128 totalPending; 
        uint128 totalRedeemed;
        uint32 cutOffAt;  
        uint16 currentRound;
        uint128 maxCapacity;   
        StructureData.OptionState onGoing;
        StructureData.OptionState expired;
    
    } 

     
    struct CollectableValue {
       address asset;
       uint256 amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
 
library Utils { 
     
    uint256 public constant ROUND_PRICE_DECIMALS = 10;
    uint256 public constant RATIOMULTIPLIER = 10 ** ROUND_PRICE_DECIMALS; 
    function getAmountToTerminate(uint256 _maturedAmount, uint256 _assetToTerminate, uint256 _assetAmount) 
    internal pure returns(uint256) {
       if (_assetToTerminate == 0 || _assetAmount == 0 || _maturedAmount == 0) return 0;
       return _assetToTerminate >= _assetAmount ?  _maturedAmount  : _maturedAmount * _assetToTerminate / _assetAmount;
   }

   function withPremium(uint256 _baseAmount, uint256 _premimumRate) internal pure returns(uint256) {
       return  _baseAmount * (RATIOMULTIPLIER + _premimumRate) / RATIOMULTIPLIER;
   }
   
   function premium(uint256 _baseAmount, uint256 _premimumRate) internal pure returns(uint256) {
       return   _baseAmount * _premimumRate / RATIOMULTIPLIER;
   }
   
   function subOrZero(uint256 _base, uint256 _substractor) internal pure returns (uint256) {
       return _base >= _substractor ? _base - _substractor : 0;
   }
  
    function assertUint104(uint256 num) internal pure {
        require(num <= type(uint104).max, "Overflow uint104");
    }

    function assertUint128(uint256 num) internal pure {
        require(num <= type(uint128).max, "Overflow uint128");
    }

}