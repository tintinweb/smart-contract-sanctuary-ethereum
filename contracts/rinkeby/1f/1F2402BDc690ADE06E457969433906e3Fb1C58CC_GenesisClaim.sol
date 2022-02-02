// SPDX-License-Identifier: AGPL-3.0-or-later\

pragma solidity ^0.7.5;
pragma abicoder v2;

import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

import "../interfaces/ITreasury.sol";
import "../interfaces/IgSTRL.sol";
import "../interfaces/IStaking.sol";

import "../types/Ownable.sol";

/** This contract allows Astral genesis contributors to claim STRL. It has been
 * revised to consider 9/10 tokens as staked at the time of claim; previously,
 * no claims were tracked as staked. The change keeps network ownership in check.
 * 100% can be treated as stakedm if the DAO sees fit to do so.
 */
contract GenesisClaim is Ownable {

	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	struct Term {
		uint256 percent;  // 4 decimals (5000 = 0.5%)
		uint256 claimed;  // static number
		uint256 gClaimed; // rebase-tracking number
		uint256 max;      // maximum nominal STRL amount can claim
	}

	// claim token
	IERC20 internal immutable strl;
	
	// payment token, 18 decimals only
	IERC20 internal immutable quote;

	// mints claim token
	ITreasury internal immutable treasury;

	// stake STRL for sSTRL
	IStaking internal immutable staking;

	// holds non-circulating supply
	address internal immutable dao;

	// tracks rebase-agnostic balance
	IgSTRL internal immutable gSTRL;
	
	// track 1/10 as static. governance can disable of desired.
	bool public useStatic = true;

	// tracks address info
	mapping(address => Term) public terms;
	// facilitates address change
	mapping(address => address) public walletChange;
	// as percent of supply (4 decimals: 10000 = 1%)
	uint256 public totalAllocated;
	// maximum portion of supply can allocate. == 7.8%
	uint256 public maximumAllocated = 78000;

	constructor(
		address _strl,
		address _quote,
		address _treasury,
		address _staking,
		address _dao,
		address _gSTRL
	) {
		require(_strl     != address(0), "Genesis: zero STRL");
		require(_quote    != address(0), "Genesis: zero Quote Token");
		require(_treasury != address(0), "Genesis: zero Treasury");
		require(_staking  != address(0), "Genesis: zero Staking");
		require(_dao      != address(0), "Genesis: zero DAO");
		require(_gSTRL    != address(0), "Genesis: zero gSTRL");

		strl      = IERC20(_strl);
		quote     = IERC20(_quote);
		treasury  = ITreasury(_treasury);
		staking   = IStaking(_staking);
		gSTRL     = IgSTRL(_gSTRL);
		dao       = _dao;
	}

	// allows wallet to claim STRL
	function claim(address _to, uint256 _amount) external {
		strl.safeTransfer(_to, _claim(_amount));
	}

	// allows wallet to claim STRL and stake it. set _claim = true if warmup is 0
	function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claimFromStaking
    ) external {
        staking.stake(_to, _claim(_amount), _rebasing, _claimFromStaking);
    }

	// logic for claiming STRL
	function _claim(uint256 _amount) internal returns (uint256 toSend_) {
        Term memory info = terms[msg.sender];

        quote.safeTransferFrom(msg.sender, address(this), _amount);
        toSend_ = treasury.deposit(_amount, address(quote), 0);

        require(redeemableFor(msg.sender).div(1e9) >= toSend_, "Claim more than vested");
        require(info.max.sub(claimed(msg.sender)) >= toSend_, "Claim more than max");

        if (useStatic) {
            terms[msg.sender].gClaimed = info.gClaimed.add(gSTRL.balanceTo(toSend_.mul(9).div(10)));
            terms[msg.sender].claimed = info.claimed.add(toSend_.div(10));
        } else terms[msg.sender].gClaimed = info.gClaimed.add(gSTRL.balanceTo(toSend_));
    }

	// allows address to push terms to new address
	function pushWalletChange(address _newAddress) external {
        require(terms[msg.sender].percent != 0, "No wallet to change");
        walletChange[msg.sender] = _newAddress;
    }

	// allows new address to pull terms
	function pullWalletChange(address _oldAddress) external {
        require(walletChange[_oldAddress] == msg.sender, "Old wallet did not push");
        require(terms[msg.sender].percent != 0, "Wallet already exists");

        walletChange[_oldAddress] = address(0);
        terms[msg.sender] = terms[_oldAddress];
        delete terms[_oldAddress];
    }

	// mass approval saves gas
	function approve() external {
		strl.approve(address(staking), 1e33);
		quote.approve(address(treasury), 1e33);
	}

	// view STRL claimable for address. quote decimals 18
	function redeemableFor(address _address) public view returns (uint256) {
        Term memory info = terms[_address];
        uint256 max = circulatingSupply().mul(info.percent).div(1e6);
        if (max > info.max) max = info.max;
        return max.sub(claimed(_address)).mul(1e9);
    }

	// view STLR claimed by address. STRL decimals 9
	function claimed(address _address) public view returns (uint256) {
        return gSTRL.balanceFrom(terms[_address].gClaimed).add(terms[_address].claimed);
    }

	// view circulating supply of STRL
	function circulatingSupply() public view returns (uint256) {
        return treasury.baseSupply().sub(strl.balanceOf(dao));
    }

	// set terms for new address
	function setTerms(
		address _address,
		uint256 _percent,
		uint256 _claimed,
		uint256 _gClaimed,
		uint256 _max
	) public onlyOwner {
		require(terms[_address].max == 0, "Genesis: address already exists");
		terms[_address] = Term({
			percent: _percent,
			claimed: _claimed,
			gClaimed: _gClaimed,
			max: _max
		});
		require(totalAllocated.add(_percent) <= maximumAllocated, "Genesis: cannot allocate more");
		totalAllocated = totalAllocated.add(_percent);
	}

	// all claims tracked under gClaimed (and track rebase)
	function treatAllAsStaked() external {
		require(msg.sender == dao, "Genesis: sender is not DAO");
		useStatic = false;
	}
}

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.7.5;

