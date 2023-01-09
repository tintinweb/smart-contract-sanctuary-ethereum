// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MultiSig {
    // EIP712 Precomputed hashes:
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
    bytes32 constant EIP712DOMAINTYPE_HASH =
        0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    // keccak256("Simple MultiSig")
    bytes32 constant NAME_HASH =
        0xb7a0bfa1b79f2443f4d73ebb9259cddbcd510b18be6fc4da7d1aa7b1786e73e6;

    // keccak256("1")
    bytes32 constant VERSION_HASH =
        0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    // keccak256("MultiSigTransaction(address destination,uint256 value,bytes data,uint256 nonce,address executor,uint256 gasLimit)")
    bytes32 constant TXTYPE_HASH =
        0x3ee892349ae4bbe61dce18f95115b5dc02daf49204cc602458cd4c1f540d56d7;

    bytes32 constant SALT =
        0x251543af6a222378665a76fe38dbceae4871a070b7fdaf5c6c30cf758dc33cc0;

    uint256 public nonce; // (only) mutable state
    uint256 public threshold; // immutable state
    mapping(address => bool) isOwner; // immutable state
    address[] public ownersArr; // immutable state

    bytes32 DOMAIN_SEPARATOR; // hash for EIP712, computed from contract address

    // Note that owners_ must be strictly increasing, in order to prevent duplicates
    constructor(
        uint256 threshold_,
        address[] memory owners_,
        uint256 chainId
    ) {
        require(
            owners_.length <= 10 &&
                threshold_ <= owners_.length &&
                threshold_ > 0
        );

        address lastAdd = address(0);
        for (uint256 i = 0; i < owners_.length; i++) {
            require(owners_[i] > lastAdd);
            isOwner[owners_[i]] = true;
            lastAdd = owners_[i];
        }
        ownersArr = owners_;
        threshold = threshold_;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712DOMAINTYPE_HASH,
                NAME_HASH,
                VERSION_HASH,
                chainId,
                this,
                SALT
            )
        );
    }

    function permitMessage(
        address destination,
        uint256 value,
        bytes memory data,
        address executor,
        uint256 gasLimit
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TXTYPE_HASH,
                    destination,
                    value,
                    keccak256(data),
                    nonce,
                    executor,
                    gasLimit
                )
            );
    }

    function getDomainSeparator() public view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

    // Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
    function execute(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address destination,
        uint256 value,
        bytes memory data,
        address executor,
        uint256 gasLimit
    ) public {
        require(
            sigR.length == threshold,
            "MultiSig: wrong number of signatures"
        );
        require(
            sigR.length == sigS.length && sigR.length == sigV.length,
            "MultiSig: number of signatures don't match"
        );
        require(
            executor == msg.sender || executor == address(0),
            "MultiSig: executor must be msg.sender or address(0)"
        );

        // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
        bytes32 txInputHash = keccak256(
            abi.encode(
                TXTYPE_HASH,
                destination,
                value,
                keccak256(data),
                nonce,
                executor,
                gasLimit
            )
        );
        bytes32 totalHash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash)
        );

        address lastAdd = address(0); // cannot have address(0) as an owner
        for (uint256 i = 0; i < threshold; i++) {
            address recovered = ecrecover(totalHash, sigV[i], sigR[i], sigS[i]);
            require(
                recovered > lastAdd && isOwner[recovered],
                "MultiSig: Bad sig"
            );
            lastAdd = recovered;
        }

        // If we make it here all signatures are accounted for.
        // The address.call() syntax is no longer recommended, see:
        // https://github.com/ethereum/solidity/issues/2884
        nonce = nonce + 1;
        bool success = false;
        assembly {
            success := call(
                gasLimit,
                destination,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
        require(success, "MultiSig: external call failed");
    }

    receive() external payable {
        revert();
    }
}