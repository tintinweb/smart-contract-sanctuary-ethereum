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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// Inheritas.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/**
*
*  #### ##    ## ##     ## ######## ########  #### ########    ###     ######  
* 	##  ###   ## ##     ## ##       ##     ##  ##     ##      ## ##   ##    ## 
* 	##  ####  ## ##     ## ##       ##     ##  ##     ##     ##   ##  ##       
* 	##  ## ## ## ######### ######   ########   ##     ##    ##     ##  ######  
* 	##  ##  #### ##     ## ##       ##   ##    ##     ##    #########       ## 
* 	##  ##   ### ##     ## ##       ##    ##   ##     ##    ##     ## ##    ## 
*  #### ##    ## ##     ## ######## ##     ## ####    ##    ##     ##  ###### 
*
* 
* 	Inheritas Service
*	
*	Inherit assets in a decentralized way. Inheritas is a service to make assets
*	inheritance easy, safe, fast, cheap and decentralized. Currently the service
*	only accepts ERC721 and ERC1155 NFTs. In the future, support for ERC20 and
*	others will be added.
*
*	How-to
*
*	The mechanism is easy and simple. The owner of an asset should call the active
*	function to register an asset in the service. He/She must set a deadline and a
*	beneficiary. When the deadline will be reached, the beneficiary will be able to
* 	claim the asset calling the claim function. This deadline could be extended and
*	the beneficiary could be changed calling the alive function. Assets never leave
*	the registrants wallet until the beneficiaries claim them.
*
*	Price
*
*	Currently the Inheritas service has a fee of 0.01 ether but an user could buy
*	a lifeTimePass in order to get FREE access to the service paying 0.1 ether.
*	That's your choice, pay 0.01 ether per asset or unlimited assets per 0.1 ether.
*
*	WARNING!
*
*	To avoid assets to reach the unclaimable state: Don't interact with the asset
*	in none of the following ways: transfer, burn, approve, revoke-approval.
*	In case of the asset reached the unclaimable state, please re-approve this 
*	contract as operator. If the contract has no capabilities to transfer the asset,
*	the claim function will revert, making the asset unclaimable.
*
*	Technichal Details
*	
*	This contract relies in the approval feature, the registrant must approve this
*	contract as operator to transfer the asset to the beneficiary when the deadline
*	will be reached, in order to be able to register it in the Inheritas service.
*	If before claims the asset, it's transferred, burnt, or the approval is revoked,
*	the claim function will reverts and the asset will not ever be claimable. The
*	only way to re-activate the asset to be claimable is to set the approval again.
*	Due to the nature of the approval feature in the ERC721, if the registrant
*	approves the asset to another operator, the previously approved operator (this
*	contract), will be revoked making the claim function reverts too and the asset
*	unclaimable. To avoid assets to be unclaimable the right behaviour after a
*	successfully register into the service should be: Don't interact with the
*	asset in none of the following ways: transfer, burn, approve, revoke-approval.
*
*	If you think your asset reached the unclaimable state, just approve this 
*	contract as operator to the asset again. This will fix the unclaimable state, 
* 	making the asset claimable again.
*
*	Devs & Security Contact
*	
*	Tag Me on the Alchemy University discord to comment anything about the code!
*						@MaestroCripto @J.Valeska
**/

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error InvalidParams();
error FeePriceError();
error Forbidden();
error NotApproved();

