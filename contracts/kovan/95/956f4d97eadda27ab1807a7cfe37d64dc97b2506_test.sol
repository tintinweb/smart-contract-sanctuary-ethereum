/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract test{
    
        struct tokenBalanceStruct{
            address addr;
            uint    amount;
            uint    types;
            uint    state;
        }
        function tokenBalance(address userAddr) public view returns(tokenBalanceStruct[] memory allbalances){

        }

         struct userContStruct{
        uint    id;
        address collaAddr;
        uint    collaAmount;
        address USDAddr;
        uint    USDAmount;
        uint    USDAmountEst;
        uint    factor;
        uint    debt;
    }
    function getUserCont(address userAddr) public view returns(userContStruct[] memory userContAll){

    }

    function collaToValue(address collaAddr, uint amount) public view returns(uint){

    }

    function liquiContCollaAmount(address userAddr,uint contId) public view returns(uint){
        
    }
}