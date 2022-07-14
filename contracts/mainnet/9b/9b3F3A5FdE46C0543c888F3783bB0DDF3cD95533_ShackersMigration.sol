// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "opensea-migration/contracts/OpenSeaMigration.sol";

interface IShackers {
  function mint(address to, uint256 tokenId, string calldata tokenUri) external;
}

interface ISurprise {
  function mint(address to, uint256 id, uint96 amount) external;
}

/*
                            :+
                           -#:
                          -##
                         .##*
                         =###
                         *###:     +
                         *###*     =*.
                   +.    +####*-   :##-
                   *+  . .#######++*###*.
                 .*#+ .*  +##############+.
                 +#*. +#  .################-
                     +#+   +################+.
                   :*##:   -##########*==#####:
                  +####:   -########=:.+#######-
                :*######=-=######+-  -##########-
               -##############*=.  .*############:
              :#############=:    -##############*
             .###########+-      =################-
             *#########=.          :-+############+
            :##########*+-:            :=*#########
            +#######+*######*+-        .=##########
            ########= .=*#####-      :+############
            #########.   .=*#:     -*#############*
            +########=      .    -*###############-
            :#########*+-:      +################*
             +###########+  :-:   :+############*.
              +#########= :*####*+-:.-+########*.
               -#######=-*###########*+=+*####=
                 -*#########################=.
                   :=*##################*=:
                       :-=+**####**+=-:.


@title Shackers Migration - Bring OG Shackers to the other side
@author loltapes.eth
*/
contract ShackersMigration is OpenSeaMigration, Ownable, Pausable, ReentrancyGuard {

  IShackers public immutable SHACKERS_CONTRACT;
  ISurprise public immutable SURPRISE_CONTRACT;

  uint96 internal constant SURPRISE_AMOUNT = 3;
  uint256 internal constant SURPRISE_ID = 0;

  constructor(
    address shackersContractAddress,
    address surpriseContractAddress,
    address openSeaStoreAddress,
    address makerAddress
  ) OpenSeaMigration(openSeaStoreAddress, makerAddress) {
    SHACKERS_CONTRACT = IShackers(shackersContractAddress);
    SURPRISE_CONTRACT = ISurprise(surpriseContractAddress);

    _pause();
  }

  function setPaused(bool paused) external onlyOwner {
    if (paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function _onMigrateLegacyToken(
    address owner,
    uint256 legacyTokenId,
    uint256 internalTokenId,
    uint256 amount,
    bytes calldata /* data */
  ) internal override whenNotPaused nonReentrant {
    // burn OpenSea legacy shacker; we could also transfer to MAKER and change the metadata but decided not to
    // amount is always `1`, so we don't bother to support minting multiple below
    _burn(legacyTokenId, amount);

    // reverts on invalid tokens as a safeguard to not migrate just any token
    uint256 newTokenId = convertInternalToNewId(internalTokenId);

    // mint shiny new shacker
    SHACKERS_CONTRACT.mint(owner, newTokenId, "");

    // mint surprise
    // OpenSea seems to not invoke onERC1155BatchReceived, but instead onERC1155Received per token transferred
    // when calling `safeBatchTransferFrom`, so minting the surprise can't be batched :/
    SURPRISE_CONTRACT.mint(owner, SURPRISE_ID, SURPRISE_AMOUNT);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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