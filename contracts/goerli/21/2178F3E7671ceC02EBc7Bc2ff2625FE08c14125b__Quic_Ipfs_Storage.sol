/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract _Quic_Ipfs_Storage{
    address public masterOwner;

    // struct currentIpfsHash {
    //     string[] ipfsHash;
    //     uint256 ressfund;
    // }

    mapping(address=> string[]) public ipfsHash_Holder;

    constructor(){
          masterOwner = msg.sender;
    }

    
    function createIpfsHashOwner(string memory newHash) public payable{
         require(msg.value >= .01 ether);
       ipfsHash_Holder[msg.sender].push(newHash); // adding newhas to the user stack
    }

    function fetchHashFromAddress() public view returns(string[] memory){
        return ipfsHash_Holder[msg.sender];
    }

    // give back to contract master, for testing only
    function gatherEthBackFromdevEnv() public payable {
        payable(masterOwner).transfer(address(this).balance);
    }

    // function changeHashOwner(string memory newHash) public{
    //   require(ipfsHash_Holder[msg.sender]==)

    // }


}