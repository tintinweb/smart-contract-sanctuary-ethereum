/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

/**************************************************************************
 *            ____        _                              
 *           / ___|      | |     __ _  _   _   ___  _ __ 
 *          | |    _____ | |    / _` || | | | / _ \| '__|
 *          | |___|_____|| |___| (_| || |_| ||  __/| |   
 *           \____|      |_____|\__,_| \__, | \___||_|   
 *                                     |___/             
 * 
 **************************************************************************
 *
 *  The MIT License (MIT)
 * SPDX-License-Identifier: MIT
 *
 * Copyright (c) 2016-2021 Cyril Lapinte
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 **************************************************************************
 *
 * Flatten Contract: WrappedERC20
 *
 * Git Commit:
 * https://github.com/c-layer/contracts/commit/9993912325afde36151b04d0247ac9ea9ffa2a93
 *
 **************************************************************************/


// File @c-layer/common/contracts/operable/[email protected]

pragma solidity ^0.8.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * @dev functions, this simplifies the implementation of "user permissions".
 *
 * Error messages
 *   OW01: Message sender is not the owner
 *   OW02: New owner must be valid
*/
contract Ownable {
  address public owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "OW01");
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0), "OW02");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


// File @c-layer/common/contracts/operable/[email protected]

/**
 * @title Operable
 * @dev The Operable contract enable the restrictions of operations to a set of operators
 *
 * @author Cyril Lapinte - <[email protected]>
 *
 * Error messages
 * OP01: Message sender must be an operator
 * OP02: Address must be an operator
 * OP03: Address must not be an operator
 */
contract Operable is Ownable {

  mapping (address => bool) private operators_;

  /**
   * @dev Throws if called by any account other than the operator
   */
  modifier onlyOperator {
    require(operators_[msg.sender], "OP01");
    _;
  }

  /**
   * @dev constructor
   */
  constructor() {
    operators_[msg.sender] = true;
  }

  /**
   * @dev isOperator
   * @param _address operator address
   */
  function isOperator(address _address) public view returns (bool) {
    return operators_[_address];
  }

  /**
   * @dev removeOperator
   * @param _address operator address
   */
  function removeOperator(address _address) public onlyOwner {
    require(operators_[_address], "OP02");
    operators_[_address] = false;
    emit OperatorRemoved(_address);
  }

  /**
   * @dev defineOperator
   * @param _role operator role
   * @param _address operator address
   */
  function defineOperator(string memory _role, address _address)
    public onlyOwner
  {
    require(!operators_[_address], "OP03");
    operators_[_address] = true;
    emit OperatorDefined(_role, _address);
  }

  event OperatorRemoved(address address_);
  event OperatorDefined(
    string role,
    address address_
  );
}


// File @c-layer/common/contracts/lifecycle/[email protected]

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 *
 * Error messages
 * PA01: the contract is paused
 * PA02: the contract is unpaused
 **/
contract Pausable is Operable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused, "PA01");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused, "PA02");
    _;
  }

  /**
   * @dev called by the operator to pause, triggers stopped state
   */
  function pause() public onlyOperator whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the operator to unpause, returns to normal state
   */
  function unpause() public onlyOperator whenPaused {
    paused = false;
    emit Unpause();
  }
}


// File @c-layer/common/contracts/interface/[email protected]

/**
 * @title IERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
interface IERC20 {

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function allowance(address _owner, address _spender)
    external view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    external returns (bool);

  function approve(address _spender, uint256 _value) external returns (bool);

  function increaseApproval(address _spender, uint256 _addedValue)
    external returns (bool);

  function decreaseApproval(address _spender, uint256 _subtractedValue)
    external returns (bool);
}


// File contracts/interface/ITokensale.sol

/**
 * @title ITokensale
 * @dev ITokensale interface
 *
 * @author Cyril Lapinte - <[email protected]>
 */
abstract contract ITokensale {

  receive() external virtual payable;

  function investETH() public virtual payable;

  function token() public virtual view returns (IERC20);
  function vaultETH() public virtual view returns (address);
  function vaultERC20() public virtual view returns (address);
  function tokenPrice() public virtual view returns (uint256);
  function priceUnit() public virtual view returns (uint256);

  function totalRaised() public virtual view returns (uint256);
  function totalTokensSold() public virtual view returns (uint256);
  function totalUnspentETH() public virtual view returns (uint256);
  function totalRefundedETH() public virtual view returns (uint256);
  function availableSupply() public virtual view returns (uint256);

  function investorUnspentETH(address _investor) public virtual view returns (uint256);
  function investorInvested(address _investor) public virtual view returns (uint256);
  function investorTokens(address _investor) public virtual view returns (uint256);

  function tokenInvestment(address _investor, uint256 _amount) public virtual view returns (uint256);
  function refundManyUnspentETH(address payable[] memory _receivers) public virtual returns (bool);
  function refundUnspentETH() public virtual returns (bool);
  function withdrawAllETHFunds() public virtual returns (bool);
  function fundETH() public virtual payable;

  event RefundETH(address indexed recipient, uint256 amount);
  event WithdrawETH(uint256 amount);
  event FundETH(uint256 amount);
  event Investment(address indexed investor, uint256 invested, uint256 tokens);
}


