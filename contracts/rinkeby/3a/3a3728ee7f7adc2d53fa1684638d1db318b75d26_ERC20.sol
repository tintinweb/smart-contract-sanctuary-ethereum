/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

 


 
  interface IERC20 {

     function totalSupply() external view returns(uint256);
     function balanceof(address account) external view returns(uint256);
     function transfer(address to, uint256 amount) external  returns(bool);
     function allowance(address owner , address spender)external view returns(uint256);
     function approve(address spender , uint256 amount)external  returns (bool);
     function transferFrom(address from , address to , uint256 amount) external returns(bool);

     event Transfer(address indexed from , address indexed to, uint256 value);
     event Approvel(address indexed owner , address indexed spender , uint256 value);


}


 contract ERC20 is IERC20{

    

     mapping(address => uint256) _balances;
     
     mapping(address => mapping(address => uint256))_allowances;


     uint256 private _totalSupply;
     uint256 private decimalse;
     string  private name;
     string  private symbol;

     constructor(){
          name= "iman";
          symbol="imo";
          _totalSupply=1000000000000;
          decimalse=10;
          _balances[msg.sender]=_totalSupply;
     }

    //   function name()public view virtual  returns(string memory) {
    //      return _name;

    //  }

    //  function symbol()public view virtual returns(string memory){
    //      return _symbol;

    //  }

  

    //  function decimalse() public view virtual returns(uint256){
    //      return _decimalse;
    //  }

       function totalSupply()public view virtual override returns (uint256){

        return _totalSupply;

    }

     function balanceof(address account)public view virtual override returns(uint256){
        return _balances[account];

     }

     

      function _transfer(address from, address to,uint256 amount) internal virtual {
         require(from != address(0),"ERC20: trassfer from the zero address");
         require(to   != address(0), "ERC20: trassfer  to  the zero address");

         uint256 FromBalances = _balances[from];
         require(FromBalances >= amount,"ERC20: Your inventory is insufficient");

        _balances[from] = _balances[from] - (amount);
        _balances[to] = _balances[to] + (amount);

        emit Transfer(from, to, amount);

     }

     function _approve(address owner,address spender, uint256 amount)internal virtual {
         require(owner   != address(0), "ERC20: approve owner the zero address");
         require(spender != address(0), "ERC20: approve spender the zero address");

         _allowances[owner][spender]= amount;
         emit Approvel(owner, spender, amount);
     }

     

     function transfer(address to, uint256 amount) public virtual override  returns(bool) {
       address from =msg.sender;
        _transfer(from, to, amount);
        return true;
     }


     
    function allowance (address owner,address spender)public view virtual override returns(uint256){
      return _allowances[owner][spender];

    }

    
    function approve(address spender, uint256 amount)public virtual override returns(bool){
        address owner = msg.sender;
        _approve(owner, spender, amount);
         return true;


    }


     function transferFrom(address from,address to, uint256 amount)public  virtual override returns(bool)
    {
     address spender =msg.sender;
     require(amount <= _allowances[from][spender]);
     _transfer(from, to, amount);
    
     return true;

    }

    
 }