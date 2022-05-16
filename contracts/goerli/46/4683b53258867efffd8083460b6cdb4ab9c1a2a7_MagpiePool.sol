// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import './security/PausableUpgradeable.sol';
import './interfaces/IMagpieProviders.sol';
import './interfaces/IWormhole.sol';
import './interfaces/IMagpieTokenManager.sol';
import './interfaces/IMagpiePool.sol';
import './lib/LibAssetUpgradeable.sol';

contract MagpiePool is
  Initializable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable,
  OwnableUpgradeable,
  IMagpiePool
{
  using LibAssetUpgradeable for address;

  uint256 private constant BASE_DIVISOR = 10000000000; // Basis Points * 10 for better accuracy

  uint256 public baseGas;

  IWormhole private wormholeBridge;
  IMagpieTokenManager public magpieTokenManager;
  IMagpieProviders public magpieProviders;

  address private wormholeBridgeAddress;
  address private magpieCoreAddress;

  mapping(address => uint256) public gasFeeAccumulatedByToken;
  //uint256 public gasFeeAccumulated;
  mapping(address => mapping(address => uint256)) public gasFeeAccumulated;
  mapping(address => uint256) public incentivePool;

  event AssetSent(
    address indexed asset,
    uint256 indexed amount,
    uint256 indexed transferredAmount,
    address target,
    uint256 fromChainId,
    uint256 lpFee,
    uint256 transferFee,
    uint256 gasFee
  );
  event Deposit(
    address indexed from,
    address indexed tokenAddress,
    address indexed receiver,
    uint256 toChainId,
    uint256 amount,
    uint256 reward
  );
  event GasFeeWithdraw(address indexed tokenAddress, address indexed owner, uint256 indexed amount);
  event EthReceived(address, uint256);

  // MODIFIERS
  modifier onlyMagpieCore() {
    require(magpieCoreAddress == msg.sender, 'MagpiePool: Only magpieCore allowed');
    _;
  }

  modifier onlyLiquidityProviders() {
    require(msg.sender == address(magpieProviders), 'MagpiePool: Only magpieProviders is allowed');
    _;
  }

  modifier tokenChecks(address tokenAddress) {
    (, bool supportedToken, , , ) = magpieTokenManager.tokensInfo(tokenAddress);
    require(supportedToken, 'MagpiePool: Token not supported');
    _;
  }

  function initialize(
    address _magpieCoreAddress,
    address _magpiePauser,
    address _magpieTokenManager,
    address _magpieProviders,
    address _tokenBridgeAddress
  ) public initializer {
    require(_magpieProviders != address(0), 'MagpiePool: MagpieProviders cannot be 0x0');
    __ReentrancyGuard_init();
    __Ownable_init();
    __Pausable_init(_magpiePauser);
    magpieCoreAddress = _magpieCoreAddress;
    magpieTokenManager = IMagpieTokenManager(_magpieTokenManager);
    magpieProviders = IMagpieProviders(_magpieProviders);
    wormholeBridge = IWormhole(_tokenBridgeAddress);
    wormholeBridgeAddress = _tokenBridgeAddress;
    baseGas = 21000;
  }

  function getLiquidity(address tokenAddress) public view returns (uint256 currentLiquidity) {
    uint256 liquidityPoolBalance = magpieProviders.getLiquidity(tokenAddress);

    currentLiquidity =
      liquidityPoolBalance -
      magpieProviders.totalLPFees(tokenAddress) -
      gasFeeAccumulatedByToken[tokenAddress] -
      incentivePool[tokenAddress];
  }

  function _bridgeInToken(
    uint256 toChainId,
    address tokenAddress,
    address receiver,
    uint256 amount
  ) private {
    IMagpieTokenManager.TokenConfig memory config = magpieTokenManager.getDepositInfo(
      toChainId,
      tokenAddress
    );

    require(
      config.min <= amount && config.max >= amount,
      'MagpiePool: Deposit amount not in Cap limit'
    );
    require(receiver != address(0), 'MagpiePool: Receiver address cannot be 0');
    require(amount != 0, 'MagpiePool: Amount cannot be 0');
    address sender = msg.sender;

    uint256 rewardAmount = _getRewardAmount(amount, tokenAddress);
    if (rewardAmount != 0) {
      incentivePool[tokenAddress] = incentivePool[tokenAddress] - rewardAmount;
    }

    magpieProviders.increaseLiquidity(tokenAddress, amount);
    tokenAddress.transferFrom(sender, address(this), amount);

    emit Deposit(sender, tokenAddress, receiver, toChainId, amount + rewardAmount, rewardAmount);
  }

  function _bridgeInTokenWormhole(
    address tokenAddress,
    bytes32 receiver,
    uint256 amount
  ) private returns (uint64) {
    tokenAddress.increaseAllowance(wormholeBridgeAddress, amount);

    return
      wormholeBridge.transferTokens(
        tokenAddress,
        amount,
        uint16(wormholeBridge.chainId()),
        receiver,
        0,
        uint32(block.timestamp % 2**32)
      );
  }

  /*
   * @dev Function used to deposit tokens into pool to initiate a cross chain token transfer.
   * @param toChainId Chain id where funds needs to be transfered
   * @param tokenAddress ERC20 Token address that needs to be transfered
   * @param receiver Address on toChainId where tokens needs to be transfered
   * @param amount Amount of token being transfered
   */
  function bridgeInToken(BridgeInTokenArgs calldata bridgeInArgs)
    external
    tokenChecks(bridgeInArgs.tokenAddress)
    whenNotPaused
    nonReentrant
    returns (uint64)
  {
    if (bridgeInArgs.useTokenBridge) {
      return
        _bridgeInTokenWormhole(
          bridgeInArgs.tokenAddress,
          bridgeInArgs.receiver,
          bridgeInArgs.amount
        );
    } else {
      _bridgeInToken(bridgeInArgs.toChainId, bridgeInArgs.tokenAddress, address(uint160(uint256(bridgeInArgs.receiver))), bridgeInArgs.amount);
      return 0;
    }
  }

  function _bridgeOutToken(
    address tokenAddress,
    uint256 amount,
    address payable receiver,
    uint256 gasFee
  ) private returns (uint256) {
    IMagpieTokenManager.TokenConfig memory config = magpieTokenManager.getTransferInfo(
      tokenAddress
    );
    require(
      config.min <= amount && config.max >= amount,
      'MagpiePool: Withdraw amount not in Cap limit'
    );
    require(receiver != address(0), 'MagpiePool: Bad receiver address');
    uint256[4] memory transferDetails = _getBridgeAmountOut(gasFee, tokenAddress, amount);
    magpieProviders.decreaseLiquidity(tokenAddress, transferDetails[0]);
    tokenAddress.transfer(receiver, transferDetails[0]);

    return transferDetails[0];
  }

  function _bridgeOutTokenWormhole(
    address tokenAddress,
    uint256 amount,
    address payable receiver,
    uint256 gasFee,
    bytes memory encodedVm
  ) private returns (uint256) {
    wormholeBridge.completeTransfer(encodedVm);

    uint256[2] memory transferDetails = _getBridgeAmountOutWormhole(gasFee, tokenAddress, amount);

    tokenAddress.transfer(receiver, transferDetails[0]);
    return transferDetails[0];
  }

  function bridgeOutToken(BridgeOutTokenArgs calldata bridgeOutArgs)
    external
    nonReentrant
    onlyMagpieCore
    whenNotPaused
    returns (uint256 amountToTransfer)
  {
    if (bridgeOutArgs.encodedVM.length == 0) {
      return
        _bridgeOutToken(
          bridgeOutArgs.tokenAddress,
          bridgeOutArgs.amount,
          bridgeOutArgs.receiver,
          bridgeOutArgs.gasFee
        );
    } else {
      return
        _bridgeOutTokenWormhole(
          bridgeOutArgs.tokenAddress,
          bridgeOutArgs.amount,
          bridgeOutArgs.receiver,
          bridgeOutArgs.gasFee,
          bridgeOutArgs.encodedVM
        );
    }
  }

  function _getRewardAmount(uint256 amount, address tokenAddress)
    private
    view
    returns (uint256 rewardAmount)
  {
    uint256 currentLiquidity = getLiquidity(tokenAddress);
    uint256 providedLiquidity = magpieProviders.getLiquidityProvidedByToken(tokenAddress);
    if (currentLiquidity < providedLiquidity) {
      uint256 liquidityDifference = providedLiquidity - currentLiquidity;
      if (amount >= liquidityDifference) {
        rewardAmount = incentivePool[tokenAddress];
      } else {
        // Multiply by 10000000000 to avoid 0 reward amount for small amount and liquidity difference
        rewardAmount = (amount * incentivePool[tokenAddress] * 10000000000) / liquidityDifference;
        rewardAmount = rewardAmount / 10000000000;
      }
    }
  }

  function _getBridgeAmountOutWormhole(
    uint256 gasFee,
    address tokenAddress,
    uint256 amount
  ) private returns (uint256[2] memory) {
    gasFeeAccumulatedByToken[tokenAddress] += gasFee;
    gasFeeAccumulated[tokenAddress][msg.sender] += gasFee;

    return [amount, gasFee];
  }

  /*
   * @dev Internal function to calculate amount of token that needs to be transfered afetr deducting all required fees.
   * Fee to be deducted includes gas fee, lp fee and incentive pool amount if needed.
   * @param tokenAddress Token address for which calculation needs to be done
   * @param amount Amount of token to be transfered before deducting the fee
   * @param tokenGasPrice Gas price in the token being transfered to be used to calculate gas fee
   * @return [ amountToTransfer, lpFee, transferFeeAmount, gasFee ]
   */
  function _getBridgeAmountOut(
    uint256 gasFee,
    address tokenAddress,
    uint256 amount
  ) private returns (uint256[4] memory) {
    IMagpieTokenManager.TokenInfo memory tokenInfo = magpieTokenManager.getTokensConfig(
      tokenAddress
    );
    uint256 transferFeePerc = _getTransferFee(tokenAddress, amount, tokenInfo);
    uint256 lpFee;
    if (transferFeePerc > tokenInfo.equilibriumFee) {
      // Here add some fee to incentive pool also
      lpFee = (amount * tokenInfo.equilibriumFee) / BASE_DIVISOR;
      unchecked {
        incentivePool[tokenAddress] +=
          (amount * (transferFeePerc - tokenInfo.equilibriumFee)) /
          BASE_DIVISOR;
      }
    } else {
      lpFee = (amount * transferFeePerc) / BASE_DIVISOR;
    }
    uint256 transferFeeAmount = (amount * transferFeePerc) / BASE_DIVISOR;

    magpieProviders.updateLPFee(tokenAddress, lpFee);

    gasFeeAccumulatedByToken[tokenAddress] += gasFee;
    gasFeeAccumulated[tokenAddress][msg.sender] += gasFee;
    uint256 amountToTransfer = amount - transferFeeAmount;
    return [amountToTransfer, lpFee, transferFeeAmount, gasFee];
  }

  function _getTransferFee(
    address tokenAddress,
    uint256 amount,
    IMagpieTokenManager.TokenInfo memory tokenInfo
  ) private view returns (uint256 fee) {
    uint256 currentLiquidity = getLiquidity(tokenAddress);
    uint256 providedLiquidity = magpieProviders.getLiquidityProvidedByToken(tokenAddress);

    uint256 resultingLiquidity = currentLiquidity - amount;

    // Fee is represented in basis points * 10 for better accuracy
    uint256 numerator = providedLiquidity * tokenInfo.equilibriumFee * tokenInfo.maxFee; // F(max) * F(e) * L(e)
    uint256 denominator = tokenInfo.equilibriumFee *
      providedLiquidity +
      (tokenInfo.maxFee - tokenInfo.equilibriumFee) *
      resultingLiquidity; // F(e) * L(e) + (F(max) - F(e)) * L(r)

    if (denominator == 0) {
      fee = 0;
    } else {
      fee = numerator / denominator;
    }
  }

  function withdrawGasFee(address tokenAddress) external onlyMagpieCore whenNotPaused nonReentrant {
    uint256 _gasFeeAccumulated = gasFeeAccumulated[tokenAddress][msg.sender];
    require(_gasFeeAccumulated != 0, 'Gas Fee earned is 0');
    gasFeeAccumulatedByToken[tokenAddress] =
      gasFeeAccumulatedByToken[tokenAddress] -
      _gasFeeAccumulated;
    gasFeeAccumulated[tokenAddress][msg.sender] = 0;
    tokenAddress.transfer(payable(msg.sender), _gasFeeAccumulated);

    emit GasFeeWithdraw(tokenAddress, msg.sender, _gasFeeAccumulated);
  }

  function getTransferFee(address tokenAddress, uint256 amount) external view returns (uint256) {
    return _getTransferFee(tokenAddress, amount, magpieTokenManager.getTokensConfig(tokenAddress));
  }

  function transfer(
    address tokenAddress,
    address receiver,
    uint256 tokenAmount
  ) external whenNotPaused onlyLiquidityProviders nonReentrant {
    require(receiver != address(0), 'MagpiePool: Invalid receiver');

    tokenAddress.transfer(payable(receiver), tokenAmount);
  }

  receive() external payable {
    emit EthReceived(_msgSender(), msg.value);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {PausableUpgradeable as OpenZeppelinPausableUpgradeable} from '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, OpenZeppelinPausableUpgradeable {
  address private _pauser;

  event PauserChanged(address indexed previousPauser, address indexed newPauser);

  /**
   * @dev The pausable constructor sets the original `pauser` of the contract to the sender
   * account & Initializes the contract in unpaused state..
   */
  function __Pausable_init(address pauser) internal initializer {
    require(pauser != address(0), 'Pauser Address cannot be 0');
    __Pausable_init();
    _pauser = pauser;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isPauser(address pauser) public view returns (bool) {
    return pauser == _pauser;
  }

  /**
   * @dev Throws if called by any account other than the pauser.
   */
  modifier onlyPauser() {
    require(isPauser(msg.sender), 'Only pauser is allowed to perform this operation');
    _;
  }

  /**
   * @dev Allows the current pauser to transfer control of the contract to a newPauser.
   * @param newPauser The address to transfer pauserShip to.
   */
  function changePauser(address newPauser) public onlyPauser {
    _changePauser(newPauser);
  }

  /**
   * @dev Transfers control of the contract to a newPauser.
   * @param newPauser The address to transfer ownership to.
   */
  function _changePauser(address newPauser) internal {
    require(newPauser != address(0));
    emit PauserChanged(_pauser, newPauser);
    _pauser = newPauser;
  }

  function renouncePauser() external virtual onlyPauser {
    emit PauserChanged(_pauser, address(0));
    _pauser = address(0);
  }

  function pause() public onlyPauser {
    _pause();
  }

  function unpause() public onlyPauser {
    _unpause();
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieProviders {
    function decimalPrecision() external view returns (uint256); 

    function initialize(address _lpToken) external; 

    function updateLPFee(address _token, uint256 _amount) external; 

    function addNativeLiquidity() external; 

    function addTokenLiquidity(address _token, uint256 _amount) external; 

    function withdrawFee(uint256 _nftId) external; 

    function getFeeAccumulatedOnNft(uint256 _nftId) external view returns (uint256); 

    function getLiquidityProvidedByToken(address tokenAddress) external view returns (uint256); 

    function getTokenPriceInLPShares(address _baseToken) external view returns (uint256); 

    function getTotalLPFeeByToken(address tokenAddress) external view returns (uint256); 

    function getTotalReserveByToken(address tokenAddress) external view returns (uint256);

    function getSuppliedLiquidity(uint256 _nftId) external view returns (uint256); 

    function increaseNativeLiquidity(uint256 _nftId) external; 

    function increaseTokenLiquidity(uint256 _nftId, uint256 _amount) external;

    function owner() external view returns (address); 

    function paused() external view returns (bool);

    function removeLiquidity(uint256 _nftId, uint256 amount) external;

    function renounceOwnership() external; 

    function setMagpiePool(address _liquidityPool) external;

    function setMagpieLpToken(address _lpToken) external;

    function setMagpieListManager(address _whiteListPeriodManager) external; 

    function getLPShareInToken(uint256 _shares, address _tokenAddress) external view returns (uint256); 

    function totalLPFees(address) external view returns (uint256); 

    function totalLiquidity(address) external view returns (uint256);

    function totalReserve(address) external view returns (uint256);

    function totalShares(address) external view returns (uint256); 

    function transferOwnership(address newOwner) external; 

    function whiteListPeriodManager() external view returns (address); 

    function increaseLiquidity(address tokenAddress, uint256 amount) external; 

    function decreaseLiquidity(address tokenAddress, uint256 amount) external; /* decreaseLiquidity */

    function getLiquidity(address tokenAddress) external view returns (uint256); /* getLiquidity */
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IWormhole {

  function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

  function wrapAndTransferETH(uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

  function completeTransfer(bytes memory encodedVm) external;

  function chainId() external view returns (uint16) ;

}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpieTokenManager {
  
  struct TokenInfo {
    uint256 transferOverhead;
    bool supportedToken;
    uint256 equilibriumFee; // Percentage fee Represented in basis points
    uint256 maxFee; // Percentage fee Represented in basis points
    TokenConfig tokenConfig;
  }

  struct TokenConfig {
    uint256 min;
    uint256 max;
  }

  function getStableStateFee(address tokenAddress) external view returns (uint256);

  function getMaxFee(address tokenAddress) external view returns (uint256);

  function changeFee(
    address tokenAddress,
    uint256 _equilibriumFee,
    uint256 _maxFee
  ) external; /* updateFee */

  function tokensInfo(address tokenAddress)
    external
    view
    returns (
      uint256 transferOverhead,
      bool supportedToken,
      uint256 equilibriumFee,
      uint256 maxFee,
      TokenConfig memory config
    ); /*tokensConfig */

  function getTokensConfig(address tokenAddress) external view returns (TokenInfo memory);

  function getDepositInfo(uint256 toChainId, address tokenAddress)
    external
    view
    returns (TokenConfig memory);

  function getTransferInfo(address tokenAddress) external view returns (TokenConfig memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

interface IMagpiePool {
  function getLiquidity(address tokenAddress) external returns(uint256);

  struct BridgeOutTokenArgs {
    address tokenAddress;
    uint256 amount;
    address payable receiver;
    uint256 gasFee;
    bytes encodedVM;
  }

  struct BridgeInTokenArgs {
    uint256 toChainId;
    address tokenAddress;
    bytes32 receiver;
    uint256 amount;
    bool useTokenBridge;
  }

  function bridgeInToken(BridgeInTokenArgs calldata bridgeInArgs) external returns(uint64);

  function bridgeOutToken(BridgeOutTokenArgs calldata bridgeOutArgs) external returns(uint256);

  function transfer(
    address _tokenAddress,
    address receiver,
    uint256 _tokenAmount
  ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

library LibAssetUpgradeable {
  using LibAssetUpgradeable for address;

  address constant NATIVE_ASSETID = address(0);

  function isNative(address self) internal pure returns (bool) {
    return self == NATIVE_ASSETID;
  }

  function getBalance(address self) internal view returns (uint) {
    return
      self.isNative()
        ? address(this).balance
        : IERC20Upgradeable(self).balanceOf(address(this));
  }

  function transferFrom(
    address self,
    address from,
    address to,
    uint256 amount
  ) internal {
    SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(self), from, to, amount);
  }

  function increaseAllowance(
    address self,
    address spender,
    uint256 amount
  ) internal {
    require(!self.isNative(), "LibAsset: Allowance can't be increased for native asset");
    SafeERC20Upgradeable.safeIncreaseAllowance(IERC20Upgradeable(self), spender, amount);
  }

  function decreaseAllowance(
    address self,
    address spender,
    uint256 amount
  ) internal {
    require(!self.isNative(), "LibAsset: Allowance can't be decreased for native asset");
    SafeERC20Upgradeable.safeDecreaseAllowance(IERC20Upgradeable(self), spender, amount);
  }

  function transfer(
      address self,
      address payable recipient,
      uint256 amount
  ) internal {
    self.isNative()
      ? AddressUpgradeable.sendValue(recipient, amount)
      : SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(self), recipient, amount);
  }

  function approve(
    address self,
    address spender,
    uint256 amount
  ) internal {
    require(!self.isNative(), "LibAsset: Allowance can't be increased for native asset");
    SafeERC20Upgradeable.safeApprove(IERC20Upgradeable(self), spender, amount);
  }

  function getAllowance(address self, address owner, address spender) internal view returns (uint256) {
    return IERC20Upgradeable(self).allowance(owner, spender);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}