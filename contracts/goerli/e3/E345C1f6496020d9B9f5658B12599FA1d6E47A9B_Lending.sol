// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "AggregatorV3Interface.sol";
import "IERC20.sol";
import "Ownable.sol";
import "ReentrancyGuard.sol";

contract Lending is Ownable, ReentrancyGuard {
    event Borrowed(
        uint256 id,
        address borrower,
        uint256 collateralAmount,
        uint256 loanAmount,
        uint256 interestRate,
        uint256 loanDeadline,
        bool isActive
    );
    event Repaid(
        uint256 id,
        address borrower,
        uint256 collateralAmount,
        uint256 loanAmount,
        uint256 interestRate,
        uint256 loanDeadline,
        bool isActive
    );
    event Withdrew(
        uint256 id,
        address borrower,
        uint256 loanDeadline,
        uint256 collateralAmount,
        bool isActive
    );
    event Deposited(uint256 amount, uint256 depositTime, uint256 reserve);

    struct Loan {
        uint256 loanId; // Id of loan
        address borrower; // Address who get the loan
        uint256 interestRate; // Interest rate of current loan
        uint256 collateralAmount; // Amount value in collateral token
        uint256 collateralAmountInUSDT; // Amount value in USDT
        uint256 loanAmount; // Loan amount in USDT
        uint256 loanStartingTime; // Loan starting time
        uint256 loanDuration; // Loan term
        uint256 loanEndingTime; // Deadline to repay the loan
        LOAN_STATE loanState; // Status of loan (none, borrowed, repaid, failed)
    }

    AggregatorV3Interface public priceFeed;
    IERC20 public USDTtoken;
    IERC20 public LINKtoken;

    uint256 public interestRate;

    uint256 public idCounter;

    enum LOAN_STATE {
        NONE,
        BORROWED,
        REPAID,
        FAILED
    }

    uint256 public USDTReserve; // USDT reserve of the contrect

    mapping(uint256 => Loan) loans; // Mapping of ids to loans

    constructor(
        address _USDTtoken,
        address _LINKtoken,
        address _priceFeed
    ) {
        USDTtoken = IERC20(_USDTtoken);
        LINKtoken = IERC20(_LINKtoken);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    // This function is called by borrower to get the loan.

    function borrow(uint256 _loanAmount) public nonReentrant {
        require(_loanAmount <= USDTReserve, "Not enough reserve USDT to lend!");
        Loan memory loan;
        loan.loanId = idCounter;
        loan.borrower = msg.sender;
        loan.interestRate = interestRate;
        (
            loan.collateralAmount,
            loan.collateralAmountInUSDT
        ) = getCollateralAmount(_loanAmount, loan.interestRate);

        loan.loanAmount = _loanAmount;
        loan.loanStartingTime = block.timestamp;
        loan.loanEndingTime = block.timestamp + loan.loanDuration;
        loan.loanState = LOAN_STATE.BORROWED;
        loans[idCounter] = loan;
        require(
            LINKtoken.transferFrom(
                loan.borrower,
                address(this),
                loan.collateralAmount
            ),
            "Not enough collateral!"
        );
        require(
            USDTtoken.transfer(loan.borrower, loan.loanAmount),
            "Transfer failed!"
        );
        emit Borrowed(
            idCounter,
            msg.sender,
            loan.collateralAmount,
            _loanAmount,
            loan.interestRate,
            loan.loanEndingTime,
            true
        );
        idCounter++;
    }

    // This function is called by an address who borrowed with this id
    // to repay before its deadline.

    function repay(uint256 _id) public checkStatus(_id) nonReentrant {
        checkLoanDeadline(_id);
        require(
            loans[_id].loanState == LOAN_STATE.FAILED,
            "The loan with this id was not paid before its deadline!"
        );
        require(
            USDTtoken.transferFrom(
                msg.sender,
                address(this),
                loans[_id].collateralAmountInUSDT
            ),
            "Repay was failed!"
        );
        loans[_id].loanState = LOAN_STATE.REPAID;
        require(LINKtoken.transfer(msg.sender, loans[_id].collateralAmount));
        emit Repaid(
            _id,
            msg.sender,
            loans[_id].collateralAmount,
            loans[_id].collateralAmountInUSDT,
            loans[_id].interestRate,
            loans[_id].loanEndingTime,
            false
        );
    }

    function setInterestRate(uint256 _rate) public onlyOwner {
        interestRate = _rate;
    }

    function getExchangeRate() internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getCollateralAmount(uint256 _loanAmount, uint256 _interestRate)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 collateralAmountInUSDT = ((_interestRate / 100) * _loanAmount) +
            _loanAmount;
        uint256 collateralAmount = (1 / getExchangeRate()) *
            collateralAmountInUSDT;
        return (collateralAmount, collateralAmountInUSDT);
    }

    // This function checks each time whether the loan has expired. If the period has expired,
    // the collateral is transferred from the contract to the contract owner.

    function checkLoanDeadline(uint256 _id) internal {
        if (loans[_id].loanEndingTime <= block.timestamp) {
            loans[_id].loanState = LOAN_STATE.FAILED;
            payable(owner()).transfer(loans[_id].collateralAmount);
            emit Withdrew(
                _id,
                loans[_id].borrower,
                loans[_id].loanEndingTime,
                loans[_id].collateralAmount,
                false
            );
        }
    }

    // The contract holder uses this function to provide USDT liquidity to the contract.

    function deposit(uint256 _amount) public onlyOwner {
        USDTtoken.transferFrom(msg.sender, address(this), _amount);
        USDTReserve += _amount;
        emit Deposited(_amount, block.timestamp, USDTReserve);
    }

    modifier checkStatus(uint256 _id) {
        require(
            loans[_id].loanState == LOAN_STATE.NONE,
            "The loan with this id does not exist!"
        );
        require(
            loans[_id].loanState == LOAN_STATE.REPAID,
            "The loan with this id was already paid!"
        );
        _;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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