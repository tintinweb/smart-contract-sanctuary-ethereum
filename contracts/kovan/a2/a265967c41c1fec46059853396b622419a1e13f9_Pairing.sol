/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// File: Trial/library.sol


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
// File: Trial/verifier_receiver.sol


pragma solidity ^0.8.0;


contract Verifier_Receiver {
    using Pairing for *;
    struct VerifyingKey_R {
        Pairing.G1Point alpha;
        Pairing.G2Point beta;
        Pairing.G2Point gamma;
        Pairing.G2Point delta;
        Pairing.G1Point[] gamma_abc;
    }
    struct Proof_R {
        Pairing.G1Point a;
        Pairing.G2Point b;
        Pairing.G1Point c;
    }
    function verifyingKey_R() pure internal returns (VerifyingKey_R memory vk) {
        vk.alpha = Pairing.G1Point(uint256(0x2216015fdeef5d5fe67e6d42ff88978b2878561954a8dcb6becd030b2d482b4c), uint256(0x1f20e362784b38579aa5e0f27806efaa03e2ca9b9faddfa17c78127e66b2e52d));
        vk.beta = Pairing.G2Point([uint256(0x0737bdc39497c39ae4997cb6664f6716e2911c290548b96b772fe48a5e487f2b), uint256(0x13b371bbe06790bae2e15dea6cae0c87167a867d250b6567e71caa751253ca82)], [uint256(0x30110e417512e614ced6f0dfd7a02402d14dd58745efd31bc08e95e292a6fe62), uint256(0x0eabf754f1f4001a6231651c7462a439f37ddf2bd9b8696868b16d69f27559dd)]);
        vk.gamma = Pairing.G2Point([uint256(0x2369438d026bd5a897952ce512f10d7a2d5ead13569f22a06acdafecea0d39b1), uint256(0x03d1539ab808ceecc88fce0035b85ac5ac497039cf1e3bd0948e7669190c1de2)], [uint256(0x0ff808265105c53689073b83703c8ae0adac10dbdd808b604e466dc30a494cbf), uint256(0x156772471412ec57a87983b600b7fa840d14ce0686900f4ab49a9275ed87f5e3)]);
        vk.delta = Pairing.G2Point([uint256(0x196a173b8f67913e92e6b176c6248f25c11a8528cc55c03d5688a05be53ba37a), uint256(0x09dd9f623000d4a673adba1ab55a6af50fbf980abd0abb8d7e259d281da246fa)], [uint256(0x038477499d772047e126292260a689017a4b49dc07c95a654314062d38dd67b8), uint256(0x2331545d60b8e46878391e75d0afac82aaeb05230f57050a4b1a0b551bb8c12c)]);
        vk.gamma_abc = new Pairing.G1Point[](8);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x11adcf95ba8c28e4383db70e0a6d16d00c3d9c71b317a5e6b05f7c4f99f1a199), uint256(0x2af8633a3e18ee126bcea45e2a6023db1985b7f8603feffd9b0be98d658078a1));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x205ef47e67fea532120eb4730e2f453567f0db1253acb3a3dd17bab8e0329ad0), uint256(0x0f2a84c606acedf9ad5e1389f76e8848625f601f5bf867b1c6a9c0daf78cce2c));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x295162a9018753acf18f85fb68f5d1b93bcbfdaca4dc9890346bca890dcebc0e), uint256(0x1a4d6cb49e527957b1de02499462e5f0eecbdf4c2fbb0242e3c143121c170d46));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x2923be890fd34ddc1ae2044bfbda7414725cb89dd1b6ddf288e33ddc18f8bc1f), uint256(0x1b33bd55e42dcacc31d08c5379e4f0761f4d7d310ff40f57fead452e02b35dd4));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x0b46dd7d1fd9763cb6879b2c23304b01bbe15479098c03588fde27be3da73de8), uint256(0x190a559113acf1c03cc95d65be837b5cb17cff3f0c6fa9c46549f00b1beea01c));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x16db7471b62960c0237765ec23fb222c3b46a1474c1292787d6ad90c0c76c482), uint256(0x28c8ca933ffe3d31e85d61f42cc3d70778c6020d61a7603a19d926077dfcb746));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1f660ab0a620181696b7c32cc2ab518f4fe8a4f8b1b807027629d9fa482f99db), uint256(0x16a73cedd700a9e9e54b02fa561c116a0db06f649e239be22556ce9c8edd7040));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x07dfff259d8e20bba391046146a1d6f900f9478aec5fc2ac2fe12cbd49119ce1), uint256(0x20a28f15c2020b0cdb447e6f35a9bc3c78ed8bf56bf02c6b88528ab1a18aeab6));
    }
    function verify_R(uint[] memory input, Proof_R memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey_R memory vk = verifyingKey_R();
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
    function verifyReceiver(
            Proof_R memory proof, uint[7] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](7);
        
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify_R(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
// File: Trial/verifier_sender.sol


pragma solidity ^0.8.0;


contract Verifier_Sender {
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
        vk.alpha = Pairing.G1Point(uint256(0x2ef2098c8b96ccdf8090000b681e55ebf86f007c79edeca4565481c36b127a4a), uint256(0x2fedbedaf3d4783b07710b80835fa268b2992e86ca619e2bec4d37c9e257dfc6));
        vk.beta = Pairing.G2Point([uint256(0x1f30174e6501470ceeca5db3b8c9d04f12943adf5a6a7ed4fb9bd83e1df28490), uint256(0x221d1123fb02c86120bb78168c3a36ce2901faa160792560898220c19ff1ae38)], [uint256(0x10e53fad8b04ed8a5936442b7cb4a45f73b86cf7a5a358b615c45e6d4b704364), uint256(0x201b54af2f7b4ca834fc17489729f7ff03df05dc890f381089f0c92bb2c62dd2)]);
        vk.gamma = Pairing.G2Point([uint256(0x231bd8b0384f6958b69b7d20f399043899c99535b92236ec15f45b58fef1f2b1), uint256(0x03bb508fe18034f4ccd0cce81d2e7c1d25364f6f078385388c897800cc429bf2)], [uint256(0x0937fd1f4e41ac3c1978ebc0e5dc8425e85eadcf7d532c181d54d7250251d1d6), uint256(0x0f4856265599512127a770510852aed59068dd3a99d3a2bc51b3fa41439c6166)]);
        vk.delta = Pairing.G2Point([uint256(0x2f8e404f637a02546b7e94b6b71f08c528f546b7768891d18e5191e445e8352d), uint256(0x1275502ab0c29be9ac345fee7671114aac9ff61322f55cb184d3813fa7f64fca)], [uint256(0x100f571ee207e2ba3e1aeb879812e64229ee66e92be569630991b7f418cdb3e2), uint256(0x0a12d78fb94cec6828febde046564534fed5fcb62592903b8455db6c2ab9e4f1)]);
        vk.gamma_abc = new Pairing.G1Point[](8);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x24e2988c7d7d86bfc22cbdb0662d1a5ea91d12b92618d52909bba4cbada6e2b4), uint256(0x1099e35202ffc80151828cbb7d2335f0a0e57606dc9802b17216e781168ba565));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x0809bf1197c483a10e6d36dcde1ab5db2749087048fb7dc421f0bdff7b860ea2), uint256(0x0767974488b0c86c06cd1a2d25c0d173dd19d1aa6c0cf9a9073e15f8c976e7f7));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0db7d6de2b260d74fcef138a3b4549df859390b9b4afe7dd90d0e5ef494a4098), uint256(0x0d73e03530dd26f1e4fe5c1df37a8996c4d48318ac7b610e42e253e6840b3e3d));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x127307d4fdafc6753ffeb10766854ec3605f059e7a30fa93ca23c404886eda9c), uint256(0x21d8bc247063748e6a37072b4a0cb939506878dbc4a5bfcf7b4e2bbfb0e92411));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x127e067aa95abffa4d912b2f2e375477d8551b3f3aafe5fdf6c8772cf6009d99), uint256(0x2057d2c631374f26304cef92c9e8045eb354f5b89380b7b6871fed98f90f0705));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x0e87ef6961e75d7cf50a2c02e1d6b0bd951c6246dab1ca123a4becc2a559e0b6), uint256(0x0df9c0b3e290731b6795ae2c05bec87490ab3502d1d3dc1357e7a794678a6f9f));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x0b5c7ab0f7d6bb29ac554a019adf67689dc248a981a2520cba87ba8a14225949), uint256(0x2a1e4d52ce72310b101c3a9af1d37bd8f911a29b09e0d556ac8285cbab2529e2));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x05e004bf36e76c30d8989fcd899872a6ae8f53f0489ef7d7c01e501ce363369a), uint256(0x075e8beaeb50178cd46ce81465f722b1c6eba454408bce30994c1bd0e10c8465));
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
    function verifySender(
            Proof memory proof, uint[7] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](7);
        
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

