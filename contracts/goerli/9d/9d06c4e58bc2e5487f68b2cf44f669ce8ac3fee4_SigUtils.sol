// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract SigUtils {
    bytes32 public DOMAIN_SEPARATOR;

    constructor(bytes32 _DOMAIN_SEPARATOR) {
        DOMAIN_SEPARATOR = _DOMAIN_SEPARATOR;
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    // Permit(address owner,address recipient)
    bytes32 public constant PERMIT_TYPEHASH =
        0x3c102999161b963e1dd60e9fc8bcd19e8dc308faf347a2600c5fe56e26f3f891;
    // 0x1d047335da90fece53750da36850b6307f2d8cb838bc5f691d92381f57016e51;
    // 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    struct Permit {
        address owner;
        address recipient;
        // uint256 nonce;
    }

    // computes the hash of a permit
    function getStructHash(Permit memory _permit)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    _permit.owner,
                    _permit.recipient
                    // _permit.nonce
                )
            );
    }

    // computes the hash of the fully encoded EIP-712 message for the domain, which can be used to recover the signer
    function getTypedDataHash(Permit memory _permit)
        public
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    getStructHash(_permit)
                )
            );
    }
}