contract Inheritas is Ownable, ReentrancyGuard {
	using Counters for Counters.Counter;	
	
	uint serviceFee = 0.01 ether;		// A fee must be paid to use the service
	uint lifeTimePassPrice = 0.1 ether;	// The price of a lifeTimePass to the Inheritas service
	
	// Keep track of the type of assets allowed by the Inheritas service
	enum assetType {
		ERC721,
		ERC1155
	}
	// Store info about an asset registered into the Inheritas service
	struct Asset {
		uint assetID;				// The assetID to identify the asset in the service
		uint deadline;				// The deadline to claim the asset by the beneficiary
		address owner;				// Owner/operator registering the asset in the service
		address beneficiary;		// The beneficiary of the asset after the deadline
		address contractAddress;	// The contract address of the asset
		uint tokenID;				// The tokenID of the asset in its contract
		assetType erc;				// The ERC of the asset
	}
	
	// Keep track of every asset registered in the Inheritas service by ID
	mapping (uint256 => Asset) public assets;
	// Keep track of the address of every LifeTime Pass buyer
	mapping (address => bool) public lifeTimePass;
	// The total number of assets registered into the service, claimed ones included
	Counters.Counter public _totalAssets;
	// The total number of assets claimed using the service
	Counters.Counter public _claimedAssets;
	
	// Emit an event after successfully register an asset into the service
	event NewAsset(
		uint assetID,
		uint deadline,
		address indexed owner,
		address indexed beneficiary,
		address indexed contractAddress,
		uint tokenID,
		assetType erc
	);
	// Emit an event after successfully update an asset registered into the service
	event Alive(
		uint assetID,
		uint deadline,
		address indexed owner,
		address indexed beneficiary,
		address indexed contractAddress,
		uint tokenID,
		assetType erc
	);
	// Emit an event after successfully claim an asset from the service
	event Claimed(
		uint assetID,
		address indexed from,
		address indexed to,
		address indexed contractAddress,
		uint tokenID,
		assetType erc
	);
	// Emit an event after successfully buy a LifeTime Pass to the service
	event LifeTimePassSold(address indexed buyer);
	// Emit an event after successfully revoke a LifeTime Pass
	event LifeTimePassRevoked(address indexed banned);
	
	constructor () {
		// Set contract deployer as owner and beneficiary from fees
		transferOwnership(msg.sender);
	}
	
	// Register the specified asset into the Inheritas service
	function active(
		uint _deadline, 
		address _beneficiary, 
		address _assetContract, 
		uint _assetID, 
		assetType _assetType
	) external payable nonReentrant {
		
		if (block.timestamp > _deadline) revert InvalidParams();
		if (_beneficiary == address(0)) revert InvalidParams();
		if (_assetContract == address(0)) revert InvalidParams();
		if (!lifeTimePass[msg.sender]) {
			if (msg.value != serviceFee) revert FeePriceError();
		}
		if (!_isApproved(_assetContract, _assetID, _assetType, msg.sender)) revert NotApproved();
		// Increment total assets count...
		_totalAssets.increment();
		// ... and use the current value as assetID
		//uint256 assetID = _totalAssets.current();
		// Using the hash make things easier to the frontend and the users
		uint256 assetID = uint(keccak256(abi.encodePacked(_assetContract, _assetID)));
		// Store info about the new registered asset
		assets[assetID] = Asset(
			assetID,
			_deadline,
			msg.sender,
			_beneficiary,
			_assetContract,
			_assetID,
			_assetType
		);
		
		// Emit an event after successfully register an asset into the service
		emit NewAsset(
			assetID,
			_deadline,
			msg.sender,
			_beneficiary,
			_assetContract,
			_assetID,
			_assetType
		);
	}
	
	// Extends the current deadline and/or change the beneficiary
	function alive(uint256 _assetID, uint _deadline, address _beneficiary) nonReentrant external {
		if (assets[_assetID].owner != msg.sender) revert Forbidden();
		if (block.timestamp > _deadline) revert InvalidParams();
		if (_beneficiary == address(0)) revert InvalidParams();
		// Update the deadline and the beneficiary, even if they did not change
		assets[_assetID].deadline = _deadline;
		assets[_assetID].beneficiary = _beneficiary;
		
		emit Alive(
			_assetID,
			_deadline,
			msg.sender,
			_beneficiary,
			assets[_assetID].contractAddress,
			assets[_assetID].tokenID,
			assets[_assetID].erc		
		);
		// A registrant still could call this function after transferring the asset,
		// but it will just be a waste of gas, the claim function will revert.
		// The same applies to burn, revoke approval, approve another operator...
	}
	
	// The beneficiary will be able to claim the asset after reach the deadline
	// This function will revert if the registrant tranfers, burns, revokes
	// approval, approves another operator, and/or asset is not claimable
	function claim(uint256 _assetID) external nonReentrant {
		if (!_isClaimable(_assetID, msg.sender)) revert Forbidden();
		
		// Checks if an asset is an ERC721
		if (assets[_assetID].erc == assetType.ERC721) {
			// Transfers the asset to the beneficiary
			IERC721(assets[_assetID].contractAddress)
				.safeTransferFrom(
					assets[_assetID].owner,
					assets[_assetID].beneficiary,
					assets[_assetID].tokenID
			);		
		}

		// Checks if an asset is an ERC1155
		if (assets[_assetID].erc == assetType.ERC1155) {
			// Transfers the asset to the beneficiary
			IERC1155(assets[_assetID].contractAddress)
				.safeTransferFrom(
					assets[_assetID].owner,
					assets[_assetID].beneficiary,
					assets[_assetID].tokenID,
					1,
					""
			);
		}

		// Emit an event after successfully claim an asset
		emit Claimed(
			_assetID,
			assets[_assetID].owner,
			assets[_assetID].beneficiary,
			assets[_assetID].contractAddress,
			assets[_assetID].tokenID,
			assets[_assetID].erc
		);
		
		// Increment the total claimed assets count
		_claimedAssets.increment();
		// Remove the asset from the Inheritas service registry
		delete assets[_assetID];
	}
	
	// A registrant may cancel the service to an specified asset
	function remove(uint _assetID) external {
		if (assets[_assetID].owner != msg.sender) revert Forbidden();
		delete assets[_assetID];
	}
	
	// Users may buy a LifeTimePass to get FREE access to the service
	function buyLifeTimePass() external payable {
		require(!lifeTimePass[msg.sender], "Already have a LifeTime Pass!");
		if (msg.value != lifeTimePassPrice) revert FeePriceError();
		lifeTimePass[msg.sender] = true;
		emit LifeTimePassSold(msg.sender);
	}

	// Check whether an asset is claimable or not based in deadline & beneficiary
	function _isClaimable(uint _assetID, address _beneficiary) internal view returns (bool) {
		return block.timestamp > assets[_assetID].deadline && 
				_beneficiary == assets[_assetID].beneficiary;
	}
	
	// Checks for approvals after check whether it is an ERC721 or ERC1155 asset
	function _isApproved(address _assetContract, uint _assetID, assetType _assetType, address _by) internal view returns (bool) {
		// Check if asset is an ERC721
		if (_assetType == assetType.ERC721) {
			IERC721 iface = IERC721(_assetContract);
			// Check if the contract is approved to transfer the token
			return iface.ownerOf(_assetID) == _by &&
					iface.getApproved(_assetID) == address(this);
		}
		// Check if asset is an ERC115
		if (_assetType == assetType.ERC1155) {
			IERC1155 iface = IERC1155(_assetContract);
			// Check if the contract is approved to transfer the token
			return iface.balanceOf(_by, _assetID) > 0 &&
					iface.isApprovedForAll(_by, address(this));	
		}
		return false;
		// This works with assets using the ERC721/ERC1155 OpenZeppelin Standards
		// A mallory could bypass this function, but this is here to protect users
		// from register assets without approve them before. The security of
		// the contract will not be affected if this function is bypassed.
		// ERC721 reverts if sender isn't the owner or approved, tokenId does
		// not exist, contract is not approved.
		// ERC1155 will do in theses cases, excluding the tokenID

	}
	
	// The owner is able to change the serviceFee and the lifeTimePassPrice
	function setPrices(uint _serviceFee, uint _lifeTimePassPrice) public onlyOwner {
		serviceFee = _serviceFee;
		lifeTimePassPrice = _lifeTimePassPrice;
	}
	
	// Security function to ban malicious users. If the owner abuse it, users could
	// stop to register assets into the service, while the claim function will be
	// continously working without problems. This incentives the owner to non abuse.
	function revokeLifeTimePass(address banedUser) public onlyOwner {
		lifeTimePass[banedUser] = false;
	}
	
	
	// Withdraw contract funds (onlyOwner)
	function withdraw() public onlyOwner {
		(bool sent, ) = payable(owner()).call{ value: address(this).balance }("");
		require(sent);
	}
	// Receive fallback
	event Received(address indexed sender, uint amount);
	receive() external payable {
		emit Received(msg.sender, msg.value);
	}
}