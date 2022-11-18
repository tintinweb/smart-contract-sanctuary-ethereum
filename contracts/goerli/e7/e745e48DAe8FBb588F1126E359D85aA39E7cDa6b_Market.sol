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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
pragma solidity =0.8.10;

interface IBet {
    function mint(address to) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./SignatureLib.sol";

interface IMarket {
	function getFee() external view returns (uint8);

	function getTotalInPlay() external view returns (uint256);

	function getInPlayCount() external view returns (uint256);

	function getTotalExposure() external view returns (uint256);

	function getBetByIndex(uint256 index)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			bool,
			address
		);

	function getOdds(
		int256 wager,
		int256 odds,
		bytes32 propositionId
	) external view returns (int256);

	function getOracleAddress() external view returns (address);

	function getPotentialPayout(
		bytes32 propositionId,
		uint256 wager,
		uint256 odds
	) external view returns (uint256);

	function getVaultAddress() external view returns (address);

	function back(
		bytes32 nonce,
		bytes32 propositionId,
		bytes32 marketId,
		uint256 wager,
		uint256 odds,
		uint256 close,
		uint256 end,
		SignatureLib.Signature calldata sig
	) external returns (uint256);

	function settle(uint256 index) external;

	// function settleMarket(
	//     uint256 from,
	//     uint256 to,
	//     bytes32 marketId
	// ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

// Binary Oracle
interface IOracle {
    function checkResult(
        bytes32 marketId,
        bytes32 propositionId
    ) external view returns (bool);

    function getResult(bytes32 marketId) external view returns (bytes32);

    function setResult(
        bytes32 marketId,
        bytes32 propositionId,
        bytes32 sig
    ) external;

    event ResultSet(bytes32 marketId, bytes32 propositionId);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IVault is IERC20Metadata {
    function asset() external view returns (IERC20Metadata assetTokenAddress);

    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);

    function getPerformance() external view returns (uint256);

    function setMarket(address market, uint256 max) external;

    function totalAssets() external view returns (uint256);

    function withdraw(uint256 shares) external;

    event Deposit(address indexed who, uint256 value);
    event Withdraw(address indexed who, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBet} from "./IBet.sol";
import "./IVault.sol";
import "./IMarket.sol";
import "./IOracle.sol";
import "./SignatureLib.sol";

// Put these in the ERC721 contract
struct Bet {
	bytes32 propositionId;
	bytes32 marketId;
	uint256 amount;
	uint256 payout;
	uint256 payoutDate;
	bool settled;
	address owner;
}

contract Market is Ownable, IMarket {
	uint256 private constant MAX = 32;
	int256 private constant PRECISION = 1_000;
	uint8 private immutable _fee;
	IVault private immutable _vault;
	address private immutable _self;
	IOracle private immutable _oracle;

	uint256 private _inplayCount; // running count of bets
	Bet[] private _bets;

	// MarketID => Bets Indexes
	mapping(bytes32 => uint256[]) private _marketBets;

	// MarketID => amount bet
	mapping(bytes32 => uint256) private _marketTotal;

	// MarketID => PropositionID => amount bet
	mapping(bytes32 => mapping(uint16 => uint256)) private _marketBetAmount;

	// PropositionID => amount bet
	mapping(bytes32 => uint256) private _potentialPayout;

	uint256 private _totalInPlay;
	uint256 private _totalExposure;

	// Can claim after this period regardless
	uint256 public immutable timeout;
	uint256 public immutable min;

	mapping(address => uint256) private _workerfees;

	function getFee() external view returns (uint8) {
		return _fee;
	}

	function getTotalInPlay() external view returns (uint256) {
		return _totalInPlay;
	}

	function getInPlayCount() external view returns (uint256) {
		return _inplayCount;
	}

	function getCount() external view returns (uint256) {
		return _bets.length;
	}

	function getTotalExposure() external view returns (uint256) {
		return _totalExposure;
	}

	function getOracleAddress() external view returns (address) {
		return address(_oracle);
	}

	function getVaultAddress() external view returns (address) {
		return address(_vault);
	}

	function getExpiry(uint64 id) external view returns (uint256) {
		return _getExpiry(id);
	}

	function getMarketTotal(bytes32 marketId) external view returns (uint256) {
		return _marketTotal[marketId];
	}

	function _getExpiry(uint64 id) private view returns (uint256) {
		return _bets[id].payoutDate + timeout;
	}

	constructor(
		IVault vault,
		uint8 fee,
		address oracle
	) {
		require(address(vault) != address(0), "Invalid address");
		_self = address(this);
		_vault = vault;
		_fee = fee;
		_oracle = IOracle(oracle);

		timeout = 30 days;
		min = 1 hours;
	}

	function getBetByIndex(uint256 index)
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			bool,
			address
		)
	{
		return _getBet(index);
	}

	function _getBet(uint256 index)
		private
		view
		returns (
			uint256,
			uint256,
			uint256,
			bool,
			address
		)
	{
		Bet memory bet = _bets[index];
		return (bet.amount, bet.payout, bet.payoutDate, bet.settled, bet.owner);
	}

