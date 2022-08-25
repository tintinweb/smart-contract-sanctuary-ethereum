/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract ProxyStorage {
    address public implementation;
}

contract SimpleProxy is ProxyStorage {

    constructor(address implementation_) {
        implementation = implementation_;
    }

    function setNewImplementation(address implementation_) public {
        implementation = implementation_;
    }

    fallback() external {
        address _impl = implementation;

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}

contract GoodImpl is ProxyStorage {
    uint public myUint1;

    function setMy1Uint(uint _uint) public {
        myUint1 = _uint;
    }
}

contract BadUpgradeImpl is ProxyStorage {
    uint public myUint2;

    function setMy2Uint(uint _uint) public {
        myUint2 = _uint;
    }
}

contract GoodUpgradeImpl is ProxyStorage {
    uint public myUint1;
    uint public myUint2;

    function setMyUint(uint _uint) public {
        myUint1 = _uint;
    }

    function setMy2Uint(uint _uint) public {
        myUint2 = _uint;
    }
}