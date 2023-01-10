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
//  Author :      [erc1337] Coffee & Weed
//  Description:  Wrapper to aggregate multiple Augminted Scientists $SCALEs claims in 1 tx
//  SPDX-License-Identifier: Do what the fuck you want
pragma solidity ^0.8.17;

error ClaimFailed();
error WithdrawFailed();

contract erc1337_MulticallScientists {
    address owner;
    address scientists = 0xA310425046661c523d98344F7E9D66B32195365d;

    constructor(){
        owner = msg.sender;
    }

    function claimAll(uint256[] calldata _ids) external payable {
        uint256 length = _ids.length;
        for (uint256 i; i < length;) {
            bool success;
            (success, ) = scientists.delegatecall(abi.encodeWithSignature("claimScales(uint256)", _ids[i]));
            if(success == false) revert ClaimFailed();
            unchecked { ++i; }
        }
    }

    function setScientists(address _scientists) external payable {
        require(msg.sender == owner, "Not owner");
        scientists = _scientists;
    }

    // If someone is dumb enough to send funds, at least it's not lost
   function withdraw() external {
        require(msg.sender == owner, "Not owner");
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        if(success == false) revert WithdrawFailed();
    }
}