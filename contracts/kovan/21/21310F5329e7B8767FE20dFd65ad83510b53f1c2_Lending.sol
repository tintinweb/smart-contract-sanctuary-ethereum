// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error TransferFailed();
error TokenNotAllowed(address token);
error NeedsMoreThanZero();

contract Lending is ReentrancyGuard, Ownable {
    mapping(address => address) public s_tokenToPriceFeed;
    address[] public s_allowedTokens;
    // Account -> Token -> Amount
    mapping(address => mapping(address => uint256))
        public s_accountToTokenDeposits;
    // Account -> Token -> Amount
    mapping(address => mapping(address => uint256))
        public s_accountToTokenBorrows;

    // 5% Liquidation Reward
    uint256 public constant LIQUIDATION_REWARD = 5;
    // At 80% Loan to Value Ratio, the loan can be liquidated
    uint256 public constant LIQUIDATION_THRESHOLD = 80;
    uint256 public constant MIN_HEALH_FACTOR = 1e18;

    event AllowedTokenSet(address indexed token, address indexed priceFeed);
    event Deposit(
        address indexed account,
        address indexed token,
        uint256 indexed amount
    );
    event Borrow(
        address indexed account,
        address indexed token,
        uint256 indexed amount
    );
    event Withdraw(
        address indexed account,
        address indexed token,
        uint256 indexed amount
    );
    event Repay(
        address indexed account,
        address indexed token,
        uint256 indexed amount
    );
    event Liquidate(
        address indexed account,
        address indexed repayToken,
        address indexed rewardToken,
        uint256 halfDebtInEth,
        address liquidator
    );

    function deposit(address token, uint256 amount)
        external
        nonReentrant
        isAllowedToken(token)
        moreThanZero(amount)
    {
        emit Deposit(msg.sender, token, amount);
        s_accountToTokenDeposits[msg.sender][token] += amount;
        bool success = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) revert TransferFailed();
    }

    function withdraw(address token, uint256 amount)
        external
        nonReentrant
        moreThanZero(amount)
    {
        require(
            s_accountToTokenDeposits[msg.sender][token] >= amount,
            "Not enough funds"
        );
        emit Withdraw(msg.sender, token, amount);
        _pullFunds(msg.sender, token, amount);
        require(
            healthFactor(msg.sender) >= MIN_HEALH_FACTOR,
            "Platform will go insolvent!"
        );
    }

    function _pullFunds(
        address account,
        address token,
        uint256 amount
    ) private {
        require(
            s_accountToTokenDeposits[account][token] >= amount,
            "Not enough funds to withdraw"
        );
        s_accountToTokenDeposits[account][token] -= amount;
        bool success = IERC20(token).transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
    }

    function borrow(address token, uint256 amount)
        external
        nonReentrant
        isAllowedToken(token)
        moreThanZero(amount)
    {
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "Not enough tokens to borrow"
        );
        s_accountToTokenBorrows[msg.sender][token] += amount;
        emit Borrow(msg.sender, token, amount);
        bool success = IERC20(token).transfer(msg.sender, amount);
        if (!success) revert TransferFailed();
        require(
            healthFactor(msg.sender) >= MIN_HEALH_FACTOR,
            "Platform will go insolvent!"
        );
    }

    function liquidate(
        address account,
        address repayToken,
        address rewardToken
    ) external nonReentrant {
        require(
            healthFactor(account) < MIN_HEALH_FACTOR,
            "Account can't be liquidated!"
        );
        uint256 halfDebt = s_accountToTokenBorrows[account][repayToken] / 2;
        uint256 halfDebtInEth = getEthValue(repayToken, halfDebt);
        require(halfDebtInEth > 0, "Choose a different repayToken!");
        uint256 rewardAmountInEth = (halfDebtInEth * LIQUIDATION_REWARD) / 100;
        uint256 totalRewardAmountInRewardToken = getTokenValueFromEth(
            rewardToken,
            rewardAmountInEth + halfDebtInEth
        );
        emit Liquidate(
            account,
            repayToken,
            rewardToken,
            halfDebtInEth,
            msg.sender
        );
        _repay(account, repayToken, halfDebt);
        _pullFunds(account, rewardToken, totalRewardAmountInRewardToken);
    }

    function repay(address token, uint256 amount)
        external
        nonReentrant
        isAllowedToken(token)
        moreThanZero(amount)
    {
        emit Repay(msg.sender, token, amount);
        _repay(msg.sender, token, amount);
    }

    function _repay(
        address account,
        address token,
        uint256 amount
    ) private {
        // require(s_accountToTokenBorrows[account][token] - amount >= 0, "Repayed too much!");
        // On 0.8+ of solidity, it auto reverts math that would drop below 0 for a uint256
        s_accountToTokenBorrows[account][token] -= amount;
        bool success = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        if (!success) revert TransferFailed();
    }

    function getAccountInformation(address user)
        public
        view
        returns (uint256 borrowedValueInETH, uint256 collateralValueInETH)
    {
        borrowedValueInETH = getAccountBorrowedValue(user);
        collateralValueInETH = getAccountCollateralValue(user);
    }

    function getAccountCollateralValue(address user)
        public
        view
        returns (uint256)
    {
        uint256 totalCollateralValueInETH = 0;
        for (uint256 index = 0; index < s_allowedTokens.length; index++) {
            address token = s_allowedTokens[index];
            uint256 amount = s_accountToTokenDeposits[user][token];
            uint256 valueInEth = getEthValue(token, amount);
            totalCollateralValueInETH += valueInEth;
        }
        return totalCollateralValueInETH;
    }

    function getAccountBorrowedValue(address user)
        public
        view
        returns (uint256)
    {
        uint256 totalBorrowsValueInETH = 0;
        for (uint256 index = 0; index < s_allowedTokens.length; index++) {
            address token = s_allowedTokens[index];
            uint256 amount = s_accountToTokenBorrows[user][token];
            uint256 valueInEth = getEthValue(token, amount);
            totalBorrowsValueInETH += valueInEth;
        }
        return totalBorrowsValueInETH;
    }

    function getEthValue(address token, uint256 amount)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_tokenToPriceFeed[token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // 2000 DAI = 1 ETH
        // 0.002 ETH per DAI
        // price will be something like 20000000000000000
        // So we multiply the price by the amount, and then divide by 1e18
        return (uint256(price) * amount) / 1e18;
    }

    function getTokenValueFromEth(address token, uint256 amount)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            s_tokenToPriceFeed[token]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (amount * 1e18) / uint256(price);
    }

    function healthFactor(address account) public view returns (uint256) {
        (
            uint256 borrowedValueInEth,
            uint256 collateralValueInEth
        ) = getAccountInformation(account);
        uint256 collateralAdjustedForThreshold = (collateralValueInEth *
            LIQUIDATION_THRESHOLD) / 100;
        if (borrowedValueInEth == 0) return 100e18;
        return (collateralAdjustedForThreshold * 1e18) / borrowedValueInEth;
    }

    /********************/
    /* Modifiers */
    /********************/

    modifier isAllowedToken(address token) {
        if (s_tokenToPriceFeed[token] == address(0))
            revert TokenNotAllowed(token);
        _;
    }

    modifier moreThanZero(uint256 amount) {
        if (amount == 0) {
            revert NeedsMoreThanZero();
        }
        _;
    }

    /********************/
    /* DAO / OnlyOwner Functions */
    /********************/
    function setAllowedToken(address token, address priceFeed)
        external
        onlyOwner
    {
        bool foundToken = false;
        uint256 allowedTokensLength = s_allowedTokens.length;
        for (uint256 index = 0; index < allowedTokensLength; index++) {
            if (s_allowedTokens[index] == token) {
                foundToken = true;
                break;
            }
        }
        if (!foundToken) {
            s_allowedTokens.push(token);
        }
        s_tokenToPriceFeed[token] = priceFeed;
        emit AllowedTokenSet(token, priceFeed);
    }

    /********************/
    /* Getter Functions */
    /********************/
    // Ideally, we'd have getter functions for all our s_ variables we want exposed, and set them all to private.
    // But, for the purpose of this demo, we've left them public for simplicity.
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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