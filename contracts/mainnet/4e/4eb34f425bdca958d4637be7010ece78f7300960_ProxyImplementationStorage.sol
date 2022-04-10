/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

pragma solidity ^0.8.9;

interface IProxyImplementationStorage {
    function implementation() external returns(address);
}

contract ProxyImplementationStorage {
    constructor(address _implementation, address[] memory _alloweds) public {
        implementation = _implementation;

        for (uint256 i = 0; i < _alloweds.length; i++) {
            allowed[_alloweds[i]] = true;
        }

        allowed[msg.sender] = true;
    }

    address public implementation;

    mapping (address => bool) allowed;

    function setAllowed(address _addr, bool _allowed) public {
        require(allowed[msg.sender], '!allowed');
        allowed[_addr] = _allowed;
    }

    function upgradeImplementation(address newImplementation) public {
        require(allowed[msg.sender], '!allowed');
        implementation = newImplementation;
    }
}