// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library ECDSA {
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // If the signature is valid, return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

/**
 * Simple wallet contract, anyone can deposit Ether
 * and anyone with a valid signature can withdraw, in case
 * of an emergency
 */
contract EtherWallet {
    address public owner;
    mapping(bytes => bool) public usedSignatures;

    event Deposit(address indexed _from, uint256 indexed value);
    event Withdraw(address indexed _to, uint256 indexed value);

    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    constructor() payable {
        owner = msg.sender;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // anyone with a valid signature can call this, in case of an emergency
    function withdraw(bytes memory signature) external {
        require(!usedSignatures[signature], "Signature already used!");
        require(
            ECDSA.recover(
                keccak256("\x19Ethereum Signed Message:\n32"),
                signature
            ) == owner,
            "No permission!"
        );
        usedSignatures[signature] = true;

        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);

        emit Withdraw(msg.sender, balance);
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == owner, "No permission!");

        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}