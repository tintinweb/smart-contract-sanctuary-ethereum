pragma solidity ^0.5.16;

contract SimpleProxy {

    address internal masterCopy;
    address internal owner;


    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "BID:Zero master is not permitted");
        masterCopy = _masterCopy;
        owner=msg.sender;
    }

    function setMaster(address _masterCopy) external{
        require(msg.sender==owner, "not controller");
        masterCopy = _masterCopy;
    }

    function ()
        external
        payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }
}