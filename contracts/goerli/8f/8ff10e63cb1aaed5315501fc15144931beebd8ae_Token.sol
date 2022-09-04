/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

 abstract contract ERC20Interface {
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function totalSupply() public view virtual returns  (uint);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Supply(uint indexed maximumSupply, uint indexed totalSupply, uint renainingSupply);
}


contract Token is ERC20Interface  {
    string public name;
    string public symbol;
    uint8 public decimals; 
    address public owner;

    uint256 public _totalSupply;
    uint public maximumSupply;
    

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private  allowed;
    mapping(address => bool) public blacklist;

  
    constructor()  {
        name = "ZartajTest";
        symbol = "ZARTY";
        decimals = 18;
        _totalSupply = 1000000 * 10**18;
        maximumSupply = 10000000 * 10**18;
        owner= msg.sender;


        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function  remainingToken() public view returns (uint remainingSupply) {

        return ( maximumSupply - _totalSupply);
    }


    modifier ownable ()  {
        require (msg.sender== owner,"only owner can perform this");
        _;
    }
      modifier checkBlacklist (address _who){
        require(!blacklist[_who], "THIS ADDRESS IS BLACKLISTED BY OWNER OF THIS CONTRACT");
        _;
    }

    function blackListing(address _who ) public  ownable {
        blacklist[_who] = true;

    }

    function whitelisting(address _who) public  ownable {
        blacklist[_who] = false;
    }
 

    function totalSupply() public override view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public checkBlacklist(msg.sender) override returns (bool success)  {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public checkBlacklist(msg.sender) override returns (bool success) {
        balances[msg.sender] = (balances[msg.sender] -= tokens);
        balances[to] = (balances[to] += tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public checkBlacklist(msg.sender) override returns (bool success) {
        require(balances[from] >=tokens , "You don't have enough tokens");
        require(allowed[from][msg.sender] >=tokens , "You are not allowwed to send tokens");
        balances[from] = (balances[from] -= tokens);
        allowed[from][msg.sender] = (allowed[from][msg.sender] -= tokens);
        balances[to] = (balances[to]+= tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function mint (address to ,uint amount) public ownable {
       require(_totalSupply + amount <= maximumSupply,"You are exceeding the maximum supply");
       balances[to] += amount;
       _totalSupply += amount;
       emit Supply(maximumSupply,_totalSupply,remainingToken());
    }

    function burn (uint amount) public {
        require(balances[msg.sender] >= amount, "not enough balance to burn");
        balances[msg.sender] -= amount;
        _totalSupply -= amount;
    }

       
}