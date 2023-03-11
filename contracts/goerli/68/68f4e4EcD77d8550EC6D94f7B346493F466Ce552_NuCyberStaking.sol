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

import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IArrayErrors.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ContractState.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/utils/ERC173.sol";
import "@lambdalf-dev/ethereum-contracts/contracts/interfaces/IERC721.sol";
import { FxBaseRootTunnel } from "fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";

contract NuCyberStaking is IArrayErrors, ContractState, ERC173, FxBaseRootTunnel {
	// **************************************
	// *****        CUSTOM TYPES        *****
	// **************************************
		// struct StakingInfo {
		// 	uint256 lastUpdate;
		// 	uint256 rewardsEarned;
		// }
		struct StakedToken {
			uint64 tokenId;
			address beneficiary;
		}
	// **************************************

	// **************************************
	// *****           ERRORS           *****
	// **************************************
		/**
		* @dev Thrown when user tries to unstake a token they don't own
		* 
		* @param tokenId the token being unstaked
		*/
		error NCS_TOKEN_NOT_OWNED(uint256 tokenId);
    /**
    * @dev Thrown when trying to stake while rewards are not set
    */
    error NCS_REWARDS_NOT_SET();
	// **************************************

	// **************************************
	// *****           EVENTS           *****
	// **************************************
		/**
		* @dev Emitted when a user sets a beneficiary address
		* 
		* @param tokenId the token being unstaked
		* @param beneficiary the address benefitting from the token
		*/
		event BenefitStarted(uint256 indexed tokenId, address indexed beneficiary);
		/**
		* @dev Emitted when a user sets a beneficiary address
		* 
		* @param tokenId the token being unstaked
		* @param beneficiary the address benefitting from the token
		*/
		event BenefitEnded(uint256 indexed tokenId, address indexed beneficiary);
	// **************************************

  // **************************************
  // *****    BYTECODE  VARIABLES     *****
  // **************************************
    uint8 public constant ACTIVE = 1;
		// uint256 public constant DAY = 86400;
  // **************************************

	// **************************************
	// *****     STORAGE  VARIABLES     *****
	// **************************************
		// uint256 public generationRate;
		IERC721 public nuCyber;
		// Wallet address mapped to staking info
		// mapping(address => StakingInfo) public stakingInfo;
		// Wallet address mapped to list of token Ids
		mapping(address => StakedToken[]) private _stakedTokens;
		// Beneficiary wallet address mapped to list of token Ids
		mapping(address => uint256[]) private _benefitTokens;
	// **************************************

	constructor(address nucyberContractAddress_/*, uint256 generationRate_*/, address cpManager_, address fxRoot_)
  FxBaseRootTunnel(cpManager_, fxRoot_) {
		nuCyber = IERC721(nucyberContractAddress_);
		// generationRate = generationRate_;
		_setOwner(msg.sender);
	}

	// **************************************
	// *****          INTERNAL          *****
	// **************************************
		/**
		* @dev Internal function returning the benefit balance of `account_`.
		* 
		* @param account_ the beneficiary address
		*/
		function _balanceOfBenefit(address account_) internal view returns (uint256) {
			return _benefitTokens[account_].length;
		}
		/**
		* @dev Internal function returning the staking balance of `account_`.
		* 
		* @param account_ the beneficiary address
		*/
		function _balanceOfStaked(address account_) internal view returns (uint256) {
			return _stakedTokens[account_].length;
		}
		/**
		* @dev Internal function that ends a benefit.
		* 
		* @param beneficiary_ the beneficiary address
		* @param tokenId_ the token being unstaked
		* 
		* Requirements:
		* 
		* - Emits a {BenefitEnded} event
		*/
		function _endBenefit(address beneficiary_, uint256 tokenId_) internal {
			uint256 _last_ = _benefitTokens[beneficiary_].length;
			uint256 _count_ = _last_;
			bool _deleted_;
			while(_count_ > 0) {
				unchecked {
					--_count_;
				}
				if (_benefitTokens[beneficiary_][_count_] == tokenId_) {
					if (_count_ != _last_ - 1) {
						_benefitTokens[beneficiary_][_count_] = _benefitTokens[beneficiary_][_last_ - 1];
					}
					_benefitTokens[beneficiary_].pop();
					_deleted_ = true;
				}
			}
			if(! _deleted_) {
				revert NCS_TOKEN_NOT_OWNED(tokenId_);
			}
			emit BenefitEnded(tokenId_, beneficiary_);
		}
		/**
		* @dev Internal function that returns a specific staked token and its index
		* 
		* @param tokenOwner_ the token owner
		* @param tokenId_ the token being unstaked
		* 
		* Requirements:
		* 
		* - `tokenOwner_` must own `tokenId_`
		*/
		function _findToken(address tokenOwner_, uint256 tokenId_) internal view returns (StakedToken memory, uint256) {
			uint256 _count_ = _stakedTokens[tokenOwner_].length;
			while(_count_ > 0) {
				unchecked {
					--_count_;
				}
				if (_stakedTokens[tokenOwner_][_count_].tokenId == tokenId_) {
					return (_stakedTokens[tokenOwner_][_count_], _count_);
				}
			}
			revert NCS_TOKEN_NOT_OWNED(tokenId_);
		}
    /**
    * @dev Internal function to process a message sent by the child contract on Polygon
    * Note: In our situation, we do not expect to receive any message from the child contract.
    * 
    * @param message the message sent by the child contract
    */
    function _processMessageFromChild(bytes memory message) internal override {
      // We don't need a message from child
    }
    /**
    * @dev Internal function to send a message to the child contract on Polygon
    * 
    * @param sender_ the address staking or unstaking one or more token
    * @param amount_ the number of token being staked or unstaked
    * @param isStake_ whether the token are being staked or unstaked
    */
    function _sendMessage(address sender_, uint16 amount_, bool isStake_) internal {
      if (amount_ > 0) {
        _sendMessageToChild(
          abi.encode(sender_, uint8(1), amount_, isStake_)
        );
      }
    }
		/**
		* @dev Internal function that stakes `tokenId_` for `tokenOwner_`.
		* 
		* @param tokenOwner_ the token owner
		* @param tokenId_ the token being staked
		* @param beneficiary_ an address that will benefit from the token being staked
		* 
		* Requirements:
		* 
		* - `tokenOwner_` must own `tokenId_`
		* - This contract must be allowed to transfer NuCyber tokens on behalf of `tokenOwner_`
		* - Emits a {BenefitStarted} event if `beneficiary_` is not null
		*/
		function _stakeToken(address tokenOwner_, uint256 tokenId_, address beneficiary_) internal {
			_stakedTokens[tokenOwner_].push(StakedToken(uint64(tokenId_),beneficiary_));
			if (beneficiary_ != address(0)) {
				_benefitTokens[beneficiary_].push(tokenId_);
				emit BenefitStarted(tokenId_, beneficiary_);
			}
			// _updateStakingInfo(tokenOwner_);
			try nuCyber.transferFrom(tokenOwner_, address(this), tokenId_) {}
			catch Error(string memory reason) {
				revert(reason);
			}
		}
		/**
		* @dev Internal function that unstakes `tokenId_` for `tokenOwner_`.
		* 
		* @param tokenOwner_ the token owner
		* @param tokenId_ the token being unstaked
		* 
		* Requirements:
		* 
		* - `tokenOwner_` must own `tokenId_`
		* - Emits a {BenefitEnded} event if `tokenId_` had a beneficiary
		*/
		function _unstakeToken(address tokenOwner_, uint256 tokenId_) internal {
			uint256 _last_ = _stakedTokens[tokenOwner_].length;
			uint256 _count_ = _last_;
			bool _deleted_;
			while(_count_ > 0) {
				unchecked {
					--_count_;
				}
				if (_stakedTokens[tokenOwner_][_count_].tokenId == tokenId_) {
					address _beneficiary_ = _stakedTokens[tokenOwner_][_count_].beneficiary;
					if(_beneficiary_ != address(0)) {
						_endBenefit(_beneficiary_, tokenId_);
					}
					if (_count_ != _last_ - 1) {
						_stakedTokens[tokenOwner_][_count_] = _stakedTokens[tokenOwner_][_last_ - 1];
					}
					_stakedTokens[tokenOwner_].pop();
					_deleted_ = true;
				}
			}
			if(! _deleted_) {
				revert NCS_TOKEN_NOT_OWNED(tokenId_);
			}
			// _updateStakingInfo(tokenOwner_);
			try nuCyber.transferFrom(address(this), tokenOwner_, tokenId_) {}
			catch Error(string memory reason) {
				revert(reason);
			}
		}
		/**
		* @dev Internal function that updates staking info for `tokenOwner_`.
		* 
		* @param tokenOwner_ the token owner
		*/
		// function _updateStakingInfo(address tokenOwner_) internal {
		// 	stakingInfo[tokenOwner_].rewardsEarned = totalEarned(tokenOwner_);
		// 	stakingInfo[tokenOwner_].lastUpdate = block.timestamp;
		// }
	// **************************************

	// **************************************
	// *****           PUBLIC           *****
	// **************************************
		/**
		* @notice Stakes a batch of NuCyber at once.
		* 
		* @param tokenIds_ the tokens being staked
		* @param beneficiaries_ a list of addresses that will benefit from the tokens being staked
		* 
		* Requirements:
		* 
		* - Caller must own all of `tokenIds_`
		* - Emits one or more {BenefitStarted} events if `beneficiaries_` is not null
		* - This contract must be allowed to transfer NuCyber tokens on behalf of the caller
		*/
		function bulkStake(uint256[] memory tokenIds_, address[] memory beneficiaries_) public isState(ACTIVE) {
      if (fxChildTunnel == address(0)) {
        revert NCS_REWARDS_NOT_SET();
      }
			uint256 _len_ = tokenIds_.length;
			if ( beneficiaries_.length != _len_ ) {
				revert ARRAY_LENGTH_MISMATCH();
			}
			while (_len_ > 0) {
				unchecked {
					--_len_;
				}
				_stakeToken(msg.sender, tokenIds_[_len_], beneficiaries_[_len_]);
			}
			_sendMessage(msg.sender, uint16(tokenIds_.length), true);
		}
		/**
		* @notice Unstakes a batch of NuCyber at once.
		* 
		* @param tokenIds_ the tokens being unstaked
		* 
		* Requirements:
		* 
		* - Caller must own all of `tokenIds_`
		* - Emits one or more {BenefitEnded} events if `tokenIds_` had beneficiaries
		*/
		function bulkUnstake(uint256[] memory tokenIds_) public {
			uint256 _len_ = tokenIds_.length;
			while (_len_ > 0) {
				unchecked {
					--_len_;
				}
				_unstakeToken(msg.sender, tokenIds_[_len_]);
			}
			_sendMessage(msg.sender, uint16(tokenIds_.length), false);
		}
		/**
		* @notice Stakes a NuCyber token.
		* 
		* @param tokenId_ the token being staked
		* @param beneficiary_ an address that will benefit from the token being staked
		* 
		* Requirements:
		* 
		* - Caller must own `tokenId_`
		* - Emits a {BenefitStarted} event if `beneficiary_` is not null
		* - This contract must be allowed to transfer NuCyber tokens on behalf of the caller
		*/
		function stake(uint256 tokenId_, address beneficiary_) public isState(ACTIVE) {
      if (fxChildTunnel == address(0)) {
        revert NCS_REWARDS_NOT_SET();
      }
			_stakeToken(msg.sender, tokenId_, beneficiary_);
			_sendMessage(msg.sender, 1, true);
		}
		/**
		* @notice Unstakes a NuCyber token.
		* 
		* @param tokenId_ the token being unstaked
		* 
		* Requirements:
		* 
		* - Caller must own `tokenId_`
		* - Emits a {BenefitEnded} event if `tokenId_` had a beneficiary
		*/
		function unstake(uint256 tokenId_) public {
			_unstakeToken(msg.sender, tokenId_);
			_sendMessage(msg.sender, 1, false);
		}
		/**
		* @notice Updates the beneficiary of a staked token.
		* 
		* @param tokenId_ the staked token
		* @param newBeneficiary_ the address that will benefit from the staked token
		* 
		* Requirements:
		* 
		* - Caller must own `tokenId_`
		* - Emits a {BenefitEnded} event if `tokenId_` had a beneficiary
		* - Emits a {BenefitStarted} event if `newBeneficiary_` is not null
		*/
		function updateBeneficiary(uint256 tokenId_, address newBeneficiary_) public {
			(StakedToken memory _stakedToken_, uint256 _index_) = _findToken(msg.sender, tokenId_);
			_stakedTokens[msg.sender][_index_].beneficiary = newBeneficiary_;
			if (_stakedToken_.beneficiary != address(0)) {
				_endBenefit(_stakedToken_.beneficiary, tokenId_);
			}
			if (newBeneficiary_ != address(0)) {
				_benefitTokens[newBeneficiary_].push(tokenId_);
				emit BenefitStarted(tokenId_, newBeneficiary_);
			}
		}
	// **************************************

	// **************************************
	// *****       CONTRACT OWNER       *****
	// **************************************
		/**
		* @notice Sets the NuCyber contract address
		* 
		* @param contractAddress_ the address of the NuCyber contract
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner
		*/
		function setNuCyberContract(address contractAddress_) external onlyOwner {
			nuCyber = IERC721(contractAddress_);
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
      if (newState_ > ACTIVE) {
        revert ContractState_INVALID_STATE(newState_);
      }
      _setContractState(newState_);
		}
		/**
		* @notice Updates the rewards rate.
		* 
		* @param newRate_ the new rewards rate, in tokens per day
		* 
		* Requirements:
		* 
		* - Caller must be the contract owner
		*/
		// function setRewardsRate(uint256 newRate_) external onlyOwner {
		// 	generationRate = newRate_;
		// }
    /**
    * @notice Updates the child contract on Polygon
    * 
    * @param fxChildTunnel_ the new child contract on Polygon
    * 
    * Requirements:
    * 
    * - Caller must be the contract owner.
    */
    function updateFxChildTunnel(address fxChildTunnel_) external onlyOwner {
      fxChildTunnel = fxChildTunnel_;
    }
	// **************************************

	// **************************************
	// *****            VIEW            *****
	// **************************************
		/**
		* @notice Returns the number oof NuCyber staked and owned by `tokenOwner_`.
		* Note: We need this function for collab.land to successfully give out token ownership roles
		* 
		* @param tokenOwner_ address owning tokens
		*/
		function balanceOf(address tokenOwner_) public view returns (uint256) {
			return nuCyber.balanceOf(tokenOwner_) + _balanceOfStaked(tokenOwner_) + _balanceOfBenefit(tokenOwner_);
		}
		/**
		* @notice Returns the benefit balance of `account_`.
		* 
		* @param account_ the address to check
		*/
		function balanceOfBenefit(address account_) external view returns (uint256) {
			return _balanceOfBenefit(account_);
		}
		/**
		* @notice Returns the staking balance of `account_`.
		* 
		* @param account_ the address to check
		*/
		function balanceOfStaked(address account_) external view returns (uint256) {
			return _balanceOfStaked(account_);
		}
		/**
		* @dev Returns the rewards that `tokenOwner_` earns per second.
		* 
		* @param tokenOwner_ address owning tokens
		*/
		// function rewardsPerSecond(address tokenOwner_) public view returns (uint256) {
		// 	return generationRate * _stakedTokens[tokenOwner_].length;
		// }
		/**
		* @notice Returns the list of tokens owned by `tokenOwner_`.
		* 
		* @param tokenOwner_ address owning tokens
		*/
		function stakedTokens(address tokenOwner_) public view returns (StakedToken[] memory) {
			return _stakedTokens[tokenOwner_];
		}
		/**
		* @notice Returns the amount of rewards earned by `tokenOwner_`.
		* 
		* @param tokenOwner_ address owning tokens
		*/
		// function totalEarned(address tokenOwner_) public view returns (uint256) {
		// 	return stakingInfo[tokenOwner_].rewardsEarned + rewardsPerSecond(tokenOwner_) * generationRate / DAY;
		// }
	// **************************************
}

