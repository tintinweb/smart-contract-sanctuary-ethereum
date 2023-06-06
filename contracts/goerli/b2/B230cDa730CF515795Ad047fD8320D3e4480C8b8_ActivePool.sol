// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Interfaces/IActivePool.sol";
import "./Interfaces/ICollSurplusPool.sol";
import "./Dependencies/ICollateralToken.sol";
import "./Dependencies/ERC3156FlashLender.sol";
import "./Dependencies/SafeERC20.sol";
import "./Dependencies/ReentrancyGuard.sol";
import "./Dependencies/AuthNoOwner.sol";

/**
 * The Active Pool holds the collateral and EBTC debt (but not EBTC tokens) for all active cdps.
 *
 * When a cdp is liquidated, it's collateral and EBTC debt are transferred from the Active Pool, to either the
 * Stability Pool, the Default Pool, or both, depending on the liquidation conditions.
 */
contract ActivePool is IActivePool, ERC3156FlashLender, ReentrancyGuard {
    using SafeERC20 for IERC20;
    string public constant NAME = "ActivePool";

    address public immutable borrowerOperationsAddress;
    address public immutable cdpManagerAddress;
    address public immutable collSurplusPoolAddress;
    address public feeRecipientAddress;

    uint256 internal StEthColl; // deposited collateral tracker
    uint256 internal EBTCDebt;
    uint256 internal FeeRecipientColl; // coll shares claimable by fee recipient
    ICollateralToken public collateral;

    // --- Contract setters ---

    /// @notice Constructor for the ActivePool contract
    /// @dev Initializes the contract with the borrowerOperationsAddress, cdpManagerAddress, collateral token address, collSurplusAddress, and feeRecipientAddress
    /// @param _borrowerOperationsAddress The address of the Borrower Operations contract
    /// @param _cdpManagerAddress The address of the Cdp Manager contract
    /// @param _collTokenAddress The address of the collateral token
    /// @param _collSurplusAddress The address of the collateral surplus pool
    /// @param _feeRecipientAddress The address of the fee recipient

    constructor(
        address _borrowerOperationsAddress,
        address _cdpManagerAddress,
        address _collTokenAddress,
        address _collSurplusAddress,
        address _feeRecipientAddress
    ) {
        borrowerOperationsAddress = _borrowerOperationsAddress;
        cdpManagerAddress = _cdpManagerAddress;
        collateral = ICollateralToken(_collTokenAddress);
        collSurplusPoolAddress = _collSurplusAddress;
        feeRecipientAddress = _feeRecipientAddress;

        // TEMP: read authority to avoid signature change
        address _authorityAddress = address(AuthNoOwner(cdpManagerAddress).authority());
        if (_authorityAddress != address(0)) {
            _initializeAuthority(_authorityAddress);
        }

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit CdpManagerAddressChanged(_cdpManagerAddress);
        emit CollateralAddressChanged(_collTokenAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusAddress);
        emit FeeRecipientAddressChanged(_feeRecipientAddress);
    }

    // --- Getters for public variables. Required by IPool interface ---

    /// @notice Amount of stETH collateral shares in the contract
    /// @dev Not necessarily equal to the the contract's raw StEthColl balance - tokens can be forcibly sent to contracts
    /// @return uint The amount of StEthColl allocated to the pool

    function getStEthColl() external view override returns (uint) {
        return StEthColl;
    }

    /// @notice Returns the EBTCDebt state variable
    /// @dev The amount of EBTC debt in the pool. Like StEthColl, this is not necessarily equal to the contract's EBTC token balance - tokens can be forcibly sent to contracts
    /// @return uint The amount of EBTC debt in the pool

    function getEBTCDebt() external view override returns (uint) {
        return EBTCDebt;
    }

    /// @notice The amount of stETH collateral shares claimable by the fee recipient
    /// @return uint The amount of collateral shares claimable by the fee recipient

    function getFeeRecipientClaimableColl() external view override returns (uint) {
        return FeeRecipientColl;
    }

    // --- Pool functionality ---

    /// @notice Sends stETH collateral shares to a specified account
    /// @dev Only for use by system contracts, the caller must be either BorrowerOperations or CdpManager
    /// @param _account The address of the account to send stETH to
    /// @param _shares The amount of stETH shares to send

    function sendStEthColl(address _account, uint _shares) public override {
        _requireCallerIsBOorCdpM();

        uint _StEthColl = StEthColl;
        require(_StEthColl >= _shares, "!ActivePoolBal");

        StEthColl = _StEthColl - _shares;

        emit ActivePoolCollBalanceUpdated(_StEthColl);
        emit CollateralSent(_account, _shares);

        _transferSharesWithContractHooks(_account, _shares);
    }

    /// @notice Sends stETH to a specified account, drawing from both core shares and liquidator rewards shares
    /// @notice Liquidator reward shares are not tracked via internal accounting in the active pool and are assumed to be present in expected amount as part of the intended behavior of BorowerOperations and CdpManager
    /// @dev Liquidator reward shares are added when a cdp is opened, and removed when it is closed
    /// @dev closeCdp() or liqudations result in the actor (borrower or liquidator respectively) receiving the liquidator reward shares
    /// @dev Redemptions result in the shares being sent to the coll surplus pool for claiming by the CDP owner
    /// @dev Note that funds in the coll surplus pool, just like liquidator reward shares, are not tracked as part of the system CR or coll of a CDP.
    /// @dev Requires that the caller is either BorrowerOperations or CdpManager
    /// @param _account The address of the account to send StEthColl and the liquidator reward to
    /// @param _shares The amount of StEthColl to send
    /// @param _liquidatorRewardShares The amount of the liquidator reward shares to send

    function sendStEthCollAndLiquidatorReward(
        address _account,
        uint _shares,
        uint _liquidatorRewardShares
    ) external override {
        _requireCallerIsBOorCdpM();

        uint _StEthColl = StEthColl;
        require(_StEthColl >= _shares, "ActivePool: Insufficient collateral shares");
        uint totalShares = _shares + _liquidatorRewardShares;

        StEthColl = _StEthColl - _shares;

        emit ActivePoolCollBalanceUpdated(_StEthColl);
        emit CollateralSent(_account, totalShares);

        _transferSharesWithContractHooks(_account, totalShares);
    }

    /// @notice Allocate stETH shares from the system to the fee recipient to claim at-will (pull model)
    /// @dev Requires that the caller is CdpManager
    /// @dev Only the current fee recipient address is able to claim the shares
    /// @dev If the fee recipient address is changed while outstanding claimable coll is available, only the new fee recipient will be able to claim the outstanding coll
    /// @param _shares The amount of StEthColl to allocate to the fee recipient

    function allocateFeeRecipientColl(uint _shares) external override {
        _requireCallerIsCdpManager();

        uint _StEthColl = StEthColl;
        uint _FeeRecipientColl = FeeRecipientColl;

        require(StEthColl >= _shares, "ActivePool: Insufficient collateral shares");

        StEthColl = _StEthColl - _shares;
        FeeRecipientColl = _FeeRecipientColl + _shares;

        emit ActivePoolCollBalanceUpdated(_StEthColl);
        emit ActivePoolFeeRecipientClaimableCollIncreased(FeeRecipientColl, _shares);
    }

    /// @notice Helper function to transfer stETH shares to another address, ensuring to call hooks into other system pools if they are the recipient
    /// @param _account The address to transfer shares to
    /// @param _shares The amount of shares to transfer

    function _transferSharesWithContractHooks(address _account, uint _shares) internal {
        // NOTE: No need for safe transfer if the collateral asset is standard. Make sure this is the case!
        collateral.transferShares(_account, _shares);

        if (_account == collSurplusPoolAddress) {
            ICollSurplusPool(_account).receiveColl(_shares);
        }
    }

    /// @notice Increases the tracked EBTC debt of the system by a specified amount
    /// @dev Managed by system contracts - requires that the caller is either BorrowerOperations or CdpManager
    /// @param _amount: The amount to increase the system EBTC debt by

    function increaseEBTCDebt(uint _amount) external override {
        _requireCallerIsBOorCdpM();

        uint _EBTCDebt = EBTCDebt;

        EBTCDebt = _EBTCDebt + _amount;
        emit ActivePoolEBTCDebtUpdated(_EBTCDebt);
    }

    /// @notice Decreases the tracked EBTC debt of the system by a specified amount
    /// @dev Managed by system contracts - requires that the caller is either BorrowerOperations or CdpManager
    /// @param _amount: The amount to decrease the system EBTC debt by

    function decreaseEBTCDebt(uint _amount) external override {
        _requireCallerIsBOorCdpM();

        uint _EBTCDebt = EBTCDebt;

        EBTCDebt = _EBTCDebt - _amount;
        emit ActivePoolEBTCDebtUpdated(_EBTCDebt);
    }

    // --- 'require' functions ---

    /// @notice Checks if the caller is BorrowerOperations
    function _requireCallerIsBorrowerOperations() internal view {
        require(
            msg.sender == borrowerOperationsAddress,
            "ActivePool: Caller is not BorrowerOperations"
        );
    }

    /// @notice Checks if the caller is either BorrowerOperations or CdpManager
    function _requireCallerIsBOorCdpM() internal view {
        require(
            msg.sender == borrowerOperationsAddress || msg.sender == cdpManagerAddress,
            "ActivePool: Caller is neither BorrowerOperations nor CdpManager"
        );
    }

    /// @notice Checks if the caller is CdpManager
    function _requireCallerIsCdpManager() internal view {
        require(msg.sender == cdpManagerAddress, "ActivePool: Caller is not CdpManager");
    }

    /// @notice Notify that stETH collateral shares have been recieved, updating internal accounting accordingly
    /// @param _value The amount of collateral to receive

    function receiveColl(uint _value) external override {
        _requireCallerIsBorrowerOperations();

        uint _StEthColl = StEthColl;
        StEthColl = _StEthColl + _value;
        emit ActivePoolCollBalanceUpdated(_StEthColl);
    }

    // === Flashloans === //

    /// @notice Borrow assets with a flash loan
    /// @param receiver The address to receive the flash loan
    /// @param token The address of the token to loan
    /// @param amount The amount of tokens to loan
    /// @param data Additional data
    /// @return A boolean value indicating whether the operation was successful

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external override returns (bool) {
        require(amount > 0, "ActivePool: 0 Amount");
        require(amount <= maxFlashLoan(token), "ActivePool: Too much");
        // NOTE: Check for `token` is implicit in the requires above

        uint256 fee = (amount * feeBps) / MAX_BPS;
        uint256 amountWithFee = amount + fee;
        uint256 oldRate = collateral.getPooledEthByShares(1e18);

        collateral.transfer(address(receiver), amount);

        // Callback
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == FLASH_SUCCESS_VALUE,
            "ActivePool: IERC3156: Callback failed"
        );

        // Transfer of (principal + Fee) from flashloan receiver
        collateral.transferFrom(address(receiver), address(this), amountWithFee);

        // Send earned fee to designated recipient
        collateral.transfer(feeRecipientAddress, fee);

        // Check new balance
        // NOTE: Invariant Check, technically breaks CEI but I think we must use it
        // NOTE: Must be > as otherwise you can self-destruct donate to brick the functionality forever
        // NOTE: This means any balance > StEthColl is stuck, this is also present in LUSD as is

        // NOTE: This check effectively prevents running 2 FL at the same time
        //  You technically could, but you'd be having to repay any amount below StEthColl to get Fl2 to not revert
        require(
            collateral.balanceOf(address(this)) >= collateral.getPooledEthByShares(StEthColl),
            "ActivePool: Must repay Balance"
        );
        require(collateral.sharesOf(address(this)) >= StEthColl, "ActivePool: Must repay Share");
        require(
            collateral.getPooledEthByShares(1e18) == oldRate,
            "ActivePool: Should keep same collateral share rate"
        );

        emit FlashLoanSuccess(address(receiver), token, amount, fee);

        return true;
    }

    /// @notice Calculate the flash loan fee for a given token and amount loaned
    /// @param token The address of the token to calculate the fee for
    /// @param amount The amount of tokens to calculate the fee for
    /// @return The amount of the flash loan fee

    function flashFee(address token, uint256 amount) external view override returns (uint256) {
        require(token == address(collateral), "ActivePool: collateral Only");

        return (amount * feeBps) / MAX_BPS;
    }

    /// @notice Get the maximum flash loan amount for a specific token
    /// @dev Exclusively used here for stETH collateral, equal to the current balance of the pool
    /// @param token The address of the token to get the maximum flash loan amount for
    /// @return The maximum flash loan amount for the token
    function maxFlashLoan(address token) public view override returns (uint256) {
        if (token != address(collateral)) {
            return 0;
        }

        return collateral.balanceOf(address(this));
    }

    // === Governed Functions === //

    /// @notice Claim outstanding shares for fee recipient, updating internal accounting and transferring the shares.
    /// @dev Call permissinos are managed via authority for flexibility, rather than gating call to just feeRecipient.
    /// @dev Is likely safe as an open permission though caution should be taken.
    /// @param _shares The amount of shares to claim to feeRecipient

    function claimFeeRecipientColl(uint _shares) external override requiresAuth {
        uint _FeeRecipientColl = FeeRecipientColl;
        require(_FeeRecipientColl >= _shares, "ActivePool: Insufficient fee recipient coll");

        FeeRecipientColl = _FeeRecipientColl - _shares;
        emit ActivePoolFeeRecipientClaimableCollDecreased(FeeRecipientColl, _shares);

        collateral.transferShares(feeRecipientAddress, _shares);
    }

    /// @dev Function to move unintended dust that are not protected
    /// @notice moves given amount of given token (collateral is NOT allowed)
    /// @notice because recipient are fixed, this function is safe to be called by anyone

    function sweepToken(address token, uint amount) public nonReentrant requiresAuth {
        require(token != address(collateral), "ActivePool: Cannot Sweep Collateral");

        uint256 balance = IERC20(token).balanceOf(address(this));
        require(amount <= balance, "ActivePool: Attempt to sweep more than balance");

        IERC20(token).safeTransfer(feeRecipientAddress, amount);

        emit SweepTokenSuccess(token, amount, feeRecipientAddress);
    }

    function setFeeRecipientAddress(address _feeRecipientAddress) external requiresAuth {
        require(
            _feeRecipientAddress != address(0),
            "ActivePool: cannot set fee recipient to zero address"
        );
        feeRecipientAddress = _feeRecipientAddress;
        emit FeeRecipientAddressChanged(_feeRecipientAddress);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity 0.8.17;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {Authority} from "./Authority.sol";

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Modified by BadgerDAO to remove owner
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
contract AuthNoOwner {
    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    Authority public authority;
    bool public authorityInitialized;

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "Auth: UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig));
    }

    function setAuthority(address newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(authority.canCall(msg.sender, address(this), msg.sig));

        authority = Authority(newAuthority);

        // Once authority is set once via any means, ensure it is initialized
        if (!authorityInitialized) {
            authorityInitialized = true;
        }

        emit AuthorityUpdated(msg.sender, Authority(newAuthority));
    }

    /// @notice Changed constructor to initialize to allow flexiblity of constructor vs initializer use
    /// @notice sets authorityInitiailzed flag to ensure only one use of
    function _initializeAuthority(address newAuthority) internal {
        require(address(authority) == address(0), "Auth: authority is non-zero");
        require(!authorityInitialized, "Auth: authority already initialized");

        authority = Authority(newAuthority);
        authorityInitialized = true;

        emit AuthorityUpdated(address(this), Authority(newAuthority));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(address user, address target, bytes4 functionSig) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../Interfaces/IERC3156FlashLender.sol";
import "../Interfaces/IWETH.sol";
import "./AuthNoOwner.sol";

abstract contract ERC3156FlashLender is IERC3156FlashLender, AuthNoOwner {
    // TODO: Fix / Finalize
    uint256 public constant MAX_BPS = 10_000;

    uint256 public feeBps = 50; // 50 BPS
    uint256 public maxFeeBps = 1_000; // 10%

    bytes32 public constant FLASH_SUCCESS_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");

    function setFeeBps(uint _newFee) external requiresAuth {
        require(_newFee <= maxFeeBps, "ERC3156FlashLender: _newFee should <= maxFeeBps");

        // set new flash fee
        uint _oldFee = feeBps;
        feeBps = _newFee;
        emit FlashFeeSet(msg.sender, _oldFee, _newFee);
    }

    function setMaxFeeBps(uint _newMaxFlashFee) external requiresAuth {
        require(_newMaxFlashFee <= MAX_BPS, "ERC3156FlashLender: _newMaxFlashFee should <= 10000");

        // set new max flash fee
        uint _oldMaxFlashFee = maxFeeBps;
        maxFeeBps = _newMaxFlashFee;
        emit MaxFlashFeeSet(msg.sender, _oldMaxFlashFee, _newMaxFlashFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC20.sol";

/**
 * Based on the stETH:
 *  -   https://docs.lido.fi/contracts/lido#
 */
interface ICollateralToken is IERC20 {
    // Returns the amount of shares that corresponds to _ethAmount protocol-controlled Ether
    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);

    // Returns the amount of Ether that corresponds to _sharesAmount token shares
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    // Moves `_sharesAmount` token shares from the caller's account to the `_recipient` account.
    function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256);

    // Returns the amount of shares owned by _account
    function sharesOf(address _account) external view returns (uint256);

    // Returns authorized oracle address
    function getOracle() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 internal constant OPEN = 1;
    uint256 internal constant LOCKED = 2;

    uint256 public locked = OPEN;

    modifier nonReentrant() virtual {
        require(locked == OPEN, "ReentrancyGuard: REENTRANCY");

        locked = LOCKED;

        _;

        locked = OPEN;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./Address.sol";

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        require(
            returndata.length == 0 || abi.decode(returndata, (bool)),
            "SafeERC20: ERC20 operation did not succeed"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IPool.sol";

interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event CdpManagerAddressChanged(address _newCdpManagerAddress);
    event ActivePoolEBTCDebtUpdated(uint _EBTCDebt);
    event ActivePoolCollBalanceUpdated(uint _coll);
    event CollateralAddressChanged(address _collTokenAddress);
    event FeeRecipientAddressChanged(address _feeRecipientAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusAddress);
    event ActivePoolFeeRecipientClaimableCollIncreased(uint _coll, uint _fee);
    event ActivePoolFeeRecipientClaimableCollDecreased(uint _coll, uint _fee);
    event FlashLoanSuccess(address _receiver, address _token, uint _amount, uint _fee);
    event SweepTokenSuccess(address _token, uint _amount, address _recipient);

    // --- Functions ---
    function sendStEthColl(address _account, uint _amount) external;

    function receiveColl(uint _value) external;

    function sendStEthCollAndLiquidatorReward(
        address _account,
        uint _shares,
        uint _liquidatorRewardShares
    ) external;

    function allocateFeeRecipientColl(uint _shares) external;

    function claimFeeRecipientColl(uint _shares) external;

    function feeRecipientAddress() external view returns (address);

    function getFeeRecipientClaimableColl() external view returns (uint);

    function setFeeRecipientAddress(address _feeRecipientAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ICollSurplusPool {
    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event CdpManagerAddressChanged(address _newCdpManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event CollateralAddressChanged(address _collTokenAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event CollateralSent(address _to, uint _amount);

    event SweepTokenSuccess(address _token, uint _amount, address _recipient);

    // --- Contract setters ---

    function getStEthColl() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;

    function receiveColl(uint _value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    event FlashFeeSet(address _setter, uint _oldFee, uint _newFee);
    event MaxFlashFeeSet(address _setter, uint _oldMaxFee, uint _newMaxFee);

    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Common interface for the Pools.
interface IPool {
    // --- Events ---

    event ETHBalanceUpdated(uint _newBalance);
    event EBTCBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event CollateralSent(address _to, uint _amount);

    // --- Functions ---

    function getStEthColl() external view returns (uint);

    function getEBTCDebt() external view returns (uint);

    function increaseEBTCDebt(uint _amount) external;

    function decreaseEBTCDebt(uint _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}