// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {
	IERC20,
	SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {
	StakerConfig
} from "./lib/StakerConfig.sol";

import {
	IFee1155
} from "./interfaces/IFee1155.sol";

import {
	ItemOrigin,
	ISuperVerseStaker
} from "./interfaces/ISuperVerseStaker.sol";

import {
	ItemsById,
	PRECISION,
	SINGLE_ITEM
} from "./lib/TypesAndConstants.sol";

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title SuperVerseDAO staking contract.
	@author throw; <@0xthrpw>
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	yr mum is a savage

	@custom:date May 15th, 2023.
*/
contract SuperVerseStaker is 
	ISuperVerseStaker, StakerConfig, ReentrancyGuard
{
	using SafeERC20 for IERC20;

	/** 
	This struct defines a user's staked position
	*/
	struct Staker {
		uint256 stakerPower;
		uint256 missedReward;
		uint256 claimedReward;
		uint256 stakedTokens;
		ItemsById ETs;
		ItemsById SFs;
	}

	/// user address > position
	mapping ( address => Staker ) internal _stakers;

	/// rewards distributed over reward period.
	uint256 public reward;
	/// rewards for previous reward windows.
	uint256 public allProduced;
	/// total produced reward.
	uint256 public producedReward;
	/// reward round beginning timestamp.
	uint256 public producedTimestamp;
	/// rewards per power point.
	uint256 public rpp;
	/// total power points.
	uint256 public totalPower;

	/**
	   Construct a new instance of a SuperVerse staking contract with the 
	   following parameters.

	   @param _etCollection The address of the Elliotrades NFT collection
	   @param _sfCollection The address of the SuperFarm NFT collection
	   @param _token The address of the staking erc20 token
	   @param _rewardPeriod The length of time rewards are emitted
	*/
	constructor(
		address _etCollection,
		address _sfCollection,
		address _token,
		uint256 _rewardPeriod
	) StakerConfig (
		_etCollection,
		_sfCollection,
		_token,
		_rewardPeriod
	) {}

	/**
	   
	*/
	receive () external payable{
		emit Fund(
			msg.sender, 
			msg.value
		);
	}

	function _produced () private view returns (uint256) {
		return allProduced + 
			reward * (block.timestamp - producedTimestamp) / REWARD_PERIOD;
	}

	function _update () private {
		uint256 current = _produced();
		if (current > producedReward) {
			uint256 difference = current - producedReward;
			if (totalPower > 0) {
				rpp += difference * PRECISION / totalPower;
			}
			producedReward += difference;
		}
	}

	/**
	   Get the pending reward for a given address
	*/
	function _calcReward (
		address _recipient,
		uint256 _rpp
	) private view returns(uint256) {
		Staker storage staker = _stakers[_recipient];
		return staker.stakerPower * _rpp/ PRECISION - 
			staker.claimedReward - staker.missedReward;
	}

	/**
		A helper function for locking ERC20 and ERC1155 assets and
		calculating staker's gained power.

		@param _erc20Amount Amount of ERC20 staking tokens.
		@param _items An array of ERC1155 items being staked.
		@param _staker A storage pointer to staker.

		@return power A sum of all assets power.
	*/
	function _addAssets (
		uint256 _erc20Amount,
		InputItem[] calldata _items,
		Staker storage _staker
	) private returns (uint256 power) {

		/// Handle ERC20 tokens
		IERC20(TOKEN).safeTransferFrom(
			msg.sender,
			address(this),
			_erc20Amount
		);

		power = _erc20Amount;
		
		for (uint256 i; i < _items.length; ){
			
			if (_items[i].origin == ItemOrigin.SF1155) {

				if (_staker.SFs.exists(_items[i].itemId)) {
					revert ItemAlredyStaked();
				}

				IFee1155(SF_COLLECTION).safeTransferFrom(
					msg.sender,
					address(this),
					_items[i].itemId,
					SINGLE_ITEM,
					""
				);

				_staker.SFs.add(_items[i].itemId);
			} 

			if (_items[i].origin == ItemOrigin.ET1155) {
				
				if (_staker.ETs.exists(_items[i].itemId)) {
					revert ItemAlredyStaked();
				}

				IFee1155(ET_COLLECTION).safeTransferFrom(
					msg.sender,
					address(this),
					_items[i].itemId,
					SINGLE_ITEM,
					""
				);

				_staker.ETs.add(_items[i].itemId);
			}

			//get item id and parse group id
			uint256 grpId = _items[i].itemId >> 128;

			unchecked {
				//add value from group id in item reward mapping
				power += itemValues[_items[i].origin][grpId];
				++i;
			}
		}
	}

	/**
	   A helper function for retrieving ERC20 and ERC1155 assets and
		calculating staker's lost power.

		@param _erc20Amount Amount of ERC20 staking tokens.
		@param _items An array of ERC1155 items being staked.
		@param _staker A storage pointer to staker.

		@return power A sum of all assets power.
	*/
	function _removeAssets (
		uint256 _erc20Amount,
		InputItem[] calldata _items,
		Staker storage _staker
	) private returns (uint256 power) {

		if (_erc20Amount > _staker.stakedTokens) {
			revert AmountExceedsStakedAmount();
		}

		/// Handle ERC20 tokens
		IERC20(TOKEN).safeTransfer(
			msg.sender,
			_erc20Amount
		);

		power = _erc20Amount;
		
		for (uint256 i; i < _items.length; ){
			
			if (_items[i].origin == ItemOrigin.SF1155) {

				if (!_staker.SFs.exists(_items[i].itemId)) {
					revert ItemNotFound();
				}

				IFee1155(SF_COLLECTION).safeTransferFrom(
					address(this),
					msg.sender,
					_items[i].itemId,
					SINGLE_ITEM,
					""
				);

				_staker.SFs.remove(_items[i].itemId);
			} 

			if (_items[i].origin == ItemOrigin.ET1155) {
				
				if (!_staker.ETs.exists(_items[i].itemId)) {
					revert ItemNotFound();
				}

				IFee1155(ET_COLLECTION).safeTransferFrom(
					address(this),
					msg.sender,
					_items[i].itemId,
					SINGLE_ITEM,
					""
				);

				_staker.ETs.remove(_items[i].itemId);
			}

			//get item id and parse group id
			uint256 grpId = _items[i].itemId >> 128;

			unchecked {
				//add value from group id in item reward mapping
				power += itemValues[_items[i].origin][grpId];
				++i;
			}
		}
	}

	function _claim () private {

		_update();

		uint256 rewardAmount = _calcReward(msg.sender, rpp);
		if (rewardAmount == 0) {
			return;
		}

		(bool success,) = msg.sender.call{value: rewardAmount}("");
		if (!success) {
			revert RewardPayoutFailed();
		}

		unchecked {
			_stakers[msg.sender].claimedReward += rewardAmount;
		}
		
		emit Claim(msg.sender, rewardAmount);
	}

	/**
	   Stake ERC 20 tokens and items from specified collections.  The amount of 
	   ERC20 tokens can be zero as long as at least one item is staked.

	   @param _amount ss
	   @param _items ss
	*/
	function stake (
		uint256 _amount,
		InputItem[] calldata _items
	) external nonReentrant {

		if(_amount == 0 && _items.length == 0){
			revert BadArguments();
		}

		Staker storage staker = _stakers[msg.sender];

		uint256 power = _addAssets(_amount, _items, staker);

		_update();

		/// Update balance and positions
		unchecked {
			staker.stakedTokens += _amount;
			staker.stakerPower += power;
			staker.missedReward += power * rpp / PRECISION;
			totalPower += power;
		}

		emit Stake(
			msg.sender,
			_amount,
			power,
			_items
		);
	}

	/**
	   
	*/
	function withdraw (
		uint256 _amount,
		InputItem[] calldata _items
	) external nonReentrant {

		if(_amount == 0 && _items.length == 0){
			revert BadArguments();
		}

		Staker storage staker = _stakers[msg.sender];

		uint256 lostPower = _removeAssets(_amount, _items, staker);

		_claim();

		uint256 difference = staker.stakerPower - lostPower;

		unchecked {
			staker.stakedTokens -= _amount;
			staker.stakerPower = difference;
			staker.missedReward += difference * rpp / PRECISION;
			totalPower -= lostPower;
		}
		delete staker.claimedReward;

		emit Withdraw(
			msg.sender,
			_amount,
			lostPower,
			_items
		);
	}

	/**
	   
	*/
	function claim () external nonReentrant {
		_claim();
	}

	/**
	   
	*/
	function rebase () external {
		if( block.timestamp < nextRebaseTimestamp ){
			revert RebaseWindowClosed();
		}

		allProduced = _produced();
		reward = address(this).balance;
		producedTimestamp = block.timestamp;
		nextRebaseTimestamp = block.timestamp + rebaseCooldown;
	}

	function availableReward (address _staker) public view returns (uint256) {
		uint256 rpp_virtual = rpp;
		uint256 current = _produced();
		uint256 difference = current - producedReward;
		if (totalPower > 0) {
			rpp_virtual += difference * PRECISION / totalPower;
		}
		return _calcReward(_staker, rpp_virtual);
	}

	function stakerInfo (
		address _staker
	) external view returns (
		uint256 stakerPower,
		uint256 missedReward,
		uint256 claimedReward,
		uint256 stakedTokens,
		uint256 availableToClaim,
		uint256[] memory idsET,
		uint256[] memory idsSFs
	) {
		Staker storage staker = _stakers[_staker];
		availableToClaim = availableReward(_staker);
		stakerPower = staker.stakerPower;
		missedReward = staker.missedReward;
		claimedReward = staker.claimedReward;
		stakedTokens = staker.stakedTokens;
		idsET = staker.ETs.array;
		idsSFs = staker.SFs.array;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

interface IFee1155 {
	function setApprovalForAll ( address, bool ) external;
	function safeTransferFrom (
		address, address, uint256, uint256, bytes memory) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

/**
	This enum tracks each type of asset that may be operated on with this 
	staker.

	@param ET1155 A staked Elliotrades NFT.
	@param SF1155 A staked SuperFarm NFT.
*/
enum ItemOrigin {
	ET1155,
	SF1155
}

interface ISuperVerseStaker {

	error ItemAlredyStaked ();

	error ItemNotFound ();

	error AmountExceedsStakedAmount ();

	error RewardPayoutFailed ();
	
	/**
		Thrown when attempting to stake or unstake no tokens and no items.
	*/
	error BadArguments ();

	/**
		Thrown when attempting to rebase before cooldown window is finished.
	*/
	error rebaseWindowClosed ();

	/**
		Thrown when attempting to rebase before cooldown window is finished.
	*/
	error RebaseWindowClosed ();

	/**
	   Emitted on new staking position.
	*/
	event Stake (
		address indexed user,
		uint256 amount,
		uint256 power,
		InputItem[] items
	);

	/** 
	   Emitted on successful reward claim.
	*/
	event Claim (
		address indexed user,
		uint256 amount
	);

	/** 
	   Emitted on successful withdrawal.
	*/
	event Withdraw (
		address indexed user,
		uint256 amount,
		uint256 power,
		InputItem[] items
	);

	/** 
	   Emitted on reward funding.
	*/
	event Fund (
		address indexed user,
		uint256 amount
	);

	/**
	   Input helper struct.
	*/
	struct InputItem {
		uint256 itemId;
		ItemOrigin origin;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	Ownable
} from "@openzeppelin/contracts/access/Ownable.sol";
import {
	Address
} from "@openzeppelin/contracts/utils/Address.sol";

error RightNotSpecified();
error CallerHasNoAccess();
error ManagedRightNotSpecified();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title An advanced permission-management contract.
	@author Tim Clancy <@_Enoch>

	This contract allows for a contract owner to delegate specific rights to
	external addresses. Additionally, these rights can be gated behind certain
	sets of circumstances and granted expiration times. This is useful for some
	more finely-grained access control in contracts.

	The owner of this contract is always a fully-permissioned super-administrator.

	@custom:date August 23rd, 2021.
*/
abstract contract PermitControl is Ownable {
	using Address for address;

	/// A special reserved constant for representing no rights.
	bytes32 internal constant _ZERO_RIGHT = hex"00000000000000000000000000000000";

	/// A special constant specifying the unique, universal-rights circumstance.
	bytes32 internal constant _UNIVERSAL = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

	/**
		A special constant specifying the unique manager right. This right allows an
		address to freely-manipulate the `managedRight` mapping.
	*/
	bytes32 internal constant _MANAGER = hex"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

	/**
		A mapping of per-address permissions to the circumstances, represented as
		an additional layer of generic bytes32 data, under which the addresses have
		various permits. A permit in this sense is represented by a per-circumstance
		mapping which couples some right, represented as a generic bytes32, to an
		expiration time wherein the right may no longer be exercised. An expiration
		time of 0 indicates that there is in fact no permit for the specified
		address to exercise the specified right under the specified circumstance.

		@dev Universal rights MUST be stored under the 0xFFFFFFFFFFFFFFFFFFFFFFFF...
		max-integer circumstance. Perpetual rights may be given an expiry time of
		max-integer.
	*/
	mapping ( address => mapping( bytes32 => mapping( bytes32 => uint256 ))) 
		internal _permissions;

	/**
		An additional mapping of managed rights to manager rights. This mapping
		represents the administrator relationship that various rights have with one
		another. An address with a manager right may freely set permits for that
		manager right's managed rights. Each right may be managed by only one other
		right.
	*/
	mapping ( bytes32 => bytes32 ) internal _managerRights;

	/**
		An event emitted when an address has a permit updated. This event captures,
		through its various parameter combinations, the cases of granting a permit,
		updating the expiration time of a permit, or revoking a permit.

		@param updater The address which has updated the permit.
		@param updatee The address whose permit was updated.
		@param circumstance The circumstance wherein the permit was updated.
		@param role The role which was updated.
		@param expirationTime The time when the permit expires.
	*/
	event PermitUpdated (
		address indexed updater,
		address indexed updatee,
		bytes32 circumstance,
		bytes32 indexed role,
		uint256 expirationTime
	);

	/**
		An event emitted when a management relationship in `managerRight` is
		updated. This event captures adding and revoking management permissions via
		observing the update history of the `managerRight` value.

		@param manager The address of the manager performing this update.
		@param managedRight The right which had its manager updated.
		@param managerRight The new manager right which was updated to.
	*/
	event ManagementUpdated (
		address indexed manager,
		bytes32 indexed managedRight,
		bytes32 indexed managerRight
	);

	/**
		A modifier which allows only the super-administrative owner or addresses
		with a specified valid right to perform a call.

		@param _circumstance The circumstance under which to check for the validity
			of the specified `right`.
		@param _right The right to validate for the calling address. It must be
			non-expired and exist within the specified `_circumstance`.
	*/
	modifier hasValidPermit (
		bytes32 _circumstance,
		bytes32 _right
	) {
		if (
			msg.sender != owner() &&
				!_hasRight(msg.sender, _circumstance, _right)
		) {
			revert CallerHasNoAccess();
		}
		_;
	}

	/**
		Determine whether or not an address has some rights under the given
		circumstance,

		@param _address The address to check for the specified `_right`.
		@param _circumstance The circumstance to check the specified `_right` for.
		@param _right The right to check for validity.

		@return true or false, whether user has rights and time is valid.
	*/
	function _hasRight (
		address _address,
		bytes32 _circumstance,
		bytes32 _right
	) internal view returns (bool) {
		return _permissions[_address][_circumstance][_right] > block.timestamp;
	}
	/**
		Set the `_managerRight` whose `UNIVERSAL` holders may freely manage the
		specified `_managedRight`.

		@param _managedRight The right which is to have its manager set to
			`_managerRight`.
		@param _managerRight The right whose `UNIVERSAL` holders may manage
			`_managedRight`.
	*/

	function setManagerRight (
		bytes32 _managedRight,
		bytes32 _managerRight
	) external virtual hasValidPermit(_UNIVERSAL, _MANAGER) {
		if (_managedRight == _ZERO_RIGHT) {
			revert ManagedRightNotSpecified();
		}
		_managerRights[_managedRight] = _managerRight;
		emit ManagementUpdated(msg.sender, _managedRight, _managerRight);
	}

	/**
		Set the permit to a specific address under some circumstances. A permit may
		only be set by the super-administrative contract owner or an address holding
		some delegated management permit.

		@param _address The address to assign the specified `_right` to.
		@param _circumstance The circumstance in which the `_right` is valid.
		@param _right The specific right to assign.
		@param _expirationTime The time when the `_right` expires for the provided
			`_circumstance`.
	*/
	function setPermit (
		address _address,
		bytes32 _circumstance,
		bytes32 _right,
		uint256 _expirationTime
	) public virtual hasValidPermit(_UNIVERSAL, _managerRights[_right]) {
		if(_right == _ZERO_RIGHT) {
			revert RightNotSpecified();
		}
		_permissions[_address][_circumstance][_right] = _expirationTime;
		emit PermitUpdated(
			msg.sender,
			_address,
			_circumstance,
			_right,
			_expirationTime
		);
	}

	/**
		Determine whether or not an address has some rights under the given
		circumstance, and if they do have the right, until when.

		@param _address The address to check for the specified `_right`.
		@param _circumstance The circumstance to check the specified `_right` for.
		@param _right The right to check for validity.

		@return The timestamp in seconds when the `_right` expires. If the timestamp
			is zero, we can assume that the user never had the right.
	*/
	function hasRightUntil (
		address _address,
		bytes32 _circumstance,
		bytes32 _right
	) public view returns (uint256) {
		return _permissions[_address][_circumstance][_right];
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	IERC721
} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {
	IERC1155
} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {
	IERC20,
	SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {
	PermitControl
} from "./access/PermitControl.sol";

/**
	Thrown in the event that attempting to rescue an asset from the contract 
	fails.

	@param index The index of the asset whose rescue failed.
*/
error RescueFailed (uint256 index);

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title Escape Hatch
	@author Rostislav Khlebnikov <@catpic5buck>
	@custom:contributor Tim Clancy <@_Enoch>
	
	This contract contains logic for pausing contract operations during updates 
	and a backup mechanism for user assets restoration.
*/
abstract contract EscapeHatch is PermitControl {
	using SafeERC20 for IERC20;

	/// The public identifier for the right to rescue assets.
	bytes32 internal constant _ASSET_RESCUER = keccak256("ASSET_RESCUER");

	/**
		An enum type representing the status of the contract being escaped.

		@param None A default value used to avoid setting storage unnecessarily.
		@param Unpaused The contract is unpaused.
		@param Paused The contract is paused.
	*/
	enum Status {
		None,
		Unpaused,
		Paused
	}

	/**
		An enum type representing the type of asset this contract may be dealing 
		with.

		@param Native The type for Ether.
		@param ERC20 The type for an ERC-20 token.
		@param ERC721 The type for an ERC-721 token.
		@param ERC1155 The type for an ERC-1155 token.
	*/
	enum AssetType {
		Native,
		ERC20,
		ERC721,
		ERC1155
	}

	/**
		A struct containing information about a particular asset transfer.

		@param assetType The type of the asset involved.
		@param asset The address of the asset.
		@param id The ID of the asset.
		@param amount The amount of asset being transferred.
		@param to The destination address where the asset is being sent.
	*/
	struct Asset {
		AssetType assetType;
		address asset;
		uint256 id;
		uint256 amount;
		address to;
	}

	/// A flag to track whether or not the contract is paused.
	Status internal _status = Status.Unpaused;

	/**
		Construct a new instance of an escape hatch, which supports pausing and the 
		rescue of trapped assets.

		@param _rescuer The address of the rescuer caller that can pause, unpause, 
			and rescue assets.
	*/
	constructor (
		address _rescuer
	) {

		// Set the permit for the rescuer.
		setPermit(_rescuer, _UNIVERSAL, _ASSET_RESCUER, type(uint256).max);
	}

	/// An administrative function to pause the contract.
	function pause () external hasValidPermit(_UNIVERSAL, _ASSET_RESCUER) {
		_status = Status.Paused;
	}

	/// An administrative function to resume the contract.
	function unpause () external hasValidPermit(_UNIVERSAL, _ASSET_RESCUER) {
		_status = Status.Unpaused;
	}

	/// Return the magic value signifying the ability to receive ERC-721 items.
	function onERC721Received (
		address,
		address,
		uint256,
		bytes memory
	) public pure returns (bytes4) {
		return bytes4(
			keccak256(
				"onERC721Received(address,address,uint256,bytes)"
			)
		);
	}

	/// Return the magic value signifying the ability to receive ERC-1155 items.
	function onERC1155Received (
		address,
		address,
		uint256,
		uint256,
		bytes memory
	) public pure returns (bytes4) {
		return bytes4(
			keccak256(
				"onERC1155Received(address,address,uint256,uint256,bytes)"
			)
		);
	}

	/// Return the magic value signifying the ability to batch receive ERC-1155.
	function onERC1155BatchReceived (
		address,
		address,
		uint256[] memory,
		uint256[] memory,
		bytes memory
	) public pure returns (bytes4) {
		return bytes4(
			keccak256(
				"onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
			)
		);
	}

	/**
		An admin function used in emergency situations to transfer assets from this 
		contract if they get stuck.

		@param _assets An array of `Asset` structs to attempt transfers.

		@custom:throws RescueFailed if an Ether asset could not be rescued.
	*/
	function rescueAssets (
		Asset[] calldata _assets
	) external hasValidPermit(_UNIVERSAL, _ASSET_RESCUER) {
		for (uint256 i; i < _assets.length; ) {

			// If the asset is Ether, attempt a rescue; skip on reversion.
			if (_assets[i].assetType == AssetType.Native) {
				(bool result, ) = _assets[i].to.call{ value: _assets[i].amount }("");
				if (!result) {
					revert RescueFailed(i);
				}
				unchecked {
					++i;
				}
				continue;
			}

			// Attempt to rescue ERC-20 items.
			if (_assets[i].assetType == AssetType.ERC20) {
				IERC20(_assets[i].asset).safeTransfer(
					_assets[i].to,
					_assets[i].amount
				);
			}

			// Attempt to rescue ERC-721 items.
			if (_assets[i].assetType == AssetType.ERC721) {
				IERC721(_assets[i].asset).transferFrom(
					address(this),
					_assets[i].to,
					_assets[i].id
				);
			}

			// Attempt to rescue ERC-1155 items.
			if (_assets[i].assetType == AssetType.ERC1155) {
				IERC1155(_assets[i].asset).safeTransferFrom(
					address(this),
					_assets[i].to,
					_assets[i].id,
					_assets[i].amount,
					""
				);
			}
			unchecked {
				++i;
			}
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {
	EscapeHatch
} from "./EscapeHatch.sol";

import {
	ItemOrigin
} from "../interfaces/ISuperVerseStaker.sol";

/**
	Thrown when attempting to set item values with unequal argument arrays lengths.
*/
error CantConfigureItemValues ();

/**
	@custom:benediction DEVS BENEDICAT ET PROTEGAT CONTRACTVS MEAM
	@title SuperVerseDAO staking contract.
	@author throw; <@0xthrpw>
	@author Tim Clancy <@_Enoch>
	@author Rostislav Khlebnikov <@catpic5buck>

	yr mum's config

	@custom:date May 15th, 2023.
*/
contract StakerConfig is EscapeHatch {

	/// The identifier for the right to configure emission rates and the DAO tax.
	bytes32 constant private  _CONFIG_ITEM_VALUES = 
		keccak256("CONFIG_ITEM_VALUES");

	/// The identifier for the right to configure the length of reward emission.
	bytes32 constant private  _CONFIG_WINDOW = 
		keccak256("CONFIG_WINDOW");

	/// The address of the Elliotrades NFT collection
	address immutable public ET_COLLECTION;

	/// The address of the SuperFarm NFT collection
	address immutable public SF_COLLECTION;

	/// The address of the ERC20 staking token
	address immutable public TOKEN;

	/// The amount of time for which rewards are emitted
	uint256 public immutable REWARD_PERIOD;

	/// The timestamp of when rebase can next be called
	uint256 public nextRebaseTimestamp;

	/// The minimum amount of seconds between rebase calls
	uint256 public rebaseCooldown;

	/// collection type > group id > equivalent token amount
	mapping( ItemOrigin => mapping ( uint256 => uint128 ) ) public itemValues;

	/**
	   Construct a new instance of a SuperVerse staking contract with the 
	   following parameters.

	   @param _etCollection The address of the Elliotrades NFT collection
	   @param _sfCollection The address of the SuperFarm NFT collection
	   @param _token The address of the staking erc20 token
	   @param _rewardPeriod The length of time rewards are emitted
	*/
	constructor(
		address _etCollection,
		address _sfCollection,
		address _token,
		uint256 _rewardPeriod
	) EscapeHatch (
		msg.sender
	) {
		ET_COLLECTION = _etCollection;
		SF_COLLECTION = _sfCollection;
		TOKEN = _token;
		REWARD_PERIOD = _rewardPeriod;
		rebaseCooldown = 1 weeks;
	}


	/**
		This function allows a permitted user to configure the equivalent token
		values available for each item rarity/type.

		@param _assetType The type of asset whose timelock options are being 
			configured.
		@param _groupIds An array with IDs for specific rewards 
			available under `_assetType`.
		@param _values An array keyed to `_groupIds` containing the token 
			value for the group id
	*/
	function configureItemValues (
		ItemOrigin _assetType,
		uint256[] memory _groupIds,
		uint128[] memory _values
	) external hasValidPermit(_UNIVERSAL, _CONFIG_ITEM_VALUES) {
		if (_groupIds.length != _values.length) {
			revert CantConfigureItemValues();
		}
		for (uint256 i; i < _groupIds.length; ) {
			itemValues[_assetType][_groupIds[i]] = _values[i];
			unchecked { ++i; }
		}
	}

	/**
	   
	*/
	function setRebaseCooldown (
		uint256 _rebaseCooldown
	) external hasValidPermit(_UNIVERSAL, _CONFIG_WINDOW) {
		rebaseCooldown = _rebaseCooldown;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

using ItemsHelper for ItemsById global;

library ItemsHelper {

	function add(
		ItemsById storage _items,
		uint256 _tokenId
	) internal {
		_items.array.push(_tokenId);
		_items.idx[_tokenId] = _items.array.length;
	}

	function remove(
		ItemsById storage _items,
		uint256 _tokenId
	) internal {

		uint256 arrayIdx = _items.idx[_tokenId] - 1;
		uint256 lastIdx = _items.array.length - 1;

		if (arrayIdx != lastIdx) {
			uint256 lastElement = _items.array[lastIdx];
			_items.array[arrayIdx] = lastElement;
			_items.idx[lastElement] = arrayIdx;
		}

		_items.array.pop();

		delete _items.idx[_tokenId];
	}

	function exists(
		ItemsById storage _items,
		uint256 _tokenId
	) internal view returns (bool) {
		return _items.idx[_tokenId] != 0;
	}
}

/*
	Staked item storage alignment.
*/
struct ItemsById {
	uint256[] array;
	mapping ( uint256 => uint256 ) idx;
}

uint256 constant SINGLE_ITEM = 1;
uint256 constant PRECISION = 1e12;