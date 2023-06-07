// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";


/**
 * @title Pawnfi's SAFE Contract
 * @author Pawnfi
 */
contract SAFE is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Seconds per week
    uint256 private constant WEEK = 604800;
    
    /**
     * @notice StreamData
     * @member start Start time
     * @member amount token amount
     * @member amount Withdrew amount
     */
    struct StreamData {
        uint256 start;
        uint256 amount;
        uint256 claimed;
    }

    /**
     * @notice Place info
     * @member weight Weight
     * @member displace Displace time
    */
    struct PlaceData {
        uint128 weight;
        uint128 displace;
    }

    // `weeklyTotalWeight` track the total place weight for each week,
    // calculated as the sum of [number of tokens] * [weeks to displace] for all active places.
    // The array index corresponds to the number of the epoch week.
    uint128[65535] public weeklyTotalWeight;

    /// @notice `weeklyPlaceData` tracks the total place weights and displacable token balances for each user.
    mapping(address => PlaceData[65535]) weeklyPlaceData;

    // `withdrawnUntil` tracks the most recent week for which each user has withdrawn their
    // expired token places. Displace values in `weeklyPlaceData` with an index less than the related
    // value within `withdrawnUntil` have already been withdrawn.
    mapping(address => uint256) withdrawnUntil;

    // After a place expires, a user calls to `initiateExitStream` and the withdrawable tokens
    // are streamed out linearly over the following week. This array is used to track data
    // related to the exit stream.
    mapping(address => StreamData) public exitStream;

    // when set to true, other accounts cannot call `place` on behalf of an account
    mapping(address => bool) public blockThirdPartyActions;

    /// @notice Staking token
    IERC20Upgradeable public stakingToken;

    /// @notice  Start time
    uint256 public startTime;

    /// @notice Set maximum place weeks
    uint256 public MAX_PLACE_WEEKS;
    
    /// @notice Emitted when place token
    event NewPlace(address indexed user, uint256 amount, uint256 placeWeeks);

    /// @notice Emitted when extend token place
    event ExtendPlace(address indexed user, uint256 amount, uint256 oldWeeks, uint256 newWeeks);

    /// @notice Emitted when create an exit stream
    event NewExitStream(address indexed user, uint256 startTime, uint256 amount);

    /// @notice Emitted when withdraw token
    event ExitStreamWithdrawal(address indexed user, uint256 claimed, uint256 remaining);

    constructor() initializer {}

    /**
     * @notice Initialize parameters
     * @param stakingToken_ Staking token address
     * @param startTime_ Start time
     * @param maxPlaceWeeks_ maximum place weeks
     */ 
    function initialize(IERC20Upgradeable stakingToken_, uint256 startTime_, uint256 maxPlaceWeeks_) external initializer {
        MAX_PLACE_WEEKS = maxPlaceWeeks_;
        require(IERC20MetadataUpgradeable(address(stakingToken_)).decimals() == 18);
        stakingToken = stakingToken_;
        // must start on the epoch week
        require((startTime_ / WEEK) * WEEK == startTime_, "!epoch week");
        startTime = startTime_;
    }

    /**
     * @notice Allow or block third-party calls to deposit, withdraw
                or claim rewards on behalf of the caller
     * @param newBlock When set to true, other accounts cannot call on behalf of the account `place`
     */
    function setBlockThirdPartyActions(bool newBlock) external {
        blockThirdPartyActions[msg.sender] = newBlock;
    }

    /**
     * @notice Get current weeks
     * @return uint256 current weeks
     */
    function getWeek() public view returns (uint256) {
        return (block.timestamp - startTime) / WEEK;
    }

    /**
     * @notice Get the current place weight for a user
     * @param user User address
     * @return uint256 Current weight of the user
     */
    function userWeight(address user) external view returns (uint256) {
        return weeklyWeightOf(user, getWeek());
    }

    /**
     * @notice Get the place weight for a user in a given week
     * @param user User address
     * @param week Week number
     * @return uint256 User's weight in the specified week
     */
    function weeklyWeightOf(address user, uint256 week) public view returns (uint256) {
        uint256 weight = uint256(weeklyPlaceData[user][week].weight);
        return weight;
    }

    /**
     * @notice Get the token balance that displaces for a user in a given week
     * @param user User address
     * @param week week number
     * @return uint256 The amount displaced in the specified week of the user
     */
    function weeklyDisplacesOf(address user, uint256 week) external view returns (uint256) {
        return uint256(weeklyPlaceData[user][week].displace);
    }

    /**
     * @notice Get the total balance held in this contract for a user,
                including both active and expired places
     * @param user user address
     * @return balance The token balance of the user in the specified week number       
     */
    function userBalance(address user) external view returns (uint256 balance) {
        uint256 i = withdrawnUntil[user] + 1;
        uint256 finish = getWeek() + MAX_PLACE_WEEKS + 1;
        while (i < finish) {
            balance += weeklyPlaceData[user][i].displace;
            i++;
        }
        return balance;
    }

    /**
     * @notice Get the current total place weight
     * @return uint256 Total weight of the current week
     */
    function totalWeight() external view returns (uint256) {
        return weeklyTotalWeight[getWeek()];
    }

    /**
     * @notice Get the user place weight and total place weight for the given week
     * @param user user address
     * @param week week number
     * @return uint256 User's weight in the specified week
     * @return uint256 Total weight in the specified week
     */
    function weeklyWeight(address user, uint256 week) external view returns (uint256, uint256) {
        return (weeklyWeightOf(user, week), weeklyTotalWeight[week]);
    }

    /**
     * @notice Get data on a user's active token places
     * @param user Address to query data for
     * @return placeData dynamic array of [weeks until expiration, balance of place]
     */
    function getActiveUserPlaces(address user) external view returns (uint256[2][] memory placeData) {
        uint256 length = 0;
        uint256 week = getWeek();
        uint256[] memory displaces = new uint256[](MAX_PLACE_WEEKS);
        for (uint256 i = 0; i < MAX_PLACE_WEEKS; i++) {
            displaces[i] = weeklyPlaceData[user][i + week + 1].displace;
            if (displaces[i] > 0) length++;
        }
        placeData = new uint256[2][](length);
        uint256 x = 0;
        for (uint256 i = 0; i < MAX_PLACE_WEEKS; i++) {
            if (displaces[i] > 0) {
                placeData[x] = [i + 1, displaces[i]];
                x++;
            }
        }
        return placeData;
    }

    /**
     * @notice Deposit tokens into the contract to create a new place.
     * @dev A place is created for a given number of weeks. Minimum 1, maximum `MAX_PLACE_WEEKS`.
             A user can have more than one place active at a time. A user's total "place weight"
             is calculated as the sum of [number of tokens] * [weeks until displace] for all
             active places. Fees are distributed porportionally according to a user's place
             weight as a percentage of the total place weight. At the start of each new week,
             each place's weeks until displace is reduced by 1. Places that reach 0 week no longer
             receive any weight, and tokens may be withdrawn by calling `initiateExitStream`.
     * @param user Address to create a new place for (does not have to be the caller)
     * @param amount Amount of tokens to place. This balance transfered from the caller.
     * @param placeWeeks The number of weeks for the place.
     */
    function place(address user, uint256 amount, uint256 placeWeeks) external returns (bool) {
        if (msg.sender != user) {
            require(!blockThirdPartyActions[user], "Cannot place on behalf of this account");
        }
        require(placeWeeks > 0, "Min 1 week");
        require(placeWeeks <= MAX_PLACE_WEEKS, "Exceeds MAX_PLACE_WEEKS");
        require(amount > 0, "Amount must be nonzero");

        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 start = getWeek();
        _increaseAmount(user, start, amount, placeWeeks, 0);

        uint256 end = start + placeWeeks;
        weeklyPlaceData[user][end].displace += uint128(amount);

        emit NewPlace(user, amount, placeWeeks);
        return true;
    }

    /**
     * @notice Extend the length of an existing place.
     * @param amount Amount of tokens to extend the place for. When the value given equals
                       the total size of the existing place, the entire place is moved.
                       If the amount is less, then the place is effectively split into
                       two places, with a portion of the balance extended to the new length
                       and the remaining balance at the old length.
     * @param replaceWeeks The number of weeks for the place that is being extended.
     * @param newWeeks The number of weeks to extend the place until.
     */
    function extendPlace(uint256 amount, uint256 replaceWeeks, uint256 newWeeks) external returns (bool) {
        require(replaceWeeks > 0, "Min 1 week");
        require(newWeeks <= MAX_PLACE_WEEKS, "Exceeds MAX_PLACE_WEEKS");
        require(replaceWeeks < newWeeks, "newWeeks must be greater than weeks");
        require(amount > 0, "Amount must be nonzero");

        PlaceData[65535] storage data = weeklyPlaceData[msg.sender];
        uint256 start = getWeek();
        uint256 end = start + replaceWeeks;
        data[end].displace -= uint128(amount);
        end = start + newWeeks;
        data[end].displace += uint128(amount);

        _increaseAmount(msg.sender, start, amount, newWeeks, replaceWeeks);
        emit ExtendPlace(msg.sender, amount, replaceWeeks, newWeeks);
        return true;
    }

    /**
     * @notice Create an exit stream, to withdraw tokens in expired places over 1 week
     */
    function initiateExitStream() external returns (bool) {
        StreamData storage stream = exitStream[msg.sender];
        uint256 streamable = streamableBalance(msg.sender);
        require(streamable > 0, "No withdrawable balance");

        uint256 amount = stream.amount - stream.claimed + streamable;
        exitStream[msg.sender] = StreamData({
            start: block.timestamp,
            amount: amount,
            claimed: 0
        });
        withdrawnUntil[msg.sender] = getWeek();

        emit NewExitStream(msg.sender, block.timestamp, amount);
        return true;
    }

    /**
     * @notice Withdraw tokens from an active or completed exit stream
     */
    function withdrawExitStream() external returns (bool) {
        StreamData storage stream = exitStream[msg.sender];
        uint256 amount;
        if (stream.start > 0) {
            amount = claimableExitStreamBalance(msg.sender);
            if (stream.start + WEEK < block.timestamp) {
                delete exitStream[msg.sender];
            } else {
                stream.claimed = stream.claimed + amount;
            }
            stakingToken.safeTransfer(msg.sender, amount);
        }
        emit ExitStreamWithdrawal(msg.sender, amount, stream.amount - stream.claimed);
        return true;
    }

    /**
     * @notice Get the amount of `stakingToken` in expired places that is
                eligible to be released via an exit stream.
     */
    function streamableBalance(address user) public view returns (uint256) {
        uint256 finishedWeek = getWeek();

        PlaceData[65535] storage data = weeklyPlaceData[user];
        uint256 amount;

        for (
            uint256 last = withdrawnUntil[user] + 1;
            last <= finishedWeek;
            last++
        ) {
            amount = amount + data[last].displace;
        }
        return amount;
    }

    /**
     * @notice Get the amount of tokens available to withdraw from the active exit stream.
    */
    function claimableExitStreamBalance(address user) public view returns (uint256) {
        StreamData storage stream = exitStream[user];
        if (stream.start == 0) return 0;
        if (stream.start + WEEK < block.timestamp) {
            return stream.amount - stream.claimed;
        } else {
            uint256 claimable = stream.amount * (block.timestamp - stream.start) / WEEK;
            return claimable - stream.claimed;
        }
    }

    /**
     * @dev Increase the amount within a place weight array over a given time period
     */
    function _increaseAmount(address user, uint256 start, uint256 amount, uint256 rounds, uint256 oldRounds) internal {
        uint256 oldEnd = start + oldRounds;
        uint256 end = start + rounds;
        PlaceData[65535] storage data = weeklyPlaceData[user];
        for (uint256 i = start; i < end; i++) {
            uint256 weight = amount * (end - i);
            if (i < oldEnd) {
                weight -= amount * (oldEnd - i);
            }
            weeklyTotalWeight[i] += uint128(weight);
            data[i].weight += uint128(weight);
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
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

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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