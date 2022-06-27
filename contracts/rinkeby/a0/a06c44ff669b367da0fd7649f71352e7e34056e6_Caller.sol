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
    toCall private contractInstance;
    address contractAddress;

    constructor () {
        contractInstance = toCall(contractAddress);
        contractAddress = 0x3A8e197337c66e751e2E06b61C3BfDf4317e6731;
    }

    function getBalanceOf(address _address)public view returns(uint256) {
        return contractInstance.balanceOf(_address);
    }

    function getOwnerOf(uint256 _tokenId) public view returns(address) {
        return contractInstance.ownerOf(_tokenId);
    }

    function setContractToCall(address _contractAddress) public  {
        contractAddress = _contractAddress;
    }
}