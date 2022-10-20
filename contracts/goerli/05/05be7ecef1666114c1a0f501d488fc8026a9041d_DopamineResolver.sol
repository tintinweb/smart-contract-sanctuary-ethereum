// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IDopamineRegistry} from "../interfaces/IDopamineRegistry.sol";
import {IDopamineRegistrar} from "../interfaces/IDopamineRegistrar.sol";
import {IDopamineRegistrarController} from "../interfaces/IDopamineRegistrarController.sol";
import {IDopamineResolver} from "../interfaces/resolvers/IDopamineResolver.sol";
import {Multicallable} from "./Multicallable.sol";
import {PNFTResolver} from "./PNFTResolver.sol";
import {TextResolver} from "./TextResolver.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

contract DopamineResolver is Multicallable, PNFTResolver, TextResolver {

    IDopamineRegistry immutable registry;
    IDopamineRegistrar immutable registrar;
    IDopamineRegistrarController immutable controller;

    /// @notice Instantiates a Dopamine Resolver contract.
    /// @param registry_ The Dopamine registry contract address.
    /// @param registrar_ The Dopamine registrar contract address.
    /// @param controller_ The Dopamine registrar controller contract address.
    constructor(
        IDopamineRegistry registry_,
        IDopamineRegistrar registrar_,
        IDopamineRegistrarController controller_
    ) {
        registry = registry_;
        registrar = registrar_;
        controller = controller_;
    }

    function isAuthorized(bytes32 chip, uint96 permissions) internal view override returns (bool) {
        if (
            msg.sender == address(controller) || 
            msg.sender == registry.owner(chip)
        ) {
            return true;
        }
        address registrant = registrar.ownerOf(uint256(chip));
        return (msg.sender == registrant && registrar.checkPermissions(chip, permissions));
    }

    function supportsInterface(bytes4 id) public pure override(Multicallable, PNFTResolver, TextResolver) returns (bool) {
        return super.supportsInterface(id);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IDopamineRegistryEventsAndErrors} from "./IDopamineRegistryEventsAndErrors.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Registry Interface
interface IDopamineRegistry is IDopamineRegistryEventsAndErrors {

    /// @notice A Dopamine registry record, composed of an owner and resolver.
    struct Record {
        address owner;
        address resolver;
    }

    /// @notice Sets a chip record's owner and resolver.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param owner The address of the owner for the record.
    /// @param resolver The address of the resolver for the record.
    function setRecord(
        bytes32 chip,
        address owner,
        address resolver
    ) external;

    /// @notice Sets a chip record's resolver.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param resolver The address of the resolver for the record.
    function setResolver(
        bytes32 chip,
        address resolver
    ) external;

    /// @notice Sets a chip record's owner.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param owner The address of the owner for the record.
    function setOwner(
        bytes32 chip,
        address owner
    ) external;

    /// @notice Gets the owner address of a chip record.
    /// @param chip The keccak-256 hash of the chip public key.
    function owner(bytes32 chip) external view returns (address);

    /// @notice Gets the resolver address of a chip record.
    /// @param chip The keccak-256 hash of the chip public key.
    function resolver(bytes32 chip) external returns (address);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IERC721Binder} from "./IERC721Binder.sol";
import {IERC1155Binder} from "./IERC1155Binder.sol";
import {IDopamineRegistrarEventsAndErrors} from "./IDopamineRegistrarEventsAndErrors.sol";
import {Signature} from "../DopamineRegistrarConstants.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Registrar Interface
interface IDopamineRegistrar is IDopamineRegistrarEventsAndErrors {

    /// @notice Gets the owner address for a specific chip identifier.
    /// @param id The uint256 identifier of the chip being queried.
    function ownerOf(uint256 id) external view returns (address);

    /// @notice Gets the metadata URI associated with a registered chip.
    /// @param id The identifier of the chip being queried.
    function uri(uint256 id) external view returns (string memory);

    /// @notice Checks whether registrar permissions are set for a chip.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param permissions The permissions being checked for.
    /// @return True if the permissions are set, False otherwise.
    function checkPermissions(bytes32 chip, uint96 permissions) external view returns (bool);

    /// @notice Registers a chip to the Dopamine registry.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param registrant The address of the new chip registrant.
    /// @param resolver The address of the resolver the chip record points to.
    /// @param perms The registered chip registrar permissions.
    function register(
        bytes32 chip,
        address registrant,
        address resolver,
        uint96 perms
    ) external;

    /// @notice Transfers registration of a chip to a new registrant.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param claimant The address of the new registrant.
    /// @param scanSignature The chip scanner's ECDSA signature.
    /// @param claimSignature The claimant's ECDSA signature.
    function claim(
        bytes32 chip,
        address claimant,
        Signature calldata scanSignature,
        Signature calldata claimSignature
    ) external;

    /// @notice Sets an authorized signer for the registrar.
    /// @param signer The address of an approved registration signer.
    /// @param setting Whether the signer may authorize registrations (boolean).
    function setSigner(address signer, bool setting) external;

    /// @notice Sets the controller operation status for the registrar.
    /// @param controller The address of the controller being set.
    /// @param setting A boolean indicating whether the controller is on or off.
    function setController(address controller, bool setting) external;

    /// @notice Sets the resolver for a given chip's record.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param resolver The address of the resolver being set.
    function setResolver(bytes32 chip, address resolver) external;

    /// @notice Sets registrar permissions for a given chip.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param permissions The permissions to set for the chip.
    function setPermissions(bytes32 chip, uint96 permissions) external;

    /// @notice Clears registrar permissions for a given chip.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param permissions The permissions to unset for the chip.
    function unsetPermissions(bytes32 chip, uint96 permissions) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IDopamineRegistrarControllerEventsAndErrors} from "./IDopamineRegistrarControllerEventsAndErrors.sol";
import {Signature, BindableType} from "../DopamineRegistrarConstants.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Registrar Controller Interface
interface IDopamineRegistrarController is IDopamineRegistrarControllerEventsAndErrors {

    /// @notice Representation of a bindable token meant to bind to a chip PNFT.
    struct Bindable {
        BindableType bindableType;
        address token;
        uint256 id;
        uint256 amount;
    }

    /// @notice Registers and bundles a chip on behalf of a registrant.
    /// @param chip A keccak-256 hash of the chip public key.
    /// @param registrant Address of the new chip registrant.
    /// @param resolver Address of the resolver the chip will point to.
    /// @param perms The registrar permissions to give to the registered chip.
    /// @param data Data to pass to the chip for resolver initialization.
    /// @param bindables List of bindable tokens to bundle with the chip.
    /// @param signature The registration authorization signature.
	function registerAndBundle(
        bytes32 chip,
        address registrant,
        address resolver,
        uint96 perms,
		bytes[] calldata data,
        Bindable[] calldata bindables,
        Signature calldata signature
    ) external;
}

pragma solidity ^0.8.16;

import {IMulticallable} from "./IMulticallable.sol";
import {IPNFTResolver} from "./IPNFTResolver.sol";
import {ITextResolver} from "./ITextResolver.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

interface IDopamineResolver is IMulticallable, IPNFTResolver, ITextResolver {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IMulticallable} from "../interfaces/resolvers/IMulticallable.sol";

/// @title Multicallable Interface
abstract contract Multicallable is IMulticallable {

    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _MULTICALLABLE_INTERFACE_ID = 0x0;

    function multicall(
        bytes32 chip,
        bytes[] calldata data
    ) public returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; ++i) {
            if (bytes32(data[i][4:36]) != chip) {
                revert ChipIdentifierMismatch();
            }
            (bool success, bytes memory result) = address(this).delegatecall(
                data[i]
            );
            if (!success) {
                revert ResolverCallFail();
            }
            results[i] = result;
        }
        return results;
    }
    
    function supportsInterface(bytes4 id) external pure virtual returns (bool) {
        return id == _ERC165_INTERFACE_ID || id == _MULTICALLABLE_INTERFACE_ID;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {BaseResolver} from "./BaseResolver.sol";
import {IPNFTResolver} from "../interfaces/resolvers/IPNFTResolver.sol";
import {REGISTRAR_ALLOW_SET_PNFT} from "../DopamineRegistrarConstants.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title PNFT Resolver Interface
abstract contract PNFTResolver is IPNFTResolver, BaseResolver {

    bytes4 private constant _PNFT_RESOLVER_INTERFACE_ID = 0x0;

    mapping(bytes32 => IPNFTResolver.NFT) pnfts;

    function setPNFT(
        bytes32 chip,
        address token,
        uint256 id
    ) public authorizedOnly(chip, REGISTRAR_ALLOW_SET_PNFT) {
        pnfts[chip] = IPNFTResolver.NFT(token, id);
        emit PNFTChanged(chip, token, id);
    }
    
    function PNFT(bytes32 chip) external view returns (address, uint256) {
        IPNFTResolver.NFT memory pnft = pnfts[chip];
        return (pnft.token, pnft.id);
    }

    function supportsInterface(bytes4 id) public pure virtual override(IERC165, BaseResolver) returns (bool) {
        return id == _PNFT_RESOLVER_INTERFACE_ID || super.supportsInterface(id);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {BaseResolver} from "./BaseResolver.sol";
import {ITextResolver} from "../interfaces/resolvers/ITextResolver.sol";
import {REGISTRAR_ALLOW_SET_TEXT} from "../DopamineRegistrarConstants.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Text Resolver Interface
abstract contract TextResolver is ITextResolver, BaseResolver {

    bytes4 private constant _TEXT_RESOLVER_INTERFACE_ID = 0x0;

    mapping(bytes32 => mapping(string => string)) textRecords;
    
    function setText(
        bytes32 chip,
        string calldata key,
        string calldata value
    ) external authorizedOnly(chip, REGISTRAR_ALLOW_SET_TEXT) {
        textRecords[chip][key] = value;
        emit TextChanged(chip, key, value);
    }

    function text(
        bytes32 chip,
        string calldata key
    ) external view returns (string memory) {
        return textRecords[chip][key];
    }

    function supportsInterface(bytes4 id) public pure virtual override(IERC165, BaseResolver) returns (bool) {
        return id == _TEXT_RESOLVER_INTERFACE_ID || super.supportsInterface(id);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Registry Events & Errors Interface
interface IDopamineRegistryEventsAndErrors {

    /// @notice Emits when the owner of a chip record is a set.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param owner The record owner address to set.
    event OwnerSet(bytes32 chip, address owner);

    /// @notice Emits when the resolver of a chip record is set.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param resolver The record resolver address to set.
    event ResolverSet(bytes32 chip, address resolver);

    /// @notice Sender is not authorized to perform the call.
    error SenderUnauthorized();
}

pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IERC721BinderErrors} from "./IERC721BinderErrors.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @dev Note: the ERC-165 identifier for this interface is 0x2ac2d2bc.
interface IERC721Binder is IERC165, IERC721BinderErrors {

    /// @notice Handles the binding of an IERC721Bindable-compliant NFT.
    /// @dev An IERC721Bindable-compliant smart contract MUST call this function
    ///  at the end of a `bind` after delegating ownership to the asset owner.
    ///  The function MUST revert if `to` is not the asset owner of `bindId` or 
    ///  if asset `bindId` is not a valid asset. The function MUST revert if it 
    ///  rejects the bind. If accepting the bind, the function MUST return 
    /// `bytes4(keccak256("onERC721Bind(address,address,address,uint256,uint256,bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the binding NFT is `msg.sender`.
    /// @param operator The address responsible for initiating the bind.
    /// @param from The address which owns the unbound NFT.
    /// @param to The address which owns the asset being bound to.
    /// @param tokenId The identifier of the NFT being bound.
    /// @param bindId The identifier of the asset being bound to.
    /// @param data Additional data sent along with no specified format.
    /// @return `bytes4(keccak256("onERC721Bind(address,address,address,uint256,uint256,bytes)"))`
    function onERC721Bind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        bytes calldata data
    ) external returns (bytes4);

    /// @notice Handles the unbinding of an IERC721Bindable-compliant NFT.
    /// @dev An IERC721Bindable-compliant smart contract MUST call this function
    ///  at the end of an `unbind` after revoking delegated asset ownership.
    ///  The function MUST revert if `from` is not the asset owner of `bindId`
    ///  or if `bindId` is not a valid asset. The function MUST revert if it 
    ///  rejects the unbind. If accepting the unbind, the function MUST return
    ///  `bytes4(keccak256("onERC721Unbind(address,address,address,uint256,uint256,bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the unbinding NFT is `msg.sender`.
    /// @param from The address which owns the asset the NFT is bound to.
    /// @param to The address which will own the NFT once unbound.
    /// @param tokenId The identifier of the NFT being unbound.
    /// @param bindId The identifier of the asset being unbound from.
    /// @param data Additional data with no specified format.
    /// @return `bytes4(keccak256("onERC721Unbind(address,address,address,uint256,uint256,bytes)"))`
    function onERC721Unbind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        bytes calldata data
    ) external returns (bytes4);

    /// @notice Gets the owner address of the asset represented by id `bindId`.
    /// @dev Queries for assets assigned to the zero address MUST throw.
    /// @param bindId The identifier of the asset whose owner is being queried.
    /// @return The address of the owner of the asset.
    function ownerOf(uint256 bindId) external view returns (address);

    /// @notice Checks if an operator can act on behalf of an asset owner.
    /// @param owner The address that owns an asset.
    /// @param operator The address that acts on behalf of owner `owner`.
    /// @return True if `operator` can act on behalf of `owner`, else False.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

}

pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IERC1155BinderErrors} from "./IERC1155BinderErrors.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @dev Note: the ERC-165 identifier for this interface is 0x6fc97e78.
interface IERC1155Binder is IERC165, IERC1155BinderErrors {

    /// @notice Handles binding of an IERC1155Bindable-compliant token type.
    /// @dev An IERC1155Bindable-compliant smart contract MUST call this 
    ///  function at the end of a `bind` after delegating ownership to the asset 
    ///  owner. The function MUST revert if `to` is not the asset owner of
    ///  `bindId`, or if `bindId` is not a valid asset. The function MUST revert
    ///  if it rejects the bind. If accepting the bind, the function MUST return
    ///  `bytes4(keccak256("onERC1155Bind(address,address,address,uint256,uint256,uint256,bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the binding token is `msg.sender`.
    /// @param operator The address responsible for binding.
    /// @param from The address which owns the unbound tokens.
    /// @param to The address which owns the asset being bound to.
    /// @param tokenId The identifier of the token type being bound.
    /// @param bindId The identifier of the asset being bound to.
    /// @param data Additional data sent along with no specified format.
    /// @return `bytes4(keccak256("onERC1155Bind(address,address,address,uint256,uint256,uint256,bytes)"))`
    function onERC1155Bind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 bindId,
        bytes calldata data
    ) external returns (bytes4);

    /// @notice Handles binding of multiple IERC1155Bindable-compliant tokens 
    ///  `tokenIds` to multiple assets `bindIds`.
    /// @dev An IERC1155Bindable-compliant smart contract MUST call this 
    ///  function at the end of a `batchBind` after delegating ownership of 
    ///  multiple token types to the asset owner. The function MUST revert if 
    ///  `to` is not the asset owner of `bindId`, or if `bindId` is not a valid 
    ///  asset. The function MUST revert if it rejects the binds. If accepting 
    ///  the binds, the function MUST return `bytes4(keccak256("onERC1155BatchBind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the binding token is `msg.sender`.
    /// @param operator The address responsible for performing the binds.
    /// @param from The address which owns the unbound tokens.
    /// @param to The address which owns the assets being bound to.
    /// @param tokenIds The list of token types being bound.
    /// @param amounts The number of tokens for each token type being bound.
    /// @param bindIds The identifiers of the assets being bound to.
    /// @param data Additional data sent along with no specified format.
    /// @return `bytes4(keccak256("onERC1155Bind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
    function onERC1155BatchBind(
        address operator,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata bindIds,
        bytes calldata data
    ) external returns (bytes4);

    /// @notice Handles unbinding of an IERC1155Bindable-compliant token type.
    /// @dev An IERC1155Bindable-compliant contract MUST call this function at
    ///  the end of an `unbind` after revoking delegated asset ownership. The 
    ///  function MUST revert if `from` is not the asset owner of `bindId`, 
    ///  or if `bindId` is not a valid asset. The function MUST revert if it
    ///  rejects the unbind. If accepting the unbind, the function MUST return
    ///  `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256,uint256,uint256,bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the unbinding token is `msg.sender`.
    /// @param operator The address responsible for performing the unbind.
    /// @param from The address which owns the asset the token type is bound to.
    /// @param to The address which will own the tokens once unbound.
    /// @param tokenId The token type being unbound.
    /// @param amount The number of tokens of type `tokenId` being unbound.
    /// @param bindId The identifier of the asset being unbound from.
    /// @param data Additional data sent along with no specified format.
    /// @return `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256,uint256,uint256,bytes)"))`
    function onERC1155Unbind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 bindId,
        bytes calldata data
    ) external returns (bytes4);

    /// @notice Handles unbinding of multiple IERC1155Bindable-compliant token types.
    /// @dev An IERC1155Bindable-compliant contract MUST call this function at
    ///  the end of an `batchUnbind` after revoking delegated asset ownership. 
    ///  The function MUST revert if `from` is not the asset owner of `bindId`, 
    ///  or if `bindId` is not a valid asset. The function MUST revert if it
    ///  rejects the unbinds. If accepting the unbinds, the function MUST return
    ///  `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the unbinding token is `msg.sender`.
    /// @param operator The address responsible for performing the unbinds.
    /// @param from The address which owns the assets being unbound from.
    /// @param to The address which will own the tokens once unbound.
    /// @param tokenIds The list of token types being unbound.
    /// @param amounts The number of tokens for each token type being unbound.
    /// @param bindIds The identifiers of the assets being unbound from.
    /// @param data Additional data sent along with no specified format.
    /// @return `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
    function onERC1155BatchUnbind(
        address operator,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata bindIds,
        bytes calldata data
    ) external returns (bytes4);

    /// @notice Gets the owner address of the asset represented by id `bindId`.
    /// @param bindId The identifier of the asset whose owner is being queried.
    /// @return The address of the owner of the asset.
    function ownerOf(uint256 bindId) external view returns (address);

    /// @notice Checks if an operator can act on behalf of an asset owner.
    /// @param owner The address that owns an asset.
    /// @param operator The address that acts on behalf of owner `owner`.
    /// @return True if `operator` can act on behalf of `owner`, else False.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Registrar Events & Errors Interface
