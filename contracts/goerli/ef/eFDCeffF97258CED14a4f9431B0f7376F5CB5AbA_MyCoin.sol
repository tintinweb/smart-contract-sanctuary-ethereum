/**
 *Submitted for verification at Etherscan.io on 2023-03-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IERC20 {
    
    event Transfer(address indexed from, address indexed to, uint256 value);

   event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

   function allowance(address owner, address spender) external view returns (uint256);

   function approve(address spender, uint256 amount) external returns (bool);

   function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IERC20MetaData{
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}




contract MyCoin is IERC20,IERC20MetaData{

    address _owner;

    string _name;
    string _symbol;

    uint256 _totalSupply;

    mapping(address=>uint256) _balanceMap;

    mapping(address=>mapping(address=>uint256)) _allowance;

    constructor(string memory name_ ,string  memory symbol_ ,uint256  totalSupply_ ){
            _owner=msg.sender;
            _name=name_;
            _symbol=symbol_;
            _balanceMap[msg.sender]=totalSupply_;
            _totalSupply=totalSupply_;
    }

    modifier onlyOwner{
        require(_owner==msg.sender,"deny: only owener can call this function");
        _;
    }

    function mint(address account,uint256 amount) onlyOwner public {
        require(account!=address(0),"can't be address 0");
        _totalSupply+=amount;
        _balanceMap[account]+=amount;
        emit Transfer(address(0),account,amount);
    }

    function burn(address account,uint256 amount) onlyOwner public{
        require(account!=address(0),"can't be address 0");
        _totalSupply-=amount;
         uint256 accountBalance= _balanceMap[account];
         require(accountBalance> amount,"balacne not enough to burn");
         _balanceMap[account]-= amount;
        emit Transfer(account,address(0),amount);
    }


    function name() public view returns (string memory){
        return _name;
    }

    
    function symbol() public view returns (string memory){
        return _symbol;
    }

    function decimals() public pure returns (uint8){
        return 18;
    }


     function totalSupply()  public view returns (uint256){
            return _totalSupply;
     }


     function balanceOf(address account)  public view returns (uint256){
         return _balanceMap[account];
     }

    function _transfer(address from,address to, uint256 amount) internal returns (bool){
        uint256 balanceNow= _balanceMap[from];
        require(balanceNow>amount,"money is not enough");
        require(to!=address(0),"this is a blackhole address");
        _balanceMap[from]-=amount;
        _balanceMap[to]+=amount;
        emit Transfer(from,to,amount);
        return true;
        }

     function transfer(address to, uint256 amount) public returns (bool){
        return _transfer(msg.sender,to,amount);
     }

   function allowance(address owner, address spender) public view returns (uint256){
        return _allowance[owner][spender];
   }

    function _approve(address owner,address spender, uint256 amount) internal returns (bool){
         _allowance[owner][spender]=amount;
        emit Approval(owner,spender,amount);
        return true;
     }


     function approve(address spender, uint256 amount) public returns (bool){
        return _approve(msg.sender,spender,amount);
     }

        function transferFrom(address from, address to, uint256 amount) public returns (bool){
                uint256 myAllowance=_allowance[from][msg.sender];
                require(amount<myAllowance,"allowance is not enough");
                require(amount<_balanceMap[from],"balance is not enough");
                
                _approve(from,msg.sender,myAllowance-amount);
               return _transfer(from,to,amount);

        }









}