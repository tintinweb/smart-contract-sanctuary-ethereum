// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Diamond} from "./external/diamond/Diamond.sol";
import {LibDiamondInitializer} from "./libraries/LibDiamondInitializer.sol";

/// @title Dominium - Shared ownership
/// @author Amit Molek
/// @dev Provides shared ownership functionality/logic. Powered by EIP-2535.
/// Note: This contract is designed to work with DominiumProxy.
/// Where this contract holds all the functionality/logic and the proxy holds all the storage
/// (so it is unique per group)
contract Dominium is Diamond {
    constructor(
        address admin,
        LibDiamondInitializer.DiamondInitData memory initData
    ) payable Diamond(admin) {
        LibDiamondInitializer._diamondInit(initData);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "./libraries/LibDiamond.sol";
import {IDiamondCut} from "./interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "./interfaces/IDiamondLoupe.sol";
import {LibRoles} from "../../libraries/LibRoles.sol";

contract Diamond {
    constructor(address admin) payable {
        LibRoles._grantRole(LibRoles.DEFAULT_ADMIN_ROLE, admin);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev Deposit actions for group members
interface IDeposit {
    /// @dev Emitted on member deposit
    /// @param member the member that made a deposit
    /// @param amount the deposit amount
    event Deposited(address member, uint256 amount);

    /// @notice Deposit funds
    /// @dev Should restrict deposits only to group members
    /// Emits `Deposited` event
    function deposit() external payable;

    /// @notice Deposit funds for a group member
    /// @dev Should restrict deposits only to group members
    /// Emits `Deposited` event
    function deposit(address member) external payable;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev EIP712 for Antic domain.
interface IEIP712 {
    function toTypedDataHash(bytes32 messageHash)
        external
        view
        returns (bytes32);

    function domainSeperator() external view returns (bytes32);

    function chainId() external view returns (uint256 id);

    function verifyingContract() external view returns (address);

    function salt() external pure returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

import {IWallet} from "./IWallet.sol";

/// @title Group managment interface
/// @author Amit Molek
interface IGroup {
    /// @dev Emitted when a member joins the group
    /// @param account the member that joined the group
    event Joined(address account);

    /// @dev Emitted when a member leaves the group
    /// @param account the member that leaved the group
    event Left(address account);

    /// @notice Join the group
    /// @dev The caller must pass his contribution to the group
    /// which also will represent his ownership units
    /// Emits `Joined` event
    function join(bytes memory data) external payable;

    /// @notice Leave the group
    /// @dev The member will be refunded with his join contribution
    /// Emits `Leaved` event
    function leave() external;

    /// @param account the address you want to check if it is a member
    /// @return true if `account` is a member
    function isMember(address account) external view returns (bool);

    /// @return an array with all the group's members
    function members() external view returns (address[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

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

    /// @dev Emitted on approved hash
    /// @param hash the approved hash
    event ApprovedHash(bytes32 hash);

    /// @return true if the hash has been approved
    function isHashApproved(bytes32 hash) external view returns (bool);

    /// @notice Execute proposition
    /// @param proposition the proposition to enact
    /// @param signatures a set of members EIP712 signatures on `proposition`
    /// @dev Emits `ExecutedTransaction` and `ApprovedHash` (only if `relevantHash` is passed) events
    function enactProposition(
        Proposition memory proposition,
        bytes[] memory signatures
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibDiamond} from "../external/diamond/libraries/LibDiamond.sol";
import {IDiamondLoupe} from "../external/diamond/interfaces/IDiamondLoupe.sol";
import {IDiamondCut} from "../external/diamond/interfaces/IDiamondCut.sol";
import {IERC165} from "../external/diamond/interfaces/IERC165.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {LibRoles} from "../libraries/LibRoles.sol";
import {IGroup} from "../interfaces/IGroup.sol";
import {IDeposit} from "../interfaces/IDeposit.sol";
import {IWallet} from "../interfaces/IWallet.sol";
import {IEIP712} from "../interfaces/IEIP712.sol";
import {IEIP712Transaction} from "../interfaces/IEIP712Transaction.sol";
import {IGovernance} from "../interfaces/IGovernance.sol";
import {ISignature} from "../interfaces/ISignature.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC1155TokenReceiver} from "../interfaces/IERC1155TokenReceiver.sol";
import {IERC721TokenReceiver} from "../interfaces/IERC721TokenReceiver.sol";

/// @author Amit Molek
/// @dev Implements Diamond Storage for diamond initialization
library LibDiamondInitializer {
    struct DiamondInitData {
        address admin;
        IDiamondCut diamondCutFacet;
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
        ds.supportedInterfaces[type(IAccessControl).interfaceId] = true;
        ds.supportedInterfaces[type(IGroup).interfaceId] = true;
        ds.supportedInterfaces[type(IDeposit).interfaceId] = true;
        ds.supportedInterfaces[type(IWallet).interfaceId] = true;
        ds.supportedInterfaces[type(IEIP712).interfaceId] = true;
        ds.supportedInterfaces[type(IEIP712Transaction).interfaceId] = true;
        ds.supportedInterfaces[type(IGovernance).interfaceId] = true;
        ds.supportedInterfaces[type(ISignature).interfaceId] = true;
        ds.supportedInterfaces[type(IERC1271).interfaceId] = true;
        ds.supportedInterfaces[type(IERC1155TokenReceiver).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721TokenReceiver).interfaceId] = true;

        // Roles
        LibRoles._grantRole(LibRoles.DEFAULT_ADMIN_ROLE, initData.admin);

        // DiamondCut facet cut
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(initData.diamondCutFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        // DiamondLoupe facet cut
        functionSelectors = new bytes4[](4);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(initData.diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });

        LibDiamond.diamondCut(cut, address(0), "");
    }

    function _diamondInitialized() internal view returns (bool) {
        LibDiamondInitializer.DiamondStorage storage ds = LibDiamondInitializer
            .diamondStorage();
        return ds.initialized;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

/// @author Amit Molek
/// @dev Implements Diamond Storage for access control logic
/// Based on OpenZeppelin's Access Control
library LibRoles {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    struct DiamondStorage {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.LibRoles");

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0;

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

    /// @return Returns `true` if `account` has been granted `role`
    function _hasRole(bytes32 role, address account)
        internal
        view
        returns (bool)
    {
        DiamondStorage storage ds = diamondStorage();
        return ds.roles[role].members[account];
    }

    /// @return Returns the admin role of `role`
    function _getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        DiamondStorage storage ds = diamondStorage();
        return ds.roles[role].adminRole;
    }

    /// @dev Reverts if the caller was not granted with `role`
    function _roleGuard(bytes32 role) internal view {
        LibRoles._roleGuard(role, msg.sender);
    }

    /// @dev Reverts if `account` was not granted with `role`
    function _roleGuard(bytes32 role, address account) internal view {
        if (!_hasRole(role, account)) {
            bytes memory err = abi.encodePacked(
                "RolesFacet: ",
                account,
                " lacks role: ",
                role
            );
            revert(string(err));
        }
    }

    /// @dev Use this to change the `role`'s admin role
    /// @param role the role you want to change the admin role
    /// @param adminRole the new admin role you want `role` to have
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        LibRoles.DiamondStorage storage ds = LibRoles.diamondStorage();

        bytes32 oldAdminRole = _getRoleAdmin(role);
        ds.roles[role].adminRole = adminRole;

        emit RoleAdminChanged(role, oldAdminRole, adminRole);
    }

    /// @dev Use to grant `role` to `account`
    /// No access restriction
    function _grantRole(bytes32 role, address account) internal {
        LibRoles.DiamondStorage storage ds = LibRoles.diamondStorage();

        // Early exist if the account already has role
        if (_hasRole(role, account)) {
            return;
        }

        ds.roles[role].members[account] = true;

        emit RoleGranted(role, account, msg.sender);
    }

    /// @dev Use to revoke `role` to `account`
    /// No access restriction
    function _revokeRole(bytes32 role, address account) internal {
        LibRoles.DiamondStorage storage ds = LibRoles.diamondStorage();

        if (!_hasRole(role, account)) {
            return;
        }

        ds.roles[role].members[account] = false;

        emit RoleRevoked(role, account, msg.sender);
    }
}