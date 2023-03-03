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
* Team: Asteria Labs
* Author: Lambdalf the White
*/

pragma solidity 0.8.17;

import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IEtherErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/INFTSupplyErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC173.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ContractState.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/Whitelist_ECDSA.sol";

interface IAsteriaPass {
  function claimFor(address account_, uint256 tokenId_) external;
}

contract AsteriaAuction is IEtherErrors, INFTSupplyErrors, ERC173, ContractState, Whitelist_ECDSA {
  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
  	uint8 public constant AUCTION = 1;
  	uint8 public constant PRESALE = 2;
  	uint8 public constant REFUND = 3;
  	uint8 public constant WHITELIST = 4;
    uint256 public constant MAX_AMOUNT = 1;
    uint256 public constant DEPOSIT_PRICE = 500000000000000000; // 0.5 ETH
    uint256 immutable MAX_SUPPLY;
    uint256 private constant _RESERVE = 5;
  // **************************************

  // **************************************
  // *****     STORAGE VARIABLES      *****
  // **************************************
    mapping (address => uint256) public depositedAmount;
    mapping (address => bool) public hasPurchased;
    IAsteriaPass public asteriaPass;
    uint256 public salePrice = 3330000000000000000;
    address payable private _asteria;
    address payable private _stable;
    uint256 private _nextWaitlist;
    uint256 private _nextPurchase = 1;
    mapping (uint256 => address) private _waitlist;
    mapping (uint256 => address) private _purchasers;
  // **************************************

  // **************************************
  // *****           ERROR            *****
  // **************************************
    /**
    * @dev Thrown when user who already deposited tries to make a new deposit.
    * 
    * @param account the address trying to make a deposit
    */
    error AA_ALREADY_DEPOSITED(address account);
    /**
    * @dev Thrown when user who already purchased a pass tries to claim a refund or complete a purchase.
    * 
    * @param account the address trying to claim a refund or completing a purchase
    */
    error AA_ALREADY_PURCHASED(address account);
    /**
    * @dev Thrown when new sale price is lower than {DEPOSIT_PRICE}
    */
    error AA_INVALID_PRICE();
    /**
    * @dev Thrown when trying to airdrop tokens when none are due.
    */
    error AA_NO_AIRDROP_DUE();
    /**
    * @dev Thrown when user with no deposit tries to claim a refund or complete a purchase.
    * 
    * @param account the address trying to claim a refund or completing a purchase
    */
    error AA_NO_DEPOSIT(address account);
    /**
    * @dev Thrown when trying to airdrop tokens while pass contract is not set.
    */
    error AA_PASS_NOT_SET();
    /**
    * @dev Thrown when trying to airdrop waitlist before finishing to airdrop purchases.
    */
    error AA_PURCHASES_PENDING();
    /**
    * @dev Thrown when trying to join the waitlist when it's full
    */
    error AA_WAITLIST_FULL();
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
    MAX_SUPPLY = maxSupply_;
    _nextWaitlist = maxSupply_ + 1;
    _setWhitelist(signer_);
    _setOwner(msg.sender);
  }

  // **************************************
  // *****          MODIFIER          *****
  // **************************************
  	/**
  	* @dev Ensures that the caller has not already deposited.
  	*/
  	modifier hasNotDeposited() {
    	if (depositedAmount[msg.sender] != 0) {
    		revert AA_ALREADY_DEPOSITED(msg.sender);
    	}
    	_;
  	}
  	/**
  	* @dev Ensures that the caller has not already purchased a pass.
  	*/
  	modifier hasNotPurchased() {
    	if (hasPurchased[msg.sender]) {
    		revert AA_ALREADY_PURCHASED(msg.sender);
    	}
    	_;
  	}
  	/**
  	* @dev Ensures that the pass contract is set.
  	*/
  	modifier passIsSet() {
  		if (address(asteriaPass) == address(0)) {
  			revert AA_PASS_NOT_SET();
  		}
  		_;
  	}
  	/**
  	* @dev Ensures that the correct amount of ETH has been sent to cover a purchase or deposit.
  	* 
  	* @param totalPrice_ the amount of Eth required for this payment
  	*/
  	modifier validateEthAmount(uint256 totalPrice_) {
  		uint256 _expected_ = depositedAmount[msg.sender] > 0 ?
  			totalPrice_ - depositedAmount[msg.sender] : totalPrice_;
    	if (msg.value != _expected_) {
    		revert ETHER_INCORRECT_PRICE(msg.value, _expected_);
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
  	/**
  	* @dev Internal function processing a purchase.
  	* 
    * @param account_ the address purchasing a token
  	*/
  	function _processPurchase(address account_) internal {
  		if (_nextPurchase > MAX_SUPPLY) {
  			revert NFT_MAX_SUPPLY(1, 0);
  		}
  		hasPurchased[account_] = true;
    	_purchasers[_nextPurchase] = account_;
    	unchecked {
    		++_nextPurchase;
    	}
    	emit Purchased(account_);
      uint256 _share_ = salePrice / 2;
      _processEthPayment(_stable, _share_);
      _processEthPayment(_asteria, _share_);
  	}
  // **************************************

  // **************************************
  // *****           PUBLIC           *****
  // **************************************
    /**
    * @notice Claims a refund of a deposit.
    * 
    * @param proof_ Signature confirming that the caller is eligible for a refund
    * 
    * Requirements:
    * 
    * - Contract state must be {REFUND}.
    * - Caller must have deposited some preorder funds.
    * - Caller must be eligible for a refund.
    * - Caller must be able to receive ETH.
    * - Emits a {Refunded} event.
    */
    function claimRefund(Proof calldata proof_) external isState(REFUND) {
    	uint256 _balance_ = depositedAmount[msg.sender];
      if (_balance_ == 0) {
      	revert AA_NO_DEPOSIT(msg.sender);
      }
      checkWhitelistAllowance(msg.sender, REFUND, MAX_AMOUNT, proof_);
      depositedAmount[msg.sender] = 0;
      emit Refunded(msg.sender, _balance_);
      _processEthPayment(payable(msg.sender), _balance_);
    }
    /**
    * @notice Completes a winning bid purchase.
    * 
    * @param proof_ Signature confirming that the caller is eligible for a purchase
    * 
    * Requirements:
    * 
    * - Contract state must be {PRESALE}.
    * - Caller must be eligible for a direct purchase.
    * - Caller must not have already purchased a pass.
    * - Caller must send enough ETH to complete the purchase.
    * - Emits a {Purchased} event.
    * - Transfers {salePrice} directly to withdrawal addresses.
    */
    function completePurchase(Proof calldata proof_)
    external
    payable
    isState(PRESALE)
    hasNotPurchased
    validateEthAmount(salePrice) {
      checkWhitelistAllowance(msg.sender, PRESALE, MAX_AMOUNT, proof_);
    	depositedAmount[msg.sender] = 0;
    	_processPurchase(msg.sender);
    }
    /**
    * @notice Deposits a portion of the sale price.
    * 
    * Requirements:
    * 
    * - Contract state must be {AUCTION}.
    * - Caller must not already have made a deposit.
    * - Caller must send enough ETH to cover the deposit price.
    * - Emits a {Deposited} event.
    */
    function depositBid() external payable isState(AUCTION) hasNotDeposited validateEthAmount(DEPOSIT_PRICE) {
    	depositedAmount[msg.sender] = msg.value;
    	emit Deposited(msg.sender, msg.value);
    }
    /**
    * @notice Deposits the purchase price to join the waitlist.
    * 
    * Requirements:
    * 
    * - Contract state must be {PRESALE}.
    * - Caller must not have already purchased a pass.
    * - Caller must send enough ETH to complete the purchase.
    * - Emits a {Deposited} event.
    */
    function joinWaitlist() external payable isState(PRESALE) hasNotPurchased validateEthAmount(salePrice) {
    	if (_nextWaitlist == 1) {
    		revert AA_WAITLIST_FULL();
    	}
    	unchecked {
    		--_nextWaitlist;
    		depositedAmount[msg.sender] += msg.value;
    	}
    	_waitlist[_nextWaitlist] = msg.sender;
    	emit Deposited(msg.sender, msg.value);
    }
    /**
    * @notice Purchases a Pass.
    * 
    * @param proof_ Signature confirming that the caller is eligible for a purchase
    * 
    * Requirements:
    * 
    * - Contract state must be {PRESALE}.
    * - Caller must not have already purchased a pass.
    * - Caller must send enough ETH to cover the purchase.
    * - Caller must be eligible for a direct purchase.
    * - Emits a {Purchased} event.
    * - Transfers {salePrice} directly to withdrawal addresses.
    */
    function purchasePresale(Proof calldata proof_)
    external
    payable
    isState(PRESALE)
    hasNotPurchased
    validateEthAmount(salePrice) {
      checkWhitelistAllowance(msg.sender, WHITELIST, MAX_AMOUNT, proof_);
    	_processPurchase(msg.sender);
    }
  // **************************************

  // **************************************
  // *****       CONTRACT OWNER       *****
  // **************************************
    /**
    * @notice Claims a purchased pass for `to_`.
    * Note: This function allows the team to mint a pass that hasn't been claimed during the claim period
    *   The recipient may be a different address than the purchaser, for example,
    *   if the purchasing wallet has been compromised
    * 
    * @param for_ address that purchased the pass
    * @param to_ address receiving the pass
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `for_` must have purchased a pass.
    */
    // function airdropClaim(address for_, address to_) external onlyOwner {}
    /**
    * @notice Distributes purchased passes.
    * 	Note: It is preferable to not airdrop more than 50 tokens at a time.
    * 
    * @param amount_ the number of passes to distribute
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - Asteria pass contract must be set.
    * - Contract state must be {REFUND}.
    */
    function distributePurchasedPass(uint256 amount_) external onlyOwner passIsSet isState(REFUND) {
    	if (_nextPurchase == 1) {
    		revert AA_NO_AIRDROP_DUE();
    	}
    	uint256 _count_ = 1;
    	uint256 _index_ = _nextPurchase;
    	while (_index_ > 0 && _count_ < amount_) {
    		unchecked {
    			--_index_;
    		}
    		address _account_ = _purchasers[_index_];
    		if (_account_ != address(0)) {
	    		unchecked {
	    			++_count_;
	    		}
	    		delete _purchasers[_index_];
		    	try asteriaPass.claimFor(_account_, _index_) {}
		      catch Error(string memory reason) {
		        revert(reason);
		      }
    		}
    	}
    }
    /**
    * @notice Distributes waitlisted passes.
    * 	Note: It is preferable to not airdrop more than 50 tokens at a time.
    * 
    * @param amount_ the number of passes to distribute
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - Asteria pass contract must be set.
    * - Contract state must be {REFUND}.
    * - All purchased passes must be distributed.
    */
    function distributeWaitlistedPass(uint256 amount_) external onlyOwner passIsSet isState(REFUND) {
    	if (_nextWaitlist > MAX_SUPPLY) {
    		revert AA_NO_AIRDROP_DUE();
    	}
    	if (_purchasers[_nextPurchase - 1] != address(0) && _purchasers[1] != address(0)) {
    		revert AA_PURCHASES_PENDING();
    	}
    	uint256 _count_;
    	uint256 _index_ = MAX_SUPPLY + 1;
    	while (_index_ > 0 && _count_ < amount_) {
    		unchecked {
    			--_index_;
    		}
    		address _account_ = _waitlist[_index_];
    		if (_account_ != address(0)) {
	    		unchecked {
	    			++_count_;
	    		}
	    		delete _waitlist[_index_];
		    	try asteriaPass.claimFor(_account_, _index_) {}
		      catch Error(string memory reason) {
		        revert(reason);
		      }
    		}
    	}
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
    * @param newState_ the new sale state
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newState_` must be a valid state.
    */
    function setContractState(uint8 newState_) external onlyOwner {
      if (newState_ > REFUND) {
        revert ContractState_INVALID_STATE(newState_);
      }
      _setContractState(newState_);
    }
    /**
    * @notice Updates the sale price.
    * 
    * @param newSalePrice_ the new private price
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    * - `newSalePrice_` must be lower than or equal to {DEPOSIT_PRICE}.
    */
    function setPrice(uint256 newSalePrice_) external onlyOwner {
    	if (DEPOSIT_PRICE > newSalePrice_) {
    		revert AA_INVALID_PRICE();
    	}
      salePrice = newSalePrice_;
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
    /**
    * @notice Updates Asteria and Stable addresses
    * 
    * @param newAsteria_ the new Asteria address
    * @param newStable_ the new Stable address
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
    * - Caller must be the contract owner.
    * - Contract state must be {PAUSED}.
    * - Contract must have a positive balance.
    * - `_asteria` must be able to receive funds.
    * - `_stable` must be able to receive funds.
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
  	* @notice Returns the number of passes purchased.
  	* 
  	* @return the number of passes purchased
  	*/
  	function totalPurchased() public view returns (uint256) {
  		return _nextPurchase - 1;
  	}
  	/**
  	* @notice Returns the number of addresses on the waitlist.
  	* 
  	* @return the number of passes purchased
  	*/
  	function totalWaitlisted() public view returns (uint256) {
  		return MAX_SUPPLY + 1 - _nextWaitlist;
  	}
  // **************************************
}