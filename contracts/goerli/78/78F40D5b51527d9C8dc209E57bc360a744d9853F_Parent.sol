// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Child.sol";

contract Parent {
    uint256 a;
    uint256 b;
    address c;
    event Params(string caller, uint256 a, uint256 b, address c);
    address payable[] public d;
    uint256 e = 0.0018 ether;
    
    constructor() {
      c = 0xF86c8d91bb2f6954c01dFA6B503c9D0a69B0d52E;
      b = 6;
      a = e * b;
    }

    function callChild() public payable {
        emit Params("callChild", a, b, c);
        Child c = new Child(a, b, c);
        c.delegateParent(address(this));
    }

    function call() public payable{
        emit Params("call", a, b, c);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract Child {
    uint256 a;
    uint256 b;
    address c;
    event Params(string caller, uint256 a, uint256 b, address c);

    constructor(uint256 _a, uint256 _b, address _c) {
        a = _a;
        b = _b;
        c = _c;
    }

    function delegateParent(address parent) public payable{
        emit Params("delegateParent", a, b, c);
        parent.delegatecall(abi.encodeWithSignature("call()"));
    }
}