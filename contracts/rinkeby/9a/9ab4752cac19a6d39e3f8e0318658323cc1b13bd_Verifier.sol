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
        vk.alpha = Pairing.G1Point(uint256(0x1e524143a4e33044ca64af12216d9b3ba0c4903116e6d6aed50acb8ce2048c0f), uint256(0x2bf05a133c68165a2bf1cfa4b6b1bad23920f847f26d84af5b0cbbf0f2b60c0f));
        vk.beta = Pairing.G2Point([uint256(0x2192bfc4a44f84e3ebd2c9522ac65bcc5ddb3032cfcb4948a2712b4829a7715c), uint256(0x176e73950dc2faa78bec6a04a30df5ed6b6357221874847dba24e0b1384fb983)], [uint256(0x2468d386d0480e1a8568c05a6644a2254eaa70a97217ca9a695a2c1e002f6d27), uint256(0x27744613d508316d7d7e96ed0122f6f3dcb28ca730fde1d27052cbf2b0ae3e93)]);
        vk.gamma = Pairing.G2Point([uint256(0x2380a03b2f02da78ea2ff6c23de34a0944aeb9c1cba7e1f10f58bb2193d44919), uint256(0x24574ea1f6eccf0de10230bcf8e6e00c8833b7aa041c2af46bb0efbb9e2216ec)], [uint256(0x1be51a2964e3c92327be70fc0d972ceb77bf9ec815d6dcf2d3cad7a5c415a41f), uint256(0x087f53208b6db113d95fc47f0930a15f56c7b83bd9410a3ec0496c447fd79369)]);
        vk.delta = Pairing.G2Point([uint256(0x145e4490ec23473fc5610922127e7e64b2c3324bbfce5d70fee1d256b2453e61), uint256(0x1bf9524786b3c2e28267e1079f9261d9d347dd8bf7858d99c1f61f4872f9cdbf)], [uint256(0x2a19e8515644caacd99d98d85d0c82f10acc1dfa524d958d95253136e0f679b3), uint256(0x0a77d270c6d1ae3140b8684f868b2f29a35c46cead2eb30bec8d4fea1b5b4a8a)]);
        vk.gamma_abc = new Pairing.G1Point[](11);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x0d99253d34e7b77a4209e34f551e415cb641241afa138bcb37f77ec34a5322b2), uint256(0x217be25a0cfd532d3a2a612baa36c1dacf47b51f25902a1e7a667b5907edfd92));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x2dd70e3717827e210e134d1bdef9c258ce0e5458f964496f371b053980b82ddc), uint256(0x0f14bef1fd0097dcb5ddb608b86d452ab00f958ee4b1fdfc896140270b5169c3));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x157d778ed3935e52b7652046db7d0c2eef498a40387fb1ce696e937d32da4d48), uint256(0x2f876e2d18c1f877088c63b1aaa090dd49f31c5b27d9d68263a23526347d5807));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0b7ea47febc0fbe5f401c832a67d4004dacf557e074e8beec023cbe1108dc01c), uint256(0x20800db9692ca5ad090545d8e1f8f5eadc1273457b1c397f21e5ae4d16b6860d));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x304140cf7023e2e157daf6480ac1aa1e0245a0c6ed6c5fc9ee728b40d44343d1), uint256(0x0b461c136bd4009a2476c864a7a177aab908a4b9bbfc415600b766cece124440));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x08cbd731d2a1d6ae0e270c75ea88131ff1b8299d6f08de27b3d9aa7801c954cc), uint256(0x2ed071787f6c4da4517f2944558a6ca61cd956d6f4c5aaa7d12ba16b7cdefe00));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1d0cd171c380cf186d471ace978222b88dd9621367adf5c97c2971012521756f), uint256(0x173e7d4609df3b31fbf2899e409906a6afd776eb05cb146025241bbc9faa52ad));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x1f1343be34f6661cf6589876aeac50c3506f8e175e6509e095a188ddb9599da9), uint256(0x0cb4ce9b085e0fd821fccdad5506401adefbbf9a85522ac863f19e21e6e2c90e));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x0a57c1b943a0b00c9a0b1ee119accb9717deb80a7918be2fd85a2632674f898f), uint256(0x198033b05fc7eb0be0b954caaf9c8dd15d2d5a2726d8ff510568e79810ac3db0));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x03a73c20c5ca09d99652deed7085c6cdcb2ea19742ea45f7733b52b33ec8efaa), uint256(0x0cf53b454c1d51650c5a5113b89225cb27794bd5a55387197131be9d46423eec));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x2df9fe2bdb8a57df7b6b4a4032ce87a9f9ae9665982498cf86ebb2821a520714), uint256(0x1a1046fe895ca501da3d5523003507f6e8606d0e298df50fd99bb26439ac38cb));
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