/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

// SPDX-License-Identifier: MIT

  pragma solidity ^ 0.8.0;

     contract Bank {
       
       address Owner ; 
         constructor () {
             Owner = msg.sender ;
         }

          struct user {
               string Name ;
               uint ID ;
             address payable Address ;
          }  uint id = 0;
              
             uint256  Lock_pool ;
             address statuse_log ;
             
           enum lock {none ,weekly, monthly, yearly } lock Lock ;

             struct menu {
                 uint  Balance ;
                 uint time ;
             }  menu public Menu ;


         mapping ( address => uint ) Wallet ;
          mapping ( uint => user ) User ;
          mapping ( address => bool ) Statuse ;
          mapping ( address => bool ) acounts;
          mapping ( address => mapping ( uint => uint )) Locked_accounts ;
            mapping ( address => user ) Page ;

            modifier Modifier () {
                require (  Owner != msg.sender, "You cannot register, dear owner" );
                  require ( Statuse [msg.sender] != true , "You have registered");_;
             }


             function Statuse_Lock () public view returns ( string [3] memory Log ) {
                require ( Statuse [msg.sender] == true, "Please log in to see the list" );
               Log = [" : 1_weekly : % 9' " , "2_monthly : % 21' " , " 3_yearly : % 60' " ] ;
             return Log ;
             }

           function Regester ( string memory name ) public Modifier  {
                ++ id ;
               User [id] = user ( name , id , payable(msg.sender)) ;
                 Page [ payable(msg.sender)] = user (  name , id , payable(msg.sender));
                 Statuse [msg.sender] = true ;
             }


             function Deposit () public payable {
              require ( Statuse [msg.sender] == true, "Please Please login to your account to deposit your assets in to see the list" );
                 if ( msg.value <= 25 ether){
                     Wallet [msg.sender] = msg.value ;
                       Wallet [msg.sender] -= 1e10;
                      Lock_pool += 1e10;
                 } if ( msg.value <= 50 ether  ) {
                      Wallet [msg.sender] = msg.value ;
                      Wallet [msg.sender] -= 1e15;
                      Lock_pool += 1e15;
                 } if ( msg.value >= 50 ) {
                      Wallet [msg.sender] = msg.value ;
                      Wallet [msg.sender] -= 1e17;
                      Lock_pool += 1e17;
                 } acounts [msg.sender] = true ;
             }


             function account () public view returns ( uint ) {
                require ( Statuse [msg.sender] == true, "Please log in to your account of Regester");
                  require ( acounts [msg.sender] == true , "Please recharge your account");
                return Wallet [msg.sender] ;
             }
           

         function Option ( lock number) public {
            require ( Statuse [msg.sender] == true, "Please log in to see the list" );
             require ( acounts [msg.sender] == true, "Please recharge your account" ); 
             if ( number == lock.weekly) {
                    statuse_log = (msg.sender);
                     Weekly ( payable(msg.sender));
                 }
              
             if ( number == lock.monthly) {
                     statuse_log = (msg.sender);
                     Monthly ( payable(msg.sender));
                 }

             if ( number == lock.yearly) {
                 statuse_log = (msg.sender);
                   yearly (payable (msg.sender));
                 }
         }

            function Weekly ( address ) private  {
                require ( Wallet [ statuse_log ] >= 1 ether,"For weekly locktime you must have at least 1 ETH in your wallet" );
                   Wallet [statuse_log] -= 1e18 ;
                   Wallet [statuse_log] -= 1e6; 
                   Lock_pool += 1e6 ;
                  uint value = 1e18;
                  Locked_accounts [statuse_log] [value] = block.timestamp + 604800 ;
                    Lock_pool += 1e18;
                   uint time =  Locked_accounts [statuse_log] [value] - block.timestamp ;
                    Menu = menu ( value , time);
             }

             function Monthly ( address ) private  {
                 require ( Wallet [statuse_log] >= 6 ether, " For monthly locktime you must have at least 6 ETH in your wallet" );
                   Wallet [statuse_log] -= 6e18 ;
                   Wallet [statuse_log] -= 1e6; 
                   Lock_pool += 1e6 ;
                 uint value = 6e18;
                  Locked_accounts [statuse_log] [value] = block.timestamp + 2628000 ;
                   Lock_pool += 6e18;
                    uint time =  Locked_accounts [statuse_log] [value] - block.timestamp ;
                    Menu = menu ( value , time);
             }  

             function yearly ( address ) private {
              require ( Wallet [statuse_log] >= 10 ether, " For yearly locktime you must have at least 10 ETH in your wallet" );
                 Wallet [statuse_log] -= 10e18 ;
                  Wallet [statuse_log] -= 1e6; 
                  Lock_pool += 1e6 ;
                 uint value = 10e18;
                  Locked_accounts [statuse_log] [value] = block.timestamp + 31536000 ;
                   Lock_pool += 10e18;
                    uint time =  Locked_accounts [statuse_log] [value] - block.timestamp ;
                    Menu = menu ( value , time);
             }

             
     }