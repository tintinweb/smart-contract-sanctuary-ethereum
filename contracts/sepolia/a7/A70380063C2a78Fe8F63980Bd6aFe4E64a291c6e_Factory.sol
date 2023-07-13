/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

interface IERC20 {
    function transfer(address to, uint256 amount) external;
}

contract Receiver {
    function send( address token, address recipient, uint256 amount ) public {
        require(msg.sender == address(0x00deadbeefdeadbeefdeadbeefdeadbeefdeadbeef));
        IERC20(token).transfer(recipient, amount);
    }
}

contract Factory {
    address public owner;
    mapping ( uint256 => Receiver ) public receiversMap;
    bytes public initClone;
    
    constructor() {
        owner = msg.sender;
        receiversMap[0] = initReceiver();
    }

    function initReceiverPrevious() private returns (Receiver receiver) {
        bytes memory deploymentData = type(Receiver).creationCode;
        bytes20 target = bytes20(address(0x00deadbeefdeadbeefdeadbeefdeadbeefdeadbeef));
        bytes20 replacement = bytes20(uint160(address(this)));
        uint256 deploymentDataLength = deploymentData.length;
        uint256 targetLength = target.length;
        for (uint256 i = 0; i < deploymentDataLength; i++) {
            bytes20 chunk;
            assembly {
                chunk := mload(add(deploymentData, add(0x20, i)))
            }
            if (i + targetLength <= deploymentDataLength && chunk == target) {
                for (uint256 j = 0; j < targetLength; j++) {
                    deploymentData[i + j] = replacement[j];
                }
                break;
            }
        }
        assembly {
            receiver := create(0, add(deploymentData, 0x20), mload(deploymentData))
        }
    }

    function initReceiver() private returns (Receiver receiver) {
        bytes memory deploymentData = type(Receiver).creationCode;
        uint256 deploymentDataLength = deploymentData.length;
        assembly {
            let target := 0xdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef
            let replacement := and(address(), 0xffffffffffffffffffffffffffffffffffffffff)
            for { let i := 0 } lt(i, deploymentDataLength) { i := add(i, 1) } {
                let chunk := and(mload(add(deploymentData, i)), 0xffffffffffffffffffffffffffffffffffffffff)
                if eq(chunk, target) {
                    let offset := add(deploymentData, i)
                    mstore(offset, replacement)
                    i := deploymentDataLength
                }
            }
            receiver := create(0, add(deploymentData, 0x20), deploymentDataLength)
        }
    }

    function create( uint256[] calldata salts ) external {
        require(msg.sender == owner);
        bytes20 targetBytes = bytes20(address(receiversMap[0]));
        bytes memory clone;
        assembly {
            clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
        }
        for(uint256 i = 0; i < salts.length; i++) {
            bytes32 salt = bytes32(salts[i]);
            address cloneAddress;
            assembly {
                cloneAddress := create2(0, clone, 0x37, salt)
            }
            receiversMap[salts[i]] = Receiver(cloneAddress);
        }
    }

    function collect( address token, address recipient, uint256[] calldata receivers, uint[] calldata amounts ) public {
        require(msg.sender == owner);
        for(uint256 i = 0; i < receivers.length; i++) {
            receiversMap[receivers[i]].send( token, recipient, amounts[i] );
        }
    }

    function collect( address token, address[] calldata recipients, uint256[] calldata receivers, uint[] calldata amounts ) public {
        require(msg.sender == owner);
        for(uint256 i = 0; i < recipients.length; i++) {
            receiversMap[receivers[i]].send( token, recipients[i], amounts[i] );
        }
    }
}