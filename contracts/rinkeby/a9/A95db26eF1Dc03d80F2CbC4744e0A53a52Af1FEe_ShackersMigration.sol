// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "opensea-migration/contracts/OpenSeaMigration.sol";

// custom contract
interface IShackers {
  function mint(address to, uint256 tokenId, string calldata tokenUri) external;
}

// manifold contract for easy UI
interface IFloor69 {
  function mintExtensionExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}

contract ShackersMigration is OpenSeaMigration {
  IShackers public immutable SHACKERS_CONTRACT;
  IFloor69 public immutable FLOOR69_CONTRACT;

  constructor(
    address shackersContractAddress,
    address floor69ContractAddress,
    address openSeaStoreAddress,
    address makerAddress
  ) OpenSeaMigration(openSeaStoreAddress, makerAddress) {
    SHACKERS_CONTRACT = IShackers(shackersContractAddress);
    FLOOR69_CONTRACT = IFloor69(floor69ContractAddress);
  }

  function _onMigrateLegacyToken(
    address owner,
    uint256 legacyTokenId,
    uint256 internalTokenId,
    uint256 amount,
    bytes calldata data
  ) internal override {
    // burn OpenSea legacy shacker; we could also transfer to MAKER and change the metadata but decided not to
    // amount is always `1`, so we don't bother to support minting multiple below
    _burn(legacyTokenId, amount);

    // reverts on invalid tokens as a safeguard to not migrate just any token
    uint256 newTokenId = convertInternalToNewId(internalTokenId);

    // mint shiny new shacker and a surprise
    SHACKERS_CONTRACT.mint(owner, newTokenId, "");

    address[] memory owners = new address[](1);
    owners[0] = owner;
    uint[] memory idAndAmounts = new uint[](1);
    idAndAmounts[0] = uint(1);
    FLOOR69_CONTRACT.mintExtensionExisting(owners, idAndAmounts, idAndAmounts);
  }

  function convertInternalToNewId(uint256 id) pure public returns (uint256) {
    // here comes the fun part; mapping of the legacy NFT IDs to IDs in this contract
    // Grown up Shackers 0-102 plus the X Shacker will be mapped to token IDs 0-103.
    // Babies come thereafter

    if (id > 0 && id < 5) {            //  1-4  =>  0-3
      return id - 1;
    } else if (id > 5 && id < 10) {    //  6-9  =>  4-7
      return id - 2;
    } else if (id > 10 && id < 18) {   // 11-17 => 8-14
      return id - 3;
    } else if (id > 18 && id < 24) {   // 19-23 => 15-19
      return id - 4;
    } else if (id == 26 || id == 27) { // 26-27 => 20-21
      return id - 6;
    } else if (id > 28 && id < 32) {   // 29-31 => 22-24
      return id - 7;
    } else if (id == 34 || id == 35) { // 34-35 => 25-26
      return id - 9;
    } else if (id == 50) {
      return 27;
    } else if (id > 51 && id < 59) {   // 52-58 => 28-34
      return id - 24;
    } else if (id == 62) {
      return 35;
    } else if (id == 67) {
      return 36;
    } else if (id > 68 && id < 73) {   // 69-72 => 37-40
      return id - 32;
    } else if (id == 75 || id == 76) { // 75-76 => 41-42
      return id - 34;
    } else if (id > 77 && id < 86) {   // 78-85 => 43-50
      return id - 35;
    } else if (id == 90 || id == 91) { // 90-91 => 51-52
      return id - 39;
    } else if (id == 101) {
      return 53;
    } else if (id == 103) {
      return 54;
    } else if (id == 105) {
      return 55;
    } else if (id == 108) {
      return 56;
    } else if (id == 112) {
      return 57;
    } else if (id == 113) {
      return 58;
    } else if (id == 114) {
      return 59;
    } else if (id == 117) {
      return 60;
    } else if (id == 119) {
      return 61;
    } else if (id == 121) {
      return 62;
    } else if (id == 123) {
      return 63;
    } else if (id == 125) {
      return 64;
    } else if (id == 127) {
      return 65;
    } else if (id == 131) {
      return 66;
    } else if (id == 135) {
      return 67;
    } else if (id > 137 && id < 141) { // 138-140 => 68-70
      return id - 70;
    } else if (id == 143) {
      return 71;
    } else if (id == 145) {
      return 72;
    } else if (id == 147) {
      return 73;
    } else if (id == 148) {
      return 74;
    } else if (id == 151) {
      return 75;
    } else if (id == 162) {
      return 76;
    } else if (id == 171) {
      return 77;
    } else if (id == 180) {
      return 78;
    } else if (id == 182) {
      return 79;
    } else if (id == 189) {
      return 80;
    } else if (id == 192) {
      return 81;
    } else if (id == 193) {
      return 82;
    } else if (id == 197) {
      return 83;
    } else if (id == 199) {
      return 84;
    } else if (id == 201) {
      return 85;
    } else if (id == 202) {
      return 86;
    } else if (id > 203 && id < 218) { // 204-217 => 87-100
      return id - 117;
    } else if (id == 268) {
      return 101;
    } else if (id == 269) {
      return 102;
    } else if (id == 200) {
      return 103;
    } else if (id == 5) {  // BABIES FROM HERE
      return 104;
    } else if (id == 10) {
      return 105;
    } else if (id == 18) {
      return 106;
    } else if (id == 32) {
      return 107;
    } else if (id == 36) {
      return 108;
    } else if (id > 58 && id < 62) { // 59-61 => 109-111
      return id + 50;
    } else if (id == 92) {
      return 112;
    } else if (id == 93) {
      return 113;
    } else if (id == 102) {
      return 114;
    } else if (id == 106) {
      return 115;
    } else if (id == 107) {
      return 116;
    } else if (id == 132) {
      return 117;
    } else if (id > 171 && id < 175) { // 172-174 => 118-120
      return id - 54;
    } else if (id == 177) {
      return 121;
    } else if (id == 178) {
      return 122;
    } else if (id > 269 && id < 276) { // 270-275 => 123-128
      return id - 147;
    }

    // reaching this means no valid ID was matched
    revert("Invalid Token ID");
  }
}

