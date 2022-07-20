// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Diamond } from "../../diamond/Diamond.sol";
import { IDiamondWritable } from "../../diamond/writable/IDiamondWritable.sol";
import { ERC165Controller } from "../../core/introspection/ERC165Controller.sol";
import { IERC165 } from "../../core/introspection/IERC165.sol";
import { IERC721 } from "../../core/token/ERC721/IERC721.sol";

bytes constant DIAMOND_SELECTORS = abi.encode(1, IDiamondWritable.diamondCut.selector);
bytes constant ERC165_SELECTORS = abi.encode(1, IERC165.supportsInterface.selector);
bytes constant SUPPORTED_INTERFACES = abi.encode(
    2,
    type(IERC165).interfaceId,
    type(IERC721).interfaceId
);

/**
 * @title Mutytes diamond implementation facet
 */
contract MutytesDiamondFacet is Diamond, ERC165Controller {
    /**
     * @notice Initialize the diamond proxy
     * @param facetAddress The diamond facet address
     */
    function init(address facetAddress) external virtual onlyOwner {
        FacetCut[] memory facetCuts = new FacetCut[](2);
        facetCuts[0] = FacetCut(facetAddress, FacetCutAction.Add, _diamodSelectors());
        facetCuts[1] = FacetCut(address(this), FacetCutAction.Add, _erc165Selectors());
        _setSupportedInterfaces(_supportedInterfaces(), true);
        diamondCut_(facetCuts, address(0), "");
    }

    function _diamodSelectors()
        internal
        pure
        virtual
        returns (bytes4[] memory selectors)
    {
        return _ptrToBytes4Array(DIAMOND_SELECTORS);
    }

    function _erc165Selectors()
        internal
        pure
        virtual
        returns (bytes4[] memory selectors)
    {
        return _ptrToBytes4Array(ERC165_SELECTORS);
    }

    function _supportedInterfaces() internal pure virtual returns (bytes4[] memory) {
        return _ptrToBytes4Array(SUPPORTED_INTERFACES);
    }

    function _ptrToBytes4Array(bytes memory ptr)
        private
        pure
        returns (bytes4[] memory selectors)
    {
        assembly {
            selectors := add(ptr, 0x20)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamond } from "./IDiamond.sol";
import { DiamondController } from "./DiamondController.sol";
import { DiamondReadable } from "./readable/DiamondReadable.sol";
import { DiamondWritable } from "./writable/DiamondWritable.sol";

/**
 * @title Diamond read and write operations implementation
 */
contract Diamond is IDiamond, DiamondReadable, DiamondWritable, DiamondController {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondWritableController } from "./IDiamondWritableController.sol";

/**
 * @title DiamondWritable interface
 * @dev See https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondWritable is IDiamondWritableController {
    /**
     * @notice Add/replace/remove functions
     * @dev Executes a callback function if applicable
     * @param facetCuts The facet addresses and function selectors
     * @param init The callback address
     * @param data The callback function call
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address init,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC165Model } from "./ERC165Model.sol";

abstract contract ERC165Controller is ERC165Model {
    function supportsInterface_(bytes4 interfaceId) internal view virtual returns (bool) {
        return _supportsInterface(interfaceId);
    }

    function _setSupportedInterfaces(bytes4[] memory interfaceIds, bool isSupported)
        internal
        virtual
    {
        unchecked {
            for (uint256 i; i < interfaceIds.length; i++) {
                _setSupportedInterface(interfaceIds[i], isSupported);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface
 * @dev See https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice Query whether contract supports an interface
     * @param interfaceId The interface id
     * @return isSupported Whether the interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721Controller } from "./IERC721Controller.sol";

/**
 * @title ERC721 interface
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Controller {
    /**
     * @notice Get the balance of an owner
     * @param owner The owner's address
     * @return balance The balance amount
     */
    function balanceOf(address owner) external returns (uint256);

    /**
     * @notice Get the owner a token
     * @param tokenId The token id
     * @return owner The owner's address
     */
    function ownerOf(uint256 tokenId) external returns (address);

    /**
     * @notice Transfer a token between addresses
     * @dev Preforms ERC721Receiver check if applicable
     * @param from The token's owner address
     * @param to The recipient address
     * @param tokenId The token id
     * @param data Additional data
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @notice Transfer a token between addresses
     * @dev Preforms ERC721Receiver check if applicable
     * @param from The token's owner address
     * @param to The recipient address
     * @param tokenId The token id
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Transfer a token between addresses
     * @param from The token's owner address
     * @param to The recipient address
     * @param tokenId The token id
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @notice Grant approval to a token
     * @param approved The address to approve
     * @param tokenId The token id
     */
    function approve(address approved, uint256 tokenId) external;

    /**
     * @notice Set operator approval
     * @param operator The operator's address
     * @param approved Whether to grant approval
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @notice Get the approved address of a token
     * @param tokenId The token id
     * @return approved The approved address
     */
    function getApproved(uint256 tokenId) external returns (address);

    /**
     * @notice Query whether the operator is approved for an address
     * @param owner The address to query
     * @param operator The operator's address
     * @return isApproved Whether the operator is approved
     */
    function isApprovedForAll(address owner, address operator) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondReadable } from "./readable/IDiamondReadable.sol";
import { IDiamondWritable } from "./writable/IDiamondWritable.sol";

/**
 * @title Diamond read and write operations interface
 */
interface IDiamond is IDiamondReadable, IDiamondWritable {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondReadableController } from "./readable/DiamondReadableController.sol";
import { DiamondWritableController } from "./writable/DiamondWritableController.sol";

abstract contract DiamondController is
    DiamondReadableController,
    DiamondWritableController
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondReadable } from "./IDiamondReadable.sol";
import { DiamondReadableController } from "./DiamondReadableController.sol";

