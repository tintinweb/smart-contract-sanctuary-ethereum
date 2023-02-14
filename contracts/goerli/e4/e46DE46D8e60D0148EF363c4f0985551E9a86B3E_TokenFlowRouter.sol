// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IDiamond } from "./interfaces/IDiamond.sol";
import { LibDiamond } from "./libraries/LibDiamond.sol";
import { IDiamondCut } from "./interfaces/IDiamondCut.sol";


/**
 * @title Diamond
 * @author Hysland Finance
 * @notice An implementation of an `ERC2535` Diamond.
 *
 * See details of the `ERC2535` diamond standard at https://eips.ethereum.org/EIPS/eip-2535.
 *
 * On top of the vanilla implementation, this version supports [`multicall()`](#multicall), allowing users to batch multiple calls in one transaction.
 *
 * Security warning: `delegatecall` in a loop. Facets should not use `msg.value`.
 *
 * EVM note: if you pass any gas token to the diamond, the diamond cannot delegatecall a nonpayable function. All non-view functions in facets should be marked as payable. Even if the function does not require or expect the gas token, it may be multicalled with a function that does.
 */
contract Diamond is IDiamond {

    /// @notice Emitted when the diamond is cut.
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

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

    /**
     * @notice Constructs the Diamond contract.
     * @param contractOwner The owner of the new contract.
     * @param diamondCutFacet The address of a [DiamondCutFacet](./facets/DiamondCutFacet).
     */
    constructor(address contractOwner, address diamondCutFacet) payable {
        // due to a known solidity compiler optimizer bug, using libraries in the constructor results in large amounts of unreachable code
        // to save gas on deployment, inline the library functions. much harder to read but worth the savings
        // also able to cut down on code as we're adding the zero index facet and selector
        // checks
        require(contractOwner != address(0x0), "Diamond: zero address owner");
        uint256 contractSize;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(diamondCutFacet)
        }
        require(contractSize > 0, "Diamond: no code add");
        // get storage
        bytes32 DIAMOND_STORAGE_POSITION = keccak256("libdiamond.diamond.storage");
        DiamondStorage storage ds;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := DIAMOND_STORAGE_POSITION
        }
        // set owner
        ds.contractOwner = contractOwner;
        // add multicall as immutible facet
        ds.facetAddresses.push(address(this));
        bytes4 multicallSelector = IDiamond.multicall.selector;
        bytes4[] memory multicallSelectors = new bytes4[](1);
        multicallSelectors[0] = multicallSelector;
        ds.facetFunctionSelectors[address(this)].functionSelectors.push(multicallSelector);
        ds.selectorToFacetAndPosition[multicallSelector].facetAddress = address(this);
        // add diamond cut facet
        ds.facetFunctionSelectors[diamondCutFacet].facetAddressPosition = 1;
        ds.facetAddresses.push(diamondCutFacet);
        bytes4 diamondCutSelector = IDiamondCut.diamondCut.selector;
        bytes4[] memory diamondCutSelectors = new bytes4[](1);
        diamondCutSelectors[0] = diamondCutSelector;
        ds.facetFunctionSelectors[diamondCutFacet].functionSelectors.push(diamondCutSelector);
        ds.selectorToFacetAndPosition[diamondCutSelector].facetAddress = diamondCutFacet;
        // emit event
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(this),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: multicallSelectors
        });
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: diamondCutSelectors
        });
        emit DiamondCut(cut, address(0), "");
    }

    /***************************************
    EXTERNAL FUNCTIONS
    ***************************************/

    /**
     * @notice Receives and executes a batch of function calls on this contract.
     * @param data A list of function calls to execute.
     * @return results The results of each function call.
     */
    function multicall(bytes[] memory data) external payable override returns (bytes[] memory results) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; ) {
            bytes memory nextcall = data[i];
            // get function selector
            bytes4 msgsig;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                msgsig := mload(add(nextcall, 32))
            }
            // get facet from function selector
            address facet = ds.selectorToFacetAndPosition[msgsig].facetAddress;
            require(facet != address(0), "Diamond: function dne");
            // execute external function from facet using delegatecall and return any value
            results[i] = functionDelegateCall(facet, nextcall);
            unchecked { i++; }
        }
        return results;
    }

    /**
     * @notice Executes an arbitrary function call on this contract.
     * @param data The data for the function to call.
     * @return result The result of the function call.
     */
    // solhint-disable-next-line no-complex-fallback
    fallback(bytes calldata data) external payable override returns (bytes memory result) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: function dne");
        // execute external function from facet using delegatecall and return any value
        return functionDelegateCall(facet, data);
    }

    /**
     * @notice Allows this contract to receive the gas token.
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable override {}

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Safely performs a Solidity function call using a low level `delegatecall`.
     * @dev If `target` reverts with a revert reason, it is bubbled up by this function.
     * @param target The address of the contract to `delegatecall`.
     * @param data The data to pass to the target.
     * @return result The result of the function call.
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory result) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        if(success) {
            return returndata;
        } else {
            // look for revert reason and bubble it up if present
            if(returndata.length > 0) {
                // the easiest way to bubble the revert reason is using memory via assembly
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("Diamond: failed delegatecall");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IDiamond
 * @author Hysland Finance
 * @notice An implementation of an `ERC2535` Diamond.
 *
 * See details of the `ERC2535` diamond standard at https://eips.ethereum.org/EIPS/eip-2535.
 *
 * On top of the vanilla implementation, this version supports [`multicall()`](#multicall), allowing users to batch multiple calls in one transaction.
 *
 * Security warning: `delegatecall` in a loop. Facets should not use `msg.value`.
 *
 * EVM note: if you pass any gas token to the diamond, the diamond cannot delegatecall a nonpayable function. All non-view functions in facets should be marked as payable. Even if the function does not require or expect the gas token, it may be multicalled with a function that does.
 */