// File: http://github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: http://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: http://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: http://github.com/OpenZeppelin/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: Trial/Conf.sol



pragma solidity ^0.8.0;




contract Confidential is ERC20, Verifier_Sender, Verifier_Receiver{

    mapping (address => uint[2]) balanceHashes;

    constructor(uint256 initialSupply) ERC20("TOKEN", "SS"){

    _mint(msg.sender, initialSupply);
    balanceHashes[msg.sender] =   [267155370138219963795935159289233917406, 297982103872684426429258885425731138599];

    }

    function trans(address _to, Proof memory proofSender, Proof_R memory proofReceiver, uint hashSenderBalanceAfter_1, uint hashSenderBalanceAfter_2, uint hashValue_1, uint hashValue_2, uint hashReceiverBalanceAfter_1, uint hashReceiverBalanceAfter_2, uint boo) public {

    address to = _to;     
    uint[2] memory hashSenderBalanceBefore = balanceHashes[msg.sender];
    uint[2] memory hashReceiverBalanceBefore = balanceHashes[to];
    uint[7] memory inputSender = [hashSenderBalanceBefore[0], hashSenderBalanceBefore[1], hashSenderBalanceAfter_1, hashSenderBalanceAfter_2, hashValue_1, hashValue_2, boo];
    uint[7] memory inputReceiver = [hashReceiverBalanceBefore[0], hashReceiverBalanceBefore[1], hashReceiverBalanceAfter_1, hashReceiverBalanceAfter_2, hashValue_1, hashValue_2, boo];

    bool senderProofIsCorrect = verifySender(proofSender, inputSender);
    bool receiverProofIsCorrect = verifyReceiver(proofReceiver, inputReceiver); 

    if (senderProofIsCorrect && receiverProofIsCorrect){

        balanceHashes[msg.sender] = [hashSenderBalanceAfter_1, hashSenderBalanceAfter_2];
        balanceHashes[to] = [hashReceiverBalanceAfter_1, hashReceiverBalanceAfter_2];

    }

    }

    function alance(address _account) public view returns (uint[2] memory){

        return balanceHashes[_account];

    }





}