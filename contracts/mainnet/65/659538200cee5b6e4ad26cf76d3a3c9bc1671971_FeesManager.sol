// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IERC11554K.sol";
import "./interfaces/IGuardians.sol";
import "./interfaces/IERC11554KController.sol";
import "./libraries/GuardianTimeMath.sol";
import "./interfaces/IERC20Metadata.sol";

/**
 * @dev Fees Manager that receives and manages fees
 * from items trading and guardian fees paid to guardians.
 */
contract FeesManager is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    /// @dev Trading fees split struct.
    struct TradingFeeSplit {
        uint256 protocol;
        uint256 guardian;
    }
    /// @notice Percentage factor for 0.01%.
    uint256 public constant PERCENTAGE_FACTOR = 10000;
    /// @notice Bucket size ~1 month.
    uint256 public constant BUCKET_SIZE = 30 * 24 * 60 * 60;
    /// @notice Global trading fee.
    uint256 public globalTradingFee;
    /// @notice TradingFeeSplit struct, trading fee split between protocol (default 80%) and guardian (default 20%).
    TradingFeeSplit public tradingFeeSplit;
    /// @notice Exchange contract.
    address public exchange;
    /// @notice Guardians contract.
    IGuardians public guardians;
    /// @notice Accumulated erc20 trading fees.
    mapping(IERC20Upgradeable => mapping(address => uint256)) public fees;
    /// @notice Anchor time, which is startig point for buckets, which is initialize time.
    uint256 public anchorTime;
    /// @notice Controller contract.
    IERC11554KController public controller;
    /// @notice Accumulated asset guardians fees by bucket.
    mapping(IERC20Upgradeable => mapping(address => mapping(uint256 => uint256)))
        public guardiansFees;
    /// @notice Last withdrawn fee bucket.
    mapping(IERC20Upgradeable => mapping(address => uint256))
        public lastWithdrawnBucket;
    /// @dev Trading Fees from an exchange have been received and organized for the beneficiaries - the protocol, the guardian, and the royalty receiver.
    event ReceivedFees(
        uint256 id,
        uint256 salePrice,
        IERC20Upgradeable asset,
        uint256 feeForProtocol,
        uint256 feeForGuardian,
        address guardian,
        uint256 feeForOriginator,
        address originator
    );
    /// @dev Guardian fees for an item have been paid.
    event PaidGuardianFee(
        address indexed payer,
        address indexed guardian,
        IERC20Upgradeable asset,
        uint256 amount
    );
    /// @dev Guardian fees have been refunded by a guardian.
    event RefundedGuardianFee(
        address indexed recepient,
        address indexed guardian,
        IERC20Upgradeable asset,
        uint256 amount
    );
    /// @dev Guardian fees moved from one guardian to another
    event MovedGuardianFees(
        address indexed guardianFrom,
        address indexed guardianTo,
        IERC20Upgradeable asset
    );
    /// @dev Guardian has withdrawn guardian fees.
    event WithdrawnGuardianFees(
        address indexed guardian,
        IERC20Upgradeable asset,
        uint256 amount
    );
    /// @dev Trading Fees have been claimed and withdrawn by a beneficiary - the protocol, the guardian, or the royalty receiver.
    event ClaimFees(address indexed claimer, uint256 fees);

    /**
     * @dev Only 4k exchange modifier.
     */
    modifier onlyExchange() {
        require(_msgSender() == exchange, "Callable only by 4K exchange");
        _;
    }

    /**
     * @dev Only 4k guardians modifier.
     */
    modifier onlyGuardians() {
        require(
            _msgSender() == address(guardians),
            "Callable only by guardians contract"
        );
        _;
    }

    /**
     * @notice Initialize FeesManager contract.
     * @param controller_ ERC11554K controller contract address.
     * @param guardians_ Guardians contract address.
     */
    function initialize(IERC11554KController controller_, IGuardians guardians_)
        external
        virtual
        initializer
    {
        __Ownable_init();
        globalTradingFee = 100;
        anchorTime = block.timestamp;
        controller = controller_;
        tradingFeeSplit = TradingFeeSplit(8000, 2000);
        guardians = guardians_;
    }

    /**
     * @notice Sets guardians to guardians_.
     *
     * Requirements:
     *
     * 1) The caller must be the owner.
     * @param guardians_ New Guardians contract address.
     */
    function setGuardians(IGuardians guardians_) external virtual onlyOwner {
        guardians = guardians_;
    }

    /**
     * @notice Sets controller to controller_.
     *
     * Requirements:
     *
     * 1) The caller must be the owner.
     * @param controller_ New Controller contract address.
     */
    function setController(IERC11554KController controller_)
        external
        virtual
        onlyOwner
    {
        controller = controller_;
    }

    /**
     * @notice Sets globalTradingFee to globalTradingFee_.
     *
     * Requirements:
     *
     * 1) The caller must be the owner.
     * @param globalTradingFee_ New global trading fee.
     */
    function setGlobalTradingFee(uint256 globalTradingFee_)
        external
        virtual
        onlyOwner
    {
        globalTradingFee = globalTradingFee_;
    }

    /**
     * @notice Sets tradingFeeSplit.
     *
     * Requirements:
     *
     * 1) The caller must be the owner.
     * @param protocolSplit New protocol fees share.
     * @param guardianSplit New guardians fees share.
     */
    function setTradingFeeSplit(uint256 protocolSplit, uint256 guardianSplit)
        external
        virtual
        onlyOwner
    {
        require(
            protocolSplit + guardianSplit == PERCENTAGE_FACTOR,
            "Percentages sum must be 100%"
        );
        tradingFeeSplit.protocol = protocolSplit;
        tradingFeeSplit.guardian = guardianSplit;
    }

    /**
     * @notice Sets exchange to exchange_.
     *
     * Requirements:
     *
     * 1) The caller must be the owner.
     * @param exchange_ New Exchange contract address.
     */
    function setExchange(address exchange_) external onlyOwner {
        exchange = exchange_;
    }

    /**
     * @dev Callback function to receive trading fees from item's trade on some exchange.
     * Splits trading fees according to trading fee splitting between a guardian, the protocol and an item original minter.
     *
     * Requirements:
     *
     * 1) The caller must be an exchange.
     * 2) The item must be stored at a guardian.
     * 3) Asset the asset that was used for the transaction and the unit of the salesprice. ie. USDT WBTC etc
     * 4) SalePrice is the total of the transaction. Scales up as more tokens are purchased.
     * @param erc11554k ERC11554K collection contract address.
     * @param id Item id, for which fees received during trade.
     * @param asset The asset that was used for the transaction and the unit of the salesprice. ie. USDT WBTC etc
     * @param salePrice The total of the transaction. Scales up as more tokens are purchased.
     */
    function receiveFees(
        IERC11554K erc11554k,
        uint256 id,
        IERC20Upgradeable asset,
        uint256 salePrice
    ) external virtual onlyExchange {
        address guardianAddress = guardians.whereItemStored(erc11554k, id);
        require(
            guardianAddress != address(0),
            "Item is not stored in any guardian"
        );
        address protocolBeneficiary = owner();

        uint256 feeForGuardian = (salePrice *
            globalTradingFee *
            tradingFeeSplit.guardian) / (PERCENTAGE_FACTOR * PERCENTAGE_FACTOR);
        uint256 feeForProtocol = (salePrice *
            globalTradingFee *
            tradingFeeSplit.protocol) / (PERCENTAGE_FACTOR * PERCENTAGE_FACTOR);
        (address originatorAddress, uint256 feeForOriginator) = erc11554k
            .royaltyInfo(id, salePrice);

        fees[asset][guardianAddress] += feeForGuardian;
        fees[asset][protocolBeneficiary] += feeForProtocol;
        fees[asset][originatorAddress] += feeForOriginator;

        emit ReceivedFees(
            id,
            salePrice,
            asset,
            feeForProtocol,
            feeForGuardian,
            guardianAddress,
            feeForOriginator,
            originatorAddress
        );
    }

    /**
     * @notice Claim ERC20 asset fees from fees manager.
     * @param asset ERC20 asset for which to claim fees.
     * @return claimed amount of fees claimed.
     */
    function claimFees(IERC20Upgradeable asset)
        external
        virtual
        returns (uint256 claimed)
    {
        address claimer = _msgSender();
        claimed = fees[asset][claimer];
        fees[asset][claimer] = 0;
        if (claimed > 0) {
            asset.safeTransfer(
                claimer,
                GuardianTimeMath.transformDecimalPrecision(
                    claimed,
                    IERC20Metadata(address(asset)).decimals()
                )
            );
        }
        emit ClaimFees(claimer, claimed);
    }

    /**
     * @dev Pays guardian fee for an item to guardian by payer.
     * Goes through corresponding time buckets of the guardian, derived
     * from storagePaidUntil and storage paid time before,
     * and increments proportional storageFeeAmount, using
     * guardianClassFeeRateMultiplied and bucket time span. Transfers payment.
     *
     * Requirements:
     *
     * 1) The caller must be Guardians contract.
     * 2) Fees payer must have approved storageFeeAmount for FeesManager on payment asset passed.
     * @param guardianFeeAmount Guardian fee amount paid by user to guardian.
     * @param guardianClassFeeRateMultiplied Guardian class fee rate multiplied by items held by user.
     * @param guardian Guardian address.
     * @param storagePaidUntil Storage fee paid until timestamp.
     * @param payer Payer address.
     */
    function payGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address payer,
        IERC20Upgradeable asset
    ) external virtual onlyGuardians {
        /// Storage paid until timestamp was updated in ERC11554K, calculates older one.
        uint256 storagePaidUntilBefore = storagePaidUntil -
            guardianFeeAmount /
            guardianClassFeeRateMultiplied;
        uint256 firstBucket = getBucket(storagePaidUntilBefore);
        uint256 lastBucket = getBucket(storagePaidUntil);
        for (uint256 i = firstBucket + 1; i < lastBucket; ++i) {
            guardiansFees[asset][guardian][i] +=
                BUCKET_SIZE *
                guardianClassFeeRateMultiplied;
        }
        if (lastBucket > firstBucket) {
            uint256 bucketStorageTime = ((firstBucket + 1) *
                BUCKET_SIZE +
                anchorTime) - storagePaidUntilBefore;
            guardiansFees[asset][guardian][firstBucket] +=
                bucketStorageTime *
                guardianClassFeeRateMultiplied;
            bucketStorageTime =
                storagePaidUntil -
                (lastBucket * BUCKET_SIZE + anchorTime);
            guardiansFees[asset][guardian][lastBucket] +=
                bucketStorageTime *
                guardianClassFeeRateMultiplied;
        } else {
            guardiansFees[asset][guardian][firstBucket] += guardianFeeAmount;
        }
        uint256 scaledAmount = GuardianTimeMath.transformDecimalPrecision(
            guardianFeeAmount,
            IERC20Metadata(address(asset)).decimals()
        );
        require(scaledAmount > 0, "Scaled fees are zero");
        asset.safeTransferFrom(payer, address(this), scaledAmount);
        emit PaidGuardianFee(payer, guardian, asset, guardianFeeAmount);
    }

    /**
     * @dev Refunds guardian fee guardianFeeAmount for an item from guardian to recipient,
     * based on guardianClassFeeRateMultiplied, storagePaidUntil. Iterates over buckets and
     * subtracts corresponding bucket storage fee amount. Accumulates it and transfers to the recipient.
     *
     * Disclaimer:
     * refundGuardianFee isn't currently used in the protocol.
     *
     * Requirements:
     *
     * 1) The caller must be Guardians contract.
     * @param guardianFeeAmount Guardian fee amount to refund to recipient from guardian.
     * @param guardianClassFeeRateMultiplied Guardian class fee rate multiplied by items held by user.
     * @param guardian Guardian address.
     * @param storagePaidUntil Storage fee paid until timestamp.
     * @param recipient Recipient address.
     */
    function refundGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address recipient,
        IERC20Upgradeable asset
    ) external virtual onlyGuardians {
        // Storage paid until timestamp was updated in ERC11554K, calculates older one.
        uint256 unusedStorageTimestamp = storagePaidUntil -
            guardianFeeAmount /
            guardianClassFeeRateMultiplied;
        uint256 firstBucket = getBucket(unusedStorageTimestamp);
        uint256 lastBucket = getBucket(storagePaidUntil);
        for (uint256 i = firstBucket + 1; i < lastBucket; ++i) {
            guardiansFees[asset][guardian][i] -=
                BUCKET_SIZE *
                guardianClassFeeRateMultiplied;
        }
        if (lastBucket > firstBucket) {
            uint256 bucketStorageTime = ((firstBucket + 1) *
                BUCKET_SIZE +
                anchorTime) - unusedStorageTimestamp;
            guardiansFees[asset][guardian][firstBucket] -=
                bucketStorageTime *
                guardianClassFeeRateMultiplied;
            bucketStorageTime =
                storagePaidUntil -
                (lastBucket * BUCKET_SIZE + anchorTime);
            guardiansFees[asset][guardian][lastBucket] -=
                bucketStorageTime *
                guardianClassFeeRateMultiplied;
        } else {
            guardiansFees[asset][guardian][firstBucket] -= guardianFeeAmount;
        }
        uint256 scaledAmount = GuardianTimeMath.transformDecimalPrecision(
            guardianFeeAmount,
            IERC20Metadata(address(asset)).decimals()
        );
        require(scaledAmount > 0, "Scaled fees are zero");
        asset.safeTransfer(recipient, scaledAmount);
        emit RefundedGuardianFee(recipient, guardian, asset, guardianFeeAmount);
    }

    /**
     * @notice Moves all guardian fees between guardians.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param guardianFrom Guardian address, from which fees are moved.
     * @param guardianTo Guardian address, to which fees are moved.
     */
    function moveFeesBetweenGuardians(
        address guardianFrom,
        address guardianTo,
        IERC20Upgradeable asset
    ) external virtual onlyOwner {
        uint256 curBucket = getBucket(block.timestamp) + 1;
        while (true) {
            uint256 amount = guardiansFees[asset][guardianFrom][curBucket];
            if (amount == 0) {
                break;
            }
            guardiansFees[asset][guardianFrom][curBucket] = 0;
            guardiansFees[asset][guardianTo][curBucket] += amount;
            ++curBucket;
        }
        emit MovedGuardianFees(guardianFrom, guardianTo, asset);
    }

    /**
     * @notice Withdraws all guardian fees by guardian until currentBucket-1 based on current block.timestamp.
     *
     * Requirements:
     *
     * 1) Last withdrawn bucket must be less than current bucket.
     */
    function withdrawGuardianFees(IERC20Upgradeable asset) external virtual {
        uint256 currentBucket = getBucket(block.timestamp);
        uint256 firstBucket = lastWithdrawnBucket[asset][_msgSender()];
        uint256 amount = 0;
        for (uint256 i = firstBucket; i < currentBucket; ++i) {
            amount += guardiansFees[asset][_msgSender()][i];
            guardiansFees[asset][_msgSender()][i] = 0;
        }
        require(amount > 0, "No guardian fees to withdraw");
        lastWithdrawnBucket[asset][_msgSender()] = currentBucket - 1;

        uint256 scaledAmount = GuardianTimeMath.transformDecimalPrecision(
            amount,
            IERC20Metadata(address(asset)).decimals()
        );
        require(scaledAmount > 0, "Scaled fees are zero");
        asset.safeTransfer(_msgSender(), scaledAmount);

        emit WithdrawnGuardianFees(_msgSender(), asset, amount);
    }

    /**
     * @notice Calculate trading fees for an item with erc11554k id and salePrice.
     * @param erc11554k The token contract/collection that will be traded and whose total fees the caller wants to know about.
     * @param id The id of the specific token that will be traded and whose total fees the caller wants to know about.
     * @param salePrice The total of the transaction. Scales up as more tokens are purchased.
     * @return the total fee, which is the sum of the originator royalty and the total trading fee.
     */
    function calculateTotalFee(
        IERC11554K erc11554k,
        uint256 id,
        uint256 salePrice
    ) public view virtual returns (uint256) {
        uint256 totalTradingFee = (salePrice * globalTradingFee) /
            PERCENTAGE_FACTOR;
        (, uint256 feeForOriginator) = erc11554k.royaltyInfo(id, salePrice);
        return feeForOriginator + totalTradingFee;
    }

    /**
     * @notice Returns bucket based on timestamp.
     * @param timestamp Timestamp from which bucket is derived.
     * @return returns Corresponding uint256 bucket.
     */
    function getBucket(uint256 timestamp)
        public
        view
        virtual
        returns (uint256)
    {
        return (timestamp - anchorTime) / BUCKET_SIZE;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev {IERC11554K} interface:
 */
interface IERC11554K {
    function controllerMint(
        address mintAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function controllerBurn(
        address burnAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function owner() external view returns (address);

    function balanceOf(address user, uint256 item)
        external
        view
        returns (uint256);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);

    function totalSupply(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev {IERC11554KController} interface:
 */
interface IERC11554KController {
    function owner() external returns (address);

    function originators(address collection, uint256 tokenId)
        external
        returns (address);

    function isActiveCollection(address collection) external returns (bool);

    function isLinkedCollection(address collection) external returns (bool);

    function paymentToken() external returns (IERC20Upgradeable);

    function maxMintPeriod() external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev GuardianTimeMath library. Provides support for converting between guardian fees and purchased storage time
 */
library GuardianTimeMath {
    /**
     * @dev Calculates the fee amount associated with the items
     * scaledByNumItems based on currGuardianFeePaidUntil guardianClassFeeRate
     * (scaled by the number being moved, for semi-fungibles).
     * @param currGuardianFeePaidUntil a timestamp that describes until when storage has been paid.
     * @param guardianClassFeeRate a guardian's guardian fee rate. Amount per second.
     * @param scaledByNumItems the number of items that are being stored by a guardian at the time of the query.
     * @return the remaining amount of guardian fee that is left within the `currGuardianFeePaidUntil` at the `guardianClassFeeRate` rate for `scaledByNumItems` items
     */
    function calculateRemainingFeeAmount(
        uint256 currGuardianFeePaidUntil,
        uint256 guardianClassFeeRate,
        uint256 guardianFeeRatePeriod,
        uint256 scaledByNumItems
    ) internal view returns (uint256) {
        if (currGuardianFeePaidUntil <= block.timestamp) {
            return 0;
        } else {
            return ((((currGuardianFeePaidUntil - block.timestamp) *
                guardianClassFeeRate) * scaledByNumItems) /
                guardianFeeRatePeriod);
        }
    }

    /**
     * @dev Calculates added guardian storage time based on
     * guardianFeePaid guardianClassFeeRate and numItems
     * (scaled by the number being moved, for semi-fungibles).
     * @param guardianFeePaid the amount of guardian fee that is being paid.
     * @param guardianClassFeeRate a guardian's guardian fee rate. Amount per time period.
     * @param guardianFeeRatePeriod the size of the period used in the guardian fee rate.
     * @param numItems the number of items that are being stored by a guardian at the time of the query.
     * @return the amount of guardian time that can be purchased from `guardianFeePaid` fee amount at the `guardianClassFeeRate` rate for `numItems` items
     */
    function calculateAddedGuardianTime(
        uint256 guardianFeePaid,
        uint256 guardianClassFeeRate,
        uint256 guardianFeeRatePeriod,
        uint256 numItems
    ) internal pure returns (uint256) {
        return
            (guardianFeePaid * guardianFeeRatePeriod) /
            (guardianClassFeeRate * numItems);
    }

    /**
     * @dev Function that allows us to transform an amount from the internal, 18 decimal format, to one that has another decimal precision.
     * @param internalAmount the amount in 18 decimal represenation.
     * @param toDecimals the amount of decimal precision we want the amount to have
     */
    function transformDecimalPrecision(
        uint256 internalAmount,
        uint256 toDecimals
    ) internal pure returns (uint256) {
        return (internalAmount / (10**(18 - toDecimals)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IERC20Metadata {
    function decimals() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";

/**
 * @dev {IGuardians} interface:
 */
interface IGuardians {
    function controllerStoreItem(
        IERC11554K collection,
        address mintAddress,
        uint256 id,
        address guardian,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount,
        uint256 numItems,
        address feePayer,
        IERC20Upgradeable paymentAsset
    ) external;

    function controllerTakeItemOut(
        address guardian,
        IERC11554K collection,
        uint256 id,
        uint256 numItems,
        address from
    ) external;

    function shiftGuardianFeesOnTokenMove(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function isAvailable(address guardian) external view returns (bool);

    function guardianInfo(address guardian)
        external
        view
        returns (
            bytes32,
            string memory,
            string memory,
            string memory,
            string memory,
            bool,
            bool
        );

    function guardianWhitelist(address guardian, address user)
        external
        view
        returns (bool);

    function delegated(address guardian) external view returns (address);

    function getRedemptionFee(address guardian, uint256 classID)
        external
        view
        returns (uint256);

    function getMintingFee(address guardian, uint256 classID)
        external
        view
        returns (uint256);

    function isClassActive(address guardian, uint256 classID)
        external
        view
        returns (bool);

    function minStorageTime() external view returns (uint256);

    function stored(
        address guardian,
        IERC11554K collection,
        uint256 id
    ) external view returns (uint256);

    function whereItemStored(IERC11554K collection, uint256 id)
        external
        view
        returns (address);

    function itemGuardianClass(IERC11554K collection, uint256 id)
        external
        view
        returns (uint256);

    function guardianFeePaidUntil(
        address user,
        address collection,
        uint256 id
    ) external view returns (uint256);

    function isFeeAboveMinimum(
        uint256 guardianFeeAmount,
        uint256 numItems,
        address guardian,
        uint256 guardianClassIndex
    ) external view returns (bool);

    function getGuardianFeeRateByCollectionItem(
        IERC11554K collection,
        uint256 itemId
    ) external view returns (uint256);

    function getGuardianFeeRate(address guardian, uint256 guardianClassIndex)
        external
        view
        returns (uint256);

    function inRepossession(
        address user,
        IERC11554K collection,
        uint256 id
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
interface IERC20PermitUpgradeable {
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