	function getOdds(
		int256 wager,
		int256 odds,
		bytes32 propositionId
	) external view returns (int256) {
		if (wager == 0 || odds == 0) return 0;

		return _getOdds(wager, odds, propositionId);
	}

	function _getOdds(
		int256 wager,
		int256 odds,
		bytes32 propositionId
	) private view returns (int256) {
		int256 p = int256(_vault.totalAssets()); //TODO: check that typecasting to a signed int is safe

		if (p == 0) {
			return 0;
		}

		// f(wager) = odds - odds*(wager/pool)
		if (_potentialPayout[propositionId] > uint256(p)) {
			return 0;
		}

		// do not include this guy in the return
		p -= int256(_potentialPayout[propositionId]);

		return odds - ((odds * ((wager * PRECISION) / p)) / PRECISION);
	}

	function getPotentialPayout(
		bytes32 propositionId,
		uint256 wager,
		uint256 odds
	) external view returns (uint256) {
		return _getPayout(propositionId, wager, odds);
	}

	function _getPayout(
		bytes32 propositionId,
		uint256 wager,
		uint256 odds
	) private view returns (uint256) {
		assert(odds > 0);
		assert(wager > 0);

		// add underlying to the market
		int256 trueOdds = _getOdds(int256(wager), int256(odds), propositionId);
		if (trueOdds == 0) {
			return 0;
		}

		return (uint256(trueOdds) * wager) / 1_000_000;
	}

	function back(
		bytes32 nonce,
		bytes32 propositionId,
		bytes32 marketId,
		uint256 wager,
		uint256 odds,
		uint256 close,
		uint256 end,
		SignatureLib.Signature calldata signature
	) external returns (uint256) {
		require(
			end > block.timestamp && block.timestamp > close,
			"back: Invalid date"
		);

		// check the oracle first
		require(
			IOracle(_oracle).checkResult(marketId, propositionId) == false,
			"back: Oracle result already set for this market"
		);

		IERC20Metadata underlying = _vault.asset();

		// add underlying to the market
		uint256 payout = _getPayout(propositionId, wager, odds);

		// escrow
		underlying.transferFrom(msg.sender, _self, wager);
		underlying.transferFrom(address(_vault), _self, (payout - wager));

		// add to the market
		_marketTotal[marketId] += wager;

		_bets.push(
			Bet(propositionId, marketId, wager, payout, end, false, msg.sender)
		);
		uint256 count = _bets.length;
		uint256 index = count - 1;
		_marketBets[marketId].push(count);

		_totalInPlay += wager;
		_totalExposure += (payout - wager);
		_inplayCount++;

		emit Placed(index, propositionId, marketId, wager, payout, msg.sender);

		return count; // token ID
	}

	function settle(uint256 index) external {
		Bet memory bet = _bets[index];
		require(bet.settled == false, "settle: Bet has already settled");
		bool result = IOracle(_oracle).checkResult(
			bet.marketId,
			bet.propositionId
		);
		_settle(index, result);
	}

	// function settleMarket(
	//     uint256 from,
	//     uint256 to,
	//     bytes32 marketId
	// ) external {
	//     for (uint256 i = from; i < to; i++) {
	//         uint256 index = _marketBets[marketId][i];

	//         if (!_bets[index].settled) {
	//             bytes32 propositionId = IOracle(_oracle).getResult(
	//                 _bets[index].marketId
	//             );

	//             if (_bets[index].propositionId == propositionId) {
	//                 _settle(index, true);
	//             } else {
	//                 _settle(index, false);
	//             }
	//         }
	//     }
	// }

	function _settle(uint256 id, bool result) private {
		require(
			_bets[id].payoutDate < block.timestamp,
			"_settle: Payout date not reached"
		);

		_bets[id].settled = true;
		_totalInPlay -= _bets[id].amount;
		_totalExposure -= _bets[id].payout - _bets[id].amount;
		_inplayCount--;

		IERC20Metadata underlying = _vault.asset();

		if (result == true) {
			// Transfer the win to the punter
			underlying.transfer(_bets[id].owner, _bets[id].payout);
		}

		if (result == false) {
			// Transfer the proceeds to the vault, less market fee
			underlying.transfer(address(_vault), _bets[id].payout);
		}

		emit Settled(id, _bets[id].payout, result, _bets[id].owner);
	}

	modifier onlyMarketOwner(
		bytes32 messageHash,
		SignatureLib.Signature calldata signature
	) {
		//bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
		require(
			SignatureLib.recoverSigner(messageHash, signature) == owner(),
			"onlyMarketOwner: Invalid signature"
		);
		_;
	}

	event Placed(
		uint256 index,
		bytes32 propositionId,
		bytes32 marketId,
		uint256 amount,
		uint256 payout,
		address indexed owner
	);

	event Settled(
		uint256 id,
		uint256 payout,
		bool result,
		address indexed owner
	);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

library SignatureLib {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function recoverSigner(
        bytes32 message,
        Signature memory signature
    ) public pure returns (address) {
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        return ecrecover(prefixedHash, signature.v, signature.r, signature.s);
    }
}