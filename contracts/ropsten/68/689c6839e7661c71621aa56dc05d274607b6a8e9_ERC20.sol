/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT

  pragma solidity ^0.8.0; 

   interface IERC20 {

  function totalSupply () external view returns ( uint256 ) ;

   function balanceOf ( address account ) external view returns ( uint256 );

   function allowance ( address owner , address spendr ) external view returns ( uint256 ) ;

      function transfer ( address to , uint256 value ) external returns ( bool ) ;

      function approve ( address spender , uint256 value ) external returns ( bool );

      function transferFrom ( address from , address to , uint256 value ) external returns ( bool );

   event Transfer ( address indexed from , address indexed to , uint256 value ) ;

   event Approval ( address indexed  from , address indexed  to , uint256 value ); 

 }

    contract ERC20 is IERC20  {
      
   address Owner ;

     constructor ( string memory name_ , string memory symbol_ , uint8 decimals_ , uint256 totalSupply_ ) {

        Owner = msg.sender ;
          _name = name_ ;
          _symbol = symbol_ ; 
          _totalSupply = totalSupply_;
          _decimals = decimals_ ;

     _balances [msg.sender] = _totalSupply ;
     }

       mapping ( address => uint256  ) _balances ;
       mapping ( address => mapping ( address => uint256 )) _allowend ;


      string private _name ;

      string private _symbol ;

       uint256 private _totalSupply ;
 
      uint8 private _decimals ;

      
       function name () public view returns ( string memory ) {
       
       return _name ;
     }
       
       function symbol () public view returns ( string memory ) {

       return _symbol ;
     }

      function decimals () public view returns ( uint8 ) {
       
      return _decimals ;
     }

     function totalSupply () public override view returns ( uint256 ) {

     return _totalSupply ;
     }

     function balanceOf ( address account ) public override view returns ( uint256 ) {

      return _balances [ account ];
     }

     function allowance ( address _owner , address _spender ) public override view returns ( uint256 ) {

      return _allowend [_owner] [_spender] ;
     }

     function mint ( address account , uint256 amount ) public virtual {
       require ( msg.sender == Owner && account != address(0), "This is address zero");
       
         _balances [account] += amount ;
         _totalSupply += amount ;
      
      emit Transfer ( address(0) , account , amount);
     }

      

     function approve ( address _spender , uint256 _value ) public override  returns ( bool ) {
        
        _allowend [msg.sender] [_spender] = _value ;
        emit Approval ( msg.sender , _spender , _value );
      
      return true ;
     }
     
      function transfer ( address _to , uint256 _value ) public override returns ( bool ) {
        require ( msg.sender != address (0));
         require ( _to != address (0) );
            
            _balances [msg.sender] = _balances [msg.sender] - _value ;
            _balances[ _to] = _balances [_to] + _value ;

         emit Transfer ( msg.sender , _to , _value );
     return true ;
     }

      function transferFrom ( address _from , address _to , uint256 _value ) public override returns ( bool ) {
        require ( _from != address(0) );
         require ( _to != address(0) );

            _balances[_from ] = _balances [_from ] - _value ;
            _balances [_to] = _balances [_to] + _value ;

         emit Transfer ( _from , _to , _value );
     return true ;
     }
 
      
       function burn ( address account , uint256 value ) public {
           
       }
 
 
 
 
 
 
 
 
 
 
 
  }