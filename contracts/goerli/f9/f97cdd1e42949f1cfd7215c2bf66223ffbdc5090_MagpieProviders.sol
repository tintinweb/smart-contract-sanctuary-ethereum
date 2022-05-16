// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import './security/PausableUpgradeable.sol';
import './interfaces/IMagpieLPToken.sol';
import './interfaces/IMagpieTokenManager.sol';
import './interfaces/IMagpieListManager.sol';
import './interfaces/IMagpiePool.sol';
import './lib/LibAssetUpgradeable.sol';

contract MagpieProviders is
  Initializable,
  ReentrancyGuardUpgradeable,
  OwnableUpgradeable,
  PausableUpgradeable
{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using LibAssetUpgradeable for address;

  uint256 public constant decimalPrecision = 10**18;

  IMagpieLPToken private magpieLPToken;
  IMagpiePool private magpiePool;
  IMagpieTokenManager private magpieTokenManager;
  IMagpieListManager private magpieListManager;

  event LiquidityAdded(address indexed tokenAddress, uint256 indexed amount, address indexed lp);
  event LiquidityRemoved(address indexed tokenAddress, uint256 indexed amount, address indexed lp);
  event FeeClaimed(
    address indexed tokenAddress,
    uint256 indexed fee,
    address indexed lp,
    uint256 sharesBurnt
  );
  event FeeAdded(address indexed tokenAddress, uint256 indexed fee);
  event EthReceived(address indexed sender, uint256 value);
  event CurrentLiquidityChanged(address indexed token, uint256 indexed newValue);

  // LP Fee Distribution
  mapping(address => uint256) public totalReserve; // Include Liquidity + Fee accumulated
  mapping(address => uint256) public totalLiquidity; // Include Liquidity only
  mapping(address => uint256) public currentLiquidity; // Include current liquidity, updated on every in and out transfer
  mapping(address => uint256) public totalLPFees;
  mapping(address => uint256) public totalShares;

  /**
   * @dev Modifier for checking to validate a NFTId and it's ownership
   * @param _tokenId token id to validate
   * @param _transactor typically msgSender(), passed to verify against owner of _tokenId
   */
  modifier onlyValidLpToken(uint256 _tokenId, address _transactor) {
    (address token, , ) = magpieLPToken.tokenMetadata(_tokenId);
    require(magpieLPToken.exists(_tokenId), 'MagpieProvider: tokenId does not exist');
    require(
      magpieLPToken.ownerOf(_tokenId) == _transactor,
      'MagpieProvider: transactor does not own NFT'
    );
    _;
  }

  /**
   * @dev Modifier for checking if msg.sender in liquiditypool
   */
  modifier onlyMagpiePool() {
    require(msg.sender == address(magpiePool), 'MagpieProvider: unauthorized');
    _;
  }

  modifier tokenChecks(address tokenAddress) {
    require(tokenAddress != address(0), 'MagpieProvider: tokenAddress invalid');
    require(_isSupportedToken(tokenAddress), 'MagpieProvider: tokenAddress not supported');
    _;
  }

  function initialize(
    address _magpieLPToken,
    address _magpieTokenManager,
    address _magpiePauser
  ) public initializer {
    __Ownable_init();
    __Pausable_init(_magpiePauser);
    __ReentrancyGuard_init();
    _setLPToken(_magpieLPToken);
    _setTokenManager(_magpieTokenManager);
  }

  function _isSupportedToken(address _token) private view returns (bool) {
    return magpieTokenManager.getTokensConfig(_token).supportedToken;
  }

  function getTotalReserveByToken(address tokenAddress) public view returns (uint256) {
    return totalReserve[tokenAddress];
  }

  function getLiquidityProvidedByToken(address tokenAddress) public view returns (uint256) {
    return totalLiquidity[tokenAddress];
  }

  function getTotalLPFeeByToken(address tokenAddress) public view returns (uint256) {
    return totalLPFees[tokenAddress];
  }

  function getLiquidity(address tokenAddress) public view returns (uint256) {
    return currentLiquidity[tokenAddress];
  }

  /**
   * @dev To be called post initialization, used to set address of NFT Contract
   * @param _lpToken address of lpToken
   */
  function setLpToken(address _lpToken) external onlyOwner {
    _setLPToken(_lpToken);
  }

  /**
   * private method to set LP token contract.
   */
  function _setLPToken(address _lpToken) private {
    magpieLPToken = IMagpieLPToken(_lpToken);
  }

  function increaseLiquidity(address tokenAddress, uint256 amount) external onlyMagpiePool {
    _increaseCurrentLiquidity(tokenAddress, amount);
  }

  function decreaseLiquidity(address tokenAddress, uint256 amount) external onlyMagpiePool {
    _decreaseCurrentLiquidity(tokenAddress, amount);
  }

  function _increaseCurrentLiquidity(address tokenAddress, uint256 amount) private {
    currentLiquidity[tokenAddress] += amount;
    emit CurrentLiquidityChanged(tokenAddress, currentLiquidity[tokenAddress]);
  }

  function _decreaseCurrentLiquidity(address tokenAddress, uint256 amount) private {
    currentLiquidity[tokenAddress] -= amount;
    emit CurrentLiquidityChanged(tokenAddress, currentLiquidity[tokenAddress]);
  }

  /**
   * Public method to set TokenManager contract.
   */
  function setMagpieTokenManager(address _tokenManager) external onlyOwner {
    _setTokenManager(_tokenManager);
  }

  /**
   * private method to set TokenManager contract.
   */
  function _setTokenManager(address _tokenManager) private {
    magpieTokenManager = IMagpieTokenManager(_tokenManager);
  }

  /**
   * @dev To be called post initialization, used to set address of magpieListManager Contract
   * @param _magpieListManager address of magpieListManager
   */
  function setMagpieListManager(address _magpieListManager) external onlyOwner {
    magpieListManager = IMagpieListManager(_magpieListManager);
  }

  /**
   * @dev To be called post initialization, used to set address of LiquidityPool Contract
   * @param _liquidityPool address of LiquidityPool
   */
  function setMagpiePool(address _liquidityPool) external onlyOwner {
    magpiePool = IMagpiePool(_liquidityPool);
  }

  /**
   * @dev Returns price of Base token in terms of LP Shares
   * @param _baseToken address of baseToken
   * @return Price of Base token in terms of LP Shares
   */
  function getTokenPriceInLPShares(address _baseToken) public view returns (uint256) {
    uint256 supply = totalShares[_baseToken];
    if (supply > 0) {
      return totalShares[_baseToken] / totalReserve[_baseToken];
    }
    return decimalPrecision;
  }

  /**
   * @dev Converts shares to token amount
   */

  function getLPShareInToken(uint256 _shares, address _tokenAddress) public view returns (uint256) {
    return (_shares * totalReserve[_tokenAddress]) / totalShares[_tokenAddress];
  }

  function getFeeAccumulatedOnNft(uint256 _nftId) public view returns (uint256) {
    require(magpieLPToken.exists(_nftId), 'MagpieProvider: nftID invalid');

    (address _tokenAddress, uint256 nftSuppliedLiquidity, uint256 totalNFTShares) = magpieLPToken
      .tokenMetadata(_nftId);

    if (totalNFTShares == 0) {
      return 0;
    }
    // Calculate rewards accumulated
    uint256 eligibleLiquidity = getLPShareInToken(totalNFTShares, _tokenAddress);
    uint256 lpFeeAccumulated;

    // Handle edge cases where eligibleLiquidity is less than what was supplied by very small amount
    if (nftSuppliedLiquidity > eligibleLiquidity) {
      lpFeeAccumulated = 0;
    } else {
      unchecked {
        lpFeeAccumulated = eligibleLiquidity - nftSuppliedLiquidity;
      }
    }
    return lpFeeAccumulated;
  }

  /**
   * @dev Records fee being added to total reserve
   * @param _token Address of Token for which LP fee is being added
   * @param _amount Amount being added
   */
  function updateLPFee(address _token, uint256 _amount)
    external
    onlyMagpiePool
    tokenChecks(_token)
    whenNotPaused
  {
    totalReserve[_token] += _amount;
    totalLPFees[_token] += _amount;
    emit FeeAdded(_token, _amount);
  }

  /**
   * @dev private function to add liquidity to a new NFT
   */
  function _addLiquidity(address _token, uint256 _amount) private {
    require(_amount > 0, 'MagpieProvider: cannot add 0 amount');
    uint256 nftId = magpieLPToken.mint(msg.sender);
    IMagpieLPToken.MagpieLPTokenInfo memory data = IMagpieLPToken.MagpieLPTokenInfo(_token, 0, 0);
    magpieLPToken.updateTokenInfo(nftId, data);
    _increaseLiquidity(nftId, _amount);
  }

  /**
   * @dev Function to mint a new NFT for a user, add token liquidity and store the
   *      record in the newly minted NFT
   * @param _token Address of token for which liquidity is to be added
   * @param _amount Amount of liquidity added
   */
  function addTokenLiquidity(address _token, uint256 _amount)
    external
    nonReentrant
    tokenChecks(_token)
    whenNotPaused
  {
    require(
      _token.getAllowance(msg.sender, address(this)) >= _amount,
      'MagpieProvider: insufficient balance'
    );
    _token.transferFrom(msg.sender, address(magpiePool), _amount);
    _addLiquidity(_token, _amount);
  }

  /**
   * @dev private helper function to increase liquidity in a given NFT
   */
  function _increaseLiquidity(uint256 _nftId, uint256 _amount)
    private
    onlyValidLpToken(_nftId, msg.sender)
  {
    (address token, uint256 totalSuppliedLiquidity, uint256 shares) = magpieLPToken.tokenMetadata(
      _nftId
    );

    require(_amount > 0, 'MagpieProvider: invalid amount');
    magpieListManager.beforeAddingLiquidity(msg.sender, token, _amount);

    uint256 mintedSharesAmount;
    // Adding liquidity in the pool for the first time
    if (totalReserve[token] == 0) {
      mintedSharesAmount = decimalPrecision * _amount;
    } else {
      mintedSharesAmount = (_amount * totalShares[token]) / totalReserve[token];
    }

    require(
      mintedSharesAmount >= decimalPrecision,
      'MagpieProvider: amount below minimum liquidity'
    );

    totalLiquidity[token] += _amount;
    totalReserve[token] += _amount;
    totalShares[token] += mintedSharesAmount;

    IMagpieLPToken.MagpieLPTokenInfo memory data = IMagpieLPToken.MagpieLPTokenInfo(
      token,
      totalSuppliedLiquidity + _amount,
      shares + mintedSharesAmount
    );
    magpieLPToken.updateTokenInfo(_nftId, data);

    // Increase the current liquidity
    _increaseCurrentLiquidity(token, _amount);
    emit LiquidityAdded(token, _amount, msg.sender);
  }

  /**
   * @dev Function to allow LPs to add ERC20 token liquidity to existing NFT
   * @param _nftId ID of NFT for updating the balances
   * @param _amount Token amount to be added
   */
  function increaseTokenLiquidity(uint256 _nftId, uint256 _amount)
    external
    nonReentrant
    whenNotPaused
  {
    (address token, , ) = magpieLPToken.tokenMetadata(_nftId);
    require(_isSupportedToken(token), 'MagpieProvider: token not supported');
    require(
      token.getAllowance(msg.sender, address(this)) >= _amount,
      'MagpieProvider: insufficient allowance'
    );
    token.transferFrom(msg.sender, address(magpiePool), _amount);
    _increaseLiquidity(_nftId, _amount);
  }

  /**
   * @dev Function to allow LPs to remove their liquidity from an existing NFT
   *      Also automatically redeems any earned fee
   */
  function removeLiquidity(uint256 _nftId, uint256 _amount)
    external
    nonReentrant
    onlyValidLpToken(_nftId, msg.sender)
    whenNotPaused
  {
    (address _tokenAddress, uint256 nftSuppliedLiquidity, uint256 totalNFTShares) = magpieLPToken
      .tokenMetadata(_nftId);
    require(_isSupportedToken(_tokenAddress), 'MagpieProvider: tokenAddress not supported');

    require(_amount > 0, 'MagpieProvider: invalid amount');
    require(nftSuppliedLiquidity >= _amount, 'MagpieProvider: insufficient liquidity');
    magpieListManager.beforeRemovingLiquidity(msg.sender, _tokenAddress, _amount);
    // Claculate how much shares represent input amount
    uint256 lpSharesForInputAmount = _amount * getTokenPriceInLPShares(_tokenAddress);

    // Calculate rewards accumulated
    uint256 eligibleLiquidity = getLPShareInToken(totalNFTShares, _tokenAddress);

    uint256 lpFeeAccumulated;

    // Handle edge cases where eligibleLiquidity is less than what was supplied by very small amount
    if (nftSuppliedLiquidity > eligibleLiquidity) {
      lpFeeAccumulated = 0;
    } else {
      unchecked {
        lpFeeAccumulated = eligibleLiquidity - nftSuppliedLiquidity;
      }
    }
    // Calculate amount of lp shares that represent accumulated Fee
    uint256 lpSharesRepresentingFee = lpFeeAccumulated * getTokenPriceInLPShares(_tokenAddress);

    totalLPFees[_tokenAddress] -= lpFeeAccumulated;
    uint256 amountToWithdraw = _amount + lpFeeAccumulated;
    uint256 lpSharesToBurn = lpSharesForInputAmount + lpSharesRepresentingFee;

    // Handle round off errors to avoid dust lp token in contract
    if (totalNFTShares - lpSharesToBurn < decimalPrecision) {
      lpSharesToBurn = totalNFTShares;
    }
    totalReserve[_tokenAddress] -= amountToWithdraw;
    totalLiquidity[_tokenAddress] -= _amount;
    totalShares[_tokenAddress] -= lpSharesToBurn;

    _decreaseCurrentLiquidity(_tokenAddress, _amount);

    _burnSharesFromNft(_nftId, lpSharesToBurn, _amount, _tokenAddress);

    _transferFromLiquidityPool(_tokenAddress, msg.sender, amountToWithdraw);

    emit LiquidityRemoved(_tokenAddress, amountToWithdraw, msg.sender);
  }

  /**
   * @dev Function to allow LPs to claim the fee earned on their NFT
   * @param _nftId ID of NFT where liquidity is recorded
   */
  function withdrawFee(uint256 _nftId)
    external
    onlyValidLpToken(_nftId, msg.sender)
    whenNotPaused
    nonReentrant
  {
    (address _tokenAddress, uint256 nftSuppliedLiquidity, uint256 totalNFTShares) = magpieLPToken
      .tokenMetadata(_nftId);
    require(_isSupportedToken(_tokenAddress), 'MagpieProvider: tokenAddress not supported');

    uint256 lpSharesForSuppliedLiquidity = nftSuppliedLiquidity *
      getTokenPriceInLPShares(_tokenAddress);

    // Calculate rewards accumulated
    uint256 eligibleLiquidity = getLPShareInToken(totalNFTShares, _tokenAddress);
    uint256 lpFeeAccumulated = eligibleLiquidity - nftSuppliedLiquidity;
    require(lpFeeAccumulated > 0, 'MagpieProvider: no rewards to claim');
    // Calculate amount of lp shares that represent accumulated Fee
    uint256 lpSharesRepresentingFee = totalNFTShares - lpSharesForSuppliedLiquidity;

    totalReserve[_tokenAddress] -= lpFeeAccumulated;
    totalShares[_tokenAddress] -= lpSharesRepresentingFee;
    totalLPFees[_tokenAddress] -= lpFeeAccumulated;

    _burnSharesFromNft(_nftId, lpSharesRepresentingFee, 0, _tokenAddress);
    _transferFromLiquidityPool(_tokenAddress, msg.sender, lpFeeAccumulated);
    emit FeeClaimed(_tokenAddress, lpFeeAccumulated, msg.sender, lpSharesRepresentingFee);
  }

  /*
   * @dev private Function to burn LP shares and remove liquidity from existing NFT
   */
  function _burnSharesFromNft(
    uint256 _nftId,
    uint256 _shares,
    uint256 _tokenAmount,
    address _tokenAddress
  ) private {
    (, uint256 nftSuppliedLiquidity, uint256 nftShares) = magpieLPToken.tokenMetadata(_nftId);
    nftShares -= _shares;
    nftSuppliedLiquidity -= _tokenAmount;

    magpieLPToken.updateTokenInfo(
      _nftId,
      IMagpieLPToken.MagpieLPTokenInfo(_tokenAddress, nftSuppliedLiquidity, nftShares)
    );
  }

  function _transferFromLiquidityPool(
    address _tokenAddress,
    address _receiver,
    uint256 _tokenAmount
  ) private {
    magpiePool.transfer(_tokenAddress, _receiver, _tokenAmount);
  }

  function getLiquidityProvidedByLPShare(uint256 _nftId) external view returns (uint256) {
    (, uint256 totalSuppliedLiquidity, ) = magpieLPToken.tokenMetadata(_nftId);
    return totalSuppliedLiquidity;
  }

  receive() external payable {
    emit EthReceived(msg.sender, msg.value);
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

interface IMagpieListManager {
  function areMagpieListRestrictionsEnabled() external view returns (bool);

  function beforeAddingLiquidity(
    address _lp,
    address _token,
    uint256 _amount
  ) external;

  function beforeRemovingLiquidity(
    address _lp,
    address _token,
    uint256 _amount
  ) external;

  function beforeTransferringLiquidity(
    address _from,
    address _to,
    address _token,
    uint256 _amount
  ) external;

  function getMaxCommunityLpAmount(address _token) external view returns (uint256);

  function initialize(
    address _liquidityProviders,
    address _tokenManager
  ) external;

  function isExcludedAddress(address) external view returns (bool);

  function owner() external view returns (address);

  function paused() external view returns (bool);

  function totalCapPerToken(address) external view returns (uint256);

  function WalletCapPerToken(address) external view returns (uint256);

  function renounceOwnership() external;

  function setareMagpieListRestrictionsEnabled(bool _status) external;

  function setCap(
    address _token,
    uint256 _totalCap,
    uint256 _perTokenWalletCap
  ) external;

  function setCaps(
    address[] memory _tokens,
    uint256[] memory _totalCaps,
    uint256[] memory _perTokenWalletCaps
  ) external;

  function setIsExcludedAddressStatus(address[] memory _addresses, bool[] memory _status) external;

  function setMagpieProviders(address _liquidityProviders) external;

  function setWalletCapPerToken(address _token, uint256 _perTokenWalletCap) external;

  function setMagpieTokenManager(address _tokenManager) external;

  function setTotalCap(address _token, uint256 _totalCap) external;

  function transferOwnership(address newOwner) external;
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