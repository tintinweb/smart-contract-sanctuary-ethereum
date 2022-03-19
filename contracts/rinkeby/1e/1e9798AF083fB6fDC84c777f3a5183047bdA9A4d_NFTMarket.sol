//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./IERC721Mint.sol";
import "./EnumDeclaration.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTMarket is IERC721Receiver {

    event NFTCreated(address indexed _owner, uint _tokenId);
    event ListItem(address indexed _owner, uint _tokenId, uint _price);
    event Cancelled(address indexed _owner, uint _tokenId);
    event BuyItem(address indexed _seller, address indexed _buyer, uint _tokenId, uint _tokenPrice);
    event ListOnAuction(address indexed _owner, uint _tokenId, uint _minPrice);
    event MakeBid(address indexed _bidder, uint _tokenId, uint _newPrice);
    event FinishAuction(address indexed _seller, uint _tokenId, uint _price, bool _success);

    struct Order {
        address seller;
        OrderStatus status;
        uint price;
    }

    struct Auction {
        address seller;
        address lastBidder;
        uint32 numBids;
        AuctionStatus status;
        uint minPrice;
        uint startTime;
    }

    IERC721Mint NFT;
    IERC20 token;
    uint32 minBids;
    uint minAuctionTime;

    mapping(uint => Order) public orders;
    mapping(uint => Auction) public auctions;

    constructor (address _NFTContract, address _ERC20Contract, uint _minAuctionTime, uint32 _minBids) {
        NFT = IERC721Mint(_NFTContract);
        token = IERC20(_ERC20Contract);
        minAuctionTime = _minAuctionTime;
        minBids = _minBids;
    }

    function createItem(string memory _tokenURI, address _owner) public {
        uint tokenId = NFT.mint(_owner, _tokenURI);
        emit NFTCreated(_owner, tokenId);
    }

    function listItem(uint tokenId, uint price) public {
        NFT.safeTransferFrom(msg.sender, address(this), tokenId);
        
        orders[tokenId].seller = msg.sender;
        orders[tokenId].status = OrderStatus.onSale;
        orders[tokenId].price = price;

        emit ListItem(msg.sender, tokenId, price);
    }

    function cancel(uint tokenId) public {
        require(orders[tokenId].status == OrderStatus.onSale, "NFTMarket::cancel:token not onSale");
        require(orders[tokenId].seller == msg.sender, "NFTMarket::cancel:you are not a seller");
        
        NFT.safeTransferFrom(address(this), msg.sender, tokenId);
        orders[tokenId].status = OrderStatus.cancelled;

        emit Cancelled(msg.sender, tokenId);
    }

    function buyItem(uint tokenId) public {
        require(orders[tokenId].status == OrderStatus.onSale, "NFTMarket::cancel:token not onSale");

        token.transferFrom(msg.sender, orders[tokenId].seller, orders[tokenId].price);
        NFT.safeTransferFrom(address(this), msg.sender, tokenId);
        orders[tokenId].status = OrderStatus.sold;

        emit BuyItem(orders[tokenId].seller, msg.sender, tokenId, orders[tokenId].price);
    }

    function listItemOnAuction(uint tokenId, uint minPrice) public {
        NFT.safeTransferFrom(msg.sender, address(this), tokenId);

        auctions[tokenId].seller = msg.sender;
        auctions[tokenId].minPrice = minPrice;
        auctions[tokenId].startTime = block.timestamp;
        auctions[tokenId].status = AuctionStatus.onAuction;

        emit ListOnAuction(msg.sender, tokenId, minPrice);
    }

    function makeBid(uint tokenId, uint price) public {
        require(auctions[tokenId].status == AuctionStatus.onAuction, "NFTMarket::makeBid:token not onAuction");
        require(auctions[tokenId].minPrice < price, "NFTMarket::makeBid:your bid is too small");

        token.transferFrom(msg.sender, address(this), price);

        if (auctions[tokenId].numBids != 0) {
            token.transfer(auctions[tokenId].lastBidder, auctions[tokenId].minPrice);
        }

        auctions[tokenId].lastBidder = msg.sender;
        auctions[tokenId].minPrice = price;
        auctions[tokenId].numBids += 1;

        emit MakeBid(msg.sender, tokenId, price);
    }

    function finishAuction(uint tokenId) public {
        require(auctions[tokenId].status == AuctionStatus.onAuction, "NFTMarket::finishAuction:token not onAuction");
        require(block.timestamp - auctions[tokenId].startTime > minAuctionTime, "NFTMarket::finishAuction:auction time is not over");
        
        bool success;

        if (auctions[tokenId].numBids < minBids) {
            success = false;
            NFT.safeTransferFrom(address(this), auctions[tokenId].seller, tokenId);

            if (auctions[tokenId].numBids != 0) {
                token.transfer(auctions[tokenId].lastBidder, auctions[tokenId].minPrice);
            }

        } else {
            success = true;
            NFT.safeTransferFrom(address(this), auctions[tokenId].lastBidder, tokenId);
            token.transfer(auctions[tokenId].seller, auctions[tokenId].minPrice);
        }

        auctions[tokenId].numBids = 0;
        auctions[tokenId].status = AuctionStatus.finished;
        
        emit FinishAuction(auctions[tokenId].seller, tokenId, auctions[tokenId].minPrice, success);
    }

    function onERC721Received(address,address,uint256,bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Mint is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function mint(address _recipient, string memory _tokenURI) external returns (uint);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

    enum OrderStatus {
        unknown,
        onSale,
        cancelled,
        sold
    }

    enum AuctionStatus {
        unknown,
        onAuction,
        finished
    }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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