/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-04
*/

// SPDX-License-Identifier: GPL-3.0 
pragma solidity 0.8.0;


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


interface ITomiDomain is IERC721{
     function baseNode() external returns(bytes32);

    // function getForAuction() external view returns (address payable, uint256);

}

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}








contract TomiDomainNFT is Ownable, IERC721Receiver, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 public beneficiary;
    uint256 public nftId;
    uint public highestBid;
    uint256 public highestBidder;
    uint256 public basePrice;
    uint public bidExpiryTime; //  = block.timestamp + 24 hours;
    
    uint8 public marketPlacePercentage;
    uint8 public minterPercentage;
    uint256 public everyBidIncrementTime;
    uint8 public minimumBidIncreasePercentage;


    address payable public marketPlaceFeeWallet;
    
    bool canceled;


    struct currentBid {
        address payable currentBidder;
        uint256 currentBidAmount;
    }
    struct bid{
        address payable bidder;
        uint256 bidAmount;
    }

    struct nftDomainInfo {
        address payable minter;
        uint256 mintTime;
        uint256 expiryTime;
        bool isClaimed;
    }

    struct balance {
        uint256 totalBalance;
        uint256 bidIndex;
    }

    mapping(uint256 => nftDomainInfo) public tokenIdForNftDomainInfo;
    mapping(address => uint256) public minter;
    mapping(address => uint256) public bidder;
    mapping(address => mapping(uint256 => balance)) public addressForBalance;
    mapping(uint256 => mapping(uint256 => bid)) public tokenIdForAllBids;
    mapping(uint256 => uint256) public lengthForAllBids;
    mapping(uint256 => currentBid) public tokenIdForCurrentBid;
    mapping(address => uint256) pendingBidReturns;
    
    ITomiDomain tomiDomain;
    ENS ENSRegistry;
   
   // Events
    event highestBidIncreased(address bidder, uint256 amount);

    event changedFeePercentages (
        uint8 _marketPlacePercentage,
        uint8 _minterPercentage
    );

    event changedMarketPlaceFeeWallet (
        address indexed _marketPlaceFeeWallet
    );

    event changedTDNSAddress (
        address indexed _TDNSAddress
    );


    event bidMade (
        address indexed _minter,
        uint256 _mintTime,
        uint256 _initialExpiryTime,
        uint256 _tokenId
    );

    event bidCancelled (
        address indexed _bidder,
        uint256 _amount,
        uint256 _tokenId
    );
 // When anyone other than the highest bidder wants to claim back their bid amount
    event bidClaimed (
        address indexed _bidder,
        uint256 _amount,
        uint256 _tokenId,
        uint256 _totalBalance
    );
// When bids were made and expiry was caught outside of the claim function
    event bidExpired (
        address indexed _bidder,
        address indexed _minter,
        uint256 _amount,
        uint256 _tokenId
    );
    
// When bids were made and expiry was caught inside of the claim function

    event claimed (
        address indexed _bidder,
        address indexed _minter,
        uint256 _amount,
        uint256 _tokenId
    );

    event noBidsMadeAndExpired (
        address indexed _minter,
        uint256 _atokenID
    );

    event claimedAndNoBidsMade (
        address indexed _minter,
        uint256 _amount
    );

     event ERC721Received (
        address indexed _operator,
        address indexed _to,
        uint256 _tokenId,
        bytes data
    );

    constructor() {
         marketPlaceFeeWallet = payable(msg.sender); // TODO

        marketPlacePercentage = 50;
        minterPercentage = 50;

        minimumBidIncreasePercentage = 1;

        basePrice = 0.01 ether;
        bidExpiryTime = 24 hours;
        everyBidIncrementTime = 5 minutes;
        tomiDomain=ITomiDomain(0xC36606d59d7570a26B1040c572Adbfd1936a5085);
        ENSRegistry=ENS(0x1e7426a2b72B768bBBC5B2686280aB51196592FB);
        
    }

    //Getters

    function getTDNSContractAddress () public view returns (address) {
        return address(tomiDomain);
    }

    function getMarketPlaceWallet() public view returns (address payable) {
        return marketPlaceFeeWallet;
    }

    // Setter
    function setTDNSContractAddress(address _originContract) public onlyOwner {
        tomiDomain = ITomiDomain(_originContract);

        emit changedTDNSAddress(address(tomiDomain));
    }
    function setMarketPlaceFeeWallet(address payable _marketPlaceFeeWallet) public onlyOwner {
        marketPlaceFeeWallet = _marketPlaceFeeWallet;

        emit changedMarketPlaceFeeWallet(_marketPlaceFeeWallet);
    }

     function setFeePercentages(uint8 _marketPlacePercentage) external onlyOwner {
        require(_marketPlacePercentage < 100, "setFeePercentages::The marketplace cut should be less then 100%");

        marketPlacePercentage = _marketPlacePercentage;
        minterPercentage = 100 - marketPlacePercentage;

        emit changedFeePercentages(marketPlacePercentage, minterPercentage);
    }

    function setMinimumBidIncreasePercentage(uint8 _percentage) external onlyOwner {
        minimumBidIncreasePercentage = _percentage;
    }



    function setOnBid(address payable _minter, uint256 _tokenId) external  {
        ENSRegistry.setSubnodeOwner(tomiDomain.baseNode(), bytes32(_tokenId), address(this));

        tokenIdForNftDomainInfo[_tokenId] = nftDomainInfo(_minter, block.timestamp, block.timestamp + bidExpiryTime, false);

    emit bidMade(
        tokenIdForNftDomainInfo[_tokenId].minter,
        tokenIdForNftDomainInfo[_tokenId].mintTime,
        tokenIdForNftDomainInfo[_tokenId].expiryTime,
        _tokenId
        );
    } 
