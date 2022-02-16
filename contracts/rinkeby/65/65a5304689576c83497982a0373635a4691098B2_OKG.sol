// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// An Omega Key and its owners
struct OmegaKey {
	bool active;
	bool removed; // whether a Key is removed by a successful Reward claim
	uint256 keyId; // equal to the Id of the Voxo this Key was assigned to
	address[] owners;
}

// A Player's Omega Key collection
struct Player {
	bool active;
	uint256[] keyids; // A Key # is equal to the Voxo's Id it was assigned to
}

/**
 * @title Omega Key Game Smart Contract
 * @dev All methods to conduct the Omega Key Game on-chain
 * @dev https://voxodeus.notion.site/Omega-Key-Game-143fcf958a254295a5a1e2b344867fca
 */

contract OKG is Ownable, Pausable {
	using SafeMath for uint256;
	using Address for address;

	// Mapping to handle Omega Keys
	mapping(uint256 => OmegaKey) public omegaKeys;
	// Mapping to handle Players
	mapping(address => Player) public players;
	// Event for when an Omega Key is released
	event OmegaKeyReleased(uint256[] OmegaKey);
	// Event for when a Player registers their ownership of an Omega Key
	event OmegaKeyRegistered(address indexed Owner, uint256[]  OmegaKey);
	// Event for when an Omega Key is removed from the game
	event OmegaKeyRemoved(address indexed Winner, uint256 indexed OmegaKey, uint256 indexed Tier, address[] allOwners);
	// Event for when the removal of an Omega Key is reversed
	event OmegaKeyRestored(address[] oldOwners, uint256 indexed OmegaKey);
	// Event for when an Omega Reward is successfully claimed
	event RewardClaimed(address indexed Winner, uint256 indexed Tier, uint256 Amount);
	// Event for when an Omega Reward's claim status is reverted to being available
	event RewardRestored(uint256 indexed Tier, uint256 Amount);
	// Address of the NFT contract
	address public nftContract;
	// Availability of the Diamond Reward
	bool public isDiamondRewardClaimed;
	// Availability of the Gold Reward
	bool public isGoldRewardClaimed;
	// Availability of the Silver Reward
	bool public isSilverRewardClaimed;
	// Availability of the Bronze Reward
	bool public isBronzeRewardClaimed;


    constructor(address NFT_contract_address) {
    	nftContract = NFT_contract_address;
    }

	modifier isReleased(uint256 _keyId) {
		require(isKey(_keyId), "VOXO: Omega Key not released");
		_;
	}

	modifier whenNotGameOver() {
		require(!isGameOver(), "VOXO: Game Over");
		_;
	}

	modifier isOmegaRewardAmount(uint256 _ethReward) {
		require(isOmegaReward(_ethReward), "VOXO: Reward for this ETH amount does not exist");
		_;
	}

	/**
     * @dev Implementation / Instance of paused methods() in the ERC20.
     * @param status Setting the status boolean (True for paused, or False for unpaused)
     * See {ERC20Pausable}.
     */
    function pause(bool status) public onlyOwner() {
        if (status) {
            _pause();
        } else {
            _unpause();
        }
    }

	/**
	 * @dev Method to record the release of a new Omega Key
	 * @dev A Key # is equal to the voxoId of the Voxo it is assigned to
	 * @param _id The Array of keyids
	 */
	function release(uint256[] calldata _id) external
		onlyOwner()
		whenNotGameOver()
		whenNotPaused()
	{
		for (uint i = 0; i < _id.length; i++) {
			require((_id[i] != uint(0)), "VOXO: Voxo Id cannot be Zero");
			require(!isKey(_id[i]), "VOXO: Voxo can only be assigned 1 Omega Key");
			require(!isRemoved(_id[i]), "VOXO: Voxo cannot be assigned to a removed Omega Key");
		}

		for (uint i = 0; i < _id.length; i++) {
			omegaKeys[_id[i]] = OmegaKey({
				active: true,
				removed: false,
				keyId: _id[i],
				owners: new address[](0)
			});
		}
		// Emit Event for the released Omega Key
		emit OmegaKeyReleased(_id);
	}

	/**
	 * @dev Method to register a Player's ownership of an Omega Key
	 * @param _keyId The Voxo Id / Key # a player intends to register
	 */
	function register(uint256[] calldata _keyId) external
		whenNotGameOver()
		whenNotPaused()
	{
		// Instance of NFT VoxoDeus, to Verify the ownership
		IERC721 _token = IERC721(address(nftContract));
		for (uint i = 0; i < _keyId.length; i++) {
			require((_keyId[i] != uint(0)), "VOXO: Voxo Id cannot be Zero");
			require(isKey(_keyId[i]), "VOXO: Omega Key not released");
			require(!isRegistered(_keyId[i], _msgSender()), "VOXO: Omega Key already registered");
			require(_token.ownerOf(_keyId[i]) == _msgSender(), "VOXO: You are not the owner of this KeyVoxo");
		}

		for (uint i = 0; i < _keyId.length; i++) {
			// register Player as an owner of this Omega Key
			omegaKeys[_keyId[i]].owners.push(_msgSender());
			// add Omega Key to a Player's Omega Key Collection
			if (players[_msgSender()].active) {
				players[_msgSender()].keyids.push(_keyId[i]);
			} else {
				players[_msgSender()].active = true;
				players[_msgSender()].keyids.push(_keyId[i]);
			}
		}
		// Emit Event for the Player registering an Omega Key
		emit OmegaKeyRegistered(_msgSender(), _keyId);
	}

	/**
	 * @dev Method to claim an Omega Reward
	 * @dev To claim a Reward, a Player needs to have at least
	 * @dev the Reward's required number of Keys in their Collection
	 * @dev Key Requirements: 3 for Bronze, 4 for Silver, 6 for Gold, and 8 for Diamond.
	 * @param _ethClaim The ETH amount the Reward's winner will be awarded
	 */
	function claim(uint256 _ethClaim) public
		whenNotGameOver()
		whenNotPaused()
		isOmegaRewardAmount(_ethClaim)
	{
		require(players[_msgSender()].active, "VOXO: Player does not exist");

		// The Reward specifics
		uint256 noKeysRequired;
		// Tier Bronze
		if (_ethClaim == uint256(16)) {
			require(!isBronzeRewardClaimed, "VOXO: Bronze Reward already claimed");
			require(players[_msgSender()].keyids.length >= 3, "VOXO: Player Key collection insufficient for this Reward");
			noKeysRequired = 3;
			removeOmegaKeys(noKeysRequired);
			isBronzeRewardClaimed = true;
		}
		// Tier Silver
		if (_ethClaim == uint256(33))  {
			require(!isSilverRewardClaimed, "VOXO: Silver Reward already claimed");
			require(players[_msgSender()].keyids.length >= 4, "VOXO: Player Key collection insufficient for this Reward");
			noKeysRequired = 4;
			removeOmegaKeys(noKeysRequired);
			isSilverRewardClaimed = true;
		}
		// Tier Gold
		if (_ethClaim == uint256(66))  {
			require(!isGoldRewardClaimed, "VOXO: Gold Reward already claimed");
			require(players[_msgSender()].keyids.length >= 6, "VOXO: Player Key collection insufficient for this Reward");
			noKeysRequired = 6;
			removeOmegaKeys(noKeysRequired);
			isGoldRewardClaimed = true;
		}
		// Tier Diamond
		if (_ethClaim == uint256(135)) {
			require(!isDiamondRewardClaimed, "VOXO: Diamond Reward already claimed");
			require(players[_msgSender()].keyids.length >= 8, "VOXO: Player Key collection insufficient for this Reward");
			noKeysRequired = 8;
			removeOmegaKeys(noKeysRequired);
			isDiamondRewardClaimed = true;
		}

		emit RewardClaimed(_msgSender(), noKeysRequired, _ethClaim);
	}

	/**
	 * @dev Method to remove Omega Keys.
	 * @dev Omega Keys are removed from the game - burned - whenever a Player
	 * @dev uses that Key # to claim a Reward. This method doesn't check the
     * @dev ownership of the VoxoId, as Players can own Omega Keys without
     * @dev still holding the KeyVoxo.
	 * @dev
	 * @dev Omega Keys are removed in the order that they were registered.
	 * @dev Thus, a Player may still have Keys left after removing all the
	 * @dev Keys they used to claim a Reward.
	 * @dev
	 * @param _keys Number of keys to burn
	 */
	function removeOmegaKeys(uint256 _keys) private {
		for (uint i = 0; i < _keys; i++) {
			// Select the Player's oldest remaining Key to burn
			uint256 keyToRemove = players[_msgSender()].keyids[0];
			omegaKeys[keyToRemove].active = false;
			omegaKeys[keyToRemove].removed = true;
			// Remove all owners from that Key
			address[] memory allOwners = omegaKeys[keyToRemove].owners;
			// Likewise, the Omega Key must be removed from all Players whom
			// had previously registered it / added it to their Key Collection.
			for (uint j = 0; j < allOwners.length; j++) {
				players[allOwners[j]].keyids = removeKeyFromPlayer(keyToRemove, allOwners[j]);
				if (players[allOwners[j]].keyids.length > 0) {
					players[allOwners[j]].keyids.pop();
				}
			}
			emit OmegaKeyRemoved(_msgSender(), keyToRemove, _keys, allOwners);
		}
	}

	/**
	 * @dev Method to remove an Omega Key from a Player's Collection.
	 * @param _keyId The Voxo Id / Key # - The Omega Key to remove
	 * @param _player the owner of the Key Collection
	 * @return keyids Player's Collection with the removed Keys removed
	 */
	function removeKeyFromPlayer(uint256 _keyId, address _player) internal view returns (uint256[] memory keyids) {
		keyids = players[_player].keyids;
		uint256 index = keyids.length;
		for (uint i = 0; i < index; i++) {
			if (keyids[i] == _keyId) {
				keyids[i] = keyids[index - 1];
				delete keyids[index - 1];
			}
		}
	 }

	/**
	 * @dev Method reverting the game state following an invalidated Omega Reward Claim
	 * @dev Used exclusively in the unexpected case where a winning claim is found to be fraudulent
	 * @dev or otherwise in conflict with the terms governing a player's participation in the game.
	 * @param _ethReward the ETH payout amount corresponding to an Omega Reward tier
	 */
	function restoreReward(uint256 _ethReward) private
	{
		uint256 noKeysRequired = 0;
		if ((_ethReward == uint256(16)) && (isBronzeRewardClaimed)) {
			isBronzeRewardClaimed = false;
			noKeysRequired = 3;
		}
		if ((_ethReward == uint256(33)) && (isSilverRewardClaimed)) {
			isSilverRewardClaimed = false;
			noKeysRequired = 4;
		}
		if ((_ethReward == uint256(66)) && (isGoldRewardClaimed)) {
			isGoldRewardClaimed = false;
			noKeysRequired = 6;
		}
		if (_ethReward == uint256(135) && (isDiamondRewardClaimed)) {
			isDiamondRewardClaimed = false;
			noKeysRequired = 8;
		}
		emit RewardRestored(noKeysRequired, _ethReward);
	}

	/**
	 * @dev Method to revert a removed Omega Key for all previous Owners
	 * @dev Used exclusively in the unexpected case where a winning claim is found to be fraudulent
	 * @dev or otherwise in conflict with the terms governing a player's participation in the game.
	 * @param _keyIds an Array of Keys #s
	 */
	function revertRewardClaim(uint256 _ethReward, uint256[] memory _keyIds, address _disqualifiedPlayer) public
		onlyOwner()
		whenNotPaused()
		isOmegaRewardAmount(_ethReward)
	{
		// Verify that all the Keys-to-be-restored were previously removed
		for (uint j = 0; j < _keyIds.length; j++) {
			require ((omegaKeys[_keyIds[j]].removed && !omegaKeys[_keyIds[j]].active), "VOXO: Omega Key is not removed");
		}
		// Restore the Reward
		restoreReward(_ethReward);
		// Restore the Keys to the Player's Collection
		for (uint i = 0; i < _keyIds.length; i++) {
			address[] memory oldOwners;
			omegaKeys[_keyIds[i]].owners = removePlayer(_keyIds[i], _disqualifiedPlayer);
			if (omegaKeys[_keyIds[i]].owners.length > 0) {
				omegaKeys[_keyIds[i]].owners.pop();
				oldOwners = omegaKeys[_keyIds[i]].owners;
			}
			omegaKeys[_keyIds[i]] = OmegaKey({
				active: true,
				removed: false,
				keyId: _keyIds[i],
				owners: oldOwners
			});
			// Add Key back to each Owner's Key Collection
			for(uint k = 0; k < omegaKeys[_keyIds[i]].owners.length; k++) {
				players[omegaKeys[_keyIds[i]].owners[k]].keyids.push(_keyIds[i]);
			}
			emit OmegaKeyRestored(omegaKeys[_keyIds[i]].owners, _keyIds[i]);
		}
	}

	/**
	 * @dev Method to verify an Key # is among the released Omega Keys
	 * @param _keyId The Voxo Id / Key #
	 * @return True if the Key # was released, False if not
	 */
	function isKey(uint256 _keyId) public view returns (bool) {
		return omegaKeys[_keyId].active;
	}

	/**
	 * @dev Method to verify that an Omega Key was removed
	 * @param _keyId The Voxo Id / Key #
	 * @return True if the Omega Key was removed, False if not
	 */
	function isRemoved(uint256 _keyId) public view returns (bool) {
		return omegaKeys[_keyId].removed;
	}

	/**
	 * @dev Method to verify an ETH amount has a corresponding Omega Reward
	 * @param _ethReward The ETH amount an Omega Reward pays out
	 * @return True if Omega Reward with that ETH reward exists, False if not
	 */
	function isOmegaReward(uint256 _ethReward) public pure returns (bool) {
		return (_ethReward == uint256(16)) || (_ethReward == uint256(33)) || (_ethReward == uint256(66)) || (_ethReward == uint256(135));
	}

	/**
	 * @dev Method to verify that no Rewards are left unclaimed,
	 * @dev marking the end of the Omega Key Game
	 * @return True if all Reward are unavailable, False if at least one Reward is still available
	 */
	function isGameOver() public view returns (bool) {
		return (isDiamondRewardClaimed && isGoldRewardClaimed && isSilverRewardClaimed && isBronzeRewardClaimed);
	}

	/**
	 * @dev Method to verify that a Player has registered an Omega Key
	 * @param _keyId The Voxo Id / Key #
	 * @return registered True if the Omega Key is registered, False if not
	 */
	function isRegistered(uint256 _keyId, address _owner) internal view isReleased(_keyId) returns (bool registered) {
		registered = false;
		for (uint i = 0; i < omegaKeys[_keyId].owners.length; i++) {
			if (omegaKeys[_keyId].owners[i] == _owner) {
				registered = true;
			}
		}
		return registered;
	}

	/**
	 * @dev Method returning the Player's Key Collection
	 * @param _player The owner of the Key Collection
	 * @return The list of Keys collected (and registered) by the Player
	 */
	function getKeyCollection(address _player) public view returns (uint256[] memory) {
		return players[_player].keyids;
	}

	/**
	 * @dev Method returning the Player's Key Collection size
	 * @param _player The owner of the Key Collection
	 * @return The number of keys collected (and registered) by the Player
	 */
	function getKeyCollectionSize(address _player) public view returns (uint256 ) {
		return players[_player].keyids.length;
	}

	/**
	 * @dev Method returning the Omega Key Collection without disqualified Player
	 * @param _keyIds The Voxo Id / Key #, where the disqualified Player will be removed from
	 * @param _disqualifiedPlayer The disqualifiedPlayer of the Key Collection
	 * @return owners The Omega Key Collection without disqualified Player
	 */
	function removePlayer(uint256 _keyIds, address _disqualifiedPlayer) internal view returns (address[] memory owners) {
		owners = omegaKeys[_keyIds].owners;
		uint256 index = owners.length;
		for (uint i = 0; i < index; i++) {
			if (owners[i] == _disqualifiedPlayer) {
				owners[i] = owners[index - 1];
				delete owners[index - 1];
			}
		}
	}
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

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