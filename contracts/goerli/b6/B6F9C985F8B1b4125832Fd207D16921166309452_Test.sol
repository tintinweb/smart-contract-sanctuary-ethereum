/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxy {
    function name() external view returns (string memory);

    function deal(uint value) external;

    
}


contract ProxyStorage {
    event log(string  values);
    // 最后一次添加的合约地址
    address internal rootToken;

    // 版本号-> 合约地址
    mapping(string => address) internal logicContracts;

}

contract Test is ProxyStorage {

    bytes32 internal constant IMPLEMENTATION_SLOT =keccak256("PROXY.20220415.PROXY-slot");

    function name() public view virtual  returns (string memory) {
        return IProxy(implementation()).name();
    }

    function implementation() public view returns (address _implementation) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            _implementation := sload(slot)
        }
    }

    function setImplementation(address newImplementation) public  virtual   {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImplementation)
        }
    }

    function test(uint value) public {
         emit log("in Test test");
        IProxy(implementation()).deal(value);
    }
}