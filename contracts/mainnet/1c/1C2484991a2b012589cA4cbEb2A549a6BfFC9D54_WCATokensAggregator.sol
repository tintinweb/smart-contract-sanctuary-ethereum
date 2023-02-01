/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

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

// File: contracts/WCATokensAggregator.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;



contract WCATokensAggregator is Ownable {
	IERC20 public Token;
	IWCARestake public Restake;
	IWCAWhitelist public Whitelist;
	IWCAICO public ICO;
	IWCAMundialStaking public MundialStaking;
	IWCAMundialRewards public MundialRewards;
	IWCADAOLocking public WCADAOLocking;

	string public constant version = "0.2";

	constructor(
		address _Token,
		address _Restake,
		address _Whitelist,
		address _ICO,
		address _MundialStaking,
		address _MundialRewards,
		address _WCADAOLocking
	) {
		Token = IERC20(_Token);
		Restake = IWCARestake(_Restake);
		Whitelist = IWCAWhitelist(_Whitelist);
		ICO = IWCAICO(_ICO);
		MundialStaking = IWCAMundialStaking(_MundialStaking);
		MundialRewards = IWCAMundialRewards(_MundialRewards);
		WCADAOLocking = IWCADAOLocking(_WCADAOLocking);
	}

	function setAddresses(
		address _Token,
		address _Restake,
		address _Whitelist,
		address _ICO,
		address _MundialStaking,
		address _MundialRewards,
		address _WCADAOLocking
	) external onlyOwner {
		Token = IERC20(_Token);
		Restake = IWCARestake(_Restake);
		Whitelist = IWCAWhitelist(_Whitelist);
		ICO = IWCAICO(_ICO);
		MundialStaking = IWCAMundialStaking(_MundialStaking);
		MundialRewards = IWCAMundialRewards(_MundialRewards);
		WCADAOLocking = IWCADAOLocking(_WCADAOLocking);
	}

	function balanceOf(address _address) external view returns (uint256) {
		return Token.balanceOf(_address) + Restake.getTotalClaimable(_address) + Whitelist.getTotalClaimable(_address) + ICO.getTotalClaimable(_address) + getMundialStakingAvailableRewards(_address) + MundialRewards.getAvailableTokens(_address) + WCADAOLocking.getLockedTokensFromWallet(_address);
	}

	function stakedBalanceOf(address _address) external view returns (uint256) {
		return Restake.getTotalClaimable(_address) + Whitelist.getTotalClaimable(_address) + ICO.getTotalClaimable(_address) + getMundialStakingAvailableRewards(_address) + MundialRewards.getAvailableTokens(_address) + WCADAOLocking.getLockedTokensFromWallet(_address);
	}

	function subdividedBalanceOf(address _address)
		external
		view
		returns (
			uint256 tokensOnWallet,
			uint256 restake,
			uint256 whitelist,
			uint256 ico,
			uint256 mundialStaking,
			uint256 mundialRewards,
			uint256 lockedFromStaking,
			uint256 lockedFromWallet
		)
	{
		tokensOnWallet = Token.balanceOf(_address);
		restake = Restake.getTotalClaimable(_address);
		whitelist = Whitelist.getTotalClaimable(_address);
		ico = ICO.getTotalClaimable(_address);
		mundialStaking = getMundialStakingAvailableRewards(_address);
		mundialRewards = MundialRewards.getAvailableTokens(_address);
		lockedFromStaking = WCADAOLocking.getLockedTokensFromStaking(_address);
		lockedFromWallet = WCADAOLocking.getLockedTokensFromWallet(_address);

		if (lockedFromStaking > 0) {
			uint256 count = lockedFromStaking;
			if (restake > 0) {
				if (restake >= count) {
					restake -= count;
					return (tokensOnWallet, restake, whitelist, ico, mundialStaking, mundialRewards, lockedFromStaking, lockedFromWallet);
				} else {
					count -= restake;
					restake = 0;
				}
			}
			if (whitelist > 0) {
				if (whitelist >= count) {
					whitelist -= count;
					return (tokensOnWallet, restake, whitelist, ico, mundialStaking, mundialRewards, lockedFromStaking, lockedFromWallet);
				} else {
					count -= whitelist;
					whitelist = 0;
				}
			}
			if (ico > 0) {
				if (ico >= count) {
					ico -= count;
					return (tokensOnWallet, restake, whitelist, ico, mundialStaking, mundialRewards, lockedFromStaking, lockedFromWallet);
				} else {
					count -= ico;
					ico = 0;
				}
			}
			if (mundialStaking > 0) {
				if (mundialStaking >= count) {
					mundialStaking -= count;
					return (tokensOnWallet, restake, whitelist, ico, mundialStaking, mundialRewards, lockedFromStaking, lockedFromWallet);
				} else {
					count -= mundialStaking;
					mundialStaking = 0;
				}
			}
			if (mundialRewards > 0) {
				if (mundialRewards >= count) {
					mundialRewards -= count;
					return (tokensOnWallet, restake, whitelist, ico, mundialStaking, mundialRewards, lockedFromStaking, lockedFromWallet);
				} else {
					count -= mundialRewards;
					mundialRewards = 0;
				}
			}
			return (tokensOnWallet, restake, whitelist, ico, mundialStaking, mundialRewards, lockedFromStaking, lockedFromWallet);
		}
	}

	function getMundialStakingAvailableRewards(address _staker) public view returns (uint256) {
		uint256 tokenRewards = 0;
		for (uint256 i = MundialStaking.getStakedCount(_staker); i > 0; i--) {
			uint256 tokenId = MundialStaking.getStakedTokens(_staker)[i - 1];
			tokenRewards += MundialStaking.getRewardsByTokenId(tokenId);
		}
		if (tokenRewards == 0 && MundialStaking.stakerRewards(_staker) == 0) {
			return 0;
		}
		uint256 availableRewards = MundialStaking.stakerRewards(_staker) + tokenRewards - MundialStaking.stakerRewardsClaimed(_staker);
		return availableRewards;
	}
}

interface IWCARestake {
	function getTotalClaimable(address _address) external view returns (uint256);
}

interface IWCAWhitelist {
	function getTotalClaimable(address _address) external view returns (uint256);
}

interface IWCAICO {
	function getTotalClaimable(address _address) external view returns (uint256);
}

interface IWCAMundialStaking {
	function getRewardsByTokenId(uint256 _tokenId) external view returns (uint256);

	function getStakedCount(address staker) external view returns (uint256);

	function getStakedTokens(address staker) external view returns (uint256[] memory);

	function stakerRewards(address staker) external view returns (uint256);

	function stakerRewardsClaimed(address staker) external view returns (uint256);
}

interface IWCAMundialRewards {
	function getAvailableTokens(address _address) external view returns (uint256);
}

interface IWCADAOLocking {
	function getLockedTokensFromStaking(address _address) external view returns (uint256);

	function getLockedTokensFromWallet(address _address) external view returns (uint256);
}