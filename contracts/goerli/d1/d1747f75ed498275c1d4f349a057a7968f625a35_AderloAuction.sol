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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./Auth.sol";

interface ISTDNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function creatorOf(uint256 _tokenId) external view returns (address);
    function royalty() external view returns (uint256);
    function royalties(uint256 _tokenId) external view returns (uint256);
    function collectionOwner() external view returns (address);
}

interface IAderloNFT {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256);
}

contract AderloAuction is Auth, ERC721Holder {
    using SafeMath for uint256;
    using Address for address;

    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public MIN_BID_INCREMENT_PERCENT = 50; // 5%
    uint256 public swapFee = 25;  // 2.5% for admin tx fee
    address public swapFeeAddress;
    
    // Bid struct to hold bidder and amount
    struct Bid {
        address from;
        uint256 bidPrice;
    }

    // Auction struct which holds all the required info
    struct Auction {
        uint256 auction_id;
        address collection;
        uint256 token_id;
        uint256 startTime;
        uint256 endTime;
        uint256 startPrice;
        address creator;
        address owner;
        bool active;
    }
    uint256 public currentID;
    // Array with all auctions
    mapping(uint256 => Auction) public auctions;
    // Mapping from auction index to user bids
    mapping (uint256 => Bid[]) public auctionBids;

    uint256 public referral_fee = 50;  // unit=1000, (5% = 50)
    struct Referral {
        bool referred;
        address referred_by;
    }
    mapping(address => Referral) public referrals;

    event BidSuccess(address _from, uint256 _auctionId, uint256 _amount, uint256 _bidIndex);
    // AuctionCreated is fired when an auction is created
    event AuctionCreated(Auction auction);
    // AuctionCanceled is fired when an auction is canceled
    event AuctionCanceled(uint _auctionId);
    // AuctionFinalized is fired when an auction is finalized
    event AuctionFinalized(Bid bid, Auction auction);

    constructor () Auth(msg.sender) { swapFeeAddress = msg.sender; }

    function setFee(uint256 _swapFee, address _swapFeeAddress) external authorized {
        swapFee = _swapFee;
        swapFeeAddress = _swapFeeAddress;
    }

    function createAuction(
        address _collection, 
        uint256 _token_id, 
        uint256 _startPrice, 
        uint256 _startTime, 
        uint256 _endTime
    ) OnlyItemOwner(_collection, _token_id) public {
        require(block.timestamp < _endTime, "end timestamp have to be bigger than current time");
        ISTDNFT nft = ISTDNFT(_collection);
        nft.safeTransferFrom(msg.sender, address(this), _token_id);

        currentID = currentID.add(1);
        Auction memory newAuction;
        newAuction.auction_id = currentID;
        newAuction.collection = _collection;
        newAuction.token_id = _token_id;
        newAuction.startPrice = _startPrice;
        newAuction.startTime = _startTime;
        newAuction.endTime = _endTime;
        newAuction.owner = msg.sender;
        newAuction.creator = getNFTCreator(_collection, _token_id);
        newAuction.active = true;
        auctions[currentID] = newAuction;
        emit AuctionCreated(newAuction);
    }
    
    function finalizeAuction(uint256 auctionId) public {
        Auction storage myAuction = auctions[auctionId];
        require(auctionId <= currentID && myAuction.active, "Invalid Auction Id");
        uint256 bidsLength = auctionBids[auctionId].length;
        require(msg.sender == myAuction.owner, "Only auction owner can finalize");
        uint256 _tokenId = myAuction.token_id;
        // if there are no bids cancel
        if (bidsLength == 0) {
            ISTDNFT(myAuction.collection).safeTransferFrom(address(this), myAuction.owner, _tokenId);
            myAuction.active = false;
            myAuction = myAuction;
            emit AuctionCanceled(auctionId);
        } else {
            // the money goes to the auction owner
            Bid memory lastBid = auctionBids[auctionId][bidsLength - 1];
            
            uint256 nftRoyalty = getRoyalty(myAuction.collection);
            address collection_owner = getCollectionOwner(myAuction.collection);
            uint256 nftRoyalties = getRoyalties(myAuction.collection, _tokenId);
            address itemCreator = getNFTCreator(myAuction.collection, _tokenId);

            uint256 feeAmount = lastBid.bidPrice.mul(swapFee).div(PERCENTS_DIVIDER);
            uint256 royaltyAmount = lastBid.bidPrice.mul(nftRoyalty).div(PERCENTS_DIVIDER);
            uint256 royaltiesAmount = lastBid.bidPrice.mul(nftRoyalties).div(PERCENTS_DIVIDER);
            uint256 sellerAmount = lastBid.bidPrice.sub(feeAmount).sub(royaltyAmount).sub(royaltiesAmount);
            
            if (referrals[msg.sender].referred) {
                uint256 referralAmount = lastBid.bidPrice.mul(referral_fee).div(PERCENTS_DIVIDER);
                (bool rs, ) = payable(referrals[msg.sender].referred_by).call{value: referralAmount}("");
                require(rs, "Failed to send referral fee to referral user");
                sellerAmount = sellerAmount.sub(referralAmount);
            }
            if(swapFee > 0) {
                (bool fs, ) = payable(swapFeeAddress).call{value: feeAmount}("");
                require(fs, "Failed to send fee to fee address");
            }
            if(nftRoyalty > 0 && collection_owner != address(0x0)) {
                (bool hs, ) = payable(collection_owner).call{value: royaltyAmount}("");
                require(hs, "Failed to send collection royalties to collection owner");
            }
            if(nftRoyalties > 0 && itemCreator != address(0x0)) {
                (bool ps, ) = payable(itemCreator).call{value: royaltiesAmount}("");
                require(ps, "Failed to send item royalties to item creator");
            }
            (bool os, ) = payable(myAuction.owner).call{value: sellerAmount}("");
            require(os, "Failed to send to item owner");
            ISTDNFT(myAuction.collection).safeTransferFrom(address(this), lastBid.from, _tokenId);
            myAuction.active = false;
            emit AuctionFinalized(lastBid, myAuction);
        }
    }
    
    function bidOnAuction(uint256 _auction_id, uint256 amount, address _ref_address) external payable {
        require(_auction_id <= currentID && auctions[_auction_id].active, "Invalid Auction Id");
        Auction memory myAuction = auctions[_auction_id];
        require(myAuction.owner != msg.sender, "Owner can not bid");
        require(block.timestamp < myAuction.endTime, "auction is over");
        require(block.timestamp >= myAuction.startTime, "auction is not started");

        uint256 bidsLength = auctionBids[_auction_id].length;
        uint256 tempAmount = myAuction.startPrice;
        Bid memory lastBid;
        if( bidsLength > 0 ) {
            lastBid = auctionBids[_auction_id][bidsLength - 1];
            tempAmount = lastBid.bidPrice.mul(PERCENTS_DIVIDER + MIN_BID_INCREMENT_PERCENT).div(PERCENTS_DIVIDER);
        }
        require(msg.value >= tempAmount, "too small amount");
        require(msg.value >= amount, "too small balance");
        if( bidsLength > 0 ) {
            (bool result, ) = payable(lastBid.from).call{value: lastBid.bidPrice}("");
            require(result, "Failed to send to the last bidder!");
        }
        if (referrals[msg.sender].referred == false && _ref_address != msg.sender && _ref_address != address(0)) {
            referrals[msg.sender].referred_by = _ref_address;
            referrals[msg.sender].referred = true;
        }

        Bid memory newBid;
        newBid.from = msg.sender;
        newBid.bidPrice = amount;
        auctionBids[_auction_id].push(newBid);
        emit BidSuccess(msg.sender, _auction_id, newBid.bidPrice, bidsLength);
    }
    
    function getBidsAmount(uint256 _auction_id) public view returns(uint) {
        return auctionBids[_auction_id].length;
    }
    
    function getCurrentBids(uint256 _auction_id) public view returns(uint256, address) {
        uint256 bidsLength = auctionBids[_auction_id].length;
        // if there are bids refund the last bid
        if (bidsLength >= 0) {
            Bid memory lastBid = auctionBids[_auction_id][bidsLength - 1];
            return (lastBid.bidPrice, lastBid.from);
        }    
        return (0, address(0));
    }

    function getRoyalty(address collection) view internal returns(uint256) {
        ISTDNFT nft = ISTDNFT(collection);
        try nft.royalty() returns (uint256 value) {
            return value;
        } catch {
            IAderloNFT aderloNFT = IAderloNFT(collection);
            try aderloNFT.royaltyInfo(1, 1000) returns (address, uint256 _salePrice) {
                return _salePrice;
            } catch {
                return 0;
            }
        }
    }

    function getRoyalties(address collection, uint256 tokenId) view internal returns(uint256) {
        ISTDNFT nft = ISTDNFT(collection);
        try nft.royalties(tokenId) returns (uint256 value) {
            return value;
        } catch {
            return 0;
        }
    }

    function getNFTCreator(address collection, uint256 tokenId) view internal returns(address) {
        ISTDNFT nft = ISTDNFT(collection); 
        try nft.creatorOf(tokenId) returns (address creatorAddress) {
            return creatorAddress;
        } catch {
            return address(0x0);
        }
    }

    function getCollectionOwner(address collection) view internal returns(address) {
        ISTDNFT nft = ISTDNFT(collection); 
        try nft.collectionOwner() returns (address collection_owner) {
            return collection_owner;
        } catch {
            IAderloNFT aderloNFT = IAderloNFT(collection);
            try aderloNFT.royaltyInfo(1, 1000) returns (address _receiver, uint256) {
                return _receiver;
            } catch {
                return address(0x0);
            }
        }
    }
    
    modifier OnlyItemOwner(address _collection, uint256 _tokenId) {
        ISTDNFT collectionContract = ISTDNFT(_collection);
        require(collectionContract.ownerOf(_tokenId) == msg.sender);
        _;
    }

    function setReferralFee(uint256 _ref_fee) external authorized {
        require(_ref_fee < 100, "Fee should not greater than product cost!");
        referral_fee = _ref_fee;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}