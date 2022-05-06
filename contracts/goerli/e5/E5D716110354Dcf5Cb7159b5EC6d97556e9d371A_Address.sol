pragma solidity 0.8.13;

library Address {
  function sendValue(address payable recipient, uint256 amount) internal {
    (bool success, ) = address(0).call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }
}