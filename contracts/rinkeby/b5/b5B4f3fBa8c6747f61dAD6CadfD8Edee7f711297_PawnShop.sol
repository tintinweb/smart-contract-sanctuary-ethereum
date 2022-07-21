//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PawnShop {

    using SafeMath for uint256;
    using SafeMath for uint8;

    enum PawnStatus {
        CREATED,
        CANCELLED,
        DEAL,
        LIQUIDATED,
        REPAID
    }
    struct Pawn {
        // who borrows money
        address creator;
        address contractAddress;
        uint256 tokenId;
        PawnStatus status;
    }
    struct Bid {
        address creator; // who create the bid
        uint256 loanAmount;
        // the amount of wei the lender lend to the borrower
        uint256 interest; // the maximum interest that the borrower have to pay in wei
        uint256 loanStartTime; // timestamp
        uint256 loanDuration; // duration in days
        bool isInterestProRated; // if the borrower pays sonner, then pays less interest
    }
    address public owner;
    address[] public _whiteListNFT;
    uint256 public _feeRate;
    uint256 public _totalNumberOfPawn = 0;
    uint256 public _totalNumberOfBid = 0;
    // mapping nft address -> token id -> pawn
    mapping(uint256 => Pawn) public _pawns;
    // mapping bid id => bid
    mapping(uint256 => Bid) public _bids;
    // mapping bid id to pawn id
    mapping(uint256 => uint256) public _bidToPawn;
    mapping(uint256 => uint256) public _pawnToBid;

    constructor() {
        owner = msg.sender;
    }

    event PawnCreated(address borrower, uint256 indexed pawnId);
    event PawnCancelled(address borrower, uint256 indexed pawnId);
    event PawnDeal(address borrower, address lender, uint256 indexed pawnId, uint256 bidId);
    event PawnRepaid(address borrower, address lender, uint256 indexed pawnId, uint256 bidId);
    event PawnLiquidated(address borrower, address lender, uint256 indexed pawnId, uint256 bidId);
    event BidCreated(address borrower, address lender, uint256 pawnId, uint256 indexed bidId);
    event BidAccepted(address borrower, address lender, uint256 pawnId, uint256 indexed bidId);
    event BidCancelled(address borrower, address lender, uint256 pawnId, uint256 indexed bidId);
    event WhiteListAdded(address smartContract);
    event WhiteListRemoved(address smartContract);

    function getPawnById(uint256 id) public view returns(Pawn memory) {
        return _pawns[id];
    }

    function createPawn(address tokenAddress, uint256 tokenId) public {
        _totalNumberOfPawn += 1;
        bool isInWhiteList = false;
        for (uint256 i = 0; i < _whiteListNFT.length; i++) {
            if (tokenAddress == _whiteListNFT[i]) {
                isInWhiteList = true;
            }
        }
        address sender = msg.sender;
        require(
            isInWhiteList == true,
            "PawnShop: smart contract is not in white list"
        );
        bool isApproved = IERC721(tokenAddress).getApproved(tokenId) ==
            address(this);
        bool isApprovedForAll = IERC721(tokenAddress).isApprovedForAll(
            sender,
            address(this)
        );
        require(
            isApproved || isApprovedForAll,
            "PawnShop: haven't got permission to transfer"
        );

        IERC721(tokenAddress).transferFrom(msg.sender, address(this), tokenId);

        _pawns[_totalNumberOfPawn].creator = sender;
        _pawns[_totalNumberOfPawn].contractAddress = tokenAddress;
        _pawns[_totalNumberOfPawn].tokenId = tokenId;
        _pawns[_totalNumberOfPawn].status = PawnStatus.CREATED;
        emit PawnCreated(sender, _totalNumberOfPawn);
    }

    function cancelPawn(uint256 pawnId) public {
        Pawn storage pawn = _pawns[pawnId];
        address creator = pawn.creator;
        require(
            pawn.status == PawnStatus.CREATED,
            "PawnShop: Only can cancel when it has status of CREATED"
        );
        require(
            msg.sender == creator,
            "PawnShop: Only owner of the pawn can cancel it"
        );
        require(
            _pawnToBid[pawnId] == 0,
            "PawnShop: Only can cancel when no bid is accepted"
        );
        pawn.status = PawnStatus.CANCELLED;
        IERC721(pawn.contractAddress).transferFrom(address(this), creator, pawn.tokenId);
        emit PawnCancelled(owner, pawnId);
    }

    function createBid(
        uint256 rate,
        uint256 duration,
        bool isInterestProRated,
        uint256 pawnId
    ) public payable {
        _totalNumberOfBid += 1;
        address lender = msg.sender;
        uint256 amount = msg.value;
        Pawn storage pawn = _pawns[pawnId];
        address borrower = pawn.creator;
        require(pawnId > 0, "PawnShop: pawn id is not valid");
        require(
            borrower != address(0) || pawn.contractAddress != address(0), 
            "PawnShop: pawn is not existed"
        );
        require(
            borrower != lender,
            "PawnShop: creator of the pawn cannot make a bid"
        );
        require(
            pawn.status == PawnStatus.CREATED,
            "PawnShop: cannot bid this pawn"
        );
        require(
            amount > 0,
            "PawnShop: amount of money must be bigger than 0"
        );

        _bids[_totalNumberOfBid].creator = lender;
        _bids[_totalNumberOfBid].loanAmount = amount;
        _bids[_totalNumberOfBid].interest = rate;
        _bids[_totalNumberOfBid].loanDuration = duration;
        _bids[_totalNumberOfBid].isInterestProRated = isInterestProRated;
        // _bids[_totalNumberOfBid].loanStartTime = loanStartTime;
        // loanStartTime will be set when the borrower accepts bid

        _bidToPawn[_totalNumberOfBid] = pawnId;
        emit BidCreated(borrower, lender, pawnId, _totalNumberOfBid);
    }

    function cancelBid(uint256 bidId) public {
        Bid memory currBid = _bids[bidId];
        address payable lender = payable(currBid.creator);
        address sender = msg.sender;
        require(
            sender == lender,
            "PawnShop: only creator can cancel the bid"
        );
        uint256 pawnId = _bidToPawn[bidId];
        address borrower = _pawns[pawnId].creator;
        require(
            _pawnToBid[pawnId] != bidId,
            "PawnShop: your bid is accepted, cannot cancel"
        );
        lender.transfer(currBid.loanAmount);
        delete _bids[bidId];
        delete _bidToPawn[bidId];
        emit BidCancelled(borrower, lender, pawnId, bidId);
    }

    function acceptBid(uint256 bidId) public {
        Bid storage currBid = _bids[bidId];
        address lender = currBid.creator;
        uint256 pawnId = _bidToPawn[bidId];
        require(
            pawnId > 0,
            "PawnShop: The pawn is not existed"
        );
        Pawn storage pawn = _pawns[pawnId];
        address payable borrower = payable(pawn.creator);
        require(
            borrower == msg.sender,
            "PawnShop: only creator of pawn can accept bid"
        );
        borrower.transfer(currBid.loanAmount);
        pawn.status = PawnStatus.DEAL;
        _pawnToBid[pawnId] = bidId;
        currBid.loanStartTime = block.timestamp;
        emit BidAccepted(borrower, lender, pawnId, bidId);
    }

    function repaid(uint256 pawnId) public payable {
        Pawn storage currPawn = _pawns[pawnId];
        address borrower = currPawn.creator;
        require(
            borrower == msg.sender,
            "PawnShop: Only creator of pawn can repay"
        );
        uint256 bidId = _pawnToBid[pawnId];
        require(
            bidId != 0,
            "PawnShop: This pawn doen't have any accepted bid"
        );
        Bid storage currBid = _bids[bidId];
        uint256 repayDeadline = _calculateRepayDeadline(currBid.loanStartTime, currBid.loanDuration);
        require(
            block.timestamp <= repayDeadline,
            "PawnShop: to late to repaid"
        );
        uint256 value = msg.value;
        uint256 repaidAmount = _calculateRepaidAmount(
            currBid.loanAmount,
            currBid.interest,
            currBid.loanStartTime,
            currBid.loanDuration,
            currBid.isInterestProRated
        );
        require(
            value == repaidAmount,
            "PawnShop: pay exactly repaid amount"
        );
        // transfer token back to borrower
        IERC721(currPawn.contractAddress).transferFrom(address(this), currPawn.creator, currPawn.tokenId);
        // transfer money to lender
        address payable lender = payable(currBid.creator);
        lender.transfer(value);
        delete _pawnToBid[pawnId];
        delete _bidToPawn[bidId];
        emit PawnRepaid(borrower, lender, pawnId, bidId);
    }

    function _calculateRepayDeadline(uint256 loanStartTime, uint256 loanDuration) public pure returns(uint256) {
        uint256 loanDurationInSeconds = loanDuration.mul(1 days);
        uint256 repayDeadline = loanStartTime.add(loanDurationInSeconds);
        return repayDeadline;
    }

    function _calculateRepaidAmount(
        uint256 original, uint256 interest, uint256 loanStartTime, uint256 duration, bool isInterestProRated
    ) public view returns (uint256) {
        uint256 interestDue = interest;
        if (isInterestProRated) {
            uint256 interestPerDay = interest.div(duration);
            uint256 secondPassed = block.timestamp.sub(loanStartTime);
            uint256 dayPassed = ceilDiv(secondPassed, 1 days);
            interestDue = dayPassed.mul(interestPerDay);
        }
        return original.add(interestDue);
    }

    function getRepaidAmount(uint256 pawnId) public view returns(uint256) {
        require(pawnId > 0, "PawnShop: pawn id is not existed");
        uint256 bidId = _pawnToBid[pawnId];
        require(bidId > 0, "PawnShop: pawn doesn't have a accepted bid or the pawn is done");
        Bid storage bid = _bids[bidId];
        return _calculateRepaidAmount(bid.loanAmount, bid.interest, bid.loanStartTime, bid.loanDuration, bid.isInterestProRated);
    }
    
    // get this from openzeppelin
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    function liquidate(uint256 bidId) public {
        Bid storage currBid = _bids[bidId];
        address lender = currBid.creator;
        require(lender == msg.sender, "PawnShop: only creator of bid can liquidate token");
        require(block.timestamp > currBid.loanStartTime + currBid.loanAmount, "PawnShop: Not valid time to liquidate");
        uint256 pawnId = _bidToPawn[bidId];
        require(_pawnToBid[pawnId] == bidId, "PawnShop: this bid is not accepted by borrower");
        Pawn storage currPawn = _pawns[pawnId];
        address pawner = currPawn.creator;
        IERC721(currPawn.contractAddress).transferFrom(address(this), lender, currPawn.tokenId);
        emit PawnLiquidated(pawner, lender, pawnId, bidId);
    }

    function addToWhiteList(address smartContract) public {
        require(msg.sender == owner, "PawnShop: Only owner can add address to white list");
        require(smartContract != address(0), "PawnShop: smart contract address must be different with 0");
        uint256 i = 0;
        for (i = 0; i < _whiteListNFT.length; i++) {
            if (_whiteListNFT[i] == smartContract) {
                return;
            }
        }
        _whiteListNFT.push(smartContract);
        emit WhiteListAdded(smartContract);
    }

    function removeFromWhiteList(address smartContract) public {
        require(msg.sender == owner, "PawnShop: Only owner can remove address from white list");
        uint256 i;
        for (i = 0; i < _whiteListNFT.length; i++) {
            if (_whiteListNFT[i] == smartContract) {
                break;
            }
        }
        delete _whiteListNFT[i];
        emit WhiteListRemoved(smartContract);
    }

    function getWhiteList() public view returns(address[] memory) {
        return _whiteListNFT;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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