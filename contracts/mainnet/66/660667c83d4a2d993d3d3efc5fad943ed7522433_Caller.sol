/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.21;

contract Proxy {

    // The delegate address will be overwritten with the
    // value that was supposed to be stored in n
    address public delegate;
    uint public n = 1;

    function Proxy(address _delegateAdr) public {
        delegate = _delegateAdr;
    }

    function() external payable {

        assembly {
            let _target := sload(0)
            calldatacopy(0x0, 0x0, calldatasize)
            let result := delegatecall(gas, _target, 0x0, calldatasize, 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize)
            switch result case 0 {revert(0, 0)} default {return (0, returndatasize)}
        }
    }
}

contract Delegate {

    // Storage is not in the same order as in the Proxy contract
    uint public n = 1;

    function adds() public {
        n = 5;
    }
}

contract Caller {

    Delegate proxy;

    function Caller(address _proxyAdr) public {
        proxy = Delegate(_proxyAdr);
    }

    function go() public {
       proxy.adds();
    }
}