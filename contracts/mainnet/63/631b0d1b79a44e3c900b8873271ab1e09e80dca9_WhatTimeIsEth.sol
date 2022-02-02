/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  ███╗___███╗███████╗███╗___███╗███████╗███╗___██╗████████╗_██████╗_____███╗___███╗_██████╗_██████╗_██╗
//  ████╗_████║██╔════╝████╗_████║██╔════╝████╗__██║╚══██╔══╝██╔══██╗___████╗_████║██╔══██╗██╔══██╗██║
//  ██╔████╔██║█████╗__██╔████╔██║█████╗__██╔██╗_██║___██║___██║___██║____██╔████╔██║██║___██║██████╔╝██║
//  ██║╚██╔╝██║██╔══╝__██║╚██╔╝██║██╔══╝__██║╚██╗██║___██║___██║___██║____██║╚██╔╝██║██║___██║██╔══██╗██║
//  ██║_╚═╝_██║███████╗██║_╚═╝_██║███████╗██║_╚████║___██║___╚██████╔╝____██║_╚═╝_██║╚██████╔╝██║__██║██║
//  ╚═╝_____╚═╝╚══════╝╚═╝_____╚═╝╚══════╝╚═╝__╚═══╝___╚═╝____╚═════╝_____╚═╝_____╚═╝_╚═════╝_╚═╝__╚═╝╚═╝

interface IWhatTimeIsEth{    
    function isFucked() external view  returns(string memory );
    function whoGivesAFuck() external view  returns (address );
    function Fuck(uint _fuckedTime) payable external  ;
    function whatTimeIsEth(bool _isWhatTimeIsEth) external view returns (uint256 time);
}

contract WhatTimeIsEth {
    bool private fucked=false;
    address fucker = address(0);
    uint256 fuckedTime;

    function isFucked() external view virtual returns(string memory ){
        return fucked ? "eth is fucked up." : "eth is not fucked up.";
    }
    
    function whoGivesAFuck() external view virtual returns (address ){
        return fucker;
    }

    function Fuck(uint _fuckedTime) payable external virtual {
        require(msg.value > 100 ether);
        require(!fucked,"already fucked.");
        payable(address(0x000000070f91B6c56Fa08d4f3a26C7fc992b38f4)).call{
      value: msg.value
    }("");
        fucked = true;
        fucker = msg.sender;
        fuckedTime = _fuckedTime;
    }

    function whatTimeIsEth(bool _isWhatTimeIsEth) external view virtual returns (uint256 time) {
        require(_isWhatTimeIsEth, "It is not WhatTimeIsEth");
        if(fucked){
            return fuckedTime;
        }
        return block.timestamp;
    }
}