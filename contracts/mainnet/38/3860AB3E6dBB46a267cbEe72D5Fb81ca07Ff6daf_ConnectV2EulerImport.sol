//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import "./helpers.sol";
import "./interface.sol";
import "./events.sol";

contract EulerImport is EulerHelpers {
	/**
	 * @dev Import Euler position .
	 * @notice Import EOA's Euler position to DSA's Euler position
	 * @param userAccount EOA address
	 * @param sourceId Sub-account id of "EOA" from which the funds will be transferred
	 * @param targetId Sub-account id of "DSA" to which the funds will be transferred
	 * @param inputData The struct containing all the neccessary input data
	 */
	function importEuler(
		address userAccount,
		uint256 sourceId,
		uint256 targetId,
		ImportInputData memory inputData
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		require(sourceId < 256 && targetId < 256, "Id should be less than 256");

		(_eventName, _eventParam) = _importEuler(
			userAccount,
			sourceId,
			targetId,
			inputData
		);
	}

	/**
	 * @dev Import Euler position .
	 * @notice Import EOA's Euler position to DSA's Euler position
	 * @param userAccount EOA address
	 * @param sourceId Sub-account id of "EOA" from which the funds will be transferred
	 * @param targetId Sub-account id of "DSA" to which the funds will be transferred
	 * @param inputData The struct containing all the neccessary input data
	 */
	function _importEuler(
		address userAccount,
		uint256 sourceId,
		uint256 targetId,
		ImportInputData memory inputData
	) internal returns (string memory _eventName, bytes memory _eventParam) {
		require(inputData._supplyTokens.length > 0, "0-length-not-allowed");
		require(
			AccountInterface(address(this)).isAuth(userAccount),
			"user-account-not-auth"
		);
		require(
			inputData._enterMarket.length == inputData._supplyTokens.length,
			"lengths-not-same"
		);

		ImportData memory data;
		ImportHelper memory helper;

		helper.sourceAccount = getSubAccountAddress(userAccount, sourceId);
		helper.targetAccount = getSubAccountAddress(address(this), targetId);

		// BorrowAmts will be in underlying token decimals
		data = getBorrowAmounts(helper.sourceAccount, inputData, data);

		// SupplyAmts will be in 18 decimals
		data = getSupplyAmounts(helper.sourceAccount, inputData, data);

		helper.supplylength = data.supplyTokens.length;
		helper.borrowlength = data.borrowTokens.length;
		uint16 enterMarketsLength = 0;

		for (uint16 i = 0; i < inputData._enterMarket.length; i++) {
			if (inputData._enterMarket[i]) {
				++enterMarketsLength;
			}
		}

		helper.totalExecutions =
			helper.supplylength +
			enterMarketsLength +
			helper.borrowlength;

		IEulerExecute.EulerBatchItem[]
			memory items = new IEulerExecute.EulerBatchItem[](
				helper.totalExecutions
			);

		uint16 k = 0;

		for (uint16 i = 0; i < helper.supplylength; i++) {
			items[k++] = IEulerExecute.EulerBatchItem({
				allowError: false,
				proxyAddr: address(data.eTokens[i]),
				data: abi.encodeWithSignature(
					"transferFrom(address,address,uint256)",
					helper.sourceAccount,
					helper.targetAccount,
					data.supplyAmts[i]
				)
			});

			if (inputData._enterMarket[i]) {
				items[k++] = IEulerExecute.EulerBatchItem({
					allowError: false,
					proxyAddr: address(markets),
					data: abi.encodeWithSignature(
						"enterMarket(uint256,address)",
						targetId,
						data.supplyTokens[i]
					)
				});
			}
		}

		for (uint16 j = 0; j < helper.borrowlength; j++) {
			items[k++] = IEulerExecute.EulerBatchItem({
				allowError: false,
				proxyAddr: address(data.dTokens[j]),
				data: abi.encodeWithSignature(
					"transferFrom(address,address,uint256)",
					helper.sourceAccount,
					helper.targetAccount,
					data.borrowAmts[j]
				)
			});
		}

		address[] memory deferLiquidityChecks = new address[](2);
		deferLiquidityChecks[0] = helper.sourceAccount;
		deferLiquidityChecks[1] = helper.targetAccount;

		eulerExec.batchDispatch(items, deferLiquidityChecks);

		_eventName = "LogEulerImport(address,uint256,uint256,address[],uint256[],address[],uint256[],bool[])";
		_eventParam = abi.encode(
			userAccount,
			sourceId,
			targetId,
			inputData._supplyTokens,
			data.supplyAmts,
			inputData._borrowTokens,
			data.borrowAmts,
			inputData._enterMarket
		);
	}
}

