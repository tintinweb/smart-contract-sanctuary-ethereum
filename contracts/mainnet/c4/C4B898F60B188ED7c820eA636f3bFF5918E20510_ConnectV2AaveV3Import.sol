pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
/**
 * @title Aave v3 import connector .
 * @dev  Import EOA's aave V3 position to DSA's aave v3 position
 */
import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import { AaveInterface, ATokenInterface } from "./interface.sol";
import "./helpers.sol";
import "./events.sol";

contract AaveV3ImportResolver is AaveHelpers {
	function _importAave(address userAccount, ImportInputData memory inputData)
		internal
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(
			AccountInterface(address(this)).isAuth(userAccount),
			"user-account-not-auth"
		);

		require(inputData.supplyTokens.length > 0, "0-length-not-allowed");

		ImportData memory data;

		AaveInterface aave = AaveInterface(aaveProvider.getPool());

		data = getBorrowAmounts(userAccount, aave, inputData, data);
		data = getSupplyAmounts(userAccount, inputData, data);

		//  payback borrowed amount;
		_PaybackStable(
			data._borrowTokens.length,
			aave,
			data._borrowTokens,
			data.stableBorrowAmts,
			userAccount
		);
		_PaybackVariable(
			data._borrowTokens.length,
			aave,
			data._borrowTokens,
			data.variableBorrowAmts,
			userAccount
		);

		//  transfer atokens to this address;
		_TransferAtokens(
			data._supplyTokens.length,
			aave,
			data.aTokens,
			data.supplyAmts,
			data._supplyTokens,
			userAccount
		);

		// borrow assets after migrating position
		if (data.convertStable) {
			_BorrowVariable(
				data._borrowTokens.length,
				aave,
				data._borrowTokens,
				data.totalBorrowAmtsWithFee
			);
		} else {
			_BorrowStable(
				data._borrowTokens.length,
				aave,
				data._borrowTokens,
				data.stableBorrowAmtsWithFee
			);
			_BorrowVariable(
				data._borrowTokens.length,
				aave,
				data._borrowTokens,
				data.variableBorrowAmtsWithFee
			);
		}

		_eventName = "LogAaveV3Import(address,bool,address[],address[],uint256[],uint256[],uint256[],uint256[])";
		_eventParam = abi.encode(
			userAccount,
			inputData.convertStable,
			inputData.supplyTokens,
			inputData.borrowTokens,
			inputData.flashLoanFees,
			data.supplyAmts,
			data.stableBorrowAmts,
			data.variableBorrowAmts
		);
	}

	/**
	 * @dev Import aave V3 position .
	 * @notice Import EOA's aave V3 position to DSA's aave v3 position
	 * @param userAccount The address of the EOA from which aave position will be imported
	 * @param inputData The struct containing all the neccessary input data
	 */
	function importAave(address userAccount, ImportInputData memory inputData)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		(_eventName, _eventParam) = _importAave(userAccount, inputData);
	}
}

contract ConnectV2AaveV3Import is AaveV3ImportResolver {
	string public constant name = "Aave-v3-import-v1";
}

pragma solidity ^0.7.0;

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
}

interface MemoryInterface {
    function getUint(uint id) external returns (uint num);
    function setUint(uint id, uint val) external;
}

interface InstaMapping {
    function cTokenMapping(address) external view returns (address);
    function gemJoinMapping(bytes32) external view returns (address);
}

interface AccountInterface {
    function enable(address) external;
    function disable(address) external;
    function isAuth(address) external view returns (bool);
}

pragma solidity ^0.7.0;

interface AaveInterface {
	function supply(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	function withdraw(
		address _asset,
		uint256 _amount,
		address _to
	) external;

	function borrow(
		address _asset,
		uint256 _amount,
		uint256 _interestRateMode,
		uint16 _referralCode,
		address _onBehalfOf
	) external;

	function repay(
		address _asset,
		uint256 _amount,
		uint256 _rateMode,
		address _onBehalfOf
	) external;

	function setUserUseReserveAsCollateral(
		address _asset,
		bool _useAsCollateral
	) external;

	function swapBorrowRateMode(address _asset, uint256 _rateMode) external;
}

interface ATokenInterface {
	function scaledBalanceOf(address _user) external view returns (uint256);

