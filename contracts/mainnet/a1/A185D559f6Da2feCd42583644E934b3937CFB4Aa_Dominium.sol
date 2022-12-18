//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Diamond} from "./external/diamond/Diamond.sol";
import {LibDiamondInitializer} from "./libraries/LibDiamondInitializer.sol";
import {IDiamondCut} from "./external/diamond/interfaces/IDiamondCut.sol";

/// @title Dominium - Shared ownership
/// @author Amit Molek
/// @dev Provides shared ownership functionality/logic. Powered by EIP-2535.
/// Note: This contract is designed to work with DominiumProxy.
/// Where this contract holds all the functionality/logic and the proxy holds all the storage
/// (so it is unique per group)
contract Dominium is Diamond {
    constructor(
        address admin,
        address anticFeeCollector,
        uint16 anticJoinFeePercentage,
        uint16 anticSellFeePercentage,
        IDiamondCut diamondCut,
        LibDiamondInitializer.DiamondInitData memory initData
    )
        payable
        Diamond(
            admin,
            anticFeeCollector,
            anticJoinFeePercentage,
            anticSellFeePercentage,
            address(diamondCut)
        )
    {
        LibDiamondInitializer._diamondInit(initData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {OwnershipFacet} from "./facets/OwnershipFacet.sol";
import {AnticFeeCollectorProviderFacet} from "./facets/AnticFeeCollectorProviderFacet.sol";
import {LibAnticFeeCollectorProvider} from "./libraries/LibAnticFeeCollectorProvider.sol";

contract Diamond is OwnershipFacet, AnticFeeCollectorProviderFacet {
    constructor(
        address _contractOwner,
        address _anticFeeCollector,
        uint16 anticJoinFeePercentage,
        uint16 anticSellFeePercentage,
        address _diamondCutFacet
    ) payable {
        LibDiamond.setContractOwner(_contractOwner);
        LibAnticFeeCollectorProvider._transferAnticFeeCollector(
            _anticFeeCollector
        );
        LibAnticFeeCollectorProvider._changeAnticFee(
            anticJoinFeePercentage,
            anticSellFeePercentage
        );

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }

        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        LibDiamond.enforceHasContractCode(
            facet,
            "Diamond: Function does not exist"
        );

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
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IAnticFeeCollectorProvider} from "../interfaces/IAnticFeeCollectorProvider.sol";
import {LibAnticFeeCollectorProvider} from "../libraries/LibAnticFeeCollectorProvider.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

/// @title Antic fee collector address provider facet
/// @author Amit Molek
/// @dev Please see `IAnticFeeCollectorProvider` for docs.
contract AnticFeeCollectorProviderFacet is IAnticFeeCollectorProvider {
    function transferAnticFeeCollector(address newCollector) external override {
        LibDiamond.enforceIsContractOwner();
        LibAnticFeeCollectorProvider._transferAnticFeeCollector(newCollector);
    }

    function changeAnticFee(uint16 newJoinFee, uint16 newSellFee)
        external
        override
    {
        LibDiamond.enforceIsContractOwner();
        LibAnticFeeCollectorProvider._changeAnticFee(newJoinFee, newSellFee);
    }

    function anticFeeCollector() external view override returns (address) {
        return LibAnticFeeCollectorProvider._anticFeeCollector();
    }

    function anticFees()
        external
        view
        override
        returns (uint16 joinFee, uint16 sellFee)
    {
        (joinFee, sellFee) = LibAnticFeeCollectorProvider._anticFees();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";

// The functions in DiamondLoupeFacet MUST be added to a diamond.
// The EIP-2535 Diamond standard requires these functions.

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds
                .facetFunctionSelectors[facetAddress_]
                .functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = ds
            .facetFunctionSelectors[_facet]
            .functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        override
        returns (address facetAddress_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds
            .selectorToFacetAndPosition[_functionSelector]
            .facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId)
        external
        view
        override
        returns (bool)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Antic fee collector address provider interface
/// @author Amit Molek
interface IAnticFeeCollectorProvider {
    /// @dev Emitted on transfer of the Antic's fee collector address
    /// @param previousCollector The previous fee collector
    /// @param newCollector The new fee collector
    event AnticFeeCollectorTransferred(
        address indexed previousCollector,
        address indexed newCollector
    );

    /// @dev Emitted on changing the Antic fees
    /// @param oldJoinFee The previous join fee percentage out of 1000
    /// @param newJoinFee The new join fee percentage out of 1000
    /// @param oldSellFee The previous sell fee percentage out of 1000
    /// @param newSellFee The new sell fee percentage out of 1000
    event AnticFeeChanged(
        uint16 oldJoinFee,
        uint16 newJoinFee,
        uint16 oldSellFee,
        uint16 newSellFee
    );

    /// @notice Transfer Antic's fee collector address
    /// @param newCollector The address of the new Antic fee collector
    function transferAnticFeeCollector(address newCollector) external;

    /// @notice Change Antic fees
    /// @param newJoinFee Antic join fee percentage out of 1000
    /// @param newSellFee Antic sell/receive fee percentage out of 1000
    function changeAnticFee(uint16 newJoinFee, uint16 newSellFee) external;

    /// @return The address of Antic's fee collector
    function anticFeeCollector() external view returns (address);

    /// @return joinFee The fee amount in percentage (out of 1000) that Antic takes for joining
    /// @return sellFee The fee amount in percentage (out of 1000) that Antic takes for selling
    function anticFees() external view returns (uint16 joinFee, uint16 sellFee);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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
pragma solidity 0.8.16;

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
pragma solidity 0.8.16;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageAnticFeeCollectorProvider} from "../storage/StorageAnticFeeCollectorProvider.sol";

/// @author Amit Molek
/// @dev Please see `IAnticFeeCollectorProvider` for docs
library LibAnticFeeCollectorProvider {
    event AnticFeeCollectorTransferred(
        address indexed previousCollector,
        address indexed newCollector
    );

    event AnticFeeChanged(
        uint16 oldJoinFee,
        uint16 newJoinFee,
        uint16 oldSellFee,
        uint16 newSellFee
    );

    function _transferAnticFeeCollector(address _newCollector) internal {
        require(
            _newCollector != address(0),
            "FeeCollector: Fee collector can't be zero address"
        );

        StorageAnticFeeCollectorProvider.DiamondStorage
            storage ds = StorageAnticFeeCollectorProvider.diamondStorage();

        require(
            _newCollector != ds.anticFeeCollector,
            "FeeCollector: Same collector"
        );

        emit AnticFeeCollectorTransferred(ds.anticFeeCollector, _newCollector);

        ds.anticFeeCollector = _newCollector;
    }

    function _changeAnticFee(uint16 newJoinFee, uint16 newSellFee) internal {
        StorageAnticFeeCollectorProvider.DiamondStorage
            storage ds = StorageAnticFeeCollectorProvider.diamondStorage();

        require(
            newJoinFee != ds.joinFeePercentage,
            "FeeCollector: Same join fee"
        );
        require(
            newSellFee != ds.sellFeePercentage,
            "FeeCollector: Same sell fee"
        );

        require(
            newJoinFee <=
                StorageAnticFeeCollectorProvider.MAX_ANTIC_FEE_PERCENTAGE,
            "FeeCollector: Invalid Antic join fee percentage"
        );

        require(
            newSellFee <=
                StorageAnticFeeCollectorProvider.MAX_ANTIC_FEE_PERCENTAGE,
            "FeeCollector: Invalid Antic sell/receive fee percentage"
        );

        emit AnticFeeChanged(
            ds.joinFeePercentage,
            newJoinFee,
            ds.sellFeePercentage,
            newSellFee
        );

        ds.joinFeePercentage = newJoinFee;
        ds.sellFeePercentage = newSellFee;
    }

    function _anticFeeCollector() internal view returns (address) {
        StorageAnticFeeCollectorProvider.DiamondStorage
            storage ds = StorageAnticFeeCollectorProvider.diamondStorage();

        return ds.anticFeeCollector;
    }

    function _anticFees()
        internal
        view
        returns (uint16 joinFee, uint16 sellFee)
    {
        StorageAnticFeeCollectorProvider.DiamondStorage
            storage ds = StorageAnticFeeCollectorProvider.diamondStorage();

        joinFee = ds.joinFeePercentage;
        sellFee = ds.sellFeePercentage;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

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

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        require(
            _newOwner != address(0),
            "LibDiamond: Owner can't be zero address"
        );

        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
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
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Replace facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
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
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
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
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for Antic fee collector provider
library StorageAnticFeeCollectorProvider {
    uint16 public constant MAX_ANTIC_FEE_PERCENTAGE = 500; // 50%

    struct DiamondStorage {
        /// @dev Address that the Antic fees will get sent to
        address anticFeeCollector;
        /// @dev Antic join fee percentage out of 1000
        /// e.g. 25 -> 25/1000 = 2.5%
        uint16 joinFeePercentage;
        /// @dev Antic sell/receive fee percentage out of 1000
        /// e.g. 25 -> 25/1000 = 2.5%
        uint16 sellFeePercentage;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.dominium.storage.AnticFeeCollectorProvider");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Antic fee collection
interface IAnticFee {
    /// @dev Emitted on value transfer to Antic
    /// @param amount the amount transferred to Antic
    event TransferredToAntic(uint256 amount);

    /// @return The address that the Antic fees will be sent to
    function antic() external view returns (address);

    /// @return The fee amount that will be collected from
    /// `value` when joining the group
    function calculateAnticJoinFee(uint256 value)
        external
        view
        returns (uint256);

    /// @return The fee amount that will be collected from `value` when
    /// value is transferred to the contract
    function calculateAnticSellFee(uint256 value)
        external
        view
        returns (uint256);

    /// @dev The percentages are out of 1000. So 25 -> 25/1000 = 2.5%
    /// @return joinFeePercentage The Antic fee percentage for join
    /// @return sellFeePercentage The Antic fee percentage for sell/receive
    function anticFeePercentages()
        external
        view
        returns (uint16 joinFeePercentage, uint16 sellFeePercentage);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Deployment refund actions
interface IDeploymentRefund {
    /// @dev Emitted on deployer withdraws deployment refund
    /// @param account the deployer that withdraw
    /// @param amount the refund amount
    event WithdrawnDeploymentRefund(address account, uint256 amount);

    /// @dev Emitted on deployment cost initialization
    /// @param gasUsed gas used in the group contract deployment
    /// @param gasPrice gas cost in the deployment
    /// @param deployer the account that deployed the group
    event InitializedDeploymentCost(
        uint256 gasUsed,
        uint256 gasPrice,
        address deployer
    );

    /// @dev Emitted on deployer joins the group
    /// @param ownershipUnits amount of ownership units acquired
    event DeployerJoined(uint256 ownershipUnits);

    /// @return The refund amount needed to be paid based on `units`.
    /// If the refund was fully funded, this will return 0
    /// If the refund amount is bigger than what is left to be refunded, this will return only
    /// what is left to be refunded. e.g. Need to refund 100 wei and 70 wei was already paid,
    /// if a new member joins and buys 40% ownership he will only need to pay 30 wei (100-70).
    function calculateDeploymentCostRefund(uint256 units)
        external
        view
        returns (uint256);

    /// @return The deployment cost needed to be refunded
    function deploymentCostToRefund() external view returns (uint256);

    /// @return The deployment cost already paid
    function deploymentCostPaid() external view returns (uint256);

    /// @return The refund amount that can be withdrawn by the deployer
    function refundable() external view returns (uint256);

    /// @notice Deployment cost refund withdraw (collected so far)
    /// @dev Refunds the deployer with the collected deployment cost
    /// Emits `WithdrawnDeploymentRefund` event
    function withdrawDeploymentRefund() external;

    /// @return The address of the contract/group deployer
    function deployer() external view returns (address);

    /// @dev Initializes the deployment cost.
    /// SHOULD be called together with the deployment of the contract, because this function uses
    /// `tx.gasprice`. So for the best accuracy initialize the contract and call this function in the same transaction.
    /// @param deploymentGasUsed Gas used to deploy the contract/group
    /// @param deployer_ The address who deployed the contract/group
    function initDeploymentCost(uint256 deploymentGasUsed, address deployer_)
        external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev EIP712 for Antic domain.
interface IEIP712 {
    function toTypedDataHash(bytes32 messageHash)
        external
        view
        returns (bytes32);

    function domainSeparator() external view returns (bytes32);

    function chainId() external view returns (uint256 id);

    function verifyingContract() external view returns (address);

    function salt() external pure returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "./IWallet.sol";

/// @author Amit Molek
/// @dev EIP712 Proposition struct signature verification for Antic domain
interface IEIP712Proposition {
    /// @param signer the account you want to check that signed
    /// @param proposition the proposition to verify
    /// @param signature the supposed signature of `signer` on `proposition`
    /// @return true if `signer` signed `proposition` using `signature`
    function verifyPropositionSigner(
        address signer,
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) external view returns (bool);

    /// @param proposition the proposition
    /// @param signature the account's signature on `proposition`
    /// @return the address that signed on `proposition`
    function recoverPropositionSigner(
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) external view returns (address);

    function hashProposition(IWallet.Proposition memory proposition)
        external
        pure
        returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "./IWallet.sol";

/// @author Amit Molek
/// @dev EIP712 transaction struct signature verification for Antic domain
interface IEIP712Transaction {
    /// @param signer the account you want to check that signed
    /// @param transaction the transaction to verify
    /// @param signature the supposed signature of `signer` on `transaction`
    /// @return true if `signer` signed `transaction` using `signature`
    function verifyTransactionSigner(
        address signer,
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) external view returns (bool);

    /// @param transaction the transaction
    /// @param signature the account's signature on `transaction`
    /// @return the address that signed on `transaction`
    function recoverTransactionSigner(
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) external view returns (address);

    function hashTransaction(IWallet.Transaction memory transaction)
        external
        pure
        returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.        
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.        
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev ERC1271 support. You can read more here:
/// https://eips.ethereum.org/EIPS/eip-1271
interface IERC1271 {
    /// @return magicValue the magicValue if the provided signature is valid
    /// @param hash of the data to be signed
    /// @param signature of hash
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4 magicValue);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Multisig Governance interface
/// @author Amit Molek
interface IGovernance {
    /// @notice Verify the given hash using the governance rules
    /// @param hash the hash you want to verify
    /// @param signatures the member's signatures of the given hash
    /// @return true, if all the hash is verified
    function verifyHash(bytes32 hash, bytes[] memory signatures)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Group managment interface
/// @author Amit Molek
interface IGroup {
    /// @dev Emitted when a member joins the group
    /// @param account the member that joined the group
    /// @param ownershipUnits number of ownership units bought
    event Joined(address account, uint256 ownershipUnits);

    /// @dev Emitted when a member acquires more ownership units
    /// @param account the member that acquired more
    /// @param ownershipUnits number of ownership units bought
    event AcquiredMore(address account, uint256 ownershipUnits);

    /// @dev Emitted when a member leaves the group
    /// @param account the member that leaved the group
    event Left(address account);

    /// @notice Join the group
    /// @dev The caller must pass contribution to the group
    /// which also represent the ownership units.
    /// The value passed to this function MUST include:
    /// the ownership units cost, Antic fee and deployment cost refund
    /// (ownership units + Antic fee + deployment refund)
    /// Emits `Joined` event
    function join(bytes memory data) external payable;

    /// @notice Acquire more ownership units
    /// @dev The caller must pass contribution to the group
    /// which also represent the ownership units.
    /// The value passed to this function MUST include:
    /// the ownership units cost, Antic fee and deployment cost refund
    /// (ownership units + Antic fee + deployment refund)
    /// Emits `AcquiredMore` event
    function acquireMore(bytes memory data) external payable;

    /// @notice Leave the group
    /// @dev The member will be refunded with his join contribution and Antic fee
    /// Emits `Leaved` event
    function leave() external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StateEnum} from "../structs/StateEnum.sol";

/// @title Group state interface
/// @author Amit Molek
interface IGroupState {
    /// @dev Emits on event change
    /// @param from the previous event
    /// @param to the new event
    event StateChanged(StateEnum from, StateEnum to);

    /// @return the current state of the contract/group
    function state() external view returns (StateEnum);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Ownership interface
/// @author Amit Molek
interface IOwnership {
    /// @return The ownership units `member` owns
    function ownershipUnits(address member) external view returns (uint256);

    /// @return The total ownership units targeted by the group members
    function totalOwnershipUnits() external view returns (uint256);

    /// @return The total ownership units owned by the group members
    function totalOwnedOwnershipUnits() external view returns (uint256);

    /// @return true if the group members owns all the targeted ownership units
    function isCompletelyOwned() external view returns (bool);

    /// @return the smallest ownership unit
    function smallestOwnershipUnit() external view returns (uint256);

    /// @return true if `account` is a member
    function isMember(address account) external view returns (bool);

    /// @return an array with all the group's members
    function members() external view returns (address[] memory);

    /// @return the address of the member at `index`
    function memberAt(uint256 index) external view returns (address, uint256);

    /// @return how many members this group has
    function memberCount() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Receive
interface IReceive {
    /// @dev Emitted on withdraw
    /// @param member the member that withdrew
    /// @param value the value that the member withdrew
    event ValueWithdrawn(address member, uint256 value);

    /// @dev Emitted on receiving value
    /// @param from the value sender
    /// @param value the received value
    event ValueReceived(address from, uint256 value);

    receive() external payable;

    /// @notice Withdraw collected funds
    /// @dev Emits `ValueWithdrawn`
    function withdraw() external;

    /// @return The value amount that the member can `withdraw` from the group
    function withdrawable(address member) external view returns (uint256);

    /// @return The total value amount withdrawable from the group
    function totalWithdrawable() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev signature verification helpers.
interface ISignature {
    /// @param signer the account you want to check that signed
    /// @param hashToVerify the EIP712 hash to verify
    /// @param signature the supposed signature of `signer` on `hashToVerify`
    /// @return true if `signer` signed `hashToVerify` using `signature`
    function verifySigner(
        address signer,
        bytes32 hashToVerify,
        bytes memory signature
    ) external pure returns (bool);

    /// @param hash the EIP712 hash
    /// @param signature the account's signature on `hash`
    /// @return the address that signed on `hash`
    function recoverSigner(bytes32 hash, bytes memory signature)
        external
        pure
        returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Multisig wallet interface
/// @author Amit Molek
interface IWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct Proposition {
        /// @dev Proposition's deadline
        uint256 endsAt;
        /// @dev Proposed transaction to execute
        Transaction tx;
        /// @dev can be useful if your `transaction` needs an accompanying hash.
        /// For example in EIP1271 `isValidSignature` function.
        /// Note: Pass zero hash (0x0) if you don't need this.
        bytes32 relevantHash;
    }

    /// @dev Emitted on proposition execution
    /// @param hash the transaction's hash
    /// @param value the value passed with `transaction`
    /// @param successful is the transaction were successfully executed
    event ExecutedTransaction(
        bytes32 indexed hash,
        uint256 value,
        bool successful
    );

    /// @notice Execute proposition
    /// @param proposition the proposition to enact
    /// @param signatures a set of members EIP712 signatures on `proposition`
    /// @dev Emits `ExecutedTransaction` and `ApprovedHash` (only if `relevantHash` is passed) events
    /// @return successful true if the `proposition`'s transaction executed successfully
    /// @return returnData the data returned from the transaction
    function enactProposition(
        Proposition memory proposition,
        bytes[] memory signatures
    ) external returns (bool successful, bytes memory returnData);

    /// @return true, if the proposition has been enacted
    function isPropositionEnacted(bytes32 propositionHash)
        external
        view
        returns (bool);

    /// @return the maximum amount of value allowed to be transferred out of the contract
    function maxAllowedTransfer() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Wallet hash interface
/// @author Amit Molek
interface IWalletHash {
    /// @dev Emitted on approved hash
    /// @param hash the approved hash
    event ApprovedHash(bytes32 hash);

    /// @dev Emitted on revoked hash
    /// @param hash the revoked hash
    event RevokedHash(bytes32 hash);

    /// @return true, if the hash is approved
    function isHashApproved(bytes32 hash) external view returns (bool);

    /// @return `hash`'s deadline
    function hashDeadline(bytes32 hash) external view returns (uint256);

    /// @notice Approves hash
    /// @param hash to be approved
    /// @param signatures a set of member's EIP191 signatures on `hash`
    /// @dev Emits `ApprovedHash`
    function approveHash(bytes32 hash, bytes[] memory signatures) external;

    /// @notice Revoke approved hash
    /// @param hash to be revoked
    /// @param signatures a set of member's EIP191 signatures on `hash`
    /// @dev Emits `RevokedHash`
    function revokeHash(bytes32 hash, bytes[] memory signatures) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/* Diamond */
import {LibDiamond} from "../external/diamond/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../external/diamond/interfaces/IDiamondLoupe.sol";
import {DiamondLoupeFacet} from "../external/diamond/facets/DiamondLoupeFacet.sol";
import {IDiamondCut} from "../external/diamond/interfaces/IDiamondCut.sol";

/* ERC165 */
import {IERC165} from "../external/diamond/interfaces/IERC165.sol";
import {IGroup} from "../interfaces/IGroup.sol";
import {IWallet} from "../interfaces/IWallet.sol";
import {IEIP712} from "../interfaces/IEIP712.sol";
import {IEIP712Transaction} from "../interfaces/IEIP712Transaction.sol";
import {IEIP712Proposition} from "../interfaces/IEIP712Proposition.sol";
import {IGovernance} from "../interfaces/IGovernance.sol";
import {ISignature} from "../interfaces/ISignature.sol";
import {IERC1271} from "../interfaces/IERC1271.sol";
import {IERC1155TokenReceiver} from "../interfaces/IERC1155TokenReceiver.sol";
import {IERC721TokenReceiver} from "../interfaces/IERC721TokenReceiver.sol";
import {IOwnership} from "../interfaces/IOwnership.sol";
import {IAnticFee} from "../interfaces/IAnticFee.sol";
import {IDeploymentRefund} from "../interfaces/IDeploymentRefund.sol";
import {IReceive} from "../interfaces/IReceive.sol";
import {IGroupState} from "../interfaces/IGroupState.sol";
import {IWalletHash} from "../interfaces/IWalletHash.sol";
import {IAnticFeeCollectorProvider} from "../external/diamond/interfaces/IAnticFeeCollectorProvider.sol";

/// @author Amit Molek
/// @dev Implements Diamond Storage for diamond initialization
library LibDiamondInitializer {
    struct DiamondInitData {
        IDiamondLoupe diamondLoupeFacet;
    }

    struct DiamondStorage {
        bool initialized;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.LibDiamondInitializer");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    modifier initializer() {
        LibDiamondInitializer.DiamondStorage storage ds = LibDiamondInitializer
            .diamondStorage();
        require(!ds.initialized, "LibDiamondInitializer: Initialized");
        _;
        ds.initialized = true;
    }

    function _diamondInit(DiamondInitData memory initData)
        internal
        initializer
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // ERC165
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IGroup).interfaceId] = true;
        ds.supportedInterfaces[type(IWallet).interfaceId] = true;
        ds.supportedInterfaces[type(IEIP712).interfaceId] = true;
        ds.supportedInterfaces[type(IEIP712Transaction).interfaceId] = true;
        ds.supportedInterfaces[type(IGovernance).interfaceId] = true;
        ds.supportedInterfaces[type(ISignature).interfaceId] = true;
        ds.supportedInterfaces[type(IERC1271).interfaceId] = true;
        ds.supportedInterfaces[type(IERC1155TokenReceiver).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721TokenReceiver).interfaceId] = true;
        ds.supportedInterfaces[type(IEIP712Proposition).interfaceId] = true;
        ds.supportedInterfaces[type(IOwnership).interfaceId] = true;
        ds.supportedInterfaces[type(IAnticFee).interfaceId] = true;
        ds.supportedInterfaces[type(IDeploymentRefund).interfaceId] = true;
        ds.supportedInterfaces[type(IReceive).interfaceId] = true;
        ds.supportedInterfaces[type(IGroupState).interfaceId] = true;
        ds.supportedInterfaces[type(IWalletHash).interfaceId] = true;
        ds.supportedInterfaces[
            type(IAnticFeeCollectorProvider).interfaceId
        ] = true;

        // DiamondLoupe facet cut
        bytes4[] memory functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(initData.diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        LibDiamond.diamondCut(cut, address(0), "");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek

/// @dev State of the contract/group
enum StateEnum {
    UNINITIALIZED,
    OPEN,
    FORMED
}