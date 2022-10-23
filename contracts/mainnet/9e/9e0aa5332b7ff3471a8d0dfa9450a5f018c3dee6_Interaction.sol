/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
interface Assess {
     function assess() external;
}

contract Interaction {

  address public owner;
  address public constant OTHER_CONTRACT = 0xd09a57127BC40D680Be7cb061C2a6629Fe71AbEf;
  Assess AssessContract = Assess(OTHER_CONTRACT);
  constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
            _;
    }
  function testCall() public onlyOwner {
    //This is example and not related to your contract
    AssessContract.assess();
  }
}