contract ConnectV2EulerImport is EulerImport {
	string public constant name = "Euler-Import-v1.0";
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;
import { TokenInterface, AccountInterface } from "../../../common/interfaces.sol";
import { Basic } from "../../../common/basic.sol";
import "./interface.sol";

contract EulerHelpers is Basic {
	/**
	 * @dev Euler's Market Module
	 */
	IEulerMarkets internal constant markets =
		IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

	/**
	 * @dev Euler's Execution Module
	 */
	IEulerExecute internal constant eulerExec =
		IEulerExecute(0x59828FdF7ee634AaaD3f58B19fDBa3b03E2D9d80);

	/**
	 * @dev Compute sub account address.
	 * @notice Compute sub account address from sub-account id
	 * @param primary primary address
	 * @param subAccountId sub-account id whose address needs to be computed
	 */
	function getSubAccountAddress(address primary, uint256 subAccountId)
		public
		pure
		returns (address)
	{
		require(subAccountId < 256, "sub-account-id-too-big");
		return address(uint160(primary) ^ uint160(subAccountId));
	}

	struct ImportInputData {
		address[] _supplyTokens;
		address[] _borrowTokens;
		bool[] _enterMarket;
	}

	struct ImportData {
		address[] supplyTokens;
		address[] borrowTokens;
		EulerTokenInterface[] eTokens;
		EulerTokenInterface[] dTokens;
		uint256[] supplyAmts;
		uint256[] borrowAmts;
	}

	struct ImportHelper {
		uint256 supplylength;
		uint256 borrowlength;
		uint256 totalExecutions;
		address sourceAccount;
		address targetAccount;
	}

	function getSupplyAmounts(
		address userAccount, // user's EOA sub-account address
		ImportInputData memory inputData,
		ImportData memory data
	) internal view returns (ImportData memory) {
		data.supplyAmts = new uint256[](inputData._supplyTokens.length);
		data.supplyTokens = new address[](inputData._supplyTokens.length);
		data.eTokens = new EulerTokenInterface[](
			inputData._supplyTokens.length
		);
		uint256 length_ = inputData._supplyTokens.length;

		for (uint256 i = 0; i < length_; i++) {
			address token_ = inputData._supplyTokens[i] == ethAddr
				? wethAddr
				: inputData._supplyTokens[i];
			data.supplyTokens[i] = token_;
			data.eTokens[i] = EulerTokenInterface(
				markets.underlyingToEToken(token_)
			);
			data.supplyAmts[i] = data.eTokens[i].balanceOf(userAccount); //All 18 dec
		}

		return data;
	}

	function getBorrowAmounts(
		address userAccount, // user's EOA sub-account address
		ImportInputData memory inputData,
		ImportData memory data
	) internal view returns (ImportData memory) {
		uint256 borrowTokensLength_ = inputData._borrowTokens.length;

		if (borrowTokensLength_ > 0) {
			data.borrowTokens = new address[](borrowTokensLength_);
			data.dTokens = new EulerTokenInterface[](borrowTokensLength_);
			data.borrowAmts = new uint256[](borrowTokensLength_);

			for (uint256 i = 0; i < borrowTokensLength_; i++) {
				address _token = inputData._borrowTokens[i] == ethAddr
					? wethAddr
					: inputData._borrowTokens[i];

				data.borrowTokens[i] = _token;
				data.dTokens[i] = EulerTokenInterface(
					markets.underlyingToDToken(_token)
				);
				data.borrowAmts[i] = data.dTokens[i].balanceOf(userAccount);
			}
		}
		return data;
	}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

interface EulerTokenInterface {
	function balanceOf(address _user) external view returns (uint256);

	function transferFrom(
		address,
		address,
		uint256
	) external returns (bool);

	function allowance(address, address) external returns (uint256);
}

interface IEulerMarkets {
	function enterMarket(uint256 subAccountId, address newMarket) external;

	function getEnteredMarkets(address account)
		external
		view
		returns (address[] memory);

	function exitMarket(uint256 subAccountId, address oldMarket) external;

	function underlyingToEToken(address underlying)
		external
		view
		returns (address);

	function underlyingToDToken(address underlying)
		external
		view
		returns (address);
}

interface IEulerExecute {
	struct EulerBatchItem {
		bool allowError;
		address proxyAddr;
		bytes data;
	}

	struct EulerBatchItemResponse {
		bool success;
		bytes result;
	}

	function batchDispatch(
		EulerBatchItem[] calldata items,
		address[] calldata deferLiquidityChecks
	) external;

	function deferLiquidityCheck(address account, bytes memory data) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract Events {
	event LogEulerImport(
		address user,
		uint256 sourceId,
		uint256 targetId,
		address[] supplyTokens,
		uint256[] supplyAmounts,
		address[] borrowTokens,
		uint256[] borrowAmounts,
		bool[] enterMarket
	);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma abicoder v2;

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
    function cast(
        string[] calldata _targetNames,
        bytes[] calldata _datas,
        address _origin
    ) external payable returns (bytes32[] memory responses);
}

interface ListInterface {
    function accountID(address) external returns (uint64);
}

interface InstaConnectors {
    function isConnectors(string[] calldata) external returns (bool, address[] memory);
}

//SPDX-License-Identifier: MIT
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import { MemoryInterface, InstaMapping, ListInterface, InstaConnectors } from "./interfaces.sol";


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
   * @dev Return InstaList Address
   */
  ListInterface internal constant instaList = ListInterface(0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb);

  /**
	 * @dev Return connectors registry address
	 */
	InstaConnectors internal constant instaConnectors = InstaConnectors(0x97b0B3A8bDeFE8cB9563a3c610019Ad10DB8aD11);

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

//SPDX-License-Identifier: MIT
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

  function toUint(int256 x) internal pure returns (uint256) {
      require(x >= 0, "int-overflow");
      return uint256(x);
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
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