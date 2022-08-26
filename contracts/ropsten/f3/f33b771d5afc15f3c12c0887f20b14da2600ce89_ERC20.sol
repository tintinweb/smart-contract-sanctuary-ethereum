/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT

   pragma solidity ^ 0.8.0;

    interface IERC20 
    {

       function totalSupply () external view returns (uint256);

       function balanceOf (address account) external view returns (uint256);

       function allowence (address owner , address spender) external view returns (uint256);

       function transfer (address to , uint256 amount) external returns (bool);

       function transferFrom (address from , address to , uint256 amount) external returns (bool);

       function approve (address spender , uint256 amount) external returns (bool);

          event Transfer (address indexed from , address indexed to , uint256 amount);

          event Approval (address indexed from , address indexed to , uint256 amount);

     }


       contract ERC20 is IERC20 
      {
     
        address Owner;

        string private _name;

        string private _symbol;

        uint256 private _totalSupply;

        uint8 private _decimals; 

          mapping (address => uint256) balances;
          mapping (address => mapping(address => uint256)) allowences;

     constructor ( string memory name_ , string memory symbol_ , uint256 totalSupply_ , uint8 decimals_)
     {
        Owner = msg.sender ;

         _name = name_;
         _symbol = symbol_;
         _totalSupply = totalSupply_;
         _decimals = decimals_;

       balances [msg.sender] = _totalSupply ;    
    }

    function name () public view  returns (string memory)
    {
        return _name ;
    }

    function decimals () public view returns (uint8)
    {
        return _decimals; 
    }

    function symbol () public view returns (string memory)
    {
        return _symbol;
    }

    function allowence ( address owner , address spender) public view override returns (uint256)
    {
        return allowences [owner][spender] ;
    }

    function totalSupply () public view override returns (uint256)
    {
        return _totalSupply;
    } 

    function balanceOf (address account) public view override returns (uint256)
    {
        return balances [account];
    }

    function approve (address owner, uint256 value) public override returns (bool)
    {
        balances [owner] = value ;
        emit Approval (msg.sender , owner , value);
    
     return true ;
    }

    function transfer (address to , uint256 value) public override returns (bool)
    {
        balances [to] = value ;
     emit Transfer(msg.sender , to , value);
    
     return true ;
    }

    function transferFrom (address from , address to , uint256 value) public override returns (bool)
    {
        require (from != address(0));
        require (to != address(0));

     balances [from] = balances [from] - value ;
     balances [to] = balances [to] + value ;

     emit Transfer (from , to , value);
      return true ;
    }

     
}