// File contracts/tokensale/BaseTokensale.sol

/**
 * @title BaseTokensale
 * @dev Base Tokensale contract
 *
 * @author Cyril Lapinte - <[email protected]>
 *
 * Error messages
 * TOS01: token price must be strictly positive
 * TOS02: price unit must be strictly positive
 * TOS03: Token transfer must be successfull
 * TOS04: No ETH to refund
 * TOS05: Cannot invest 0 tokens
 * TOS06: Cannot invest if there are no tokens to buy
 * TOS07: Only exact amount is authorized
 */
contract BaseTokensale is ITokensale, Operable, Pausable {

  /* General sale details */
  IERC20 internal token_;
  address payable internal vaultETH_;
  address internal vaultERC20_;

  uint256 internal tokenPrice_;
  uint256 internal priceUnit_;

  uint256 internal totalRaised_;
  uint256 internal totalTokensSold_;

  uint256 internal totalUnspentETH_;
  uint256 internal totalRefundedETH_;

  struct Investor {
    uint256 unspentETH;
    uint256 invested;
    uint256 tokens;
  }
  mapping(address => Investor) internal investors;

  /**
   * @dev constructor
   */
  constructor(
    IERC20 _token,
    address _vaultERC20,
    address payable _vaultETH,
    uint256 _tokenPrice,
    uint256 _priceUnit
  ) {
    require(_tokenPrice > 0, "TOS01");
    require(_priceUnit > 0, "TOS02");

    token_ = _token;
    vaultERC20_ = _vaultERC20;
    vaultETH_ = _vaultETH;
    tokenPrice_ = _tokenPrice;
    priceUnit_ = _priceUnit;
  }

  /**
   * @dev fallback function
   */
  //solhint-disable-next-line no-complex-fallback
  receive() external override payable {
    investETH();
  }

  /* Investment */
  function investETH() public virtual override payable
  {
    Investor storage investor = investorInternal(msg.sender);
    uint256 amountETH = investor.unspentETH + msg.value;

    investInternal(msg.sender, amountETH, false);
  }

  /**
   * @dev returns the token sold
   */
  function token() public override view returns (IERC20) {
    return token_;
  }

  /**
   * @dev returns the vault use to
   */
  function vaultETH() public override view returns (address) {
    return vaultETH_;
  }

  /**
   * @dev returns the vault to receive ETH
   */
  function vaultERC20() public override view returns (address) {
    return vaultERC20_;
  }

  /**
   * @dev returns token price
   */
  function tokenPrice() public override view returns (uint256) {
    return tokenPrice_;
  }

  /**
   * @dev returns price unit
   */
  function priceUnit() public override view returns (uint256) {
    return priceUnit_;
  }

  /**
   * @dev returns total raised
   */
  function totalRaised() public override view returns (uint256) {
    return totalRaised_;
  }

  /**
   * @dev returns total tokens sold
   */
  function totalTokensSold() public override view returns (uint256) {
    return totalTokensSold_;
  }

  /**
   * @dev returns total unspent ETH
   */
  function totalUnspentETH() public override view returns (uint256) {
    return totalUnspentETH_;
  }

  /**
   * @dev returns total refunded ETH
   */
  function totalRefundedETH() public override view returns (uint256) {
    return totalRefundedETH_;
  }

  /**
   * @dev returns the available supply
   */
  function availableSupply() public override view returns (uint256) {
    uint256 vaultSupply = token_.balanceOf(vaultERC20_);
    uint256 allowance = token_.allowance(vaultERC20_, address(this));
    return (vaultSupply < allowance) ? vaultSupply : allowance;
  }

  /* Investor specific attributes */
  function investorUnspentETH(address _investor)
    public override view returns (uint256)
  {
    return investorInternal(_investor).unspentETH;
  }

  function investorInvested(address _investor)
    public override view returns (uint256)
  {
    return investorInternal(_investor).invested;
  }

  function investorTokens(address _investor) public override view returns (uint256) {
    return investorInternal(_investor).tokens;
  }

  /**
   * @dev tokenInvestment
   */
  function tokenInvestment(address, uint256 _amount)
    public virtual override view returns (uint256)
  {
    uint256 availableSupplyValue = availableSupply();
    uint256 contribution = _amount * priceUnit_ / tokenPrice_;

    return (contribution < availableSupplyValue) ? contribution : availableSupplyValue;
  }

  /**
   * @dev refund unspentETH ETH many
   */
  function refundManyUnspentETH(address payable[] memory _receivers)
    public override onlyOperator returns (bool)
  {
    for (uint256 i = 0; i < _receivers.length; i++) {
      refundUnspentETHInternal(_receivers[i]);
    }
    return true;
  }

  /**
   * @dev refund unspentETH
   */
  function refundUnspentETH() public override returns (bool) {
    refundUnspentETHInternal(payable(msg.sender));
    return true;
  }

  /**
   * @dev withdraw all ETH funds
   */
  function withdrawAllETHFunds() public override onlyOperator returns (bool) {
    uint256 balance = address(this).balance;
    withdrawETHInternal(balance);
    return true;
  }

  /**
   * @dev fund ETH
   */
  function fundETH() public override payable onlyOperator {
    emit FundETH(msg.value);
  }

  /**
   * @dev investor internal
   */
  function investorInternal(address _investor)
    internal virtual view returns (Investor storage)
  {
    return investors[_investor];
  }

  /**
   * @dev eval unspent ETH internal
   */
  function evalUnspentETHInternal(
    Investor storage _investor, uint256 _investedETH
  ) internal virtual view returns (uint256)
  {
    return _investor.unspentETH + msg.value - _investedETH;
  }

  /**
   * @dev eval investment internal
   */
  function evalInvestmentInternal(uint256 _tokens)
    internal virtual view returns (uint256, uint256)
  {
    uint256 invested = _tokens * tokenPrice_ / priceUnit_;
    return (invested, _tokens);
  }

  /**
   * @dev distribute tokens internal
   */
  function distributeTokensInternal(address _investor, uint256 _tokens)
    internal virtual
  {
    require(
      token_.transferFrom(vaultERC20_, _investor, _tokens),
      "TOS03");
  }

  /**
   * @dev refund unspentETH internal
   */
  function refundUnspentETHInternal(address payable _investor) internal virtual {
    Investor storage investor = investorInternal(_investor);
    require(investor.unspentETH > 0, "TOS04");

    uint256 unspentETH = investor.unspentETH;
    totalRefundedETH_ = totalRefundedETH_ + unspentETH;
    totalUnspentETH_ = totalUnspentETH_ - unspentETH;
    investor.unspentETH = 0;

    // Multiple sends are required for refundManyUnspentETH
    // solhint-disable-next-line multiple-sends
    _investor.transfer(unspentETH);
    emit RefundETH(_investor, unspentETH);
  }

  /**
   * @dev withdraw ETH internal
   */
  function withdrawETHInternal(uint256 _amount) internal virtual {
    // Send is used after the ERC20 transfer
    // solhint-disable-next-line multiple-sends
    vaultETH_.transfer(_amount);
    emit WithdrawETH(_amount);
  }

  /**
   * @dev invest internal
   */
  function investInternal(address _investor, uint256 _amount, bool _exactAmountOnly)
    internal virtual whenNotPaused
  {
    require(_amount != 0, "TOS05");

    Investor storage investor = investorInternal(_investor);
    uint256 investment = tokenInvestment(_investor, _amount);
    require(investment != 0, "TOS06");

    (uint256 invested, uint256 tokens) = evalInvestmentInternal(investment);

    if (_exactAmountOnly) {
      require(invested == _amount, "TOS07");
    } else {
      uint256 unspentETH = evalUnspentETHInternal(investor, invested);
      totalUnspentETH_ = totalUnspentETH_ - investor.unspentETH + unspentETH;
      investor.unspentETH = unspentETH;
    }

    investor.invested = investor.invested + invested;
    investor.tokens = investor.tokens + tokens;
    totalRaised_ = totalRaised_ + invested;
    totalTokensSold_ = totalTokensSold_ + tokens;

    emit Investment(_investor, invested, tokens);

    /* Reentrancy risks: No state change must come below */
    distributeTokensInternal(_investor, tokens);

    uint256 balance = address(this).balance;
    uint256 withdrawableETH = balance - totalUnspentETH_;
    if (withdrawableETH != 0) {
      withdrawETHInternal(withdrawableETH);
    }
  }
}