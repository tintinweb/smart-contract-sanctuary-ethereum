// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemAlreadyRented(
);
//error NotListedForRent(address nftAddress, uint256 tokenId);
error NoSellersForThisAddressTokenId();
error NotEnoughTokensListed(
    address nftAddress,
    uint256 tokenId,
    uint256 tokenQuantity
);
error AlreadyListedForRent(
    address nftAddress,
    uint256 tokenId,
    uint256 tokenQuantity
);
error ItemNotRentedByUser(
    uint256 tokenQuantity,
    address sellerAddress,
    address renterAddress
);
error cantRentOwnedNfts(uint256 tokenId, address spender, address nftAddress);
error NoRenterWithAddressForNftAndSellerAddress(
    address sellerAddress,
    address renterAddress
);
error NFTnotYetListed();
error PriceMustBeAboveZero();
error NotOwner();
error NoProceeds();
error TokenStandardNotSupported();
error NoSuchListing();
error NFTdoesNotExist(); //newly added
error DurationMustBeAtleastOneDay();
error DurationMustBeLessThanOrEqualTomaxRentDuration();

contract lyncrent is ReentrancyGuard {

    enum NFTStandard {
        E721,
        E1155
    }

    struct tokenRenter {
        address renterAddress;
        uint256 tokenQuantityRented;
        uint256 rentedDuration;
    }
    struct tokenSeller {
        NFTStandard nftStandard;
        address sellerAddress;
        uint256 tokenQuantity; //listed quty of NFT
        uint256 pricePerDay;
        uint256 maxRentDuration;
        uint256 tokenQuantityAlreadyRented; //Already rented
        tokenRenter[]  renterArray;
    }

  
    mapping(address => tokenSeller) sellerTempMappings;
    //mapping(address => tokenRenter) renterTempMapping;

    event ItemListedForRent(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        NFTStandard nftStandard,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration
    );

    event UpdateItemlisted(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        NFTStandard nftStandard,
        uint256 tokenQuantity,
        uint256 pricePerDay,
        uint256 maxRentDuration
    );

    event ItemRented(
        address indexed renter,
        address indexed nftAddress,
        uint256 indexed tokenId,
        NFTStandard nftStandard,
        uint256 tokenQuantity,
        address sellerAddress,
        uint256 price
        //uint256 duration //no of days
    );

    event ItemReturned(
        address indexed renter,
        address indexed nftAddress,
        uint256 indexed tokenId,
        NFTStandard nftStandard,
        uint256 tokenQuantity,
        address sellerAddress,
        uint256 price,
        uint256 duration //no of days
    );

    event ItemDeListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        NFTStandard nftStandard,
        uint256 tokenQuantity
    );

    mapping(address => mapping(uint256 => tokenSeller[]))
        public allNftContractListings; //listings per nftaddress based on tokenids
    mapping(address => uint256) private s_proceeds;

    modifier notListedForRent(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity
    ) {
        tokenSeller[] storage listings = allNftContractListings[_nftAddress][
            _tokenId
        ];

        if (listings.length != 0) {
            uint256 listingAllowed;
            uint256 index = getIndexOfArray(listings, msg.sender);

           
            if(_nftStandard == NFTStandard.E1155){
                IERC1155 nft = IERC1155(_nftAddress);
                uint256 ownerAmount = nft.balanceOf(msg.sender, _tokenId);
                if(ownerAmount > 0){
                    listingAllowed = ownerAmount - listings[index].tokenQuantity;
                    if (listingAllowed < _tokenQuantity) {
                        revert AlreadyListedForRent(
                            _nftAddress,
                            _tokenId,
                            _tokenQuantity
                        );
                    }
                }else{
                    revert NotOwner();
                }
                
            }else if(_nftStandard == NFTStandard.E721){
                if(listings[index].tokenQuantity == 1){
                    revert AlreadyListedForRent(
                        _nftAddress,
                        _tokenId,
                        _tokenQuantity
                    );
                }
            }else {
                revert TokenStandardNotSupported();
            }

         
        }
        _;
    }


    modifier isListedForRent(
        tokenSeller[] storage listings,
        uint256 _tokenQuantity
    ){
        uint index = getIndexOfArray(listings, msg.sender);
        if(listings.length > 0){
            require(listings[index].sellerAddress == msg.sender, "You are not the owner of this listing");
            if(listings[index].tokenQuantity > 0){
                _;
            }else {
                revert NFTnotYetListed();
            }
        }else{
            revert NFTnotYetListed();
        }
    }


    modifier isCurrentlyRentedByUser(
        tokenSeller[] storage listings,
        uint256 _tokenQuantity,
        address _sellerAddress
    ) {
        if (listings.length > 0) {
            uint256 index = getIndexOfArray(listings, _sellerAddress);
            if (listings[index].renterArray.length > 0) {
                tokenRenter[]  storage renters = listings[index].renterArray;
                uint256 indexRenter = getIndexOfRenterArray(
                    renters,
                    msg.sender
                );
                if (renters[indexRenter].tokenQuantityRented < _tokenQuantity) {
                    revert ItemNotRentedByUser(
                        _tokenQuantity,
                        _sellerAddress,
                        msg.sender
                    );
                }
            } else {
                revert NoRenterWithAddressForNftAndSellerAddress(
                    _sellerAddress,
                    msg.sender
                );
            }
        } else {
            revert NoSellersForThisAddressTokenId();
        }
        _;
    }

    modifier notAlreadyRentedSeller(
        tokenSeller[] storage listings,
        uint256 _tokenQuantity,
        address _sellerAddress
    ) {

        if (listings.length > 0) {
            //uint256 index = getIndexOfArray(listings, _sellerAddress);
            tokenSeller storage tokenSellerStorage = listings[getIndexOfArray(listings, _sellerAddress)];
            if (
                tokenSellerStorage.tokenQuantity < 1
            ) {
                revert ItemAlreadyRented();
            } else if (
                tokenSellerStorage.tokenQuantity <
                _tokenQuantity
            ) {
                revert ItemAlreadyRented();
            }
        } else {
            revert NoSellersForThisAddressTokenId();
        }
        _;
    }


    function listItemForRent(
        NFTStandard _nftStandard,
        uint256 _tokenId,
        uint256 _price,
        address _nftAddress,
        uint256 _tokenQuantity,
        uint256 _maxRentDuration
    )
        external
        notListedForRent(_nftStandard,_nftAddress, _tokenId, _tokenQuantity)
    {
        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        if (_maxRentDuration < 1) {
            revert DurationMustBeAtleastOneDay();
        }

        if(_nftStandard == NFTStandard.E721){
            require(_tokenQuantity == 1, "This NFT standard supports only 1 listing");
            IERC721 nft = IERC721(_nftAddress);
            address owner = nft.ownerOf(_tokenId);
            require(owner == msg.sender, "You Do not own the NFT");

        }else if(_nftStandard == NFTStandard.E1155){
            IERC1155 nft = IERC1155(_nftAddress);
            uint256 ownerAmount = nft.balanceOf(msg.sender, _tokenId);
            require(ownerAmount >= _tokenQuantity, "Not enough tokens owned by Address"); 
        }

        tokenSeller storage tokenSellerStorage = allNftContractListings[_nftAddress][_tokenId].push();

        tokenSellerStorage.nftStandard = _nftStandard;
        tokenSellerStorage.sellerAddress = msg.sender;
        tokenSellerStorage.tokenQuantity = _tokenQuantity;
        tokenSellerStorage.pricePerDay = _price;
        tokenSellerStorage.maxRentDuration = _maxRentDuration;
        tokenSellerStorage.tokenQuantityAlreadyRented = 0;
        //tokenSellerStorage.renterArray = new tokenRenter[](0);
 

        emit ItemListedForRent(
            msg.sender,
            _nftAddress,
            _tokenId,
            _nftStandard,
            _tokenQuantity,
            _price,
            _maxRentDuration
        );
    }

    function  updateListedItemForRent(    
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price,
        uint256 _tokenQuantity,
        uint256 _maxRentDuration
    )
     external 
     isListedForRent(
         allNftContractListings[
            _nftAddress
        ][_tokenId],
        _tokenQuantity)
    {
        require(_price > 0, "Price for listing should be greater than Zero");
        require(_maxRentDuration >= 1, "Max rent duration should be greater than or equal to 1");

        tokenSeller[] storage listings = allNftContractListings[_nftAddress][_tokenId];
        uint index = getIndexOfArray(listings, msg.sender);


        if(_nftStandard == NFTStandard.E721){
            require(_tokenQuantity == 1, "This NFT standard supports only 1 listing");
        }else if(_nftStandard == NFTStandard.E1155){
            IERC1155 nft = IERC1155(_nftAddress);
            uint256 ownerAmount = nft.balanceOf(msg.sender, _tokenId);
            require(ownerAmount >= listings[index].tokenQuantityAlreadyRented + _tokenQuantity,"Not Enough tokens owned by address");
        }

        tokenSeller storage tokenSellerStorage = listings[index];

        tokenSellerStorage.tokenQuantity = _tokenQuantity;
        tokenSellerStorage.pricePerDay = _price;
        tokenSellerStorage.maxRentDuration = _maxRentDuration;

        emit UpdateItemlisted(
            msg.sender,
            _nftAddress,
            _tokenId,
            _nftStandard,
            _tokenQuantity,
            _price,
            _maxRentDuration
        );
    }

    function delistItemsFromRent(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity
    )
        external
         notAlreadyRentedSeller(
            allNftContractListings[
            _nftAddress
        ][_tokenId],
            _tokenQuantity,
            msg.sender
        )
    {

        if(_nftStandard == NFTStandard.E721){
            require(_tokenQuantity == 1, "This NFT standard supports only 1 listing");
            IERC721 nft = IERC721(_nftAddress);
            address owner = nft.ownerOf(_tokenId);
            require(owner == msg.sender, "You Do not own the NFT");

        }else if(_nftStandard == NFTStandard.E1155){
            IERC1155 nft = IERC1155(_nftAddress);
            uint256 ownerAmount = nft.balanceOf(msg.sender, _tokenId);
            require(ownerAmount > _tokenQuantity, "Not enough tokens owned by Address"); 
        }

        tokenSeller[] storage listings = allNftContractListings[
            _nftAddress
        ][_tokenId];
        uint256 index = getIndexOfArray(listings, msg.sender);
        tokenSeller storage tokenSellerStorage = listings[index];
        uint256 tokenNumber = tokenSellerStorage.tokenQuantity - _tokenQuantity;
        if (tokenNumber == 0) {
            //delete from storage the listing
            removeListing(listings,index);
        } else {
            tokenSellerStorage.tokenQuantity =
                tokenSellerStorage.tokenQuantity -
                _tokenQuantity;
        }
        emit ItemDeListed(
            msg.sender,
            _nftAddress,
            _tokenId,
            _nftStandard,
            _tokenQuantity
        );
    }

    function rentItem(
        NFTStandard _nftStandard,
        uint256 _duration,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        address _sellerAddress
    )
        external
        payable
        notAlreadyRentedSeller(
            allNftContractListings[
            _nftAddress
        ][_tokenId],
            _tokenQuantity,
            _sellerAddress
        )
    {
        if(_nftStandard == NFTStandard.E721){
            require(_tokenQuantity == 1, "Token Quantity cannot be greater than 1 for ERC721 Standard");
        }

        tokenSeller[] storage listings = allNftContractListings[
            _nftAddress
        ][_tokenId];
        uint256 index = getIndexOfArray(listings, _sellerAddress);

        tokenSeller storage tokenSellerStorage = listings[index];
        require(
            tokenSellerStorage.tokenQuantity -
                tokenSellerStorage.tokenQuantityAlreadyRented >=
                _tokenQuantity,
            "Specifed token amount is not rented"
        );
        if (_duration > tokenSellerStorage.maxRentDuration) {
            revert DurationMustBeLessThanOrEqualTomaxRentDuration();
        }
        if (msg.sender == _sellerAddress) {
            revert cantRentOwnedNfts(_tokenId, msg.sender, _nftAddress);
        }
        if (_duration < 1) {
            revert DurationMustBeAtleastOneDay();
        }
        if (msg.value < tokenSellerStorage.pricePerDay * _duration*_tokenQuantity) {
            revert PriceNotMet(
                _nftAddress,
                _tokenId,
                tokenSellerStorage.pricePerDay
            );
        }
        updateRentItemStorage(tokenSellerStorage, _tokenQuantity,_duration);

        s_proceeds[_sellerAddress] = msg.value;


        emit ItemRented(
            msg.sender,
            _nftAddress,
            _tokenId,
            _nftStandard,
            _tokenQuantity,
            _sellerAddress,
            tokenSellerStorage.pricePerDay
            //_duration
        );
    }