// SPDX-License-Identifier: MIT
// OpenSeaMigration v1.1.2
// Creator: LaLa Labs

pragma solidity ^0.8.14;

import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol';

contract OpenSeaMigration is ERC1155Receiver {
    address public constant BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

    IERC1155 public immutable OPENSEA_STORE;

    uint160 internal immutable MAKER;

    event TokenMigrated(address account, uint256 legacyTokenId, uint256 amount);

    constructor(
        address openSeaStoreAddress,
        address makerAddress
    ) {
        OPENSEA_STORE = IERC1155(openSeaStoreAddress);
        MAKER = uint160(makerAddress);
    }

    // migration of a single token
    function onERC1155Received(
        address /* operator */,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(OPENSEA_STORE), 'OSMigration: Only accepting OpenSea assets');

        _migrateLegacyToken(from, id, value, data);
        return IERC1155Receiver.onERC1155Received.selector;
    }

    // migration of multiple tokens
    function onERC1155BatchReceived(
        address /* operator */,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        require(msg.sender == address(OPENSEA_STORE), 'OSMigration: Only accepting OpenSea assets');

        for (uint256 i; i < ids.length; i++) {
            _migrateLegacyToken(from, ids[i], values[i], data);
        }
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice Migrates an OpenSea token. The legacy token must have been transferred to this contract before.
     * This method must only be called from `onERC1155Received` or `onERC1155BatchReceived`.
     */
    function _migrateLegacyToken(
        address owner,
        uint256 legacyTokenId,
        uint256 amount,
        bytes calldata data
    ) internal {
        uint256 internalTokenId = _getInternalTokenId(legacyTokenId);

        _onMigrateLegacyToken(owner, legacyTokenId, internalTokenId, amount, data);

        emit TokenMigrated(owner, legacyTokenId, amount);
    }

    /**
     * @dev Overwrite this method to perform the actual migration logic like sending to burn address and minting a new token.
     *   If a token should not/can not be migrated for any reason, revert this call.
     *
     * @param owner The previous owner of the legacy token.
     * @param legacyTokenId The OpenSea token ID
     * @param internalTokenId The internal token ID from the OpenSea collection. This number is incrementing with
     *   every minted token by {MAKER}.
     * @param amount The amount of legacy tokens being migrated.
     * @param data Additional data with no specified format
     */
    function _onMigrateLegacyToken(
        address owner,
        uint256 legacyTokenId,
        uint256 internalTokenId,
        uint256 amount,
        bytes calldata data
    ) internal virtual {
        revert('OSMigration: Not implemented');
    }

    /**
     * @dev Burn the token. Since OpenSea Shared Storefront does not support real burn, transfer to dead address.
     *
     * @param legacyTokenId The OpenSea token ID
     * @param amount The amount of legacy tokens being migrated.
     */
    function _burn(
        uint256 legacyTokenId,
        uint256 amount
    ) internal {
        OPENSEA_STORE.safeTransferFrom(address(this), BURN_ADDRESS, legacyTokenId, amount, "");
    }

    /**
     * @dev Transfer to MAKER. An alternative way for burning, which allows the MAKER to make updates to the metadata,
     *   unless it has been frozen before. Useful to change the NFT image to a blank one for example.
     *
     * @param legacyTokenId The OpenSea token ID
     * @param amount The amount of legacy tokens being migrated.
     * @param data Additional data with no specified format
     */
    function _transferToMaker(
        uint256 legacyTokenId,
        uint256 amount,
        bytes calldata data
    ) internal {
        OPENSEA_STORE.safeTransferFrom(address(this), address(MAKER), legacyTokenId, amount, data);
    }

    /**
     * Retrieves the internal token ID from a legacy token ID in OpenSea format.
     * - Requires the format of the legacyTokenId to match OpenSea format
     * - Requires the encoded maker address to be the original minter
     *
     * @return The OpenSea internal token ID.
     *
     * Thanks CyberKongz for the insights into OpenSea IDs!
     */
    function _getInternalTokenId(uint256 legacyTokenId) public view returns (uint256) {
        // first 20 bytes: check maker address
        if (uint160(legacyTokenId >> 96) != MAKER) {
            revert('OSMigration: Invalid Maker');
        }

        // last 5 bytes: should always be 1
        if (legacyTokenId & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1) {
            revert('OSMigration: Invalid Checksum');
        }

        // middle 7 bytes: nft id (serial for all NFTs that MAKER minted)
        return (legacyTokenId & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}