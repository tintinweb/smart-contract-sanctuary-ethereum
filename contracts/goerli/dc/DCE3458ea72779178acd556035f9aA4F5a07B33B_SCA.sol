//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Smart Contract Account, a contract deployed for a single user and that allows
// them to invoke meta-transactions.
contract SCA {
    uint256 s_nonce;
    address public immutable s_owner;

    // Hardcode the owner of this contract upon deployment.
    constructor(address owner) {
        s_owner = owner;
    }

    // Execute a transaction on behalf of the owner. Ensure that they have
    // correctly signed the transaction they desire, and execute as the
    // smart contract account.
    // This function can also be used to withdraw funds from the contract itself,
    // whether they be gas tokens or ERC-20s.
    function executeTransaction(
        address to,
        bytes calldata data,
        uint256 value,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external {
        bytes32 sig = keccak256(
            abi.encodePacked(to, data, value, s_owner, s_nonce, block.chainid)
        );
        require(ecrecover(sig, v + 27, r, s) == s_owner, "Invalid signature.");
        /* (bool success, bytes memory returnData) = */ to.call{value: value} (
            abi.encodePacked(data)
        );
        s_nonce++;
    }
}