/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


abstract contract toCall {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
  function balanceOf(address owner) external virtual view returns (uint256 balance);
}

contract Caller {
    address contractAddress = 0x67Df369a31c60C060855aF135135fAeCC8508F16;

    function getContractInstance() public view returns(toCall) {
        return toCall(contractAddress);
    }

    function getBalanceOf(address _address)public view returns(uint256) {
        return getContractInstance().balanceOf(_address);
    }

    function getOwnerOf(uint256 _tokenId) public view returns(address) {
        return getContractInstance().ownerOf(_tokenId);
    }

    function setContractToCall(address _contractAddress) public  {
        contractAddress = _contractAddress;
    }
}