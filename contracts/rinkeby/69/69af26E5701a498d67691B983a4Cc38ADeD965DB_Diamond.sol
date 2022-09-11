// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

pragma solidity 0.8.15;

import {OwnableStorage} from "../features/access/ownable/OwnableStorage.sol";
import {IERC173} from "../features/access/ownable/IERC173.sol";
import {IERC165, ERC165Storage} from "../features/introspection/ERC165.sol";
import {ERC2771Context} from "../features/metatx/ERC2771Context.sol";
import {IDiamondCut} from "../features/diamond/IDiamondCut.sol";
import {IDiamondLoupe} from "../features/diamond/IDiamondLoupe.sol";

import {DiamondStorage} from "./DiamondStorage.sol";

contract Diamond {
    using ERC165Storage for ERC165Storage.Layout;
    using OwnableStorage for OwnableStorage.Layout;

    constructor(
        address owner,
        address diamondCutFacet,
        address diamondLoupeFacet,
        address erc165Facet,
        address ownableFacet,
        address contextFacet
    ) {
        ERC165Storage.Layout storage erc165 = ERC165Storage.layout();

        // register DiamondCut

        bytes4[] memory selectorsDiamondCut = new bytes4[](1);
        selectorsDiamondCut[0] = IDiamondCut.diamondCut.selector;

        erc165.setSupportedInterface(type(IDiamondCut).interfaceId, true);

        // register DiamondLoupe

        bytes4[] memory selectorsDiamondLoupe = new bytes4[](4);
        selectorsDiamondLoupe[0] = IDiamondLoupe.facets.selector;
        selectorsDiamondLoupe[1] = IDiamondLoupe
            .facetFunctionSelectors
            .selector;
        selectorsDiamondLoupe[2] = IDiamondLoupe.facetAddresses.selector;
        selectorsDiamondLoupe[3] = IDiamondLoupe.facetAddress.selector;

        erc165.setSupportedInterface(type(IDiamondLoupe).interfaceId, true);

        // register ERC165 (supportsInterface)

        bytes4[] memory selectorsERC165 = new bytes4[](1);
        selectorsERC165[0] = IERC165.supportsInterface.selector;

        erc165.setSupportedInterface(type(IERC165).interfaceId, true);

        // register ERC173 (Ownable)

        bytes4[] memory selectorsOwnable = new bytes4[](2);
        selectorsOwnable[0] = IERC173.owner.selector;
        selectorsOwnable[1] = IERC173.transferOwnership.selector;

        erc165.setSupportedInterface(type(IERC173).interfaceId, true);

        // register ERC2771 (Context)

        bytes4[] memory selectorsContext = new bytes4[](2);
        selectorsContext[0] = ERC2771Context.setTrustedForwarder.selector;
        selectorsContext[1] = ERC2771Context.isTrustedForwarder.selector;

        // execute the first ever diamond cut
        // we are calling the addFunctions directly to save ~ %50 gas

        DiamondStorage.addFunctions(diamondCutFacet, selectorsDiamondCut);
        DiamondStorage.addFunctions(diamondLoupeFacet, selectorsDiamondLoupe);
        DiamondStorage.addFunctions(erc165Facet, selectorsERC165);
        DiamondStorage.addFunctions(ownableFacet, selectorsOwnable);
        DiamondStorage.addFunctions(contextFacet, selectorsContext);

        // set owner

        OwnableStorage.layout().setOwner(owner);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        DiamondStorage.Layout storage l;
        bytes32 position = DiamondStorage.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            l.slot := position
        }

        // get facet from function selector
        address facet = l.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "BAD_FUNC");

        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../features/diamond/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error DiamondFacetAlreadyExists(address facet, bytes4 selector);
error DiamondFacetSameFunction(address facet, bytes4 selector);

library DiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct Layout {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            l.slot := position
        }
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
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
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        // require(
        //     _functionSelectors.length > 0,
        //     "LibDiamondCut: No selectors in facet to cut"
        // );
        Layout storage l = layout();
        // require(
        //     _facetAddress != address(0),
        //     "LibDiamondCut: Add facet can't be address(0)"
        // );
        uint96 selectorPosition = uint96(
            l.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(l, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = l
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            if (oldFacetAddress != address(0)) {
                revert DiamondFacetAlreadyExists(oldFacetAddress, selector);
            }

            addFunction(l, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        // require(
        //     _functionSelectors.length > 0,
        //     "LibDiamondCut: No selectors in facet to cut"
        // );
        Layout storage l = layout();
        // require(
        //     _facetAddress != address(0),
        //     "LibDiamondCut: Add facet can't be address(0)"
        // );
        uint96 selectorPosition = uint96(
            l.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(l, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = l
                .selectorToFacetAndPosition[selector]
                .facetAddress;

            if (oldFacetAddress == _facetAddress) {
                revert DiamondFacetSameFunction(oldFacetAddress, selector);
            }

            removeFunction(l, oldFacetAddress, selector);
            addFunction(l, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        // require(
        //     _functionSelectors.length > 0,
        //     "LibDiamondCut: No selectors in facet to cut"
        // );
        Layout storage l = layout();
        // if function does not exist then do nothing and return
        // require(
        //     _facetAddress == address(0),
        //     "LibDiamondCut: Remove facet address must be address(0)"
        // );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = l
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(l, oldFacetAddress, selector);
        }
    }

    function addFacet(Layout storage l, address _facetAddress) internal {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        l.facetFunctionSelectors[_facetAddress].facetAddressPosition = l
            .facetAddresses
            .length;
        l.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        Layout storage l,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        l
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        l.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        l.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        Layout storage l,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        // require(
        //     _facetAddress != address(0),
        //     "LibDiamondCut: Can't remove function that doesn't exist"
        // );
        // an immutable function is a function defined directly in a diamond
        // require(
        //     _facetAddress != address(this),
        //     "LibDiamondCut: Can't remove immutable function"
        // );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = l
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = l
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = l
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            l.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            l
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        l.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete l.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = l.facetAddresses.length - 1;
            uint256 facetAddressPosition = l
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = l.facetAddresses[
                    lastFacetAddressPosition
                ];
                l.facetAddresses[facetAddressPosition] = lastFacetAddress;
                l
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            l.facetAddresses.pop();
            delete l.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IERC173Events} from "./IERC173Events.sol";

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Events {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title Contract ownership standard interface (event only)
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173Events {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {OwnableStorage} from "./OwnableStorage.sol";
import {IERC173Events} from "./IERC173Events.sol";

abstract contract OwnableInternal is IERC173Events {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(msg.sender == _owner(), "Ownable: sender must be owner");
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("openzeppelin.contracts.storage.Ownable");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
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

pragma solidity 0.8.15;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IERC165} from "./IERC165.sol";
import {ERC165Storage} from "./ERC165Storage.sol";

/**
 * @title ERC165 implementation
 */
contract ERC165 is IERC165 {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("openzeppelin.contracts.storage.ERC165");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(Layout storage l, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {ERC2771ContextStorage} from "./ERC2771ContextStorage.sol";
import {ERC2771ContextInternal} from "./ERC2771ContextInternal.sol";
import {OwnableInternal} from "../access/ownable/OwnableInternal.sol";

contract ERC2771Context is ERC2771ContextInternal, OwnableInternal {
    function setTrustedForwarder(address trustedForwarder) public onlyOwner {
        ERC2771ContextStorage.layout().trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return _isTrustedForwarder(forwarder);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";

import {ERC2771ContextStorage} from "./ERC2771ContextStorage.sol";

abstract contract ERC2771ContextInternal is Context {
    function _isTrustedForwarder(address operator)
        internal
        view
        returns (bool)
    {
        return ERC2771ContextStorage.layout().trustedForwarder == operator;
    }

    function _msgSender()
        internal
        view
        virtual
        override
        returns (address sender)
    {
        if (_isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData()
        internal
        view
        virtual
        override
        returns (bytes calldata)
    {
        if (_isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

library ERC2771ContextStorage {
    struct Layout {
        address trustedForwarder;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("v1.flair.contracts.storage.ERC2771Context");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}