interface IDiamond {

    // note that this interface is not the same as the version given in the standard
    // the true interface is scattered across multiple files
    // this is used to produce a minimal abi that can be used for the majority of mutator functions

    /**
     * @notice Receives and executes a batch of function calls on this contract.
     * @param data A list of function calls to execute.
     * @return results The results of each function call.
     */
    function multicall(bytes[] memory data) external payable returns (bytes[] memory results);

    /**
     * @notice Executes an arbitrary function call on this contract.
     * @param data The data for the function to call.
     * @return result The result of the function call.
     */
    fallback(bytes calldata data) external payable returns (bytes memory result);

    /**
     * @notice Allows this contract to receive the gas token.
     */
    receive() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


/**
 * @title IDiamondCut
 * @author Hysland Finance
 * @notice A set of functions that allow modifications of an `ERC2535` Diamond.
 *
 * See details of the `ERC2535` diamond standard at https://eips.ethereum.org/EIPS/eip-2535.
 *
 * The owner of the diamond may use [`diamondCut()`](#diamondcut) to add, replace, or remove functions.
 */
interface IDiamondCut {

    /// @notice Emitted when the diamond is cut.
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Add=0, Replace=1, Remove=2
    enum FacetCutAction {Add, Replace, Remove}

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /**
     * @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall.
     * @dev Add access control in implementation.
     * @param _diamondCut Contains the facet addresses and function selectors.
     * @param _init The address of the contract or facet to execute `_calldata`.
     * @param _calldata A function call, including function selector and arguments.
     */
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { IDiamondCut } from "./../interfaces/IDiamondCut.sol";


/**
 * @title LibDiamond
 * @author Hysland Finance
 * @notice A library for the core diamond functionality.
 */
library LibDiamond {

    /***************************************
    STORAGE FUNCTIONS
    ***************************************/

    bytes32 constant internal DIAMOND_STORAGE_POSITION = keccak256("libdiamond.diamond.storage");

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

    /**
     * @notice Returns the `DiamondStorage` struct.
     * @return ds The `DiamondStorage` struct.
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }

    /***************************************
    OWNERSHIP FUNCTIONS
    ***************************************/

    /// @dev Emitted when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Get the address of the owner.
     * @return contractOwner_ The address of the owner.
     */
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    /**
     * @notice Reverts if `msg.sender` is not the contract owner.
     */
    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: !owner");
    }

    /**
     * @notice Set the address of the new owner of the contract.
     * @dev Set _newOwner to address(0) to renounce any ownership.
     * @param _newOwner The address of the new owner of the contract.
     */
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /***************************************
    DIAMOND CUT FUNCTIONS
    ***************************************/

