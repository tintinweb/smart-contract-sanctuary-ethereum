/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

/**
 *Submitted for verification at Etherscan.io on 2022-05-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.11 <0.9.0;

contract TestErrors {
    uint public number;
    function TestRequire(uint  value) public returns(bool) {
        require(value<10, "Value is not good");
        number = value;
        return true;
    }

    function TestAssert(uint  value) public returns(bool) {
        assert(value<10);
        number = value;
        return true;
    }

     function TestRevert(uint  value) public returns(bool) {
        if(value < 10 || value > 255){
             revert("Overflow Exist");
         }
        number = value;
        return true;
    }

      error TokenPriceNotMatchValue(bytes32 revertReason, uint valueSent, uint totalTokenPrice);

    function TestRevertEvent(uint  value) public returns(bool) {
        if(value < 10 || value > 255){
            uint totalTokenPrice = 5000 ;//some inner extra data calulation value
            revert TokenPriceNotMatchValue({
                revertReason: "somthing fail",
                valueSent: value,
                totalTokenPrice: totalTokenPrice
            });
         }
        number = value;
        return true;
    }

     function TestRequireWithStateChange(uint  value) public  returns(bool) {
        require(value<10, "Value is not good");
        number=15;
        return true;
    }

     function TestRevertEventWithStateChange(uint  value) public returns(bool) {
        number=20;
        if(value < 10 || value > 255){
            uint totalTokenPrice = 5000 ;//some inner extra data calulation value
            revert TokenPriceNotMatchValue({
                revertReason: "somthing fail",
                valueSent: value,
                totalTokenPrice: totalTokenPrice
            });
         }
        return true;
    }

}