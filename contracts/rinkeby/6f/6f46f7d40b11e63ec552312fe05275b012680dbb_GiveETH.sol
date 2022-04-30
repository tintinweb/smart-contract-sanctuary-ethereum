/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract GiveETH {

    receive  () external payable{ }
    mapping (address => bool) hasCollectedFunds;

    function collectETHDeposit() external returns (bool) {
      require (hasCollectedFunds[msg.sender] == false, "This user has collected funds");
      deposit();
      hasCollectedFunds[msg.sender] = true;
      return true;
    }

    function deposit() internal  {
      (bool success,) = payable(msg.sender).call{value : 0.001 ether}("");
     require (success , "Trasaction failed");
    }

    function selfDestruct (address lol) external {
        selfdestruct(payable(lol));
    }
}