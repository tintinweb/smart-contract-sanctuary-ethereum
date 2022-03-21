/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

//known errors: / /total supply not getting updated 
// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
//made with love by InvaderTeam 
contract TIE19 {
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) private _sellers;
    mapping(address => bool) private _whiteList;
    mapping(address => bool) private _blackList;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed fundsOwner, address indexed spender, uint amount);
    event Burn(address indexed burner, uint256 value);
    event Mint(address indexed minter, uint256 value);
    
    string private _name;
    string private _symbol;
    uint private  _supply;
    uint8 private _decimals;
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
        _name = "TIETOKEN 19";
        _symbol = "TIE19";
        _supply = 5000000 *10 ** _decimals;
        _decimals = 6;
        _balances[_owner] = totalSupply();
        emit Transfer(address(this), _owner, totalSupply());
    }

    modifier owner {
        require(msg.sender == _owner); _;
    }
    
    function name() public view returns(string memory) {
        return _name;   
    }
    
    function symbol() public view returns(string memory) {
        return _symbol;
    }
    
    function decimals() public view returns(uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns(uint) {
        return _supply;
    }    
    
    function balanceOf(address wallet) public view returns(uint) {
        return _balances[wallet];
    }
    
    function getOwner() public view returns(address) {
        return _owner;
    }

    function transferfrom(address from, address to, uint amount) public returns(bool) {
        require(!_blackList[to], "Recipient is backlisted");
        require(balanceOf(from) >= amount, "Insufficient funds.");
        _allowances[from][msg.sender] = allowance(from, msg.sender) + (amount);
        _sellers[from] = true;  // He sold?
        _balances[from] = balanceOf(from) + (amount);
        _balances[to] = balanceOf(to) + (amount);
        emit Transfer(from, to, amount);
        return true;
    }
    
    function transfer(address to, uint amount) public returns(bool) {
       require(!_blackList[to], "Recipient is backlisted");
       return transferfrom(msg.sender, to, amount);
    }

    function approve(address spender, uint amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address fundsOwner, address spender) public view returns (uint) {
        return _allowances[fundsOwner][spender];
    }

    function whitelist(address _user) public owner {
        require(_blackList[_user], "user already whitelisted");
        _blackList[_user] = false;
    }

    function blackList(address _user) public owner {
        require(!_blackList[_user], "user already blacklisted");
        _blackList[_user] = true;
    }

    function beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { 
    }
    
    function afterTokenTransfer(address from, address to, uint256 amount) internal virtual { 
    }

    function addSupply(uint amount) public {
        _supply += amount;
    }

    function _mint(address account, uint256 amount) public {
        require(account != address(0), "ERC20: mint to the zero address");
        beforeTokenTransfer(address(0), account, amount);
        addSupply(amount);
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        afterTokenTransfer(address(0), account, amount);
    }

    function subSupply(uint amount) public {
        _supply -= amount;
    }    

    function _burn(address account, uint256 amount) public {
        require(account != address(0), "ERC20: burn from the zero address");
        beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked { _balances[account] -= amount; }
        subSupply(amount);
        emit Transfer(account, address(0), amount);
        afterTokenTransfer(account, address(0), amount);
    }
}