// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// solhint-disable func-name-mixedcase
interface ICurveAddressProvider {
  function get_registry() external view returns (address);

  function get_address(uint256 _id) external view returns (address);
}

interface ICurveRegistry {
  function get_pool_from_lp_token(address lpToken)
    external
    view
    returns (address);

  function get_lp_token(address swapAddress) external view returns (address);

  function get_n_coins(address _pool) external view returns (uint256[2] memory);

  function get_coins(address _pool) external view returns (address[8] memory);

  function get_underlying_coins(address _pool)
    external
    view
    returns (address[8] memory);
}

interface ICurveFactoryRegistry {
  function get_n_coins(address _pool) external view returns (uint256);

  function get_coins(address _pool) external view returns (address[4] memory);

  function get_underlying_coins(address _pool)
    external
    view
    returns (address[8] memory);

  function is_meta(address _pool) external view returns (bool);
}

interface ICurveCryptoRegistry {
  function get_pool_from_lp_token(address lpToken)
    external
    view
    returns (address);

  function get_lp_token(address swapAddress) external view returns (address);

  function get_n_coins(address _pool) external view returns (uint256);

  function get_coins(address _pool) external view returns (address[8] memory);
}

// solhint-enable func-name-mixedcase

contract CurveRegistry is Ownable {
  using SafeERC20 for IERC20;

  ICurveAddressProvider private constant CURVE_ADDRESS_PROVIDER =
    ICurveAddressProvider(0x0000000022D53366457F9d5E68Ec105046FC4383);

  ICurveRegistry public CurveMainRegistry;
  ICurveCryptoRegistry public CryptoRegistry;
  ICurveFactoryRegistry public FactoryRegistry;

  address private constant WBTC_ADDRESS =
    0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  address private constant SBTC_CRV_TOKEN =
    0x075b1bb99792c9E1041bA13afEf80C91a1e70fB3;
  address internal constant ETH_ADDRESS =
    0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // Mapping from {poolAddress} to {status}
  mapping(address => bool) public shouldUseUnderlying;
  // Mapping from {poolAddress} to {depositAddress}
  mapping(address => address) private depositAddresses;

  constructor() {
    CurveMainRegistry = ICurveRegistry(CURVE_ADDRESS_PROVIDER.get_registry());

    FactoryRegistry = ICurveFactoryRegistry(
      CURVE_ADDRESS_PROVIDER.get_address(3)
    );

    CryptoRegistry = ICurveCryptoRegistry(
      CURVE_ADDRESS_PROVIDER.get_address(5)
    );

    // @notice Initial assigments for deposit addresses
    depositAddresses[
      0x45F783CCE6B7FF23B2ab2D70e416cdb7D6055f51
    ] = 0xbBC81d23Ea2c3ec7e56D39296F0cbB648873a5d3;
    depositAddresses[
      0xA2B47E3D5c44877cca798226B7B8118F9BFb7A56
    ] = 0xeB21209ae4C2c9FF2a86ACA31E123764A3B6Bc06;
    depositAddresses[
      0x52EA46506B9CC5Ef470C5bf89f17Dc28bB35D85C
    ] = 0xac795D2c97e60DF6a99ff1c814727302fD747a80;
    depositAddresses[
      0x06364f10B501e868329afBc005b3492902d6C763
    ] = 0xA50cCc70b6a011CffDdf45057E39679379187287;
    depositAddresses[
      0x79a8C46DeA5aDa233ABaFFD40F3A0A2B1e5A4F27
    ] = 0xb6c057591E073249F2D9D88Ba59a46CFC9B59EdB;
    depositAddresses[
      0xA5407eAE9Ba41422680e2e00537571bcC53efBfD
    ] = 0xFCBa3E75865d2d561BE8D220616520c171F12851;

    // @notice Which pools should use underlting tokens to add liquidity
    // {address} should/n't user underlting {status}
    shouldUseUnderlying[0xDeBF20617708857ebe4F679508E7b7863a8A8EeE] = true;
    shouldUseUnderlying[0xEB16Ae0052ed37f479f7fe63849198Df1765a733] = true;
  }

  function isCurvePool(address swapAddress) public view returns (bool) {
    if (CurveMainRegistry.get_lp_token(swapAddress) != address(0)) {
      return true;
    }
    return false;
  }

  function isFactoryPool(address swapAddress) public view returns (bool) {
    if (FactoryRegistry.get_coins(swapAddress)[0] != address(0)) {
      return true;
    }
    return false;
  }

  function isCryptoPool(address swapAddress) public view returns (bool) {
    if (CryptoRegistry.get_coins(swapAddress)[0] != address(0)) {
      return true;
    }
    return false;
  }

  /**
    @notice This function is used to check if the curve pool is a metapool
    @notice all factory pools are metapools
    @param swapAddress Curve swap address for the pool
    @return isMeta true if the pool is a metapool, false otherwise
    */
  function isMetaPool(address swapAddress) public view returns (bool isMeta) {
    if (isCurvePool(swapAddress)) {
      uint256[2] memory poolTokenCounts = CurveMainRegistry.get_n_coins(
        swapAddress
      );
      if (poolTokenCounts[0] == poolTokenCounts[1]) return false;
      else return true;
    }
    if (isFactoryPool(swapAddress)) {
      if (FactoryRegistry.is_meta(swapAddress)) {
        return true;
      }
    }
    return isMeta;
  }

  /* 
    @notice This function is used to get the curve pool deposit address
    @notice The deposit address is used for pools with wrapped (c, y) tokens
    @param swapAddress Curve swap address for the pool
    @return depositAddress curve pool deposit address or the swap address not mapped
    */
  function getDepositAddress(address swapAddress)
    external
    view
    returns (address depositAddress)
  {
    depositAddress = depositAddresses[swapAddress];
    if (depositAddress == address(0)) return swapAddress;
  }

  /*
    @notice This function is used to get the curve pool swap address
    @notice The token and swap address is the same for metapool factory pools
    @param swapAddress Curve swap address for the pool
    @return swapAddress curve pool swap address or address(0) if pool doesnt exist
    */
  function getSwapAddress(address tokenAddress)
    external
    view
    returns (address swapAddress)
  {
    swapAddress = CurveMainRegistry.get_pool_from_lp_token(tokenAddress);
    if (swapAddress != address(0)) {
      return swapAddress;
    } else if (isFactoryPool(tokenAddress)) {
      return tokenAddress;
    } else if (
      CryptoRegistry.get_pool_from_lp_token(tokenAddress) != address(0)
    ) {
      return CryptoRegistry.get_pool_from_lp_token(tokenAddress);
    }
    return address(0);
  }

  /*
    @notice This function is used to check the curve pool token address
    @notice The token and swap address is the same for metapool factory pools
    @param swapAddress Curve swap address for the pool
    @return tokenAddress curve pool token address or address(0) if pool doesnt exist
    */
  function getTokenAddress(address swapAddress)
    external
    view
    returns (address tokenAddress)
  {
    tokenAddress = CurveMainRegistry.get_lp_token(swapAddress);
    if (tokenAddress != address(0)) {
      return tokenAddress;
    }
    if (isFactoryPool(swapAddress)) {
      return swapAddress;
    }
    if (isCryptoPool(swapAddress)) {
      return CryptoRegistry.get_lp_token(swapAddress);
    }
    return address(0);
  }

  /**
    @notice Checks the number of non-underlying tokens in a pool
    @param swapAddress Curve swap address for the pool
    @return count The number of underlying tokens in the pool
    */
  function getNumTokens(address swapAddress)
    public
    view
    returns (uint256 count)
  {
    if (isCurvePool(swapAddress)) {
      return CurveMainRegistry.get_n_coins(swapAddress)[0];
    } else if (isCryptoPool(swapAddress)) {
      return CryptoRegistry.get_n_coins(swapAddress);
    } else if (isFactoryPool(swapAddress)) {
      return FactoryRegistry.get_n_coins(swapAddress);
    }
  }

  /**
    @notice This function returns an array of underlying pool token addresses
    @param swapAddress Curve swap address for the pool
    @return poolTokens returns 4 element array containing the addresses of the pool tokens (0 address if pool contains < 4 tokens)
    */
  function getPoolTokens(address swapAddress)
    public
    view
    returns (address[8] memory poolTokens)
  {
    if (isMetaPool(swapAddress)) {
      if (isFactoryPool(swapAddress)) {
        address[4] memory poolTokenCounts = FactoryRegistry.get_coins(
          swapAddress
        );

        for (uint256 i = 0; i < 4; i++) {
          poolTokens[i] = poolTokenCounts[i];
          if (poolTokens[i] == address(0)) break;
        }
      } else if (isCryptoPool(swapAddress)) {
        poolTokens = CryptoRegistry.get_coins(swapAddress);
      } else {
        poolTokens = CurveMainRegistry.get_coins(swapAddress);
      }
    } else {
      if (isBtcPool(swapAddress)) {
        poolTokens = CurveMainRegistry.get_coins(swapAddress);
      } else if (isCurvePool(swapAddress)) {
        if (isEthPool(swapAddress)) {
          poolTokens = CurveMainRegistry.get_coins(swapAddress);
        } else {
          poolTokens = CurveMainRegistry.get_underlying_coins(swapAddress);
        }
      } else if (isCryptoPool(swapAddress)) {
        poolTokens = CryptoRegistry.get_coins(swapAddress);
      } else {
        address[4] memory poolTokenCounts = FactoryRegistry.get_coins(
          swapAddress
        );

        for (uint256 i = 0; i < 4; i++) {
          poolTokens[i] = poolTokenCounts[i];
          if (poolTokens[i] == address(0)) break;
        }
      }
    }
    return poolTokens;
  }

  /**
    @notice This function checks if the curve pool contains WBTC
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains WBTC, false otherwise
    */
  function isBtcPool(address swapAddress) public view returns (bool) {
    address[8] memory poolTokens = CurveMainRegistry.get_coins(swapAddress);
    for (uint256 i = 0; i < 4; i++) {
      if (poolTokens[i] == WBTC_ADDRESS || poolTokens[i] == SBTC_CRV_TOKEN)
        return true;
    }
    return false;
  }

  /**
    @notice This function checks if the curve pool contains ETH
    @param swapAddress Curve swap address for the pool
    @return true if the pool contains ETH, false otherwise
    */
  function isEthPool(address swapAddress) public view returns (bool) {
    address[8] memory poolTokens = CurveMainRegistry.get_coins(swapAddress);
    for (uint256 i = 0; i < 4; i++) {
      if (poolTokens[i] == ETH_ADDRESS) {
        return true;
      }
    }
    return false;
  }

  /**
    @notice This function is used to check if the pool contains the token
    @param swapAddress Curve swap address for the pool
    @param tokenContractAddress contract address of the token
    @return isUnderlying true if the pool contains the token, false otherwise
    @return underlyingIndex index of the token in the pool, 0 if pool does not contain the token
    */
  function isUnderlyingToken(address swapAddress, address tokenContractAddress)
    external
    view
    returns (bool isUnderlying, uint256 underlyingIndex)
  {
    address[8] memory poolTokens = getPoolTokens(swapAddress);
    for (uint256 i = 0; i < 8; i++) {
      if (poolTokens[i] == tokenContractAddress) return (true, i);
    }
  }

  /**
    @notice Updates to the latest curve main registry from the address provider
    */
  function updateCurveRegistry() external onlyOwner {
    address newAddress = CURVE_ADDRESS_PROVIDER.get_registry();
    require(address(CurveMainRegistry) != newAddress, "Already up-to-date");

    CurveMainRegistry = ICurveRegistry(newAddress);
  }

  /**
    @notice Updates to the latest curve v1 factory registry from the address provider
    */
  function updateFactoryRegistry() external onlyOwner {
    address newAddress = CURVE_ADDRESS_PROVIDER.get_address(3);
    require(address(FactoryRegistry) != newAddress, "Already up-to-date");

    FactoryRegistry = ICurveFactoryRegistry(newAddress);
  }

  /**
    @notice Updates to the latest curve crypto registry from the address provider
    */
  function updateCryptoRegistry() external onlyOwner {
    address newAddress = CURVE_ADDRESS_PROVIDER.get_address(5);
    require(address(CryptoRegistry) != newAddress, "Already up-to-date");

    CryptoRegistry = ICurveCryptoRegistry(newAddress);
  }

  /**
    @notice Add new pools which use the _use_underlying bool
    @param swapAddresses Curve swap addresses for the pool
    @param addUnderlying True if underlying tokens are always added
    */
  function updateShouldUseUnderlying(
    address[] calldata swapAddresses,
    bool[] calldata addUnderlying
  ) external onlyOwner {
    require(swapAddresses.length == addUnderlying.length, "Mismatched arrays");
    for (uint256 i = 0; i < swapAddresses.length; i++) {
      shouldUseUnderlying[swapAddresses[i]] = addUnderlying[i];
    }
  }

  /**
    @notice Add new pools which use uamounts for add_liquidity
    @param swapAddresses Curve swap addresses to map from
    @param _depositAddresses Curve deposit addresses to map to
    */
  function updateDepositAddresses(
    address[] calldata swapAddresses,
    address[] calldata _depositAddresses
  ) external onlyOwner {
    require(
      swapAddresses.length == _depositAddresses.length,
      "Mismatched arrays"
    );
    for (uint256 i = 0; i < swapAddresses.length; i++) {
      depositAddresses[swapAddresses[i]] = _depositAddresses[i];
    }
  }

  /**
    @notice Withdraws tokens that had been sent to registry address
    @param tokens ERC20 Token addressess (ZeroAddress if ETH)
    */
  function withdrawTokens(address[] calldata tokens) external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      uint256 qty;

      if (tokens[i] == ETH_ADDRESS) {
        qty = address(this).balance;
        Address.sendValue(payable(owner()), qty);
      } else {
        qty = IERC20(tokens[i]).balanceOf(address(this));
        IERC20(tokens[i]).safeTransfer(owner(), qty);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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