pragma solidity ^0.8.0;

import { RLPReader } from "./RLPReader.sol";

library ExitPayloadReader {
  using RLPReader for bytes;
  using RLPReader for RLPReader.RLPItem;

  uint8 constant WORD_SIZE = 32;

  struct ExitPayload {
    RLPReader.RLPItem[] data;
  }

  struct Receipt {
    RLPReader.RLPItem[] data;
    bytes raw;
    uint256 logIndex;
  }

  struct Log {
    RLPReader.RLPItem data;
    RLPReader.RLPItem[] list;
  }

  struct LogTopics {
    RLPReader.RLPItem[] data;
  }

  // copy paste of private copy() from RLPReader to avoid changing of existing contracts
  function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }

  function toExitPayload(bytes memory data)
        internal
        pure
        returns (ExitPayload memory)
    {
        RLPReader.RLPItem[] memory payloadData = data
            .toRlpItem()
            .toList();

        return ExitPayload(payloadData);
    }

    function getHeaderNumber(ExitPayload memory payload) internal pure returns(uint256) {
      return payload.data[0].toUint();
    }

    function getBlockProof(ExitPayload memory payload) internal pure returns(bytes memory) {
      return payload.data[1].toBytes();
    }

    function getBlockNumber(ExitPayload memory payload) internal pure returns(uint256) {
      return payload.data[2].toUint();
    }

    function getBlockTime(ExitPayload memory payload) internal pure returns(uint256) {
      return payload.data[3].toUint();
    }

    function getTxRoot(ExitPayload memory payload) internal pure returns(bytes32) {
      return bytes32(payload.data[4].toUint());
    }

    function getReceiptRoot(ExitPayload memory payload) internal pure returns(bytes32) {
      return bytes32(payload.data[5].toUint());
    }

    function getReceipt(ExitPayload memory payload) internal pure returns(Receipt memory receipt) {
      receipt.raw = payload.data[6].toBytes();
      RLPReader.RLPItem memory receiptItem = receipt.raw.toRlpItem();

      if (receiptItem.isList()) {
          // legacy tx
          receipt.data = receiptItem.toList();
      } else {
          // pop first byte before parsting receipt
          bytes memory typedBytes = receipt.raw;
          bytes memory result = new bytes(typedBytes.length - 1);
          uint256 srcPtr;
          uint256 destPtr;
          assembly {
              srcPtr := add(33, typedBytes)
              destPtr := add(0x20, result)
          }

          copy(srcPtr, destPtr, result.length);
          receipt.data = result.toRlpItem().toList();
      }

      receipt.logIndex = getReceiptLogIndex(payload);
      return receipt;
    }

    function getReceiptProof(ExitPayload memory payload) internal pure returns(bytes memory) {
      return payload.data[7].toBytes();
    }

    function getBranchMaskAsBytes(ExitPayload memory payload) internal pure returns(bytes memory) {
      return payload.data[8].toBytes();
    }

    function getBranchMaskAsUint(ExitPayload memory payload) internal pure returns(uint256) {
      return payload.data[8].toUint();
    }

    function getReceiptLogIndex(ExitPayload memory payload) internal pure returns(uint256) {
      return payload.data[9].toUint();
    }
    
    // Receipt methods
    function toBytes(Receipt memory receipt) internal pure returns(bytes memory) {
        return receipt.raw;
    }

    function getLog(Receipt memory receipt) internal pure returns(Log memory) {
        RLPReader.RLPItem memory logData = receipt.data[3].toList()[receipt.logIndex];
        return Log(logData, logData.toList());
    }

    // Log methods
    function getEmitter(Log memory log) internal pure returns(address) {
      return RLPReader.toAddress(log.list[0]);
    }

    function getTopics(Log memory log) internal pure returns(LogTopics memory) {
        return LogTopics(log.list[1].toList());
    }

    function getData(Log memory log) internal pure returns(bytes memory) {
        return log.list[2].toBytes();
    }

    function toRlpBytes(Log memory log) internal pure returns(bytes memory) {
      return log.data.toRlpBytes();
    }

    // LogTopics methods
    function getField(LogTopics memory topics, uint256 index) internal pure returns(RLPReader.RLPItem memory) {
      return topics.data[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes memory proof
    ) internal pure returns (bool) {
        require(proof.length % 32 == 0, "Invalid proof length");
        uint256 proofHeight = proof.length / 32;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2 ** proofHeight, "Leaf index is too big");

        bytes32 proofElement;
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }

            if (index % 2 == 0) {
                computedHash = keccak256(
                    abi.encodePacked(computedHash, proofElement)
                );
            } else {
                computedHash = keccak256(
                    abi.encodePacked(proofElement, computedHash)
                );
            }

            index = index / 2;
        }
        return computedHash == rootHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProof {
    /*
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes memory value,
        bytes memory encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    ) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint256 pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {
                return false;
            }

            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;
            }
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (
                        keccak256(RLPReader.toBytes(currentNodeList[16])) ==
                        keccak256(value)
                    ) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) {
                    return false;
                }
                nodeKey = bytes32(
                    RLPReader.toUintStrict(currentNodeList[nextPathNibble])
                );
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 traversed = _nibblesToTraverse(
                    RLPReader.toBytes(currentNodeList[0]),
                    path,
                    pathPtr
                );
                if (pathPtr + traversed == path.length) {
                    //leaf node
                    if (
                        keccak256(RLPReader.toBytes(currentNodeList[1])) ==
                        keccak256(value)
                    ) {
                        return true;
                    } else {
                        return false;
                    }
                }

                //extension node
                if (traversed == 0) {
                    return false;
                }

                pathPtr += traversed;
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
            } else {
                return false;
            }
        }
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint256 pathPtr
    ) private pure returns (uint256) {
        uint256 len = 0;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory nibbles = "";
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble;
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint256 i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
            }
        }
        return nibbles;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str)
        private
        pure
        returns (bytes1)
    {
        return
            bytes1(
                n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10
            );
    }
}

/*
* @author Hamdi Allam [email protected]
* Please reach out with any questions or concerns
*/
pragma solidity ^0.8.0;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START  = 0xb8;
    uint8 constant LIST_SHORT_START   = 0xc0;
    uint8 constant LIST_LONG_START    = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint len;
        uint memPtr;
    }

    struct Iterator {
        RLPItem item;   // Item that's being iterated over.
        uint nextPtr;   // Position of the next item in the list.
    }

    /*
    * @dev Returns the next element in the iteration. Reverts if it has not next element.
    * @param self The iterator.
    * @return The next element in the iteration.
    */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint ptr = self.nextPtr;
        uint itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
    * @dev Returns true if the iteration has more elements.
    * @param self The iterator.
    * @return true if the iteration has more elements.
    */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
    * @dev Create an iterator. Reverts if item is not a list.
    * @param self The RLP item.
    * @return An 'Iterator' over the item.
    */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
    * @param item RLP encoded bytes
    */
    function rlpLen(RLPItem memory item) internal pure returns (uint) {
        return item.len;
    }

    /*
    * @param item RLP encoded bytes
    */
    function payloadLen(RLPItem memory item) internal pure returns (uint) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
    * @param item RLP encoded list in bytes
    */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint dataLen;
        for (uint i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr); 
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START)
            return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    function payloadLocation(RLPItem memory item) internal pure returns (uint, uint) {
        uint offset = _payloadOffset(item.memPtr);
        uint memPtr = item.memPtr + offset;
        uint len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint memPtr, uint len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;
        
        uint ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint result;
        uint memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint) {
        require(item.len > 0 && item.len <= 33);

        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset;

        uint result;
        uint memPtr = item.memPtr + offset;
        assembly {
            result := mload(memPtr)

            // shfit to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint) {
        // one byte prefix
        require(item.len == 33);

        uint result;
        uint memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        uint offset = _payloadOffset(item.memPtr);
        uint len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
    * Private Helpers
    */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint) {
        if (item.len == 0) return 0;

        uint count = 0;
        uint currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
           currPtr = currPtr + _itemLength(currPtr); // skip over an item
           count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint memPtr) private pure returns (uint) {
        uint itemLen;
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START)
            itemLen = 1;
        
        else if (byte0 < STRING_LONG_START)
            itemLen = byte0 - STRING_SHORT_START + 1;

        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte
                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } 

        else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint memPtr) private pure returns (uint) {
        uint byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) 
            return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START))
            return 1;
        else if (byte0 < LIST_SHORT_START)  // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else
            return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /*
    * @param src Pointer to source
    * @param dest Pointer to destination
    * @param len Amount of memory to copy from the source
    */
    function copy(uint src, uint dest, uint len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint mask = 256 ** (WORD_SIZE - len) - 1;

        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import {RLPReader} from "../lib/RLPReader.sol";
import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol";
import {Merkle} from "../lib/Merkle.sol";
import "../lib/ExitPayloadReader.sol";


interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract ICheckpointManager {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    /**
     * @notice mapping of checkpoint header numbers to block details
     * @dev These checkpoints are submited by plasma contracts
     */
    mapping(uint256 => HeaderBlock) public headerBlocks;
}

abstract contract FxBaseRootTunnel {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    // keccak256(MessageSent(bytes))
    bytes32 public constant SEND_MESSAGE_EVENT_SIG = 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    // state sender contract
    IFxStateSender public fxRoot;
    // root chain manager
    ICheckpointManager public checkpointManager;
    // child tunnel contract which receives and sends messages 
    address public fxChildTunnel;

    // storage to avoid duplicate exits
    mapping(bytes32 => bool) public processedExits;

    constructor(address _checkpointManager, address _fxRoot) {
        checkpointManager = ICheckpointManager(_checkpointManager);
        fxRoot = IFxStateSender(_fxRoot);
    }

    // set fxChildTunnel if not set already
    function setFxChildTunnel(address _fxChildTunnel) public {
        require(fxChildTunnel == address(0x0), "FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET");
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * @notice Send bytes message to Child Tunnel
     * @param message bytes message that will be sent to Child Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToChild(bytes memory message) internal {
        fxRoot.sendMessageToChild(fxChildTunnel, message);
    }

    function _validateAndExtractMessage(bytes memory inputData) internal returns (bytes memory) {
        ExitPayloadReader.ExitPayload memory payload = inputData.toExitPayload();

        bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
        uint256 blockNumber = payload.getBlockNumber();
        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                blockNumber,
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(branchMaskBytes),
                payload.getReceiptLogIndex()
            )
        );
        require(
            processedExits[exitHash] == false,
            "FxRootTunnel: EXIT_ALREADY_PROCESSED"
        );
        processedExits[exitHash] = true;

        ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
        ExitPayloadReader.Log memory log = receipt.getLog();

        // check child tunnel
        require(fxChildTunnel == log.getEmitter(), "FxRootTunnel: INVALID_FX_CHILD_TUNNEL");

        bytes32 receiptRoot = payload.getReceiptRoot();
        // verify receipt inclusion
        require(
            MerklePatriciaProof.verify(
                receipt.toBytes(), 
                branchMaskBytes, 
                payload.getReceiptProof(), 
                receiptRoot
            ),
            "FxRootTunnel: INVALID_RECEIPT_PROOF"
        );

        // verify checkpoint inclusion
        _checkBlockMembershipInCheckpoint(
            blockNumber,
            payload.getBlockTime(),
            payload.getTxRoot(),
            receiptRoot,
            payload.getHeaderNumber(),
            payload.getBlockProof()
        );

        ExitPayloadReader.LogTopics memory topics = log.getTopics();

        require(
            bytes32(topics.getField(0).toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
            "FxRootTunnel: INVALID_SIGNATURE"
        );

        // received message data
        (bytes memory message) = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message
        return message;
    }

    function _checkBlockMembershipInCheckpoint(
        uint256 blockNumber,
        uint256 blockTime,
        bytes32 txRoot,
        bytes32 receiptRoot,
        uint256 headerNumber,
        bytes memory blockProof
    ) private view returns (uint256) {
        (
            bytes32 headerRoot,
            uint256 startBlock,
            ,
            uint256 createdAt,

        ) = checkpointManager.headerBlocks(headerNumber);

        require(
            keccak256(
                abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)
            )
                .checkMembership(
                blockNumber-startBlock,
                headerRoot,
                blockProof
            ),
            "FxRootTunnel: INVALID_HEADER"
        );
        return createdAt;
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param inputData RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function receiveMessage(bytes memory inputData) public virtual {
        bytes memory message = _validateAndExtractMessage(inputData);
        _processMessageFromChild(message);
    }

    /**
     * @notice Process message received from Child Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param message bytes message that was sent from Child Tunnel
     */
    function _processMessageFromChild(bytes memory message) virtual internal;
}