/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: MIT

// This file is MIT Licensed.
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

// Author: P.G. RAL
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
        vk.alpha = Pairing.G1Point(uint256(0x1bc908de1981da8df81090dab5755934a020b446785b7ea92540e601cdab6820), uint256(0x1dce4246d1a0807fe32bd8b2f6b46400a1d73a82974a46f643c0bef9e252ab04));
        vk.beta = Pairing.G2Point([uint256(0x109ba3e07d374d09ad4ca0461bfe6bdf7cf6ea4b763af7aba41ec7b28504cc99), uint256(0x137bf638a8a8572c49cdf2f455e97efbfb20dec1fe2b12ed2cb2d9a35d96aa15)], [uint256(0x13e1a315adb43a2b9961b4e6e0162366a3f67f01775097249ecc8bd072f954cb), uint256(0x0e24d11ad7ef8526ae60b28c3b9f25a2afa8cb01f4537085effc103b0f841ca2)]);
        vk.gamma = Pairing.G2Point([uint256(0x2db9bc34830616c044fafa1e09ca207c97930c7a07cd1864feca01a6ddc336ac), uint256(0x249260af0f48af728c65981630194556b83dfddfd4ca9c32ee5d1a4c4d9cdb2d)], [uint256(0x02241f7135817e74310b31a1c82d8b9d2816d9191e0deeb0c58ced39cf53ebea), uint256(0x0f3891c17dc4064397d32da6796fc95561d837da4091c0788f544a6531393358)]);
        vk.delta = Pairing.G2Point([uint256(0x1b47d52f79c09a3ff53cdc2646573db0650f190b3a52450dfbec7c9ddf11f87a), uint256(0x02dde474c689347efbc8a5ed0e92d878b8200d82591140b2ea9352218c41cb15)], [uint256(0x1b3fe4455e4c77c64849a53210fe8fedc714adbb92a26468b82c31c004029acd), uint256(0x002af03cec759e417bee1e4ce59592c18e97001a92cc2ec97488402fa0fd5ee2)]);
        vk.gamma_abc = new Pairing.G1Point[](11);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x28213d9b799efcb461a0d027d917a17f21566343d91644f51c04007c5ac62715), uint256(0x26effb76c999a8224f969d7c94e99f26b3cae23fdc96813f343af3e96fc9539e));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1dd9c1782619cc5dc76536bee2fa6d7048fcc57bfd4a43904f5aac7a110cce2c), uint256(0x193ec69c123d8b87c00142fffeb23e9aa33475c2bf1aa467acee4f53bb718422));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x24aa1fa2a0ae2b568b792cbcc23dd7c63f36e898b4fe42fdbb1ad1a570f0829b), uint256(0x227a9c0c11430dce6b478280a2d2e35be0e4d5b04a3577ce1c2e46af90d537d6));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2b81554039b27da71f4d312e1b2d0ac999b49696d1a162baeea41787c62297df), uint256(0x04cdf431be1956d01e0a26c25b25f438f4b029aa2952a772cebace87e9cac77e));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x2115019937d65485a5b68da40a45b4313833b55b88a4e8d19561744601ddafe0), uint256(0x29846be2cd0372b14028da932bd16a97aec4c521f8b57dc098bf418ce2ee64bb));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x222658cc936e4d0afbbad6cba9b54119228fc717e704741cce5c450fe1539cf2), uint256(0x1d3779eb005e6033a0bbec5e7f0779730595984db5226a5f89619ac1ebcc9d36));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1603be1457c412c651726c97cb2ce62330026ce078fff82906ce5b09a3f7a4c5), uint256(0x2f20c87b89d6dab91b041526465645d36a15ecd06e5b3f9d397943c8f0d8f66d));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x0f21aba0357f6ff0279e464b08339d7436fcac69ac8ce53776007eb7b7d83d62), uint256(0x0ff9da48ca0c6e6d46501c934da1eb4ca30e0ec0bf92d5ee4e7ab6d2b217d438));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x1325c41dc4134e6f5e19c7bba90d87dc0aaada34f18eca12e3e8cdcebe98cb5c), uint256(0x0f80b049a40b0908dce832ffbda9a32d49acbdce7018411ddcfa6517a05c530f));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0402918849de382eb44cba916bc742b622f4af20c8eaa50b4af56311067e9a44), uint256(0x0df6cb6a2d785c7142f7102b3f77293c27e57305b91a0779b555a21388e5300b));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1b9e954d2bbde1ae86a2b034524e28f6adcbbedd7edd690dc47ecc9a032c434c), uint256(0x25f74e92bc9cb5f6a20043a8260861ece74d3eba37c555003ac0357c787a5f07));
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