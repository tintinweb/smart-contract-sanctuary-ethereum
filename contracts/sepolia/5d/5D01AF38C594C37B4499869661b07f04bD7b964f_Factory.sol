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

    function create(uint256[] calldata salts) external {
        require(msg.sender == owner);
        bytes20 targetBytes = bytes20(address(receiversMap[0]));
        address[] memory addresses = new address[](salts.length);
        uint256[] memory saltLookup = salts;
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            for {let i := 0} lt(i, salts.length) {i := add(i, 1)} {
                let salt := mload(add(saltLookup, mul(i, 0x20)))
                let cloneAddress := create2(0, clone, 0x37, salt)
                mstore(add(addresses, mul(i, 20)), cloneAddress)
            }
        }
        for (uint256 i = 0; i < salts.length; i++) {
            receiversMap[salts[i]] = Receiver(addresses[i]);
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