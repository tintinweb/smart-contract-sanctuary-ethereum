/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: MIT

  pragma solidity ^ 0.8.0;
   
    interface IERC20 {

    function totalSupply () external  view returns ( uint256 );

      function balanceOf ( address account ) external view returns ( uint256 );

      function allowance ( address owner , address spender ) external view returns ( uint256 );

       function transfer ( address to , uint value ) external returns ( bool );

        function approve ( address spender , uint value ) external returns ( bool ) ;

       function transferFrom ( address from , address to , uint value ) external returns ( bool );

      event Transfer ( address indexed from , address indexed to , uint value );

    event Approval ( address indexed from , address indexed to , uint value );

 }


    contract ERC20 is IERC20 {

   address Owner ;
   
    constructor ( string memory name_ , string memory symbol_ , uint256 totalSupply_ ) {
      
      Owner = msg.sender; 
       _name = name_ ;
       _symbol = symbol_ ;
         _decimals = 18 ;
         _totalSupply = totalSupply_ ;

      _balances [msg.sender ] = _totalSupply ;
    }

   mapping ( address => uint256 ) _balances ;
   mapping ( address => mapping ( address => uint256 )) _allowance ;

     string private _name ;

     string private _symbol ;

     uint8 private _decimals ;

     uint256 private _totalSupply;

      
        function name () public view returns ( string memory ) {

       return _name ;
     }

        function symbol () public view returns ( string memory ) {
      
       return _symbol ;
     }

        function decimals () public view returns ( uint256 ) {

       return _decimals ;
     }

        function totalSupply () public override view returns ( uint256 ) {

       return _totalSupply ;
     }

        function balanceOf ( address account ) public override view returns ( uint256 ) {

       return _balances [account] ;
     }

        function owner () public view returns ( address ) {

       return Owner ;
     }

        function allowance ( address _owner , address _spender ) public override view returns ( uint256 ) {

        return _allowance [_owner] [_spender] ;
     }
        
        function transfer ( address _to , uint256 _value ) public override returns ( bool ) {
         require ( msg.sender != address(0), "This address is zero " );
         require ( _to != address(0), " This address is zero " );

            _balances [msg.sender] = _balances [msg.sender] - _value ;
            _balances [_to] = _balances [_to] + _value ;

         emit Transfer ( msg.sender , _to , _value ) ;
      return true ;
     }
     
        function approve ( address _spender , uint _value ) public override returns ( bool ) {

         _allowance [msg.sender] [_spender] = _value ;
         emit Approval ( msg.sender , _spender , _value );
      return true ;
     }

        function transferFrom ( address _from , address _to , uint256 _value ) public override returns ( bool ) {
        require ( _from != address (0) , "This address is Zero");
         require ( _to != address(0) , "This address is Zero " );

            _balances [_from] = _balances [_from] - _value ;
            _balances [_to] = _balances [_to]  + _value ;

         emit Transfer ( _from , _to , _value ) ;
      return true ; 
     }

 }