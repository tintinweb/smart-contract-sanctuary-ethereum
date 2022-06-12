pragma solidity ^0.5.16;


contract SimpleProxy {

    address internal masterCopy;
    address internal owner;
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;


    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "BID:Zero master is not permitted");
        //masterCopy = _masterCopy;
        assembly {
            sstore(_IMPLEMENTATION_SLOT, _masterCopy)
        }
        owner=msg.sender;
    }

    

    function setMaster(address _masterCopy) external{
        require(msg.sender==owner, "not controller");
        assembly {
            sstore(_IMPLEMENTATION_SLOT, _masterCopy)
        }
        //masterCopy = _masterCopy;
    }

    function ()
        external
        payable
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let masterCopy := and(sload(_IMPLEMENTATION_SLOT), 0xffffffffffffffffffffffffffffffffffffffff)
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas, masterCopy, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) { revert(0, returndatasize()) }
            return(0, returndatasize())
        }
    }



}