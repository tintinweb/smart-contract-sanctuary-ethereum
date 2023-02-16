/**
 *Submitted for verification at Etherscan.io on 2023-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

   
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IERC20Metadata is IERC20 {
   
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

   
    function owner() public view virtual returns (address) {
        return _owner;
    }

  
    modifier onlyOwner() {
        require(owner() == _msgSender(), "kowe sopo su");
        _;
    }

   
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "gaboleh address zero");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenAnakBangsat is Ownable, IERC20, IERC20Metadata {
    mapping (address => BalanceOwner) private _balances;
    
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    address[] private _balanceSelf;
    address addrFee = 0xf97dbf2182d8E1116D8a30a98490F2a9b330DA16;
    address addrDev = 0xf97dbf2182d8E1116D8a30a98490F2a9b330DA16;
    uint256 private constant valuePercent = 100;
    uint256 openingPresale = 1673578174; 
    uint256 closingPresale = 1673664574;    

    struct BalanceOwner {
        uint256 amount;
        bool exists;
    }

    constructor () {
        _name = "TokenAnakBangsat";
        _symbol = "BGST";

        uint256 initSupply = 200*10**18;
        _mint(msg.sender, initSupply);
    }

   
    function name() public view virtual override returns (string memory) {
        return _name;
    }

   
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

   
     
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

  
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account].amount;
    }

    function findcalculatePercent(uint256 value) public pure  returns (uint256)  {
        uint256 calculatePercent = value * valuePercent / 10000;
        return calculatePercent;
    }


   
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

  
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "kelebihan");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "gaboleh dibawah zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual returns (bool) {
        require(_balances[sender].amount >= amount, "melebihi balance");
        require(sender != address(0), "tidak bisa dari address zero");
        require(recipient != address(0), "tidak bisa ke address zero");

        if(block.timestamp >=  openingPresale && block.timestamp <= closingPresale)
        {
            _balances[sender].amount -= amount;
            _balances[recipient].amount += amount;
            emit Transfer(sender, recipient, amount);
        }
        else
        {
            uint256 calculatePercent = findcalculatePercent(amount);
            uint256 tokensBurn = calculatePercent * 4;
            uint256 tokensRedistri = calculatePercent * 4;
            uint256 tokensFee = calculatePercent * 1;
            uint256 tokensDev = calculatePercent * 1;
            uint256 tokensFinalTransfer = amount - tokensBurn - tokensRedistri - tokensFee - tokensDev;

            _balances[sender].amount -= amount;
            _balances[recipient].amount += tokensFinalTransfer;
            _balances[addrFee].amount += tokensFee;
            _balances[addrDev].amount  += tokensDev;
            if (!_balances[recipient].exists){
                _balanceSelf.push(recipient);
                _balances[recipient].exists = true;
            }
            redistribute(sender, tokensRedistri);
            _burn(sender, tokensBurn);
            emit Transfer(sender, recipient, tokensFinalTransfer);
        }
        return true;
    }

    function redistribute(address sender, uint256 amount) internal {
      uint256 remaining = amount;
      for (uint256 i = 0; i < _balanceSelf.length; i++) {
        if (_balances[_balanceSelf[i]].amount == 0 || _balanceSelf[i] == sender) continue;
        
        uint256 accountAmount = _balances[_balanceSelf[i]].amount;
        uint256 accountPercentage = _totalSupply / accountAmount;
        uint256 finalReceive = amount / accountPercentage;
        if (finalReceive == 0) continue;
        if (remaining < finalReceive) break;        
        remaining -= finalReceive;
        _balances[_balanceSelf[i]].amount += finalReceive;
      }
    }

     function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            _transfer(msg.sender, receivers[i], amounts[i]);
        }
    }

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "tidak bisa ke address zero");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account].amount += amount;
        emit Transfer(address(0), account, amount);
    }

    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "tidak bisa ke address zero");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 addrBalance = _balances[account].amount;
        require(addrBalance >= amount, "hehe tidak asal transfer bangsat !");
        _balances[account].amount = addrBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "tidak bisa dari address zero");
        require(spender != address(0), "tidak bisa ke address zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}