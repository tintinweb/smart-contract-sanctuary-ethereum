// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IMarket} from "./interfaces/IMarket.sol";
import {ICollections} from "./interfaces/ICollections.sol";

/**
 * @title A Market for pieces of media
 * @notice This contract contains all of the market logic for Media
 */
contract Market is IMarket, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /* *******
     * Globals
     * *******
     */
    // Fee percent
    uint256 public fee;

    // Fee address
    address public feeAddress;

    // Referral wei amount
    uint256 public referralAmount;

    // Collection contract address
    address public collectionContractAddress;

    // Mapping from token to the current ask for the token
    mapping(address => mapping(uint256 => uint256)) private _tokenAsks;

    // Mapping from token to the current bid for the token
    mapping(address => mapping(uint256 => Bid)) private _tokenBids;

    // Mapping for referral
    mapping(address => address) private referrals;

    // Mapping referral processed
    mapping(address => bool) private referralProcessed;

    constructor() {}

    /* *********
     * Modifiers
     * *********
     */

    modifier onlyApprovedOrOwner(
        address spender,
        address tokenAddress,
        uint256 tokenId
    ) {
        IERC721 tokenContract = IERC721(tokenAddress);
        address tokenOwner = tokenContract.ownerOf(tokenId);
        require(
            tokenContract.getApproved(tokenId) == spender ||
                spender == tokenOwner ||
                tokenContract.isApprovedForAll(tokenOwner, spender) ||
                ICollections(collectionContractAddress).validMedia(msg.sender),
            "Market: only approved or owner"
        );
        _;
    }

    modifier onlyValidCaller(address caller) {
        require(
            caller == msg.sender ||
                ICollections(collectionContractAddress).validMedia(msg.sender),
            "Market: invalid caller"
        );
        _;
    }

    modifier onlyExistingToken(address tokenAddress, uint256 tokenId) {
        require(
            IERC721(tokenAddress).ownerOf(tokenId) != address(0),
            "Market: invalid token"
        );
        _;
    }

    fallback() external payable {}

    receive() external payable {}

    /* ****************
     * View Functions
     * ****************
     */
    function currentAskForToken(address tokenAddress, uint256 tokenId)
        external
        view
        override
        returns (uint256)
    {
        return _tokenAsks[tokenAddress][tokenId];
    }

    function currentBidForToken(address tokenAddress, uint256 tokenId)
        external
        view
        override
        returns (Bid memory)
    {
        return _tokenBids[tokenAddress][tokenId];
    }

    function isValidBid(uint256 bidAmount) public pure override returns (bool) {
        return bidAmount != 0;
    }

    /* ****************
     * Public Functions
     * ****************
     */

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setAsk(
        address tokenOwner,
        address tokenAddress,
        uint256 tokenId,
        uint256 ask
    )
        public
        override
        nonReentrant
        onlyApprovedOrOwner(msg.sender, tokenAddress, tokenId)
        onlyValidCaller(tokenOwner)
    {
        require(isValidBid(ask), "Market: Ask invalid");
        _tokenAsks[tokenAddress][tokenId] = ask;
        emit AskCreated(tokenAddress, tokenId, ask);
    }

    /**
     * @notice removes an ask for a token and emits an AskRemoved event
     */
    function removeAsk(
        address tokenOwner,
        address tokenAddress,
        uint256 tokenId
    )
        public
        override
        onlyApprovedOrOwner(msg.sender, tokenAddress, tokenId)
        onlyValidCaller(tokenOwner)
    {
        emit AskRemoved(
            tokenAddress,
            tokenId,
            _tokenAsks[tokenAddress][tokenId]
        );
        delete _tokenAsks[tokenAddress][tokenId];
    }

    function _setBid(
        address tokenAddress,
        uint256 tokenId,
        Bid calldata bid
    ) private {
        require(msg.sender == bid.bidder, "Market: Bidder must be msg sender");
        require(bid.bidder != address(0), "Market: bidder cannot be 0 address");
        require(bid.amount != 0, "Market: bid amount cannot be 0");
        require(bid.amount == msg.value, "Market: invalid amount");

        Bid storage existingBid = _tokenBids[tokenAddress][tokenId];

        // If there is an existing bid, refund it before continuing
        if (existingBid.amount > 0) {
            require(
                bid.amount > existingBid.amount,
                "Amount should be bigger than the current bid"
            );
            removeBid(tokenAddress, tokenId, bid.bidder);
        }

        _tokenBids[tokenAddress][tokenId] = Bid(msg.value, bid.bidder);
        emit BidCreated(tokenAddress, tokenId, bid);

        // If a bid meets the criteria for an ask, automatically accept the bid.
        // If no ask is set or the bid does not meet the requirements, ignore.
        if (
            _tokenAsks[tokenAddress][tokenId] > 0 &&
            bid.amount >= _tokenAsks[tokenAddress][tokenId]
        ) {
            // Finalize exchange
            _finalizeNFTTransfer(tokenAddress, tokenId);
            _processReferral(bid.bidder);
        }
    }

    function setBidWithReferral(
        address tokenAddress,
        uint256 tokenId,
        Bid calldata bid,
        address referralAddress
    )
        external
        payable
        override
        nonReentrant
        onlyExistingToken(tokenAddress, tokenId)
    {
        require(
            referralAddress != address(0),
            "Market: invalid referral address"
        );
        require(referralAddress != msg.sender, "Market: cannot refer yourself");

        if (referralProcessed[msg.sender] == false) {
            referrals[msg.sender] = referralAddress;
        }
        _setBid(tokenAddress, tokenId, bid);
    }

    function setBid(
        address tokenAddress,
        uint256 tokenId,
        Bid calldata bid
    )
        public
        payable
        override
        nonReentrant
        onlyExistingToken(tokenAddress, tokenId)
    {
        _setBid(tokenAddress, tokenId, bid);
    }

    /**
     * @notice Removes the bid on a particular media for a bidder. The bid amount
     * is transferred from this contract to the bidder, if they have a bid placed.
     */
    function removeBid(
        address tokenAddress,
        uint256 tokenId,
        address bidder
    ) public override {
        require(bidder == msg.sender, "Market: bidder should be the caller");

        Bid storage bid = _tokenBids[tokenAddress][tokenId];
        uint256 bidAmount = bid.amount;

        require(bid.amount > 0, "Market: cannot remove bid amount of 0");

        emit BidRemoved(tokenAddress, tokenId, bid);
        delete _tokenBids[tokenAddress][tokenId];
        require(payable(bidder).send(bidAmount), "Market: failed to refund");
    }

    function acceptBid(
        address tokenOwner,
        address tokenAddress,
        uint256 tokenId,
        Bid calldata expectedBid
    )
        external
        override
        nonReentrant
        onlyApprovedOrOwner(msg.sender, tokenAddress, tokenId)
        onlyValidCaller(tokenOwner)
    {
        Bid memory bid = _tokenBids[tokenAddress][tokenId];
        require(bid.amount > 0, "Market: cannot accept bid of 0");
        require(
            bid.amount == expectedBid.amount &&
                bid.bidder == expectedBid.bidder,
            "Market: Unexpected bid found."
        );
        require(
            isValidBid(bid.amount),
            "Market: Bid invalid for share splitting"
        );

        _finalizeNFTTransfer(tokenAddress, tokenId);
        _processReferral(bid.bidder);
    }

    function _processReferral(address bidder) private {
        if (
            referrals[bidder] != address(0) &&
            referralProcessed[bidder] == false &&
            referralAmount != 0
        ) {
            require(payable(referrals[bidder]).send(referralAmount));
            referralProcessed[bidder] = true;
        }
    }

    /**
     * @notice Given a token ID and a bidder, this method transfers the value of
     * the bid. It also transfers the ownership of the media
     * to the bid recipient. Finally, it removes the accepted bid and the current ask.
     */
    function _finalizeNFTTransfer(address tokenAddress, uint256 tokenId)
        private
    {
        require(feeAddress != address(0), "Market: fee address is not set");

        Bid memory bid = _tokenBids[tokenAddress][tokenId];
        address tokenOwner = IERC721(tokenAddress).ownerOf(tokenId);

        uint256 feeAmount = (bid.amount * fee) / 100;
        uint256 transferAmount = bid.amount - feeAmount;

        require(payable(tokenOwner).send(transferAmount));
        require(payable(feeAddress).send(feeAmount));

        // Transfer media to bid recipient
        IERC721(tokenAddress).safeTransferFrom(tokenOwner, bid.bidder, tokenId);

        // Remove the accepted bid
        delete _tokenBids[tokenAddress][tokenId];
        delete _tokenAsks[tokenAddress][tokenId];

        emit BidFinalized(tokenAddress, tokenId, bid);
    }

    function setFee(uint256 _fee) external override onlyOwner {
        fee = _fee;
    }

    function setFeeAddress(address _feeAddress) external override onlyOwner {
        require(_feeAddress != address(0), "Market: fee address cannot be 0");
        feeAddress = _feeAddress;
    }

    function setReferralAmount(uint256 _referralAmount)
        external
        override
        onlyOwner
    {
        referralAmount = _referralAmount;
    }

    function setCollectionContractAddress(address _collectionContractAddress)
        external
        override
        onlyOwner
    {
        require(_collectionContractAddress != address(0), "invalid address");
        collectionContractAddress = _collectionContractAddress;
    }

    function transfer(
        address from,
        address to,
        address tokenAddress,
        uint256 tokenId
    ) external override onlyApprovedOrOwner(msg.sender, tokenAddress, tokenId) {
        require(
            from == msg.sender,
            "Market: from address should be the sender"
        );
        require(to != address(0), "Market: to address cannot be 0");

        delete _tokenAsks[tokenAddress][tokenId];

        IERC721(tokenAddress).safeTransferFrom(from, to, tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for Zora Protocol's Market
 */
interface IMarket {
    struct Bid {
        // Amount of the currency being bid
        uint256 amount;
        // Address of the bidder
        address bidder;
    }

    event BidCreated(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        Bid bid
    );

    event BidRemoved(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        Bid bid
    );

    event BidFinalized(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        Bid bid
    );

    event AskCreated(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    event AskRemoved(
        address indexed tokenAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    function currentBidForToken(address tokenAddress, uint256 tokenId)
        external
        view
        returns (Bid memory);

    function currentAskForToken(address tokenAddress, uint256 tokenId)
        external
        view
        returns (uint256);

    function isValidBid(uint256 amount) external view returns (bool);

    function setAsk(
        address tokenOwner,
        address tokenAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function removeAsk(
        address tokenOwner,
        address tokenAddress,
        uint256 tokenId
    ) external;

    function setBidWithReferral(
        address tokenAddress,
        uint256 tokenId,
        Bid memory bid,
        address referralAddress
    ) external payable;

    function setBid(
        address tokenAddress,
        uint256 tokenId,
        Bid memory bid
    ) external payable;

    function removeBid(
        address tokenAddress,
        uint256 tokenId,
        address bidder
    ) external;

    function acceptBid(
        address tokenOwner,
        address tokenAddress,
        uint256 tokenId,
        Bid calldata expectedBid
    ) external;

    function setFee(uint256 fee) external;

    function setFeeAddress(address feeAddress) external;

    function setReferralAmount(uint256 referralAmount) external;

    function setCollectionContractAddress(address _collectionContractAddress)
        external;

    function transfer(
        address from,
        address to,
        address tokenAddress,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma abicoder v2;

/**
 * @title Interface for Collections Contract
 */
interface ICollections {
    struct CollectionData {
        string nftName;
        string nftSymbol;
        address mediaAddress;
    }

    event CollectionCreated(address indexed mediaAddress);

    function getCollectionData(address mediaAddress)
        external
        view
        returns (CollectionData memory);

    function createNewCollection(
        string calldata nftSymbol,
        string calldata nftName
    ) external returns (address);

    function validMedia(address _mediaAddress) external returns (bool);
}

// SPDX-License-Identifier: MIT

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