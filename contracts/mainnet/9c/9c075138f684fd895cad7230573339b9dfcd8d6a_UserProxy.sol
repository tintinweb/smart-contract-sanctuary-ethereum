/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract UserProxy {
    address public owner;
    address public target;

    error onlyOwnerAllowed(address);

    constructor(address _target, address _owner) {
        owner = _owner;
        target = _target;
    }

    modifier onlyOwner {
        if(msg.sender != owner) revert onlyOwnerAllowed(owner);
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setTarget(address newTarget) external onlyOwner {
        target = newTarget;
    }

    function write(bytes[] memory data) external onlyOwner returns (bytes[] memory results){
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = target.delegatecall(data[i]);
            if (!success) {
                // tx revert silently
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            results[i] = result;
        }
    }

    fallback() external {
        (bool success, ) = target.delegatecall(msg.data);

        assembly {
             let mem := mload(0x40)
             returndatacopy(mem, 0, returndatasize())

             switch success
             case 0 { revert(mem, returndatasize()) }
             default { return(mem, returndatasize()) }
        }
    }
}