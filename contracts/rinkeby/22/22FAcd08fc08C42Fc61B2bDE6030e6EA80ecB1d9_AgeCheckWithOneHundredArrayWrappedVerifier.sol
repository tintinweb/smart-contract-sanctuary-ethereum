pragma solidity ^0.8.0;



import "./AgeCheckWithOneHundredArrayVerifier.sol";

contract AgeCheckWithOneHundredArrayWrappedVerifier {





    //AgeCheckWithOneHundredArrayVerifier.sol
    event AgeCheckWithOneHundredArrayVerifierEvent(address _verifier, bool result, uint[102] inputData);

    function wrappedTxVerify___AgeCheckWithOneHundredArrayVerifier(address _verifier, AgeCheckWithOneHundredArrayVerifier.Proof memory proof, uint[102] memory inputData) public {
        bool result = AgeCheckWithOneHundredArrayVerifier(_verifier).verifyTx(proof, inputData);
        emit AgeCheckWithOneHundredArrayVerifierEvent(_verifier, result, inputData);

    }

    function wrappedTxVerifyView___AgeCheckWithOneHundredArrayVerifier(address _verifier, AgeCheckWithOneHundredArrayVerifier.Proof memory proof, uint[102] memory inputData) public view returns(bool) {
        return AgeCheckWithOneHundredArrayVerifier(_verifier).verifyTx(proof, inputData);
    }
}

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

