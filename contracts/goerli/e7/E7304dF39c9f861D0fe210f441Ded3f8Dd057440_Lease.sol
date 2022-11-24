// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IexecRateOracle} from './IexecRateOracle.sol';
import {FakeIexecRateOracle} from './FakeIexecOracle.sol';
import {ERC721A} from "./libs/ERC721A.sol";
import {TenantId} from "./TenantId.sol";
import {OwnerId} from "./OwnerId.sol";
import "hardhat/console.sol";

/**
 * @title Lease
 * @notice This contracts allows owners to create Leases & tenants to pay their rent.
 * @author Quentin DC @ Starton Hackathon 2022
 */
//TODO add withdraw function
//TODO ownable for updatable slippage ?
//TODO Add require on payment type (enum ?)

contract Lease {
    // =========================== Enums & Structs =============================
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint64 public constant DIVIDER = 10**18;
    uint8 private slippage = 200; // per 10_000

    /**
     * @notice Enum for the status of the rent payments
     */
    enum PaymentStatus {
        PENDING,
        PAID,
        NOT_PAID,
        CANCELLED,
        CONFLICT
    }

    enum LeaseStatus {
        ACTIVE,
        PENDING,
        ENDED,
        CANCELLED
    }

    /**
     * @notice Struct for a lease with price
     * @param ownerId The id of the owner
     * @param tenantId The id of the tenant
     * @param paymentData The rent payment related data
     * @param totalNumberOfRents The amount of rent payments for the lease
     * @param reviewStatus Review-related data
     * @param rentPaymentInterval The minimum interval between each rent payment
     * @param rentPaymentLimitTime The minimum interval to mark a rent payment as not paid
     * @param startDate The start date of the lease
     * @param cancellation Lease cancellation related data
     * @param rentPayments Array of all the rent payments of the lease
     * @param metaData Metadata of the lease
     */
    struct Lease {
        uint256 ownerId;
        uint256 tenantId;
        PaymentData paymentData;
        uint8 totalNumberOfRents;
        ReviewStatus reviewStatus;
        uint256 rentPaymentInterval;
        uint256 rentPaymentLimitTime;
        uint256 startDate;
        Cancellation cancellation;
        LeaseStatus status;
        RentPayment[] rentPayments;
        string metaData;
    }

    /**
     * @notice Struct representing payment-related data
     * @param rentAmount Amount of the rent
     * @param paymentToken Token in which the rent will be paid
     * @param rentCurrency CRYPTO if rent is in crypto. Otherwise fiat currency available in list.
     */
    struct PaymentData {
        uint256 rentAmount;
        address paymentToken;
        string currencyPair;
    }

    /**
     * @notice Struct for "multisig" cancellation. When both params are true, all pending payments are cancelled and
     * the lease is ended
     * @param cancelledByOwner Owner cancellation signature
     * @param cancelledByTenant Tenant cancellation signature
     */
    struct Cancellation {
        bool cancelledByOwner;
        bool cancelledByTenant;
    }

    /**
     * @notice Struct representing review-related data
     * @param ownerReviewed True if Owner reviewed the ended lease
     * @param tenantReviewed True if Owner reviewed the ended lease
     * @param ownerReviewUri Tenant review IPFS URI
     * @param tenantReviewUri Owner review IPFS URI
     */
    struct ReviewStatus {
        bool ownerReviewed;
        bool tenantReviewed;
        string ownerReviewUri;
        string tenantReviewUri;
    }

    /**
     * @notice Struct for rent payments
     * @param validationDate The timestamp of the rent status update
     * @param withoutIssues True is the tenant had no issues with the rented property during this rent period
     * @param exchangeRate Exchange rate between the rent currency and the payment token | "0" if rent in token or ETH
     * @param exchangeRateTimestamp Timestamp of the exchange rate | "0" if rent in token or ETH
     * @param paymentStatus The status of the payment
     */
    struct RentPayment {
        uint256 validationDate;
        bool withoutIssues;
        int256 exchangeRate;
        uint256 exchangeRateTimestamp;
        PaymentStatus paymentStatus;
    }

    // =========================== Mappings ==============================

    /**
     * @notice Mapping of all leases
     */
    mapping(uint256 => Lease) public leases;

//    string[] public availableCurrency = ['CRYPTO', 'USD', 'EUR'];

    OwnerId ownerContract;
    TenantId tenantContract;
//    FakeIexecOracle rateOracle;
    IexecRateOracle rateOracle;


    constructor (address _ownerContract, address _tenantContract, address _rateOracle) {
        _tokenIds.increment();
        ownerContract = OwnerId(_ownerContract);
        tenantContract = TenantId(_tenantContract);
//        rateOracle = FakeIexecOracle(_rateOracle);
        rateOracle = IexecRateOracle(_rateOracle);
    }

    // =========================== View functions ==============================

    /**
     * @notice Getter for all payments of a lease
     * @param _leaseId The id of the lease
     * @return rentPayments The array of all rent payments of the lease
     */
    function getPayments(uint256 _leaseId) external view returns(RentPayment[] memory rentPayments) {
        Lease storage lease = leases[_leaseId];
        return lease.rentPayments;
    }

    // =========================== User functions ==============================


    /**
     * @notice Function called by the owner to create a new lease
     * @param _tenantId The id of the tenant
     * @param _rentAmount The amount of the rent in fiat
     * @param _totalNumberOfRents The amount of rent payments for the lease
     * @param _paymentToken The address of the token used for payment
     * @param _rentPaymentInterval The minimum interval between each rent payment
     * @param _rentPaymentLimitTime The minimum interval to mark a rent payment as not paid
     * @param _currencyPair The currency pair used for rent price & payment | "CRYPTO" if rent in token or ETH
     * @param _startDate The start date of the lease
     */
    function createLease(
        uint256 _tenantId,
        uint256 _rentAmount,
        uint8 _totalNumberOfRents,
        address _paymentToken,
        uint256 _rentPaymentInterval,
        uint256 _rentPaymentLimitTime,
        string calldata _currencyPair,
        uint256 _startDate) external onlyTrustOwner
    {
        require(ownerContract.getOwnerIdFromAddress(msg.sender) != 0, "Lease: You are not an owner");
//        require(tenantContract.ownerOf(_tenantId) != address(0));
        require(tenantContract.getTenant(_tenantId).id != 0, "Lease: Tenant does not exist");
        require(tenantContract.tenantHasLease(_tenantId) == false, "Lease: Tenant already has a lease");

        Lease storage lease = leases[_tokenIds.current()];
        lease.ownerId = ownerContract.getOwnerIdFromAddress(msg.sender);
        lease.tenantId = _tenantId;
        lease.paymentData.rentAmount = _rentAmount;
        lease.totalNumberOfRents = _totalNumberOfRents;
        lease.paymentData.paymentToken = _paymentToken;
        lease.paymentData.currencyPair = _currencyPair;
        lease.rentPaymentInterval = _rentPaymentInterval;
        lease.rentPaymentLimitTime = _rentPaymentLimitTime;
        lease.startDate = _startDate;
        lease.status = LeaseStatus.PENDING;

        //Rent id starts at 0 as it will be the multiplicator for the Payment Intervals
        for(uint8 i = 0; i < lease.totalNumberOfRents; i++) {
            lease.rentPayments.push(RentPayment(0, false, 0, 0, PaymentStatus.PENDING));
        }

        emit LeaseCreated(_tokenIds.current(), _tenantId, lease.ownerId, _rentAmount, _totalNumberOfRents,
            _paymentToken, _rentPaymentInterval, _rentPaymentLimitTime, _startDate, _currencyPair);

        _tokenIds.increment();
    }

    /**
     * @notice Called by the tenant to update the lease metadata
     * @param _leaseId The id of the lease
     * @param _newCid The new IPFS URI of the lease metadata
     */
    function updateLeaseMetaData(uint256 _leaseId, string memory _newCid) external {
        Lease storage lease = leases[_leaseId];
        require(msg.sender == tenantContract.ownerOf(lease.tenantId),
            "Only the tenant can call this function");
        require(bytes(_newCid).length > 0, "Should provide a valid IPFS URI");

        lease.metaData = _newCid;

        emit LeaseMetaDataUpdated(_leaseId, _newCid);
    }


    /**
     * @notice Called by the tenant or the owner to decline the lease proposition
     * @param _leaseId The id of the lease
     */
    function declineLease(uint256 _leaseId) external {
        Lease storage lease = leases[_leaseId];
        require(msg.sender == tenantContract.ownerOf(lease.tenantId)
            || msg.sender == ownerContract.ownerOf(lease.ownerId),
            "Only the tenant or Owner can call this function");

        lease.status = LeaseStatus.CANCELLED;

        emit UpdateLeaseStatus(_leaseId, LeaseStatus.CANCELLED);
    }

    /**
     * @notice Called by the tenant to validate the lease
     * @param _leaseId The id of the lease
     */
    function validateLease(uint256 _leaseId) external {
        Lease storage lease = leases[_leaseId];
        require(lease.ownerId != 0, "Lease does not exist");
        require(msg.sender == tenantContract.ownerOf(lease.tenantId),
            "Only the tenant can call this function");
        require(lease.status == LeaseStatus.PENDING, "Lease was already validated");

        tenantContract.updateHasLease(lease.tenantId, true);
        lease.status = LeaseStatus.ACTIVE;

        emit LeaseValidated(_leaseId);
    }

    // COMMENTED FOR NOW - STILL IN DISCUSSION
    //    /**
    //     * @notice Called by the tenant to set a rent payment from with to without issues
    //     * @param _leaseId The id of the lease
    //     * @param _rentId The id of the rent
    //     */
    //    function setRentPaymentToWithoutIssues(uint256 _leaseId, uint256 _rentId) external  {
    //        Lease storage lease = leases[_leaseId];
    //        RentPayment storage rentPayment = lease.rentPayments[_rentId];
    //        require(msg.sender == tenantContract.ownerOf(lease.tenantId),
    //            "Only the tenant can call this function");
    //        require(rentPayment.withoutIssues == true, "Status is already set to true");
    //        rentPayment.withoutIssues = false;
    //
    //        emit RentPaymentIssueStatusUpdated(_leaseId, _rentId, false);
    //    }

    /**
     * @notice Used to pay a rent using ETH
     * @param _leaseId The id of the lease
     * @param _rentId The id of the rent
     * @param _withoutIssues "true" if the tenant had no issues with the rented property during this rent period
     */
    function payCryptoRentInETH(uint256 _leaseId, uint256 _rentId, bool _withoutIssues) external payable {
        Lease storage lease = leases[_leaseId];

        //TODO Will be implemented when exchangeRate switched to an index
        //        require(lease.paymentData.exchangeRate == 'CRYPTO', "Lease: Rent is not set to crypto");
        address ownerAddress = tenantContract.ownerOf(lease.tenantId);
        require(ownerAddress == msg.sender, "Only the tenant can perform this action");

        RentPayment storage rentPayment = lease.rentPayments[_rentId];

        require(lease.status == LeaseStatus.ACTIVE, "Lease is not Active");
        require(block.timestamp >= lease.startDate + lease.rentPaymentInterval * _rentId, "Payment not due");
        require(rentPayment.paymentStatus == PaymentStatus.PENDING, "Payment is not pending, please contact the owner");

        require(msg.value == lease.paymentData.rentAmount, "Wrong rent value");

        payable (ownerAddress).transfer(msg.value);

        _mintFromTenant(_leaseId, _rentId, PaymentStatus.PAID, _withoutIssues);
        _updateLeaseAndPaymentsStatuses(_leaseId);

        emit CryptoRentPaid(_leaseId, _rentId, _withoutIssues, msg.value);
    }

    /**
     * @notice Used to pay a rent in token using tokens
     * @param _leaseId The id of the lease
     * @param _rentId The id of the rent
     * @param _withoutIssues "true" if the tenant had no issues with the rented property during this rent period
     * @param _amount amount in tokens
     * @dev Only the registered tenant can call this function
     */
    function payCryptoRentInToken(uint256 _leaseId, uint256 _rentId, bool _withoutIssues, uint256 _amount) external {
        Lease storage lease = leases[_leaseId];
        //        require(lease.paymentData.exchangeRate == 'CRYPTO', "Lease: Rent is not set to crypto");

        require(tenantContract.ownerOf(lease.tenantId) == msg.sender, "Only the tenant can perform this action");

        RentPayment storage rentPayment = lease.rentPayments[_rentId];

        require(lease.status == LeaseStatus.ACTIVE, "Lease is not Active");
        require(block.timestamp >= lease.startDate + lease.rentPaymentInterval * _rentId, "Payment not due");
        require(rentPayment.paymentStatus == PaymentStatus.PENDING, "Payment is not pending, please contact the owner");

        IERC20 token = IERC20(lease.paymentData.paymentToken);

        require(token.balanceOf(msg.sender) >= _amount, "Not enough token balance");
        require(_amount >= lease.paymentData.rentAmount, "Wrong rent value");


        //Need allowance to Lease contract before executing this function
        token.transferFrom(msg.sender, ownerContract.ownerOf(lease.ownerId), _amount);

        _mintFromTenant(_leaseId, _rentId, PaymentStatus.PAID, _withoutIssues);
        _updateLeaseAndPaymentsStatuses(_leaseId);

        emit CryptoRentPaid(_leaseId, _rentId, _withoutIssues, _amount);
    }

    /**
     * @notice Used to pay a rent stated in Fiat currency using tokens
     * @param _leaseId The id of the lease
     * @param _rentId The id of the rent
     * @param _withoutIssues "true" if the tenant had no issues with the rented property during this rent period
     * @dev Only the registered tenant can call this function
     */
    function payFiatRentInEth(uint256 _leaseId, uint256 _rentId, bool _withoutIssues) external payable {
        Lease storage lease = leases[_leaseId];
        rateOracle.updateRate(lease.paymentData.currencyPair);

        //        require(lease.paymentData.exchangeRate != 'CRYPTO', "Lease: Rent is not set to fiat");
        address ownerAddress = tenantContract.ownerOf(lease.tenantId);
        require(ownerAddress == msg.sender, "Only the tenant can perform this action");

        RentPayment storage rentPayment = lease.rentPayments[_rentId];

        require(lease.status == LeaseStatus.ACTIVE, "Lease is not Active");
        require(block.timestamp >= lease.startDate + lease.rentPaymentInterval * _rentId, "Payment not due");
        require(rentPayment.paymentStatus == PaymentStatus.PENDING, "Payment is not pending, please contact the owner");


        (int256 exchangeRate, uint256 date) = rateOracle.getRate(lease.paymentData.currencyPair);
        rentPayment.exchangeRate = exchangeRate;
        rentPayment.exchangeRateTimestamp = date;

        // exchangeRate: in wei/Fiat | rentAmount in fiat currency
        uint256 rentAmountInWei = lease.paymentData.rentAmount * (uint256(exchangeRate));

        require(msg.value >= (rentAmountInWei - (rentAmountInWei * slippage) / 10000), "Wrong rent value");

        payable (ownerAddress).transfer(msg.value);

        _mintFromTenant(_leaseId, _rentId, PaymentStatus.PAID, _withoutIssues);
        _updateLeaseAndPaymentsStatuses(_leaseId);

        emit FiatRentPaid(_leaseId, _rentId, _withoutIssues, msg.value, exchangeRate, date);
    }

    /**
     * @notice Used to pay a rent using tokens NOT IMPLEMENTED YET
     * @param _leaseId The id of the lease
     * @param _rentId The id of the rent
     * @param _withoutIssues "true" if the tenant had no issues with the rented property during this rent period
     * @param _amountInSmallestDecimal amount in smallest token decimal
     * @dev Only the registered tenant can call this function
     */
    function payFiatRentInToken(uint256 _leaseId, uint256 _rentId, bool _withoutIssues, uint256 _amountInSmallestDecimal) external {
        Lease storage lease = leases[_leaseId];
        rateOracle.updateRate(lease.paymentData.currencyPair);

        //        require(lease.paymentData.exchangeRate != 'CRYPTO', "Lease: Rent is not set to fiat");

        require(tenantContract.ownerOf(lease.tenantId) == msg.sender, "Only the tenant can perform this action");

        RentPayment storage rentPayment = lease.rentPayments[_rentId];

        require(lease.status == LeaseStatus.ACTIVE, "Lease is not Active");
        require(block.timestamp >= lease.startDate + lease.rentPaymentInterval * _rentId, "Payment not due");
        require(rentPayment.paymentStatus == PaymentStatus.PENDING, "Payment is not pending, please contact the owner");

        IERC20 token = IERC20(lease.paymentData.paymentToken);

        require(token.balanceOf(msg.sender) >= _amountInSmallestDecimal, "Not enough token balance");

        (int256 exchangeRate, uint256 date) = rateOracle.getRate(lease.paymentData.currencyPair);
        rentPayment.exchangeRate = exchangeRate;
        rentPayment.exchangeRateTimestamp = date;

        // exchangeRate: in tokenDecimal/Fiat | rentAmount in fiat currency
        uint256 rentAmountInToken = lease.paymentData.rentAmount * (uint256(exchangeRate));

        require(_amountInSmallestDecimal >= (rentAmountInToken - (rentAmountInToken * slippage) / 10000), "Wrong rent value");

        token.transferFrom(msg.sender, ownerContract.ownerOf(lease.ownerId), _amountInSmallestDecimal);

        _mintFromTenant(_leaseId, _rentId, PaymentStatus.PAID, _withoutIssues);
        _updateLeaseAndPaymentsStatuses(_leaseId);

        emit FiatRentPaid(_leaseId, _rentId, _withoutIssues, _amountInSmallestDecimal, exchangeRate, date);
    }

    /**
     * @notice Can be called by the owner to mark a rent as not paid after the rent payment limit time is reached
     * @param _leaseId The id of the lease
     * @param _rentId The id of the rent
     * @dev Only the owner of the lease can call this function
     */
    function markRentAsNotPaid(uint256 _leaseId, uint256 _rentId) external {
        Lease storage lease = leases[_leaseId];
        require(msg.sender == ownerContract.ownerOf(lease.ownerId), "Only the owner can call this function");
        require(lease.status == LeaseStatus.ACTIVE, "Lease is not Active");
        require(block.timestamp > lease.startDate + lease.rentPaymentLimitTime * _rentId, "Tenant still has time to pay");

        RentPayment storage rentPayment = lease.rentPayments[_rentId];

        require(rentPayment.paymentStatus == PaymentStatus.PENDING, "Payment already has another status");

        _mint(_leaseId, _rentId, PaymentStatus.NOT_PAID);
        _updateLeaseAndPaymentsStatuses(_leaseId);

        emit RentNotPaid(_leaseId, _rentId);
    }

    /**
     * @notice Can be called by the owner to set a NOT_PAID rent back to PENDING, to give the tenant a possibility to pay his rent
     * @param _leaseId The id of the lease
     * @param _rentId The id of the rent
     * @dev Only the owner of the lease can call this function for a RentPayment set to NOT_PAID
     */
    function markRentAsPending(uint256 _leaseId, uint256 _rentId) external {
        Lease storage lease = leases[_leaseId];
        RentPayment storage rentPayment = lease.rentPayments[_rentId];
        require(msg.sender == ownerContract.ownerOf(lease.ownerId), "Only the owner can call this function");
        require(lease.status == LeaseStatus.ACTIVE, "Lease is not Active");
        require(rentPayment.paymentStatus == PaymentStatus.NOT_PAID, "Payment must be set to NOT_PAID");

        _mint(_leaseId, _rentId, PaymentStatus.PENDING);
        _updateLeaseAndPaymentsStatuses(_leaseId);

        emit SetRentToPending(_leaseId, _rentId);
    }

    /**
     * @notice Can be called by the owner or the tenant to cancel the remaining payments of a lease and make it as ended
     * @dev Both tenant and owner must call this function for the lease to be cancelled
     * @param _leaseId The id of the lease
     */
    function cancelLease(uint256 _leaseId) external {
        Lease storage lease = leases[_leaseId];
        require(lease.status == LeaseStatus.ACTIVE, "Lease is not Active");

        if(msg.sender == ownerContract.ownerOf(lease.ownerId)) {
            require(lease.cancellation.cancelledByOwner == false, "Lease already cancelled by owner");
            lease.cancellation.cancelledByOwner = true;
        } else if (msg.sender == tenantContract.ownerOf(lease.tenantId)) {
            require(lease.cancellation.cancelledByTenant == false, "Lease already cancelled by tenant");
            lease.cancellation.cancelledByTenant = true;
        } else {
            revert("Only the owner or the tenant can call this function");
        }

        emit CancellationRequested(_leaseId, lease.cancellation.cancelledByOwner, lease.cancellation.cancelledByTenant);

        if(lease.cancellation.cancelledByOwner && lease.cancellation.cancelledByTenant) {
            for(uint8 i = 0; i < lease.totalNumberOfRents; i++) {
                RentPayment storage rentPayment = lease.rentPayments[i];
                if(rentPayment.paymentStatus == PaymentStatus.PENDING) {
                    _mint(_leaseId, i, PaymentStatus.CANCELLED);
                }
            }
            _updateLeaseAndPaymentsStatuses(_leaseId);
        }
    }

    /**
     * @notice Can be called by the owner or the tenant to review the lease after the lease had been terminated
     * @param _leaseId The id of the lease
     * @param _reviewUri The IPFS URI of the review
     * @dev Only one review per tenant / owner. Can be called again to update the review.
     */
    function reviewLease(uint256 _leaseId, string calldata _reviewUri) external {
        Lease storage lease = leases[_leaseId];
        require(lease.status == LeaseStatus.ENDED, "Lease: Lease is still not finished");
        if(msg.sender == tenantContract.ownerOf(lease.tenantId)) {
            require(!lease.reviewStatus.tenantReviewed, "Lease: Tenant already reviewed");
            lease.reviewStatus.tenantReviewUri = _reviewUri;
            lease.reviewStatus.tenantReviewed = true;
            emit LeaseReviewedByTenant(_leaseId, _reviewUri);
        } else if(msg.sender == ownerContract.ownerOf(lease.ownerId)) {
            require(!lease.reviewStatus.ownerReviewed, "Lease: Owner already reviewed");
            lease.reviewStatus.ownerReviewUri = _reviewUri;
            lease.reviewStatus.ownerReviewed = true;
            emit LeaseReviewedByOwner(_leaseId, _reviewUri);
        } else {
            revert("You are not allowed to review this lease");
        }
    }

    // =========================== Private functions ===========================

    /**
     * @notice Private function to update the payment status & potential issues of a rent payment
     * @param _leaseId The id of the lease
     * @param _rentId The rent payment id
     * @param _paymentStatus The new payment status
     * @param _withoutIssues "true" if the tenant had no issues with the rented property during this rent period
     */
    function _mintFromTenant(uint256 _leaseId, uint256 _rentId, PaymentStatus _paymentStatus, bool _withoutIssues) private {
        RentPayment storage rentPayment = leases[_leaseId].rentPayments[_rentId];
        rentPayment.paymentStatus = _paymentStatus;
        rentPayment.withoutIssues = _withoutIssues;
        rentPayment.validationDate = block.timestamp;
    }

    /**
     * @notice Private function to update the payment status of a rent payment
     * @param _leaseId The id of the lease
     * @param _rentId The rent payment id
     * @param _paymentStatus The new payment status
     */
    function _mint(uint256 _leaseId, uint256 _rentId, PaymentStatus _paymentStatus) private {
        RentPayment storage rentPayment = leases[_leaseId].rentPayments[_rentId];
        rentPayment.paymentStatus = _paymentStatus;
        rentPayment.validationDate = block.timestamp;
    }

    /**
     * @notice Private function checking whether the lease is ended or not
     * @param _leaseId The id of the lease
     */
    function _updateLeaseAndPaymentsStatuses(uint256 _leaseId) private {
        Lease storage lease = leases[_leaseId];

        for(uint8 i = 0; i < lease.totalNumberOfRents; i++) {
            RentPayment storage rentPayment = lease.rentPayments[i];
            if(rentPayment.paymentStatus == PaymentStatus.PENDING ||
                rentPayment.paymentStatus == PaymentStatus.CONFLICT) {
                return;
            }
        }
        lease.status = LeaseStatus.ENDED;
        tenantContract.updateHasLease(lease.tenantId, false);

        emit UpdateLeaseStatus(_leaseId, lease.status);
    }

    // =========================== Events ==============================

    event LeaseCreated(
        uint256 leaseId,
        uint256 tenantId,
        uint256 ownerId,
        uint256 rentAmount,
        uint8 totalNumberOfRents,
        address paymentToken,
        uint256 rentPaymentInterval,
        uint256 rentPaymentLimitTime,
        uint256 startDate,
        string currencyPair);

    event LeaseValidated(uint256 leaseId);

    event RentPaymentIssueStatusUpdated(uint256 leaseId, uint256 rentId, bool withoutIssues);

    event CryptoRentPaid(uint256 leaseId, uint256 rentId, bool withoutIssues, uint256 amount);

    event FiatRentPaid(uint256 leaseId, uint256 rentId, bool withoutIssues, uint256 amount, int256 exchangeRate, uint256 exchangeRateTimestamp);

    event RentNotPaid(uint256 leaseId, uint256 rentId);

    event SetRentToPending(uint256 leaseId, uint256 rentId);

    event UpdateLeaseStatus(uint256 leaseId, LeaseStatus status);

    event CancellationRequested(uint256 leaseId, bool cancelledByOwner, bool cancelledByTenant);

    event LeaseReviewedByOwner(uint256 leaseId, string reviewUri);

    event LeaseReviewedByTenant(uint256 leaseId, string reviewUri);

    event LeaseMetaDataUpdated(uint256 leaseId, string metaData);

    // =========================== Modifiers ==============================

    modifier onlyTrustOwner() {
        require(ownerContract.balanceOf(msg.sender) != 0,
            "Only an owner can call this function");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Oracle} from "./libs/Oracle.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/**
 * @title IexecRateOracle
 * @notice This contracts is used to call several IexecOracle contracts used for calculating Fiat rent conversions in token
 * @author Quentin DC @ Starton Hackathon 2022
 */
contract IexecRateOracle is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _callId;

    Oracle iexecOracle;
    address public oracleAddress = 0x36dA71ccAd7A67053f0a4d9D5f55b725C9A25A3E;

    mapping(string => bytes32) public rateIndexToOracleKey;

    mapping(string => RateData) public rateIndexToRateData;

    struct RateData {
        int256 rate;
        uint256 timestamp;
    }

    constructor() {
        _callId.increment();
        iexecOracle = Oracle(oracleAddress);
        rateIndexToOracleKey['EUR-ETH'] = 0x86bb403e4f69c1bb69a6968c4301a2c625418a9cd5a6bbea7c5c1154bde66350;
        rateIndexToOracleKey['USD-ETH'] = 0x3b2a4f0ea99be0c500ece0ce3c4444bc48c3121e73efde91be84bc6f579b088c;
        rateIndexToOracleKey['USD-SHI'] = 0x3b2a4f0ea99be0c500ece0ce3c4444bc48c3121e73efde91be84bc6f579b088c;
    }

    function addOrUpdateOracleKey(string memory _rateIndex, bytes32 _oracleKey) external onlyOwner {
        rateIndexToOracleKey[_rateIndex] = _oracleKey;
    }

    function updateOracleAddress (address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
    }

    function updateRate(string memory _currencyPair) external {
        bytes32 oracleKey = rateIndexToOracleKey[_currencyPair];
        require(oracleKey != 0, "Rate not found");

        (int256 _rate, uint256 _date) = iexecOracle.getInt(oracleKey);
        rateIndexToRateData[_currencyPair] = RateData(_rate, _date);
    }

    function getRate(string calldata _currencyPair) external view returns (int256 _rate, uint256 _date) {
        RateData memory rateData = rateIndexToRateData[_currencyPair];
        return (rateData.rate, rateData.timestamp);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {ERC721A} from "./libs/ERC721A.sol";

/**
 * @title OwnerId contract
 * @notice This contracts allows users to create a unique ID for themselves as a real estate owner.
 * @author Quentin DC @ Starton Hackathon 2022
 */
contract OwnerId is ERC721A, AccessControl {
    // =========================== Structs ==============================

    /// @notice Owner information struct
    /// @param id the Owner ID
    /// @param name the name of the owner
    /// @param dataUri the IPFS URI of the Platform metadata
    struct Owner {
        uint256 id;
        string name;
        string dataUri;
    }

    /**
     * @notice Taken Owner names
     */
    mapping(string => bool) public takenNames;

    /**
     * @notice Token ID to Owner struct
     */
    mapping(uint256 => Owner) public owners;

    /**
     * @notice Role granting Minting permission
     */
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    constructor() ERC721A("OwnerId", "TOID") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =========================== View functions ==============================

    /**
     * @notice Allows retrieval of number of minted Owner IDs for a platform.
     * @param _ownerAddress Address of the owner of the Owner ID
     * @return the number of tokens minted by the owner
     */
    function numberMinted(address _ownerAddress) public view returns (uint256) {
        return balanceOf(_ownerAddress);
    }

    /**
     * @notice Allows getting the Owner ID from an address
     * @param _owner Owner Address to check
     * @return uint256 the Owner ID associated to this address
     */
    function getOwnerIdFromAddress(address _owner) external view returns (uint256) {
        uint256 ownedTokenId;
        uint256 currentTokenId = _startTokenId();
        address latestOwnerAddress;

        while (currentTokenId <= totalSupply()) {
            TokenOwnership memory ownership = _ownershipOf(currentTokenId);

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
                ownedTokenId = currentTokenId;
                break;
            }

            currentTokenId++;
        }

        return ownedTokenId;
    }

    // =========================== User functions ==============================

    /**
     * @dev MINT ROLE WAS COMMENTED FOR TESTING PURPOSES
     * @notice Allows an owner to mint a new Owner ID
     * @dev You need to have MINT_ROLE to use this function
     * @param _ownerName Owner Name
     */
    function mint(string memory _ownerName) external canMint(_ownerName)
//    onlyRole(MINT_ROLE)
    {
        _safeMint(msg.sender, 1);
        _afterMint(_ownerName);
    }

    /**
     * @notice Update Owner URI data.
     * @dev we are trusting the Owner to provide the valid IPFS URI
     * @param _ownerId Token ID to update
     * @param _newCid New IPFS URI
     */
    function updateProfileData(uint256 _ownerId, string memory _newCid) external {
        require(ownerOf(_ownerId) == msg.sender);
        require(bytes(_newCid).length > 0, "Should provide a valid IPFS URI");

        owners[_ownerId].dataUri = _newCid;

        emit CidUpdated(_ownerId, _newCid);
    }

    /**
     * @notice Check whether the Owner ID is valid.
     * @param _ownerId Owner ID
     */
    function isValid(uint256 _ownerId) external view {
        require(_ownerId > 0 && _ownerId <= totalSupply(), "Not a valid Owner ID");
    }


    // =========================== Owner functions ==============================


    // =========================== Private functions ==============================

    /**
     * @notice Update Owner name mapping and emit event after mint.
     * @param _ownerName Name of the platform
     */
    function _afterMint(string memory _ownerName) private {
        uint256 ownerId = _nextTokenId() - 1;
        Owner storage owner = owners[ownerId];
        owner.name = _ownerName;
        takenNames[_ownerName] = true;

        emit Mint(msg.sender, ownerId, _ownerName);
    }

    // =========================== Internal functions ==============================

    /**
     * Update the start token id to 1
     */
    function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
        return 1;
    }


    // =========================== Overrides ==============================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, AccessControl) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) {
        revert("Not allowed");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) {
        revert("Not allowed");
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        return _buildTokenURI(tokenId);
    }

    function _buildTokenURI(uint256 id) internal view returns (string memory) {
        string memory platformName = owners[id].name;

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 720 720"><defs><linearGradient id="a" x1="67.94" y1="169.48" x2="670.98" y2="562.86" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#17a9c2"/><stop offset=".12" stop-color="#1aa9bc"/><stop offset=".29" stop-color="#25abab"/><stop offset=".48" stop-color="#35ad8f"/><stop offset=".64" stop-color="#48b072"/><stop offset=".78" stop-color="#59b254"/><stop offset="1" stop-color="#7ab720"/></linearGradient></defs><path style="fill:url(#a)" d="M0 0h720v720H0z"/><path d="M47.05 92.37V53.84H33.29V46h36.85v7.84H56.41v38.52h-9.36Zm35.71-23.34-8.07-1.46c.91-3.25 2.47-5.65 4.68-7.21 2.21-1.56 5.5-2.34 9.87-2.34 3.96 0 6.92.47 8.86 1.41 1.94.94 3.31 2.13 4.1 3.57s1.19 4.1 1.19 7.96l-.1 10.37c0 2.95.14 5.13.43 6.53.28 1.4.82 2.91 1.6 4.51h-8.79c-.23-.59-.52-1.47-.85-2.63-.15-.53-.25-.88-.32-1.04-1.52 1.48-3.14 2.58-4.87 3.32s-3.57 1.11-5.54 1.11c-3.46 0-6.18-.94-8.18-2.82-1.99-1.88-2.99-4.25-2.99-7.12 0-1.9.45-3.59 1.36-5.08s2.18-2.63 3.81-3.42 3.99-1.48 7.07-2.07c4.15-.78 7.03-1.51 8.63-2.18v-.89c0-1.71-.42-2.93-1.27-3.65s-2.44-1.09-4.78-1.09c-1.58 0-2.82.31-3.7.93-.89.62-1.6 1.71-2.15 3.27Zm11.89 7.21c-1.14.38-2.94.83-5.41 1.36-2.47.53-4.08 1.04-4.84 1.55-1.16.82-1.74 1.87-1.74 3.13s.46 2.32 1.39 3.23c.93.91 2.11 1.36 3.54 1.36 1.6 0 3.13-.53 4.59-1.58 1.08-.8 1.78-1.78 2.12-2.94.23-.76.35-2.2.35-4.33v-1.77Zm17.49 16.13V46h8.89v46.37h-8.89Zm37.45-10.69 8.86 1.49c-1.14 3.25-2.94 5.72-5.39 7.42s-5.53 2.55-9.22 2.55c-5.84 0-10.16-1.91-12.97-5.72-2.21-3.06-3.32-6.92-3.32-11.58 0-5.57 1.46-9.93 4.36-13.08 2.91-3.15 6.59-4.73 11.04-4.73 5 0 8.94 1.65 11.83 4.95s4.27 8.36 4.14 15.17h-22.27c.06 2.64.78 4.69 2.15 6.15 1.37 1.47 3.08 2.2 5.12 2.2 1.39 0 2.56-.38 3.51-1.14.95-.76 1.67-1.98 2.15-3.67Zm.51-8.98c-.06-2.57-.73-4.53-1.99-5.87-1.27-1.34-2.81-2.01-4.62-2.01-1.94 0-3.54.71-4.81 2.12-1.27 1.41-1.89 3.33-1.87 5.76h13.28Zm46.62 19.67h-8.89V75.23c0-3.63-.19-5.97-.57-7.04-.38-1.06-1-1.89-1.85-2.48s-1.88-.89-3.08-.89c-1.54 0-2.92.42-4.14 1.27s-2.06 1.96-2.51 3.35c-.45 1.39-.68 3.96-.68 7.72v15.21h-8.89V58.78h8.26v4.93c2.93-3.8 6.62-5.69 11.07-5.69 1.96 0 3.75.35 5.38 1.06 1.62.71 2.85 1.61 3.68 2.7.83 1.1 1.41 2.34 1.74 3.73s.49 3.38.49 5.98v20.88Zm24.42-33.59v7.08h-6.07V79.4c0 2.74.06 4.34.17 4.79.12.45.38.83.79 1.12.41.3.91.44 1.5.44.82 0 2.01-.28 3.57-.85l.76 6.9c-2.07.89-4.41 1.33-7.02 1.33-1.6 0-3.05-.27-4.33-.81-1.29-.54-2.23-1.23-2.83-2.09-.6-.85-1.02-2.01-1.25-3.46-.19-1.03-.28-3.12-.28-6.26V65.86h-4.08v-7.08h4.08v-6.67l8.92-5.19v11.86h6.07Zm6.26 33.59V46h6.14v40.9h22.84v5.47h-28.97Zm57.47-4.14c-2.11 1.79-4.14 3.06-6.09 3.8-1.95.74-4.04 1.11-6.28 1.11-3.69 0-6.53-.9-8.51-2.7-1.98-1.8-2.97-4.11-2.97-6.91 0-1.64.37-3.15 1.12-4.51s1.73-2.45 2.94-3.27c1.21-.82 2.58-1.44 4.1-1.87 1.12-.3 2.8-.58 5.06-.85 4.6-.55 7.98-1.2 10.15-1.96.02-.78.03-1.28.03-1.49 0-2.32-.54-3.95-1.61-4.9-1.46-1.29-3.62-1.93-6.48-1.93-2.68 0-4.65.47-5.93 1.41s-2.22 2.6-2.83 4.98l-5.57-.76c.51-2.38 1.34-4.31 2.5-5.77 1.16-1.47 2.84-2.59 5.03-3.38 2.19-.79 4.73-1.19 7.62-1.19s5.2.34 6.99 1.01c1.79.68 3.11 1.52 3.95 2.55.84 1.02 1.43 2.31 1.77 3.88.19.97.28 2.72.28 5.25v7.59c0 5.29.12 8.64.36 10.04.24 1.4.72 2.75 1.44 4.03h-5.95c-.59-1.18-.97-2.56-1.14-4.14Zm-.47-12.72c-2.07.84-5.17 1.56-9.3 2.15-2.34.34-4 .72-4.97 1.14-.97.42-1.72 1.04-2.25 1.85s-.79 1.71-.79 2.7c0 1.52.57 2.78 1.72 3.8 1.15 1.01 2.83 1.52 5.05 1.52s4.14-.48 5.85-1.44 2.96-2.27 3.76-3.94c.61-1.29.92-3.18.92-5.69v-2.09Zm14.33 29.8-.63-5.35c1.24.34 2.33.51 3.26.51 1.27 0 2.28-.21 3.04-.63s1.38-1.01 1.87-1.77c.36-.57.94-1.98 1.74-4.24.11-.32.27-.78.51-1.39l-12.75-33.65h6.14l6.99 19.45c.91 2.47 1.72 5.06 2.44 7.78.65-2.61 1.43-5.17 2.34-7.65l7.18-19.58h5.69l-12.78 34.16c-1.37 3.69-2.44 6.23-3.19 7.62-1.01 1.88-2.17 3.25-3.48 4.13-1.31.88-2.87 1.31-4.68 1.31-1.1 0-2.32-.23-3.67-.7Zm55.63-23.76 5.88.73c-.93 3.44-2.65 6.1-5.16 8-2.51 1.9-5.71 2.85-9.62 2.85-4.91 0-8.81-1.51-11.69-4.54-2.88-3.03-4.32-7.27-4.32-12.73s1.46-10.04 4.36-13.16c2.91-3.12 6.68-4.68 11.32-4.68s8.16 1.53 11.01 4.59c2.85 3.06 4.27 7.36 4.27 12.91 0 .34-.01.84-.03 1.52h-25.05c.21 3.69 1.25 6.52 3.13 8.48 1.88 1.96 4.22 2.94 7.02 2.94 2.09 0 3.87-.55 5.35-1.64 1.48-1.1 2.65-2.85 3.51-5.25Zm-18.69-9.2h18.76c-.25-2.83-.97-4.94-2.15-6.36-1.81-2.19-4.17-3.29-7.05-3.29-2.61 0-4.81.88-6.6 2.63s-2.77 4.09-2.96 7.02Zm31.66 20.02V58.78h5.12v5.09c1.31-2.38 2.51-3.95 3.62-4.71s2.32-1.14 3.65-1.14c1.92 0 3.87.61 5.85 1.83l-1.96 5.28c-1.39-.82-2.78-1.23-4.18-1.23-1.24 0-2.36.37-3.35 1.12-.99.75-1.7 1.79-2.12 3.12-.63 2.02-.95 4.24-.95 6.64v17.59h-5.69Zm21.79 0V46h9.36v46.37h-9.36ZM407.37 46h17.11c3.86 0 6.8.3 8.83.89 2.72.8 5.05 2.22 6.99 4.27 1.94 2.05 3.42 4.55 4.43 7.51 1.01 2.96 1.52 6.62 1.52 10.96 0 3.82-.47 7.11-1.42 9.87-1.16 3.37-2.82 6.1-4.97 8.19-1.62 1.58-3.82 2.82-6.58 3.7-2.07.65-4.83.98-8.29.98h-17.62V46Zm9.36 7.84v30.71h6.99c2.61 0 4.5-.15 5.66-.44 1.52-.38 2.78-1.02 3.78-1.93 1-.91 1.82-2.4 2.45-4.48.63-2.08.95-4.91.95-8.49s-.32-6.34-.95-8.26-1.52-3.42-2.66-4.49-2.58-1.8-4.33-2.18c-1.31-.3-3.87-.44-7.69-.44h-4.21Z" style="fill:#fff"/><text y="670" x="30" style="font:70px sans-serif;fill:#fff">',
                        platformName,
                        "</text></svg>"
                    )
                )
            )
        );
        return
        string(
        abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
        bytes(
        abi.encodePacked(
        '{"name":"',
        platformName,
        '", "image":"',
        image,
        unicode'", "description": "Owner ID"}'
        )
        )
        )
        )
        );
    }

    // =========================== Modifiers ==============================

    /**
     * Check if Owner is able to mint a new ID.
     * @param _ownerName name for the owner
     */
    modifier canMint(string memory _ownerName) {
        require(numberMinted(msg.sender) == 0, "You already have an ID");
        require(bytes(_ownerName).length >= 2, "Name too short");
        require(bytes(_ownerName).length <= 10, "Name too long");
        require(!takenNames[_ownerName], "Name already taken");
        _;
    }

    // =========================== Events ==============================

    /**
     * Emit when new Owner ID is minted.
     * @param _ownerAddress Address of the owner of the ID
     * @param _tokenId New Owner ID
     * @param _ownerName Name of the Owner
     */
    event Mint(address indexed _ownerAddress, uint256 _tokenId, string _ownerName);

    /**
     * Emit when Cid is updated for a platform.
     * @param _tokenId ID concerned
     * @param _newCid New URI
     */
    event CidUpdated(uint256 indexed _tokenId, string _newCid);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {ERC721A} from "./libs/ERC721A.sol";

