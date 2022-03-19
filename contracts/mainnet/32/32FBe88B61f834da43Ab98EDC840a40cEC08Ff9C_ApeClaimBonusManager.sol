// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "Ownable.sol";
import "IERC721Enumerable.sol";
import "IERC20.sol";
import"ApeClaimBonus.sol";

interface IClaim {
	function claim() external;
}

contract ApeClaimBonusManager is Ownable {
	IGrape public constant GRAPE = IGrape(0x025C6da5BD0e6A5dd1350fda9e3B6a614B205a1F);
	IERC20 public constant APE = IERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381);
	IERC721Enumerable public constant ALPHA = IERC721Enumerable(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
	IERC721Enumerable public constant BETA = IERC721Enumerable(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
	IERC721Enumerable public constant GAMMA = IERC721Enumerable(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623);

	uint256 constant ALPHA_SHARE = 10094 ether;
	uint256 constant BETA_SHARE = 2042 ether;
	uint256 constant GAMMA_SHARE = 856 ether;

	uint256 constant A_B_COMMS = 45;
	uint256 constant G_COMMS = 45;
	uint256 constant OUR_COMMS = 10;

	bool setup;
	address public claimer;
	mapping(address => mapping(uint256 => address)) public assetToUser;

	event AlphaDeposited(address indexed user, uint256 tokenId);
	event BetaDeposited(address indexed user, uint256 tokenId);
	event GammaDeposited(address indexed user, uint256 tokenId);

	event AlphaWithdrawn(address indexed user, uint256 tokenId);
	event BetaWithdrawn(address indexed user, uint256 tokenId);
	event GammaWithdrawn(address indexed user, uint256 tokenId);

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	function init(address _claimer) external onlyOwner {
		require(!setup);
		setup = true;
		claimer = _claimer;
	}

	function fetchApe() external onlyOwner {
		APE.transfer(msg.sender, APE.balanceOf(address(this)));
	}

	// In the case a user sends an asset directly to the contract...
	function rescueAsset(address _asset, uint256 _tokenId, address _recipient) external onlyOwner {
		require(assetToUser[_asset][_tokenId] == address(0), "Can't steal");
		IERC721Enumerable(_asset).transferFrom(address(this), _recipient, _tokenId);
	}

	function depositAlpha(uint256[] calldata _alphas) external {
		uint256 gammaBalance = GAMMA.balanceOf(address(this));
		uint256 toSwap = min(gammaBalance, _alphas.length);

		for (uint256 i = 0; i < toSwap; i++) {
			require(!GRAPE.alphaClaimed(_alphas[i]), "Alpha already claimed");
			ALPHA.transferFrom(msg.sender, claimer, _alphas[i]);
			GAMMA.transferFrom(address(this), claimer, GAMMA.tokenOfOwnerByIndex(address(this), 0));
		}
		if (toSwap > 0)
			IClaim(claimer).claim();
		for (uint256 i = 0; i < toSwap; i++) {
			uint256 gammaTokenId = GAMMA.tokenOfOwnerByIndex(claimer, 0);
			address gammaOwner = assetToUser[address(GAMMA)][gammaTokenId];

			delete assetToUser[address(GAMMA)][gammaTokenId];
			GAMMA.transferFrom(claimer, gammaOwner, gammaTokenId);
			emit GammaWithdrawn(gammaOwner, gammaTokenId);
			APE.transfer(gammaOwner, GAMMA_SHARE * G_COMMS / 100);
			ALPHA.transferFrom(claimer, msg.sender, _alphas[i]);
		}
		for (uint256 i = toSwap; i < _alphas.length; i++) {
			require(!GRAPE.alphaClaimed(_alphas[i]), "Alpha already claimed");
			ALPHA.transferFrom(msg.sender, address(this), _alphas[i]);
			assetToUser[address(ALPHA)][_alphas[i]] = msg.sender;
			emit AlphaDeposited(msg.sender, _alphas[i]);
		}
		if (toSwap > 0)
			APE.transfer(msg.sender, toSwap * (ALPHA_SHARE + GAMMA_SHARE * A_B_COMMS / 100));
	}

	function depositBeta(uint256[] calldata _betas) external {
		uint256 gammaBalance = GAMMA.balanceOf(address(this));
		uint256 toSwap = min(gammaBalance, _betas.length);

		for (uint256 i = 0; i < toSwap; i++) {
			require(!GRAPE.betaClaimed(_betas[i]), "Beta already claimed");
			BETA.transferFrom(msg.sender, claimer, _betas[i]);
			GAMMA.transferFrom(address(this), claimer, GAMMA.tokenOfOwnerByIndex(address(this), 0));
		}
		if (toSwap > 0)
			IClaim(claimer).claim();
		for (uint256 i = 0; i < toSwap; i++) {
			uint256 gammaTokenId = GAMMA.tokenOfOwnerByIndex(claimer, 0);
			address gammaOwner = assetToUser[address(GAMMA)][gammaTokenId];

			delete assetToUser[address(GAMMA)][gammaTokenId];
			GAMMA.transferFrom(claimer, gammaOwner, gammaTokenId);
			emit GammaWithdrawn(gammaOwner, gammaTokenId);
			APE.transfer(gammaOwner, GAMMA_SHARE * G_COMMS / 100);
			BETA.transferFrom(claimer, msg.sender, _betas[i]);
		}
		for (uint256 i = toSwap; i < _betas.length; i++) {
			require(!GRAPE.betaClaimed(_betas[i]), "Beta already claimed");
			BETA.transferFrom(msg.sender, address(this), _betas[i]);
			assetToUser[address(BETA)][_betas[i]] = msg.sender;
			emit BetaDeposited(msg.sender, _betas[i]);
		}
		if (toSwap > 0)
			APE.transfer(msg.sender, toSwap * (BETA_SHARE + GAMMA_SHARE * A_B_COMMS / 100));
	}

	function depositGamma(uint256[] calldata _gammas) external {
		uint256 alphaBalance = ALPHA.balanceOf(address(this));
		uint256 betaBalance = BETA.balanceOf(address(this));
		uint256 alphaToSwap = min(alphaBalance, _gammas.length);
		uint256 betaToSwap = min(betaBalance, _gammas.length - alphaToSwap);

		for (uint256 i = 0; i < alphaToSwap; i++) {
			require(!GRAPE.gammaClaimed(_gammas[i]), "Gamma already claimed");
			GAMMA.transferFrom(msg.sender, claimer, _gammas[i]);
			ALPHA.transferFrom(address(this), claimer, ALPHA.tokenOfOwnerByIndex(address(this), 0));
		}
		for (uint256 i = 0; i < betaToSwap; i++) {
			require(!GRAPE.gammaClaimed(_gammas[i + alphaToSwap]), "Gamma already claimed");
			GAMMA.transferFrom(msg.sender, claimer, _gammas[i + alphaToSwap]);
			BETA.transferFrom(address(this), claimer, BETA.tokenOfOwnerByIndex(address(this), 0));
		}
		if (alphaToSwap + betaToSwap > 0)
			IClaim(claimer).claim();
		for (uint256 i = 0; i < alphaToSwap; i++) {
			uint256 alphaTokenId = ALPHA.tokenOfOwnerByIndex(claimer, 0);
			address alphaOwner = assetToUser[address(ALPHA)][alphaTokenId];

			delete assetToUser[address(ALPHA)][alphaTokenId];
			ALPHA.transferFrom(claimer, alphaOwner, alphaTokenId);
			emit AlphaWithdrawn(alphaOwner, alphaTokenId);
			APE.transfer(alphaOwner, ALPHA_SHARE + GAMMA_SHARE * A_B_COMMS / 100);
			GAMMA.transferFrom(claimer, msg.sender, _gammas[i]);
		}
		for (uint256 i = 0; i < betaToSwap; i++) {
			uint256 betaTokenId = BETA.tokenOfOwnerByIndex(claimer, 0);
			address betaOwner = assetToUser[address(BETA)][betaTokenId];

			delete assetToUser[address(BETA)][betaTokenId];
			BETA.transferFrom(claimer, betaOwner, betaTokenId);
			emit BetaWithdrawn(betaOwner, betaTokenId);
			APE.transfer(betaOwner, BETA_SHARE + GAMMA_SHARE * A_B_COMMS / 100);
			GAMMA.transferFrom(claimer, msg.sender, _gammas[i + alphaToSwap]);
		}
		for (uint256 i = alphaToSwap + betaToSwap; i < _gammas.length; i++) {
			require(!GRAPE.gammaClaimed(_gammas[i]), "Gamma already claimed");
			assetToUser[address(GAMMA)][_gammas[i]] = msg.sender;
			GAMMA.transferFrom(msg.sender, address(this), _gammas[i]);
			emit GammaDeposited(msg.sender, _gammas[i]);
		}
		if (alphaToSwap + betaToSwap > 0)
			APE.transfer(msg.sender, (alphaToSwap + betaToSwap) * (GAMMA_SHARE * G_COMMS / 100));
	}

	function withdrawAlpha(uint256[] calldata _alphas) external {
		for (uint256 i = 0; i < _alphas.length; i++) {
			require(assetToUser[address(ALPHA)][_alphas[i]] == msg.sender, "!owner");
			delete assetToUser[address(ALPHA)][_alphas[i]];
			ALPHA.transferFrom(address(this), msg.sender, _alphas[i]);
			emit AlphaWithdrawn(msg.sender, _alphas[i]);
		}
	}

	function withdrawBeta(uint256[] calldata _betas) external {
		for (uint256 i = 0; i < _betas.length; i++) {
			require(assetToUser[address(BETA)][_betas[i]] == msg.sender, "!owner");
			delete assetToUser[address(BETA)][_betas[i]];
			BETA.transferFrom(address(this), msg.sender, _betas[i]);
			emit BetaWithdrawn(msg.sender, _betas[i]);
		}
	}

	function withdrawGamma(uint256[] calldata _gammas) external {
		for (uint256 i = 0; i < _gammas.length; i++) {
			require(assetToUser[address(GAMMA)][_gammas[i]] == msg.sender, "!owner");
			delete assetToUser[address(GAMMA)][_gammas[i]];
			GAMMA.transferFrom(address(this), msg.sender, _gammas[i]);
			emit GammaWithdrawn(msg.sender, _gammas[i]);
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC721.sol";

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "Ownable.sol";
import "IERC721Enumerable.sol";
import "IERC20.sol";

interface IGrape {
	function claimTokens() external;
	function alphaClaimed(uint256) external view returns(bool);
	function betaClaimed(uint256) external view returns(bool);
	function gammaClaimed(uint256) external view returns(bool);
}

contract ApeClaimBonus is Ownable {

	IGrape public constant GRAPE = IGrape(0x025C6da5BD0e6A5dd1350fda9e3B6a614B205a1F);
	IERC20 public constant APE = IERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381);
	IERC721Enumerable public constant ALPHA = IERC721Enumerable(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
	IERC721Enumerable public constant BETA = IERC721Enumerable(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
	IERC721Enumerable public constant GAMMA = IERC721Enumerable(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623);

	address public manager;

	constructor(address _manager) {
		manager = _manager;
		ALPHA.setApprovalForAll(_manager, true);
		BETA.setApprovalForAll(_manager, true);
		GAMMA.setApprovalForAll(_manager, true);
	}

    // In the case a user sends an asset directly to the contract...
	function rescueAsset(address _asset, uint256 _tokenId, address _recipient) external onlyOwner {
		IERC721Enumerable(_asset).transferFrom(address(this), _recipient, _tokenId);
	}

	function claim() external {
		require(msg.sender == manager);
		GRAPE.claimTokens();
		APE.transfer(msg.sender, APE.balanceOf(address(this)));
	}
}