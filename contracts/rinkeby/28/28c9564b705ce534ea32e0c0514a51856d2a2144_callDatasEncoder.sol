/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier : MIT

pragma solidity ^0.8.10;

contract callDatasEncoder {
        
    uint private amountOutMin1 = 1000;
    address[] private AvaxShermix = [0xFBf02764ca98778F07b5bF6677ce09B85476a7aC, 0xa1091A624AFcab43575298447c6c60Fc54966917];
    address private timelock = 0x28EEd3aC3eBD21F849C4c0cA969ddb90fa01a9d3;
    uint private deadline1 = 11111111111; 


    
    function getCallDatas() public view returns (bytes memory callDatas) {

        uint amountOutMin = amountOutMin1;
        address[] memory path = AvaxShermix ;
        address to = timelock;
        uint deadline = deadline1; {
            
        return callDatas = abi.encodeWithSignature("swapExactAVAXForTokens(uint256,address[],address,uint256)", amountOutMin, path, to, deadline); 
            
        }
        
        
        
    }

}