// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IArrayErrors {
  /**
  * @dev Thrown when two related arrays have different lengths
  */
  error ARRAY_LENGTH_MISMATCH();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC165.sol";

/**
* @title ERC-1155 Multi Token Standard
* @dev See https://eips.ethereum.org/EIPS/eip-1155
* Note: The ERC-165 identifier for this interface is 0xd9b67a26.
*/
interface IERC1155 /* is IERC165 */ {
  /**
  * @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is
  *   enabled or disabled (absence of an event assumes disabled).
  * 
  * @param owner address that owns the tokens
  * @param operator address allowed or not to manage the tokens
  * @param approved whether the operator is allowed
  */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  /**
  * @dev MUST emit when the URI is updated for a token ID.
  * URIs are defined in RFC 3986.
  * The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
  * 
  * @param value the new uri
  * @param id the token id involved
  */
  event URI(string value, uint256 indexed id);
  /**
  * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred,
  *   including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
  * 
  * The `operator` argument MUST be the address of an account/contract
  *   that is approved to make the transfer (SHOULD be msg.sender).
  * The `from` argument MUST be the address of the holder whose balance is decreased.
  * The `to` argument MUST be the address of the recipient whose balance is increased.
  * The `ids` argument MUST be the list of tokens being transferred.
  * The `values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in ids)
  *   the holder balance is decreased by and match what the recipient balance is increased by.
  * When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
  * When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).
  * 
  * @param operator address ordering the transfer
  * @param from address tokens are being transferred from
  * @param to address tokens are being transferred to
  * @param ids identifiers of the tokens being transferred
  * @param values amounts of tokens being transferred
  */
  event TransferBatch(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256[] ids,
    uint256[] values
  );
  /**
  * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred,
  *   including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
  * 
  * The `operator` argument MUST be the address of an account/contract
  *   that is approved to make the transfer (SHOULD be msg.sender).
  * The `from` argument MUST be the address of the holder whose balance is decreased.
  * The `to` argument MUST be the address of the recipient whose balance is increased.
  * The `id` argument MUST be the token type being transferred.
  * The `value` argument MUST be the number of tokens the holder balance is decreased by
  *   and match what the recipient balance is increased by.
  * When minting/creating tokens, the `from` argument MUST be set to `0x0` (i.e. zero address).
  * When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).
  * 
  * @param operator address ordering the transfer
  * @param from address tokens are being transferred from
  * @param to address tokens are being transferred to
  * @param id identifier of the token being transferred
  * @param value amount of token being transferred
  */
  event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

  /**
  * @notice Transfers `values_` amount(s) of `ids_` from the `from_` address to the `to_` address specified
  *   (with safety call).
  * 
  * @dev Caller must be approved to manage the tokens being transferred out of the `from_` account
  *   (see "Approval" section of the standard).
  * 
  * MUST revert if `to_` is the zero address.
  * MUST revert if length of `ids_` is not the same as length of `values_`.
  * MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids_` is lower than the respective amount(s)
  *   in `values_` sent to the recipient.
  * MUST revert on any other error.        
  * MUST emit {TransferSingle} or {TransferBatch} event(s) such that all the balance changes are reflected
  *   (see "Safe Transfer Rules" section of the standard).
  * Balance changes and events MUST follow the ordering of the arrays
  *   (ids_[0]/values_[0] before ids_[1]/values_[1], etc).
  * After the above conditions for the transfer(s) in the batch are met,
  *   this function MUST check if `to_` is a smart contract (e.g. code size > 0).
  *   If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to_`
  *   and act appropriately (see "Safe Transfer Rules" section of the standard).
  */
  function safeBatchTransferFrom(
    address from_,
    address to_,
    uint256[] calldata ids_,
    uint256[] calldata values_,
    bytes calldata data_
  ) external;
  /**
  * @notice Transfers `value_` amount of an `id_` from the `from_` address to the `to_` address specified
  *   (with safety call).
  * 
  * @dev Caller must be approved to manage the tokens being transferred out of the `from_` account
  *   (see "Approval" section of the standard).
  * 
  * MUST revert if `to_` is the zero address.
  * MUST revert if balance of holder for token `id_` is lower than the `value_` sent.
  * MUST revert on any other error.
  * MUST emit the {TransferSingle} event to reflect the balance change
  *   (see "Safe Transfer Rules" section of the standard).
  * After the above conditions are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0).
  *   If so, it MUST call `onERC1155Received` on `to_` and act appropriately
  *   (see "Safe Transfer Rules" section of the standard).
  */
  function safeTransferFrom(address from_, address to_, uint256 id_, uint256 value_, bytes calldata data_) external;
  /**
  * @notice Enable or disable approval for `operator_` to manage all of the caller's tokens.
  * 
  * @dev MUST emit the {ApprovalForAll} event on success.
  */
  function setApprovalForAll(address operator_, bool approved_) external;

