// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IQ00ts {
    function transferFrom(address, address, uint256) external;
}

error InvalidAddress();

contract Positioner {
    address constant Q00TANT_CONTRACT_ADDRESS = 0x9F7C5D43063e3ECEb6aE43A22b669BB01fD1039A;
    address constant Q00NICORN_CONTRACT_ADDRESS = 0xc8Dc0f7B8Ca4c502756421C23425212CaA6f0f8A;

    function position(address q00t, uint256 tokenId, address destination) external {
        if (q00t != Q00NICORN_CONTRACT_ADDRESS && q00t != Q00TANT_CONTRACT_ADDRESS) revert InvalidAddress();
        IQ00ts(q00t).transferFrom(msg.sender, destination, tokenId);
    }
}