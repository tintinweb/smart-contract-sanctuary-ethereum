// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

// create lend order
// create borrow order
// move borrower's asset to vault (like staking)
// get borrower's limit to borrow (in value of stable coin using chainlink)
// move lender's amount to borrower (once interest rate matched)
// move repaid amout + interest (from borrower) to lender after aggreed term (period)
// once repaid, move the asset from vault to borrower's account (like unstake)
// move the fee of the trade to treasury account
// if asset value reduced below the 105% of borrowed amount, then asset will be sent to lender's account (liquidation)

// if lender want to pre-withdraw the lended amount, then lender may create a borrow order based on the asset against which lender have provided amount earlier
// likewise if borrower want to pre-close the mortgage, then borrower may create a lend order using the previously borrowed amount against the same asset or can fully pay the interest for complete term and can close the mortgage

// incentive to lender
// incentive to borrower

// mint protocol token to incentivise borrowers and lenders
// user will pay fee in protocol token

contract P2pDefi is Ownable {
    uint8 private decimalForRateOfInterest = 2;
    uint8 private decimalForAmount = 10;
    IERC20 public protocolToken;
    enum Status {
        SUCCEEDED,
        STARTED,
        OPEN,
        IN_PROGRESS,
        COMPLETED,
        LIQUIDATED,
        PRE_CLOSED,
        FAILED
    }
    struct OrderLendData {
        uint256 id;
        address lendingToken;
        uint256 termPeriodInDays;
        uint256 amount;
        uint32 rateOfInterest;
        address assetToken;
        uint256 updatedAt;
        Status status;
        bool isActive;
    }
    struct TermLendData {
        uint256 id;
        address borrowerAddress;
        uint256 termPeriodInDays;
        uint256 amount;
        uint32 rateOfInterest;
        address assetToken;
        uint256 updatedAt;
        Status status;
        bool isActive;
    }
    struct OrderBorrowData {
        uint256 id;
        address borrowingToken;
        uint256 termPeriodInDays;
        uint256 amount;
        uint32 rateOfInterest;
        address assetToken;
        uint256 updatedAt;
        Status status;
        bool isActive;
    }
    struct TermBorrowData {
        uint256 id;
        address borrowerAddress;
        uint256 termPeriodInDays;
        uint256 amount;
        uint32 rateOfInterest;
        address assetToken;
        uint256 updatedAt;
        Status status;
        bool isActive;
    }
    // lending token address => lender address => orderId => LendData
    mapping(address => mapping(address => OrderLendData)) public orderLendMap;
    mapping(address => mapping(address => TermLendData)) public termLendMap;
    mapping(address => mapping(address => OrderBorrowData))
        public orderBorrowMap;
    mapping(address => mapping(address => TermBorrowData)) public termBorrowMap;

    constructor(address _protocolTokenAddress) public {
        protocolToken = IERC20(_protocolTokenAddress);
    }

    function createLendOrder(
        address _lendingToken,
        uint256 _termPeriodInDays,
        uint256 _lendingAmount,
        uint32 _rateOfInterest,
        address _assetToken
    ) public {
        // move lending amount to vault (like staking), so that once interest rate and term period matched with borrower then we can move this amount to borrowers account after due diligent
        // create a record in the blockchain which will be done in BigchainDB
        require(_lendingAmount > 0, "Amount cannot be zero or less");
        IERC20(_lendingToken).transferFrom(
            msg.sender,
            address(this),
            _lendingAmount
        );
        // uint256 orderLendId = getOrderLendId(_lendingToken);
        orderLendMap[_lendingToken][msg.sender] = OrderLendData(
            0,
            _lendingToken,
            _termPeriodInDays,
            _lendingAmount,
            _rateOfInterest,
            _assetToken,
            block.timestamp,
            Status.OPEN,
            true
        );
    }

    // function getOrderLendId(address _lendingToken)
    //     private
    //     view
    //     returns (uint256)
    // {
    //     uint256 orderLength = orderLendMap[_lendingToken][msg.sender].length;
    //     if (orderLength > 0) {
    //         for (uint256 i = 0; i < orderLength; i++) {
    //             if (!orderLendMap[_lendingToken][msg.sender][i].isActive) {
    //                 return i;
    //             }
    //         }
    //         return orderLength;
    //     } else {
    //         return 0;
    //     }
    // }

    function createBorrowOrder(
        address _borrowingToken,
        uint256 _termPeriodInDays,
        uint256 _borrowingAmount,
        uint32 _rateOfInterest,
        address _assetToken
    ) public {
        require(_borrowingAmount > 0, "Amount cannot be zero or less");
        uint256 borrowLimit = 10000; // getBorrowLimit(); ###***###
        require(
            _borrowingAmount < borrowLimit,
            "Borrowing amount cannot be more than 80% of asset value"
        );
        orderBorrowMap[_borrowingToken][msg.sender] = OrderBorrowData(
            0,
            _borrowingToken,
            _termPeriodInDays,
            _borrowingAmount,
            _rateOfInterest,
            _assetToken,
            block.timestamp,
            Status.OPEN,
            true
        );
        // OrderBorrowData[] memory orderBorrowData = orderBorrowMap[
        //     _borrowingToken
        // ][msg.sender];
        // uint256 orderLength = orderBorrowData.length;
        // uint256 i = 0;
        // if (orderLength > 0) {
        //     for (i = 0; i < orderLength; i++) {
        //         if (!orderBorrowData[i].isActive) {
        //             orderBorrowData[i] = OrderBorrowData(
        //                 i,
        //                 _borrowingToken,
        //                 _termPeriodInDays,
        //                 _borrowingAmount,
        //                 _rateOfInterest,
        //                 _assetToken,
        //                 block.timestamp,
        //                 Status.OPEN,
        //                 true
        //             );
        //             break;
        //         }
        //     }
        // } else {
        //     orderBorrowMap[_borrowingToken][msg.sender].push(
        //         OrderBorrowData(
        //             i++,
        //             _borrowingToken,
        //             _termPeriodInDays,
        //             _borrowingAmount,
        //             _rateOfInterest,
        //             _assetToken,
        //             block.timestamp,
        //             Status.OPEN,
        //             true
        //         )
        //     );
        // }
        // if (i != 0 && i <= orderLength) {
        //     orderBorrowMap[_borrowingToken][msg.sender] = orderBorrowData;
        // }
    }

    function getBorrowOrders(address _borrowingToken)
        public
        view
        returns (OrderBorrowData memory)
    {
        return orderBorrowMap[_borrowingToken][msg.sender];
    }

    // function getOrderBorrowId(OrderBorrowData[] memory orderBorrowData)
    //     private
    //     view
    //     returns (uint256)
    // {
    //     uint256 orderLength = orderBorrowData.length;
    //     if (orderLength > 0) {
    //         for (uint256 i = 0; i < orderLength; i++) {
    //             if (!orderBorrowData[i].isActive) {
    //                 return i;
    //             }
    //         }
    //         return orderLength;
    //     } else {
    //         return 0;
    //     }
    // }
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