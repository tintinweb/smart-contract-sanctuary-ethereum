/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT

 pragma solidity ^ 0.8.15 ;

   interface IERC20 {

       function totalSupply () external view returns ( uint256 ) ;

        function balanceOf (address account) external view returns ( uint256 ) ;

      function allowece ( address owner , address spender ) external view returns ( uint256 ) ;


           function transfer ( address to , uint amount ) external  returns ( bool );

         function approve ( address spender , uint amount ) external returns ( bool ) ;

           function transferFrom ( address from , address to , uint amount ) external returns ( bool );


            event Transfer ( address indexed from , address indexed to , uint amount ) ;

            event Approval ( address indexed from , address indexed to , uint amount ) ;
     }


       contract ERC20 is IERC20 { 


       string  public _name ; 
        
        string public _symbol ;

        uint public  _desimal ;

        uint public  _totalSupply;


            mapping ( address => uint ) balances ;
            mapping ( address => mapping ( address => uint )) allowend ;


           constructor () {
                 _name = "MEHRAN";
                _symbol = "MHN";
               _desimal = 10 ;
              _totalSupply = 100000000000 ;
             balances [msg.sender] = _totalSupply ;
           }

 
         function totalSupply () public view override returns (uint256 ) {
            return _totalSupply ;
         }

          function balanceOf ( address account ) public view returns ( uint256 ) {
           return balances [account ] ;
         }


          function allowece  (address owner , address spender) public override view returns ( uint256 ) {
              
               return allowend [owner] [ spender] ;
             }

             function transfer ( address to , uint amount ) public override returns ( bool ) {
             require ( balances [msg.sender] >= amount );
                 balances [msg.sender] = balances [msg.sender] - amount ;
                 balances [ to] =  balances [ to] + amount ;
                 emit Transfer ( msg.sender ,  to , amount ) ;
               return true ;
             }


             function approve ( address spender , uint amount ) public override returns ( bool ) {
                  allowend [msg.sender] [spender] = amount ;
                 emit Approval ( msg.sender , spender , amount ) ;
                return true ;
             }


             function transferFrom ( address from , address to , uint amount ) public override returns ( bool ) {
             require ( balances [msg.sender] >= amount ) ;
               require ( allowend [from][msg.sender] >= amount );
               balances [from] = balances [from] + amount ;
                allowend [from] [msg.sender] = allowend [from] [msg.sender] + amount ;
                balances [to] = balances [to] + amount ;
             return true ;
         }





      }