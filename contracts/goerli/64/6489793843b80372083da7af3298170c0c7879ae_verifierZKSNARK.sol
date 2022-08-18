// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import {Pairing, G1Point, G2Point, VerifyingKey, Proof} from './pairing.sol';
contract verifierZKSNARK {
    using Pairing for *;
    address public admin;
    VerifyingKey[3] public vk;

    constructor(){
        admin = msg.sender;
    }

    function setVerifyingKey(VerifyingKey calldata _vKey, uint index) external {
        require(msg.sender==admin,"Only admin can set verification keys");
        // Alpha
        vk[index].alpha1.X = _vKey.alpha1.X;
        vk[index].alpha1.Y = _vKey.alpha1.Y;
        for (uint j = 0; j < 2; j++) {
            // Beta
            vk[index].beta2.X[j] = _vKey.beta2.X[j];
            vk[index].beta2.Y[j] = _vKey.beta2.Y[j];
            // Gamma
            vk[index].gamma2.X[j] = _vKey.gamma2.X[j];
            vk[index].gamma2.Y[j] = _vKey.gamma2.Y[j];
            // Delta
            vk[index].delta2.X[j] = _vKey.delta2.X[j];
            vk[index].delta2.Y[j] = _vKey.delta2.Y[j];
        }
        for (uint j = 0; j < _vKey.IC.length; j++) {
            // IC
            vk[index].IC.push(G1Point(_vKey.IC[j].X, _vKey.IC[j].Y));
        }
    }

    // function verifyingKey() internal pure returns (VerifyingKey memory vk) {    
    // }

    function verify(uint[] memory input, Proof memory proof, uint vkIndex) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        // VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk[vkIndex].IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        G1Point memory vk_x = G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk[vkIndex].IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk[vkIndex].IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk[vkIndex].alpha1, vk[vkIndex].beta2,
            vk_x, vk[vkIndex].gamma2,
            proof.C, vk[vkIndex].delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[] memory input,
            uint vkIndex
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = G1Point(a[0], a[1]);
        proof.B = G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = G1Point(c[0], c[1]);
    
        if (verify(input, proof, vkIndex) == 0) {
            return true;
        } else {
            return false;
        }
    }
}