interface IDopamineRegistrarEventsAndErrors {

    /// @notice Emits when a registrar controller is set or unset.
    /// @param controller The address of the specified registrar controller.
    /// @param setting A boolean indicating whether authorization is on or off.
    event ControllerSet(address controller, bool setting);

    /// @notice Emits when a registrar signer is set or unset.
    /// @param signer The address of specified registrar signer.
    /// @param setting A boolean indicating whether signing is permitted or not.
    event SignerSet(address signer, bool setting);

    /// @notice Emits when a chip registration has been claimed by a new owner.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param pnft The identifier of the claimed chip's physical-bound token.
    /// @param claimant The address of the new registrar owner.
    /// @param permissions The permissions associated with the claimed chip.
    event Claim(
        bytes32 indexed chip,
        uint256 indexed pnft,
        address claimant,
        uint96 permissions
    );

    /// @notice Emits when a chip has its permissions modified to `perms`.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param permissions The newly set chip registration permissions.
    event SetPermission(bytes32 indexed chip, uint96 permissions);

    /// @notice Caller is not a registrar controller.
    error ControllerOnly();

    /// @notice Caller is not the owner of the contract.
    error OwnerOnly();

    /// @notice Chip does not have sufficient registrar permissions.
    error PermissionDenied();

    /// @notice Caller is not the chip registrant.
    error RegistrantOnly();

