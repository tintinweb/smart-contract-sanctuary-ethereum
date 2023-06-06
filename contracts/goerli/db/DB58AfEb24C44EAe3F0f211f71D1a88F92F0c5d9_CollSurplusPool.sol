// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./Interfaces/ICollSurplusPool.sol";
import "./Dependencies/ICollateralToken.sol";
import "./Dependencies/SafeERC20.sol";
import "./Dependencies/ReentrancyGuard.sol";
import "./Dependencies/AuthNoOwner.sol";
import "./Interfaces/IActivePool.sol";

contract CollSurplusPool is ICollSurplusPool, ReentrancyGuard, AuthNoOwner {
    using SafeERC20 for IERC20;

    string public constant NAME = "CollSurplusPool";

    address public immutable borrowerOperationsAddress;
    address public immutable cdpManagerAddress;
    address public immutable activePoolAddress;
    address public immutable feeRecipientAddress;
    ICollateralToken public immutable collateral;

    // deposited ether tracker
    uint256 internal StEthColl;
    // Collateral surplus claimable by cdp owners
    mapping(address => uint) internal balances;

    // --- Contract setters ---

    /**
     * @notice Sets the addresses of the contracts and renounces ownership
     * @dev One-time initialization function. Can only be called by the owner as a security measure. Ownership is renounced after the function is called.
     * @param _borrowerOperationsAddress The address of the BorrowerOperations
     * @param _cdpManagerAddress The address of the CDPManager
     * @param _activePoolAddress The address of the ActivePool
     * @param _collTokenAddress The address of the CollateralToken
     */
    constructor(
        address _borrowerOperationsAddress,
        address _cdpManagerAddress,
        address _activePoolAddress,
        address _collTokenAddress
    ) {
        borrowerOperationsAddress = _borrowerOperationsAddress;
        cdpManagerAddress = _cdpManagerAddress;
        activePoolAddress = _activePoolAddress;
        collateral = ICollateralToken(_collTokenAddress);
        feeRecipientAddress = IActivePool(activePoolAddress).feeRecipientAddress();

        address _authorityAddress = address(AuthNoOwner(cdpManagerAddress).authority());
        if (_authorityAddress != address(0)) {
            _initializeAuthority(_authorityAddress);
        }

        emit BorrowerOperationsAddressChanged(_borrowerOperationsAddress);
        emit CdpManagerAddressChanged(_cdpManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit CollateralAddressChanged(_collTokenAddress);
    }

    /**
     * @notice Gets the current collateral state variable of the pool
     * @dev Not necessarily equal to the raw collateral token balance - tokens can be forcibly sent to contracts
     * @return The current collateral balance tracked by the variable
     */
    function getStEthColl() external view override returns (uint) {
        return StEthColl;
    }

    /**
     * @notice Gets the collateral surplus available for the given account
     * @param _account The address of the account
     * @return The collateral balance available to claim
     */
    function getCollateral(address _account) external view override returns (uint) {
        return balances[_account];
    }

    // --- Pool functionality ---

    function accountSurplus(address _account, uint _amount) external override {
        _requireCallerIsCdpManager();

        uint newAmount = balances[_account] + _amount;
        balances[_account] = newAmount;

        emit CollBalanceUpdated(_account, newAmount);
    }

    function claimColl(address _account) external override {
        _requireCallerIsBorrowerOperations();
        uint claimableColl = balances[_account];
        require(claimableColl > 0, "CollSurplusPool: No collateral available to claim");

        balances[_account] = 0;
        emit CollBalanceUpdated(_account, 0);

        require(StEthColl >= claimableColl, "!CollSurplusPoolBal");
        StEthColl = StEthColl - claimableColl;
        emit CollateralSent(_account, claimableColl);

        // NOTE: No need for safe transfer if the collateral asset is standard. Make sure this is the case!
        collateral.transferShares(_account, claimableColl);
    }

    // --- 'require' functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(
            msg.sender == borrowerOperationsAddress,
            "CollSurplusPool: Caller is not Borrower Operations"
        );
    }

    function _requireCallerIsCdpManager() internal view {
        require(msg.sender == cdpManagerAddress, "CollSurplusPool: Caller is not CdpManager");
    }

    function _requireCallerIsActivePool() internal view {
        require(msg.sender == activePoolAddress, "CollSurplusPool: Caller is not Active Pool");
    }

    function receiveColl(uint _value) external override {
        _requireCallerIsActivePool();
        StEthColl = StEthColl + _value;
    }

    // === Governed Functions === //

    /// @dev Function to move unintended dust that are not protected
    /// @notice moves given amount of given token (collateral is NOT allowed)
    /// @notice because recipient are fixed, this function is safe to be called by anyone
    function sweepToken(address token, uint amount) public nonReentrant requiresAuth {
        require(token != address(collateral), "CollSurplusPool: Cannot Sweep Collateral");

        uint256 balance = IERC20(token).balanceOf(address(this));
        require(amount <= balance, "CollSurplusPool: Attempt to sweep more than balance");

        IERC20(token).safeTransfer(feeRecipientAddress, amount);

        emit SweepTokenSuccess(token, amount, feeRecipientAddress);
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