	function isTransferAllowed(address _user, uint256 _amount)
		external
		view
		returns (bool);

	function balanceOf(address _user) external view returns (uint256);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function allowance(address, address) external returns (uint256);
}

interface AavePoolProviderInterface {
	function getPool() external view returns (address);
}

interface AaveDataProviderInterface {
	function getReserveTokensAddresses(address _asset)
		external
		view
		returns (
			address aTokenAddress,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		);

	function getUserReserveData(address _asset, address _user)
		external
		view
		returns (
			uint256 currentATokenBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableBorrowRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool usageAsCollateralEnabled
		);
}

interface AaveAddressProviderRegistryInterface {
	function getAddressesProvidersList()
		external
		view
		returns (address[] memory);
}

pragma solidity ^0.7.0;

import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import { AaveInterface, AavePoolProviderInterface, AaveDataProviderInterface } from "./interface.sol";
import "./events.sol";
import "./interface.sol";

abstract contract Helper is DSMath, Basic {
	/**
	 * @dev Aave referal code
	 */
	uint16 internal constant referalCode = 3228;

	/**
	 * @dev Aave Lending Pool Provider
	 */
	AavePoolProviderInterface internal constant aaveProvider =
		AavePoolProviderInterface(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

	/**
	 * @dev Aave Protocol Data Provider
	 */
	AaveDataProviderInterface internal constant aaveData =
		AaveDataProviderInterface(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

	function getIsColl(address token, address user)
		internal
		view
		returns (bool isCol)
	{
		(, , , , , , , , isCol) = aaveData.getUserReserveData(token, user);
	}

	struct ImportData {
		address[] _supplyTokens;
		address[] _borrowTokens;
		ATokenInterface[] aTokens;
		uint256[] supplyAmts;
		uint256[] variableBorrowAmts;
		uint256[] variableBorrowAmtsWithFee;
		uint256[] stableBorrowAmts;
		uint256[] stableBorrowAmtsWithFee;
		uint256[] totalBorrowAmts;
		uint256[] totalBorrowAmtsWithFee;
		bool convertStable;
	}

	struct ImportInputData {
		address[] supplyTokens;
		address[] borrowTokens;
		bool convertStable;
		uint256[] flashLoanFees;
	}
}

contract AaveHelpers is Helper {
	function getBorrowAmount(address _token, address userAccount)
		internal
		view
		returns (uint256 stableBorrow, uint256 variableBorrow)
	{
		(
			,
			address stableDebtTokenAddress,
			address variableDebtTokenAddress
		) = aaveData.getReserveTokensAddresses(_token);

		stableBorrow = ATokenInterface(stableDebtTokenAddress).balanceOf(
			userAccount
		);
		variableBorrow = ATokenInterface(variableDebtTokenAddress).balanceOf(
			userAccount
		);
	}

	function getBorrowAmounts(
		address userAccount,
		AaveInterface aave,
		ImportInputData memory inputData,
		ImportData memory data
	) internal returns (ImportData memory) {
		if (inputData.borrowTokens.length > 0) {
			data._borrowTokens = new address[](inputData.borrowTokens.length);
			data.variableBorrowAmts = new uint256[](
				inputData.borrowTokens.length
			);
			data.variableBorrowAmtsWithFee = new uint256[](
				inputData.borrowTokens.length
			);
			data.stableBorrowAmts = new uint256[](
				inputData.borrowTokens.length
			);
			data.stableBorrowAmtsWithFee = new uint256[](
				inputData.borrowTokens.length
			);
			data.totalBorrowAmts = new uint256[](inputData.borrowTokens.length);
			data.totalBorrowAmtsWithFee = new uint256[](
				inputData.borrowTokens.length
			);
			for (uint256 i = 0; i < inputData.borrowTokens.length; i++) {
				for (uint256 j = i; j < inputData.borrowTokens.length; j++) {
					if (j != i) {
						require(
							inputData.borrowTokens[i] !=
								inputData.borrowTokens[j],
							"token-repeated"
						);
					}
				}
			}
			for (uint256 i = 0; i < inputData.borrowTokens.length; i++) {
				address _token = inputData.borrowTokens[i] == ethAddr
					? wethAddr
					: inputData.borrowTokens[i];
				data._borrowTokens[i] = _token;

				(
					data.stableBorrowAmts[i],
					data.variableBorrowAmts[i]
				) = getBorrowAmount(_token, userAccount);

				if (data.variableBorrowAmts[i] != 0) {
					data.variableBorrowAmtsWithFee[i] = add(
						data.variableBorrowAmts[i],
						inputData.flashLoanFees[i]
					);
					data.stableBorrowAmtsWithFee[i] = data.stableBorrowAmts[i];
				} else {
					data.stableBorrowAmtsWithFee[i] = add(
						data.stableBorrowAmts[i],
						inputData.flashLoanFees[i]
					);
				}

				data.totalBorrowAmts[i] = add(
					data.stableBorrowAmts[i],
					data.variableBorrowAmts[i]
				);
				data.totalBorrowAmtsWithFee[i] = add(
					data.stableBorrowAmtsWithFee[i],
					data.variableBorrowAmtsWithFee[i]
				);

				if (data.totalBorrowAmts[i] > 0) {
					uint256 _amt = data.totalBorrowAmts[i];
					TokenInterface(_token).approve(address(aave), _amt);
				}
			}
		}
		return data;
	}

	function getSupplyAmounts(
		address userAccount,
		ImportInputData memory inputData,
		ImportData memory data
	) internal view returns (ImportData memory) {
		data.supplyAmts = new uint256[](inputData.supplyTokens.length);
		data._supplyTokens = new address[](inputData.supplyTokens.length);
		data.aTokens = new ATokenInterface[](inputData.supplyTokens.length);

		for (uint256 i = 0; i < inputData.supplyTokens.length; i++) {
			for (uint256 j = i; j < inputData.supplyTokens.length; j++) {
				if (j != i) {
					require(
						inputData.supplyTokens[i] != inputData.supplyTokens[j],
						"token-repeated"
					);
				}
			}
		}
		for (uint256 i = 0; i < inputData.supplyTokens.length; i++) {
			address _token = inputData.supplyTokens[i] == ethAddr
				? wethAddr
				: inputData.supplyTokens[i];
			(address _aToken, , ) = aaveData.getReserveTokensAddresses(_token);
			data._supplyTokens[i] = _token;
			data.aTokens[i] = ATokenInterface(_aToken);
			data.supplyAmts[i] = data.aTokens[i].balanceOf(userAccount);
		}

		return data;
	}

	function _paybackBehalfOne(
		AaveInterface aave,
		address token,
		uint256 amt,
		uint256 rateMode,
		address user
	) private {
		aave.repay(token, amt, rateMode, user);
	}

	function _PaybackStable(
		uint256 _length,
		AaveInterface aave,
		address[] memory tokens,
		uint256[] memory amts,
		address user
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_paybackBehalfOne(aave, tokens[i], amts[i], 1, user);
			}
		}
	}

	function _PaybackVariable(
		uint256 _length,
		AaveInterface aave,
		address[] memory tokens,
		uint256[] memory amts,
		address user
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_paybackBehalfOne(aave, tokens[i], amts[i], 2, user);
			}
		}
	}

	function _TransferAtokens(
		uint256 _length,
		AaveInterface aave,
		ATokenInterface[] memory atokenContracts,
		uint256[] memory amts,
		address[] memory tokens,
		address userAccount
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				uint256 _amt = amts[i];
				require(
					atokenContracts[i].transferFrom(
						userAccount,
						address(this),
						_amt
					),
					"allowance?"
				);

				if (!getIsColl(tokens[i], address(this))) {
					aave.setUserUseReserveAsCollateral(tokens[i], true);
				}
			}
		}
	}

	function _BorrowVariable(
		uint256 _length,
		AaveInterface aave,
		address[] memory tokens,
		uint256[] memory amts
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_borrowOne(aave, tokens[i], amts[i], 2);
			}
		}
	}

	function _BorrowStable(
		uint256 _length,
		AaveInterface aave,
		address[] memory tokens,
		uint256[] memory amts
	) internal {
		for (uint256 i = 0; i < _length; i++) {
			if (amts[i] > 0) {
				_borrowOne(aave, tokens[i], amts[i], 1);
			}
		}
	}

	function _borrowOne(
		AaveInterface aave,
		address token,
		uint256 amt,
		uint256 rateMode
	) private {
		aave.borrow(token, amt, rateMode, referalCode, address(this));
	}
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogAaveV3Import(
		address indexed user,
		address[] ctokens,
		string[] supplyIds,
		string[] borrowIds,
		uint256[] flashLoanFees,
		uint256[] supplyAmts,
		uint256[] borrowAmts
	);
}

