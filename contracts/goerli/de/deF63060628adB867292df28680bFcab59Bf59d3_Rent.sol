// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error Rent_NoDeposit();
error Rent_CreditMoreEth();
error Rent_YourTransactionFailed();
error Rent_FirstStartRent();

contract Rent {
  mapping(address => uint256) private s_accDeposite;

  bool private s_starded = false;

  uint256 s_timestarted;

  // uint256 public cost = 1e15;

  event creditMessage(string payam, uint256 value);

  uint256 public s_time;

  uint256 public val;

  address payable FullAdmin = payable(0xEc789eCEDDf724306787b3Cb1806e2ac113D7C24);

  // mainFunctons ///

  function credit() public payable returns (bool) {
    if ((msg.value) <= 0.2 ether) {
      revert Rent_CreditMoreEth();
    }
    (bool success, ) = FullAdmin.call{value: msg.value}("");
    if (!success) {
      revert Rent_YourTransactionFailed();
    }
    emit creditMessage("Nice", msg.value);
    s_accDeposite[msg.sender] += msg.value;
    return (success);
  }

  function start() public {
    // require(, "increase your deposite please !");
    if (!(getAccDeposite(msg.sender) >= 0.2 ether)) {
      revert Rent_NoDeposit();
    }
    s_timestarted = block.timestamp;
    s_starded = true;
  }

  function finish(uint256 _cost) public {
    if (s_starded) {
      s_starded = false;
      s_accDeposite[msg.sender] -= ((block.timestamp) - s_timestarted) * _cost;

      // s_accDeposite[msg.sender] -=
    } else {
      revert Rent_FirstStartRent();
    }
  }

  // geters //

  function getAccDeposite(address _acc) public view returns (uint256) {
    return s_accDeposite[_acc];
  }

  function getStartedState() public view returns (bool) {
    return s_starded;
  }
}