    /// @notice Caller is not the chip scanner.
    error ScannerOnly();

    /// @notice Provided signature has expired.
    error SignatureExpired();

    /// @notice Provided signature is not valid.
    error SignatureInvalid();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////
 
// Signatures 

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
    uint256 expiry;
}

// Registrar Permissions

uint32 constant REGISTRAR_DENY_ALL = 0;

uint32 constant REGISTRAR_ALLOW_SET_PERMS = 1;
uint32 constant REGISTRAR_ALLOW_UNSET_PERMS = 2;

uint32 constant REGISTRAR_ALLOW_TRANSFER = 4;
uint32 constant REGISTRAR_ALLOW_BUNDLE = 8;
uint32 constant REGISTRAR_ALLOW_UNBUNDLE = 16;
uint32 constant REGISTRAR_ALLOW_SET_URI = 32;

uint32 constant REGISTRAR_ALLOW_SET_RESOLVER = 64;
uint32 constant REGISTRAR_ALLOW_SET_PNFT = 128;
uint32 constant REGISTRAR_ALLOW_SET_TEXT = 256;

uint32 constant REGISTRAR_DEFAULT_PERMS = 
    REGISTRAR_ALLOW_TRANSFER | 
    REGISTRAR_ALLOW_UNBUNDLE |  
    REGISTRAR_ALLOW_SET_TEXT |
    REGISTRAR_ALLOW_UNSET_PERMS;

