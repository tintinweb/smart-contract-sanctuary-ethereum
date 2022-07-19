// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Escrow.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

// 1.We must delete the loan/order details which has been liquidated so that doing so will
// delete the loan/order from storage in order to achieve a substantial gas
// savings and to lessen the burden of storage on Ethereum nodes, since
// we will never access this loan's details again, and the details are
// still available through event data.

//2. Add an escrow service to store funds  ie ethers
//3. Add a way to implment escrow to ERC721
//4. Ways to handle and check various contract and its managment for security and gas effeciency..
//5. Gotcha related to struct and mapping N storage and memoring with mappings..
//6. Security checks using myhtril and other audit service's
//7. Re-test around the other various kind of pevious attack's.
//8. errors are much cheaper and allow you to encode additional data. NatSpec to describe the error to user.
//9. Mapping inside struct VS mapping gloaal
//10. Mapping private specifier and gotha-pitfall
//11. should revert the transactions that wil allow the direct trabsfer of the ether over the smart contract via use of the receeiver ///ether / delegate call with selfdestruct to d the ethers.
//12. Re-entrancy attack's.. in fallback via check-effect pattern..
//13. Always provide ways to withdraw NFT /funds back to the smart contact ..
//14. Decimal precision error (in division) and fix in solidity with checks
//15. Use immutable and constant..in variables and define visibilty for functions and variables.
//https://medium.com/@soliditydeveloper.com/solidity-design-patterns-multiply-before-dividing-407980646f7
//https://github.com/stakewise/contracts/issues/54
// a/b case 1 : a = 0.0000000000000000000000000000000000000000001 , case2  b = 2^256-1 ; case 3 : a==b case4 a <b , case 5 a > b
//https://github.com/stakewise/contracts/issues/45
// There should not be any case where the  total amount of paid to lender is higher then the total EMI paid..

// we must hchecing that mappin glaways are associated with an Id while creation..
// Make sure that the amoutInput for emi calculation is in wei so that the precision loss can be minimized..
//https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/external-calls/

//16. Attack via help of the safeTransferFrom via use of callback to check if receiver contract address implmented the IERC721REceiveer Interface..
//17 Make contracts upgradable.
//18. Handle the hardhat failure and restart mechanism during the middle of multiple contract deployments
//19. We must have a check to ensure that we never transfer the amount reeived from the borrower in-case of EMI will always be
//higher or at-least equal to amout paid to borrower .
//20 USe SafeMatch for multiply , divide , add , sub etc..
//21 Implemnt https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/escrow/Escrow.sol..
// Automated testing  Smart contract :// Slither// Theo// Mythril// Solhint Linter
//22 Reading from storage is more expensive than reading from memory

