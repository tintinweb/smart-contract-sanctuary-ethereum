// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

/*
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Storage is Ownable {
  /// @dev Bytes storage.
  mapping(bytes32 => bytes) private _bytes;

  /// @dev Bool storage.
  mapping(bytes32 => bool) private _bool;

  /// @dev Uint storage.
  mapping(bytes32 => uint256) private _uint;

  /// @dev Int storage.
  mapping(bytes32 => int256) private _int;

  /// @dev Address storage.
  mapping(bytes32 => address) private _address;

  /// @dev String storage.
  mapping(bytes32 => string) private _string;

  event Updated(bytes32 indexed key);

  /**
   * @param key The key for the record
   */
  function getBytes(bytes32 key) external view returns (bytes memory) {
    return _bytes[key];
  }

  /**
   * @param key The key for the record
   */
  function getBool(bytes32 key) external view returns (bool) {
    return _bool[key];
  }

  /**
   * @param key The key for the record
   */
  function getUint(bytes32 key) external view returns (uint256) {
    return _uint[key];
  }

  /**
   * @param key The key for the record
   */
  function getInt(bytes32 key) external view returns (int256) {
    return _int[key];
  }

  /**
   * @param key The key for the record
   */
  function getAddress(bytes32 key) external view returns (address) {
    return _address[key];
  }

  /**
   * @param key The key for the record
   */
  function getString(bytes32 key) external view returns (string memory) {
    return _string[key];
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setBytes(bytes32 key, bytes calldata value) external onlyOwner {
    _bytes[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setBool(bytes32 key, bool value) external onlyOwner {
    _bool[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setUint(bytes32 key, uint256 value) external onlyOwner {
    _uint[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setInt(bytes32 key, int256 value) external onlyOwner {
    _int[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setAddress(bytes32 key, address value) external onlyOwner {
    _address[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   * @param value The value to set.
   */
  function setString(bytes32 key, string calldata value) external onlyOwner {
    _string[key] = value;
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteBytes(bytes32 key) external onlyOwner {
    delete _bytes[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteBool(bytes32 key) external onlyOwner {
    delete _bool[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteUint(bytes32 key) external onlyOwner {
    delete _uint[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteInt(bytes32 key) external onlyOwner {
    delete _int[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteAddress(bytes32 key) external onlyOwner {
    delete _address[key];
    emit Updated(key);
  }

  /**
   * @param key The key for the record
   */
  function deleteString(bytes32 key) external onlyOwner {
    delete _string[key];
    emit Updated(key);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Storage.sol";
import "./dex/IPair.sol";
import "./dex/IRouter.sol";

interface IPriceFeed {
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

contract BuyLiquidity is Ownable {
  /// @notice Storage contract
  Storage public info;

  /// @notice Treasury contract
  address payable public treasury;

  /// @notice Fee token to USD price feed contract
  IPriceFeed public priceFeed;

  struct Swap {
    address[] path;
    uint256 outMin;
  }

  event StorageChanged(address indexed info);

  event TreasuryChanged(address indexed treasury);

  event PriceFeedChanged(address indexed priceFeed);

  constructor(
    address _info,
    address payable _terasury,
    address _priceFeed
  ) {
    info = Storage(_info);
    treasury = _terasury;
    priceFeed = IPriceFeed(_priceFeed);
  }

  /**
   * @notice Change storage contract address.
   * @param _info New storage contract address.
   */
  function changeStorage(address _info) external onlyOwner {
    info = Storage(_info);
    emit StorageChanged(_info);
  }

  /**
   * @notice Change treasury contract address.
   * @param _treasury New treasury contract address.
   */
  function changeTreasury(address payable _treasury) external onlyOwner {
    treasury = _treasury;
    emit TreasuryChanged(treasury);
  }

  /**
   * @notice Change price feed contract address.
   * @param _priceFeed New price feed contract address.
   */
  function changePrireFeed(address _priceFeed) external onlyOwner {
    priceFeed = IPriceFeed(_priceFeed);
    emit PriceFeedChanged(_priceFeed);
  }

  function _swap(
    address router,
    uint256 amount,
    uint256 outMin,
    address[] memory path,
    uint256 deadline
  ) internal {
    if (path[0] == path[path.length - 1]) return;

    IRouter(router).swapExactTokensForTokensSupportingFeeOnTransferTokens(
      amount,
      outMin,
      path,
      address(this),
      deadline
    );
  }

  /**
   * @return Current call commission.
   */
  function fee() public view returns (uint256) {
    uint256 feeUSD = info.getUint(keccak256("DFH:Fee:Automate:BuyLiquidity"));
    if (feeUSD == 0) return 0;

    (, int256 answer, , , ) = priceFeed.latestRoundData();
    require(answer > 0, "BuyLiquidity::fee: invalid fee token price");

    return (feeUSD * (10**18)) / uint256(answer);
  }

  function buyLiquidity(
    uint256 amount,
    address router,
    Swap memory swap0,
    Swap memory swap1,
    IPair to,
    uint256 deadline
  ) external payable {
    require(
      info.getBool(keccak256(abi.encodePacked("DFH:Contract:BuyLiquidity:allowedRouter:", router))),
      "BuyLiquidity::buyLiquidity: invalid router address"
    );
    require(swap0.path[0] == swap1.path[0], "BuyLiquidity::buyLiqudity: start token not equals");

    // Pay commission
    uint256 payFee = fee();
    require(msg.value >= payFee, "BuyLiquidity::buyLiqudity: insufficient funds to pay commission");
    treasury.transfer(payFee);
    if (msg.value > payFee) {
      payable(msg.sender).transfer(msg.value - payFee);
    }

    // Get amount
    address token0 = to.token0();
    require(swap0.path[swap0.path.length - 1] == token0, "BuyLiquidity::buyLiqudity: invalid token0");
    address token1 = to.token1();
    require(swap1.path[swap1.path.length - 1] == token1, "BuyLiquidity::buyLiqudity: invalid token1");
    IERC20(swap0.path[0]).transferFrom(msg.sender, address(this), amount);
    IERC20(swap0.path[0]).approve(router, amount);

    // Swap tokens
    uint256 amount0In = amount / 2;
    _swap(router, amount0In, swap0.outMin, swap0.path, deadline);
    uint256 amount1In = amount - amount0In;
    _swap(router, amount1In, swap1.outMin, swap1.path, deadline);

    // Add liquidity
    amount0In = IERC20(token0).balanceOf(address(this));
    amount1In = IERC20(token1).balanceOf(address(this));
    IERC20(token0).approve(router, amount0In);
    IERC20(token1).approve(router, amount1In);
    IRouter(router).addLiquidity(token0, token1, amount0In, amount1In, 0, 0, msg.sender, deadline);

    // Return remainder
    uint256 tokenBalance = IERC20(token0).balanceOf(address(this));
    if (tokenBalance > 0) {
      IERC20(token0).transfer(msg.sender, tokenBalance);
    }
    tokenBalance = IERC20(token1).balanceOf(address(this));
    if (tokenBalance > 0) {
      IERC20(token1).transfer(msg.sender, tokenBalance);
    }
    tokenBalance = IERC20(swap0.path[0]).balanceOf(address(this));
    if (tokenBalance > 0) {
      IERC20(swap0.path[0]).transfer(msg.sender, tokenBalance);
    }
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPair is IERC20 {
  function token0() external view returns (address);

  function token1() external view returns (address);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

interface IRouter {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
}