import "../interfaces/IOwnable.sol";

abstract contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyOwner() {
        emit OwnershipPulled( _owner, address(0) );
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyOwner() {
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
		// benefit is lost if 'b' is also tested.
		// See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

	function average(uint256 a, uint256 b) internal pure returns (uint256) {
		return div(add((a & b), (a ^ b)), 2);
	}

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0);
		return a % b;
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.7.5;

import "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IgSTRL is IERC20 {
	function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function index() external view returns (uint256);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);

    function migrate(address _staking, address _sOHM) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface ITreasury {
	event Deposit(address indexed token, uint256 amount, uint256 value);
    event Withdraw(address indexed token, uint256 amount, uint256 value);
    event CreateDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event RepayDebt(
        address indexed debtor,
        address indexed token,
        uint256 amount,
        uint256 value
    );
    event Managed(address indexed token, uint256 amount);
    event ReservesAudited(uint256 indexed totalReserves);
    event Minted(address indexed caller, address indexed recipient, uint256 amount);
    event PermissionQueued(STATUS indexed status, address queued);
    event Permissioned(address addr, STATUS indexed status, bool result);

	enum STATUS {
        RESERVEDEPOSITOR,
        RESERVESPENDER,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        RESERVEDEBTOR,
        REWARDMANAGER,
        SSTRL,
        STRLDEBTOR
    }

    struct Queue {
        STATUS managing;
        address toPermit;
        address calculator;
        uint256 timelockEnd;
        bool nullify;
        bool executed;
    }

	function deposit(
		uint256 amount_,
		address token_,
		uint256 profit_
	) external returns (uint256);

	function withdraw(uint256 amount_, address token_) external;

	function tokenValue(address token_, uint256 amount_) external view returns (uint256 value_);

	function mint(address recipient, uint256 amount) external;

	function manage(address token_, uint256 amount_) external;

	function incurDebt(uint256 amount_, address token_) external;

	function repayDebtWithReserve(uint256 amount_, address token_) external;

	function excessReserves() external view returns (uint256);

	function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface IStaking {
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256);

    function claim(address _recipient, bool _rebasing) external returns (uint256);

    function forfeit() external returns (uint256);

    function toggleLock() external;

    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256);

    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_);

    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_);

    function rebase() external;

    function index() external view returns (uint256);

    function contractBalance() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function supplyInWarmup() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface IOwnable {
	function owner() external view returns (address);

	function renounceManagement() external;

	function pushManagement(address newOwner_) external;

	function pullManagement() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

interface IERC20 {
	/**
	 * @dev Returns the amount of tokens in existance.
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
	 * condition is to first reduce the spender's allowanceto 0 and set the 
	 * desired value afterwards:
	 * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
	 *
	 * Emits an {Approval} event.
	 */
	function approve(address spender, uint256 amount) external returns (bool);

	/**
	 * @dev Moves `amount` tokens from `spender` to `recipient` using the 
	 * allowance mechanism. `amount` is then deducated from the caller's 
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 *
	 * Emits a {Transfer} event.
	 */
	function transferFrom(address spender, address recipient, uint256 amount) external returns (bool);

	/**
	 * @dev Emitted when `value` tokens are moved from one account (`from`) to
	 * another (`to`).
	 *
	 * Note that `value` may be zero.
	 */
	event Transfer(address indexed, address indexed to, uint256 value);

	/**
	 * @dev Emitted when the allowance of `spender` for an `owner` is set by
	 * a call to {approve}. `value` is the allowance.
	 */
	event Approval(address indexed owner, address indexed spender, uint256 value);
}