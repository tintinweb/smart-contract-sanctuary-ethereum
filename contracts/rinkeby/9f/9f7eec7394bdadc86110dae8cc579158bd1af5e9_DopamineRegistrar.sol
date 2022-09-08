// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IPNFTRegistrar} from "../interfaces/IPNFTRegistrar.sol";
import {IERC721PNFTRegistrar} from "../interfaces/IERC721PNFTRegistrar.sol";
import {IERC1155PNFTRegistrar} from "../interfaces/IERC1155PNFTRegistrar.sol";
import {IERC721PNFT} from "../interfaces/IERC721PNFT.sol";
import {IERC1155PNFT} from "../interfaces/IERC1155PNFT.sol";

import {DopamineResolver} from "./DopamineResolver.sol";
import {ERC1155B} from "../erc1155/ERC1155B.sol";

/// @title Dopamine Registrar
contract DopamineRegistrar is ERC1155B, IPNFTRegistrar {

    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    bytes32 public constant CLAIM_TYPEHASH = keccak256("Claim(bytes32 chip,address claimant,uint256 expiry)");

    DopamineResolver public defaultResolver;


    mapping(address => bool) controllers;

    /// @notice Tracks the owner balance for an external token of a specific id.
    mapping(address => mapping(address => mapping(uint256 => uint256))) public erc1155BalanceOf;

    /// @notice Tracks the owner balance for an external NFT of a specific id.
    mapping(address => mapping(address => uint256)) public erc721BalanceOf;

    /// @notice Maps an address to a nonce for replay protection.
    mapping(address => uint256) public nonces;

    /// @notice Checks to ensure message sender is the current chip owner.
    /// @param chip A keccak-256 hash of the chip public key.
    /// @param claimant The person responsible for claiming the chip.
    /// @param v Transaction signature recovery identifier.
    /// @param r Transaction signature output component #1.
    /// @param s Transaction signature output component #2.
    /// @param expiry The timestamp at which this signature is set to expire.
    modifier onlyChip(
        bytes32 chip,
        address claimant,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry
    ) {
        if (claimant != msg.sender) {
            revert ChipOwnerOnly();
        }
        if (block.timestamp > expiry) {
            revert SignatureExpired();
        }
        address signatory = ecrecover(
            _hashTypedData(keccak256(
                abi.encode(
                    CLAIM_TYPEHASH,
                    chip,
                    msg.sender,
                    expiry
                )
            )),
            v,
            r,
            s
        );
        if (signatory == address(0) || signatory != address(uint160(uint256(chip)))) {
            revert SignatureInvalid();
        }
        _;
    }

    modifier onlyRegistrant(uint256 id) {
        if (msg.sender != _ownerOf[id]) {
            revert RegistrantOnly();
        }
        _;
    }

    modifier onlyController() {
        if (!controllers[msg.sender]) {
            revert ControllerOnly();
        }
        _;
    }

    constructor(DopamineResolver resolver) {
        defaultResolver = resolver;
        _CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = _buildDomainSeparator();
    }

    /// @notice Gets the owning address of the chip with id `id`.
    /// @param id The id of the chip being queried.
    /// @return The address of the owner for chip id `id`.
    function ownerOf(uint256 id) public view returns (address) {
        return _ownerOf[id];
    }


    /// @inheritdoc IERC721PNFTRegistrar
    function balanceOf(
        address pnft,
        address owner
    ) external view returns (uint256) {
        return erc721BalanceOf[pnft][owner];
    }

    /// @inheritdoc IERC1155PNFTRegistrar
    function balanceOf(
        address pnft,
        address owner,
        uint256 id
    ) external view returns (uint256) {
        return erc1155BalanceOf[pnft][owner][id];
    }

    /// @inheritdoc IERC1155PNFTRegistrar
    function balanceOfBatch(
        address pnft,
        address[] memory owners,
        uint256[] memory ids
    ) external view returns (uint256[] memory balances) {
        if (owners.length != ids.length) {
            revert ArityMismatch();
        }

        balances = new uint256[](owners.length);

        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = erc1155BalanceOf[pnft][owners[i]][ids[i]];
            }
        }
    }

    function claim(
        bytes32 chip,
        address claimant,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry
    ) public onlyChip(chip, claimant, v, r, s, expiry) {

        uint256 chipId = _id(chip);
        safeTransferFrom(_ownerOf[chipId], claimant, chipId, 1, "");
        _transferPNFTBalance(chip, _ownerOf[chipId], claimant);
    }

    function register(
        bytes32 chip,
        address[] memory pnfts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public {

        if (
            pnfts.length != ids.length     ||
            pnfts.length != amounts.length
        ) {
            revert ArityMismatch();
        }

        address binder = address(uint160(uint256(chip)));
        uint256 chipId = uint256(uint160(binder));

        _mint(address(this), chipId);

        defaultResolver.setPNFTs(chip, pnfts);

        address pnft;
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < pnfts.length; i++) {

            pnft = pnfts[i];
            id = ids[i];
            amount = amounts[i];

            if (IERC165(pnft).supportsInterface(type(IERC721PNFT).interfaceId)) {
                IERC721PNFT(pnft).mint(id, chipId);
            } else if (IERC165(pnft).supportsInterface(type(IERC1155PNFT).interfaceId)) {
                IERC1155PNFT(pnft).mint(id, amount, chipId);
            } else {
                revert PNFTInvalid();
            }
        }
    }

    function onERC1155Bind(
        uint256 id,
        uint256 amount,
        uint256 registrarId
    ) public returns (bytes4) {
        return type(IERC1155PNFTRegistrar).interfaceId;
    }

    function onERC1155Unbind(
        uint256 id,
        uint256 amount,
        uint256 registrarId
    ) public returns (bytes4) {
        unchecked {
            erc1155BalanceOf[msg.sender][_ownerOf[registrarId]][id] += amount;
        }
        return type(IERC1155PNFTRegistrar).interfaceId;
    }

    function onERC721Bind(
        uint256 id,
        uint256 registrarId
    ) public returns (bytes4) {
        unchecked {
            erc721BalanceOf[msg.sender][_ownerOf[registrarId]]++;
        }
        return type(IERC721PNFTRegistrar).interfaceId;
    }

    function onERC721Unbind(
        uint256 id,
        uint256 registrarId
    ) public returns (bytes4) {
        unchecked {
            erc721BalanceOf[msg.sender][_ownerOf[registrarId]]--;
        }
        return type(IERC721PNFTRegistrar).interfaceId;
    }

    function _address(bytes32 chip) internal returns (address) {
        return address(uint160(uint256(chip)));
    }

    function _id(bytes32 chip) internal returns (uint256) {
        return uint256(uint160(_address(chip)));
    }

    function _transferPNFTBalance(
        bytes32 chip,
        address from,
        address to
    ) internal {

        address binder = address(uint160(uint256(chip)));
        address[] memory pnfts = defaultResolver.getPNFTs(chip);

        address pnft;
        uint256 bal;

        for (uint256 i = 0; i < pnfts.length; i++) {
            pnft = pnfts[i];
            if (IERC165(pnft).supportsInterface(type(IERC721PNFT).interfaceId)) {
                bal = IERC721PNFT(pnft).balanceOf(binder);
                erc721BalanceOf[pnft][from] -= bal;
                erc721BalanceOf[pnft][to] += bal;
            } 
        }
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

    /// @dev Generates an EIP-712 Dopamine DAO domain separator.
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

import {IPNFTRegistrarEventsAndErrors} from "./IPNFTRegistrarEventsAndErrors.sol";
import {IERC721PNFTRegistrar} from "./IERC721PNFTRegistrar.sol";
import {IERC1155PNFTRegistrar} from "./IERC1155PNFTRegistrar.sol";

/// @title Dopamine PNFT Registrar Interface
interface IPNFTRegistrar is IERC721PNFTRegistrar, IERC1155PNFTRegistrar, IPNFTRegistrarEventsAndErrors {

    /// @notice Gets the owning address of the chip with id `id`.
    /// @param id The id of the chip being queried.
    /// @return The address of the owner for chip id `id`.
    function ownerOf(uint256 id) external view override(IERC1155PNFTRegistrar, IERC721PNFTRegistrar) returns (address);

    function register(
        bytes32 chip,
        address[] memory pnfts,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external;

    function claim(
        bytes32 chip,
        address owner,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 expiry
    ) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine ERC-721 PNFT Registrar Interface
interface IERC721PNFTRegistrar {

    /// @notice Gets the number of PNFT tokens `pnft` owned by address `owner`.
    /// @param pnft The address of the PNFT contract.
    /// @param owner The token owner's address.
    /// @return The number of tokens address `owner` owns for the PNFT `pnft`.
    function balanceOf(
        address pnft,
        address owner
    ) external view returns (uint256);

    function onERC721Bind(
        uint256 id,
        uint256 registrarId
    ) external returns (bytes4);

    function onERC721Unbind(
        uint256 id,
        uint256 registrarId
    ) external returns (bytes4);

    /// @notice Gets the owning address of the chip with id `id`.
    /// @param id The id of the chip being queried.
    /// @return The address of the owner for chip id `id`.
    function ownerOf(uint256 id) external view returns (address);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine ERC-1155 PNFT Registrar Interface
interface IERC1155PNFTRegistrar {

    /// @notice Gets the number of tokens of type `id` owned by address `owner`.
    /// @param pnft The address of the PNFT contract.
    /// @param owner The token owner's address.
    /// @param id The id of the token being queried.
    /// @return The number of tokens address `owner` owns of type `id`.
    function balanceOf(
        address pnft,
        address owner,
        uint256 id
    ) external view returns (uint256);

    /// @notice Retrieves balances of multiple owner / token type pairs.
    /// @param owners List of token owner addresses.
    /// @param ids List of token type identifiers.
    /// @return balances List of balances corresponding to the owner / id pairs.
    function balanceOfBatch(
        address pnft,
        address[] memory owners,
        uint256[] memory ids
    ) external view returns (uint256[] memory balances);

    function onERC1155Bind(
        uint256 id,
        uint256 amount,
        uint256 registrarId
    ) external returns (bytes4);

    function onERC1155Unbind(
        uint256 id,
        uint256 amount,
        uint256 registrarId
    ) external returns (bytes4);

    /// @notice Gets the owning address of the chip with id `id`.
    /// @param id The id of the chip being queried.
    /// @return The address of the owner for chip id `id`.
    function ownerOf(uint256 id) external view returns (address);


}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IERC721PNFTEventsAndErrors} from "./IERC721PNFTEventsAndErrors.sol";

/// @title IERC721 Physical-bound NFT Interface
interface IERC721PNFT is IERC721, IERC721PNFTEventsAndErrors {

    function mint(
        uint256 id,
        uint256 registrarId
    ) external returns (uint256);

    function bind(
        address from,
        address to,
        uint256 id,
        address registrar,
        uint256 registrarId
    ) external;

    function unbind(
        address from,
        address to,
        uint256 id,
        address registrar,
        uint256 registrarId
    ) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IERC1155PNFTEventsAndErrors} from "../interfaces/IERC1155PNFTEventsAndErrors.sol";

/// @title IERC1155 Physical-bound NFT Interface
interface IERC1155PNFT is IERC1155PNFTEventsAndErrors {

    function mint(
        uint256 id,
        uint256 amount,
        uint256 registrarId
    ) external returns (uint256, uint256);

    function bind(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        address registrar,
        uint256 registrarId
    ) external;

    function unbind(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        address registrar,
        uint256 registrarId
    ) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IDRS} from "../interfaces/IDRS.sol";
import {PNFTResolver} from "./PNFTResolver.sol";

/// @title Dopamine Resolver
contract DopamineResolver is PNFTResolver {

    // IDRS public immutable registry;

    // constructor(address _registry) {
    //     registry = IDRS(_registry);
    // }

    function supportsInterface(bytes4 id)
        public 
        view 
        override(PNFTResolver) 
        returns (bool) 
    {
        return super.supportsInterface(id);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {IERC1155BErrors} from "../interfaces/IERC1155BErrors.sol";

/// @title Dopamine ERC-1155 NFT Contract
/// @notice This is a minimal ERC-1155 implementation for representing NFTs.
contract ERC1155B is IERC1155, IERC1155BErrors {

    /// @notice Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @notice Gets the owner for a non-fungible token.
    mapping(uint256 => address) public _ownerOf;

    /// @notice EIP-165 identifiers for all supported interfaces.
    bytes4 private constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant _ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4 private constant _ERC1155_METADATA_INTERFACE_ID = 0x0e89341c;

    /// @notice Gets the number of tokens of id `id` owned by address `owner`.
    /// @param owner The token owner's address.
    /// @param id The type of the token being queried for.
    /// @return amount The number of tokens address `owner` owns for NFT `id`.
    function balanceOf(
        address owner,
        uint256 id
    ) public view returns (uint256 amount) {
        address target = _ownerOf[id];

        assembly {
            amount := eq(target, owner)
        }
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
        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            revert SenderUnauthorized();
        }

        if (from != _ownerOf[id]) {
            revert OwnerInvalid();
        }

        if (amount != 1) {
            revert TokenAmountInvalid();
        }

        _ownerOf[id] = to;

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

        if (msg.sender != from && !isApprovedForAll[from][msg.sender]) {
            revert SenderUnauthorized();
        }

        uint256 id;

        unchecked {
            for (uint256 i = 0; i < ids.length; ++i) {
                id = ids[i];
                if (from != _ownerOf[id]) {
                    revert OwnerInvalid();
                }
                if (amounts[i] != 1) {
                    revert TokenAmountInvalid();
                }
                _ownerOf[id] = to;
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

    /// @notice Sets the operator for the sender address.
    function setApprovalForAll(address operator, bool approved) public {
        isApprovedForAll[msg.sender][operator] = approved;
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
    function _mint(address to, uint256 id) internal virtual {
        if (_ownerOf[id] != address(0)) {
            revert TokenAlreadyMinted();
        }

        _ownerOf[id] = to;

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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title PNFT Registrar Events & Errors Interface
interface IPNFTRegistrarEventsAndErrors {

    /// @notice Function callable only by the registrar controller.
    error ControllerOnly();

    /// @notice Function only invokable by address in possession of the chip.
    error ChipOwnerOnly();

    /// @notice Specified PNFT is not valid.
    error PNFTInvalid();

    /// @notice Function callable only by the PNFT registrant.
    error RegistrantOnly();

    /// @notice Signature is expired.
    error SignatureExpired();

    /// @notice Signature is invalid.
    error SignatureInvalid();
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title IERC721 Physical-bound NFT Events & Errors Interface
interface IERC721PNFTEventsAndErrors {

    event Bind(uint256 id, address registrar, uint256 registrarId);

    event Unbind(uint256 id);

    error BindInvalid();

    error RegistrarOnly();

    error UnbindInvalid();

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title IERC1155 Physical-bound NFT Events & Errors Interface
interface IERC1155PNFTEventsAndErrors {

    event Bind(uint256 id, uint256 amount, address registrar, uint256 registrarId);

    event Unbind(uint256 id, uint256 amount);

    error BindInvalid();

    error UnbindInvalid();

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IDRSEventsAndErrors} from "./IDRSEventsAndErrors.sol";

/// @title Dopamine Reality Service Interface
interface IDRS is IDRSEventsAndErrors {

    struct Record {
        address owner;
        address resolver;
    }

    function setRecord(
        bytes32 chip,
        address owner,
        address resolver
    ) external;

    function setResolver(
        bytes32 chip,
        address resolver
    ) external;

    function setOwner(
        bytes32 chip,
        address owner
    ) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IPNFTResolver} from "../interfaces/IPNFTResolver.sol";

/// @title PNFT Resolver
contract PNFTResolver is IPNFTResolver {

    mapping(bytes32 => address[]) bundles;

    function setPNFTs(bytes32 chip, address[] memory bundle) external {
        bundles[chip] = bundle;
    }

    function getPNFTs(bytes32 chip) external returns (address[] memory) {
        return bundles[chip];
    }

    function addPNFT(bytes32 chip, address pnft) external {
        address[] memory bundle = bundles[chip];
        for (uint256 i = 0; i < bundle.length; i++) { 
            if (bundle[i] == pnft) {
                revert PNFTAlreadyExists();
            }
        }
        bundles[chip].push(pnft);
    }

    function supportsInterface(bytes4 id)
        public 
        view 
        virtual
        returns (bool) 
    {
        id == type(IPNFTResolver).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC1155B Errors Interface
interface IERC1155BErrors {

    /// @notice Mismatch between input arrays.
    error ArityMismatch();

    /// @notice Originating address does not own the NFT.
    error OwnerInvalid();

    /// @notice Receiving address cannot be the zero address.
    error ReceiverInvalid();

    /// @notice Receiving contract does not implement the ERC-721 wallet interface.
    error SafeTransferUnsupported();

    /// @notice Sender is not token owner, approved address, or owner operator.
    error SenderUnauthorized();

    /// @notice Token has already been minted.
    error TokenAlreadyMinted();

    /// @notice Token transfer amount is invalid.
    error TokenAmountInvalid();

    /// @notice Token may not be transferred.
    error TokenNonTransferable();

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title DRS Events & Errors Interface
interface IDRSEventsAndErrors {

    /// @notice Emits when a new owner is set for a chip record.
    event OwnerSet(bytes32 chip, address owner);

    /// @notice Emits when a new resolver is set for a chip record.
    event ResolverSet(bytes32 chip, address resolver);

    /// @notice Function callable only by the owner.
    error OwnerOnly();

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import {IPNFTResolverEventsAndErrors} from "./IPNFTResolverEventsAndErrors.sol";

/// @title Dopamine PNFT Resolver Interface
interface IPNFTResolver is IPNFTResolverEventsAndErrors {

    function setPNFTs(bytes32 chip, address[] memory bundle) external;

    function getPNFTs(bytes32 chip) external returns (address[] memory);

    function addPNFT(bytes32 chip, address pnft) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title PNFT Resolver Events & Errors Interface
interface IPNFTResolverEventsAndErrors {

    error PNFTAlreadyExists();
}