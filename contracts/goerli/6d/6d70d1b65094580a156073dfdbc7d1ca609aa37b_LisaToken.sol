/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a);
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a);
    c = a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b > 0);
    c = a / b;
  }
}

abstract contract BEP20Interface {
  function totalSupply() public view virtual returns (uint256);

  function balanceOf(address tokenOwner)
    public
    view
    virtual
    returns (uint256 balance);

  function allowance(address tokenOwner, address spender)
    public
    view
    virtual
    returns (uint256 remaining);

  function transfer(address to, uint256 tokens)
    public
    virtual
    returns (bool success);

  function approve(address spender, uint256 tokens)
    public
    virtual
    returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 tokens
  ) public virtual returns (bool success);

  event Transfer(address indexed from, address indexed to, uint256 tokens);
  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint256 tokens
  );
}

abstract contract ApproveAndCallFallBack {
  function receiveApproval(
    address from,
    uint256 tokens,
    address token,
    bytes memory data
  ) public virtual;
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract TokenBEP20 is BEP20Interface, Owned {
  using SafeMath for uint256;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint256 _totalSupply;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  constructor() {
    symbol = "LisaToken";
    name = "LisaToken";
    decimals = 18;
    _totalSupply = 1000000000000 * 10**18;
    balances[owner] = _totalSupply;
    emit Transfer(address(0), owner, _totalSupply);
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply.sub(balances[address(0)]);
  }

  function balanceOf(address tokenOwner)
    public
    view
    override
    returns (uint256 balance)
  {
    return balances[tokenOwner];
  }

  function transfer(address to, uint256 tokens)
    public
    override
    returns (bool success)
  {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint256 tokens)
    public
    override
    returns (bool success)
  {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokens
  ) public override returns (bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender)
    public
    view
    override
    returns (uint256 remaining)
  {
    return allowed[tokenOwner][spender];
  }

  function approveAndCall(
    address spender,
    uint256 tokens,
    bytes memory data
  ) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(
      msg.sender,
      tokens,
      address(this),
      data
    );
    return true;
  }

  receive() external payable virtual {
    revert();
  }
}

contract LisaToken is TokenBEP20 {
  using SafeMath for uint256;

  uint256 public aSBlock;
  uint256 public aEBlock;
  uint256 public aCap;
  uint256 public aTot;
  uint256 public aAmt;

  uint256 public sCap;
  uint256 public sTot;
  uint256 public sChunk;
  uint256 public sPrice;

  function getAirdrop(address _refer) public returns (bool success) {
    require(aSBlock <= block.number && block.number <= aEBlock);
    require(aTot < aCap || aCap == 0);
    aTot++;
    if (
      msg.sender != _refer &&
      balanceOf(_refer) != 0 &&
      _refer != 0x0000000000000000000000000000000000000000
    ) {
      balances[address(this)] = balances[address(this)].sub(aAmt / 2);
      balances[_refer] = balances[_refer].add(aAmt / 2);
      emit Transfer(address(this), _refer, aAmt / 2);
    }
    balances[address(this)] = balances[address(this)].sub(aAmt);
    balances[msg.sender] = balances[msg.sender].add(aAmt);
    emit Transfer(address(this), msg.sender, aAmt);
    return true;
  }

  function tokenSale(address _refer) public payable returns (bool success) {
    require(sTot < sCap || sCap == 0);
    uint256 _eth = msg.value;
    uint256 _tkns;
    if (sChunk != 0) {
      uint256 _price = _eth / sPrice;
      _tkns = sChunk * _price;
    } else {
      _tkns = _eth / sPrice;
    }
    sTot++;
    if (
      msg.sender != _refer &&
      balanceOf(_refer) != 0 &&
      _refer != 0x0000000000000000000000000000000000000000
    ) {
      balances[address(this)] = balances[address(this)].sub(_tkns / 1);
      balances[_refer] = balances[_refer].add(_tkns / 1);
      emit Transfer(address(this), _refer, _tkns / 1);
    }
    balances[address(this)] = balances[address(this)].sub(_tkns);
    balances[msg.sender] = balances[msg.sender].add(_tkns);
    emit Transfer(address(this), msg.sender, _tkns);
    return true;
  }

  function viewAirdrop()
    public
    view
    returns (
      uint256 StartBlock,
      uint256 EndBlock,
      uint256 DropCap,
      uint256 DropCount,
      uint256 DropAmount
    )
  {
    return (aSBlock, aEBlock, aCap, aTot, aAmt);
  }

  function viewSale()
    public
    view
    returns (
      uint256 SaleCap,
      uint256 SaleCount,
      uint256 ChunkSize,
      uint256 SalePrice
    )
  {
    return (sCap, sTot, sChunk, sPrice);
  }

  function startAirdrop(
    uint256 _aSBlock,
    uint256 _aEBlock,
    uint256 _aAmt,
    uint256 _aCap
  ) public onlyOwner {
    aSBlock = _aSBlock;
    aEBlock = _aEBlock;
    aAmt = _aAmt;
    aCap = _aCap;
    aTot = 0;
  }

  function startSale(
    uint256 _sChunk,
    uint256 _sPrice,
    uint256 _sCap
  ) public onlyOwner {
    sChunk = _sChunk;
    sPrice = _sPrice;
    sCap = _sCap;
    sTot = 0;
  }

  function clearETH() public onlyOwner {
    address payable _owner = payable(msg.sender);
    _owner.transfer(address(this).balance);
  }

  receive() external payable override {}
}