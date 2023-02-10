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

import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/INFTSupplyErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC165.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC173.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC2981.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ContractState.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/Whitelist_ECDSA.sol";

interface ITeleporter {
  function burn(uint256 tokenId_) external;
  function claimFor(uint256 qty_, address account_) external;
  function restore(uint256 tokenId_, address to_) external;
  function ownerOf(uint256 tokenId_) external view returns (address);
  function totalSupply() external view returns (uint256);
}

contract TeleporterDelegate is INFTSupplyErrors, IERC165, ERC173, ERC2981, ContractState, Whitelist_ECDSA {
  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
    uint256 public constant MAX_SUPPLY = 4000;
    uint8 public constant SNAPSHOT_CLAIM = 1;
    uint8 public constant LLAMA_CLAIM = 2;
    uint8 public constant ACTIVE = 3;
  // **************************************

  // **************************************
  // *****     STORAGE VARIABLES      *****
  // **************************************
    ITeleporter public lltp;
    ITeleporter public blltp;
  // **************************************

  // **************************************
  // *****           ERROR            *****
  // **************************************
    /**
    * @dev Thrown when user tries to use a Teleporter they don't own.
    */
    error TP_NOT_OWNED();
    /**
    * @dev Thrown when trying to interact with the Teleporter contract while it's not set.
    */
    error TP_NOT_SET();
  // **************************************

  constructor(address signerWallet_, address royaltyRecipient_, uint256 royaltyRate_) {
    _setOwner(msg.sender);
    _setWhitelist(signerWallet_);
    _setRoyaltyInfo(royaltyRecipient_, royaltyRate_);
  }

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
    /**
    * @dev Ensures the Teleporter contracts are set.
    */
    modifier tpAreSet() {
      if (address(lltp) == address(0) || address(blltp) == address(0)) {
        revert TP_NOT_SET();
      }
      _;
    }
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    /**
    * @notice Claims a Teleporter and transfers it to the caller.
    * 
    * @param proof_ the signature to verify whitelist allocation
    * 
    * Requirements:
    * 
    * - Sale state must be {LLAMA_CLAIM}
    * - Caller must be whitelisted
    */
    function llamaClaim(Proof calldata proof_)
    public
    tpAreSet
    isState(LLAMA_CLAIM)
    isWhitelisted(msg.sender, LLAMA_CLAIM, 1, proof_, 1) {
      uint256 _remainingSupply_ = MAX_SUPPLY - totalSupply();
      if (1 > _remainingSupply_) {
        revert NFT_MAX_SUPPLY(1, _remainingSupply_);
      }
      lltp.claimFor(1, msg.sender);
      _consumeWhitelist(msg.sender, LLAMA_CLAIM, 1);
    }
    /**
    * @notice Claims `qty_` Teleporters and transfers them to the caller.
    * 
    * @param qty_ the amount of tokens to be minted
    * @param alloted_ the maximum alloted for that user
    * @param proof_ the signature to verify whitelist allocation
    * 
    * Requirements:
    * 
    * - Sale state must be {SNAPSHOT_CLAIM}
    * - Caller must be whitelisted
    */
    function snapshotClaim(uint256 qty_, uint256 alloted_, Proof calldata proof_)
    public
    tpAreSet
    isState(SNAPSHOT_CLAIM)
    isWhitelisted(msg.sender, SNAPSHOT_CLAIM, alloted_, proof_, qty_) {
      if (qty_ == 0) {
        revert NFT_INVALID_QTY();
      }
      uint256 _remainingSupply_ = MAX_SUPPLY - totalSupply();
      if (qty_ > _remainingSupply_) {
        revert NFT_MAX_SUPPLY(qty_, _remainingSupply_);
      }
      lltp.claimFor(qty_, msg.sender);
      _consumeWhitelist(msg.sender, SNAPSHOT_CLAIM, qty_);
    }
    /**
    * @notice Uses several Teleporters at once.
    *
    * Requirements:
    *
    * - Each Teleporter must exist
    * - The caller must own each Teleporter
    */
    function massTeleport(uint256[] calldata tokenIds_) public tpAreSet isState(ACTIVE) {
      uint256 _index_ = tokenIds_.length;
      while (_index_ > 0) {
        unchecked {
          --_index_;
        }
        uint256 _tokenId_ = tokenIds_[_index_];
        address _tokenOwner_ = lltp.ownerOf(_tokenId_);
        if (_tokenOwner_ != msg.sender) {
          revert TP_NOT_OWNED();
        }
        lltp.burn(_tokenId_);
        blltp.restore(_tokenId_, _tokenOwner_);
      }
    }
    /**
    * @notice Repairs `tokenId_` and transfers it to `to_`.
    * 
    * @param tokenId_ the token to repair
    * @param proof_ the signature to verify whitelist allocation
    * 
    * Requirements:
    * 
    * - `tokenId_` must have been burned
    * - The caller must be whitelisted to repair `tokenId_`
    */
    function repair(uint256 tokenId_, Proof calldata proof_) public tpAreSet isState(ACTIVE) {
      checkWhitelistAllowance(msg.sender, ACTIVE, tokenId_, proof_);
      address _tokenOwner_ = blltp.ownerOf(tokenId_);
      if (_tokenOwner_ != msg.sender) {
        revert TP_NOT_OWNED();
      }
      blltp.burn(tokenId_);
      lltp.restore(tokenId_, msg.sender);
    }
    /**
    * @dev Burns `tokenId_`.
    *
    * Requirements:
    *
    * - `tokenId_` must exist
    * - The caller must own `tokenId_` or be an approved operator
    */
    function teleport(uint256 tokenId_) public tpAreSet isState(ACTIVE) {
      address _tokenOwner_ = lltp.ownerOf(tokenId_);
      if (_tokenOwner_ != msg.sender) {
        revert TP_NOT_OWNED();
      }
      lltp.burn(tokenId_);
      blltp.restore(tokenId_, _tokenOwner_);
    }
  // **************************************

  // **************************************
  // *****       CONTRACT_OWNER       *****
  // **************************************
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
      if (newState_ > ACTIVE) {
        revert ContractState_INVALID_STATE(newState_);
      }
      _setContractState(newState_);
    }
    /**
    * @notice Updates the royalty recipient and rate.
    * 
    * @param newRoyaltyRecipient_ the new recipient of the royalties
    * @param newRoyaltyRate_ the new royalty rate
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
    * @notice Sets the token contracts.
    * 
    * @param newTP_ the new teleporter contract
    * @param newBTP_ the new broken teleporter contract
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setTokens(address newTP_, address newBTP_) external onlyOwner {
      lltp = ITeleporter(newTP_);
      blltp = ITeleporter(newBTP_);
    }
    /**
    * @notice Updates the whitelist signer.
    * 
    * @param newAdminSigner_ the new whitelist signer
    *  
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setWhitelist(address newAdminSigner_) external onlyOwner {
      _setWhitelist(newAdminSigner_);
    }
  // **************************************

  // **************************************
  // *****            VIEW            *****
  // **************************************
    /**
    * @notice Count NFTs tracked by this contract
    * 
    * @return the number of NFTs in existence
    */
    function totalSupply() public view returns (uint256) {
      uint256 lltpSupply = address(lltp) == address(0) ? 0 : lltp.totalSupply();
      uint256 blltpSupply = address(blltp) == address(0) ? 0 : blltp.totalSupply();
      return lltpSupply + blltpSupply;
    }

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
      function supportsInterface(bytes4 interfaceId_) public view override returns (bool) {
        return 
          interfaceId_ == type(IERC165).interfaceId ||
          interfaceId_ == type(IERC173).interfaceId ||
          interfaceId_ == type(IERC2981).interfaceId;
      }
    // ***********
  // **************************************
}