contract AgeCheckWithOneHundredArrayVerifier {
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
        vk.alpha = Pairing.G1Point(uint256(0x1e2deba1037f31a2469a953ff5a9ec2df8830c2a2a37068b027837facf4e4803), uint256(0x02846bd7a3ca70d92275d557121c6b0ce20ee87976af65f270a6efb7cad12170));
        vk.beta = Pairing.G2Point([uint256(0x27f2f9905c7065b6e6515257674c7ab230a711c4bb4d940bc3633f3c162ffe2a), uint256(0x254fa731ba2aff20129e77474ac7ec716c2c3cf595ab42baa4fc66709483cca0)], [uint256(0x228594dc45544553d4d8e903584b94c36a197540edb656d4aaef5c53abf3e75a), uint256(0x05f1c0d7094fb8bb7557ac86e7e44953262b2cdf65875ecc80dd19d7861a0cee)]);
        vk.gamma = Pairing.G2Point([uint256(0x029ee658b5934222ae2d4049536e25da7eb71d91a9338059eb38594a70461bde), uint256(0x1276a8d51c78b9e0bd64612e6fdc7aadebc7b87a1e5cdfdc5416630cadb4bb53)], [uint256(0x169cd06d9b3423a3c500088d4c727d4852f46af649feb425a13223115ba5664b), uint256(0x2fb53204a916cccb1145bb2bce110431c23f83b6434e34fd9600d86ad7423bd1)]);
        vk.delta = Pairing.G2Point([uint256(0x14d46a1541342a9025c7a92b922db724458890a52181bc978177ff6930135797), uint256(0x0c58abb894c0efbed234944ce6e588f20b405a87cee244c29e5b650729bc7ab5)], [uint256(0x1a7a3978123822c45f282d885f82b3d9e1c1298161fb6cd7eb4ab63c2bbdca14), uint256(0x0bd6af9e0e856a3828dbf051d9d02b5500377c8a79cc43ef2cddfcc1da3132bc)]);
        vk.gamma_abc = new Pairing.G1Point[](103);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x217c613e9f8eda31dfadb52802cfc998daa2fc8373c2bee19255b6e39b7f0273), uint256(0x13b233f06d8469d864a24d840d44186488b72bc4e89a9848583d00d2de5a7c8f));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1f2185f66f3bc81c4748b14331526e8f3576cb73ca36a8fa738798f938cf4782), uint256(0x1d1a21873f391fd596100393965a526428e2ce2c7e27939a782967d1c8922b3a));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x04831f9670b2db25a76a51acfda553529e85d254a803736252f7490366301fab), uint256(0x26d8b722091843953960bbdfd62ae2191f50e897a9317aa2b56c708636f446ac));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x0f10440f37697bf229e3cd77a33b74a28bc516a64b1a6ad084d777f7b295120f), uint256(0x203ce7d9225663626572cf6e7192edb1ba86c27afa0492a9353bd74cd2b99b16));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x17b375ecf311719299d4a4322253c8d69ac4ebf47613bf5a05db73df0e199d0d), uint256(0x2f79f265ad478b6778f840caa77e04c26aa90897d20904372b5f27971f3517f3));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x1c72ec8885d0eb63bc6131d7cb0bae44d03f71f61001e48fd940b839183317f8), uint256(0x2f2b30606067c853c3b49d29158626a8ce2d67855e523843fcb06556ed87e674));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x2665024eee834bf4ce7a9ca3285a24da2cfbb7229800b8b51f911baf6ce6c7e7), uint256(0x22b9d5270e55ae145a591c5d7088b85255301864d7a1479cd1190b908dd68b00));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x156b5088178c9d0542363d9eeb3d3bdc31c0971e43ac0b3ba973cec1925839e7), uint256(0x13848ac46540aafe9348f05b38349666c1d558e40f388f88b4603003089cb3c5));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x098ef40decae14178850659e6dcb4cb6653f6fa2eaa3a24ae11102354897411c), uint256(0x2c5b1f99fb22806d1901918b7c014bc3a915b7665b423854fd5d7f27834aba07));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x120fc688bc7c855208d5a80b9b1423c14c4b2ca7e0fbcb94a3b3b643d286b6fa), uint256(0x078b5f99bfca343fbc6a9cc0b12047e84ba641f811b0d1b758ccf5487eda578e));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x203b2cd8cfa7edaba51756be1fa7d13fabf2ea34317c61eb32ca928b068233d8), uint256(0x0a704a51c685cb9c05649e250f972d643f6a47352c2578b9634c1671f7388143));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0b1a276c1c9de7efa58405a57713d525e38deee8916af641a89968721cece945), uint256(0x1b548d9bbc0f0f61447a5bdb99a9f4e725a27e594323761bcf0aebb4dcd759f7));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x16aa36dabfa2b8057e3ea7c4fb286ff933167128df95f717127692119ff74cfe), uint256(0x080b44e5c60d1c23f756d91a7135814dae15195db38f24d9b984173d05e098c5));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x279f1a085ae53677aaefcf447782fbb2b12299ffb81082e68d90f82fa49572c6), uint256(0x09f43411d125537700979b78cd37a108049c57fd4c38720a52ce61bd75806ba4));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x06b866585dd85eb02fdd10a7e3153948072e45f998add6faff35ce70c29ad18c), uint256(0x08c79f7fc618997ff4421715a3eaf958b3c56c0b07536ecf7f49c1be745da767));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x25dc23cb3d822b144678c9fa1c99e98cacd4da37c9dd74f39757693008b84767), uint256(0x19fea042d4dcde84a928a5cf31612e8b12d570635a7c921b99a5cfb70c9d358f));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x28d8b215e2e1891f9176c7a5c31ca8fda830e469fda2ca0f182812bd08a48209), uint256(0x17a72ce33fa54d8510977c205ac2c3479aa6997df5bb81c363353773224d94f8));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x2281f197bad76ab43d19f5b08941c45c7cf8c574741082ac5030bf1dffa279fa), uint256(0x1a56703b1aa1288681f0e7b2051d28b5e56a9150cf404b2d43a6669ee4ac2901));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x161b76c53074d7afabb1e8edc11c5f053d278d765417f4e3b4455fbe2dde7bba), uint256(0x1a466efc4106a9b5b52298c31337ea2a1ee3e65c51b7c5a13fd50fcf789a0ff9));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x1dcd4843c8f10e161088e991276eecfee5583b71265045094142084d6edd32c4), uint256(0x0207e53705eabdfd265d46d25683338f37ae9a90efe8c50a7c71c964ecfe222a));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x2893d10c0130d7f69a43bad24c34edaf8599fae7f484c4d023a1d10d4f103030), uint256(0x1fdca07faa56a713cf9ebd5b98c836386e02f8586b4e5d982e5d8cb629216783));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x17dd5a089810d08b9326c023e5d5f18461292e0d4a25017c382282d6fd73827c), uint256(0x271a4a9e6b62bf65f99599bd160f023e5731d2e18844d37e23c1a15f45c24aba));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x0bb2c5d5d0fbd06a4b803ebafa69594ad9ab681f834cc2825efe5194a82965f9), uint256(0x16269c482cf664628478aef09f9d7c89540032f76989c0ecd1ed8a828cbbfb12));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x2a499a43a5a2b500f48be4ad21f3333a9cecec63f94fbe9a6ce250919b9c3582), uint256(0x24695365748e392c90993d665798868221e5e0cb9d7ce3dc7a1c912db66de223));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x0d85ee08ecc38980f9dbad5aa607dd9417aaddd776fd421fd2f27d5bda90a323), uint256(0x110b9279a4b1897c29cbcb44e6e4b4afb7c8ce95535734f8734c75a911edac54));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x08f990d11323f43215bbcae1dfb64e8d0e36e522d3518243c0c1f4a97eb4f4b8), uint256(0x2fc5015914a3355f995e6a8a957d4b846dea7e6b6ebebfd2efd90b66db7b994e));
        vk.gamma_abc[26] = Pairing.G1Point(uint256(0x08ff0b8f419b5c79590530cebb217c213e013fd24da6bcb37f320384a7d7381c), uint256(0x240e25cbc9200c8d28d3bdbfdc49392148de10afebaea256a91e7f4a860277c5));
        vk.gamma_abc[27] = Pairing.G1Point(uint256(0x15c7488d457335751f71be58e7d1fbfb0352ce2c046cd26dfccaaf94c455cd9c), uint256(0x00f33dddf0af68231938dc8dba9cd64c115ad69506a8f0e6ae203ea1328ed073));
        vk.gamma_abc[28] = Pairing.G1Point(uint256(0x2e71bd84ec2420e5d7c9e437206595722b1b1560116dd600269b2ba7eb2e8b80), uint256(0x114b25651d9f32dc0ccdd63726fbc733464282f1672ef51f7f684087e37bc9b1));
        vk.gamma_abc[29] = Pairing.G1Point(uint256(0x1aa7db91cb946a415cf5953518334bbe1f770d13a4bb640882dca79f16d3b4f7), uint256(0x04af399e5bed8f14de383f6788e4cf7d043325fea8c4a2d2ae15468874a81bc0));
        vk.gamma_abc[30] = Pairing.G1Point(uint256(0x1a0223eedb938611206d17f2cc24707b494243007621f948df160519d3db72e4), uint256(0x1fcff0471802d1f814b3e546ee21aa988408d7b23920124dc5aabe796f3aa4ef));
        vk.gamma_abc[31] = Pairing.G1Point(uint256(0x16ed4d22ac6aecf54dce11e3586a6246eb51612abe007595f6f87e50646a92e2), uint256(0x16a0c23072a0b3c7dbefeddbd61623898410a41debb1ea009c6fec4b64ca5a6e));
        vk.gamma_abc[32] = Pairing.G1Point(uint256(0x135bb0719e6680114062a00b008ae46fcb96809b17c9507097888c8b45be89e0), uint256(0x0d68e573b0a78799121445016038a239e1c585e97af89f2fab82ac2d12e15032));
        vk.gamma_abc[33] = Pairing.G1Point(uint256(0x2dfdae8f04968ab190ed85d5c2f92aa51941f7648e3c23809dc22a27e24490dc), uint256(0x01c5949b4be091d788572e2d2ae47b465495baa2e970182331baa22888cb61ee));
        vk.gamma_abc[34] = Pairing.G1Point(uint256(0x138930c3793d630fccdfa94ca5a929d261c0c401036c7bb4565066fcd76ed230), uint256(0x1087a986e38ad15d3dfa218ca9e7afcef3d1bc3b81019ecacde7ed2954fa0710));
        vk.gamma_abc[35] = Pairing.G1Point(uint256(0x2347c15cdead161e1153891a92ab801dab109964d07f195af9341f4ae6657a55), uint256(0x1aa822953d3f4f0c585c7b9a4f63ca0c630c309c11893c2efbd2196e47423b3e));
        vk.gamma_abc[36] = Pairing.G1Point(uint256(0x035187a17497edae7a265d1fce5a9f4991f103bfa3d9f7d8f0e70f63566821ac), uint256(0x2bf7bb77804c6cdd4902af3e12c3d3c4bad69f034caebf34fe5ed173fa0fc60c));
        vk.gamma_abc[37] = Pairing.G1Point(uint256(0x08b99f99f8b4e248c95bbdbb56cd9fa1e68a0c9b1e477c97c79c1352503002b8), uint256(0x26b712f85f4aa4a0136cea057452774ddfbb72c56606257e64020704c24680ed));
        vk.gamma_abc[38] = Pairing.G1Point(uint256(0x2981c0ece51b9f66073eb13b3dddcb6c9c55a0f6df08fcd376cf4c21e98785e6), uint256(0x18b9d866f83e1b686e14e7651c30bcc1882be1546f694333c25638240bf8ee65));
        vk.gamma_abc[39] = Pairing.G1Point(uint256(0x2cae7ab264389a79af336d0b61569ffb903673c5f4446c2b7579b4f5afb92c73), uint256(0x086be6b761b88caf3ea42430c0d43a3443aba61bed85ac2de293d66a80148372));
        vk.gamma_abc[40] = Pairing.G1Point(uint256(0x123417059acdccb8d6be41bebd413b5b52a93bfbee9b34c30d703f1a2475031b), uint256(0x2f87dca8637c0997007f21c6adc427f4e528e6371ded601aa3859945b3087975));
        vk.gamma_abc[41] = Pairing.G1Point(uint256(0x156fd58b0db90929dd07e4493b049ec2f3f8fa517e95768026006c3aa5edbb3a), uint256(0x21b9fea9f4aefc69b90c892940c00880c77c55f4a26464efa1681a4dda4a58db));
        vk.gamma_abc[42] = Pairing.G1Point(uint256(0x27a82281fa38bc09f9a36a0a21ec38d77552761decfc203410f31a15ae78fee3), uint256(0x25bd7499158dc7b08e094f2b4c099fc8afe1363d537c8791e576facb59edb42e));
        vk.gamma_abc[43] = Pairing.G1Point(uint256(0x14b0e23df96a993bc2657f0e490e50cf71ce736f7a5af7d1903624596f233296), uint256(0x0dfb8690193b50e422702be5a72a2bb92f00f0bce25c12d749b07e7e2eb58747));
        vk.gamma_abc[44] = Pairing.G1Point(uint256(0x10dc493f503faa1dd88a2709353ea3490bba7d939071797b15dc9b12d3b76c4d), uint256(0x0ef8b02b3671e8d0d59e2b4861c6a6b3011f2e776b3c044d5b621142db2a4c31));
        vk.gamma_abc[45] = Pairing.G1Point(uint256(0x221898fdad2fe2c53a8410c0a3e3b5e335fcc3d55f83aaefed1b8a527559607e), uint256(0x2ad8a55c3c7722b7bbefa884035c78012dd885e000a30307e3fae5ec7ec0d447));
        vk.gamma_abc[46] = Pairing.G1Point(uint256(0x003427b5b9bf3af6598c0e036acb12838051f0efc5b5318661dd52a3dedf9c0b), uint256(0x172c2c64e85291e6a93278786b3be05e958aadf91a0d340e884425c02a0738a5));
        vk.gamma_abc[47] = Pairing.G1Point(uint256(0x2c07fb37b6f2faa1ce7af6a8080d1d8c27828691a9aebd4136827fce67812b50), uint256(0x12c3018d43ba2ac317b90404b152e104b30d15429e5acef8de36609096f73b43));
        vk.gamma_abc[48] = Pairing.G1Point(uint256(0x11f3df4b7ee51f3c8a528e8d0bc99f6ecea784638985adb84db40cdc9b8b07df), uint256(0x2cb5a4e4809d86756020d5f4e366c6f7bd57270242d0683ecb0be109e3ff7e19));
        vk.gamma_abc[49] = Pairing.G1Point(uint256(0x01256347dc14fa89bd37f18b1549dc3070c37ee2f6fcefc76e2a61faebd8060a), uint256(0x26ecf48d00f1ea4db96f97adea38a93ed85ea0a60361030842bc029b6c79428c));
        vk.gamma_abc[50] = Pairing.G1Point(uint256(0x2657bad0fd1bf8e15ab27cc2c471d98bcba6e4aa8f02090383d64cc7cd7a4817), uint256(0x0439e1f21c3a3a7b49f5e2f1a67655b6d0dbc36aa17a67ae1ad498ccde00a4dc));
        vk.gamma_abc[51] = Pairing.G1Point(uint256(0x2763b3891a9ef6311bc57078ad8d096b75cb53b285da110eb8e11ab07c41137a), uint256(0x2235db301a12ae3a2fbfc1ddade7c977ffcde385beed5a8403f4ee10dfc469ad));
        vk.gamma_abc[52] = Pairing.G1Point(uint256(0x1131bb4d8565a48100c46963427f1ac2b22375c1fde2ba1fd9c4d9fd57639c5f), uint256(0x2efa4208fb59e547d85b6489b5b13d9c171306c080e81bc51e87c17d6c74252d));
        vk.gamma_abc[53] = Pairing.G1Point(uint256(0x156c7d44eacd265c37e20c8f4c7f7ea3e0ba17f6faf64c31fd4dda9b5395b8bb), uint256(0x14cc0d7e0dc49dd3ef14247df164642bb9cd37fcbedf9c27f5342d4b3d5a6588));
        vk.gamma_abc[54] = Pairing.G1Point(uint256(0x0fe29e05e5840bdc5637a5d1f83d79b63b3eef2225d715665a8ebd6bc86178a8), uint256(0x149d7c45ecef341333968f2f3f6d9520b53be3f76211f450652e6382907930bf));
        vk.gamma_abc[55] = Pairing.G1Point(uint256(0x18cfdde1530e5c513b43fe58234ecf85a0d373b66d49e0f7a4028e782ebed3e8), uint256(0x25c854af1da572eb6e2bd559331ef11c9b85eba58787018216f4fbb6301a24f5));
        vk.gamma_abc[56] = Pairing.G1Point(uint256(0x1466e150352c747e6912df2eb0d3918203f9357b0c83ae13487bd31aa798e036), uint256(0x1dcf0720f0474db07a50eb10a96d109a38be4a57d114b7722c521e04f8680dc8));
        vk.gamma_abc[57] = Pairing.G1Point(uint256(0x234e6806bffba92a3160d4423321727fa4339990e062e1c73fde0597b13c07c4), uint256(0x1c32398b27f8fdfd24f2d980ba284a0d93f8d31ac4eee1e290d249638bb8bfdf));
        vk.gamma_abc[58] = Pairing.G1Point(uint256(0x16c07a2a46238dcdccb9e2d569ede517ed59500b42ef0e67e77d674527b48428), uint256(0x23ade61af48bc4e3862c09600bfd8c86133b73313f89ac43376250fe2a8fc500));
        vk.gamma_abc[59] = Pairing.G1Point(uint256(0x1ce15609a4a0eca9c286a7d7e20d2600c5d55a79237442b7a6af7381850c1293), uint256(0x096a6ee024fa6b717c4a446c36a5f7565e65d184f6ce95c4d2cfbbc88c91cdff));
        vk.gamma_abc[60] = Pairing.G1Point(uint256(0x01d6b46f0633ed9edc47d46af81df7339d7eb798dffeea0eab000d617efb253a), uint256(0x2593be78ca169c9f21995fdd7fc6d53fce9b30d4a84c296aac3610599404e462));
        vk.gamma_abc[61] = Pairing.G1Point(uint256(0x256dbeff2e0e5ee47ba6823e8f797b63177aaec32cbcf1e447718ab3b62c25fd), uint256(0x03101b0448262b8e2e1ee668ef2c3a90580d3739055db9ceff0e7d4c0f60e022));
        vk.gamma_abc[62] = Pairing.G1Point(uint256(0x06e2700471337306e49018698f79fbc6ebee316c96fd9bdadc757eca2887881f), uint256(0x211a0ad810f534358c47ae8dcd00ff8e84091116e3736b344a7435a6461eac8f));
        vk.gamma_abc[63] = Pairing.G1Point(uint256(0x0eee1fbc100702da38c783d5362c0c41ba8f4a316717fb3433d84b18cc969c2c), uint256(0x2f78fa503d4db80e5722315768d177bd60128ad29130649a37293cf5767a4147));
        vk.gamma_abc[64] = Pairing.G1Point(uint256(0x1c2d1bb383c42478a3a6469e81ada8f5ab0b930cb61e2369e754db0460dc87f1), uint256(0x2eb292b8926dcf5e4cb8930ef73153926a35003263722c43cc7907e326dd6e2a));
        vk.gamma_abc[65] = Pairing.G1Point(uint256(0x2dde50c25162303f423fc3ea52d6772a1439be47452704279a370fa018b276b9), uint256(0x01953eecc044d8210c5bb49922da0ac90d4244bb49ef74c6d0d75ef90ed30829));
        vk.gamma_abc[66] = Pairing.G1Point(uint256(0x0a6102b4826562383a4e678c1f66673ce2a316daf0a6703d76f8e865aa8ea4d4), uint256(0x0ffae699d09c2b6367ce52f7769dbfdb302b58379a4f262dafa19ce3c95b5d89));
        vk.gamma_abc[67] = Pairing.G1Point(uint256(0x27ca2e2556fca585baa3b6b660f6f8ea20a659488039c063d078349995c97d26), uint256(0x2325ee542377fac9a0761edb671a986d01ed4b59384a4a28b5de0737f16e3c73));
        vk.gamma_abc[68] = Pairing.G1Point(uint256(0x1506668b91683baa59dd9f41ca92e59d1489c6cb1d30f333aadeb7a15ab85e97), uint256(0x06904be6fbc75d5cff04afeec7aa5828ba5f83c61bb8eb4068ef8f9706fee76b));
        vk.gamma_abc[69] = Pairing.G1Point(uint256(0x0f5befa00defb3c2c5f6ac31a19327aa81536c773152eb321c57390dd3ad79af), uint256(0x1e22df66fb8e5cd7e496324b19191a4f527b405e5c270e3f3ffa3dd33128d654));
        vk.gamma_abc[70] = Pairing.G1Point(uint256(0x0440af065e55e850554a3d5fd06e2c45e3cf5450c017a3303e734b62f0df4c21), uint256(0x1e119fdc0b47257ca7029ba131f74e331262d9b92e96f4f009a0799c94e0e60a));
        vk.gamma_abc[71] = Pairing.G1Point(uint256(0x12e86035b2600ee3c2679dd66636adefb6d1e78824992f118a33168b8ce6d837), uint256(0x24fe5b575ffea78a56c51c29d1ee62012e0037a8e664e36ff0b4f7d14b0ce9f8));
        vk.gamma_abc[72] = Pairing.G1Point(uint256(0x0704ba8a54f51c708fb9f70d678b4550c87176034ef30c27e865a75ac62c5721), uint256(0x2ac355990cd9ac5d6f88ededfbe4b2c22f726878b7e4984f998f0c834a113156));
        vk.gamma_abc[73] = Pairing.G1Point(uint256(0x0bde263d31e13858b17bd639a61cc40652a74a501d4382c2fe5c710ef9acf9aa), uint256(0x01b1a9fe7ab45a4995023d4f892c36d3f33ef845c2701d6ef3b6b5df71c82085));
        vk.gamma_abc[74] = Pairing.G1Point(uint256(0x1ecf315f5e3a26b790fb296f40d08089af129d4942a5687504f0f7ef99688fe0), uint256(0x2069205f5eaab33288c7d74e99479bdbfc4d7fd1a522b2d493385bdbc6e476d2));
        vk.gamma_abc[75] = Pairing.G1Point(uint256(0x2c7a66634003740c6b8c53d9b5a5a5377188fd4eca280d4c6ad1e2862c84c9cc), uint256(0x0ca0e7f8757aa1b2a9b409ca1ca01ba389297233cc249bcedf2558fc902eee8c));
        vk.gamma_abc[76] = Pairing.G1Point(uint256(0x07256649f18111e4eb859528972a3954746c51d968ba51a300584b6a779103fd), uint256(0x1138be2b94be2a5e5aa67fe214c4008f539d80562bc7ee9aa547ba1ef1ac29eb));
        vk.gamma_abc[77] = Pairing.G1Point(uint256(0x225118932d2c03b0dc85fff2676d3b057fcd14f909fbe48e0abce9f0702816fe), uint256(0x29a04f3c23b1c1acad24553d4f0c8fdc4121d93cdc8b6d6f05fe86efef6701e2));
        vk.gamma_abc[78] = Pairing.G1Point(uint256(0x128bfdc5952f45804f6e0181175374d90b1ff30da7aeaafcd5799e1c21fe34a5), uint256(0x297562d605ce84432b8e6be6ebfa69d7c6c20febf7470e3f839aa9afa2f63683));
        vk.gamma_abc[79] = Pairing.G1Point(uint256(0x27d1d3ae14c5625c932c830213d99a973c0b6176dcd41a3f58365df02215f99a), uint256(0x1133f3bfe514f18aa86da85ad84f434f7df32edaad8716f1e4f3a7bd00170fec));
        vk.gamma_abc[80] = Pairing.G1Point(uint256(0x2e4c2796dbf3a30e402561730dbf8292095340658ebe743d04708e37cf8e591c), uint256(0x23c9a06a800a0967cef559e747c10d2b79854d126e4beae45e61c123fe59e960));
        vk.gamma_abc[81] = Pairing.G1Point(uint256(0x2e183cac23f1c9a5074f09162da281cc3186ba898e4f307f4f141ba1c1384a58), uint256(0x0e01175a9431aea9b937306a0a0a27724bd7e50211aaf5494af4b2db624fb794));
        vk.gamma_abc[82] = Pairing.G1Point(uint256(0x304eed07e12b507cde8984945a2f831ff40586f07f841b85ce33cf63eb7db833), uint256(0x1780c058ea97a6fc08c0116fd345307646a5a7e2d9e9fe023e21b41410bfa82b));
        vk.gamma_abc[83] = Pairing.G1Point(uint256(0x13891a9f162fc1f19a950a0cdbfbd6d42862203c0a6ae3a7ccfca9e01957d2ec), uint256(0x089c146445bd1be0421a63382c99346a874fad17afcfae3c38737f8bab73857c));
        vk.gamma_abc[84] = Pairing.G1Point(uint256(0x1f2dd44db8eb4bc5109bdf876e3f45c556ddb191af492b0149a64ea333f34397), uint256(0x05ae4de3e75316877b13383c018c3834bb953a4937480af7586f1439dffe7f38));
        vk.gamma_abc[85] = Pairing.G1Point(uint256(0x1dbdd5ef2dcf864c8ac1ea5ab4c7084625a856d7d333f0401c52f78068a3948e), uint256(0x053d8b8e05530ff0d372aff388b9c2b06b5ed021343c0fa0f5b495918a94326f));
        vk.gamma_abc[86] = Pairing.G1Point(uint256(0x21807f0674a6fdcbfea33dd921530359849e349a4d013480f6dbe33704b2b104), uint256(0x122e971ca6cf231704d96cdfcb011cffc657463c120cbd160244a5194018d421));
        vk.gamma_abc[87] = Pairing.G1Point(uint256(0x04462001be29d400e80260ba8b239884ed92b67587becea65b10d46784863566), uint256(0x2822a8bcf858f43f35347b3049be47bf5d30430066b8b4af37399f5b8393a3c8));
        vk.gamma_abc[88] = Pairing.G1Point(uint256(0x18ce1edf908e1856edc9218b875d56b95dde50bb5c2077e81ea4a02c36976689), uint256(0x2f679ca6282dfb0e754c951c5b7ef4d5152ee691862002d2b4d0b246012a806e));
        vk.gamma_abc[89] = Pairing.G1Point(uint256(0x05dc1cf56790038a4f2dde59d3bcba7b7ce2802f3a06ddcfbbb72e0054568cfe), uint256(0x1bfa513f1ae98ab61b1706920920889ca09d2215f27f03da35dce3ef4590117f));
        vk.gamma_abc[90] = Pairing.G1Point(uint256(0x2f14dd7e96e0a568fd5053372bcfc684619dc4001450f56bcef7509b8ead61d0), uint256(0x12437fb326bfd7bf265b5191d2f2cd33d920891aa4e3d474e708d527b271228f));
        vk.gamma_abc[91] = Pairing.G1Point(uint256(0x047d66526743143f236c6c81d6effd149ffcfb2588c826b132c41c66749c0c12), uint256(0x18deb12e08d525bf724d7add4589d2031fc5b48a123156403370ba2996733480));
        vk.gamma_abc[92] = Pairing.G1Point(uint256(0x20b9f75c2e75281f6ab0d007734d1c48967775a6c30a836cf6d8a063cffdd6ff), uint256(0x13d0769c3821fea2805701895ec94b0150de3864dd3f3892dae42ac0b6947eab));
        vk.gamma_abc[93] = Pairing.G1Point(uint256(0x00897835426b6cf5461e858ea6eca7cc85382250c55a900c4b389055b13f27ad), uint256(0x2bd9537eacffe2ca5122d95d18bd94f9416981eff6617597d09a3e1a27ea7912));
        vk.gamma_abc[94] = Pairing.G1Point(uint256(0x106149bc92ca108fcf6684c3e811f6c37505651ea7f0d6b8b87de7a8da98d727), uint256(0x2e37aaf9bf76c064dad12808636bea2452ee3f23a39ba7cdf500c14983eaae6a));
        vk.gamma_abc[95] = Pairing.G1Point(uint256(0x1e0141c3d0f09c1b397efab09f662c70cbe7ddbd65de19a1850c8b2fd3c60139), uint256(0x0e15e51e15f3f1fd0ccc719cd44376d40810cebe4bf30a27552038dab2502823));
        vk.gamma_abc[96] = Pairing.G1Point(uint256(0x16ebf2f673ce816c65941380eeffaaa5dc27d2b87561a8bfa7227f6bde9ea852), uint256(0x1a65029c97af9a155fdba66dab7f1bc0fdff9db768469a780e55ee144bf6656d));
        vk.gamma_abc[97] = Pairing.G1Point(uint256(0x2a83705b1213ee978e963402a830c539cfbb6313229ccd3faa16ce2f832803fd), uint256(0x117ce0196ad50d3b76578e3757b21d286730445216333252c9f82c74dc94dbbe));
        vk.gamma_abc[98] = Pairing.G1Point(uint256(0x00107eab4d9268876e621a8531c2951d320e9afeeac0b64106df062cf9e3b0b4), uint256(0x0f5e999a1927d966de5e2b7d24cc76ff47289e2cc9989b1145bffd830976ca32));
        vk.gamma_abc[99] = Pairing.G1Point(uint256(0x0cb97f56b61f179b84f3b55b65b757791cd4565bde99dfa9027502c2205817a5), uint256(0x0f8e388f5d2df9365a6e0f3727bf9b2b52ba564d407031d3860f676a78b36a78));
        vk.gamma_abc[100] = Pairing.G1Point(uint256(0x03b480cf8b77404c14badabe5209ef232ee79a62b789e66c8aa310f3b38a321b), uint256(0x180293eee1ee67b64c16011ceeebe65fcc54a3774e666522fb0f2046c99fdd6e));
        vk.gamma_abc[101] = Pairing.G1Point(uint256(0x0e43a0b30897c3a23036ed80aaa61b72fd5e0d9565ca8f32effa548e0d253cf8), uint256(0x156b9cacac4982202f501e91d63c692ab0c0e302b316fd2d0ac805d368c3e2db));
        vk.gamma_abc[102] = Pairing.G1Point(uint256(0x300c07da39c9165bbcfc889fc8eae264147831366b54591a80810df9c8cc5cc3), uint256(0x2a0e55073df666883ada28c60cdbaddee83f2299cbf074aa97562546dc89071c));
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