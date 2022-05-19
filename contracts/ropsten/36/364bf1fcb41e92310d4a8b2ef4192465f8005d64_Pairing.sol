/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: UNLICENSED
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
    /// @return the generator of G1
    function P1() pure internal returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() pure internal returns (G2Point memory) {
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
    }
    /// @return the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) pure internal returns (G1Point memory) {
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
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
    }


    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[1];
            input[i * 6 + 3] = p2[i].X[0];
            input[i * 6 + 4] = p2[i].Y[1];
            input[i * 6 + 5] = p2[i].Y[0];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success);
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

contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey() pure internal returns (VerifyingKey memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x23967d0856270c7b06df015a336b0f50eab6993548b50099299be424047feedc), uint256(0x241755d7ade3e0b5ae1b8cc1b6dc2afc7c27b7592280343784a9c27119d33b75));
        vk.beta = Pairing.G2Point([uint256(0x0c57e757ed05353252a2c8d81a7e00fe94fed84d59f7b0805b6d2fac99d44d42), uint256(0x2505285147ca4b0c789d179e47843d5e2ef308811187e515d1555357920feb62)], [uint256(0x2ac3cb0825144ac78059786b1248027bd6b83622d5740eb92d1a41f065864b6f), uint256(0x1230e898aeee62135cdad1d59108316d99d8522f8f8b6a9b53f67d6066b7d6ee)]);
        vk.gamma = Pairing.G2Point([uint256(0x1e143dcb3afe85bd65f3570867d9ef4a6d0a5ca0b01f1a9b751c64efecef30fd), uint256(0x237a18aefd2c110400f5aacc90759419f083a38a22906b2d27b0303a2d35426b)], [uint256(0x0e3947d4c126b955458a59b81a77f42063d58d5ce8ab1b0bd6e8d561909c14a0), uint256(0x0abd3f90892f40e08f057fa9333414da0f8affa8204e8ad38a424399d24c49b1)]);
        vk.delta = Pairing.G2Point([uint256(0x189774d1c53006510835af68cfed580fa7cb36304830be47e3280060310e5fe3), uint256(0x2d83d1aa1b682c74a5335a051b6ab2ca4fa7c9dcc18493d880c7b47d5b2a705a)], [uint256(0x29108f3a5f8c69af9adb04cdbcc41b9360e5c74cb8d936552dddba15fe2d7012), uint256(0x1543bd55bee1803ae4f077a692291c9b98e7460dee4deef7ed6e67587ed78714)]);
        vk.gamma_abc = new Pairing.G1Point[](11);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x287df93ef23bf95fdf83d30b886065aff79a5222f0c3a9250759b15f7a3a7ceb), uint256(0x078337ebf97710be0fddb183f5369b5c10eacda1c19fe73711ce24178a657602));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0e1dda8eb4db658e59cb455c94dc3b415831c9ddb066c0b238eca8aa2d2f5332), uint256(0x11aec000c46d1e06433bc5b29b54e37bf1afb81b5e4d09558db0e514ba5967f4));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x145b32c8c54a4e3597a78e7dadcc7b985480c36df1c37c25b999c851cb48ff97), uint256(0x13c8f6ac699f4664b25b4f81cdf2362f6323bf4d8c07f915200da992bb363b55));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x013427c1768daa7b09ea68fddf81ba462b38317c33a4349f11cd44b5b7d79c43), uint256(0x0f4d37f0309dd763035a519fc23495a39fb0ee5d8d1bb54740f3182bbd6cc161));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x27aba8c305dcde5c9148082c993eede69845d1ae2836f353de7284c4a3d68e07), uint256(0x07111cb78984df5f20792477f06bd7e17b29c97d64d335072dbe87c024ae9228));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0fb6ba9aa21fa990056d4685b7cf56cbda3c9fc536961fa2f739afcd273378d2), uint256(0x0dfb1491ca05ff34e823370ff806bd5b479931cf04251aba04189143c927a36f));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x15ca0671a2e2edc6ee869ab66949c33b11b6332079f261fc6e9ea44d5b42f86a), uint256(0x2f26fec09f039be2a21f173d869349fdfb94e3f71364113d451bbbda1ebfffb8));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x18d50382514c2a453fd3a4a1daaa924fc76661adc190ecd43c18be65b3e4434a), uint256(0x196be48c6d01b07a5d71340800c9eede10ef00c856cdc476f1392768bd6e1c9e));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x1e088be06e63dfdfda6737f51c7591a35a44f2c7f3345f0a20807b626086fd20), uint256(0x0b393d8b4d8583fd9f9e784955c1a62fb3d4a32aa8131b52ce6bb1de28fd9ac9));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0a3bb9e224955d841a80b508b4fd0caa719d5e75a996fa97f8203c644f035378), uint256(0x0769a4a4b0b1a3d67a6e9c924d201f05739369392c423433ddd48f3f561dc797));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x149a0eb34b0aad1898a52bc2b8f53eb3d9095127742762b2b7d22a809d820755), uint256(0x2cee0ce307c9f724bb300812f81e5998d77f5a3cee9b3b1147db1e71a1bc3aba));
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.gamma_abc.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field);
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.gamma_abc[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.gamma_abc[0]);
        if(!Pairing.pairingProd4(
             proof.a, proof.b,
             Pairing.negate(vk_x), vk.gamma,
             Pairing.negate(proof.c), vk.delta,
             Pairing.negate(vk.alpha), vk.beta)) return 1;
        return 0;
    }
    function verifyTx(
            Proof memory proof, uint[10] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](10);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}