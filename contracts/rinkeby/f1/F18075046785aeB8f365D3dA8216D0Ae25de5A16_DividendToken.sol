pragma solidity 0.4.18;

/*
  The MIT License (MIT)

  Copyright (c) 2018 Murray Software, LLC.

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/ownership/Ownable.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "snapshotable/contracts/Snapshotable.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable avoid-call-value

contract DividendToken is ERC20, Ownable, UsingSnapshotable {
  using SafeMath for uint;

  Snapshotable.Uint internal totalSupplyHistory;
  mapping(address => Snapshotable.Uint) internal balanceHistories;
  mapping(address => mapping(address => uint)) internal allowed;

  uint public ethDust;

  struct Dividend {
    ERC20 token;
    uint amount;
  }

  Dividend[] internal dividends;

  event Withdrawal(address indexed holder, ERC20 indexed token, uint amount);
  event DividendIssued(ERC20 indexed token, uint amount);

  /*
   * ERC20
   */
  function totalSupply() public view returns (uint) {
    return totalSupplyHistory.lastValue();
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balanceHistories[_owner].lastValue();
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function approveAndCall(address _spender, uint256 _value, bytes _data) public payable returns (bool success) {
    require(_spender != address(this));
    approve(_spender, _value);
    require(_spender.call.value(msg.value)(_data));
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /*
   * Dividend support
   */
  function dividend(ERC20 token, uint amount) public onlyOwner {
    // since we wont give this out, don't transfer it in and decrement the dividend amount
    amount -= amount % totalSupply();
    require(token.transferFrom(msg.sender, address(this), amount));
    dividends.push(Dividend(token, amount));
    DividendIssued(token, amount);
  }

  function ethDividend() public payable {
    uint dust = msg.value % totalSupply();
    uint amount = msg.value - dust;
    ethDust += dust;
    dividends.push(Dividend(ERC20(0x0), amount));
    DividendIssued(ERC20(0x0), amount);
  }

  function sweepDust() public onlyOwner {
    uint amount = ethDust;
    ethDust = 0;
    require(transfer(msg.sender, amount));
  }

  function withdraw() public {
    Snapshotable.Uint storage balanceHistory = balanceHistories[msg.sender];
    if (balanceHistory.count() > 0) {

      uint i;
      uint totalSupplyIndex = 0;
      uint balanceIndex = 0;
      uint firstEligibleDividend = balanceHistory.keyAt(0);
      uint eligibleDividendCount = dividends.length - firstEligibleDividend;
      uint[] memory amounts = new uint[](eligibleDividendCount);

      for (i = 0; i < eligibleDividendCount; i++) {
        uint totalSupplyValue = 0;
        uint balanceValue = 0;
        uint dividendIndex = firstEligibleDividend + i;

        (totalSupplyValue, totalSupplyIndex) = totalSupplyHistory.scanForKeyBefore(dividendIndex, totalSupplyIndex);
        (balanceValue, balanceIndex) = balanceHistory.scanForKeyBefore(dividendIndex, balanceIndex);

        amounts[i] = dividends[dividendIndex].amount * balanceValue / totalSupplyValue;
      }

      balanceHistory.reset(dividends.length);

      for (i = 0; i < eligibleDividendCount; i++) {
        ERC20 token = dividends[firstEligibleDividend + i].token;
        if (address(token) != 0x0) {
          require(token.transfer(msg.sender, amounts[i]));
        } else {
          require(transfer(msg.sender, amounts[i]));
        }
        Withdrawal(msg.sender, token, amounts[i]);
      }
    }
  }

  function _transfer(address _from, address _to, uint _value) internal {
    balanceHistories[_from].decrement(dividends.length, _value);
    balanceHistories[_to].increment(dividends.length, _value);
    Transfer(_from, _to, _value);
  }
}

pragma solidity ^0.4.18;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

pragma solidity ^0.4.18;

import "./ERC20Basic.sol";


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

pragma solidity 0.4.18;
/*
  The MIT License (MIT)

  Copyright (c) 2018 Murray Software, LLC.

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// solhint-disable no-inline-assembly
// solhint-disable no-unused-vars

library Snapshotable {

  struct Uint {
    uint[] snapshots;
  }

  function lastEntry(Uint storage self) internal view returns (uint key, uint value) {
    uint packed = last(self);
    return (toKey(packed), toValue(packed));
  }

  function lastKey(Uint storage self) internal view returns (uint) {
    return toKey(last(self));
  }

  function lastValue(Uint storage self) internal view returns (uint) {
    return toValue(last(self));
  }

  function count(Uint storage self) internal view returns (uint) {
    return self.snapshots.length;
  }

  function entryAt(Uint storage self, uint index) internal view returns (uint key, uint val) {
    uint packed = self.snapshots[index];
    return (toKey(packed), toValue(packed));
  }

  function keyAt(Uint storage self, uint index) internal view returns (uint key) {
    return toKey(self.snapshots[index]);
  }

  function valueAt(Uint storage self, uint index) internal view returns (uint val) {
    return toValue(self.snapshots[index]);
  }

  function scanForKeyBefore(Uint storage self, uint maxKey, uint start) internal view returns (uint val, uint index) {
    uint end = count(self);
    index = start;
    while (index + 1 < end && keyAt(self, index + 1) <= maxKey) {
      index++;
    }
    return (valueAt(self, index), index);
  }

  function reset(Uint storage self, uint key) internal {
    reset(self, key, lastValue(self));
  }

  function reset(Uint storage self, uint key, uint value) internal {
    self.snapshots.length = 1;
    self.snapshots[0] = entry(key, value);
  }

  function increment(Uint storage self, uint key, uint incr) internal {
    uint last = self.snapshots.length;
    if (last == 0) {
      self.snapshots.push(entry(key, incr));
    } else {
      last--;
      uint packed = self.snapshots[last];
      if (toKey(packed) == key) {
        self.snapshots[last] = packed + incr;
      } else {
        self.snapshots.push(entry(key, packed + incr));
      }
    }
  }

  function decrement(Uint storage self, uint key, uint decr) internal {
    uint last = self.snapshots.length;
    require(last > 0);
    last--;
    uint packed = self.snapshots[last];
    require(toValue(packed) >= decr);
    if (toKey(packed) == key) {
      self.snapshots[last] = packed - decr;
    } else {
      self.snapshots.push(entry(key, packed - decr));
    }
  }

  function last(Uint storage self) private view returns (uint) {
    if (self.snapshots.length == 0) {
      return 0;
    } else {
      return self.snapshots[self.snapshots.length-1];
    }
  }

  uint internal constant SHIFT_FACTOR = 2**(256 - 64); // 64 bits of index value

  function toKey(uint packed) private pure returns (uint) {
    return packed / SHIFT_FACTOR;
  }

  function toValue(uint packed) private pure returns (uint) {
    return packed & (SHIFT_FACTOR - 1);
  }

  function entry(uint key, uint value) private pure returns (uint) {
    return (key * SHIFT_FACTOR) | (value & (SHIFT_FACTOR - 1));
  }

}


contract UsingSnapshotable {
  using Snapshotable for Snapshotable.Uint;
}