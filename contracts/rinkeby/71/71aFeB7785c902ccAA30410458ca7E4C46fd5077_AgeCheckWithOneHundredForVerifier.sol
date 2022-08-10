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

contract AgeCheckWithOneHundredForVerifier {
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
        vk.alpha = Pairing.G1Point(uint256(0x1eef3201c0626877382f8ff0ff6058a20bc6088cf5afba11dba417654d086567), uint256(0x2b7721b01f16e8c91a28f1411fb4faee5b74f0c56cfbbe300750296a28f9ed25));
        vk.beta = Pairing.G2Point([uint256(0x214d2510599ca255daee2fd622375170244717684d1bb6d7d0679d8ab22f5912), uint256(0x1f54f85e3bd438d4b68fac16d0c949a55f3c8fb3dd05c3adc1a8a5a576229a80)], [uint256(0x266bbd020581c70b8bff62e64e586be60b914bcbecd1693bfa9a5fd38b681b1c), uint256(0x2b8af07adebbc01bf7c6639a587b27fa73c800dc4eb1e1b1c1fe50220b34c4ec)]);
        vk.gamma = Pairing.G2Point([uint256(0x0465888031ffb0db405dc66795c97b882ce89ce143c91c640c47eb6514db1340), uint256(0x2dc6b45f613a112797ed40a8d5a96fa5e10f20e61647b6e10a6e343553ede16b)], [uint256(0x0eb0650a2585f8abbb2403b21dbf56ea871a99593e2bfa5a2a4f5d590acbd62c), uint256(0x000d2354026be1f5ca93d29af2aefe6d0f5d772f14780c1153e1d19e39b34fc6)]);
        vk.delta = Pairing.G2Point([uint256(0x04ed5fea2063415f001772f69ba5371927737dad79711536288ee613555a38e2), uint256(0x2a4634d423afa6451df57860290687a720de8e6e85637b00b62bcc4ba1b413dd)], [uint256(0x1e7d88c68e705d7926e5de7e575153314d34beabfd39b7e06cbc170ad24f1150), uint256(0x0be8e0025299a5e91d6178edeb0f2b5aa810600b5586ff02b14ec65c1b52fd2c)]);
        vk.gamma_abc = new Pairing.G1Point[](103);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1ec6121e26e47922ccda2ef67c234bfb25e5b3091a13e2cb0be957eb1862d2e8), uint256(0x2b1ceff73efa462fc4672eaa25cbf31fe143b571fc37449ccb709b97524f096a));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x23041405a7a7a7204e6b606b5e98c8ea00e65cd114574c99521451031d257c5a), uint256(0x2fe9cd4ab039a11438a0a84033fee0c29cbb6f909940167c894781404f9fb944));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x261ce97e292a8ac6ff5befb4d2691b442a936f913d8c2af81fbf39161d04eed6), uint256(0x1ea82bbb0b5bae256e8538aff532693bd5676f0f25560bb3937a69960cf5cc62));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x302d23e419634afb91011baefc7c076563357a013570e793d8dfd69c82ebc1b6), uint256(0x03fa42b176f1734dfc5e9e53196993351ee0128793c623693e844a0be33dee39));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x21dc4ce489d72e4d302770cdeedbccbeda02546942eb84ca03166e6916c43209), uint256(0x2e45e04ff875de0f5c712627e8c54fe71bc72f83d063905f3af0c30b769cc9a8));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0c81e0d379cfd4cade0ab3742e1aa26ff51f9dbf0e289d3eeecd244450020700), uint256(0x20dc11e92b13240fe28ebfd44a2f60cae508343471045c9c88fec5f6056afd94));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1c7d1e980641e3023a1d3df56e52651ae4242c17254c1f7c718cf6905179999d), uint256(0x22dabdb3fea4a8709e836a7ba562611cb06dee067a0664e294881b53524ac3a2));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2f8eab2639585a452669da1859a995fe05f43a2cf0f147795f1fc5776b2dcdd9), uint256(0x0860f39db7c772b9d27e98dd0de2d82821f967aa285c958350eb50c2d5b162ad));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x27c2c90771b7d8bf399391d2e516e206ac0d4aba87c4a814428a2ca35e7c9edb), uint256(0x21820db24cd3efe8f6af38a2c2270d7d1d5bff1e3cbd2b8db15ad18faf6b7df1));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x07d01da48889b685e8303f0eff4194652b31844a5fe7b3c2de12237dfed34643), uint256(0x0fb899945c79a43fbfaa03c6950601554eb48cbfb0fb85344e423d4269d8e946));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x074c68a1ed73d4eec411892b9a2c1a92ad8e0c3227f59ac672dff38fe04bebb0), uint256(0x2a55c27dbdfb2a902fa6e733bb189a71ea8193a99e5b39f399e88e8e370492f7));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0d08498bffd79ba29f9c4c27850db3e91248749a907fed1004b61b83c4d47f80), uint256(0x15fad5f77f8675cb8f38e3845671c4943e98ecb1d3334aa88d9613680829c4aa));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x24b9482b906583f655adabe760b588dd631dd218a4b2f002b9937bc746fa5328), uint256(0x2e2444c052cec95e03e4af69633bcdfe56edd53f939057fa3608067e091678f6));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x0517906b65202ce040acd33efaafa657b7178e5ee9bacd5b6845f5dfc5ff32a1), uint256(0x22602bf6d4b29278ed79748f6bafb7c60a06123defcfcf8a5b942141f3b01b32));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1810a3c32715be9783f31f535c3d407dbbfd1c583f747de4e03daca371d38a2f), uint256(0x15433e64325afc6940e8c76c9c1b8e7f071f8a3cbca634d5d238cd76548faa96));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x26f20043473ae40e83c6356d8e49c1b89e480c9201d14d93497f8f2df0deffa6), uint256(0x0695731505bd9cd44aacc41d7de4e13dc5af4f13f87fd1091588631d752e2a37));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x0b0e81db55e3f19fcdca5c35fcb5c3d12c0afcae55fd06b368d73639bbac81ef), uint256(0x1a83cb09f622bdb16d4da0c8aa73249a2ffbf9d58648df3711416fa779f9d957));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x02a7aeb0d0a0b6819e92a5d6e747beb3e158483d000fa480816a2412dde46d57), uint256(0x2a9f333bf7c0c7a9dc00a1dae95bc5c0fd2ffc7c6e68975818ac1ae1b4197982));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x006dfc29e1600546a551f4c2a354fe1fbdb1432c64d0c48d3dbec08d94fcb99c), uint256(0x047a9b183e31a4ad1265c3c24bb68080dcd1adc9538971e7c536719340f6529b));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x12d91b1d87005d6cf291965b0fc94c8c1a67f9b99bac5c30ea12b912a615d589), uint256(0x07e47f3d48b229010b1d9b6ccc4b5bc9017846a9170b9cef2547195feb6eb941));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x20b55b366453746bce121334a3d124e48486448ad3f2bc3175304f5a72f21abd), uint256(0x190a02d03ea1999a22042d32b1f073d7e8d21892da9d60f21839e3d145995150));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x1394c1692c98368b6b9ce4c8f0dfd1eaeebde7f23a0d94a5fac1557b64530b5e), uint256(0x210ec0eed2aecf76396efb5968718325f27bc88b46e0ba152ec834379e9454d8));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x15c9dcd5cb3e728a42f462a607124b8839be8423ea7ef65791e8c4eb905fcdbe), uint256(0x12a0eb6c5197cf08cd2fc528dc14f3c002ac4b4efbb95ba90a7a1d53d0a08e3a));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x037d0ab7d4e66d5acd73e89255c22c9ae13e409a8ec8ed47c6c4a624aef67480), uint256(0x0fd688ee517961b8b6413860417f29581d6968c8c99ca95eaea6137dab7b79b5));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x21220744c0847a4ba260c4ffcdad7aa8dc4dfc70815ece44331a1f8edffd3ba8), uint256(0x1a3ed553239a8fff42e5de58436e838f9bb1958c6f89806032ea18d2201da7b6));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x213365b282a5a3df7abe499157335b755a86cddf8cdc1b193658ff12fdb41aef), uint256(0x0d1423a085edbd979539404cf97d46a2932395202c47ff32e33c26e10052d178));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x0bf0a934215209acdda2ca0c532eb4c37e02da34ea135f36bc506b5e98d16d8c), uint256(0x146845c9daf4947feeb2990976359421f0fbced4c227c95316bf05bc4aa671f2));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x0b6927e164acb0124078eaa1eb0a4206a317796fe460a72409b7c5ddbcc02b3f), uint256(0x16222c0c331eddb263091193d4abff06973ef41336cb2bd2460be84d8b16c996));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x0f59df1073f2fad7435147b093907c1ccd524be5317673e8eca8a8f82ea2ba38), uint256(0x235926eee555effa2fd97c73fba7458ecdfdaf5cf88d12b210e6db9e9a4ad6c9));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x27da751bee3b126eae91836247176f97f8bdfb536d1a31cb360aafd367c0cdde), uint256(0x2a7bf1ff9e0ee6cc81d44472fd9b747d5f8fdb25f47d2ba11054121f53ed2294));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x0abb4d08d72544baccb60602c00c3aac404374e18f89f03032cbc8d978b829a7), uint256(0x2f3994f86702e31a5d3da51c19ac941dcae2fa6c53840df4f6d9faa14e2d8546));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x08a5d261ed279da232e335fe6262d11d97b8813de2ec2273a19f6d18913d4348), uint256(0x1b27e573133c99c9799ef5defc43a0e9be77d56fd3dd8ce72bd19d2c080fa02e));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x2931b1d51f487dec7333e4161bece80eaf622eabe81f067dea9bd59f911f4c02), uint256(0x2b684c9d31e089b29c574f6394015717ef3aefe9e4e065a462a7e252fab8ce3c));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x2762c8684348177c5c12de0a1bd8e5449a09359500b0fb8b07cc212374977908), uint256(0x0010f51bb65479c712f66a537e1f3135c964993e98d07082fa2dc2c763c4639f));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x2cb10c34230a8da464b244007a772a9a7c3a75ab8a98b1160e961dccc46b6d5d), uint256(0x1e5249fcf8b27812572fc57a403b631c1e473340a0250e2340e9a2840e261559));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x2022efe6fcb5cb6262b0cc7e8a550e7133c28773af58292448b44075c7d76798), uint256(0x2f843bfe946ac1b270dc0c1a61203aad94917f271851038e708f79d8f3a3b731));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x203dd21720f0eb4c7d7d5f1e9bbd06ea1f6c78618a5144a84dabe398921669b2), uint256(0x0df5e4a2fd69c9f827fb0ad3b26dfe801ecda3f73ab21b8610a8afe96af896a3));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x2ed6e9b5525d72e0551674a4f753281616e0e48b2f6ea36f323b919109dbe54a), uint256(0x0db573da4a5053ace55c8ed621f570dbb323f1956ebc90fdbcd6fde1fc82ca59));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x155eeec90b385b347098525c87b8944a073f791b798d0362f174cf6f8e1e65dc), uint256(0x12a27a2e0e3281dcb494ca85bb298a566443da8df3277f5c9222a34944df9ed5));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x06e19a7a9945bac139fb67c8aca26020d031d7be62e7e83c183b3166f385533a), uint256(0x2d309fb3525f759dded88639923765959424cfb80687a159cf4b344ee6644ce0));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x036ab35a7ec5aaac916f2d2e84297275685985eaa8b8435f0929bc55d62aa3a5), uint256(0x0547d2d9bedd3118c7defb096923111e9108f22a7f79bd96951ec2eccfa28556));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x2de8d6f32a9a79a8ecdf0687d805eb1d175baefacb156900a1452ee22ba1227c), uint256(0x2c9417d7cd901018260c10f9cc7631394e009162a006c6adf619dfd1f215b1fa));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x2d993ea18d1bd1c25cc0ad780ebc007abf9f5d146d0eff3fd7373367c0e3a9b8), uint256(0x19c6da942a2df02ab5283c5ca881bb1c8bf2233f6261dc80d135db1b45157a52));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x21c663749dcbf8efa6714dcc1da4694f352c47db75dc835b350345dc5f4c2962), uint256(0x06390f79f9703b896af4621c1a5a7b99cad2f6702f2ff79299d9ab79d48f9a52));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x11e203465e7c64e68fdbe24be0f3edb7bdebf1a4d913d0d6ac5005da95d6c072), uint256(0x2eef12326f915d894d5dfaf08dae3e3ac202422e19940d110d7829e0084e851a));
        vk.gamma_abc[45] = Pairing.G1Point(uint256(0x2c7a8c52a8efa63f18603776b237efc5c154e31eb7b035ccb8a03536d2450ca9), uint256(0x2c171b7ff0faccb952ee140d9abca765fbe34b57926da443e642386fbcf1157a));
        vk.gamma_abc[46] = Pairing.G1Point(uint256(0x1ee2f4a3cfc073247c0e229691409f7f91d144d29ed09dd6b0f83f38b8401c19), uint256(0x2eae9aee969fd45ef2d4a1891b915222c52545a13f8bb7943d1b04ae2e84e46d));
        vk.gamma_abc[47] = Pairing.G1Point(uint256(0x04a21de38c12d09cf3eccc13b2ca9f7d4278feb8f5d3d71287374ff0b2e98f4d), uint256(0x1b80fe78c4c56c85ef0496af87231b0e8e33ee25d9b7c058c00b261c2f21efe3));
        vk.gamma_abc[48] = Pairing.G1Point(uint256(0x0c5418d05f97e6251bcfaa6f88ff3ec5a49cf90324e6f5ea277dc1b4d7f7e986), uint256(0x2894f3732900b7f40141a41c3d22eb75d82a520798e230b8fc47ec85521abf45));
        vk.gamma_abc[49] = Pairing.G1Point(uint256(0x0235238bd56dc22542e41d09110900d786d85d36883f06718b4baf199ced2f57), uint256(0x2bd85a1425a85ba9934eedcb58a4e18b5b497e4e8e9ef2a873476aa0cebb8e69));
        vk.gamma_abc[50] = Pairing.G1Point(uint256(0x2e873e840bf8266ce033e9f25e882fdf24c22427e7593af2affc96664b494917), uint256(0x035160f4f1faa092da50bcfee932a2a43ecdb49a1c16dc20e2cf0d8482c0c4ad));
        vk.gamma_abc[51] = Pairing.G1Point(uint256(0x1244ed8983a194d32ee02a179ec6b279677a908d34d13b5aa05b4d494f2ec639), uint256(0x14ddb754c12c0daa5ae8ceaba0709bcf3ba10f601ed107c7209aacaace686aee));
        vk.gamma_abc[52] = Pairing.G1Point(uint256(0x2efeac8183c186748f565b957ba1274f6c48515444e224ac7d502aedd87ccba1), uint256(0x2f5e1c8a4dbfe38559544537ce13d75ad2157837551ec04b3e0db4a5154b7141));
        vk.gamma_abc[53] = Pairing.G1Point(uint256(0x0f0135a0321c1b4cc1ce3a0e95144e7b38f7b0c7e5b87565ce7ad6d7245eddbc), uint256(0x25c47a0c70428136962831d4763327b2c8204ce474a9b78b3872c3bfd1d03fb6));
        vk.gamma_abc[54] = Pairing.G1Point(uint256(0x1f83e68e1ffa2bbbf08ace2cecc5fd9ec6736bf8fde6b01c3f61f4716118c266), uint256(0x020ede196bb79c620789203ad5b75de8199518abef888ee65384d247e9a693d3));
        vk.gamma_abc[55] = Pairing.G1Point(uint256(0x092030413f249d6eaff4481911761eb375b642e87973a050da3c6e67b19220cf), uint256(0x1e18a06eb7812096b3386456ce05979266054189750e948d56f3e6e6550c075b));
        vk.gamma_abc[56] = Pairing.G1Point(uint256(0x00e2f8d8f701737a56a5e3ee620b23c1ba2e29dfda7560e6b347b46ddb3f474c), uint256(0x258aae0ca8b0c7b8e8564f090e437ed9c9d87af6e53f5efaa17abb9d4de5d4e0));
        vk.gamma_abc[57] = Pairing.G1Point(uint256(0x063a63e8548027cb618a336cc64a31927a03ebd9c83dbdc7d7fe408c36457dfc), uint256(0x0b75a0a644cfad93ab66c180930e18089729aaff2bb2c8e068743c821dea1c12));
        vk.gamma_abc[58] = Pairing.G1Point(uint256(0x181c3a8fb9db5c882575838a2ad2ae756fb38deee60ac4c76fec4ce22775830a), uint256(0x19530884399a520b906d723346919592b944aa80dd9ceeb815c5e6af86755393));
        vk.gamma_abc[59] = Pairing.G1Point(uint256(0x0543ee920d50760fb57eef0541d59a624c37e827cf9e65a2c6c0eae15de85b99), uint256(0x1bc587b2ee90e3b8a6d48c40737763e8c4d6b4f6b0559e638b89285ca788b87b));
        vk.gamma_abc[60] = Pairing.G1Point(uint256(0x2c438a421b9c852da3b55bcf5c96ff63ab3d700b8e17bcaa4c93fda73126922d), uint256(0x00c2b4880eca6f76eef763578d79883a832c81652c872e4cede629980563a8de));
        vk.gamma_abc[61] = Pairing.G1Point(uint256(0x1e7e04b1c25c4eb47d4ce28756dce6dd9393d830ffd08630ec544085d7e52f8a), uint256(0x1fcc3d26792a64e2cf5597b48df5a526f3c898d22d8e5359296fbf383a8f8ffb));
        vk.gamma_abc[62] = Pairing.G1Point(uint256(0x17eab364ca704342141a01dab2652e7fa8e26cd21cfc1992048bb52b8de0238c), uint256(0x2cfbab535703e24bb24d2a6f920cda4d93cfa05f79f3f553682693478493a747));
        vk.gamma_abc[63] = Pairing.G1Point(uint256(0x0c2c9480218fc10cc659eaf0191023df3c359f2b14d341e24fb6f6fcd0b28b17), uint256(0x0da06c8d39feca9ac3bf0285a6ef4e36607de6b8c1517f0f6a7b126d6db25535));
        vk.gamma_abc[64] = Pairing.G1Point(uint256(0x1135cd64022caeb02d07a165453047b1c4c9e3cf12c949b9e40040880fb52aae), uint256(0x1ec3178d9471ea91675d5d3769ffa5113c190566bac6313a657d5cdda93ed777));
        vk.gamma_abc[65] = Pairing.G1Point(uint256(0x2ca7e772deb1c579d9e33a9cf4d21e94bf4d5e107bb148e1e0dcf3910e192fb4), uint256(0x0e861643e15283d568b6560f321b33e4549870a2468691a8fba4729bc4bd08f8));
        vk.gamma_abc[66] = Pairing.G1Point(uint256(0x097c6c981acaa4560b5f1c7fa6d08b90a8e947ed6d524a43d0eb5928ada6ec07), uint256(0x1a74656fdfd8559685533a550c0c737a669653ae42f7a39eee2433101e4a426c));
        vk.gamma_abc[67] = Pairing.G1Point(uint256(0x18349acf4d9f7657e3b32edb47e3288bd9f220869150071ac5c8129872bdc520), uint256(0x22d4c93b958d3b59e53f61df2a1d30e7ff428dbc73c297ce8b6c6ab239d9d486));
        vk.gamma_abc[68] = Pairing.G1Point(uint256(0x0280bf10a90f2850f13bb157c51c9e5566fa215571e772e34f4188509a0dde34), uint256(0x0a42911820df685685fd09794b229b0882a0a88a674be7a268824a83fd6adf1e));
        vk.gamma_abc[69] = Pairing.G1Point(uint256(0x05575f8e1462d1fd1f4e3d372dfb30b0631cb70ac7e44002166c14352d00313e), uint256(0x14e6f8557bc7886916a9408667e5a1383dea0d4f7870b16f6e75afa0eb8d49e3));
        vk.gamma_abc[70] = Pairing.G1Point(uint256(0x03321fcc2f8b1dc2046870328e873b999d80db9ab3c0ae3bca5a2f245632388b), uint256(0x136cac4f671eb5cf4393892f3c33cfb611f2ef5df7c559a61b4fc88d4e5c63ff));
        vk.gamma_abc[71] = Pairing.G1Point(uint256(0x2e974f6355d0b553a8cc4be972af7bd0aed11ac07877c459c6e0acd38e29b82b), uint256(0x25c0fd5bd9a713902b7a2f71e9c1ac44e9f31101f10052f9c401fdf001ce8311));
        vk.gamma_abc[72] = Pairing.G1Point(uint256(0x1fb2edc37120f8b804c0862c6ef2d1419f1c5cdc52521dd51739fbf298c959b2), uint256(0x05f88eab672b80b881075697b56589cc625798888f0a147a9c8c6f9f017cb00b));
        vk.gamma_abc[73] = Pairing.G1Point(uint256(0x2af7e4931b37edcb7c83a1a5d28c7567f390c539a4ab641e0a601117a031a298), uint256(0x1e6ca8518264571e4712a911cf56e3e34d7eae79e411d0d9ea1625a15f1076c2));
        vk.gamma_abc[74] = Pairing.G1Point(uint256(0x2a68e449de6e6a5c610ecc7cba674ef0f9da9df036d27ab171875f5c3a53b389), uint256(0x027d691c5a47a1b42f1901ec8f4aef551469b5e01ab486bf0f5b33b6d40736b6));
        vk.gamma_abc[75] = Pairing.G1Point(uint256(0x188ebdbd94b03be4e896035dd4185e72e3218ac14f9e7c0cb644f044c075e165), uint256(0x0590d002a9b22342ed7f77580de6309e08b20f75d724b7315dbccb1caeebf7c1));
        vk.gamma_abc[76] = Pairing.G1Point(uint256(0x022aeb172310e366b54e75aa41f857af82e505e5fea0927da7567d612cc575a1), uint256(0x01a3ed9266c51eb772a17be2abc7506ff47c51896168a155c8df22dff162642f));
        vk.gamma_abc[77] = Pairing.G1Point(uint256(0x08696aa2054b909f85369b388f350e3df9e6c58c0f4f33d2f1dc87089cd9d9af), uint256(0x10a50b9a4a4c0aafcb0cbf30d8b8a8bfb0d8a09d21abea7f0c31940fbb582cf2));
        vk.gamma_abc[78] = Pairing.G1Point(uint256(0x2f1a0f0139c0fa3656779241c44b6e9ae2f559d0e5841777383dc1eaa0946393), uint256(0x1fdeeaf3a4aca542ac858a0680ca098e1333154cb4aeee862c27d5e4d5bbd7a6));
        vk.gamma_abc[79] = Pairing.G1Point(uint256(0x16475d7245a3b8c9a3560520c64ac8e22011b408538e7b6eb232f394de8d73ac), uint256(0x0186d04e957f8cb980341703ea331c266af1ce3129b08cb70623db2477000fd9));
        vk.gamma_abc[80] = Pairing.G1Point(uint256(0x00e29163f6d904a1d22212257deb0bdc6783b8971f7d61698126a2f5ea8a6923), uint256(0x2ffb97308fa14562483922e1d7635720bc28d0876a02badfcb6873ab97861404));
        vk.gamma_abc[81] = Pairing.G1Point(uint256(0x0280412240d20fe9cf961257ad21f2fdb6feffd2b1c868305b952c3aab2790b5), uint256(0x00ab6039cea15e8fa8fffbbff6e25aa37c9bd2d06222e10946384cec1e7e3ffc));
        vk.gamma_abc[82] = Pairing.G1Point(uint256(0x0bfa1ebdf745d30949bf22a5ca196963e86850b091cbdb9ad9f1b5ff25c6ffcb), uint256(0x25171dfc5b4c4e6027f9577f42f3fb4d51f2c5d352bf92437cc031b99001a370));
        vk.gamma_abc[83] = Pairing.G1Point(uint256(0x00f7c7e08a728678806795ab4e5c754cc79330cb44f97c7a544981a75de48f38), uint256(0x1662051430b7492959d7c68b530931a4af083046c89bc55b5f521b82c1366a22));
        vk.gamma_abc[84] = Pairing.G1Point(uint256(0x03a30eecf853f5ab08c387f315f78662f98766491f4b1032496a3ed94bbcde91), uint256(0x04b2d9ebf6abdb84f31d43b9013f82c46cb54cf4b664fef06bacc7b329912fcf));
        vk.gamma_abc[85] = Pairing.G1Point(uint256(0x1d8a08fce5a35ee007014551fe4ea423e5fbda51acb1dc918dae599654dc197c), uint256(0x130da03d98d387e36d3320c54451a3b9c909d739a5d08c754cd4b1bc14ea1f08));
        vk.gamma_abc[86] = Pairing.G1Point(uint256(0x090fdf855bb809ae4977a9627bf44a0e68067069cddaa8a52673b0b6ed49ec26), uint256(0x1cd384b90a43f0b8c6ee78c3a3c9c38842df968a51d2178b22e4b2905e223c49));
        vk.gamma_abc[87] = Pairing.G1Point(uint256(0x0ef13fd1e3549aea86a85fbf8a49025dcfa6f0f92fac4c462013b8ce402b08bf), uint256(0x3022ffaa2385a35dbf5f20c2f0f47d6232c1c64f6e01f21bdc476cc14c8244ae));
        vk.gamma_abc[88] = Pairing.G1Point(uint256(0x15c2d64ad133445a8b3fae6738f0b7631778c1dd8f00ca4808ac45f07275f229), uint256(0x2179c8e131bb9ee8734dfc2b7a655c21cd78394f3bf599f65abd9497fe373298));
        vk.gamma_abc[89] = Pairing.G1Point(uint256(0x099c6e228fa56ea92496aa86d43a82a25d8f3ca37d83ef96ab0d54df641ebc4b), uint256(0x1db5c1d05e92f0837fcb3ce87cdc9978b109d8f7ecb86de0cec059687e426be1));
        vk.gamma_abc[90] = Pairing.G1Point(uint256(0x287733184e08b9fd80d696311f44e8fc2394b27565c49d7e3b733ee9ce63416a), uint256(0x14f148b2b01f891e7ac640c2154b363f3172b8d2b678bcaa10bc2bb4d2d43111));
        vk.gamma_abc[91] = Pairing.G1Point(uint256(0x1df07936e76c12672812141d07f79745d58ddb06db9e2aba11593bdc63029fc1), uint256(0x00d6ab2021d5bfb1fde43ce87543a3f4d12944d423392aa3b1b64dc3b9cb9b5f));
        vk.gamma_abc[92] = Pairing.G1Point(uint256(0x09bfb22a01ebdaed7b99c67bb55bf5b17ddb4a420739d9e581400fe30c524107), uint256(0x04af7593d94e559467d38cbf1a888cc4f9b7644c275f330863c41a4f3fbf1ff4));
        vk.gamma_abc[93] = Pairing.G1Point(uint256(0x07df88b45c40dc0c60fe1694dc8fc6c12d0a715e089b52d636a4ae8cf72672b6), uint256(0x184d3d683f7cc1280ef2b2a7745ff1bed33d48fa0c108f8684491a330a2c1168));
        vk.gamma_abc[94] = Pairing.G1Point(uint256(0x1efd948183811a06da3ecc2e9a84d2e272337dc3e2d8a0d5c97784d3a5296c53), uint256(0x1e94e487f81e9c1331ab609f6a89b00a6e4f9f0a54d35fc06145b0efc66f0d70));
        vk.gamma_abc[95] = Pairing.G1Point(uint256(0x27a334535fd01c8f02b6d771d9ae671e1099bd67714e59816be76844e7a9ce2b), uint256(0x0a49d1aea4ef952a3ea204fea349161c4f49b366fe823e7f8e8493705df55b52));
        vk.gamma_abc[96] = Pairing.G1Point(uint256(0x2cd4039c31e2a9a59621087e9c2ff35d2b294e755fed20a30a02164e6c48e780), uint256(0x0f1c375df59b43767f23cecec94d7193dce0aa45094d09883e06500b0577d2df));
        vk.gamma_abc[97] = Pairing.G1Point(uint256(0x258aab513c615eb3e65596b2ca788a0479938ff7acc308a29acc6da483f41612), uint256(0x16a78c3084c1d96c4a08639bc2055227d2ecd6dc04103e72959361f047bb7672));
        vk.gamma_abc[98] = Pairing.G1Point(uint256(0x0355df2d59df1fb939bc8f3ac06914b27b6656001604146ac38c13c748595021), uint256(0x034913169589e7d469ccef60d220ac83ad420660e2d8b2431979f323e1f88fe6));
        vk.gamma_abc[99] = Pairing.G1Point(uint256(0x13652cd3e3c31ef93ad4418c877555fa88a3cc9aae5f5c849b595a9945b7d85c), uint256(0x114d5cac2f9fd2906118b55a63eac764534ed8b810488a11670b5f615e7e6b83));
        vk.gamma_abc[100] = Pairing.G1Point(uint256(0x1cd52d2753399c9e192983df7f9ad46434c17de72784b912fd3d85a9b12f2afb), uint256(0x1e834c537925f29952e8b79d8a4c617d81a8569c7893bbf8e289cb57be671210));
        vk.gamma_abc[101] = Pairing.G1Point(uint256(0x18c8c67ea8a22c6e268fe3e64319850b13ef998a44e4d3dbeec4dc25919ba9d9), uint256(0x176d7efd8325e65b9413b726cc0b4b0da4f0edb8834e647b2acade6389d18910));
        vk.gamma_abc[102] = Pairing.G1Point(uint256(0x15b915dc8bb19ab333e74d22adebaa3ec5fbbc0bd25a5905a5505d99138914f4), uint256(0x26b7a476cab36c8ea7fcd51f217d5b7f349ceb77190283a6080efa13c951c205));
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