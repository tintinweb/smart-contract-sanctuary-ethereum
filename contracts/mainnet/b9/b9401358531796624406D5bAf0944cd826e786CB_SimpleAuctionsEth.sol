//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SimpleAuctionsEth is Ownable{

    mapping(address => mapping(uint256 => Auction)) public auctions; // map token address and token id to auction
    mapping(address => bool) public sellers; // Only authorized sellers can make auctions

    //Each Auction is unique to each NFT (contract + id pairing).
    struct Auction {
        uint256 auctionEnd;
        uint128 minPrice;
        uint128 nftHighestBid;
        address nftHighestBidder;
        address nftSeller;
        address erc20Token;
    }

    uint32 public bidIncreasePercentage; // 100 == 1% -> every bid must be higher than the previous
    uint64 public auctionBidPeriod; // in seconds. The lenght of time between last bid and auction end. Auction duration increases if new bid is made in this period before auction end.
    uint64 public minAuctionDuration; // in seconds 86400 = 1 day
    uint64 public maxAuctionDuration; // in seconds 2678400 = 1 month

    /* ========== EVENTS ========== */
    
    event AuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        address erc20Token,
        uint128 minPrice,
        uint256 auctionEnd
    );

    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        address erc20Token,
        uint256 tokenAmount
    );

    event AuctionCompleted(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint128 nftHighestBid,
        address nftHighestBidder,
        address erc20Token
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _seller,
        uint32 _bidIncreasePercentage,
        uint64 _auctionBidPeriod,
        uint64 _minAuctionDuration, 
        uint64 _maxAuctionDuration 
        ) {
        sellers[_seller] = true;
        bidIncreasePercentage = _bidIncreasePercentage;
        auctionBidPeriod = _auctionBidPeriod;
        minAuctionDuration = _minAuctionDuration;
        maxAuctionDuration = _maxAuctionDuration; 
    }

    /* ========== CREATE AUCTION ========== */

    function createAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _minPrice,
        uint256 _auctionEnd
    )
        external
    {
        require(sellers[msg.sender], "Unauthorized");
        require(_minPrice > 0, "Price cannot be 0");
        require(block.timestamp + minAuctionDuration <= _auctionEnd && block.timestamp + maxAuctionDuration >= _auctionEnd, "Invalid auctionEnd");
        require(_erc20Token != address(0), "ERC20 invalid");

        auctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        auctions[_nftContractAddress][_tokenId].nftSeller = msg.sender;
        auctions[_nftContractAddress][_tokenId].erc20Token = _erc20Token;
        auctions[_nftContractAddress][_tokenId].auctionEnd = _auctionEnd;
        
        emit AuctionCreated(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _minPrice,
            _auctionEnd
        );
    }

    /* ========== MAKE BID ========== */

    function makeBid(
        address _nftContractAddress,
        uint256 _tokenId,
        address _erc20Token,
        uint128 _tokenAmount
    )
        external
        payable
    {
        require(block.timestamp < auctions[_nftContractAddress][_tokenId].auctionEnd, "Auction has ended");
        require(msg.sender != auctions[_nftContractAddress][_tokenId].nftSeller, "Owner cannot bid on own NFT");
        require(_erc20Token == auctions[_nftContractAddress][_tokenId].erc20Token, "Wrong ERC20");
        require(_tokenAmount >= auctions[_nftContractAddress][_tokenId].minPrice && 
            _tokenAmount * 10000 >= (auctions[_nftContractAddress][_tokenId].nftHighestBid *
                (10000 + bidIncreasePercentage)),
            "Bid too low");

        if(auctions[_nftContractAddress][_tokenId].nftHighestBid != 0) {
            IERC20(_erc20Token).transfer(
                auctions[_nftContractAddress][_tokenId].nftHighestBidder,
                auctions[_nftContractAddress][_tokenId].nftHighestBid
            );
        }

        IERC20(_erc20Token).transferFrom(
            msg.sender,
            address(this),
            _tokenAmount
        );

        auctions[_nftContractAddress][_tokenId].nftHighestBid = _tokenAmount;
        auctions[_nftContractAddress][_tokenId].nftHighestBidder = msg.sender;

        if(block.timestamp + auctionBidPeriod > auctions[_nftContractAddress][_tokenId].auctionEnd){
            auctions[_nftContractAddress][_tokenId].auctionEnd = block.timestamp + auctionBidPeriod;
        }

        emit BidMade(
            _nftContractAddress,
            _tokenId,
            msg.sender,
            _erc20Token,
            _tokenAmount
        );
    }

    /* ========== SETTLE AUCTION ========== */

    function settleAuction(address _nftContractAddress, uint256 _tokenId)
        external
    {
        require(block.timestamp >= auctions[_nftContractAddress][_tokenId].auctionEnd, "Auction ongoing");
        
        address _nftSeller = auctions[_nftContractAddress][_tokenId].nftSeller;
            
        address _nftHighestBidder = auctions[_nftContractAddress][_tokenId].nftHighestBidder;
        
        uint128 _nftHighestBid = auctions[_nftContractAddress][_tokenId].nftHighestBid;

        address _erc20Token = auctions[_nftContractAddress][_tokenId].erc20Token;

        if(_nftHighestBid != 0) {
            IERC20(_erc20Token).transfer(_nftSeller, _nftHighestBid);  
        }

        auctions[_nftContractAddress][_tokenId].nftHighestBidder = address(0);
        auctions[_nftContractAddress][_tokenId].nftHighestBid = 0;
        auctions[_nftContractAddress][_tokenId].minPrice = 0;
        auctions[_nftContractAddress][_tokenId].auctionEnd = 0;
        auctions[_nftContractAddress][_tokenId].nftSeller = address(0);
        auctions[_nftContractAddress][_tokenId].erc20Token = address(0);

        emit AuctionCompleted(
            _nftContractAddress,
            _tokenId,
            _nftSeller,
            _nftHighestBid,
            _nftHighestBidder,
            _erc20Token
        );
    }
    
    /* ========== SETTINGS ========== */

    function setAuctionBidPeriod(uint32 _auctionBidPeriod) external onlyOwner {
        auctionBidPeriod = _auctionBidPeriod;
    }

    function setBidIncreasePercentage(uint32 _bidIncreasePercentage) external onlyOwner {
        bidIncreasePercentage = _bidIncreasePercentage;
    }

    function setAuctionDuration(uint64 _minAuctionDuration, uint64 _maxAuctionDuration) external onlyOwner {
        minAuctionDuration = _minAuctionDuration;
        maxAuctionDuration = _maxAuctionDuration;
    }

    function addSeller(address _seller) external onlyOwner {
        sellers[_seller] = true;
    }

    function removeSeller(address _seller) external onlyOwner {
        sellers[_seller] = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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