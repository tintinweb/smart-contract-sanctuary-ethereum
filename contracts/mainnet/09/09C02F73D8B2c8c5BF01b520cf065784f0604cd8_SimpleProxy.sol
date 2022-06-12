pragma solidity ^0.5.16;

//EIP-1967 compatible
contract SimpleProxy {

    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "BID:Zero master is not permitted");
        address admin;
        admin = msg.sender;
        assembly {
            sstore(_IMPLEMENTATION_SLOT, _masterCopy)
            sstore(_ADMIN_SLOT, admin)
        }

    }

    

    function setMaster(address _masterCopy) external{
        address owner;
        assembly {
            owner := sload(_ADMIN_SLOT)
        }
        require(msg.sender==owner, "not controller");
        assembly {
            sstore(_IMPLEMENTATION_SLOT, _masterCopy)
        }
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