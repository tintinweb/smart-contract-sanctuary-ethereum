/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

interface airdrop {
    function transferFrom(address from,address to,uint256 tokenId) external;
    function tokensOfOwner(address owner) external view returns (uint256);
    function mint() external;
}

contract multiCall{
    address constant contra = address(0xB4feDc003053C22ac8b808Bb424f3e1787f30cF2);
    function call(uint256 times) public {
        for(uint i=0;i<times;++i){
           new claimer(contra);
        }
    }
}
contract claimer{
    constructor(address contra){
        airdrop(contra).mint();
        uint256 id = airdrop(contra).tokensOfOwner(address(this));
        airdrop(contra).transferFrom(address(this),msg.sender,id);
        selfdestruct(payable(address(msg.sender)));
    }
}