/**
 * @title Diamond read operations implementation
 */
contract DiamondReadable is IDiamondReadable, DiamondReadableController {
    /**
     * @inheritdoc IDiamondReadable
     */
    function facets() external view virtual returns (Facet[] memory) {
        return facets_();
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetFunctionSelectors(address facet)
        external
        view
        virtual
        returns (bytes4[] memory)
    {
        return facetFunctionSelectors_(facet);
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddresses() external view virtual returns (address[] memory) {
        return facetAddresses_();
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddress(bytes4 selector) external view virtual returns (address) {
        return facetAddress_(selector);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondWritable } from "./IDiamondWritable.sol";
import { DiamondWritableController } from "./DiamondWritableController.sol";

/**
 * @title Diamond write operations implementation
 */
contract DiamondWritable is IDiamondWritable, DiamondWritableController {
    /**
     * @inheritdoc IDiamondWritable
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address init,
        bytes calldata data
    ) external virtual onlyOwner {
        diamondCut_(facetCuts, init, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondReadableController } from "./IDiamondReadableController.sol";

/**
 * @title DiamondReadable interface
 * @dev See https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondReadable is IDiamondReadableController {
    /**
     * @notice Get all of the diamond facets
     * @return facets The facet addresses and their function selectors
     */
    function facets() external returns (Facet[] memory);

    /**
     * @notice Get the function selectors of a facet
     * @param facet The facet address
     * @return selectors The function selectors
     */
    function facetFunctionSelectors(address facet) external returns (bytes4[] memory);

    /**
     * @notice Get all of the diamond's facet addresses
     * @return facetAddresses The facet addresses
     */
    function facetAddresses() external returns (address[] memory);

    /**
     * @notice Get the facet that implements a selector
     * @param selector The function selector
     * @return facetAddress The facet address
     */
    function facetAddress(bytes4 selector) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial DiamondReadable interface required by controller functions
 */
interface IDiamondReadableController {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial DiamondWritable interface required by controller functions
 */
interface IDiamondWritableController {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    error UnexpectedFacetCutAction(FacetCutAction action);

    event DiamondCut(FacetCut[] diamondCut, address init, bytes data);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondReadableController } from "./IDiamondReadableController.sol";
import { DiamondReadableModel } from "./DiamondReadableModel.sol";
import { ProxyFacetedController } from "../../core/proxy/faceted/ProxyFacetedController.sol";

abstract contract DiamondReadableController is
    IDiamondReadableController,
    DiamondReadableModel,
    ProxyFacetedController
{
    function facets_() internal view virtual returns (Facet[] memory) {
        return _facets();
    }

    function facetFunctionSelectors_(address facet)
        internal
        view
        virtual
        returns (bytes4[] memory)
    {
        return _facetFunctionSelectors(facet);
    }

    function facetAddresses_() internal view virtual returns (address[] memory) {
        return _facetAddresses();
    }

    function facetAddress_(bytes4 selector) internal view virtual returns (address) {
        return _implementation(selector);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondWritableController } from "./IDiamondWritableController.sol";
import { ProxyFacetedController } from "../../core/proxy/faceted/ProxyFacetedController.sol";
import { OwnableController } from "../../core/access/ownable/OwnableController.sol";
import { AddressUtils } from "../../core/utils/AddressUtils.sol";
import { IntegerUtils } from "../../core/utils/IntegerUtils.sol";

abstract contract DiamondWritableController is
    IDiamondWritableController,
    ProxyFacetedController,
    OwnableController
{
    using AddressUtils for address;
    using IntegerUtils for uint256;

    function diamondCut_(
        FacetCut[] memory facetCuts,
        address init,
        bytes memory data
    ) internal virtual {
        unchecked {
            for (uint256 i; i < facetCuts.length; i++) {
                FacetCut memory facetCut = facetCuts[i];

                if (facetCut.action == FacetCutAction.Add) {
                    addFunctions_(
                        facetCut.functionSelectors,
                        facetCut.facetAddress,
                        false
                    );
                } else if (facetCut.action == FacetCutAction.Replace) {
                    replaceFunctions_(facetCut.functionSelectors, facetCut.facetAddress);
                } else if (facetCut.action == FacetCutAction.Remove) {
                    removeFunctions_(facetCut.functionSelectors);
                } else {
                    revert UnexpectedFacetCutAction(facetCut.action);
                }
            }
        }

        emit DiamondCut(facetCuts, init, data);
        initializeDiamondCut_(init, data);
    }

    function initializeDiamondCut_(address init, bytes memory data) internal virtual {
        if (init == address(0)) {
            data.length.enforceIsZero();
        } else {
            data.length.enforceIsNotZero();

            if (init != address(this)) {
                init.enforceIsContract();
            }

            _Proxy(init, data);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondReadable } from "./IDiamondReadable.sol";
import { proxyFacetedStorage, ProxyFacetedStorage } from "../../core/proxy/faceted/ProxyFacetedStorage.sol";

abstract contract DiamondReadableModel {
    function _facets()
        internal
        view
        virtual
        returns (IDiamondReadable.Facet[] memory facets)
    {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        facets = new IDiamondReadable.Facet[](ps.implementations.length);
        uint256[] memory current = new uint256[](facets.length);

        unchecked {
            for (uint256 i; i < facets.length; i++) {
                address facet = ps.implementations[i];
                uint256 selectorCount = ps.implementationInfo[facet].selectorCount;
                facets[i].facetAddress = facet;
                facets[i].functionSelectors = new bytes4[](selectorCount);
            }

            for (uint256 i; i < ps.selectors.length; i++) {
                bytes4 selector = ps.selectors[i];
                address facet = ps.selectorInfo[selector].implementation;
                uint256 position = ps.implementationInfo[facet].position;
                facets[position].functionSelectors[current[position]++] = selector;
            }
        }
    }

    function _facetFunctionSelectors(address facet)
        internal
        view
        virtual
        returns (bytes4[] memory selectors)
    {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        selectors = new bytes4[](ps.implementationInfo[facet].selectorCount);
        uint256 index;

        unchecked {
            for (uint256 i; index < selectors.length; i++) {
                bytes4 selector = ps.selectors[i];

                if (ps.selectorInfo[selector].implementation == facet) {
                    selectors[index++] = selector;
                }
            }
        }
    }

    function _facetAddresses() internal view virtual returns (address[] memory) {
        return proxyFacetedStorage().implementations;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ProxyFacetedModel } from "./ProxyFacetedModel.sol";
import { ProxyController } from "../ProxyController.sol";
import { AddressUtils } from "../../utils/AddressUtils.sol";

abstract contract ProxyFacetedController is ProxyFacetedModel, ProxyController {
    using AddressUtils for address;

    function implementation_() internal view virtual override returns (address) {
        return implementation_(msg.sig);
    }

    function implementation_(bytes4 selector)
        internal
        view
        virtual
        returns (address implementation)
    {
        implementation = _implementation(selector);
        implementation.enforceIsNotZeroAddress();
    }

    function addFunctions_(
        bytes4[] memory selectors,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        _enforceCanAddFunctions(implementation);

        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                bytes4 selector = selectors[i];
                _enforceCanAddFunction(selector, implementation);
                _addFunction_(selector, implementation, isUpgradable);
            }
        }
    }

    function addFunction_(
        bytes4 selector,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        _enforceCanAddFunctions(implementation);
        _enforceCanAddFunction(selector, implementation);
        _addFunction_(selector, implementation, isUpgradable);
    }

    function replaceFunctions_(bytes4[] memory selectors, address implementation)
        internal
        virtual
    {
        _enforceCanAddFunctions(implementation);

        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                bytes4 selector = selectors[i];
                _enforceCanReplaceFunction(selector, implementation);
                _replaceFunction_(selector, implementation);
            }
        }
    }

    function replaceFunction_(bytes4 selector, address implementation) internal virtual {
        _enforceCanAddFunctions(implementation);
        _enforceCanReplaceFunction(selector, implementation);
        _replaceFunction_(selector, implementation);
    }

    function removeFunctions_(bytes4[] memory selectors) internal virtual {
        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                removeFunction_(selectors[i]);
            }
        }
    }

    function removeFunction_(bytes4 selector) internal virtual {
        address implementation = _implementation(selector);
        _enforceCanRemoveFunction(selector, implementation);
        _removeFunction_(selector, implementation);
    }

    function setUpgradableFunctions_(bytes4[] memory selectors, bool isUpgradable)
        internal
        virtual
    {
        unchecked {
            for (uint256 i; i < selectors.length; i++) {
                setUpgradableFunction_(selectors[i], isUpgradable);
            }
        }
    }

    function setUpgradableFunction_(bytes4 selector, bool isUpgradable) internal virtual {
        _implementation(selector).enforceIsNotZeroAddress();
        _setUpgradableFunction(selector, isUpgradable);
    }

    function _addFunction_(
        bytes4 selector,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        _addFunction(selector, implementation, isUpgradable);
        _afterAddFunction(implementation);
    }

    function _replaceFunction_(bytes4 selector, address implementation) internal virtual {
        address oldImplementation = _implementation(selector);
        _replaceFunction(selector, implementation);
        _afterRemoveFunction(oldImplementation);
        _afterAddFunction(implementation);
    }

    function _removeFunction_(bytes4 selector, address implementation) internal virtual {
        _removeFunction(selector);
        _afterRemoveFunction(implementation);
    }

    function _enforceCanAddFunctions(address implementation) internal view virtual {
        if (implementation != address(this)) {
            implementation.enforceIsContract();
        }
    }

    function _enforceCanAddFunction(bytes4 selector, address) internal view virtual {
        _implementation(selector).enforceIsZeroAddress();
    }

    function _enforceCanReplaceFunction(bytes4 selector, address implementation)
        internal
        view
        virtual
    {
        address oldImplementation = _implementation(selector);
        oldImplementation.enforceNotEquals(implementation);
        _enforceCanRemoveFunction(selector, oldImplementation);
    }

    function _enforceCanRemoveFunction(bytes4 selector, address implementation)
        internal
        view
        virtual
    {
        implementation.enforceIsNotZeroAddress();

        if (!_isUpgradable(selector)) {
            // Can't remove immutable functions - functions defined directly in the proxy w/o upgradability
            implementation.enforceNotEquals(address(this));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant FACETED_PROXY_STORAGE_SLOT = keccak256("core.proxy.faceted.storage");

struct SelectorInfo {
    bool isUpgradable;
    uint16 position;
    address implementation;
}

struct ImplementationInfo {
    uint16 position;
    uint16 selectorCount;
}

struct ProxyFacetedStorage {
    mapping(bytes4 => SelectorInfo) selectorInfo;
    bytes4[] selectors;
    mapping(address => ImplementationInfo) implementationInfo;
    address[] implementations;
}

function proxyFacetedStorage() pure returns (ProxyFacetedStorage storage ps) {
    bytes32 slot = FACETED_PROXY_STORAGE_SLOT;
    assembly {
        ps.slot := slot
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { proxyFacetedStorage, ProxyFacetedStorage, SelectorInfo, ImplementationInfo } from "./ProxyFacetedStorage.sol";

abstract contract ProxyFacetedModel {
    function _implementation(bytes4 selector) internal view virtual returns (address) {
        return proxyFacetedStorage().selectorInfo[selector].implementation;
    }

    function _addFunction(
        bytes4 selector,
        address implementation,
        bool isUpgradable
    ) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        ps.selectorInfo[selector] = SelectorInfo(
            isUpgradable,
            uint16(ps.selectors.length),
            implementation
        );
        ps.selectors.push(selector);
    }

    function _replaceFunction(bytes4 selector, address implementation) internal virtual {
        proxyFacetedStorage().selectorInfo[selector].implementation = implementation;
    }

    function _removeFunction(bytes4 selector) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        uint16 position = ps.selectorInfo[selector].position;
        uint256 lastPosition = ps.selectors.length - 1;

        if (position != lastPosition) {
            bytes4 lastSelector = ps.selectors[lastPosition];
            ps.selectors[position] = lastSelector;
            ps.selectorInfo[lastSelector].position = position;
        }

        ps.selectors.pop();
        delete ps.selectorInfo[selector];
    }

    function _afterAddFunction(address implementation) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        ImplementationInfo memory info = ps.implementationInfo[implementation];

        if (++info.selectorCount == 1) {
            info.position = uint16(ps.implementations.length);
            ps.implementations.push(implementation);
        }

        ps.implementationInfo[implementation] = info;
    }

    function _afterRemoveFunction(address implementation) internal virtual {
        ProxyFacetedStorage storage ps = proxyFacetedStorage();
        ImplementationInfo memory info = ps.implementationInfo[implementation];

        if (--info.selectorCount == 0) {
            uint16 position = info.position;
            uint256 lastPosition = ps.implementations.length - 1;

            if (position != lastPosition) {
                address lastImplementation = ps.implementations[lastPosition];
                ps.implementations[position] = lastImplementation;
                ps.implementationInfo[lastImplementation].position = position;
            }

            ps.implementations.pop();
            delete ps.implementationInfo[implementation];
        } else {
            ps.implementationInfo[implementation] = info;
        }
    }

    function _setUpgradableFunction(bytes4 selector, bool isUpgradable) internal virtual {
        proxyFacetedStorage().selectorInfo[selector].isUpgradable = isUpgradable;
    }

    function _isUpgradable(bytes4 selector) internal view virtual returns (bool) {
        return proxyFacetedStorage().selectorInfo[selector].isUpgradable;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ProxyModel } from "./ProxyModel.sol";
import { AddressUtils } from "../utils/AddressUtils.sol";
import { IntegerUtils } from "../utils/IntegerUtils.sol";

abstract contract ProxyController is ProxyModel {
    using AddressUtils for address;
    using IntegerUtils for uint256;

    function Proxy_(address init, bytes memory data) internal virtual {
        data.length.enforceIsNotZero();
        init.enforceIsContract();
        _Proxy(init, data);
    }

    function fallback_() internal virtual {
        _delegate(implementation_());
    }

    function implementation_() internal view virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Address utilities
 */
library AddressUtils {
    error UnexpectedContractAddress();
    error UnexpectedNonContractAddress();
    error UnexpectedZeroAddress();
    error UnexpectedNonZeroAddress();
    error UnexpectedAddress();

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function enforceIsContract(address account) internal view {
        if (isContract(account)) {
            return;
        }

        revert UnexpectedNonContractAddress();
    }

    function enforceIsNotContract(address account) internal view {
        if (isContract(account)) {
            revert UnexpectedContractAddress();
        }
    }

    function enforceIsZeroAddress(address account) internal pure {
        if (account == address(0)) {
            return;
        }

        revert UnexpectedNonZeroAddress();
    }

    function enforceIsNotZeroAddress(address account) internal pure {
        if (account == address(0)) {
            revert UnexpectedZeroAddress();
        }
    }

    function enforceEquals(address a, address b) internal pure {
        if (a == b) {
            return;
        }

        revert UnexpectedAddress();
    }

    function enforceNotEquals(address a, address b) internal pure {
        if (a == b) {
            revert UnexpectedAddress();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ProxyModel {
    function _Proxy(address init, bytes memory data) internal virtual {
        (bool success, bytes memory reason) = init.delegatecall(data);

        if (!success) {
            assembly {
                revert(add(reason, 0x20), mload(reason))
            }
        }
    }

    function _delegate(address implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Integer utilities
 */
library IntegerUtils {
    error UnexpectedZeroValue();
    error UnexpectedNonZeroValue();
    error OutOfBoundsValue(uint256 value, uint256 length);
    error UnexpectedValue();

    function enforceIsZero(uint256 i) internal pure {
        if (i == 0) {
            return;
        }

        revert UnexpectedNonZeroValue();
    }

    function enforceIsNotZero(uint256 i) internal pure {
        if (i == 0) {
            revert UnexpectedZeroValue();
        }
    }

    function enforceLessThan(uint256 a, uint256 b) internal pure {
        if (a < b) {
            return;
        }

        revert OutOfBoundsValue(a, b);
    }

    function enforceNotLessThan(uint256 a, uint256 b) internal pure {
        if (a < b) {
            revert OutOfBoundsValue(b, a);
        }
    }

    function enforceGreaterThan(uint256 a, uint256 b) internal pure {
        if (a > b) {
            return;
        }

        revert OutOfBoundsValue(b, a);
    }

    function enforceNotGreaterThan(uint256 a, uint256 b) internal pure {
        if (a > b) {
            revert OutOfBoundsValue(a, b);
        }
    }
    
    function enforceEquals(uint256 a, uint256 b) internal pure {
        if (a == b) {
            return;
        }

        revert UnexpectedValue();
    }

    function enforceNotEquals(uint256 a, uint256 b) internal pure {
        if (a == b) {
            revert UnexpectedValue();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Controller } from "../IERC173Controller.sol";
import { OwnableModel } from "./OwnableModel.sol";
import { AddressUtils } from "../../utils/AddressUtils.sol";

abstract contract OwnableController is IERC173Controller, OwnableModel {
    using AddressUtils for address;

    modifier onlyOwner() {
        _enforceOnlyOwner();
        _;
    }

    function Ownable_() internal virtual {
        Ownable_(msg.sender);
    }

    function Ownable_(address owner) internal virtual {
        transferOwnership_(owner);
    }

    function owner_() internal view virtual returns (address) {
        return _owner();
    }

    function transferOwnership_(address newOwner) internal virtual {
        _transferOwnership(newOwner);
        emit OwnershipTransferred(_owner(), newOwner);
    }

    function _enforceOnlyOwner() internal view virtual {
        msg.sender.enforceEquals(_owner());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface required by controller functions
 */
interface IERC173Controller {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ownableStorage as os } from "./OwnableStorage.sol";

abstract contract OwnableModel {
    function _owner() internal view virtual returns (address) {
        return os().owner;
    }

    function _transferOwnership(address newOwner) internal virtual {
        os().owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant OWNABLE_STORAGE_SLOT = keccak256("core.access.ownable.storage");

struct OwnableStorage {
    address owner;
}

function ownableStorage() pure returns (OwnableStorage storage os) {
    bytes32 slot = OWNABLE_STORAGE_SLOT;
    assembly {
        os.slot := slot
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { erc165Storage as es } from "./ERC165Storage.sol";

abstract contract ERC165Model {
    function _supportsInterface(bytes4 interfaceId) internal view virtual returns (bool) {
        return es().supportedInterfaces[interfaceId];
    }

    function _setSupportedInterface(bytes4 interfaceId, bool isSupported)
        internal
        virtual
    {
        es().supportedInterfaces[interfaceId] = isSupported;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

bytes32 constant ERC165_STORAGE_SLOT = keccak256("core.introspection.erc165.storage");

struct ERC165Storage {
    mapping(bytes4 => bool) supportedInterfaces;
}

function erc165Storage() pure returns (ERC165Storage storage es) {
    bytes32 slot = ERC165_STORAGE_SLOT;
    assembly {
        es.slot := slot
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721BaseController } from "./base/IERC721BaseController.sol";
import { IERC721ApprovableController } from "./approvable/IERC721ApprovableController.sol";
import { IERC721TransferableController } from "./transferable/IERC721TransferableController.sol";

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721Controller is
    IERC721TransferableController,
    IERC721ApprovableController,
    IERC721BaseController
{}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721BaseController {
    error NonExistentToken(uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721ApprovableController {
    error UnapprovedTokenAction(uint256 tokenId);
    
    error UnapprovedOperatorAction();

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC721 interface required by controller functions
 */
interface IERC721TransferableController {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
}