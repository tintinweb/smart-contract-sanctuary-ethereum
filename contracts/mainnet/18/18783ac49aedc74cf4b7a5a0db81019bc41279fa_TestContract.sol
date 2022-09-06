/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReverseResolver {
    function setName(string memory name) external;
}

contract TestContract {

    address private _owner;

    IReverseResolver private ReverseResolver = IReverseResolver(0x084b1c3C81545d370f3634392De611CaaBFf8148);    
    
    constructor() {
        _owner = msg.sender;
    }

    function contractOwner() public view returns (address) {
        return _owner;
    }
  
    function isOwner() private view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwner(address _to) public  {
        require(isOwner());
        _owner = _to;
    }

    function setContractName(string calldata _name ) external {
        require(isOwner());
        ReverseResolver.setName(_name);
    }

}