// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import './security/PausableUpgradeable.sol';
import './interfaces/IMagpieProviders.sol';
import './interfaces/IMagpieTokenManager.sol';
import './interfaces/IMagpieLPToken.sol';

contract MagpieListManager is Initializable, OwnableUpgradeable, PausableUpgradeable {
  IMagpieProviders private magpieProviders;
  IMagpieTokenManager private magpieTokenManager;
  IMagpieLPToken private magpieLPToken;
  bool public areMagpieListRestrictionsEnabled;

  /* LP Status */
  // EOA? -> status, stores addresses that we want to ignore, like staking contracts.
  mapping(address => bool) private isExcludedAddress;

  /* Caps */
  // Token Address -> Limit
  mapping(address => uint256) public perTokenTotalCap;
  // Token Address -> Limit
  mapping(address => uint256) public perTokenWalletCap;

  event ExcludedAddressStatusUpdated(address indexed lp, bool indexed status);
  event TotalCapUpdated(address indexed token, uint256 totalCap);
  event PerTokenWalletCap(address indexed token, uint256 perCommunityWalletCap);
  event WhiteListStatusUpdated(bool status);

  modifier onlyLiquidityPool() {
    require(msg.sender == address(magpieProviders), 'MagpieListManager: unauthorized');
    _;
  }

  modifier onlyLpNft() {
    require(msg.sender == address(magpieLPToken), 'MagpieListManager: unauthorized');
    _;
  }

  modifier tokenChecks(address tokenAddress) {
    require(tokenAddress != address(0), 'MagpieListManager: tokenAddress invalid');
    require(_isSupportedToken(tokenAddress), 'MagpieListManager: tokenAddress not supported');
    _;
  }

  function initialize(
    address _liquidityProviders,
    address _tokenManager,
    address _lpToken,
    address _pauser
  ) external initializer {
    __Ownable_init();
    __Pausable_init(_pauser);
    areMagpieListRestrictionsEnabled = true;
    _setLiquidityProviders(_liquidityProviders);
    _setTokenManager(_tokenManager);
    _setLpToken(_lpToken);
  }

  function _isSupportedToken(address _token) private view returns (bool) {
    return magpieTokenManager.getTokensConfig(_token).supportedToken;
  }

  /**
   * @dev Internal Function which checks for various caps before allowing LP to add liqudity
   */
  function _beforeAddingLiquidity(
    address,
    address _token,
    uint256 _amount
  ) private {
    // Per Token Total Cap or PTTC
    require(
      ifEnabled(
        magpieProviders.getLiquidityProvidedByToken(_token) + _amount <= perTokenTotalCap[_token]
      ),
      'MagpieListManager: perTokenTotalCap exceeded'
    );
  }

  /**
   * @dev External Function which checks for various caps before allowing LP to add liqudity. Only callable by LiquidityPoolManager
   */
  function beforeAddingLiquidity(
    address _lp,
    address _token,
    uint256 _amount
  ) external onlyLiquidityPool whenNotPaused {
    _beforeAddingLiquidity(_lp, _token, _amount);
  }

  /**
   * @dev Internal Function which checks for various caps before allowing LP to remove liqudity
   */
  function _beforeRemovingLiquidity(
    address,
    address,
    uint256
  ) internal pure {
    return;
  }

  /**
   * @dev External Function which checks for various caps before allowing LP to remove liqudity. Only callable by LiquidityPoolManager
   */
  function beforeRemovingLiquidity(
    address _lp,
    address _token,
    uint256 _amount
  ) external view onlyLiquidityPool whenNotPaused {
    _beforeRemovingLiquidity(_lp, _token, _amount);
  }

  /**
   * @dev External Function which checks for various caps before allowing LP to transfer their LpNFT. Only callable by LpNFT contract
   */
  function beforeTransferringLiquidity(
    address,
    address,
    address,
    uint256
  ) external view onlyLpNft whenNotPaused {
    return;
  }

  function _setTokenManager(address _magpieTokenManager) internal {
    magpieTokenManager = IMagpieTokenManager(_magpieTokenManager);
  }

  function setTokenManager(address _tokenManager) external onlyOwner {
    _setTokenManager(_tokenManager);
  }

  function _setLiquidityProviders(address _magpieProviders) internal {
    magpieProviders = IMagpieProviders(_magpieProviders);
  }

  function setLiquidityProviders(address _liquidityProviders) external onlyOwner {
    _setLiquidityProviders(_liquidityProviders);
  }

  function _setLpToken(address _magpieLPToken) internal {
    magpieLPToken = IMagpieLPToken(_magpieLPToken);
  }

  function setLpToken(address _lpToken) external onlyOwner {
    _setLpToken(_lpToken);
  }

  function setIsExcludedAddressStatus(address[] memory _addresses, bool[] memory _status)
    external
    onlyOwner
  {
    require(_addresses.length == _status.length, 'MagpieListManager: length mismatch');
    uint256 length = _addresses.length;
    for (uint256 i; i < length; ) {
      isExcludedAddress[_addresses[i]] = _status[i];
      emit ExcludedAddressStatusUpdated(_addresses[i], _status[i]);
      unchecked {
        ++i;
      }
    }
  }

  function setTotalCap(address _token, uint256 _totalCap) public tokenChecks(_token) onlyOwner {
    require(
      magpieProviders.getLiquidityProvidedByToken(_token) <= _totalCap,
      'MagpieListManager: totalCap less than set limit'
    );
    require(
      _totalCap >= perTokenWalletCap[_token],
      'MagpieListManager: totalCap less than perTokenWalletCap'
    );
    if (perTokenTotalCap[_token] != _totalCap) {
      perTokenTotalCap[_token] = _totalCap;
      emit TotalCapUpdated(_token, _totalCap);
    }
  }

  /**
   * @dev Special care must be taken when calling this function
   *      There are no checks for _perTokenWalletCap (since it's onlyOwner), but it's essential that it
   *      should be >= max lp provided by an lp.
   *      Checking this on chain will probably require implementing a bbst, which needs more bandwidth
   *      Call the view function getMaxCommunityLpPositon() separately before changing this value
   */
  function setPerTokenWalletCap(address _token, uint256 _perTokenWalletCap)
    public
    tokenChecks(_token)
    onlyOwner
  {
    require(
      _perTokenWalletCap <= perTokenTotalCap[_token],
      'MagpieListManager: perTokenWalletCap greater than perTokenTotalCap'
    );
    if (perTokenWalletCap[_token] != _perTokenWalletCap) {
      perTokenWalletCap[_token] = _perTokenWalletCap;
      emit PerTokenWalletCap(_token, _perTokenWalletCap);
    }
  }

  function setCap(
    address _token,
    uint256 _totalCap,
    uint256 _perTokenWalletCap
  ) public onlyOwner {
    setTotalCap(_token, _totalCap);
    setPerTokenWalletCap(_token, _perTokenWalletCap);
  }

  function setCaps(
    address[] memory _tokens,
    uint256[] memory _totalCaps,
    uint256[] memory _perTokenWalletCaps
  ) external onlyOwner {
    require(
      _tokens.length == _totalCaps.length && _totalCaps.length == _perTokenWalletCaps.length,
      'MagpieListManager: length mismatch'
    );
    uint256 length = _tokens.length;
    for (uint256 i; i < length; ) {
      setCap(_tokens[i], _totalCaps[i], _perTokenWalletCaps[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Enables (or disables) reverts if liquidity exceeds caps.
   *      Even if this is disabled, the contract will continue to track LP's positions
   */
  function setAreMagpieListRestrictionsEnabled(bool _status) external onlyOwner {
    areMagpieListRestrictionsEnabled = _status;
    emit WhiteListStatusUpdated(_status);
  }

  /**
   * @dev returns the value of if (areWhiteListEnabled) then (_cond)
   */
  function ifEnabled(bool _cond) private view returns (bool) {
    return !areMagpieListRestrictionsEnabled || (areMagpieListRestrictionsEnabled && _cond);
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

interface IMagpieLPToken {
  struct MagpieLPTokenInfo {
    address token;
    uint256 suppliedLiquidity;
    uint256 shares;
  }

  function approve(address to, uint256 tokenId) external;

  function balanceOf(address _owner) external view returns (uint256);

  function exists(uint256 _tokenId) external view returns (bool);

  function getApproved(uint256 tokenId) external view returns (address);

  function initialize(
    string memory _name,
    string memory _symbol
  ) external;

  function isApprovedForAll(address _owner, address operator) external view returns (bool);

  function magpiePoolAddress() external view returns (address);

  function mint(address _to) external returns (uint256);

  function name() external view returns (string memory);

  function owner() external view returns (address);

  function ownerOf(uint256 tokenId) external view returns (address);

  function paused() external view returns (bool);

  function renounceOwnership() external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) external;

  function setApprovalForAll(address operator, bool approved) external;

  function setMagpiePool(address _lpm) external;

  function setMagpieListManager(address _whiteListPeriodManager) external;

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  function symbol() external view returns (string memory);

  function tokenByIndex(uint256 index) external view returns (uint256);

  function tokenMetadata(uint256)
    external
    view
    returns (
      address token,
      uint256 totalSuppliedLiquidity,
      uint256 totalShares
    );

  function tokenOfOwnerByIndex(address _owner, uint256 index) external view returns (uint256);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  function totalSupply() external view returns (uint256);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferOwnership(address newOwner) external;

  function updateTokenInfo(uint256 _tokenId, MagpieLPTokenInfo memory _magpielpTokenInfo) external;

  function magpieListManager() external view returns (address);
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