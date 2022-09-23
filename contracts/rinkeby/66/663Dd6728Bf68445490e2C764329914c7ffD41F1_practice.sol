/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract practice {

    uint aa = 1;

    function pizzalover() public returns(uint){
        aa = aa+1;
        return aa;
    }
        function pizzahater() public returns(uint){
        aa = aa+1;
        return aa;
    }
        function burgerlover() public returns(uint){
        aa = aa+1;
        return aa;
    }
        function burgerhater() public returns(uint){
        aa = aa+1;
        return aa;
    }
        function howmanypizzalover() public view returns(uint){
        return aa;
    }
        function howmanypizzahater() public view returns(uint){
        return aa;
    }
        function howmanyburgerlover() public view returns(uint){
        return aa;
    }
        function howmanyburgerhater() public view returns(uint){
        return aa;
    }
}