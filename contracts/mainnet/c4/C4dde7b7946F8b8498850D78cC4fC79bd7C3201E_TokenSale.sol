pragma solidity 0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

contract TokenSale is Ownable {
    uint256 public constant SALE_DURATION = 1_900_510; // 21 days in seconds
    uint256 public constant LOCK_DURATION = 15_768_000; // 6 months in seconds
    uint256 public constant VESTING_DURATION = 25_920_000; // 10 months in seconds
    uint256 public constant MAX_SUPPLY = 30_000_000 * 10 ** 18; // total tokens available for sale
    string public constant VIRTUAL_BONDING_CURVE_COEFFICIENT = "0.000000005"; // pricing coefficient to facilitate public sale starting price
    AggregatorV3Interface public immutable priceFeed;

    bool public isPaused;
    bool public saleOpen;
    bool public hasReclaimed;
    uint256 public totalPurchased;
    uint256 public startingBalance;
    uint256 public saleEndTime;
    uint256 public lockEndTime;
    uint256 public vestingEndTime;
    uint256 public whitelistCount;
    uint256 public presaleMinimum = 5000 * 10 ** 6; // 6 decimals for dollar
    uint256 public whitelistMinimum = 1000 * 10 ** 6;
    uint256 public tokensPerUSD = (25 * 10 ** 18) / 10 ** 6; // Tokens received per dollar, using 6 decimals
    address public adminAddress;

    IERC20 public yoloToken;

    mapping(address => uint256) public purchasedAmount;
    mapping(address => uint256) public claimedAmount;
    mapping(address => bool) public whitelist;

    event SaleOpen(
        uint256 timestamp,
        uint256 saleEndTime,
        uint256 lockEndTime,
        uint256 vestingEndTime
    );
    event Buy(address indexed user, uint256 weiIn, uint256 tokenAllocated);
    event TokensClaimed(address indexed user, uint256 tokensToClaim);
    event Withdraw(address indexed receiver, uint256 weiAmount);
    event TokenReclamation(address indexed receiver, uint256 weiAmount);

    modifier onlyAdmin() {
        require(
            msg.sender == adminAddress || msg.sender == owner(),
            "Only admin may call"
        );
        _;
    }

    modifier whenSaleOpen() {
        require(saleOpen, "Sale is not open");
        require(block.timestamp < saleEndTime, "Sale has ended");
        _;
    }

    modifier beforeSaleOpen() {
        require(!saleOpen, "Sale is already open");
        _;
    }

    modifier whenUnpaused() {
        require(!isPaused, "Sale is paused");
        _;
    }

    modifier whenClaimingPeriod() {
        require(block.timestamp >= lockEndTime, "Tokens are locked");
        _;
    }

    modifier canReclaim() {
        require(!hasReclaimed, "Tokens already reclaimed");
        _;
    }

    constructor(address _token) {
        yoloToken = IERC20(_token);
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    function getVestedAmount(address user) public view returns (uint256) {
        if (block.timestamp < lockEndTime || lockEndTime == 0) {
            return 0;
        } else if (block.timestamp >= vestingEndTime) {
            return purchasedAmount[user];
        } else {
            // console.log("purchasedAmount %s", purchasedAmount[user]);

            uint256 vestingDuration = vestingEndTime - lockEndTime;
            uint256 timeSinceLockEnd = block.timestamp - lockEndTime;
            // console.log(
            //     "claim amount %s",
            //     (purchasedAmount[user] * timeSinceLockEnd) / vestingDuration
            // );
            return (purchasedAmount[user] * timeSinceLockEnd) / vestingDuration;
        }
    }

    function setAdminAddress(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0), "Admin must not be zero address");
        adminAddress = _adminAddress;
    }

    function pause() external onlyOwner {
        require(!isPaused, "Already paused");
        isPaused = true;
    }

    function unpause() external onlyOwner {
        require(isPaused, "Already unpaused");
        isPaused = false;
    }

    function addToWhitelist(address user) external onlyAdmin {
        require(whitelistCount < 100, "100 max reached");
        require(!whitelist[user], "User already whitelisted");

        whitelist[user] = true;
        ++whitelistCount;
    }

    function setWhitelistMinimum(uint256 minimum) external onlyOwner {
        whitelistMinimum = minimum;
    }

    function setPresaleMinimum(uint256 minimum) external onlyOwner {
        presaleMinimum = minimum;
    }

    function getLatestEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // console.log("cl price:");
        // console.logInt(price);
        return uint256(price);
    }

    function openSale() external onlyOwner beforeSaleOpen {
        require(
            yoloToken.balanceOf(address(this)) >= MAX_SUPPLY,
            "Not enough tokens transferred to contract for sale"
        );

        saleOpen = true;
        saleEndTime = block.timestamp + SALE_DURATION;
        lockEndTime = saleEndTime + LOCK_DURATION;
        vestingEndTime = lockEndTime + VESTING_DURATION;
        startingBalance = yoloToken.balanceOf(address(this));
    }

    function buy() external payable whenSaleOpen whenUnpaused {
        uint256 latestEthPrice = getLatestEthPrice();
        // (oracle)1e8 * (msg.value)1e18  / (1e8 * 1e18)
        uint256 usdAmount = (latestEthPrice * msg.value) / 10 ** 20; // 1e6 decimal like usdc

        require(usdAmount >= presaleMinimum, "Below amount minimum");

        _buy(usdAmount);
    }

    function whitelistBuy() external payable whenSaleOpen whenUnpaused {
        uint256 latestEthPrice = getLatestEthPrice();
        // (oracle)1e8 * (msg.value)1e18 / (1e8 * 1e18)
        uint256 usdAmount = (latestEthPrice * msg.value) / 10 ** 20; // decimal 10e6

        require(whitelist[msg.sender] == true, "Not in whitelist");
        require(
            usdAmount >= whitelistMinimum,
            "Below whitelist amount minimum"
        );

        _buy(usdAmount);
    }

    function _buy(uint256 usdAmount) internal {
        // console.log("usd amount: %s:", usdAmount);
        uint256 tokenAmount = usdAmount * tokensPerUSD;

        require(
            totalPurchased + tokenAmount <= MAX_SUPPLY,
            "Max supply exceeded"
        );

        totalPurchased += tokenAmount;
        purchasedAmount[msg.sender] += tokenAmount;
        emit Buy(msg.sender, msg.value, tokenAmount);
    }

    function claim() external whenClaimingPeriod {
        uint256 tokensToClaim = getVestedAmount(msg.sender) -
            claimedAmount[msg.sender];
        require(tokensToClaim > 0, "No tokens to claim");

        // Transfer the tokens to the user
        yoloToken.transfer(msg.sender, tokensToClaim);

        claimedAmount[msg.sender] += tokensToClaim;

        emit TokensClaimed(msg.sender, tokensToClaim);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether to withdraw");

        payable(owner()).transfer(balance);

        emit Withdraw(msg.sender, balance);
    }

    function reclaimTokens() external onlyOwner canReclaim {
        require(block.timestamp > saleEndTime, "Reclaiming is not allowed yet");

        uint256 remainingBalance = startingBalance - totalPurchased;
        require(remainingBalance > 0, "No tokens to reclaim"); // should be unreachable - cant open sale

        yoloToken.transfer(msg.sender, remainingBalance);

        hasReclaimed = true;

        emit TokenReclamation(msg.sender, remainingBalance);
    }
}

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