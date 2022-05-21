// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/MyCoin.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A simple ERC-20 staking contract for the Uniswap testnet.
/// @author Sfy Mantissa
contract Staking is Ownable {

  /// @notice Get the staked token balance of the account.
  mapping(address => uint256) public balanceOf;

  /// @notice Get last stake timestamp of the account.
  mapping(address => uint256) public stakeStartTimestampOf;

  /// @notice Get whether the account already claimed the reward.
  mapping(address => bool) public hasClaimedReward;

  /// @notice Get the stake token address.
  address public stakeTokenAddress;

  /// @notice Get the reward token address.
  address public rewardTokenAddress;

  /// @notice Get the percentage of staked tokens which is returned every
  ///         rewardInterval as reward tokens.
  uint256 public rewardPercentage;

  /// @notice Get the interval for reward returns.
  uint256 public rewardInterval;

  /// @notice Get the interval for which `claim()`
  ///         function remains unavailable.
  uint256 public lockInterval;

  /// @notice Gets triggered when tokens are staked by the account.
  event Staked(address from, uint256 amount);

  /// @notice Gets triggered when tokens are unstaked by the account.
  event Unstaked(address to, uint256 amount);

  /// @notice Get triggered when the reward is claimed by the account.
  event Claimed(address to, uint256 amount);

  /// @notice All constructor params are actually set in config.ts.
  constructor(
    address _stakeTokenAddress,
    address _rewardTokenAddress,
    uint256 _rewardPercentage,
    uint256 _rewardInterval,
    uint256 _lockInterval
  ) 
  {
    stakeTokenAddress = _stakeTokenAddress;
    rewardTokenAddress = _rewardTokenAddress;
    rewardPercentage = _rewardPercentage;
    rewardInterval = _rewardInterval;
    lockInterval = _lockInterval;

  }

  /// @notice Allows the user to stake a specified `amount` of tokens.
  /// @dev The implied usage cycle is stake() → claim() → unstake() → ...
  /// @param _amount The amount of tokens to be staked.
  function stake(uint256 _amount) 
    external
  {
    require(
      !hasClaimedReward[msg.sender],
      "ERROR: must unstake after claiming the reward to stake again."
    );

    IUniswapV2Pair(stakeTokenAddress).transferFrom(
      msg.sender,
      address(this),
      _amount
    );

    balanceOf[msg.sender] += _amount;
    stakeStartTimestampOf[msg.sender] = block.timestamp;

    emit Staked(msg.sender, _amount);
  }

  /// @notice Allows the user to unstake all staked tokens.
  function unstake()
    external
  {
    require(
      hasClaimedReward[msg.sender],
      "ERROR: must claim reward before unstaking."
    );

    uint256 amount = balanceOf[msg.sender];
    
    IUniswapV2Pair(stakeTokenAddress).transfer(
      msg.sender,
      amount
    );

    balanceOf[msg.sender] = 0;
    hasClaimedReward[msg.sender] = false;

    emit Unstaked(msg.sender, amount);
  }

  /// @notice Allows the user to claim the reward.
  function claim()
    external
  {
    require(
      block.timestamp >= stakeStartTimestampOf[msg.sender] + lockInterval,
      "ERROR: must wait for lock interval to pass."
    );

    require(
      !hasClaimedReward[msg.sender],
      "ERROR: already claimed the reward."
    );

    uint256 rewardPerRewardInterval = 
      balanceOf[msg.sender] * rewardPercentage / 100;

    uint256 rewardTotal = 
      rewardPerRewardInterval * (
        (block.timestamp - stakeStartTimestampOf[msg.sender]) / rewardInterval
    );

    hasClaimedReward[msg.sender] = true;
    MyCoin(rewardTokenAddress).mint(msg.sender, rewardTotal);

    emit Claimed(msg.sender, rewardTotal);
  }

  /// @notice Allows the owner to change the rewardInterval.
  function changeRewardInterval(uint256 _rewardInterval)
    external
    onlyOwner
  {
    rewardInterval = _rewardInterval;
  }

  /// @notice Allows the owner to change the lockInterval.
  function changeLockInterval(uint256 _lockInterval)
    external
    onlyOwner
  {
    lockInterval = _lockInterval;
  }

  /// @notice Allows the owner to change the rewardPercentage.
  function changeRewardPercentage(uint256 _rewardPercentage)
    external
    onlyOwner
  {
    rewardPercentage = _rewardPercentage;
  }
}

/// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

/// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface MyCoin {

  event Transfer(address indexed seller, address indexed buyer, uint256 amount);
  event Approval(address indexed owner, address indexed delegate, uint256 amount);

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
  function transfer(address buyer, uint256 amount) external returns (bool);
  function transferFrom(address seller, address buyer, uint256 amount) external returns (bool);
  function approve(address delegate, uint256 amount) external returns (bool);
  function burn(address account, uint256 amount) external returns (bool);
  function mint(address account, uint256 amount) external returns (bool);

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