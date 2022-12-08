// SPDX-License-Identifier: GPL-3.0
// solc --bin --abi SolvencyContract.sol -o ./SolvencyContract --overwrite 

pragma solidity ^0.8.0;

import "Pairing.sol";
import "SnarkUtils.sol";

contract SolvencyProtocol {

     struct VerifyingKey {
        Pairing.G1Point alpha1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point IC0;
        Pairing.G1Point IC1;
    }
    
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    event ProofPublished(bool verificationOutcome, string metadata, uint timestamp, uint vKeyId,
                        uint[2] proofG1A, uint[2][2] proofG2B, uint[2] proofG1C, uint256 publicInput,
                        uint256 publicInputPreimageHash, 
                        uint256[] publicInputPreimage);
    
    address private owner;
    mapping (uint => VerifyingKey) public verifyingKeys;
    uint[] public vKeyIds;

    constructor() {
        owner = msg.sender;
    }
    
    function addVerifyingKey(uint[2] memory alpha1,
                    uint[2][2] memory beta2, 
                    uint[2][2] memory gamma2,
                    uint[2][2] memory delta2, 
                    uint[2][2] memory IC,
                    uint vKeyId
                    ) public {
        require(msg.sender == owner, "You must be the owner to add a new verifying key!");
        Pairing.G1Point memory _alpha1 = Pairing.G1Point(alpha1[0], alpha1[1]);
        Pairing.G2Point memory _beta2 = Pairing.G2Point([beta2[0][1], beta2[0][0]], [beta2[1][1], beta2[1][0]]);
        Pairing.G2Point memory _gamma2 = Pairing.G2Point([gamma2[0][1], gamma2[0][0]], [gamma2[1][1], gamma2[1][0]]);
        Pairing.G2Point memory _delta2 = Pairing.G2Point([delta2[0][1], delta2[0][0]], [delta2[1][1], delta2[1][0]]);

        assert(IC.length == 2);
        Pairing.G1Point memory IC0 = Pairing.G1Point(IC[0][0], IC[0][1]);
        Pairing.G1Point memory IC1 = Pairing.G1Point(IC[1][0], IC[1][1]);
        
        verifyingKeys[vKeyId] = VerifyingKey({
            alpha1: _alpha1,
            beta2: _beta2,
            gamma2: _gamma2,
            delta2: _delta2,
            IC0: IC0,
            IC1: IC1
        });
        vKeyIds.push(vKeyId);
    }

    function vKeyIdIncluded(uint vKeyId) public view returns (bool) {
        for(uint x = 0; x < vKeyIds.length; x++) {
            if (vKeyIds[x] == vKeyId) {
                return true;
            }
        }
        return false;
    }

    function publishSolvencyProof(uint[2] memory a,
                                 uint[2][2] memory b, 
                                 uint[2] memory c, 
                                 uint256 publicInputHash,
                                 uint256[] memory publicInputPreimage,
                                 string memory metadata,
                                 uint vKeyId) public returns (bool)
    {
        
        Proof memory proof = Proof({
                A: Pairing.G1Point(a[0], a[1]),
                B: Pairing.G2Point([b[0][1],b[0][0]], [b[1][1], b[1][0]]),
                C: Pairing.G1Point(c[0], c[1])
            });
        
        bool validKey = vKeyIdIncluded(vKeyId);
        assert(validKey);    
        
        // copy function arguments to local memory to avoid "stack too deep" error
        
        uint[2] memory proofG1A = [proof.A.X, proof.A.Y];
        uint[2][2] memory proofG1B = [proof.B.X,proof.B.Y];
        uint[2] memory proofG1C = [proof.C.X,proof.C.Y];
        bool verified = verifyProof(proof, publicInputHash, vKeyId);
        uint256[] memory _publicInputPreimage = new uint256[](publicInputPreimage.length);
        for(uint i = 0; i < publicInputPreimage.length; i++) {
            _publicInputPreimage[i] = publicInputPreimage[i];
        }
        uint256 _publicInputHash = publicInputHash;
        uint _vKeyId = vKeyId;
        string memory _metadata = metadata;
        
        uint256 publicInputPreimageHash = uint256(SnarkUtils.bitCorrectedKeccak(publicInputPreimage));
        
        emit ProofPublished(verified, _metadata, block.timestamp, _vKeyId,
            proofG1A, proofG1B, proofG1C, _publicInputHash, publicInputPreimageHash, _publicInputPreimage);
        
        return verified;
    }

    function verify(uint256 input, Proof memory proof, VerifyingKey memory verifyingKey) internal view returns (bool) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        
        Pairing.G1Point memory vk_x = verifyingKey.IC0;

        require(input < snark_scalar_field,"verifier-gte-snark-scalar-field");
        vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(verifyingKey.IC1, input));

        return Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            verifyingKey.alpha1, verifyingKey.beta2,
            vk_x, verifyingKey.gamma2,
            proof.C, verifyingKey.delta2
        );
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            Proof memory proof,
            uint256 input,
            uint vKeyId
        ) public view returns (bool r) {
        VerifyingKey memory verifyingKey = verifyingKeys[vKeyId];
        return verify(input, proof, verifyingKey);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library Pairing {
    
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint256[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;

        uint gas_cost = (80000 * 3 + 100000) * 2;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(gas_cost, 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

library SnarkUtils {

    uint8 internal constant NUM_SCALAR_BITS = 254;
    uint8 internal constant PUBLIC_INPUT_LEN = 248;

    function bitCorrectedBytes(uint256[] memory input) internal pure returns (bytes memory) {
        // in the snark, variables are 254 bits instead of 256 bits
        // step 1: convert the raw data in input to a sequence of bytes, where the two highest order
        uint256 numBits = input.length * NUM_SCALAR_BITS;
        uint256 bitPadding = (8 - (numBits % 8)) % 8;
        uint256 numBytes = (numBits + bitPadding) / 8;
        assert(numBytes * 8 == numBits + bitPadding);

        bytes memory outputBytes = new bytes(numBytes);
        
        uint256 inputIdx = 0;
        uint256 inputBitIdx = NUM_SCALAR_BITS - 1;
        uint8 outputBitIdx = 7 - uint8(bitPadding);
        uint8 currByte = 0;
        uint256 currByteIdx = 0;
        
        // set the bits one by one
        while (inputIdx < input.length) {
            uint8 inputBit = uint8(input[inputIdx] >> inputBitIdx) & 1;
            currByte |= inputBit << outputBitIdx;
            
            if (outputBitIdx == 0) {
                outputBytes[currByteIdx] = bytes1(currByte);
                currByteIdx += 1;
                currByte = 0;
                outputBitIdx = 7;
            } else {
                outputBitIdx -= 1;
            }

            if (inputBitIdx == 0) {
                inputIdx += 1;
                inputBitIdx = NUM_SCALAR_BITS - 1;
            } else {
                inputBitIdx -= 1;
            }

        }
        return outputBytes;
    }

    function bitCorrectedKeccak(uint256[] memory input) internal pure returns (bytes32) {
        bytes memory outputBytes = bitCorrectedBytes(input);
        // step 2: compute the keccak and drop the unused bits
        return keccak256(outputBytes) >> (256 - PUBLIC_INPUT_LEN);

    }
}