/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;
contract TempStorage{
    mapping(address=>bool) public _isChannelUpdated;

    address public Core_Address; 

    constructor(address _coreAddress)public{
        require(_coreAddress != address(0),"Core address cannot be zero");
        Core_Address = _coreAddress;
    }

    function isChannelAdjusted(address _channelAddress) external view returns(bool) {
        return _isChannelUpdated[_channelAddress];
    }

    function setChannelAdjusted(address _channelAddress) external {
         require(msg.sender == Core_Address, "Can only be called via Core");
        _isChannelUpdated[_channelAddress] = true;
    }
}