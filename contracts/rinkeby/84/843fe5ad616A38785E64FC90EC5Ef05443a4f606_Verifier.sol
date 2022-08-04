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
        vk.alpha = Pairing.G1Point(uint256(0x23d3a344c5100954c8f1765cb565c9a3915f61390a870bc71308156b1617ffa9), uint256(0x06bb713a97c27d9396d417a4ed8f38fbc7c7169d1cbf3b6ab5d0259418d46530));
        vk.beta = Pairing.G2Point([uint256(0x2187add15a505bf2bc62145ca2ee89da8b88b52016ca01ed36de0d857520591b), uint256(0x007ed782e5738a8decd24179a7cc9c0e39a3a1f979b56d646f11236d4cf08549)], [uint256(0x23790fec13f51077d463a727280b6354cac5575c1fc826c9611db2acff5dd658), uint256(0x00645c9bcbbbe4e7946ccd9308df506367a36269bc23a3e898be52de4b7de64c)]);
        vk.gamma = Pairing.G2Point([uint256(0x1c107126bd5d3f14cb637b20e25fd8b115d35ef2dcb59465f779b05d2a0e7e36), uint256(0x2bc461af63096f01ba63a2c2ddcafcdff793fde1c4cca0abc91ec6c0741e6d04)], [uint256(0x102cf11438fb559d4947ff163997e04279f107095c2ad0b535c227746d352ff3), uint256(0x0b0ca1b1eebca5cdc9369943be7fb2792b4dea7a868e221ab82aa00c618c1cec)]);
        vk.delta = Pairing.G2Point([uint256(0x034f8367459c2c917e0317337ae16395370cff2ba950cd736c0ec8fb037c37d4), uint256(0x18d90201bbe224958e723a240c3dbfc7ea40a496459163de3f7a1461ce4937d6)], [uint256(0x1b842eef148fa85a630ef4f091f2f31e6592371f7d761bc59312f5152702100e), uint256(0x1d9b4a8e7015167971b3e886eb22d7495cc7a2df80997b2c73061183f26ee80a)]);
        vk.gamma_abc = new Pairing.G1Point[](103);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x04119b0da6252349d6894c7fac2967f6873afea830892d303e238eb581f532c4), uint256(0x235d85436ffb047433a8358a4cb746f0ea639d318737aecfccfa8827c1171a8a));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x05599033c6f583d8270457891b3ed1e30c13d7060062fc5c7fb39627d2fbf5e8), uint256(0x1d36d87412afd525a05131af233bf5d9a734720e1cff26bfc2ac1f33189dc49c));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x174d0ccf2f833c3380816ef6922fa689858cdd0c9a75c28d2deca0386fc3cd7c), uint256(0x2b684f96fb8055e7e50dfe932b3980f2aee467030ed42ee75b0c3e47dccd7eef));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1a04938baa21f4de4b2aa6588250d82163a8616a07f415a88000371d9ef6d51b), uint256(0x0f701600e5f75bc9af482baca8e220fae37ba3f32acd79e539f2cf2d546a5d34));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0ce37fcf3528bf9d6424304e10dded0ebda0c9e5e2ced79fd774e03fca520ef0), uint256(0x024da94f44dc102b89bad63bedd8bca9fa98929b89570c849cb322e8997031e6));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x11094b2247cbdf4ca6803ed510e7e798a0616737de50c2ad8c694e1c111f6b83), uint256(0x2dd2f8ab78f94ef6ea12d0e7795005ef263a3ee64163effab39c2bf28fed190d));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x19ccaa11ab7d95ba03d56a1438c37892035e2397b93d18ffd11cfa4ae57d4dea), uint256(0x2a2cbd545498ae43ee59db8b77d1a49093383710c6077db37e221b4a56c104b8));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x0310182336d98dfc821cffc0434231db23ea9fba185d989516dea603af0944af), uint256(0x06f058c722d2c8280574a70e25b13c6a6999d35bd48a9c5cd61e4339d02072b7));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x2116e7ad4dccfb154d8f8911d78645b4241d9dc301a50511806a0d6a538046dd), uint256(0x2284fc60866a8fdd33c042f3e9effbf783b8238b09b97b8211cefa7a9de69b83));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x032baacf7feda8e377ea351aafb9a1161493af4f46077c21715a3f5c91eb2a2a), uint256(0x23b8a8082306d07ade5256ff773c48a02ac68daea390f6bfe49cefe785f846c5));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x0f99f3086851bff1e2d0a04e44f0084a0d127fdae0782a54fe28d8663e14e9ba), uint256(0x284f2eb711a4a5d7421ec0c91006f1f2a2ffa27a3fd24cbb37c7a4d6162c94e9));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x009d146a2f772c45d39170caad2b855f3ecffe347922e7ae29df22c517947f15), uint256(0x036957ebb294bf78c07ffda0f005639efb098ad9d93c9854253fd4ea5f6bb231));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x136ce1050a9b0e511a21288bc2d501411e07dd04562783a4e8f60c4fb05c4c9c), uint256(0x26039bd2f3ae56e332ee39fed434f2f2b44253362724e6f7920bc204bf42cc35));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x221e5879a603f3b8f1665b976af5c88643e5d41a893b4a88d91d921e16ae19d7), uint256(0x127dc1090056b8f71ee30f0346e3b124ee9a0ee4c8dd3aa452a426f2d0fcadbc));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x0ce9cf40c1e71a5ca9bb4d53202c792c098f79051930e83e42dad8d8d95b4122), uint256(0x0776c8b46841b92a373d975e09fcc7d937c93850182968fe6c6a351881bbcda7));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x08130837a7bebcd4a1af92593bfe3cb28ef8a2410dd3c47179cf4f90ae757d65), uint256(0x1df5624beba1fa401e48eb208366ba9d15072bb0233ff530a09cb83ad1b991c1));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x1c3c3501cc3caab0cb41ee5788921c68e38fb8706e155cec069cf59be502cc5a), uint256(0x049f5d94ba2a4df6e8ae100d4a3521dca72a0da06aa34c820300dce02119c62f));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x190379c50f766697c5e50de3e06357eab931871d57a4353577ec8d2f817206da), uint256(0x13a86c4fbc6b11fce4bc626cc4cd2f4eaf36efcde11fbf81cc2bb437cb82aae5));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x285aea5bbd8b5536a440cfbf56a732f4f34a0c3b6e4cb67aa485d7fc15b01bc8), uint256(0x2894bd502a510944f8cb4ee0b6c9fe3407c985cb4797a1213c3be90410daadfb));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x2d73184d3fa057bad8f667ad2e1cf5dbc56679f52963daa2b6ce96704fff6b15), uint256(0x2bb8a2b4716889e593c3e275a9b43a7943db18f926ab7f9203cfffdf637de0ef));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x1579c1883b34a2fbf55947210e592503a04a0e9028204229cc85a5c90d9c9174), uint256(0x0399ea7807fb551f919fed3877a4aa1d549365000f42a04592fa0cb6cf84a101));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x157151331c7aaf22bf0f0309d5d16d7e740ae75e4ad3c118e8d00e0e6865a8b9), uint256(0x0391fc01da4bba554298513a4a9aab1ab1d526c0f8a8a101499a076120547d52));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x03741bbdbc9b3701542ba360357c26374ea20878867b7897a4c749cf3e636ec7), uint256(0x2ddc56564133940e12043b60ffde6421edb8ba8bf06c4ded2742cc470cb9c884));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x2dd8d589064bfdd80801785635bd11f51916707d6b1eabfef600924fb5f105fc), uint256(0x213a51afe884cec37d2f57cc3a23cbc7c8de0294a5c0a46229566912951f9b8c));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x16b8955db75e41f857e6b4e352155f9384ab29d0fdb8f4e4b519b48985935be4), uint256(0x015a3012060a28ee5466eb6b6befa2900d1098f82289fa0fbe0094ffaca92582));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x228ce73d19e60da4f544d3aa6963a17c4f5d7225e37f7b552b611a139af80dcb), uint256(0x0eee5f92e79c61aa163a6412612939660a9345e663dcc83b7cfcfb6e41c9a285));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x2cb2d2a66e6ff1bb435fecb6555103098dae9a9c67ee1cdeaed2e690f959ce0a), uint256(0x28e371401fa776ede9d92b300a9eb4bf1ab8e4aef2006482f627961989fdc22a));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x2a6a173fc013bbc53ee0a1a4c92be8ab03a85681e4362ca9547ab22398b27876), uint256(0x1c313f7c1b87044cf9c1ecc7a9815aa1e744e0617f114822a10f46226dbe4f2c));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x003af160c98f77989e8671f4d92f2d819d2502334d675f0c42e68a4f3a0edbed), uint256(0x27b0b95cde457a68ddc80ce8813687d324a86c6bd774d226f1b7b0e77cc61215));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x191f063f6c3a5c7929eb6c139b1a182da0f209413ed94fef0ba1e51e47c675ad), uint256(0x1e32eb3e50abe5f36a585ef3354b055513b49668e45a20bc05f6cc0dae41d3fc));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x26d8d2d0bcf660d3c8409646b6c0fa1955a542d951cda4ef5383e7cd5a6688ed), uint256(0x1d7066d255f2858313fb9a36cb315cab25aa5120daf78440806abe97df1ab943));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x2f35f17d17c29f1e4956699d2537ca727135495e61960bd8f179690f2228c54c), uint256(0x03c6d9c50fe094b4592a6d5be2c27cccc7eb7f98db8fedc3b9254a7c6a35e18c));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x3016ca345224ee00097ac8f32972ec82ec8e5ccb71ce3226e268ab0037f9b2a8), uint256(0x22b97533e0d9066d12244651c08b379378395cd76b84d539e78a5fc9de6c052b));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x1b34f04c8f27a2c8b8d0e5e1a6c84d962e9e81c7f5c9aa64a4188e491f69ad63), uint256(0x09b71ae49c4150ec17b796dd1f45488ff0592c8a0911d4baa72ddb22922c3c1c));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x0b6be05634c3d5159e69eb0d6591ac3141fecc4d8d3abdadc91d26dfeeab087a), uint256(0x1af0d00c0767191eefbaf16f19807585fbf01c0b1e583fe2024ad19b13ba979c));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x2c1a5e0bae8bca8bad4a332349b9065b10bbfcb12ac022a758fac5050c00a20c), uint256(0x2caae3252351bef8f2dffba279890f8eae8cd65106fdaf53b4f1dcb5f2a6062d));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x0fffcdef4c2af611a834b3918ff82621bb9a0ba82d532b8c059fc8f48d71c739), uint256(0x2d26083753fd03713fb97b236835876e8cdb199f340aaadda4cf4c3f154da043));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x15d454e0623a9816fadb2994a8d232337542687fa8d9d5d1f6df22bb5ec41601), uint256(0x12e9f7634d65e22247d7b695cc60d1a0d36da05c598cff3c00631f1fc523f26b));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x03d6d796cdaaeb0e19c0b2f5aa686a1458fdef6083e9cc780a546d23017f2224), uint256(0x0a00df5273d3894bbf1dd7b47b9b9b45e2b65fc300f1282596242e9273a5d940));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x21203931975970a1559bf0d6074672ec232bee6a9b382f8686cb8b42df236196), uint256(0x143b888c3939f1e3c110195eca707940efadd1d9a6c6cff3e746bb6fb76dc560));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x2e0859b548d88fa9c0408c10fff4509a8e6414f06aadb163247b9b7a9069c799), uint256(0x183b92a24ef6abe4575aac5d96b52dcd68f6cf2fd98d1e8b531c1a269ba0e37d));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x018489c1afe8d850be2ffdd31a0cabc0dd53e43df8baedc0b4648dd108d221d6), uint256(0x2768c49320f7f2cbfb2b6c5ab4abbc46be1ce86ef4e9a751393041e8d793e59f));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x1e1c692702f0c27c174ef9dfcf6ecee3104973b573e7ae2bf558bd3fb50744e6), uint256(0x161869e18b418cef3f0990c69b4b86b9c92ab94d50c9410ef51329e4ebd276b7));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x1aadb4a97577c826933a6563dae6be6a4b7ed95377ddcb47ba4057d10b7ccb84), uint256(0x19e3432d53de1c6e90f0526ce23df2b845d38463c434dde3a61524a161a20792));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x2b6a8db97c9b3705c91a37d23db93de681cfea76c6cb8101b5ca0b3a83becf70), uint256(0x1cca94d16860735d0fe63dd52f4695c0b7575f3745643618d67baebad0dd6a7e));
        vk.gamma_abc[45] = Pairing.G1Point(uint256(0x06391f6481614d682ae0601f76b50f86b7fe98894d9ee66c118026afc39e1b8a), uint256(0x12dd6f9c03394d5a6babde80b382863990e4b8a754bc2112d2c96ec3256ea3fd));
        vk.gamma_abc[46] = Pairing.G1Point(uint256(0x01189d4294845e0c7d4c95bb714e68d1e1efcde9eec17736918fbdcd0876d92a), uint256(0x0f22cee0bbc1a6908ecbc5930afde6b5066cf5851279e5c791c8ab1f2d234064));
        vk.gamma_abc[47] = Pairing.G1Point(uint256(0x303071e1259d600d62fa431919974065f0aae991d0922343410defc0f2a86077), uint256(0x0e8a04c1a52bf14d708bf61d1665212b30a4124a55de361cf7e8cb3e2f4cde99));
        vk.gamma_abc[48] = Pairing.G1Point(uint256(0x2521b9454a7d8b07a6127610c6594519b526437a2574b2fcb0d2b5cbfd96b9dd), uint256(0x201b9df1e7fff08a87fb79985d043e0a6d8f121f189145e800d0ecf608b0c636));
        vk.gamma_abc[49] = Pairing.G1Point(uint256(0x01de22ec2951c283b8d3616e5d2bbfe61e357caf4f407b2f85d27ab092554116), uint256(0x165228469f16af2547fbf004006df8d0d1c61a65bb1ac83fbefe9b2a84737efb));
        vk.gamma_abc[50] = Pairing.G1Point(uint256(0x2ce090c2bc70188775750a0d10f12c838dca95960ae5d260e17a2234653e73d3), uint256(0x2632e582fe1689b3fba2d6bbeb64d933348fa7f4b5a7a0f799e034a568369640));
        vk.gamma_abc[51] = Pairing.G1Point(uint256(0x04ff8303860f5b40e4e8aa27e1a3dc4a9eecb6d7d82efb1da4abd5e56857cf9d), uint256(0x2727a0c38719be6c5ef7fac2d7fd8d3e1086964257dcac31a00994942260b71e));
        vk.gamma_abc[52] = Pairing.G1Point(uint256(0x040583cffee2e62a9b25e4d372e055aa8af55d1baf7817afc2974499a421292f), uint256(0x1782ed3b23e9cfbd7727feaa41a83fc74b3982aa462b28e17c7c29b8a476e865));
        vk.gamma_abc[53] = Pairing.G1Point(uint256(0x1a3beffdb942ac1560e8ab0012d5ba73d0cd10495f549e568e886e115d4c97ee), uint256(0x0101ff8a5e81dd4de2cef79df8532d663c48415edf33f14ae0b056fac0f756a6));
        vk.gamma_abc[54] = Pairing.G1Point(uint256(0x1cfda832b3696fdaa54673669174e8ffe1b60c3b36f93ee63f3b628549335b34), uint256(0x2006a4fc1e6adb78c0dddce83a276b2b36ba5d2ebaf032776c5004e80b5d4b35));
        vk.gamma_abc[55] = Pairing.G1Point(uint256(0x12201deaea2e5ccae094acf45fd6c93f610342e8631ed15610f18502df5a607c), uint256(0x23ee88bc3f093282c3132ddba0f0e09b5b85ff26564ae5a627b0ce0474a33267));
        vk.gamma_abc[56] = Pairing.G1Point(uint256(0x1cb8e77c7fa788f2c9399d557c6af45f05827a67c244603fb7a63dcbd24ed763), uint256(0x13c222bd731d8720ce403c0f953c6a0c1d88f27549756cfdd1ff0f8c1c9e044e));
        vk.gamma_abc[57] = Pairing.G1Point(uint256(0x1acf8210057e41501bd7259af48cdbfd35b4c0ac7795e937616b447261bb0354), uint256(0x268827920bbbe3a997f94aef01a9eaad8560a43d2b83736a1881efcd7bda9499));
        vk.gamma_abc[58] = Pairing.G1Point(uint256(0x295b84b16d8951b833bc0f9b7f1a0a6d206ac9c8239e02e1cdb9594c4350977e), uint256(0x1a76406982ab9316ea0e90a435afdee5e09ba70c2247ae8b56d70b2e39049e7d));
        vk.gamma_abc[59] = Pairing.G1Point(uint256(0x023a0c34f72c3b98bfec0f8e5ad7cb833452e85c49ffbbecd1f74cd66931dc20), uint256(0x1a4f220f8366d1f6901284e38eb170fa7ecf1d25d04cf8fcc9adc1f257c8216e));
        vk.gamma_abc[60] = Pairing.G1Point(uint256(0x21dfaac4fc47c915ff813c602611c04580bde962538bece509fc0d49be446fdf), uint256(0x26ecd7a6521b82c1618220fc4985d1aee9c11b75966a92e8e505e51f5ad6af58));
        vk.gamma_abc[61] = Pairing.G1Point(uint256(0x1f013f522054877d7b898f1b01f850deb300d5f9d7e0e5af2e02fd2245d5816b), uint256(0x1f14955a835c08e31d362259249c74d0f0110ab01de2db11443a830a2383dc6e));
        vk.gamma_abc[62] = Pairing.G1Point(uint256(0x0b38c0de3beaf430d974504b57687e94790dfff375587c1c105571c69f13d230), uint256(0x266e9de6936e7f1a9cfe2bc0e1f01c38e4bd3f0f70ccb0536abeb3e841657b82));
        vk.gamma_abc[63] = Pairing.G1Point(uint256(0x0e37a14702fdca81174dd05ca609d75dc972835469588f3a8792c8b21342870f), uint256(0x278ec8708f915db1f70364ed83f29a2a2e9a4cc439ea3560a0bde9e20c65770e));
        vk.gamma_abc[64] = Pairing.G1Point(uint256(0x0e4b16606fd1447b3fa45f0d548e777c07a3e757e53271310370ce5f11e25a9e), uint256(0x0cd19563c24d94c4ba9ceecde85118d3a68c543d2b1b478683b6b8d92026a7f0));
        vk.gamma_abc[65] = Pairing.G1Point(uint256(0x1949a273bf04b42d9ade42f66c1169b51ae2a9145342c110d7ad70869955a092), uint256(0x248166e3cb58bc96a2e11daa0be4c7d81897c2186ac37290ca0815e37b487e18));
        vk.gamma_abc[66] = Pairing.G1Point(uint256(0x0abe0325f20d212756100c3310299cf8909667395ab480212dcdf6b64596725c), uint256(0x0fae6664e9abcac576ee21a32858c662de21418b573b458258a7fe467d812bfc));
        vk.gamma_abc[67] = Pairing.G1Point(uint256(0x1e2bf3a4a44970fe38ff4217a7348ab340fb6edbcf01f667e006abc55a11de80), uint256(0x213e7cef78dcffcf9a45317dedc201f0e9940e9239b6e28afcd5f121db1a084a));
        vk.gamma_abc[68] = Pairing.G1Point(uint256(0x28a446394dc259d74fdd64ec91d4c2693bcfa1cf6f0c5369ea52a24279bfe436), uint256(0x262720cfb4874a04f5250bf6be9fec12cc8418130a753ae2b20b867442a74a15));
        vk.gamma_abc[69] = Pairing.G1Point(uint256(0x05254d38145d0aa4e9f751be73dcb73227af8bfddf35a8b9802ff4268493e820), uint256(0x067f5f05368f88da574fe6507c5bf964afe9a70aab9b2f665214e5b8c587c3a1));
        vk.gamma_abc[70] = Pairing.G1Point(uint256(0x1edf469c6ad96a880b1200df52c78a13f46fd734f105255d4763d0dac33fa128), uint256(0x2ff64692533c51e6df8e58dedfc192c6d650943d057b8130094da0cd5f9c9da6));
        vk.gamma_abc[71] = Pairing.G1Point(uint256(0x2de358ebf37faaef952ad8a48ace9b5de1efc53cc5342cdad30e0ab34db20cbe), uint256(0x24c9a45912939359167c8e6872d4bf3d7d067235a0ea23baa4f558a8e5395f13));
        vk.gamma_abc[72] = Pairing.G1Point(uint256(0x2931627cb753e7448209ef464a7bff34a377c9582c86467e32fc8880c10b9b48), uint256(0x1acdf9b398da816423d8317c955179aa731fc8d2d0b5c062a420dfd90c96146d));
        vk.gamma_abc[73] = Pairing.G1Point(uint256(0x0e214dea0e11dfd3020f3eb048b2acd842f24e5eab2d6a93568eb854cbb59dc5), uint256(0x1df3434d8fbfc499abadd9d3346a7dd5dcf883b0423ccdd33933ffc90e965ac8));
        vk.gamma_abc[74] = Pairing.G1Point(uint256(0x21c85a9e7fe4011cc6126f7cf956e68406d7d57994e85d86f57cf19e22ec7b54), uint256(0x1fc5dff78eb5dd02a5e94588d426240b95e0e3bcd67a892031ca5d3768dcf187));
        vk.gamma_abc[75] = Pairing.G1Point(uint256(0x0479e295ad86e3aa6bfc9d239d0cc408f513466b0bceee19db32da4cce610ab7), uint256(0x10cc09431088eb1ef8dab1a7dde6aef843564defe218e0118cd561bfa66b011c));
        vk.gamma_abc[76] = Pairing.G1Point(uint256(0x23f111172985bf54b5da3e763dfd27aeae554679d9d42cdef899b1bc1c7d4807), uint256(0x21dddc520af0c3897b48c84779ef8afe0d97d7f2f7a6db90eb190b9f55df5b96));
        vk.gamma_abc[77] = Pairing.G1Point(uint256(0x0d5d4e35aa07770469252a39bcb792a09c16d2edc1aeb58bd80afe1fb0f160d1), uint256(0x1d791848e0c34a50530c8771becde1a5e326443e0f40e416cf5445e684e366c0));
        vk.gamma_abc[78] = Pairing.G1Point(uint256(0x22d5c0a0757a59bd4f0ff46fd37c4e82edab242716e1d68049b683af762091c3), uint256(0x2dd2b96524061da21d1629c99e5b9acb815e814e910550f02ffd0b1cda9a5cf5));
        vk.gamma_abc[79] = Pairing.G1Point(uint256(0x00c9facbdc0dcd9d36a3371531461578d6d6db4e9068f3ae7bd2608c26314c00), uint256(0x11693191c7e9795c37cc2f752e5c797d57ac1bb515829337aea0763b5be473af));
        vk.gamma_abc[80] = Pairing.G1Point(uint256(0x295b9a7072145981fa0d0bb3e81e51e631f0fd92e2473e2e8622370ff833f24d), uint256(0x08f61d1c3f12970c6d34434b669ca2a2fb13b1a28ddd10d5f9fc079dfcb2dbfc));
        vk.gamma_abc[81] = Pairing.G1Point(uint256(0x044080fc23faf55eec76d53976fe10650d5dbe394afdcb8395f2ca74e04191dd), uint256(0x030f3eeb242cbaeca7fc6b22177cf2828b2ad11c30f29bea4e11a7b165e18076));
        vk.gamma_abc[82] = Pairing.G1Point(uint256(0x2bc18fee3718c56ed3a02e92a954e5109c936b53ddc03d6cf12c8e39363677db), uint256(0x0cf8c1dbf7a7b0d6595008cc98638b61238ddc0bfbb79e6e84f27c823374218b));
        vk.gamma_abc[83] = Pairing.G1Point(uint256(0x06952dd77462321deb47255ba4cc71df3c71e0a0495cb0d328285a887490dad2), uint256(0x1a738965cdf1d65aee64cf69313c6f5b84554e1a51b8ba5866c1a73c0c21dee1));
        vk.gamma_abc[84] = Pairing.G1Point(uint256(0x12ddc4a4344dad8b49c21f7e59c194f18ae4a66106e6c8f753d6ae15161d3f84), uint256(0x21281a5d2986c0cb8be5fbb642ffc0d0749b3cd75bfdc826361fb9285fd57b36));
        vk.gamma_abc[85] = Pairing.G1Point(uint256(0x2c91a7191b75bc3ad8313862e74cac2143c340fbd106c07d70a8c8ed25b1ff89), uint256(0x29b2ef454092b3224de89168f0b54c00b0e8bc0af647f7922d0d4e18badfb696));
        vk.gamma_abc[86] = Pairing.G1Point(uint256(0x1e54303fcfffb94d7188557b576efd1784376058ce0748252229190c68abbe2f), uint256(0x0f43369335ba092584f07c8aa4840194079f4a77d6a76c11242e306bf28b719d));
        vk.gamma_abc[87] = Pairing.G1Point(uint256(0x10eab5f3da49d24cbed353529656cba289ab82a2b6f00fba61ce051cd2301c23), uint256(0x2115f4db0cf450534e9397669ff8dbf449e2d8be35884b40b3d164b8fe0979bc));
        vk.gamma_abc[88] = Pairing.G1Point(uint256(0x11036626cfc910e691cae39c3a86316312700f666101104bfcac4fd3164b517b), uint256(0x134f4d8d604e30b0c77f7d12b255868fb84f404301dfa8ba881a523e6bbc0b78));
        vk.gamma_abc[89] = Pairing.G1Point(uint256(0x0698474a8e5bae8c45e3e9f7a057371fc083a0349befae054b221f5a95fd7ed5), uint256(0x2ac40bc91191a3169d7b606fdc17b9d87196b52aeda65ca63e777199ca9936e8));
        vk.gamma_abc[90] = Pairing.G1Point(uint256(0x1d04f64dadf51df5e210cd444e2b83cb13af209dab4306bc99a85c0c1e11f170), uint256(0x225ffe8284b87e41c6b703076568beaeaf74b11dd8f0834e1c2d56299ff28d25));
        vk.gamma_abc[91] = Pairing.G1Point(uint256(0x2f04e3f715ea2c0c32f40e0c0cc190a26d55bd10a739e937a2c2df387e8d545f), uint256(0x00411418d8eafcfe60658d55e4c07a27dbcf4841966b8653591296f3432bfc69));
        vk.gamma_abc[92] = Pairing.G1Point(uint256(0x078ec9f23a8200e9771afa65d48c3612588d55fa8c7f4a82f418429ec258c962), uint256(0x230a024def2852100026de0d7ced6c18520cdd15ef92346493bc66ffe48c8df9));
        vk.gamma_abc[93] = Pairing.G1Point(uint256(0x0607230f3db7a8ff1c4a852c5429ed68dff18cae14352a575bf44e13cf010734), uint256(0x2516faad47d14dbd15d6759c930d18bf694496d5fcceeeb2e9e0f9d33268d9b3));
        vk.gamma_abc[94] = Pairing.G1Point(uint256(0x1ec73d6f2e097da4beaeacda549117318618f499d8cea3e4ad81ccf3058aad20), uint256(0x1b3d329043d03504d6088b1e19305da7eb73a58b6ac1e20f7adcd38efc49a72e));
        vk.gamma_abc[95] = Pairing.G1Point(uint256(0x0d6c8e6b96cadfb9e937f7f5e2dcdfd568ce51e557b6aa047bbbe8b58eb937ab), uint256(0x032d1b179026585810521a427b63db0fbd00637ee9e25f5c9ec12d67aad4e236));
        vk.gamma_abc[96] = Pairing.G1Point(uint256(0x06684e54985b1aa944b30c38a73868eea234d6612caaa5e6a9785db4bb7b652d), uint256(0x244a8ae133707065653fa3435ba41e57fbc6c39dca3065e01db4e1e9278889af));
        vk.gamma_abc[97] = Pairing.G1Point(uint256(0x0fe10b996a65d6d67c7b9e117c727e391a18045b879285164d25f4016baca4c2), uint256(0x08ee852c18563ae50fde7a4bf017946ff003873277a2e305f230f29fa20a3e97));
        vk.gamma_abc[98] = Pairing.G1Point(uint256(0x105dbd8e2832c9fc7cbf357488c8996b8162f8fef145a71bbc80dcf0415af0e9), uint256(0x2ef858b15468979ca4a8082942ae9a15cc370cb7e9c88a297b63b893a9fc0aac));
        vk.gamma_abc[99] = Pairing.G1Point(uint256(0x064731691d826c2ca8e986850db7db2413c5b34127e2461db6060c1b8ffe8276), uint256(0x143a9efe00d15bc7402f8ee8d730bb346104d168bff142e310c8f2dcc7e4e61f));
        vk.gamma_abc[100] = Pairing.G1Point(uint256(0x1967d69f7a0f82cd51fab03266cfcdca6e580d576e7fa48cc74c265c1b18361e), uint256(0x1bb354d4494b6036b567cf9ea7aa83602847ad4d5b9edf4290501edffef3931a));
        vk.gamma_abc[101] = Pairing.G1Point(uint256(0x089b444033c1132b4558170026c3ddea9b52edff544f112edc7b31a53dffe8fa), uint256(0x0da16267b83020c4064a0e106107931dccdfc99ec8dd10fd5446c280b98c973b));
        vk.gamma_abc[102] = Pairing.G1Point(uint256(0x006f73af72e9c09f5617d5c8088f5fd86c7c62f19c2b3757202f3b707a74d73f), uint256(0x03b13318971a977d737ee494d7f32fa7e0b7fbfd23073cf36715daae1a5083e1));
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
            Proof memory proof, uint[102] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](102);
        
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