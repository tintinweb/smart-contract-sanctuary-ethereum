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