  /**
  * @notice Returns the balance of `owner_`'s tokens of type `id_`.
  */
  function balanceOf(address owner_, uint256 id_) external view returns (uint256);
  /**
  * @notice Returns the balance of multiple account/token pairs.
  */
  function balanceOfBatch(address[] calldata owners_, uint256[] calldata ids_) external view returns (uint256[] memory);
  /**
  * @notice Returns the approval status of `operator_` for `owner_`.
  */
  function isApprovedForAll(address owner_, address operator_) external view returns (bool);
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC1155Errors {
  /**
  * @dev Thrown when `operator` has not been approved to manage `tokenId` on behalf of `tokenOwner`.
  * 
  * @param from address owning the token
  * @param operator address trying to manage the token
  */
  error IERC1155_CALLER_NOT_APPROVED(address from, address operator);
  /**
  * @dev Thrown when trying to create series `id` that already exists.
  * 
  * @param id identifier of the NFT being referenced
  */
  error IERC1155_EXISTANT_TOKEN(uint256 id);
  /**
  * @dev Thrown when `from` tries to transfer more than they own.
  * 
  * @param from address that the NFT are being transferred from
  * @param id identifier of the NFT being referenced
  * @param balance amount of tokens that the address owns
  */
  error IERC1155_INSUFFICIENT_BALANCE(address from, uint256 id, uint256 balance);
  /**
  * @dev Thrown when operator tries to approve themselves for managing a token they own.
  */
  error IERC1155_INVALID_CALLER_APPROVAL();
  /**
  * @dev Thrown when a token is being transferred to the zero address.
  */
  error IERC1155_INVALID_TRANSFER();
  /**
  * @dev Thrown when the requested token doesn"t exist.
  * 
  * @param id identifier of the NFT being referenced
  */
  error IERC1155_NON_EXISTANT_TOKEN(uint256 id);
  /**
  * @dev Thrown when a token is being safely transferred to a contract unable to handle it.
  * 
  * @param receiver address unable to receive the token
  */
  error IERC1155_NON_ERC1155_RECEIVER(address receiver);
  /**
  * @dev Thrown when an ERC1155Receiver contract rejects a transfer.
  */
  error IERC1155_REJECTED_TRANSFER();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC1155.sol";

/**
* @dev Interface of the optional ERC1155MetadataExtension interface, as defined
* in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
*/
interface IERC1155MetadataURI /* is IERC1155 */ {
  /**
  * @dev Returns the URI for token type `id_`.
  *
  * If the `id_` substring is present in the URI, it must be replaced by clients with the actual token type ID.
  */
  function uri(uint256 id_) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC1155Receiver {
  /**
  * @dev Handles the receipt of a single ERC1155 token type.
  *   This function is called at the end of a {safeTransferFrom} after the balance has been updated.
  *   To accept the transfer, this must return
  *   `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
  *   (i.e. 0xf23a6e61, or its own function selector).
  */
  function onERC1155Received(
    address operator_,
    address from_,
    uint256 id_,
    uint256 value_,
    bytes calldata data_
  ) external returns (bytes4);
  /**
  * @dev Handles the receipt of a multiple ERC1155 token types.
  *   This function is called at the end of a {safeBatchTransferFrom} after the balances have been updated.
  *   To accept the transfer(s), this must return
  *   `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
  *   (i.e. 0xbc197c81, or its own function selector).
  */
  function onERC1155BatchReceived(
    address operator_,
    address from_,
    uint256[] calldata ids_,
    uint256[] calldata values_,
    bytes calldata data_
  ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC165 {
  /**
  * @notice Returns if a contract implements an interface.
  * @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
  */
  function supportsInterface(bytes4 interfaceId_) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC165.sol";

/**
* @dev Required interface of an ERC173 compliant contract, as defined in the
* https://eips.ethereum.org/EIPS/eip-173[EIP].
*/
interface IERC173 /* is IERC165 */ {
  /**
  * @dev This emits when ownership of a contract changes.
  * 
  * @param previousOwner the previous contract owner
  * @param newOwner the new contract owner
  */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
  * @notice Set the address of the new owner of the contract.
  * @dev Set newOwner_ to address(0) to renounce any ownership.
  */
  function transferOwnership(address newOwner_) external; 

  /**
  * @notice Returns the address of the owner.
  */
  function owner() external view returns(address);
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC173Errors {
  /**
  * @dev Thrown when `operator` is not the contract owner.
  * 
  * @param operator address trying to use a function reserved to contract owner without authorization
  */
  error IERC173_NOT_OWNER(address operator);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC165.sol";

/**
* @dev Interface for the NFT Royalty Standard
*/
interface IERC2981 /* is IERC165 */ {
  /**
  * ERC165 bytes to add to interface array - set in parent contract implementing this standard
  *
  * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
  * bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  * _registerInterface(_INTERFACE_ID_ERC2981);
  * 
  * @notice Called with the sale price to determine how much royalty is owed and to whom.
  */
  function royaltyInfo(
    uint256 tokenId_,
    uint256 salePrice_
  ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC2981Errors {
  /**
  * @dev Thrown when the desired royalty rate is higher than 10,000
  * 
  * @param royaltyRate the desired royalty rate
  * @param royaltyBase the maximum royalty rate
  */
  error IERC2981_INVALID_ROYALTIES(uint256 royaltyRate, uint256 royaltyBase);
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface INFTSupplyErrors {
  /**
  * @dev Thrown when trying to mint 0 token.
  */
  error NFT_INVALID_QTY();
  /**
  * @dev Thrown when trying to set max supply to an invalid amount.
  */
  error NFT_INVALID_SUPPLY();
  /**
  * @dev Thrown when trying to mint more tokens than the max allowed per transaction.
  * 
  * @param qtyRequested the amount of tokens requested
  * @param maxBatch the maximum amount that can be minted per transaction
  */
  error NFT_MAX_BATCH(uint256 qtyRequested, uint256 maxBatch);
  /**
  * @dev Thrown when trying to mint more tokens from the reserve than the amount left.
  * 
  * @param qtyRequested the amount of tokens requested
  * @param reserveLeft the amount of tokens left in the reserve
  */
  error NFT_MAX_RESERVE(uint256 qtyRequested, uint256 reserveLeft);
  /**
  * @dev Thrown when trying to mint more tokens than the amount left to be minted (except reserve).
  * 
  * @param qtyRequested the amount of tokens requested
  * @param remainingSupply the amount of tokens left in the reserve
  */
  error NFT_MAX_SUPPLY(uint256 qtyRequested, uint256 remainingSupply);
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "../interfaces/IERC173.sol";
import "../interfaces/IERC173Errors.sol";

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
abstract contract ERC173 is IERC173, IERC173Errors {
  // The owner of the contract
  address private _owner;

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
      if (owner() != msg.sender) {
        revert IERC173_NOT_OWNER(msg.sender);
      }
      _;
    }
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Sets the contract owner.
    * 
    * Note: This function needs to be called in the contract constructor to initialize the contract owner, 
    * if it is not, then parts of the contract might be non functional
    * 
    * @param owner_ : address that owns the contract
    */
    function _setOwner(address owner_) internal {
      _owner = owner_;
    }
  // **************************************

  // **************************************
  // *****       CONTRACT OWNER       *****
  // **************************************
    /**
    * @dev Transfers ownership of the contract to `newOwner_`.
    * 
    * @param newOwner_ : address of the new contract owner
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function transferOwnership(address newOwner_) public virtual onlyOwner {
      address _oldOwner_ = _owner;
      _owner = newOwner_;
      emit OwnershipTransferred(_oldOwner_, newOwner_);
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @dev Returns the address of the current contract owner.
    * 
    * @return address : the current contract owner
    */
    function owner() public view virtual returns (address) {
      return _owner;
    }
  // **************************************
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "../interfaces/IERC2981.sol";
import "../interfaces/IERC2981Errors.sol";

abstract contract ERC2981 is IERC2981, IERC2981Errors {
  // Royalty rate is stored out of 10,000 instead of a percentage to allow for
  // up to two digits below the unit such as 2.5% or 1.25%.
  uint public constant ROYALTY_BASE = 10000;
  // Represents the percentage of royalties on each sale on secondary markets.
  // Set to 0 to have no royalties.
  uint256 private _royaltyRate;
  // Address of the recipient of the royalties.
  address private _royaltyRecipient;

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
  /**
    * @dev Sets the royalty rate to `royaltyRate_` and the royalty recipient to `royaltyRecipient_`.
    * 
    * @param royaltyRecipient_ the address that will receive royalty payments
    * @param royaltyRate_ the percentage of the sale price that will be taken off as royalties,
    *   expressed in Basis Points (100 BP = 1%)
    * 
    * Requirements: 
    * 
    * - `royaltyRate_` cannot be higher than `10,000`;
    */
    function _setRoyaltyInfo(address royaltyRecipient_, uint256 royaltyRate_) internal virtual {
      if (royaltyRate_ > ROYALTY_BASE) {
        revert IERC2981_INVALID_ROYALTIES(royaltyRate_, ROYALTY_BASE);
      }
      _royaltyRate      = royaltyRate_;
      _royaltyRecipient = royaltyRecipient_;
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @notice Called with the sale price to determine how much royalty is owed and to whom.
    * 
    * Note: This function should be overriden to revert on a query for non existent token.
    * 
    * @param tokenId_ identifier of the NFT being referenced
    * @param salePrice_ the sale price of the token sold
    * 
    * @return address the address receiving the royalties
    * @return uint256 the royalty payment amount
    */
    /* solhint-disable no-unused-vars */
    function royaltyInfo(uint256 tokenId_, uint256 salePrice_) public view virtual override returns (address, uint256) {
      if (salePrice_ == 0 || _royaltyRate == 0) {
        return (_royaltyRecipient, 0);
      }
      uint256 _royaltyAmount_ = _royaltyRate * salePrice_ / ROYALTY_BASE;
      return (_royaltyRecipient, _royaltyAmount_);
    }
    /* solhint-enable no-unused-vars */
  // **************************************
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: MIT

/**
* @team: Asteria Labs
* @author: Lambdalf the White
*/

pragma solidity 0.8.17;

import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IArrayErrors.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC1155Errors.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/INFTSupplyErrors.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC165.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC1155.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC1155Receiver.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC1155MetadataURI.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/utils/ERC173.sol';
import '@lambdalf-dev/ethereum-contracts/contracts/utils/ERC2981.sol';
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Cover is 
IERC1155Errors, IArrayErrors, INFTSupplyErrors,
IERC165, IERC1155, IERC1155MetadataURI,
DefaultOperatorFilterer, ERC2981, ERC173 {
  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
    uint256 public constant DEFAULT_SERIES_ID = 1;
    uint256 public constant VOLUME_1 = 100;
    uint256 public constant VOLUME_2 = 200;
    uint256 public constant VOLUME_3 = 300;
    uint256 public constant VOLUME_4 = 400;
    uint256 public constant VOLUME_5 = 500;
    uint256 public constant VOLUME_6 = 600;
    uint256 public constant VOLUME_7 = 700;
    string public constant name = "Life of HEL";
    string public constant symbol = "LOH";
  // **************************************

  // **************************************
  // *****     STORAGE VARIABLES      *****
  // **************************************
    string  private _uri = "https://mint.lifeofhel.xyz/api/";
    // List of valid series
    BitMaps.BitMap private _validSeries;
    // Series ID mapped to balances
    mapping (uint256 => mapping(address => uint256)) private _balances;
    // Token owner mapped to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;
    // Series ID mapped to minter
    mapping (uint256 => address) public minters;
  // **************************************

  // **************************************
  // *****           ERROR            *****
  // **************************************
    /**
    * @dev Thrown when non minter tries to mint a token.
    * 
    * @param account the address trying to mint
    * @param id the series ID being minted
    */
    error NON_MINTER(address account, uint256 id);
  // **************************************

  constructor(address royaltyRecipent_) {
    _setOwner(msg.sender);
    _setRoyaltyInfo(royaltyRecipent_, 750);
  }

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Ensures that `id_` is a valid series
    * 
    * @param id_ the series id to validate 
    */
    modifier isValidSeries(uint256 id_) {
      if (! BitMaps.get(_validSeries, id_)) {
        revert IERC1155_NON_EXISTANT_TOKEN(id_);
      }
      _;
    }
    /**
    * @dev Ensures that `sender_` is a registered minter
    * 
    * @param sender_ the address to verify
    * @param id_ the series id to validate 
    */
    modifier isMinter(address sender_, uint256 id_) {
      if (minters[id_] != sender_) {
        revert NON_MINTER(sender_, id_);
      }
      _;
    }
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Internal function that checks if the receiver address is able to handle batches of IERC1155 tokens.
    * 
    * @param operator_ address sending the transaction
    * @param from_ address from where the tokens are sent
    * @param to_ address receiving the tokens
    * @param ids_ list of token types being sent
    * @param amounts_ list of amounts of tokens being sent
    * @param data_ additional data to accompany the call
    */
    function _doSafeBatchTransferAcceptanceCheck(
      address operator_,
      address from_,
      address to_,
      uint256[] memory ids_,
      uint256[] memory amounts_,
      bytes memory data_
    ) private {
      uint256 _size_;
      assembly {
        _size_ := extcodesize(to_)
      }
      if (_size_ > 0) {
        try IERC1155Receiver(to_).onERC1155BatchReceived(operator_, from_, ids_, amounts_, data_) returns (bytes4 retval) {
          if (retval != IERC1155Receiver.onERC1155BatchReceived.selector) {
            revert IERC1155_REJECTED_TRANSFER();
          }
        }
        catch (bytes memory reason) {
          if (reason.length == 0) {
            revert IERC1155_REJECTED_TRANSFER();
          }
          else {
            assembly {
              revert(add(32, reason), mload(reason))
            }
          }
        }
      }
    }
    /**
    * @dev Internal function that checks if the receiver address is able to handle IERC1155 tokens.
    * 
    * @param operator_ address sending the transaction
    * @param from_ address from where the tokens are sent
    * @param to_ address receiving the tokens
    * @param id_ the token type being sent
    * @param amount_ the amount of tokens being sent
    * @param data_ additional data to accompany the call
    */
    function _doSafeTransferAcceptanceCheck(
      address operator_,
      address from_,
      address to_,
      uint256 id_,
      uint256 amount_,
      bytes memory data_
    ) private {
      uint256 _size_;
      assembly {
        _size_ := extcodesize(to_)
      }
      if (_size_ > 0) {
        try IERC1155Receiver(to_).onERC1155Received(operator_, from_, id_, amount_, data_) returns (bytes4 retval) {
          if (retval != IERC1155Receiver.onERC1155Received.selector) {
            revert IERC1155_REJECTED_TRANSFER();
          }
        }
        catch (bytes memory reason) {
          if (reason.length == 0) {
            revert IERC1155_REJECTED_TRANSFER();
          }
          else {
            assembly {
              revert(add(32, reason), mload(reason))
            }
          }
        }
      }
    }
    /**
    * @dev Internal function that checks if `operator_` is allowed to manage tokens on behalf of `owner_`
    * 
    * @param owner_ address owning the tokens
    * @param operator_ address to check approval for
    */
    function _isApprovedOrOwner(address owner_, address operator_) internal view returns (bool) {
      return owner_ == operator_ || isApprovedForAll(owner_, operator_);
    }
    /**
    * @dev Internal function that checks whether `id_` is an existing series.
    * 
    * @param id_ the token type being verified
    */
    function _isValidSeries(uint256 id_) internal view returns (bool) {
      return BitMaps.get(_validSeries, id_);
    }
    /**
    * @dev Internal function that mints `amount_` tokens from series `id_` into `recipient_`.
    * 
    * @param recipient_ the address receiving the tokens
    * @param id_ the token type being sent
    * @param amount_ the amount of tokens being sent
    */
    // function _mint(address recipient_, uint256 id_, uint256 amount_) internal {
    //   unchecked {
    //     _balances[id_][recipient_] += amount_;
    //   }
    //   emit TransferSingle(msg.sender, address(0), recipient_, id_, amount_);
    // }
    /**
    * @dev Converts a `uint256` to its ASCII `string` decimal representation.
    * 
    * @param value_ the value being converted to its string representation
    */
    function _toString(uint256 value_) internal pure virtual returns (string memory str) {
      assembly {
        // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
        // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
        // We will need 1 word for the trailing zeros padding, 1 word for the length,
        // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
        let m := add(mload(0x40), 0xa0)
        // Update the free memory pointer to allocate.
        mstore(0x40, m)
        // Assign the `str` to the end.
        str := sub(m, 0x20)
        // Zeroize the slot after the string.
        mstore(str, 0)

        // Cache the end of the memory to calculate the length later.
        let end := str

        // We write the string from rightmost digit to leftmost digit.
        // The following is essentially a do-while loop that also handles the zero case.
        // prettier-ignore
        // solhint-disable-next-line
        for { let temp := value_ } 1 {} {
          str := sub(str, 1)
          // Write the character to the pointer.
          // The ASCII index of the "0" character is 48.
          mstore8(str, add(48, mod(temp, 10)))
          // Keep dividing `temp` until zero.
          temp := div(temp, 10)
          // prettier-ignore
          if iszero(temp) { break }
        }

        let length := sub(end, str)
        // Move the pointer 32 bytes leftwards to make room for the length.
        str := sub(str, 0x20)
        // Store the length.
        mstore(str, length)
      }
    }
  // **************************************

  // **************************************
  // *****          DELEGATE          *****
  // **************************************
    // *********
    // * Cover *
    // *********
      /**
      * @notice Mints `qty_` amount of `id_` to the `recipient_` address.
      * 
      * @param id_ the series id to mint 
      * @param qty_ amount of tokens to mint
      * @param recipient_ address receiving the tokens
      * 
      * Requirements:
      * 
      * - `id_` must be a valid series
      * - Caller must be allowed to mint tokens
      */
      function mintTo(uint256 id_, uint256 qty_, address recipient_)
      external
      isValidSeries(id_)
      isMinter(msg.sender, id_) {
        unchecked {
          _balances[id_][recipient_] += qty_;
        }
        emit TransferSingle(msg.sender, address(0), recipient_, id_, qty_);
      }
    // *********
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    // *********
    // * Cover *
    // *********
      /**
      * @notice Burns `qty_` amount of `id_` on behalf of `tokenOwner_`.
      * 
      * @param id_ the series id to mint 
      * @param qty_ amount of tokens to mint
      * @param tokenOwner_ address owning the tokens
      * 
      * Requirements:
      * 
      * - `id_` must be a valid series
      * - Caller must be allowed to burn tokens
      * - `tokenOwner_` must own at least `qty_` tokens of series `id_`
      */
      function burnFrom(uint256 id_, uint256 qty_, address tokenOwner_)
      external
      isValidSeries(id_) {
        if (! _isApprovedOrOwner(tokenOwner_, msg.sender)) {
          revert IERC1155_CALLER_NOT_APPROVED(tokenOwner_, msg.sender);
        }
        uint256 _balance_ = _balances[id_][tokenOwner_];
        if (_balance_ < qty_) {
          revert IERC1155_INSUFFICIENT_BALANCE(tokenOwner_, id_, _balance_);
        }
        unchecked {
          _balances[id_][tokenOwner_] -= qty_;
        }
        emit TransferSingle(msg.sender, tokenOwner_, address(0), id_, qty_);
      }
    // *********

    // ************
    // * IERC1155 *
    // ************
      /**
      * @notice Transfers `amounts_` amount(s) of `ids_` from the `from_` address to the `to_` address specified (with safety call).
      * 
      * @param from_ Source address
      * @param to_ Target address
      * @param ids_ IDs of each token type (order and length must match `amounts_` array)
      * @param amounts_ Transfer amounts per token type (order and length must match `ids_` array)
      * @param data_ Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to_`
      * 
      * Requirements:
      * 
      * - Caller must be approved to manage the tokens being transferred out of the `from_` account (see "Approval" section of the standard).
      * - MUST revert if `to_` is the zero address.
      * - MUST revert if length of `ids_` is not the same as length of `amounts_`.
      * - MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids_` is lower than the respective amount(s) in `amounts_` sent to the recipient.
      * - MUST revert on any other error.        
      * - MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
      * - Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_amounts[0] before ids_[1]/_amounts[1], etc).
      * - After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to_` and act appropriately (see "Safe Transfer Rules" section of the standard).                      
      */
      function safeBatchTransferFrom(
        address from_,
        address to_,
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        bytes calldata data_
      ) external override onlyAllowedOperator(from_) {
        if (to_ == address(0)) {
          revert IERC1155_INVALID_TRANSFER();
        }
        uint256 _len_ = ids_.length;
        if (amounts_.length != _len_) {
          revert ARRAY_LENGTH_MISMATCH();
        }
        address _operator_ = msg.sender;
        if (! _isApprovedOrOwner(from_, _operator_)) {
          revert IERC1155_CALLER_NOT_APPROVED(from_, _operator_);
        }
        for (uint256 i; i < _len_;) {
          if (! _isValidSeries(ids_[i])) {
            revert IERC1155_NON_EXISTANT_TOKEN(ids_[i]);
          }
          uint256 _balance_ = _balances[ids_[i]][from_];
          if (_balance_ < amounts_[i]) {
            revert IERC1155_INSUFFICIENT_BALANCE(from_, ids_[i], _balance_);
          }
          unchecked {
            _balances[ids_[i]][from_] = _balance_ - amounts_[i];
          }
          _balances[ids_[i]][to_] += amounts_[i];
          unchecked {
            ++i;
          }
        }
        emit TransferBatch(_operator_, from_, to_, ids_, amounts_);

        _doSafeBatchTransferAcceptanceCheck(_operator_, from_, to_, ids_, amounts_, data_);
      }
      /**
      * @notice Transfers `amount_` amount of an `id_` from the `from_` address to the `to_` address specified (with safety call).
      * 
      * @param from_ Source address
      * @param to_ Target address
      * @param id_ ID of the token type
      * @param amount_ Transfer amount
      * @param data_ Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to_`
      * 
      * Requirements:
      * 
      * - Caller must be approved to manage the tokens being transferred out of the `from_` account (see "Approval" section of the standard).
      * - MUST revert if `to_` is the zero address.
      * - MUST revert if balance of holder for token type `id_` is lower than the `amount_` sent.
      * - MUST revert on any other error.
      * - MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
      * - After the above conditions are met, this function MUST check if `to_` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to_` and act appropriately (see "Safe Transfer Rules" section of the standard).        
      */
      function safeTransferFrom(
        address from_,
        address to_,
        uint256 id_,
        uint256 amount_,
        bytes calldata data_
      ) external override isValidSeries(id_) onlyAllowedOperator(from_) {
        if (to_ == address(0)) {
          revert IERC1155_INVALID_TRANSFER();
        }
        address _operator_ = msg.sender;
        if (! _isApprovedOrOwner(from_, _operator_)) {
          revert IERC1155_CALLER_NOT_APPROVED(from_, _operator_);
        }
        uint256 _balance_ = _balances[id_][from_];
        if (_balance_ < amount_) {
          revert IERC1155_INSUFFICIENT_BALANCE(from_, id_, _balance_);
        }
        unchecked {
          _balances[id_][from_] = _balance_ - amount_;
        }
        _balances[id_][to_] += amount_;
        emit TransferSingle(_operator_, from_, to_, id_, amount_);
        _doSafeTransferAcceptanceCheck(_operator_, from_, to_, id_, amount_, data_);
      }
      /**
      * @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
      * 
      * @param operator_ Address to add to the set of authorized operators
      * @param approved_ True if the operator is approved, false to revoke approval
      * 
      * Requirements:
      * 
      * - MUST emit the ApprovalForAll event on success.
      */
      function setApprovalForAll(address operator_, bool approved_)
      external
      override
      onlyAllowedOperatorApproval(operator_) {
        address _tokenOwner_ = msg.sender;
        if (_tokenOwner_ == operator_) {
          revert IERC1155_INVALID_CALLER_APPROVAL();
        }
        _operatorApprovals[_tokenOwner_][operator_] = approved_;
        emit ApprovalForAll(_tokenOwner_, operator_, approved_);
      }
    // ************
  // **************************************

  // **************************************
  // *****       CONTRACT OWNER       *****
  // **************************************
    // *********
    // * Cover *
    // *********
      /**
      * @notice Creates a new series
      * 
      * @param id_ the new series ID
      * @param minter_ the address allowed to mint (address zero to revoke minter status)
      * 
      * Requirements:
      * 
      * - Caller must be the contract owner
      * - `id_` must not be a valid series ID
      */
      function createSeries(uint256 id_, address minter_) external onlyOwner {
        if (BitMaps.get(_validSeries, id_)) {
          revert IERC1155_EXISTANT_TOKEN(id_);
        }
        BitMaps.set(_validSeries, id_);
        minters[id_] = minter_;
      }
      /**
      * @notice Sets the minter of an existing series
      * 
      * @param id_ the series ID
      * @param minter_ the address allowed to mint (address zero to revoke minter status)
      * 
      * Requirements:
      * 
      * - Caller must be the contract owner
      * - `id_` must be a valid series ID
      */
      function setMinter(uint256 id_, address minter_) external onlyOwner isValidSeries(id_) {
        minters[id_] = minter_;
      }
      /**
      * @notice Updates the royalty recipient and rate.
      * 
      * @param royaltyRecipient_ the new recipient of the royalties
      * @param royaltyRate_ the new royalty rate
      * 
      * Requirements:
      * 
      * - Caller must be the contract owner
      * - `royaltyRate_` must be between 0 and 10,000
      */
      function setRoyaltyInfo(address royaltyRecipient_, uint256 royaltyRate_) external onlyOwner {
        _setRoyaltyInfo(royaltyRecipient_, royaltyRate_);
      }
      /**
      * @notice Sets the uri of the tokens.
      * 
      * @param uri_ The new uri of the tokens
      */
      function setURI(string memory uri_) external onlyOwner {
        _uri = uri_;
        emit URI(uri_, DEFAULT_SERIES_ID);
      }
    // *********
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    // *********
    // * Cover *
    // *********
      /**
      * @notice Returns whether series `id_` exists.
      * 
      * @param id_ ID of the token type
      * 
      * @return TRUE if the series exists, FALSE otherwise
      */
      function exist(uint256 id_) public view returns (bool) {
        return _isValidSeries(id_);
      }
    // *********

    // ***********
    // * IERC165 *
    // ***********
      /**
      * @notice Query if a contract implements an interface.
      * @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
      * 
      * @param interfaceID_ the interface identifier, as specified in ERC-165
      * 
      * @return TRUE if the contract implements `interfaceID_` and `interfaceID_` is not 0xffffffff, FALSE otherwise
      */
      function supportsInterface(bytes4 interfaceID_) public pure override returns (bool) {
        return 
          interfaceID_ == type(IERC165).interfaceId ||
          interfaceID_ == type(IERC173).interfaceId ||
          interfaceID_ == type(IERC1155).interfaceId ||
          interfaceID_ == type(IERC1155MetadataURI).interfaceId ||
          interfaceID_ == type(IERC2981).interfaceId;
      }
    // ***********

    // ************
    // * IERC1155 *
    // ************
      /**
      * @notice Get the balance of an account's tokens.
      * 
      * @param owner_ the address of the token holder
      * @param id_ ID of the token type
      * 
      * @return `owner_`'s balance of the token type requested
      */
      function balanceOf(address owner_, uint256 id_) public view override isValidSeries(id_) returns (uint256) {
        return _balances[id_][owner_];
      }
      /**
      * @notice Get the balance of multiple account/token pairs
      * 
      * @param owners_ the addresses of the token holders
      * @param ids_ ID of the token types
      * 
      * @return the `owners_`' balance of the token types requested (i.e. balance for each (owner, id) pair)
      */
      function balanceOfBatch(address[] calldata owners_, uint256[] calldata ids_)
      public
      view
      override
      returns (uint256[] memory) {
        uint256 _len_ = owners_.length;
        if (_len_ != ids_.length) {
          revert ARRAY_LENGTH_MISMATCH();
        }
        uint256[] memory _balances_ = new uint256[](_len_);
        while (_len_ > 0) {
          unchecked {
            --_len_;
          }
          if (! _isValidSeries(ids_[_len_])) {
            revert IERC1155_NON_EXISTANT_TOKEN(ids_[_len_]);
          }
          _balances_[_len_] = _balances[ids_[_len_]][owners_[_len_]];
        }
        return _balances_;
      }
      /**
      * @notice Queries the approval status of an operator for a given owner.
      * 
      * @param owner_ the owner of the tokens
      * @param operator_ address of authorized operator
      * 
      * @return TRUE if the operator is approved, FALSE if not
      */
      function isApprovedForAll(address owner_, address operator_) public view override returns (bool) {
        return _operatorApprovals[owner_][operator_];
      }
    // ************

    // ***********************
    // * IERC1155MetadataURI *
    // ***********************
      /**
      * @dev Returns the URI for token type `id`.
      */
      function uri(uint256 id_) external view isValidSeries(id_) returns (string memory) {
        return bytes(_uri).length > 0 ? string(abi.encodePacked(_uri, _toString(id_))) : _toString(id_);
      }
    // ***********************
  // **************************************
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";
/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";
/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}