// SPDX-License-Identifier: MIT
// author: Exotic Technology LTD

/*

                          %%%%%*       /%%%%*                              
                         %%%                         %%                         
                     .%%                                 %%                     
                   %%                                       %                   
                 %%                                           %                 
               %%                                               %               
             .%     @@@@@@@@@@@@@@@@@@@@@               @@@@                    
            %%      @@@                @@@             @@@         ,            
            %       @@@                  @@@         @@@                        
           %%       &&&                   &@@@     @@@              %           
           %        &&&                     @@@@ @@@                            
          ,%        &&&&&&&&&&&&&&&&&&&%%(.   @@@@@                             
           %        %%%                      @@@@@@@                            
           %        %%%                    @@@@   @@@@                          
           %%       %%%                  @@@@       @@@             %           
            %%      %%%                 @@@           @@@          %            
             %%     %%%               @@@               @@@       %             
              %%    %%%%%%%%%%%%%%%%@@@                  @@@@    %              
                %%                                             %                
                  %%                                         %                  
                    %%                                     %                    
                       %%%                             %%                       
                            %%%                   %%#                           
                                    #%%%%%%%                                    
*/

pragma solidity ^0.8.0;

import "./ownable.sol";

contract exoticJudge is Ownable{

    bool private replacePayee  = false;

    bool private canTransferOwnership  = false;

    bool private replaceExpenseWallet  = false;

    bool private changeExpenseAmount  = false;


    function flipReplacePayee()public onlyOwner{

        replacePayee = !replacePayee;

    }

    function getCanReplacePayee() public view returns(bool){

      return replacePayee;

    }
    
    function flipTransferOwnership()public onlyOwner{

        canTransferOwnership = !canTransferOwnership;

    }

    function getCanTransferOwnership() public view returns(bool){

      return canTransferOwnership;

    }
    
    function flipExpenseWallet()public onlyOwner{

        replaceExpenseWallet = !replaceExpenseWallet;

    }

    
    function getCanflipExpenseWallet() public view returns(bool){

      return replaceExpenseWallet;

    }


    
    function flipExpenseAmount()public onlyOwner{

        changeExpenseAmount = !changeExpenseAmount;

    }

    
    function getCanExpenseAmount() public view returns(bool){

      return changeExpenseAmount;

    }





}