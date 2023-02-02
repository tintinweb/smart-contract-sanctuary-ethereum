/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ContractInterface {
    function stake(uint256[] memory tokenId) external payable ;
    function unStake(uint256[] memory tokenId) external payable ;
    function ownerOf(uint256 tokenId) external payable returns(address) ;
    }
contract abc {
   
    ContractInterface main1;
    function setContract(address a) public {
     main1 = ContractInterface(a);
  }
    function stake(uint256[] memory tokenId) public payable {
        for(uint256 i = 0;i<tokenId.length;i++){
            require(main1.ownerOf(tokenId[i])== msg.sender,"not owner");
        }
        main1.stake(tokenId);
    }

}