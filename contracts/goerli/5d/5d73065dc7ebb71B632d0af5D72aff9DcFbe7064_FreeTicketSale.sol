/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

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

// File @lambdalf-dev/ethereum-contracts/contracts/utils/[email protected]

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

// File @lambdalf-dev/ethereum-contracts/contracts/interfaces/[email protected]

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

// File @lambdalf-dev/ethereum-contracts/contracts/interfaces/[email protected]

interface IERC173Errors {
  /**
  * @dev Thrown when `operator` is not the contract owner.
  *
  * @param operator address trying to use a function reserved to contract owner without authorization
  */
  error IERC173_NOT_OWNER(address operator);
}

// File @lambdalf-dev/ethereum-contracts/contracts/utils/[email protected]

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

// File @lambdalf-dev/ethereum-contracts/contracts/interfaces/[email protected]

/**
* @title ERC-20 Multi Token Standard
* @dev See https://eips.ethereum.org/EIPS/eip-20
*/
interface IERC20 /* is IERC165 */ {
  /**
  * @dev Emitted when the allowance of a `spender` for an `owner` is set by a call to {approve}.
  *   `value` is the new allowance.
  *
  * @param owner address that owns the tokens
  * @param spender address allowed to spend the tokens
  * @param value the amount of tokens allowed to be spent
  */
  event Approval(address indexed owner, address indexed spender, uint256 value);
  /**
  * @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
  *   Note that `value` may be zero.
  *
  * @param from address tokens are being transferred from
  * @param to address tokens are being transferred to
  * @param value amount of tokens being transferred
  */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
  * @dev Sets `amount_` as the allowance of `spender_` over the caller's tokens.
  *
  * Returns a boolean value indicating whether the operation succeeded.
  *
  * IMPORTANT: Beware that changing an allowance with this method brings the risk
  *   that someone may use both the old and the new allowance by unfortunate transaction ordering.
  *   One possible solution to mitigate this race condition is to first reduce the spender"s allowance to 0,
  *   and set the desired value afterwards:
  *   https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
  *
  * Emits an {Approval} event.
  */
  function approve(address spender_, uint256 amount_) external returns (bool);
  /**
  * @dev Moves `amount_` tokens from the caller's account to `recipient_`.
  *
  * Returns a boolean value indicating whether the operation succeeded.
  *
  * Emits a {Transfer} event.
  */
  function transfer(address recipient_, uint256 amount_) external returns (bool);
  /**
  * @dev Moves `amount_` tokens from `sender_` to `recipient_` using the allowance mechanism.
  *   `amount_` is then deducted from the caller's allowance.
  *
  * Returns a boolean value indicating whether the operation succeeded.
  *
  * Emits a {Transfer} event.
  */
  function transferFrom(
    address sender_,
    address recipient_,
    uint256 amount_
  ) external returns (bool);

  /**
  * @dev Returns the remaining number of tokens that `spender_` will be allowed to spend on behalf of `owner_`
  *   through {transferFrom}. This is zero by default.
  *
  * This value changes when {approve} or {transferFrom} are called.
  */
  function allowance(address owner_, address spender_) external view returns (uint256);
  /**
  * @dev Returns the amount of tokens owned by `account_`.
  */
  function balanceOf(address account_) external view returns (uint256);
  /**
  * @dev Returns the amount of tokens in existence.
  */
  function totalSupply() external view returns (uint256);
}

// File @lambdalf-dev/ethereum-contracts/contracts/interfaces/[email protected]

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

// File @lambdalf-dev/ethereum-contracts/contracts/interfaces/[email protected]

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

// File contracts/FreeTicketSale.sol

interface IDexa {
  function mintTo(uint256 id_, uint256 qty_, address recipient_) external;
  function balanceOf(address owner_, uint256 id_) external view returns (uint256);
}

contract FreeTicketSale is IEtherErrors, INFTSupplyErrors, ERC173, ContractState {
  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
    uint8 public constant PUBLIC_SALE = 1;
  // **************************************

  // **************************************
  // *****     STORAGE VARIABLES      *****
  // **************************************
    IDexa public dexa;
    mapping(uint256 => uint256) public maxSupplies;
    mapping(uint256 => uint256) public mintedSupplies;
  // **************************************

  constructor(address dexaAddress_) {
    dexa = IDexa(dexaAddress_);
        _setOwner(msg.sender);
  }

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    /**
    * @dev Mints `qty_` tickets.
    *
    * @param id_ the identifier of the series
    * @param qty_ the number of tickets purchased
    *
    * Requirements:
    *
    * - Contract state must be {PUBLIC_SALE}
    */
    function claim(uint256 id_, uint256 qty_) external isState(PUBLIC_SALE) {
      uint256 _remainingSupply_;
      unchecked {
        _remainingSupply_ = maxSupplies[id_] - mintedSupplies[id_];
      }
      if (qty_ > _remainingSupply_) {
        revert NFT_MAX_SUPPLY(qty_, _remainingSupply_);
      }
      unchecked {
        mintedSupplies[id_] += qty_;
      }
      dexa.mintTo(id_, qty_, msg.sender);
    }
  // **************************************

  // **************************************
  // *****       CONTRACT OWNER       *****
  // **************************************
    /**
    * @dev Updates the max supply for the Standard cover
    *
    * @param id_ the identifier of the series
    * @param newMaxSupply_ the new max supply
    *
    * Requirements:
    *
    * - Caller must be the contract owner.
    */
    function updateSupply(uint256 id_, uint256 newMaxSupply_) external onlyOwner {
      maxSupplies[id_] = newMaxSupply_;
    }
    /**
    * @dev Updates the contract state.
    *
    * @param newState_ the new sale state
    *
    * Requirements:
    *
    * - Caller must be the contract owner.
    * - `newState_` must be a valid state.
    */
    function setContractState(uint8 newState_) external onlyOwner {
      if (newState_ > PUBLIC_SALE) {
        revert ContractState_INVALID_STATE(newState_);
      }
      _setContractState(newState_);
    }
    /**
    * @dev Sets the Cover contract address.
    *
    * @param contractAddress_ the Cover contract address
    *
    * Requirements:
    *
    * - Caller must be the contract owner.
    */
    function setDexa(address contractAddress_) external onlyOwner {
      dexa = IDexa(contractAddress_);
    }
  // **************************************
}