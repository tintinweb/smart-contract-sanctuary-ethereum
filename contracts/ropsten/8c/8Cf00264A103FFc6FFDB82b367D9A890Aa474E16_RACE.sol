// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

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



contract RACE {
    using Counters for Counters.Counter;

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
        uint8 status;
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

    Counters.Counter private orderId;

    // orderId ==> OrderDetails
    mapping(uint256 => Order) public orders;

    //orderId ==> EMI Info
    mapping(uint256 => EMI) private emiInfo;

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
        address _nftToken // returns ( //     // bytes _SignaturePhase1_DIC_PK
    ) external {
        require(_principalAmount > 0, "PRINCIPAL_NONZERO");
        require(_totalInterest > 0, "INTEREST-PAID_NONZERO");
        require(_nftToken != address(0), "NFT-ADDRESS_NONZERO");
        require(_loanFinalRepaytime > block.timestamp, "REPAYMENT-DURATION_NOT_CURRENT");
        require(_noInstallment > 0, "NO-INSTALLMENTS_NONZERO");

        // if Signature get verified with the data Signed by the DIC wallet private key
        //  then only we will update the VerifyOrder and mark it as Accepted but only
        // for phase1 .. (as similar in bluprint)

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
        // newOrder.orderCreatedAt = block.timestamp;

        //@TODO Oes it actually returns the previous counter or else does it updates and retrun the incremented Id..
        orderId.increment();
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
        require(emiDetail.orderId != 0, "NON_EXIST");

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

    //Only a specific role is allowed to call this function.. onlyOwner
    function VerifyOrder(uint256 _orderId, bool _status) public {
        require(isExistOrder(_orderId), "ORDER_NONEXIST");
        Order storage OrderInfo = orders[_orderId];
        require(OrderInfo.IsAcceptedOrderDIC == 0, "Order sttaus already process DIC");
        require(OrderInfo.loanState == LoanState.Created, "Order status non-cretaed");
        OrderInfo.IsAcceptedOrderDIC = _status ? 1 : 2;
    }

    // Should be added non-Re-entrant here..
    function placeOffer(
        uint256 _orderId,
        uint256 _totalInterestAmount,
        uint256 _loanFinalRepaytime,
        uint32 _NoInstallment
    ) public payable {
        require(msg.value > 0, "NOT_EQUAL_ZERO");
        require(isExistOrder(_orderId), "NONEXIST_ORDER");
        require(orders[_orderId].borrower != msg.sender, "NON-OWNEsR");
        require(orders[_orderId].IsAcceptedOrderDIC == 1, "NON-APPROVED OFFER");

        // Replace with openzepilian escorw functionality here and
        // lock ether's into escrow contract

        // Must have an internal check so that transferFrom got sucesss or failed..
        // We must check that boolean is being returned from transferFrom
        // IERC721(nftToken).safeTransferFrom(_msgSender(), address(this), tokenId);

        //https://ethereum-blockchain-developer.com/026-mappings-and-structs/05-add-struct/
        Offer memory offer = Offer(
            msg.sender,
            _orderId,
            msg.value,
            _totalInterestAmount,
            _loanFinalRepaytime,
            _NoInstallment,
            0
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
            _NoInstallment
        );
    }

    function AcceptOffer() public {
        // Check msg,sender === orderId.borrower
        // Offer should not be in already accepted
        // MUst check contract have allowance for the NFT & ethers must be transfered to contract..
        // Offer must exist
        // Order must be intitial for offer to be accepted .
        // Should transfer the fund to an escrow service and other ethers to borrower ..
        // Update the status for order as started and offer as accepted ..
    }

    function isExistOrder(uint256 _orderID) internal view returns (bool) {
        Order storage verfyOrder = orders[_orderID];
        return verfyOrder.NFT_address != address(0);
    }

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