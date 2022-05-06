/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract StakingInterface {

    function getNumber(address _metamorphicContractAddress) public returns (uint256){
        bytes memory data = abi.encodeWithSignature("getNumber()");
        (bool success, bytes memory result) = _metamorphicContractAddress.call(data);

        uint256 value = abi.decode(result, (uint256));
    
        return value;
    }
}