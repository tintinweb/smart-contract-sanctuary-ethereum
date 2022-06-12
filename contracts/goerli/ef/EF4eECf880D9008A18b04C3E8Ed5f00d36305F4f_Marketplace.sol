/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

// File: contracts/interfaces/IStarknetCore.sol


pragma solidity ^0.8.0;

interface IStarknetCore {
  /// @notice Sends a message to an L2 contract.
  /// @return the hash of the message.
  function sendMessageToL2(
    uint256 toAddress,
    uint256 selector,
    uint256[] calldata payload
  ) external returns (bytes32);

  /// @notice Consumes a message that was sent from an L2 contract.
  /// @return the hash of the message.
  function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload)
    external returns(bytes32);
}
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: contracts/alim.sol


pragma solidity 0.8.13;




contract Marketplace is ERC721Holder {

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct AuctionListing {
        address seller;
        uint256 startingPrice;
        uint256 duration;
    }

    struct BuyNowListing {
        address seller;
        uint256 price;
    }

    /*//////////////////////////////////////////////////////////////
                             STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    //NFT contract address => tokenId => Auctionlisting
    mapping(address => mapping(uint256 => AuctionListing)) auctionListings;
    mapping(address => mapping(uint256 => BuyNowListing)) buyNowListings;

    IStarknetCore immutable starknetCore;
    
    uint256 constant INITIALIZE_SELECTOR =
    1611874740453389057402018505070086259979648973895522495658169458461190851914;

    uint256 constant STOP_SELECTOR =
    32032038621086203069106091894612339762081205489210192790601047421080225239;
    
    uint256 L2CONTRACT_ADDRESS =
    88716746582861518782029534537239299938153893061365637382342674063266644116;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event AuctionListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 startingPrice,
        uint256 endTime
    );
    
    event AuctionUnlisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    
    event NFTListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event NFTUnlisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _starknetCoreAddress) {
        starknetCore = IStarknetCore(_starknetCoreAddress);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function putOnAuction(address nftAddress, uint tokenId, uint startingPrice, uint duration) external {

        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        auctionListings[nftAddress][tokenId] = AuctionListing(msg.sender, startingPrice, block.timestamp + duration);

        //[nftAddress, tokenId, startingPrice, endTime]
        uint256[] memory payload = new uint256[](4);
        payload[0] = uint256(uint160(nftAddress));
        payload[1] = tokenId;
        payload[2] = startingPrice;
        payload[3] = block.timestamp + duration;
        
        starknetCore.sendMessageToL2(
            L2CONTRACT_ADDRESS, 
            INITIALIZE_SELECTOR,
            payload
        );
        
        emit AuctionListed(msg.sender, nftAddress, tokenId, startingPrice, block.timestamp + duration);
    }

    function putOnBuyNow(address nftAddress, uint tokenId, uint price) external {
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        buyNowListings[nftAddress][tokenId] = BuyNowListing(msg.sender, price);
        emit NFTListed(msg.sender, nftAddress, tokenId, price);
    }

    function buyNow(address nftAddress, uint tokenId) external payable {
        require(buyNowListings[nftAddress][tokenId].price == msg.value);
        delete buyNowListings[nftAddress][tokenId];
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        payable(buyNowListings[nftAddress][tokenId].seller).transfer(msg.value);
        emit NFTUnlisted(msg.sender, nftAddress, tokenId, msg.value);
    }

    function removeFromAuction(address nftAddress, uint tokenId) external {
        require(auctionListings[nftAddress][tokenId].seller == msg.sender);
        delete auctionListings[nftAddress][tokenId];
        
        //[nftAddress, tokenId]
        uint256[] memory payload = new uint256[](2);
        payload[0] = uint256(uint160(nftAddress));
        payload[1] = tokenId;
        
        starknetCore.sendMessageToL2(
            L2CONTRACT_ADDRESS,
            STOP_SELECTOR,
            payload
        );
        
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        emit AuctionUnlisted(msg.sender, nftAddress, tokenId);
    }

    function removeFromBuyNow(address nftAddress, uint tokenId) external {
        require(buyNowListings[nftAddress][tokenId].seller == msg.sender);
        delete buyNowListings[nftAddress][tokenId];
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);
        emit AuctionUnlisted(msg.sender, nftAddress, tokenId);
    }

    function claimAsset(address nftAddress, uint256 tokenId) external payable {
        uint256[] memory rcvPayload = new uint256[](4);
        rcvPayload[0] = uint256(uint160(msg.sender));
        rcvPayload[1] = uint256(uint160(nftAddress));
        rcvPayload[2] = tokenId;
        rcvPayload[3] = msg.value;
        
        starknetCore.consumeMessageFromL2(L2CONTRACT_ADDRESS, rcvPayload);

        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function setL2Address(uint256 _L2Address) external {
        L2CONTRACT_ADDRESS = _L2Address;
    }

}