//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

/**
 * @title InstaLite Connector
 * @dev Supply, Withdraw & Deleverage
 */

import { TokenInterface } from "../../common/interfaces.sol";
import { Basic } from "../../common/basic.sol";
import { Events } from "./events.sol";
import { IInstaLite } from "./interface.sol";

abstract contract InstaLiteConnector is Events, Basic {
	TokenInterface internal constant astethToken =
		TokenInterface(0x1982b2F5814301d4e9a8b0201555376e62F82428);
	TokenInterface internal constant stethToken =
		TokenInterface(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
	address internal constant ethVaultAddr =
		0xc383a3833A87009fD9597F8184979AF5eDFad019;

	/**
	 * @dev Supply ETH/ERC20
	 * @notice Supply a token into Instalite.
	 * @param vaultAddr Address of instaLite Contract.
	 * @param token The address of the token to be supplied. (For ETH: 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)
	 * @param amt The amount of token to be supplied. (For max: `uint256(-1)`)
	 * @param getId ID to retrieve amt.
	 * @param setIds array of IDs to store the amount of tokens deposited.
	 */
	function supply(
		address vaultAddr,
		address token,
		uint256 amt,
		uint256 getId,
		uint256[] memory setIds
	)
		public
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);
		bool isEth = token == ethAddr;
		uint256 vTokenAmt;

		if (isEth) {
			_amt = _amt == uint256(-1) ? address(this).balance : _amt;
			vTokenAmt = IInstaLite(vaultAddr).supplyEth{ value: amt }(
				address(this)
			);
		} else {
			TokenInterface tokenContract = TokenInterface(token);

			_amt = _amt == uint256(-1)
				? tokenContract.balanceOf(address(this))
				: _amt;

			approve(tokenContract, vaultAddr, _amt);
			vTokenAmt = IInstaLite(vaultAddr).supply(
				token,
				_amt,
				address(this)
			);
		}

		if (setIds.length >= 2) {
			setUint(setIds[0], _amt);
			setUint(setIds[1], vTokenAmt);
		}

		_eventName = "LogSupply(address,address,uint256,uint256,uint256,uint256[])";
		_eventParam = abi.encode(
			vaultAddr,
			token,
			vTokenAmt,
			_amt,
			getId,
			setIds
		);
	}

	/**
	 * @dev Withdraw ETH/ERC20
	 * @notice Withdraw deposited tokens from Instalite.
	 * @param vaultAddr Address of vaultAddress Contract.
	 * @param amt The amount of the token to withdraw.
	 * @param getId ID to retrieve amt.
	 * @param setIds array of IDs to stores the amount of tokens withdrawn.
	 */
	function withdraw(
		address vaultAddr,
		uint256 amt,
		uint256 getId,
		uint256[] memory setIds
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		uint256 vTokenAmt = IInstaLite(vaultAddr).withdraw(_amt, address(this));

		if (setIds.length >= 2) {
			setUint(setIds[0], _amt);
			setUint(setIds[1], vTokenAmt);
		}

		_eventName = "LogWithdraw(address,uint256,uint256,uint256,uint256[])";
		_eventParam = abi.encode(vaultAddr, _amt, vTokenAmt, getId, setIds);
	}

	/**
	 * @dev Deleverage vault. Pays back ETH debt and get stETH collateral. 1:1 swap of ETH to stETH
	 * @notice Deleverage Instalite vault.
	 * @param vaultAddr Address of vaultAddress Contract.
	 * @param amt The amount of the token to deleverage.
	 * @param getId ID to retrieve amt.
	 * @param setId ID to set amt.
	 */
	function deleverage(
		address vaultAddr,
		uint256 amt,
		uint256 getId,
		uint256 setId
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		uint256 _amt = getUint(getId, amt);

		uint256 initialBal = astethToken.balanceOf(address(this));

		approve(TokenInterface(wethAddr), vaultAddr, _amt);

		IInstaLite(vaultAddr).deleverage(_amt);

		uint256 finalBal = astethToken.balanceOf(address(this));

		require(amt <= (1e9 + finalBal - initialBal), "lack-of-steth");

		setUint(setId, _amt);

		_eventName = "LogDeleverage(address,uint256,uint256,uint256)";
		_eventParam = abi.encode(vaultAddr, _amt, getId, setId);
	}

	/**
	 * @dev Deleverage and Withdraw vault. Pays back weth debt and gets steth collateral (aSteth).
	 * @notice Deleverage Instalite vault.
	 * @param vaultAddr Address of vaultAddress Contract.
	 * @param deleverageAmt The amount of the weth to deleverage.
	 * @param withdrawAmt The amount of the token to withdraw.
	 * @param getIds IDs to retrieve amts.
	 * @param setIds IDs to set amts.
	 */
	function deleverageAndWithdraw(
		address vaultAddr,
		uint256 deleverageAmt,
		uint256 withdrawAmt,
		uint256[] memory getIds,
		uint256[] memory setIds
	)
		external
		payable
		returns (string memory _eventName, bytes memory _eventParam)
	{
		if (getIds.length >= 2) {
			deleverageAmt = getUint(getIds[0], deleverageAmt);
			withdrawAmt = getUint(getIds[1], withdrawAmt);
		}

		uint256 _astethAmt;
		uint256 _ethAmt;
		uint256 _stethAmt;
		uint256 _tokenAmt;

		approve(TokenInterface(wethAddr), vaultAddr, deleverageAmt);
		if (vaultAddr == ethVaultAddr) {
			uint256 initialBalAsteth = astethToken.balanceOf(address(this));
			uint256 initialBalEth = address(this).balance;
			uint256 initialBalSteth = stethToken.balanceOf(address(this));

			IInstaLite(vaultAddr).deleverageAndWithdraw(
				deleverageAmt,
				withdrawAmt,
				address(this)
			);

			_astethAmt =
				astethToken.balanceOf(address(this)) -
				initialBalAsteth;
			_ethAmt = address(this).balance - initialBalEth;
			_stethAmt = stethToken.balanceOf(address(this)) - initialBalSteth;
			require(deleverageAmt <= (1e9 + _astethAmt), "lack-of-steth");

			if (setIds.length >= 3) {
				setUint(setIds[0], _astethAmt);
				setUint(setIds[1], _ethAmt);
				setUint(setIds[2], _stethAmt);
			}
		} else {
			TokenInterface tokenContract = TokenInterface(
				IInstaLite(vaultAddr).token()
			);

			uint256 initialBalAsteth = astethToken.balanceOf(address(this));
			uint256 initialBalToken = tokenContract.balanceOf(address(this));

			IInstaLite(vaultAddr).deleverageAndWithdraw(
				deleverageAmt,
				withdrawAmt,
				address(this)
			);

			_astethAmt =
				astethToken.balanceOf(address(this)) -
				initialBalAsteth;
			_tokenAmt =
				tokenContract.balanceOf(address(this)) -
				initialBalToken;
			require(deleverageAmt <= (1e9 + _astethAmt), "lack-of-steth");

			if (setIds.length >= 2) {
				setUint(setIds[0], _astethAmt);
				setUint(setIds[1], _tokenAmt);
			}
		}

		_eventName = "LogDeleverageAndWithdraw(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256[],uint256[])";
		_eventParam = abi.encode(
			vaultAddr,
			deleverageAmt,
			withdrawAmt,
			_astethAmt,
			_ethAmt,
			_stethAmt,
			_tokenAmt,
			getIds,
			setIds
		);
	}
}

