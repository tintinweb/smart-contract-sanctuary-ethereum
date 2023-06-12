// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {ITaxHandler} from "./interfaces/ITaxHandler.sol";
import {IPoolManager} from "./interfaces/IPoolManager.sol";

contract WarpedTaxHandler is ITaxHandler, Ownable {
	/// @notice NFTs to be used to determine user tax level.
	IERC721[] public nftContracts;
	/// @notice Bits representing levels of each NFTs: 1,2,4,8
	mapping(IERC721 => uint8) public nftLevels;

	struct TaxRatePoint {
		uint256 threshold;
		uint256 rate;
	}

	TaxRatePoint[] public taxRates;
	uint256 public basisTaxRate;
	uint256 public maxTaxRate = 400;
	bool public taxDisabled;
	IPoolManager public poolManager;

	/// @notice Constructor of tax handler contract
	/// @param _poolManager exchange pool manager address
	/// @param _nftContracts array of addresses of NFT contracts
	/// @param _levels array of levels of NFT contracts
	constructor(
		IPoolManager _poolManager,
		address[] memory _nftContracts,
		uint8[] memory _levels
	) {
		poolManager = _poolManager;

		_addNFTs(_nftContracts, _levels);
		// init default tax rates
		basisTaxRate = 400;
		taxRates.push(TaxRatePoint(7, 100));
		taxRates.push(TaxRatePoint(5, 200));
		taxRates.push(TaxRatePoint(1, 300));
		taxDisabled = false;
	}

	/**
	 * @notice Get number of tokens to pay as tax.
	 * @dev There is no easy way to differentiate between a user swapping
	 * tokens and a user adding or removing liquidity to the pool. In both
	 * cases tokens are transferred to or from the pool. This is an unfortunate
	 * case where users have to accept being taxed on liquidity additions and
	 * removal. To get around this issue a separate liquidity addition contract
	 * can be deployed. This contract could be exempt from taxes if its
	 * functionality is verified to only add and remove liquidity.
	 * @param benefactor Address of the benefactor.
	 * @param beneficiary Address of the beneficiary.
	 * @param amount Number of tokens in the transfer.
	 * @return taxAmount Number of tokens for tax
	 */
	function getTax(
		address benefactor,
		address beneficiary,
		uint256 amount
	) external view override returns (uint256) {
		if (taxDisabled) {
			return 0;
		}

		// Transactions between regular users (this includes contracts) aren't taxed.
		if (
			!poolManager.isPoolAddress(benefactor) &&
			!poolManager.isPoolAddress(beneficiary)
		) {
			return 0;
		}

		// Transactions between pools aren't taxed.
		if (
			poolManager.isPoolAddress(benefactor) &&
			poolManager.isPoolAddress(beneficiary)
		) {
			return 0;
		}

		uint256 taxRate = 0;
		// If the benefactor is found in the set of exchange pools, then it's a buy transactions, otherwise a sell
		// transactions, because the other use cases have already been checked above.
		if (poolManager.isPoolAddress(benefactor)) {
			taxRate = _getTaxBasisPoints(beneficiary);
		} else {
			taxRate = _getTaxBasisPoints(benefactor);
		}

		return (amount * taxRate) / 10000;
	}

	/**
	 * @notice Reset tax rate points.
	 * @param thresholds of user level.
	 * @param rates of tax per each threshold.
	 * @param _basisTaxRate basis tax rate.
	 *
	 * Requirements:
	 *
	 * - values of `thresholds` must be placed in ascending order.
	 */
	function setTaxRates(
		uint256[] memory thresholds,
		uint256[] memory rates,
		uint256 _basisTaxRate
	) external onlyOwner {
		require(thresholds.length == rates.length, "Invalid level points");
		require(_basisTaxRate > 0, "Invalid base rate");
		require(_basisTaxRate <= maxTaxRate, "Base rate must be <= than max");

		delete taxRates;
		for (uint256 i = 0; i < thresholds.length; i++) {
			require(rates[i] <= maxTaxRate, "Rate must be less than max rate");
			taxRates.push(TaxRatePoint(thresholds[i], rates[i]));
		}
		basisTaxRate = _basisTaxRate;
	}

	/**
	 * @notice Add addresses and their levels of NFTs(only ERC721).
	 * @dev For future NFT launch, allow to add new NFT addresses and levels.
	 * @param contracts NFT contract addresses.
	 * @param levels NFT contract levels to be used for user level calculation.
	 */
	function addNFTs(
		address[] memory contracts,
		uint8[] memory levels
	) external onlyOwner {
		require(contracts.length > 0 && levels.length > 0, "Invalid parameters");
		_addNFTs(contracts, levels);
	}

	/**
	 * @notice Remove nft level by address.
	 * @param contracts NFT contract addresses.
	 */
	function removeNFTs(address[] memory contracts) external onlyOwner {
		require(contracts.length > 0, "Invalid parameters");
		for (uint8 i = 0; i < contracts.length; i++) {
			for (uint8 j = 0; j < nftContracts.length; j++) {
				if (address(nftContracts[j]) == contracts[i]) {
					delete nftContracts[j];
					break;
				}
			}
			nftLevels[IERC721(contracts[i])] = 0;
		}
	}

	/**
	 * @notice Set no tax for special period
	 */
	function pauseTax() external onlyOwner {
		require(!taxDisabled, "Already paused");
		taxDisabled = true;
	}

	/**
	 * @notice Resume tax handling
	 */
	function resumeTax() external onlyOwner {
		require(taxDisabled, "Not paused");
		taxDisabled = false;
	}

	/**
	 * @notice Get percent of tax to pay for the given user.
	 * @dev Basis tax percent will be varied based on user's ownership of NFTs
	 * in the STARL metaverse. There are 3 user levels and user's level will be
	 * determined by bit-or of nft levels he owned.
	 * SATE: 8(4th bit), LM/LMvX: 4(3rd bit), PAL: 2(2nd bit), PN: 1(first bit)
	 * bit-or >= 7 : 1%
	 * bit-or >= 5 : 2%
	 * bit-or >= 1 : 3%
	 * @param user Address of user(buyer/seller address).
	 * @return Number Basis tax percent in 2 decimal.
	 */
	function _getTaxBasisPoints(address user) internal view returns (uint256) {
		uint256 userLevel = 0;
		for (uint256 i = 0; i < nftContracts.length; i++) {
			IERC721 nft = nftContracts[i];
			if (nft.balanceOf(user) > 0) {
				userLevel = userLevel | nftLevels[nftContracts[i]];
			}
		}
		for (uint256 i = 0; i < taxRates.length; i++) {
			if (userLevel >= taxRates[i].threshold) {
				return taxRates[i].rate;
			}
		}
		return basisTaxRate;
	}

	function _addNFTs(
		address[] memory contracts,
		uint8[] memory levels
	) internal {
		require(contracts.length == levels.length, "Invalid parameters");

		for (uint8 i = 0; i < contracts.length; i++) {
			require(IERC165(contracts[i]).supportsInterface(type(IERC721).interfaceId), "IERC721 not implemented");

			nftContracts.push(IERC721(contracts[i]));
			nftLevels[IERC721(contracts[i])] = levels[i];
		}
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

// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

/**
 * @title Exchange pool processor abstract contract.
 * @dev Keeps an enumerable set of designated exchange addresses as well as a single primary pool address.
 */
interface IPoolManager {
	/// @notice Primary exchange pool address.
	function primaryPool() external view returns (address);

	/**
	 * @notice Check if the given address is pool address.
	 * @param addr Address to check.
	 * @return bool True if the given address is pool address.
	 */
	function isPoolAddress(address addr) external view returns (bool);
}

// SPDX-License-Identifier: MIT

/**
 __      __  _____ _______________________________________   
/  \    /  \/  _  \\______   \______   \_   _____/\______ \  
\   \/\/   /  /_\  \|       _/|     ___/|    __)_  |    |  \ 
 \        /    |    \    |   \|    |    |        \ |    `   \
  \__/\  /\____|__  /____|_  /|____|   /_______  //_______  /
       \/         \/       \/                  \/         \/ 
 */

pragma solidity ^0.8.18;

interface ITaxHandler {
	/**
	 * @notice Get number of tokens to pay as tax.
	 * @param benefactor Address of the benefactor.
	 * @param beneficiary Address of the beneficiary.
	 * @param amount Number of tokens in the transfer.
	 * @return taxAmount Number of tokens for tax.
	 */
	function getTax(
		address benefactor,
		address beneficiary,
		uint256 amount
	) external view returns (uint256);
}