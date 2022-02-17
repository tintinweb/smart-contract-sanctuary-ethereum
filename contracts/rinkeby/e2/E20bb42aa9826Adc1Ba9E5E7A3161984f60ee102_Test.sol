/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.4.23;

contract Test{
   uint256 public sum;
   bool public iscontract;
    //function inputTest(address[] addrs,uint[] uints) public returns(address[],)
     function canSettleOrder(uint listingTime, uint expirationTime)
        view
        public
        returns (bool)
    {
        return (listingTime < now) && (expirationTime == 0 || now < expirationTime);
    }
    function checkSize(address sell) public returns(uint){
        uint size;
        address target = sell;
        assembly {
            size := extcodesize(target)
        }
        return size;
    }
    function isContract(address _addr) public returns (bool isContract){
    uint size;
    assembly {
    size := extcodesize(_addr)
    }
    iscontract=size>0;
    return (size > 0);
}
}