////////////////////////////////////////////// :: TODO
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external override returns (bytes4) {
        emit ERC721Received(_operator, _from, _tokenId, _data);

        return IERC721Receiver.onERC721Received.selector;
    }

    function bidFuction(uint256 _tokenId) external payable nonReentrant {
        nftDomainInfo memory tempNftDomainInfo = tokenIdForNftDomainInfo[_tokenId];
        currentBid memory tempCurrentBid = tokenIdForCurrentBid[_tokenId];
        balance memory tempBalance = addressForBalance[msg.sender][_tokenId];
        require(tempNftDomainInfo.isClaimed == false, "claim:NFT has already been claimed");
        require(msg.value != 0, "bod:Added bid cannot be 0 wei");
        uint newBid = msg.value +tempBalance.totalBalance;
        if(tempCurrentBid.currentBidAmount == 0) {
            require(newBid >= basePrice, "bid:: Bid must be higher the or equal to baseprice(0.01 Ether" );
        }
      else {
            require(newBid > tempCurrentBid.currentBidAmount.add(tempCurrentBid.currentBidAmount.mul(minimumBidIncreasePercentage).div(100)), "bid::Bid must be higher than 1% of current highest bid");   
             }
        

        if (block.timestamp > tempNftDomainInfo.expiryTime && tempCurrentBid.currentBidAmount == 0 ether) {
            tomiDomain.transferFrom(address(this), tempNftDomainInfo.minter, _tokenId);
            tokenIdForNftDomainInfo[_tokenId].isClaimed = true;

            emit noBidsMadeAndExpired(tempNftDomainInfo.minter, _tokenId);
        }
        else if (block.timestamp > tempNftDomainInfo.expiryTime) {
            emit bidExpired(tempCurrentBid.currentBidder, tempNftDomainInfo.minter, tempCurrentBid.currentBidAmount, _tokenId);
        }
        else {
            if (tempBalance.totalBalance == 0 ether) {
                addressForBalance[msg.sender][_tokenId] = balance(newBid, lengthForAllBids[_tokenId]);
            }
            else {
                tokenIdForAllBids[_tokenId][tempBalance.bidIndex] = bid(payable(0x0), 0 ether);
                addressForBalance[msg.sender][_tokenId] = balance(newBid, lengthForAllBids[_tokenId]);
            }
            tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId]] = bid(payable(msg.sender), newBid);
            lengthForAllBids[_tokenId]++;
            tokenIdForCurrentBid[_tokenId] = currentBid(payable(msg.sender), newBid);

            tempNftDomainInfo.expiryTime += everyBidIncrementTime;
            tokenIdForNftDomainInfo[_tokenId] = nftDomainInfo(tempNftDomainInfo.minter, tempNftDomainInfo.mintTime, tempNftDomainInfo.expiryTime, tempNftDomainInfo.isClaimed);

            emit bidMade(msg.sender, newBid, _tokenId, addressForBalance[msg.sender][_tokenId].totalBalance);
        }
    }


    function cancelBid(uint256 _bidAmount, uint256 _tokenId) external nonReentrant {
        require(_bidAmount >= basePrice, "cancelBid::Bid can't be less than base price");
        require(block.timestamp < tokenIdForNftDomainInfo[_tokenId].expiryTime, "cancelBid::This NFT has expired");
        require(tokenIdForNftDomainInfo[_tokenId].isClaimed == false, "cancelBid::NFT has already been claimed");
        require(addressForBalance[msg.sender][_tokenId].totalBalance != 0 ether, "cancelBid::User has no bids to cancel");
        require(lengthForAllBids[_tokenId] > 0, "cancelBid::No bids have been yet made on this NFT");


        // Declared to store values for event emission
        address payable tempBidder;
        uint256 tempBidAmount;

        bool isExistingBid = false;
        
        if (tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId] - 1].bidder == msg.sender && 
        tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId] - 1].bidAmount == _bidAmount) {
            isExistingBid = true;

            tempBidder = tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId] - 1].bidder;
            tempBidAmount = tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId] - 1].bidAmount;

            sendValue(tempBidder, tempBidAmount);

            tokenIdForAllBids[_tokenId][lengthForAllBids[_tokenId] - 1] = bid(payable(0x0), 0 ether);
            lengthForAllBids[_tokenId]--;
            addressForBalance[msg.sender][_tokenId] = balance(0, 0);

            if (lengthForAllBids[_tokenId] == 0) {
                tokenIdForCurrentBid[_tokenId].currentBidder = payable(0x0);
                tokenIdForCurrentBid[_tokenId].currentBidAmount = 0 ether;
            }
            else {
                for (uint256 i = lengthForAllBids[_tokenId] - 1 ; i >= 0 ; i--) {
                    if (tokenIdForAllBids[_tokenId][i].bidAmount != 0) {
                        tokenIdForCurrentBid[_tokenId].currentBidder = tokenIdForAllBids[_tokenId][i].bidder;
                        tokenIdForCurrentBid[_tokenId].currentBidAmount = tokenIdForAllBids[_tokenId][i].bidAmount;
                        break;
                    }
                    else {
                        if (i == 0) {
                            tokenIdForCurrentBid[_tokenId].currentBidder = tokenIdForAllBids[_tokenId][i].bidder;
                            tokenIdForCurrentBid[_tokenId].currentBidAmount = tokenIdForAllBids[_tokenId][i].bidAmount;
                            lengthForAllBids[_tokenId]--;
                            break;
                        }
                        lengthForAllBids[_tokenId]--;
                    }
                }
            }
        }
        else {
            uint256 tempBidIndex = addressForBalance[msg.sender][_tokenId].bidIndex;
            if (tokenIdForAllBids[_tokenId][tempBidIndex].bidAmount == _bidAmount) {
                isExistingBid = true;

                tempBidder = tokenIdForAllBids[_tokenId][tempBidIndex].bidder;
                tempBidAmount = tokenIdForAllBids[_tokenId][tempBidIndex].bidAmount;

                sendValue(tempBidder, tempBidAmount);

                tokenIdForAllBids[_tokenId][tempBidIndex] = bid(payable(0x0), 0 ether);
                addressForBalance[msg.sender][_tokenId] = balance(0, 0);
            }
        }

        require(isExistingBid, "cancelBid::Only bidder can cancel their own bid or Incorrect bid amount");
        
        emit bidCancelled(tempBidder, tempBidAmount, _tokenId);
    }

    
    function claim(uint256 _tokenId) external nonReentrant {
        nftDomainInfo memory tempNftDomainInfo = tokenIdForNftDomainInfo[_tokenId];
        currentBid memory tempCurrentBid = tokenIdForCurrentBid[_tokenId];
        require(block.timestamp >= tempNftDomainInfo.expiryTime, "claim::NFT can only be claimed once bidding time has expired");


        if (msg.sender == tempNftDomainInfo.minter && tempCurrentBid.currentBidAmount == 0 ether) {
            require(tempNftDomainInfo.isClaimed == false, "claim::NFT has already been claimed");

            tomiDomain.transferFrom(address(this), tempNftDomainInfo.minter, _tokenId);
            
            
            tokenIdForNftDomainInfo[_tokenId].isClaimed = true;

            emit claimedAndNoBidsMade(tempNftDomainInfo.minter, _tokenId);
        }
        else {
            if (msg.sender == tempCurrentBid.currentBidder|| msg.sender == tempNftDomainInfo.minter) {
                require(tempNftDomainInfo.isClaimed == false, "claim::NFT has already been claimed");

                uint256 marketplaceShare = tempCurrentBid.currentBidAmount.mul(marketPlacePercentage).div(100);
                uint256 minterShare = tempCurrentBid.currentBidAmount.sub(marketplaceShare);

                sendValue(marketPlaceFeeWallet, marketplaceShare);
                sendValue(tempNftDomainInfo.minter, minterShare);

                // transferBackAllOtherBids(_tokenId);

                tomiDomain.transferFrom(address(this), tempCurrentBid.currentBidder, _tokenId);
                ENSRegistry.setSubnodeOwner(tomiDomain.baseNode(), bytes32(_tokenId), tempCurrentBid.currentBidder);

                addressForBalance[msg.sender][_tokenId] = balance(0, 0);
                tokenIdForNftDomainInfo[_tokenId].isClaimed = true;

                emit claimed(tempCurrentBid.currentBidder, tempNftDomainInfo.minter, tempCurrentBid.currentBidAmount, _tokenId);
            }
            else {
                require(addressForBalance[msg.sender][_tokenId].totalBalance != 0 ether, "claim::User has no bids to claim");

                sendValue(payable(msg.sender), addressForBalance[msg.sender][_tokenId].totalBalance);

                uint256 tempBidAmount = addressForBalance[msg.sender][_tokenId].totalBalance;
                addressForBalance[msg.sender][_tokenId] = balance(0, 0);

                emit bidClaimed(msg.sender, tempBidAmount, _tokenId, addressForBalance[msg.sender][_tokenId].totalBalance);
            }
        }
    }

// functions

  function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "sendValue: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "sendValue: unable to send value, recipient may have reverted");
    }
    
    receive() external payable {
        
    }


 

}