//Supporting the rentItem function 
function updateRentItemStorage(tokenSeller storage tokenSellerStorage,uint _tokenQuantity, uint _duration) private {

        //tokenSeller storage tokenSellers = tokenSellerStorage;

        tokenRenter memory renterDetails;
        renterDetails.renterAddress = msg.sender;
        renterDetails.rentedDuration = _duration;
        renterDetails.tokenQuantityRented += _tokenQuantity;

        tokenSellerStorage.tokenQuantity =
            tokenSellerStorage.tokenQuantity - _tokenQuantity;


        tokenSellerStorage.tokenQuantityAlreadyRented =
            tokenSellerStorage.tokenQuantityAlreadyRented +
            _tokenQuantity;

        tokenSellerStorage.renterArray.push(renterDetails);
}

//delete it later
   function withdrawProceeds(address _sellerAddress) internal {
        uint256 proceeds = s_proceeds[_sellerAddress];
        if (proceeds <= 0) {
            revert NoProceeds();
        }
        s_proceeds[_sellerAddress] = 0;

        (bool success, ) = payable(_sellerAddress).call{value: proceeds}("");
        require(success, "Transfer failed");
    }


    function returnNftFromRent(
        NFTStandard _nftStandard,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenQuantity,
        address _sellerAddress
    )
        external
        isCurrentlyRentedByUser(
           allNftContractListings[_nftAddress][
            _tokenId
        ],
            _tokenQuantity,
            _sellerAddress
        )
    {
        if(_nftStandard == NFTStandard.E721){
            require(_tokenQuantity == 1, "Token Quantity cannot be greater than 1 for ERC721 Standard");
        }

        tokenSeller[] storage listings = allNftContractListings[
            _nftAddress
        ][_tokenId];
        uint256 index = getIndexOfArray(listings, _sellerAddress);
        tokenSeller storage tokenSellerStorage = listings[index];
        uint256 renterIndex = getIndexOfRenterArray(
            tokenSellerStorage.renterArray,
            msg.sender
        );


        tokenSellerStorage.tokenQuantity =
            tokenSellerStorage.tokenQuantity +
            _tokenQuantity;

        tokenSellerStorage.tokenQuantityAlreadyRented =
            tokenSellerStorage.tokenQuantityAlreadyRented -
            _tokenQuantity;

        tokenSellerStorage.renterArray[renterIndex].tokenQuantityRented =
            tokenSellerStorage.renterArray[renterIndex].tokenQuantityRented -
            _tokenQuantity;

        withdrawProceeds(_sellerAddress);

        emit ItemReturned(
            msg.sender,
            _nftAddress,
            _tokenId,
            _nftStandard,
            _tokenQuantity,
            _sellerAddress,
            tokenSellerStorage.pricePerDay,
            tokenSellerStorage.renterArray[renterIndex].rentedDuration
        );
    
    }


    function getIndexOfArray(
        tokenSeller[] storage sellerArray,
        address _sellerAddress
    ) internal view returns (uint256) {
        uint256 index;
        bool value = false;
        for (uint256 i = 0; i < sellerArray.length; i++) {
            if (sellerArray[i].sellerAddress == _sellerAddress) {
                index = i;
                value = true;
            }
        }
        if(value == false){
            revert NoSuchListing();
        }
        return index;
    }

    function getIndexOfRenterArray(
        tokenRenter[] storage sellerArray,
        address _sellerAddress
    ) internal view returns (uint256) {
        uint256 index;
        bool value = false;
        for (uint256 i = 0; i < sellerArray.length; i++) {
            if (sellerArray[i].renterAddress == _sellerAddress) {
                index = i;
            }
        }
        if(value == false){
            revert NoSuchListing();
        }
        return index;
    }

    function removeListing(tokenSeller[] storage sellerArray, uint256 _index)
        internal
    {
        sellerArray[_index] = sellerArray[sellerArray.length - 1];
        sellerArray.pop();
    }

    function removeRenterListing(
        tokenRenter[] storage renterArray,
        uint256 _index
    ) internal {
        renterArray[_index] = renterArray[renterArray.length - 1];
        renterArray.pop();
    }

    fallback() payable external {}

    receive() external payable {
            // React to receiving ether
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