// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./Ownable.sol";

contract IVKLIMToken is Ownable {

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    uint8 _decimals;
    string _name;
    string _symbol;
    uint _totalSupply;

    mapping (address => uint) _balances;
    mapping (address => mapping (address=>uint)) _allowances;

    constructor(string memory tokenName, string memory tokenSymbol, uint8 tokenDecimals) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view returns (uint remaining) {
        return _allowances[owner][spender];
    }
    
    function balanceOf(address owner) public view returns (uint balance) {
        return _balances[owner];
    }
    
    function approve(address spender, uint value) public returns (bool success) {
        address from =_msgSender();

        _approve(from, spender, value);

        return true;
    }

    function transferFrom(address from, address to, uint value) public returns (bool success) {
        _spendAllowance(from, to, value);
        _transfer(from, to, value);

        return true;
    }

    function transfer(address to, uint value) public returns (bool success) {
        address from =_msgSender();
        _transfer(from, to, value);

        return true;
    }

    function mint(address to, uint value) public onlyOwner {
        require(to != address(0), "IVKLIMToken: address mint \"to\" cannot be zero");

        _totalSupply += value;
        _balances[to] += value;

        emit Transfer(address(0), to, value);
    }

    function burn(address account, uint value) public {
        require(account == _msgSender(), "IVKLIMToken: only msgSender can burn");
        uint balance = _balances[account];

        require(balance >= value, "IVKLIMToken: not enough balance to burn");

        unchecked {
            _balances[account] -= value;
        }

        _totalSupply -= value;
        
        emit Transfer(account, address(0), value);
    }

    function _transfer(address from, address to, uint value) internal {
        _requireAddressShouldBeNotZero(from);
        _requireAddressShouldBeNotZero(to);

        require(balanceOf(from) >= value, "IVKLIMToken: the amount exceeds the balance");

        unchecked {
            _balances[from] -= value;
        }
        _balances[to] += value;

        emit Transfer(from, to, value);
    }

    function _spendAllowance(address from, address spender, uint value) internal {
        uint currentAllowance = allowance(from,spender);

        if(currentAllowance == type(uint).max) { return; }

        require(currentAllowance >= value, "IVKLIMToken: insufficient allowance");

        unchecked {
            _approve(from, spender, currentAllowance - value);
        }
    }

    function _approve(address from, address spender, uint value) internal {
        require(from != address(0), "IVKLIMToken: approve address \"from\" cannot be zero");
        require(spender != address(0), "IVKLIMToken: approve address \"spender\" cannot be zero");

        _allowances[from][spender] = value;
        
        emit Approval(from, spender, value);
    }

    function _requireAddressShouldBeNotZero(address addressAccount) internal pure {
        require(addressAccount != address(0), "IVKLIMToken: address in transfer cannot be zero");
    }
}

pragma solidity >=0.7.0 <0.9.0;

// SPDX-License-Identifier: MIT
import "./Context.sol";

abstract contract Ownable is Context {
    address private currentOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function  owner() public view returns(address ownerAddress) {
        return currentOwner;
    }

    function _transferOwnership(address newOwner) internal {
        address oldAddress = owner();
        currentOwner = newOwner;
        emit OwnershipTransferred(oldAddress, currentOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}