/**
 * @title Tenant ID
 * @notice This contracts allows users to create a unique ID for themselves as a tenant.
 * @author Quentin DC @ Starton Hackathon 2022
 */
contract TenantId is ERC721A, Ownable {
    // =========================== Structs ==============================

    /// @notice Tenant information struct
    /// @param profileId the id of the profile
    /// @param handle the handle of the profile
    /// @param hasLease true is tenant is already in a lease
    /// @param dataUri the IPFS URI of the profile metadata
    struct Tenant {
        uint256 id;
        string handle;
        bool hasLease;
        string dataUri;
    }

    // =========================== Mappings & Variables ==============================

    /// Taken handles
    mapping(string => bool) public takenHandles;

    /// Token ID to Profile struct
    mapping(uint256 => Tenant) public tenants;

    /**
     * @notice The address of the lease contract
     */
    address private leastContractAddress;

    /**
     */
    constructor() ERC721A("UserId", "TID") {}

    // =========================== View functions ==============================

    /**
     * Allows retrieval of number of minted IDs for a user.
     * @param _user Address of the owner of the tenant Id
     * @return the number of tokens minted by the user
     */
    function numberMinted(address _user) public view returns (uint256) {
        return balanceOf(_user);
    }

    function getTenant(uint256 _tenantId) external view returns (Tenant memory) {
        require(_exists(_tenantId), "TenantId: Profile does not exist");
        return tenants[_tenantId];
    }

    function tenantHasLease(uint256 _tenantId) external view returns (bool hasLease) {
        require(_exists(_tenantId), "TenantId: Profile does not exist");
        return tenants[_tenantId].hasLease;
    }

    /**
     * Allows getting the TenantId of one address
     * @param _tenantAddress Address to check
     * @return uint256 the id of the NFT
     */
    function getUserId(address _tenantAddress) public view returns (uint256) {
        uint256 ownedTokenId;
        uint256 currentTokenId = _startTokenId();
        address latestOwnerAddress;

        while (currentTokenId <= totalSupply()) {
            TokenOwnership memory ownership = _ownershipOf(currentTokenId);

            if (!ownership.burned && ownership.addr != address(0)) {
                latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _tenantAddress) {
                ownedTokenId = currentTokenId;
                break;
            }

            currentTokenId++;
        }

        return ownedTokenId;
    }


    // =========================== User functions ==============================

    /**
     * Allows a user to mint a new Tenant Id without the need of Proof of Humanity.
     * @param _handle Handle for the user
     */
    function mint(string memory _handle) external canMint(_handle) {
        _safeMint(msg.sender, 1);
        _afterMint(_handle);
    }

    /**
     * @notice Update user data.
     * @dev we are trusting the user to provide the valid IPFS URI
     * @param _tokenId Token ID to update
     * @param _newCid New IPFS URI
     */
    function updateProfileData(uint256 _tokenId, string memory _newCid) external {
        require(ownerOf(_tokenId) == msg.sender);
        require(bytes(_newCid).length > 0, "Should provide a valid IPFS URI");
        tenants[_tokenId].dataUri = _newCid;

        emit CidUpdated(_tokenId, _newCid);
    }

    /**
     * @notice Update the user 'hasLease' prop.
     * @dev Only the Lease contract can update this status
     * @param _tokenId Token ID to update
     * @param _hasLease True is tenant is already in a lease
     */
    function updateHasLease(uint256 _tokenId, bool _hasLease) external onlyLeaseContract {
        require(_exists(_tokenId), "TenantId: This user does not exist");
        tenants[_tokenId].hasLease = _hasLease;

        emit TenantHasLeaseUpdated(_tokenId, _hasLease);
    }

    /**
     * @notice Check whether the Tenant ID is valid.
     * @param _tenantId Owner ID
     */
    function isValid(uint256 _tenantId) external view {
        require(_tenantId > 0 && _tenantId <= totalSupply(), "Not a valid Tenant ID");
    }



    // =========================== Owner functions ==============================


    function updateLeaseContractAddress(address _leaseContractAddress) external onlyOwner {
        require(_leaseContractAddress != address(0), "TenantId: lease contract address cannot be zero address");
        leastContractAddress = _leaseContractAddress;
    }


    // =========================== Private functions ===========================

    /**
     * Update handle address mapping and emit event after mint.
     * @param _handle Handle for the user
     */
    function _afterMint(string memory _handle) private {
        uint256 userTokenId = _nextTokenId() - 1;
        Tenant storage profile = tenants[userTokenId];
        profile.id = userTokenId;
        profile.handle = _handle;
        takenHandles[_handle] = true;

        emit Mint(msg.sender, userTokenId, _handle);
    }

    // =========================== Internal functions ==========================

    /**
     * Update the start token id to 1
     */
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    // =========================== Overrides ==============================

    /**
     * @notice Ids Transfers are blocked. TenantIds are SBTs.
     * @dev Transfer functions blocked for this contract
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) {
        revert("Not allowed");
    }

    /**
     * @notice Ids Transfers are blocked. TenantIds are SBTs.
     * @dev Transfer functions blocked for this contract
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721A) {
        revert("Not allowed");
    }

    /**
     * @notice See IERC721A.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A) returns (string memory) {
        return _buildTokenURI(tokenId);
    }

    function _buildTokenURI(uint256 id) internal view returns (string memory) {
        string memory username = tenants[id].handle;

        bytes memory image = abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(
                bytes(
                    abi.encodePacked(
                        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 720 720"><defs><linearGradient id="a" x1="67.94" y1="169.48" x2="670.98" y2="562.86" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#17a9c2"/><stop offset=".12" stop-color="#1aa9bc"/><stop offset=".29" stop-color="#25abab"/><stop offset=".48" stop-color="#35ad8f"/><stop offset=".64" stop-color="#48b072"/><stop offset=".78" stop-color="#59b254"/><stop offset="1" stop-color="#7ab720"/></linearGradient></defs><path style="fill:url(#a)" d="M0 0h720v720H0z"/><path d="M47.05 92.37V53.84H33.29V46h36.85v7.84H56.41v38.52h-9.36Zm35.71-23.34-8.07-1.46c.91-3.25 2.47-5.65 4.68-7.21 2.21-1.56 5.5-2.34 9.87-2.34 3.96 0 6.92.47 8.86 1.41 1.94.94 3.31 2.13 4.1 3.57s1.19 4.1 1.19 7.96l-.1 10.37c0 2.95.14 5.13.43 6.53.28 1.4.82 2.91 1.6 4.51h-8.79c-.23-.59-.52-1.47-.85-2.63-.15-.53-.25-.88-.32-1.04-1.52 1.48-3.14 2.58-4.87 3.32s-3.57 1.11-5.54 1.11c-3.46 0-6.18-.94-8.18-2.82-1.99-1.88-2.99-4.25-2.99-7.12 0-1.9.45-3.59 1.36-5.08s2.18-2.63 3.81-3.42 3.99-1.48 7.07-2.07c4.15-.78 7.03-1.51 8.63-2.18v-.89c0-1.71-.42-2.93-1.27-3.65s-2.44-1.09-4.78-1.09c-1.58 0-2.82.31-3.7.93-.89.62-1.6 1.71-2.15 3.27Zm11.89 7.21c-1.14.38-2.94.83-5.41 1.36-2.47.53-4.08 1.04-4.84 1.55-1.16.82-1.74 1.87-1.74 3.13s.46 2.32 1.39 3.23c.93.91 2.11 1.36 3.54 1.36 1.6 0 3.13-.53 4.59-1.58 1.08-.8 1.78-1.78 2.12-2.94.23-.76.35-2.2.35-4.33v-1.77Zm17.49 16.13V46h8.89v46.37h-8.89Zm37.45-10.69 8.86 1.49c-1.14 3.25-2.94 5.72-5.39 7.42s-5.53 2.55-9.22 2.55c-5.84 0-10.16-1.91-12.97-5.72-2.21-3.06-3.32-6.92-3.32-11.58 0-5.57 1.46-9.93 4.36-13.08 2.91-3.15 6.59-4.73 11.04-4.73 5 0 8.94 1.65 11.83 4.95s4.27 8.36 4.14 15.17h-22.27c.06 2.64.78 4.69 2.15 6.15 1.37 1.47 3.08 2.2 5.12 2.2 1.39 0 2.56-.38 3.51-1.14.95-.76 1.67-1.98 2.15-3.67Zm.51-8.98c-.06-2.57-.73-4.53-1.99-5.87-1.27-1.34-2.81-2.01-4.62-2.01-1.94 0-3.54.71-4.81 2.12-1.27 1.41-1.89 3.33-1.87 5.76h13.28Zm46.62 19.67h-8.89V75.23c0-3.63-.19-5.97-.57-7.04-.38-1.06-1-1.89-1.85-2.48s-1.88-.89-3.08-.89c-1.54 0-2.92.42-4.14 1.27s-2.06 1.96-2.51 3.35c-.45 1.39-.68 3.96-.68 7.72v15.21h-8.89V58.78h8.26v4.93c2.93-3.8 6.62-5.69 11.07-5.69 1.96 0 3.75.35 5.38 1.06 1.62.71 2.85 1.61 3.68 2.7.83 1.1 1.41 2.34 1.74 3.73s.49 3.38.49 5.98v20.88Zm24.42-33.59v7.08h-6.07V79.4c0 2.74.06 4.34.17 4.79.12.45.38.83.79 1.12.41.3.91.44 1.5.44.82 0 2.01-.28 3.57-.85l.76 6.9c-2.07.89-4.41 1.33-7.02 1.33-1.6 0-3.05-.27-4.33-.81-1.29-.54-2.23-1.23-2.83-2.09-.6-.85-1.02-2.01-1.25-3.46-.19-1.03-.28-3.12-.28-6.26V65.86h-4.08v-7.08h4.08v-6.67l8.92-5.19v11.86h6.07Zm6.26 33.59V46h6.14v40.9h22.84v5.47h-28.97Zm57.47-4.14c-2.11 1.79-4.14 3.06-6.09 3.8-1.95.74-4.04 1.11-6.28 1.11-3.69 0-6.53-.9-8.51-2.7-1.98-1.8-2.97-4.11-2.97-6.91 0-1.64.37-3.15 1.12-4.51s1.73-2.45 2.94-3.27c1.21-.82 2.58-1.44 4.1-1.87 1.12-.3 2.8-.58 5.06-.85 4.6-.55 7.98-1.2 10.15-1.96.02-.78.03-1.28.03-1.49 0-2.32-.54-3.95-1.61-4.9-1.46-1.29-3.62-1.93-6.48-1.93-2.68 0-4.65.47-5.93 1.41s-2.22 2.6-2.83 4.98l-5.57-.76c.51-2.38 1.34-4.31 2.5-5.77 1.16-1.47 2.84-2.59 5.03-3.38 2.19-.79 4.73-1.19 7.62-1.19s5.2.34 6.99 1.01c1.79.68 3.11 1.52 3.95 2.55.84 1.02 1.43 2.31 1.77 3.88.19.97.28 2.72.28 5.25v7.59c0 5.29.12 8.64.36 10.04.24 1.4.72 2.75 1.44 4.03h-5.95c-.59-1.18-.97-2.56-1.14-4.14Zm-.47-12.72c-2.07.84-5.17 1.56-9.3 2.15-2.34.34-4 .72-4.97 1.14-.97.42-1.72 1.04-2.25 1.85s-.79 1.71-.79 2.7c0 1.52.57 2.78 1.72 3.8 1.15 1.01 2.83 1.52 5.05 1.52s4.14-.48 5.85-1.44 2.96-2.27 3.76-3.94c.61-1.29.92-3.18.92-5.69v-2.09Zm14.33 29.8-.63-5.35c1.24.34 2.33.51 3.26.51 1.27 0 2.28-.21 3.04-.63s1.38-1.01 1.87-1.77c.36-.57.94-1.98 1.74-4.24.11-.32.27-.78.51-1.39l-12.75-33.65h6.14l6.99 19.45c.91 2.47 1.72 5.06 2.44 7.78.65-2.61 1.43-5.17 2.34-7.65l7.18-19.58h5.69l-12.78 34.16c-1.37 3.69-2.44 6.23-3.19 7.62-1.01 1.88-2.17 3.25-3.48 4.13-1.31.88-2.87 1.31-4.68 1.31-1.1 0-2.32-.23-3.67-.7Zm55.63-23.76 5.88.73c-.93 3.44-2.65 6.1-5.16 8-2.51 1.9-5.71 2.85-9.62 2.85-4.91 0-8.81-1.51-11.69-4.54-2.88-3.03-4.32-7.27-4.32-12.73s1.46-10.04 4.36-13.16c2.91-3.12 6.68-4.68 11.32-4.68s8.16 1.53 11.01 4.59c2.85 3.06 4.27 7.36 4.27 12.91 0 .34-.01.84-.03 1.52h-25.05c.21 3.69 1.25 6.52 3.13 8.48 1.88 1.96 4.22 2.94 7.02 2.94 2.09 0 3.87-.55 5.35-1.64 1.48-1.1 2.65-2.85 3.51-5.25Zm-18.69-9.2h18.76c-.25-2.83-.97-4.94-2.15-6.36-1.81-2.19-4.17-3.29-7.05-3.29-2.61 0-4.81.88-6.6 2.63s-2.77 4.09-2.96 7.02Zm31.66 20.02V58.78h5.12v5.09c1.31-2.38 2.51-3.95 3.62-4.71s2.32-1.14 3.65-1.14c1.92 0 3.87.61 5.85 1.83l-1.96 5.28c-1.39-.82-2.78-1.23-4.18-1.23-1.24 0-2.36.37-3.35 1.12-.99.75-1.7 1.79-2.12 3.12-.63 2.02-.95 4.24-.95 6.64v17.59h-5.69Zm21.79 0V46h9.36v46.37h-9.36ZM407.37 46h17.11c3.86 0 6.8.3 8.83.89 2.72.8 5.05 2.22 6.99 4.27 1.94 2.05 3.42 4.55 4.43 7.51 1.01 2.96 1.52 6.62 1.52 10.96 0 3.82-.47 7.11-1.42 9.87-1.16 3.37-2.82 6.1-4.97 8.19-1.62 1.58-3.82 2.82-6.58 3.7-2.07.65-4.83.98-8.29.98h-17.62V46Zm9.36 7.84v30.71h6.99c2.61 0 4.5-.15 5.66-.44 1.52-.38 2.78-1.02 3.78-1.93 1-.91 1.82-2.4 2.45-4.48.63-2.08.95-4.91.95-8.49s-.32-6.34-.95-8.26-1.52-3.42-2.66-4.49-2.58-1.8-4.33-2.18c-1.31-.3-3.87-.44-7.69-.44h-4.21Z" style="fill:#fff"/><text y="670" x="30" style="font:70px sans-serif;fill:#fff">',
                        username,
                        "</text></svg>"
                    )
                )
            )
        );
        return
        string(
        abi.encodePacked(
        "data:application/json;base64,",
        Base64.encode(
        bytes(
        abi.encodePacked(
        '{"name":"',
        username,
        '", "image":"',
        image,
        unicode'", "description": "Tenant User ID"}'
        )
        )
        )
        )
        );
    }

    // =========================== Modifiers ==============================

    /**
     * Check if user is able to mint a new Tenant Id.
     * @param _handle Handle for the user
     */
    modifier canMint(string memory _handle) {
        require(numberMinted(msg.sender) == 0, "You already have a Tenant Id");
        require(bytes(_handle).length >= 2, "Handle too short");
        require(bytes(_handle).length <= 10, "Handle too long");
        require(!takenHandles[_handle], "Handle already taken");
        _;
    }

    // =========================== Events ==============================

    /**
     * Emit when new Tenant Id is minted.
     * @param _address Address of the owner of the Tenant Id
     * @param _tokenId Tenant Id for the user
     * @param _handle Handle for the user
     */
    event Mint(address indexed _address, uint256 _tokenId, string _handle);

    /**
     * Emit when Cid is updated for a user.
     * @param _tokenId Tenant Id ID for the user
     * @param _newCid Content ID
     */
    event CidUpdated(uint256 indexed _tokenId, string _newCid);

    /**
     * Emit when the tenant's lease status changes.
     * @param tokenId Tenant Id ID for the user
     * @param hasLease True is tenant is on lease, false otherwise
     */
    event TenantHasLeaseUpdated(uint256 tokenId, bool hasLease);


    // =========================== Modifiers ==============================

    modifier onlyLeaseContract() {
        require(msg.sender == leastContractAddress,
            "TenantId: Only the lease contract can call this function");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Oracle} from "./libs/Oracle.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

/**
 * @title IexecRateOracle
 * @notice This contracts is used to call several IexecOracle contracts used for calculating Fiat rent conversions in token
 * @author Quentin DC @ Starton Hackathon 2022
 */
contract FakeIexecRateOracle is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _callId;

    Oracle iexecOracle;
    address public oracleAddress = 0x36dA71ccAd7A67053f0a4d9D5f55b725C9A25A3E;

    mapping(string => bytes32) public rateIndexToOracleKey;

    mapping(string => RateData) public rateIndexToRateData;

    struct RateData {
        int256 rate;
        uint256 timestamp;
    }

    constructor() {
        _callId.increment();
        iexecOracle = Oracle(oracleAddress);
        rateIndexToOracleKey['EUR-ETH'] = 0x86bb403e4f69c1bb69a6968c4301a2c625418a9cd5a6bbea7c5c1154bde66350;
        rateIndexToOracleKey['USD-ETH'] = 0x3b2a4f0ea99be0c500ece0ce3c4444bc48c3121e73efde91be84bc6f579b088c;
        rateIndexToOracleKey['USD-SHI'] = 0x3b2a4f0ea99be0c500ece0ce3c4444bc48c3121e73efde91be84bc6f579b088c;
    }

    function addOrUpdateOracleKey(string memory _rateIndex, bytes32 _oracleKey) external onlyOwner {
        rateIndexToOracleKey[_rateIndex] = _oracleKey;
    }

    function updateOracleAddress (address _oracleAddress) external onlyOwner {
        oracleAddress = _oracleAddress;
    }

    function updateRate(string memory _currencyPair) external {
        bytes32 oracleKey = rateIndexToOracleKey[_currencyPair];
        require(oracleKey != 0, "Rate not found");

//        (int256 _rate, uint256 _date) = iexecOracle.getInt(oracleKey);

        rateIndexToRateData[_currencyPair] = RateData(852430000000000, 1669203550);
    }

    function getRate(string calldata _currencyPair) external view returns (int256 _rate, uint256 _date) {
        RateData memory rateData = rateIndexToRateData[_currencyPair];
        return (rateData.rate, rateData.timestamp);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
    0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
    unchecked {
        return _currentIndex - _burnCounter - _startTokenId();
    }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
    unchecked {
        return _currentIndex - _startTokenId();
    }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
        interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
        interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
        interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

    unchecked {
        if (_startTokenId() <= curr)
            if (curr < _currentIndex) {
                uint256 packed = _packedOwnerships[curr];
                // If not burned.
                if (packed & _BITMASK_BURNED == 0) {
                    // Invariant:
                    // There will always be an initialized ownership slot
                    // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                    // before an unintialized ownership slot
                    // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                    // Hence, `curr` will not underflow.
                    //
                    // We can directly compare the packed value.
                    // If the address is zero, packed will be zero.
                    while (packed == 0) {
                        packed = _packedOwnerships[--curr];
                    }
                    return packed;
                }
            }
    }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
        // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
        // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
        // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    function revoke(address to, uint256 tokenId) public payable virtual {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = address(0);
        emit RevokeApproval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
        _startTokenId() <= tokenId &&
        tokenId < _currentIndex && // If within bounds,
        _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
        // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
        // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
        // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
    private
    view
    returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================
    /**
       * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function _internalTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from)
            revert TransferFromIncorrectOwner();

        (
        uint256 approvedAddressSlot,
        address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (
            !_isSenderApprovedOrOwner(
            approvedAddress,
            from,
            _msgSenderERC721A()
        )
        )
            if (!isApprovedForAll(from, _msgSenderERC721A()))
                revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
            // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
        // We can directly increment and decrement the balances.
        --_packedAddressData[from]; // Updates: `balance -= 1`.
        ++_packedAddressData[to]; // Updates: `balance += 1`.

        // Updates:
        // - `address` to the next owner.
        // - `startTimestamp` to the timestamp of transfering.
        // - `burned` to `false`.
        // - `nextInitialized` to `true`.
        _packedOwnerships[tokenId] = _packOwnershipData(
            to,
            _BITMASK_NEXT_INITIALIZED |
            _nextExtraData(from, to, prevOwnershipPacked)
        );

        // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
        if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
            uint256 nextTokenId = tokenId + 1;
            // If the next slot's address is zero and not burned (i.e. packed value is zero).
            if (_packedOwnerships[nextTokenId] == 0) {
                // If the next slot is within bounds.
                if (nextTokenId != _currentIndex) {
                    // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                    _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                }
            }
        }
    }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
            // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
        // We can directly increment and decrement the balances.
        --_packedAddressData[from]; // Updates: `balance -= 1`.
        ++_packedAddressData[to]; // Updates: `balance += 1`.

        // Updates:
        // - `address` to the next owner.
        // - `startTimestamp` to the timestamp of transfering.
        // - `burned` to `false`.
        // - `nextInitialized` to `true`.
        _packedOwnerships[tokenId] = _packOwnershipData(
            to,
            _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
        );

        // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
        if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
            uint256 nextTokenId = tokenId + 1;
            // If the next slot's address is zero and not burned (i.e. packed value is zero).
            if (_packedOwnerships[nextTokenId] == 0) {
                // If the next slot is within bounds.
                if (nextTokenId != _currentIndex) {
                    // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                    _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                }
            }
        }
    }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
    unchecked {
        // Updates:
        // - `balance += quantity`.
        // - `numberMinted += quantity`.
        //
        // We can directly add to the `balance` and `numberMinted`.
        _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

        // Updates:
        // - `address` to the owner.
        // - `startTimestamp` to the timestamp of minting.
        // - `burned` to `false`.
        // - `nextInitialized` to `quantity == 1`.
        _packedOwnerships[startTokenId] = _packOwnershipData(
            to,
            _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
        );

        uint256 toMasked;
        uint256 end = startTokenId + quantity;

        // Use assembly to loop and emit the `Transfer` event for gas savings.
        // The duplicated `log4` removes an extra check and reduces stack juggling.
        // The assembly, together with the surrounding Solidity code, have been
        // delicately arranged to nudge the compiler into producing optimized opcodes.
        assembly {
        // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
            toMasked := and(to, _BITMASK_ADDRESS)
        // Emit the `Transfer` event.
            log4(
            0, // Start of data (0, since no data).
            0, // End of data (0, since no data).
            _TRANSFER_EVENT_SIGNATURE, // Signature.
            0, // `address(0)`.
            toMasked, // `to`.
            startTokenId // `tokenId`.
            )

        // The `iszero(eq(,))` check ensures that large values of `quantity`
        // that overflows uint256 will make the loop run out of gas.
        // The compiler will optimize the `iszero` away for performance.
            for {
                let tokenId := add(startTokenId, 1)
            } iszero(eq(tokenId, end)) {
                tokenId := add(tokenId, 1)
            } {
            // Emit the `Transfer` event. Similar to above.
                log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
            }
        }
        if (toMasked == 0) revert MintToZeroAddress();

        _currentIndex = end;
    }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
    unchecked {
        // Updates:
        // - `balance += quantity`.
        // - `numberMinted += quantity`.
        //
        // We can directly add to the `balance` and `numberMinted`.
        _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

        // Updates:
        // - `address` to the owner.
        // - `startTimestamp` to the timestamp of minting.
        // - `burned` to `false`.
        // - `nextInitialized` to `quantity == 1`.
        _packedOwnerships[startTokenId] = _packOwnershipData(
            to,
            _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
        );

        emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

        _currentIndex = startTokenId + quantity;
    }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

    unchecked {
        if (to.code.length != 0) {
            uint256 end = _currentIndex;
            uint256 index = end - quantity;
            do {
                if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } while (index < end);
            // Reentrancy protection.
            if (_currentIndex != end) revert();
        }
    }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
            // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
    unchecked {
        // Updates:
        // - `balance -= 1`.
        // - `numberBurned += 1`.
        //
        // We can directly decrement the balance, and increment the number burned.
        // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
        _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

        // Updates:
        // - `address` to the last owner.
        // - `startTimestamp` to the timestamp of burning.
        // - `burned` to `true`.
        // - `nextInitialized` to `true`.
        _packedOwnerships[tokenId] = _packOwnershipData(
            from,
            (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
        );

        // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
        if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
            uint256 nextTokenId = tokenId + 1;
            // If the next slot's address is zero and not burned (i.e. packed value is zero).
            if (_packedOwnerships[nextTokenId] == 0) {
                // If the next slot is within bounds.
                if (nextTokenId != _currentIndex) {
                    // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                    _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                }
            }
        }
    }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
    unchecked {
        _burnCounter++;
    }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
        // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
        // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
        // We will need 1 word for the trailing zeros padding, 1 word for the length,
        // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
        // Update the free memory pointer to allocate.
            mstore(0x40, m)
        // Assign the `str` to the end.
            str := sub(m, 0x20)
        // Zeroize the slot after the string.
            mstore(str, 0)

        // Cache the end of the memory to calculate the length later.
            let end := str

        // We write the string from rightmost digit to leftmost digit.
        // The following is essentially a do-while loop that also handles the zero case.
        // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
            // Write the character to the pointer.
            // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
            // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
        // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
        // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: Apache-2.0

/******************************************************************************
 * Copyright 2022 IEXEC BLOCKCHAIN TECH                                       *
 *                                                                            *
 * Licensed under the Apache License, Version 2.0 (the "License");            *
 * you may not use this file except in compliance with the License.           *
 * You may obtain a copy of the License at                                    *
 *                                                                            *
 *     http://www.apache.org/licenses/LICENSE-2.0                             *
 *                                                                            *
 * Unless required by applicable law or agreed to in writing, software        *
 * distributed under the License is distributed on an "AS IS" BASIS,          *
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
 * See the License for the specific language governing permissions and        *
 * limitations under the License.                                             *
 ******************************************************************************/

pragma solidity >=0.6.12;
/**
 * @dev Any contract which implements this GenericOracle contract should add its
 * own protection logic reponsible of securing the `_updateValue(..)` method.
 */
abstract contract Oracle {
    function getRaw(bytes32)public view virtual returns (bytes memory, uint256);
    function getString(bytes32)public view virtual returns (string memory, uint256);
    function getInt(bytes32) public view virtual returns (int256, uint256);
    function getBool(bytes32) public view virtual returns (bool, uint256);
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` revokes `approved` ability to manage the `tokenId` token.
     */
    event RevokeApproval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}