/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

// File: contracts/callerContract.sol



pragma solidity >=0.7.0 <0.9.0;


abstract contract toCall {
  function ownerOf(uint256 tokenId) public virtual view returns (address);
}

contract Caller {
    toCall private contractInstance;
    address contractToCall = 0x16fD6a57a239D7c9E5C6092AF675498eDD51975F;

    constructor () {
        contractInstance = toCall(contractToCall);
    }

    function getOwnerOf() public view returns(address) {
        return contractInstance.ownerOf(1);
    }
}