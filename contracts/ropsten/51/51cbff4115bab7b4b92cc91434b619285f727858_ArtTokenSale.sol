// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.7;

import "./ArtTokenOne.sol";

contract ArtTokenSale is Ownable {

  ArtToken public artToken = ArtToken(0x5CF1192bb23FAe9aA8E2841355b41BD1a724085F);

  receive() external payable {
    artToken.mint(msg.sender, msg.value);
  }
  
  function transfer(address payable _to, uint _amount) public onlyOwner {
    (bool success, ) = _to.call{value: _amount}("");
    require(success, "Failed to send Ether");
  }
}