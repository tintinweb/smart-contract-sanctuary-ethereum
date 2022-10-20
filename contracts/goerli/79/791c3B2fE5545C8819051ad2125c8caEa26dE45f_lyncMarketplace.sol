// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemNotForSale(address nftAddress, uint256 tokenId);
error TokenNotListed();
error AlreadyListed(address nftAddress, uint256 tokenId);
error NoProceeds();
error NotOwner();
error NotApprovedForMarketplace();
error SelectValidTokenStandard();
error PriceMustBeAboveZero();
error NftAddressDoesNotExist(address nftAddress);

contract lyncMarketplace is ReentrancyGuard {
    enum NFTStandard {
        E721,
        E1155
    }

    struct tokenSeller {
        NFTStandard nftStandard;
        address sellerAddress;
        uint256 tokenQuantity;
        uint256 tokenPrice;
    }

    struct tokenBuyer {
        NFTStandard nftStandard;
        address nftAddress;
        uint256 tokenId;
        uint256 tokenQuantity;
        address sellerAddress;
        address buyerAddress;
    }

    tokenBuyer[] public tokenBuyersArray;

    event ItemsListed(
        NFTStandard nftStandard,
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 tokenQuantity,
        uint256 price
    );
    event ItemsCanceled(
        NFTStandard nftStandard,
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 tokenQuantity
    );

    event ItemsBought(
        NFTStandard nftStandard,
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 tokenQuantity,
        uint256 price
    );

    // State Variables
    mapping(address => mapping(uint256 => tokenSeller[])) public s_listings;
    mapping(address => uint256) private s_proceeds;
    //uint256 index = 0;

    // address public nftAddress;

    constructor() {}

    // Function modifiers
    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        uint256 tokenQuantity
    ) {
        bool check = false;

        tokenSeller[] memory listings = s_listings[nftAddress][tokenId];
        for (uint256 i = 0; i < listings.length; i++) {
            tokenSeller memory tempStructSeller = listings[i];
            if (
                tempStructSeller.sellerAddress == msg.sender &&
                tempStructSeller.tokenQuantity > 0
            ) {
                check = true;
                break;
               
            }
        }
        if (check == true) {
            revert AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    function checkIsOwner(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity
    ) internal view  returns (bool isOwner){
        if(_nftStandard == NFTStandard.E1155){
            IERC1155 nft = IERC1155(_nftAddress);

            uint256 amount = nft.balanceOf(msg.sender, _tokenId);
            if (amount < _tokenQuantity) {
                isOwner = false; 
            }else{
                if (!IERC1155(_nftAddress).isApprovedForAll(msg.sender, address(this))) {
                    isOwner = false;
                }else{
                    isOwner = true;
                }
                
            }
        }else if(_nftStandard == NFTStandard.E721){
            require(_tokenQuantity == 1 , "for ERC721 nft, Quantity should be 1");
            IERC721 nft = IERC721(_nftAddress);
            address owner = nft.ownerOf(_tokenId);
            if (msg.sender != owner) {
                isOwner = false;
            }else{
                if (nft.getApproved(_tokenId) != address(this)) {
                    isOwner = false;
                }else{
                    isOwner = true;
                }
            }
        }else{
            revert SelectValidTokenStandard();
        }
        return isOwner;
    }

    function checkIfApproved(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId) internal view returns(bool isApproved){
        if(_nftStandard == NFTStandard.E1155){
            if (!IERC1155(_nftAddress).isApprovedForAll(msg.sender, address(this))) {
                isApproved = false;
            }else{
                isApproved = true;
            }
            
        }else if(_nftStandard == NFTStandard.E721){
            IERC721 nft = IERC721(_nftAddress);
            if (nft.getApproved(_tokenId) != address(this)) {
                isApproved = false;
            }else{
                isApproved = true;
            }
            
        }else{
            revert SelectValidTokenStandard();
        }
        return isApproved;
    }

    modifier isListed(
        tokenSeller[] memory listings,
        uint256 tokenQuantity,
        address spender
    ) {
        bool check = false;
        //tokenSeller[] memory listings = s_listings[nftAddress][tokenId];
        for (uint256 i = 0; i < listings.length; i++) {
            if (
                listings[i].sellerAddress == spender &&
                listings[i].tokenQuantity >= tokenQuantity
            ) {
                check = true;
                _;
            }
        }
        if (check == false) {
            revert TokenNotListed();
        }
    }

    modifier isListedSeller(
        address _nftAddress,
        uint _tokenId
    ) {
        tokenSeller[] memory listings = s_listings[_nftAddress][_tokenId];
        for (uint256 i = 0; i < listings.length; i++) {
            if (
                listings[i].sellerAddress == msg.sender
            ) {
                _;
                break;
            }
        }

    }

    function listItem(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _price
    ) external notListed(_nftAddress, _tokenId, _tokenQuantity) {
        bool isOwnerAndApproved = checkIsOwner(_nftStandard,_nftAddress,_tokenId, _tokenQuantity);
        //bool isApproved = checkIfApproved(_nftStandard,_nftAddress,_tokenId);
        if(isOwnerAndApproved == true) {

            if (_price <= 0) {
                revert PriceMustBeAboveZero();
            }
            
            tokenSeller memory tempSellerStruct;

            if(_nftStandard == NFTStandard.E1155 || _nftStandard == NFTStandard.E721){

                tempSellerStruct.nftStandard = _nftStandard;
                tempSellerStruct.sellerAddress = msg.sender;
                tempSellerStruct.tokenQuantity = _tokenQuantity;
                tempSellerStruct.tokenPrice = _price;
            }else{
                revert SelectValidTokenStandard();
            }
      
            //tokenSeller[] storage tempArray = s_listings[nftAddress][tokenId];
            s_listings[_nftAddress][_tokenId].push(tempSellerStruct);

            // s_listings[nftAddress][tokenId] = tempArray;
            emit ItemsListed(_nftStandard,msg.sender, _nftAddress, _tokenId, _tokenQuantity, _price);
        }

    }

    function cancelListing(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity
    ) external isListed(s_listings[_nftAddress][_tokenId], _tokenQuantity, msg.sender) nonReentrant{
        bool isOwnerAndApproved = checkIsOwner(_nftStandard,_nftAddress,_tokenId, _tokenQuantity);
        if(isOwnerAndApproved == true){
            tokenSeller[] storage listings = s_listings[_nftAddress][_tokenId];
            uint index = getIndexOfArray(listings, msg.sender);
            removeListing(listings, index);

            emit ItemsCanceled(_nftStandard,msg.sender, _nftAddress, _tokenQuantity, _tokenId);
        }

    }

    function buyItem(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        address _sellerAddress
    )
        external
        payable
        isListed(s_listings[_nftAddress][_tokenId], _tokenQuantity, _sellerAddress)
        nonReentrant
    {
        tokenSeller[] storage listings = s_listings[_nftAddress][_tokenId];

        uint index = getIndexOfArray(listings, _sellerAddress);

        if (msg.value < (listings[index].tokenPrice) * (_tokenQuantity)) {
            revert PriceNotMet(
                _nftAddress,
                _tokenId,
                listings[index].tokenPrice
            );
        }

        s_proceeds[_sellerAddress] += msg.value;

        if(listings[index].nftStandard == NFTStandard.E1155){
            IERC1155(_nftAddress).safeTransferFrom(
                listings[index].sellerAddress,
                msg.sender,
                _tokenId,
                _tokenQuantity,
                ""
            );
        }else if(listings[index].nftStandard == NFTStandard.E721){
            IERC721(_nftAddress).safeTransferFrom(
                listings[index].sellerAddress,
                msg.sender,
                _tokenId
            );
        }

        UpdateTokenBuyersArray(_nftStandard,_nftAddress,_tokenId,_tokenQuantity,_sellerAddress);

        withdrawProceeds(listings[index].sellerAddress);


        // listings[index].tokenQuantity -= _tokenQuantity; 
        // (bool success, ) = payable(listings[index].sellerAddress).call{
        //     value: msg.value
        // }("");
        // require(success, "Transfer failed");

        // tokenBuyer memory tokenBuyers;

        // tokenBuyers.nftAddress = _nftAddress;
        // tokenBuyers.tokenId = _tokenId;
        // tokenBuyers.tokenQuantity = _tokenQuantity;
        // tokenBuyers.sellerAddress = _sellerAddress;
        // tokenBuyers.buyerAddress = msg.sender;

        // tokenBuyersArray.push(tokenBuyers);


        emit ItemsBought(
            _nftStandard,
            msg.sender,
            _nftAddress,
            _tokenId,
            _tokenQuantity,
            listings[index].tokenPrice
        );
        if(listings[index].tokenQuantity - _tokenQuantity == 0){
            removeListing(listings, index);
        }else{
            uint newQuantity = listings[index].tokenQuantity - _tokenQuantity;
            updateListingData(listings, index, newQuantity);
        }
    }

    function updateListingData(tokenSeller[] storage tokenSellers, uint _index, uint _newQuantity) internal {
            tokenSellers[_index].tokenQuantity = _newQuantity;
    }


    function UpdateTokenBuyersArray(   
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        address _sellerAddress
        ) private  {

        tokenBuyer memory tokenBuyers;
        tokenBuyers.nftStandard = _nftStandard;
        tokenBuyers.nftAddress = _nftAddress;
        tokenBuyers.tokenId = _tokenId;
        tokenBuyers.tokenQuantity = _tokenQuantity;
        tokenBuyers.sellerAddress = _sellerAddress;
        tokenBuyers.buyerAddress = msg.sender;

        tokenBuyersArray.push(tokenBuyers);
    }


    function updateListingPriceAndQuantity(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        uint256 _newPrice
    )
        external
        isListedSeller(_nftAddress, _tokenId)
        nonReentrant
    {
        bool isOwnerAndApproved = checkIsOwner(_nftStandard,_nftAddress,_tokenId, _tokenQuantity);
        if(isOwnerAndApproved == true){
            if (_newPrice == 0) {
                revert PriceMustBeAboveZero();
            }
            tokenSeller[] storage listings = s_listings[_nftAddress][_tokenId];
            uint index = getIndexOfArray(listings, msg.sender);
            listings[index].tokenQuantity = _tokenQuantity;
            listings[index].tokenPrice = _newPrice;

            emit ItemsListed(_nftStandard,msg.sender, _nftAddress, _tokenId, _tokenQuantity, _newPrice);
        }

    }

    function withdrawProceeds(address _sellerAddress) private {
        // uint256 proceeds = s_proceeds[_sellerAddress];
        // if (proceeds <= 0) {
        //     revert NoProceeds();
        // }
        // s_proceeds[_sellerAddress] = 0;

        (bool success, ) = payable(_sellerAddress).call{value: msg.value}("");
        require(success, "Transfer failed");
    }

    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (tokenSeller[] memory)
    {
        return s_listings[nftAddress][tokenId];
    }

    function removeListing(tokenSeller[] storage sellerArray, uint256 _index)
        internal
    {
        sellerArray[_index] = sellerArray[sellerArray.length - 1];
        sellerArray.pop();
    }

    function getIndexOfArray(
        tokenSeller[] storage sellerArray,
        address _sellerAddress
    ) internal view returns (uint256) {
        uint256 index;
        for (uint256 i = 0; i < sellerArray.length; i++) {
            if (sellerArray[i].sellerAddress == _sellerAddress) {
                index = i;
            }
        }
        return index;
    }

//     function getProceeds(address seller) external view returns (uint256) {
//         return s_proceeds[seller];
//     }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
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