pragma solidity ^0.7.0;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}

pragma solidity ^0.7.0;

import { TokenInterface } from "./interfaces.sol";
import { Stores } from "./stores.sol";
import { DSMath } from "./math.sol";

abstract contract Basic is DSMath, Stores {

    function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10 ** (18 - _dec));
    }

    function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10 ** (18 - _dec));
    }

    function getTokenBal(TokenInterface token) internal view returns(uint _amt) {
        _amt = address(token) == ethAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getTokensDec(TokenInterface buyAddr, TokenInterface sellAddr) internal view returns(uint buyDec, uint sellDec) {
        buyDec = address(buyAddr) == ethAddr ?  18 : buyAddr.decimals();
        sellDec = address(sellAddr) == ethAddr ?  18 : sellAddr.decimals();
    }

    function encodeEvent(string memory eventName, bytes memory eventParam) internal pure returns (bytes memory) {
        return abi.encode(eventName, eventParam);
    }

    function approve(TokenInterface token, address spender, uint256 amount) internal {
        try token.approve(spender, amount) {

        } catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr ? TokenInterface(wethAddr) : TokenInterface(sell);
    }

    function changeEthAddrToWethAddr(address token) internal pure returns(address tokenAddr){
        tokenAddr = token == ethAddr ? wethAddr : token;
    }

    function convertEthToWeth(bool isEth, TokenInterface token, uint amount) internal {
        if(isEth) token.deposit{value: amount}();
    }

    function convertWethToEth(bool isEth, TokenInterface token, uint amount) internal {
       if(isEth) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping } from "./interfaces.sol";


abstract contract Stores {

  /**
   * @dev Return ethereum address
   */
  address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /**
   * @dev Return Wrapped ETH address
   */
  address constant internal wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /**
   * @dev Return memory variable address
   */
  MemoryInterface constant internal instaMemory = MemoryInterface(0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F);

  /**
   * @dev Return InstaDApp Mapping Addresses
   */
  InstaMapping constant internal instaMapping = InstaMapping(0xe81F70Cc7C0D46e12d70efc60607F16bbD617E88);

  /**
   * @dev Get Uint value from InstaMemory Contract.
   */
  function getUint(uint getId, uint val) internal returns (uint returnVal) {
    returnVal = getId == 0 ? val : instaMemory.getUint(getId);
  }

  /**
  * @dev Set Uint value in InstaMemory Contract.
  */
  function setUint(uint setId, uint val) virtual internal {
    if (setId != 0) instaMemory.setUint(setId, val);
  }

}