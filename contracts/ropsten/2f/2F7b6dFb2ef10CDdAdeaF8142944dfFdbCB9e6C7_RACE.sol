// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

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
//11. shOULD revert the transactions that wil allow the direct trabsfer of the ether over the smart contract via use of the receeiver ///ether / delegate call with selfdestruct to sent the ethers.
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
contract RACE is ReentrancyGuard, ERC721Holder {
    using Counters for Counters.Counter;
    using ECDSA for bytes32;
    using Address for address payable;

    address public immutable signerAddress;
    address public immutable escrow;

    enum OfferStatus {
        // State when offer does not exist
        NoExist,
        // When the lender has placed the offer
        Initial,
        // When lender accepts the placed offer
        Accepted,
        // when Offer is withdrawn by lender
        Withdrawn
    }

    struct Offer {
        //User(lender) who has placed the offer.
        address userOffered;
        uint256 orderId;
        uint256 principalOffered;
        // Total value/amount that is being paid as the interest in
        uint256 totalInterestAmountOffered;
        uint256 repayamentTImeStamptalOffered;
        // Total no of EMI/installment's to be paid
        uint32 noOfInstallmentOffered;
        // 1 ; Accept  / 2 : Rejected
        OfferStatus status;
    }

    struct EMI {
        uint256 orderId;
        //Time duration (in seconds) for paying single EMI
        uint256 EachEMIDuration;
        // The last EMIId for which the EMI is paid by borrower
        uint32 LastPaidEMI_Id;
        // TOtal No of EMI paid for order
        uint32 TotalNOofPaidEMI;
        //Amout of single installment of EMI
        uint256 EMIAmount;
    }

    struct Order {
        // Order against NFT token address.
        address NFT_address;
        //token ID of NFT
        uint256 tokenId;
        // lender address for order whose offer is accepted..
        address lender;
        // Borrower address for order who's NFT are locked
        address borrower;
        // time when the loan is being started ...once after borrower accept offer..
        uint256 Loan_startDate;
        //time at which order is placed intially by borrower
        // uint256 orderCreatedAt;

        // Timestamp(in Unix ie 23 Oct 2302) for which NFT is considered for loan  ie final Repaymnet duration of loan
        uint256 repaymentTimestamp; //@TODO to be changed.
        // Total no of EMI/installment's to be paid
        uint32 NoOfInstallment;
        // Total amout borrowed to the borrower by lender in wei
        uint256 principal;
        // Total value/amount that is being paid as the interest in wei
        uint256 totalInterestAmount;
        // Current loan Status
        LoanState loanState;
        // 0 : inital(defualt value) 1 : order Accepted by DIC , 2 :  rejected
        uint8 IsAcceptedOrderDIC;
        // Id for Offer which is accpted for order by borrower
        uint8 AcceptedOfferId;
        // offer-Id managment for the order
        Counters.Counter offerId;
        // OfferId ==> OfferDetails
        mapping(uint256 => Offer) offers;
        // //orderId ==> EMI Info
        // mapping(uint256 => EMI) emiInfo;
    }

    enum LoanState {
        // The loan data is stored, but not initiated yet.
        Created,
        // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
        Active,
        //An offer is accepted by the order creator for a particular offer.
        Accepted,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the lender. This is a terminal state.
        Defaulted
    }

    event OrderCreated(
        uint256 _orderId,
        address borrower,
        address NFTAddress,
        uint256 tokenID,
        uint256 principal,
        uint256 interst,
        uint256 NoofInstallment,
        uint256 RepayUnixTimeStamp
    );
    event OfferPlaced(
        uint256 _orderId,
        uint256 _offerId,
        address userOffered,
        uint256 principal,
        uint256 _totalInterestAmount,
        uint256 _loanFinalRepaytime,
        uint32 _NoInstallment
    );

    event loanStarted(
        uint256 _orderId,
        uint256 _offerId,
        address _lender,
        address _borrower,
        uint256 _principal,
        address _nftAddress,
        uint256 _tokenId
    );

    Counters.Counter private orderId;

    // orderId ==> OrderDetails
    mapping(uint256 => Order) public orders;

    //orderId ==> EMI Info
    mapping(uint256 => EMI) private emiInfo;

    constructor(address _signerAddress, address _ethEscrow) {
        require(_signerAddress != address(0), "SIGNER-ADDRESS_NONZERO");
        require(_ethEscrow != address(0), "ESCROW-ADDRESS_NONZERO");

        signerAddress = _signerAddress;
        escrow = _ethEscrow;
    }

    /**
    An approval must be provided to contract for NFT before  executing this function.
    A order is the process where borrower lock his/her NFT and create a proposal with the details.
    An order can have multiple offer's.But only single offer can be accepted for it.
    **/
    function createOrder(
        uint256 _tokenId,
        uint256 _principalAmount,
        uint256 _totalInterest,
        uint32 _noInstallment,
        uint256 _loanFinalRepaytime,
        uint256 _maxApprovalAmount,
        address _nftToken,
        bytes memory _signaure
    ) external {
        require(_principalAmount > 0, "PRINCIPAL_NONZERO");
        require(_totalInterest > 0, "INTEREST-PAID_NONZERO");
        require(_nftToken != address(0), "NFT-ADDRESS_NONZERO");
        require(_loanFinalRepaytime > block.timestamp, "REPAYMENT-DURATION_NOT_CURRENT");
        require(_noInstallment > 0, "NO-INSTALLMENTS_NONZERO");

        // if Signature get verified with the data Signed by the DIC wallet private key
        //  then only we will update the VerifyOrder and mark it as Accepted but only
        // for phase1 .. (as similar in bluprint)
        bytes32 hash = hashMessage(block.chainid, _maxApprovalAmount, _tokenId, _nftToken);
        require(matchAddressSigner(hash, _signaure), "INVALID_SIGN_DATA");
        require(_principalAmount <= _maxApprovalAmount, "PRINCIPAL_EXCEED_MAX_APPROVAL");

        //@TODO Does it actually returns the previous counter or else does it updates and retrun the incremented Id..
        orderId.increment();
        uint256 currorderId = orderId.current();

        // Receive Collateral NFT Tokens
        IERC721(_nftToken).safeTransferFrom(msg.sender, address(this), _tokenId);

        // Save order-info

        Order storage newOrder = orders[currorderId];
        newOrder.NFT_address = _nftToken;
        newOrder.tokenId = _tokenId;
        newOrder.borrower = msg.sender;
        newOrder.repaymentTimestamp = _loanFinalRepaytime;
        newOrder.NoOfInstallment = _noInstallment;
        newOrder.principal = _principalAmount;
        newOrder.totalInterestAmount = _totalInterest;
        newOrder.loanState = LoanState.Created;
        newOrder.IsAcceptedOrderDIC = 1;
        // newOrder.orderCreatedAt = block.timestamp;

        emit OrderCreated(
            currorderId,
            msg.sender,
            _nftToken,
            _tokenId,
            _principalAmount,
            _totalInterest,
            _noInstallment,
            _loanFinalRepaytime
        );
    }

    /**  filter by :
         active orders   
         Token contract 
         user Address
         */
    function getOrders(uint256 _orderId)
        public
        view
        returns (
            address nftAddress,
            uint256 tokenId,
            address borrower,
            uint32 noOfInstallment,
            uint8 acceptedOrderId,
            uint8 DICAcceptanceStatus,
            LoanState status
        )
    {
        require(isExistOrder(_orderId), "ORDER_NONEXIST");
        Order storage orderInfo = orders[_orderId];

        return (
            orderInfo.NFT_address,
            orderInfo.tokenId,
            orderInfo.borrower,
            orderInfo.NoOfInstallment,
            orderInfo.AcceptedOfferId,
            orderInfo.IsAcceptedOrderDIC,
            orderInfo.loanState
        );
    }

    function getEMIDetailsforOrder(uint256 _orderId)
        public
        view
        returns (
            uint256 loanStartDate,
            uint256 repaymentTImeStamp,
            uint256 principal,
            uint256 totalInterestAmount,
            uint256 totalNOofPaidEMI,
            uint256 lastPaidEMIId,
            uint256 eachEMIDuration,
            uint256 eMIAmount
        )
    {
        require(isExistOrder(_orderId), "ORDER_NONEXIST");
        Order storage orderInfo = orders[_orderId];
        EMI memory emiDetail = emiInfo[_orderId];
        require(emiDetail.orderId != 0, "EMIDETAIL_NON_EXIST");

        return (
            orderInfo.Loan_startDate,
            orderInfo.repaymentTimestamp,
            orderInfo.principal,
            orderInfo.totalInterestAmount,
            emiDetail.TotalNOofPaidEMI,
            emiDetail.LastPaidEMI_Id,
            emiDetail.EachEMIDuration,
            emiDetail.EMIAmount
        );
    }

    function hashMessage(
        uint256 chainId,
        uint256 _maxApprovalAmount,
        uint256 tokenId,
        address _nftaddress
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    keccak256(abi.encodePacked(chainId, _maxApprovalAmount, tokenId, _nftaddress))
                )
            );
    }

    function matchAddressSigner(bytes32 hash, bytes memory signature) private view returns (bool) {
        return signerAddress == hash.recover(signature);
    }

    //Only a specific role/wallet is allowed to call this function.. onlyOwner
    /**
    function verifyOrder(
        uint256 _orderId,
        bool _status,
        uint256 _maxApprovalAmount,
        bytes memory _signaure
    ) external {
        require(isExistOrder(_orderId), "ORDER_NONEXIST");
        Order storage OrderInfo = orders[_orderId];
        bytes32 hash = hashMessage(
            msg.sender,
            block.chainid,
            _maxApprovalAmount,
            OrderInfo.tokenId,
            OrderInfo.NFT_address
        );
        require(matchAddressSigner(hash, _signaure), "Sorry, you are not a whitelisted user");
        require(OrderInfo.IsAcceptedOrderDIC == 0, "Order sttaus already process DIC");
        require(OrderInfo.loanState == LoanState.Created, "Order status non-cretaed");
        OrderInfo.IsAcceptedOrderDIC = _status ? 1 : 2;
    }
*/

    // Should be added non-Re-entrant here..
    function placeOffer(
        uint256 _orderId,
        uint256 _totalInterestAmount,
        uint256 _loanFinalRepaytime,
        uint32 _noInstallment
    ) external payable {
        require(msg.value > 0, "NOT_EQUAL_ZERO");
        require(_noInstallment > 0, "INSTALLMENT_NON-ZERO");
        require(_loanFinalRepaytime > block.timestamp, "REPAYMENT-TIME_NON-CURRENT");
        require(_totalInterestAmount > 0, "INTEREST_NON-ZERO");
        require(isExistOrder(_orderId), "NONEXIST_ORDER");
        require(orders[_orderId].borrower != msg.sender, "OWNER NOT ALLOWED");
        require(orders[_orderId].IsAcceptedOrderDIC == 1, "NON-APPROVED OFFER");

        // lock ether's into escrow contract
        address payable ethEscrow = payable(escrow);
        ethEscrow.sendValue(msg.value);

        //https://ethereum-blockchain-developer.com/026-mappings-and-structs/05-add-struct/
        Offer memory offer = Offer(
            msg.sender,
            _orderId,
            msg.value,
            _totalInterestAmount,
            _loanFinalRepaytime,
            _noInstallment,
            OfferStatus.Initial
        );
        orders[_orderId].offerId.increment();
        uint256 currofferId = orders[_orderId].offerId.current();
        orders[_orderId].offers[currofferId] = offer;

        emit OfferPlaced(
            _orderId,
            currofferId,
            msg.sender,
            msg.value,
            _totalInterestAmount,
            _loanFinalRepaytime,
            _noInstallment
        );
    }

    // Check msg,sender === orderId.borrower
    // Offer should not be in already accepted
    // MUst check contract have allowance for the NFT & ethers must be transfered to contract..
    // Offer must exist
    // Order must be intitial for offer to be accepted .
    // Should transfer the fund to an escrow service and other ethers to borrower ..
    // Update the status for order as started and offer as accepted ..

    function acceptOffer(uint256 _orderId, uint8 _offerId) external nonReentrant {
        require(isExistOrder(_orderId), "NONEXIST_ORDER");
        require(orders[_orderId].borrower == msg.sender, "ONLY_OWNER_ALLOWED");
        require(orders[_orderId].borrower == msg.sender, "ONLY_OWNER_ALLOWED");
        require(orders[_orderId].loanState == LoanState.Created, "SHOULD_NOT_ALREADY_ACEPTED");
        require(isExistOffer(_orderId, _offerId), "NONEXIST_ORDER");
        require(
            IERC721(orders[_orderId].NFT_address).ownerOf(orders[_orderId].tokenId) == msg.sender,
            "NFT_OWNERSHIP_NON_AVAILABLE"
        );
        uint256 payment = orders[_orderId].offers[_offerId].principalOffered;
        require(address(escrow).balance >= payment, "IN-SUFFICIENT_ETH_BALANCE");

        Order storage orderDetails = orders[_orderId];
        orderDetails.loanState = LoanState.Accepted;
        orderDetails.AcceptedOfferId = _offerId;
        orderDetails.lender = orders[_orderId].offers[_offerId].userOffered;
        orderDetails.Loan_startDate = block.timestamp;

        orders[_orderId].offers[_offerId].status = OfferStatus.Accepted;

        address payable borrower = payable(orders[_orderId].borrower);
        borrower.sendValue(payment);

        //Approve & Transfer the ERC721 token to an excrow contract.
        IERC721(orders[_orderId].NFT_address).approve(escrow, orders[_orderId].tokenId);
        IERC721(orders[_orderId].NFT_address).safeTransferFrom(address(this), escrow, orders[_orderId].tokenId);

        orderDetails.loanState = LoanState.Active;

        emit loanStarted(
            _orderId,
            _offerId,
            orders[_orderId].lender,
            orders[_orderId].borrower,
            orders[_orderId].offers[_offerId].principalOffered,
            orders[_orderId].NFT_address,
            orders[_orderId].tokenId
        );
    }

    function isExistOrder(uint256 _orderID) internal view returns (bool) {
        return orders[_orderID].NFT_address != address(0);
    }

    function isExistOffer(uint256 _orderID, uint256 _offerId) internal view returns (bool) {
        return orders[_orderID].offers[_offerId].status != OfferStatus.NoExist;
    }

    // Only the lender can withdraw his offer once no accepted by the borrower and will refund the
    // ethers deposited to the lender
    //can be called only once
    // Status must be updated to withdrawn
    //
    // function withdrawActiveOffer() {}

    // function withdrawOrder() {}

    // (orderID ==> EMI_Id) one ==> many association
    // EMI (oderID ==> EMI[])

    // or EMI(orderID ===> (emiId==> EMI))

    //     <!-- orderId ==> EMIid ==> emi details     -->
    // mapping (uint => mapping (uint256 =>  EMI)) private _orderhasEMIs;

    // struct EMI {
    //     EMIId
    //     EMI_paidAt
    //     EMI_dueDate
    // }

    // Q. How to differentite among the loan ID and orderId ?
    // As some of the order will be going to get
    // rejects but wiil be needing to track down the wtihdraw status accordignly..

    // function getEMIDueDate(orderId){

    //     uint256 DueEMITimestamp   = Orders[orderId].Loan_startDate
    //+( Orders[orderId].EachEMIDuration * LastPaidEMI_Id)
    //         DueEMITimestamp = DueEMITimestamp + BUFFER_TIME_STAMP;
    //         uint8 EMItimeStamp
    // }
    // function withdrawOrder(){}

    // function isLoanExpired(){}

    // function RejectedOfferwithdraw(){}

    // function payEMI(){}

    // lender can clain NFT when loan defaulted...
    // function claimNFT(){}

    // Borrower witjdraw NFT back once fully paid all EMI's
    // NFT ==> borrower
    // function withDrawNFT(){}

    // @notice A continuously increasing counter that simultaneously allows
    //         every loan to have a unique ID and provides a running count of
    //         how many loans have been started by this contract.
    // uint256 public totalNumLoans = 0;

    // @notice A counter of the number of currently outstanding loans.
    // uint256 public totalActiveLoans = 0;

    // @notice A mapping from a loan's identifier to the loan's details,
    //         represted by the loan struct. To fetch the lender, call
    //         NFTfi.ownerOf(loanId).
    //mapping (uint256 => Loan) public loanIdToLoan;

    // @notice A mapping tracking whether a loan has either been repaid or
    //         liquidated. This prevents an attacker trying to repay or
    //         liquidate the same loan twice.
    //mapping (uint256 => bool) public loanRepaidOrLiquidated;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}