// File: @openzeppelin/contracts/token/ERC20/IERC20.sol
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

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

// File: contracts/Vesting.sol


pragma solidity ^0.8.2;


contract Vesting is Ownable {
  event AddVestingEvent(address addr, uint8 vestingType, uint256 balance);
  event ClaimEvent(address addr, uint8 vestingType, uint256 balance);

  enum VestingType {
    PRIVATE_SALE,
    TEAM,
    MARKETING,
    TREASURY
  }

  // DST ERC20 token address
  address public dstAddress;

  // Vesting info per type
  struct VestingInfo {
    // Start time
    uint256 startTime;
    // vesting start time = start time + vesting month
    uint8 vestingStartMonth;
    // maximum addable balance
    uint256 totalBalance;
      // current added balance
    uint256 addedBalance;
    // current claimed balance
    uint256 claimedBalance;
    // bias point for initial release. Initial release amount is total vesting balance * initialBp / 10000
    uint16 initialBp;
    // bias point for periodic release. Periodic release amount is total vesting balance * (number of passed month * periodBp) / 10000
    uint16 periodBp;
  }

  // Vesting info per address
  struct VestingAccountInfo {
    uint8 vestingType;
    uint256 totalBalance;
    uint256 claimedBalance;
    uint256 createdTime;
    uint256 lastClaimedTime;
  }

  mapping(uint8 => VestingInfo) public vestingInfos;
  mapping(address => VestingAccountInfo) public vestingAccountInfos;

  constructor() {
    vestingInfos[uint8(VestingType.PRIVATE_SALE)] = VestingInfo({
      startTime: 0,
      vestingStartMonth: 6,
      // 16.50% of total supply
      totalBalance: 165000000 * 10 ** 18,
      addedBalance: 0,
      claimedBalance: 0,
      // 5% of total private sale vesting(0.825% of total supply)
      initialBp: 500,
      // 4% of total private vesting(0.66% of total supply)
      periodBp: 400
    });

    vestingInfos[uint8(VestingType.TEAM)] = VestingInfo({
      startTime: 0,
      vestingStartMonth: 12,
      // 8% of total supply
      totalBalance: 80000000 * 10 ** 18,
      addedBalance: 0,
      claimedBalance: 0,
      // 0%
      initialBp: 0,
      // 2.8% of total team vesting(0.224% of total supply)
      periodBp: 280
    });

    vestingInfos[uint8(VestingType.MARKETING)] = VestingInfo({
      startTime: 0,
      vestingStartMonth: 0,
      // 5.5% of total supply
      totalBalance: 55000000 * 10 ** 18,
      addedBalance: 0,
      claimedBalance: 0,
      // 10% of total marketing vesting(0.55% of total supply)
      initialBp: 1000,
      // 10% of total marketing vesting(0.55% of total supply)
      periodBp: 1000
    });

    vestingInfos[uint8(VestingType.TREASURY)] = VestingInfo({
      startTime: 0,
      vestingStartMonth: 1,
      // 29% of total supply
      totalBalance: 290000000 * 10 ** 18,
      addedBalance: 0,
      claimedBalance: 0,
      // 10% of total treasury vesting(2.9% of total supply)
      initialBp: 1000,
      // 1% of total treasury vesting(0.29% of total supply)
      periodBp: 100
    });
  }

  function setDSTAddress(address addr) public onlyOwner {
    // Check address is ERC20
    IERC20(addr).balanceOf(addr);
    dstAddress = addr;
  }

  function setStartTime(uint8 vestingType, uint256 timestamp) public onlyOwner {
    // Check vesting type
    require(vestingType >= uint8(VestingType.PRIVATE_SALE) && vestingType <= uint8(VestingType.TREASURY), "wrong vesting type");

    // Check timestamp
    require(timestamp > block.timestamp, "should be future");

    VestingInfo storage vestingInfo_ = vestingInfos[vestingType];

    // Can't set start time twice
    require(vestingInfo_.startTime == 0, "already set start time");

    vestingInfo_.startTime = timestamp;
  }

  function add(uint8 vestingType, uint256 balance, address addr) public onlyOwner {
    require(dstAddress != address(0), "no dst address");
    // Check vesting type
    require(vestingType >= uint8(VestingType.PRIVATE_SALE) && vestingType <= uint8(VestingType.TREASURY), "wrong vesting type");

    // Check total balance
    VestingInfo storage vestingInfo_ = vestingInfos[vestingType];
    require(vestingInfo_.totalBalance >= vestingInfo_.addedBalance + balance, "over total balance");

    // Check admin's DST balance
    uint256 adminBalance = IERC20(dstAddress).balanceOf(msg.sender);
    uint256 allowance = IERC20(dstAddress).allowance(msg.sender, address(this));
    require(allowance >= balance, "need approve");
    require(adminBalance >= balance, "not enough balance");

    // Check address's vesting info
    require(vestingAccountInfos[addr].createdTime == 0, "alreay added address");

    vestingAccountInfos[addr] = VestingAccountInfo({
      vestingType: vestingType,
      totalBalance: balance,
      claimedBalance: 0,
      createdTime: block.timestamp,
      lastClaimedTime: 0
    });

    // Transfer DST: Contract caller(Admin) -> Contract
    IERC20(dstAddress).transferFrom(msg.sender, address(this), balance);

    // Update added balance
    vestingInfo_.addedBalance += balance;

    // Update vesting account info
    vestingAccountInfos[addr].vestingType = vestingType;
    vestingAccountInfos[addr].totalBalance = balance;

    emit AddVestingEvent(addr, vestingType, balance);
  }

  function claim() public {
    // Check existence of vesting account info
    require(vestingAccountInfos[msg.sender].createdTime > 0, "no vesting");

    // Check vesting is started
    VestingInfo storage vestingInfo = vestingInfos[vestingAccountInfos[msg.sender].vestingType];
    require(vestingInfo.startTime > 0 && vestingInfo.startTime <= block.timestamp, "not started yet");

    // Check claimable balance
    uint256 balance = getClaimableBalance(msg.sender);
    require(balance > 0, "no balance");
    require(vestingInfo.claimedBalance + balance <= vestingInfo.totalBalance, "over total balance");
    require(vestingAccountInfos[msg.sender].claimedBalance + balance <= vestingAccountInfos[msg.sender].totalBalance, "over account total balance");

    // Update claimed balance of total vesting
    vestingInfo.claimedBalance += balance;

    // Update claimed balance of account
    vestingAccountInfos[msg.sender].claimedBalance += balance;
    vestingAccountInfos[msg.sender].lastClaimedTime = block.timestamp;

    // Transfer DST: Contract -> Contract caller
    IERC20(dstAddress).transfer(msg.sender, balance);

    emit ClaimEvent(msg.sender, vestingAccountInfos[msg.sender].vestingType, balance);
  }

  // Calculate claimable token
  function getClaimableBalance(address addr) public view returns (uint256) {
    require(vestingAccountInfos[addr].createdTime > 0, "no account info");
    uint256 balance = _getClaimableBalance(vestingAccountInfos[addr].vestingType, vestingAccountInfos[addr].totalBalance, vestingAccountInfos[addr].claimedBalance, block.timestamp);

    return balance;
  }

  function _getClaimableBalance(uint8 vestingType, uint256 totalBalance, uint256 claimedBalance, uint256 time) public view returns (uint256) {
    // Check vesting type
    require(vestingType >= uint8(VestingType.PRIVATE_SALE) && vestingType <= uint8(VestingType.TREASURY), "wrong vesting type");

    VestingInfo memory vestingInfo = vestingInfos[vestingType];
    if (vestingInfo.startTime == 0 || time < vestingInfo.startTime) {
      return 0;
    }

    uint256 balance = 0;
    if (vestingType == uint8(VestingType.MARKETING)) {
      // Marketing vesting amount is released by 10% every 4 months.
      uint256 monthDiff = (time - vestingInfo.startTime) / 120 days + 1;
      balance += totalBalance / 10000 * vestingInfo.periodBp * monthDiff;
    } else {
      // Add initial released amount
      balance += totalBalance / 10000 * vestingInfo.initialBp;

      // Add periodic released amount
      uint256 vestingStartTime = vestingInfo.startTime + uint256(vestingInfo.vestingStartMonth) * 30 days;
      // Vesting amount except markting is released by periodic bias percent every each month.
      if (time > vestingStartTime) {
        uint monthDiff = (time - vestingStartTime) / 30 days + 1;
        balance += totalBalance / 10000 * vestingInfo.periodBp * monthDiff;
      }
    }

    // Check claimed amount
    if (claimedBalance >= balance) {
      return 0;
    }

    // Subtract claimed amount
    balance -= claimedBalance;

    // Check balance is over total balance
    if (balance + claimedBalance > totalBalance) {
      return totalBalance - claimedBalance;
    }

    return balance;
  }

  function getVestingInfo(uint8 vestingType) public view returns (VestingInfo memory) {
    // Check vesting type
    require(vestingType >= uint8(VestingType.PRIVATE_SALE) && vestingType <= uint8(VestingType.TREASURY), "wrong vesting type");
    return vestingInfos[vestingType];
  }

  function getVestingAccountInfo(address addr) public view returns (VestingAccountInfo memory) {
    return vestingAccountInfos[addr];
  }
}