    /// @notice Emitted when the diamond is cut.
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    /**
     * @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall.
     * @param _diamondCut Contains the facet addresses and function selectors.
     * @param _init The address of the contract or facet to execute `_calldata`.
     * @param _calldata A function call, including function selector and arguments.
     */
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex = 0; facetIndex < _diamondCut.length; ) {
            // safe to assume valid FacetCutAction
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            }
            unchecked { facetIndex++; }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    /**
     * @notice Adds one or more functions from the facet to this diamond.
     * @param _facetAddress The address of the facet with the logic.
     * @param _functionSelectors The function selectors to add to this diamond.
     */
    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamond: no selectors to cut");
        require(_facetAddress != address(0), "LibDiamond: zero address facet");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorPosition256 = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length;
        uint96 selectorPosition96 = uint96(selectorPosition256);
        // add new facet address if it does not exist
        if (selectorPosition256 == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex = 0; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamond: add duplicate func");
            addFunction(ds, selector, selectorPosition96, _facetAddress);
            unchecked { selectorPosition96++; }
            unchecked { selectorIndex++; }
        }
    }

    /**
     * @notice Replaces one or more functions from the facet to this diamond.
     * @param _facetAddress The address of the facet with the logic.
     * @param _functionSelectors The function selectors to replace on this diamond.
     */
    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamond: no selectors to cut");
        require(_facetAddress != address(0), "LibDiamond: zero address facet");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorPosition256 = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length;
        uint96 selectorPosition96 = uint96(selectorPosition256);
        // add new facet address if it does not exist
        if (selectorPosition256 == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex = 0; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamond: replace func same");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition96, _facetAddress);
            unchecked { selectorPosition96++; }
            unchecked { selectorIndex++; }
        }
    }

    /**
     * @notice Removes one or more functions from the facet from this diamond.
     * @param _facetAddress The address of the facet with the logic.
     * @param _functionSelectors The function selectors to remove from this diamond.
     */
    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamond: no selectors to cut");
        require(_facetAddress == address(0), "LibDiamond: remove !zero facet");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        for (uint256 selectorIndex = 0; selectorIndex < _functionSelectors.length; ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
            unchecked { selectorIndex++; }
        }
    }

    /**
     * @notice Adds a new facet to the list of known facets.
     * @param ds The DiamondStorage struct.
     * @param _facetAddress The address of the facet to add.
     */
    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamond: no code add");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    /**
     * @notice Adds a function from the facet to this diamond.
     * @param ds The DiamondStorage struct.
     * @param _selector The function selector to add to this diamond.
     * @param _selectorPosition The position in facetFunctionSelectors.functionSelectors array.
     * @param _facetAddress The address of the facet with the logic.
     */
    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    /**
     * @notice Removes a function from the facet from this diamond.
     * @param ds The DiamondStorage struct.
     * @param _facetAddress The address of the facet with the logic.
     * @param _selector The function selector to add to this diamond.
     */
    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "LibDiamond: remove func dne");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamond: remove immut func");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];
        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    /***************************************
    HELPER FUNCTIONS
    ***************************************/

    /**
     * @notice Optionally delegatecalls a contract on diamond cut.
     * @param _init The address of the contract to delegatecall to or zero to skip.
     * @param _calldata The data to send to _init.
     */
    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamond: no code init");
        functionDelegateCall(_init, _calldata);
    }

    /**
     * @notice Reverts execution if the address has no code.
     * @param _contract The address to query code.
     * @param _errorMessage The revert message.
     */
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

    /**
     * @notice Safely performs a Solidity function call using a low level `delegatecall`.
     * @dev If `target` reverts with a revert reason, it is bubbled up by this function.
     * @param target The address of the contract to `delegatecall`.
     * @param data The data to pass to the target.
     * @return result The result of the function call.
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory result) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        if(success) {
            return returndata;
        } else {
            // look for revert reason and bubble it up if present
            if(returndata.length > 0) {
                // the easiest way to bubble the revert reason is using memory via assembly
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("LibDiamond: init func failed");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Diamond } from "./Diamond.sol";


/**
 * @title TokenFlowRouter
 * @author Hysland Finance
 * @notice The entry point for all TokenFlowRouter functionality.
 *
 * TokenFlowRouter is an `ERC2535` Diamond. All of the diamond functionality is defined in [`Diamond`](./Diamond). The diamond then delegates to facets defined in `facets/`.
 *
 * See details of the `ERC2535` diamond standard at https://eips.ethereum.org/EIPS/eip-2535.
 */
contract TokenFlowRouter is Diamond {

    /**
     * @notice Constructs the TokenFlowRouter contract.
     * @param contractOwner The owner of the new contract.
     * @param diamondCutFacet The address of a [DiamondCutFacet](./facets/DiamondCutFacet).
     */
    // solhint-disable-next-line no-empty-blocks
    constructor(address contractOwner, address diamondCutFacet) payable Diamond(contractOwner, diamondCutFacet) {}
}