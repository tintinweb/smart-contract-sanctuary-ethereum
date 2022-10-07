// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IERC2981{
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external returns (address, uint256) ;
}

contract Marketplace is ReentrancyGuard, IERC721Receiver{
    /////////////////////////////////////////////////////////////////////STATE VARIABLES////////////////////////////////////////////////////////
    uint256 private nftsold;
    uint256 private nftkey;
    address owner;
    uint256 listingprice;
   
    
    ///////////////////////////////////////////////////////////////////////////STRUCT/////////////////////////////////////////////////////////
    struct Nftdetail{
        address seller;
        address buyer;
        uint price;
        bool sold;
        address nftaddress;
        uint tokenid;
        uint tokenkey;
    }

    /// @dev mapping of tokenkey to struct of nftdetails
    /////////////////////////////////////////////////////////////////////////////MAPPING//////////////////////////////////////////////////////////////////
    mapping (uint256 => Nftdetail) public NFTDetails;

    //////////////////////////////////////////////////////////////////////////CONSTRUCTOR////////////////////////////////////////////////////
    constructor(){
        owner = msg.sender;
    }

    /////////////////////////////////////////////////////////////////////////EVENTS/////////////////////////////////////////////////////////////
    event listed(
        address seller,
        address buyer,
        uint price,
        bool sold,
        address nftaddress,
        uint tokenid,
        uint tokenkey
    );

    ///////////////////////////////////////////////////////////////////////MODIFIER//////////////////////////////////////////////////////////
    modifier onlyowner {
        require(msg.sender == owner, "not owner");
        _;
    }

    /////////////////////////////////////////////////////////////////////CUSTOM ERRORS////////////////////////////////////////////////
    /// not owner
    error Notnftowner();

    /// Price must be at least 1 wei
    error Zeroprice();

    /// Price must be equal to listing price
    error Listingprice();

    /// amount not enough for this nft
    error insufficientfunds();

    /// @dev a function to set the listingprice
    function setlistingprice(uint price) external onlyowner{
        listingprice =  price;
    }

    /// @dev function were seller come to list their nft for sale on the platform
    /// @param _price for the nft to be listed
    /// @param _nftaddress address of the nft
    /// @param _tokenid the id of the nft to be listed
    function listnft(uint _price, address _nftaddress, uint _tokenid) external payable nonReentrant returns(uint256) {
        /// check if the msg.sender is the owner of the token
        if (IERC721(_nftaddress).ownerOf(_tokenid) != msg.sender){
            revert Notnftowner();
        }
        if ( _price <= 0) {
            revert Zeroprice();
        }
        if ( msg.value < listingprice) {
            revert Listingprice();
        }
        nftkey = nftkey + 1;
        uint256 key = nftkey;
        Nftdetail storage ND = NFTDetails[key];
        ND.seller = payable(msg.sender);
        ND.price = _price;
        ND.nftaddress = _nftaddress;
        ND.tokenid = _tokenid;
        ND.tokenkey = key;
        ND.sold = false;

        IERC721(_nftaddress).safeTransferFrom(msg.sender, address(this),_tokenid);
        emit listed(msg.sender,address(0),_price,false,_nftaddress,_tokenid,key);
        return key;
    }

    /// @dev a  user comes to buy an nft
    /// @param _tokenid nftid to buy
    function buynft(uint _tokenid) payable external {
        Nftdetail storage ND = NFTDetails[_tokenid];
        require(ND.sold != true, "already sold");
        if ( msg.value <  ND.price ) {
            revert insufficientfunds();
        }
        uint saleprice = msg.value;
        address seller = ND.seller;
        address nftaddress = ND.nftaddress;
        (bool sent,) = payable(seller).call{value:saleprice}("");
        require(sent == true, "failed");
        (bool sent2,) = payable(owner).call{value:listingprice}("");
        require(sent2 == true, "failed");
        // _getroyalties(_tokenid,saleprice,nftaddress);   //// check why this line is not working
        IERC721(nftaddress).safeTransferFrom(address(this), msg.sender,_tokenid);
        ND.buyer = payable(msg.sender);
        ND.sold = true;
        nftsold  = nftsold + 1;
    }

    function _checkRoyalties(address _contract) internal returns (bool) {
        bool success = IERC165(_contract).supportsInterface(0x2a55205a);
        return success;
    }

    function _getroyalties(uint tokenid, uint price , address nftaddress) internal returns(uint netprice){
        bool implement = _checkRoyalties(nftaddress);
        require(implement == true, "does implements");
        (address royalityreceiver, uint amountofroyalties) = IERC2981(nftaddress).royaltyInfo(tokenid, price);
        uint sellermoney = price - amountofroyalties;
        (bool sent,) = payable(royalityreceiver).call{value: amountofroyalties}("");
        require(sent == true, "failed");
        return sellermoney;
    }  

     function fetchMarketItems() public view returns (Nftdetail[] memory) {
        uint256 itemCount = nftkey;
         uint256 currentIndex = 0;
        uint256 unsoldItemCount = nftkey- nftsold;
        Nftdetail[] memory items = new Nftdetail[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (NFTDetails[i + 1].sold == false) {
                uint256 currentId = i + 1;
                Nftdetail storage currentItem  =NFTDetails[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function getlistingprice() external view returns(uint256) {
        return listingprice;
    }

    /* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (Nftdetail[] memory) {
        uint256 totalItemCount = nftkey;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (NFTDetails[i + 1].buyer == msg.sender) {
                itemCount += 1;
            }
        }

        Nftdetail[] memory items = new Nftdetail[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (NFTDetails[i + 1].buyer == msg.sender) {
                uint256 currentId = i + 1;
                Nftdetail storage currentItem  =NFTDetails[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /* Returns only items a user has created */
    function fetchItemsCreated() public view returns (Nftdetail[] memory) {
        uint256 totalItemCount = nftkey;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (NFTDetails[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        Nftdetail[] memory items = new Nftdetail[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (NFTDetails[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                Nftdetail storage currentItem = NFTDetails[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }


    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        return type(IERC721Receiver).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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