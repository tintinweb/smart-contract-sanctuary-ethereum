pragma solidity ^0.8.17;

import "IERC721Enumerable.sol";
import "IERC20.sol";
import "IApeMatcher.sol";
import "ISmoothOperator.sol";
import "IApeStaking.sol";
import "IApeMatcherHelper.sol";


contract ApeMatcherHelper {

	struct RewardInfo {
		uint128 primaryRewards;
		uint128 gammaRewards;
	}

	IApeStaking public immutable APE_STAKING;
	IERC721Enumerable public immutable ALPHA;
	IERC721Enumerable public immutable BETA;
	IERC721Enumerable public immutable GAMMA;
	IERC20 public immutable APE;
	IApeMatcherHelper public immutable MATCHER;
	address public immutable SMOOTH;

	uint256 constant ALPHA_SHARE = 10094 ether; //bayc
	uint256 constant BETA_SHARE = 2042 ether; // mayc
	uint256 constant GAMMA_SHARE = 856 ether; // dog
	uint256 constant EOF = 69420;

	constructor(address a, address b, address c, address d, address e, address f, address g) {
		APE_STAKING = IApeStaking(a);
		ALPHA = IERC721Enumerable(b);
		BETA = IERC721Enumerable(c);
		GAMMA = IERC721Enumerable(d);
		APE = IERC20(e);
		MATCHER = IApeMatcherHelper(f);
		SMOOTH = address(g);
	}

	function getUserQueuedNftsIDs(address _user, IERC721Enumerable _nft, uint256 _index, uint256 _maxLen) external view returns(uint256[] memory tokenIds) {
		tokenIds = new uint256[](_maxLen + 1);
		uint256 j;
		uint256 balance = _nft.balanceOf(address(MATCHER));

		// if _index is higher than balance at time of call, return empty array instead of revert
		if (balance < _index) {
			return new uint256[](0);
		}

		// if endIndex (_index + _maxLen) overflows, set endIndex to balance
		uint256 endIndex = _index + _maxLen;
		if (balance < endIndex)
			endIndex = balance;

		// from index to endIndex, check if asset is owner's and populate tokenIds array
		for(uint256 i = _index; i < endIndex; i++) {
			uint256 tokenId = _nft.tokenOfOwnerByIndex(address(MATCHER), i);
			address owner = MATCHER.assetToUser(address(_nft), tokenId);
			if (_user == owner)
				tokenIds[j++] = tokenId;
		}
		tokenIds[j++] = EOF;
	}

	function getUserQueuedCoinDepositsIDs(
		address _user,
		uint256 _type,
		uint256 _index,
		uint256 _maxLen) external view returns(uint256[] memory depositIds, uint256 amount) {
		depositIds = new uint256[](_maxLen);
		uint256 j;
		uint256 start;
		uint256 end;

		if (_type == ALPHA_SHARE) {
			start = MATCHER.alphaSpentCounter();
			end = MATCHER.alphaDepositCounter();
		}
		else if (_type == BETA_SHARE) {
			start = MATCHER.betaSpentCounter();
			end = MATCHER.betaDepositCounter();
		}
		else if (_type == GAMMA_SHARE) {
			start = MATCHER.gammaSpentCounter();
			end = MATCHER.gammaDepositCounter();
		}

		// if start + _index is higher than end (max endIndex) at time of call, return empty array
		if (start + _index > end) {
			return (new uint256[](0), 0);
		}

		// if endIndex (_index + _maxLen) overflows, set endIndex to end
		uint256 endIndex = _index + _maxLen;
		if (end < endIndex)
			endIndex = end;

		for(uint256 i = start + _index; i < endIndex; i++) {
			IApeMatcherHelper.DepositPosition memory pos =  MATCHER.depositPosition(_type, i);
			if (pos.depositor == _user) {
				depositIds[j++] = i;
				amount += pos.count;
			}
		}
	}

	function getUserMatches(address _user, uint256 _index, uint256 _maxLen) external view returns(IApeMatcherHelper.GreatMatchWithId[] memory) {
		IApeMatcherHelper.GreatMatchWithId[] memory matches = new IApeMatcherHelper.GreatMatchWithId[](_maxLen);
		uint256 j;
		uint256 counter = MATCHER.matchCounter();

		if (_index > counter)
			return new IApeMatcherHelper.GreatMatchWithId[](0);

		// if endIndex (_index + _maxLen) overflows, set endIndex to counter
		uint256 endIndex = _index + _maxLen;
		if (counter < endIndex)
			endIndex = counter;

		for(uint256 i = _index; i < endIndex; i++) {
			IApeMatcherHelper.GreatMatch memory _match = MATCHER.matches(i);
			if (_user == _match.primaryOwner ||
				_user == _match.primaryTokensOwner ||
				_user == _match.doggoOwner ||
				_user == _match.doggoTokensOwner)
				matches[j++] = IApeMatcherHelper.GreatMatchWithId(i, _match);
		}
		return matches;
	}

	function getDoglessArray(uint256 _index, uint256 _maxLen) external view returns(uint256[] memory) {
		uint256[] memory arr = new uint256[](_maxLen);
		uint256 j;
		uint256 counter = MATCHER.doglessMatchCounter();

		if (_index > counter)
			return new uint256[](0);
		
		uint256 endIndex = _index + _maxLen;
		if (counter < endIndex)
			endIndex = counter;
		for(uint256 i = _index; i < endIndex; i++) {
			arr[j++] = MATCHER.doglessMatches(i);
		}
		return arr;
	}

	function getDoglessArrayExtra(uint256 _index, uint256 _maxLen) external view returns(uint256[] memory) {
		uint256[] memory arr = new uint256[](_maxLen);
		uint256 j;
		uint256 counter = MATCHER.doglessMatchCounter();

		if (_index > counter)
			return new uint256[](0);
		
		uint256 endIndex = _index + _maxLen;
		if (counter < endIndex)
			endIndex = counter;
		for(uint256 i = _index; i < endIndex; i++) {
			arr[j++] = MATCHER.doglessMatches(i);
		}
		return arr;
	}

	function getPendingRewardsOfMatches(uint256[] calldata _matchIds) external view returns(RewardInfo[] memory){
		RewardInfo[] memory arr = new RewardInfo[](_matchIds.length);
		for (uint256 i = 0; i < _matchIds.length; i++) {
			IApeMatcherHelper.GreatMatch memory _match = MATCHER.matches(_matchIds[i]);
			uint256 tP = APE_STAKING.pendingRewards(_match.primary, SMOOTH, _match.ids & 0xffffffffffff);
			uint256 tG;
			if (_match.ids >> 48 > 0)
				tG = APE_STAKING.pendingRewards(3, SMOOTH, _match.ids >> 48);
			arr[i] = RewardInfo(uint128(tP), uint128(tG));
		}
		return arr;
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

pragma solidity ^0.8.17;

interface IApeMatcher {
	struct GreatMatch {
		bool	active;	
		uint8	primary;			// alpha:1/beta:2
		uint32	start;				// time of activation
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

	function depositApeTokenForUser(uint32[3] calldata _depositAmounts, address _user) external;
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

pragma solidity ^0.8.17;

interface IApeMatcherHelper {

	struct DepositPosition {
		uint32 count;
		address depositor;
	}

	struct GreatMatchWithId {
		uint256 id;
		GreatMatch _match;
	}

	struct GreatMatch {
		bool	active;	
		uint8	primary;			// alpha:1/beta:2
		uint32	start;				// time of activation
		uint96	ids;				// right most 48 bits => primary | left most 48 bits => doggo
		address	primaryOwner;
		address	primaryTokensOwner;	// owner of ape tokens attributed to primary
		address doggoOwner;
		address	doggoTokensOwner;	// owner of ape tokens attributed to doggo
	}

	function assetToUser(address, uint256) external view returns(address);
	function alphaSpentCounter() external view returns(uint256);
	function betaSpentCounter() external view returns(uint256);
	function gammaSpentCounter() external view returns(uint256);
	function alphaDepositCounter() external view returns(uint256);
	function betaDepositCounter() external view returns(uint256);
	function gammaDepositCounter() external view returns(uint256);

	function depositPosition(uint256, uint256) external view returns(DepositPosition memory);
	function matches(uint256) external view returns(GreatMatch memory);
	function matchCounter() external view returns(uint256);

	function doglessMatchCounter() external view returns(uint256);
	function doglessMatches(uint256) external view returns(uint256);
}