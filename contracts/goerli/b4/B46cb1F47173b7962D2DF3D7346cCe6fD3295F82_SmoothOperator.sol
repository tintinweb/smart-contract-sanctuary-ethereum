pragma solidity ^0.8.17;

import "IERC721Enumerable.sol";
import "IERC20.sol";
import "Ownable.sol";
import "ISmoothOperator.sol";
import "IApeStaking.sol";
import "IApeMatcher.sol";


contract SmoothOperator is Ownable, ISmoothOperator {

	// IApeStaking public constant apeStaking = IApeStaking(0x5954aB967Bc958940b7EB73ee84797Dc8a2AFbb9);
	// IERC721Enumerable public constant ALPHA = IERC721Enumerable(0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D);
	// IERC721Enumerable public constant BETA = IERC721Enumerable(0x60E4d786628Fea6478F785A6d7e704777c86a7c6);
	// IERC721Enumerable public constant GAMMA = IERC721Enumerable(0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623);
	// IERC20 public constant APE = IERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381);

	IApeStaking public APE_STAKING;
	IERC721Enumerable public ALPHA;
	IERC721Enumerable public BETA;
	IERC721Enumerable public GAMMA;
	IERC20 public APE;

	uint256 constant ALPHA_SHARE = 10094 ether;
	uint256 constant BETA_SHARE = 2042 ether;
	uint256 constant GAMMA_SHARE = 856 ether;

	address public manager;

	constructor(address _manager, address a,address b,address c,address d,address e) {
		ALPHA = IERC721Enumerable(a);
		BETA = IERC721Enumerable(b);
		GAMMA = IERC721Enumerable(c);
		APE = IERC20(d);
		APE_STAKING = IApeStaking(e);
		manager = _manager;
		ALPHA.setApprovalForAll(_manager, true);
		BETA.setApprovalForAll(_manager, true);
		GAMMA.setApprovalForAll(_manager, true);
		APE.approve(_manager, type(uint256).max);
		APE.approve(address(APE_STAKING), type(uint256).max);
	}

	modifier onlyManager() {
		require(msg.sender == manager, "Smooth: Can't toucht this");
		_;
	}

	/**
	 * @notice
	 * Function that swaps a primary asset from a match
	 * @param _primary Contract address of the primary asset
	 * @param _in New asset ID to be swapped in
	 * @param _out Asset ID to be swapped out
	 * @param _receiver Address receiving the swapped out asset
	 * @param _gammaId Dog ID to uncommit and recommit if it exists
	 */
	function swapPrimaryNft(
		address _primary,
		uint256 _in,
		uint256 _out,
		address _receiver,
		uint256 _gammaId) external onlyManager returns(uint256 totalPrimary, uint256 totalGamma) {
		IERC721Enumerable primary = IERC721Enumerable(_primary);
		IApeStaking.SingleNft[] memory tokens = new IApeStaking.SingleNft[](1);
		IApeStaking.PairNftWithdrawWithAmount[] memory nullPair = new IApeStaking.PairNftWithdrawWithAmount[](0);
		IApeStaking.PairNftWithdrawWithAmount[] memory pair = new IApeStaking.PairNftWithdrawWithAmount[](1);

		tokens[0] = IApeStaking.SingleNft(uint32(_out), uint224(primary == ALPHA ? ALPHA_SHARE : BETA_SHARE));
		pair[0] = IApeStaking.PairNftWithdrawWithAmount(uint32(_out), uint32(_gammaId), uint184(GAMMA_SHARE), true);
		// unstake and unbind dog from primary if it exists
		if (_gammaId > 0) {
			APE_STAKING.withdrawBAKC(
				primary == ALPHA ? pair : nullPair,
				primary == ALPHA ? nullPair : pair);
			totalGamma = APE.balanceOf(address(this)) - GAMMA_SHARE;
		}
		// unstake primary
		if (primary == ALPHA)
			APE_STAKING.withdrawBAYC(tokens, address(this));
		else
			APE_STAKING.withdrawMAYC(tokens, address(this));
		primary.transferFrom(address(this), _receiver, _out);
		totalPrimary = APE.balanceOf(address(this))
					- totalGamma - (primary == ALPHA ? ALPHA_SHARE : BETA_SHARE)
					- (_gammaId > 0 ? GAMMA_SHARE : 0);
		// send rewards of both dog and primary parties
		APE.transfer(manager, totalPrimary + totalGamma);
		tokens[0].tokenId = uint32(_in);
		// stake new primary
		if (primary == ALPHA)
			APE_STAKING.depositBAYC(tokens);
		else
			APE_STAKING.depositMAYC(tokens);
		// stake and bind previous dog to new primary if it exists
		if (_gammaId > 0) {
			IApeStaking.PairNftDepositWithAmount[] memory nullPairD = new IApeStaking.PairNftDepositWithAmount[](0);
			IApeStaking.PairNftDepositWithAmount[] memory pairD = new IApeStaking.PairNftDepositWithAmount[](1);
			pairD[0] = IApeStaking.PairNftDepositWithAmount(uint32(_in), uint32(_gammaId), uint184(GAMMA_SHARE));
			APE_STAKING.depositBAKC(
				primary == ALPHA ? pairD : nullPairD,
				primary == ALPHA ? nullPairD : pairD);
		}
	}

	/**
	 * @notice
	 * Function that swaps a dog asset from a match
	 * @param _primary Contract address of the primary asset
	 * @param _primaryId Primary asset ID to uncommit and recommit
	 * @param _in New dog ID to be swapped in
	 * @param _out DOG ID to be swapped out
	 * @param _receiver Address receiving the swapped out asset
	 */
	function swapDoggoNft(
		address _primary,
		uint256 _primaryId,
		uint256 _in,
		uint256 _out,
		address _receiver) external onlyManager returns(uint256 totalGamma) {
		IERC721Enumerable primary = IERC721Enumerable(_primary);
		IApeStaking.PairNftWithdrawWithAmount[] memory nullPair = new IApeStaking.PairNftWithdrawWithAmount[](0);
		IApeStaking.PairNftWithdrawWithAmount[] memory pair = new IApeStaking.PairNftWithdrawWithAmount[](1);

		pair[0] = IApeStaking.PairNftWithdrawWithAmount(uint32(_primaryId), uint32(_out), uint184(GAMMA_SHARE), true);
		// unstake and unbind dog from primary
		APE_STAKING.withdrawBAKC(
			primary == ALPHA ? pair : nullPair,
			primary == ALPHA ? nullPair : pair);
		totalGamma = APE.balanceOf(address(this)) - GAMMA_SHARE;
		GAMMA.transferFrom(address(this), _receiver, _out);
		// stake and bind previous dog to new primary
		IApeStaking.PairNftDepositWithAmount[] memory nullPairD = new IApeStaking.PairNftDepositWithAmount[](0);
		IApeStaking.PairNftDepositWithAmount[] memory pairD = new IApeStaking.PairNftDepositWithAmount[](1);
		pairD[0] = IApeStaking.PairNftDepositWithAmount(uint32(_primaryId), uint32(_in), uint184(GAMMA_SHARE));
		APE_STAKING.depositBAKC(
			primary == ALPHA ? pairD : nullPairD,
			primary == ALPHA ? nullPairD : pairD);
		// send rewards of dog partiy
		APE.transfer(manager,totalGamma);
	}

	/**
	 * @notice
	 * Function that claims the rewards of a given match
	 * @param _primary Contract address of the primary asset
	 * @param _tokenId Primary asset ID to claim from
	 * @param _gammaId Dog ID to claim from is _claimGamma is true
	 * @param _claimSetup Indicates to claim Dog or primary pr both
	 */
	function claim(address _primary, uint256 _tokenId, uint256 _gammaId, uint256 _claimSetup) public onlyManager returns(uint256 total, uint256 totalGamma) {
		IERC721Enumerable primary = IERC721Enumerable(_primary);
		uint256[] memory tokens = new uint256[](1);
		IApeStaking.PairNft[] memory pair = new IApeStaking.PairNft[](1);
		IApeStaking.PairNft[] memory nullPair = new IApeStaking.PairNft[](0);
		tokens[0] = _tokenId;
		pair[0] = IApeStaking.PairNft(uint128(_tokenId), uint128(_gammaId));
		if (_claimSetup == 0 || _claimSetup == 2) {
			APE_STAKING.claimBAKC(
				primary == ALPHA ? pair : nullPair,
				primary == ALPHA ? nullPair : pair, address(this));
			totalGamma = APE.balanceOf(address(this));
		}
		if (_claimSetup == 1 || _claimSetup == 2){
			if (primary == ALPHA)
				APE_STAKING.claimBAYC(tokens, address(this));
			else
				APE_STAKING.claimMAYC(tokens, address(this));
			total = APE.balanceOf(address(this)) - totalGamma;
		}
		APE.transfer(manager, total + totalGamma);
	}

	/**
	 * @notice
	 * Function that commits a pair of assets in the staking contract
	 * @param _primary Contract address of the primary asset
	 * @param _tokenId Primary asset ID to commit
	 * @param _gammaId Dog ID to commit if it exists
	 */
	function commitNFTs(address _primary, uint256 _tokenId, uint256 _gammaId) external onlyManager {
		IERC721Enumerable primary = IERC721Enumerable(_primary);
		IApeStaking.SingleNft[] memory tokens = new IApeStaking.SingleNft[](1);
		tokens[0] = IApeStaking.SingleNft(uint32(_tokenId), uint224(primary == ALPHA ? ALPHA_SHARE : BETA_SHARE));

		IApeStaking.PairNftDepositWithAmount[] memory nullPair = new IApeStaking.PairNftDepositWithAmount[](0);
		IApeStaking.PairNftDepositWithAmount[] memory pair = new IApeStaking.PairNftDepositWithAmount[](1);
		pair[0] = IApeStaking.PairNftDepositWithAmount(uint32(_tokenId), uint32(_gammaId), uint184(GAMMA_SHARE));

		if (primary == ALPHA)
			APE_STAKING.depositBAYC(tokens);
		else
			APE_STAKING.depositMAYC(tokens);
		if (_gammaId > 0)
			APE_STAKING.depositBAKC(
				primary == ALPHA ? pair : nullPair,
				primary == ALPHA ? nullPair : pair);
	}

	/**
	 * @notice
	 * Function that binds a dog to a primary asset
	 * @param _primary Contract address of the primary asset
	 * @param _tokenId Primary asset ID
	 * @param _gammaId Dog ID to bind
	 */
	function bindDoggoToExistingPrimary(address _primary, uint256 _tokenId, uint256 _gammaId) external onlyManager {
		IERC721Enumerable primary = IERC721Enumerable(_primary);
		IApeStaking.PairNftDepositWithAmount[] memory nullPair = new IApeStaking.PairNftDepositWithAmount[](0);
		IApeStaking.PairNftDepositWithAmount[] memory pair = new IApeStaking.PairNftDepositWithAmount[](1);
		pair[0] = IApeStaking.PairNftDepositWithAmount(uint32(_tokenId), uint32(_gammaId), uint184(GAMMA_SHARE));

		APE_STAKING.depositBAKC(
			primary == ALPHA ? pair : nullPair,
			primary == ALPHA ? nullPair : pair);
	}

	/**
	 * @notice
	 * Function that unbinds a dog from a primary asset
	 * @param _primary Contract address of the primary asset
	 * @param _tokenId Primary asset ID
	 * @param _gammaId Dog ID to unbind
	 * @param _receiver Owner of dog
	 * @param _tokenOwner Owner of token deposit
	 * @param _caller Address that initiated the execution
	 */
	function unbindDoggoFromExistingPrimary(
		address _primary,
		uint256 _tokenId,
		uint256 _gammaId,
		address _receiver,
		address _tokenOwner,
		address _caller) external onlyManager returns(uint256 totalGamma) {
		IERC721Enumerable primary = IERC721Enumerable(_primary);
		IApeStaking.PairNftWithdrawWithAmount[] memory nullPair = new IApeStaking.PairNftWithdrawWithAmount[](0);
		IApeStaking.PairNftWithdrawWithAmount[] memory pair = new IApeStaking.PairNftWithdrawWithAmount[](1);

		pair[0] = IApeStaking.PairNftWithdrawWithAmount(uint32(_tokenId), uint32(_gammaId), uint184(GAMMA_SHARE), true);
		APE_STAKING.withdrawBAKC(
			primary == ALPHA ? pair : nullPair,
			primary == ALPHA ? nullPair : pair);
		GAMMA.transferFrom(address(this), _receiver == _caller ? _receiver : manager, _gammaId);
		APE.transfer(_tokenOwner == _caller ? _tokenOwner : manager, GAMMA_SHARE);
		if (_tokenOwner != _caller)
			IApeMatcher(manager).depositApeTokenForUser([0, 0, uint32(1)], _tokenOwner);
		totalGamma = APE.balanceOf(address(this));
		APE.transfer(manager, totalGamma);
	}

	/**
	 * @notice
	 * Function that uncommits all assets from a match
	 * @param _match Contract address of the primary asset
	 * @param _caller Address that initiated the execution
	 */
	function uncommitNFTs(IApeMatcher.GreatMatch calldata _match, address _caller) external onlyManager returns(uint256 totalPrimary, uint256 totalGamma) {
		IERC721Enumerable primary = _match.primary == 1 ? ALPHA : BETA;
		uint256 tokenId = uint256(_match.ids & (2**48 - 1));
		uint256 gammaId = uint256(_match.ids >> 48);
		uint256 primaryShare = primary == ALPHA ? ALPHA_SHARE : BETA_SHARE;
		IApeStaking.SingleNft[] memory tokens = new IApeStaking.SingleNft[](1);
		IApeStaking.PairNftWithdrawWithAmount[] memory nullPair = new IApeStaking.PairNftWithdrawWithAmount[](0);
		IApeStaking.PairNftWithdrawWithAmount[] memory pair = new IApeStaking.PairNftWithdrawWithAmount[](1);

		tokens[0] = IApeStaking.SingleNft(uint32(tokenId), uint224(primaryShare));
		pair[0] = IApeStaking.PairNftWithdrawWithAmount(uint32(tokenId), uint32(gammaId), uint184(GAMMA_SHARE), true);
		if (gammaId > 0) {
			APE_STAKING.withdrawBAKC(
				primary == ALPHA ? pair : nullPair,
				primary == ALPHA ? nullPair : pair);
			GAMMA.transferFrom(address(this), _caller == _match.doggoOwner ? _match.doggoOwner : manager, gammaId);
			APE.transfer(_match.doggoTokensOwner == _caller ? _match.doggoTokensOwner : manager, GAMMA_SHARE);
			if (_match.doggoTokensOwner != _caller)
				IApeMatcher(manager).depositApeTokenForUser([0, 0, uint32(1)], _match.doggoTokensOwner);
			totalGamma = APE.balanceOf(address(this));
		}
		if (primary == ALPHA)
			APE_STAKING.withdrawBAYC(tokens, address(this));
		else
			APE_STAKING.withdrawMAYC(tokens, address(this));
		primary.transferFrom(address(this), _caller == _match.primaryOwner ? _match.primaryOwner : manager, tokenId);
		APE.transfer(_match.primaryTokensOwner == _caller ? _match.primaryTokensOwner : manager, primaryShare);
		if (_match.primaryTokensOwner != _caller)
			IApeMatcher(manager).depositApeTokenForUser(
				primary == ALPHA ? [uint32(1), 0, 0] : [0, uint32(1), 0],
				_match.primaryTokensOwner);
		totalPrimary = APE.balanceOf(address(this)) - totalGamma;
		APE.transfer(manager, totalPrimary + totalGamma);
	}

	/**
	 * @notice
	 * As scary as this look, this function can't steal assets.
	 * It cannot access NFT contract outside of designated code above.
	 * All contracts that needed approval have received approval in the constructor.
	 * Only the staking contract and the manager contract can move assets around.
	 * A rogue contract call could not transfer nfts or tokens out of this contract.
	 * The existence of this function is purely to claim any rewards from snapshots taken during the time nfts are chilling here.
	 * Blame Dingaling for the addition of this 
	 */
	function exec(address _target, bytes calldata _data) external payable onlyOwner {
		require(_target != address(ALPHA) &&
				_target != address(BETA) &&
				_target != address(GAMMA) &&
				_target != address(APE) &&
				_target != address(APE_STAKING), "Cannot call any assets handled by this contract");
		(bool success,) = _target.call{value:msg.value}(_data);
		require(success);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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

pragma solidity ^0.8.17;

import "IApeMatcher.sol";

interface ISmoothOperator {
	function commitNFTs(address _primary, uint256 _tokenId, uint256 _gammaId) external;

	function uncommitNFTs(IApeMatcher.GreatMatch calldata _match, address _caller) external returns(uint256, uint256);

	function claim(address _primary, uint256 _tokenId, uint256 _gammaId, uint256 _claimSetup) external returns(uint256 total, uint256 totalGamma);

	function swapPrimaryNft(
		address _primary,
		uint256 _in,
		uint256 _out,
		address _receiver,
		uint256 _gammaId) external returns(uint256 totalGamma, uint256 totalPrimary);

		function swapDoggoNft(
		address _primary,
		uint256 _primaryId,
		uint256 _in,
		uint256 _out,
		address _receiver) external returns(uint256 totalGamma);

	function bindDoggoToExistingPrimary(address _primary, uint256 _tokenId, uint256 _gammaId) external;
	
	function unbindDoggoFromExistingPrimary(
		address _primary,
		uint256 _tokenId,
		uint256 _gammaId,
		address _receiver,
		address _tokenOwner,
		address _caller) external returns(uint256 totalGamma);

	
}

pragma solidity ^0.8.17;

interface IApeMatcher {
	struct GreatMatch {
		bool	active;	
		uint8	primary;			// alpha:1/beta:2
		uint32	start;				// time of activation
		uint96	doglessIndex;
		uint96	ids;				// right most 48 bits => primary | left most 48 bits => doggo
		address	primaryOwner;
		address	primaryTokensOwner;	// owner of ape tokens attributed to primary
		address doggoOwner;
		address	doggoTokensOwner;	// owner of ape tokens attributed to doggo
	}

	struct DepositPosition {
		uint32 count;
		address depositor;
	}

	struct DepositWithdrawals {
		uint128 depositId;
		uint32 amount;
	}

	function depositApeTokenForUser(uint32[3] calldata _depositAmounts, address _user) external;
}

pragma solidity ^0.8.17;

interface IApeStaking {
    /// @notice State for ApeCoin, BAYC, MAYC, and Pair Pools
    struct Pool {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
        TimeRange[] timeRanges;
    }

    /// @notice Pool rules valid for a given duration of time.
    /// @dev All TimeRange timestamp values must represent whole hours
    struct TimeRange {
        uint48 startTimestampHour;
        uint48 endTimestampHour;
        uint96 rewardsPerHour;
        uint96 capPerPosition;
    }

    /// @dev Convenience struct for front-end applications
    struct PoolUI {
        uint256 poolId;
        uint256 stakedAmount;
        TimeRange currentTimeRange;
    }

    /// @dev Per address amount and reward tracking
    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }
    
    /// @dev Struct for depositing and withdrawing from the BAYC and MAYC NFT pools
    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }
    /// @dev Struct for depositing from the BAKC (Pair) pool
    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }
    /// @dev Struct for withdrawing from the BAKC (Pair) pool
    struct PairNftWithdrawWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
        bool isUncommit;
    }
    /// @dev Struct for claiming from an NFT pool
    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
    }
    /// @dev NFT paired status.  Can be used bi-directionally (BAYC/MAYC -> BAKC) or (BAKC -> BAYC/MAYC)
    struct PairingStatus {
        uint248 tokenId;
        bool isPaired;
    }

    // @dev UI focused payload
    struct DashboardStake {
        uint256 poolId;
        uint256 tokenId;
        uint256 deposited;
        uint256 unclaimed;
        uint256 rewards24hr;
        DashboardPair pair;
    }
    /// @dev Sub struct for DashboardStake
    struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
    }

    function nftPosition(uint256, uint256) external view returns(Position memory);
    function getPoolsUI() external view returns(PoolUI memory, PoolUI memory, PoolUI memory, PoolUI memory);
    function rewardsBy(uint256 _poolId, uint256 _from, uint256 _to) external view returns (uint256, uint256);

	function depositApeCoin(uint256 _amount, address _recipient) external;
	function depositSelfApeCoin(uint256 _amount) external;

    function claimApeCoin(address _recipient) external;
	function claimSelfApeCoin() external;
    function withdrawApeCoin(uint256 _amount, address _recipient) external;


	function depositBAYC(SingleNft[] calldata _nfts) external;
	function depositMAYC(SingleNft[] calldata _nfts) external;
	function depositBAKC(PairNftDepositWithAmount[] calldata _baycPairs, PairNftDepositWithAmount[] calldata _maycPairs) external;

	function claimBAYC(uint256[] calldata _nfts, address _recipient) external;
	function claimMAYC(uint256[] calldata _nfts, address _recipient) external;
	function claimBAKC(PairNft[] calldata _baycPairs, PairNft[] calldata _maycPairs, address _recipient) external;

	function withdrawBAYC(SingleNft[] calldata _nfts, address _recipient) external;
	function withdrawMAYC(SingleNft[] calldata _nfts, address _recipient) external;
	function withdrawBAKC(PairNftWithdrawWithAmount[] calldata _baycPairs, PairNftWithdrawWithAmount[] calldata _maycPairs) external;

    function pendingRewards(uint256 _poolId, address _address, uint256 _tokenId) external view returns (uint256);
}