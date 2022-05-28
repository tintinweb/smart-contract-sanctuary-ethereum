/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

// SPDX-License-Identifier: MIT
// File: Verifier.sol

//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//

pragma solidity >=0.6.11 <0.9.0;
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
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
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
        uint[] memory input = new uint[](inputSize);
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
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
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
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            4015971214601274450582101135234403977948829308494056514325025916553484348525,
            11789912012887439061740017382543741713717193756194819373236584508249107661673
        );

        vk.beta2 = Pairing.G2Point(
            [20255323772829801273420091817897198918239028838425965777612542038169975419508,
             3932073073691051474925814736979819662971431136358536406781793245616612078183],
            [20315184067271392694795858456192746192780612986629659565241454598731903404551,
             1817538646234672822961599988535674980504573755905895828151514219476194302891]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [7157325244600479738828671977338575584250177511702524541177934927488056408288,
             20778548848453107970364483342423551760830142336787930901049167979048839139566],
            [21326815489288211003075842908779331731011334731378812632413119599895426772924,
             15550697619689924443198267164562407939690361731406344169455259116840836519610]
        );
        vk.IC = new Pairing.G1Point[](12);
        
        vk.IC[0] = Pairing.G1Point( 
            13258671518662272156668045725753548517292408369276097669744612499644639985199,
            18328917881163459378799695387003119211819366370857144419323111328867076087196
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            11986413794539534181854010880830007481587794435093268553237256798553031548479,
            4142823611053178014442940561605196650163378044623108726023610205759096586416
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            2408712341269051459170603178704173833817859061779358178294525336503084051722,
            3744317428816116986284369547620189571043802361851893056735019397327144333037
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            18814612696964021713016567038503271705204140935948076194327477748029586402203,
            1775969053143610410363361224193572967864437705120956336576005385669732992194
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            11183140220864597845902782661998366880308280490397765424345284873802720691864,
            20978720925297211463970351393865892573471453560241272148417687968018917049204
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            20114783927688701953414907883241976581371243911433720173232361881686798655158,
            467048386246020673431288616050633336156228923857041535989879609227853228297
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            21170157634457262863461492640896707606544692459017506920269111783554876492239,
            20029392916973329244156141746047908563202304885241153568230330446262155504367
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            17828898543710425911820157927422145517192743509112383262008075052438713912287,
            4274502957606338895044634003575767688719901767829447034049702966253123907806
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            20779536105730031657363767714446251995267490161494453508949389322686872731608,
            8967749183487882174488103915064032110388858789671164540378952308834043826237
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            21199602532812613573279341785963345317159478947610857198587212004714862723700,
            12735810896103605072333660798266389778499222142937286839238154822344308181340
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            8152304417864896593301461133767955254145088948549183291237053616602307742165,
            20262272479404548692059972020341058335416051693215726313804670979378235481947
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            4968300722750185908602196457445874584107733833333443263543066565572071930433,
            16747063878934550129570875186036423553469155618128088913059244922717054924169
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[11] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        
        if (verify(inputValues, proof) == 0) {
            return false;
        } else {
            return true;
        }
    }
}

// File: MyContract.sol


pragma solidity >=0.6.11 <0.9.0;


contract MyContract {
    address public owner;   // 合約的owner
    address public verifierAddress; // circom產生Verifier.sol的Address

    uint constant public root = 1036557378593479572902185418110055117026790461032715144693387447280599040; // Java Merkle Tree產生的Root hash (10進位)
    
    uint[2] public a;        // proof.json所產生的Array a
    uint[2][2] public b;     // proof.json所產生的2D-Array b
    uint[2] public c;        // proof.json所產生的Array c
    uint[11] public input;   // Public input 以及 Private input (secret)

    uint[8] public msgHash;  // Dev檢查使用

    uint public circom_root; 
    uint public slice_num;   // slice的數量 

    bool public success;     // 預設為False, 若驗證成功則改為True

    event verifyRootResult(bool); // 紀錄執行完verifyRoot function的結果到Log
    event Withdraw(uint);         // 紀錄執行完withdrawCommission function的結果到Log

    constructor(address _verifierAddress) payable{ 
        owner = msg.sender;
        verifierAddress = _verifierAddress;
    }

    modifier checkContractBalance() {
        require(address(this).balance >= 10 wei, "ETH of contract isn't enough.");
        _;
    }

    function setData(uint[2] calldata _a, uint[2][2] calldata _b, uint[2] calldata _c, uint[11] calldata _input) public {
        a = _a;
        b = _b;
        c = _c;
        input = _input;
        slice_num = input[10];        //set Slice_num & Circom_root

        for(uint i = 0; i < 8; i++) {
            msgHash[i] = _input[i+1];
        }

        // assign value to circom_root
        circom_root = input[9];

        // Link to Verifier.sol
        Verifier verifier = Verifier(verifierAddress);
        verifier.verifyProof(_a, _b, _c, _input);

        verifyRoot();
    } 

    function verifyRoot() internal {
        if( circom_root == root ) {   
            success = true;
        } else {
            success = false;
        }
        emit verifyRootResult(success);
    }

    function withdrawCommission() public checkContractBalance {
            require(success == true, "Root is not correct.");

            (bool sent, ) = msg.sender.call{value: slice_num * 10 wei}("");
            require(sent, "Sent failed.");
            emit Withdraw(slice_num * 10 wei);

            success = false;
    }

    function getBalance(address addr) public view returns (uint){
        return addr.balance / 10**18;
    }
}