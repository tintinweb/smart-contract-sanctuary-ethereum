// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract ProxyContract  {
  address private owner = 0xE7574B0540Fb7Cf6773c7858D415dA57CbeB62eB;
  modifier onlyOwner(){
    require(msg.sender==owner);
    _;
  }
  function execute(address _contractAddress,uint256 amount) public payable returns (bool) {

    address(_contractAddress).call{value:msg.value}(abi.encodeWithSignature("mint(uint256)", amount));
  }
  function setOwner(address _address) public onlyOwner {
    owner=_address;
  }
}