// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "./Libraries.sol";

/**
 * TCG2CoinSale is contract for selling ethTCG2 coin for fix price per token.
 * v0.1.1
*/
contract TCG2CoinSale is Ownable {
  
  ERC20 public tokenContractAddress;
  address public withdrawalWallet;
  uint256 public tokenPriceInWei;
  uint256 public actualContractBalanceInWei;
  uint256 public totalAmountRaisedInWei;
  uint256 public tokenDecimal;

  
  event SellTcgForEth(address indexed _to, uint256 _tokenPriceInWei, uint256 _value);
  event WithdrawTCG(address indexed _to, uint256 _value);
  event WithdrawETH(address indexed _to, uint256 _value);
  event UpdateWithdrawalWallet(address indexed _withdrawalWallet);
  event UpdateTokenPriceInWei(uint256 _tokenPriceInWei);
  event UpdateTokenContractAddress(address indexed _tokenContractAddress);
  event UpdateTokenDecimal(uint256 _tokenDecimal);


  constructor(uint256 _tokenPriceInWei, address _withdrawalWallet, ERC20 _tokenContractAddress) {
    require(_tokenPriceInWei > 0);
    require(_withdrawalWallet != address(0));
    tokenPriceInWei = _tokenPriceInWei;
    withdrawalWallet = _withdrawalWallet;
    tokenContractAddress = _tokenContractAddress;
    tokenDecimal = _tokenContractAddress.decimals();
  }

  function rescueETH() external onlyOwner {
    require(actualContractBalanceInWei > 0);
    payable(owner()).transfer(actualContractBalanceInWei);
    emit WithdrawETH(owner(), actualContractBalanceInWei);
    actualContractBalanceInWei = 0;
  }

  function rescueTCG(uint256 amount) external onlyOwner {
    require(amount > 0);
    tokenContractAddress.transfer(owner(), amount);
    emit WithdrawTCG(owner(), actualContractBalanceInWei);
  }

  function rescueEthToWallet() external onlyOwner {
    require(actualContractBalanceInWei > 0);
    payable(withdrawalWallet).transfer(actualContractBalanceInWei);
    emit WithdrawETH(withdrawalWallet, actualContractBalanceInWei);
    actualContractBalanceInWei = 0;
  }

  function rescueTcgToWallet(uint256 amount) external onlyOwner {
    require(amount > 0);
    tokenContractAddress.transfer(withdrawalWallet, amount);
    emit WithdrawTCG(withdrawalWallet, actualContractBalanceInWei);
  }

  function setToken(ERC20 _tokenContractAddress) external onlyOwner {
    tokenContractAddress = _tokenContractAddress;
    emit UpdateTokenContractAddress(address(tokenContractAddress));
    tokenDecimal = tokenContractAddress.decimals();
    emit UpdateTokenDecimal(tokenDecimal);
  }

  function setWallet(address _withdrawalWallet) external onlyOwner {
    withdrawalWallet = _withdrawalWallet;
    emit UpdateWithdrawalWallet(withdrawalWallet);
  }

  function setPricePerToken(uint256 _tokenPriceInWei) external onlyOwner {
    require(_tokenPriceInWei > 0);
    tokenPriceInWei = _tokenPriceInWei;
    emit UpdateTokenPriceInWei(tokenPriceInWei);
  }

  receive() external payable {
      buyTokens();
  }

  function buyTokens() public payable {
    require(msg.value != 0);
    require(tokenPriceInWei > 0);
    uint256 value = (msg.value * 10 ** tokenDecimal) / tokenPriceInWei;
    tokenContractAddress.transfer(msg.sender, value);
    actualContractBalanceInWei = actualContractBalanceInWei + msg.value;
    totalAmountRaisedInWei = totalAmountRaisedInWei + msg.value;
    emit SellTcgForEth(msg.sender, tokenPriceInWei, value);
  }
}