//SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IPipeline.sol";
import "../libraries/LibFunction.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";

/**
 * @title Pipeline
 * @author Publius
 * @notice Pipeline creates a sandbox to execute any series of function calls on any series of protocols through Pipe functions.
 * Any assets left in Pipeline between transactions can be transferred out by any account.
 * Users Pipe a series of PipeCalls that each execute a function call to another protocol through Pipeline.
 * https://evmpipeline.org
 **/

contract Pipeline is IPipeline, ERC1155Holder, ERC721Holder {
    /**
     * @notice Execute a single PipeCall.
     * Supports sending Ether through msg.value
     * @param p PipeCall to execute
     * @return result return value of PipeCall
    **/
    function pipe(PipeCall calldata p)
        external
        payable
        override
        returns (bytes memory result)
    {
        result = _pipe(p.target, p.data, msg.value);
    }
    
    /**
     * @notice Execute a list of executes a list of PipeCalls.
     * @param pipes list of PipeCalls to execute
     * @return results list of return values for each PipeCall
    **/
    function multiPipe(PipeCall[] calldata pipes)
        external
        payable
        override
        returns (bytes[] memory results)
    {
        results = new bytes[](pipes.length);
        for (uint256 i = 0; i < pipes.length; i++) {
            results[i] = _pipe(pipes[i].target, pipes[i].data, 0);
        }
    }

    /**
     * @notice Execute a list of AdvancedPipeCalls.
     * @param pipes list of AdvancedPipeCalls to execute
     * @return results list of return values for each AdvancedPipeCalls
    **/
    function advancedPipe(AdvancedPipeCall[] calldata pipes)
        external
        payable
        override
        returns (bytes[] memory results) {
            results = new bytes[](pipes.length);
            for (uint256 i = 0; i < pipes.length; ++i) {
                results[i] = _advancedPipe(pipes[i], results);
            }
        }

    // Execute function call using calldata
    function _pipe(
        address target,
        bytes calldata data,
        uint256 value
    ) private returns (bytes memory result) {
        bool success;
        (success, result) = target.call{value: value}(data);
        LibFunction.checkReturn(success, result);
    }

    // Execute function call using memory
    function _pipeMem(
        address target,
        bytes memory data,
        uint256 value
    ) private returns (bytes memory result) {
        bool success;
        (success, result) = target.call{value: value}(data);
        LibFunction.checkReturn(success, result);
    }

    // Execute an AdvancedPipeCall
    function _advancedPipe(
        AdvancedPipeCall calldata p,
        bytes[] memory returnData
    ) private returns (bytes memory result) {
        uint256 value = getEthValue(p.clipboard);
        // 0x00 -> Normal pipe: Standard function call
        // else > Advanced pipe: Copy return data into function call through buildAdvancedCalldata
        if (p.clipboard[0] == 0x00) {
            result = _pipe(p.target, p.callData, value);
        } else {
            result = LibFunction.useClipboard(p.callData, p.clipboard, returnData);
            result = _pipeMem(p.target, result, value);
        }
    }

    // Extracts Ether value from a Clipboard
    // clipboard[1] indicates whether there is an Ether value in the advanced data
    // if 0x00 -> No Ether value, return 0
    // else -> return the last 32 bytes of clipboard
    function getEthValue(bytes calldata clipboard) private pure returns (uint256 value) {
        if (clipboard[1] == 0x00) return 0;
        assembly { value := calldataload(sub(add(clipboard.offset, clipboard.length), 32))}
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import {LibDiamond} from "./LibDiamond.sol";

/**
 * @title Lib Function
 * @author Publius
 **/

library LibFunction {
    /**
     * @notice Checks The return value of a any function call for success, if not returns the error returned in `results`
     * @param success Whether the corresponding function call succeeded
     * @param result The return data of the corresponding function call
    **/
    function checkReturn(bool success, bytes memory result) internal pure {
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            // Also, used in Uniswap V3 https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/Multicall.sol#L17
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }

    /**
     * @notice Gets the facet address for a given selector
     * @param selector The function selector to fetch the facet address for
     * @dev Fails if no set facet address
     * @return facet The facet address
    **/
    function facetForSelector(bytes4 selector)
        internal
        view
        returns (address facet)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facet = ds.selectorToFacetAndPosition[selector].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
    }

    /** @notice Use a Clipboard on callData to copy return values stored as returnData from any Advanced Calls
     * that have already been executed and paste them into the callData of the next Advanced Call, in a customizable manner
     * @param callData The callData bytes of next Advanced Call to paste onto
     * @param clipboard 0, 1 or n encoded paste operations and encoded ether value if using Pipeline
     * -------------------------------------------------------------------------------------
     * Clipboard stores the bytes:
     * [ Type   | Use Ether Flag*  | Type data      | Ether Value (only if flag == 1)*]
     * [ 1 byte | 1 byte           | n bytes        | 0 or 32 bytes                   ]
     * * Use Ether Flag and Ether Value are processed in Pipeline.sol (Not used in Farm). See Pipeline.getEthValue for ussage.
     * Type: 0x00, 0x01 or 0x002
     *  - 0x00: 0 Paste Operations (Logic in Pipeline.sol and FarmFacet.sol)
     *  - 0x01: 1 Paste Operation
     *  - 0x02: n Paste Operations
     * Type Data: There are two types with type data: 0x01, 0x02
     *  Type 1 (0x01): Copy 1 bytes32 from a previous function return value
     *       [ pasteParams ]
     *       [ 32 bytes ]
     *      Note: Should be encoded with ['bytes2', 'uint80', 'uint80', 'uint80']  where the first two bytes are Type and Send Ether Flag if using Pipeline
     *  Type 2 (0x02): Copy n bytes32 from a previous function return value
     *       [ Padding      | pasteParams[] ]
     *       [ 32 bytes     | 32 + 32 * n   ]
     *        * The first 32 bytes are the length of the array.
     * -------------------------------------------------------------------------------------
     * @param returnData A list of return values from previously executed Advanced Calls
     @return data The function call return datas
    **/
    function useClipboard(
        bytes calldata callData,
        bytes calldata clipboard,
        bytes[] memory returnData
    ) internal pure returns (bytes memory data) {
        bytes1 typeId = clipboard[0];
        if (typeId == 0x01) {
            bytes32 pasteParams = abi.decode(clipboard, (bytes32));
            data = LibFunction.pasteAdvancedBytes(callData, returnData, pasteParams);
        } else if (typeId == 0x02) {
            (, bytes32[] memory pasteParams) = abi.decode(
                clipboard,
                (uint256, bytes32[])
            );
            data = callData;
            for (uint256 i; i < pasteParams.length; i++)
                data = LibFunction.pasteAdvancedBytes(data, returnData, pasteParams[i]);
        } else {
            revert("Function: Advanced Type not supported");
        }
    }

    /**
     * @notice Copies 32 bytes from returnData into callData determined by pasteParams
     * @param callData The callData bytes of the next function call
     * @param returnData A list of bytes corresponding to return data from previous function calls in the transaction
     * @param pasteParams Denotes which data should be copied and where it should be pasted
     * Should be in the following format
     * [2 bytes | 10 bytes         | 10 bytes  | 10 bytes   ]
     * [ N/A    | returnDataIndex  | copyIndex | pasteIndex ]
     * @return pastedData the calldata for the next function call with bytes pasted from returnData
     **/
    function pasteAdvancedBytes(
        bytes memory callData,
        bytes[] memory returnData,
        bytes32 pasteParams
    ) internal pure returns (bytes memory pastedData) {
        // Shift `pasteParams` right 22 bytes to insolated reduceDataIndex
        bytes memory copyData = returnData[uint256((pasteParams << 16) >> 176)];
        pastedData = paste32Bytes(
            copyData,
            callData,
            uint256((pasteParams << 96) >> 176), // Isolate copyIndex
            uint256((pasteParams << 176) >> 176) // Isolate pasteIndex
        );
    }

    /**
     * @notice Copy 32 Bytes from copyData at copyIndex and paste into pasteData at pasteIndex
     * @param copyData The data bytes to copy from
     * @param pasteData The data bytes to paste into
     * @param copyIndex The index in copyData to copying from
     * @param pasteIndex The index in pasteData to paste into
     * @return pastedData The data with the copied with 32 bytes
    **/
    function paste32Bytes(
        bytes memory copyData,
        bytes memory pasteData,
        uint256 copyIndex,
        uint256 pasteIndex
    ) internal pure returns (bytes memory pastedData) {
        assembly {
            mstore(add(pasteData, pasteIndex), mload(add(copyData, copyIndex)))
        }
        pastedData = pasteData;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

/**
 * @title IPipeline
 * @author Publius
 * @notice Pipeline Interface – Pipeline creates a sandbox to execute any series of function calls on any series of protocols through Pipe functions. 
 * Any assets left in Pipeline between transactions can be transferred out by any account. 
 * Users Pipe a series of PipeCalls that each execute a function call to another protocol through Pipeline. 
 **/

// PipeCalls specify a function call to be executed by Pipeline. 
// Pipeline supports 2 types of PipeCalls: PipeCall and AdvancedPipeCall.

// PipeCall makes a function call with a static target address and callData.
struct PipeCall {
    address target;
    bytes data;
}

// AdvancedPipeCall makes a function call with a static target address and both static and dynamic callData.
// AdvancedPipeCalls support sending Ether in calls.
// [ PipeCall Type | Send Ether Flag | PipeCall Type data | Ether Value (only if flag == 1)]
// [ 1 byte        | 1 byte          | n bytes        | 0 or 32 bytes                      ]
// See LibFunction.useClipboard for more details.
struct AdvancedPipeCall {
    address target;
    bytes callData;
    bytes clipboard;
}

interface IPipeline {

    function pipe(PipeCall calldata p)
        external
        payable
        returns (bytes memory result);

    function multiPipe(PipeCall[] calldata pipes)
        external
        payable
        returns (bytes[] memory results);

    function advancedPipe(AdvancedPipeCall[] calldata pipes)
        external
        payable
        returns (bytes[] memory results);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC721Receiver.sol";

  /**
   * @dev Implementation of the {IERC721Receiver} interface.
   *
   * Accepts all token transfers. 
   * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
   */
contract ERC721Holder is IERC721Receiver {

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";

library LibDiamond {
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

    function enforceIsOwnerOrContract() internal view {
        require(msg.sender == diamondStorage().contractOwner ||
                msg.sender == address(this), "LibDiamond: Must be contract or owner"
        );
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors});
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: _diamondLoupeFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        diamondCut(cut, address(0), "");
    }

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
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

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
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

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}

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
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
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
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity =0.7.6;
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC1155Receiver.sol";
import "../../introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() internal {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
            ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}