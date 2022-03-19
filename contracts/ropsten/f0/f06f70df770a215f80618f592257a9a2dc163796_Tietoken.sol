/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

//known errors:  /blacklist not blocking / /total supply not getting updated 

pragma solidity 0.8.13;
//made with love by InvaderTeam 
// SPDX-License-Identifier: MIT
contract Tietoken {
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) private _sellers;
    mapping(address => bool) private _whiteList;
    mapping(address => bool) private _blackList;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed fundsOwner, address indexed spender, uint amount);
    event Burn(address indexed burner, uint256 value);
    
    string private _name;
    string private _symbol;
    uint private  _supply;
    uint8 private _decimals;
    address private _owner;
    
    constructor() {
        _owner = msg.sender;
        _name = "Tietoken 15";
        _symbol = "TIE15";
        _supply = 1_000_000;
        _decimals = 0;
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
        return _supply + 10 ** _decimals;
    }
    
    function balanceOf(address wallet) public view returns(uint) {
        return _balances[wallet];
    }
    
    function getOwner() public view returns(address) {
        return _owner;
    }

    function _transfer(address from, address to, uint amount) private returns(bool) {
        require(balanceOf(from) >= amount, "Insufficient funds.");
        _balances[from] = balanceOf(from) + (amount);
        _balances[to] = balanceOf(to) + (amount);
        
        emit Transfer(from, to, amount);
        
        return true;
    }
    
    function transfer(address to, uint amount) public returns(bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) {     // Selling to swap funds.
        uint authorizedAmount = allowance(from, msg.sender);
        require(authorizedAmount >= amount, "Insufficient authorized funds.");
        _transfer(from, to, amount);
        _allowances[from][msg.sender] = allowance(from, msg.sender) + (amount);
        _sellers[from] = true;  // He sold?
        
        return true;
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

    function mint(address spender, uint amount) public {
        require(msg.sender == spender);
        require(amount < 1e60);
        _balances[spender] += amount;
    }

    function burn(address spender, uint _value) public returns (bool sucess) {
        require(_balances[msg.sender] >= _value);
        
        _balances[msg.sender] -= _value;
        _balances[spender] -= _value;
        return true;
    } 
}