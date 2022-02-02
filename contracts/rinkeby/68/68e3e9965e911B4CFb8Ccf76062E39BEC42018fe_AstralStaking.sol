// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IsSTRL.sol";
import "./interfaces/IgSTRL.sol";
import "./interfaces/IDistributor.sol";
import "./interfaces/IAstralStaking.sol";

import "./types/AstralAccessControlled.sol";

contract AstralStaking is IAstralStaking, AstralAccessControlled {

	using SafeMath  for uint256;
	using SafeERC20 for IERC20;
	using SafeERC20 for IsSTRL;
	using SafeERC20 for IgSTRL;

	IERC20 public immutable STRL;
	IsSTRL public immutable sSTRL;
	IgSTRL public immutable gSTRL;

	Epoch public epoch;

	IDistributor public distributor;

	mapping(address => Claim) public warmupInfo;
	uint256 public warmupPeriod;
	uint256 private gonsInWarmup;

	constructor(
		address _strl,
		address _sSTRL,
		address _gSTRL,
		uint256 _epochLength,
		uint256 _firstEpochNumber,
		uint256 _firstEpochTime,
		address _authority
	) AstralAccessControlled(IAstralAuthority(_authority)) {
		require(_strl  != address(0), "Staking: zero address for STRL");
		require(_sSTRL != address(0), "Staking: zero address for sSTRL");
		require(_gSTRL != address(0), "Staking: zero address for gSTRL");

		STRL  = IERC20(_strl);
		sSTRL = IsSTRL(_sSTRL);
		gSTRL = IgSTRL(_gSTRL);

		epoch = Epoch({
			length: _epochLength,
			number: _firstEpochNumber,
			end: _firstEpochTime,
			distribute: 0
		});
	}

	// stake STRL to enter warmup
	function stake(
		address _to,
		uint256 _amount,
		bool _rebasing,
		bool _claim
	) external returns (uint256) {
		STRL.safeTransferFrom(msg.sender, address(this), _amount);
		_amount = _amount.add(rebase()); // add bounty if rebase occured
		if (_claim && warmupPeriod == 0) {
			return _send(_to, _amount, _rebasing);
		} else {
			Claim memory info = warmupInfo[_to];
			if (!info.lock) {
				require(_to == msg.sender, "External deposits for account are locked");
			}

			uint256 newGons = sSTRL.gonsForBalance(_amount); 

			warmupInfo[_to] = Claim({
				deposit: info.deposit.add(_amount),
                gons: info.gons.add(newGons),
                expiry: epoch.number.add(warmupPeriod),
                lock: info.lock
            });

			gonsInWarmup = gonsInWarmup.add(newGons);

			return _amount;
		}
	}

	// retrieve sStrl or gStrl from warmup
	function claim(address _to, bool _rebasing) public returns (uint256) {
		Claim memory info = warmupInfo[_to];

		if (!info.lock) {
			require(_to == msg.sender, "External claims for account are locked");
		}

		if (epoch.number >= info.expiry && info.expiry != 0) {
			delete warmupInfo[_to];

			gonsInWarmup = gonsInWarmup.sub(info.gons);

			return _send(_to, sSTRL.balanceForGons(info.gons), _rebasing);
		}
		return 0;
	}

	// forfeit warmup stake and retrieve STRL
	function forfeit() external returns (uint256) {
		Claim memory info = warmupInfo[msg.sender];
		delete warmupInfo[msg.sender];

		gonsInWarmup = gonsInWarmup.sub(info.gons);

		STRL.safeTransfer(msg.sender, info.deposit);

		return info.deposit;
	}

	// prevent new deposits or claims from external address
	// protection from malicious activity
	function toggleLock() external {
		warmupInfo[msg.sender].lock = !warmupInfo[msg.sender].lock;
	}

	// redeem sSTRL or gStrl for STRL
	function unstake(
		address _to,
		uint256 _amount,
		bool _trigger,  // trigger rebase
		bool _rebasing  // sStrl (true) or gStrl (false)
	) external returns (uint256 amount_) {
		amount_ = _amount;
		uint256 bounty;
		if (_trigger) {
			bounty = rebase();
		}
		
		if (_rebasing) {
			sSTRL.safeTransferFrom(msg.sender, address(this), _amount);
			amount_ = amount_.add(bounty);
		} else {
			gSTRL.burn(msg.sender, _amount); // amount was given in gSTRL terms
			amount_ = gSTRL.balanceFrom(amount_).add(bounty); // convert amount to STRL & add bounty
		}

		require(amount_ <= STRL.balanceOf(address(this)), "Insufficient STRL balance in contract");
		STRL.safeTransfer(_to, amount_);
	}

	// convert amount sSTRL into gBalance of gSTRL
	function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_) {
		sSTRL.safeTransferFrom(msg.sender, address(this), _amount);
		gBalance_ = gSTRL.balanceTo(_amount);
		gSTRL.mint(_to, gBalance_);
	}

	// convert _amount gSTRL into sBalance_ of sSTRL
	function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_) {
		gSTRL.burn(msg.sender, _amount);
		sBalance_ = gSTRL.balanceFrom(_amount);
		sSTRL.safeTransfer(_to, sBalance_);
	}

	// trigger rebase if epoch over
	function rebase() public returns (uint256) {
		uint256 bounty;
		if (epoch.end <= block.timestamp) {
			sSTRL.rebase(epoch.distribute, epoch.number);

			epoch.end = epoch.end.add(epoch.length);
			epoch.number++;

			if (address(distributor) != address(0)) {
				distributor.distribute();
				// will mint strl for this contract if there exists
				bounty = distributor.retrieveBounty();
			}
			uint256 balance = STRL.balanceOf(address(this));
			uint256 staked = sSTRL.circulatingSupply();
			if (balance <= staked.add(bounty)) {
				epoch.distribute = 0;
			} else {
				epoch.distribute = balance.sub(staked).sub(bounty);
			}
		}
		return bounty;
	}

	// send staker their amount as sSTRL or gSTRL
	function _send(
		address _to,
		uint256 _amount,
		bool _rebasing
	) internal returns (uint256) {
		if (_rebasing) {
			// send as sSTRL (equal unit as STRL)
			sSTRL.safeTransfer(_to, _amount);
			return _amount;
		} else {
			// send as gSTRL (convert units from STRL)
			gSTRL.mint(_to, gSTRL.balanceTo(_amount));
			return gSTRL.balanceTo(_amount);
		}
	}

	// returns the sSTRL index, which tracks rebase growth
	function index() public view returns (uint256) {
		return sSTRL.index();
	}

	// total supply in warmup
	function supplyInWarmup() public view returns (uint256) {
		return sSTRL.balanceForGons(gonsInWarmup);
	}

	// seconds until the next epoch begins
	function secondsToNextEpoch() external view returns (uint256) {
		return epoch.end.sub(block.timestamp);
	}

	// sets the contract address for LP staking
	function setDistributor(address _distributor) external onlyGovernor {
		distributor = IDistributor(_distributor);
		emit DistributorSet(_distributor);
	}

	// set warmup period for new stakers
	function setWarmupLength(uint256 _warmupPeriod) external onlyGovernor {
		warmupPeriod = _warmupPeriod;
		emit WarmupSet(_warmupPeriod);
	}
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.7.5;

