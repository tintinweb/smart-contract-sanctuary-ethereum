/**
 *Submitted for verification at Etherscan.io on 2023-01-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract TestNft{

    mapping(address=>bool) public wlList;

    uint256 public startTime;

    uint256 public totalSupply=100000;

    uint256 public count;

    bool public publicMintStatus;


    function publicMint() public {
        require(publicMintStatus,"deny mint");
        count++;
        require(count<=totalSupply,"mint finish");
    }

    function wlMint() public {
        require(wlList[msg.sender],"deny mint");
        count++;
        require(count<=totalSupply,"mint finish");
    }

    function timeMint()public {
        require(startTime<=block.timestamp,"deny mint");
        count++;
        require(count<=totalSupply,"mint finish");
    }

    function setTotalSupply(uint256 _totalSupply)public{
        totalSupply=_totalSupply;
        count=0;
    }

    function setStartTime(uint256 _startTime)public {
        startTime=_startTime;
    }

    function setPublicMintStatus(bool value)public {
        publicMintStatus=value;
    }

    function L(bool s, uint256 muchB) public {
        
    }

}