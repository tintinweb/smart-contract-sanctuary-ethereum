pragma solidity >=0.6.0 <0.7.0;

/* @notice - A temproary storage contract that keeps track of channels whose
*            new poolContribution and weight has been updated
*
*            This helps us flag the already adjusted channels and ensure that
*            they are not repeated in the for loop.
*
*/
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