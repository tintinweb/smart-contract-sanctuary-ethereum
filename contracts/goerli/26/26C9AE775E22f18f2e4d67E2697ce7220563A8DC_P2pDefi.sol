// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";
import "P2pDefiLibrary.sol";

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
    // lending token address => lender address => orderId => LendDetail
    mapping(address => mapping(address => mapping(uint256 => P2pDefiLibrary.OrderLendDetail)))
        private orderLendMap;
    mapping(address => mapping(address => mapping(uint256 => P2pDefiLibrary.TermLendDetail)))
        private termLendMap;
    mapping(address => mapping(address => mapping(uint256 => P2pDefiLibrary.OrderBorrowDetail)))
        private orderBorrowMap;
    mapping(address => mapping(address => mapping(uint256 => P2pDefiLibrary.TermBorrowDetail)))
        private termBorrowMap;
    mapping(address => mapping(address => P2pDefiLibrary.OrderAndTermHeader))
        public headerMap; // ###***### make it to private in production
    IERC20 public protocolToken;

    // P2pDefiStorage p2pDefiStorage;

    constructor(address _protocolTokenAddress) public {
        protocolToken = IERC20(_protocolTokenAddress);
        // p2pDefiStorage = P2pDefiStorage(_p2pDefiStorageAddress);
    }

    function createLendOrder(
        uint256 termPeriodInDays,
        uint256 lendingAmount,
        uint32 rateOfInterest,
        address lendingToken,
        address assetToken,
        bool isActive
    ) public onlyOwner returns (uint256 id) {
        // move lending amount to vault (like staking), so that once interest rate and term period matched with borrower then we can move this amount to borrowers account after due diligent
        // create a record in the blockchain which will be done in BigchainDB
        require(lendingAmount > 0, "Amount cannot be zero or less");
        IERC20(lendingToken).transferFrom(
            msg.sender,
            address(this),
            lendingAmount
        );
        id = 1;
        uint256 length = headerMap[lendingToken][msg.sender]
            .orderLendHeader
            .idsToOverwrite
            .length;
        if (length > 0) {
            id = headerMap[lendingToken][msg.sender]
                .orderLendHeader
                .idsToOverwrite[length - 1];

            headerMap[lendingToken][msg.sender]
                .orderLendHeader
                .idsToOverwrite
                .pop();
        } else {
            headerMap[lendingToken][msg.sender].orderLendHeader.maxId++;
            id = headerMap[lendingToken][msg.sender].orderLendHeader.maxId;

            // uint256 maxId = headerMap[lendingToken][msg.sender]
            //     .orderLendHeader
            //     .maxId;
            // id = (maxId == 0) ? 1 : maxId + 1;
            // headerMap[lendingToken][msg.sender].orderLendHeader.maxId = id;
        }
        headerMap[lendingToken][msg.sender].orderLendHeader.openIds.push(id);
        orderLendMap[lendingToken][msg.sender][id] = P2pDefiLibrary
            .OrderLendDetail({
                lendingToken: lendingToken,
                assetToken: assetToken,
                id: id,
                termPeriodInDays: termPeriodInDays,
                amount: lendingAmount,
                rateOfInterest: rateOfInterest,
                updatedAt: block.timestamp,
                openIdsIndex: headerMap[lendingToken][msg.sender]
                    .orderLendHeader
                    .openIds
                    .length - 1,
                status: P2pDefiLibrary.Status.OPEN,
                isActive: isActive
            });
        return id;
    }

    function createBorrowOrder(
        uint256 termPeriodInDays,
        uint256 borrowingAmount,
        uint32 rateOfInterest,
        address borrowingToken,
        address assetToken,
        bool isActive
    ) public returns (uint256 id) {
        require(borrowingAmount > 0, "Amount cannot be zero or less");
        uint256 borrowLimit = 10000; // getBorrowLimit(); ###***###
        require(
            borrowingAmount < borrowLimit,
            "Borrowing amount cannot be more than 80% of asset value"
        );
        id = 1;
        uint256 length = headerMap[borrowingToken][msg.sender]
            .orderBorrowHeader
            .idsToOverwrite
            .length;
        if (length > 0) {
            id = headerMap[borrowingToken][msg.sender]
                .orderBorrowHeader
                .idsToOverwrite[length - 1];

            headerMap[borrowingToken][msg.sender]
                .orderBorrowHeader
                .idsToOverwrite
                .pop();
        } else {
            headerMap[borrowingToken][msg.sender].orderBorrowHeader.maxId++;
            id = headerMap[borrowingToken][msg.sender].orderBorrowHeader.maxId;
            // uint256 maxId = headerMap[borrowingToken][msg.sender]
            //     .orderBorrowHeader
            //     .maxId;
            // id = (maxId == 0) ? 1 : maxId + 1;
            // headerMap[borrowingToken][msg.sender].orderBorrowHeader.maxId = id;
        }
        headerMap[borrowingToken][msg.sender].orderBorrowHeader.openIds.push(
            id
        );
        orderBorrowMap[borrowingToken][msg.sender][id] = P2pDefiLibrary
            .OrderBorrowDetail({
                borrowingToken: borrowingToken,
                assetToken: assetToken,
                rateOfInterest: rateOfInterest,
                id: id,
                termPeriodInDays: termPeriodInDays,
                amount: borrowingAmount,
                updatedAt: block.timestamp,
                openIdsIndex: headerMap[borrowingToken][msg.sender]
                    .orderBorrowHeader
                    .openIds
                    .length - 1,
                status: P2pDefiLibrary.Status.OPEN,
                isActive: isActive
            });
        return id;
    }

    function cancelBorrowOrder(address borrowingToken, uint256 id) public {
        require(
            orderBorrowMap[borrowingToken][msg.sender][id].isActive != false,
            "Record is already inactive"
        );
        uint256[] memory openIds = headerMap[borrowingToken][msg.sender]
            .orderBorrowHeader
            .openIds;
        uint256 openIdIndex = orderBorrowMap[borrowingToken][msg.sender][id]
            .openIdsIndex;

        headerMap[borrowingToken][msg.sender].orderBorrowHeader.openIds[
                openIdIndex
            ] = openIds[openIds.length - 1];
        orderBorrowMap[borrowingToken][msg.sender][openIds[openIds.length - 1]]
            .openIdsIndex = openIdIndex;
        headerMap[borrowingToken][msg.sender].orderBorrowHeader.openIds.pop();
        delete orderBorrowMap[borrowingToken][msg.sender][id];
        headerMap[borrowingToken][msg.sender]
            .orderBorrowHeader
            .idsToOverwrite
            .push(id);
    }

    function cancelLendOrder(address lendingToken, uint256 id) public {
        require(
            orderLendMap[lendingToken][msg.sender][id].isActive != false,
            "Record is already inactive"
        );
        uint256[] memory openIds = headerMap[lendingToken][msg.sender]
            .orderLendHeader
            .openIds;
        uint256 openIdIndex = orderLendMap[lendingToken][msg.sender][id]
            .openIdsIndex;

        headerMap[lendingToken][msg.sender].orderLendHeader.openIds[
            openIdIndex
        ] = openIds[openIds.length - 1];
        orderLendMap[lendingToken][msg.sender][openIds[openIds.length - 1]]
            .openIdsIndex = openIdIndex;
        headerMap[lendingToken][msg.sender].orderLendHeader.openIds.pop();
        delete orderLendMap[lendingToken][msg.sender][id];
        headerMap[lendingToken][msg.sender].orderLendHeader.idsToOverwrite.push(
                id
            );
    }

    function getBorrowOrderDetail(
        address borrowingToken,
        address user,
        uint256 id
    ) public view returns (P2pDefiLibrary.OrderBorrowDetail memory) {
        return (orderBorrowMap[borrowingToken][user][id]);
    }

    function getLendOrderDetail(
        address lendingToken,
        address user,
        uint256 id
    ) public view returns (P2pDefiLibrary.OrderLendDetail memory) {
        return (orderLendMap[lendingToken][user][id]);
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library P2pDefiLibrary {
    uint8 internal constant decimalForRateOfInterest = 2;
    uint8 internal constant decimalForAmount = 10;
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
    struct LenderAmountAndAddress {
        uint256 amount;
        address userAddress;
    }

    struct OrderLendDetail {
        address lendingToken;
        address assetToken;
        uint32 rateOfInterest;
        uint256 id;
        uint256 termPeriodInDays;
        uint256 amount;
        uint256 updatedAt;
        uint256 openIdsIndex;
        Status status;
        bool isActive;
    }
    struct TermLendDetail {
        address lendingToken;
        address assetToken;
        uint32 rateOfInterest;
        uint256 id;
        uint256 termPeriodInDays;
        uint256 amount;
        uint256 updatedAt;
        uint256 openIdsIndex;
        Status status;
        bool isActive;
    }
    struct OrderBorrowDetail {
        address borrowingToken;
        address assetToken;
        uint32 rateOfInterest;
        uint256 id;
        uint256 termPeriodInDays;
        uint256 amount;
        uint256 updatedAt;
        uint256 openIdsIndex;
        Status status;
        bool isActive;
    }
    struct TermBorrowDetail {
        address borrowingToken;
        address assetToken;
        LenderAmountAndAddress[] lenderAmountAndAddress;
        uint32 rateOfInterest;
        uint256 id;
        uint256 termPeriodInDays;
        uint256 amount;
        uint256 updatedAt;
        uint256 openIdsIndex;
        Status status;
        bool isActive;
    }

    struct OrderLendHeader {
        uint256 maxId;
        uint256[] openIds;
        uint256[] idsToOverwrite;
    }
    struct TermLendHeader {
        uint256 maxId;
        uint256[] openIds;
        uint256[] idsToOverwrite;
    }
    struct OrderBorrowHeader {
        uint256 maxId;
        uint256[] openIds;
        uint256[] idsToOverwrite;
    }
    struct TermBorrowHeader {
        uint256 maxId;
        uint256[] openIds;
        uint256[] idsToOverwrite;
    }

    struct OrderAndTermHeader {
        OrderLendHeader orderLendHeader;
        TermLendHeader termLendHeader;
        OrderBorrowHeader orderBorrowHeader;
        TermBorrowHeader termBorrowHeader;
    }
}