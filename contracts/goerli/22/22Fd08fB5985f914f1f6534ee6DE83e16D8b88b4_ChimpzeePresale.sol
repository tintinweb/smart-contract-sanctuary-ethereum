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

/**    ______  ____  ____  _____  ____    ____  _______   ________  ________  ________  
 *   .' ___  ||_   ||   _||_   _||_   \  /   _||_   __ \ |  __   _||_   __  ||_   __  | 
 *  / .'   \_|  | |__| |    | |    |   \/   |    | |__) ||_/  / /    | |_ \_|  | |_ \_| 
 *  | |         |  __  |    | |    | |\  /| |    |  ___/    .'.' _   |  _| _   |  _| _  
 *  \ `.___.'\ _| |  | |_  _| |_  _| |_\/_| |_  _| |_     _/ /__/ | _| |__/ | _| |__/ | 
 *   `.____ .'|____||____||_____||_____||_____||_____|   |________||________||________| 
 */

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract ChimpzeePresale is Ownable, Pausable, ReentrancyGuard {
    uint256 public totalTokensSold = 0;
    uint256 public totalTokensSoldWithBonus = 0;
    uint256 public totalUsdRaised = 0;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimStart;
    uint256 public baseDecimals = (10**18);
    uint256 public maxTokensToBuy = 500_000_000;
    uint256 public minUsdAmountToBuy = 50000000000000000000; 
    uint256 public currentStage = 0;
    uint256 public checkPoint = 0;

    uint256[][3] public stages;
    uint256[][2] public bonuses = [[uint256(75), 150, 250, 500], [uint256(25), 50, 75, 100]];

    address public saleTokenAdress;

    // For Goerli testnet (DONT FORGET TO CHANGE FOR PROD)
    IERC20 public USDTInterface = IERC20(0x71Ee5CFb3b517c9C8c584e1c33eD6C74d300cb3d);
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);

    mapping(address => uint256) public userDeposits;
    mapping(address => bool) public hasClaimed;

    // Events
    event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);
    event SaleTimeUpdated(bytes32 indexed key, uint256 prevValue, uint256 newValue, uint256 timestamp);
    event TokensBought(address indexed user, uint256 indexed tokensBought, uint256 bonusTokens, uint256 totalTokens, address indexed purchaseToken, uint256 amountPaid, uint256 usdEq, uint256 timestamp);
    event TokensAdded(address indexed token, uint256 noOfTokens, uint256 timestamp);
    event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
    event ClaimStartUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);

     /**
     * @dev Initializes the contract and sets key parameters
     * @param _startTime start time of the presale
     * @param _endTime end time of the presale
     * @param _stages stage data
     */
    constructor (uint256 _startTime, uint256 _endTime, uint256[][3] memory _stages) {
        require(_startTime > block.timestamp && _endTime > _startTime, "Invalid time");
        startTime = _startTime;
        endTime = _endTime;
        stages = _stages;
        emit SaleTimeSet(startTime, endTime, block.timestamp);
    }

    /**
     * @dev To pause the presale
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev To unpause the presale
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev To change maxTokensToBuy amount
     * @param _maxTokensToBuy New max token amount
     */
    function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyOwner {
        require(_maxTokensToBuy > 0, 'Zero max tokens to buy value');
        maxTokensToBuy = _maxTokensToBuy;
    }

    /**
     * @dev To change minUsdAmountToBuy. If zero, there is no min limit.
     * @param _minUsdAmount New min USD amount
     */
    function changeMinUsdAmountToBuy(uint256 _minUsdAmount) external onlyOwner {
        minUsdAmountToBuy = _minUsdAmount;
    }

    /**
     * @dev To change stages data
     * @param _stages New stage data
     */
    function changeStages(uint256[][3] memory _stages) external onlyOwner {
        stages = _stages;
    }

    /**
     * @dev To change bonus data
     * @param _bonuses New bonus data
     */
    function changeBonuses(uint256[][2] memory _bonuses) external onlyOwner {
        bonuses = _bonuses;
    }

    /**
     * @dev To change USDT interface
     * @param _address Address of the USDT interface
     */
    function changeUSDTInterface(address _address) external onlyOwner {
        USDTInterface = IERC20(_address);
    }

    /**
     * @dev To change aggregator interface
     * @param _address Address of the aggregator interface
     */
    function changeAggregatorInterface(address _address) external onlyOwner {
        priceFeed = AggregatorV3Interface(_address);
    }

    modifier checkSaleState(uint256 amount) {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Invalid time for buying"
        );
        require(amount > 0, "Invalid sale amount");
        _;
    }

    /**
     * @dev To calculate the price in USD for given amount of tokens.
     * @param _amount No of tokens
     */
    function calculatePrice(uint256 _amount) public view returns (uint256) {
        uint256 USDTAmount;
        uint256 total = checkPoint == 0 ? totalTokensSold : checkPoint;
        require(_amount <= maxTokensToBuy, 'Amount exceeds max tokens to buy');
        if (_amount + total > stages[0][currentStage] || block.timestamp >= stages[2][currentStage]) {
            require(currentStage < (stages[0].length - 1), 'Not valid');
            if (block.timestamp >= stages[2][currentStage]) {
                require(stages[0][currentStage] + _amount <= stages[0][currentStage + 1], '');
                USDTAmount = _amount * stages[1][currentStage + 1];
            } else {
                uint256 tokenAmountForCurrentPrice = stages[0][currentStage] - total;
                USDTAmount = tokenAmountForCurrentPrice * stages[1][currentStage] + (_amount - tokenAmountForCurrentPrice) * stages[1][currentStage + 1];
            }
        } else USDTAmount = _amount * stages[1][currentStage];
        return USDTAmount;
    }

    /**
     * @dev To calculate rewards in CHMPZ coin for given amount of tokens and usd price.
     * @param _amount No of tokens
     * @param _usdAmount usd price
     */
    function calculateBonus(uint256 _amount, uint256 _usdAmount) public view returns (uint256) {
        uint256 bonusCoins;
        require(_usdAmount >= minUsdAmountToBuy, 'Min usd not reached');
        for (uint i = bonuses[0].length; i > 0; i--) {
            if (_usdAmount >= (bonuses[0][i - 1] * baseDecimals)) {
                bonusCoins = ((bonuses[1][i - 1] * 100) * _amount) / 10_000;
                break;
            } else bonusCoins = 0;
        }
        return bonusCoins;
    }

    /**
     * @dev To update the sale times
     * @param _startTime New start time
     * @param _endTime New end time
     */
    function changeSaleTimes(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime > 0 || _endTime > 0, 'Invalid parameters');
        if (_startTime > 0) {
            uint256 prevValue = startTime;
            startTime = _startTime;
            emit SaleTimeUpdated(bytes32('START'), prevValue, _startTime, block.timestamp);
        }

        if (_endTime > 0) {
            uint256 prevValue = endTime;
            endTime = _endTime;
            emit SaleTimeUpdated(bytes32('END'), prevValue, _endTime, block.timestamp);
        }
    }

    /**
     * @dev To get latest ETH price in 10**18 format
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        price = (price * (10**10));
        return uint256(price);
    }

    /**
     * @dev To buy into a presale using USDT
     * @param amount No of tokens to buy
     */
    function buyWithUSDT(uint256 amount) external checkSaleState(amount) whenNotPaused returns (bool) {
        uint256 usdPrice = calculatePrice(amount);
        uint256 bonusCoins = calculateBonus(amount, usdPrice);
        uint256 newAmount = amount + bonusCoins;
        totalTokensSold += amount;
        totalTokensSoldWithBonus += newAmount;
        if (checkPoint != 0) checkPoint += amount;
        uint256 total = totalTokensSold > checkPoint ? totalTokensSold : checkPoint;
        if (total > stages[0][currentStage] || block.timestamp >= stages[2][currentStage]) {
            if (block.timestamp >= stages[2][currentStage]) {
                 checkPoint = stages[0][currentStage] + amount;
            }
            currentStage += 1;
        }
        userDeposits[_msgSender()] += (newAmount * baseDecimals);
        totalUsdRaised += usdPrice;
        uint256 ourAllowance = USDTInterface.allowance(_msgSender(), address(this));
        require(usdPrice <= ourAllowance, 'Not enough allowance');
        (bool success, ) = address(USDTInterface).call(abi.encodeWithSignature('transferFrom(address,address,uint256)', _msgSender(), owner(), usdPrice));
        require(success, 'Token payment failed');
        emit TokensBought(_msgSender(), amount, bonusCoins, newAmount, address(USDTInterface), usdPrice, usdPrice, block.timestamp);
        return true;
    }

    /**
     * @dev To buy into a presale using ETH
     * @param amount No of tokens to buy
     */
    function buyWithEth(uint256 amount) external payable checkSaleState(amount) whenNotPaused nonReentrant returns (bool) {
        uint256 usdPrice = calculatePrice(amount);
        uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
        require(msg.value >= ethAmount, 'Less payment');
        uint256 bonusCoins = calculateBonus(amount, usdPrice);
        uint256 newAmount = amount + bonusCoins;
        uint256 excess = msg.value - ethAmount;
        totalTokensSold += amount;
        totalTokensSoldWithBonus += newAmount;
        if (checkPoint != 0) checkPoint += amount;
        uint256 total = totalTokensSold > checkPoint ? totalTokensSold : checkPoint;
        if (total > stages[0][currentStage] || block.timestamp >= stages[2][currentStage]) {
            if (block.timestamp >= stages[2][currentStage]) {
                checkPoint = stages[0][currentStage] + amount;
            }
            currentStage += 1;
        }
        userDeposits[_msgSender()] += (newAmount * baseDecimals);
        totalUsdRaised += usdPrice;
        sendValue(payable(owner()), ethAmount);
        if (excess > 0) sendValue(payable(_msgSender()), excess);
        emit TokensBought(_msgSender(), amount, bonusCoins, newAmount, address(0), ethAmount, usdPrice, block.timestamp);
        return true;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH Payment failed");
    }

    /**
     * @dev To set the claim start time and sale token address by the owner
     * @param _claimStart claim start time
     * @param noOfTokens Number of tokens to add to the contract
     * @param _saleTokenAdress sale token address
     */
    function startClaim(uint256 _claimStart, uint256 noOfTokens, address _saleTokenAdress) external onlyOwner returns (bool) {
        require(_claimStart > endTime && _claimStart > block.timestamp, "Invalid claim start time");
        require(noOfTokens >= (totalTokensSoldWithBonus * baseDecimals), "Tokens less than sold");
        require(_saleTokenAdress != address(0), "Zero token address");
        require(claimStart == 0, "Claim already set");
        claimStart = _claimStart;
        saleTokenAdress = _saleTokenAdress;
        bool success = IERC20(_saleTokenAdress).transferFrom(_msgSender(), address(this), noOfTokens);
        require(success, "Token transfer failed");
        emit TokensAdded(saleTokenAdress, noOfTokens, block.timestamp);
        return true;
    }

    /**
     * @dev To change the claim start time by the owner
     * @param _claimStart new claim start time
     */
    function changeClaimStartTime(uint256 _claimStart) external onlyOwner returns (bool) {
        require(claimStart > 0, "Initial claim data not set");
        require(_claimStart > endTime, "Sale in progress");
        require(_claimStart > block.timestamp, "Claim start in past");
        uint256 prevValue = claimStart;
        claimStart = _claimStart;
        emit ClaimStartUpdated(prevValue, _claimStart, block.timestamp);
        return true;
    }

    /**
     * @dev To claim tokens after claiming starts
     */
    function claim() external whenNotPaused returns (bool) {
        require(saleTokenAdress != address(0), "Sale token not added");
        require(block.timestamp >= claimStart, "Claim has not started yet");
        require(!hasClaimed[_msgSender()], "Already claimed");
        hasClaimed[_msgSender()] = true;
        uint256 amount = userDeposits[_msgSender()];
        require(amount > 0, "Nothing to claim");
        delete userDeposits[_msgSender()];
        bool success = IERC20(saleTokenAdress).transfer(_msgSender(), amount);
        require(success, "Token transfer failed");
        emit TokensClaimed(_msgSender(), amount, block.timestamp);
        return true;
    }

    /**
     * @dev To manualy increment stage
     */
    function incrementCurrentStage() external onlyOwner {
        currentStage++;
        checkPoint = stages[0][currentStage];
    }

    /**
     * @dev Helper funtion to get stage information
     */
    function getStages() external view returns (uint256[][3] memory) {
        return stages;
    }
    
    /**
     * @dev Helper funtion to get bonus information
     */
    function getBonuses() external view returns (uint256[][2] memory) {
        return bonuses;
    }
}