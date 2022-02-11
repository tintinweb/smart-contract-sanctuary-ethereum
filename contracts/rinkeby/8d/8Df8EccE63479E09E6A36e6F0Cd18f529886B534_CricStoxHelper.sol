/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX-License-Identifier: NONE

pragma experimental ABIEncoderV2;
pragma solidity 0.7.0;


// 
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// 
interface ICricStoxFactory {
    function getPlayerStox(address playerStox_) external view returns (bool);
    function playerStoxsLength() external view returns (uint256);
    function playerStoxAtIndex(uint256 index_) external view returns (address);
}

// 
interface ICricStoxMaster {
    function getSupportedToken(address token_) external view returns (bool);
    function quote(address stox_, uint256 quantity_) external view returns (uint256);
}

// 
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value) external returns (bool);

  function mint(address account_, uint256 amount_) external returns (bool);

  function burn(address account_, uint256 amount_) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
}

// 
contract CricStoxHelper {
    using SafeMath for uint256;

    address public factoryAddress;
    address public cricStoxMasterAddress;

    struct StoxPrice {
        address stox;
        uint256 price;
    }

    struct UserHolding {
        address stox;
        uint256 balance;
    }

    constructor(address factoryAddress_, address cricStoxMasterAddress_) {
        factoryAddress = factoryAddress_;
        cricStoxMasterAddress = address(cricStoxMasterAddress_);
    }

    function getPriceForAllStoxs() public view returns (address[] memory, uint256[] memory) {
        uint256 numOfStoxs = ICricStoxFactory(factoryAddress)
            .playerStoxsLength();
        address[] memory stoxs = new address[](numOfStoxs);
        uint[]    memory prices = new uint[](numOfStoxs);
        for (uint256 i = 0; i < numOfStoxs; i++) {
            address currentStox = ICricStoxFactory(factoryAddress).playerStoxAtIndex(i);
            uint256 price = ICricStoxMaster(cricStoxMasterAddress).quote(currentStox, 0);
            stoxs[i] = currentStox;
            prices[i] = price;
        }
        return (stoxs, prices);
    }

    function getUserStoxsHoldings(address user_) public view returns (UserHolding[] memory) {
        uint256 numOfStoxs = ICricStoxFactory(factoryAddress)
            .playerStoxsLength();
        uint256 count = 0;
        address[] memory stoxs = new address[](numOfStoxs);
        uint256[] memory balances = new uint256[](numOfStoxs);
        for (uint256 i = 0; i < numOfStoxs; i++) {
            address currentStox = ICricStoxFactory(factoryAddress).playerStoxAtIndex(i);
            uint256 blnc = IERC20(currentStox).balanceOf(user_);
            if (blnc > 0) {
                stoxs[count] = currentStox;
                balances[count] = blnc;
                count = count + 1;
            }
        }
        UserHolding[] memory userHoldings = new UserHolding[](count);
        for (uint256 i = 0; i < count; i++) {
            userHoldings[i] = UserHolding({ stox: stoxs[i], balance: balances[i]});
        }
        return userHoldings;
    }
}