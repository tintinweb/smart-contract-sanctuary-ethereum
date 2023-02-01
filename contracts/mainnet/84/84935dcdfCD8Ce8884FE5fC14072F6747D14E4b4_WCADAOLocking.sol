/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/WCADAOLocking.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;





contract WCADAOLocking is Ownable, ERC721Holder {
	IWCATokensAggregator public WCATokensAggregator;
	IWWCA public WWCA;
	IERC20 public WCAToken;
	IERC721Enumerable public WCANFT;
	IERC721Enumerable public WCAMUNDIAL;
	IERC721Enumerable public WCAVIP;

	string public constant version = "0.1";

	enum Collection {
		WCA,
		MUNDIAL,
		VIP
	}

	struct NFT {
		Collection collection;
		uint256 id;
		uint256 stakedTimestamp;
		uint256 unstakedTimestamp;
	}

	struct Tokens {
		uint256 amount;
		uint256 stakedTimestamp;
		uint256 unstakedTimestamp;
	}

	mapping(address => NFT[]) public stakerToNFTs;
	mapping(address => Tokens[]) public stakerToTokens;
	// Amount of tokens locked and their origin
	mapping(address => uint256) public stakerToLockedTokensFromStaking;
	mapping(address => uint256) public stakerToLockedTokensFromWallet;
	address[] public stakers;

	constructor() {}

	function setContracts(
		address _WCATokensAggregator,
		address _WCAToken,
		address _WCANFT,
		address _WCAMUNDIAL,
		address _WCAVIP,
		address _WWCA
	) external onlyOwner {
		WCATokensAggregator = IWCATokensAggregator(_WCATokensAggregator);
		WCAToken = IERC20(_WCAToken);
		WCANFT = IERC721Enumerable(_WCANFT);
		WCAMUNDIAL = IERC721Enumerable(_WCAMUNDIAL);
		WCAVIP = IERC721Enumerable(_WCAVIP);
		WWCA = IWWCA(_WWCA);
	}

	function getLockedNFTs(address _address) external view returns (NFT[] memory) {
		return stakerToNFTs[_address];
	}

	function getLockedTokens(address _address) external view returns (Tokens[] memory) {
		return stakerToTokens[_address];
	}

	function getLockedTokensFromStaking(address _address) external view returns (uint256) {
		return stakerToLockedTokensFromStaking[_address];
	}

	function getLockedTokensFromWallet(address _address) external view returns (uint256) {
		return stakerToLockedTokensFromWallet[_address];
	}

	function getStakers() external view returns (address[] memory) {
		return stakers;
	}

	function lock(NFT[] calldata nfts, uint256 tokensAmount) external {
		// NFTS
		for (uint256 i = 0; i < nfts.length; i++) {
			// Get collection ERC721
			IERC721 nftCollection;
			if (nfts[i].collection == Collection.WCA) {
				nftCollection = WCANFT;
			} else if (nfts[i].collection == Collection.MUNDIAL) {
				nftCollection = WCAMUNDIAL;
			} else if (nfts[i].collection == Collection.VIP) {
				nftCollection = WCAVIP;
			}

			NFT memory nft = nfts[i];
			nft.stakedTimestamp = block.timestamp;
			nft.unstakedTimestamp = 0;

			// Check if nfts are ok
			require(nftCollection.ownerOf(nft.id) == msg.sender, "You don't own this token");

			// Transfer and store NFTs
			nftCollection.transferFrom(msg.sender, address(this), nft.id);
			stakerToNFTs[msg.sender].push(nft);
		}

		// TOKENS
		if (tokensAmount > 0) {
			require(WCATokensAggregator.balanceOf(msg.sender) >= tokensAmount, "You haven't enough $WCA");
			// If has already locked tokens in other contracts use them
			uint256 availableToLockBalance = 0;
			if (WCATokensAggregator.stakedBalanceOf(msg.sender) > stakerToLockedTokensFromStaking[msg.sender]) {
				availableToLockBalance = WCATokensAggregator.stakedBalanceOf(msg.sender) - stakerToLockedTokensFromStaking[msg.sender];
			}

			if (availableToLockBalance >= tokensAmount) {
				stakerToLockedTokensFromStaking[msg.sender] += tokensAmount;
				Tokens memory tokens = Tokens(tokensAmount, block.timestamp, 0);
				stakerToTokens[msg.sender].push(tokens);
			} else {
				uint256 tokenFromWallet = tokensAmount - availableToLockBalance;

				WCAToken.transferFrom(msg.sender, address(this), tokenFromWallet);

				stakerToLockedTokensFromStaking[msg.sender] += availableToLockBalance;
				stakerToLockedTokensFromWallet[msg.sender] += tokenFromWallet;

				Tokens memory tokens = Tokens(tokensAmount, block.timestamp, 0);
				stakerToTokens[msg.sender].push(tokens);
			}
		}

		// Add staker to array
		if (nfts.length > 0 || tokensAmount > 0) {
			stakers.push(msg.sender);
			// Update WWCA
			WWCA.updateWWCAByAddress(msg.sender);
		}
	}

	function unlock() external {
		IWWCA.WWCAAmount memory wwcaAmount = WWCA.WWCAOfAddress(msg.sender);
		uint256 wwcaToApplyFees = wwcaAmount.wwcaToken + wwcaAmount.wwcaNFT;
		uint256 lastStakeTimestamp;
		// Unlock NFTs
		for (uint256 i; i < stakerToNFTs[msg.sender].length; i++) {
			NFT memory nft = stakerToNFTs[msg.sender][i];
			// Get collection ERC721
			IERC721 nftCollection;
			if (nft.collection == Collection.WCA) {
				nftCollection = WCANFT;
			} else if (nft.collection == Collection.MUNDIAL) {
				nftCollection = WCAMUNDIAL;
			} else if (nft.collection == Collection.VIP) {
				nftCollection = WCAVIP;
			}
			if (lastStakeTimestamp < nft.stakedTimestamp) {
				lastStakeTimestamp = stakerToNFTs[msg.sender][i].stakedTimestamp;
			}
			stakerToNFTs[msg.sender][i].unstakedTimestamp = block.timestamp;
			nftCollection.transferFrom(address(this), msg.sender, nft.id);
		}
		// Unlock Tokens
		for (uint256 i; i < stakerToTokens[msg.sender].length; i++) {
			if (lastStakeTimestamp < stakerToTokens[msg.sender][i].stakedTimestamp) {
				lastStakeTimestamp = stakerToTokens[msg.sender][i].stakedTimestamp;
			}
			stakerToTokens[msg.sender][i].unstakedTimestamp = block.timestamp;
			stakerToLockedTokensFromStaking[msg.sender] = 0;
			uint256 tokenFromWallet = stakerToLockedTokensFromWallet[msg.sender];
			stakerToLockedTokensFromWallet[msg.sender] = 0;
			WCAToken.transfer(msg.sender, tokenFromWallet);
		}

		// Remove staker from array
		removeAddressFromArray(stakers, msg.sender);
		// Update WWCA
		WWCA.updateWWCAByAddress(msg.sender);

		// Calculate fees
		uint256 fees;
		if (lastStakeTimestamp >= block.timestamp - 90 days) {
			fees = (wwcaToApplyFees * 30) / 100;
		} else if (lastStakeTimestamp >= block.timestamp - 180 days) {
			fees = (wwcaToApplyFees * 20) / 100;
		} else if (lastStakeTimestamp >= block.timestamp - 270 days) {
			fees = (wwcaToApplyFees * 10) / 100;
		} else if (lastStakeTimestamp >= block.timestamp - 360 days) {
			fees = (wwcaToApplyFees * 5) / 100;
		}
		if (fees > 0) {
			WCAToken.transferFrom(msg.sender, owner(), fees);
		}
	}

	// Withdraw NFTs
	function panicWithdrawNFTs() external onlyOwner {
		uint256 tokenCount = WCANFT.balanceOf(address(this));
		for (uint256 i = 0; i < tokenCount; i++) {
			WCANFT.transferFrom(address(this), owner(), WCANFT.tokenOfOwnerByIndex(address(this), 0));
		}
		tokenCount = WCAMUNDIAL.balanceOf(address(this));
		for (uint256 i = 0; i < tokenCount; i++) {
			WCAMUNDIAL.transferFrom(address(this), owner(), WCAMUNDIAL.tokenOfOwnerByIndex(address(this), 0));
		}
		tokenCount = WCAVIP.balanceOf(address(this));
		for (uint256 i = 0; i < tokenCount; i++) {
			WCAVIP.transferFrom(address(this), owner(), WCAVIP.tokenOfOwnerByIndex(address(this), 0));
		}
	}

	// Withdraw Tokens
	function panicWithdrawTokens() external onlyOwner {
		WCAToken.transfer(owner(), WCAToken.balanceOf(address(this)));
	}

	function removeAddressFromArray(address[] storage array, address _address) internal {
		for (uint256 i = 0; i < array.length; i++) {
			if (array[i] == _address) {
				if (i < array.length - 1) {
					array[i] = array[array.length - 1];
				}
				array.pop();
				break;
			}
		}
	}
}

interface IWWCA {
	struct WWCAAmount {
		uint256 wwcaToken;
		uint256 wwcaNFT;
		uint256 wwcaBonus;
	}

	function WWCAOfAddress(address _address) external view returns (WWCAAmount memory);

	function updateWWCAByAddress(address _address) external;
}

interface IWCATokensAggregator {
	function balanceOf(address _address) external view returns (uint256);

	function stakedBalanceOf(address _address) external view returns (uint256);
}