pragma solidity >= 0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



contract RescueHash {
    function initialize() external {}
    
    function rescue(
        uint256 message0,
        uint256 message1,
        uint256 message2
    ) external view returns (uint256 result){
        require(message0 < 0x2000000000000000000000000000000000000000000000000000000000000000, "rcm0");
        require(message1 < 0x2000000000000000000000000000000000000000000000000000000000000000, "rcm1");
        require(message2 < 0x4000000000000000, "rcm2");
        message0 = bit_reverse(message0, 253);
        message1 = bit_reverse(message1, 253);
        message2 = bit_reverse(message2, 62);

        uint256 state0;
        uint256 state1;
        uint256 state2 = 3;

        (state0, state1, state2) = rescue_mimc(message0, message1, state2);

        assembly {
            state0 := addmod(state0, message2, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001)
            state1 := addmod(state1, 1, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001)
        }
        (result, state1, state2) = rescue_mimc(state0, state1, state2);
        
    }

    function rescue_mimc(
        uint256 s0,
        uint256 s1,
        uint256 s2
    ) internal view returns (uint256 ns0, uint256 ns1, uint256 ns2){
        assembly {
            let p := 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001
            s0 := addmod(s0, 0x2e827c42545887ff44c8e94bc429a6b9fba992c691596d3e97216a720f7b48ac, p)
            s1 := addmod(s1, 0x03c75f89abe4ca0baf0d7fa782a1c0b7d06953671bbbf7de43257c6dc6e54dca, p)
            s2 := addmod(s2, 0x19774ac9566bf383567f7362d1c8e62d4bba886dec26174637c734be0df06cc0, p)

            // y = x ^ {5^(-1)}, for even round
            function sbox0(x) -> y {
                let m := mload(0x40)
                mstore(m, 0x20)
                mstore(add(m, 0x20), 0x20)
                mstore(add(m, 0x40), 0x20)
                mstore(add(m, 0x60), x)
                mstore(add(m, 0x80), 0x26b6a528b427b35493736af8679aad17535cb9d394945a0dcfe7f7a98ccccccd)
                mstore(add(m, 0xA0), 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001)
                let success := staticcall(
                    gas(),
                    5,
                    m,
                    0xC0,
                    m,
                    0x20
                )
                y := mload(m)
            }

            // y = x ^ 5, for odd round
            function sbox1(x) -> y {
                 y := mulmod(x, x, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001)
                 y := mulmod(y, y, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001)
                 y := mulmod(x, y, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001)
            }

            function mds(t0, t1, t2) -> nt0, nt1, nt2 {
                nt0 := addmod(addmod(
                    mulmod(t0, 0x2bec9c48301bdaaad9c72a3d8c4d363ac8be8189ccea49a4c0bd8c37d1c6b3e3, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001), 
                    mulmod(t1, 0x1f069c8a0ff22a1e62469e5f812fe7aca34de4c88515d84c9a1af9e21f5121a8, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001), 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001),
                    mulmod(t2, 0x0d5365c702a1d156ecb069c1a5b6f3fefa94d552d01f19e0cea4ba91e4537c0b, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001), 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001)

                nt1 := addmod(addmod(
                    mulmod(t0, 0x1e4038a58dfdab6147e951763747a13f5e5599737bfa3c30d4548a366740959e, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001), 
                    mulmod(t1, 0x07cf3d4093243419a52e08fa9416458849e98b266a981933f96649f53f7824e3, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001), 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001),
                    mulmod(t2, 0x116b9e8295f0086e020f035edc4ec2b5e65187597edb3d37de19589968b8d95a, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001), 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001)
               
                nt2 := addmod(addmod(
                    mulmod(t0, 0x1e2a87b6b95d6c53a4ef91c0f455ebda2d3b80bff560df8afc804813c15542fb, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001), 
                    mulmod(t1, 0x16e10361cbf35fe8e9c30527df038594e611b03897f65996a6986e51cfe3a96b, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001), 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001),
                    mulmod(t2, 0x1c794b13d4b66d9883849539f556b020117666918dae1210cc4c713c4137c980, 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001), 0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001)
            }

            // round 0
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x043d62d812dac074cba7666e4e024bd24b52084db7832ba740cf341f0be88470, p)
            s1 := addmod(s1, 0x04e8b099362f0cbf4e86b5ab59b734df49286bf95a0493af4d222847faf89051, p)
            s2 := addmod(s2, 0x07e7156a711c0dce97e1bf3c92c66869fc8387c3ba93baabdeb7935e9229ef94, p)

            // round 1  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
           s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x1d4418eb293b45bcefea1ab6c2e25773ff151b61e1c717d50bb7cbe1317dc565, p)
            s1 := addmod(s1, 0x02cf0956c2566ed0c0483b06b6a17debcdebf16c0858597850bce1a4d10a525c, p)
            s2 := addmod(s2, 0x0faa7ae09629bdacd212b1450943445a93ab4e10559a901fb33ff8ead7ded122, p)

            // round 2
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x1020d9f9e31ac33accebdb8e7127dfa69f0cb13d16cea22c2afa39189b8eebc9, p)
            s1 := addmod(s1, 0x0a686243a889e0adc19b413a6882897dd0d13fb983e3a6fe355beff21a91d184, p)
            s2 := addmod(s2, 0x1c83e8b36d64cc64756872d4c714124768390d6aacee13e616f8eebe854ef9eb, p)

            // round 3  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x2c24954fe8789a1dc0e4612d12d96b278d3eefd1015a7adb9a1d94bf8575f418, p)
            s1 := addmod(s1, 0x113b0d59035669b65c2bc5cf6d4dfccbfaf068a8324713b8cb287728eea9fb09, p)
            s2 := addmod(s2, 0x1eda7697977e5ff6d190473db97c8129c24a01410747a5953d01ae41f1201fa8, p)
            
            // round 4
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x06336fa6da86fea1244edba9a602817992db494e8ee4cd1cdd5cef1e31a457ee, p)
            s1 := addmod(s1, 0x1cbb120a8d2384f98b5f7dde5c2d9a46c74f3f8f077447275a97feb851e923af, p)
            s2 := addmod(s2, 0x292a5b37425d93e01103d182e196c91f6a78de6fc8706045ffbe5e3b4113c475, p)

            // round 5  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x147729a654c70dfd83d0d6734d4eb1a28d5fe971f8fe4b04a923d38611b2ba51, p)
            s1 := addmod(s1, 0x11c91cdf81970c31ae841646c8c8af01b5c86f8c553b92432c04375882981f74, p)
            s2 := addmod(s2, 0x0833bdaf9311d54b95fab90c3bda39f93a0489121a83da532041a2fa49802fd6, p) 

            // round 6
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x24c823de84f3c92052667494f19b36bccbd5dfe3c9d9eee699cd820a4eec27f8, p)
            s1 := addmod(s1, 0x2d5e9c028e0d90fbcfcada03edba08a87b08d6ea24850406bf193d370664d429, p)
            s2 := addmod(s2, 0x262a0fb1764ca2a69d54f9587e87736f9f7900eb83de841a3baec1956b7bdc69, p)

            // round 7  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x303b15e35ddb721b8876809e847b8412da4211826fd5442bf4380ea05a01d3fe, p)
            s1 := addmod(s1, 0x0dad6859822f688dfcd68b0ccc95263884c135210cc7ba2aced542d618cc877f, p)
            s2 := addmod(s2, 0x20fb16de97d6fe9025d6e57d1aca4015f8938eed24d309ea45c53a1e44c822e0, p) 

            // round 8
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x290804f3f5d08d175efb5f4610aea2f6312cc0fd813a2158ebc8d39383d6bd99, p)
            s1 := addmod(s1, 0x14182199a12b196fbed8b6c03136354f72d6cb908e35f38977551ed9a396d271, p)
            s2 := addmod(s2, 0x2c23201a5e1e868b224b41ca808f5213bfffe29ac83fbed477032770d188ead5, p)

            // round 9  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0fa4cadd5eb82dac3aa145b52f72f6e557c728e7b0d6550329cbdbf7803e9291, p)
            s1 := addmod(s1, 0x0aa69f987c5d7d59551d8d8149018abcfd349fef82883c4c828fc9c8f7d57d3a, p)
            s2 := addmod(s2, 0x2ae7aeee1710fac62f0f7b8fc31bf22e602656e8f4d201d02f45bb5c5a9ea2a7, p) 

            // round 10
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x17efbf28294d5f6318a7caede8d58ff01a0283488eaa32534391d65432525a47, p)
            s1 := addmod(s1, 0x07d52d080d752529f8bc16e68936c05458b013fd3a2c3ec70c98771efc01b36e, p)
            s2 := addmod(s2, 0x09323e13b19f985d0d1a795b1918a7700eb222bb8ebbe4da30187e28036b96e9, p)

            // round 11  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x241e50fb623a7713097a5f45814cd09148c1b678f51d0b3a3bb84fde2bb12cb2, p)
            s1 := addmod(s1, 0x2ab7da957ae223437ba66e5fd9bef4ee6630e154bd0358a5f3a2062b6c6fb861, p)
            s2 := addmod(s2, 0x128bc77708c998f8fb3cdab49464c1077be69b8d369ea861d1385a6b2691ecab, p) 

            // round 12
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x179ee05447dcf2089971a88243ef7a0ed779d91b1ee62012e15575e6e1b3c5b4, p)
            s1 := addmod(s1, 0x2b14779395dabf0e13b20f90540f25a7bbf056cf3c68f2cc1e9bafe3bc1220a9, p)
            s2 := addmod(s2, 0x27b3090f24d3ec29af7f58bf923f8a131b3c9b21ea57884828d5fedd3dec311c, p)

            // round 13  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x219b7eb539cd8f5e783a1fc07048fce9eb83d1cdc0d3493fc09e56e23348f98f, p)
            s1 := addmod(s1, 0x075941e54effafe29b8a0836ceff2c7f11da4b7932d5a9d779cb2e5a3e2da771, p)
            s2 := addmod(s2, 0x13db5be2a23de171268477b3c246848d6b40906465a8c1a1a8ac4c5e937fe621, p) 

            // round 14
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x086ffc0ed3c8a41b5b882b7982faf2b8f423f8df34d5efc85dd0d387e8cebe44, p)
            s1 := addmod(s1, 0x0bae52cf7553fbcb400ac145ca8062a86bbc982784c9f3a3d8a2dd6b29b5306e, p)
            s2 := addmod(s2, 0x0c5d0c9822e8064b4764dbaa71ecb67a574ab7be3c3034b61b09c3c9dbda5c12, p)

            // round 15
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x09324dbb4fa19d86b4548778edb2ff17d9d1d82fbd47bcde9e4d8bb0c2719809, p)
            s1 := addmod(s1, 0x241d32c2e6a3c0d62c86a8400eb318ea48649f6ae8898f7eaca220cadb16fcb0, p)
            s2 := addmod(s2, 0x03b43fcc68db6c0303155b6ab0bc2dd97120e5f714df7fc91ba125d963ab2482, p) 

             // round 16
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0a8381ff49e2715755131c98a26a277f7107e89d2dae8b0e78fe4e977b9aee8d, p)
            s1 := addmod(s1, 0x249a4becebe8221baa207413a79a67933d620d64dfbbdc7ce5d34827bfe0b2ad, p)
            s2 := addmod(s2, 0x16bb4dafd6d3a0ad48deb10cc96f1e0e39a85226fb82c7ecd4a469f8c651ea2a, p)

            // round 17  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x2571b13b8139341cfbfdfb35331a243e124cf54c7e301dab4221d661efaa3b8a, p)
            s1 := addmod(s1, 0x1f082b11fd4514d0dbebadb200384adff84b6d786527f842e5f97307b7a3f66d, p)
            s2 := addmod(s2, 0x12b36359c0b3a84656219c6d450a88e9732a6a776a570673a5229918c5bef10a, p)

            // round 18
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x22fa7160d8e1135bd5181d3e2d761f7fd45c042ad4f0d9e60c6df50759afb82f, p)
            s1 := addmod(s1, 0x1c3fba7f717ffa81059e88c6bb9d4489aed9600e8ba037bf522e1b45384d8c70, p)
            s2 := addmod(s2, 0x1c56fd26e55afa44f2fc6d8f2d508a06676ac05614df9b175da02ece31040d88, p)

            // round 19
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x1df86d2ebe9bd9074b9e857c5d2f746ab70629c22c213c91fa51ff1bd174b475, p)
            s1 := addmod(s1, 0x0c3cee4e1a0d78b7e1508406a11515d2f8db2124486e260f13255fe4c43df747, p)
            s2 := addmod(s2, 0x2067e59f65bbdd4f072c4a1f15c5d417547cec2fb50ac7cf669e767239575ffc, p)
            
            // round 20
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x2ef209879e17db4b4270b59c29a5f894a2711b4e29e1ee82ce24796873590e68, p)
            s1 := addmod(s1, 0x274fd928d6080deb05be861c58972b786c99736442c34bae4fb7a5cc4d947eb4, p)
            s2 := addmod(s2, 0x11979c252ae6ac6c9640e6760af80b50e958b09e921dd03e6389ca890891c913, p)

            // round 21 
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x267082663cdcd184ed30a3f2b6c9e0301a9ead5f52b497c793f2eba170ef54e0, p)
            s1 := addmod(s1, 0x2d0667da81aea5237be170fecf619ded19b841e3471b9b80a20d19be17981d43, p)
            s2 := addmod(s2, 0x2815464fcc9566a3a53a180d6fb8d7c028ea90eacdfc0df2ac71f518ab79a617, p) 

            // round 22
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0bd5a8700ca30de6f9f760e74c6930744fc206d27b4d2ee35d0a2f0e1130deb2, p)
            s1 := addmod(s1, 0x18a10c4f55b6311dbbd44ee961ed0dda628c3ebfb2098f4b9098f28e8899bb23, p)
            s2 := addmod(s2, 0x28a57a4a66f72150f1b61e47dc04124db7f88ccbcbe852f8d95529ac4ada28bf, p)

            // round 23  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x160e287a5ab0869feb86b55a1754d8978824d2ddf9fb3432feb24196e64e6507, p)
            s1 := addmod(s1, 0x1f8d9bc1be9bb169c4f2e882ec0a52c0a11bd7a01eaf65cc47334ebb6afbca12, p)
            s2 := addmod(s2, 0x29c392cab71cfb9692295ed3b56bef36cb4d6a636cf2158e968cfd1a854a302c, p) 

            // round 24
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0cf1c91a22e683c1443881d104fdde8161ee66bcb468a667e511dbe0f492293c, p)
            s1 := addmod(s1, 0x2ae4874d96c7c84a3d9f6926340abdf1e31555d4f504e9a06dbbcafb211069c7, p)
            s2 := addmod(s2, 0x02b0ad5c08cb10395d2d12674834ae08be8e20d512d258c054f90164db4a6572, p)

            // round 25  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0a497b74786056ba4335749abebdc9ed22dfcf8fc5a425b7496bf1acedd86110, p)
            s1 := addmod(s1, 0x29d3c40517092e92ead3e510ca0855c1620d5f9152d5d524c43ab0fb5d3d855b, p)
            s2 := addmod(s2, 0x1205185af96147aa3e3d7ab586c0998006ff5265952071f893b508544b13c7f5, p) 

            // round 26
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x10cfeadc8cd3196a08c0624e279c9b4a46755f161bc914764f97a8319515191e, p)
            s1 := addmod(s1, 0x27792e3c522f9f78a9296d9172207a644856f607df91603b9dba0f63d64d4f04, p)
            s2 := addmod(s2, 0x276c221946ed59247fccd06f4f2b8e1c075d7ba2f1199ac1009b2637ba7e95ba, p)

            // round 27
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x07f97f0b29d227dc5e467417682e604012474e29195ddb2995935933e2c145c3, p)
            s1 := addmod(s1, 0x23999e25e79086ed8a533932ad49da9406acf7aa488b9457967301514560af54, p)
            s2 := addmod(s2, 0x23c70014ae1555c31bcedbb718e6da69897d74d8cfe000e094f8b670642f7ab7, p) 

            // round 28
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x2af92d6b81674d250c6f66621bbd9f8b4449a21c18ffefd9032b07880433a60d, p)
            s1 := addmod(s1, 0x1baabd1b5e38855f595d16ea11cc2827e8586c7ce0a50ab7e318b093da5b4984, p)
            s2 := addmod(s2, 0x2d49d4ed96f91184e58a897daf48902b1c96ad68b7799931364512646346ad82, p)

            // round 29  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0241072649eb7fc60f4214df7d6fd80048d8bf97419453c26c5d3f576a46046a, p)
            s1 := addmod(s1, 0x12adde3c8f4411488d475eb14245393580080fadb544369c91a284362da953f5, p)
            s2 := addmod(s2, 0x2d9ce38e088cc3d8e5d783d78ef557ac3f6b29c5552572808d2eef43342f9077, p) 

            // round 30
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x1d96452671994e1602a77c6a6268ffd7ccdbf39e527d19642dca86dfb1769085, p)
            s1 := addmod(s1, 0x01da79fbce33ec6ddae14375559290f36db35163021169b08c68318cf351df2d, p)
            s2 := addmod(s2, 0x2b9589381bf636ca778f7d40335fb169fb7e7957afd8c54ba4bb66bb89d7efce, p)

            // round 31
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x15438d653cefa32fbc3fbccdc3da2abc063d75aee95f4b9ab822db035f34161c, p)
            s1 := addmod(s1, 0x11a38e9b2f0a2f8230820ac0a75846c828e8556b2d4bb0c719e8689c6cb2d742, p)
            s2 := addmod(s2, 0x20aebd8eaa2ba10c40c2039f5278de49cea826c250b75f315f7cca82fe1bcccf, p) 

            // round 32
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x2805f77ba0f90bfbf214effe5faa7f9a3bee2eb6f19719360aec0e609cdddbb7, p)
            s1 := addmod(s1, 0x1f35fd366f894caebdfb7aecc3a471d014d524aa6274bf7dd7c98703f632b7f1, p)
            s2 := addmod(s2, 0x1138a44eb81c2ded4d764b2d8126f9eced927c29716e8a23a18d268ff3e364bd, p)

            // round 33 
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x09ea16c15205adf61033488bdb59d17e7613f90d39f6e4b7a97dea7792068575, p)
            s1 := addmod(s1, 0x18642ea66de5b1efd1682e8a5da2e030f97ac8e9d28a8fec9fcac2acf123ad5a, p)
            s2 := addmod(s2, 0x2d00b31b568c5b7305df5d853097ea0a780034e5446db453b433e078cf806ce9, p)

            // round 34
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0bdbdb7dbc5f742e40459e321270221c3ac0fe765e18d1c83c1f12e0e4276ab0, p)
            s1 := addmod(s1, 0x27f0f1e9106b61d0a6be2bce5e1e395a1c3fa169bee228839ccbe21ffeec9685, p)
            s2 := addmod(s2, 0x19a6c9fc9430f3f39ad62e3b6faba355d314bf5c9be58315bd73b94454058983, p)

            // round 35 
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0117d38e94416d29bdabf94450b5681f7604b17937f1b24d3d18baf5cd2913b3, p)
            s1 := addmod(s1, 0x0561af313be692a3b6bab41cbf3ba2ddbe27bc1c4107a602cd7b74924e4fcbe5, p)
            s2 := addmod(s2, 0x17e0bf6748e4591533d3bf82f29eda7c8c23e1b13fb5359576e83983bc7ffd51, p)
            
            // round 36
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x20301abe834d1352fb22a83575e37310b971ff87fd5f8b7c3e4a60e52d77e2bd, p)
            s1 := addmod(s1, 0x2af84be1a167caccf34fe68d6912d28286bc97ef1f595cff131378dbd2e554ce, p)
            s2 := addmod(s2, 0x05ea371f188b0d76868773b89838cc899891790098888b0961cad2561c40306f, p)

            // round 37  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0cf6ce4d9373be9539fb4421ad10b683aee4924adbe827286f4ceac1e4c67842, p)
            s1 := addmod(s1, 0x0aca25eb78a73109d86dff873e22f32df2b16ba89976521eb602ff31b48ce6a3, p)
            s2 := addmod(s2, 0x1377ac6a61a13e8b5d0b03956cf32d499907a6664bfeea10199d8b7642e5234f, p) 

            // round 38
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0117c5b7fed49913c1a4a3b0359c1ffd893a39896dd85c08628455025e36643a, p)
            s1 := addmod(s1, 0x1f51935bcdc7c51b8f74a335bebaef3ae69e06b0db01351c62954a15d1e4096b, p)
            s2 := addmod(s2, 0x2817ee19e12e7566c4221c3527563f333ce95085a67b2fc524fd426b9ec131d7, p)

            // round 39  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0959c2acc31d5651446cec07dcadb4a07eed276dbb9df45c02389d974e1c4373, p)
            s1 := addmod(s1, 0x0312c8f6f38ee402392f6afa130b34a4a27ccf79495043dc24a1f4bb8b09d602, p)
            s2 := addmod(s2, 0x27cf6996f2db864b41af1ee4dc87a9a51e3b1c4433ccb2e76d4e86de1d2b209c, p) 

            // round 40
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x0c9b46ee380ed1497bb40a2400f32552a4e9ef8f8ca2caa54e41af45801fe0bb, p)
            s1 := addmod(s1, 0x25c787129ae25108aead79cc75d304f15e23f1e5bf774f975680691966813e99, p)
            s2 := addmod(s2, 0x0e1982f2eaff67328c5d8437f91432be5f546c3db83a3b3d346529120907f99f, p)

            // round 41  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x2d3d5fc23723cf7eb9bfa2049585623029ca9759728046840123dffe86f6e950, p)
            s1 := addmod(s1, 0x06befe53a900cdcc215e89b77b6d51d72486c5273b2ae704ca10acc3c4c22351, p)
            s2 := addmod(s2, 0x0345abcbd6380b14a5938f4346683fae5749c1c6934444e75cdf7300c90e8e69, p) 

            // round 42
            s0 := sbox0(s0)
            s1 := sbox0(s1)
            s2 := sbox0(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            s0 := addmod(s0, 0x04826ffdef990240d507d26e2789d095729bc9a0a94508d261c36fe53a549bee, p)
            s1 := addmod(s1, 0x1d6dfc9dcf49c371996f6bdf2d2ec503d2b0b4b0775bfce0d988ac99c94178fc, p)
            s2 := addmod(s2, 0x184d027e3c7bdb1f245ef2f98b2b1adf4cd54b54cbdd4fb2b2f9d8342d647b52, p)

            // round 43  
            s0 := sbox1(s0)
            s1 := sbox1(s1)
            s2 := sbox1(s2)
            s0, s1, s2 := mds(s0, s1, s2)
            ns0 := addmod(s0, 0x2062808e98d02369b3360b737d446985455e0a93155a0eec12376048d61650de, p)
            ns1 := addmod(s1, 0x2de847a34da34f6c41d66683572814b1e70c66deafe51b0bf949abde45b9b646, p)
            ns2 := addmod(s2, 0x164ed456b62365fbf715619f80da62933b86aed7522914928a7cfdc1ba3d7645, p) 
        }
    }

    // reverse x
    function bit_reverse(uint256 x, uint8 bits) internal pure returns (uint256 y) {
        if (x == 0) {
            return 0;
        }
        require(bits <= 253, "bits too large");
        require(x < (1 << bits), "x out of range");
        y = 0;
        for (uint _i = 0; _i < bits; _i++) {
            y <<= 1;
            uint256 b = x & 1;
            if (b == 1) {
                y++;
            }
            x >>= 1; 
        }
    }

}