/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract OMHMarket {
  address private owner;
  address private token; // the nft contract address

  mapping(uint256 => uint256) pricePerShare;

  modifier onlyOwner { require(owner == msg.sender); _; }

  receive() external payable { owner.call{value: address(this).balance}(""); }

  constructor() {
    owner = msg.sender;
  }

  function setToken(address _token) public onlyOwner {
    require(_token != address(0) && _token != token);
    token = _token;
  }

  function numForSale(uint256 horseIndex) public view returns(bool success, uint256 amount) {
    bytes memory result;
    bytes memory payload = abi.encodeWithSignature("balanceOf(address, uint256)", address(this), horseIndex);
    (success, result) = token.staticcall(payload);
    amount = abi.decode(result, (uint256));
  }

  function balanceOf(address user, uint256 horseIndex) internal view returns(bool success, uint256 amount) {
    bytes memory result;
    bytes memory payload = abi.encodeWithSignature("balanceOf(address, uint256)", user, horseIndex);
    (success, result) = token.staticcall(payload);
    amount = abi.decode(result, (uint256));
  }

  function totalForSale() external view returns(bool success, uint256 amount) {
    bytes memory result;
    bytes memory payload = abi.encodeWithSignature("balanceOf(address)", address(this));
    (success, result) = token.staticcall(payload);
    amount = abi.decode(result, (uint256));
  }

  function firstTokenOfOwner(uint256 index) internal view returns(bool success, uint256 amount) {
    bytes memory result;
    bytes memory payload = abi.encodeWithSignature("firstTokenOfOwner(address, uint256)", address(this), index);
    (success, result) = token.staticcall(payload);
    amount = abi.decode(result, (uint256));
  }

  function buyHorse(uint256 horseIndex) public payable returns(bool success) {
    uint256 amountOfUser;
    uint256 amountForSale;
    uint256 firstToken;
    bytes memory result;
    (success, amountOfUser) = balanceOf(msg.sender, horseIndex);
    // ========================================================================
    // require(success && amountOfUser == 0); // ENABLE in prod
    // ========================================================================
    (success, amountForSale) = balanceOf(address(this), horseIndex);
    require(success && amountForSale > 0);
    require(msg.value >= pricePerShare[horseIndex], "Insufficent ETH to buy");
    (success, firstToken) = firstTokenOfOwner(horseIndex);
    require(success, "how tf did this fail?");

    bytes memory payload = abi.encodeWithSignature("transferFrom(address, address, uin256)", address(this), msg.sender, firstToken);
    (success, result) = token.staticcall(payload);
    require(success, "Token could not be transfered");
  }
}