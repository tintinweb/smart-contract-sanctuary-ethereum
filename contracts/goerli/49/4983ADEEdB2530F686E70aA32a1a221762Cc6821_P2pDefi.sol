// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";
import "P2pDefiLibrary.sol";

contract P2pDefi is Ownable {
    IERC20 public protocolToken;

    mapping(P2pDefiLibrary.EnmTxType => P2pDefiLibrary.SrtAllDetail)
        public mapAllDetails;

    constructor(address _protocolTokenAddress) public {
        protocolToken = IERC20(_protocolTokenAddress);
    }

    function getDetail(
        P2pDefiLibrary.EnmTxType txType,
        uint256 detailId,
        address lendingToken,
        address assetToken,
        address user
    ) public view returns (P2pDefiLibrary.SrtDetail memory detail) {
        uint256 lendIndex = mapAllDetails[txType].lendCoinAddressAndItsIndex[
            lendingToken
        ];
        uint256 assetIndex = mapAllDetails[txType]
            .lendDetails[lendIndex]
            .assetAddressAndItsIndex[assetToken];
        uint256 userIndex = mapAllDetails[txType]
            .lendDetails[lendIndex]
            .assetDetails[assetIndex]
            .userAddressAndItsIndex[user];
        uint256 detailIndex = mapAllDetails[txType]
            .lendDetails[lendIndex]
            .assetDetails[assetIndex]
            .userDetails[userIndex]
            .detailIdAndItsIndex[detailId];
        detail = mapAllDetails[txType]
            .lendDetails[lendIndex]
            .assetDetails[assetIndex]
            .userDetails[userIndex]
            .details[detailIndex];
    }

    function removeP2pDefiDetail(
        P2pDefiLibrary.EnmTxType txType,
        uint256 detailId,
        address lendingToken,
        address assetToken
    ) public {
        uint256 lendIndex = mapAllDetails[txType].lendCoinAddressAndItsIndex[
            lendingToken
        ];
        uint256 assetIndex = mapAllDetails[txType]
            .lendDetails[lendIndex]
            .assetAddressAndItsIndex[assetToken];
        uint256 userIndex = mapAllDetails[txType]
            .lendDetails[lendIndex]
            .assetDetails[assetIndex]
            .userAddressAndItsIndex[msg.sender];
        uint256 detailIndex = mapAllDetails[txType]
            .lendDetails[lendIndex]
            .assetDetails[assetIndex]
            .userDetails[userIndex]
            .detailIdAndItsIndex[detailId];
        mapAllDetails[txType]
            .lendDetails[lendIndex]
            .assetDetails[assetIndex]
            .userDetails[userIndex]
            .detailIdsToOverwrite
            .push(detailId);
        delete mapAllDetails[txType]
            .lendDetails[lendIndex]
            .assetDetails[assetIndex]
            .userDetails[userIndex]
            .details[detailIndex];
    }

    function setAllDetail(P2pDefiLibrary.SrtFullDetail memory srtFullDetail)
        private
        returns (P2pDefiLibrary.SrtAllDetail storage allDetail)
    {
        allDetail = mapAllDetails[srtFullDetail.txType];
        allDetail.txType = srtFullDetail.txType;
        allDetail.isActive = srtFullDetail.isActive;
    }

    function setLendDetail(P2pDefiLibrary.SrtFullDetail memory srtFullDetail)
        private
        returns (P2pDefiLibrary.SrtLendDetail storage lendDetail)
    {
        uint256 length = mapAllDetails[srtFullDetail.txType].lendDetails.length;
        if (!(length > 1)) {
            mapAllDetails[srtFullDetail.txType].lendDetails.push();
            length++;
        }
        lendDetail = mapAllDetails[srtFullDetail.txType].lendDetails.push();
        lendDetail.lendTokenAddress = srtFullDetail.lendTokenAddress;
        lendDetail.isActive = srtFullDetail.isActive;
        mapAllDetails[srtFullDetail.txType].lendCoinAddressAndItsIndex[
                srtFullDetail.lendTokenAddress
            ] = length;
    }

    function setAssetDetail(P2pDefiLibrary.SrtFullDetail memory srtFullDetail)
        private
        returns (P2pDefiLibrary.SrtAssetDetail storage assetDetail)
    {
        uint256 length = mapAllDetails[srtFullDetail.txType]
            .lendDetails[srtFullDetail.lendIndex]
            .assetDetails
            .length;
        if (!(length > 1)) {
            mapAllDetails[srtFullDetail.txType]
                .lendDetails[srtFullDetail.lendIndex]
                .assetDetails
                .push();
            length++;
        }
        assetDetail = mapAllDetails[srtFullDetail.txType]
            .lendDetails[srtFullDetail.lendIndex]
            .assetDetails
            .push();
        assetDetail.assetTokenAddress = srtFullDetail.assetTokenAddress;
        assetDetail.isActive = srtFullDetail.isActive;
        mapAllDetails[srtFullDetail.txType]
            .lendDetails[srtFullDetail.lendIndex]
            .assetAddressAndItsIndex[srtFullDetail.assetTokenAddress] = length;
    }

    function setUserDetail(P2pDefiLibrary.SrtFullDetail memory srtFullDetail)
        private
        returns (P2pDefiLibrary.SrtUserDetail storage userDetail)
    {
        uint256 length = mapAllDetails[srtFullDetail.txType]
            .lendDetails[srtFullDetail.lendIndex]
            .assetDetails[srtFullDetail.assetIndex]
            .userDetails
            .length;
        if (!(length > 1)) {
            mapAllDetails[srtFullDetail.txType]
                .lendDetails[srtFullDetail.lendIndex]
                .assetDetails[srtFullDetail.assetIndex]
                .userDetails
                .push();
            length++;
        }
        userDetail = mapAllDetails[srtFullDetail.txType]
            .lendDetails[srtFullDetail.lendIndex]
            .assetDetails[srtFullDetail.assetIndex]
            .userDetails
            .push();
        userDetail.isActive = srtFullDetail.isActive;
        userDetail.maxDetailId = srtFullDetail.maxDetailId;
        userDetail.userAddress = msg.sender;
        mapAllDetails[srtFullDetail.txType]
            .lendDetails[srtFullDetail.lendIndex]
            .assetDetails[srtFullDetail.assetIndex]
            .userAddressAndItsIndex[srtFullDetail.assetTokenAddress] = length;
    }

    function setDetail(P2pDefiLibrary.SrtFullDetail memory srtFullDetail)
        private
        returns (P2pDefiLibrary.SrtDetail storage detail)
    {
        uint256 length = mapAllDetails[srtFullDetail.txType]
            .lendDetails[srtFullDetail.lendIndex]
            .assetDetails[srtFullDetail.assetIndex]
            .userDetails[srtFullDetail.userIndex]
            .details
            .length;
        if (!(length > 1)) {
            mapAllDetails[srtFullDetail.txType]
                .lendDetails[srtFullDetail.lendIndex]
                .assetDetails[srtFullDetail.assetIndex]
                .userDetails[srtFullDetail.userIndex]
                .details
                .push();
            length++;
        }
        uint256[] memory detailIdsToOverwrite = mapAllDetails[
            srtFullDetail.txType
        ]
            .lendDetails[srtFullDetail.lendIndex]
            .assetDetails[srtFullDetail.assetIndex]
            .userDetails[srtFullDetail.userIndex]
            .detailIdsToOverwrite;
        if (detailIdsToOverwrite.length > 0) {
            srtFullDetail.detailId = detailIdsToOverwrite[
                detailIdsToOverwrite.length - 1
            ];
            srtFullDetail.detailIndex = mapAllDetails[srtFullDetail.txType]
                .lendDetails[srtFullDetail.lendIndex]
                .assetDetails[srtFullDetail.assetIndex]
                .userDetails[srtFullDetail.userIndex]
                .detailIdAndItsIndex[srtFullDetail.detailId];
            mapAllDetails[srtFullDetail.txType]
                .lendDetails[srtFullDetail.lendIndex]
                .assetDetails[srtFullDetail.assetIndex]
                .userDetails[srtFullDetail.userIndex]
                .detailIdsToOverwrite
                .pop();
            detail = mapAllDetails[srtFullDetail.txType]
                .lendDetails[srtFullDetail.lendIndex]
                .assetDetails[srtFullDetail.assetIndex]
                .userDetails[srtFullDetail.userIndex]
                .details[srtFullDetail.detailIndex];
        } else {
            mapAllDetails[srtFullDetail.txType]
                .lendDetails[srtFullDetail.lendIndex]
                .assetDetails[srtFullDetail.assetIndex]
                .userDetails[srtFullDetail.userIndex]
                .maxDetailId++;
            srtFullDetail.detailId = mapAllDetails[srtFullDetail.txType]
                .lendDetails[srtFullDetail.lendIndex]
                .assetDetails[srtFullDetail.assetIndex]
                .userDetails[srtFullDetail.userIndex]
                .maxDetailId;
            detail = mapAllDetails[srtFullDetail.txType]
                .lendDetails[srtFullDetail.lendIndex]
                .assetDetails[srtFullDetail.assetIndex]
                .userDetails[srtFullDetail.userIndex]
                .details
                .push();
            length++;
            srtFullDetail.detailIndex = length - 1;
        }
        detail.isActive = srtFullDetail.isActive;
        detail.side = srtFullDetail.side;
        detail.status = srtFullDetail.status;
        detail.rateOfInterest = srtFullDetail.rateOfInterest;
        detail.amount = srtFullDetail.amount;
        detail.termPeriodInDays = srtFullDetail.termPeriodInDays;
        // detail.partnerAmountAndAddress = srtDetail.partnerAmountAndAddress;
        detail.detailId = srtFullDetail.detailId;
        detail.updatedAt = block.timestamp;
        detail.validFrom = srtFullDetail.validFrom;
        detail.validTo = srtFullDetail.validTo;
        mapAllDetails[srtFullDetail.txType]
            .lendDetails[srtFullDetail.lendIndex]
            .assetDetails[srtFullDetail.assetIndex]
            .userDetails[srtFullDetail.userIndex]
            .detailIdAndItsIndex[srtFullDetail.detailId] = srtFullDetail
            .detailIndex;
    }

    function createP2pDefiDetail(
        P2pDefiLibrary.EnmTxType txType,
        P2pDefiLibrary.EnmSide side,
        uint32 rateOfInterest,
        uint256 termPeriodInDays,
        uint256 lendingAmount,
        address lendingToken,
        address assetToken
    ) public returns (uint256 detailId) {
        require(lendingAmount > 0, "Amount cannot be zero or less");
        detailId = 1;
        uint256 index = 1;
        P2pDefiLibrary.SrtFullDetail memory srtFullDetail;
        srtFullDetail.isActive = true;
        srtFullDetail.side = side;
        srtFullDetail.status = P2pDefiLibrary.EnmStatus.OPEN;
        srtFullDetail.rateOfInterest = rateOfInterest;
        srtFullDetail.amount = lendingAmount;
        srtFullDetail.termPeriodInDays = termPeriodInDays;
        srtFullDetail.detailId = detailId;
        srtFullDetail.validFrom = block.timestamp;
        srtFullDetail.validTo = 0;
        srtFullDetail.assetTokenAddress = assetToken;
        srtFullDetail.lendTokenAddress = lendingToken;
        srtFullDetail.lendIndex = index;
        srtFullDetail.assetIndex = index;
        srtFullDetail.userIndex = index;
        srtFullDetail.detailIndex = index;
        srtFullDetail.txType = txType;

        if (!mapAllDetails[srtFullDetail.txType].isActive) {
            setAllDetail(srtFullDetail);
            setLendDetail(srtFullDetail);
            setAssetDetail(srtFullDetail);
            setUserDetail(srtFullDetail);
            setDetail(srtFullDetail);
        } else {
            srtFullDetail.lendIndex = mapAllDetails[srtFullDetail.txType]
                .lendCoinAddressAndItsIndex[lendingToken];
            if (
                !mapAllDetails[srtFullDetail.txType]
                    .lendDetails[srtFullDetail.lendIndex]
                    .isActive
            ) {
                setLendDetail(srtFullDetail);
                setAssetDetail(srtFullDetail);
                setUserDetail(srtFullDetail);
                setDetail(srtFullDetail);
            } else {
                srtFullDetail.assetIndex = mapAllDetails[srtFullDetail.txType]
                    .lendDetails[srtFullDetail.lendIndex]
                    .assetAddressAndItsIndex[assetToken];

                if (
                    !mapAllDetails[srtFullDetail.txType]
                        .lendDetails[srtFullDetail.lendIndex]
                        .assetDetails[srtFullDetail.assetIndex]
                        .isActive
                ) {
                    setAssetDetail(srtFullDetail);
                    setUserDetail(srtFullDetail);
                    setDetail(srtFullDetail);
                } else {
                    srtFullDetail.userIndex = mapAllDetails[
                        srtFullDetail.txType
                    ]
                        .lendDetails[srtFullDetail.lendIndex]
                        .assetDetails[srtFullDetail.assetIndex]
                        .userAddressAndItsIndex[msg.sender];
                    if (
                        !mapAllDetails[srtFullDetail.txType]
                            .lendDetails[srtFullDetail.lendIndex]
                            .assetDetails[srtFullDetail.assetIndex]
                            .userDetails[srtFullDetail.userIndex]
                            .isActive
                    ) {
                        setUserDetail(srtFullDetail);
                        setDetail(srtFullDetail);
                    } else {
                        setDetail(srtFullDetail);
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
    enum EnmStatus {
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
    enum EnmSide {
        LEND,
        BORROW
    }
    enum EnmTxType {
        ORDER,
        TERM
    }

    struct SrtPartnerAmountAndAddress {
        uint256 amount;
        address userAddress;
    }

    struct SrtDetail {
        bool isActive;
        EnmSide side;
        EnmStatus status;
        uint32 rateOfInterest;
        uint256 amount;
        uint256 termPeriodInDays;
        uint256 detailId;
        uint256 updatedAt;
        uint256 validFrom;
        uint256 validTo;
        SrtPartnerAmountAndAddress[] partnerAmountAndAddress;
    }

    struct SrtUserDetail {
        bool isActive;
        uint256 maxDetailId;
        uint256[] detailIdsToOverwrite;
        address userAddress;
        SrtDetail[] details;
        mapping(uint256 => uint256) detailIdAndItsIndex;
    }

    struct SrtAssetDetail {
        bool isActive;
        uint256[] userAddressToOverwrite;
        address assetTokenAddress;
        SrtUserDetail[] userDetails;
        mapping(address => uint256) userAddressAndItsIndex;
    }

    struct SrtLendDetail {
        bool isActive;
        uint256[] assetTokenAddressToOverwrite;
        address lendTokenAddress;
        SrtAssetDetail[] assetDetails;
        mapping(address => uint256) assetAddressAndItsIndex;
    }

    struct SrtAllDetail {
        bool isActive;
        EnmTxType txType;
        uint256[] lendTokenAddressToOverwrite;
        SrtLendDetail[] lendDetails;
        mapping(address => uint256) lendCoinAddressAndItsIndex;
    }

    struct SrtFullDetail {
        bool isActive;
        EnmTxType txType;
        EnmSide side;
        EnmStatus status;
        uint32 rateOfInterest;
        uint256 amount;
        uint256 termPeriodInDays;
        uint256 detailId;
        uint256 updatedAt;
        uint256 validFrom;
        uint256 validTo;
        uint256 maxDetailId;
        uint256 detailIndex;
        uint256 userIndex;
        uint256 assetIndex;
        uint256 lendIndex;
        uint256[] detailIdsToOverwrite;
        uint256[] userAddressToOverwrite;
        uint256[] assetTokenAddressToOverwrite;
        address userAddress;
        address assetTokenAddress;
        address lendTokenAddress;
    }
}