contract RACE is ReentrancyGuard, ERC721Holder {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    // using Address for address payable;
    uint256 public _timestamp = block.timestamp;
    address public immutable SIGNER_ADDRESS;
    address public immutable ESCROW;
    // Max number of EMI that can be bounced
    uint256 public MAX_EMI_BOUNCE_COUNT;
    // Time (seconds) duration within transaction confirmation ie 24/48 hours
    uint256 public immutable EMI_PAYMENT_CONFIRMATION_PERIOD;

    // Max number of installment
    uint256 public MAX_INSTALLMENT_COUNT = 12;
    //CRYPTOPUNKS contract address
    address public CRYPTOPUNKS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
    //Multisig admin wallet address
    address public MULTISIG_ADDRESS;
    //Equivalent to bid
    struct Offer {
        // User(lender) who has placed the offer.
        address userOffered;
        uint256 orderId;
        uint256 principalOffered;
        // Total value/amount that is to be paid along with the interest
        uint256 totalInterestAmountOffered;
        uint256 repayamentTimeStampOffered;
        // Total no of EMI/installment's to be paid
        uint32 numberOfInstallmentOffered;
        // Status of that offer
        OfferStatus status;
    }
    struct Emi {
        uint256 orderId;
        // Total No of EMI paid for order
        uint32 totalNumberOfPaidEmi;
        // Amout to be paid for a single installment of EMI
        uint256 emiAmount;
    }
    // Equivalent to loan proposal
    struct Order {
        // Order against NFT token or contract address.
        address nftAddress;
        // Token ID of NFT
        uint256 tokenId;
        // Lender address for order whose offer is accepted..
        address lender;
        // Address of the borrower create the loan proposal
        address borrower;
        // Exact time at which the loan starts, which is after the borrower accepts a proposal
        uint256 loanStartDate;
        // Timestamp(in Unix ie 23 Oct 2302 MM::HH::SS) for which the loan has been granted and is expected to be paid back
        uint256 repaymentTimeStamp;
        // Loan expiration time or time after which no bids can be placed and no bid can be accepted
        uint256 orderExpirationTime;
        // Total no of EMI/installment's to be paid
        uint32 numberOfInstallment;
        // Total amout borrowed by the borrower from lender in wei
        uint256 principal;
        // Total value/amount with interest that has to be paid to the borrower in wei
        uint256 totalInterestAmount;
        // Current loan status
        LoanState loanState;
        // 0 : inital(defualt value) 1 : order Accepted by DIC, 2 :  rejected
        uint8 isAcceptedOrderDic;
        // Id for Offer/bid which is accpted for order by borrower
        uint8 acceptedOfferId;
        // offer-Id managment for the order
        Counters.Counter offerId;
        // mapping for OfferId ==> OfferDetails
        mapping(uint256 => Offer) offers;
    }

    enum LoanState {
        // The loan is proposed, but not initiated yet.
        Proposed,
        // Atleast one bid is offered by a lender on this order
        BidOffered,
        // An offer is accepted by the order borrower for a particular offer.
        Accepted,
        // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
        Active,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the lender. This is a terminal state.
        Defaulted,
        // The loan has been withdrawn/canceled by the user ie creator/borrower
        Withdrawn
    }
    enum OfferStatus {
        // State when offer does not exist
        NoExist,
        // When the lender has placed the offer/ proposed an offer
        Proposed,
        // When the borrower accepts the placed offer
        Accepted,
        // When Offer is withdrawn by lender
        Withdrawn,
        // When amount refunded/claimed back by lender in-case of bid not acceped
        Refunded,
        // When loan is successfully repaid by the borrower
        Completed
    }

    event OrderCreated(
        uint256 orderId,
        address borrower,
        address nftAddress,
        uint256 tokenId,
        uint256 principal,
        uint256 interest,
        uint256 numberOfInstallment,
        uint256 orderExpirationTime,
        uint256 repayUnixTimeStamp
    );
    event OfferPlaced(
        uint256 orderId,
        uint256 offerId,
        address userOffered,
        uint256 principal,
        uint256 totalInterestAmount,
        uint256 loanFinalRepaytime,
        uint32 numberOfInstallment
    );
    event OfferWithdrawn(uint256 orderId, uint256 offerId, address userWithdrawn, address nftAddress, uint256 tokenId);
    event OrderWithdrawn(uint256 orderId, address userWithdrawn, address nftAddress, uint256 tokenId);
    event OfferClaimBack(uint256 orderId, uint256 offerId, uint256 amountClaimed, address userClaimBack);
    event LoanStarted(uint256 orderId, uint256 offerId);
    event EmiPaid(
        uint256 orderId,
        address payee,
        uint256 totalAmount,
        bool singlePayment,
        uint256 totalNumberOfPaidEmi,
        LoanState loanState
    );
    event ClaimedDefaultedNft(uint256 orderId, address userClaimed, address nftAddress, uint256 tokenId);
    event ClaimedRepaidNft(uint256 _orderId, address userClaimed, address nftAddress, uint256 tokenId);

    // Counter for orderID
    Counters.Counter private orderId;

    // orderId ==> OrderDetails
    mapping(uint256 => Order) private orders;
    // orderId ==> EMI Info
    mapping(uint256 => Emi) private emiInfo;

    constructor(
        address _signerAddress,
        address _multiSigAdminwallet,
        uint256 _emiBounceCount,
        uint256 _emiConfirmationTime
    ) {
        require(_signerAddress != address(0), "SIGNER-ADDRESS_MUST_BE__NONZERO");
        require(_multiSigAdminwallet != address(0), "MULTISIG-ADDRESS_MUST_BE__NONZERO");

        Escrow escrowContract = new Escrow(_multiSigAdminwallet, address(this));

        // intitalizing the state variables
        ESCROW = address(escrowContract);
        SIGNER_ADDRESS = _signerAddress;
        MAX_EMI_BOUNCE_COUNT = _emiBounceCount;
        EMI_PAYMENT_CONFIRMATION_PERIOD = _emiConfirmationTime;
        MULTISIG_ADDRESS = _multiSigAdminwallet;
    }

    // Unknown transfer to the contract
    receive() external payable {
        require(false, "UNKNOWN_TRANSFER");
    }
    // Unknown transfer to the contract
    fallback() external payable {
        require(false, "UNKNOWN_TRANSFER");
    }
    // Method to return a bid's details on a loan proposal
    function getOffer(uint256 _orderId, uint256 _offerId)
        public
        view
        returns (
            address userAddress,
            uint256 principalOffered,
            uint256 totalInterestAmountOffered,
            uint256 repayamentTimeStampOffered,
            uint32 numberOfInstallmentOffered,
            string memory status
        )
    {
        require(isExistOrder(_orderId), "ORDER_NONEXIST");
        require(isExistOffer(_orderId, _offerId), "NONEXIST_OFFER");
        string memory _status;
        if (orders[_orderId].offers[_offerId].status == OfferStatus.NoExist) {
            _status = "Non-Existing";
        } else if (orders[_orderId].offers[_offerId].status == OfferStatus.Proposed) {
            _status = "Proposed";
        } else if (orders[_orderId].offers[_offerId].status == OfferStatus.Accepted) {
            _status = "Accepted";
        } else if (orders[_orderId].offers[_offerId].status == OfferStatus.Withdrawn) {
            _status = "Withdrawn";
        } else if (orders[_orderId].offers[_offerId].status == OfferStatus.Refunded) {
            _status = "Refunded";
        } else if (orders[_orderId].offers[_offerId].status == OfferStatus.Completed) {
            _status = "Completed";
        }

        return (
            orders[_orderId].offers[_offerId].userOffered,
            orders[_orderId].offers[_offerId].principalOffered,
            orders[_orderId].offers[_offerId].totalInterestAmountOffered,
            orders[_orderId].offers[_offerId].repayamentTimeStampOffered,
            orders[_orderId].offers[_offerId].numberOfInstallmentOffered,
            _status
        );
    }
    // Method to return loan proposal details which were proposed by the borrower
    function getOrder(uint256 _orderId)
        public
        view
        returns (
            address nftAddress,
            uint256 tokenId,
            address borrower,
            uint32 numberOfInstallment,
            uint8 acceptedOfferId,
            uint8 DICAcceptanceStatus,
            string memory status
        )
    {
        require(isExistOrder(_orderId), "NONEXISTING_ORDER");
        Order storage orderInfo = orders[_orderId];
        string memory _status;
        if (_timestamp > orderInfo.orderExpirationTime) {
            _status = "Expired";
        } else if (orderInfo.loanState == LoanState.Proposed) {
            _status = "Proposed";
        } else if (orderInfo.loanState == LoanState.BidOffered) {
            _status = "BidOffered";
        } else if (orderInfo.loanState == LoanState.Accepted) {
            _status = "Accepted";
        } else if (orderInfo.loanState == LoanState.Active) {
            _status = "Active";
        } else if (orderInfo.loanState == LoanState.Repaid) {
            _status = "Repaid";
        } else if (orderInfo.loanState == LoanState.Defaulted) {
            _status = "Defaulted";
        } else if (orderInfo.loanState == LoanState.Withdrawn) {
            _status = "Withdrawn";
        }
        return (
            orderInfo.nftAddress,
            orderInfo.tokenId,
            orderInfo.borrower,
            orderInfo.numberOfInstallment,
            orderInfo.acceptedOfferId,
            orderInfo.isAcceptedOrderDic,
            _status
        );
    }
    // Method to return EMI details on a loan proposal
    function getEMIDetailsforOrder(uint256 _orderId)
        public
        view
        returns (
            uint256 emiInstallment,
            uint256 repaymentTimeStamp,
            uint256 principal,
            uint256 totalInterestAmount,
            uint256 totalNumberOfPaidEmi,
            uint256 emiAmount
        )
    {
        require(isExistOrder(_orderId), "NONEXISTING_ORDER");
        uint256 acceptOfferId = orders[_orderId].acceptedOfferId;
        Emi memory emiDetail = emiInfo[_orderId];
        require(emiDetail.orderId != 0, "NONEXISTING_EMIDATA");
        require(acceptOfferId != 0, "NO_OFFER_ACCEPTED");

        return (
            orders[_orderId].offers[acceptOfferId].numberOfInstallmentOffered,
            orders[_orderId].offers[acceptOfferId].repayamentTimeStampOffered,
            orders[_orderId].offers[acceptOfferId].principalOffered,
            orders[_orderId].offers[acceptOfferId].totalInterestAmountOffered,
            emiDetail.totalNumberOfPaidEmi,
            emiDetail.emiAmount
        );
    }

    // Hashing message for verifying singature for order
    function hashMessage(
        uint256 chainId,
        uint256 _maxApprovalAmount,
        uint256 tokenId,
        address _nftaddress
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(chainId, _maxApprovalAmount, tokenId, _nftaddress))
                )
            );
    }

    // recovering signer address from the signature
    function matchAddressSigner(bytes32 hash, bytes memory signature) public view returns (bool) {
        return SIGNER_ADDRESS == hash.recover(signature);
    }

    // Setter for setting new cryptopunks contract address
    function updateCryptopunksAddress(address _cryptopunks) external {
        require(msg.sender == MULTISIG_ADDRESS, "only owner allowed");
        CRYPTOPUNKS = _cryptopunks;
        // Updating on escrow
        Escrow(ESCROW).updateCryptopunksAddress(_cryptopunks);
    }

    // Setter for setting new MultiSig address
    function updateMultiSigAddress(address _newMultiSigAddress) external {
        require(msg.sender == MULTISIG_ADDRESS, "only owner allowed");
        MULTISIG_ADDRESS = _newMultiSigAddress;
        // Updating on escrow
        Escrow(ESCROW).updateMultiSigAddress(_newMultiSigAddress);
    }

    // Setter for setting new MultiSig address
    function updateEMIBounceCount(uint256 _newEMIBounceCount) external {
        require(msg.sender == MULTISIG_ADDRESS, "only owner allowed");
        MAX_EMI_BOUNCE_COUNT = _newEMIBounceCount;
    }

    /**
    An approval must be provided to contract for NFT before executing this function.
    An order is the process where borrower lock his/her NFT and create a proposal with the details.
    An order can have multiple offer's. But only single offer can be accepted for it.
    **/
    function createOrder(
        uint256 _tokenId,
        uint256 _principalAmount,
        uint256 _totalAmountWithInterest,
        uint32 _numberOfInstallment,
        uint256 _orderExpirationTime,
        uint256 _maxApprovalAmount,
        //@TODO can be simplified..
        address _nftToken,
        bytes memory _signature
    ) external {
        require(_principalAmount > 0, "PRINCIPAL_MUST_BE__NONZERO");
        require(_totalAmountWithInterest > 0, "INTEREST-PAID_MUST_BE__NONZERO");
        require(_nftToken != address(0), "NFT-ADDRESS_MUST_BE__NONZERO");
        require(_orderExpirationTime > _timestamp, "INVALID_LOAN_EXPIRY_TIME");
        require(_numberOfInstallment > 0, "NUMBER_OF_INSTALLMENTS_MUST_BE_NONZERO");
        require(_numberOfInstallment <= MAX_INSTALLMENT_COUNT, "INVALID_INSTALLMENT_COUNT");

        // if the signature gets verified with the data signed by the DIC wallet private key
        // then only we will update the VerifyOrder and mark it as Accepted but only
        // for phase1 .. (as similar in bluprint)
        bytes32 hash = hashMessage(block.chainid, _maxApprovalAmount, _tokenId, _nftToken);
        require(matchAddressSigner(hash, _signature), "INVALID_SIGN_DATA");
        require(_principalAmount <= _maxApprovalAmount, "PRINCIPAL_EXCEEDS_MAX_APPROVAL");

        //@TODO Does it actually return the previous counter or else does it updates and retrun the incremented Id..
        orderId.increment();
        uint256 currentOrderId = orderId.current();

        // Receive Collateral NFT Tokens
        if (_nftToken == CRYPTOPUNKS) {
            // IPunks(_nftToken).buyPunk(_tokenId); // to be refactored
            CRYPTOPUNKS.call(abi.encodeWithSignature("buyPunk(uint256)", _tokenId));
        } else {
            IERC721(_nftToken).safeTransferFrom(msg.sender, address(this), _tokenId);
        }

        // Save order-info
        Order storage newOrder = orders[currentOrderId];
        newOrder.nftAddress = _nftToken;
        newOrder.tokenId = _tokenId;
        newOrder.borrower = msg.sender;
        newOrder.repaymentTimeStamp = 0; // can be removed
        newOrder.numberOfInstallment = _numberOfInstallment;
        newOrder.principal = _principalAmount;
        newOrder.orderExpirationTime = _orderExpirationTime;
        newOrder.totalInterestAmount = _totalAmountWithInterest;
        newOrder.loanState = LoanState.Proposed;
        newOrder.isAcceptedOrderDic = 1;

        emit OrderCreated(
            currentOrderId,
            msg.sender,
            _nftToken,
            _tokenId,
            _principalAmount,
            _totalAmountWithInterest,
            _numberOfInstallment,
            _orderExpirationTime,
            0
        );
    }

    // Method to place bid on a particular order/ Loan proposal
    function placeOffer(
        uint256 _principal,
        uint256 _orderId,
        uint256 _totalAmountWithInterest,
        uint32 _numberOfInstallment
    ) external payable nonReentrant {
        require(msg.value > 0, "AMOUNT_MUST_NOT_EQUAL_ZERO");
        require(msg.value == _principal, "INVALID_AMOUNT_SENT");
        require(isExistOrder(_orderId), "NONEXISTING_ORDER");
        require(_numberOfInstallment > 0, "INSTALLMENT_MUST_BE_NON-ZERO");
        require(orders[_orderId].orderExpirationTime > _timestamp, "ORDER_EXPIRED");
        require(_numberOfInstallment <= MAX_INSTALLMENT_COUNT, "INVALID_INSTALLMENT_COUNT");
        require(_totalAmountWithInterest > 0, "INTEREST_MUST_BE_NON-ZERO");
        require(_principal < _totalAmountWithInterest, "INVALID_INTEREST_AMOUNT");
        require(orders[_orderId].borrower != msg.sender, "OWNER_NOT_ALLOWED");
        // require(orders[_orderId].isAcceptedOrderDic == 1, "NON-APPROVED_OFFER");
        require(
            orders[_orderId].loanState == LoanState.BidOffered || orders[_orderId].loanState == LoanState.Proposed,
            "INVALID_LOAN_STATE"
        );
        require(_totalAmountWithInterest >= _numberOfInstallment, "INVALID_NUMBER_OF_INSTALLMENTS");

        // lock ether's into an external escrow contract by transferring from address(this) to escrow contract.
        // address payable ethEscrow = payable(escrow);
        // ethEscrow.sendValue(msg.value);
        (bool success, ) = ESCROW.call{ value: msg.value }(
            abi.encodeWithSignature("deposit(address,uint256,address)", address(0), msg.value, msg.sender)
        );
        require(success, "ESCROW_DEPOST_FAILED");

        Order storage orderDetails = orders[_orderId];
        orderDetails.loanState = LoanState.BidOffered;

        Offer memory offer = Offer(
            msg.sender,
            _orderId,
            msg.value,
            _totalAmountWithInterest,
            0, // repayment timestamp is set 0 intitially
            _numberOfInstallment,
            OfferStatus.Proposed
        );
        orders[_orderId].offerId.increment();
        uint256 currentOfferId = orders[_orderId].offerId.current();
        orders[_orderId].offers[currentOfferId] = offer;

        emit OfferPlaced(
            _orderId,
            currentOfferId,
            msg.sender,
            msg.value,
            _totalAmountWithInterest,
            0,
            _numberOfInstallment
        );
    }

    // Method for accepting offer where loan starts
    function acceptOffer(
        uint256 _orderId,
        uint8 _offerId,
        uint256 _emiAmount
    ) external nonReentrant {
        require(isExistOrder(_orderId), "NONEXISTING_ORDER");
        require(isExistOffer(_orderId, _offerId), "NONEXISTING_OFFER");
        require(orders[_orderId].borrower == msg.sender, "ONLY_OWNER_ALLOWED");
        require(_emiAmount > 0, "INVALID_EMI_AMOUNT");
        require(orders[_orderId].orderExpirationTime > _timestamp, "LOAN_EXPIRED");
        require(orders[_orderId].loanState == LoanState.BidOffered, "INVALID_LOAN_STATE");
        require(orders[_orderId].offers[_offerId].status == OfferStatus.Proposed, "NON_INITAL_OFFER_STATE");

        // Checks for cryptopunks non-standard tokens
        if (orders[_orderId].nftAddress == CRYPTOPUNKS) {

            (, bytes memory result) = CRYPTOPUNKS.call(
                abi.encodeWithSignature("punkIndexToAddress(uint256)", orders[_orderId].tokenId)
                );
            (address approval) = abi.decode(result, (address));
            // Checks for NFT ownership
            require(
                approval == address(this),
                "NFT_OWNERSHIP_NOT_AVAILABLE"
            );
        } else {
            // Checks for NFT ownership
            require(
                IERC721(orders[_orderId].nftAddress).ownerOf(orders[_orderId].tokenId) == address(this),
                "NFT_OWNERSHIP_NOT_AVAILABLE"
            );
        }
        // Escrow balance must be grater than the amount to be transferred
        uint256 payment = orders[_orderId].offers[_offerId].principalOffered;
        require(address(ESCROW).balance >= payment, "IN-SUFFICIENT_ETH_BALANCE");

        // Updating/Storing the loan details
        Order storage orderDetails = orders[_orderId];
        orderDetails.loanState = LoanState.Accepted;
        orderDetails.acceptedOfferId = _offerId;
        orderDetails.lender = orders[_orderId].offers[_offerId].userOffered;
        orderDetails.loanStartDate = _timestamp;

        // calculations for due date on the basis of the loan avail date
        uint256 dueDate;
        if (BokkyPooBahsDateTimeLibrary.getDay(_timestamp) < 15) {
            uint256 tempDueDate = BokkyPooBahsDateTimeLibrary.addMonths(
                _timestamp,
                orderDetails.offers[_offerId].numberOfInstallmentOffered
            );
            (uint256 _year, uint256 _month, ) = BokkyPooBahsDateTimeLibrary.timestampToDate(tempDueDate);
            dueDate = BokkyPooBahsDateTimeLibrary.timestampFromDate(_year, _month, 5);
        } else {
            uint256 tempDueDate = BokkyPooBahsDateTimeLibrary.addMonths(
                _timestamp,
                orderDetails.offers[_offerId].numberOfInstallmentOffered + 1
            );
            (uint256 _year, uint256 _month, ) = BokkyPooBahsDateTimeLibrary.timestampToDate(tempDueDate);
            dueDate = BokkyPooBahsDateTimeLibrary.timestampFromDate(_year, _month, 5);
        }

        orderDetails.repaymentTimeStamp = dueDate;
        orderDetails.offers[_offerId].repayamentTimeStampOffered = dueDate;

        //@TODO deduct the fee here ..
        Escrow(ESCROW).withdrawal(address(0), payment, orderDetails.borrower);
        if (orderDetails.nftAddress == CRYPTOPUNKS) {
            //Transfer punk to escrow
            CRYPTOPUNKS.call(abi.encodeWithSignature("transferPunk(address,uint256)", ESCROW, orderDetails.tokenId));
        } else {
            //Approve & Transfer the ERC721 token to an excrow contract.
            IERC721(orderDetails.nftAddress).approve(ESCROW, orderDetails.tokenId);
            IERC721(orderDetails.nftAddress).safeTransferFrom(address(this), ESCROW, orderDetails.tokenId);
        }

        orderDetails.loanState = LoanState.Active;
        orders[_orderId].offers[_offerId].status = OfferStatus.Accepted;

        // calculations from offer end
        uint256 totalPayableAmount = orderDetails.offers[_offerId].totalInterestAmountOffered;
        uint256 installmentCount = orderDetails.offers[_offerId].numberOfInstallmentOffered;

        // handle  99/100 (removed as aready cheecked and rejected) and 1/0 (never occur ) and 7/3 ... and 10/3
        // below code is used as ceiling emiAmount
        // Ref : https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol

        /* This check must be full-filled in order to check that borrower loan amount must not exceed
        the sum of all emi paid. */
        require((_emiAmount * installmentCount) == totalPayableAmount, "EMI_AMOUNT_ERROR");

        emiInfo[_orderId].orderId = _orderId;
        emiInfo[_orderId].emiAmount = _emiAmount;

        emit LoanStarted(_orderId, _offerId);
    }

    // Method for a lender to withdraw an offer which is not accepted by the borrower
    function withdrawOffer(uint256 _orderId, uint256 _offerId) public nonReentrant {
        require(isExistOffer(_orderId, _offerId), "NONEXISTING_OFFER");
        require(orders[_orderId].offers[_offerId].status == OfferStatus.Proposed, "NON_INITAL_OFFER_STATE");
        require(orders[_orderId].loanState != LoanState.Proposed, "INVALID_LOAN_STATE");
        require(
            orders[_orderId].offers[_offerId].userOffered == msg.sender,
            "ONLY_OFFER_LENDER_ALLLOWED, UNAUTHORIZED_USER"
        );

        orders[_orderId].offers[_offerId].status = OfferStatus.Withdrawn;

        // Send ether's back into lender's account
        // Address payable lender = payable(orders[_orderId].offers[_offerId].userOffered);
        // Lender.sendValue(orders[_orderId].offers[_offerId].principalOffered);
        Escrow(ESCROW).withdrawal(
            address(0),
            orders[_orderId].offers[_offerId].principalOffered,
            orders[_orderId].offers[_offerId].userOffered
        );

        emit OfferWithdrawn(_orderId, _offerId, msg.sender, orders[_orderId].nftAddress, orders[_orderId].tokenId);
    }

    // function for a borrower to withdraw an order/loan-proposal which is not active yet
    function withdrawOrder(uint256 _orderId) public {
        require(isExistOrder(_orderId), "NONEXISTING_ORDER");
        require(orders[_orderId].borrower == msg.sender, "UNAUTHORIZED_USER");
        require(
            orders[_orderId].loanState == LoanState.BidOffered || orders[_orderId].loanState == LoanState.Proposed,
            "INVALID_LOAN_STATE"
        );
        require(orders[_orderId].acceptedOfferId == 0, "OFFER_ACCEPTED_ALREADY");

        Order storage orderDetails = orders[_orderId];
        orderDetails.loanState = LoanState.Withdrawn;

        // Refund the collateral/ NFT tokens back to the borrower's address
        if (orders[_orderId].nftAddress == CRYPTOPUNKS) {
            CRYPTOPUNKS.call(
                abi.encodeWithSignature("transferPunk(address,uint256)", orders[_orderId].borrower, orders[_orderId].tokenId)
                );
        } else {
            IERC721(orders[_orderId].nftAddress).safeTransferFrom(
                address(this),
                orders[_orderId].borrower,
                orders[_orderId].tokenId
            );
        }
        emit OrderWithdrawn(_orderId, msg.sender, orders[_orderId].nftAddress, orders[_orderId].tokenId);
    }

    // Internal methd
    function defaultCheck(uint256 _orderId) internal view {
        uint256 loanStartDate = orders[_orderId].loanStartDate;
        uint256 tempDueDate;
        (uint256 _year, uint256 _month, uint256 loanAvailDay) = BokkyPooBahsDateTimeLibrary.timestampToDate(
            loanStartDate
        );
        if (loanAvailDay <= 15) {
            tempDueDate = BokkyPooBahsDateTimeLibrary.timestampFromDate(
                _year,
                _month + emiInfo[_orderId].totalNumberOfPaidEmi + MAX_EMI_BOUNCE_COUNT,
                6
            );
        } else {
            tempDueDate = BokkyPooBahsDateTimeLibrary.timestampFromDate(
                _year,
                _month + emiInfo[_orderId].totalNumberOfPaidEmi + MAX_EMI_BOUNCE_COUNT + 1,
                6
            );
        }

        require(tempDueDate > _timestamp, "LOAN_DEFAULTED");
    }

    // Method for borrower to payEMI (Monthly payments or full and final)
    function payEMI(
        uint256 _orderId,
        bool _oneTimePayment,
        uint256 _foreClosingAmount,
        bytes memory _signature
    ) external payable nonReentrant {
        require(isExistOrder(_orderId), "NONEXISTING_ORDER");
        require(orders[_orderId].borrower == msg.sender, "UNAUTHORIZED_USER");
        require(orders[_orderId].loanState == LoanState.Active, "NON_ACTIVE_LOAN");
        require(emiInfo[_orderId].orderId == _orderId, "INVALID_ORDERID");
        uint256 acceptOfferId = orders[_orderId].acceptedOfferId;
        // Check for loan deadline
        require(
            orders[_orderId].offers[acceptOfferId].repayamentTimeStampOffered + EMI_PAYMENT_CONFIRMATION_PERIOD >=
                _timestamp,
            "TIME_PERIOD_EXCEED"
        );

        // checks for defaulted case
        defaultCheck(_orderId);

        if (_oneTimePayment) {
            require(_foreClosingAmount > 0, "BALANCE_MUST_BE_NONZERO");
            require(emiInfo[_orderId].totalNumberOfPaidEmi >= 1, "MIN_INSTALLMENTS_NOT_REACHED");

            // Signature creation from orderId and foreclosing amount
            bytes32 hash = keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(_orderId, _foreClosingAmount))
                )
            );
            // Verifying the signer of the signature
            require(matchAddressSigner(hash, _signature), "INVALID_SIGN_DATA");

            require(msg.value == _foreClosingAmount, "INVALID_FORECLOSURE_AMOUNT");
            require(
                _foreClosingAmount <
                    orders[_orderId].offers[orders[_orderId].acceptedOfferId].totalInterestAmountOffered,
                "FORECLOSING_AMOUNT_ERROR"
            );
            // Direct transfer to the lenders account from escrow
            (bool success, ) = orders[_orderId].lender.call{ value: msg.value }("");
            require(success, "AMOUNT_TRANSFER_TO_LENDER_FAILED");

            orders[_orderId].loanState = LoanState.Repaid;
            orders[_orderId].offers[orders[_orderId].acceptedOfferId].status = OfferStatus.Completed;
        } else {
            require(emiInfo[_orderId].emiAmount == msg.value, "INVALID_EMI_INSTALLMENT_AMOUNT");
            // Checks for the last installment
            if (
                (emiInfo[_orderId].totalNumberOfPaidEmi + 1) ==
                orders[_orderId].offers[acceptOfferId].numberOfInstallmentOffered
            ) {
                orders[_orderId].loanState = LoanState.Repaid;
                orders[_orderId].offers[orders[_orderId].acceptedOfferId].status = OfferStatus.Completed;
            }
            (bool success, ) = orders[_orderId].lender.call{ value: msg.value }("");
            require(success, "EMI_TRANSFER_TO_LENDER_FAILED");
            emiInfo[_orderId].totalNumberOfPaidEmi = emiInfo[_orderId].totalNumberOfPaidEmi + 1;
        }

        emit EmiPaid(
            _orderId,
            msg.sender,
            msg.value,
            _oneTimePayment,
            emiInfo[_orderId].totalNumberOfPaidEmi,
            orders[_orderId].loanState
        );
    }

    // lender can claim NFT when the order/loan has been defaulted...
    function claimDefaultedNFT(uint256 _orderId) external {
        require(isExistOrder(_orderId), "NONEXISTING_ORDER");
        uint256 acceptedOfferId = orders[_orderId].acceptedOfferId;
        require(orders[_orderId].offers[acceptedOfferId].userOffered == msg.sender, "UNAUTHORIZED_USER");
        require(orders[_orderId].offers[acceptedOfferId].status == OfferStatus.Accepted, "INVALID_LOAN_STATUS");

        uint256 loanStartDate = orders[_orderId].loanStartDate;

        // checks for deafulted case
        uint256 tempDueDate;
        (uint256 _year, uint256 _month, uint256 loanAvailDay) = BokkyPooBahsDateTimeLibrary.timestampToDate(
            loanStartDate
        );
        if (loanAvailDay <= 15) {
            tempDueDate = BokkyPooBahsDateTimeLibrary.timestampFromDate(
                _year,
                _month + emiInfo[_orderId].totalNumberOfPaidEmi + 3,
                6
            );
        } else {
            tempDueDate = BokkyPooBahsDateTimeLibrary.timestampFromDate(
                _year,
                _month + emiInfo[_orderId].totalNumberOfPaidEmi + 3 + 1,
                6
            );
        }

        require(
            orders[_orderId].offers[acceptedOfferId].repayamentTimeStampOffered + EMI_PAYMENT_CONFIRMATION_PERIOD <=
                _timestamp ||
                tempDueDate < _timestamp,
            "LOAN_NOT_DEFAULTED"
        );

        orders[_orderId].loanState = LoanState.Defaulted;
        orders[_orderId].offers[acceptedOfferId].status = OfferStatus.Refunded;

        Escrow(ESCROW).withdrawNFT(
            orders[_orderId].nftAddress,
            orders[_orderId].offers[acceptedOfferId].userOffered,
            orders[_orderId].tokenId
        );

        emit ClaimedDefaultedNft(
            _orderId,
            orders[_orderId].offers[acceptedOfferId].userOffered,
            orders[_orderId].nftAddress,
            orders[_orderId].tokenId
        );
    }

    // Borrower can withdraw NFT back once the complete loan has been paid
    // NFT ==> borrower
    function withdrawNFT(uint256 _orderId) external {
        require(isExistOrder(_orderId), "NONEXISTING_ORDER");
        uint256 acceptedOfferId = orders[_orderId].acceptedOfferId;
        require(orders[_orderId].borrower == msg.sender, "UNAUTHORIZED_USER");
        require(orders[_orderId].offers[acceptedOfferId].status == OfferStatus.Completed, "INVALID_OFFER_STATUS");
        require(orders[_orderId].loanState == LoanState.Repaid, "NON_REPAID_LOAN");

        Escrow(ESCROW).withdrawNFT(orders[_orderId].nftAddress, msg.sender, orders[_orderId].tokenId);

        emit ClaimedRepaidNft(_orderId, msg.sender, orders[_orderId].nftAddress, orders[_orderId].tokenId);
    }

    function isExistOrder(uint256 _orderId) internal view returns (bool) {
        return orders[_orderId].nftAddress != address(0);
    }

    function isExistOffer(uint256 _orderId, uint256 _offerId) internal view returns (bool) {
        return orders[_orderId].offers[_offerId].status != OfferStatus.NoExist;
    }

    function setTime (uint256 day, uint256 month, uint256 year) public {
        _timestamp = BokkyPooBahsDateTimeLibrary.timestampFromDate(year, month, day);
    }

    function getTime () public view returns(uint256, uint256, uint256){
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary.timestampToDate(_timestamp);
        return (year, month, day);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
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
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts v4.4.1 (utils/escrow/Escrow.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./Ipunks.sol";

//@TODO integrate ERC1155 tokens too..
//@todo add code for 'ERC721: transfer to non ERC721Receiver implementer'
contract Escrow is ReentrancyGuard, AccessControl, ERC721Holder {
    using SafeERC20 for IERC20;
    address internal constant ETH = address(0);
    address public MULTISIG_ADDRESS;
    address public immutable COLLATERAL_SC_ADDRESS;
    //CRYPTOPUNKS contract address
    address public CRYPTOPUNKS = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;

    event Deposited(address indexed tokenAddress, uint256 amount, address indexed payee);
    event Withdrawn(address indexed tokenAddress, uint256 amount, address indexed payee);
    event EmergencyWithdrawn(address indexed tokenAddress, uint256 amount, address indexed payee);

    bytes32 public constant EMERGENCY_WITHDRAW_ROLE = keccak256("EMERGENCY_WITHDRAW_ROLE");
    bytes32 public constant FUNDS_WITHDRAW_ROLE = keccak256("FUNDS_WITHDRAW_ROLE");

    constructor(address _multiSigWallet, address _collateralAddress) {
        MULTISIG_ADDRESS = _multiSigWallet;
        COLLATERAL_SC_ADDRESS = _collateralAddress;
        _setupRole(EMERGENCY_WITHDRAW_ROLE, _multiSigWallet);
        _setupRole(FUNDS_WITHDRAW_ROLE, _collateralAddress);
        //Ref : https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl
        //Roles can be granted and revoked dynamically via the grantRole and revokeRole functions. Each role has an associated admin role, and only accounts that have a role’s admin role can call grantRole and revokeRole.
        // By default, the admin role for all roles is DEFAULT_ADMIN_ROLE, which means that only accounts with this role will be able to grant or revoke other roles. More complex role relationships can be created by using _setRoleAdmin.
        _setRoleAdmin(EMERGENCY_WITHDRAW_ROLE, EMERGENCY_WITHDRAW_ROLE);
        _setRoleAdmin(FUNDS_WITHDRAW_ROLE, EMERGENCY_WITHDRAW_ROLE);
    }

    //https://github.com/aragon/aragon-apps/blob/master/apps/vault/contracts/Vault.sol

    /**
     * @notice Deposit `_value` `_token` to the vault
     * @param _token Address of the token being transferred
     * @param _value Amount of tokens being transferred
     */
    // TO check if deposit need any kind of modifier or else external will be sufficient
    function deposit(
        address _token,
        uint256 _value,
        address _payee
    ) external payable {
        _deposit(_token, _value, _payee);
    }

    function _deposit(
        address _token,
        uint256 _value,
        address _payee
    ) internal {
        require(_value > 0, "ERROR_DEPOSIT_VALUE_ZERO");

        if (_token == ETH) {
            // Deposit is implicit in this case
            require(msg.value == _value, "ERROR_VALUE_MISMATCH");
        } else {
            IERC20(_token).safeTransferFrom(msg.sender, address(this), _value);
        }
        emit Deposited(_token, _value, _payee);
    }

    function balance(address _token) public view returns (uint256) {
        if (_token == ETH) {
            return address(this).balance;
        } else {
            return IERC20(_token).balanceOf(address(this));
        }
    }

    /**
     * @notice Deposit `_value` `_token` to the vault
     * @param _token Address of the token being transferred
     * @param _value Amount of tokens being transferred
     */
    function withdrawal(
        address _token,
        uint256 _value,
        address recipient
    ) external nonReentrant onlyRole(FUNDS_WITHDRAW_ROLE) {
        _withdraw(_token, _value, recipient);
    }

    function _withdraw(
        address _token,
        uint256 _value,
        address recipient
    ) internal {
        require(_value > 0, "ERROR_DEPOSIT_VALUE_ZERO");

        if (_token == ETH) {
            // Deposit is implicit in this case
            require(address(this).balance >= _value, "Insufficient ETH balance");

            (bool success, ) = recipient.call{ value: _value }("");
            require(success, "Unable to transfer the value");
        } else {
            //What will happen if ERC20 token are tranfered to another contract address without
            // any approval.
            //Will there be any method to check or restrict it.
            bool success = IERC20(_token).approve(recipient, _value);
            require(success, "Unable to approve tokens");
            IERC20(_token).safeTransferFrom(address(this), recipient, _value);
        }
        emit Withdrawn(_token, _value, recipient);
    }

    function emergencyWithdrawal(address _token) external nonReentrant onlyRole(EMERGENCY_WITHDRAW_ROLE) {
        uint256 amount;
        if (_token == ETH) {
            amount = address(this).balance;
            _withdraw(_token, amount, MULTISIG_ADDRESS);
        } else {
            amount = IERC20(_token).balanceOf(address(this));
            _withdraw(_token, amount, MULTISIG_ADDRESS);
        }
        emit EmergencyWithdrawn(_token, amount, MULTISIG_ADDRESS);
    }

    function withdrawNFT(
        address _nftAddress,
        address _receiptent,
        uint256 _tokenId
    ) external onlyRole(FUNDS_WITHDRAW_ROLE) nonReentrant {
        if (_nftAddress == CRYPTOPUNKS) {
            require(IPunks(_nftAddress).punkIndexToAddress(_tokenId) == address(this), "NFT_OWNERSHIP_NOT_AVAILABLE");
            IPunks(_nftAddress).transferPunk(_receiptent, _tokenId);
        } else {
            require(IERC721(_nftAddress).ownerOf(_tokenId) == address(this), "NFT_OWNERSHIP_NOT_AVAILABLE");

            IERC721(_nftAddress).approve(_receiptent, _tokenId);
            IERC721(_nftAddress).safeTransferFrom(address(this), _receiptent, _tokenId);
        }
    }

    function updateCryptopunksAddress(address _cryptopunksAddress) external {
        require(msg.sender == COLLATERAL_SC_ADDRESS, "NOT_AUTHORISED");
        CRYPTOPUNKS = _cryptopunksAddress;
    }

    function updateMultiSigAddress(address _multiSigAddress) external {
        require(msg.sender == COLLATERAL_SC_ADDRESS, "NOT_AUTHORISED");
        _revokeRole(EMERGENCY_WITHDRAW_ROLE, MULTISIG_ADDRESS);
        MULTISIG_ADDRESS = _multiSigAddress;
        _grantRole(EMERGENCY_WITHDRAW_ROLE, _multiSigAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for a permittable ERC721 contract
 * See https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC721 allowance (see {IERC721-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC721-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IPunks {
    function punksOfferedForSale(uint256 punkIndex)
        external
        view
        returns (
            bool,
            uint256,
            address,
            uint256,
            address
        );

    function punkIndexToAddress(uint256 punkIndex) external view returns (address owner);

    function buyPunk(uint256 punkIndex) external payable;

    function transferPunk(address to, uint256 punkIndex) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}