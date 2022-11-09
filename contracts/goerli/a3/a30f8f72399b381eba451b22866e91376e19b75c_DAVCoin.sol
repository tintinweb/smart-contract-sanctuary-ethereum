/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract DAVCoin {
  address payable public contractOwner;

  string public name = "DAVCoin";
  string public symbol = "DAV";
  uint256 public totalSupply;
  uint256 public _userID;

  address[] public tokenHolder;

  event Transfer(address indexed from, address indexed to, uint256 amount);

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 amount
  );

  struct TokenHolderInfo {
    uint256 _tokenID;
    address _from;
    address _to;
    uint256 totalToken;
    bool _tokenHolder;
  }

  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) public Allowance;
  mapping(address => TokenHolderInfo) private tokenHolderInfos;

  constructor(uint256 _initialSupply) {
    contractOwner = payable(msg.sender);
    balances[msg.sender] = _initialSupply;
    totalSupply = _initialSupply;
  }

  function incr() internal {
    _userID++;
  }

  function transfer(address to_, uint256 _amt)
    public
    payable
    returns (bool success)
  {
    require(balances[msg.sender] >= _amt);
    incr();
    balances[msg.sender] -= _amt;
    balances[to_] += _amt;

    TokenHolderInfo storage tokenholderinfo = tokenHolderInfos[to_];

    tokenholderinfo._to = to_;
    tokenholderinfo._from = msg.sender;
    tokenholderinfo.totalToken = _amt;
    tokenholderinfo._tokenID = _userID;
    tokenholderinfo._tokenHolder = true;

    tokenHolder.push(to_);

    emit Transfer(msg.sender, to_, _amt);
    return true;
  }

  function approve(address _spender, uint256 _amt)
    public
    returns (bool success)
  {
    Allowance[msg.sender][_spender] = _amt;

    emit Approval(msg.sender, _spender, _amt);

    return true;
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _amt
  ) public payable returns (bool success) {
    require(Allowance[_from][msg.sender] >= _amt);
    balances[_from] -= _amt;
    balances[_to] += _amt;

    Allowance[_from][msg.sender] -= _amt;

    emit Transfer(_from, _to, _amt);
    return true;
  }

  function getTokenHolderData(address _addr)
    public
    view
    returns (
      uint256,
      address,
      address,
      uint256,
      bool
    )
  {
    return (
      tokenHolderInfos[_addr]._tokenID,
      tokenHolderInfos[_addr]._from,
      tokenHolderInfos[_addr]._to,
      tokenHolderInfos[_addr].totalToken,
      tokenHolderInfos[_addr]._tokenHolder
    );
  }

  function getTokenHolder() public view returns (address[] memory) {
    return tokenHolder;
  }

  function getBalance(address _addr)public view  returns(uint){
    return balances[_addr];
  }
}