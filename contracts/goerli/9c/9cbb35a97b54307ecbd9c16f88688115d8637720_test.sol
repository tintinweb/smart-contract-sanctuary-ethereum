/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract test {

    function gethashInfo(address _nftAddress, uint256 _optionsId,uint256 _tokenId) public view returns(bytes32)
    {
        return keccak256(abi.encodePacked(msg.sender, _nftAddress, _optionsId, _tokenId));
    }

    function gethashInfoV1(address _account, address _nftAddress, uint256 _optionsId,uint256 _tokenId) public pure returns(bytes32)
    {
        return keccak256(abi.encodePacked(_account, _nftAddress, _optionsId, _tokenId));
    }
}

// bytes32 _value = keccak256(abi.encodePacked(account, _ops,_id));