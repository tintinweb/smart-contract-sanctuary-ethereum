/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

// Sources flattened with hardhat v2.12.3 https://hardhat.org

// File @lambdalf-dev/ethereum-contracts/contracts/interfaces/[email protected]

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


// File @lambdalf-dev/ethereum-contracts/contracts/interfaces/[email protected]

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


// File @lambdalf-dev/ethereum-contracts/contracts/interfaces/[email protected]

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

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;
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


// File @lambdalf-dev/ethereum-contracts/contracts/utils/[email protected]

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


// File @lambdalf-dev/ethereum-contracts/contracts/interfaces/[email protected]

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


// File @lambdalf-dev/ethereum-contracts/contracts/interfaces/[email protected]

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


// File @lambdalf-dev/ethereum-contracts/contracts/utils/[email protected]

/**
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;
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


// File contracts/AsteriaPurchase.sol

/**
* Team: Asteria Labs
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;
interface IAsteriaPass {
	function claimFor(address account_) external;
}

contract AsteriaPurchase is IEtherErrors, INFTSupplyErrors, ERC173, ContractState, Whitelist_ECDSA {
  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
		uint8 public constant WHITELIST = 1;
		uint8 public constant WAITLIST = 2;
		uint8 public constant CLAIM = 3;
		uint256 public constant MAX_AMOUNT = 1;
  // **************************************

  // **************************************
  // *****     STORAGE VARIABLES      *****
  // **************************************
		uint256 public supplyPurchased;
		uint256 public maxSupply; // 333 - 5 reserve
		uint256 public salePrice = 3330000000000000000; // 3.33 ETH
		uint256 public depositPrice = 500000000000000000; // 0.5 ETH
  	IAsteriaPass public asteriaPass;
		mapping(address => uint256) public depositedAmount;
	  address payable private _asteria;
	  address payable private _stable;
		address[] private _purchasers;
  // **************************************

  // **************************************
  // *****           ERROR            *****
  // **************************************
		/**
		* @dev Thrown when user with no deposit tries to claim a refund or complete a purchase.
		* 
		* @param account the address trying to claim a refund or completing a purchase
		*/
		error AP_NO_DEPOSIT(address account);
		/**
		* @dev Thrown when user tries to claim a pass while pass contract is not set.
		*/
		error AP_PASS_NOT_SET();
		/**
		* @dev Thrown when user who successfully purchased a pass tries to claim a refund or complete a purchase.
		* 
		* @param account the address trying to claim a refund or completing a purchase
		*/
		error AP_PURCHASED(address account);
		/**
		* @dev Thrown when validating purchase for an account with no purchase.
		* 
		* @param account the address trying to claim a refund or completing a purchase
		*/
		error AP_NOT_PURCHASED(address account);
  // **************************************

  // **************************************
  // *****           EVENT            *****
  // **************************************
		/**
		* Emitted when a user deposits money for presale
		* 
		* @param account the address purchasing a pass
		* @param amount the amount deposited
		*/
		event Deposited(address indexed account, uint256 indexed amount);
		/**
		* Emitted when a user purchases a pass
		* 
		* @param account the address purchasing a pass
		*/
		event Purchased(address indexed account);
		/**
		* Emitted when a user gets refunded their presale deposit
		* 
		* @param account the address purchasing a pass
		* @param amount the amount refunded
		*/
		event Refunded(address indexed account, uint256 indexed amount);
  // **************************************

	constructor(address asteria_, address stable_, address signer_, uint256 maxSupply_) {
    _asteria = payable(asteria_);
    _stable = payable(stable_);
    maxSupply = maxSupply_;
    _setWhitelist(signer_);
    _setOwner(msg.sender);
	}

	// **************************************
	// *****          MODIFIER          *****
	// **************************************
		/**
		* @dev Ensures the supply is not depleted.
		*/
		modifier supplyNotDepleted() {
			if (maxSupply <= supplyPurchased) {
				revert NFT_MAX_SUPPLY(MAX_AMOUNT, maxSupply - supplyPurchased);
			}
			_;
		}
		/**
		* @dev Ensures the user hasn't already purchased a pass.
		*/
		modifier notPurchased(address account_) {
			if (hasPurchased(account_)) {
				revert AP_PURCHASED(account_);
			}
			_;
		}
		/**
		* @dev Ensures the contract is in WHITELIST or WAITLIST phase.
		*/
		modifier isWhitelistOrWaitlist() {
			uint8 _contractState_ = getContractState();
      if (_contractState_ != WHITELIST && _contractState_ != WAITLIST) {
        revert ContractState_INCORRECT_STATE(_contractState_);
      }
			_;
		}
	// **************************************

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function processing an ether payment.
		* 
		* @param recipient_ the address receiving the payment
		* @param amount_ the amount sent
		*/
		function _processEthPayment(address payable recipient_, uint256 amount_) internal {
      // solhint-disable-next-line
      (bool _success_,) = recipient_.call{ value: amount_ }("");
      if (! _success_) {
        revert ETHER_TRANSFER_FAIL(recipient_, amount_);
      }
		}
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @notice Claims a purchased Pass.
		* 
		* Requirements:
		* 
		* - Contract state must be CLAIM
		* - Caller must have purchased a pass
		*/
		function claimPass() external isState(CLAIM) {
			if (address(asteriaPass) == address(0)) {
				revert AP_PASS_NOT_SET();
			}
			if (depositedAmount[msg.sender] < salePrice) {
				revert AP_NOT_PURCHASED(msg.sender);
			}
			unchecked {
				depositedAmount[msg.sender] -= salePrice;
			}
			asteriaPass.claimFor(msg.sender);
		}
		/**
		* @notice Claims a refund of a waitlist deposit.
		* 
		* Requirements:
		* 
		* - Contract state must be CLAIM
		* - Caller must have deposited some preorder funds
		* - Caller must have deposited less than the sale price
		* - Caller must not have already purchased a pass
		* - Caller must be able to receive ETH
		* - Emits a {Refunded} event
		*/
		function claimRefund() external isState(CLAIM) notPurchased(msg.sender) {
			uint256 value = depositedAmount[msg.sender];
			if (value == 0) {
				revert AP_NO_DEPOSIT(msg.sender);
			}
			depositedAmount[msg.sender] = 0;
			_processEthPayment(payable(msg.sender), value);
			emit Refunded(msg.sender, value);
		}
		/**
		* @notice Completes a waitlist purchase.
		* 
		* Requirements:
		* 
		* - Contract state must be WAITLIST
		* - Supply most not be depleted
		* - Caller must have deposited some preorder funds
		* - Caller must have deposited less than the sale price
		* - Caller must not have already purchased a pass
		* - Caller must send enough ether to complete the purchase
		* - Emits a {Purchased} event
		*/
		function completePurchase() external payable isState(WAITLIST) supplyNotDepleted notPurchased(msg.sender) {
			if (depositedAmount[ msg.sender ] == 0) {
				revert AP_NO_DEPOSIT(msg.sender);
			}
			uint256 _expected_;
			unchecked {
				_expected_ = salePrice - depositedAmount[ msg.sender ];
			}
			if (msg.value != _expected_) {
				revert ETHER_INCORRECT_PRICE(msg.value, _expected_);
			}
			unchecked {
				++supplyPurchased;
				depositedAmount[ msg.sender ] += msg.value;
			}
			_purchasers.push(msg.sender);
			emit Purchased(msg.sender);
			uint256 _share_ = salePrice / 2;
			_processEthPayment(_stable, _share_);
			_processEthPayment(_asteria, _share_);
		}
		/**
		* @notice Purchases a Pass
		* 
		* @param proof_ Signature confirming that the caller is allowed to purchase a token
		* 
		* Requirements:
		* 
		* - Contract state must not be PAUSED
		* - Supply most not be depleted
		* - Caller must be on the WHITELIST
		* - Caller must not have already purchased a pass
		* - Caller must send ether to cover the sale price
		* - Emits a {Purchased} event
		*/
		function purchasePresale(Proof calldata proof_)
		external
		payable
		isWhitelistOrWaitlist()
		supplyNotDepleted
		notPurchased(msg.sender)
		isWhitelisted(msg.sender, WHITELIST, MAX_AMOUNT, proof_, MAX_AMOUNT) {
			if (msg.value != salePrice) {
				revert ETHER_INCORRECT_PRICE(msg.value, salePrice);
			}
			unchecked {
				++supplyPurchased;
				depositedAmount[ msg.sender ] += msg.value;
			}
			_purchasers.push(msg.sender);
			emit Purchased(msg.sender);
			uint256 _share_ = salePrice / 2;
			_processEthPayment(_stable, _share_);
			_processEthPayment(_asteria, _share_);
			// Refund extra deposit if user has more than the purchase price deposited
			if (depositedAmount[msg.sender] > salePrice) {
				_processEthPayment(payable(msg.sender), depositedAmount[msg.sender] - salePrice);
			}
		}
		/**
		* @notice Deposits a portion of the sale price
		* 
		* @param proof_ Signature confirming that the caller is allowed to preorder a token
		* 
		* Requirements:
		* 
		* - Contract state must not be PAUSED
		* - Supply most not be depleted
		* - Caller must be on the WAITLIST
		* - Caller must not have already purchased a pass
		* - Caller must send ether to cover the deposit price
		* - Emits a {Deposited} event
		*/
		function preOrder(Proof calldata proof_)
		external
		payable
		isState(WHITELIST)
		supplyNotDepleted
		notPurchased(msg.sender)
		isWhitelisted(msg.sender, WAITLIST, MAX_AMOUNT, proof_, MAX_AMOUNT) {
			if (msg.value != depositPrice) {
				revert ETHER_INCORRECT_PRICE(msg.value, depositPrice);
			}
			unchecked {
				depositedAmount[ msg.sender ] += msg.value;
			}
			_consumeWhitelist(msg.sender, WAITLIST, MAX_AMOUNT);
			emit Deposited(msg.sender, msg.value);
		}
	// **************************************

	// **************************************
	// *****       CONTRACT OWNER       *****
	// **************************************
		/**
		* @notice Claims a purchased pass for `to_`.
		* Note: This function allows the team to mint a pass that hasn't been claimed during the claim period
		* 	The recipient may be a different address than the purchaser, for example,
		* 	if the purchasing wallet has been compromised
		* 
		* @param for_ address that purchased the pass
		* @param to_ address receiving the pass
		* 
    * Requirements:
		* 
    * - Caller must be the contract owner.
		* - `for_` must have purchased a pass
		*/
		function airdropClaim(address for_, address to_) external onlyOwner {
			if (address(asteriaPass) == address(0)) {
				revert AP_PASS_NOT_SET();
			}
			if (depositedAmount[for_] < salePrice) {
				revert AP_NOT_PURCHASED(for_);
			}
			unchecked {
				depositedAmount[for_] -= salePrice;
			}
			asteriaPass.claimFor(to_);
		}
    /**
    * @notice Sets the Asteria Pass contract address.
    * 
    * @param contractAddress_ the Asteria Pass contract address
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
		function setAsteriaPass(address contractAddress_) external onlyOwner {
			asteriaPass = IAsteriaPass(contractAddress_);
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
      if (newState_ > CLAIM) {
        revert ContractState_INVALID_STATE(newState_);
      }
      _setContractState(newState_);
    }
    /**
    * @notice Updates the royalty recipient and rate.
    * 
    * @param newSalePrice_ the new private price
    * @param newDepositPrice_ the new public price
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function setPrices(uint256 newSalePrice_, uint256 newDepositPrice_) external onlyOwner {
      salePrice = newSalePrice_;
      depositPrice = newDepositPrice_;
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
		* @notice Updates Asteria and Stable addresses
		* 
		* @param newAsteria_ The new Asteria address
		* @param newStable_  The new Stable address
    *  
    * Requirements:
    * 
    * - Caller must be the contract owner.
		*/
		function updateAddresses(address newAsteria_, address newStable_) external onlyOwner {
			_asteria = payable(newAsteria_);
			_stable = payable(newStable_);
		}
    /**
    * @notice Withdraws all the money stored in the contract and splits it between `_asteria` and `_stable`.
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner
    * - Contract state must be PAUSED
    * - Contract must have a positive balance
    * - `_asteria` must be able to receive funds
    * - `_stable` must be able to receive funds
    */
		function withdraw() public onlyOwner isState(PAUSED) {
			uint256 _amount_ = address(this).balance;
			if (_amount_ == 0) {
				revert ETHER_NO_BALANCE();
			}
			uint256 _share_ = _amount_ / 2;
			_processEthPayment(_stable, _share_);
			_processEthPayment(_asteria, _share_);
		}
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		/**
		* @notice Returns the list of addresses that purchased a pass.
		* 
		* @return the list of addresses that purchased a pass
		*/
		function getPurchasers() external view returns (address[] memory) {
			return _purchasers;
		}
		/**
		* @notice Rturns whether or not a given address has purchased a pass.
		* 
		* @param account_ the address to check
		* 
		* @return true if `account_` has purchased a pass
		*/
		function hasPurchased(address account_) public view returns (bool) {
			return depositedAmount[account_] >= salePrice;
		}
	// **************************************
}