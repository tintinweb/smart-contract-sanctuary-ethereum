/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

contract marketingWallet{

    address payable private gnosisMultiSig;
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor (address _addr) {
        gnosisMultiSig = payable(_addr); 
        _owner = _addr;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }
    
    fallback() external  payable { }

    
    function _sentEthToGnosis() external onlyOwner{
        (bool success,) = gnosisMultiSig.call{value:(address(this).balance)}("");
        require(success, 'Failed to forward funds');
    }

}