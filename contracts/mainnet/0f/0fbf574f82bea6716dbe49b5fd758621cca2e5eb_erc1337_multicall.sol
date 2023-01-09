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
//
//  
//  erc1337     Coffee & Weed
//  
//  Wrapper for multicalls and delegated multicalls
//  Originally to aggregate multiple Augminted Scientists $SCALEs claim calls
//  
//  
// SPDX-License-Identifier: Do what the fuck you want
pragma solidity ^0.8.17;

contract erc1337_multicall {
    function multiDelegatecall(address target, bytes[] calldata calls) external payable returns (bytes[] memory results) {
        uint256 length = calls.length;
        results = new bytes[](length);
        for (uint256 i; i < length;) {
            bool success;
            (success, results[i]) = target.delegatecall(calls[i]);
            require(success, "Multicall3: call failed");
            unchecked { ++i; }
        }
    }

    function multicall(address target, bytes[] calldata calls) external payable returns (bytes[] memory results) {
        uint256 length = calls.length;
        results = new bytes[](length);
        for (uint256 i; i < length;) {
            bool success;
            (success, results[i]) = target.call(calls[i]);
            require(success, "Multicall3: call failed");
            unchecked { ++i; }
        }
    }
}