/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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

abstract contract Verifier {
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
        vk.alpha = Pairing.G1Point(uint256(0x1dbfb6a2510ce11bc441c5718774012e3f073d9122e63716dec269955554a061), uint256(0x08cfdf5aefa9c9c1674c3fb1c5a4cfd6ecfa48434e67c1fc742de4812bf50112));
        vk.beta = Pairing.G2Point([uint256(0x1c2eae5b53f74dbf5b310d9402a02aed6b219c0fb7a776f15a78524ccd326f14), uint256(0x2e8df313a105d253e1b71b4a07d6e15eab1dd081f1e01e0f09308603f6e25509)], [uint256(0x0f9ef6e1ca74bb6bee1f1605d028830b855f12595c38e4da1a2670bab8e05716), uint256(0x1dab40eba2676f76f64096cb25c49b0c9413831a8745e7dec9a492a8ebbf7fe2)]);
        vk.gamma = Pairing.G2Point([uint256(0x23abe550bcdfca0517cdbc8b2ec364a0fccd906cf16aad67143f4ac4da725fa3), uint256(0x08de938fbc46a02e2c14c263002510fce894f83c99b95dc5899b44bdcd113e57)], [uint256(0x2d24c8a4b13ced9ce25f572ca00c901086920b7b067477c7862cb1e611cfda61), uint256(0x04c50b7ad397568fdb09be7992edc55495d21c5b1d1fa6090f3039a6e181b066)]);
        vk.delta = Pairing.G2Point([uint256(0x1c78a97e22f33250524a4e6f733707139c883e05fcc1d2ce7149586101f4f77e), uint256(0x0e5c5ddaa046c6b52e95063fc3f49c6200301a50726f4bbdddf07e2ecd45ffc0)], [uint256(0x0ede1d0f88f72f3fe328b48357c46f93fce462361dab1ed7bc4d15b58c447102), uint256(0x13853e9c167271df75f37d9a632432aa54bb372f3d925e08b2b792657266d2bf)]);
        vk.gamma_abc = new Pairing.G1Point[](26);
        vk.gamma_abc[0] = Pairing.G1Point(uint256(0x1f8aff80da51bd04b0bfe47853ac86816c633fa2c5962287b63b1127e76f109e), uint256(0x0f68afc853785bd23dc0ba75ed4115ffe22072cedb95fe43de36d0d7b225bc4c));
        vk.gamma_abc[1] = Pairing.G1Point(uint256(0x1168e23da3edecc9b4bfeb4dc0121ef689794dc3212a0a52231f768437500d00), uint256(0x185f29a92e1d5fa33de48608216c23253c3df59c9512b62f4b4f9a4a1e05dd28));
        vk.gamma_abc[2] = Pairing.G1Point(uint256(0x0eb36b174f1084db0c6884b43c636eff34afc530a82e68c5d42facf73f4cefab), uint256(0x1030e6a45692572bf9a26069a00ec50370277b2ad8dbf4bf2249a283bd7c6b06));
        vk.gamma_abc[3] = Pairing.G1Point(uint256(0x05fdbeb65cb2777546f934b50f8082e8cd44b6781960a8d8dd7226e80847dabf), uint256(0x2ef2f55b190ca44bfb694b69123cac18bca941e4a792dc068420ca8e39eaf807));
        vk.gamma_abc[4] = Pairing.G1Point(uint256(0x1bd3b55d283a4483ec36a912cccef14068b31b6894d6faf1c53ce01c48bfe8b6), uint256(0x18d4932af4c42d5a37bf07da61b8f63d73d895f7d63665dedaa78665226e9623));
        vk.gamma_abc[5] = Pairing.G1Point(uint256(0x22e6fa391638315b840166bbb7cd8247f2fc05c29918a3541a4109ff48b793a2), uint256(0x1fefc1ea64abf33bbfe24d289dfdee00ff1f2c1671653cca0a5416c113d1266c));
        vk.gamma_abc[6] = Pairing.G1Point(uint256(0x1bb09c70312d3fe5dbc77d413e8aa21840d6ba1848b839934c3cd5bd5c18cb56), uint256(0x247d15a623d59f9a10d214230b40f781bd0a19214c61983438d5110718a4be9d));
        vk.gamma_abc[7] = Pairing.G1Point(uint256(0x2a182ab1b7c3ebf8494e7f40d1e8b8d314027a4ab5ed87b873a0b6fe4fd7f990), uint256(0x0cc956442985764a1dd9f88f5cc16ada3ec45b34fe5fcfdcba32b53539ef24f1));
        vk.gamma_abc[8] = Pairing.G1Point(uint256(0x286f213f4b9b6fd60483bd3236b631ac601bcf89d67af555727f256ea3f2dac1), uint256(0x1c901e79003462405bc05d54b45933d09f4a54e3d7e4eff5f54c2ea407c8d4cc));
        vk.gamma_abc[9] = Pairing.G1Point(uint256(0x0219c2ac564fa66e307da83f6cd1edbc516998ee56f903e656da5d30ec470dd2), uint256(0x045e0b20eb93fdccee793891ef01d47385a71488fb07946a4a93b9f250dd0111));
        vk.gamma_abc[10] = Pairing.G1Point(uint256(0x175fda71da731bc5360297ba0f24c19dd287bc56e8efc9130926f6eaddfb59d2), uint256(0x2edef838bf347ca2763a9b271bbc9d6755240936d053f38dd887eb6d674168d3));
        vk.gamma_abc[11] = Pairing.G1Point(uint256(0x0f87604ff8aef132c3ff8b824c47134e2242813121e9ab7efac9edd82666ef50), uint256(0x02a8e7d717ab65670465d29d100b8b68103ea85cc05b7c8e3f4a329a9f6f2dca));
        vk.gamma_abc[12] = Pairing.G1Point(uint256(0x2eba7ffe6d431660471ead2af431c7972709f451cae5a28a4079eaec504e7689), uint256(0x0f38dd3391dff2a10733cd4e666b66f83061c57de2e517a23b28306498cecfdf));
        vk.gamma_abc[13] = Pairing.G1Point(uint256(0x1828d6839b3411918ab87370d3a4deea79cfb21d0327ac5a7683ab8a194297c0), uint256(0x2dfef55a59cd65297860952a4cf2b73ebdd5a19f829c495a9349c841265c3090));
        vk.gamma_abc[14] = Pairing.G1Point(uint256(0x2c0e8dea0ec9512736772008e71e57440c65d9cdb0aca4ff721c7e8e84cf5e95), uint256(0x1dc8a95d29439ec0a1d46e433b7556a11bb409033c781cdd75594207bf54760d));
        vk.gamma_abc[15] = Pairing.G1Point(uint256(0x00482b33b67168fe86f5bb890d9e1dbe121f597d33a3db461f552fdacd787304), uint256(0x2a0504a2f3757a730f5d5efa30132970622d68d3801fc0513e265f4bffa85190));
        vk.gamma_abc[16] = Pairing.G1Point(uint256(0x2f408a27322e820e54221e903b074bf687252edcad4c7b8d42e63786d0fa8fbb), uint256(0x23cbbe7cb9779b7d82d8ca6b3af6b5a12df17fdcc10d760c5e89da3b9f918365));
        vk.gamma_abc[17] = Pairing.G1Point(uint256(0x2c1922420566bdbe30bcca456d32a12c5d059f299b99f4b0a9715bedf13eec2e), uint256(0x2237cde98cb8023a39329cddcafca08bbbc4beef61f672dfc1f922fd201e088f));
        vk.gamma_abc[18] = Pairing.G1Point(uint256(0x0a75781e083fe426b602fc68e6a61a2eafe3f620c19ec9b7816d741fe6a177e1), uint256(0x2e20db226b9dda1147954dcefa424648bb1d233da51958d3619bb5ed44f2fb98));
        vk.gamma_abc[19] = Pairing.G1Point(uint256(0x0b81292418e6ae29d7a7724b8fd29c7a316dac1e8fe964cae7fd3e96b8810ec3), uint256(0x1641c31149a6b1a19db37784fd51eae45c6e0e4267e1150b6a86c582aa0cc347));
        vk.gamma_abc[20] = Pairing.G1Point(uint256(0x22035db37ba17592cdc31e7ae1465c8b4e2082c3f5e8eae191f912f126cad1ff), uint256(0x0eed8edbbe3acff201d837d1d3e07bf334d18dac1fa54847a931faefa7db757c));
        vk.gamma_abc[21] = Pairing.G1Point(uint256(0x0491cf9e6111206699c50cf489765c5a59442b41c4d0d3f2520390f29c6ad652), uint256(0x17fdfbee1f0a5697f52cd967c6653d5098b69b46f7546d794356595e9641c832));
        vk.gamma_abc[22] = Pairing.G1Point(uint256(0x060db22dcff996625f305f2a3f7f616c68bd15b7fc40b6c1ce53450cef6428da), uint256(0x08e8aa365b26b6f0ffc0dfcf680d9dc2cfb0b8ace9050c70427012a9a77f37a2));
        vk.gamma_abc[23] = Pairing.G1Point(uint256(0x15e96472b2f1d206f11100fa1cf5d7ee33226e740ae06a59daf9fdec35a80610), uint256(0x29d9b50aeb4fde4de9eee35d123631e9fc429ac13152921ca08ae3803001d81e));
        vk.gamma_abc[24] = Pairing.G1Point(uint256(0x2026e399f1add101072526dadc749eeb40373821be540aaf371aa63e75cc6fc3), uint256(0x2b292c6cb4fbd768ee9f58a081ff50b33a3e66bdaf3003a4fcc2e3d61124ad81));
        vk.gamma_abc[25] = Pairing.G1Point(uint256(0x1249eba8b36fa62f50e53f85283230061499bfde1c736a2444d76dbdb5e6ba1f), uint256(0x2ad044104d998361000ac932ee86abd7df15e3361c0c84e5bb286912e93c4380));
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
            Proof memory proof, uint[25] memory input
        ) public view returns (bool r) {
        uint[] memory inputValues = new uint[](25);
        
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


contract Hangman is Verifier {
    
    /// @notice Mapping of game instances
    mapping(uint => Game) public games;
    
    /// @notice Information about the game including secret word, which turn it is, and previous user actions
    struct Game {
        /// @notice sha-256 encrypted secret word that game host picked
        uint32[8] secretWordHash;
        /// @notice Length of a word that game host picked (max: 16)
        uint8 length;
        /// @notice Indicates whether it is a turn to guess a letter or post a proof whether the previous guess is correct
        bool guesserTurn;
        /// @notice A list of attempts to guess letters that are in the word. Represented as codes of ASCII characters
        uint8[] attempts;
        /// @notice The resulting word as an array of ASCII characters. When first {length} characters of this array are set, the game ends
        uint8[16] word;
    }

    modifier _guesserTurn(uint gameId) {
        if (!games[gameId].guesserTurn) revert NotGuesserTurn();
        _;
    }

    modifier _verifierTurn(uint gameId) {
        if (games[gameId].guesserTurn) revert NotTurnToVerify();
        _;
    }

    modifier _letterNotUsed(uint gameId, uint8 letter) {
        Game memory game = games[gameId];
        for (uint i = 0; i < game.attempts.length; i++) {
            if (game.attempts[i] == letter) revert LetterWasUsed(letter);
        }
        _;
    }

    modifier _gameActive(uint gameId) {
        if (!isGameActive(gameId)) revert GameNotActive(gameId);

        _;
    }

    /**
     * @notice Creates new game. Persists hash of a secret word and the length of the word.
     * @param proof Proof generated by Zokrates
     * @param input Input for the verifier where:
     *  Elements  [0-7] - sha-256 hash of the secret word. Word can be from 3 to 16 characters long.
     *  Element     [8] - '0'. Required for creating new game, explained below.
     *  Elements [9-24] - a mask representing occurance of Element 8 in the word.
     *    For "Hello" the mask will be 0000011111111111 which proofs that the word is 5 characters long
     */
    function createGame(Proof calldata proof, uint[25] calldata input) external {
        uint gameId = uint(keccak256(abi.encodePacked(msg.sender, block.timestamp)));
        
        // Basic validation
        if (games[gameId].length > 0) revert GameAlreadyExsits(gameId);
        if (input[8] != 0) revert NotAStartGameInput(input);

        // Determine word length and validate 9-24 elements of the input. Revert if it's not consecutive 0's at the beginning followed by 1's till the end
        uint8 wordLength;
        for (uint i = 9; i < input.length; i++) {
            if (input[i] == 0 && wordLength == i - 9) {
                wordLength++;
            } else if (input[i] == 0) {
                revert InvalidWordInput(input);
            }
        }

        if (wordLength < 3) revert InvalidWordLength(wordLength);

        // Verify proof
        if (!verifyTx(proof, input)) revert InvalidProof();

        // Persist game information in storage
        for (uint i = 0; i < 8; i++) {
            // Conversion is safe as proof verification would fail if these are not u32 numbers
            games[gameId].secretWordHash[i] = uint32(input[i]);
        }
        games[gameId].length = wordLength;
        games[gameId].guesserTurn = true;

        emit GameCreated(gameId, wordLength);
    }

    /**
     * @notice Suggests a letter to check whether it's in the word. Can only try one that wasn't checked before. Flips the turn to the verifier
     * @param gameId Game for which the guess is submitted
     * @param letter Letter as an ASCII code
     */
    function guessLetter(uint gameId, uint8 letter) external _letterNotUsed(gameId, letter) _gameActive(gameId) _guesserTurn(gameId) {
        if (letter == 0) revert InvalidGuess(letter);

        Game storage game = games[gameId];

        if (!game.guesserTurn) revert NotGuesserTurn();

        game.attempts.push(letter);
        game.guesserTurn = false;
    }

    /**
     * @notice Verifies whether the letter exists in the secret word and captures letter's positions if guessed correctly. 
     * Only executed after a guess is made. Flips the turn back to the guesser.
     * @param proof Proof generated by Zokrates
     * @param input Input for the verifier where:
     *  Elements  [0-7] - sha-256 hash of the secret word. Word can be from 3 to 16 characters long.
     *  Element     [8] - a letter that was last suggested by the guesser. 
     *  Elements [9-24] - a mask representing positions of El.8 in the word. For example, for word "Hello" and letter "l" it will be 0011000000000000
     * @param gameId Game for which verification is submitted
     */
    function verifyLetter(Proof calldata proof, uint[25] calldata input, uint gameId) external _verifierTurn(gameId) {
        Game storage game = games[gameId];

        // Validate input
        checkWordHashMatches(game, input);
        if (input[8] != game.attempts[game.attempts.length - 1]) revert NotLatestGuess(game.attempts[game.attempts.length - 1], uint8(input[8]));

        // Verify proof
        if (!verifyTx(proof, input)) revert InvalidProof();

        // Store letter positions in the result if guessed correctly
        uint gameLength = game.length;
        for (uint i = 9; i < gameLength; i++) {
            if (input[i] == 1) { 
                game.word[i - 9] = uint8(input[8]);
            }
        }

        games[gameId].guesserTurn = true;

        if (!isGameActive(gameId)) {
            emit GameEnded(gameId, game.word);
        }
    }

    function checkWordHashMatches(Game memory game, uint[25] memory input) internal pure {
        for (uint i = 0; i < 8; i++) {
            if (game.secretWordHash[i] != uint32(input[i])) revert InvalidWordHash(input);
        }
    }

    function isGameActive(uint gameId) internal view returns (bool) {
        Game memory game = games[gameId];        
        bool gameActive;
        for (uint i = 0; i < game.length; i++) {
            if (game.word[i] == 0) {
                gameActive = true;
                break;
            }
        }

        return gameActive;
    }

    function gameAttempts(uint gameId) public view returns (uint8[] memory) {
        return games[gameId].attempts;
    }

    function gameWord(uint gameId) public view returns (uint8[16] memory) {
        return games[gameId].word;
    }

    event GameCreated(uint indexed gameId, uint8 wordLength);
    event GameEnded(uint indexed gameId, uint8[16] word);

    error GameAlreadyExsits(uint gameId);
    error GameNotActive(uint gameId);
    error NotAStartGameInput(uint[25] input);
    error InvalidProof();
    error InvalidWordInput(uint[25] input);
    error InvalidWordLength(uint8 wordLength);
    error NotGuesserTurn();
    error NotTurnToVerify();
    error LetterWasUsed(uint8 letter);
    error InvalidGuess(uint8 letter);
    error NotLatestGuess(uint8 latestGuess, uint8 verificationForGuess);
    error InvalidWordHash(uint[25] input);
}