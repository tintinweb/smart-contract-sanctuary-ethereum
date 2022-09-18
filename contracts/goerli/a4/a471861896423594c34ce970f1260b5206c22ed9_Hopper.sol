// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.15;

import {CREATE3} from "solmate/utils/CREATE3.sol";

import {AltBn128} from "./AltBn128.sol";
import {LSAG}  from "./LSAG.sol";

contract Hopper {

    event Deposited(address Depositor);
    event Withdrawal(address Receiver);
    event Hop(address NewLocation);

    bytes32 immutable depHash;

    uint8 dParticipantsNo;
    bytes32 public ringHash;
    mapping(uint8 => uint256[2]) public publicKeys;
    mapping(uint8 => uint256[2]) public keyImages;


    function _hop(
        uint256 value,
        bytes calldata deplCode
    ) internal returns (
        address newLocation
    ) {
        require(depHash == keccak256(abi.encodePacked(deplCode)), "INVALID CREATION CODE");

        newLocation = CREATE3.deploy(
            keccak256(abi.encodePacked(msg.sender, block.difficulty)), 
            abi.encodePacked(deplCode, abi.encode(0, depHash)), 
            value
        );

        emit Hop(newLocation);
    }

    // create the overloaded for 5
    function _deposit(uint256[2] memory publicKey) internal {

        if (!AltBn128.onCurve(uint256(publicKey[0]), uint256(publicKey[1]))) {
            revert("Public Key not on Curve");
        }

        unchecked{
            for (uint8 i = 0; i < dParticipantsNo; i++) {
                if (publicKeys[i][0] == publicKey[0] &&
                    publicKeys[i][1] == publicKey[1]) {
                    revert("Address already in current Ring");
                }
            }
        }

        publicKeys[dParticipantsNo] = publicKey;
        dParticipantsNo++;

        // Broadcast Event
        emit Deposited(msg.sender);

    }

    function _processWithdraw(
        address payable _recipient
    ) internal {
        // sanity checks
        require(msg.value == 0, "Message value is supposed to be zero for ETH instance");
        require(_recipient != address(0), "Cannot send to the burn address");

        (bool success, ) = _recipient.call{ value: 1 ether }("");
        require(success, "payment to _recipient did not go thru");
    }

    function deposit(uint256[2] memory publicKey) public payable {
        require(dParticipantsNo < 6, "RING FULL");
        require(dParticipantsNo != 5, "EXPECTED HOP ARGUMENTS");
        require(msg.value == 1 ether, "EXPECTED 1ETH");

        _deposit(publicKey);

    }

    function deposit(uint256[2] memory publicKey, bytes calldata deplCode) public payable returns (address newLocation) {
        require(dParticipantsNo == 5, "HOP ARGUMENTS NOT EXPECTED");
        require(msg.value == 1 ether, "EXPECTED 1ETH");

        _deposit(publicKey);
        ringHash = _createRingHash();
        newLocation = _hop(0, deplCode);

    }

    // Creates ring hash (used for signing)
    function _createRingHash() internal view
        returns (bytes32)
    {
        uint256[2][6] memory _publicKeys;

        

        bytes memory b = abi.encodePacked(
            address(this),
            _publicKeys
        );

        return keccak256(b);
    }

    function getPubKeys() public view returns (uint256[2][] memory) {
        // todo; the order of fixed/dynamic sizes feels weird here
        uint256[2][] memory _publicKeys = new uint256[2][](dParticipantsNo);
        
        unchecked{
            for (uint256 i = 0; i < dParticipantsNo; i++) {
                _publicKeys[i] = [
                    uint256(publicKeys[uint8(i)][0]),
                    uint256(publicKeys[uint8(i)][1])
                ];
            }
        }

        return _publicKeys;
    }

    function withdraw(
        address payable receiver, 
        uint256 c0, 
        uint256[2] memory keyImage, 
        uint256[] memory s
    ) public {
        require(dParticipantsNo == 6, "RING NOT COMPLETE");
        require(address(this).balance >= 1 ether, "WITHDRAWALS COMPLETED");

        // Convert public key to dynamic array
        // Based on number of people who have
        // deposited
        uint256[2][] memory _publicKeys = getPubKeys();

        // Attempts to verify ring signature
        bool signatureVerified = LSAG.verify(
            abi.encodePacked(address(this), receiver), // Convert to bytes
            c0,
            keyImage,
            s,
            _publicKeys
        );

        /*
        if (!signatureVerified) {
            revert("Invalid signature");
        }
        */

        // Checks if Key Image has been used
        // AKA No double withdraw
        uint8 withdrawalCount = uint8(6 - address(this).balance/10**18);

        unchecked{
            for (uint i = 0; i < withdrawalCount; i++) {
                if (keyImages[uint8(i)][0] == keyImage[0] &&
                    keyImages[uint8(i)][1] == keyImage[1]) {
                    revert("Signature has been used!");
                }
            }
        }

        keyImages[withdrawalCount] = keyImage;

        _processWithdraw(receiver);

        emit Withdrawal(receiver);
    }

    constructor(
        uint8 _dParticipantsNo,
        bytes32 _depHash
    ) payable {
        dParticipantsNo = _dParticipantsNo;
        depHash         = _depHash;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {Bytes32AddressLib} from "./Bytes32AddressLib.sol";

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/CREATE3.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/create3/blob/master/contracts/Create3.sol)
library CREATE3 {
    using Bytes32AddressLib for bytes32;

    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 0 size               //
    // 0x37       |  0x37                 | CALLDATACOPY     |                        //
    // 0x36       |  0x36                 | CALLDATASIZE     | size                   //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 size                 //
    // 0x34       |  0x34                 | CALLVALUE        | value 0 size           //
    // 0xf0       |  0xf0                 | CREATE           | newContract            //
    //--------------------------------------------------------------------------------//
    // Opcode     | Opcode + Arguments    | Description      | Stack View             //
    //--------------------------------------------------------------------------------//
    // 0x67       |  0x67XXXXXXXXXXXXXXXX | PUSH8 bytecode   | bytecode               //
    // 0x3d       |  0x3d                 | RETURNDATASIZE   | 0 bytecode             //
    // 0x52       |  0x52                 | MSTORE           |                        //
    // 0x60       |  0x6008               | PUSH1 08         | 8                      //
    // 0x60       |  0x6018               | PUSH1 18         | 24 8                   //
    // 0xf3       |  0xf3                 | RETURN           |                        //
    //--------------------------------------------------------------------------------//
    bytes internal constant PROXY_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

    bytes32 internal constant PROXY_BYTECODE_HASH = keccak256(PROXY_BYTECODE);

    function deploy(
        bytes32 salt,
        bytes memory creationCode,
        uint256 value
    ) internal returns (address deployed) {
        bytes memory proxyChildBytecode = PROXY_BYTECODE;

        address proxy;
        assembly {
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            // We start 32 bytes into the code to avoid copying the byte length.
            proxy := create2(0, add(proxyChildBytecode, 32), mload(proxyChildBytecode), salt)
        }
        require(proxy != address(0), "DEPLOYMENT_FAILED");

        deployed = getDeployed(salt);
        (bool success, ) = proxy.call{value: value}(creationCode);
        require(success && deployed.code.length != 0, "INITIALIZATION_FAILED");
    }

    function getDeployed(bytes32 salt) internal view returns (address) {
        address proxy = keccak256(
            abi.encodePacked(
                // Prefix:
                bytes1(0xFF),
                // Creator:
                address(this),
                // Salt:
                salt,
                // Bytecode hash:
                PROXY_BYTECODE_HASH
            )
        ).fromLast20Bytes();

        return
            keccak256(
                abi.encodePacked(
                    // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01)
                    // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex)
                    hex"d6_94",
                    proxy,
                    hex"01" // Nonce of the proxy contract (1)
                )
            ).fromLast20Bytes();
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

/** 
 * Heavily referenced from https://github.com/ethereum/py_ecc/blob/master/py_ecc/bn128/bn128_curve.py
*/

library AltBn128 {
    uint256 constant public G1x = uint256(0x01);
    uint256 constant public G1y = uint256(0x02);

    // Number of elements in the field (often called `q`)
    // n = n(u) = 36u^4 + 36u^3 + 18u^2 + 6u + 1
    uint256 constant public N = 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

    // p = p(u) = 36u^4 + 36u^3 + 24u^2 + 6u + 1
    // Field Order
    uint256 constant public P = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

    // (p+1) / 4
    uint256 constant public A = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52;

    /* ECC Functions */
    function ecAdd(uint256[2] memory p0, uint256[2] memory p1) internal view
        returns (uint256[2] memory retP)
    {
        uint256[4] memory i = [p0[0], p0[1], p1[0], p1[1]];
        
        assembly {
            // call ecadd precompile
            // inputs are: x1, y1, x2, y2
            if iszero(staticcall(not(0), 0x06, i, 0x80, retP, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function ecMul(uint256[2] memory p, uint256 s) internal view
        returns (uint256[2] memory retP)
    {
        // With a public key (x, y), this computes p = scalar * (x, y).
        uint256[3] memory i = [p[0], p[1], s];
        
        assembly {
            // call ecmul precompile
            // inputs are: x, y, scalar
            if iszero(staticcall(not(0), 0x07, i, 0x60, retP, 0x40)) {
                revert(0, 0)
            }
        }
    }

    function ecMulG(uint256 s) internal view
        returns (uint256[2] memory retP)
    {
        return ecMul([G1x, G1y], s);
    }

    function powmod(uint256 base, uint256 e, uint256 m) internal view
        returns (uint256 o)
    {
        // returns pow(base, e) % m
        assembly {
            // define pointer
            let p := mload(0x40)

            // Store data assembly-favouring ways
            mstore(p, 0x20)             // Length of Base
            mstore(add(p, 0x20), 0x20)  // Length of Exponent
            mstore(add(p, 0x40), 0x20)  // Length of Modulus
            mstore(add(p, 0x60), base)  // Base
            mstore(add(p, 0x80), e)     // Exponent
            mstore(add(p, 0xa0), m)     // Modulus

            // call modexp precompile! -- old school gas handling
            let success := staticcall(sub(gas(), 2000), 0x05, p, 0xc0, p, 0x20)

            // gas fiddling
            switch success case 0 {
                revert(0, 0)
            }

            // data
            o := mload(p)
        }
    }

    // Keep everything contained within this lib
    function addmodn(uint256 x, uint256 n) internal pure
        returns (uint256)
    {
        return addmod(x, n, N);
    }

    function modn(uint256 x) internal pure
        returns (uint256)
    {
        return x % N;
    }

    /*
       Checks if the points x, y exists on alt_bn_128 curve
    */
    function onCurve(uint256 x, uint256 y) internal pure
        returns(bool)
    {
        uint256 beta = mulmod(x, x, P);
        beta = mulmod(beta, x, P);
        beta = addmod(beta, 3, P);

        return onCurveBeta(beta, y);
    }

    function onCurveBeta(uint256 beta, uint256 y) internal pure
        returns(bool)
    {
        return beta == mulmod(y, y, P);
    }

    /*
    * Calculates point y value given x
    */
    function evalCurve(uint256 x) internal view
        returns (uint256, uint256)
    {
        uint256 beta = mulmod(x, x, P);
        beta = mulmod(beta, x, P);
        beta = addmod(beta, 3, P);

        uint256 y = powmod(beta, A, P);

        // require(beta == mulmod(y, y, P), "Invalid x for evalCurve");
        return (beta, y);
    }
}

// SPDX-License-Identifier: The Unlicense
pragma solidity ^0.8.0;

import "./AltBn128.sol";

/*
Linkable Spontaneous Anonymous Groups

https://eprint.iacr.org/2004/027.pdf
*/

library LSAG {
    // abi.encodePacked is the "concat" or "serialization"
    // of all supplied arguments into one long bytes value
    // i.e. abi.encodePacked :: [a] -> bytes

    /**
    * Converts an integer to an elliptic curve point
    */
    function intToPoint(uint256 _x) public view
        returns (uint256[2] memory)
    {
        uint256 x = _x;
        uint256 y;
        uint256 beta;

        unchecked{
            while (true) {
                (beta, y) = AltBn128.evalCurve(x);

                if (AltBn128.onCurveBeta(beta, y)) {
                    return [x, y];
                }

                x = AltBn128.addmodn(x, 1);
            }
        }
    }

    /**
    * Returns an integer representation of the hash
    * of the input
    */
    function H1(bytes memory b) public pure
        returns (uint256)
    {
        return AltBn128.modn(uint256(keccak256(b)));
    }

    /**
    * Returns elliptic curve point of the integer representation
    * of the hash of the input
    */
    function H2(bytes memory b) public view
        returns (uint256[2] memory)
    {
        return intToPoint(H1(b));
    }

    /**
    * Helper function to calculate Z1
    * Avoids stack too deep problem
    */
    function ringCalcZ1(
        uint256[2] memory pubKey,
        uint256 c,
        uint256 s
    ) public view
        returns (uint256[2] memory)
    {
        return AltBn128.ecAdd(
            AltBn128.ecMulG(s),
            AltBn128.ecMul(pubKey, c)
        );
    }

    /**
    * Helper function to calculate Z2
    * Avoids stack too deep problem
    */
    function ringCalcZ2(
        uint256[2] memory keyImage,
        uint256[2] memory h,
        uint256 s,
        uint256 c
    ) public view
        returns (uint256[2] memory)
    {
        return AltBn128.ecAdd(
            AltBn128.ecMul(h, s),
            AltBn128.ecMul(keyImage, c)
        );
    }


    /**
    * Verifies the ring signature
    * Section 4.2 of the paper https://eprint.iacr.org/2004/027.pdf
    */
    function verify(
        bytes memory message,
        uint256 c0,
        uint256[2] memory keyImage,
        uint256[] memory s,
        uint256[2][] memory publicKeys
    ) public view
        returns (bool)
    {
        require(publicKeys.length >= 2, "Signature size too small");
        require(publicKeys.length == s.length, "Signature sizes do not match!");

        uint256 c = c0;
        uint256 i = 0;

        // Step 1
        // Extract out public key bytes
        bytes memory hBytes = "";

        unchecked{
            for (i = 0; i < publicKeys.length; i++) {
                hBytes = abi.encodePacked(
                    hBytes,
                    publicKeys[i]
                );
            }
        }

        uint256[2] memory h = H2(hBytes);

        // Step 2
        uint256[2] memory z_1;
        uint256[2] memory z_2;

        unchecked{
            for (i = 0; i < publicKeys.length; i++) {
                z_1 = ringCalcZ1(publicKeys[i], c, s[i]);
                z_2 = ringCalcZ2(keyImage, h, s[i], c);

                if (i != publicKeys.length - 1) {
                    c = H1(
                        abi.encodePacked(
                            hBytes,
                            keyImage,
                            message,
                            z_1,
                            z_2
                        )
                    );
                }
            }
        }

        return c0 == H1(
            abi.encodePacked(
                hBytes,
                keyImage,
                message,
                z_1,
                z_2
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}