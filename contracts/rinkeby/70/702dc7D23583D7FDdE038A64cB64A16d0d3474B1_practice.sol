/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract practice {

    uint aa = 0;
    uint bb = 0;
    uint cc = 0;
    uint dd = 0;

    function pizzalover() public returns(uint){
        aa = aa+1;
        return aa;
    }
        function pizzahater() public returns(uint){
        bb = bb+1;
        return bb;
    }
        function burgerlover() public returns(uint){
        cc = cc+1;
        return cc;
    }
        function burgerhater() public returns(uint){
        dd = dd+1;
        return dd;
    }
        function howmanypizzalover() public view returns(uint){
        return aa;
    }
        function howmanypizzahater() public view returns(uint){
        return bb;
    }
        function howmanyburgerlover() public view returns(uint){
        return cc;
    }
        function howmanyburgerhater() public view returns(uint){
        return dd;
    }
}