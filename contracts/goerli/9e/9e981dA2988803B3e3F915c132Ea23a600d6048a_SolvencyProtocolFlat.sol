/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;



library PairingFlat {
    
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }

    struct VerifyingKey {
        G1Point alpha1;
        G2Point beta2;
        G2Point gamma2;
        G2Point delta2;
        G1Point[] IC;
    }
    
    struct Proof {
        PairingFlat.G1Point A;
        PairingFlat.G2Point B;
        PairingFlat.G1Point C;
    }

    struct PublicInputs {
        uint[] input;
    }
  

    struct PublishedProof {
        Proof proof;
        PublicInputs publicInputs;
        bool verificationOutcome;
        uint timestamp;
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

library VerifyingKeyAFlat {

    function IC_A() public pure returns (PairingFlat.G1Point[] memory) {
        // returns first half of the verifying key 

        PairingFlat.G1Point[] memory IC = new PairingFlat.G1Point[](122);
      
    IC[0] = PairingFlat.G1Point(
        0x111ff64aaaf55756601c5054d7bbd9e76c07ad36552426a6164b9a55a0ebf0ba,
        0x0dba58fb33aa66328e15c8476f1c57dc34001763f5bc243532896502cafe1786
    );

    IC[1] = PairingFlat.G1Point(
        0x13e13e366d41173b038936be3acc5aa80053203c20ac086e60a1cc81a4f5f8d4,
        0x2323e09694fd4aead2a4e696693c8d55fa2f96a12e6d6fba8f04b446c154dac4
    );

    IC[2] = PairingFlat.G1Point(
        0x2e124ca60263a11e98e3af18e1aa6ebf899e51b0826f249f263aa9047d95dcd1,
        0x232c711298a700c83b78dd717fd2f9f49fd8f0bcc14264ca2800195c675c31d1
    );

    IC[3] = PairingFlat.G1Point(
        0x1868cb6d386f9a906572f79ecfcff868efc56b36c1c7f00b8d998668aa7b553e,
        0x0f5c6ae132f0a51db05533d3df74de6fe211e10f33a36cbb64b5d5707c98e604
    );

    IC[4] = PairingFlat.G1Point(
        0x00bf07d56094e6aad69b67d3a671cd24ab0b3af25c8d2fed2e5181eeb14b84eb,
        0x0c80b8c94b35d32ff62e13c648b02ad1010e2c7e648dcfd9369550ab57b65cce
    );

    IC[5] = PairingFlat.G1Point(
        0x004e1db3c2660cad255c9054e38ae97a2626cbe15232329659fa39ff2c0ecb62,
        0x144002ebe88e67c345c3aa56a82d483aa0f97d0c915dc817605a231dc7d9d018
    );

    IC[6] = PairingFlat.G1Point(
        0x2fe9f156a765b021ccaec0e64f77ae817cd3fa81ab9b891e98321d64f5c6616b,
        0x1f95e1c8715f0061f629de644f9d9f7a083327e1c2b59f8fc52e8b7c5fb4f091
    );

    IC[7] = PairingFlat.G1Point(
        0x102ef65b9d4c7c430db14a328c0d703a753aeb3db8dfe0770150ba0e47c66244,
        0x27dab33077465c38d512b86a0dd31513fc683aea3474ee48acfefb275abd24c3
    );

    IC[8] = PairingFlat.G1Point(
        0x088fbb6d07b3d690cfd81861cc4fb205e6abdda69ff012d5319a18864e66b143,
        0x04f836d0637c909ab262114053300fe21de59357c22996d07af1f14e08a33576
    );

    IC[9] = PairingFlat.G1Point(
        0x1036808c70516b6ff4177bc49bd14738bd7fb3fe6eff1e5625cd4bf69cbc8372,
        0x235ff4bf5aa10efc17e9cf78a3f943ea2962741debee0eead2c22d8e191f6299
    );

    IC[10] = PairingFlat.G1Point(
        0x2a4e8868390b380f15537845744743c011cc6c67d2bdf285596be5503c3c5f8a,
        0x2e99cd60d54e3b81992a07c50eea3dd42d6821d5429857a6c5d50469e97dc8ff
    );

    IC[11] = PairingFlat.G1Point(
        0x2cc824d19020470a01690825c5754d84d8cd124c515cca05d5b070d62abcc13a,
        0x1ab42947b7ab4d37a0ea1a48a1ab9e7474b20f1afecd7b9fed0b238a9a5325b3
    );

    IC[12] = PairingFlat.G1Point(
        0x0f455aa25fb88754ac63c6e28aa41182f2cde2787916e21d7fc36883b7acf3bd,
        0x208def736cceb29c6331c0fe595f5f39e36ceee63099503cad6dd7fd0cf4c517
    );

    IC[13] = PairingFlat.G1Point(
        0x0ae0f1d7eb04a4f9c357201faa6e87de92b5bfc686714d38f849da66673ea8ad,
        0x2ffa32ac2d9c09a2667325c805992331d46a399274c35000c161eef7c8be1bf6
    );

    IC[14] = PairingFlat.G1Point(
        0x25f2a27c229ec31dfc95b72d3a07b65f2fc8cc886cb22351e35ad18e0bac7497,
        0x197d133fb39e337d3cc99f2a58b7facc7191119e8cd64654f498e1e601657a9a
    );

    IC[15] = PairingFlat.G1Point(
        0x0129a7bcb6518beb121a3baaefb3499990ed35a0915befe238e4a2c0451c0f63,
        0x13e66ca29474ca6daf5604b711fea56e450306d3b6c7693cc9a8f6b58d48c0f4
    );

    IC[16] = PairingFlat.G1Point(
        0x27ae13572769b549b01fdaeea1ff5f10194a2f65d71592da0d9dc630e2f5464c,
        0x29e756a50267ea5fc2f20572d456b9d5e499e3c5409e5bc1fe36a4db7f257254
    );

    IC[17] = PairingFlat.G1Point(
        0x0d2e7b8dad1548eac8f9d8e3828298dbe9cc55100721fa806ca4d7b295704e56,
        0x18a229161cb27f8d3e0edbeb40557f33db16e2c08a25bc539126064ccf169081
    );

    IC[18] = PairingFlat.G1Point(
        0x0df6d911df400a9ef494df92e9ab709fdbebe56e8b78a2355e0270bab8cd58f0,
        0x149f856591ccd96843302957a9e06d441ac199e4a63c0e11c6e378e866a001ae
    );

    IC[19] = PairingFlat.G1Point(
        0x0c7a8eba0927779c456313e96aa6939cd7635fc131ba01d973e00798470032a3,
        0x20e8c21a18ad99abbedab8625134e8dfc0df221921c6935d35c8ccd44e9564d2
    );

    IC[20] = PairingFlat.G1Point(
        0x0bdcb05ad16ace80a664a3755df9d5b439a6d613dffbb37b34a6665694792ed7,
        0x0a72504bf98dd14148c3209af66f7b8a3c263a4e58fb38ba4e1090c0236b9cfd
    );

    IC[21] = PairingFlat.G1Point(
        0x0e72e8715be3fe010a7fc66845fda2ee3fd3d3355b756d80adc55d2f06aa784a,
        0x158381d84678239e3c954c5e56670bf7f63c74f280d6ef7cdac8a8d5f33adaac
    );

    IC[22] = PairingFlat.G1Point(
        0x1e19b11b41e29cedf0c1b2220a5ae60ec214b8c69c8a28d7d348f8988be32983,
        0x115ca2ec0da9c69a9ee67918c7ab8d9e9129ef6b636cf853b9b2e47801400707
    );

    IC[23] = PairingFlat.G1Point(
        0x2321574dfa0649a133ff7733fdb7caf8e7f06490684e508c84f585ebfe40f53f,
        0x2f025952f108439165f3867a6cb04b2100de3a5dbb65d60263ae7fcd322c8619
    );

    IC[24] = PairingFlat.G1Point(
        0x2e876e6d551c80f4bb340366da178aafb1ec7ced5d7dbb6dadd367fb8efa8d1e,
        0x0c1176d34d203102b2929cf3333977dca17a0df77b908679a14dc2f35a64e460
    );

    IC[25] = PairingFlat.G1Point(
        0x1488cc7326ac65381662517c38a82a327055eb81986136ee33351666c6bdfd83,
        0x1c28ccfa9fe0f5024df4a46407d8741afe6f78f524e0e75b2c996bdd9d5e3380
    );

    IC[26] = PairingFlat.G1Point(
        0x1ee760c519f4ca7647416b3c7e24fd5068a33b017fcf67042b4c8526ee1baaa3,
        0x09d88f724c5f3eff30d54c14a4cd4f70be377ca53ef7aa3b5011eb6ed2307f2e
    );

    IC[27] = PairingFlat.G1Point(
        0x27f9aa1f0844c381e4cdd2c24d14f1f12e35a1176f5aa6bea3e8101d132d5026,
        0x0265e8211382f573e31023a67159a29b1972ad5c8bc2bd85f812cbaf0a07c31d
    );

    IC[28] = PairingFlat.G1Point(
        0x04c9a5b5c92a6f2c1753bf672b9c597a00b6bbe4eebd3010dadde587e42bdcf5,
        0x2377702e4412184720f6fc8ae04983ba97a2d792b1a50b6d756a4dec0c70fde3
    );

    IC[29] = PairingFlat.G1Point(
        0x201754e972301d4bd357826e7631f3258783fe53265a51cf1f22f57a6339f183,
        0x0b475a56c21a8b45f4c687183a8d22bc8a3fa021be2487e92abf6512d273fdec
    );

    IC[30] = PairingFlat.G1Point(
        0x1689efd6f431ca2ef3e150cc8f9a13527d69ae6ea0eab32e59511e6d9d2eca07,
        0x123dc24fa9c31b5f5e3c8f1557c754a8698f6ce3a647a024bca48940dec9d0f4
    );

    IC[31] = PairingFlat.G1Point(
        0x03c6380d8bfb2a99e41585888adb95f1f4ef70c54988e989f58a0c1661b3525b,
        0x2c615c1a9b1dadcbcfd0b535f2a8d2df2510c3b5d450b9ea69c378b1a521fe60
    );

    IC[32] = PairingFlat.G1Point(
        0x0e3cce4c88de2a6a943e0d1125cfb00d53fa89751bbde5c819fd50da5d144b66,
        0x25d35ebb06adc00f878edc7ce88eeffdf1c58ed64723086fd52f71fff4e50c7e
    );

    IC[33] = PairingFlat.G1Point(
        0x08744e777d28fc8e0c6d9028a61d6c358677c74b38b270523b39ffc30adbd51a,
        0x2212950009ea2f9b9a822c080defc1bae913ff49663c6efaf64b7caeae5e9d62
    );

    IC[34] = PairingFlat.G1Point(
        0x174e3c4111fd23cfca2138d21860ea5bab918645ca7c1abdd583360b388805f9,
        0x1081a26af63fa9a92bb300653537c6a8ad83303c20181469440f65d9dcab6342
    );

    IC[35] = PairingFlat.G1Point(
        0x21d8a9de182a0480c4ad0751624b54b01af6d54ce999d02fc5d7e5c6a4c8308c,
        0x047be886d30109835440f107e4bcc44eb6e4f093712537e19faa28c6b0066a67
    );

    IC[36] = PairingFlat.G1Point(
        0x1c049a728360caa8af92a0441a8fea0d33887e2e60630eb3ff9892fa1de4a268,
        0x20175918bf23a55cb239135850af0d56322e7f64c09a8fd521e981e3c9294965
    );

    IC[37] = PairingFlat.G1Point(
        0x1873ddc51f65aece793c19ba26fdb84c8e43e52bf4961cd16df102761ee7b244,
        0x250526e2b7954f23b997617215e1d9524f412d619e0d26163dff61043e4a62c5
    );

    IC[38] = PairingFlat.G1Point(
        0x002be6952e175a976fc0c68a7548ecccd044342de512b83b5f30d6fb92533149,
        0x23e98997e198d7c0cceeedb8ab3e910c5a881574cfdc1bff4653e22691014e14
    );

    IC[39] = PairingFlat.G1Point(
        0x26e32f2e0093037b2f72d6d672678cf116805f19447c9ca98175f3ee4d0cdf25,
        0x22e198c51f8db73324937079e297d1992ffa0d571f25d448c453b2a2a8ddc561
    );

    IC[40] = PairingFlat.G1Point(
        0x1912236730023d86bb7860e18fcbaf0937ec315f6b807653360a7e13ecac3a87,
        0x14a3acb8656242d5e4273c727a137509082507a57d042187d936bb75cdef8dc8
    );

    IC[41] = PairingFlat.G1Point(
        0x0259f4d450b7c4055a16c2286ad089721697c287af184b230647476aabb002fa,
        0x1834e403015a29a60975f271e3af36ed89c0f4d196b86492ca02a2ae823bd0e4
    );

    IC[42] = PairingFlat.G1Point(
        0x1ea179a340a843edbc4ab309198ef7e4d05b5027911a3eeffd4e3f3b91373195,
        0x29b99a48a27e443bf8a58a506ed467919db5929355df416159b7207351609e4c
    );

    IC[43] = PairingFlat.G1Point(
        0x22387fd2d23b818e108a115095f36802209da3dc1a07f9a4d2f9810a6135e8c9,
        0x0f19044c3c5906fae01ea5ee6a2eaa6f7e75872d827b67c0f4efa5dea7bb41f2
    );

    IC[44] = PairingFlat.G1Point(
        0x13bf19cfa4a85d9a6903b0884a79d353b47b7d1419c1919f7f66ce6e980d106b,
        0x24496e8e5dfb7c1fb8c2a3e607a789723eb204067b829a5bfd48cce52e7716e0
    );

    IC[45] = PairingFlat.G1Point(
        0x27b4462eade6c98235df6e71bb5059a231702708611d737efe1dad23d1383b83,
        0x2676e94da8dad75e9927139c05130bd0b07d2b15eb7d0f7570c240f0a476277e
    );

    IC[46] = PairingFlat.G1Point(
        0x2faf4c14f1b87999de622009cff720ca770d186d4e67dfcb12c4cc69c0f08208,
        0x07b44f189abb45e59e7be4ad06c94486dd62001ab38428ec66002a2d63419693
    );

    IC[47] = PairingFlat.G1Point(
        0x0643d0288c3648f26cc47e34ba4e0fd236480a38741508703beebcad1dcf955a,
        0x08373ca4441d8199a11c193d3221d58832df7c67702377fdfd19dd35db35a844
    );

    IC[48] = PairingFlat.G1Point(
        0x2e6af8b1ad0c889ca0ce26af01a01bc28b95b652b6526172c1f2f326d14884f7,
        0x0a18ecbfaef718d4a622bdc9c6e3749c5b76540b6bb3356d8d0cf502313613c9
    );

    IC[49] = PairingFlat.G1Point(
        0x07c6381aad06f8162787054cb55d5719d6c10707886b5cf973db90d9f688f592,
        0x21931c9c9551b3831634d6e032d8858e61e56cad191750f19d4558f8501a8789
    );

    IC[50] = PairingFlat.G1Point(
        0x0a3605e756baab502f1ea2a97d81ee053a6b466739622870a156a28a2da7f3f1,
        0x15f3cb5bd1615e8c0ef89f1c21fe4d3a3421e30ba4a30a036efdd9631d8a044e
    );

    IC[51] = PairingFlat.G1Point(
        0x104e29883151a9d39a5da1247d00f1dff651e511802f59392aa6534ed27433ed,
        0x072aec1ddf9b7ebc54f30aed9f1271672dd1ad615cccffbe5d878e3e1cd8a5e8
    );

    IC[52] = PairingFlat.G1Point(
        0x30442189237367e86a4f0fe534e246dbe4b3891f3a1784fc5201764c249fa3be,
        0x0d37335be17e979e3021b9938e272c1158b4c80255606ae5cbbf60d4e6e1b1ea
    );

    IC[53] = PairingFlat.G1Point(
        0x2622f3379d5c4bf19d180dbcbf775a7477454707457aac00c51a4027e1ab6b51,
        0x10530e2378c08016f6e645a3d500a38bb1fa3dcc647523b2a7ad652168194595
    );

    IC[54] = PairingFlat.G1Point(
        0x19984f2a45d28198b7716b26ccce5a413d74555acf161f06ee0de486e23db557,
        0x21e94ffc9e0aea80d722fd759fd08fd52ee89b8d75d6803dd97f887f26320ddf
    );

    IC[55] = PairingFlat.G1Point(
        0x1d97360bde955833731155d66cb374d0c154485753b0736a841235490d316651,
        0x0888b32349c4eb7b83edbd47ec7c5123e4cc0990cd8d9343618f140d37705d44
    );

    IC[56] = PairingFlat.G1Point(
        0x01fd037ff38f1dbb16ce2d22083e40959ee5f78f29260ebd1b9c8b6bc9a7f491,
        0x1869297fe893d4bb87f59f59af68b972513060c30c1d6337527714983df00321
    );

    IC[57] = PairingFlat.G1Point(
        0x0d3b2f51c4f37fb2723384992b41c7fba13424d2d63101bbbfe947b89dfe0f82,
        0x1f40b7446e3ce158e1b5b1653191ebae102bd3c86168938638dc2331df9d33de
    );

    IC[58] = PairingFlat.G1Point(
        0x0fd85215a821e867aaec087be9f6a60809b4c7a6808d16282c2aa04b496b36a0,
        0x290a2e91914a3380e049ec748d25572dd788e8ad05a1d7307b78b756934ed6b7
    );

    IC[59] = PairingFlat.G1Point(
        0x14f7a9c7a488b2599b7ce22c55aae3e5100ce92577faf9824d6b26e6928c82e7,
        0x19828cf0dc644a43bc5a6a712016c0070c3eb88323377ae99da6fa1c5af87e76
    );

    IC[60] = PairingFlat.G1Point(
        0x0155415d42548f8f937e08e1f882a71c7d0aef83fd5f256a7685cfac84918f4a,
        0x09c48a5aa7bc35fa90b397ada611bc3adfe5eef93fbfe4c47cbf7b5dff34ac85
    );

    IC[61] = PairingFlat.G1Point(
        0x0864e56b2bc499aaba10e1b08f1e7fa1b626825e755e2290ed1b01ae41500cfa,
        0x03ba6e39a8aa959a711a0ae54ab51a57db75c4f624e9b6dfa3e24679cbfbf104
    );

    IC[62] = PairingFlat.G1Point(
        0x060347d1be92fd5327da32dc22e8294942f09782e4b9891e85b98f55e2ac822d,
        0x242d9c283c261524a53d665d6c79031edde466ccded4d453e02e5d02e0218963
    );

    IC[63] = PairingFlat.G1Point(
        0x24f12edd4a1fbf8c413ca2c2f96d582dd523edb018aa4ca0558092a63c668286,
        0x28ec72cd9136a94e02c29b9b0020ec1b3a1d899e325120509c9862e980142664
    );

    IC[64] = PairingFlat.G1Point(
        0x208745638ea16523da49a1d8829cb69f7693072d63247b7db21c4bae0e55ade0,
        0x0a89c52e8f81ecf7ebecf5bff8680bd3bc741bc614ccbeaa6f8a13f5db7fb087
    );

    IC[65] = PairingFlat.G1Point(
        0x16bb6439111ce12ea69fe8e0bf8b8b198833e59f877c69e5bc592fdd45a4530f,
        0x0f13c619fcca4409d8e64b112a9ba2ded8720299aff3cb63868117b9f5385c12
    );

    IC[66] = PairingFlat.G1Point(
        0x12408b8523f80f54017f2a536cd2e43a1e3ea21a0dd89f9be14f0469895bcc62,
        0x0086f8f11c1284b67c584b7a57ad12dd92ab583277e757dd979c24b714b740d3
    );

    IC[67] = PairingFlat.G1Point(
        0x08c73d52a67fc7b33acc56ccf272688f2948baa430f418e96c4ae42f444a1a56,
        0x17fbbaabbc8a22286abb30af39044aae80983e2e58d3281292f3fa9382aa82a0
    );

    IC[68] = PairingFlat.G1Point(
        0x2c7d578f857eb85e772d6b3f2df54bb2eddf40284ada04a295adeba1c74bd3ee,
        0x088fe57751d34146afbd55f7f7884f9e2be91c481934db642c7edf6aa262ba34
    );

    IC[69] = PairingFlat.G1Point(
        0x04908b079d0891ab0c0f451a86af8ff26a1cf5a42c618f3b3bbf0d642c63d83c,
        0x0353e34851deb43cff8ec89c9fa3e55ad63796f91861d0f5644ee2b655f75475
    );

    IC[70] = PairingFlat.G1Point(
        0x1ce47bdf049ff5b79132cd416681e8e26d0e62f81b145efc3e7f54cd15ddf970,
        0x0e5dcf73a6a7d0811957ff26a980d142e297d9127f210bd0331f092884fef542
    );

    IC[71] = PairingFlat.G1Point(
        0x2a5cb674cdaa197d2ecd0fb277dd6c0c6483d73cd7952170669e4ceccf027a5b,
        0x2e63674bc73bdaf9a7354328e33ae4d3d87e302471eaa83ad6c4f3972fc2dc7a
    );

    IC[72] = PairingFlat.G1Point(
        0x1642973ec98968edf8f68e904d6cc592df190d84b8e9e94d0c98e9939c3bd865,
        0x02d7ee0b1da60f13488d0e3c76d0deffe4f0bf72fb9c1fe3dcf27004a1ff652c
    );

    IC[73] = PairingFlat.G1Point(
        0x253b554fa279e040c8270d50d33764449f00b52b80c68eae710bf5204ff93a1b,
        0x101266ffa0e721d8e2a7f02dabe2f4b1902afb28dd723333a38edfa6cb4c0d14
    );

    IC[74] = PairingFlat.G1Point(
        0x1c2e288b776ba054416908109d625934375adac88715e8e451b4178a62bca969,
        0x2bdeed77f98518d01cd76a9974299003f8472310b2089e93d246348a1e3d816f
    );

    IC[75] = PairingFlat.G1Point(
        0x256939d24e17ed0b04cd8faafe4a775cd5ae3df384f2a8a6bc438bf0118cfecc,
        0x0aa90504e0e285ca33d76268e515532d24e47f910b818910ae48629bfdc382e3
    );

    IC[76] = PairingFlat.G1Point(
        0x14937c2eb94f0bd4e0b71e17542aeb10993a0335f9d01f82fc9c4f12da4f98fd,
        0x014c0a64f864b6468b2e4b22d2d815883f5ebe52f5ddcf0f0c3829759f7e7776
    );

    IC[77] = PairingFlat.G1Point(
        0x1af394a5b7599de66f9bbc3ea25190e1f7566ae8c7e7f498edd1b548a2349dd5,
        0x1d63588bf40b89b50768d60d9d8f08f9c27eda14ddebfd60e86576ab6a8025b2
    );

    IC[78] = PairingFlat.G1Point(
        0x29abffc994ab01618ee44facd4ed58d5406fe94c45f50317658367137a7228b6,
        0x1f3a8ce8d321fa1a01582a7f7db1b3468facde05837f7e428b3d07c8c5eee113
    );

    IC[79] = PairingFlat.G1Point(
        0x2e0ab181c7d2380441974d262a7f5035039c40b220bda435a24d6cb7486e8dd5,
        0x1938c3cf8e9747d930a7c173bfd159f6c3920096b671e0f56d064857487f9902
    );

    IC[80] = PairingFlat.G1Point(
        0x2a2be2b2a6d0ac732916a2d4e415c413c7203443fd6a8efc41429cd5f3c3c467,
        0x283461beec6e448989aa9b47627ebff146d9059a87f5f2c634698ce614a64fb3
    );

    IC[81] = PairingFlat.G1Point(
        0x2026738190a51fd56d69e3d3460ecdf3252b26d7470d19c6c1168b2172d91694,
        0x266f994fcd7d9691272511a4366517ba37170c609e495eff20d6bc1656566515
    );

    IC[82] = PairingFlat.G1Point(
        0x23c015437ab3cd13f97d22dc078a830a4dd7a689349b30a9b45623543d867d9c,
        0x04f09336b5452f8a920bdc34ecef802f31fcdc1aee3c605117fa58a9d33a0bf0
    );

    IC[83] = PairingFlat.G1Point(
        0x0af36c9e34c66ec5de9485d0f222e1a204e54c902fe5e5feb89950e886be7470,
        0x01561343f969d0996f347f265b22079dd1118a94cc6a9774d31bd0842ff426b8
    );

    IC[84] = PairingFlat.G1Point(
        0x28815288c82eef9b6ef3b03fab46b956c6efe71f0ff66e1a53ffffeb03de067f,
        0x0cbd1532dbf9a6b7c05807286e6e6194589331013e5d7a0917ef1921e1047bbe
    );

    IC[85] = PairingFlat.G1Point(
        0x13d5b9c0017b0421fae0f525fabc98a6e741f2d1774997c585ba9838b1f5772f,
        0x04f310f23458f2b56e7e60df5afd6b7383c296d05c91c47b9fbcfdd56eb0a419
    );

    IC[86] = PairingFlat.G1Point(
        0x1831dcff373edaa7a3cb8d66bd0d1c835e17d90bee0117ea7e84a8883dfcec5e,
        0x3055e6ce87dbff24722323ed48e921ae53a26af67e455890902117b914711e7a
    );

    IC[87] = PairingFlat.G1Point(
        0x2d58768afc56eb14ea7f78af1b6dc85352020347de3d359a4017e850b1f1d4e3,
        0x19257ef95f1b66bc3efbbe182230a492f97e55227581cbe670fc92ad9dd0d551
    );

    IC[88] = PairingFlat.G1Point(
        0x2a59fd35969d6293894ee25d80ad64330e35fad5645077bce0721bdeb2eae541,
        0x2b10ba40ee6b152561bc017339b02d41fcc6cfad790b3342a0d543c5c8fa1722
    );

    IC[89] = PairingFlat.G1Point(
        0x24a534477ade8430ce6eefff45e001a1563767bdde9924676b231a132b7ad712,
        0x090ff9657e37a428ff1625b38275f2ed9e940730cabc5c2f9f5c17a8bcc2bf82
    );

    IC[90] = PairingFlat.G1Point(
        0x109138416659c155d286c1a6daaee5b21f8f2c3a586133288dc7794bb6b849fe,
        0x183a21e22cccfb700a2eb169eebb1573ca916467442485f970981436caaa25fa
    );

    IC[91] = PairingFlat.G1Point(
        0x167546cdcee1cbc3a7d3f8facc54b352e2578d0551e32c7e3896959847adab2a,
        0x1c83b076ea36060868f0df6ea52cb24695f48209aa5516651516dd75db57da2f
    );

    IC[92] = PairingFlat.G1Point(
        0x193124830b032f1b6710944d2aced389337bafcfe8043f5dc29d96e4c090b3c8,
        0x0f03df88d9f95f47f4862afb085a69c10d4bafe8632c476ce09e87fde272d19a
    );

    IC[93] = PairingFlat.G1Point(
        0x2535a0625a473e617c9004024deb6920c5bef8afe17ba248a65944fff092f7c0,
        0x204203f581cdceef9a94c76735fe765022af44d0ea5bc42837aa3b634aba9d60
    );

    IC[94] = PairingFlat.G1Point(
        0x0fa60adc2b6ec7ba6c1d7bece8f901fc5d49d84823f9fdd1104eaf10aa3bd8f6,
        0x0f2e69c4643b4517b7962abe74e6ddf14ab036b80d0c13a21ea56e09cfb32a48
    );

    IC[95] = PairingFlat.G1Point(
        0x17d12d829316243ab10281b4af124828da834d35afd7f332eff068c4c3aa46ce,
        0x0bc071a4cc05343d07ade8c65bd0fb22040ac300341d570dac7f3d5d54fdb0ca
    );

    IC[96] = PairingFlat.G1Point(
        0x2b4c3fa030f56dcdd56b875afe3236e9db2f670473d605eec5dac37fd523cdc1,
        0x1d2bebcd992db9fbbd071fbdf7b5e674e9a88f5d591983e3a7069ac9fb49e35a
    );

    IC[97] = PairingFlat.G1Point(
        0x1d1a9228e452ce91f876343b0f46d316e6faed5781a8f3feead2b0b40f796653,
        0x1094c90f0f021c4cc3f8954f1400d4a726c82a73007888c236644c39068b2ed3
    );

    IC[98] = PairingFlat.G1Point(
        0x08dfb49d01398f1f2e9c46b9c5059dd74950d746a75433a49e92498db8c11d86,
        0x1c98832fde76f5b3bab1839a9f3eea57062b9f3937f4e820b1a1873ae1cd44a3
    );

    IC[99] = PairingFlat.G1Point(
        0x2399e2a411f565db9483e6ec186de5e1a0cb34dd98e1d6f9e078b6b9e7182c53,
        0x2f06799700a0aa1c59b7650e4c8a742f62879b22ac1395220a15ff458c8f91d5
    );

    IC[100] = PairingFlat.G1Point(
        0x03378e9d94dbdc58c741ee559131dc344f940fbab1619595d82320b432019990,
        0x0e94b2f27613f65fac7f4dcc7816dbbf2757e09fb72d914fb3cf106d1b7071f1
    );

    IC[101] = PairingFlat.G1Point(
        0x10a08265d16f52af3dd35dd07cc96f6c686889f3644f1a58e0b852c29040691c,
        0x2b8af9c4e79d9ad4cb87a6a4a2596a13fb7659e6c76fac199af0440bc2d4a45d
    );

    IC[102] = PairingFlat.G1Point(
        0x2bd678b564fc35fb6aa9c6aa6aa512abf2d7574dd95285aa9d145eb98b7e4c1f,
        0x0cfe3f6cda445d44ef423a3cf7cac78c6ed823dd2a9e01a381d597f98da3dcd3
    );

    IC[103] = PairingFlat.G1Point(
        0x20ca4f0ba5aff33542ad1e6035cb59dc15beba7e3078390ba8cd09e824f2394c,
        0x09f0539d860aa81659a22e5fc6f374de7943261ae29800a485f010180e61f4c2
    );

    IC[104] = PairingFlat.G1Point(
        0x14cebfac3ec6b3babad939a51f23741a6e803c0ea0ada4988c25e04073316ac7,
        0x2da0357a0a668ce201041b574b663fc200134f8e3c774c0ade8a7caa82a9da01
    );

    IC[105] = PairingFlat.G1Point(
        0x12fd41420f115f41eae40a0118019900436fbc769c8c5b7cdea1607d3a464982,
        0x14300a897f1ceebe4447e9537a01bf60456a39a326bbcee88f37f5f6e6b405ec
    );

    IC[106] = PairingFlat.G1Point(
        0x1456cbe36ac02687831367cf0efcec6aaeae70e716067187e728a0500cbb6755,
        0x0ff2fb19aac79818aca10802d57edd78719c9dbc9df073fb3643a50d9e2844f5
    );

    IC[107] = PairingFlat.G1Point(
        0x2a93501c8b51c21cdaaa0f53469f42dada69cb4ba4ebdfdea216c2bf6b1d4619,
        0x0da8cfed760dc048ded1c289617db82b8de3ddb3350ee3377d64f9cf40ac07ee
    );

    IC[108] = PairingFlat.G1Point(
        0x0db250807ca700b562b13467e11e30e64d51d633fb871bf7c634a9dd33fca687,
        0x063618b908add3ddc346171362a71c2b0eaef82183077cc9e303f3024cd8b9aa
    );

    IC[109] = PairingFlat.G1Point(
        0x1814f9b8827897083a401a359f909dd27e4e91354e8ebdd40cfd6017b65d0ae7,
        0x1ea970075b305cbec929aea502a093c581b124bee4991de6a8174e2470149e1c
    );

    IC[110] = PairingFlat.G1Point(
        0x0f64ed5f29fae3ac81cb56251af71e8a5287204cdebdb6e6e4ec37fd757aeeac,
        0x26180e7fb007a96986196df4e55b3e02a66cbe3e608472267357104374c93e73
    );

    IC[111] = PairingFlat.G1Point(
        0x1781d4f83d01a09da7c1e9a0f42208afbaad2c9330d8a09783fed0ab712abb50,
        0x0bf3eee50b18e055f0c74d5418297e74f3ebf9120634ad74c8a5ab8935df735f
    );

    IC[112] = PairingFlat.G1Point(
        0x271f8acd9d07be34322db9a6fe64f8261f09d326452b6497ca15ce15ed009eb4,
        0x18c83eef82274b1d8091ea0d598b8a53f74d5806dcbed0e1ff2267b80d21d00d
    );

    IC[113] = PairingFlat.G1Point(
        0x2b8be3399c80aea3e3423e2aa235f811d19fb40145eda8ea8f1b7e2b90fc98b7,
        0x13d48bcabc8387593f79136debd1113f9560cc6577b5c81fefbc657fc89cff0a
    );

    IC[114] = PairingFlat.G1Point(
        0x0bcfa47821537ee4d92b1386d083a2c976eb75d9c9fee24149054fef093541c3,
        0x047317ffbd5accc8f9d965dc1cb0b81f8e1ba52988b1e44beafc1b7e898fadde
    );

    IC[115] = PairingFlat.G1Point(
        0x2e90904a5589b9322a71651533bed156f857c88f375929f8462f64dbac5c5d09,
        0x2dad490333b0a34da75e7baec33fb067a9d756fd189887881e6a1d2b57eda176
    );

    IC[116] = PairingFlat.G1Point(
        0x25907effc57f2337bc129ac7f1fdb0c64e873a9250e2ee2a59f4ff72c89ab1f2,
        0x2a953cfd2eb2595c6dfed2b2facd7ac3bf67ae94c48099c024d39c0780acd9b4
    );

    IC[117] = PairingFlat.G1Point(
        0x1cb2e0705abe1fb88520dc5e4c27fbe2b27857d2184a6dfa07caa88bd540d407,
        0x1499e5b80de114f7378b50fced5c34f17e82009d818013b2d5cd076d9dac77aa
    );

    IC[118] = PairingFlat.G1Point(
        0x0ac3d9ac67304d2ec0a6c1fd697eeed71bbed5779e55779bdbd1eb26685f7a5d,
        0x109233728169011e7624b9a19d3c6ccfddb127508ff8957a329c903de77f1bef
    );

    IC[119] = PairingFlat.G1Point(
        0x0afc1abd69612502b7902a843dbec83230e94dc9e96da2e4afb2116ecd32df7b,
        0x003bde662692fd34decfe1196b5e17887c8de4fb80b619d1601330cbac542c74
    );

    IC[120] = PairingFlat.G1Point(
        0x2ffa17e6d6f146c9f5f6f276342b4cbb75f9e477aa709ba5af67ccb8427128c4,
        0x101cf9309a41f680d5c03517e219518f1c477d01d22efdd762fcc1322c84eb2c
    );

    IC[121] = PairingFlat.G1Point(
        0x2542e5ef7ec24aa02023e33d877d64b9a96ac5fba18644363b15b64533e7534e,
        0x2ec55fef89f471a7f2448786050a378d903bf7e138d8f685813fc9bfc6466b54
    );

        return IC;
    }
}

library VerifyingKeyBFlat {
    function IC_B() public pure returns (PairingFlat.G1Point[] memory) {
        // returns first half of the verifying key 

        PairingFlat.G1Point[] memory IC = new PairingFlat.G1Point[](122);

         IC[0] = PairingFlat.G1Point(
            0x2070bc7a1bbfd53f1dc155babe243799cef5e681e0d04501142cdd42c0a536fe,
            0x2eff8bd0981eab1648d586738b8eade2fc0ee533bf8c70ebf3263ea8e705d14a
        );

        IC[1] = PairingFlat.G1Point(
            0x2266806735b37e752c5321e23199d99e40e4644a35b72e39a8f7f31b8a9bae4e,
            0x237b34a6737fc1fd72a7f172a1de91bcac96d470b5b29f38469e1aea75fa3f7a
        );

        IC[2] = PairingFlat.G1Point(
            0x250982c88d3f8c90ee81c2fbb5514704dd283bcd5ddbd8efaa59c8d4d1a646a8,
            0x1e0b1c27584b317ec8cd5dadf3a874c6fadd98fd4200d7d0d246d9562c285920
        );

        IC[3] = PairingFlat.G1Point(
            0x2f14d066d853cc0bd765e0dc71843549f69f6eb64f717b51dd0eae18bcf6e9e8,
            0x09d0cbbebc516a614c3d5d490dde2dd41126c4e5b11f8b94456c27484adb3b54
        );

        IC[4] = PairingFlat.G1Point(
            0x065b32624bb94998e6717adccee5688a5fcb716ecfd86ea9488cda8b73de8e21,
            0x07b316b25fcc49da9d5ce704ce418e7b02ee0a453d98536aa12ebb4d39e46973
        );

        IC[5] = PairingFlat.G1Point(
            0x1170cb222011fca085f00a684f8504fd607e5eb38763b0785cfe8e7def7038cb,
            0x0d13f9b01fe6bc27913bc73bc8e85a12ad442a3a0a43bfff996308d7c2fdd029
        );

        IC[6] = PairingFlat.G1Point(
            0x1df8af3cccae1d53e31e5f73d3ef7cc0e6f2da4ef59bd49e9cd5dffa01379382,
            0x0268c416d3df8a67cf9f5a018023e78df6ca79983bf11192bc5405a789bb8c3c
        );

        IC[7] = PairingFlat.G1Point(
            0x1ab5ac66f0272b56024da1e63b48a0a37de0dafadc79a8cee64d67568a7467df,
            0x1d940b81ef014afc23e8632a36b1f161930de4ffe79a3cd117a1e91c20b7d5ac
        );

        IC[8] = PairingFlat.G1Point(
            0x04c6d29f4cf360b219d46e44e2f107c6c992ceb980e9abda2ae8a57184a6c4de,
            0x007c369327ef4951c584266e41c20cb9767ec24927ce7aa76f79d1b307b7d1a4
        );

        IC[9] = PairingFlat.G1Point(
            0x147d0f42b708d6f48f5f552233da235f44dc8bff7d27f2c687a396a860e96360,
            0x1118531724a9d7fe3b467bcd6facba8383a102ec037a49f16cea97f607641fea
        );

        IC[10] = PairingFlat.G1Point(
            0x091ae384d0c704c46c0b736438f633daa4e039fc1496009d96cd6be0b1303436,
            0x00d88372a9fd5d70f6770967803c7e201aea65b4316ce4337d561a218fb1ffe9
        );

        IC[11] = PairingFlat.G1Point(
            0x2d8b78371fa46cd67e177a789b8c1439312f31cd3ff57233718b737d0228efbf,
            0x1670ee053604ee4e5d9b00b6a4404bb43e1dd8e3a6cbdc0855a9336c65709190
        );

        IC[12] = PairingFlat.G1Point(
            0x2906c8c2c5fd63c8ed42c854866998a753581edc1d78d099df46dd3982095125,
            0x10250b7e05b56569c0433131fe9e0ea8f4ac8e0d433d68bbc463d09397810089
        );

        IC[13] = PairingFlat.G1Point(
            0x255c016919c00b46e135868f0cba94ea47002b3c4d3e6fd1802f056483b0a3a1,
            0x1d66ce539221e2f626e20dcbe8d837904521899954a969a9e48c6b511a0551bb
        );

        IC[14] = PairingFlat.G1Point(
            0x104f08cd69a7e2339cc216422b16e266100a9c5e71ba81ebe25a606d6d339823,
            0x010f470ab67953b6045482951718f6d40abc229dd03c45a3e75079f291d8fdfd
        );

        IC[15] = PairingFlat.G1Point(
            0x1c38f7d7fec462378ab769f2265cff0122c6506433d3c7e24c3b57b6e1759748,
            0x2441fe780e96b86175e98ee2cee3414bf04ba4f6d33446ddcb55483a11c58d76
        );

        IC[16] = PairingFlat.G1Point(
            0x107fb54c433c24be05f44027899457daf7bdfc6a3e22277ff0fe53b1c61cd924,
            0x0436170079120208dd2b5fa9e35e123424c9fa78889b7a663c840436acdbdaef
        );

        IC[17] = PairingFlat.G1Point(
            0x1b59ae5a423bf5c82235d4b78d9e3ecea72882c79fdade4570bd08102ad49395,
            0x29ab0a991279c1a294f80085975ba0880eb60891ce647d09506e4f7b951943ea
        );

        IC[18] = PairingFlat.G1Point(
            0x2578b90767b6d41a1c602fdfc07b72df8e897d80e9be9f93eda5e787650fa1c3,
            0x1c1656b9512d8ebefcc14b6deee34d1d9e66c253d0dc44b21977522a3f9184d2
        );

        IC[19] = PairingFlat.G1Point(
            0x2b632983ff7ba759f509e99d0c1b32d6f5c94e32dff5fba0f3f113a5b6ec1d03,
            0x296ad58b9759ce80fdd49f312165db33757b7c63eb70fb00599ac2671cd1eb2d
        );

        IC[20] = PairingFlat.G1Point(
            0x25f019ad1beb743579a2104612bbacb9bd2186a6f915ae224011b138d529fb01,
            0x2af5d2541f0cdc9ff6134ad93a4477d389efb43c8acbc608024a7f1627261ac6
        );

        IC[21] = PairingFlat.G1Point(
            0x150819771c46a5d8bbd7b2311a0a9c5a8273b103dbf6d0adbea4a28e44719b2e,
            0x150e39cd6dcd9d1cef2681acf0afa59090b3e3116ff2e468bc4a79815ed2bfc0
        );

        IC[22] = PairingFlat.G1Point(
            0x0e170ca0c95c488eb0e50d954a584185fcf8a845eb9027a7ad6a6dfdea2319e5,
            0x001017d84325dea518efe8b40dd5c6b8005f815e8277250647955d771dbcf1cd
        );

        IC[23] = PairingFlat.G1Point(
            0x10f87dcbf6740d31bd7b29b2a0c16b78fe1f2da4d882cd17fa02511ea7269ce9,
            0x096dd48616e6430b662585a4dcad99951b6731206166ea70356c1a25fec697f3
        );

        IC[24] = PairingFlat.G1Point(
            0x211b1a8cb9e01113976e524abf69c2dfedf6e2031aa5c0d59ad68c81cf859b25,
            0x20dd8bb7bc0243d0ab397d61e12c5c1c7bb8573d9325676c08e36bd1f24ca911
        );

        IC[25] = PairingFlat.G1Point(
            0x258db0ed3dd73cba48343f0319155c66077e70adcecfe10005ccf14500bd5223,
            0x16ed34ded75018c790eb1fa90a11c9a39c44c86877f506ada9ea87f664c12ca0
        );

        IC[26] = PairingFlat.G1Point(
            0x2f9940da5a4d4088a30727828fd37a9cf74ed9cc80ef429d26f082f1d085eabe,
            0x19d19c2e9b565a2aef60816de1563ee133d6cb6ea5ef9e5adae290c1856449a2
        );

        IC[27] = PairingFlat.G1Point(
            0x2f77e057c4f6e1d58e5eb49e7b8981bf6c7fb662fbc633a2e79faf85969f9abb,
            0x1281c0c68d6b4308315f0c67f78f301dc8246a3dd479fae77084efd67dfc80e7
        );

        IC[28] = PairingFlat.G1Point(
            0x03a7c237efb4cf13bb797a3f1c0cdbc8677a4b7db3bfdb88faec5cccc9ef6779,
            0x2bfa4fb436b1211700b9f2838536a4326a644751f1f1686ce0c7f3c34d91e19a
        );

        IC[29] = PairingFlat.G1Point(
            0x03e107a18ddf986c82855411e180ae108c47e3f66849b1b161a52b58ba35a145,
            0x21ac59e47052dd719cdcae11720bbee75cce01ed599493adc06c5cc94ab9aaae
        );

        IC[30] = PairingFlat.G1Point(
            0x22d3ba46b815aa5dfa49737ca827536cb4e883eb721cd6d4ca456254de07aca3,
            0x2c3254a50eecedd2d52478612730ce8e5b7d361b7ef06fbb4fc9e97125cd8da3
        );

        IC[31] = PairingFlat.G1Point(
            0x1522f4080b406c7a151e4ea86c980bcab0445f900ef093ce710a278c86cc1749,
            0x10846ea59766f6953d7909655f5c5faf9b4803d7e4cc9d8856cd02fedc4207fc
        );

        IC[32] = PairingFlat.G1Point(
            0x2601009997af435fc1b7eb57af5844761236ded1dbc816463a64fad61389897e,
            0x125052957f6f57c0a3e5248e2ab01d52213e45600d96a9eb4c0cbd7b1b2b0fb7
        );

        IC[33] = PairingFlat.G1Point(
            0x0081abf5e8b929db8f5bd5069e98759fb3b75681c6d9c762da780c5b295d74c2,
            0x06094f38877e7432080fa385a55f8782dcda08b24bac1860d428ae236c4b2baf
        );

        IC[34] = PairingFlat.G1Point(
            0x0927ea8a5531672557cc4b9a5fc4a83438f8744f30ceadd944f0728b5fad1491,
            0x19d681799b7e3d48405e04c86171a611235f16440b0d166e0da97bf5ac5a36ba
        );

        IC[35] = PairingFlat.G1Point(
            0x2f2b7fbdd15f3225f929edba65340f794c8bcf6a05163826c3e721a79df7c06f,
            0x2d440db9a23aac7ebc057e9e04c1ab5d26624bd625a73dc7f888f8cdd7edc58c
        );

        IC[36] = PairingFlat.G1Point(
            0x2f2e24e7165eeb8f3fae8558e1b754f7cf4ae6ad95c71ee80322d632df1502cd,
            0x1d1b6cc1a6117094bd1c1d51b19bb1008dc5783e5ae3a78242f107a9a4e7da0f
        );

        IC[37] = PairingFlat.G1Point(
            0x246714f34d66c01278450a2928237892bec416c3bda66965f22bd7659d1ae3a6,
            0x2121ff272e334e5717dc9c2633f887753030f58335a13f0631945e8553d555fc
        );

        IC[38] = PairingFlat.G1Point(
            0x0d060001fc8f307912ee64549ec9cdbaca613ff24ad6dbe2cb3ab2108508881c,
            0x220fc23b68ac43a51026adf0959518d0590e46441194f999408ee771c8fe3e47
        );

        IC[39] = PairingFlat.G1Point(
            0x1a4da31524df4d6dea4265b85b13923b55531de0a471616e8f1e6dfbe78cb2c5,
            0x0f4abde9ecf8a81d696ccd83e53dcaaefe17fb50272bde4b9f2db5599b2fdb2a
        );

        IC[40] = PairingFlat.G1Point(
            0x298e2240d394c96ab083ecf2cae650fd995a02da46883bf7e2aec722f79b6192,
            0x221bd789c85cb29a50aeed7353583567d326cfec312ede15dd3589711a80ac90
        );

        IC[41] = PairingFlat.G1Point(
            0x0d59b394e935365bb24b002351a6c30cba91e0a1eef379e28f12fd96424547d2,
            0x14c262aa27fd30f31079c702df4388959c6d9ec4fb4a570d31d7dcabdcc7ddfb
        );

        IC[42] = PairingFlat.G1Point(
            0x2dbfb09f83674387c47548f64085cb46162f5f14cdded65ee86e25f5a24d8539,
            0x197aaf0de53553b9753fcae430efe0f2cba235c19c51dfc33ebd7fbdf528ba5d
        );

        IC[43] = PairingFlat.G1Point(
            0x0d2d8fc0e1101916480261ce36275cce9236ad6bdede86f84f09855b8fd07b0a,
            0x17d1bfd8a7e2ab3ad52c594ae2bc25a7b722fe03ef6e639526ad066b2870f192
        );

        IC[44] = PairingFlat.G1Point(
            0x1af800ba83b8046d72ebfa8412fc6353f893d7eb088683c13cc6d4c1537171aa,
            0x27b4396d9e28329e1fa66ceab635720e0ddd20dc812f586d576d77ec109f9ec9
        );

        IC[45] = PairingFlat.G1Point(
            0x2287a331f3962115bd6bfa8f95ad4e414912c4c7be667801f79f3050ce196684,
            0x0590185d3f6dc7a8968234f7f7b0a5b83f235ca980d4456ddc937ebe46271006
        );

        IC[46] = PairingFlat.G1Point(
            0x1e6ebd003545a64d8c7abdf246c82b5c637dbbb55caf6babf6f3aa064ba3fc23,
            0x2b31018d57c4cfe083c21c8f6fa80ca63047abfc5ca8a852cc20ba34838f5fbe
        );

        IC[47] = PairingFlat.G1Point(
            0x03d9f269c0ff02f0c6a9319665c9da659804afd80244568da59fc4e2a4972fcf,
            0x2a84c857aea3d951be0c30c91ac805e3c45335ae2d82abd32c9cc1c68f8e59c4
        );

        IC[48] = PairingFlat.G1Point(
            0x16ecd06a9bbeb47d2731f57cd853f77f8ad96d503eea29750a6517dc1853eb8e,
            0x299a73ff008a9e4ea7c73fb3d1cda1c9d0b11eced82a5ab1a326ba17aae16f1a
        );

        IC[49] = PairingFlat.G1Point(
            0x0ec407642ef0e83a74f87f2a84a1875b7c447431429b3ec215a2f40b71056351,
            0x0b7d2257ad2d900cc7453abae53f1b3dde69c8c533a878d71a79a3b721b46e32
        );

        IC[50] = PairingFlat.G1Point(
            0x0d834a5cd5d48216682c0514f27af09c266938e79a0ea52a7c98ffc5f66e8c51,
            0x09320d8f1dd473732622faf8553a1b89ff88952f4b02cf93d23f9558a45d916f
        );

        IC[51] = PairingFlat.G1Point(
            0x1060898ee694859cdd4503486787dfe680e3fef9f0c86b243dd511fe7c5f8a6d,
            0x0707841f2828e9f8776d0dd062b75c87bd2164f78bb8dd6002b7c2fbaef497af
        );

        IC[52] = PairingFlat.G1Point(
            0x18d53112a47ed61e79e79d982c70c5bb57464721e33d37ddc21efa9d0016d644,
            0x2215bd1f6ea974f949e9c2cf403f8d4a65a3e0382bdcd5f4ebf942171ad3258a
        );

        IC[53] = PairingFlat.G1Point(
            0x1f390a74860862c2b1f4eaeb3af28cff7e55205b8ca8fd82b512f1d5e0a799b9,
            0x05f631e61c47abab2667c7395306f33c19e47e64fe6145ac874584d95ab09e8a
        );

        IC[54] = PairingFlat.G1Point(
            0x1ead8f33e4715f9e8d1115c3f01f55f4da130ede690c6088cbc3e9da87a203b5,
            0x091896f86843f095983313eba412eb20279335458422471540603025c30444cc
        );

        IC[55] = PairingFlat.G1Point(
            0x21ccbcdc3c46b843201a13c4a6af8c2d5d3f3cec19c80ae03c2d443c37858868,
            0x1e33f091e5d205f4cda8b4f8c36df94e3f79947669f557cb1fbadff202cf0a3f
        );

        IC[56] = PairingFlat.G1Point(
            0x23ea08c9978ea8bba07a2a1b02b0af69b170b8182cc910746eba1ed099be3cea,
            0x1eefbf1544bb1865f31d76d5c3931f663b6a701c19d0101e233e4b5076009355
        );

        IC[57] = PairingFlat.G1Point(
            0x0fab87bd12e0e279554e602efa2cb33581f4f100116932159816d1d77b7bcb09,
            0x1844ca7d7a838518dca2aedfdcfd9f9648ae76aefe83f12c87caf9eef4ec3175
        );

        IC[58] = PairingFlat.G1Point(
            0x1ecc5ec81e6c32703c22c4263b8954afaf1a9e548c139d94f0846629c81f830a,
            0x2e8f392697ebadd9fe6fc39e70be45c3b8d1dc3b6f6ab44763a17a0764c55c55
        );

        IC[59] = PairingFlat.G1Point(
            0x06c662b5b12d3b6168d68015875637775f544eb9c97311620919f945c79814e3,
            0x14ce14067c0cd7aa44da439920a015c617eb7d6388c81f8acd8bc55d8ccbe0fa
        );

        IC[60] = PairingFlat.G1Point(
            0x2a07989b6dd52a57398792d4cb695c1329473f7780326bc55ed1f7e2479a3a37,
            0x2608a0652c64a21a33314e9465b4fe89e02bd70f739602d5797da2d701797f71
        );

        IC[61] = PairingFlat.G1Point(
            0x0cd31cb362a00dfbc897fbed4637964e47717ad398333d2649a218df065f0fbb,
            0x0504b544d47e8d7bf22156d0a055ba1350ee398c2acc869a66b50f9f75a07d29
        );

        IC[62] = PairingFlat.G1Point(
            0x258466b3655fdc29f0b94c4f328df7d33f4211c3bd7dade88ab216669ec342a4,
            0x25ffff1a9b235c18a362d793a9038267b3a2d4ee83d5d2bf640b8c5c13ed8d97
        );

        IC[63] = PairingFlat.G1Point(
            0x201a15c924d8f51906ea8417a6daa4fe1debfb3cbd23749305c4109e58dcc756,
            0x03f72430160ca76ee1ae857a3324793d0cc909654cecb0c9f499430a51461fe7
        );

        IC[64] = PairingFlat.G1Point(
            0x0a746bcb53ef66dedd8bdc61773ebfaa479cba111cb8b512c39a67ba98ed191a,
            0x1ee21337ddce81fd961b13aa76d7f75cc38e19513317b2ae1813c4630a46401e
        );

        IC[65] = PairingFlat.G1Point(
            0x26e4a314374fde052f87845bb1f57c07819839d2e8cd6c21b7596e9039223dc6,
            0x116d8d558312eb80518ac50f06cefbd887cca235ae56277d0e5e2f6b8c4493fe
        );

        IC[66] = PairingFlat.G1Point(
            0x129fef13ef914e1c3d91f244d738bb46d87849bd7bef0952af21b762f266be25,
            0x08bee760b65798a0c544de9c5032b82421b0f8e13e1b71b19ec1840a52193aac
        );

        IC[67] = PairingFlat.G1Point(
            0x246467b44bf4ee66176dd4a762b1b5a15788287e20c8f01a53183fafd26cefd1,
            0x0566511a0d511aa92e81ad37db9248fb2a3e232549ccdae973c2f669bdedfe19
        );

        IC[68] = PairingFlat.G1Point(
            0x296c5119713fc75bda2b9df2d9524ea6412cf3a8dead54a59e4bee310e16860e,
            0x0dd9dbeba01ba5d7cb0093b7a1e77d229be34f91b05ddf49759ef1f865cb6c56
        );

        IC[69] = PairingFlat.G1Point(
            0x0b6011a5a4a6fc90a512b634150643b4690f6c0389da5256ef8929ec6f6cf096,
            0x0109b2a1ff64750fc2474b189bcd4bcf2093c935c903d19c4c239001cfcd109c
        );

        IC[70] = PairingFlat.G1Point(
            0x09074535d6884bd5c3c13a6603c53e5a6ba495ab26bdc272aa2eb64cbcf485c9,
            0x13ee9f9ea092a5657b0a5f78447e2b398c239010f7a1d90a54f944339b4ac267
        );

        IC[71] = PairingFlat.G1Point(
            0x04915a2575ff7dead068dbc220ebed848932a5e2792793882a8a439428fd3c9c,
            0x26bbeb65bc40940b5bffc02539cc6f666b741fe7e02519b7cba7ae935b3abd33
        );

        IC[72] = PairingFlat.G1Point(
            0x1c1f7ff645418909e2386fda59a96084237fcf8ee307d9426cb64afcc628fbb0,
            0x02b48bf6d5812ea3e3a604fdfcbe809880266b5c15786b7e9f4f52de39884e90
        );

        IC[73] = PairingFlat.G1Point(
            0x0599e87afbfaae91404ae993ff388d7cf1d8a0c14d7799915bcd0b3ed845a906,
            0x217b153c22dab6fc67b9fd478844e189ab6fed89d801e3b47eeb1ed969279a74
        );

        IC[74] = PairingFlat.G1Point(
            0x1c2d20d3181fa83cd564d0a9db3887e796bc1d08ddf973b5e0862fd39e205d6a,
            0x1106e973ac3696c4c746a08cd15047dee8bf173188433e7e5c85c83dfbaf262e
        );

        IC[75] = PairingFlat.G1Point(
            0x1866c5470058f247e7a3af91d8585ea76f2b87085f2f9427dbb195e569b80845,
            0x2a0776d37e1ece5b7cac2905f033e1a7fb83cee12914a0ee7b121aff5f547f30
        );

        IC[76] = PairingFlat.G1Point(
            0x1ac70c4f708fd31e883b32c0f533580edbb3deece603d23806560dd7870d3a63,
            0x03448a0846617c0f4e8526a82e2fb408ebf348c9d5e9d38b410948b624b8d788
        );

        IC[77] = PairingFlat.G1Point(
            0x23a56c48c60d5808d42ab381bd25d204914fecc8e4151848e663ad47a7c63238,
            0x1ff4b37d2491e24ae444de94123fdf3ab1d4def7b49e0f368bc395716e816e87
        );

        IC[78] = PairingFlat.G1Point(
            0x001baf5c4f5e43134e9ace5271fca7ae69bc21ca65849a61f4d1cd51bf17ffbb,
            0x14d88379e446ef957e385586c5d569868d3220881f515357f65c7e6e54c4f4b9
        );

        IC[79] = PairingFlat.G1Point(
            0x23e8c588d8553a889badd2ce06283f86599e2d05303ed5355c6927e7775c234e,
            0x20c347f16a04b5e569ce6d8210d1402037b62e136e6c98ebcbeb588ae97709ff
        );

        IC[80] = PairingFlat.G1Point(
            0x27abaef49ec546998314aacdd1ffe59e3297efe22be4ae4740e3523810e66a6e,
            0x00b4b99106d6fb4a21273435e919cce6b028d5da0ab0ecdc90928c3d858b853f
        );

        IC[81] = PairingFlat.G1Point(
            0x22b6c8e4eb899c4c7cebd4c68d5d27bf78ceb6f38e73153ded1a22a149e7d65a,
            0x0f854404048d538dafe80968a980e962e6e2b527ffc2434a840a231205bb7355
        );

        IC[82] = PairingFlat.G1Point(
            0x2761ad69218b67154593da5a3c9771cc1d3e87e0a5ca9722ebd9eaab50aba66a,
            0x1cfcfc9a1d93ef7db734cc230811a7c4857a4464bf7ddb5d35ba1cea39dd46f3
        );

        IC[83] = PairingFlat.G1Point(
            0x0809ba2851c42207c13c02f9381fb35e6f8535e10d4eb08961b609ef7e513fb1,
            0x246df4d23cf6575568d0f9d89b8294344a994bd82b71ddc7df15f2955d64f227
        );

        IC[84] = PairingFlat.G1Point(
            0x161cc405d350e74dbacfee6088c554d9f20d6e482f7752fc70af85babfb69b61,
            0x28d95e8a23787637395cfa8927bc6bb36a5d93b06b80f7439a8327e3e6191318
        );

        IC[85] = PairingFlat.G1Point(
            0x1f181eff4407c483cd3339ee3f66aad34b6bc8624a6a4b49a380b5b8575fc6dd,
            0x08d9a6fdfc73a5c030b4dad27ee4cd05201fbec25d9b8abde527309a62256ae2
        );

        IC[86] = PairingFlat.G1Point(
            0x28c399309422b40121f6f40a13497438c5811de9f319e51c8f2d899445fbe2c7,
            0x188a6a5c3f2ba92105e4be5b52f6682f465f11cc305db5db07fba2dd399fd972
        );

        IC[87] = PairingFlat.G1Point(
            0x20661c579cb1d12884252aac4e84bfe1cd8b5b10b4a54c1d576cc85d31394400,
            0x17fa7e75a8ac80ce406b11b729ce73fee3df9198059de905758edefb7b9a3b34
        );

        IC[88] = PairingFlat.G1Point(
            0x025c003d0263f235aeb622b9c2712e7348a0c17f6a06b8bba97d5f040beb148c,
            0x16dee48a8a2afea39a78e12ddc653643012db8de812c32aa69a76797c82f4ec6
        );

        IC[89] = PairingFlat.G1Point(
            0x0588d6d32020f3754f5306c50c26a2eaaca4170c9288a2c35e105e91f84f3f3d,
            0x269114acfb8d922f764e7f508b11b48a9970e6fff42705927ac2a97dee3e26af
        );

        IC[90] = PairingFlat.G1Point(
            0x0100ac70ad5d75ad0cac569310414fa2e73d254b32941552ef1e24551eea6fc1,
            0x03eb89b2f7bd326aec85d4c69fc5e6c65f1b1fdbf1cada9acf6fa1e0168090c7
        );

        IC[91] = PairingFlat.G1Point(
            0x11fe07f99db6ea7ea3e717b5b352ee131217702e89f96f23aa0deb296600c06f,
            0x0a466c4b996d2cb0ef12cabe18d81796253cd21339cabcff91d94389e38e07a7
        );

        IC[92] = PairingFlat.G1Point(
            0x1b79097c4d1f08c751353e056179b171d10a8fdceaca24b875f45ea214e205ed,
            0x1da85d22ee0d8b3f7cf457ac916c625ca102645afa00e35d29e8df419176e253
        );

        IC[93] = PairingFlat.G1Point(
            0x2a2e14b9a293fa29de9fc1eba94e9786f8bbba0eea6ac1368cd4ad9f9215542e,
            0x0749b2a6173279bd667099d12ea1cd4ded750b466e01dd391a61d6bab0f8640b
        );

        IC[94] = PairingFlat.G1Point(
            0x1f1098507f150870f7b5ae3dbc3bd857ac93076fc68799ada464a829f1bf8929,
            0x14a74d01d45a42332b36fde1fc13d6a063703c2938168e919a09e17ac4bfacb4
        );

        IC[95] = PairingFlat.G1Point(
            0x185eec6ff073dd1216395460e6bf570cc8ad9bb53342cc46fec1220f4d729416,
            0x07955bc4c6006e01513820e2e6e9743f28684726f76db080be9f607b3d067c6a
        );

        IC[96] = PairingFlat.G1Point(
            0x1cdbe388662e3331b7357c31e1b8c2e3cc4c11e9d3563dda93f156a00353d527,
            0x0eeca406bb553df55fcb88774f45c587b0465fd696cce0c5bc5d890f5835b239
        );

        IC[97] = PairingFlat.G1Point(
            0x2e194715e811bc077caae9c34c4482cd30f8fdb59464d2c7bf797f0ee5980c6e,
            0x134ca0b21ba310d856911611f0271f37e9a66c182007a0d379a5da10c2027bd3
        );

        IC[98] = PairingFlat.G1Point(
            0x0e6b3dc5177647e0382ca773a22ef6bd2db89656cfaf1413396af6c43157bc95,
            0x053ad5f36e78bffce1c56f8c6026cc6a06aeecef3f7e712a4c6117a56ee8ad07
        );

        IC[99] = PairingFlat.G1Point(
            0x060906d065446460b6ba9193a936b9a8455dd8a1b4e1e769be0631b0bc2070c2,
            0x03f03a062102aaa9314994e2b9ce277a9b99603c813c0d967852da6dcba66bfa
        );

        IC[100] = PairingFlat.G1Point(
            0x2a904aa05b880e8a1b97cdf1ccaeca490dfb8c2cf2367b33d0106e1eecfa81b2,
            0x2133c557bf7413dc66386501a2acdf7e75c3812a293a2af82f6532a6f9acbed0
        );

        IC[101] = PairingFlat.G1Point(
            0x233ebfa8b298070a5329053964e446c9e9270d1b57a37a6a601a6713e813f7e3,
            0x10c874d36f8c17c3d5d4436e6054fe0ad6eded5eb6bf46b1191be79c2c8a4014
        );

        IC[102] = PairingFlat.G1Point(
            0x01f2a45dc5629e480eb4aac9bd046e2725670d9d59d6ef9ba603a78baff12996,
            0x0e973887cd2f7641f02df23689ca59befb8928e096b20c2db1cc1d79460e7cb9
        );

        IC[103] = PairingFlat.G1Point(
            0x06fca2a51f1c6ed7d2fdfb0512d4725674410a945214b9c9a9601363cc6b1a94,
            0x24a42ae34fde0b15406e53a9cfb631bd0a1b12dff34cdc3b2ed299d6c6b4c2d6
        );

        IC[104] = PairingFlat.G1Point(
            0x2a442b5759c92c81ffba08a3b237f2e27f7b30fbbd1877ffa807951a86f0ee43,
            0x1c24fa771b3df442a57b22948f1377cf1d7c03d5cc5b61b11a8d58628e2a0254
        );

        IC[105] = PairingFlat.G1Point(
            0x046500a130480cc572c54080dea5c88c0033464ca800676068dde857ba6e2c39,
            0x2b61093b90ab037c170a60efe23ef3c22313b4cb5477d4d60cd74e5466432f94
        );

        IC[106] = PairingFlat.G1Point(
            0x1a9d50ef15673fbff5fa860a0e5087cedc05a3b24c5863a550cebf46ad5669b3,
            0x25ff2882160723d2ea2863105febba60e1806d201a3b681c6d26f7c8c7ae2c62
        );

        IC[107] = PairingFlat.G1Point(
            0x01ff5a9c820bda0dc3b46f0b6a043a6013ac97489aab5926cdfc4a8ba0088992,
            0x0bf706f7b4192e840d557c4fab1b6d4c45f01b2e9919a030ad2bafcbce49f97f
        );

        IC[108] = PairingFlat.G1Point(
            0x19f74232b5f2d39a6663a24c0e88610ef3e5bb7827aad8d1150f76f89456782a,
            0x116a0117e6428710dd0e1a19f8e25baa1e7f5ccb339155319cd92003c105c9db
        );

        IC[109] = PairingFlat.G1Point(
            0x1cdc3687de92f829f82b2236ed1570de8a51e5d6561f2f471721e7a72dca3a73,
            0x17944c202172b78fe26e21e634d0ec5c5da0979a0c7c379f0cdec07ccbcd07fc
        );

        IC[110] = PairingFlat.G1Point(
            0x00bcb29a4a251fe07936ac400641789ad632dcbeaaa895f48e000378f36b305a,
            0x2f79145344479220cca8c945d1f106e6d0feb1dbf112fa3a3c35d74da84178bd
        );

        IC[111] = PairingFlat.G1Point(
            0x154157975b1a081bb14b38ded763720d0e0ec09b3460ae1a10143f9175fd9fa1,
            0x0aecac4e51f762dc7e7a1ad100aacfea3be338af15418cfbac6698384a6a7418
        );

        IC[112] = PairingFlat.G1Point(
            0x1b9d109ad1f82c21259457b8f6bc7d0dcc2da6f3bcd5f44bd8acb9a38bc64242,
            0x2efccd7207865e92fdb310ee2fc470b461e252c1c41c7a9007106f90025b57a7
        );

        IC[113] = PairingFlat.G1Point(
            0x1c2ffa38a933d2118c2792013101b09de93f48aa79068b30de995001f5f842a3,
            0x13cc709b1154575df9ebb80d1bf7eaff5156ca2d8c3968cd8aa65a4fecf7ac0c
        );

        IC[114] = PairingFlat.G1Point(
            0x20e95b61c3bacc88ee72f903a8f2ffccc764b729fa1fd2a62b5a8bd727616675,
            0x26994ecd61c29c5254aec5fe3dd767e1827d1d4a61a89f7509cc16a2445cd65a
        );

        IC[115] = PairingFlat.G1Point(
            0x2c68b9b51b4aba6ec1ce5ff7a966d8c9241c07836b006073472be346864919d9,
            0x096d00dae304c96f6615f896f66b7b2cc9df4e6b359a7fce7f6dac702aaebbe2
        );

        IC[116] = PairingFlat.G1Point(
            0x13cb17c36dd393a361974c4bf80c9550a5a8a0b6852f8678fe98fdc19048edf7,
            0x2a468f65812ac4642e6d03c02c81e9b8777335d7564b0a8353fe2c3e921de272
        );

        IC[117] = PairingFlat.G1Point(
            0x01f5c668f959a25311aaceca05ff390b45cdf7228c82a5b449480bd2ec24f1ae,
            0x153cbfc32de6b53e4ea8f86fb019536b8192283b75f7ea380de90a97e5673f3a
        );

        IC[118] = PairingFlat.G1Point(
            0x0339cd8596635c19b1cef5beed908fc1f011c71701e12a05e323c71cdbc7d652,
            0x035afbdf41b3abb169b023db9fc65a2fd3c4494c8f0c9d2ba05335cee8f4f27f
        );

        IC[119] = PairingFlat.G1Point(
            0x21faa0255167eb31495874d6c4cd64d8e7d88c3dcc7620887294798128a9809e,
            0x088b1f1fb93037fd2e2e0d093489782ce31ad6a083466b898fa4254fe159e0bc
        );

        IC[120] = PairingFlat.G1Point(
            0x2316717a50f85886a99feb7b91e912cca2d445243c3b5d1675cde390e4f30200,
            0x0b9130ea71734578645e069b99a7adb1b61632a315bfe5aad88b284c582ace3c
        );

        IC[121] = PairingFlat.G1Point(
            0x010da1b3207721f5844a1a14fe5b06dd4df2b23a7c81d267edb34ee4784f5604,
            0x180c792449a361c6d5e26677b2788e0a4588f7708bfef8e53fcde5a711dd2f8e
        );

        return IC;
    }
}


contract SolvencyProtocolFlat {
    // using PairingFlat for *;
    // using VerifyingKeyAFlat for *;
    // using VerifyingKeyBFlat for *;


    uint public merkleRoot;
    PairingFlat.PublishedProof[] public publishedProofs;
    
    constructor (uint _merkleRoot) {
        merkleRoot = _merkleRoot;
    }

    function getVerifyingKey() public pure returns (PairingFlat.VerifyingKey memory vk) {
        vk.alpha1 = PairingFlat.G1Point(0x03b2ee7cef5ae40fc93f4b296aab774bb3cc0be59d7d4adedf5c50610ff4da8a, 0x2735ab4f16a82775e8f51cf1d8765a4c90156dc34de6706656c2cdfcd4f2b770);

        vk.beta2 = PairingFlat.G2Point([0x2af3cd454d4d8623c1dade0e8cee3aeaba863285122624e413ddbed7fc39c43e, 0x1a3bfc07ce657af1d9d2fca69dd2196270b5f3b67ab9dc225bb38f090f1fdf04],
                            [0x1d6f29b571316c7c80a8bb6388882687c9bef5535af5c4f6797e75bcdd197ac8, 0x0a2782a1e189bca27f8a523ac6f2dbe2ba7c7d5d544fb8162acd1d0fd6639e40]);

        vk.gamma2 = PairingFlat.G2Point([0x168a86ca5b4351706cf78dc523c977b634d1d3fdd6b02c5411697fd68cbd48df, 0x248dfe5759065e34d8f671ac55a240ef33f1da036b5ebdd099e4571e55533cba],
                                    [0x2fb9bd14ae51cd6543b83d8df88bfd61c5cae01e3122a9eef9a28f4b79ef37c5, 0x2e8e6ecbccd9dab175a4d1f48e6ee9986bc626a6e0728f799013e7650d21c2aa]);


        vk.delta2 = PairingFlat.G2Point([0x049d7206c3ae809ee79ecdf9194c16a89aba7201dc6ce7c2c624563c2c6e5bd5, 0x23e039c4dffb3c47f2a73cb274aefb3cccc386e01e77d309d305bdc9712728ea],
                                    [0x21f9eae53d3a470bdb6a6b5351e9486ed14aa780add802ba009ef76db65c436f, 0x2ff01bd7f07dc160bc30ce38ffd34ac9d2995d7f404f46e8f65c35a4146c8fd7]);
        vk.IC = new PairingFlat.G1Point[](244);
        PairingFlat.G1Point[] memory IC_A = VerifyingKeyAFlat.IC_A();
        PairingFlat.G1Point[] memory IC_B = VerifyingKeyBFlat.IC_B();

        uint x = 0;
        while (x < 122) {
            vk.IC[x] = IC_A[x];
            x = x+1;
        }
        while (x < 244) {
            vk.IC[x] = IC_B[x % 122];
            x = x+1;
        }
    }

    function publishSolvencyProof(uint[2] memory a,
                                 uint[2][2] memory b, 
                                 uint[2] memory c, 
                                 uint[] memory input) public returns (bool) 
    {
        
        PairingFlat.Proof memory proof = PairingFlat.Proof({
                A: PairingFlat.G1Point(a[0], a[1]),
                B: PairingFlat.G2Point([b[0][0],b[0][1]], [b[1][0], b[1][1]]),
                C: PairingFlat.G1Point(c[0], c[1])
            });
        


        bool verified = verifyProof(proof, input);

        // uint[] memory inputValues = new uint[](input.length);
        // for(uint i=0; i< input.length; i++){
        //     inputValues[i] = input[i];
        // }
        
        PairingFlat.PublishedProof memory publishedProof = PairingFlat.PublishedProof({
            proof:proof,
            publicInputs: PairingFlat.PublicInputs(input),//inputValues,
            verificationOutcome:verified,
            timestamp: block.timestamp
        });
        publishedProofs.push(publishedProof);
        return verified;
    }

    function testNegate() public pure returns (PairingFlat.G1Point memory) {
        PairingFlat.G1Point memory A = PairingFlat.G1Point(0x0215e5cf8e270febad5b854a870e202e071eb46ec1c4c6032250ffb475e32512,
                            0x044da0f49cc7bda29b5c4673e8b00535155f8c25201c5e386dd6614fa28affbd);
        return PairingFlat.negate(A);
    }

    function testScalarMul() public view returns (PairingFlat.G1Point memory) {
        PairingFlat.G1Point memory A = PairingFlat.G1Point(0x0215e5cf8e270febad5b854a870e202e071eb46ec1c4c6032250ffb475e32512,
                            0x044da0f49cc7bda29b5c4673e8b00535155f8c25201c5e386dd6614fa28affbd);
        return PairingFlat.scalar_mul(A, 100);
    }

    function testPairingFlat() public view returns (bool) {
        PairingFlat.G1Point[] memory p1 = new PairingFlat.G1Point[](2);
        PairingFlat.G2Point[] memory p2 = new PairingFlat.G2Point[](2);
        
        PairingFlat.G1Point[] memory IC_A = VerifyingKeyAFlat.IC_A();
        p1[0] = IC_A[0];
        p1[1] = IC_A[0];//PairingFlat.negate(IC_A[0]);
        // p2[0] = PairingFlat.G2Point([0x15529a9003e4bdf2832ae2704286a350040724cac30994161bd12087b917ad5d, 0x1b8889e9e289302cd43aac48419e92cf0c8602a34fd09a3fe1955c2cf4cbf0ce],
        //                     [0x250c62674492f7a74ca73c8b17d90e9965587a143a8dfb03de771d8139e654e6, 0x17cae475e9a11bc789850846fe3b0a5ea5a06fd7968d4bd08e80924bd5fb9ed7]);
        // p2[1] = PairingFlat.G2Point([0x049c29fa10b127d2dd44e6b71c6ed1bbe776c5d81955701a880c4ff35b62d8d2, 0x2916c6f3c04d1b76f275891e2b5ec2e867778e217d16d14f4d13074b36586aad],
        //                             [0x24d7d9fca1c935b4d0c51d09a79ab1c372d1562ff53487200b2ec89cbf785bf3, 0x1c5b48d2bb7d8423079639f868bae98f6d6a1b4b5ed67b6ce40f0ff1d24e254a]);
        // p2[2] = PairingFlat.G2Point([0x057a28d58523a79f55de659e1edfe03bfab9c898e85846b711a5a8a4fd68b41b, 0x0105f4d636cdf47c760cde5b4572739ea77d04054cdc0f1d71c2bd1d76a833ed],
        //                             [0x192dec0501bf9495f32f288be3b3986411818b2d624dca4e7790381bba53fb7e, 0x2e85c3277858b368f343a6cda9e6bfd786fe908d48b955a06c51dd672c51fcd5]);

        p2[0] = PairingFlat.G2Point([0x1b8889e9e289302cd43aac48419e92cf0c8602a34fd09a3fe1955c2cf4cbf0ce, 0x15529a9003e4bdf2832ae2704286a350040724cac30994161bd12087b917ad5d],
                            [0x17cae475e9a11bc789850846fe3b0a5ea5a06fd7968d4bd08e80924bd5fb9ed7, 0x250c62674492f7a74ca73c8b17d90e9965587a143a8dfb03de771d8139e654e6]);
        // p2[1] = PairingFlat.G2Point([0x2916c6f3c04d1b76f275891e2b5ec2e867778e217d16d14f4d13074b36586aad, 0x049c29fa10b127d2dd44e6b71c6ed1bbe776c5d81955701a880c4ff35b62d8d2],
        //                             [0x1c5b48d2bb7d8423079639f868bae98f6d6a1b4b5ed67b6ce40f0ff1d24e254a, 0x24d7d9fca1c935b4d0c51d09a79ab1c372d1562ff53487200b2ec89cbf785bf3]);
      
        p2[1] = PairingFlat.G2Point([0x1b8889e9e289302cd43aac48419e92cf0c8602a34fd09a3fe1955c2cf4cbf0ce, 0x15529a9003e4bdf2832ae2704286a350040724cac30994161bd12087b917ad5d],
                            [0x17cae475e9a11bc789850846fe3b0a5ea5a06fd7968d4bd08e80924bd5fb9ed7, 0x250c62674492f7a74ca73c8b17d90e9965587a143a8dfb03de771d8139e654e6]);
        return PairingFlat.pairing(p1, p2);
    }

    function verify(uint[] memory input, PairingFlat.Proof memory proof) internal view returns (bool) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        PairingFlat.VerifyingKey memory vk = getVerifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        PairingFlat.G1Point memory vk_x = vk.IC[0];
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = PairingFlat.addition(vk_x, PairingFlat.scalar_mul(vk.IC[i + 1], input[i]));
        }
        return PairingFlat.pairingProd4(
            PairingFlat.negate(proof.A), proof.B,
            vk.alpha1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        );
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            PairingFlat.Proof memory proof,
            uint[] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        return verify(inputValues, proof);
    }

}