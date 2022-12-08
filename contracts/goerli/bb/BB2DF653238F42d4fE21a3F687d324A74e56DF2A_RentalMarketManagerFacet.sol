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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    error InValidFacetCutAction();
    error NotDiamondOwner();
    error NoSelectorsInFacet();
    error NoZeroAddress();
    error SelectorExists(bytes4 selector);
    error SameSelectorReplacement(bytes4 selector);
    error MustBeZeroAddress();
    error NoCode();
    error NonExistentSelector(bytes4 selector);
    error ImmutableFunction(bytes4 selector);
    error NonEmptyCalldata();
    error EmptyCalldata();
    error InitCallFailed();
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner) revert NotDiamondOwner();
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert InValidFacetCutAction();
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) revert SelectorExists(selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            if (oldFacetAddress == _facetAddress) revert SameSelectorReplacement(selector);
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        if (_facetAddress != address(0)) revert MustBeZeroAddress();
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress);
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (_facetAddress == address(0)) revert NonExistentSelector(_selector);
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) revert ImmutableFunction(_selector);
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                lastSelectorPosition
            ];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                selectorPosition
            ] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(
                selectorPosition
            );
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            if (_calldata.length > 0) revert NonEmptyCalldata();
        } else {
            if (_calldata.length == 0) revert EmptyCalldata();
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitCallFailed();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize <= 0) revert NoCode();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "../storage/AppStorage.sol";
import "./SafeMath.sol";

