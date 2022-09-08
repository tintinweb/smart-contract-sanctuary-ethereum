//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title Compound.
 * @dev Rewards.
 */

import { TokenInterface } from "../../../common/interfaces.sol";
import { Stores } from "../../../common/stores.sol";
import { Helpers } from "./helpers.sol";
import { Events } from "./events.sol";

abstract contract CompoundV3RewardsResolver is Events, Helpers {
	/**
	 * @dev Claim rewards and interests accrued in supplied/borrowed base asset.
	 * @notice Claim rewards and interests accrued.
	 * @param market The address of the market.
	 * @param setId ID stores the amount of rewards claimed.
	 */
	function claimRewards(
		address market,
		uint256 setId
	) public returns (string memory eventName_, bytes memory eventParam_) {
		uint256 rewardsOwed = cometRewards.getRewardOwed(market, address(this)).owed;
		cometRewards.claim(market, address(this), true);

		setUint(setId, rewardsOwed);

		eventName_ = "LogRewardsClaimed(address,address,uint256,uint256)";
		eventParam_ = abi.encode(market, address(this), rewardsOwed, setId);
	}

	/**
	 * @dev Claim rewards and interests accrued in supplied/borrowed base asset.
	 * @notice Claim rewards and interests accrued and transfer to dest address.
	 * @param market The address of the market.
	 * @param owner The account of which the rewards are to be claimed.
	 * @param to The account where to transfer the claimed rewards.
	 * @param setId ID stores the amount of rewards claimed.
	 */
	function claimRewardsOnBehalfOf(
		address market,
		address owner,
		address to,
		uint256 setId
	) public returns (string memory eventName_, bytes memory eventParam_) {
		//in reward token decimals
		uint256 rewardsOwed = cometRewards.getRewardOwed(market, owner).owed;
		cometRewards.claimTo(market, owner, to, true);

		setUint(setId, rewardsOwed);

		eventName_ = "LogRewardsClaimedOnBehalf(address,address,address,uint256,uint256)";
		eventParam_ = abi.encode(
			market,
			owner,
			to,
			rewardsOwed,
			setId
		);
	}
}

contract ConnectV2CompoundV3Rewards is CompoundV3RewardsResolver {
	string public name = "CompoundV3Rewards-v1.0";
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
    function allowance(address owner, address spender) external view returns (uint256);
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
pragma abicoder v2;

import { TokenInterface } from "../../../common/interfaces.sol";
import { DSMath } from "../../../common/math.sol";
import { Basic } from "../../../common/basic.sol";
import {  CometRewards } from "./interface.sol";

abstract contract Helpers is DSMath, Basic {
	CometRewards internal constant cometRewards =
		CometRewards(0x1B0e765F6224C21223AeA2af16c1C46E38885a40);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

contract Events {
	event LogRewardsClaimed(
		address indexed market,
		address indexed account,
		uint256 indexed rewardsClaimed,
		uint256 setId
	);

	event LogRewardsClaimedOnBehalf(
		address indexed market,
		address indexed owner,
		address to,
		uint256 indexed rewardsClaimed,
		uint256 setId
	);
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
pragma abicoder v2;

struct UserCollateral {
	uint128 balance;
	uint128 _reserved;
}

struct RewardOwed {
	address token;
	uint256 owed;
}

interface CometRewards {
	function claim(
		address comet,
		address src,
		bool shouldAccrue
	) external;

	function claimTo(
		address comet,
		address src,
		address to,
		bool shouldAccrue
	) external;

	function getRewardOwed(address comet, address account)
		external
		returns (RewardOwed memory);

	function rewardsClaimed(address cometProxy, address account)
		external
		view
		returns (uint256);
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