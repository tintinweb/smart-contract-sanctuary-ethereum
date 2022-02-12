// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { LibDiamondCut } from "./diamond/LibDiamondCut.sol";
import { IDiamondCut } from "./diamond/IDiamondCut.sol";
import { LibDiamondStorage } from "./diamond/LibDiamondStorage.sol";
import { DiamondFacet } from "./diamond/DiamondFacet.sol";
import { OwnershipFacet } from "./diamond/OwnershipFacet.sol";
import { IERC165 } from "./diamond/IERC165.sol";
import { SafeMathUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';
import { PausableFacet } from './diamond/PausableFacet.sol';
import { TokenAvgPriceFacetV1 } from './diamond/TokenAvgPriceFacetV1.sol';

// implemented TokenAvgPrice contract using Diamond
contract TokenAvgPrice {

    using SafeMathUpgradeable for uint256;

    uint256[13] public months = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    uint256[13] public monthDays = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365];
    uint256 MAX_VALID_YR = 9999;
    uint256 MIN_VALID_YR = 2022;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(uint256 timestamp) public {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        ds.owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);

        ds.months = months;
        ds.monthDays = monthDays;
        ds.MAX_VALID_YR = MAX_VALID_YR;
        ds.MIN_VALID_YR = MIN_VALID_YR;

        LibDiamondStorage.Date memory tmp = LibDiamondStorage.Date(31, 12, 2021);
        ds.state[LibDiamondStorage.hash(tmp)] = LibDiamondStorage.State(0, 0, timestamp, timestamp.add(86400));

        OwnershipFacet ownershipFacet = new OwnershipFacet();
        DiamondFacet diamondFacet = new DiamondFacet();
        PausableFacet pausableFacet = new PausableFacet();
        TokenAvgPriceFacetV1 tokenPriceV1 = new TokenAvgPriceFacetV1();

        IDiamondCut.FacetCut[] memory diamondCut = new IDiamondCut.FacetCut[](4);
        // adding diamondCut function
        diamondCut[0].facetAddress = address(diamondFacet);
        diamondCut[0].action = IDiamondCut.FacetCutAction.Add;
        diamondCut[0].functionSelectors = new bytes4[](1);
        diamondCut[0].functionSelectors[0] = DiamondFacet.diamondCut.selector;

        // adding ownership functions
        diamondCut[1].facetAddress = address(ownershipFacet);
        diamondCut[1].action = IDiamondCut.FacetCutAction.Add;
        diamondCut[1].functionSelectors = new bytes4[](2);
        diamondCut[1].functionSelectors[0] = ownershipFacet.transferOwnership.selector;
        diamondCut[1].functionSelectors[1] = ownershipFacet.getOwner.selector;

        //adding pausable functions
        diamondCut[2].facetAddress = address(pausableFacet);
        diamondCut[2].action = IDiamondCut.FacetCutAction.Add;
        diamondCut[2].functionSelectors = new bytes4[](3);
        diamondCut[2].functionSelectors[0] = pausableFacet.pause.selector;
        diamondCut[2].functionSelectors[1] = pausableFacet.paused.selector;
        diamondCut[2].functionSelectors[2] = pausableFacet.unpause.selector;

        //adding v1 functions
        diamondCut[3].facetAddress = address(tokenPriceV1);
        diamondCut[3].action = IDiamondCut.FacetCutAction.Add;
        diamondCut[3].functionSelectors = new bytes4[](3);
        diamondCut[3].functionSelectors[0] = tokenPriceV1.setPrice.selector;
        diamondCut[3].functionSelectors[1] = tokenPriceV1.viewAvgPrice.selector;
        diamondCut[3].functionSelectors[2] = tokenPriceV1.viewPrice.selector;


        LibDiamondCut.diamondCut(diamondCut,address(0), new bytes(0));

        // adding ERC165 data
        ds.supportedInterfaces[IERC165.supportsInterface.selector] = true;
        ds.supportedInterfaces[IDiamondCut.diamondCut.selector] = true;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamondStorage.DiamondStorage storage ds;
        bytes32 position = LibDiamondStorage.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Function does not exist.");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(0, 0, size)
            switch result
            case 0 {
                revert(0, size)
            }
            default {
                return(0, size)
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
*
* Implementation of diamondCut external function and DiamondLoupe interface.
/******************************************************************************/

import "./LibDiamondStorage.sol";
import "./IDiamondCut.sol";
import "./IDiamondLoupe.sol";
import "./LibDiamondCut.sol";
import "./IERC165.sol";

contract DiamondFacet is IDiamondCut, IDiamondLoupe, IERC165 {
    // Standard diamondCut external function
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
    ) external override {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(msg.sender == ds.owner, "DiamondFacet: Must own the contract");
        require(_diamondCut.length > 0, "DiamondFacet: No facets to cut");
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            LibDiamondCut.addReplaceRemoveFacetSelectors(
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        LibDiamondCut.initializeDiamondCut(_init, _calldata);
    }

    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }
    //
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds.facetFunctionSelectors[facetAddress_].functionSelectors;
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
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        facetFunctionSelectors_ = ds.facetFunctionSelectors[_facet].functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        facetAddress_ = ds.selectorToFacetAndPosition[_functionSelector].facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction { Add, Replace, Remove }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

import "./IDiamondCut.sol";

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
*
* Implementation of internal diamondCut function.
/******************************************************************************/

import "./LibDiamondStorage.sol";
import "./IDiamondCut.sol";

library LibDiamondCut {
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'FacetCut[] memory _diamondCut' instead of
    // 'FacetCut[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        require(_diamondCut.length > 0, "LibDiamondCut: No facets to cut");
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            addReplaceRemoveFacetSelectors(
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        // add or replace functions
        if (_newFacetAddress != address(0)) {
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_newFacetAddress].facetAddressPosition;
            // add new facet address if it does not exist
            if (
                facetAddressPosition == 0 && ds.facetFunctionSelectors[_newFacetAddress].functionSelectors.length == 0
            ) {
                ensureHasContractCode(_newFacetAddress, "LibDiamondCut: New facet has no code");
                facetAddressPosition = ds.facetAddresses.length;
                ds.facetAddresses.push(_newFacetAddress);
                ds.facetFunctionSelectors[_newFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            // add or replace selectors
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
                // add
                if (_action == IDiamondCut.FacetCutAction.Add) {
                    require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
                    addSelector(_newFacetAddress, selector);
                } else if (_action == IDiamondCut.FacetCutAction.Replace) {
                    // replace
                    require(
                        oldFacetAddress != _newFacetAddress,
                        "LibDiamondCut: Can't replace function with same function"
                    );
                    removeSelector(oldFacetAddress, selector);
                    addSelector(_newFacetAddress, selector);
                } else {
                    revert("LibDiamondCut: Incorrect FacetCutAction");
                }
            }
        } else {
            require(
                _action == IDiamondCut.FacetCutAction.Remove,
                "LibDiamondCut: action not set to FacetCutAction.Remove"
            );
            // remove selectors
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                removeSelector(ds.selectorToFacetAndPosition[selector].facetAddress, selector);
            }
        }
    }

    function addSelector(address _newFacet, bytes4 _selector) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        uint256 selectorPosition = ds.facetFunctionSelectors[_newFacet].functionSelectors.length;
        ds.facetFunctionSelectors[_newFacet].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _newFacet;
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = uint16(selectorPosition);
    }

    function removeSelector(address _oldFacetAddress, bytes4 _selector) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(_oldFacetAddress != address(0), "LibDiamondCut: Can't remove or replace function that doesn't exist");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_oldFacetAddress].functionSelectors.length - 1;
        bytes4 lastSelector = ds.facetFunctionSelectors[_oldFacetAddress].functionSelectors[lastSelectorPosition];
        // if not the same then replace _selector with lastSelector
        if (lastSelector != _selector) {
            ds.facetFunctionSelectors[_oldFacetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_oldFacetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_oldFacetAddress].facetAddressPosition;
            if (_oldFacetAddress != lastFacetAddress) {
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_oldFacetAddress];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                LibDiamondCut.ensureHasContractCode(_init, "LibDiamondCut: _init address has no code");
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

    function ensureHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

import { SafeMathUpgradeable } from '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';

library LibDiamondStorage {

    using SafeMathUpgradeable for uint256;

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct State {
        uint256 price;  // price that day
        uint256 priceSum;   // sum of price from 01/01/2022
        uint256 start; // start timestamp of day
        uint256 end;   //end timestamp of day
    }

    struct Date {
        uint256 d;
        uint256 m;
        uint256 y;
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the facet address in the facetAddresses array
        // and the position of the selector in the facetSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // date state including price, priceSum, start, end
        mapping(uint256 => State) state;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // address of contract owner
        address owner;

        uint256[13] months;
        uint256[13] monthDays;
        uint256 MAX_VALID_YR;
        uint256 MIN_VALID_YR;

        bool _paused;
    }

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function hash(Date memory date) internal pure returns(uint256) {
        return date.y * 10000 + date.m * 100 + date.d;
    }

    function getPreviousDate(Date memory date) internal view returns (Date memory) {
        LibDiamondStorage.DiamondStorage storage ds = diamondStorage();
        if(date.d > 1) return Date(date.d - 1, date.m, date.y);
        if(date.m > 1) {
            uint256 additional = 0;
            if((date.m - 1) == 2 && isLeap(date.y) == true) additional = 1;
            return Date(ds.months[date.m - 1] + additional, date.m - 1, date.y);
        }
        return Date(31, 12, date.y - 1);
    }

    function isLeap(uint256 y) internal pure returns (bool) {
        // Return true if year
        // is a multiple of 4 and
        // not multiple of 100.
        // OR year is multiple of 400.
        return (((y % 4 == 0) && (y % 100 != 0)) || (y % 400 == 0));
    }

    function countLeapYearDays(Date memory date) internal pure returns (uint256) {
        uint256 yy = date.y;
        if(date.m <= 2) yy = yy.sub(1);
        return ( (yy / 4) - (yy / 100) + (yy / 400) );
    }

    function isValidDate(Date memory date) internal view returns (bool) {
        LibDiamondStorage.DiamondStorage storage ds = diamondStorage();
        // If year, month and day
        // are not in given range
        if (date.y > ds.MAX_VALID_YR || date.y < ds.MIN_VALID_YR) return false;
        if (date.m < 1 || date.m > 12) return false;
        if (date.d < 1 || date.d > 31) return false;

        if (date.m == 2) {
            if (isLeap(date.y)) return (date.d <= 29);
            else return (date.d <= 28);
        } else {
            return date.d <= ds.months[date.m];
        }
    }

    function getDay(Date memory date1, Date memory date2) internal view returns(uint256) {
        LibDiamondStorage.DiamondStorage storage ds = diamondStorage();
        uint256 dayCount1 = (date1.y * 365);
        dayCount1 = dayCount1.add(ds.monthDays[date1.m]);
        dayCount1 = dayCount1.add(date1.d);
        dayCount1 = dayCount1.add(countLeapYearDays(date1));

        uint256 dayCount2 = (date2.y * 365);
        dayCount2 = dayCount2.add(ds.monthDays[date2.m]);
        dayCount2 = dayCount2.add(date2.d);
        dayCount2 = dayCount2.add(countLeapYearDays(date2));

        if(dayCount1 > dayCount2) return dayCount1.sub(dayCount2);
        return dayCount2.sub(dayCount1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { LibDiamondStorage } from "./LibDiamondStorage.sol";

contract OwnershipFacet {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice This function transfers ownership to self. This is done
     *         so that we can ensure upgrades (using diamondCut) and
     *         various other critical parameter changing scenarios
     *         can only be done via governance (a facet).
     */
    function transferOwnership(address to) external {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(msg.sender == ds.owner, "Not authorized");
        ds.owner = to;

        emit OwnershipTransferred(msg.sender, address(this));
    }

    /**
     * @notice This gets the admin for the diamond.
     * @return Admin address.
     */
    function getOwner() external view returns (address) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        return ds.owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { LibDiamondStorage } from "./LibDiamondStorage.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract PausableFacet {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        return ds._paused;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(ds._paused == false, "pausable: already paused");
        ds._paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(ds._paused == true, "pausable: already unpaused");
        ds._paused = false;
        emit Unpaused(msg.sender);
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import { LibDiamondStorage } from "./LibDiamondStorage.sol";

contract TokenAvgPriceFacetV1 {

    using SafeMathUpgradeable for uint256;

    function setPrice(LibDiamondStorage.Date memory date, uint256 price) external {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(ds._paused == false, "TokenAvgPriceFacetV1: contract paused");
        require(LibDiamondStorage.isValidDate(date) == true, "TokenAvgPriceFacetV1: invalid date");
        LibDiamondStorage.Date memory _pre = LibDiamondStorage.getPreviousDate(date);
        require(_pre.y < 2022 || _pre.y >= 2022 && ds.state[LibDiamondStorage.hash(_pre)].price != 0, "TokenAvgPriceFacetV1: previous day price not set");
        ds.state[LibDiamondStorage.hash(date)] = LibDiamondStorage.State(
            price,
            ds.state[LibDiamondStorage.hash(_pre)].priceSum.add(price),
            ds.state[LibDiamondStorage.hash(_pre)].end,
            ds.state[LibDiamondStorage.hash(_pre)].end.add(86400)
        );
    }

    function viewPrice(LibDiamondStorage.Date memory date) public view returns (uint256) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(LibDiamondStorage.isValidDate(date) == true, "TokenAvgPriceFacetV1: invalid date");
        require(ds.state[LibDiamondStorage.hash(date)].price != 0, "TokenAvgPriceFacetV1: price not set");
        return ds.state[LibDiamondStorage.hash(date)].price;
    }

    function viewAvgPrice(LibDiamondStorage.Date memory date1, LibDiamondStorage.Date memory date2) public view returns (uint256) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();
        require(LibDiamondStorage.isValidDate(date1) == true, "TokenAvgPriceFacetV1: invalid from date");
        require(LibDiamondStorage.isValidDate(date2) == true, "TokenAvgPriceFacetV1: invalid to date");
        require(ds.state[LibDiamondStorage.hash(date1)].price != 0, "TokenAvgPriceFacetV1: price not yet set");
        require(ds.state[LibDiamondStorage.hash(date2)].price != 0, "TokenAvgPriceFacetV1: price not yet set");

        uint256 priceSum = 0;
        if(ds.state[LibDiamondStorage.hash(date1)].priceSum > ds.state[LibDiamondStorage.hash(date2)].priceSum) {
            priceSum = ds.state[LibDiamondStorage.hash(date1)].priceSum.sub(ds.state[LibDiamondStorage.hash(date2)].priceSum).add(ds.state[LibDiamondStorage.hash(date2)].price);
        } else {
            priceSum = ds.state[LibDiamondStorage.hash(date2)].priceSum.sub(ds.state[LibDiamondStorage.hash(date1)].priceSum).add(ds.state[LibDiamondStorage.hash(date1)].price);
        }
        uint256 numDays = LibDiamondStorage.getDay(date1, date2);
        return priceSum.div(numDays);
    }
}