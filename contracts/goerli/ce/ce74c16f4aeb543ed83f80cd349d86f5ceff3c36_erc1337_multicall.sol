//  
//     ▐▀▄       ▄▀▌   ▄▄▄▄▄▄▄             
//     ▌▒▒▀▄▄▄▄▄▀▒▒▐▄▀▀▒██▒██▒▀▀▄          
//    ▐▒▒▒▒▀▒▀▒▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▀▄        
//    ▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▄▒▒▒▒▒▒▒▒▒▒▒▒▀▄      
//  ▀█▒▒▒█▌▒▒█▒▒▐█▒▒▒▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▌     
//  ▀▌▒▒▒▒▒▒▀▒▀▒▒▒▒▒▒▀▀▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐   ▄▄
//  ▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▌▄█▒█
//  ▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▒█▀ 
//  ▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒█▀   
//  ▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▌    
//   ▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐     
//   ▐▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▌     
//    ▌▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▐      
//    ▐▄▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▄▌      
//      ▀▄▄▀▀▀▀▀▄▄▀▀▀▀▀▀▀▄▄▀▀▀▀▀▄▄▀        

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract erc1337_multicall {
    error DelegatecallFailed();
    error MulticallFailed();

    function multiDelegatecall(address target, bytes[] calldata calls) external payable returns (bytes[] memory results) {
        uint256 length = calls.length;
        results = new bytes[](length);
        for (uint256 i; i < length;) {
            bool success;
            (success, results[i]) = target.delegatecall(calls[i]);
            if (!success) { revert DelegatecallFailed(); }
            unchecked { ++i; }
        }
    }

    function multicall(address target, bytes[] calldata calls) external payable returns (bytes[] memory results) {
        uint256 length = calls.length;
        results = new bytes[](length);
        for (uint256 i; i < length;) {
            bool success;
            (success, results[i]) = target.call(calls[i]);
            if (!success) { revert MulticallFailed(); }
            unchecked { ++i; }
        }
    }
}