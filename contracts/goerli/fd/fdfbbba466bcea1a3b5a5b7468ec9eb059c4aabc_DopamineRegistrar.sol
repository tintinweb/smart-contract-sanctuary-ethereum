// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./DopamineRegistrarConstants.sol";
import {ERC1155} from "./nft/ERC1155.sol";
import {IDopamineRegistry} from "./interfaces/IDopamineRegistry.sol";
import {IDopamineRegistrar} from "./interfaces/IDopamineRegistrar.sol";
import {IPNFT} from "./interfaces/IPNFT.sol";
import {IERC1155Binder} from "./interfaces/IERC1155Binder.sol";
import {IERC721Binder} from "./interfaces/IERC721Binder.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Registrar
contract DopamineRegistrar is ERC1155, IPNFT, IDopamineRegistrar {

    bytes32 public constant CLAIM_TYPEHASH = keccak256("Claim(bytes32 chip,address claimant,uint256 expiry,uint256 nonce)");

    IDopamineRegistry public immutable registry;

    address public owner;

    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    mapping(address => bool) controllers;
    mapping(address => bool) signers;

    /// @notice Maps an address to a nonce for replay protection.
    mapping(address => uint256) public nonces;

    string public baseURI;

    /// @notice EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC721_BINDER_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC1155_BINDER_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _DOPAMINE_REGISTRAR_INTERFACE_ID = 0x01ffc9a7;

    /// @notice Ensures calls can be made only from the scanner of a chip.
    /// @param chip A keccak-256 hash of the chip public key.
    /// @param scanner Address of the chip scanner.
    /// @param signature The ECDSA signature associated with the chip scanner.
    modifier onlyChip(
        bytes32 chip,
        address scanner,
        Signature calldata signature
    ) {
        if (scanner != msg.sender) {
            revert ScannerOnly();
        }
        if (block.timestamp > signature.expiry) {
             revert SignatureExpired();
        }
        
        address signatory = ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",
                keccak256(abi.encode(
                    scanner,
                    signature.expiry
                ))
            )),
            signature.v,
            signature.r,
            signature.s
        );
        if (signatory == address(0) || signatory != address(uint160(uint256(chip)))) {
            revert SignatureInvalid();
        }
        _;
    }

    /// @notice Ensures calls can be made only from an authorized chip claimant.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param claimant The address of the chip's authorized claimant.
    /// @param signature The ECDSA signature associated with the claimant.
    modifier onlyAuthorizedClaimant(
        bytes32 chip,
        address claimant,
        Signature calldata signature
    ) {
        if (block.timestamp > signature.expiry) {
            revert SignatureExpired();
        }
        address signatory = ecrecover(
            _hashTypedData(keccak256(
                abi.encode(
                    CLAIM_TYPEHASH,
                    chip,
                    claimant,
                    nonces[claimant]++,
                    signature.expiry
                )
            )),
            signature.v,
            signature.r,
            signature.s
        );
        if (signatory == address(0) || !signers[signatory]) {
            revert SignatureInvalid();
        }
        _;
    }

    /// @notice Ensures calls can only be made by an authorized controller.
    modifier onlyController() {
        if (!controllers[msg.sender]) {
            revert ControllerOnly();
        }
        _;
    }

    /// @notice Ensures only the owner can make the call.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnerOnly();
        }
        _;
    }

    /// @notice Ensures calls can only be made by the chip's current registrant.
    /// @param id The identifier of the chip whose registrant is being vetted.
    /// @param permissions Permissions that must be set for the registrant call.
    modifier onlyRegistrant(uint256 id, uint96 permissions) {
        if (msg.sender != ownerOf(id)) {
            revert RegistrantOnly();
        }
        if (!_checkPermissions(id, permissions)) {
            revert PermissionDenied();
        }
        _;
    }

    /// @notice Ensures calls can only be made if given chip permission are set.
    /// @param id The identifier of the chip whose permissions are queried for.
    /// @param permissions The permissions required to have been set.
    modifier permissionsSet(uint256 id, uint96 permissions) {
        if (!_checkPermissions(id, permissions)) {
            revert PermissionDenied();
        }
        _;
    }

    /// @notice Instantiates the Dopamine registrar contract.
    /// @param registry_ The Dopamine registry contract.
    /// @param baseURI_ The base URI to set for metadata queries.
    constructor(IDopamineRegistry registry_, address controller, string memory baseURI_) {
        registry = registry_;
        baseURI = baseURI_;
        controllers[controller] = true;
        owner = msg.sender;
        _CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = _buildDomainSeparator();
    }

    /// @inheritdoc IDopamineRegistrar
    function ownerOf(uint256 id) public view override(IPNFT, IDopamineRegistrar) returns (address registrant) {
        (registrant, ) = _unpack(id);
    }

    /// @inheritdoc IDopamineRegistrar
    function uri(uint256 id) external view override(ERC1155, IDopamineRegistrar) returns (string memory) {
        if (ownerOf(id) == address(0)) {
            revert TokenNonExistent();
        }

        return string(abi.encodePacked(baseURI, _toString(id)));
    }

    /// @inheritdoc IPNFT
    function isApprovedForAll(address registrant, address operator) public view override(ERC1155, IPNFT) returns (bool) {
        return super.isApprovedForAll(registrant, operator);
    }

    /// @inheritdoc IDopamineRegistrar
    function checkPermissions(bytes32 chip, uint96 permissions) public view returns (bool) {
        return _checkPermissions(uint256(chip), permissions);
    }

    /// @inheritdoc IDopamineRegistrar
    function claim(
        bytes32 chip,
        address claimant,
        Signature calldata scanSignature,
        Signature calldata claimSignature
    ) 
        public 
        onlyChip(chip, msg.sender, scanSignature) 
        onlyAuthorizedClaimant(chip, claimant, claimSignature)
    {

        if (msg.sender == claimant) {
            revert SenderUnauthorized();
        }

        uint256 id = uint256(chip);
        (address registrant, uint96 permissions) = _unpack(id);

        _pack(id, claimant, permissions);

        emit TransferSingle(msg.sender, registrant, claimant, id, 1);
    }

    /// @inheritdoc IDopamineRegistrar
    function register(
        bytes32 chip,
        address registrant,
        address resolver,
        uint96 permissions
    ) public onlyController {

        _mint(address(this), uint256(chip), permissions);

        registry.setRecord(chip, registrant, resolver);
    }

    /// @inheritdoc IDopamineRegistrar
    function setSigner(address signer, bool setting) public onlyOwner {
        signers[signer] = setting;
        emit SignerSet(signer, setting);
    }

    /// @inheritdoc IDopamineRegistrar
    function setController(address controller, bool setting) public onlyOwner {
        controllers[controller] = setting;
        emit ControllerSet(controller, setting);
    }

    /// @inheritdoc IDopamineRegistrar
    function setPermissions(bytes32 chip, uint96 permissions) 
        public
        onlyRegistrant(uint256(chip), REGISTRAR_ALLOW_SET_PERMS)
    {

        uint256 id = uint256(chip);
        (address registrant, uint96 oldPermissions) = _unpack(id);

        permissions |= oldPermissions;
        _pack(id, registrant, permissions);
    }

    /// @inheritdoc IDopamineRegistrar
    function unsetPermissions(bytes32 chip, uint96 permissions) 
        public
        onlyRegistrant(uint256(chip), REGISTRAR_ALLOW_UNSET_PERMS)
    {
        uint256 id = uint256(chip);
        (address registrant, uint96 oldPermissions) = _unpack(id);

        permissions &= oldPermissions;
        _pack(id, registrant, permissions);
    }

    /// @inheritdoc IDopamineRegistrar
    function setResolver(bytes32 chip, address resolver) 
        public 
        onlyRegistrant(uint256(chip), REGISTRAR_ALLOW_SET_RESOLVER) 
    {
        registry.setResolver(chip, resolver);
    }

    /// @inheritdoc IERC1155Binder
    function onERC1155Bind(
        address,
        address,
        address,
        uint256,
        uint256,
        uint256 bindId,
        bytes calldata
    ) public permissionsSet(bindId, REGISTRAR_ALLOW_BUNDLE) view returns (bytes4) {
        return IERC1155Binder.onERC1155Bind.selector;
    }

    /// @inheritdoc IERC1155Binder
	function onERC1155BatchBind(
        address,
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        uint256[] calldata bindIds,
        bytes calldata
	) public view returns (bytes4) {
        for (uint256 i = 0; i < bindIds.length; ++i) {
            if (!_checkPermissions(bindIds[i], REGISTRAR_ALLOW_BUNDLE)) {
                revert PermissionDenied();
            }
        }
        return IERC1155Binder.onERC1155BatchBind.selector;
    }

    /// @inheritdoc IERC1155Binder
    function onERC1155Unbind(
        address,
        address,
        address,
        uint256,
        uint256,
        uint256 bindId,
        bytes calldata
    ) public permissionsSet(bindId, REGISTRAR_ALLOW_UNBUNDLE) view returns (bytes4) {
        return IERC1155Binder.onERC1155Unbind.selector;
    }

    /// @inheritdoc IERC1155Binder
	function onERC1155BatchUnbind(
        address,
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        uint256[] calldata bindIds,
        bytes calldata
    ) public view returns (bytes4) {
        for (uint256 i = 0; i < bindIds.length; ++i) {
            if (!_checkPermissions(bindIds[i], REGISTRAR_ALLOW_UNBUNDLE)) {
                revert PermissionDenied();
            }
        }
        return IERC1155Binder.onERC1155Unbind.selector;
    }

    /// @inheritdoc IERC721Binder
    function onERC721Bind(
        address,
        address,
        address,
        uint256,
        uint256 bindId,
        bytes calldata
    ) public permissionsSet(bindId, REGISTRAR_ALLOW_BUNDLE) view returns (bytes4) {
        return IERC721Binder.onERC721Bind.selector;
    }

    /// @inheritdoc IERC721Binder
    function onERC721Unbind(
        address,
        address,
        address,
        uint256,
        uint256 bindId,
        bytes calldata
    ) public permissionsSet(bindId, REGISTRAR_ALLOW_UNBUNDLE) view returns (bytes4) {
        return IERC721Binder.onERC721Unbind.selector;
    }

    /// @notice Checks if interface of identifier `id` is supported.
    /// @param id The ERC-165 interface identifier.
    /// @return True if interface id `id` is supported, False otherwise.
    function supportsInterface(bytes4 id) public pure override(IERC165, ERC1155) returns (bool) {
        return id == _ERC721_BINDER_INTERFACE_ID  ||
               id == _ERC1155_BINDER_INTERFACE_ID ||
               id == _DOPAMINE_REGISTRAR_INTERFACE_ID;
    }

    /// @dev Returns the domain separator tied to the contract.
    /// @return 256-bit domain separator tied to this contract.
    function _domainSeparator() internal view returns (bytes32) {
        if (block.chainid == _CHAIN_ID) {
            return _DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator();
        }
    }

    /// @dev Generates an EIP-712 Dopamine registrar domain separator.
    /// @return A 256-bit domain separator tied to this contract.
    function _buildDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Dopamine Registrar")),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }

    /// @dev Ensures the given permissions are set for a specific chip.
    /// @param id The identifier for the chip being queried.
    /// @param permissions The permissions being checked for.
    function _checkPermissions(uint256 id, uint96 permissions) internal view returns (bool) {
        (, uint96 chipPermissions) = _unpack(id);
        return chipPermissions & permissions != 1;
    }

    /// @dev Toggles the specific permissions of a chip using a bit operator.
    /// @param id The identifier for the chip whose permissions are being set.
    /// @param permissions The permissions to toggle.
    /// @param op The bitwise function used to toggle the given permissions.
    function _togglePermissions(
        uint256 id,
        uint96 permissions,
        function(uint96, uint96) pure returns (uint96) op
    ) internal {
        (address registrant, uint96 chipPermissions) = _unpack(id);
        _pack(id, registrant, op(chipPermissions, permissions));
    }

    /// @dev Bitwise operation that performs an OR between `a` and `b`.
    function _set(uint96 a, uint96 b) private pure returns (uint96) { return a | b; }

    /// @dev Bitwise operation that performs an AND between `a` and `b`.
    function _unset(uint96 a, uint96 b) private pure returns (uint96) { return a & b; }

    /// @dev Returns an EIP-712 encoding of structured data `structHash`.
    /// @param structHash The structured data to be encoded and signed.
    /// @return A byte string suitable for signing in accordance to EIP-712.
    function _hashTypedData(bytes32 structHash)
        internal
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), structHash)
        );
    }
	
	/// @dev Converts a uint256 into a string.
    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
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

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC1155MetadataURI} from "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";