library RentalStorageLib {
    bytes32 internal constant RENTAL = keccak256("rental.lib.storage");

    function getStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = RENTAL;
        assembly {
            s.slot := position
        }
    }

    function setRentalStorage(
        uint256 _tokenType,
        address _collection,
        address _user,
        uint256 _tokenId,
        uint256 _priceperday,
        uint256 _collateral,
        uint256 _expires,
        bool _vaild
    ) internal {
        AppStorage storage s = getStorage();
        s.cs._collection[_collection]._users[_tokenId].tokenType = _tokenType;
        s.cs._collection[_collection]._users[_tokenId].user = _user;
        s.cs._collection[_collection]._users[_tokenId].collateral = _collateral;
        s.cs._collection[_collection]._users[_tokenId].priceperday = _priceperday;
        s.cs._collection[_collection]._users[_tokenId].expires = _expires;
        s.cs._collection[_collection]._users[_tokenId].vaild = _vaild;
    }

    function setReturned(address _collection, uint256 _tokenId, bool _returned) internal {
        AppStorage storage s = getStorage();
        s.cs._collection[_collection]._users[_tokenId].returned = _returned;
    }

    function setClaimed(
        address _collection,
        uint256 _tokenId,
        uint256 collateralClaimed
    ) internal {
        AppStorage storage s = getStorage();
        s.cs._collection[_collection]._users[_tokenId].collateralClaimed = collateralClaimed;
    }

    function setToBeClaimed(
        address _collection,
        uint256 _tokenId,
        uint256 _collateralToBeClaimed
    ) internal {
        AppStorage storage s = getStorage();
        s
            .cs
            ._collection[_collection]
            ._users[_tokenId]
            .collateralToBeClaimed = _collateralToBeClaimed;
    }

    function setMarketRevenueBalance(uint256 _Revenue) internal {
        AppStorage storage s = getStorage();
        s.rms.marketRevenueBalance += _Revenue;
    }

    function setRenterStorage(
        address _collection,
        address _renter,
        uint256 _tokenId,
        uint256 _rentingexpires,
        bool _rentOfReturn
    ) internal {
        AppStorage storage s = getStorage();
        s.cs._collection[_collection]._users[_tokenId].renter = _renter;
        s.cs._collection[_collection]._users[_tokenId].rentingexpires = _rentingexpires;
        s.cs._collection[_collection]._users[_tokenId].renting = _rentOfReturn;
    }

    function setMartketStorage(bool removeOrAdd, uint256 quanlity) internal {
        AppStorage storage s = getStorage();
        if (removeOrAdd == true) {
            s.rms.marketBalance += quanlity;
        } else {
            s.rms.marketBalance = s.rms.marketBalance - quanlity;
        }
    }

    function getRentalDetails(
        address _collection,
        uint256 _tokenId
    )
        internal
        view
        returns (
            address _user,
            uint256 _collateral,
            uint256 _expires,
            uint256 _priceperday,
            bool _vaild,
            bool _renting
        )
    {
        AppStorage storage s = getStorage();

        return (
            s.cs._collection[_collection]._users[_tokenId].user,
            s.cs._collection[_collection]._users[_tokenId].collateral,
            s.cs._collection[_collection]._users[_tokenId].expires,
            s.cs._collection[_collection]._users[_tokenId].priceperday,
            s.cs._collection[_collection]._users[_tokenId].vaild,
            s.cs._collection[_collection]._users[_tokenId].renting
        );
    }

    function getRenterDetails(
        address _collection,
        uint256 _tokenId
    ) internal view returns (address _renter, uint256 _rentingexpires) {
        AppStorage storage s = getStorage();
        if (s.cs._collection[_collection]._users[_tokenId].renting == true) {
            return (
                s.cs._collection[_collection]._users[_tokenId].renter,
                s.cs._collection[_collection]._users[_tokenId].rentingexpires
            );
        } else {
            return (address(0), 0);
        }
    }

    function getCollateralDetails(
        address _collection,
        uint256 _tokenId
    )
        internal
        view
        returns (bool returned, uint256 _collateralClaimed, uint256 _collateralToBeClaimed)
    {
        AppStorage storage s = getStorage();
        if (s.cs._collection[_collection]._users[_tokenId].renting == true) {
            return (
                s.cs._collection[_collection]._users[_tokenId].returned,
                s.cs._collection[_collection]._users[_tokenId].collateralClaimed,
                s.cs._collection[_collection]._users[_tokenId].collateralToBeClaimed
            );
        } else {
            return (
                s.cs._collection[_collection]._users[_tokenId].returned,
                s.cs._collection[_collection]._users[_tokenId].collateralClaimed,
                s.cs._collection[_collection]._users[_tokenId].collateralToBeClaimed
            );
        }
    }

    function getLeftCollateral(
        address _collection,
        uint256 _tokenId
    ) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        if (s.cs._collection[_collection]._users[_tokenId].renting == true) {
            uint256 rentingexpires = s.cs._collection[_collection]._users[_tokenId].rentingexpires;
            uint256 collateral = s.cs._collection[_collection]._users[_tokenId].collateral;
            uint256 overDueSafeLine = 7200;
            uint256 overDueLimit = 604800;
            if (
                rentingexpires + overDueSafeLine <= block.timestamp &&
                block.timestamp <= rentingexpires + overDueLimit
            ) {
                uint256 overDueTime = block.timestamp - rentingexpires;
                uint256 overDueTimeLeft = overDueLimit - overDueTime;
                uint256 leftCollateralWhole = overDueTimeLeft * collateral;
                uint256 leftCollateral = SafeMath.div(leftCollateralWhole, overDueLimit);
                return (leftCollateral);
            } else if (block.timestamp > rentingexpires + 604800) {
                return (0);
            } else {
                return (collateral);
            }
        } else {
            return (0);
        }
    }

    function getClaimableCollateral(
        address _collection,
        uint256 _tokenId
    ) internal view returns (uint256) {
        AppStorage storage s = getStorage();
        if (s.cs._collection[_collection]._users[_tokenId].renting == true) {
            uint256 rentingexpires = s.cs._collection[_collection]._users[_tokenId].rentingexpires;
            uint256 collateral = s.cs._collection[_collection]._users[_tokenId].collateral;
            uint256 collateralClaimed = s
                .cs
                ._collection[_collection]
                ._users[_tokenId]
                .collateralClaimed;
            uint256 overDueSafeLine = 7200;
            uint256 overDueLimit = 604800;
            if (
                rentingexpires + overDueSafeLine <= block.timestamp &&
                block.timestamp <= rentingexpires + overDueLimit
            ) {
                uint256 overDueTime = block.timestamp - rentingexpires;
                uint256 collateralToClaimWhole = collateral * overDueTime;
                uint256 collateralToClaim = SafeMath.div(collateralToClaimWhole, overDueLimit);
                return (collateralToClaim - collateralClaimed);
            } else if (block.timestamp > rentingexpires + overDueLimit) {
                return (collateral - collateralClaimed);
            } else {
                return (0);
            }
        } else {
            return (0);
        }
    }

    function isRental(address _collection, uint256 _tokenId) internal view returns (bool) {
        AppStorage storage s = getStorage();
        if (s.cs._collection[_collection]._users[_tokenId].vaild == true) {
            return (true);
        } else {
            return (false);
        }
    }

    function isRenting(address _collection, uint256 _tokenId) internal view returns (bool) {
        AppStorage storage s = getStorage();
        if (s.cs._collection[_collection]._users[_tokenId].renting == true) {
            return (true);
        } else {
            return (false);
        }
    }

    function getMarketRevenueBalance() internal view returns (uint256) {
        AppStorage storage s = getStorage();
        return s.rms.marketRevenueBalance;
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.9;

import "./libraries/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./libraries/RentalStorage.sol";

error Not_Owner();
error Not_Approved();
error Can_NotRent();
error Not_EnoughCollateral();
error Not_EnoughTimeToRent();
error Not_EnoughPayment();
error Not_Created();
error You_DontHaveTheNftThatIsGoingToReturn();
error In_Renting();

contract RentalMarketManagerFacet {
    AppStorage s;

    modifier onlyOwner() {
        address _owner = owner();
        if (_owner != msg.sender) revert Not_Owner();
        _;
    }

    modifier noReentrant() {
        require(!s.locked, "Reentrancy Protection");
        s.locked = true;
        _;
        s.locked = false;
    }

    event RentalUpdated(
        address indexed collection,
        address user,
        uint256 indexed tokenId,
        uint256 indexed collateral,
        uint256 priceperday,
        uint256 expires
    );

    function listRental(
        uint256 tokenType,
        address collection,
        uint256 tokenId,
        uint256 collateral,
        uint256 priceperday,
        uint256 expiresInDays
    ) external {
        if (tokenType == 721) {
            (address a, ) = RentalStorageLib.getRenterDetails(collection, tokenId);
            if (a == address(0)) {
                if (IERC721(collection).ownerOf(tokenId) != msg.sender) revert Not_Owner();
                if (isRental(collection, tokenId) == true) revert Not_Created();
                if (IERC721(collection).isApprovedForAll(msg.sender, address(this)) == false)
                    revert Not_Approved();
                uint256 expires = block.timestamp + (expiresInDays * 86400);
                RentalStorageLib.setRentalStorage(
                    tokenType,
                    collection,
                    msg.sender,
                    tokenId,
                    priceperday,
                    collateral,
                    expires,
                    true
                );
                emit RentalUpdated(
                    collection,
                    msg.sender,
                    tokenId,
                    collateral,
                    priceperday,
                    expires
                );
            }
        }
        if (tokenType == 1155) {}
    }

    function updateRental(
        uint256 tokenType,
        address collection,
        uint256 tokenId,
        uint256 collateral,
        uint256 priceperday,
        uint256 expiresInDays
    ) external {
        if (tokenType == 721) {
            (address a, ) = RentalStorageLib.getRenterDetails(collection, tokenId);
            if (a == address(0)) revert In_Renting();
            if (IERC721(collection).ownerOf(tokenId) != msg.sender) revert Not_Owner();
            if (isRental(collection, tokenId) == false) revert Not_Created();
            if (IERC721(collection).isApprovedForAll(msg.sender, address(this)) == false)
                revert Not_Approved();
            uint256 expires = block.timestamp + (expiresInDays * 86400);
            RentalStorageLib.setRentalStorage(
                tokenType,
                collection,
                msg.sender,
                tokenId,
                priceperday,
                collateral,
                expires,
                true
            );
            emit RentalUpdated(collection, msg.sender, tokenId, collateral, priceperday, expires);
        }
        if (tokenType == 1155) {}
    }

    function rentRental(
        uint256 tokenType,
        address collection,
        uint256 tokenId,
        uint256 rentingPeirodInDays
    ) external payable noReentrant {
        if (tokenType == 721) {
            if (IERC721(collection).ownerOf(tokenId) == msg.sender) revert Can_NotRent();
            if (checkVaild(collection, tokenId, tokenType) == true) {
                (
                    address rentalowner,
                    uint256 collateral,
                    uint256 expires,
                    uint256 priceperday,
                    ,

                ) = RentalStorageLib.getRentalDetails(collection, tokenId);
                if (IERC721(collection).ownerOf(tokenId) != rentalowner) revert Can_NotRent();
                if (
                    rentingPeirodInDays > 0 &&
                    rentingPeirodInDays * 86400 + block.timestamp > expires
                ) revert Not_EnoughTimeToRent();
                if (msg.value < collateral) revert Not_EnoughCollateral();
                uint256 rentalFee = rentingPeirodInDays * priceperday;
                if (msg.value - collateral < rentalFee) revert Not_EnoughPayment();
                uint256 rentingexpires = block.timestamp + (rentingPeirodInDays * 86400);
                RentalStorageLib.setRenterStorage(
                    collection,
                    msg.sender,
                    tokenId,
                    rentingexpires,
                    true
                );
                uint256 afterCommission = calculateComssion(rentalFee);
                IERC721(collection).transferFrom(rentalowner, msg.sender, tokenId);
                (bool callSuccess, ) = payable(rentalowner).call{value: afterCommission}("");
                require(callSuccess, "Call failed");
            }
        }
        if (tokenType == 1155) {} else {}
    }

    function returnRental(
        uint256 tokenType,
        address collection,
        uint256 tokenId
    ) external noReentrant {
        if (tokenType == 721) {
            (address renter, ) = RentalStorageLib.getRenterDetails(collection, tokenId);
            if (IERC721(collection).ownerOf(tokenId) != msg.sender)
                revert You_DontHaveTheNftThatIsGoingToReturn();
            if (IERC721(collection).isApprovedForAll(msg.sender, address(this)) == false)
                revert Not_Approved();
            (address rentalowner, uint256 collateral, , , , ) = RentalStorageLib.getRentalDetails(
                collection,
                tokenId
            );
            if (renter != msg.sender) revert Not_Owner();
            IERC721(collection).transferFrom(msg.sender, rentalowner, tokenId);
            uint256 leftCollateral = RentalStorageLib.getLeftCollateral(collection, tokenId);
            if (collateral == leftCollateral) {
                (bool callSuccess, ) = payable(msg.sender).call{value: leftCollateral}("");
                require(callSuccess, "Call failed");
                RentalStorageLib.setRenterStorage(collection, address(0), tokenId, 0, false);
            } else {
                if (leftCollateral > 0) {
                    (bool callSuccess, ) = payable(msg.sender).call{value: leftCollateral}("");
                    require(callSuccess, "Call failed");
                }
                RentalStorageLib.setRenterStorage(collection, address(0), tokenId, 0, true);
                (, , uint256 collateralToBeClaimed) = RentalStorageLib.getCollateralDetails(
                    collection,
                    tokenId
                );
                RentalStorageLib.setToBeClaimed(
                    collection,
                    tokenId,
                    collateralToBeClaimed + collateral - leftCollateral
                );
            }
        }
        if (tokenType == 1155) {} else {}
    }

    function claimCollateral(address collection, uint256 tokenId) external noReentrant {
        (address rentalowner, , , , , ) = RentalStorageLib.getRentalDetails(collection, tokenId);
        (, uint256 collateralClaimed, uint256 collateralToBeClaimed) = RentalStorageLib
            .getCollateralDetails(collection, tokenId);
        if (msg.sender != rentalowner) revert Not_Owner();
        if (collateralToBeClaimed == 0) {
            uint256 collateralClaimable = RentalStorageLib.getClaimableCollateral(
                collection,
                tokenId
            );
            uint256 amountToClaim = collateralClaimable;
            if (amountToClaim == 0) revert Not_EnoughCollateral();
            RentalStorageLib.setClaimed(collection, tokenId, collateralClaimed + amountToClaim);
            (bool callSuccess, ) = payable(msg.sender).call{value: amountToClaim}("");
            require(callSuccess, "Call failed");
        } else {
            if (collateralToBeClaimed > collateralClaimed) {
                uint256 amountToClaim = collateralToBeClaimed - collateralClaimed;
                RentalStorageLib.setClaimed(collection, tokenId, collateralToBeClaimed);
                (bool callSuccess, ) = payable(msg.sender).call{value: amountToClaim}("");
                require(callSuccess, "Call failed");
                RentalStorageLib.setRenterStorage(collection, address(0), tokenId, 0, false);
            }
        }
    }

    function calculateComssion(uint256 rentalFee) internal pure returns (uint256) {
        uint256 commissionNumerator = 95;
        uint256 commissionDenominator = 100;
        return (rentalFee * commissionNumerator) / commissionDenominator;
    }

    function checkVaild(
        address collection,
        uint256 tokenId,
        uint256 tokenType
    ) internal returns (bool) {
        (
            address rentalowner,
            uint256 collateral,
            uint256 expires,
            uint256 priceperday,
            ,

        ) = RentalStorageLib.getRentalDetails(collection, tokenId);
        if (
            IERC721(collection).isApprovedForAll(rentalowner, address(this)) == true &&
            expires > block.timestamp
        ) {
            return (true);
        } else {
            RentalStorageLib.setRentalStorage(
                tokenType,
                collection,
                msg.sender,
                tokenId,
                priceperday,
                collateral,
                expires,
                false
            );
            return (false);
        }
    }

    function isRental(address collection, uint256 tokenId) public view returns (bool) {
        return RentalStorageLib.isRental(collection, tokenId);
    }

    function isRenting(address collection, uint256 tokenId) public view returns (bool) {
        return RentalStorageLib.isRenting(collection, tokenId);
    }

    function owner() internal view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./RentalMarketStorage.sol";
import "./VaultStorage.sol";
import "./UserStorage.sol";

struct AppStorage {
    NftCollectionStorage cs;
    UserStorage us;
    TokenInfo ui;
    RentalMarketStorage rms;
    VaultStorage vault;
    address owner;
    address vaultaddress;
    bool locked;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct RentalMarketStorage {
    uint256 marketBalance;
    uint256 marketLockedBalance;
    uint256 marketRevenueBalance;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct NftCollectionStorage {
    mapping(address => UserStorage) _collection;
}

struct UserStorage {
    mapping(uint256 => TokenInfo) _users;
}

struct TokenInfo {
    uint256 tokenType;
    address user;
    uint256 collateral;
    uint256 expires;
    uint256 priceperday;
    bool vaild;
    bool renting;
    address renter;
    uint256 rentingexpires;
    bool returned;
    uint256 collateralClaimed;
    uint256 collateralToBeClaimed;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

struct VaultStorage {
    mapping(address => ReclaimedHLP[]) stakers;
    //Total hlp in reclaiming state
    uint256 totalHlpBeingReclaimed;
}
struct ReclaimedHLP {
    uint256 reclaimedHlpAmount;
    uint256 redeemedHLPAmount;
    uint256 timeOfReclaim;
}