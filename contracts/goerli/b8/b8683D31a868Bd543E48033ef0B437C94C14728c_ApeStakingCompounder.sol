pragma solidity ^0.8.17;

import "Ownable.sol";
import "IERC20.sol";
import "IApeStaking.sol";
import "IApeMatcher.sol";

contract ApeStakingCompounder is Ownable {
	// IApeStaking public immutable APE_STAKING = IApeStaking(0x5954aB967Bc958940b7EB73ee84797Dc8a2AFbb9);
	// IERC20 public immutable APE = IERC20(0x4d224452801ACEd8B2F0aebE155379bb5D594381);

	IApeStaking public APE_STAKING;
	IERC20 public APE;
	IApeMatcher public MATCHER;
	address public SMOOTH;

	uint256 public totalSupply;
	mapping(address => uint256) public balanceOf;
	uint256 public debt;
	mapping(address => uint256) public userDebt;
	uint256 public totalUserDebt;

	constructor(address a, address b) {
		APE_STAKING = IApeStaking(a);
		APE = IERC20(b);
		APE.approve(address(APE_STAKING), type(uint256).max);
	}

	function setSmooth(address _smooth) external onlyOwner {
		require(SMOOTH == address(0));
		SMOOTH = _smooth;
	}

	function setMatcher(address _matcher) external onlyOwner {
		require(address(MATCHER) == address(0));
		MATCHER = IApeMatcher(_matcher);
	}


	function borrow(uint256 _amount) external {
		require(msg.sender == address(MATCHER));
		require(_amount <= liquid());

		debt += _amount;
		APE_STAKING.withdrawApeCoin(_amount, SMOOTH);
	}

	function repay(uint256 _amount) external {
		require(msg.sender == address(MATCHER));
		require(_amount <= liquid());

		debt -= _amount;
	}

	function liquid() public view returns(uint256) {
		return APE_STAKING.stakedTotal(address(this)) - totalUserDebt;
	}

	function pricePerShare() public view returns(uint256) {
		if (totalSupply == 0)
			return 1e18;
		return ((APE_STAKING.stakedTotal(address(this)) + debt + 
				APE.balanceOf(address(this)) +
				APE_STAKING.pendingRewards(0, address(this), 0)) * 1e18) / totalSupply;
	}

	function pricePerShareBehalf(uint256 _sub) internal view returns(uint256) {
		if (totalSupply == 0)
			return 1e18;
		return ((APE_STAKING.stakedTotal(address(this)) + debt + 
				APE.balanceOf(address(this)) +
				APE_STAKING.pendingRewards(0, address(this), 0) - _sub) * 1e18) / totalSupply;
	}

	function deposit(uint256 _amount) external {
		uint256 shares = _amount * 1e18 / pricePerShare();

		balanceOf[msg.sender] += shares;
		totalSupply += shares;
		APE.transferFrom(msg.sender, address(this), _amount);
		compound();
	}

	function depositOnBehalf(uint256 _amount, address _user) external {
		require(msg.sender == address(MATCHER));
		uint256 shares = _amount * 1e18 / pricePerShareBehalf(_amount);

		balanceOf[_user] += shares;
		totalSupply += shares;
		userDebt[_user] += _amount;
		totalUserDebt += _amount;
		compound();
	}

	function withdraw() external {
		withdraw(balanceOf[msg.sender]);
	}

	function withdraw(uint256 _shares) public {
		uint256 value = _shares * pricePerShare() / 1e18;
		uint256 totalValue = balanceOf[msg.sender] * pricePerShare() / 1e18;
		require(totalValue - value >= userDebt[msg.sender]);

		balanceOf[msg.sender] -= _shares;
		totalSupply -= _shares;
		compound();
		APE_STAKING.withdrawApeCoin(value, msg.sender);
	}

	function withdrawExactAmountOnBehalf(uint256 _amount, address _user, address _to) external {
		require(msg.sender == address(MATCHER));
		uint256 sharesToWithdraw = _amount * 1e18 /  pricePerShare();

		balanceOf[_user] -= sharesToWithdraw;
		totalSupply -= sharesToWithdraw;
		userDebt[_user] -= _amount;
		totalUserDebt -= _amount;
		APE_STAKING.withdrawApeCoin(_amount, _to);

	}

	function compound() public {
		APE_STAKING.claimSelfApeCoin();
		uint256 bal = APE.balanceOf(address(this));
		if (bal > 0)
			APE_STAKING.depositSelfApeCoin(bal);
	}

	function claimNftStaking(uint256[] calldata _matchIds) external {
		MATCHER.batchClaimRewardsFromMatches(_matchIds, true);
		compound();
	}

	function withdrawApeToken(IApeMatcher.DepositWithdrawals[][] calldata _deposits) external {
		MATCHER.withdrawApeToken(_deposits);
		compound();
	}

	function batchBreakMatch(uint256[] calldata _matchIds, bool[] calldata _breakAll) external {
		MATCHER.batchBreakMatch(_matchIds, _breakAll);
		compound();
	}

	function batchBreakDogMatch(uint256[] calldata _matchIds) external {
		MATCHER.batchBreakDogMatch(_matchIds);
		compound();
	}

	function batchSmartBreakMatch(uint256[] calldata _matchIds, bool[4][] memory _swapSetup) external {
		MATCHER.batchSmartBreakMatch(_matchIds, _swapSetup);
		compound();
	}
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
    function stakedTotal(address _address) external view returns (uint256);
}

pragma solidity ^0.8.17;

interface IApeMatcher {
	struct GreatMatch {
		uint96	doglessIndex;		// this var will hold primary data in first right most bit. 1 is alpha, 0 is beta
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

	struct MatchingParams {
		uint256 dogCounter;
		uint256 toMatch;
		uint256 pAvail;
		uint256 dAvail;
		uint256 gammaCount;
		bool gamma;
	}

	function depositApeTokenForUser(uint32[3] calldata _depositAmounts, address _user) external;
	function batchClaimRewardsFromMatches(uint256[] calldata _matchIds, bool _claim) external;
	function withdrawApeToken(DepositWithdrawals[][] calldata _deposits) external;
	function batchBreakMatch(uint256[] calldata _matchIds, bool[] calldata _breakAll) external;
	function batchBreakDogMatch(uint256[] calldata _matchIds) external;
	function batchSmartBreakMatch(uint256[] calldata _matchIds, bool[4][] memory _swapSetup) external;
}