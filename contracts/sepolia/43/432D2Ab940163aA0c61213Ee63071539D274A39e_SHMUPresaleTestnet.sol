// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../SHMUPresale.sol";
import "../openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract SHMUPresaleTestnet is SHMUPresale {
    using SafeERC20 for IERC20Custom;

    constructor(
        address _saleToken,
        address _oracle,
        address _usdToken,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _startPrice,
        uint256 _priceShift,
        uint256 _presaleLimit
    ) SHMUPresale(_saleToken, _oracle, _usdToken, _saleStartTime, _saleEndTime, _startPrice, _priceShift, _presaleLimit) {}

    function t_resetUser(address _user) public {
        hasClaimed[_user] = false;
        purchasedTokens[_user] = 0;
    }

    function t_claimAndReset() external whenNotPaused {
        if (block.timestamp < claimStartTime || claimStartTime == 0) revert InvalidTimeframe();
        if (hasClaimed[_msgSender()]) revert AlreadyClaimed();
        uint256 amount = purchasedTokens[_msgSender()];
        if (amount == 0) revert NothingToClaim();
        hasClaimed[_msgSender()] = true;
        totalTokensClaimed += amount;
        saleToken.safeTransfer(_msgSender(), amount * 1e18);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
        t_resetUser(_msgSender());
    }

    function t_setSaleStart(uint256 _saleStart) public {
        saleStartTime = _saleStart;
    }

    function t_setSaleEnd(uint256 _saleEnd) public {
        saleEndTime = _saleEnd;
    }

    function t_setClaimeStart(uint256 _claimStart) public {
        claimStartTime = _claimStart;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "src/openzeppelin/access/Ownable.sol";
import "src/openzeppelin/security/Pausable.sol";
import "src/openzeppelin/security/ReentrancyGuard.sol";
import "src/openzeppelin/token/ERC20/utils/SafeERC20.sol";

import "src/interfaces/IChainlinkPriceFeed.sol";
import "src/interfaces/IPresale.sol";
import "src/interfaces/IERC20Custom.sol";

/// @title Presale contract for ShibaMemu token
/// @dev The contract is designed to work on the ethereum and binance blockchains
contract SHMUPresale is IPresale, Pausable, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20Custom;

    /// @notice Address of token contract
    IERC20Custom public immutable saleToken;

    /// @notice Address of USD stablecoin
    IERC20Custom public immutable usdToken;

    /// @notice Address of USD stablecoin
    bytes32 immutable usdTokenSymbol;

    /// @notice Address of USD stablecoin
    uint8 immutable usdTokenDecimals;

    /// @notice Address of chainlink nativeCurrency/USD price feed
    IChainlinkPriceFeed public immutable oracle;

    /// @notice Last stage index
    uint256 public immutable presaleLimit;

    /// @notice Starting price for 1 token
    /// @dev Value will have same decimal places as in used USD stablecoin
    uint256 immutable startPrice;

    /// @notice The amount by which the price changes every day
    /// @dev Value will have same decimal places as in used USD stablecoin
    uint256 immutable priceShift;

    /// @notice Total amount of purchased tokens
    uint256 public totalTokensSold;

    /// @notice Total amount of claimed tokens
    uint256 public totalTokensClaimed;

    /// @notice Total price of all sold tokens in USD
    uint256 public totalSoldPrice;

    /// @notice Timestamp when purchased tokens claim starts
    uint256 public claimStartTime;

    /// @notice Timestamp when presale starts
    uint256 public saleStartTime;

    /// @notice Timestamp when presale ends
    uint256 public saleEndTime;

    /// @notice Stores the number of tokens purchased by each user that have not yet been claimed
    mapping(address => uint256) public purchasedTokens;

    /// @notice Indicates whbnber the user is blacklisted or not
    mapping(address => bool) public blacklist;

    /// @notice Indicates whbnber the user already claimed or not
    mapping(address => bool) public hasClaimed;

    /// @notice Checks that it is now possible to purchase passed amount tokens
    /// @param amount - the number of tokens to verify the possibility of purchase
    modifier verifyPurchase(uint256 amount) {
        if (block.timestamp < saleStartTime || block.timestamp >= saleEndTime) revert InvalidTimeframe();
        if (amount == 0) revert BuyAtLeastOneToken();
        if (amount + totalTokensSold > presaleLimit)
            revert PresaleLimitExceeded(presaleLimit - totalTokensSold);
        _;
    }

    /// @notice Verifies that the sender isn't blacklisted
    modifier notBlacklisted() {
        if (blacklist[_msgSender()]) revert AddressBlacklisted();
        _;
    }

    /// @notice Creates the contract
    /// @param _saleToken      - Address of presailing token
    /// @param _oracle         - Address of Chainlink nativeCurrency/USD price feed
    /// @param _usdToken       - Address of USD stablecoin
    /// @param _startPrice     - Starting price for 1 token
    /// @param _priceShift     - The amount by which the price changes every day
    /// @param _presaleLimit   - Amount of tokens that available for presale
    /// @param _saleStartTime  - Sale start time
    /// @param _saleEndTime    - Sale end time
    constructor(
        address _saleToken,
        address _oracle,
        address _usdToken,
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _startPrice,
        uint256 _priceShift,
        uint256 _presaleLimit
    ) {
        if (_oracle == address(0)) revert ZeroAddress("Aggregator");
        if (_usdToken == address(0)) revert ZeroAddress("USD token");
        if (_saleToken == address(0)) revert ZeroAddress("Sale token");

        saleToken = IERC20Custom(_saleToken);
        oracle = IChainlinkPriceFeed(_oracle);
        usdToken = IERC20Custom(_usdToken);
        usdTokenSymbol = bytes32(bytes(usdToken.symbol()));
        usdTokenDecimals = usdToken.decimals();
        startPrice = _startPrice;
        priceShift = _priceShift;
        presaleLimit = _presaleLimit;
        saleStartTime = _saleStartTime;
        saleEndTime = _saleEndTime;

        emit SaleTimeUpdated(_saleStartTime, _saleEndTime, block.timestamp);
    }

    /// @notice To pause the presale
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice To unpause the presale
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice To add users to blacklist
    /// @param _users - Array of addresses to add in blacklist
    function addToBlacklist(address[] calldata _users) external onlyOwner {
        uint256 usersAmount = _users.length;
        uint256 i = 0;
        while (i < usersAmount) {
            blacklist[_users[i]] = true;
            emit AddedToBlacklist(_users[i], block.timestamp);
            i += 1;
        }
    }

    /// @notice To remove users from blacklist
    /// @param _users - Array of addresses to remove from blacklist
    function removeFromBlacklist(address[] calldata _users) external onlyOwner {
        uint256 usersAmount = _users.length;
        uint256 i = 0;
        while (i < usersAmount) {
            blacklist[_users[i]] = false;
            emit RemovedFromBlacklist(_users[i], block.timestamp);
            i += 1;
        }
    }

    /// @notice To update the sale start and end times
    /// @param _saleStartTime - New sales start time
    /// @param _saleEndTime   - New sales end time
    /// @dev It is planned that the owner of the contracts will be a multi-signature wallet and the passed parameters will be checked several times and will definitely be correct
    function configureSaleTimeframe(uint256 _saleStartTime, uint256 _saleEndTime) external onlyOwner {
        require(claimStartTime == 0, "Claim start is configured");
        if (saleStartTime != _saleStartTime) saleStartTime = _saleStartTime;
        if (saleEndTime != _saleEndTime) saleEndTime = _saleEndTime;
        emit SaleTimeUpdated(_saleStartTime, _saleEndTime, block.timestamp);
    }

    /// @notice To set the claim start time
    /// @param _claimStartTime - claim start time
    /// @notice Function also makes sure that presale have enough sale token balance
    /// @dev Function can be executed only after the end of the presale, so totalTokensSold value here is final and will not change
    function configureClaim(uint256 _claimStartTime) external onlyOwner {
        if (block.timestamp < saleEndTime) revert PresaleNotEnded();
        require(saleToken.balanceOf(address(this)) >= totalTokensSold * 1e18, "Not enough tokens on contract");
        claimStartTime = _claimStartTime;
        emit ClaimTimeUpdated(_claimStartTime, block.timestamp);
    }

    function rescueERC20(address _contract, uint256 _amount) public onlyOwner {
        if (_contract == address(saleToken)) {
            require(claimStartTime != 0, "Only after claim configured");
            require(_amount <= saleToken.balanceOf(address(this)) - (totalSoldPrice - totalTokensClaimed) * 1e18, "Transfer purchased tokens");
        }
        require(_amount <= IERC20Custom(_contract).balanceOf(address(this)), "Not enough balance");
        IERC20Custom(_contract).safeTransfer(msg.sender, _amount);
        emit TokensRescued(_contract, _amount, block.timestamp);
    }

    /// @notice To claim tokens after claiming starts
    function claim() external whenNotPaused {
        if (block.timestamp < claimStartTime || claimStartTime == 0) revert InvalidTimeframe();
        if (hasClaimed[_msgSender()]) revert AlreadyClaimed();
        uint256 amount = purchasedTokens[_msgSender()];
        if (amount == 0) revert NothingToClaim();
        hasClaimed[_msgSender()] = true;
        totalTokensClaimed += amount;
        saleToken.safeTransfer(_msgSender(), amount * 1e18);
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
    }

    /// @notice To buy into a presale using native chain currency with referrer
    /// @param _amount - Amount of tokens to buy
    /// @param _referrerId - id of the referrer
    function buyWithNativeCoin(
        uint256 _amount,
        uint256 _referrerId
    ) public payable notBlacklisted verifyPurchase(_amount) whenNotPaused nonReentrant {
        (uint256 priceInNativeCoin, uint256 priceInUSD) = getPrice(_amount);
        if (msg.value < priceInNativeCoin) revert NotEnoughBNB(msg.value, priceInNativeCoin);
        uint256 excess = msg.value - priceInNativeCoin;
        totalTokensSold += _amount;
        totalSoldPrice += priceInUSD;
        purchasedTokens[_msgSender()] += _amount;
        _sendValue(payable(owner()), priceInNativeCoin);
        if (excess > 0) _sendValue(payable(_msgSender()), excess);
        emit TokensBought(_msgSender(), "Native", _amount, priceInUSD, priceInNativeCoin, _referrerId, block.timestamp);
    }

    /// @notice To buy into a presale using USD with referrer
    /// @param _amount - Amount of tokens to buy
    /// @param _referrerId - id of the referrer
    function buyWithUSD(
        uint256 _amount,
        uint256 _referrerId
    ) public notBlacklisted verifyPurchase(_amount) whenNotPaused nonReentrant {
        (uint256 priceInNativeCoin, uint256 priceInUSD) = getPrice(_amount);
        uint256 allowance = usdToken.allowance(_msgSender(), address(this));
        if (priceInUSD > allowance) revert NotEnoughAllowance(allowance, priceInUSD);
        totalTokensSold += _amount;
        totalSoldPrice += priceInUSD;
        purchasedTokens[_msgSender()] += _amount;
        usdToken.safeTransferFrom(_msgSender(), owner(), priceInUSD);
        emit TokensBought(_msgSender(), usdTokenSymbol, _amount, priceInUSD, priceInNativeCoin, _referrerId, block.timestamp);
    }

    /// @notice Returns current price
    function getCurrentPrice() public view returns (uint256) {
        return startPrice + priceShift * getCurrentDay();
    }

    function getCurrentDay() public view returns (uint256 currentDay) {
        uint256 firstTimestamp = saleStartTime;
        if (firstTimestamp > block.timestamp) return 0;
        uint256 lastTimestamp = block.timestamp > saleEndTime ? saleEndTime : block.timestamp;
        require(firstTimestamp <= lastTimestamp, "The first timestamp is after the last");
        currentDay = (lastTimestamp - firstTimestamp) / 1 days;
    }

    /// @notice Helper function to calculate price in native coin and USD for given amount
    /// @param _amount - Amount of tokens to buy
    /// @return priceInNativeCoin - price for passed amount of tokens in native coin in 1e18 format
    /// @return priceInUSD - price for passed amount of tokens in USD
    /// @dev Price in USD will be returned with same decimals as in used usd stablecoin contract
    function getPrice(uint256 _amount) public view returns (uint256 priceInNativeCoin, uint256 priceInUSD) {
        if (_amount + totalTokensSold > presaleLimit)
            revert PresaleLimitExceeded(presaleLimit - totalTokensSold);
        priceInUSD = getCurrentPrice() * _amount;

        (uint80 roundID, int256 price, , uint256 updatedAt, uint80 answeredInRound) = oracle.latestRoundData();
        require(answeredInRound >= roundID, "Stale price");
        require(updatedAt >= block.timestamp - 3 hours, "Stale price");
        require(price > 0, "Invalid price");
        priceInNativeCoin = (priceInUSD * 10 ** (26 - usdTokenDecimals)) / uint256(price);
    }

    /// @notice For sending native currency from contract
    /// @param _recipient - Recipient address
    /// @param _amount - Amount of native currency to send in wei
    function _sendValue(address payable _recipient, uint256 _amount) internal {
        require(address(this).balance >= _amount, "Low balance");
        (bool success, ) = _recipient.call{ value: _amount }("");
        require(success, "Payment failed");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IChainlinkPriceFeed {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "src/openzeppelin/token/ERC20/IERC20.sol";

interface IERC20Custom is IERC20 {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IPresale {
    event SaleTimeUpdated(uint256 saleStartTime, uint256 saleEndTime, uint256 timestamp);

    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);

    event TokensBought(
        address indexed user,
        bytes32 indexed purchaseMethod,
        uint256 amount,
        uint256 totalCostInUsd,
        uint256 totalCostInBNB,
        uint256 indexed referrerId,
        uint256 timestamp
    );

    event TokensRescued(address indexed contract_, uint256 amount, uint256 timestamp);

    event AddedToBlacklist(address indexed user, uint256 timestamp);

    event RemovedFromBlacklist(address indexed user, uint256 timestamp);

    event ClaimTimeUpdated(uint256 claimStartTime, uint256 timestamp);

    /// @notice Function can not be called now
    error InvalidTimeframe();

    /// @notice Function can not be called before end of presale
    error PresaleNotEnded();

    /// @notice Trying to buy 0 tokens
    error BuyAtLeastOneToken();

    /// @notice Passed amount is more than amount of tokens remaining for presale
    /// @param tokensRemains - amount of tokens remaining for presale
    error PresaleLimitExceeded(uint256 tokensRemains);

    /// @notice User is in blacklist
    error AddressBlacklisted();

    /// @notice If zero address was passed
    /// @param contractName - name indicator of the corresponding contract
    error ZeroAddress(string contractName);

    /// @notice Passed amount of BNB is not enough to buy requested amount of tokens
    /// @param sent - amount of BNB was sent
    /// @param expected - amount of BNB necessary to buy requested amount of tokens
    error NotEnoughBNB(uint256 sent, uint256 expected);

    /// @notice Provided allowance is not enough to buy requested amount of tokens
    /// @param provided - amount of allowance provided to the contract
    /// @param expected - amount of BUSD necessary to buy requested amount of tokens
    error NotEnoughAllowance(uint256 provided, uint256 expected);

    /// @notice User already claimed bought tokens
    error AlreadyClaimed();

    /// @notice No tokens were purchased by this user
    error NothingToClaim();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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