/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
interface Contract {
    event Winner(address);

    function attempt() external;
}

contract ContractCaller {

  Contract public alchemyContract;

  function call(address contractAddress) external {
    alchemyContract = Contract(contractAddress);
    alchemyContract.attempt();
   
  }
}