// Bindable Types

enum BindableType {
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Registrar Controller Events & Errors Interface
interface IDopamineRegistrarControllerEventsAndErrors {

    /// @notice Bindable token is not valid.
    /// @param token The address of the specified bindable.
    error BindableInvalid(address token);

    /// @notice Bindable token type is not valid.
    /// @param token The address of the specified bindable.
    error BindableTypeInvalid(address token);

    /// @notice Emits when a registrar signer is set or unset.
    /// @param signer The address of specified registrar signer.
    /// @param setting A boolean indicating whether signing is permitted or not.
    event SignerSet(address signer, bool setting);

    /// @notice Caller is not the owner of the contract.
    error OwnerOnly();

    /// @notice Provided signature is not valid.
    error SignatureInvalid();
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IMulticallableErrors} from "./IMulticallableErrors.sol";

/// @title Multicallable Interface
interface IMulticallable is IMulticallableErrors, IERC165 {

    /// @notice Peforms multiple chip resolver assignments in a single call.
    /// @param chip The keccak256 identifier for the chip whose records are set.
    /// @param data The ABI-encoded data to be passed with each call delegation.
    function multicall(
        bytes32 chip,
        bytes[] calldata data
    ) external returns (bytes[] memory results);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IPNFTResolverEventsAndErrors} from "./IPNFTResolverEventsAndErrors.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine PNFT Resolver Interface
interface IPNFTResolver is IPNFTResolverEventsAndErrors, IERC165 {