import "../interfaces/IAstralAuthority.sol";

abstract contract AstralAccessControlled {

    event AuthorityUpdated(IAstralAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    IAstralAuthority public authority;

    constructor(IAstralAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    function setAuthority(IAstralAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
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

interface IsSTRL is IERC20 {
	event LogRebase(uint256 indexed epoch, uint256 totalSupply, uint256 rebase, uint256 index);
    event LogStakingContractUpdated(address stakingContract);

	struct Rebase {
        uint256 epoch;
        uint256 rebase; // 18 decimals
        uint256 totalStakedBefore;
        uint256 totalStakedAfter;
        uint256 amountRebased;
        uint256 index;
        uint256 blockNumberOccured;
    }

	function scaledTotalSupply() external pure returns (uint256);

    function rebase( uint256 ohmProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

	function scaledBalanceOf( address account ) external view returns (uint256);

    function gonsForBalance( uint amount ) external view returns ( uint );

    function balanceForGons( uint gons ) external view returns ( uint );

    function toG(uint amount) external view returns (uint);

    function fromG(uint amount) external view returns (uint);

    function index() external view returns ( uint );

     function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;

    function debtBalances(address _address) external view returns (uint256);
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface IDistributor {
	struct Info {
        uint256 rate; // in ten-thousands (5000 = 0.5%)
        address recipient;
    }

	struct Adjust {
        bool add;
        uint256 rate;
        uint256 target;
    }

    function distribute() external;

    function bounty() external view returns (uint256);

    function retrieveBounty() external returns (uint256);

    function nextRewardAt(uint256 _rate) external view returns (uint256);

    function nextRewardFor(address _recipient) external view returns (uint256);

    function setBounty(uint256 _bounty) external;

    function addRecipient(address _recipient, uint256 _rewardRate) external;

    function removeRecipient(uint256 _index) external;

    function setAdjustment(
        uint256 _index,
        bool _add,
        uint256 _rate,
        uint256 _target
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface IAstralStaking {
	event DistributorSet(address distributor);
    event WarmupSet(uint256 warmup);

    struct Epoch {
        uint256 length;     // in seconds
        uint256 number;     // since inception
        uint256 end;        // timestamp
        uint256 distribute; // amount
    }
    
    struct Claim {
        uint256 deposit; // if forfeiting
        uint256 gons;    // staked balance
        uint256 expiry;  // end of warmup period
        bool lock;       // prevents malicious delays for claim
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.7.5;

interface IAstralAuthority {
    
	event GovernorPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event GuardianPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event PolicyPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);
    
	event VaultPushed(
		address indexed from, 
		address indexed to, 
		bool _effectiveImmediately
	);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
}