contract ConnectV2InstaLite is InstaLiteConnector {
	string public constant name = "InstaLite-v1.1";
}

//SPDX-License-Identifier: MIT
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

contract Events {
	event LogSupply(
		address vaultAddr,
		address token,
		uint256 vTokenAmt,
		uint256 amt,
		uint256 getId,
		uint256[] setIds
	);
	event LogWithdraw(
		address vaultAddr,
		uint256 amt,
		uint256 vTokenAmt,
		uint256 getId,
		uint256[] setIds
	);

	event LogDeleverage(
		address vaultAddr,
		uint256 amt,
		uint256 getId,
		uint256 setId
	);

	event LogDeleverageAndWithdraw(
		address vaultAddr,
		uint256 deleverageAmt,
		uint256 withdrawAmount,
		uint256 stETHAmt,
		uint256 tokenAmt,
		uint256[] getIds,
		uint256[] setIds
	);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface IInstaLite {
	function supplyEth(address to_) external payable returns (uint256);

	function supply(
		address token_,
		uint256 amount_,
		address to_
	) external returns (uint256);

	function withdraw(uint256 amount_, address to_) external returns (uint256);

	function deleverage(uint256 amt_) external;

	function deleverageAndWithdraw(
		uint256 deleverageAmt_,
		uint256 withdrawAmount_,
		address to_
	) external;

	function token() external view returns (address);
}

//SPDX-License-Identifier: MIT
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