    /// @notice Model for representing a physical-bound NFT.
    struct NFT {
        address token;
        uint256 id;
    }

    /// @notice Sets the PNFT for a specific chip record.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param token The address of the set PNFT.
    /// @param id The token identifier of the set PNFT.
    function setPNFT(
        bytes32 chip,
        address token,
        uint256 id
    ) external;

    /// @notice Gets the PNFT address and identifier for a specific chip record.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @return The address and identifier of the PNFT the chip resolves to.
    function PNFT(
        bytes32 chip
    ) external view returns (address, uint256);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {ITextResolverEventsAndErrors} from "./ITextResolverEventsAndErrors.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Text Resolver Interface
interface ITextResolver is ITextResolverEventsAndErrors, IERC165 {

    function setText(
        bytes32 chip,
        string calldata key,
        string calldata value
    ) external;

    function text(
        bytes32 chip,
        string calldata key
    ) external view returns (string memory);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IBaseResolver} from "../interfaces/resolvers/IBaseResolver.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Base Resolver Interface
abstract contract BaseResolver is IBaseResolver {

    function isAuthorized(
        bytes32 chip,
        uint96 permissions
    ) internal view virtual returns (bool);

    modifier authorizedOnly(bytes32 chip, uint96 permissions) {
        if (!isAuthorized(chip, permissions)) {
            revert SenderUnauthorized();
        }
        _;
    }

    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;

    function supportsInterface(bytes4 id) public pure virtual override(IERC165) returns (bool) {
        return id == _ERC165_INTERFACE_ID;
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC-721 Binder Errors Interface
interface IERC721BinderErrors {

    /// @notice Asset binding already exists.
    error BindExistent();

    /// @notice Asset binding is not valid.
    error BindInvalid();

    /// @notice Asset binding does not exist.
    error BindNonexistent();

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC-1155 Binder Errors Interface
interface IERC1155BinderErrors {

    /// @notice Asset has already minted.
    error AssetAlreadyMinted();

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Multicallable Errors Interface
interface IMulticallableErrors {

    /// @notice Record chip identifier does not match that passed in calldata.
    error ChipIdentifierMismatch();

    /// @notice Chip resolver call failed.
    error ResolverCallFail();

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Registry Interface
interface IPNFTResolverEventsAndErrors {

    /// @notice Emits when the PNFT for a chip record is changed.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param token The address for the newly set PNFT.
    /// @param id The identifier for the newly set PNFT.
    event PNFTChanged(bytes32 chip, address token, uint256 id);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Text Resolver Events & Errors Interface
interface ITextResolverEventsAndErrors {

    /// @notice Emits when a chip's text record is changed for a specific key.
    /// @param chip The keccak-256 identifier for the chip.
    /// @param key The text record key being changed.
    /// @param value The text data value being set.
    event TextChanged(
        bytes32 indexed chip,
        string key,
        string value
    );

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IBaseResolverErrors} from "./IBaseResolverErrors.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Base Resolver Interface
interface IBaseResolver is IBaseResolverErrors, IERC165 {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Base Resolver Errors Interface
interface IBaseResolverErrors {

    /// @notice Caller is not an authorized operator.
    error OperatorUnauthorized();

    /// @notice Caller is not an authorized operator or chip registrant.
    error SenderUnauthorized();

}