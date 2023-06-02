/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract BatcherV2 {
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
    address private immutable original;
    bytes32 byteCode;
    uint n;
    address private immutable deployer;

    constructor(uint _n) {
        original = address(this);
        deployer = msg.sender;
        createProxies(_n);
    }

    function createProxies(uint _n) internal {
        // https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract
        // https://eips.ethereum.org/EIPS/eip-1167
        bytes memory miniProxy = bytes.concat(
            bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
            bytes20(address(this)),
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
        byteCode = keccak256(abi.encodePacked(miniProxy));
        address proxy;
        uint oldN = n;
        for (uint i = 0; i < _n; i++) {
            bytes32 salt = keccak256(abi.encodePacked(msg.sender, i + oldN));
            assembly {
                proxy := create2(0, add(miniProxy, 32), mload(miniProxy), salt)
            }
        }
        // update n
        n = oldN + _n;
    }

    function callback(address target, bytes memory data) external payable {
        require(
            msg.sender == original,
            "Only original can call this function."
        );
        (bool success, ) = target.call{value: msg.value}(data);
        require(success, "Transaction failed.");
    }

    function proxyFor(
        address sender,
        uint i
    ) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        proxy = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(hex"ff", address(this), salt, byteCode)
                    )
                )
            )
        );
    }

    // increase proxy count
    function increase(uint _n) external {
        require(
            msg.sender == deployer,
            "Only deployer can call this function."
        );
        createProxies(_n);
    }

    function execute(
        uint _start,
        uint _count,
        address target,
        bytes memory data
    ) external payable {
        require(
            msg.sender == deployer,
            "Only deployer can call this function."
        );
        for (uint i = _start; i < _start + _count; i++) {
            address proxy = proxyFor(msg.sender, i);
            BatcherV2(proxy).callback{value: msg.value}(target, data);
        }
    }
}