// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error PriceNotMet(address nftAddress, uint256 tokenId, uint256 price);
error ItemAlreadyRented(
);
error NotListedForRent(address nftAddress, uint256 tokenId);
error NoSellersForThisAddressTokenId();
error NotEnoughTokensListed(
    address nftAddress,
    uint256 tokenId,
    uint256 tokenAmount
);
error AlreadyListedForRent(
    address nftAddress,
    uint256 tokenId,
    uint256 tokenAmount
);
error ItemNotRentedByUser(
    address nftAddress,
    uint256 tokenId,
    uint256 tokenAmount,
    address sellerAddress,
    address renterAddress
);
error cantRentOwnedNfts(uint256 tokenId, address spender, address nftAddress);
error NoRenterWithAddressForNftAndSellerAddress(
    address nftAddress,
    uint256 tokenId,
    address sellerAddress,
    address renterAddress
);

error PriceMustBeAboveZero();
error NotOwner();
error NoProceeds();
error NFTdoesNotExist(); //newly added
error DurationMustBeAtleastOneDay();
error DurationMustBeLessThanOrEqualTomaxRentDuration();

contract lyncRent1155 is ReentrancyGuard {
    struct tokenRenter {
        address renterAddress;
        uint256 tokenAmountRented;
        uint256 rentedDuration;
    }
    struct tokenSeller {
        address sellerAddress;
        uint256 tokenAmount; //listed quty of NFT
        uint256 pricePerDay;
        uint256 maxRentDuration;
        uint256 tokenAmountAlreadyRented; //Already rented
        tokenRenter[]  renterArray;
    }

  
    mapping(address => tokenSeller) sellerTempMappings;
    //mapping(address => tokenRenter) renterTempMapping;

    event ItemListedForRent(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 tokenAmount,
        uint256 pricePerDay,
        uint256 maxRentDuration
    );

    event ItemRented(
        address indexed renter,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 tokenAmount,
        address sellerAddress,
        uint256 price
        //uint256 duration //no of days
    );

    event ItemReturned(
        address indexed renter,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 tokeenAmount,
        address sellerAddress,
        uint256 price,
        uint256 duration //no of days
    );

    event ItemDeListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 tokenAmount
    );

    mapping(address => mapping(uint256 => tokenSeller[]))
        public allNftContractListings; //listings per nftaddress based on tokenids
    mapping(address => uint256) private s_proceeds;

    modifier notListedForRent(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenAmount
    ) {
        tokenSeller[] storage listings = allNftContractListings[_nftAddress][
            _tokenId
        ];

        if (listings.length != 0) {
            IERC1155 nft = IERC1155(_nftAddress);
            uint256 index = getIndexOfArray(listings, msg.sender);
            uint256 ownerAmount = nft.balanceOf(msg.sender, _tokenId);
            uint256 listingAllowed = ownerAmount - listings[index].tokenAmount;
            if (listingAllowed < _tokenAmount) {
                revert AlreadyListedForRent(
                    _nftAddress,
                    _tokenId,
                    _tokenAmount
                );
            } 
        }
        _;
    }
    modifier isCurrentlyRentedByUser(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        address _sellerAddress
    ) {
        tokenSeller[] storage listings = allNftContractListings[_nftAddress][
            _tokenId
        ];
        if (listings.length > 0) {
            uint256 index = getIndexOfArray(listings, _sellerAddress);
            if (listings[index].renterArray.length > 0) {
                tokenRenter[]  storage renters = listings[index].renterArray;
                uint256 indexRenter = getIndexOfRenterArray(
                    renters,
                    msg.sender
                );
                if (renters[indexRenter].tokenAmountRented < _tokenAmount) {
                    revert ItemNotRentedByUser(
                        _nftAddress,
                        _tokenId,
                        _tokenAmount,
                        _sellerAddress,
                        msg.sender
                    );
                }
            } else {
                revert NoRenterWithAddressForNftAndSellerAddress(
                    _nftAddress,
                    _tokenId,
                    _sellerAddress,
                    msg.sender
                );
            }
        } else {
            revert NoSellersForThisAddressTokenId();
        }
        _;
    }

    // modifier notAlreadyRented(
    //     address _nftAddress,
    //     uint256 _tokenId,
    //     uint256 _tokenAmount
    // ) {
    //     tokenSeller[] storage listings = allNftContractListings[_nftAddress][
    //         _tokenId
    //     ];
    //     if (listings.length > 0) {
    //         uint256 index = getIndexOfArray(listings, msg.sender);
    //         if (
    //             listings[index].tokenAmountAlreadyRented ==
    //             listings[index].tokenAmount
    //         ) {
    //             revert ItemAlreadyRented(_nftAddress, _tokenId, msg.sender);
    //         } else if (
    //             listings[index].tokenAmount -
    //                 listings[index].tokenAmountAlreadyRented <
    //             _tokenAmount
    //         ) {
    //             revert ItemAlreadyRented(_nftAddress, _tokenId, msg.sender);
    //         }
    //     } else {
    //         revert NoSellersForThisAddressTokenId(_nftAddress, _tokenId);
    //     }
    //     _;
    // }

    modifier notAlreadyRentedSeller(
        // address _nftAddress,
        // uint256 _tokenId,
        tokenSeller[] storage listings,
        uint256 _tokenAmount,
        address _sellerAddress
    ) {
        // tokenSeller[] storage listings = allNftContractListings[_nftAddress][
        //     _tokenId
        // ];
        if (listings.length > 0) {
            //uint256 index = getIndexOfArray(listings, _sellerAddress);
            tokenSeller storage tokenSellerStorage = listings[getIndexOfArray(listings, _sellerAddress)];
            if (
                tokenSellerStorage.tokenAmountAlreadyRented ==
                tokenSellerStorage.tokenAmount
            ) {
                revert ItemAlreadyRented();
            } else if (
                tokenSellerStorage.tokenAmount -
                    tokenSellerStorage.tokenAmountAlreadyRented <
                _tokenAmount
            ) {
                revert ItemAlreadyRented();
            }else{
                _;
            }
        } else {
            revert NoSellersForThisAddressTokenId();
        }
        _;
    }


    // modifier isListedForRent(
    //     address _nftAddress,
    //     uint256 _tokenId,
    //     uint256 _tokenAmount
    //    // address _sellerAddress
    // ) {
    //     tokenSeller[] storage listings = allNftContractListings[_nftAddress][
    //         _tokenId
    //     ];
    //     if (listings.length > 0) {
    //         uint256 index = getIndexOfArray(listings, msg.sender);

    //         if (listings[index].tokenAmount < _tokenAmount) {
    //             revert NotEnoughTokensListed(
    //                 _nftAddress,
    //                 _tokenId,
    //                 _tokenAmount
    //             );
    //         }
    //     } else {
    //         revert NotListedForRent(_nftAddress, _tokenId);
    //     }
    //     _;
    // }

    // modifier isListedForRentSeller(
    //     tokenSeller[] storage listings,
    //     uint256 _tokenAmount,
    //     address _sellerAddress
    // ) {
    //     // tokenSeller[] storage listings = allNftContractListings[_nftAddress][
    //     //     _tokenId
    //     // ];
    //     if (listings.length > 0) {
    //         uint256 index = getIndexOfArray(listings, _sellerAddress);
    //         //tokenSeller storage tokenSellerStorage = listings[index];
    //         if (listings[index].tokenAmount < _tokenAmount) {
    //             // revert NotEnoughTokensListed(
    //             //     _nftAddress,
    //             //     _tokenId,
    //             //     _tokenAmount
    //             // );
    //         }
    //     } else {
    //         //revert NotListedForRent(_nftAddress, _tokenId);
    //     }
    //     _;
    // }

    function listItemForRent(
        uint256 _tokenId,
        uint256 _price,
        address _nftAddress,
        uint256 _tokenAmount,
        uint256 _maxRentDuration
    )
        external
        notListedForRent(_nftAddress, _tokenId, _tokenAmount)
    {

        IERC1155 nft = IERC1155(_nftAddress);

        uint256 ownerAmount = nft.balanceOf(msg.sender, _tokenId);
        require(ownerAmount > _tokenAmount, "only NFT owner can list the NFT");
        

        if (_price <= 0) {
            revert PriceMustBeAboveZero();
        }
        if (_maxRentDuration < 1) {
            revert DurationMustBeAtleastOneDay();
        }

        //tokenRenter[] storage _renterArray;

        // sellerDetails.tokenAmount = _tokenAmount;
        // sellerDetails.pricePerDay = _price;
        // sellerDetails.maxRentDuration = _maxRentDuration;
        // sellerDetails.tokenAmountAlreadyRented = 0;
        // //sellerDetails.renterArray = renterDetails;

        // // renterTempMapping = 0;
        // // sellerDetails.renterMapping = renterTempMapping;
        tokenSeller storage tokenSellerStorage = allNftContractListings[_nftAddress][_tokenId].push();

        tokenSellerStorage.sellerAddress = msg.sender;
        tokenSellerStorage.tokenAmount = _tokenAmount;
        tokenSellerStorage.pricePerDay = _price;
        tokenSellerStorage.maxRentDuration = _maxRentDuration;
        tokenSellerStorage.tokenAmountAlreadyRented = 0;
        //tokenSellerStorage.renterArray = new tokenRenter[](0);
 

        emit ItemListedForRent(
            msg.sender,
            _nftAddress,
            _tokenId,
            _tokenAmount,
            _price,
            _maxRentDuration
        );
    }

    function delistItemsFromRent(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount
    )
        external
        // isListedForRent(_nftContractAddress, _tokenId, _tokenAmount)
         notAlreadyRentedSeller(
            allNftContractListings[
            _nftContractAddress
        ][_tokenId],
            _tokenAmount,
            msg.sender
        )
    {

        IERC1155 nft = IERC1155(_nftContractAddress);

        uint256 ownerAmount = nft.balanceOf(msg.sender, _tokenId);
        require(ownerAmount > _tokenAmount, "only NFT owner can list the NFT");

        tokenSeller[] storage listings = allNftContractListings[
            _nftContractAddress
        ][_tokenId];
        uint256 index = getIndexOfArray(listings, msg.sender);
        tokenSeller storage tokenSellerStorage = listings[index];
        uint256 tokenNumber = tokenSellerStorage.tokenAmount - _tokenAmount;
        if (tokenNumber == 0) {
            //delete from storage the listing
        } else {
            tokenSellerStorage.tokenAmount =
                tokenSellerStorage.tokenAmount -
                _tokenAmount;
        }
        emit ItemDeListed(
            msg.sender,
            _nftContractAddress,
            _tokenId,
            _tokenAmount
        );
    }

    function rentItem(
        uint256 _duration,
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        address _sellerAddress
    )
        external
        payable
        notAlreadyRentedSeller(
            allNftContractListings[
            _nftContractAddress
        ][_tokenId],
            _tokenAmount,
            _sellerAddress
        )
    {
        tokenSeller[] storage listings = allNftContractListings[
            _nftContractAddress
        ][_tokenId];
        uint256 index = getIndexOfArray(listings, _sellerAddress);
        tokenSeller storage tokenSellerStorage = listings[index];
        require(
            tokenSellerStorage.tokenAmount -
                tokenSellerStorage.tokenAmountAlreadyRented >=
                _tokenAmount,
            "Specifed token amount is not rented"
        );
        if (_duration > tokenSellerStorage.maxRentDuration) {
            revert DurationMustBeLessThanOrEqualTomaxRentDuration();
        }
        if (msg.sender == _sellerAddress) {
            revert cantRentOwnedNfts(_tokenId, msg.sender, _nftContractAddress);
        }
        if (_duration < 1) {
            revert DurationMustBeAtleastOneDay();
        }
        if (msg.value < tokenSellerStorage.pricePerDay * _duration*_tokenAmount) {
            revert PriceNotMet(
                _nftContractAddress,
                _tokenId,
                tokenSellerStorage.pricePerDay
            );
        }

        //tokenSeller storage tokenSellers = tokenSellerStorage;

        tokenRenter memory renterDetails;
        renterDetails.renterAddress = msg.sender;
        renterDetails.rentedDuration = _duration;
        renterDetails.tokenAmountRented += 1;

        tokenSellerStorage.tokenAmount =
            tokenSellerStorage.tokenAmount;


        tokenSellerStorage.tokenAmountAlreadyRented =
            tokenSellerStorage.tokenAmountAlreadyRented +
            1;

        tokenSellerStorage.renterArray.push(renterDetails);

        s_proceeds[_sellerAddress] = msg.value;

        // payable(tokenSellerStorage.sellerAddress).transfer(msg.value);
        // require(success, "Failed to Send Ether");
        emit ItemRented(
            msg.sender,
            _nftContractAddress,
            _tokenId,
            _tokenAmount,
            _sellerAddress,
            tokenSellerStorage.pricePerDay
            //_duration
        );
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
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _tokenAmount,
        address _sellerAddress
    )
        external
        isCurrentlyRentedByUser(
            _nftContractAddress,
            _tokenId,
            _tokenAmount,
            _sellerAddress
        )
    {
        tokenSeller[] storage listings = allNftContractListings[
            _nftContractAddress
        ][_tokenId];
        uint256 index = getIndexOfArray(listings, _sellerAddress);
        tokenSeller storage tokenSellerStorage = listings[index];
        uint256 renterIndex = getIndexOfRenterArray(
            tokenSellerStorage.renterArray,
            msg.sender
        );


        tokenSellerStorage.tokenAmount =
            tokenSellerStorage.tokenAmount +
            _tokenAmount;

        tokenSellerStorage.tokenAmountAlreadyRented =
            tokenSellerStorage.tokenAmountAlreadyRented -
            _tokenAmount;

        tokenSellerStorage.renterArray[renterIndex].tokenAmountRented =
            tokenSellerStorage.renterArray[renterIndex].tokenAmountRented -
            _tokenAmount;

        withdrawProceeds(_sellerAddress);

        emit ItemReturned(
            msg.sender,
            _nftContractAddress,
            _tokenId,
            _tokenAmount,
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
        for (uint256 i = 0; i < sellerArray.length; i++) {
            if (sellerArray[i].sellerAddress == _sellerAddress) {
                index = i;
            }
        }
        return index;
    }

    function getIndexOfRenterArray(
        tokenRenter[] storage sellerArray,
        address _sellerAddress
    ) internal view returns (uint256) {
        uint256 index;
        for (uint256 i = 0; i < sellerArray.length; i++) {
            if (sellerArray[i].renterAddress == _sellerAddress) {
                index = i;
            }
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