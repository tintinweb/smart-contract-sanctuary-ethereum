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

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IContractState {
  /**
  * @dev Thrown when a function is called with the wrong contract state.
  * 
  * @param currentState the current state of the contract
  */
  error ContractState_INCORRECT_STATE(uint8 currentState);
  /**
  * @dev Thrown when trying to set the contract state to an invalid value.
  * 
  * @param invalidState the invalid contract state
  */
  error ContractState_INVALID_STATE(uint8 invalidState);

  /**
  * @dev Emitted when the sale state changes
  * 
  * @param previousState the previous state of the contract
  * @param newState the new state of the contract
  */
  event ContractStateChanged(uint8 indexed previousState, uint8 indexed newState);

  /**
  * @dev Returns the current contract state.
  */
  function getContractState() external view returns (uint8);
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

pragma solidity 0.8.17;

// import "./IERC165.sol";

/**
* @title ERC-721 Non-Fungible Token Standard
* @dev See https://eips.ethereum.org/EIPS/eip-721
*  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
*/
interface IERC721 /* is IERC165 */ {
  /**
  * @dev This emits when the approved address for an NFT is changed or reaffirmed.
  *   The zero address indicates there is no approved address.
  *   When a Transfer event emits, this also indicates that the approved address for that NFT (if any) is reset to none.
  * 
  * @param owner address that owns the token
  * @param approved address that is allowed to manage the token
  * @param tokenId identifier of the token being approved
  */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  /**
  * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage all NFTs of the owner.
  * 
  * @param owner address that owns the tokens
  * @param operator address that is allowed or not to manage the tokens
  * @param approved whether the operator is allowed or not
  */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  /**
  * @dev This emits when ownership of any NFT changes by any mechanism.
  *   This event emits when NFTs are created (`from` == 0) and destroyed (`to` == 0).
  *   Exception: during contract creation, any number of NFTs may be created and assigned without emitting Transfer.
  *   At the time of any transfer, the approved address for that NFT (if any) is reset to none.
  * 
  * @param from address the token is being transferred from
  * @param to address the token is being transferred to
  * @param tokenId identifier of the token being transferred
  */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
  * @notice Change or reaffirm the approved address for an NFT
  * @dev The zero address indicates there is no approved address.
  *   Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
  */
  function approve(address approved_, uint256 tokenId_) external;
  /**
  * @notice Transfers the ownership of an NFT from one address to another address
  * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
  *   Throws if `from_` is not the current owner.
  *   Throws if `to_` is the zero address.
  *   Throws if `tokenId_` is not a valid NFT.
  *   When transfer is complete, this function checks if `to_` is a smart contract (code size > 0).
  *   If so, it calls {onERC721Received} on `to_` and throws if the return value is not
  *   `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
  */
  function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes calldata data_) external;
  /**
  * @notice Transfers the ownership of an NFT from one address to another address
  * @dev This works identically to the other function with an extra data parameter,
  *   except this function just sets data to "".
  */
  function safeTransferFrom(address from_, address to_, uint256 tokenId_) external;
  /**
  * @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets.
  * @dev Emits the ApprovalForAll event. The contract MUST allow multiple operators per owner.
  */
  function setApprovalForAll(address operator_, bool approved_) external;
  /**
  * @notice Transfer ownership of an NFT.
  *   The caller is responsible to confirm that `to_` is capable of receiving nfts or
  *   else they may be permanently lost
  * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved address for this NFT.
  *   Throws if `from_` is not the current owner.
  *   Throws if `to_` is the zero address.
  *   Throws if `tokenId_` is not a valid NFT.
  */
  function transferFrom(address from_, address to_, uint256 tokenId_) external;

  /**
  * @notice Count all NFTs assigned to an owner
  * @dev NFTs assigned to the zero address are considered invalid. Throws for queries about the zero address.
  */
  function balanceOf(address owner_) external view returns (uint256);
  /**
  * @notice Get the approved address for a single NFT
  * @dev Throws if `tokenId_` is not a valid NFT.
  */
  function getApproved(uint256 tokenId_) external view returns (address);
  /**
  * @notice Query if an address is an authorized operator for another address
  */
  function isApprovedForAll(address owner_, address operator_) external view returns (bool);
  /**
  * @notice Find the owner of an NFT
  * @dev NFTs assigned to zero address are considered invalid, and queries
  *  about them do throw.
  */
  function ownerOf(uint256 tokenId_) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC721.sol";

/**
* @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
* @dev See https://eips.ethereum.org/EIPS/eip-721
* Note: the ERC-165 identifier for this interface is 0x780e9d63.
*/
interface IERC721Enumerable /* is IERC721 */ {
  /**
  * @notice Enumerate valid NFTs
  * @dev Throws if `index_` >= {totalSupply()}.
  */
  function tokenByIndex(uint256 index_) external view returns (uint256);
  /**
  * @notice Enumerate NFTs assigned to an owner
  * @dev Throws if `index_` >= {balanceOf(owner_)} or if `owner_` is the zero address, representing invalid NFTs.
  */
  function tokenOfOwnerByIndex(address owner_, uint256 index_) external view returns (uint256);
  /**
  * @notice Count NFTs tracked by this contract
  */
  function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IERC721Errors {
  /**
  * @dev Thrown when `operator` has not been approved to manage `tokenId` on behalf of `tokenOwner`.
  * 
  * @param tokenOwner address owning the token
  * @param operator address trying to manage the token
  * @param tokenId identifier of the NFT being referenced
  */
  error IERC721_CALLER_NOT_APPROVED(address tokenOwner, address operator, uint256 tokenId);
  /**
  * @dev Thrown when `operator` tries to approve themselves for managing a token they own.
  * 
  * @param operator address that is trying to approve themselves
  */
  error IERC721_INVALID_APPROVAL(address operator);
  /**
  * @dev Thrown when a token is being transferred to the zero address.
  */
  error IERC721_INVALID_TRANSFER();
  /**
  * @dev Thrown when a token is being transferred from an address that doesn"t own it.
  * 
  * @param tokenOwner address owning the token
  * @param from address that the NFT is being transferred from
  * @param tokenId identifier of the NFT being referenced
  */
  error IERC721_INVALID_TRANSFER_FROM(address tokenOwner, address from, uint256 tokenId);
  /**
  * @dev Thrown when the requested token doesn"t exist.
  * 
  * @param tokenId identifier of the NFT being referenced
  */
  error IERC721_NONEXISTANT_TOKEN(uint256 tokenId);
  /**
  * @dev Thrown when a token is being safely transferred to a contract unable to handle it.
  * 
  * @param receiver address unable to receive the token
  */
  error IERC721_NON_ERC721_RECEIVER(address receiver);
  /**
  * @dev Thrown when trying to get the token at an index that doesn"t exist.
  * 
  * @param index the inexistant index
  */
  error IERC721Enumerable_INDEX_OUT_OF_BOUNDS(uint256 index);
  /**
  * @dev Thrown when trying to get the token owned by `tokenOwner` at an index that doesn"t exist.
  * 
  * @param tokenOwner address owning the token
  * @param index the inexistant index
  */
  error IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS(address tokenOwner, uint256 index);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// import "./IERC721.sol";

/**
* @title ERC-721 Non-Fungible Token Standard, optional metadata extension
* @dev See https://eips.ethereum.org/EIPS/eip-721
*  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
*/
interface IERC721Metadata /* is IERC721 */ {
  /**
  * @notice A descriptive name for a collection of NFTs in this contract
  */
  function name() external view returns (string memory);
  /**
  * @notice An abbreviated name for NFTs in this contract
  */
  function symbol() external view returns (string memory);
  /**
  * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
  * @dev Throws if `tokenId_` is not a valid NFT. URIs are defined in RFC 3986.
  *   The URI may point to a JSON file that conforms to the "ERC721 Metadata JSON Schema".
  */
  function tokenURI(uint256 tokenId_) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
* @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
*/
interface IERC721Receiver {
  /**
  * @notice Handle the receipt of an NFT
  * @dev The ERC721 smart contract calls this function on the recipient
  *   after a `transfer`. This function MAY throw to revert and reject the
  *   transfer. Return of other than the magic value MUST result in the
  *   transaction being reverted.
  * Note: the contract address is always the message sender.
  */
  function onERC721Received(
    address operator_,
    address from_,
    uint256 tokenId_,
    bytes calldata data_
  ) external returns(bytes4);
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

interface IEtherErrors {
  /**
  * @dev Thrown when an incorrect amount of eth is being sent for a payable operation.
  * 
  * @param amountReceived the amount the contract received
  * @param amountExpected the actual amount the contract expected to receive
  */
  error ETHER_INCORRECT_PRICE(uint256 amountReceived, uint256 amountExpected);
  /**
  * @dev Thrown when trying to withdraw from the contract with no balance.
  */
  error ETHER_NO_BALANCE();
  /**
  * @dev Thrown when contract fails to send ether to recipient.
  * 
  * @param to the recipient of the ether
  * @param amount the amount of ether being sent
  */
  error ETHER_TRANSFER_FAIL(address to, uint256 amount);
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

import "../interfaces/IContractState.sol";

abstract contract ContractState is IContractState {
  // Enum to represent the sale state, defaults to ``PAUSED``.
  uint8 public constant PAUSED = 0;

  // The current state of the contract
  uint8 private _contractState;

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Ensures that contract state is `expectedState_`.
    * 
    * @param expectedState_ : the desirable contract state
    */
    modifier isState(uint8 expectedState_) {
      if (_contractState != expectedState_) {
        revert ContractState_INCORRECT_STATE(_contractState);
      }
      _;
    }
    /**
    * @dev Ensures that contract state is not `unexpectedState_`.
    * 
    * @param unexpectedState_ : the undesirable contract state
    */
    modifier isNotState(uint8 unexpectedState_) {
      if (_contractState == unexpectedState_) {
        revert ContractState_INCORRECT_STATE(_contractState);
      }
      _;
    }
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Internal function setting the contract state to `newState_`.
    * 
    * Note: Contract state defaults to ``PAUSED``.
    *   To maintain extendability, this value kept as uint8 instead of enum.
    *   As a result, it is possible to set the state to an incorrect value.
    *   To avoid issues, `newState_` should be validated before calling this function
    */
    function _setContractState(uint8 newState_) internal virtual {
      uint8 _previousState_ = _contractState;
      _contractState = newState_;
      emit ContractStateChanged(_previousState_, newState_);
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @dev Returns the current contract state.
    * 
    * @return uint8 : the current contract state
    */
    function getContractState() public virtual view override returns (uint8) {
      return _contractState;
    }
  // **************************************
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

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

abstract contract Whitelist_ECDSA {
  // Errors
  /**
  * @dev Thrown when trying to query the whitelist while it"s not set
  */
  error Whitelist_NOT_SET();
  /**
  * @dev Thrown when `account` has consumed their alloted access and tries to query more
  * 
  * @param account address trying to access the whitelist
  */
  error Whitelist_CONSUMED(address account);
  /**
  * @dev Thrown when `account` does not have enough alloted access to fulfil their query
  * 
  * @param account address trying to access the whitelist
  */
  error Whitelist_FORBIDDEN(address account);

  /**
  * @dev A structure representing a signature proof to be decoded by the contract
  */
  struct Proof {
    bytes32 r;
    bytes32 s;
    uint8   v;
  }

  address private _adminSigner;
  mapping(uint8 => mapping(address => uint256)) private _consumed;

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Ensures that `account_` has `qty_` alloted access on the `whitelistId_` whitelist.
    * 
    * @param account_ the address to validate access
    * @param whitelistId_ the identifier of the whitelist being queried
    * @param alloted_ the max amount of whitelist spots allocated
    * @param proof_ the signature proof to validate whitelist allocation
    * @param qty_ the amount of whitelist access requested
    */
    modifier isWhitelisted(address account_, uint8 whitelistId_, uint256 alloted_, Proof memory proof_, uint256 qty_) {
      uint256 _allowed_ = checkWhitelistAllowance(account_, whitelistId_, alloted_, proof_);
      if (_allowed_ < qty_) {
        revert Whitelist_FORBIDDEN(account_);
      }
      _;
    }
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Consumes `amount_` whitelist access passes from `account_`.
    * 
    * @param account_ the address to consume access from
    * @param whitelistId_ the identifier of the whitelist being queried
    * @param qty_ the amount of whitelist access consumed
    * 
    * Note: Before calling this function, eligibility should be checked through {Whitelistable-checkWhitelistAllowance}.
    */
    function _consumeWhitelist(address account_, uint8 whitelistId_, uint256 qty_) internal {
      unchecked {
        _consumed[ whitelistId_ ][ account_ ] += qty_;
      }
    }
    /**
    * @dev Sets the pass to protect the whitelist.
    * 
    * @param adminSigner_ : the address validating the whitelist signatures
    */
    function _setWhitelist(address adminSigner_) internal virtual {
      _adminSigner = adminSigner_;
    }
    /**
    * @dev Internal function to decode a signature and compare it with the `_adminSigner`.
    * 
    * @param account_ the address to validate access
    * @param whitelistId_ the identifier of the whitelist being queried
    * @param alloted_ the max amount of whitelist spots allocated
    * @param proof_ the signature proof to validate whitelist allocation
    * 
    * @return bool whether the signature is valid or not
    */ 
    function _validateProof(
      address account_,
      uint8 whitelistId_,
      uint256 alloted_,
      Proof memory proof_
    ) private view returns (bool) {
      bytes32 _digest_ = keccak256(abi.encode(whitelistId_, alloted_, account_));
      address _signer_ = ecrecover(_digest_, proof_.v, proof_.r, proof_.s);
      return _signer_ == _adminSigner;
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @dev Returns the amount that `account_` is allowed to access from the whitelist.
    * 
    * @param account_ the address to validate access
    * @param whitelistId_ the identifier of the whitelist being queried
    * @param alloted_ the max amount of whitelist spots allocated
    * @param proof_ the signature proof to validate whitelist allocation
    * 
    * @return uint256 : the total amount of whitelist allocation remaining for `account_`
    * 
    * Requirements:
    * 
    * - `_adminSigner` must be set.
    */
    function checkWhitelistAllowance(
      address account_,
      uint8 whitelistId_,
      uint256 alloted_,
      Proof memory proof_
    ) public view returns (uint256) {
      if (_adminSigner == address(0)) {
        revert Whitelist_NOT_SET();
      }

      if (_consumed[ whitelistId_ ][ account_ ] >= alloted_) {
        revert Whitelist_CONSUMED(account_);
      }

      if (! _validateProof(account_, whitelistId_, alloted_, proof_)) {
        revert Whitelist_FORBIDDEN(account_);
      }

      return alloted_ - _consumed[ whitelistId_ ][ account_ ];
    }
  // **************************************
}

// SPDX-License-Identifier: MIT

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC165.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IArrayErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IEtherErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/INFTSupplyErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721Errors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721Receiver.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721Enumerable.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721Metadata.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC173.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC2981.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ContractState.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/Whitelist_ECDSA.sol";
import "operator-filter-registry/src/UpdatableOperatorFilterer.sol";

contract CuratedBlocks is
IArrayErrors, IEtherErrors, INFTSupplyErrors, IERC721Errors,
IERC721, IERC721Enumerable, IERC721Metadata,
IERC165, ERC173, ERC2981, ContractState, Whitelist_ECDSA, UpdatableOperatorFilterer {
  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
    address public constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    address public constant DEFAULT_OPERATOR_FILTER_REGISTRY = address(0x000000000000AAeB6D7670E522A718067333cd4E);
    uint256 public constant MAX_BATCH = 10;
  	uint8 public constant MAGMA_SALE = 1;
    uint8 public constant PRIVATE_SALE = 2;
    uint8 public constant WAITLIST_SALE = 3;
    string  public constant name = "CuratedBlocks Genesis";
    string  public constant symbol = "CBLOCKS";
  // **************************************

  // **************************************
  // *****     STORAGE VARIABLES      *****
  // **************************************
    uint256 public maxSupply;
    address public treasury;
    string  private _baseUri;
    uint256 private _nextId = 3;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _approvals;
    // List of owner addresses
    mapping(uint256 => address) private _owners;
    // Token owners mapped to balance
    mapping(address => uint256) private _balances;
    // Token owner mapped to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    // Phase mapped to sale price
    mapping(uint8 => uint256) private _salePrice;
  // **************************************

  constructor(address airdropAddress_, address royaltyRecipient_, address treasury_, address signerWallet_, uint256 maxSupply_)
  UpdatableOperatorFilterer(DEFAULT_OPERATOR_FILTER_REGISTRY, DEFAULT_SUBSCRIPTION, true) {
    maxSupply = maxSupply_;
    _salePrice[MAGMA_SALE] = 0.044 ether;
    _salePrice[PRIVATE_SALE] = 0.055 ether;
    _salePrice[WAITLIST_SALE] = 0.055 ether;
    treasury = treasury_;
    _setOwner(msg.sender);
    _setRoyaltyInfo(royaltyRecipient_, 250);
    _setWhitelist(signerWallet_);
    _owners[1] = airdropAddress_;
    _owners[2] = airdropAddress_;
  }

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Ensures the token exist. 
    * A token exists if it has been minted and is not owned by the null address.
    * 
    * @param tokenId_ identifier of the NFT being referenced
    */
    modifier exists(uint256 tokenId_) {
      if (! _exists(tokenId_)) {
        revert IERC721_NONEXISTANT_TOKEN(tokenId_);
      }
      _;
    }
  // **************************************

  // **************************************
  // *****          INTERNAL          *****
  // **************************************
    /**
    * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
    * The call is not executed if the target address is not a contract.
    *
    * @param from_ address owning the token being transferred
    * @param to_ address the token is being transferred to
    * @param tokenId_ identifier of the NFT being referenced
    * @param data_ optional data to send along with the call
    * 
    * @return whether the call correctly returned the expected magic value
    */
    function _checkOnERC721Received(address from_, address to_, uint256 tokenId_, bytes memory data_) internal returns (bool) {
      // This method relies on extcodesize, which returns 0 for contracts in
      // construction, since the code is only stored at the end of the
      // constructor execution.
      // 
      // IMPORTANT
      // It is unsafe to assume that an address not flagged by this method
      // is an externally-owned account (EOA) and not a contract.
      //
      // Among others, the following types of addresses will not be flagged:
      //
      //  - an externally-owned account
      //  - a contract in construction
      //  - an address where a contract will be created
      //  - an address where a contract lived, but was destroyed
      uint256 _size_;
      assembly {
        _size_ := extcodesize(to_)
      }

      // If address is a contract, check that it is aware of how to handle ERC721 tokens
      if (_size_ > 0) {
        try IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) returns (bytes4 retval) {
          return retval == IERC721Receiver.onERC721Received.selector;
        }
        catch (bytes memory reason) {
          if (reason.length == 0) {
            revert IERC721_NON_ERC721_RECEIVER(to_);
          }
          else {
            assembly {
              revert(add(32, reason), mload(reason))
            }
          }
        }
      }
      else {
        return true;
      }
    }
    /**
    * @dev Internal function to process whitelist status.
    * 
    * @param account_ address minting a token
    * @param currentState_ the current contract state
    * @param whitelistType_ identifies the whitelist used
    * @param alloted_ the maximum alloted for that user
    * @param qty_ the amount of tokens to be minted
    * @param proof_ the signature to verify whitelist allocation
    */
    function _processWhitelist(address account_, uint8 currentState_, uint8 whitelistType_, uint256 alloted_, uint256 qty_, Proof memory proof_) internal {
      uint256 _allowed_;
      if (currentState_ == MAGMA_SALE) {
        _allowed_ = checkWhitelistAllowance(account_, MAGMA_SALE, alloted_, proof_);
        if (_allowed_ < qty_) {
          revert Whitelist_FORBIDDEN(account_);
        }
        _consumeWhitelist(account_, MAGMA_SALE, qty_);
      }
      else if (currentState_ == PRIVATE_SALE) {
        if (whitelistType_ == MAGMA_SALE) {
          _allowed_ = checkWhitelistAllowance(account_, MAGMA_SALE, alloted_, proof_);
          if (_allowed_ < qty_) {
            revert Whitelist_FORBIDDEN(account_);
          }
          _consumeWhitelist(account_, MAGMA_SALE, qty_);
        }
        else {
          _allowed_ = checkWhitelistAllowance(account_, PRIVATE_SALE, alloted_, proof_);
          if (_allowed_ < qty_) {
            revert Whitelist_FORBIDDEN(account_);
          }
          _consumeWhitelist(account_, PRIVATE_SALE, qty_);
        }
      }
      else {
        checkWhitelistAllowance(account_, WAITLIST_SALE, 1, proof_);
      }
    }
    /**
    * @dev Internal function returning whether a token exists. 
    * A token exists if it has been minted and is not owned by the null address.
    * 
    * Note: this function must be overriden if tokens are burnable.
    * 
    * @param tokenId_ identifier of the NFT being referenced
    * 
    * @return whether the token exists
    */
    function _exists(uint256 tokenId_) internal view returns (bool) {
      if (tokenId_ == 0) {
        return false;
      }
      return _owners[tokenId_] != address(0);
    }
    /**
    * @dev Internal function returning whether `operator_` is allowed to handle `tokenId_`
    * 
    * Note: To avoid multiple checks for the same data, it is assumed 
    * that existence of `tokenId_` has been verified prior via {_exists}
    * If it hasn't been verified, this function might panic
    * 
    * @param operator_ address that tries to handle the token
    * @param tokenId_ identifier of the NFT being referenced
    * 
    * @return whether `operator_` is allowed to manage the token
    */
    function _isApprovedOrOwner(address tokenOwner_, address operator_, uint256 tokenId_) internal view returns (bool) {
      return 
        operator_ == tokenOwner_ ||
        operator_ == getApproved(tokenId_) ||
        isApprovedForAll(tokenOwner_, operator_);
    }
    /**
    * @dev Mints a token and transfer it to `to_`.
    * 
    * This internal function can be used to perform token minting.
    * If the Vested Pass contract is set, it will also burn a vested pass from the token receiver
    * 
    * @param to_ address receiving the tokens
    * 
    * Emits a {Transfer} event.
    */
    function _mint(address to_, uint256 tokenId_) internal {
      _owners[tokenId_] = to_;
      emit Transfer(address(0), to_, tokenId_);
    }
    /**
    * @dev Internal function returning the owner of the `tokenId_` token.
    * 
    * @param tokenId_ identifier of the NFT being referenced
    * 
    * @return address of the token owner
    */
    function _ownerOf(uint256 tokenId_) internal view returns (address) {
      return _owners[tokenId_];
    }
    /**
    * @dev Converts a `uint256` to its ASCII `string` decimal representation.
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
        for { let temp := value_ } 1 {} { // solhint-disable-line
          str := sub(str, 1)
          // Write the character to the pointer.
          // The ASCII index of the '0' character is 48.
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
    /**
    * @dev Internal functions that counts the NFTs tracked by this contract.
    * 
    * @return the number of NFTs in existence
    */
    function _totalSupply() internal view virtual returns (uint256) {
      return supplyMinted();
    }
    /**
    * @dev Transfers `tokenId_` from `from_` to `to_`.
    *
    * This internal function can be used to implement alternative mechanisms to perform 
    * token transfer, such as signature-based, or token burning.
    * 
    * @param from_ the current owner of the NFT
    * @param to_ the new owner
    * @param tokenId_ identifier of the NFT being referenced
    * 
    * Emits a {Transfer} event.
    */
    function _transfer(address from_, address to_, uint256 tokenId_) internal {
      unchecked {
        ++_balances[to_];
        --_balances[from_];
      }
      _owners[tokenId_] = to_;
      _approvals[tokenId_] = address(0);

      emit Transfer(from_, to_, tokenId_);
    }
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    /**
    * @notice Mints `qty_` tokens and transfers them to the caller.
    * 
    * @param qty_ : the amount of tokens to be minted
    * @param alloted_ : the maximum alloted for that user
    * @param whitelistType_ : identifies the whitelist used
    * @param proof_ : the signature to verify whitelist allocation
    * 
    * Requirements:
    * 
    * - Sale state must not be {PAUSED}.
    * - Caller must send enough ether to pay for `qty_` tokens at current sale state price.
    * - Caller must be allowed to mint `qty_` tokens during `whitelistType_` sale state.
    */
    function mint(uint256 qty_, uint256 alloted_, uint8 whitelistType_, Proof calldata proof_) public payable isNotState(PAUSED) {
      uint8 _currentState_ = getContractState();

      if (qty_ > MAX_BATCH) {
        revert NFT_MAX_BATCH(qty_, MAX_BATCH);
      }

      uint256 _remainingSupply_ = maxSupply - supplyMinted();
      if (qty_ > _remainingSupply_) {
        revert NFT_MAX_SUPPLY(qty_, _remainingSupply_);
      }

      uint256 _expected_ = qty_ * _salePrice[whitelistType_];
      if (_expected_ != msg.value) {
        revert ETHER_INCORRECT_PRICE(msg.value, _expected_);
      }

      _processWhitelist(msg.sender, _currentState_, whitelistType_, alloted_, qty_, proof_);

      uint256 _firstToken_ = _nextId;
      uint256 _nextStart_ = _firstToken_ + qty_;
      unchecked {
        _balances[msg.sender] += qty_;
        _nextId += qty_;
      }
      while (_firstToken_ < _nextStart_) {
        _mint(msg.sender, _firstToken_);
        unchecked {
          _firstToken_ ++;
        }
      }
    }

    // ***********
    // * IERC721 *
    // ***********
      /**
      * @notice Gives permission to `to_` to transfer the token number `tokenId_` on behalf of its owner.
      * The approval is cleared when the token is transferred.
      * 
      * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
      * 
      * @param to_ The new approved NFT controller
      * @param tokenId_ The NFT to approve
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - The caller must own the token or be an approved operator.
      * - Must emit an {Approval} event.
      */
      function approve(address to_, uint256 tokenId_) public override exists(tokenId_) onlyAllowedOperatorApproval(msg.sender) {
        address _tokenOwner_ = _ownerOf(tokenId_);
        if (to_ == _tokenOwner_) {
          revert IERC721_INVALID_APPROVAL(to_);
        }

        bool _isApproved_ = _isApprovedOrOwner(_tokenOwner_, msg.sender, tokenId_);
        if (! _isApproved_) {
          revert IERC721_CALLER_NOT_APPROVED(_tokenOwner_, msg.sender, tokenId_);
        }

        _approvals[tokenId_] = to_;
        emit Approval(_tokenOwner_, to_, tokenId_);
      }
      /**
      * @notice Transfers the token number `tokenId_` from `from_` to `to_`.
      * 
      * @param from_ The current owner of the NFT
      * @param to_ The new owner
      * @param tokenId_ identifier of the NFT being referenced
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - `from_` must be the token owner.
      * - The caller must own the token or be an approved operator.
      * - `to_` must not be the zero address.
      * - If `to_` is a contract, it must implement {IERC721Receiver-onERC721Received} with a return value of `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
      * - Must emit a {Transfer} event.
      */
      function safeTransferFrom(address from_, address to_, uint256 tokenId_) public override {
        safeTransferFrom(from_, to_, tokenId_, "");
      }
      /**
      * @notice Transfers the token number `tokenId_` from `from_` to `to_`.
      * 
      * @param from_ The current owner of the NFT
      * @param to_ The new owner
      * @param tokenId_ identifier of the NFT being referenced
      * @param data_ Additional data with no specified format, sent in call to `to_`
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - `from_` must be the token owner.
      * - The caller must own the token or be an approved operator.
      * - `to_` must not be the zero address.
      * - If `to_` is a contract, it must implement {IERC721Receiver-onERC721Received} with a return value of `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
      * - Must emit a {Transfer} event.
      */
      function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public override {
        transferFrom(from_, to_, tokenId_);
        if (! _checkOnERC721Received(from_, to_, tokenId_, data_)) {
          revert IERC721_NON_ERC721_RECEIVER(to_);
        }
      }
      /**
      * @notice Allows or disallows `operator_` to manage the caller's tokens on their behalf.
      * 
      * @param operator_ Address to add to the set of authorized operators
      * @param approved_ True if the operator is approved, false to revoke approval
      * 
      * Requirements:
      * 
      * - Must emit an {ApprovalForAll} event.
      */
      function setApprovalForAll(address operator_, bool approved_) public override onlyAllowedOperatorApproval(msg.sender) {
        address _account_ = msg.sender;
        if (operator_ == _account_) {
          revert IERC721_INVALID_APPROVAL(operator_);
        }

        _operatorApprovals[_account_][operator_] = approved_;
        emit ApprovalForAll(_account_, operator_, approved_);
      }
      /**
      * @notice Transfers the token number `tokenId_` from `from_` to `to_`.
      * 
      * @param from_ the current owner of the NFT
      * @param to_ the new owner
      * @param tokenId_ identifier of the NFT being referenced
      * 
      * Requirements:
      * 
      * - The token number `tokenId_` must exist.
      * - `from_` must be the token owner.
      * - The caller must own the token or be an approved operator.
      * - `to_` must not be the zero address.
      * - Must emit a {Transfer} event.
      */
      function transferFrom(address from_, address to_, uint256 tokenId_) public override onlyAllowedOperator(msg.sender) {
        if (to_ == address(0)) {
          revert IERC721_INVALID_TRANSFER();
        }

        address _tokenOwner_ = ownerOf(tokenId_);
        if (from_ != _tokenOwner_) {
          revert IERC721_INVALID_TRANSFER_FROM(_tokenOwner_, from_, tokenId_);
        }

        if (! _isApprovedOrOwner(_tokenOwner_, msg.sender, tokenId_)) {
          revert IERC721_CALLER_NOT_APPROVED(_tokenOwner_, msg.sender, tokenId_);
        }

        _transfer(_tokenOwner_, to_, tokenId_);
      }
    // ***********
  // **************************************

  // **************************************
  // *****       CONTRACT_OWNER       *****
  // **************************************
    /**
    * @notice Reduces the max supply.
    * 
    * @param newMaxSupply_ : the new max supply
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newMaxSupply_` must be lower than `maxSupply`.
    * - `newMaxSupply_` must be higher than `_nextId`.
    */
    function reduceSupply(uint256 newMaxSupply_) public onlyOwner {
      if (newMaxSupply_ > maxSupply || newMaxSupply_ < supplyMinted()) {
        revert NFT_INVALID_SUPPLY();
      }
      maxSupply = newMaxSupply_;
    }
    /**
    * @notice Updates the baseUri for the tokens.
    * 
    * @param newBaseUri_ : the new baseUri for the tokens
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setBaseUri(string memory newBaseUri_) public onlyOwner {
      _baseUri = newBaseUri_;
    }
    /**
    * @notice Updates the contract state.
    * 
    * @param newState_ : the new sale state
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newState_` must be a valid state.
    */
    function setContractState(uint8 newState_) external onlyOwner {
      if (newState_ > WAITLIST_SALE) {
        revert ContractState_INVALID_STATE(newState_);
      }
      _setContractState(newState_);
    }
    /**
    * @notice Updates the royalty recipient and rate.
    * 
    * @param newRoyaltyRecipient_ : the new recipient of the royalties
    * @param newRoyaltyRate_ : the new royalty rate
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newRoyaltyRate_` cannot be higher than 10,000.
    */
    function setRoyaltyInfo(address newRoyaltyRecipient_, uint256 newRoyaltyRate_) external onlyOwner {
      _setRoyaltyInfo(newRoyaltyRecipient_, newRoyaltyRate_);
    }
    /**
    * @notice Updates the royalty recipient and rate.
    * 
    * @param newMagmaPrice_ : the new magma price
    * @param newPrivatePrice_ : the new private price
    * @param newPublicPrice_ : the new public price
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setPrices(uint256 newMagmaPrice_, uint256 newPrivatePrice_, uint256 newPublicPrice_) external onlyOwner {
      _salePrice[MAGMA_SALE] = newMagmaPrice_;
      _salePrice[PRIVATE_SALE] = newPrivatePrice_;
      _salePrice[WAITLIST_SALE] = newPublicPrice_;
    }
    /**
    * @notice Updates the contract treasury.
    * 
    * @param newTreasury_ : the new trasury
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setTreasury(address newTreasury_) external onlyOwner {
      treasury = newTreasury_;
    }
    /**
    * @notice Updates the whitelist signer.
    * 
    * @param newAdminSigner_ : the new whitelist signer
    *  
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setWhitelist(address newAdminSigner_) external onlyOwner {
      _setWhitelist(newAdminSigner_);
    }
    /**
    * @notice Withdraws all the money stored in the contract and sends it to the treasury.
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `treasury` must be able to receive the funds.
    * - Contract must have a positive balance.
    */
    function withdraw() public onlyOwner {
      uint256 _balance_ = address(this).balance;
      if (_balance_ == 0) {
        revert ETHER_NO_BALANCE();
      }

      address _recipient_ = payable(treasury);
      // solhint-disable-next-line
      (bool _success_,) = _recipient_.call{ value: _balance_ }("");
      if (! _success_) {
        revert ETHER_TRANSFER_FAIL(_recipient_, _balance_);
      }
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @notice Returns the sale price during the specified state.
    * 
    * @param contractState_ : the state of the contract to check the price at
    * 
    * @return price : uint256 => the sale price at the specified state
    */
    function salePrice(uint8 contractState_) public virtual view returns (uint256 price) {
      return _salePrice[ contractState_ ];
    }
    /**
    * @notice Returns the total number of tokens minted
    * 
    * @return uint256 the number of tokens that have been minted so far
    */
    function supplyMinted() public view virtual returns (uint256) {
      return _nextId - 1;
    }

    // ***********
    // * IERC721 *
    // ***********
      /**
      * @notice Returns the number of tokens in `tokenOwner_`'s account.
      * 
      * @param tokenOwner_ address that owns tokens
      * 
      * @return the nomber of tokens owned by `tokenOwner_`
      */
      function balanceOf(address tokenOwner_) public view override returns (uint256) {
        if (tokenOwner_ == address(0)) {
          return 0;
        }

        return _balances[tokenOwner_];
      }
      /**
      * @notice Returns the address that has been specifically allowed to manage `tokenId_` on behalf of its owner.
      * 
      * @param tokenId_ the NFT that has been approved
      * 
      * @return the address allowed to manage `tokenId_`
      * 
      * Requirements:
      * 
      * - `tokenId_` must exist.
      * 
      * Note: See {Approve}
      */
      function getApproved(uint256 tokenId_) public view override exists(tokenId_) returns (address) {
        return _approvals[tokenId_];
      }
      /**
      * @notice Returns whether `operator_` is allowed to manage tokens on behalf of `tokenOwner_`.
      * 
      * @param tokenOwner_ address that owns tokens
      * @param operator_ address that tries to manage tokens
      * 
      * @return whether `operator_` is allowed to handle `tokenOwner`'s tokens
      * 
      * Note: See {setApprovalForAll}
      */
      function isApprovedForAll(address tokenOwner_, address operator_) public view override returns (bool) {
        return _operatorApprovals[tokenOwner_][operator_];
      }
      /**
      * @notice Returns the owner of the token number `tokenId_`.
      * 
      * @param tokenId_ the NFT to verify ownership of
      * 
      * @return the owner of token number `tokenId_`
      * 
      * Requirements:
      * 
      * - `tokenId_` must exist.
      */
      function ownerOf(uint256 tokenId_) public view override exists(tokenId_) returns (address) {
        return _ownerOf(tokenId_);
      }
    // ***********

    // *******************
    // * IERC721Metadata *
    // *******************
      /**
      * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
      * 
      * @param tokenId_ the NFT that has been approved
      * 
      * @return the URI of the token
      * 
      * Requirements:
      * 
      * - `tokenId_` must exist.
      */
      function tokenURI(uint256 tokenId_) public view override exists(tokenId_) returns (string memory) {
        return bytes(_baseUri).length > 0 ? string(abi.encodePacked(_baseUri, _toString(tokenId_))) : _toString(tokenId_);
      }
    // *******************

    // *********************
    // * IERC721Enumerable *
    // *********************
      /**
      * @notice Enumerate valid NFTs
      * @dev Throws if `index_` >= {totalSupply()}.
      * 
      * @param index_ the index requested
      * 
      * @return the identifier of the token at the specified index
      */
      function tokenByIndex(uint256 index_) public view virtual override returns (uint256) {
        if (index_ >= supplyMinted()) {
          revert IERC721Enumerable_INDEX_OUT_OF_BOUNDS(index_);
        }
        return index_ + 1;
      }
      /**
      * @notice Enumerate NFTs assigned to an owner
      * @dev Throws if `index_` >= {balanceOf(owner_)} or if `owner_` is the zero address, representing invalid NFTs.
      * 
      * @param tokenOwner_ the address requested
      * @param index_ the index requested
      * 
      * @return the identifier of the token at the specified index
      */
      function tokenOfOwnerByIndex(address tokenOwner_, uint256 index_) public view virtual override returns (uint256) {
        if (index_ >= balanceOf(tokenOwner_)) {
          revert IERC721Enumerable_OWNER_INDEX_OUT_OF_BOUNDS(tokenOwner_, index_);
        }

        uint256 _count_ = 0;
        uint256 _nextId_ = supplyMinted();
        for (uint256 i = 1; i < _nextId_; i++) {
          if (_exists(i) && tokenOwner_ == _ownerOf(i)) {
            if (index_ == _count_) {
              return i;
            }
            _count_++;
          }
        }
      }
      /**
      * @notice Count NFTs tracked by this contract
      * 
      * @return the number of NFTs in existence
      */
      function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply();
      }
    // *********************

    // ***********
    // * IERC173 *
    // ***********
      /**
      * @dev Returns the address of the current contract owner.
      * 
      * @return address : the current contract owner
      */
      function owner() public view override(ERC173, UpdatableOperatorFilterer) returns (address) {
        return ERC173.owner();
      }
    // ***********

	  // ***********
	  // * IERC165 *
	  // ***********
	    /**
	    * @notice Query if a contract implements an interface.
	    * @dev see https://eips.ethereum.org/EIPS/eip-165
	    * 
	    * @param interfaceId_ : the interface identifier, as specified in ERC-165
	    * 
	    * @return bool : true if the contract implements the specified interface, false otherwise
	    * 
	    * Requirements:
	    * 
	    * - This function must use less than 30,000 gas.
	    */
	    function supportsInterface(bytes4 interfaceId_) public pure override returns (bool) {
	      return 
	        interfaceId_ == type(IERC721).interfaceId ||
	        interfaceId_ == type(IERC721Enumerable).interfaceId ||
	        interfaceId_ == type(IERC721Metadata).interfaceId ||
	        interfaceId_ == type(IERC173).interfaceId ||
	        interfaceId_ == type(IERC165).interfaceId ||
	        interfaceId_ == type(IERC2981).interfaceId;
	    }
	  // ***********
  // **************************************
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

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  UpdatableOperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry. This contract allows the Owner to update the
 *         OperatorFilterRegistry address via updateOperatorFilterRegistryAddress, including to the zero address,
 *         which will bypass registry checks.
 *         Note that OpenSea will still disable creator earnings enforcement if filtered operators begin fulfilling orders
 *         on-chain, eg, if the registry is revoked or bypassed.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract UpdatableOperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);
    /// @dev Emitted when someone other than the owner is trying to call an only owner function.
    error OnlyOwner();

    event OperatorFilterRegistryAddressUpdated(address newRegistry);

    IOperatorFilterRegistry public operatorFilterRegistry;

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address _registry, address subscriptionOrRegistrantToCopy, bool subscribe) {
        IOperatorFilterRegistry registry = IOperatorFilterRegistry(_registry);
        operatorFilterRegistry = registry;
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(registry).code.length > 0) {
            if (subscribe) {
                registry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    registry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    registry.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if the operator is allowed.
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
     * @dev A helper function to check if the operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. OnlyOwner.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public virtual {
        if (msg.sender != owner()) {
            revert OnlyOwner();
        }
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
        emit OperatorFilterRegistryAddressUpdated(newRegistry);
    }

    /**
     * @dev Assume the contract has an owner, but leave specific Ownable implementation up to inheriting contract.
     */
    function owner() public view virtual returns (address);

    /**
     * @dev A helper function to check if the operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}