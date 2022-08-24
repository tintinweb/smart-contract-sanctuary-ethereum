/**
 *Submitted for verification at Etherscan.io on 2022-08-24
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

contract ImplStorage {
    uint public myUint;
}

contract BadImpl1 is ImplStorage {

    function setMyUint(uint _uint) public {
        myUint = _uint;
    }
}

contract BadImpl2 is ImplStorage, ProxyStorage {

    function setMyUint(uint _uint) public {
        myUint = _uint;
    }
}

contract GoodImpl is ProxyStorage, ImplStorage {

    function setMyUint(uint _uint) public {
        myUint = _uint;
    }
}

contract NewImplStorage {
    bool public myBool;
}

contract BadNewImpl is ProxyStorage, NewImplStorage {

    function setMyBool(bool _bool) public {
        myBool = _bool;
    }
}

contract GoodNewImpl is ProxyStorage, ImplStorage, NewImplStorage {

    function setMyBool(bool _bool) public {
        myBool = _bool;
    }
}