pragma solidity ^0.8.0;


import "./SignaturePerformanceTestVerifier.sol";

contract SignaturePerformanceTestWrappedVerifier {

    //SignaturePerformanceTestVerifier
    event VerifiedSignaturePerformanceTestVerifierEvent(address _verifier, bool result, uint[19] inputData);

    function wrappedTxVerifySignaturePerformanceTestVerifier(address _verifier, SignaturePerformanceTestVerifier.Proof memory proof, uint[19] memory inputData) public {
        bool result = SignaturePerformanceTestVerifier(_verifier).verifyTx(proof, inputData);
        emit VerifiedSignaturePerformanceTestVerifierEvent(_verifier, result, inputData);

    }

    function wrappedTxVerifyViewSignaturePerformanceTestVerifier(address _verifier, SignaturePerformanceTestVerifier.Proof memory proof, uint[19] memory inputData) public view returns(bool) {
        return SignaturePerformanceTestVerifier(_verifier).verifyTx(proof, inputData);
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

contract SignaturePerformanceTestVerifier {
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
        vk.alpha = Pairing.G1Point(uint256(0x275af45d46e7eab50f1787ec37f69dbd2609de23aafa208278adaa1ed567a589), uint256(0x20ac7af0d77f162a2f96fb76796c7417e7278b94b489496dd8a7be92fcf12f5e));
        vk.beta = Pairing.G2Point([uint256(0x27847049717b57a28945b0229da1e1ce387bfa6f9dbd5a4d4366347e302fccdc), uint256(0x0cf2ee4db0581c82e41ef5d6764a99f740ee3c6adee7f46ae1bd8c09ca7151b7)], [uint256(0x2d9f9c48c7ea85d9dcdf372d5620682575d0c14092851434d4124d61768bc345), uint256(0x02bde479ab74187dd9fc8680360e326b90151b4ed7a20cd03a706c9b65c1ec64)]);
        vk.gamma = Pairing.G2Point([uint256(0x05c2c7f72de1958cf9a5ecad9dc5e159f9c9278cd9bb22d76fe1bf10d11a98b6), uint256(0x2c965bfb0e91a6817921e6a663d34a6b676aeae42df5f2f9c792ec43d7a72421)], [uint256(0x0debe4a9db1e2dc116c924b55b7ef4cb707cb1c0d97a73862a3132a5b972345e), uint256(0x24d33470919b9f849fa3024a1bd78a17637706364b2be869e8a637e03a30219e)]);
        vk.delta = Pairing.G2Point([uint256(0x1d6bef3b79c9aceab9946b1253d30ff6587862d872c26013c0a80abd6415b391), uint256(0x086fb021bc53e8ce3fe76bf72695f4c0df11e93d3ed7bde8d2844aaff4c229ee)], [uint256(0x043d2436b57939cf5e9544e2ea10faecbd35219b59f8cd6eac8d5f8a9beae48b), uint256(0x29b82ea75dc616145658fc80646bb29f05ee11d87257073ef73c5ba9b3eb9052)]);
        vk.gamma_abc = new Pairing.G1Point[](20);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x14bd36ff05852f8216222bf8f4741c9894b03f36d4dda294f11ad5ef0b95c6f8), uint256(0x0531a3e5b1bd9499d5ce35416b4aee6ae77250e4b5fad4adac2bea7f26e4d85d));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0d5e4cbf7108f93d5e347ca380a2f60a22ded9caba700fd3f486d8e1430ab5b6), uint256(0x17ca469849ae230397557f18ec3422d7ab42485a7351c552af71b58edbcfd254));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x16b933fe27a302269499e8ebaee741c8960e7d6c93e9bada23b51319ef3e5742), uint256(0x2353212cb973ea41838bbf05d217b02b7256680555264fd2b52d22191539b5bd));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x1532351d5452bb04267fedade02f50ef1527b7b7b99996a00bd5d5af3bbb701d), uint256(0x0c2036259343f20d3017362bbb36441b9d848bca3716a268e859dcd8ecee2ab2));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x080586d57d30fa7ab8a1ee2b8dc47f4e304c05fb96369ab7048d20d6f486f117), uint256(0x2e84f5016f5bd9833afb2ce18e451e89e9e4610122af8cd56055dcb647adc004));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x08637fe0f618a05f3ed255c6e25509ec0a5e2bb43cc163dfca2bbbc63eae6f16), uint256(0x1bbe256335c05e15a7261ba257db8998fafbd547492abc229ce04606879b477c));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0cbccface4da15fd16fe262d1ef73286287cba44a51986ac980e401849587349), uint256(0x1fa93c61ca7669b61c8da3fefcd83789ca058df2e89257f1c8bf6b4aca6eb21c));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x11ff47e30a42d9339241a4f3f4410d599b2ae267834c311456d74a25d50c4abe), uint256(0x10c1c45aa2baee88ff648f5ec0ed7e1fcf6bd35a08a0a4277b588e5959d31b52));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x211e8a32f501ac49b5282a6c840adf1c8fcf5703849dbbbefdbedb073c370cd7), uint256(0x289cad478cb751119e2eadc9b2dfc828eb63239b40ce2d473388092418760407));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x190e64856cabb52b89e63358fc33b29cc0b326bc438482037ef299cd1ef483d8), uint256(0x2a253bd71df18016cf629022811071e0df54dffecc3ac8aac9c2774d7a68a732));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x1c28c784275c2e38e9b576745d613b09082ebbdf60c6bcb224b39c7053f26a48), uint256(0x077de7f7ad4115d6e44c06a66423f12c9213d371cded6b053207e163f74f63bd));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x22e0260989a3fb736f370d8461f34a10fd68b76cb7309d2a90855495d7918003), uint256(0x1af58a4c6b35def6975c151422337577544365181a9da4c9094135f7dd70f511));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x2b528aac1d829c861dc6a6e24bddba8f3a39d5fc572c8c412ca773eecfc1e255), uint256(0x0119b92cfec1c06fb5fa038653a9d6a34a5e25735054767c50f777dc203ea90f));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x227a340254b2db4415d0c66c5d6c70e2f67a6b48bc086213abc05a7d797f10a9), uint256(0x0bd8e13b79918a363264342d010de4cab42b76cbe09d6a4dcd6b5b795dcea257));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x1241970fddade28a6c821db52321c4ceb9126c07e74d27e201db27053b9015b9), uint256(0x0e967f7b956189094f5fc56346f8c78c9c27af931dbd13bb65e73b6c3d1ce880));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x20effeef7e6b626c36658c1db55698cb80ff907fadd2d704b8e2042e995384d8), uint256(0x0236449a384367d5af6543d3cbcce96b475e890b22aa4df910bdd6ea6ab560ee));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x0e77580df395b217c1499df96d369058d6df661ac0fe6f77592622a8964bab96), uint256(0x0be107d87b0ccd9de204bb904097b534c9235421d2f750a17ebd9ddece0f2e42));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x2eb25ac56bb565cd74966f79b9e43d40a529afc926e14915cd9151742cf51539), uint256(0x0fd8318bbaedc2bd6737aeb34a48b1de8f3c7687dc47986491766c2f73f4a23d));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x16fc65ddf67bc8ac3b4a36aaa91167c36d80853c7c510979df48619e2921b598), uint256(0x11bb60c6827785d1627f9dcbc5cd1ef433909b5919ada52f0d18420b87ce2af7));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x184d06feb75ad649590004b245961f80162ae70ae8c712c4eaad8ec69efc0eeb), uint256(0x1515016e0264564a526ee89f1939d2aff2ca98903e8343d4576e1a6be42d159c));
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
            Proof memory proof, uint[19] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](19);
        
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