// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
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

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173 } from '../IERC173.sol';

interface IOwnable is IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable } from './IOwnable.sol';

interface ISafeOwnable is IOwnable {
    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function nomineeOwner() external view returns (address);

    /**
     * @notice accept transfer of contract ownership
     */
    function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';

interface ISafeOwnableInternal is IOwnableInternal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173 } from '../IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
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

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

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

pragma solidity ^0.8.0;

import { Ownable, OwnableStorage } from './Ownable.sol';
import { ISafeOwnable } from './ISafeOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { SafeOwnableInternal } from './SafeOwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173 with ownership transfer safety check
 */
abstract contract SafeOwnable is ISafeOwnable, Ownable, SafeOwnableInternal {
    /**
     * @inheritdoc ISafeOwnable
     */
    function nomineeOwner() public view virtual returns (address) {
        return _nomineeOwner();
    }

    /**
     * @inheritdoc ISafeOwnable
     */
    function acceptOwnership() public virtual onlyNomineeOwner {
        _acceptOwnership();
    }

    function _transferOwnership(address account)
        internal
        virtual
        override(OwnableInternal, SafeOwnableInternal)
    {
        super._transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';
import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

abstract contract SafeOwnableInternal is ISafeOwnableInternal, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;
    using SafeOwnableStorage for SafeOwnableStorage.Layout;

    modifier onlyNomineeOwner() {
        require(
            msg.sender == _nomineeOwner(),
            'SafeOwnable: sender must be nominee owner'
        );
        _;
    }

    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function _nomineeOwner() internal view virtual returns (address) {
        return SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice accept transfer of contract ownership
     */
    function _acceptOwnership() internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, msg.sender);
        l.setOwner(msg.sender);
        SafeOwnableStorage.layout().setNomineeOwner(address(0));
    }

    /**
     * @notice set nominee owner, granting permission to call acceptOwnership
     */
    function _transferOwnership(address account) internal virtual override {
        SafeOwnableStorage.layout().setNomineeOwner(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeOwnableStorage {
    struct Layout {
        address nomineeOwner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.SafeOwnable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setNomineeOwner(Layout storage l, address nomineeOwner) internal {
        l.nomineeOwner = nomineeOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from './IERC165.sol';
import { ERC165Storage } from './ERC165Storage.sol';

/**
 * @title ERC165 implementation
 */
abstract contract ERC165 is IERC165 {
    using ERC165Storage for ERC165Storage.Layout;

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {
        return ERC165Storage.layout().isSupportedInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

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
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

import { Proxy } from '../../Proxy.sol';
import { IDiamondBase } from './IDiamondBase.sol';
import { DiamondBaseStorage } from './DiamondBaseStorage.sol';

/**
 * @title EIP-2535 "Diamond" proxy base contract
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
abstract contract DiamondBase is IDiamondBase, Proxy {
    /**
     * @inheritdoc Proxy
     */
    function _getImplementation() internal view override returns (address) {
        // inline storage layout retrieval uses less gas
        DiamondBaseStorage.Layout storage l;
        bytes32 slot = DiamondBaseStorage.STORAGE_SLOT;
        assembly {
            l.slot := slot
        }

        address implementation = address(bytes20(l.facets[msg.sig]));

        if (implementation == address(0)) {
            implementation = l.fallbackAddress;
            require(
                implementation != address(0),
                'DiamondBase: no facet found for function signature'
            );
        }

        return implementation;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../../../utils/AddressUtils.sol';
import { IDiamondWritable } from '../writable/IDiamondWritable.sol';

/**
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
library DiamondBaseStorage {
    using AddressUtils for address;
    using DiamondBaseStorage for DiamondBaseStorage.Layout;

    struct Layout {
        // function selector => (facet address, selector slot position)
        mapping(bytes4 => bytes32) facets;
        // total number of selectors registered
        uint16 selectorCount;
        // array of selector slots with 8 selectors per slot
        mapping(uint256 => bytes32) selectorSlots;
        address fallbackAddress;
    }

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.DiamondBase');

    event DiamondCut(
        IDiamondWritable.FacetCut[] facetCuts,
        address target,
        bytes data
    );

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice update functions callable on Diamond proxy
     * @param l storage layout
     * @param facetCuts array of structured Diamond facet update data
     * @param target optional recipient of initialization delegatecall
     * @param data optional initialization call data
     */
    function diamondCut(
        Layout storage l,
        IDiamondWritable.FacetCut[] memory facetCuts,
        address target,
        bytes memory data
    ) internal {
        unchecked {
            uint256 originalSelectorCount = l.selectorCount;
            uint256 selectorCount = originalSelectorCount;
            bytes32 selectorSlot;

            // Check if last selector slot is not full
            if (selectorCount & 7 > 0) {
                // get last selectorSlot
                selectorSlot = l.selectorSlots[selectorCount >> 3];
            }

            for (uint256 i; i < facetCuts.length; i++) {
                IDiamondWritable.FacetCut memory facetCut = facetCuts[i];
                IDiamondWritable.FacetCutAction action = facetCut.action;

                require(
                    facetCut.selectors.length > 0,
                    'DiamondBase: no selectors specified'
                );

                if (action == IDiamondWritable.FacetCutAction.ADD) {
                    (selectorCount, selectorSlot) = l.addFacetSelectors(
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                } else if (action == IDiamondWritable.FacetCutAction.REPLACE) {
                    l.replaceFacetSelectors(facetCut);
                } else if (action == IDiamondWritable.FacetCutAction.REMOVE) {
                    (selectorCount, selectorSlot) = l.removeFacetSelectors(
                        selectorCount,
                        selectorSlot,
                        facetCut
                    );
                }
            }

            if (selectorCount != originalSelectorCount) {
                l.selectorCount = uint16(selectorCount);
            }

            // If last selector slot is not full
            if (selectorCount & 7 > 0) {
                l.selectorSlots[selectorCount >> 3] = selectorSlot;
            }

            emit DiamondCut(facetCuts, target, data);
            initialize(target, data);
        }
    }

    function addFacetSelectors(
        Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        IDiamondWritable.FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            require(
                facetCut.target == address(this) ||
                    facetCut.target.isContract(),
                'DiamondBase: ADD target has no code'
            );

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                require(
                    address(bytes20(oldFacet)) == address(0),
                    'DiamondBase: selector already added'
                );

                // add facet for selector
                l.facets[selector] =
                    bytes20(facetCut.target) |
                    bytes32(selectorCount);
                uint256 selectorInSlotPosition = (selectorCount & 7) << 5;

                // clear selector position in slot and add selector
                selectorSlot =
                    (selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);

                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    l.selectorSlots[selectorCount >> 3] = selectorSlot;
                    selectorSlot = 0;
                }

                selectorCount++;
            }

            return (selectorCount, selectorSlot);
        }
    }

    function removeFacetSelectors(
        Layout storage l,
        uint256 selectorCount,
        bytes32 selectorSlot,
        IDiamondWritable.FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            require(
                facetCut.target == address(0),
                'DiamondBase: REMOVE target must be zero address'
            );

            uint256 selectorSlotCount = selectorCount >> 3;
            uint256 selectorInSlotIndex = selectorCount & 7;

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];

                require(
                    address(bytes20(oldFacet)) != address(0),
                    'DiamondBase: selector not found'
                );

                require(
                    address(bytes20(oldFacet)) != address(this),
                    'DiamondBase: selector is immutable'
                );

                if (selectorSlot == 0) {
                    selectorSlotCount--;
                    selectorSlot = l.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }

                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                // adding a block here prevents stack too deep error
                {
                    // replace selector with last selector in l.facets
                    lastSelector = bytes4(
                        selectorSlot << (selectorInSlotIndex << 5)
                    );

                    if (lastSelector != selector) {
                        // update last selector slot position info
                        l.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(l.facets[lastSelector]);
                    }

                    delete l.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }

                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = l.selectorSlots[
                        oldSelectorsSlotCount
                    ];

                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    // update storage with the modified slot
                    l.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    selectorSlot =
                        (selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }

                if (selectorInSlotIndex == 0) {
                    delete l.selectorSlots[selectorSlotCount];
                    selectorSlot = 0;
                }
            }

            selectorCount = (selectorSlotCount << 3) | selectorInSlotIndex;

            return (selectorCount, selectorSlot);
        }
    }

    function replaceFacetSelectors(
        Layout storage l,
        IDiamondWritable.FacetCut memory facetCut
    ) internal {
        unchecked {
            require(
                facetCut.target.isContract(),
                'DiamondBase: REPLACE target has no code'
            );

            for (uint256 i; i < facetCut.selectors.length; i++) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = l.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                require(
                    oldFacetAddress != address(0),
                    'DiamondBase: selector not found'
                );

                require(
                    oldFacetAddress != address(this),
                    'DiamondBase: selector is immutable'
                );

                require(
                    oldFacetAddress != facetCut.target,
                    'DiamondBase: REPLACE target is identical'
                );

                // replace old facet address
                l.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(facetCut.target);
            }
        }
    }

    function initialize(address target, bytes memory data) private {
        require(
            (target == address(0)) == (data.length == 0),
            'DiamondBase: invalid initialization parameters'
        );

        if (target != address(0)) {
            if (target != address(this)) {
                require(
                    target.isContract(),
                    'DiamondBase: initialization target has no code'
                );
            }

            (bool success, ) = target.delegatecall(data);

            if (!success) {
                assembly {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IProxy } from '../../IProxy.sol';

interface IDiamondBase is IProxy {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISafeOwnable } from '../../access/ownable/ISafeOwnable.sol';
import { IERC165 } from '../../introspection/IERC165.sol';
import { IDiamondBase } from './base/IDiamondBase.sol';
import { IDiamondReadable } from './readable/IDiamondReadable.sol';
import { IDiamondWritable } from './writable/IDiamondWritable.sol';

interface ISolidStateDiamond is
    IDiamondBase,
    IDiamondReadable,
    IDiamondWritable,
    ISafeOwnable,
    IERC165
{
    receive() external payable;

    /**
     * @notice get the address of the fallback contract
     * @return fallback address
     */
    function getFallbackAddress() external view returns (address);

    /**
     * @notice set the address of the fallback contract
     * @param fallbackAddress fallback address
     */
    function setFallbackAddress(address fallbackAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondReadable } from './IDiamondReadable.sol';

/**
 * @title EIP-2535 "Diamond" proxy introspection contract
 * @dev derived from https://github.com/mudgen/diamond-2 (MIT license)
 */
abstract contract DiamondReadable is IDiamondReadable {
    /**
     * @inheritdoc IDiamondReadable
     */
    function facets() external view returns (Facet[] memory diamondFacets) {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        diamondFacets = new Facet[](l.selectorCount);

        uint8[] memory numFacetSelectors = new uint8[](l.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(l.facets[selector]));

                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (diamondFacets[facetIndex].target == facet) {
                        diamondFacets[facetIndex].selectors[
                            numFacetSelectors[facetIndex]
                        ] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) {
                    continue;
                }

                diamondFacets[numFacets].target = facet;
                diamondFacets[numFacets].selectors = new bytes4[](
                    l.selectorCount
                );
                diamondFacets[numFacets].selectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }

        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = diamondFacets[facetIndex].selectors;

            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }

        // setting the number of facets
        assembly {
            mstore(diamondFacets, numFacets)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetFunctionSelectors(address facet)
        external
        view
        returns (bytes4[] memory selectors)
    {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        selectors = new bytes4[](l.selectorCount);

        uint256 numSelectors;
        uint256 selectorIndex;

        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));

                if (facet == address(bytes20(l.facets[selector]))) {
                    selectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }

        // set the number of selectors in the array
        assembly {
            mstore(selectors, numSelectors)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses)
    {
        DiamondBaseStorage.Layout storage l = DiamondBaseStorage.layout();

        addresses = new address[](l.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;

        for (uint256 slotIndex; selectorIndex < l.selectorCount; slotIndex++) {
            bytes32 slot = l.selectorSlots[slotIndex];

            for (
                uint256 selectorSlotIndex;
                selectorSlotIndex < 8;
                selectorSlotIndex++
            ) {
                selectorIndex++;

                if (selectorIndex > l.selectorCount) {
                    break;
                }

                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(l.facets[selector]));

                bool continueLoop;

                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facet == addresses[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }

                if (continueLoop) {
                    continue;
                }

                addresses[numFacets] = facet;
                numFacets++;
            }
        }

        // set the number of facet addresses in the array
        assembly {
            mstore(addresses, numFacets)
        }
    }

    /**
     * @inheritdoc IDiamondReadable
     */
    function facetAddress(bytes4 selector)
        external
        view
        returns (address facet)
    {
        facet = address(bytes20(DiamondBaseStorage.layout().facets[selector]));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Diamond proxy introspection interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondReadable {
    struct Facet {
        address target;
        bytes4[] selectors;
    }

    /**
     * @notice get all facets and their selectors
     * @return diamondFacets array of structured facet data
     */
    function facets() external view returns (Facet[] memory diamondFacets);

    /**
     * @notice get all selectors for given facet address
     * @param facet address of facet to query
     * @return selectors array of function selectors
     */
    function facetFunctionSelectors(address facet)
        external
        view
        returns (bytes4[] memory selectors);

    /**
     * @notice get addresses of all facets used by diamond
     * @return addresses array of facet addresses
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses);

    /**
     * @notice get the address of the facet associated with given selector
     * @param selector function selector to query
     * @return facet facet address (zero address if not found)
     */
    function facetAddress(bytes4 selector)
        external
        view
        returns (address facet);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnable, Ownable, OwnableInternal, OwnableStorage } from '../../access/ownable/Ownable.sol';
import { ISafeOwnable, SafeOwnable } from '../../access/ownable/SafeOwnable.sol';
import { IERC173 } from '../../access/IERC173.sol';
import { ERC165, IERC165, ERC165Storage } from '../../introspection/ERC165.sol';
import { DiamondBase, DiamondBaseStorage } from './base/DiamondBase.sol';
import { DiamondReadable, IDiamondReadable } from './readable/DiamondReadable.sol';
import { DiamondWritable, IDiamondWritable } from './writable/DiamondWritable.sol';
import { ISolidStateDiamond } from './ISolidStateDiamond.sol';

/**
 * @title SolidState "Diamond" proxy reference implementation
 */
abstract contract SolidStateDiamond is
    ISolidStateDiamond,
    DiamondBase,
    DiamondReadable,
    DiamondWritable,
    SafeOwnable,
    ERC165
{
    using DiamondBaseStorage for DiamondBaseStorage.Layout;
    using ERC165Storage for ERC165Storage.Layout;
    using OwnableStorage for OwnableStorage.Layout;

    constructor() {
        ERC165Storage.Layout storage erc165 = ERC165Storage.layout();
        bytes4[] memory selectors = new bytes4[](12);

        // register DiamondWritable

        selectors[0] = IDiamondWritable.diamondCut.selector;

        erc165.setSupportedInterface(type(IDiamondWritable).interfaceId, true);

        // register DiamondReadable

        selectors[1] = IDiamondReadable.facets.selector;
        selectors[2] = IDiamondReadable.facetFunctionSelectors.selector;
        selectors[3] = IDiamondReadable.facetAddresses.selector;
        selectors[4] = IDiamondReadable.facetAddress.selector;

        erc165.setSupportedInterface(type(IDiamondReadable).interfaceId, true);

        // register ERC165

        selectors[5] = IERC165.supportsInterface.selector;

        erc165.setSupportedInterface(type(IERC165).interfaceId, true);

        // register SafeOwnable

        selectors[6] = Ownable.owner.selector;
        selectors[7] = SafeOwnable.nomineeOwner.selector;
        selectors[8] = Ownable.transferOwnership.selector;
        selectors[9] = SafeOwnable.acceptOwnership.selector;

        erc165.setSupportedInterface(type(IERC173).interfaceId, true);

        // register Diamond

        selectors[10] = SolidStateDiamond.getFallbackAddress.selector;
        selectors[11] = SolidStateDiamond.setFallbackAddress.selector;

        // diamond cut

        FacetCut[] memory facetCuts = new FacetCut[](1);

        facetCuts[0] = FacetCut({
            target: address(this),
            action: IDiamondWritable.FacetCutAction.ADD,
            selectors: selectors
        });

        DiamondBaseStorage.layout().diamondCut(facetCuts, address(0), '');

        // set owner

        OwnableStorage.layout().setOwner(msg.sender);
    }

    receive() external payable {}

    /**
     * @inheritdoc ISolidStateDiamond
     */
    function getFallbackAddress() external view returns (address) {
        return DiamondBaseStorage.layout().fallbackAddress;
    }

    /**
     * @inheritdoc ISolidStateDiamond
     */
    function setFallbackAddress(address fallbackAddress) external onlyOwner {
        DiamondBaseStorage.layout().fallbackAddress = fallbackAddress;
    }

    function _transferOwnership(address account)
        internal
        virtual
        override(OwnableInternal, SafeOwnable)
    {
        super._transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableInternal } from '../../../access/ownable/OwnableInternal.sol';
import { DiamondBaseStorage } from '../base/DiamondBaseStorage.sol';
import { IDiamondWritable } from './IDiamondWritable.sol';

/**
 * @title EIP-2535 "Diamond" proxy update contract
 */
abstract contract DiamondWritable is IDiamondWritable, OwnableInternal {
    using DiamondBaseStorage for DiamondBaseStorage.Layout;

    /**
     * @inheritdoc IDiamondWritable
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external onlyOwner {
        DiamondBaseStorage.layout().diamondCut(facetCuts, target, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Diamond proxy upgrade interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondWritable {
    enum FacetCutAction {
        ADD,
        REPLACE,
        REMOVE
    }

    event DiamondCut(FacetCut[] facetCuts, address target, bytes data);

    struct FacetCut {
        address target;
        FacetCutAction action;
        bytes4[] selectors;
    }

    /**
     * @notice update diamond facets and optionally execute arbitrary initialization function
     * @param facetCuts array of structured Diamond facet update data
     * @param target optional target of initialization delegatecall
     * @param data optional initialization function call data
     */
    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IProxy {
    fallback() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../utils/AddressUtils.sol';
import { IProxy } from './IProxy.sol';

/**
 * @title Base proxy contract
 */
abstract contract Proxy is IProxy {
    using AddressUtils for address;

    /**
     * @notice delegate all calls to implementation contract
     * @dev reverts if implementation address contains no code, for compatibility with metamorphic contracts
     * @dev memory location in use by assembly may be unsafe in other contexts
     */
    fallback() external payable virtual {
        address implementation = _getImplementation();

        require(
            implementation.isContract(),
            'Proxy: implementation must be contract'
        );

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
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

    /**
     * @notice get logic implementation address
     * @return implementation address
     */
    function _getImplementation() internal virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155Internal } from '../IERC1155Internal.sol';

/**
 * @title ERC1155 enumerable and aggregate function interface
 */
interface IERC1155Enumerable is IERC1155Internal {
    /**
     * @notice query total minted supply of given token
     * @param id token id to query
     * @return token supply
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice query total number of holders for given token
     * @param id token id to query
     * @return quantity of holders
     */
    function totalHolders(uint256 id) external view returns (uint256);

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(uint256 id)
        external
        view
        returns (address[] memory);

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(address account)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155Internal } from './IERC1155Internal.sol';
import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
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

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @title ERC1155 transfer receiver interface
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @notice validate receipt of ERC1155 transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param id token ID received
     * @param value quantity of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @notice validate receipt of ERC1155 batch transfer
     * @param operator executor of transfer
     * @param from sender of tokens
     * @param ids token IDs received
     * @param values quantities of tokens received
     * @param data data payload
     * @return function's own selector if transfer is accepted
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC20MetadataStorage {
    struct Layout {
        string name;
        string symbol;
        uint8 decimals;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC20Metadata');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setName(Layout storage l, string memory name) internal {
        l.name = name;
    }

    function setSymbol(Layout storage l, string memory symbol) internal {
        l.symbol = symbol;
    }

    function setDecimals(Layout storage l, uint8 decimals) internal {
        l.decimals = decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC4626BaseStorage {
    struct Layout {
        address asset;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC4626Base');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Interface for the Multicall utility contract
 */
interface IMulticall {
    /**
     * @notice batch function calls to the contract and return the results of each
     * @param data array of function call data payloads
     * @return results array of function call results
     */
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        require(value == 0, 'UintUtils: hex length insufficient');

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/utils/EnumerableSet.sol";

import "../pricer/IPricer.sol";

import "../vendor/IExchangeHelper.sol";

import "./OrderBook.sol";

/**
 * @title Knox Dutch Auction Diamond Storage Library
 */

library AuctionStorage {
    using OrderBook for OrderBook.Index;

    struct InitAuction {
        uint64 epoch;
        uint64 expiry;
        int128 strike64x64;
        uint256 longTokenId;
        uint256 startTime;
        uint256 endTime;
    }

    enum Status {UNINITIALIZED, INITIALIZED, FINALIZED, PROCESSED, CANCELLED}

    struct Auction {
        // status of the auction
        Status status;
        // option expiration timestamp
        uint64 expiry;
        // option strike price
        int128 strike64x64;
        // auction max price
        int128 maxPrice64x64;
        // auction min price
        int128 minPrice64x64;
        // last price paid during the auction
        int128 lastPrice64x64;
        // auction start timestamp
        uint256 startTime;
        // auction end timestamp
        uint256 endTime;
        // auction processed timestamp
        uint256 processedTime;
        // total contracts available
        uint256 totalContracts;
        // total contracts sold
        uint256 totalContractsSold;
        // total unclaimed contracts
        uint256 totalUnclaimedContracts;
        // total premiums collected
        uint256 totalPremiums;
        // option long token id
        uint256 longTokenId;
    }

    struct Layout {
        // percent offset from delta strike
        int128 deltaOffset64x64;
        // minimum order size
        uint256 minSize;
        // mapping of auctions to epoch id (epoch id -> auction)
        mapping(uint64 => Auction) auctions;
        // mapping of order books to epoch id (epoch id -> order book)
        mapping(uint64 => OrderBook.Index) orderbooks;
        // mapping of unique order ids (uoids) to buyer addresses (buyer -> uoid)
        mapping(address => EnumerableSet.UintSet) uoids;
        // ExchangeHelper contract interface
        IExchangeHelper Exchange;
        // Pricer contract interface
        IPricer Pricer;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("knox.contracts.storage.Auction");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the auction parameters
     * @param epoch epoch id
     * @return auction parameters
     */
    function _getAuction(uint64 epoch) internal view returns (Auction memory) {
        return layout().auctions[epoch];
    }

    /**
     * @notice returns percent delta offset
     * @return percent delta offset as a 64x64 fixed point number
     */
    function _getDeltaOffset64x64() internal view returns (int128) {
        return layout().deltaOffset64x64;
    }

    /**
     * @notice returns the minimum order size
     * @return minimum order size
     */
    function _getMinSize() internal view returns (uint256) {
        return layout().minSize;
    }

    /**
     * @notice returns the order from the auction orderbook
     * @param epoch epoch id
     * @param orderId order id
     * @return order from auction orderbook
     */
    function _getOrderById(uint64 epoch, uint128 orderId)
        internal
        view
        returns (OrderBook.Data memory)
    {
        OrderBook.Index storage orderbook = layout().orderbooks[epoch];
        return orderbook._getOrderById(orderId);
    }

    /**
     * @notice returns the status of the auction
     * @param epoch epoch id
     * @return auction status
     */
    function _getStatus(uint64 epoch)
        internal
        view
        returns (AuctionStorage.Status)
    {
        return layout().auctions[epoch].status;
    }

    /**
     * @notice returns the stored total number of contracts that can be sold during the auction
     * returns 0 if the auction has not started
     * @param epoch epoch id
     * @return total number of contracts which may be sold
     */
    function _getTotalContracts(uint64 epoch) internal view returns (uint256) {
        return layout().auctions[epoch].totalContracts;
    }

    /**
     * @notice returns the total number of contracts sold
     * @param epoch epoch id
     * @return total number of contracts sold
     */
    function _getTotalContractsSold(uint64 epoch)
        internal
        view
        returns (uint256)
    {
        return layout().auctions[epoch].totalContractsSold;
    }

    /************************************************
     * HELPERS
     ***********************************************/

    /**
     * @notice calculates the unique order id
     * @param epoch epoch id
     * @param orderId order id
     * @return unique order id
     */
    function _formatUniqueOrderId(uint64 epoch, uint128 orderId)
        internal
        view
        returns (uint256)
    {
        // uses the first 8 bytes of the contract address to salt uoid
        bytes8 salt = bytes8(bytes20(address(this)));
        return
            (uint256(uint64(salt)) << 192) +
            (uint256(epoch) << 128) +
            uint256(orderId);
    }

    /**
     * @notice derives salt, epoch id, and order id from the unique order id
     * @param uoid unique order id
     * @return salt
     * @return epoch id
     * @return order id
     */
    function _parseUniqueOrderId(uint256 uoid)
        internal
        pure
        returns (
            bytes8,
            uint64,
            uint128
        )
    {
        uint64 salt;
        uint64 epoch;
        uint128 orderId;

        assembly {
            salt := shr(192, uoid)
            epoch := shr(128, uoid)
            orderId := uoid
        }

        return (bytes8(salt), epoch, orderId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/introspection/IERC165.sol";
import "@solidstate/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@solidstate/contracts/utils/IMulticall.sol";

import "../vendor/IExchangeHelper.sol";

import "./AuctionStorage.sol";
import "./IAuctionEvents.sol";

/**
 * @title Knox Auction Interface
 */

interface IAuction is IAuctionEvents, IERC165, IERC1155Receiver, IMulticall {
    /************************************************
     *  ADMIN
     ***********************************************/

    /**
     * @notice sets the percent offset from delta strike
     * @param newDeltaOffset64x64 new percent offset value as a 64x64 fixed point number
     */
    function setDeltaOffset64x64(int128 newDeltaOffset64x64) external;

    /**
     * @notice sets a new Exchange Helper contract
     * @param newExchangeHelper new Exchange Helper contract address
     */
    function setExchangeHelper(address newExchangeHelper) external;

    /**
     * @notice sets a new minimum order size
     * @param newMinSize new minimum order size
     */
    function setMinSize(uint256 newMinSize) external;

    /**
     * @notice sets the new pricer
     * @dev the pricer contract address must be set during the vault initialization
     * @param newPricer address of the new pricer
     */
    function setPricer(address newPricer) external;

    /************************************************
     *  INITIALIZE AUCTION
     ***********************************************/

    /**
     * @notice initializes a new auction
     * @param initAuction auction parameters
     */
    function initialize(AuctionStorage.InitAuction memory initAuction) external;

    /**
     * @notice sets the auction max/min prices
     * @param epoch epoch id
     */
    function setAuctionPrices(uint64 epoch) external;

    /************************************************
     *  PRICING
     ***********************************************/

    /**
     * @notice returns the last price paid during the auction
     * @param epoch epoch id
     * @return price as 64x64 fixed point number
     */
    function lastPrice64x64(uint64 epoch) external view returns (int128);

    /**
     * @notice calculates the current price using the price curve function
     * @param epoch epoch id
     * @return price as 64x64 fixed point number
     */
    function priceCurve64x64(uint64 epoch) external view returns (int128);

    /**
     * @notice returns the current price established by the price curve if the auction
     * is still ongoing, otherwise the last price paid is returned
     * @param epoch epoch id
     * @return price as 64x64 fixed point number
     */
    function clearingPrice64x64(uint64 epoch) external view returns (int128);

    /************************************************
     *  PURCHASE
     ***********************************************/

    /**
     * @notice adds an order specified by the price and size
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param epoch epoch id
     * @param price64x64 max price as 64x64 fixed point number
     * @param size amount of contracts
     */
    function addLimitOrder(
        uint64 epoch,
        int128 price64x64,
        uint256 size
    ) external payable;

    /**
     * @notice swaps into the collateral asset and adds an order specified by the price and size
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param s swap arguments
     * @param epoch epoch id
     * @param price64x64 max price as 64x64 fixed point number
     * @param size amount of contracts
     */
    function swapAndAddLimitOrder(
        IExchangeHelper.SwapArgs calldata s,
        uint64 epoch,
        int128 price64x64,
        uint256 size
    ) external payable;

    /**
     * @notice cancels an order
     * @dev sender must approve contract
     * @param epoch epoch id
     * @param orderId order id
     */
    function cancelLimitOrder(uint64 epoch, uint128 orderId) external;

    /**
     * @notice adds an order specified by size only
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param epoch epoch id
     * @param size amount of contracts
     * @param maxCost max cost of buyer is willing to pay
     */
    function addMarketOrder(
        uint64 epoch,
        uint256 size,
        uint256 maxCost
    ) external payable;

    /**
     * @notice swaps into the collateral asset and adds an order specified by size only
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param s swap arguments
     * @param epoch epoch id
     * @param size amount of contracts
     * @param maxCost max cost of buyer is willing to pay
     */
    function swapAndAddMarketOrder(
        IExchangeHelper.SwapArgs calldata s,
        uint64 epoch,
        uint256 size,
        uint256 maxCost
    ) external payable;

    /************************************************
     *  WITHDRAW
     ***********************************************/

    /**
     * @notice withdraws any amount(s) owed to the buyer (fill and/or refund)
     * @param epoch epoch id
     */
    function withdraw(uint64 epoch) external;

    /**
     * @notice calculates amount(s) owed to the buyer
     * @param epoch epoch id
     * @return amount refunded
     * @return amount filled
     */
    function previewWithdraw(uint64 epoch) external returns (uint256, uint256);

    /**
     * @notice calculates amount(s) owed to the buyer
     * @param epoch epoch id
     * @param buyer address of buyer
     * @return amount refunded
     * @return amount filled
     */
    function previewWithdraw(uint64 epoch, address buyer)
        external
        returns (uint256, uint256);

    /************************************************
     *  FINALIZE AUCTION
     ***********************************************/

    /**
     * @notice determines whether the auction has reached finality. the end criteria for the auction are
     * met if the auction has reached 100% utilization or the end time has been exceeded.
     * @param epoch epoch id
     */
    function finalizeAuction(uint64 epoch) external;

    /**
     * @notice transfers premiums and updates auction state
     * @param epoch epoch id
     * @return amount in premiums paid during auction
     * @return total number of contracts sold
     */
    function processAuction(uint64 epoch) external returns (uint256, uint256);

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the auction parameters
     * @param epoch epoch id
     * @return auction parameters
     */
    function getAuction(uint64 epoch)
        external
        view
        returns (AuctionStorage.Auction memory);

    /**
     * @notice returns percent delta offset
     * @return percent delta offset as a 64x64 fixed point number
     */
    function getDeltaOffset64x64() external view returns (int128);

    /**
     * @notice returns the minimum order size
     * @return minimum order size
     */
    function getMinSize() external view returns (uint256);

    /**
     * @notice returns the order from the auction orderbook
     * @param epoch epoch id
     * @param orderId order id
     * @return order from auction orderbook
     */
    function getOrderById(uint64 epoch, uint128 orderId)
        external
        view
        returns (OrderBook.Data memory);

    /**
     * @notice returns the status of the auction
     * @param epoch epoch id
     * @return auction status
     */
    function getStatus(uint64 epoch)
        external
        view
        returns (AuctionStorage.Status);

    /**
     * @notice returns the stored total number of contracts that can be sold during the auction
     * returns 0 if the auction has not started
     * @param epoch epoch id
     * @return total number of contracts which may be sold
     */
    function getTotalContracts(uint64 epoch) external view returns (uint256);

    /**
     * @notice returns the total number of contracts sold
     * @param epoch epoch id
     * @return total number of contracts sold
     */
    function getTotalContractsSold(uint64 epoch)
        external
        view
        returns (uint256);

    /**
     * @notice returns the active unique order ids
     * @param buyer address of buyer
     * @return array of unique order ids
     */
    function getUniqueOrderIds(address buyer)
        external
        view
        returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AuctionStorage.sol";

/**
 * @title Knox Auction Events Interface
 */

interface IAuctionEvents {
    /**
     * @notice emitted when the auction max/min prices have been set
     * @param epoch epoch id
     * @param strike64x64 strike price as a 64x64 fixed point number
     * @param offsetStrike64x64 offset strike price as a 64x64 fixed point number
     * @param spot64x64 spot price as a 64x64 fixed point number
     * @param maxPrice64x64 max price as a 64x64 fixed point number
     * @param minPrice64x64 min price as a 64x64 fixed point number
     */
    event AuctionPricesSet(
        uint64 indexed epoch,
        int128 strike64x64,
        int128 offsetStrike64x64,
        int128 spot64x64,
        int128 maxPrice64x64,
        int128 minPrice64x64
    );

    /**
     * @notice emitted when the exchange auction status is updated
     * @param epoch epoch id
     * @param status auction status
     */
    event AuctionStatusSet(uint64 indexed epoch, AuctionStorage.Status status);

    /**
     * @notice emitted when the delta offset is updated
     * @param oldDeltaOffset previous delta offset
     * @param newDeltaOffset new delta offset
     * @param caller address of admin
     */
    event DeltaOffsetSet(
        int128 oldDeltaOffset,
        int128 newDeltaOffset,
        address caller
    );

    /**
     * @notice emitted when the exchange helper contract address is updated
     * @param oldExchangeHelper previous exchange helper address
     * @param newExchangeHelper new exchange helper address
     * @param caller address of admin
     */
    event ExchangeHelperSet(
        address oldExchangeHelper,
        address newExchangeHelper,
        address caller
    );

    /**
     * @notice emitted when an external function reverts
     * @param message error message
     */
    event Log(string message);

    /**
     * @notice emitted when the minimum order size is updated
     * @param oldMinSize previous minimum order size
     * @param newMinSize new minimum order size
     * @param caller address of admin
     */
    event MinSizeSet(uint256 oldMinSize, uint256 newMinSize, address caller);

    /**
     * @notice emitted when a market or limit order has been placed
     * @param epoch epoch id
     * @param orderId order id
     * @param buyer address of buyer
     * @param price64x64 price paid as a 64x64 fixed point number
     * @param size quantity of options purchased
     * @param isLimitOrder true if order is a limit order
     */
    event OrderAdded(
        uint64 indexed epoch,
        uint128 orderId,
        address buyer,
        int128 price64x64,
        uint256 size,
        bool isLimitOrder
    );

    /**
     * @notice emitted when a limit order has been cancelled
     * @param epoch epoch id
     * @param orderId order id
     * @param buyer address of buyer
     */
    event OrderCanceled(uint64 indexed epoch, uint128 orderId, address buyer);

    /**
     * @notice emitted when an order (filled or unfilled) is withdrawn
     * @param epoch epoch id
     * @param buyer address of buyer
     * @param refund amount sent back to the buyer as a result of an overpayment
     * @param fill amount in long token contracts sent to the buyer
     */
    event OrderWithdrawn(
        uint64 indexed epoch,
        address buyer,
        uint256 refund,
        uint256 fill
    );

    /**
     * @notice emitted when the pricer contract address is updated
     * @param oldPricer previous pricer address
     * @param newPricer new pricer address
     * @param caller address of admin
     */
    event PricerSet(address oldPricer, address newPricer, address caller);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Knox Auction Order Book Library
 * @dev based on PiperMerriam's Grove v0.3
 * https://github.com/pipermerriam/ethereum-grove
 */

library OrderBook {
    struct Index {
        uint256 head;
        uint256 length;
        uint256 root;
        mapping(uint256 => Order) orders;
    }

    struct Order {
        Data data;
        uint256 parent;
        uint256 left;
        uint256 right;
        uint256 height;
    }

    struct Data {
        uint256 id;
        int128 price64x64;
        uint256 size;
        address buyer;
    }

    /// @dev Retrieve the highest bid in the order book.
    /// @param index The index that the order is part of.
    function _head(Index storage index) internal view returns (uint256) {
        return index.head;
    }

    /// @dev Retrieve the number of bids in the order book.
    /// @param index The index that the order is part of.
    function _length(Index storage index) internal view returns (uint256) {
        return index.length;
    }

    /// @dev Retrieve the id, price, size, and buyer for the order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getOrderById(Index storage index, uint256 id)
        internal
        view
        returns (Data memory)
    {
        return index.orders[id].data;
    }

    /// @dev Returns the previous bid in descending order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getPreviousOrder(Index storage index, uint256 id)
        internal
        view
        returns (uint256)
    {
        Order storage currentOrder = index.orders[id];

        if (currentOrder.data.id == 0) {
            // Unknown order, just return 0;
            return 0;
        }

        Order memory child;

        if (currentOrder.left != 0) {
            // Trace left to latest child in left tree.
            child = index.orders[currentOrder.left];

            while (child.right != 0) {
                child = index.orders[child.right];
            }
            return child.data.id;
        }

        if (currentOrder.parent != 0) {
            // Now we trace back up through parent relationships, looking
            // for a link where the child is the right child of it's
            // parent.
            Order storage parent = index.orders[currentOrder.parent];
            child = currentOrder;

            while (true) {
                if (parent.right == child.data.id) {
                    return parent.data.id;
                }

                if (parent.parent == 0) {
                    break;
                }
                child = parent;
                parent = index.orders[parent.parent];
            }
        }

        // This is the first order, and has no previous order.
        return 0;
    }

    /// @dev Returns the next bid in descending order.
    /// @param index The index that the order is part of.
    /// @param id The id for the order to be looked up.
    function _getNextOrder(Index storage index, uint256 id)
        internal
        view
        returns (uint256)
    {
        Order storage currentOrder = index.orders[id];

        if (currentOrder.data.id == 0) {
            // Unknown order, just return 0;
            return 0;
        }

        Order memory child;

        if (currentOrder.right != 0) {
            // Trace right to earliest child in right tree.
            child = index.orders[currentOrder.right];

            while (child.left != 0) {
                child = index.orders[child.left];
            }
            return child.data.id;
        }

        if (currentOrder.parent != 0) {
            // if the order is the left child of it's parent, then the
            // parent is the next one.
            Order storage parent = index.orders[currentOrder.parent];
            child = currentOrder;

            while (true) {
                if (parent.left == child.data.id) {
                    return parent.data.id;
                }

                if (parent.parent == 0) {
                    break;
                }
                child = parent;
                parent = index.orders[parent.parent];
            }

            // Now we need to trace all the way up checking to see if any parent is the
        }

        // This is the final order.
        return 0;
    }

    /// @dev Updates or Inserts the id into the index at its appropriate location based on the price provided.
    /// @param index The index that the order is part of.
    // / @param id The unique identifier of the data element the index order will represent.
    /// @param price64x64 The unit price specified by the buyer.
    /// @param size The size specified by the buyer.
    /// @param buyer The buyers wallet address.
    function _insert(
        Index storage index,
        int128 price64x64,
        uint256 size,
        address buyer
    ) internal returns (uint256) {
        index.length = index.length + 1;
        uint256 id = index.length;

        Data memory data = _getOrderById(index, index.head);

        int128 highestPricePaid = data.price64x64;

        if (index.head == 0 || price64x64 > highestPricePaid) {
            index.head = id;
        }

        if (index.orders[id].data.id == id) {
            // A order with this id already exists.  If the price is
            // the same, then just return early, otherwise, remove it
            // and reinsert it.
            if (index.orders[id].data.price64x64 == price64x64) {
                return id;
            }
            _remove(index, id);
        }

        uint256 previousOrderId = 0;

        if (index.root == 0) {
            index.root = id;
        }
        Order storage currentOrder = index.orders[index.root];

        // Do insertion
        while (true) {
            if (currentOrder.data.id == 0) {
                // This is a new unpopulated order.
                currentOrder.data.id = id;
                currentOrder.parent = previousOrderId;
                currentOrder.data.price64x64 = price64x64;
                currentOrder.data.size = size;
                currentOrder.data.buyer = buyer;
                break;
            }

            // Set the previous order id.
            previousOrderId = currentOrder.data.id;

            // The new order belongs in the right subtree
            if (price64x64 <= currentOrder.data.price64x64) {
                if (currentOrder.right == 0) {
                    currentOrder.right = id;
                }
                currentOrder = index.orders[currentOrder.right];
                continue;
            }

            // The new order belongs in the left subtree.
            if (currentOrder.left == 0) {
                currentOrder.left = id;
            }
            currentOrder = index.orders[currentOrder.left];
        }

        // Rebalance the tree
        _rebalanceTree(index, currentOrder.data.id);

        return id;
    }

    /// @dev Remove the order for the given unique identifier from the index.
    /// @param index The index that should be removed
    /// @param id The unique identifier of the data element to remove.
    function _remove(Index storage index, uint256 id) internal returns (bool) {
        if (id == index.head) {
            index.head = _getNextOrder(index, id);
        }

        Order storage replacementOrder;
        Order storage parent;
        Order storage child;
        uint256 rebalanceOrigin;

        Order storage orderToDelete = index.orders[id];

        if (orderToDelete.data.id != id) {
            // The id does not exist in the tree.
            return false;
        }

        if (orderToDelete.left != 0 || orderToDelete.right != 0) {
            // This order is not a leaf order and thus must replace itself in
            // it's tree by either the previous or next order.
            if (orderToDelete.left != 0) {
                // This order is guaranteed to not have a right child.
                replacementOrder = index.orders[
                    _getPreviousOrder(index, orderToDelete.data.id)
                ];
            } else {
                // This order is guaranteed to not have a left child.
                replacementOrder = index.orders[
                    _getNextOrder(index, orderToDelete.data.id)
                ];
            }
            // The replacementOrder is guaranteed to have a parent.
            parent = index.orders[replacementOrder.parent];

            // Keep note of the location that our tree rebalancing should
            // start at.
            rebalanceOrigin = replacementOrder.data.id;

            // Join the parent of the replacement order with any subtree of
            // the replacement order.  We can guarantee that the replacement
            // order has at most one subtree because of how getNextOrder and
            // getPreviousOrder are used.
            if (parent.left == replacementOrder.data.id) {
                parent.left = replacementOrder.right;
                if (replacementOrder.right != 0) {
                    child = index.orders[replacementOrder.right];
                    child.parent = parent.data.id;
                }
            }
            if (parent.right == replacementOrder.data.id) {
                parent.right = replacementOrder.left;
                if (replacementOrder.left != 0) {
                    child = index.orders[replacementOrder.left];
                    child.parent = parent.data.id;
                }
            }

            // Now we replace the orderToDelete with the replacementOrder.
            // This includes parent/child relationships for all of the
            // parent, the left child, and the right child.
            replacementOrder.parent = orderToDelete.parent;
            if (orderToDelete.parent != 0) {
                parent = index.orders[orderToDelete.parent];
                if (parent.left == orderToDelete.data.id) {
                    parent.left = replacementOrder.data.id;
                }
                if (parent.right == orderToDelete.data.id) {
                    parent.right = replacementOrder.data.id;
                }
            } else {
                // If the order we are deleting is the root order update the
                // index root order pointer.
                index.root = replacementOrder.data.id;
            }

            replacementOrder.left = orderToDelete.left;
            if (orderToDelete.left != 0) {
                child = index.orders[orderToDelete.left];
                child.parent = replacementOrder.data.id;
            }

            replacementOrder.right = orderToDelete.right;
            if (orderToDelete.right != 0) {
                child = index.orders[orderToDelete.right];
                child.parent = replacementOrder.data.id;
            }
        } else if (orderToDelete.parent != 0) {
            // The order being deleted is a leaf order so we only erase it's
            // parent linkage.
            parent = index.orders[orderToDelete.parent];

            if (parent.left == orderToDelete.data.id) {
                parent.left = 0;
            }
            if (parent.right == orderToDelete.data.id) {
                parent.right = 0;
            }

            // keep note of where the rebalancing should begin.
            rebalanceOrigin = parent.data.id;
        } else {
            // This is both a leaf order and the root order, so we need to
            // unset the root order pointer.
            index.root = 0;
        }

        // Now we zero out all of the fields on the orderToDelete.
        orderToDelete.data.id = 0;
        orderToDelete.data.price64x64 = 0;
        orderToDelete.data.size = 0;
        orderToDelete.data.buyer = 0x0000000000000000000000000000000000000000;
        orderToDelete.parent = 0;
        orderToDelete.left = 0;
        orderToDelete.right = 0;
        orderToDelete.height = 0;

        // Walk back up the tree rebalancing
        if (rebalanceOrigin != 0) {
            _rebalanceTree(index, rebalanceOrigin);
        }

        return true;
    }

    function _rebalanceTree(Index storage index, uint256 id) private {
        // Trace back up rebalancing the tree and updating heights as
        // needed..
        Order storage currentOrder = index.orders[id];

        while (true) {
            int256 balanceFactor =
                _getBalanceFactor(index, currentOrder.data.id);

            if (balanceFactor == 2) {
                // Right rotation (tree is heavy on the left)
                if (_getBalanceFactor(index, currentOrder.left) == -1) {
                    // The subtree is leaning right so it need to be
                    // rotated left before the current order is rotated
                    // right.
                    _rotateLeft(index, currentOrder.left);
                }
                _rotateRight(index, currentOrder.data.id);
            }

            if (balanceFactor == -2) {
                // Left rotation (tree is heavy on the right)
                if (_getBalanceFactor(index, currentOrder.right) == 1) {
                    // The subtree is leaning left so it need to be
                    // rotated right before the current order is rotated
                    // left.
                    _rotateRight(index, currentOrder.right);
                }
                _rotateLeft(index, currentOrder.data.id);
            }

            if ((-1 <= balanceFactor) && (balanceFactor <= 1)) {
                _updateOrderHeight(index, currentOrder.data.id);
            }

            if (currentOrder.parent == 0) {
                // Reached the root which may be new due to tree
                // rotation, so set it as the root and then break.
                break;
            }

            currentOrder = index.orders[currentOrder.parent];
        }
    }

    function _getBalanceFactor(Index storage index, uint256 id)
        private
        view
        returns (int256)
    {
        Order storage order = index.orders[id];
        return
            int256(index.orders[order.left].height) -
            int256(index.orders[order.right].height);
    }

    function _updateOrderHeight(Index storage index, uint256 id) private {
        Order storage order = index.orders[id];
        order.height =
            _max(
                index.orders[order.left].height,
                index.orders[order.right].height
            ) +
            1;
    }

    function _max(uint256 a, uint256 b) private pure returns (uint256) {
        if (a >= b) {
            return a;
        }
        return b;
    }

    function _rotateLeft(Index storage index, uint256 id) private {
        Order storage originalRoot = index.orders[id];

        if (originalRoot.right == 0) {
            // Cannot rotate left if there is no right originalRoot to rotate into
            // place.
            revert();
        }

        // The right child is the new root, so it gets the original
        // `originalRoot.parent` as it's parent.
        Order storage newRoot = index.orders[originalRoot.right];
        newRoot.parent = originalRoot.parent;

        // The original root needs to have it's right child nulled out.
        originalRoot.right = 0;

        if (originalRoot.parent != 0) {
            // If there is a parent order, it needs to now point downward at
            // the newRoot which is rotating into the place where `order` was.
            Order storage parent = index.orders[originalRoot.parent];

            // figure out if we're a left or right child and have the
            // parent point to the new order.
            if (parent.left == originalRoot.data.id) {
                parent.left = newRoot.data.id;
            }
            if (parent.right == originalRoot.data.id) {
                parent.right = newRoot.data.id;
            }
        }

        if (newRoot.left != 0) {
            // If the new root had a left child, that moves to be the
            // new right child of the original root order
            Order storage leftChild = index.orders[newRoot.left];
            originalRoot.right = leftChild.data.id;
            leftChild.parent = originalRoot.data.id;
        }

        // Update the newRoot's left order to point at the original order.
        originalRoot.parent = newRoot.data.id;
        newRoot.left = originalRoot.data.id;

        if (newRoot.parent == 0) {
            index.root = newRoot.data.id;
        }

        _updateOrderHeight(index, originalRoot.data.id);
        _updateOrderHeight(index, newRoot.data.id);
    }

    function _rotateRight(Index storage index, uint256 id) private {
        Order storage originalRoot = index.orders[id];

        if (originalRoot.left == 0) {
            // Cannot rotate right if there is no left order to rotate into
            // place.
            revert();
        }

        // The left child is taking the place of order, so we update it's
        // parent to be the original parent of the order.
        Order storage newRoot = index.orders[originalRoot.left];
        newRoot.parent = originalRoot.parent;

        // Null out the originalRoot.left
        originalRoot.left = 0;

        if (originalRoot.parent != 0) {
            // If the order has a parent, update the correct child to point
            // at the newRoot now.
            Order storage parent = index.orders[originalRoot.parent];

            if (parent.left == originalRoot.data.id) {
                parent.left = newRoot.data.id;
            }
            if (parent.right == originalRoot.data.id) {
                parent.right = newRoot.data.id;
            }
        }

        if (newRoot.right != 0) {
            Order storage rightChild = index.orders[newRoot.right];
            originalRoot.left = newRoot.right;
            rightChild.parent = originalRoot.data.id;
        }

        // Update the new root's right order to point to the original order.
        originalRoot.parent = newRoot.data.id;
        newRoot.right = originalRoot.data.id;

        if (newRoot.parent == 0) {
            index.root = newRoot.data.id;
        }

        // Recompute heights.
        _updateOrderHeight(index, originalRoot.data.id);
        _updateOrderHeight(index, newRoot.data.id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Knox Pricer Interface
 */

interface IPricer {
    /**
     * @notice gets the latest price of the underlying denominated in the base
     * @return price of underlying asset as 64x64 fixed point number
     */
    function latestAnswer64x64() external view returns (int128);

    /**
     * @notice calculates the time remaining until maturity
     * @param expiry the expiry date as UNIX timestamp
     * @return time remaining until maturity
     */
    function getTimeToMaturity64x64(uint64 expiry)
        external
        view
        returns (int128);

    /**
     * @notice gets the annualized volatility of the pool pair
     * @param spot64x64 spot price of the underlying as 64x64 fixed point number
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @param timeToMaturity64x64 time remaining until maturity as a 64x64 fixed point number
     * @return annualized volatility as 64x64 fixed point number
     */
    function getAnnualizedVolatility64x64(
        int128 spot64x64,
        int128 strike64x64,
        int128 timeToMaturity64x64
    ) external view returns (int128);

    /**
     * @notice gets the option price using the Black-Scholes model
     * @param spot64x64 spot price of the underlying as 64x64 fixed point number
     * @param strike64x64 strike price of the option as 64x64 fixed point number
     * @param timeToMaturity64x64 time remaining until maturity as a 64x64 fixed point number
     * @param isCall option type, true if call option
     * @return price of the option denominated in the base as 64x64 fixed point number
     */
    function getBlackScholesPrice64x64(
        int128 spot64x64,
        int128 strike64x64,
        int128 timeToMaturity64x64,
        bool isCall
    ) external view returns (int128);

    /**
     * @notice calculates the delta strike price
     * @param isCall option type, true if call option
     * @param expiry the expiry date as UNIX timestamp
     * @param delta64x64 option delta as 64x64 fixed point number
     * @return delta strike price as 64x64 fixed point number
     */
    function getDeltaStrikePrice64x64(
        bool isCall,
        uint64 expiry,
        int128 delta64x64
    ) external view returns (int128);

    /**
     * @notice rounds a value to the floor or ceiling depending on option type
     * @param isCall option type, true if call option
     * @param n input value
     * @return rounded value as 64x64 fixed point number
     */
    function snapToGrid64x64(bool isCall, int128 n)
        external
        view
        returns (int128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/introspection/IERC165.sol";
import "@solidstate/contracts/token/ERC1155/IERC1155.sol";
import "@solidstate/contracts/token/ERC1155/enumerable/IERC1155Enumerable.sol";
import "@solidstate/contracts/utils/IMulticall.sol";

import "../vendor/IExchangeHelper.sol";

import "./IQueueEvents.sol";

/**
 * @title Knox Queue Interface
 */

interface IQueue is
    IERC165,
    IERC1155,
    IERC1155Enumerable,
    IMulticall,
    IQueueEvents
{
    /************************************************
     *  ADMIN
     ***********************************************/

    /**
     * @notice sets a new max TVL for deposits
     * @param newMaxTVL is the new TVL limit for deposits
     */
    function setMaxTVL(uint256 newMaxTVL) external;

    /**
     * @notice sets a new Exchange Helper contract
     * @param newExchangeHelper is the new Exchange Helper contract address
     */
    function setExchangeHelper(address newExchangeHelper) external;

    /************************************************
     *  DEPOSIT
     ***********************************************/

    /**
     * @notice deposits collateral asset
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param amount total collateral deposited
     */
    function deposit(uint256 amount) external payable;

    /**
     * @notice swaps into the collateral asset and deposits the proceeds
     * @dev sent ETH will be wrapped as wETH, sender must approve contract
     * @param s swap arguments
     */
    function swapAndDeposit(IExchangeHelper.SwapArgs calldata s)
        external
        payable;

    /************************************************
     *  CANCEL
     ***********************************************/

    /**
     * @notice cancels deposit, refunds collateral asset
     * @dev cancellation must be made within the same epoch as the deposit
     * @param amount total collateral which will be withdrawn
     */
    function cancel(uint256 amount) external;

    /************************************************
     *  REDEEM
     ***********************************************/

    /**
     * @notice exchanges claim token for vault shares
     * @param tokenId claim token id
     */
    function redeem(uint256 tokenId) external;

    /**
     * @notice exchanges claim token for vault shares
     * @param tokenId claim token id
     * @param receiver vault share recipient
     */
    function redeem(uint256 tokenId, address receiver) external;

    /**
     * @notice exchanges claim token for vault shares
     * @param tokenId claim token id
     * @param receiver vault share recipient
     * @param owner claim token holder
     */
    function redeem(
        uint256 tokenId,
        address receiver,
        address owner
    ) external;

    /**
     * @notice exchanges all claim tokens for vault shares
     */
    function redeemMax() external;

    /**
     * @notice exchanges all claim tokens for vault shares
     * @param receiver vault share recipient
     */
    function redeemMax(address receiver) external;

    /**
     * @notice exchanges all claim tokens for vault shares
     * @param receiver vault share recipient
     * @param owner claim token holder
     */
    function redeemMax(address receiver, address owner) external;

    /************************************************
     *  INITIALIZE EPOCH
     ***********************************************/

    /**
     * @notice transfers deposited collateral to vault, calculates the price per share
     */
    function processDeposits() external;

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the current claim token id
     * @return claim token id
     */
    function getCurrentTokenId() external view returns (uint256);

    /**
     * @notice returns the current epoch of the queue
     * @return epoch id
     */
    function getEpoch() external view returns (uint64);

    /**
     * @notice returns the max total value locked of the vault
     * @return max total value
     */
    function getMaxTVL() external view returns (uint256);

    /**
     * @notice returns the price per share for a given claim token id
     * @param tokenId claim token id
     * @return price per share
     */
    function getPricePerShare(uint256 tokenId) external view returns (uint256);

    /**
     * @notice returns unredeemed vault shares available for a given claim token
     * @param tokenId claim token id
     * @return unredeemed vault share amount
     */
    function previewUnredeemed(uint256 tokenId) external view returns (uint256);

    /**
     * @notice returns unredeemed vault shares available for a given claim token
     * @param tokenId claim token id
     * @param owner claim token holder
     * @return unredeemed vault share amount
     */
    function previewUnredeemed(uint256 tokenId, address owner)
        external
        view
        returns (uint256);

    /**
     * @notice returns unredeemed vault shares available for all claim tokens
     * @param owner claim token holder
     * @return unredeemed vault share amount
     */
    function previewMaxUnredeemed(address owner)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Knox Queue Events Interface
 */

interface IQueueEvents {
    /**
     * @notice emitted when a deposit is cancelled
     * @param epoch epoch id
     * @param depositer address of depositer
     * @param amount quantity of collateral assets removed from queue
     */
    event Cancel(uint64 indexed epoch, address depositer, uint256 amount);

    /**
     * @notice emitted when a deposit is made
     * @param epoch epoch id
     * @param depositer address of depositer
     * @param amount quantity of collateral assets added to queue
     */
    event Deposit(uint64 indexed epoch, address depositer, uint256 amount);

    /**
     * @notice emitted when the exchange helper contract address is updated
     * @param oldExchangeHelper previous exchange helper address
     * @param newExchangeHelper new exchange helper address
     * @param caller address of admin
     */
    event ExchangeHelperSet(
        address oldExchangeHelper,
        address newExchangeHelper,
        address caller
    );

    /**
     * @notice emitted when the max TVL is updated
     * @param epoch epoch id
     * @param oldMaxTVL previous max TVL amount
     * @param newMaxTVL new max TVL amount
     * @param caller address of admin
     */
    event MaxTVLSet(
        uint64 indexed epoch,
        uint256 oldMaxTVL,
        uint256 newMaxTVL,
        address caller
    );

    /**
     * @notice emitted when vault shares are redeemed
     * @param epoch epoch id
     * @param receiver address of receiver
     * @param depositer address of depositer
     * @param shares quantity of vault shares sent to receiver
     */
    event Redeem(
        uint64 indexed epoch,
        address receiver,
        address depositer,
        uint256 shares
    );

    /**
     * @notice emitted when the queued deposits are processed
     * @param epoch epoch id
     * @param deposits quantity of collateral assets processed
     * @param pricePerShare vault price per share calculated
     * @param shares quantity of vault shares sent to queue contract
     * @param claimTokenSupply quantity of claim tokens in supply
     */
    event ProcessQueuedDeposits(
        uint64 indexed epoch,
        uint256 deposits,
        uint256 pricePerShare,
        uint256 shares,
        uint256 claimTokenSupply
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol";
import "@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol";
import "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import "@solidstate/contracts/token/ERC4626/base/ERC4626BaseStorage.sol";

import "../vendor/IPremiaPool.sol";

import "./VaultStorage.sol";

/**
 * @title Knox Vault Diamond Contract
 * @dev implements EIP2535 Diamond Standard
 * @dev contracts are upgradable
 */

contract VaultDiamond is SolidStateDiamond {
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;
    using ERC4626BaseStorage for ERC4626BaseStorage.Layout;
    using OwnableStorage for OwnableStorage.Layout;
    using VaultStorage for VaultStorage.Layout;

    constructor(VaultStorage.InitProxy memory initProxy) {
        address asset;

        {
            VaultStorage.Layout storage l = VaultStorage.layout();

            IPremiaPool.PoolSettings memory settings =
                IPremiaPool(initProxy.pool).getPoolSettings();

            l.isCall = initProxy.isCall;
            asset = l.isCall ? settings.underlying : settings.base;

            l.baseDecimals = IERC20Metadata(settings.base).decimals();
            l.underlyingDecimals = IERC20Metadata(settings.underlying)
                .decimals();

            l.delta64x64 = initProxy.delta64x64;
            l.reserveRate64x64 = initProxy.reserveRate64x64;
            l.performanceFee64x64 = initProxy.performanceFee64x64;

            l.Pricer = IPricer(initProxy.pricer);
            l.feeRecipient = initProxy.feeRecipient;
            l.keeper = initProxy.keeper;

            l.startOffset = 8 hours;
            l.endOffset = 8.5 hours;
        }

        {
            ERC20MetadataStorage.Layout storage l =
                ERC20MetadataStorage.layout();
            l.setName(initProxy.name);
            l.setSymbol(initProxy.symbol);
            l.setDecimals(18);
        }

        ERC4626BaseStorage.layout().asset = asset;
        OwnableStorage.layout().setOwner(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../auction/IAuction.sol";

import "../pricer/IPricer.sol";

import "../queue/IQueue.sol";

/**
 * @title Knox Vault Diamond Storage Library
 */

library VaultStorage {
    struct InitProxy {
        bool isCall;
        int128 delta64x64;
        int128 reserveRate64x64;
        int128 performanceFee64x64;
        string name;
        string symbol;
        address keeper;
        address feeRecipient;
        address pricer;
        address pool;
    }

    struct InitImpl {
        address auction;
        address queue;
        address pricer;
    }

    struct Option {
        // option expiration timestamp
        uint64 expiry;
        // option strike price
        int128 strike64x64;
        // option long token id
        uint256 longTokenId;
        // option short token id
        uint256 shortTokenId;
    }

    struct Layout {
        // base asset decimals
        uint8 baseDecimals;
        // underlying asset decimals
        uint8 underlyingDecimals;
        // option type, true if option is a call
        bool isCall;
        // auction processing flag, true if auction has been processed
        bool auctionProcessed;
        // vault option delta
        int128 delta64x64;
        // mapping of options to epoch id (epoch id -> option)
        mapping(uint64 => Option) options;
        // epoch id
        uint64 epoch;
        // auction start offset in seconds (startOffset = startTime - expiry)
        uint256 startOffset;
        // auction end offset in seconds (endOffset = endTime - expiry)
        uint256 endOffset;
        // auction start timestamp
        uint256 startTime;
        // total asset amount withdrawn during an epoch
        uint256 totalWithdrawals;
        // total asset amount not including premiums collected from the auction
        uint256 lastTotalAssets;
        // total premium collected during the auction
        uint256 totalPremium;
        // performance fee collected during epoch initialization
        uint256 fee;
        // percentage of asset to be held as reserves
        int128 reserveRate64x64;
        // percentage of fees taken from net income
        int128 performanceFee64x64;
        // fee recipient address
        address feeRecipient;
        // keeper bot address
        address keeper;
        // Auction contract interface
        IAuction Auction;
        // Queue contract interface
        IQueue Queue;
        // Pricer contract interface
        IPricer Pricer;
    }

    bytes32 internal constant LAYOUT_SLOT =
        keccak256("knox.contracts.storage.Vault");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = LAYOUT_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /************************************************
     *  VIEW
     ***********************************************/

    /**
     * @notice returns the current epoch
     * @return current epoch id
     */
    function _getEpoch() internal view returns (uint64) {
        return layout().epoch;
    }

    /**
     * @notice returns the option by epoch id
     * @return option parameters
     */
    function _getOption(uint64 epoch) internal view returns (Option memory) {
        return layout().options[epoch];
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

/**
 * @title Premia Exchange Helper
 * @dev deployed standalone and referenced by internal functions
 * @dev do NOT set approval to this contract!
 */
interface IExchangeHelper {
    struct SwapArgs {
        // token to pass in to swap
        address tokenIn;
        // amount of tokenIn to trade
        uint256 amountInMax;
        //min amount out to be used to purchase
        uint256 amountOutMin;
        // exchange address to call to execute the trade
        address callee;
        // address for which to set allowance for the trade
        address allowanceTarget;
        // data to execute the trade
        bytes data;
        // address to which refund excess tokens
        address refundAddress;
    }

    /**
     * @notice perform arbitrary swap transaction
     * @param sourceToken source token to pull into this address
     * @param targetToken target token to buy
     * @param pullAmount amount of source token to start the trade
     * @param callee exchange address to call to execute the trade.
     * @param allowanceTarget address for which to set allowance for the trade
     * @param data calldata to execute the trade
     * @param refundAddress address that un-used source token goes to
     * @return amountOut quantity of targetToken yielded by swap
     */
    function swapWithToken(
        address sourceToken,
        address targetToken,
        uint256 pullAmount,
        address callee,
        address allowanceTarget,
        bytes calldata data,
        address refundAddress
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPremiaPool {
    struct PoolSettings {
        address underlying;
        address base;
        address underlyingOracle;
        address baseOracle;
    }

    /**
     * @notice query holders of given token
     * @param id token id to query
     * @return list of holder addresses
     */
    function accountsByToken(uint256 id)
        external
        view
        returns (address[] memory);

    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @notice exercise option on behalf of holder
     * @param holder owner of long option tokens to exercise
     * @param longTokenId long option token id
     * @param contractSize quantity of tokens to exercise
     */
    function exerciseFrom(
        address holder,
        uint256 longTokenId,
        uint256 contractSize
    ) external;

    /**
     * @notice get fundamental pool attributes
     * @return structured PoolSettings
     */
    function getPoolSettings() external view returns (PoolSettings memory);

    /**
     * @notice get first oracle price update after timestamp. If no update has been registered yet,
     * return current price feed spot price
     * @param timestamp timestamp to query
     * @return spot64x64 64x64 fixed point representation of price
     */
    function getPriceAfter64x64(uint256 timestamp)
        external
        view
        returns (int128 spot64x64);

    /**
     * @notice process expired option, freeing liquidity and distributing profits
     * @param longTokenId long option token id
     * @param contractSize quantity of tokens to process
     */
    function processExpired(uint256 longTokenId, uint256 contractSize) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice set timestamp after which reinvestment is disabled
     * @param timestamp timestamp to begin divestment
     * @param isCallPool whether we set divestment timestamp for the call pool or put pool
     */
    function setDivestmentTimestamp(uint64 timestamp, bool isCallPool) external;

    /**
     * @notice query tokens held by given address
     * @param account address to query
     * @return list of token ids
     */
    function tokensByAccount(address account)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice force update of oracle price and pending deposit pool
     */
    function update() external;

    /**
     * @notice redeem pool share tokens for underlying asset
     * @param amount quantity of share tokens to redeem
     * @param isCallPool whether to deposit underlying in the call pool or base in the put pool
     */
    function withdraw(uint256 amount, bool isCallPool) external;

    /**
     * @notice write option without using liquidity from the pool on behalf of another address
     * @param underwriter underwriter of the option from who collateral will be deposited
     * @param longReceiver address who will receive the long token (Can be the underwriter)
     * @param maturity timestamp of option maturity
     * @param strike64x64 64x64 fixed point representation of strike price
     * @param contractSize quantity of option contract tokens to write
     * @param isCall whether this is a call or a put
     * @return longTokenId token id of the long call
     * @return shortTokenId token id of the short option
     */
    function writeFrom(
        address underwriter,
        address longReceiver,
        uint64 maturity,
        int128 strike64x64,
        uint256 contractSize,
        bool isCall
    ) external payable returns (uint256 longTokenId, uint256 shortTokenId);
}