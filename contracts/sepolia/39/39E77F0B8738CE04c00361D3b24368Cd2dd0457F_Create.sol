// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Error that occurs when the contract creation failed.
 * @param emitter The contract that emits the error.
 */
error Failed(address emitter);

/**
 * @dev Error that occurs when the factory contract has insufficient balance.
 * @param emitter The contract that emits the error.
 */
error InsufficientBalance(address emitter);

/**
 * @dev Error that occurs when the bytecode length is zero.
 * @param emitter The contract that emits the error.
 */
error ZeroBytecodeLength(address emitter);

/**
 * @dev Error that occurs when the nonce value is invalid.
 * @param emitter The contract that emits the error.
 */
error InvalidNonceValue(address emitter);

/**
 * @title CREATE Deployer Smart Contract
 * @author Pascal Marco Caversaccio, [email protected]
 * @notice Helper smart contract to make easier and safer usage of the `CREATE` EVM opcode.
 * @dev Adjusted from here: https://github.com/safe-global/safe-contracts/blob/main/contracts/libraries/CreateCall.sol.
 */

contract Create {
    /**
     * @dev Event that is emitted when a contract is successfully created.
     * @param newContract The address of the new contract.
     */
    event ContractCreation(address newContract);

    /**
     * @dev The function `deploy` deploys a new contract via calling
     * the `CREATE` opcode and using the creation bytecode as input.
     * @param amount The value in wei to send to the new account. If `amount` is non-zero,
     * `bytecode` must have a `payable` constructor.
     * @param bytecode The creation bytecode.
     */
    function deploy(
        uint256 amount,
        bytes memory bytecode
    ) public returns (address newContract) {
        if (address(this).balance < amount)
            revert InsufficientBalance(address(this));
        if (bytecode.length == 0) revert ZeroBytecodeLength(address(this));
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            /** @dev `CREATE` opcode
             *
             * Stack input
             * ------------
             * value: value in wei to send to the new account.
             * offset: byte offset in the memory in bytes, the instructions of the new account.
             * size: byte size to copy (size of the instructions).
             *
             * Stack output
             * ------------
             * address: the address of the deployed contract.
             *
             * How are bytes stored in Solidity:
             * In memory the `bytes` is stored by having first the length of the `bytes` and then the data,
             * this results in the following schema: `<32-bytes length><data>` at the location where bytecode points to.
             *
             * Now if we want to use the data with `CREATE`, we first point to the start of the raw data, which is after the length.
             * Therefore, we add 32 (the space required for the length) to the location stored in the bytecode variable.
             * This is the first parameter. For the second parameter, we read the length from memory using `mload`.
             * As the length is the first 32 bytes at the location of `bytecode`, we can read the length by calling `mload(bytecode)`.
             */
            newContract := create(amount, add(bytecode, 0x20), mload(bytecode))
        }
        if (newContract == address(0)) revert Failed(address(this));
        emit ContractCreation(newContract);
        return newContract;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via `deploy`.
     * For the specification of the Recursive Length Prefix (RLP) encoding scheme, please
     * refer to p. 19 of the Ethereum Yellow Paper (https://ethereum.github.io/yellowpaper/paper.pdf)
     * and the Ethereum Wiki (https://eth.wiki/fundamentals/rlp). For further insights also, see the
     * following issue: https://github.com/Rari-Capital/solmate/issues/207.
     *
     * Based on the EIP-161 (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-161.md) specification,
     * all contract accounts on the Ethereum mainnet are initiated with `nonce = 1`.
     * Thus, the first contract address created by another contract is calculated with a non-zero nonce.
     */
    // prettier-ignore
    function computeAddress(address addr, uint256 nonce) public view returns (address) {
        bytes memory data;
        bytes1 len = bytes1(0x94);

        /** 
         * @dev The theoretical allowed limit, based on EIP-2681, for an account nonce is 2**64-2:
         * https://eips.ethereum.org/EIPS/eip-2681.
         */
        if (nonce > type(uint64).max - 1) revert InvalidNonceValue(address(this));

        /** 
         * @dev The integer zero is treated as an empty byte string and therefore has only one
         * length prefix, 0x80, which is calculated via 0x80 + 0.
         */
        if (nonce == 0x00) data = abi.encodePacked(bytes1(0xd6), len, addr, bytes1(0x80));

        /** 
         * @dev A one-byte integer in the [0x00, 0x7f] range uses its own value as a length prefix,
         * there is no additional "0x80 + length" prefix that precedes it.
         */
        else if (nonce <= 0x7f) data = abi.encodePacked(bytes1(0xd6), len, addr, uint8(nonce));

        /**
         * @dev In the case of `nonce > 0x7f` and `nonce <= type(uint8).max`, we have the following
         * encoding scheme (the same calculation can be carried over for higher nonce bytes):
         * 0xda = 0xc0 (short RLP prefix) + 0x1a (= the bytes length of: 0x94 + address + 0x84 + nonce, in hex),
         * 0x94 = 0x80 + 0x14 (= the bytes length of an address, 20 bytes, in hex),
         * 0x84 = 0x80 + 0x04 (= the bytes length of the nonce, 4 bytes, in hex).
         */
        else if (nonce <= type(uint8).max) data = abi.encodePacked(bytes1(0xd7), len, addr, bytes1(0x81), uint8(nonce));
        else if (nonce <= type(uint16).max) data = abi.encodePacked(bytes1(0xd8), len, addr, bytes1(0x82), uint16(nonce));
        else if (nonce <= type(uint24).max) data = abi.encodePacked(bytes1(0xd9), len, addr, bytes1(0x83), uint24(nonce));
        else if (nonce <= type(uint32).max) data = abi.encodePacked(bytes1(0xda), len, addr, bytes1(0x84), uint32(nonce));
        else if (nonce <= type(uint40).max) data = abi.encodePacked(bytes1(0xdb), len, addr, bytes1(0x85), uint40(nonce));
        else if (nonce <= type(uint48).max) data = abi.encodePacked(bytes1(0xdc), len, addr, bytes1(0x86), uint48(nonce));
        else if (nonce <= type(uint56).max) data = abi.encodePacked(bytes1(0xdd), len, addr, bytes1(0x87), uint56(nonce));
        else data = abi.encodePacked(bytes1(0xde), len, addr, bytes1(0x88), uint64(nonce));

        return address(uint160(uint256(keccak256(data))));
    }

    /**
     * @dev Receive function to enable deployments of `bytecode` with a `payable` constructor.
     */
    receive() external payable {}
}