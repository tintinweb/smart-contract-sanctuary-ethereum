// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "FoodToken.sol";

contract FoodPresale {

    receive() external payable {
    buyTokens(msg.sender);
    }
    fallback () external payable {
    buyTokens(msg.sender);
    }

  FoodToken public token;
  uint private rate = 1;
  address public owner;

  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  event WithdrawContractBalance(
    address indexed owner,
    uint amount,
    uint newBalance
  );

    constructor(FoodToken _token) {
    token = _token;
    owner = msg.sender;
  }


  function multiply(uint x, uint y) internal pure returns (uint z) {
      require(y == 0 || (z = x * y) / y == x);
  }


  function buyTokens(address _beneficiary) public payable {
   
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    uint256 tokens = _getTokenAmount(weiAmount);

    _processPurchase(_beneficiary, tokens);

    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  function _preValidatePurchase(address _beneficiary,uint256 _weiAmount) internal pure
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {

  }


  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.mint(_beneficiary, _tokenAmount * 500000);
  }

  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount / rate;
  }

  function AirdropRegular(address[] memory wallets, uint256 amount) public {
      for (uint i=0; i<wallets.length; i++) {
          token.mint(wallets[i], amount);
      }
  }

  function AirdropGame(address[] memory winners, uint256[] memory amounts) public {
      for (uint i=0; i<winners.length; i++) {
          token.mint(winners[i], amounts[i]);
      }
  }

  function withdraw(uint _amount) public {
      require(owner == msg.sender, "You are not the owner");
      require(_amount <= address(this).balance, "You are trying to withdraw to much money");
      address(this).balance - _amount;
      payable(owner).transfer(_amount);

      emit WithdrawContractBalance(owner, _amount, address(this).balance);
  }

  function resetOwnership() public {
      require(owner == msg.sender, "You are not the owner");
      token.transferOwnership(owner);
  }

  function EndPresale() public {
      require(owner == msg.sender, "You are not the owner");
      token.pauseControllerDismiss();
  }



}