import {IERC1155Errors} from "../interfaces/IERC1155Errors.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine ERC-1155 NFT Contract
contract ERC1155 is IERC1155, IERC1155MetadataURI, IERC1155Errors {

    /// @notice Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) internal _isApprovedForAll;

    /// @notice Gets ownership and permission details for a specific NFT.
    mapping(uint256 => uint256) internal _nfts;

    /// @notice EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4 private constant _ERC1155_METADATA_INTERFACE_ID = 0x0e89341c;

    /// @notice Gets the approved operator for an owner address.
    function isApprovedForAll(address owner, address operator) public virtual view returns (bool) {
        return _isApprovedForAll[owner][operator];
    }

    /// @notice Gets the number of tokens of id `id` owned by address `owner`.
    /// @param owner The token owner's address.
    /// @param id The type of the token being queried for.
    /// @return amount The number of tokens address `owner` owns for NFT `id`.
    function balanceOf(
        address owner,
        uint256 id
    ) public view returns (uint256 amount) {
        (address account, ) = _unpack(id);

        assembly {
            amount := eq(account, owner)
        }
    }

    /// @notice Retrieves balances of multiple owner / token type pairs.
    /// @param owners List of token owner addresses.
    /// @param ids List of token type identifiers.
    /// @return balances List of balances corresponding to the owner / id pairs.
    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        returns (uint256[] memory balances)
    {
        if (owners.length != ids.length) {
            revert ArityMismatch();
        }

        balances = new uint256[](owners.length);

        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf(owners[i], ids[i]);
            }
        }
    }


    function uri(uint256) external view virtual returns (string memory) {
        return ""; 
    }

    /// @notice Transfers `amount` tokens of id `id` from address `from` to 
    ///  address `to`, while ensuring `to` is capable of receiving the token.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    ///  The function will throw if transferring an NFT with `amount` != 1.
    /// @param from The existing owner address of the token to be transferred.
    /// @param to The new owner address of the token being transferred.
    /// @param id The id of the token being transferred.
    /// @param amount The number of tokens being transferred.
    /// @param data Additional transfer data to pass to the receiving contract.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public {
        if (msg.sender != from && !_isApprovedForAll[from][msg.sender]) {
            revert SenderUnauthorized();
        }

        (address owner, uint96 perms) = _unpack(id);
        if (from != owner) {
            revert OwnerInvalid();
        }

        if (amount != 1) {
            revert TokenAmountInvalid();
        }

        _pack(id, to, perms);

        emit TransferSingle(msg.sender, from, to, id, amount);

        if (
            to.code.length != 0 &&
            IERC1155Receiver(to).onERC1155Received(
                msg.sender,
                address(0),
                id,
                amount,
                data
            ) !=
            IERC1155Receiver.onERC1155Received.selector
        ) {
            revert SafeTransferUnsupported();
        } else if (to == address(0)) {
            revert ReceiverInvalid();
        }
    }

    /// @notice Transfers tokens `ids` in corresponding batches `amounts` from 
    ///  address `from` to address `to`, while ensuring `to` can receive tokens.
    /// @dev Safety checks are only performed if `to` is a smart contract.
    ///  The function will throw if an NFT is transfered with an amount != 1.
    /// @param from The existing owner address of the token to be transferred.
    /// @param to The new owner address of the token being transferred.
    /// @param ids A list of the token ids being transferred.
    /// @param amounts A list of the amounts of each token id being transferred.
    /// @param data Additional transfer data to pass to the receiving contract.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public {
        if (ids.length != amounts.length) {
            revert ArityMismatch();
        }

        if (msg.sender != from && !_isApprovedForAll[from][msg.sender]) {
            revert SenderUnauthorized();
        }

        uint256 id;
        address owner;
        uint96 perms;

        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                id = ids[i];

                (owner, perms) = _unpack(id);
                if (from != owner) {
                    revert OwnerInvalid();
                }
                if (amounts[i] != 1) {
                    revert TokenAmountInvalid();
                }
                _pack(id, to, perms);
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        if (
            to.code.length != 0 &&
            IERC1155Receiver(to).onERC1155BatchReceived(
                msg.sender,
                from,
                ids,
                amounts,
                data
            ) !=
            IERC1155Receiver.onERC1155BatchReceived.selector
        ) {
            revert SafeTransferUnsupported();
        } else if (to == address(0)) {
            revert ReceiverInvalid();
        }
    }

    /// @notice Sets the operator for the sender address.
    function setApprovalForAll(address operator, bool approved) public {
        _isApprovedForAll[msg.sender][operator] = approved;
    }

    /// @notice Checks if interface of identifier `id` is supported.
    /// @param id The ERC-165 interface identifier.
    /// @return True if interface id `id` is supported, False otherwise.
    function supportsInterface(bytes4 id) public pure virtual returns (bool) {
        return
            id == _ERC165_INTERFACE_ID ||
            id == _ERC1155_INTERFACE_ID ||
            id == _ERC1155_METADATA_INTERFACE_ID;
    }

    /// @notice Mints NFT of id `id` to address `to`.
    /// @param to Address receiving the minted NFT.
    /// @param id The id of the NFT being minted.
    function _mint(address to, uint256 id, uint96 perms) internal virtual {
        (address owner, ) = _unpack(id);
        if (owner != address(0)) {
            revert TokenAlreadyMinted();
        }

        _pack(id, owner, perms);

        emit TransferSingle(msg.sender, address(0), to, id, 1);

        if (
            to.code.length != 0 &&
            IERC1155Receiver(to).onERC1155Received(
                msg.sender,
                address(0),
                id,
                1,
                ""
            ) !=
            IERC1155Receiver.onERC1155Received.selector
        ) {
            revert SafeTransferUnsupported();
        } else if (to == address(0)) {
            revert ReceiverInvalid();
        }
    }

    function _pack(uint256 id, address owner, uint96 perms) internal {
        _nfts[id] = uint256(uint160(owner)) | (uint256(perms) << 160);
        uint256 nft = _nfts[id];
        owner = address(uint160(nft));
        perms = uint96(nft >> 160);
    }

    function _unpack(uint256 id) internal view returns (address owner, uint96 perms) {
        uint256 nft = _nfts[id];
        owner = address(uint160(nft));
        perms = uint96(nft >> 160);
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

import {IERC1155Binder} from "./IERC1155Binder.sol";
import {IERC721Binder} from "./IERC721Binder.sol";

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine PNFT Interface
interface IPNFT is IERC1155Binder, IERC721Binder {

    function ownerOf(uint256 bindId) external view override(IERC1155Binder, IERC721Binder) returns (address);

    function isApprovedForAll(address owner, address operator) external view override(IERC1155Binder, IERC721Binder) returns (bool);

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC-1155 Errors Interface
interface IERC1155Errors {

    /// @notice Arity mismatch between two arrays.
    error ArityMismatch();

    /// @notice Originating address does not own the NFT.
    error OwnerInvalid();

    /// @notice Receiving address cannot be the zero address.
    error ReceiverInvalid();

    /// @notice Receiving contract does not implement the ERC-1155 wallet interface.
    error SafeTransferUnsupported();

    /// @notice Sender is not NFT owner, approved address, or owner operator.
    error SenderUnauthorized();

    /// @notice Token has already minted.
    error TokenAlreadyMinted();

    /// @notice Token amount must be equal to one.
    error TokenAmountInvalid();

    /// @notice NFT does not exist.
    error TokenNonExistent();

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

/// @title ERC-721 Binder Errors Interface
interface IERC721BinderErrors {

    /// @notice Asset binding already exists.
    error BindExistent();

    /// @notice Asset binding is not valid.
    error BindInvalid();

    /// @notice Asset binding does not exist.
    error BindNonexistent();

}