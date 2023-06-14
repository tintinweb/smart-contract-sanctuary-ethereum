//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./BalancerStrategyBase.sol";

import "../../interfaces/IStEth.sol";
import "../../interfaces/IWstEth.sol";
import "../../interfaces/IAura.sol";
import "../../interfaces/IFrxEthMinter.sol";

/**
 * @title A smart-contract that implements Balancer wstETH-sfrxETH-rETH pool strategy
 * and Aura staking.
 */
contract Balancer3EthAuraStrategy is BalancerStrategyBaseUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address public STAKING_TOKEN;

    address private BAL;
    address private AURA;

    address private WSTETH;
    address private STETH;
    address private SFRXETH;
    address private FRXETH;
    address private FRXETH_MINTER;

    bytes32 private WETH_WSTETH_ID;
    bytes32 private BAL_WETH_ID;
    bytes32 private AURA_WETH_ID;

    struct InitParams {
        address _BAL;
        address _AURA;
        address _WSTETH;
        address _STETH;
        address _SFRXETH;
        address _FRXETH;
        address _FRXETH_MINTER;
        bytes32 _WETH_WSTETH_ID;
        bytes32 _BAL_WETH_ID;
        bytes32 _AURA_WETH_ID;
    }

    function __Balancer3EthAuraStrategy_init_unchained(
        InitParams memory initParams
    ) internal initializer {
        BAL = initParams._BAL;
        AURA = initParams._AURA;
        WSTETH = initParams._WSTETH;
        STETH = initParams._STETH;
        SFRXETH = initParams._SFRXETH;
        FRXETH = initParams._FRXETH;
        FRXETH_MINTER = initParams._FRXETH_MINTER;
        WETH_WSTETH_ID = initParams._WETH_WSTETH_ID;
        BAL_WETH_ID = initParams._BAL_WETH_ID;
        AURA_WETH_ID = initParams._AURA_WETH_ID;
    }

    function __Balancer3EthAuraStrategy_init(
        BaseInitParams memory baseInitParams,
        InitParams memory initParams
    ) public initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __BalancerStrategyBase_init_unchained(baseInitParams);
        __Balancer3EthAuraStrategy_init_unchained(initParams);

        exitKind = IBalancerVault
            .ExitKind
            .EXACT_BPT_IN_FOR_ALL_TOKENS_OUT;

        joinKind = IBalancerVault
            .JoinKind
            .EXACT_TOKENS_IN_FOR_BPT_OUT;
    }

    /**
     * @dev Withdraws and unstakes a certain amount of tokens from the staking contract.
     * @param amount The amount of tokens to unstake.
     */
    function _unstake(uint256 amount) internal override {
        IAura(STAKING).withdrawAndUnwrap(amount, true);
    }

    /**
     * @dev Stakes a certain amount of tokens into the staking contract.
     * @param amount The amount of tokens to stake.
     */
    function _stake(uint256 amount) internal override {
        IERC20Upgradeable(WANT).safeIncreaseAllowance(STAKING, amount);
        IAura(STAKING).deposit(amount, address(this));
    }

    /**
     * @dev Claims rewards from the staking contract.
     * @return amounts An array with the amounts of each reward token.
     */
    function _claim()
        internal
        virtual
        override
        returns (uint256[] memory amounts)
    {
        IAura(STAKING).getReward(address(this), true);

        amounts = new uint256[](rewards.length);
        for (uint256 i = 0; i < rewards.length; i++) {
            amounts[i] = IERC20Upgradeable(rewards[i].token).balanceOf(
                address(this)
            );
        }
    }

    /**
     * @dev Performs pre-processing for deposit operations.
     * @param token The token to be deposited.
     * @param amount The amount of tokens to deposit.
     * @return The amount to be processed.
     */
    function _preProcessIn(
        address token,
        uint256 amount,
        uint256 minAmountOut
    ) internal override returns (uint256) {
        if (token == WSTETH) {
            IWETH(WETH).withdraw(amount);
            uint256 amountOut = IStEth(STETH).submit{
                value: address(this).balance
            }(address(0));
            IERC20Upgradeable(STETH).safeIncreaseAllowance(WSTETH, amountOut);

            return IWstEth(WSTETH).wrap(amountOut);
        }
        if (token == SFRXETH) {
            IWETH(WETH).withdraw(amount);
            IERC20Upgradeable(SFRXETH).safeIncreaseAllowance(
                FRXETH_MINTER,
                amount
            );

            return
                IFrxEthMinter(FRXETH_MINTER).submitAndDeposit{
                    value: address(this).balance
                }(address(this));
        }

        return 0;
    }

    /**
     * @dev Performs pre-processing for withdrawal operations.
     * @param token The token to be withdrawn.
     * @param amount The amount of tokens to withdraw.
     * @param minAmountOut The minimum acceptable amount to be withdrawn.
     * @return The amount to be processed.
     */
    function _preProcessOut(
        address token,
        uint256 amount,
        uint256 minAmountOut
    ) internal override returns (uint256) {
        if (token == WSTETH) {
            uint256 amountOut = _balancerSwapSingle(
                WETH,
                WSTETH,
                amount,
                minAmountOut,
                WETH_WSTETH_ID
            );

            return amountOut;
        }
        if (token == SFRXETH) {
            uint256 amountOutWsteth = _balancerSwapSingle(
                WSTETH,
                SFRXETH,
                amount,
                minAmountOut,
                WANT_POOL_ID
            );

            uint256 amountOut = _balancerSwapSingle(
                WETH,
                WSTETH,
                amountOutWsteth,
                0,
                WETH_WSTETH_ID
            );

            return amountOut;
        }

        return 0;
    }

    /**
     * @dev Pre-processes amounts for reward calculation.
     * @param reward The reward to be processed.
     * @param amount The amount of reward tokens.
     * @return The processed amount.
     */
    function _preProcessAmounts(
        Reward memory reward,
        uint256 amount
    ) internal override returns (uint256) {
        if (reward.token == BAL) {
            return _getAmountOutBal(amount, reward.token, WETH, BAL_WETH_ID);
        }
        if (reward.token == AURA) {
            return _getAmountOutBal(amount, reward.token, WETH, AURA_WETH_ID);
        }

        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error OnlyNonZeroAddress();

abstract contract CheckerZeroAddr is Initializable {
    modifier onlyNonZeroAddress(address addr) {
        _onlyNonZeroAddress(addr);
        _;
    }

    function __CheckerZeroAddr_init_unchained() internal onlyInitializing {}

    function _onlyNonZeroAddress(address addr) private pure {
        if (addr == address(0)) {
            revert OnlyNonZeroAddress();
        }
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./CheckerZeroAddr.sol";

abstract contract Timelock is
    Initializable,
    ContextUpgradeable,
    CheckerZeroAddr
{
    struct Transaction {
        address dest;
        uint256 value;
        string signature;
        bytes data;
        uint256 exTime;
    }

    enum ProccessType {
        ADDED,
        REMOVED,
        COMPLETED
    }

    /// @notice This event is emitted wwhen something happens with a transaction.
    /// @param transaction information about transaction
    /// @param proccessType action type
    event ProccessTransaction(
        Transaction transaction,
        ProccessType indexed proccessType
    );

    /// @notice error about that the set time is less than the delay
    error MinDelay();

    /// @notice error about that the transaction does not exist
    error NonExistTransaction();

    /// @notice error about that the minimum interval has not passed
    error ExTimeLessThanNow();

    /// @notice error about that the signature is null
    error NullSignature();

    /// @notice error about that the calling transaction is reverted
    error TransactionExecutionReverted(string revertReason);

    uint256 public constant DELAY = 2 days;

    mapping(bytes32 => bool) public transactions;

    modifier onlyInternalCall() {
        _onlyInternalCall();
        _;
    }

    function _addTransaction(
        Transaction memory transaction
    ) internal onlyNonZeroAddress(transaction.dest) returns (bytes32) {
        if (transaction.exTime < block.timestamp + DELAY) {
            revert MinDelay();
        }

        if (bytes(transaction.signature).length == 0) {
            revert NullSignature();
        }

        bytes32 txHash = _getHash(transaction);

        transactions[txHash] = true;

        emit ProccessTransaction(transaction, ProccessType.ADDED);

        return txHash;
    }

    function _removeTransaction(Transaction memory transaction) internal {
        bytes32 txHash = _getHash(transaction);

        transactions[txHash] = false;

        emit ProccessTransaction(transaction, ProccessType.REMOVED);
    }

    function _executeTransaction(
        Transaction memory transaction
    ) internal returns (bytes memory) {
        bytes32 txHash = _getHash(transaction);

        if (!transactions[txHash]) {
            revert NonExistTransaction();
        }

        if (block.timestamp < transaction.exTime) {
            revert ExTimeLessThanNow();
        }

        transactions[txHash] = false;

        bytes memory callData = abi.encodePacked(
            bytes4(keccak256(bytes(transaction.signature))),
            transaction.data
        );
        (bool success, bytes memory result) = transaction.dest.call{
            value: transaction.value
        }(callData);

        if (!success) {
            revert TransactionExecutionReverted(string(result));
        }

        emit ProccessTransaction(transaction, ProccessType.COMPLETED);

        return result;
    }

    function __Timelock_init_unchained() internal onlyInitializing {}

    function _onlyInternalCall() internal view {
        require(_msgSender() == address(this), "Timelock: only internal call");
    }

    function _getHash(
        Transaction memory transaction
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    transaction.dest,
                    transaction.value,
                    transaction.signature,
                    transaction.data,
                    transaction.exTime
                )
            );
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/ITokensRescuer.sol";

import "./CheckerZeroAddr.sol";

abstract contract TokensRescuer is
    Initializable,
    ITokensRescuer,
    CheckerZeroAddr
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function __TokensRescuer_init_unchained() internal onlyInitializing {}

    function _rescueNativeToken(
        uint256 amount,
        address receiver
    ) internal onlyNonZeroAddress(receiver) {
        AddressUpgradeable.sendValue(payable(receiver), amount);
    }

    function _rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) internal virtual onlyNonZeroAddress(receiver) onlyNonZeroAddress(token) {
        IERC20Upgradeable(token).safeTransfer(receiver, amount);
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IAsset {
    //  empty,  serves as an "abstract" interface for assets.
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBalancerVault.sol";

interface IAura {
    function stake(
        uint256 amount
    ) external;

    function withdrawAndUnwrap(
        uint256 amount,
        bool claim
    ) external;

    function getReward(address _account, bool _extras) external returns (bool);

    function deposit(uint256 assets, address receiver) external returns (uint256);

    function earned(address _account) external view returns (uint256);

    function balanceOf(address _account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalCliffs() external view returns (uint256);

    function reductionPerCliff() external view returns (uint256);

    function EMISSIONS_MAX_SUPPLY() external view returns (uint256);

    function rewardRate() external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IAsset.sol";

interface IBalancerVault {
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT
    }
    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        EXACT_BPT_IN_FOR_ALL_TOKENS_OUT
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }
    enum UserBalanceOpKind {
        DEPOSIT,
        WITHDRAW,
        TRANSFER,
        INTERNAL_TRANSFER,
        WITHDRAW_INTERNAL
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct UserBalanceOp {
        bytes32 poolId;
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest calldata request
    ) external;

    function exitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        ExitPoolRequest calldata request
    ) external;

    function swap(
        SingleSwap calldata singleSwap,
        FundManagement calldata funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external returns (int256[] memory assetDeltas);

    function getPoolTokens(
        bytes32 poolId
    )
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    function manageUserBalance(UserBalanceOp[] calldata ops) external;
}

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../interfaces/IBalancerVault.sol";

interface IBalancerWrapper {
    struct Asset {
        address token;
        bytes queryIn;
        bytes queryOut;
    }

    function swapSingle(
        address tokenOut,
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes32 poolId,
        uint256 deadline
    ) external returns (uint256);

    function join(
        uint256[] memory amounts,
        bytes32 poolId,
        address WANT,
        Asset[] memory assets,
        IBalancerVault.JoinKind joinKind
    ) external returns (uint256);

    function exit(
        uint256 amount,
        uint256[] memory minAmountsOut,
        bytes32 poolId,
        address WANT,
        Asset[] memory assets,
        IBalancerVault.ExitKind exitKind
    ) external returns (uint256[] memory);

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        bytes32 poolId
    ) external returns (uint256);
}

pragma solidity 0.8.15;

interface IFrxEthMinter {
    function submitAndDeposit(address recipient) external payable returns (uint256 shares);

    function currentWithheldETH() external view returns (uint256);
}

//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

pragma solidity 0.8.15;

interface IParallax {
    /**
     * @notice Represents a single strategy with its relevant data.
     */
    struct Strategy {
        uint256 fee;
        uint256 totalStaked;
        uint256 totalShares;
        uint256 lastCompoundTimestamp;
        uint256 cap;
        uint256 rewardPerBlock;
        uint256 rewardPerShare;
        uint256 lastUpdatedBlockNumber;
        address strategy;
        uint32 timelock;
        bool isActive;
        IERC20Upgradeable rewardToken;
        uint256 usersCount;
    }

    /// @notice The view method for getting current feesReceiver.
    function feesReceiver() external view returns (address);

    /**
     * @notice The view method for getting current withdrawal fee by strategy.
     * @param strategy An address of a strategy.
     * @return Withdrawal fee.
     **/
    function getFee(address strategy) external view returns (uint256);

    /** @notice Returns the ID of the NFT owned by the specified user at the
     *           given index.
     *  @param user The address of the user who owns the NFT.
     *  @param index The index of the NFT to return.
     *  @return The ID of the NFT at the given index, owned by the specified
     *          user.
     */
    function getNftByUserAndIndex(
        address user,
        uint256 index
    ) external view returns (uint256);

    /**
     * @notice The view method to check if the token is in the whitelist.
     * @param strategy An address of a strategy.
     * @param token An address of a token to check.
     * @return Boolean flag.
     **/
    function tokensWhitelist(
        address strategy,
        address token
    ) external view returns (bool);
}

//SPDX-License-Identifier: MIT

import "../extensions/Timelock.sol";

import "./IParallax.sol";
import "./IParallaxStrategy.sol";

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

pragma solidity 0.8.15;

interface IParallaxOrbital is IParallax {
    /**
     * @param params parameters for deposit.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *               paths - paths that will be used during swaps.
     *               strategyId - an ID of an earning strategy.
     *               holder - user to whose address the deposit is made.
     *               positionId - id of the position.
     *               amounts - array of amounts to deposit.
     *               data - additional data for strategy.
     */
    struct DepositParams {
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 strategyId;
        address holder;
        uint256 positionId;
        uint256[] amounts;
        bytes[] data;
    }

    /**
     * @param params parameters for withdraw.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *               paths - paths that will be used during swaps.
     *               strategyId - an ID of an earning strategy.
     *               positionId - id of the position.
     *               earned - earnings for the current number of shares.
     *               amounts - array of amounts to deposit.
     *               receiver - address of the user who will receive
     *                          the withdrawn assets.
     *               data - additional data for strategy.
     */
    struct WithdrawParams {
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 strategyId;
        uint256 positionId;
        uint256 shares;
        address receiver;
        bytes[] data;
    }

    /**
     * @notice Represents a single user's position in a strategy.
     */
    struct UserPosition {
        uint256 tokenId;
        uint256 shares;
        uint256 deposited;
        uint256 lastStakedBlockNumber;
        uint256 reward;
        uint256 former;
        uint32 lastStakedTimestamp;
        bool created;
        bool closed;
    }

    /**
     * @notice Represents a single user's position in a strategy.
     * @dev holder address can be obtained from contract erc721
     */
    struct TokenInfo {
        uint256 strategyId;
        uint256 positionId;
    }

    /**
     * @notice Deposit params with compoundAmountsOutMin.
     */
    struct DepositAndCompoundParams {
        uint256[] compoundAmountsOutMin;
        DepositParams depositParams;
    }

    /**
     * @notice Withdraw params with compoundAmountsOutMin.
     */
    struct WithdrawAndCompoundParams {
        uint256[] compoundAmountsOutMin;
        WithdrawParams withdrawParams;
    }

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param positionId - an ID of a position.
     * @param user - a user who makes a staking.
     * @param amount - amount of staked tokens.
     * @param shares - fraction of the user's contribution
     * (calculated from the deposited amount and the total number of tokens)
     */
    event Staked(
        uint256 indexed strategyId,
        uint256 indexed positionId,
        address user,
        address indexed holder,
        uint256 amount,
        uint256 shares
    );

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param positionId - an ID of a position.
     * @param user - a user who makes a withdrawal.
     * @param amount - amount of staked tokens (calculated from input shares).
     * @param shares - fraction of the user's contribution.
     */
    event Withdrawn(
        uint256 indexed strategyId,
        uint256 indexed positionId,
        address indexed user,
        address receiver,
        uint256 amount,
        uint256 currentFee,
        uint256 shares
    );

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param blockNumber - block number in which the compound was made.
     * @param user - a user who makes compound.
     * @param amount - amount of staked tokens (calculated from input shares).
     */
    event Compounded(
        uint256 indexed strategyId,
        uint256 indexed blockNumber,
        address indexed user,
        uint256 amount
    );

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param positionId - an ID of a position.
     * @param user - a user for whom the position was created.
     * @param blockNumber - block number in which the position was created.
     */
    event PositionCreated(
        uint256 indexed strategyId,
        uint256 indexed positionId,
        address indexed user,
        uint256 blockNumber
    );

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param positionId - an ID of a position.
     * @param user - a user whose position is closed.
     * @param blockNumber - block number in which the position was closed.
     */
    event PositionClosed(
        uint256 indexed strategyId,
        uint256 indexed positionId,
        address indexed user,
        uint256 blockNumber
    );

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param from - who sent the position.
     * @param fromPositionId - sender position ID.
     * @param to - recipient.
     * @param toPositionId - id of recipient's position.
     */
    event PositionTransferred(
        uint256 indexed strategyId,
        address indexed from,
        uint256 fromPositionId,
        address indexed to,
        uint256 toPositionId
    );

    /**
     * @dev Whitelists a new token that can be accepted as the token for
     *      deposits and withdraws. Can only be called by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param token An ddress of a new token to add.
     */
    function addToken(uint256 strategyId, address token) external;

    /**
     * @dev Removes a token from a whitelist of tokens that can be accepted as
     *      the tokens for deposits and withdraws. Can only be called by the
     *      current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param token A token to remove.
     */
    function removeToken(uint256 strategyId, address token) external;

    /**
     * @dev Registers a new earning strategy on this contract. An earning
     *      strategy must be deployed before the calling of this method. Can
     *      only be called by the current owner.
     * @param strategy An address of a new earning strategy that should be added.
     * @param timelock A number of seconds during which users can't withdraw
     *                 their deposits after last deposit. Applies only for
     *                 earning strategy that is adding. Can be updated later.
     * @param cap A cap for the amount of deposited LP tokens.
     * @param rewardPerBlock A reward amount that will be distributed between
     *                       all users in a strategy every block. Can be updated
     *                       later.
     * @param initialFee A fees that will be applied for earning strategy that
     *                    is adding. Currently only withdrawal fee is supported.
     *                    Applies only for earning strategy that is adding. Can
     *                    be updated later. Each fee should contain 2 decimals:
     *                    5 = 0.05%, 10 = 0.1%, 100 = 1%, 1000 = 10%.
     *  @param rewardToken A reward token in which rewards will be paid. Can be
     *                     updated later.
     */
    function addStrategy(
        address strategy,
        uint32 timelock,
        uint256 cap,
        uint256 rewardPerBlock,
        uint256 initialFee,
        IERC20Upgradeable rewardToken,
        bool isActive
    ) external;

    /**
     * @dev Sets a new receiver for fees from all earning strategies. Can only
     *      be called by the current owner.
     * @param newFeesReceiver A wallet that will receive fees from all earning
     *                        strategies.
     */
    function setFeesReceiver(address newFeesReceiver) external;

    /**
     * @dev Sets a new fees for an earning strategy. Can only be called by the
     *      current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param newFee Fee that will be applied for earning strategy. Fee should contain
     *                2 decimals: 5 = 0.05%, 10 = 0.1%, 100 = 1%, 1000 = 10%.
     */
    function setFee(uint256 strategyId, uint256 newFee) external;

    /**
     * @dev Sets a timelock for withdrawals (in seconds). Timelock - period
     *      during which user is not able to make a withdrawal after last
     *      successful deposit. Can only be called by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param timelock A new timelock for withdrawals (in seconds).
     */
    function setTimelock(uint256 strategyId, uint32 timelock) external;

    /**
     * @dev Setups a reward amount that will be distributed between all users
     *      in a strategy every block. Can only be called by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param newRewardToken A new reward token in which rewards will be paid.
     */
    function setRewardToken(
        uint256 strategyId,
        IERC20Upgradeable newRewardToken
    ) external;

    /**
     * @dev Sets a new cap for the amount of deposited LP tokens. A new cap must
     *      be more or equal to the amount of staked LP tokens. Can only be
     *      called by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param cap A new cap for the amount of deposited LP tokens which will be
     *            applied for earning strategy.
     */
    function setCap(uint256 strategyId, uint256 cap) external;

    /**
     * @dev Sets a value for an earning strategy (in reward token) after which
     *      compound must be executed. The compound operation is performed
     *      during every deposit and withdrawal. And sometimes there may not be
     *      enough reward tokens to complete all the exchanges and liquidity
     *      additions. As a result, deposit and withdrawal transactions may
     *      fail. To avoid such a problem, this value is provided. And if the
     *      number of rewards is even less than it, compound does not occur.
     *      As soon as there are more of them, a compound immediately occurs in
     *      time of first deposit or withdrawal. Can only be called by the
     *      current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param compoundMinAmount A value in reward token after which compound
     *                          must be executed.
     */
    function setCompoundMinAmount(
        uint256 strategyId,
        uint256 compoundMinAmount
    ) external;

    /**
     * @notice Setups a reward amount that will be distributed between all users
     *         in a strategy every block. Can only be called by the current
     *         owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param rewardPerBlock A new reward per block.
     */
    function setRewardPerBlock(
        uint256 strategyId,
        uint256 rewardPerBlock
    ) external;

    /**
     * @notice Setups a strategy status. Sets permission or prohibition for
     *         depositing funds on the strategy. Can only be called by the
     *         current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param flag A strategy status. `false` - not active, `true` - active.
     */
    function setStrategyStatus(uint256 strategyId, bool flag) external;

    /**
     * @notice Accepts deposits from users. This method accepts ERC-20 LP tokens
     *         that will be used in earning strategy. Appropriate amount of
     *         ERC-20 LP tokens must be approved for earning strategy in which
     *         it will be deposited. Can be called by anyone.
     * @param params A parameters for deposit (for more details see a
     *                      specific earning strategy).
     */
    function depositLPs(DepositAndCompoundParams memory params) external;

    /**
     * @notice Accepts deposits from users. This method accepts a group of
     *         different ERC-20 tokens in equal part that will be used in
     *         earning strategy (for more detail s see the specific earning
     *         strategy documentation). Appropriate amount of all ERC-20 tokens
     *         must be approved for earning strategy in which it will be
     *         deposited. Can be called by anyone.
     * @param params A parameters for deposit (for more details see a
     *                      specific earning strategy).
     */
    function depositTokens(DepositAndCompoundParams memory params) external;

    /**
     * @notice Accepts deposits from users. This method accepts ETH tokens that
     *         will be used in earning strategy. ETH tokens must be attached to
     *         the transaction. Can be called by anyone.
     * @param params A parameters for deposit (for more details see a
     *                      specific earning strategy).
     */
    function depositAndSwapNativeToken(
        DepositAndCompoundParams memory params
    ) external payable;

    /**
     * @notice Accepts deposits from users. This method accepts any whitelisted
     *         ERC-20 tokens that will be used in earning strategy. Appropriate
     *         amount of ERC-20 tokens must be approved for earning strategy in
     *         which it will be deposited. Can be called by anyone.
     * @param params A parameters parameters for deposit (for more
     *                      details see a specific earning strategy).
     */
    function depositAndSwapERC20Token(
        DepositAndCompoundParams memory params
    ) external;

    /**
     * @notice A withdraws users' deposits + reinvested yield. This method
     *         allows to withdraw ERC-20 LP tokens that were used in earning
     *         strategy. Can be called by anyone.
     * @param params A parameters for withdraw (for more details see a
     *                       specific earning strategy).
     */
    function withdrawLPs(WithdrawAndCompoundParams memory params) external;

    /**
     * @notice A withdraws users' deposits without reinvested yield. This method
     *         allows to withdraw ERC-20 LP tokens that were used in earning
     *         strategy Can be called by anyone.
     * @param params A parameters for withdraw (for more details see a
     *                       specific earning strategy).
     */
    function emergencyWithdraw(
        WithdrawAndCompoundParams memory params
    ) external;

    /**
     * @notice Withdraws users' deposits + reinvested yield. This method allows
     *         to withdraw a group of ERC-20 tokens in equal parts that were
     *         used in earning strategy (for more details see the specific
     *         earning strategy documentation). Can be called by anyone.
     * @param params A parameters for withdraw (for more details see a
     *                       specific earning strategy).
     */
    function withdrawTokens(WithdrawAndCompoundParams memory params) external;

    /**
     * @notice Withdraws users' deposits + reinvested yield. This method allows
     *         to withdraw ETH tokens that were used in earning strategy.Can be
     *         called by anyone.
     * @param params A parameters for withdraw (for more details see a
     *                       specific earning strategy).
     */
    function withdrawAndSwapForNativeToken(
        WithdrawAndCompoundParams memory params
    ) external;

    /**
     * @notice Withdraws users' deposits + reinvested yield. This method allows
     *         to withdraw any whitelisted ERC-20 tokens that were used in
     *         earning strategy. Can be called by anyone.
     * @param params A parameters for withdraw (for more details see a
     *                       specific earning strategy).
     */
    function withdrawAndSwapForERC20Token(
        WithdrawAndCompoundParams memory params
    ) external;

    /**
     * @notice Claims all rewards from earning strategy and reinvests them to
     *         increase future rewards. Can be called by anyone.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param amountsOutMin An array of minimum values that will be received
     *                      during exchanges, withdrawals or deposits of
     *                      liquidity, etc. The length of the array is unique
     *                      for each earning strategy. See the specific earning
     *                      strategy documentation for more details.
     */
    function compound(
        uint256 strategyId,
        uint256[] memory amountsOutMin
    ) external;

    /**
     * @notice Claims tokens that were distributed on users deposit and earned
     *         by a specific position of a user. Can be called by anyone.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param positionId An ID of a position. Must be an existing position ID.
     */
    function claim(uint256 strategyId, uint256 positionId) external;

    /**
     * @notice Adds a new transaction to the execution queue. Can only be called
     *         by the current owner.
     * @param transaction structure of:
     *                    dest - the address on which the method will be called;
     *                    value - the value of wei to send;
     *                    signature - method signature;
     *                    data - method call payload;
     *                    exTime - the time from which the transaction can be
     *                             executed. Must be less than the current
     *                             `block.timestamp` + `DELAY`.
     * @return A transaction hash.
     */
    function addTransaction(
        Timelock.Transaction memory transaction
    ) external returns (bytes32);

    /**
     * @notice Removes a transaction from the execution queue. Can only be
     *         called by the current owner.
     * @param transaction structure of:
     *                    dest - the address on which the method will be called;
     *                    value - the value of wei to send;
     *                    signature - method signature;
     *                    data - method call payload;
     *                    exTime - the time from which the transaction can be
     *                             executed. Must be less than the current
     *                             `block.timestamp` + `DELAY`.
     */
    function removeTransaction(
        Timelock.Transaction memory transaction
    ) external;

    /**
     * @notice Executes a transaction from the queue. Can only be called by the
     *         current owner.
     * @param transaction structure of:
     *                    dest - the address on which the method will be called;
     *                    value - the value of wei to send;
     *                    signature - method signature;
     *                    data - method call payload;
     *                    exTime - the time from which the transaction can be
     *                             executed. Must be less than the current
     *                             `block.timestamp` + `DELAY`.
     * @return Returned data.
     */
    function executeTransaction(
        Timelock.Transaction memory transaction
    ) external returns (bytes memory);

    /**
     * @notice Returns an amount of strategy final tokens (LPs) that are staked
     *         under a specified shares amount. Can be called by anyone.
     * @dev Staked == deposited + earned.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param shares An amount of shares for which to calculate a staked
     *               amount of tokens.
     * @return An amount of tokens that are staked under the shares amount.
     */
    function getStakedBySharesAmount(
        uint256 strategyId,
        uint256 shares
    ) external view returns (uint256);

    /**
     * @notice Returns an amount of strategy final (LPs) tokens earned by the
     *         specified shares amount in a specified earning strategy. Can be
     *         called by anyone.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param user A holder of position.
     * @param positionId An ID of a position.
     * @param shares An amount of shares for which to calculate an earned
     *               amount of tokens.
     * @return An amount of earned by shares tokens.
     */
    function getEarnedBySharesAmount(
        uint256 strategyId,
        address user,
        uint256 positionId,
        uint256 shares
    ) external view returns (uint256);

    /**
     * @notice Returns an amount of strategy final tokens (LPs) earned by the
     *         specified user in a specified earning strategy. Can be called by
     *         anyone.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param user A user to check earned tokens amount.
     * @param positionId An ID of a position. Must be an existing position ID.
     * @return An amount of earned by user tokens.
     */
    function getEarnedByUserAmount(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external view returns (uint256);

    /**
     * @notice Returns claimable by the user amount of reward token in the
     *         position. Can be called by anyone.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param user A user to check earned reward tokens amount.
     * @param positionId An ID of a position. Must be an existing position ID.
     * @return Claimable by the user amount.
     */
    function getClaimableRewards(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external view returns (uint256);

    /**
     * @dev Withdraws an ETH token that accidentally ended up on an earning
     *      strategy contract and cannot be used in any way. Can only be called
     *      by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param amount A number of tokens to withdraw from this contract.
     * @param receiver A wallet that will receive withdrawing tokens.
     */
    function rescueNativeToken(
        uint256 strategyId,
        uint256 amount,
        address receiver
    ) external;

    /**
     * @dev Withdraws an ERC-20 token that accidentally ended up on an earning
     *      strategy contract and cannot be used in any way. Can only be called
     *      by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param token A number of tokens to withdraw from this contract.
     * @param amount A number of tokens to withdraw from this contract.
     * @param receiver A wallet that will receive withdrawing tokens.
     */
    function rescueERC20Token(
        uint256 strategyId,
        address token,
        uint256 amount,
        address receiver
    ) external;

    /**
     * @notice Transfer position. Can be called by obly ERC721.
     * @param from A wallet from which token (user position) will be transferred.
     * @param to A wallet to which token (user position) will be transferred.
     * @param tokenId An ID of token to transfer.
     */
    function transferPositionFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ITokensRescuer.sol";

interface IParallaxStrategy is ITokensRescuer {
    /**
     * @param params parameters for deposit.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *               paths - paths that will be used during swaps.
     *               user - user from whom assets are debited for the deposit.
     *               holder - holder of position.
     *               positionId - id of the position.
     *               amounts - array of amounts to deposit.
     *               data - additional data for strategy.
     */
    struct DepositParams {
        uint256[] amountsOutMin;
        address[][] paths;
        address user;
        address holder;
        uint256 positionId;
        uint256[] amounts;
        bytes[] data;
    }

    /**
     * @param params parameters for withdraw.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *               paths - paths that will be used during swaps.
     *               positionId - id of the position.
     *               earned - earnings for the current number of shares.
     *               amounts - array of amounts to deposit.
     *               receiver - address of the user who will receive
     *                          the withdrawn assets.
     *               holder - holder of position.
     *               data - additional data for strategy.
     */
    struct WithdrawParams {
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 positionId;
        uint256 earned;
        uint256 amount;
        address receiver;
        address holder;
        bytes[] data;
    }

    /**
     * @notice Sets the minimum amount required for compounding.
     * @param compoundMinAmount The new minimum amount for compounding.
     */
    function setCompoundMinAmount(uint256 compoundMinAmount) external;

    /**
     * @notice Allows to deposit LP tokens directly
     *         Executes compound before depositing.
     *         Tokens that is depositing must be approved to this contract.
     *         Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens
     */
    function depositLPs(DepositParams memory params) external returns (uint256);

    /**
     * @notice Allows to deposit strategy tokens directly.
     *         Executes compound before depositing.
     *         Tokens that is depositing must be approved to this contract.
     *         Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens
     */
    function depositTokens(
        DepositParams memory params
    ) external returns (uint256);

    /**
     * @notice Allows to deposit native tokens.
     *         Executes compound before depositing.
     *         Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens.
     */
    function depositAndSwapNativeToken(
        DepositParams memory params
    ) external payable returns (uint256);

    /**
     * @notice Allows to deposit whitelisted ERC-20 token.
     *      ERC-20 token that is depositing must be approved to this contract.
     *      Executes compound before depositing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens
     */
    function depositAndSwapERC20Token(
        DepositParams memory params
    ) external returns (uint256);

    /**
     * @notice withdraws needed amount of staked LPs
     *      Sends to the user his LP tokens
     *      and withdrawal fees to the fees receiver.
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawLPs(WithdrawParams memory params) external;

    /**
     * @notice withdraws needed amount of staked LPs
     *      from the Sorbettiere staking smart-contract.
     *      Sends to the user his strategy tokens
     *      and withdrawal fees to the fees receiver.
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawTokens(WithdrawParams memory params) external;

    /**
     * @notice withdraws needed amount of staked LPs
     *      Exchanges all received strategy tokens for ETH token.
     *      Sends to the user his token and withdrawal fees to the fees receiver
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawAndSwapForNativeToken(
        WithdrawParams memory params
    ) external;

    /**
     * @notice withdraws needed amount of staked LPs
     *      Exchanges all received strategy tokens for whitelisted ERC20 token.
     *      Sends to the user his token and withdrawal fees to the fees receiver
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawAndSwapForERC20Token(
        WithdrawParams memory params
    ) external;

    /**
     * @notice Informs the strategy about the position transfer
     * @param from A wallet from which token (user position) will be transferred.
     * @param to A wallet to which token (user position) will be transferred.
     * @param tokenId An ID of a token to transfer which is related to user
     *                position.
     */
    function transferPositionFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice Informs the strategy about the claim rewards.
     * @param strategyId An ID of an earning strategy.
     * @param user Holder of position.
     * @param positionId An ID of a position.
     */
    function claim(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external;

    /**
     * @notice claims all rewards
     *      Then exchanges them for strategy tokens.
     *      Receives LP tokens for liquidity and deposits received LP tokens to
     *      increase future rewards.
     *      Can only be called by the Parallax contact.
     * @param amountsOutMin an array of minimum values
     *                      that will be received during exchanges,
     *                      withdrawals or deposits of liquidity, etc.
     *                      All values can be 0 that means
     *                      that you agreed with any output value.
     * @return received LP tokens earned with compound.
     */
    function compound(
        uint256[] memory amountsOutMin,
        bool toRevertIfFail
    ) external returns (uint256);

    /**
     * @notice Returns the maximum commission values for the current strategy.
     *      Can not be updated after the deployment of the strategy.
     *      Can be called by anyone.
     * @return max fee for this strategy
     */
    function getMaxFee() external view returns (uint256);

    /**
     * @notice A function that returns the accumulated fees.
     * @dev This is an external view function that returns the current
     *      accumulated fees.
     * @return The current accumulated fees as a uint256 value.
     */
    function accumulatedFees() external view returns (uint256);

    /**
     * @notice A function that returns the address of the strategy author.
     * @dev This is an external view function that returns the address
     *      associated with the author of the strategy.
     * @return The address of the strategy author as an 'address' type.
     */
    function STRATEGY_AUTHOR() external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IRewardsGauge {
    function balanceOf(address account) external view returns (uint256);
    function claimable_reward(address _addr, address _token) external view returns (uint256);
    function claim_rewards(address _addr) external;
    function deposit(uint256 _value) external;
    function withdraw(uint256 _value) external;
    function reward_contract() external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IStEth {
    function submit(address _referral) external payable returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ITokensRescuer {
    /**
     * @dev withdraws an ETH token that accidentally ended up
     *      on this contract and cannot be used in any way.
     *      Can only be called by the current owner.
     * @param amount - a number of tokens to withdraw from this contract.
     * @param receiver - a wallet that will receive withdrawing tokens.
     */
    function rescueNativeToken(uint256 amount, address receiver) external;

    /**
     * @dev withdraws an ERC-20 token that accidentally ended up
     *      on this contract and cannot be used in any way.
     *      Can only be called by the current owner.
     * @param token - a number of tokens to withdraw from this contract.
     * @param amount - a number of tokens to withdraw from this contract.
     * @param receiver - a wallet that will receive withdrawing tokens.
     */
    function rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) external;
}

pragma solidity 0.8.15;

interface IUniswapWrapper {
    function getPrice(
        address poolAddress,
        uint32 twapInterval
    ) external view returns (uint256 priceX96);

    function swapV3(
        address tokenIn,
        bytes memory _path,
        uint256 _amount,
        uint256 amountOutMinimum
    ) external returns (uint256 amountOut);

    function router() external view returns (address);

    function getAmountOut(
        bytes memory path,
        uint256 amountIn
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;


interface IWstEth{

    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHShares) external returns (uint256);
    function getStETHByWstETH(uint256 _wstETHAmount) external view returns (uint256);
    function tokensPerStEth() external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import "../../extensions/TokensRescuer.sol";

import "../../interfaces/IParallaxStrategy.sol";
import "../../interfaces/IParallaxOrbital.sol";
import "../../interfaces/IBalancerVault.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IUniswapWrapper.sol";
import "../../interfaces/IRewardsGauge.sol";
import "../../interfaces/IBalancerWrapper.sol";

error OnlyParallax();
error OnlyWhitelistedToken();
error OnlyValidSlippage();
error OnlyValidAmount();
error OnlyCorrectArrayLength();
error OnlyValidOutputAmount();

/**
 * @title A smart-contract that implements Balancer startegy base implementation
 * with staking functionality.
 */
contract BalancerStrategyBaseUpgradeable is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    TokensRescuer,
    IParallaxStrategy
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct BaseInitParams {
        address _PARALLAX_ORBITAL;
        address _BALANCER_VAULT;
        address _STAKING;
        address _UNI_WRAPPER;
        address _BAL_WRAPPER;
        address _WANT;
        address _WETH;
        IBalancerWrapper.Asset[] _ASSETS;
        Reward[] _REWARDS;
        bytes32 _WANT_POOL_ID;
        uint256 _EXPIRE_TIME;
        uint256 _maxSlippage;
        uint256 _initialCompoundMinAmount;
    }

    struct Reward {
        address token;
        bytes queryIn;
        bytes queryOut;
        AggregatorV2V3Interface wethOracle;
    }

    address public constant STRATEGY_AUTHOR = address(0);

    IBalancerVault.ExitKind exitKind;
    IBalancerVault.JoinKind joinKind;

    address public PARALLAX_ORBITAL;
    address public BALANCER_VAULT;
    address public UNI_WRAPPER;
    address public BAL_WRAPPER;
    address public STAKING;

    address public WETH;
    address public WANT;
    bytes32 public WANT_POOL_ID;

    IBalancerWrapper.Asset[] public assets;
    Reward[] public rewards;

    uint256 public EXPIRE_TIME;
    uint256 public constant STALE_PRICE_DELAY = 24 hours;

    uint256 public accumulatedFees;
    uint256 public maxSlippage;
    uint256 public initialCompoundMinAmount;
    uint256 public currentReward;

    modifier onlyParallax() {
        _onlyParallax();
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function __BalancerStrategyBase_init_unchained(
        BaseInitParams memory baseInitParams
    ) internal initializer {
        PARALLAX_ORBITAL = baseInitParams._PARALLAX_ORBITAL;
        BALANCER_VAULT = baseInitParams._BALANCER_VAULT;
        STAKING = baseInitParams._STAKING;
        UNI_WRAPPER = baseInitParams._UNI_WRAPPER;
        BAL_WRAPPER = baseInitParams._BAL_WRAPPER;
        WETH = baseInitParams._WETH;
        EXPIRE_TIME = baseInitParams._EXPIRE_TIME;
        WANT = baseInitParams._WANT;
        WANT_POOL_ID = baseInitParams._WANT_POOL_ID;
        maxSlippage = baseInitParams._maxSlippage;
        initialCompoundMinAmount = baseInitParams._initialCompoundMinAmount;

        for (uint256 i = 0; i < baseInitParams._ASSETS.length; i++) {
            assets.push(baseInitParams._ASSETS[i]);
        }

        uint256 rewardsLength = baseInitParams._REWARDS.length;
        for (uint256 i = 0; i < rewardsLength; i++) {
            rewards.push(baseInitParams._REWARDS[i]);
        }
    }

    function setCompoundMinAmount(
        uint256 newCompoundMinAmount
    ) external onlyParallax {
        initialCompoundMinAmount = newCompoundMinAmount;
    }

    /// @inheritdoc ITokensRescuer
    function rescueNativeToken(
        uint256 amount,
        address receiver
    ) external onlyParallax {
        _rescueNativeToken(amount, receiver);
    }

    /// @inheritdoc ITokensRescuer
    function rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) external onlyParallax {
        _rescueERC20Token(token, amount, receiver);
    }

    function transferPositionFrom(
        address from,
        address to,
        uint256 tokenId
    ) external onlyParallax {}

    function setMaxSlippage(uint256 newMaxSlippage) external onlyParallax {
        if (newMaxSlippage > 1000) {
            revert OnlyValidSlippage();
        }

        maxSlippage = newMaxSlippage;
    }

    function claim(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external onlyParallax {}

    /**
     * @notice Deposit amount of BPT tokens into the Balancer pool.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the user's address and the amount of tokens to deposit.
     */
    function depositLPs(
        DepositParams memory params
    ) external nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(params.amounts.length, 1);

        if (params.amounts[0] > 0) {
            IERC20Upgradeable(WANT).safeTransferFrom(
                params.user,
                address(this),
                params.amounts[0]
            );
            _stake(params.amounts[0]);

            return params.amounts[0];
        }

        return 0;
    }

    /**
     * @notice Deposit an equal amount of assets into the Balancer pool.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the user's address and the amount of tokens to deposit.
     */
    function depositTokens(
        DepositParams memory params
    ) external nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(params.amounts.length, assets.length);

        uint depositAssets;
        for (uint i = 0; i < assets.length; i++) {
            if (params.amounts[i] == 0) {
                continue;
            }
            depositAssets++;

            IERC20Upgradeable(assets[i].token).safeTransferFrom(
                params.user,
                address(this),
                params.amounts[i]
            );
        }

        if (depositAssets <= 1) {
            revert OnlyValidAmount();
        }

        uint256 amount = _balancerAddLiquidity(params.amounts);
        _stake(amount);

        return amount;
    }

    /**
     * @notice Swap native Ether for assets, then deposit them into Balancer pool.
     * @dev This function is only callable by the Parallax contract and requires ETH to be sent along with the transaction.
     */
    function depositAndSwapNativeToken(
        DepositParams memory params
    ) external payable nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(params.amountsOutMin.length, assets.length);

        if (msg.value > 0) {
            uint[] memory amounts = _breakEth(
                msg.value,
                address(0),
                0,
                params.amountsOutMin
            );
            uint256 amount = _balancerAddLiquidity(amounts);
            _stake(amount);

            return amount;
        }
    
        return 0;
    }

    /**
     * @notice Swap the specified ERC20 token for assets, then deposit them into the Balancer pool.
     * @dev This function is only callable by the Parallax contract.
     */
    function depositAndSwapERC20Token(
        DepositParams memory params
    ) external nonReentrant onlyParallax returns (uint256) {
        address token = address(uint160(bytes20(params.data[0])));
        _onlyWhitelistedToken(token);
        _onlyCorrectArrayLength(params.amountsOutMin.length, assets.length + 1);

        uint256 depositAmount = params.amounts[0];
        uint256 amountWeth;
        address exclude;
        uint256 excludeAmount;

        if (depositAmount > 0) {
            IERC20Upgradeable(token).safeTransferFrom(
                params.user,
                address(this),
                depositAmount
            );
            for (uint i = 0; i < assets.length; i++) {
                if (assets[i].token == token) {
                    exclude = assets[i].token;
                    excludeAmount = depositAmount / assets.length;
                }
            }

            if (token != WETH) {
                amountWeth = _preProcessOut(
                    token,
                    depositAmount - excludeAmount,
                    params.amountsOutMin[params.amountsOutMin.length - 1]
                );

                if (amountWeth == 0) {
                    amountWeth = _uniSwapAny(
                        token,
                        params.data[1],
                        depositAmount - excludeAmount,
                        params.amountsOutMin[params.amountsOutMin.length - 1]
                    );
                }
            } else {
                amountWeth = depositAmount;
            }

            uint256[] memory amounts;
            uint256[] memory minAmounts = new uint256[](assets.length);
            minAmounts = _removeElementsFromEnd(params.amountsOutMin, 1);

            IWETH(WETH).withdraw(amountWeth);

            amounts = _breakEth(
                address(this).balance,
                exclude,
                excludeAmount,
                minAmounts
            );

            uint amount = _balancerAddLiquidity(amounts);

            _stake(amount);

            return amount;
        }
        
        return 0;
    }

    /**
     * @notice Compound the harvested rewards back into the Aura pool.
     * @dev This function is only callable by the Parallax contract.
     */
    function compound(
        uint256[] memory amountsOutMin,
        bool toRevertIfFail
    ) external onlyParallax returns (uint256) {
        currentReward += _harvest(toRevertIfFail);

        if (currentReward >= assets.length) {
            IWETH(WETH).withdraw(currentReward);
            uint256[] memory amounts = _breakEth(
                address(this).balance,
                address(0),
                0,
                amountsOutMin
            );
            uint256 amount = _balancerAddLiquidity(amounts);
            _stake(amount);
            currentReward = 0;

            return amount;
        }

        return 0;
    }

    /**
     * @notice Unstake and withdraw the specified amount of BPT tokens.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the recipient's address, the amount to withdraw, and the earned amount.
     */
    function withdrawTokens(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        _onlyCorrectArrayLength(params.amountsOutMin.length, assets.length);

        if (params.amount > 0) {
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );

            _withdraw(params.receiver, actualWithdraw, params.amountsOutMin);

            _unstake(withdrawalFee);
            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice Unstake and withdraw the specified amount of BPT tokens.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the recipient's address, the amount to withdraw, and the earned amount.
     */
    function withdrawLPs(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        if (params.amount > 0) {
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );

            _unstake(actualWithdraw);

            IERC20Upgradeable(WANT).safeTransfer(
                params.receiver,
                actualWithdraw
            );

            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice Unztake the specified amount of BPT from rewards gauge, withdraw assets from the Balancer pool and swap them for the specified ERC20 token.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the recipient's address, the amount to withdraw, the earned amount, and the address of the ERC20 token to swap for.
     */
    function withdrawAndSwapForERC20Token(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        _onlyCorrectArrayLength(params.amountsOutMin.length % 2, 1);
        _onlyCorrectArrayLength(params.amountsOutMin.length / 2, assets.length);

        uint256 totalOut;

        if (params.amount > 0) {
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );

            uint256[] memory minAmountsOut = _removeElementsFromEnd(
                params.amountsOutMin,
                assets.length + 1
            );

            address token = address(uint160(bytes20(params.data[0])));

            uint256[] memory amounts = _withdraw(
                address(this),
                actualWithdraw,
                minAmountsOut
            );

            uint receivedWeth;

            for (uint i = 0; i < assets.length; i++) {
                if (assets[i].token == token) {
                    totalOut += amounts[i];
                    continue;
                }

                uint prevBalance = receivedWeth;
                receivedWeth += _preProcessOut(
                    assets[i].token,
                    amounts[i],
                    params.amountsOutMin[minAmountsOut.length + i]
                );

                if (receivedWeth > prevBalance) {
                    continue;
                }

                IERC20Upgradeable(assets[i].token).safeIncreaseAllowance(
                    UNI_WRAPPER,
                    amounts[i]
                );

                receivedWeth += _uniSwapAny(
                    assets[i].token,
                    assets[i].queryIn,
                    amounts[i],
                    params.amountsOutMin[minAmountsOut.length + i]
                );
            }

            if (token != WETH) {
                uint totalBefore = totalOut;
                totalOut += _preProcessIn(
                    token,
                    receivedWeth,
                    params.amountsOutMin[params.amountsOutMin.length - 1]
                );

                if (totalBefore == totalOut) {
                    _onlyCorrectArrayLength(params.data.length, 2);

                    totalOut = _uniSwapAny(
                        WETH,
                        params.data[1],
                        receivedWeth,
                        params.amountsOutMin[params.amountsOutMin.length - 1]
                    );
                }
            } else {
                totalOut = receivedWeth;
            }

            IERC20Upgradeable(token).safeTransfer(params.receiver, totalOut);

            _unstake(withdrawalFee);

            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice Unstake the specified amount of BPT from rewards gauge, withdraw from the Balancer pool and swap them for the native token.
     * @dev This function is only callable by the Parallax contract.
     * @param params An object containing the recipient's address, the amount to withdraw, and the earned amount.
     */
    function withdrawAndSwapForNativeToken(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        _onlyCorrectArrayLength(params.amountsOutMin.length / 2, assets.length);

        if (params.amount > 0) {
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );

            uint256[] memory minAmountsOut = _removeElementsFromEnd(
                params.amountsOutMin,
                assets.length
            );

            uint256[] memory amounts = _withdraw(
                address(this),
                actualWithdraw,
                minAmountsOut
            );

            uint receivedWeth;
            for (uint i = 0; i < assets.length; i++) {
                uint prevBalance = receivedWeth;
                receivedWeth += _preProcessOut(
                    assets[i].token,
                    amounts[i],
                    params.amountsOutMin[minAmountsOut.length + i]
                );

                if (receivedWeth > prevBalance) {
                    continue;
                }

                receivedWeth = _uniSwapAny(
                    assets[i].token,
                    assets[i].queryIn,
                    amounts[i],
                    params.amountsOutMin[minAmountsOut.length + i]
                );
            }

            IWETH(WETH).withdraw(
                IERC20Upgradeable(WETH).balanceOf(address(this))
            );

            payable(params.receiver).transfer(receivedWeth);

            _unstake(withdrawalFee);

            _takeFee(withdrawalFee);
        }
    }

    function getMaxFee() external view returns (uint256) {
        return 10000;
    }

    function _unstake(uint256 amount) internal virtual {
        if (amount == 0) {
            return;
        }

        IRewardsGauge(STAKING).withdraw(amount);
    }

    /**
     * @dev Adds liquidity to the Balancer pool using the provided amounts of assets.
     * @param amounts The amounts of assets to add as liquidity.
     */
    function _balancerAddLiquidity(
        uint256[] memory amounts
    ) internal virtual returns (uint256) {

        IBalancerWrapper.Asset[] memory _assets = new IBalancerWrapper.Asset[](amounts.length);

        _assets = assets;

        for(uint i = 0; i < assets.length; i++) {
            if(assets[i].token == WANT){
                continue;
            }
            IERC20Upgradeable(assets[i].token).safeIncreaseAllowance(
                BAL_WRAPPER,
                amounts[i]
            );
        }
        
        return IBalancerWrapper(BAL_WRAPPER).join(
            amounts,
            WANT_POOL_ID,
            WANT,
            _assets,
            joinKind
        );
    }


    /**
     * @dev Harvests the rewards and converts them to WETH.
     * @return totalWethRewards The total amount of harvested WETH rewards.
     */
    function _harvest(bool toRevertIfFail) internal returns (uint256 totalWethRewards) {
        uint256[] memory amounts = _claim();

        for (uint i = 0; i < rewards.length; i++) {
            if (rewards[i].token == WETH) {
                totalWethRewards += amounts[i];
                continue;
            }

            if (amounts[i] == 0) {
                continue;
            }

            (uint256 rate, uint256 decimals) = _getPrice(rewards[i].wethOracle);
            uint256 rewardWeth = _preProcessAmounts(rewards[i], amounts[i]);

            if (rewardWeth == 0) {
                rewardWeth = _getAmountOutUni(rewards[i], amounts[i]);
            }

            if (rate > 0) {
                uint256 amountOutOracle = (rate * amounts[i]) /
                    (10 **
                        (decimals -
                            (decimals - IWETH(rewards[i].token).decimals())));
                uint256 slippage = (amountOutOracle * (10000 - maxSlippage)) /
                    10000;

                if (rewardWeth >= slippage) {
                    uint256 amountOut = _preProcessIn(
                        rewards[i].token,
                        amounts[i],
                        slippage
                    );

                    if (amountOut > 0) {
                        totalWethRewards += amountOut;
                    } else {
                        totalWethRewards += _uniSwapAny(
                            rewards[i].token,
                            rewards[i].queryIn,
                            amounts[i],
                            slippage
                        );
                    }
                } else if(toRevertIfFail) {
                    revert OnlyValidOutputAmount();
                }
            }
        }
    }

    /**
     * @dev Stakes the specified amount of tokens into the staking contract.
     *
     * @param amount The amount of tokens to stake.
     * @dev Deposits the specified `amount` of tokens into the staking contract.
     */
    function _stake(uint amount) internal virtual {
        IERC20Upgradeable(WANT).safeIncreaseAllowance(STAKING, amount);
        IRewardsGauge(STAKING).deposit(amount);
    }

    /**
     * @dev Claims the rewards from the staking contract.
     *
     * @return amounts An array of reward amounts.
     * @dev Claims the rewards from the staking contract using the `claim_rewards()` function from `IRewardsGauge`.
     * @dev Retrieves the balance of each reward token and stores them in the `amounts` array.
     */
    function _claim() internal virtual returns (uint256[] memory amounts) {
        IRewardsGauge(STAKING).claim_rewards(address(this));
        amounts = new uint256[](rewards.length);

        for (uint i = 0; i < rewards.length; i++) {
            amounts[i] = IERC20Upgradeable(rewards[i].token).balanceOf(
                address(this)
            );
        }
    }

    function _preProcessIn(
        address token,
        uint256 amount,
        uint256 minAmountOut
    ) internal virtual returns (uint256) {
        return 0;
    }

    function _preProcessOut(
        address token,
        uint256 amount,
        uint256 minAmountOut
    ) internal virtual returns (uint256) {
        return 0;
    }

    function _preProcessAmounts(
        Reward memory reward,
        uint256 amount
    ) internal virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Unstake the specified amount of BPT tokens from the rewards gauge and
     *      exits the Balancer pool, returning the assets to the recipient.
     * @param amount: The amount of BPT tokens to withdraw.
     * @param recipient: The address that will receive the withdrawn tokens.
     */
    function _withdraw(
        address recipient,
        uint256 amount,
        uint256[] memory minAmountsOut
    ) internal virtual returns (uint256[] memory delta) {
        _unstake(amount);

        IBalancerWrapper.Asset[] memory _assets = new IBalancerWrapper.Asset[](assets.length);

        for(uint i = 0; i < assets.length; i++) {
            _assets[i] = assets[i];
        }

        IERC20Upgradeable(WANT).safeIncreaseAllowance(BAL_WRAPPER, amount);
        
        return IBalancerWrapper(BAL_WRAPPER).exit(amount, minAmountsOut, WANT_POOL_ID, WANT, _assets, exitKind);
    }

    /**
     * @dev Swaps an ERC20 token for any other token via Uniswap V3 wrapper.
     * @param tokenIn The address of the input ERC20 token.
     * @param path The encoded path for the swap.
     * @param amountIn The amount of input token to swap.
     * @param minAmountOut The minimum acceptable amount of the output token.
     * @return amountOut The actual amount of output tokens received.
     */
    function _uniSwapAny(
        address tokenIn,
        bytes memory path,
        uint256 amountIn,
        uint256 minAmountOut
    ) internal virtual returns (uint256) {
        IERC20Upgradeable(tokenIn).safeIncreaseAllowance(UNI_WRAPPER, amountIn);

        uint256 amountOut = IUniswapWrapper(UNI_WRAPPER).swapV3(
            tokenIn,
            path,
            amountIn,
            minAmountOut
        );

        return amountOut;
    }

    /**
     * @dev Performs a single swap using Balancer Vault.
     * @param tokenOut The address of the output ERC20 token.
     * @param tokenIn The address of the input ERC20 token.
     * @param amountIn The amount of input token to swap.
     * @param minAmountOut The minimum acceptable amount of the output token.
     * @param poolId The PoolId of the Balancer pool to use for the swap.
     * @return receivedTokenOut The actual amount of output tokens received.
     */
    function _balancerSwapSingle(
        address tokenOut,
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes32 poolId
    ) internal returns (uint256) {
        IERC20Upgradeable(tokenIn).safeIncreaseAllowance(
            BAL_WRAPPER,
            amountIn
        );

        return IBalancerWrapper(BAL_WRAPPER).swapSingle(
            tokenOut,
            tokenIn,
            amountIn,
            minAmountOut,
            poolId,
            _getDeadline()
        );
    }

    /**
     * @dev Breaks a given amount of Ether into WETH and WSTETH tokens.
     * @param amount The amount of Ether to break.
     */
    function _breakEth(
        uint256 amount,
        address exclude,
        uint256 excludeAmount,
        uint256[] memory minAmountsOut
    ) internal returns (uint256[] memory amounts) {
        if (amount < assets.length) {
            revert OnlyValidAmount();
        }

        IWETH(WETH).deposit{ value: amount }();
        uint part = amount / assets.length;
        amounts = new uint256[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].token == WETH) {
                amounts[i] = part;
            } else if (assets[i].token == exclude) {
                amounts[i] = excludeAmount;
            } else {
                IERC20Upgradeable(WETH).safeIncreaseAllowance(
                    UNI_WRAPPER,
                    part
                );

                uint amountIn = _preProcessIn(
                    assets[i].token,
                    part,
                    minAmountsOut[i]
                );

                if (amountIn > 0) {
                    amounts[i] = amountIn;
                    continue;
                }

                amounts[i] = IUniswapWrapper(UNI_WRAPPER).swapV3(
                    WETH,
                    assets[i].queryOut,
                    part,
                    minAmountsOut[i]
                );
            }
        }
    }

    function _takeFee(uint256 fee) internal {
        if (fee > 0) {
            accumulatedFees += fee;
            IERC20Upgradeable(WANT).safeTransfer(
                IParallaxOrbital(PARALLAX_ORBITAL).feesReceiver(),
                fee
            );
        }
    }

    function _calculateActualWithdrawAndWithdrawalFee(
        uint256 withdrawalAmount,
        uint256 earnedAmount
    ) internal view returns (uint256 actualWithdraw, uint256 withdrawalFee) {
        uint256 actualEarned = (earnedAmount *
            (10000 -
                IParallaxOrbital(PARALLAX_ORBITAL).getFee(address(this)))) /
            10000;

        withdrawalFee = earnedAmount - actualEarned;
        actualWithdraw = withdrawalAmount - withdrawalFee;
    }

    function _getDeadline() private view returns (uint256) {
        return block.timestamp + EXPIRE_TIME;
    }

    /**
     * @notice Returns a price of a token in a specified oracle.
     * @param oracle An address of an oracle which will return a price of asset.
     * @return A tuple with a price of token, token decimals and a flag that
     *         indicates if data is actual (fresh) or not.
     */
    function _getPrice(
        AggregatorV2V3Interface oracle
    ) internal view returns (uint256, uint8) {
        if (address(oracle) == address(0)) {
            return (0, 0);
        }
        (
            uint80 roundID,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = oracle.latestRoundData();
        bool dataIsActual = answeredInRound >= roundID &&
            answer > 0 &&
            block.timestamp <= updatedAt + 24 hours;

        if (!dataIsActual) {
            return (0, 0);
        }

        uint8 decimals = oracle.decimals();

        return (uint256(answer), decimals);
    }

    /**
     * @dev Retrieves the output amount for a given input amount using Uniswap v3 Wrapper for a specific reward.
     * @param reward The reward data containing the queryIn parameter.
     * @param amountIn The amount of input tokens.
     * @return amountOut The amount of output tokens.
     */
    function _getAmountOutUni(
        Reward memory reward,
        uint amountIn
    ) internal returns (uint256) {
        return IUniswapWrapper(UNI_WRAPPER).getAmountOut(
            reward.queryIn,
            amountIn
        );
    }

    /**
     * @dev Retrieves the output amount for a given input amount using Balancer Vault.
     * @param amountIn The amount of input tokens.
     * @param tokenIn The address of the input ERC20 token.
     * @param tokenOut The address of the output ERC20 token.
     * @param poolId The PoolId of the Balancer pool to use for the swap.
     * @return amountOut The amount of output tokens.
     */
    function _getAmountOutBal(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        bytes32 poolId
    ) internal returns (uint256) {
        return IBalancerWrapper(BAL_WRAPPER).getAmountOut(
            amountIn,
            tokenIn,
            tokenOut,
            poolId
        );
    }

    function _removeElementsFromEnd(
        uint[] memory arr,
        uint n
    ) internal pure returns (uint[] memory) {
        assert(n <= arr.length);

        uint[] memory newArr = new uint[](arr.length - n);
        for (uint i = 0; i < newArr.length; i++) {
            newArr[i] = arr[i];
        }
        return newArr;
    }

    function _onlyParallax() private view {
        if (_msgSender() != PARALLAX_ORBITAL) {
            revert OnlyParallax();
        }
    }

    function _onlyWhitelistedToken(address token) private view {
        if (
            !IParallaxOrbital(PARALLAX_ORBITAL).tokensWhitelist(
                address(this),
                token
            )
        ) {
            revert OnlyWhitelistedToken();
        }
    }

    function _onlyCorrectArrayLength(
        uint256 actualLength,
        uint256 expectedlength
    ) private pure {
        if (actualLength != expectedlength) {
            revert OnlyCorrectArrayLength();
        }
    }
}