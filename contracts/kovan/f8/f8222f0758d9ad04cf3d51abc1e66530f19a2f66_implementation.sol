/**
 *Submitted for verification at Etherscan.io on 2022-07-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
contract implementation {


    function call(address _addr) public payable{
      (bool success, bytes memory data)=_addr.call{value: msg.value, gas: 55000}(
            abi.encodeWithSignature("add('2','5')")
        );
    }

    function delegate(uint a,uint b,address _contract) public payable{
  (bool success, bytes memory data) = _contract.delegatecall(
             abi.encodeWithSignature("add(uint,uint)", a,b)
        );
    }

}