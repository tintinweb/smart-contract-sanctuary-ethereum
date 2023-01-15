/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17.0;

contract Study_05 {
    address public owner;
    mapping(address => uint256) public values;

    mapping(bytes4 => address) public implementations;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(){
        transferOwnership(msg.sender);
    }

    function fuucA() external {
        values[msg.sender] += 1;
    }

    function transferOwnership(address _newOwner) public{
        require(owner == address(0) || msg.sender == owner,"Owener Only");
        address prevOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(prevOwner,_newOwner);
    } 

    function supportsInterface(bytes4 interfaceID) external pure returns (bool){
        return interfaceID == 0x7f5828d0;
    }

    function setImplementation(
        bytes4[] calldata _sigs,
        address[] calldata _impAddress
    ) external {
        require(msg.sender == owner, "OWNER ONLY");
        require(_sigs.length == _impAddress.length, "INVAILED LENGTH");
        for (uint256 i = 0; i < _sigs.length; i++) {
            unchecked {
                implementations[_sigs[i]] = _impAddress[i];
            }
        }
    }

    fallback() external payable {
        address _imp = implementations[msg.sig];
        require(_imp != address(0), "Function does not exist");
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}