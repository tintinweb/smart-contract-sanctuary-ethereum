/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

// mainnet
address constant XEN_ADDRESS = 0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8;

contract Batcher {
	// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
    address private immutable original;
	address private immutable deployer;
    bytes32 private immutable miniProxyByteCode;
	
	constructor() {
        original = address(this);
		deployer = msg.sender;

        bytes memory miniProxy = bytes.concat(
            bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
            bytes20(address(this)),
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
        miniProxyByteCode = keccak256(abi.encodePacked(miniProxy));
	}

	function callback(address target, bytes memory data) external {
		require(msg.sender == original, "Only original can call this function");

        (bool success, bytes memory result) = target.call(data);
        // see https://yos.io/2022/07/16/bubbling-up-errors-in-solidity/
        if (!success) { // If call reverts
            // If there is return data, the call reverted without a reason or a custom error.
            if (result.length == 0) revert();
            assembly {
                // We use Yul's revert() to bubble up errors from the target contract.
                revert(add(32, result), mload(result))
            }
        }
	}

    // from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/Clones.sol
    function proxyFor(bytes32 salt) internal view returns (address proxy) {
        proxy = address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                miniProxyByteCode
            )))));
    }

    function proxyFor(uint32 i) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, i));
        proxy = proxyFor(salt);
    }

	function execute(bool autoCreateProxy, uint32 id, address target, bytes memory data) private {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, id));
		address proxy = proxyFor(salt);

        uint32 codeSize;
        assembly {
            codeSize := extcodesize(proxy)
        }

        if (codeSize == 0) {
            require(autoCreateProxy, 'Invalid proxy');

            bytes memory miniProxy = bytes.concat(
                bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
                bytes20(address(this)),
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            );
            assembly {
                proxy := create2(0, add(miniProxy, 32), mload(miniProxy), salt)
            }
            require(proxy != address(0), "Create2 failed");
        }

		Batcher(proxy).callback(target, data);
	}

    function execute(bool autoCreateProxy, uint32 idStart, uint32 idCount, address target, bytes memory data) public {
		require(msg.sender == deployer, "Only deployer allowed to call");
        for(uint32 i = idStart; i < idStart + idCount; ++i) {
	        execute(autoCreateProxy, i, target, data);
		}
	} 
}

contract XenBatcher is Batcher{
	function claimRank(bool range, uint32 id1, uint32 id2, uint32[] calldata ids, uint16 term1, uint16 term2) external {        
		uint256 term = term1;
        uint32 id = id1;
        uint256 index = 0;
        while (!range && index < ids.length || range && id <= id2) {
            if (!range) {
                id = ids[index];
            }

            execute(
                true,
                id,
                1,
                XEN_ADDRESS,
                abi.encodeWithSignature("claimRank(uint256)", term)
                );

			term = (term == term2) ? term1 : term + 1;

            if (range) {
                ++id;
            } else {
                ++index;
            }
        }
    }

    function claimMintRewardAndShare(uint32[] calldata ids, address other) external {
		for (uint256 index = 0; index < ids.length; ++index) {
            execute(
                false,
                ids[index],
                1,
                XEN_ADDRESS,
                abi.encodeWithSignature("claimMintRewardAndShare(address,uint256)", other, 100)
                );
        }
    }
}