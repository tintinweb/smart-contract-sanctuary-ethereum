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
    IERC20 public protocolToken;

    mapping(P2pDefiLibrary.TxType => P2pDefiLibrary.AllDetail)
        public allDetails;

    // mapping(P2pDefiLibrary.TxType => P2pDefiLibrary.AllIndex) public allIndexes;
    // P2pDefiLibrary.AllDetail allOrderDetail;
    // P2pDefiLibrary.AllDetail[] allOrderDetails;

    constructor(address _protocolTokenAddress) public {
        protocolToken = IERC20(_protocolTokenAddress);
    }

    function getLendOrder()
        public
        view
        returns (P2pDefiLibrary.Detail memory detail)
    {
        detail = allDetails[P2pDefiLibrary.TxType.ORDER]
            .lendDetails[0]
            .assetDetails[0]
            .userDetails[0]
            .details[0];
    }

    function createLendOrder(
        uint256 termPeriodInDays,
        uint256 lendingAmount,
        uint32 rateOfInterest,
        address lendingToken,
        address assetToken,
        bool isActive
    ) public returns (uint256 id) {
        require(lendingAmount > 0, "Amount cannot be zero or less");
        // IERC20(lendingToken).transferFrom(
        //     msg.sender,
        //     address(this),
        //     lendingAmount
        // );
        id = 1;

        if (!allDetails[P2pDefiLibrary.TxType.ORDER].isActive) {
            P2pDefiLibrary.AllDetail storage allDetail = allDetails[
                P2pDefiLibrary.TxType.ORDER
            ];
            P2pDefiLibrary.LendDetail storage lendDetail = allDetails[
                P2pDefiLibrary.TxType.ORDER
            ].lendDetails.push();
            // //
            P2pDefiLibrary.AssetDetail storage assetDetail = allDetails[
                P2pDefiLibrary.TxType.ORDER
            ].lendDetails[0].assetDetails.push();
            // //
            P2pDefiLibrary.UserDetail storage userDetail = allDetails[
                P2pDefiLibrary.TxType.ORDER
            ].lendDetails[0].assetDetails[0].userDetails.push();
            // //
            P2pDefiLibrary.Detail storage detail = allDetails[
                P2pDefiLibrary.TxType.ORDER
            ].lendDetails[0].assetDetails[0].userDetails[0].details.push();
            // //
            // //
            detail.isActive = true;
            detail.side = P2pDefiLibrary.Side.LEND;
            detail.status = P2pDefiLibrary.Status.OPEN;
            detail.rateOfInterest = rateOfInterest;
            detail.amount = lendingAmount;
            detail.termPeriodInDays = termPeriodInDays;
            // detail.// partnerAmountAndAddress: [];
            detail.detailId = id;
            // detail.detailIndex = 1;
            detail.updatedAt = block.timestamp;
            detail.validFrom = block.timestamp;
            // detail.vaildTo = 0;
            //
            userDetail.userAddress = msg.sender;
            userDetail.maxDetailId = 1;
            userDetail.detailIdAndItsIndex[1] = 0;
            userDetail.isActive = true;
            //
            assetDetail.assetTokenAddress = assetToken;
            assetDetail.userAddressAndItsIndex[msg.sender] = 0;
            assetDetail.isActive = true;
            //
            lendDetail.lendTokenAddress = assetToken;
            lendDetail.assetAddressAndItsIndex[assetToken] = 0;
            lendDetail.isActive = true;
            //
            allDetail.txType = P2pDefiLibrary.TxType.ORDER;
            allDetail.lendCoinAddressAndItsIndex[lendingToken] = 0;
            allDetail.isActive = true;
            //
        } else {
            uint256 lendIndex = allDetails[P2pDefiLibrary.TxType.ORDER]
                .lendCoinAddressAndItsIndex[lendingToken];
            if (
                !allDetails[P2pDefiLibrary.TxType.ORDER]
                    .lendDetails[lendIndex]
                    .isActive
            ) {
                P2pDefiLibrary.LendDetail storage lendDetail = allDetails[
                    P2pDefiLibrary.TxType.ORDER
                ].lendDetails.push();
                // //
                P2pDefiLibrary.AssetDetail storage assetDetail = allDetails[
                    P2pDefiLibrary.TxType.ORDER
                ].lendDetails[0].assetDetails.push();
                // //
                P2pDefiLibrary.UserDetail storage userDetail = allDetails[
                    P2pDefiLibrary.TxType.ORDER
                ].lendDetails[0].assetDetails[0].userDetails.push();
                // //
                P2pDefiLibrary.Detail storage detail = allDetails[
                    P2pDefiLibrary.TxType.ORDER
                ].lendDetails[0].assetDetails[0].userDetails[0].details.push();
                // //
                // //
                detail.isActive = true;
                detail.side = P2pDefiLibrary.Side.LEND;
                detail.status = P2pDefiLibrary.Status.OPEN;
                detail.rateOfInterest = rateOfInterest;
                detail.amount = lendingAmount;
                detail.termPeriodInDays = termPeriodInDays;
                // detail.// partnerAmountAndAddress: [];
                detail.detailId = id;
                // detail.detailIndex = 1;
                detail.updatedAt = block.timestamp;
                detail.validFrom = block.timestamp;
                // detail.vaildTo = 0;
                //
                userDetail.userAddress = msg.sender;
                userDetail.maxDetailId = 1;
                userDetail.detailIdAndItsIndex[1] = 0;
                userDetail.isActive = true;
                //
                assetDetail.assetTokenAddress = assetToken;
                assetDetail.userAddressAndItsIndex[msg.sender] = 0;
                assetDetail.isActive = true;
                //
                lendDetail.lendTokenAddress = assetToken;
                lendDetail.assetAddressAndItsIndex[assetToken] = 0;
                lendDetail.isActive = true;
            } else {
                uint256 assetIndex = allDetails[P2pDefiLibrary.TxType.ORDER]
                    .lendDetails[lendIndex]
                    .assetAddressAndItsIndex[assetToken];
                if (
                    !allDetails[P2pDefiLibrary.TxType.ORDER]
                        .lendDetails[lendIndex]
                        .assetDetails[assetIndex]
                        .isActive
                ) {
                    P2pDefiLibrary.AssetDetail storage assetDetail = allDetails[
                        P2pDefiLibrary.TxType.ORDER
                    ].lendDetails[0].assetDetails.push();
                    // //
                    P2pDefiLibrary.UserDetail storage userDetail = allDetails[
                        P2pDefiLibrary.TxType.ORDER
                    ].lendDetails[0].assetDetails[0].userDetails.push();
                    // //
                    P2pDefiLibrary.Detail storage detail = allDetails[
                        P2pDefiLibrary.TxType.ORDER
                    ]
                        .lendDetails[0]
                        .assetDetails[0]
                        .userDetails[0]
                        .details
                        .push();
                    // //
                    // //
                    detail.isActive = true;
                    detail.side = P2pDefiLibrary.Side.LEND;
                    detail.status = P2pDefiLibrary.Status.OPEN;
                    detail.rateOfInterest = rateOfInterest;
                    detail.amount = lendingAmount;
                    detail.termPeriodInDays = termPeriodInDays;
                    // detail.// partnerAmountAndAddress: [];
                    detail.detailId = id;
                    // detail.detailIndex = 1;
                    detail.updatedAt = block.timestamp;
                    detail.validFrom = block.timestamp;
                    // detail.vaildTo = 0;
                    //
                    userDetail.userAddress = msg.sender;
                    userDetail.maxDetailId = 1;
                    userDetail.detailIdAndItsIndex[1] = 0;
                    userDetail.isActive = true;
                    //
                    assetDetail.assetTokenAddress = assetToken;
                    assetDetail.userAddressAndItsIndex[msg.sender] = 0;
                    assetDetail.isActive = true;
                } else {
                    uint256 userIndex = allDetails[P2pDefiLibrary.TxType.ORDER]
                        .lendDetails[lendIndex]
                        .assetDetails[assetIndex]
                        .userAddressAndItsIndex[msg.sender];
                    if (
                        !allDetails[P2pDefiLibrary.TxType.ORDER]
                            .lendDetails[lendIndex]
                            .assetDetails[assetIndex]
                            .userDetails[userIndex]
                            .isActive
                    ) {
                        P2pDefiLibrary.UserDetail
                            storage userDetail = allDetails[
                                P2pDefiLibrary.TxType.ORDER
                            ].lendDetails[0].assetDetails[0].userDetails.push();
                        // //
                        P2pDefiLibrary.Detail storage detail = allDetails[
                            P2pDefiLibrary.TxType.ORDER
                        ]
                            .lendDetails[0]
                            .assetDetails[0]
                            .userDetails[0]
                            .details
                            .push();
                        // //
                        // //
                        detail.isActive = true;
                        detail.side = P2pDefiLibrary.Side.LEND;
                        detail.status = P2pDefiLibrary.Status.OPEN;
                        detail.rateOfInterest = rateOfInterest;
                        detail.amount = lendingAmount;
                        detail.termPeriodInDays = termPeriodInDays;
                        // detail.// partnerAmountAndAddress: [];
                        detail.detailId = id;
                        // detail.detailIndex = 1;
                        detail.updatedAt = block.timestamp;
                        detail.validFrom = block.timestamp;
                        // detail.vaildTo = 0;
                        //
                        userDetail.userAddress = msg.sender;
                        userDetail.maxDetailId = 1;
                        userDetail.detailIdAndItsIndex[1] = 0;
                        userDetail.isActive = true;
                    } else {
                        uint256[] memory detailIdsToOverwrite = allDetails[
                            P2pDefiLibrary.TxType.ORDER
                        ]
                            .lendDetails[lendIndex]
                            .assetDetails[assetIndex]
                            .userDetails[userIndex]
                            .detailIdsToOverwrite;
                        if (detailIdsToOverwrite.length > 0) {
                            uint256 detailId = detailIdsToOverwrite[
                                detailIdsToOverwrite.length - 1
                            ];
                            uint256 detailIndex = allDetails[
                                P2pDefiLibrary.TxType.ORDER
                            ]
                                .lendDetails[lendIndex]
                                .assetDetails[assetIndex]
                                .userDetails[userIndex]
                                .detailIdAndItsIndex[detailId];
                            allDetails[P2pDefiLibrary.TxType.ORDER]
                                .lendDetails[lendIndex]
                                .assetDetails[assetIndex]
                                .userDetails[userIndex]
                                .detailIdsToOverwrite
                                .pop();
                            P2pDefiLibrary.Detail storage detail = allDetails[
                                P2pDefiLibrary.TxType.ORDER
                            ]
                                .lendDetails[lendIndex]
                                .assetDetails[assetIndex]
                                .userDetails[userIndex]
                                .details[detailIndex];
                            detail.isActive = true;
                            detail.side = P2pDefiLibrary.Side.LEND;
                            detail.status = P2pDefiLibrary.Status.OPEN;
                            detail.rateOfInterest = rateOfInterest;
                            detail.amount = lendingAmount;
                            detail.termPeriodInDays = termPeriodInDays;
                            // detail.// partnerAmountAndAddress: [];
                            detail.detailId = detailId;
                            // detail.detailIndex = detailIndex;
                            detail.updatedAt = block.timestamp;
                            detail.validFrom = block.timestamp;
                        } else {
                            allDetails[P2pDefiLibrary.TxType.ORDER]
                                .lendDetails[lendIndex]
                                .assetDetails[assetIndex]
                                .userDetails[userIndex]
                                .maxDetailId++;
                            uint256 detailId = allDetails[
                                P2pDefiLibrary.TxType.ORDER
                            ]
                                .lendDetails[lendIndex]
                                .assetDetails[assetIndex]
                                .userDetails[userIndex]
                                .maxDetailId;
                            P2pDefiLibrary.Detail storage detail = allDetails[
                                P2pDefiLibrary.TxType.ORDER
                            ]
                                .lendDetails[lendIndex]
                                .assetDetails[assetIndex]
                                .userDetails[userIndex]
                                .details
                                .push();
                            uint256 detailIdIndex = allDetails[
                                P2pDefiLibrary.TxType.ORDER
                            ]
                                .lendDetails[lendIndex]
                                .assetDetails[assetIndex]
                                .userDetails[userIndex]
                                .details
                                .length - 1;
                            allDetails[P2pDefiLibrary.TxType.ORDER]
                                .lendDetails[lendIndex]
                                .assetDetails[assetIndex]
                                .userDetails[userIndex]
                                .detailIdAndItsIndex[detailId] = detailIdIndex;
                            detail.isActive = true;
                            detail.side = P2pDefiLibrary.Side.LEND;
                            detail.status = P2pDefiLibrary.Status.OPEN;
                            detail.rateOfInterest = rateOfInterest;
                            detail.amount = lendingAmount;
                            detail.termPeriodInDays = termPeriodInDays;
                            // detail.// partnerAmountAndAddress: [];
                            detail.detailId = detailId;
                            // detail.detailIndex = detailIdIndex;
                            detail.updatedAt = block.timestamp;
                            detail.validFrom = block.timestamp;
                            // detail.vaildTo = 0;
                        }
                        // uint256 detailIndex = allDetails[P2pDefiLibrary.TxType.ORDER]
                        // .lendDetails[lendIndex]
                        // .assetDetails[assetIndex]
                        // .userDetails[userIndex].detailIdAndItsIndex[0];
                    }
                }
            }
        }
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
        FAILED,
        FILLED,
        PARTIALLY_FILLED
    }
    enum Side {
        LEND,
        BORROW
    }
    enum TxType {
        ORDER,
        TERM
    }

    struct PartnerAmountAndAddress {
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
        PartnerAmountAndAddress[] partnerAmountAndAddress;
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

    struct Detail {
        bool isActive;
        Side side;
        Status status;
        uint32 rateOfInterest;
        uint256 amount;
        uint256 termPeriodInDays;
        PartnerAmountAndAddress[] partnerAmountAndAddress;
        uint256 detailId;
        // uint256 detailIndex;
        uint256 updatedAt;
        uint256 validFrom;
        uint256 vaildTo;
    }

    struct UserDetail {
        address userAddress;
        uint256 maxDetailId;
        uint256[] detailIdsToOverwrite;
        mapping(uint256 => uint256) detailIdAndItsIndex;
        Detail[] details;
        bool isActive;
    }

    struct AssetDetail {
        bool isActive;
        address assetTokenAddress;
        uint256[] userAddressToOverwrite;
        mapping(address => uint256) userAddressAndItsIndex;
        UserDetail[] userDetails;
    }

    struct LendDetail {
        bool isActive;
        address lendTokenAddress;
        uint256[] assetTokenAddressToOverwrite;
        mapping(address => uint256) assetAddressAndItsIndex;
        AssetDetail[] assetDetails;
    }

    struct AllDetail {
        bool isActive;
        // uint256[] ids;
        uint256[] lendTokenAddressToOverwrite;
        mapping(address => uint256) lendCoinAddressAndItsIndex;
        TxType txType;
        LendDetail[] lendDetails;
    }

    // struct UserIndex {
    //     uint256 index;
    //     mapping(uint256 => uint256) detailIdIndexes;
    // }

    // struct AssetIndex {
    //     uint256 index;
    //     mapping(address => UserIndex) userIndexes;
    // }

    // struct LendIndex {
    //     uint256 index;
    //     mapping(address => AssetIndex) assetIndexes;
    // }

    // struct AllIndex {
    //     uint256 index;
    //     mapping(address => LendIndex) lendIdexes;
    // }
}