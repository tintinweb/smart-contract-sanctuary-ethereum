/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

pragma solidity ^0.6.1;
/*
    Author: Philipp Schindler
    Source code and documentation available on Github: https://github.com/PhilippSchindler/ethdkg

    Copyright 2020 Philipp Schindler

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

contract ETHDKG {

    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// CRYPTOGRAPHIC CONSTANTS

    uint256 constant GROUP_ORDER   = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant FIELD_MODULUS = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // definition of two indepently selected generator for the groups G1 and G2 over
    // the bn128 elliptic curve
    // TODO: maybe swap generators G and H
    uint256 constant G1x  = 1;
    uint256 constant G1y  = 2;
    uint256 constant H1x  = 9727523064272218541460723335320998459488975639302513747055235660443850046724;
    uint256 constant H1y  = 5031696974169251245229961296941447383441169981934237515842977230762345915487;

    // For the generator H, we need an corresponding generator in the group G2.
    // Notice that generator H2 is actually given in its negated form,
    // because the bn128_pairing check in Solidty is different from the Pyhton variant.
    uint256 constant H2xi = 14120302265976430476300156362541817133873389322564306174224598966336605751189;
    uint256 constant H2x  =  9110522554455888802745409460679507850660709404525090688071718755658817738702;
    uint256 constant H2yi = 337404400665185879215756363144893538418066400846800837504021992006027281794;
    uint256 constant H2y  = 13873181274231081108062283139528542484285035428387832848088103558524636808404;



    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// EVENTS

    // We could trigger an event for registration as well.
    // However the data must be stored by the contract anyway, we can query it directly from client.
    // event Registation(
    //     address addr,
    //     uint256[2] public_key
    // );
    event ShareDistribution(
        address issuer,
        uint256[] encrypted_shares,
        uint256[2][] commitments
    );
    event Dispute(
        address issuer,
        address disputer,
        uint256[2] shared_key,
        uint256[2] shared_key_correctness_proof
    );
    event KeyShareSubmission(
        address issuer,
        uint256[2] key_share_G1,
        uint256[2] key_share_G1_correctness_proof,
        uint256[4] key_share_G2
    );
    event KeyShareRecovery(
        address recoverer,
        address[] recovered_nodes,
        uint256[2][] shared_keys,
        uint256[2][] shared_key_correctness_proofs
    );



    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// STORAGE

    // list of all registered account addresses
    address[] public addresses;

    // maps storing information required to perform in-contract validition for each registered node
    mapping (address => uint256[2]) public public_keys;
    mapping (address => bytes32) public share_distribution_hashes;
    mapping (address => uint256[2]) public commitments_1st_coefficient;
    mapping (address => uint256[2]) public key_shares;

    function num_nodes() public view returns(uint256)
    {
        return addresses.length;
    }

    // public output of the DKG protocol
    uint256[4] master_public_key;



    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// INITIALIZATION AND TIME_BOUNDS FOR PROTOCOL PHASES

    // block numbers of different points in time during the protcol execution
    // initialized at time of contract deployment
    uint256 public T_REGISTRATION_END;
    uint256 public T_SHARE_DISTRIBUTION_END;
    uint256 public T_DISPUTE_END;
    uint256 public T_KEY_SHARE_SUBMISSION_END;

    // number of blocks to ensure that a transaction with proper fees gets included in a block
    // needs to be appropriately set for the production system
    uint256 public constant DELTA_INCLUDE = 300;

    // number of confirmations to wait to ensure that a transaction cannot be reverted
    // needs to be appropriately set for the production system
    uint256 public constant DELTA_CONFIRM = 5;


    constructor() public {
        uint256 T_CONTRACT_CREATION = block.number;
        T_REGISTRATION_END = T_CONTRACT_CREATION + DELTA_INCLUDE;
        T_SHARE_DISTRIBUTION_END = T_REGISTRATION_END + DELTA_CONFIRM + DELTA_INCLUDE;
        T_DISPUTE_END = T_SHARE_DISTRIBUTION_END + DELTA_CONFIRM + DELTA_INCLUDE;
        T_KEY_SHARE_SUBMISSION_END = T_DISPUTE_END + DELTA_CONFIRM + DELTA_INCLUDE;
    }



    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// MAIN CONTRACT FUNCTIONS

    function register(uint256[2] memory public_key)
    public
    {
        require(
            block.number <= T_REGISTRATION_END,
            "registration failed (contract is not in registration phase)"
        );
        require(
            public_keys[msg.sender][0] == 0,
            "registration failed (account already registered a public key)"
        );
        require(
            bn128_is_on_curve(public_key),
            "registration failed (public key not on elliptic curve)"
        );

        addresses.push(msg.sender);
        public_keys[msg.sender] = public_key;
    }


    function distribute_shares(uint256[] memory encrypted_shares, uint256[2][] memory commitments)
    public
    {
        uint256 n = addresses.length;
        uint256 t = n / 2;
        if (n & 1 == 0) {
            t -= 1;
        }

        require(
            (T_REGISTRATION_END < block.number) && (block.number <= T_SHARE_DISTRIBUTION_END),
            "share distribution failed (contract is not in share distribution phase)"
        );
        require(
            public_keys[msg.sender][0] != 0,
            "share distribution failed (ethereum account has not registered)"
        );
        require(
            encrypted_shares.length == n - 1,
            "share distribution failed (invalid number of encrypted shares provided)"
        );
        require(
            commitments.length == t + 1,
            "key sharing failed (invalid number of commitments provided)"
        );
        for (uint256 k = 0; k <= t; k += 1) {
            require(
                bn128_is_on_curve(commitments[k]),
                "key sharing failed (commitment not on elliptic curve)"
            );
        }

        share_distribution_hashes[msg.sender] = keccak256(
            abi.encodePacked(encrypted_shares, commitments)
        );
        commitments_1st_coefficient[msg.sender] = commitments[0];

        emit ShareDistribution(msg.sender, encrypted_shares, commitments);
    }


    function submit_dispute(
        address issuer,
        uint256 issuer_list_idx,
        uint256 disputer_list_idx,
        uint256[] memory encrypted_shares,
        uint256[2][] memory commitments,
        uint256[2] memory shared_key,
        uint256[2] memory shared_key_correctness_proof
    )
    public
    {
        require(
            (T_SHARE_DISTRIBUTION_END < block.number) && (block.number <= T_DISPUTE_END),
            "dispute failed (contract is not in dispute phase)"
        );
        require(
            addresses[issuer_list_idx] == issuer &&
            addresses[disputer_list_idx] == msg.sender,
            "dispute failed (invalid list indices)"
        );

        // Check if a other node already submitted a dispute against the same issuer.
        // In this case the issuer is already disqualified and no further actions are required here.
        if (share_distribution_hashes[issuer] == 0) {
            return;
        }

        require(
            share_distribution_hashes[issuer] == keccak256(
                abi.encodePacked(encrypted_shares, commitments)
            ),
            "dispute failed (invalid replay of sharing transaction)"
        );
        require(
            dleq_verify(
                [G1x, G1y], public_keys[msg.sender], public_keys[issuer], shared_key, shared_key_correctness_proof
            ),
            "dispute failed (invalid shared key or proof)"
        );

        // Since all provided data is valid so far, we load the share and use the verified shared
        // key to decrypt the share for the disputer.
        uint256 share;
        uint256 disputer_idx = uint256(msg.sender);
        if (disputer_list_idx < issuer_list_idx) {
            share = encrypted_shares[disputer_list_idx];
        }
        else {
            share = encrypted_shares[disputer_list_idx - 1];
        }
        uint256 decryption_key = uint256(keccak256(
            abi.encodePacked(shared_key[0], disputer_idx)
        ));
        share ^= decryption_key;

        // Verify the share for it's correctness using the polynomial defined by the commitments.
        // First, the polynomial (in group G1) is evaluated at the disputer's idx.
        uint256 x = disputer_idx;
        uint256[2] memory result = commitments[0];
        uint256[2] memory tmp = bn128_multiply([commitments[1][0], commitments[1][1], x]);
        result = bn128_add([result[0], result[1], tmp[0], tmp[1]]);
        for (uint256 j = 2; j < commitments.length; j += 1) {
            x = mulmod(x, disputer_idx, GROUP_ORDER);
            tmp = bn128_multiply([commitments[j][0], commitments[j][1], x]);
            result = bn128_add([result[0], result[1], tmp[0], tmp[1]]);
        }
        // Then the result is compared to the point in G1 corresponding to the decrypted share.
        tmp = bn128_multiply([G1x, G1y, share]);
        require(
            result[0] != tmp[0] || result[1] != tmp[1],
            "dispute failed (the provided share was valid)"
        );

        // We mark the nodes as disqualified by setting the distribution hash to 0. This way the
        // case of not proving shares at all and providing invalid shares can be handled equally.
        share_distribution_hashes[issuer] = 0;
        emit Dispute(issuer, msg.sender, shared_key, shared_key_correctness_proof);
    }


    function submit_key_share(
        address issuer,
        uint256[2] memory key_share_G1,
        uint256[2] memory key_share_G1_correctness_proof,
        uint256[4] memory key_share_G2
    )
    public
    {
        require(
            (T_DISPUTE_END < block.number),
            "key share submission failed (contract is not in key derivation phase)"
        );
        if (key_shares[issuer][0] != 0) {
            // already submitted, no need to resubmit
            return;
        }
        require(
            share_distribution_hashes[issuer] != 0,
            "key share submission failed (issuer not qualified)"
        );
        require(
            dleq_verify(
                [H1x, H1y],
                key_share_G1,
                [G1x, G1y],
                commitments_1st_coefficient[issuer],
                key_share_G1_correctness_proof
            ),
            "key share submission failed (invalid key share (G1))"
        );
        require(
            bn128_check_pairing([
                key_share_G1[0], key_share_G1[1],
                H2xi, H2x, H2yi, H2y,
                H1x, H1y,
                key_share_G2[0], key_share_G2[1], key_share_G2[2], key_share_G2[3]
            ]),
            "key share submission failed (invalid key share (G2))"
        );

        key_shares[issuer] = key_share_G1;
        emit KeyShareSubmission(issuer, key_share_G1, key_share_G1_correctness_proof, key_share_G2);
    }


    function recover_key_shares(
        address[] memory recovered_nodes,
        uint256[2][] memory shared_keys,
        uint256[2][] memory shared_key_correctness_proofs
    )
    public
    {
        // this function is only used as message broadcast channel
        // full checks are performed in the local client software
        require(
            (T_KEY_SHARE_SUBMISSION_END < block.number),
            "key share recovery failed (contract is not in key derivation phase)"
        );
        require(
            share_distribution_hashes[msg.sender] != 0,
            "key share recovery failed (recoverer not qualified)"
        );

        emit KeyShareRecovery(
            msg.sender,
            recovered_nodes,
            shared_keys,
            shared_key_correctness_proofs
        );
    }


    function submit_master_public_key(
        uint256[4] memory _master_public_key
    )
    public
    {
        require(
            (T_DISPUTE_END < block.number),
            "master key submission failed (contract is not in key derivation phase)"
        );
        if (master_public_key[0] != 0) {
            return;
        }

        uint256 n = addresses.length;

        // find first (i.e. lowest index) node contributing to the final key
        uint256 i = 0;
        address addr;

        do {
            addr = addresses[i];
            i += 1;
        } while(i < n && share_distribution_hashes[addr] == 0);

        uint256[2] memory tmp = key_shares[addr];
        require(tmp[0] != 0, 'master key submission failed (key share missing)');
        uint256[2] memory mpk_G1 = key_shares[addr];

        for (; i < n; i += 1) {
            addr = addresses[i];
            if (share_distribution_hashes[addr] == 0) {
                continue;
            }
            tmp = key_shares[addr];
            require(tmp[0] != 0, 'master key submission failed (key share missing)');
            mpk_G1 = bn128_add([mpk_G1[0], mpk_G1[1], tmp[0], tmp[1]]);
        }
        require(
            bn128_check_pairing([
                mpk_G1[0], mpk_G1[1],
                H2xi, H2x, H2yi, H2y,
                H1x, H1y,
                _master_public_key[0], _master_public_key[1],
                _master_public_key[2], _master_public_key[3]
            ]),
            'master key submission failed (pairing check failed)'
        );

        master_public_key = _master_public_key;
    }



    ////////////////////////////////////////////////////////////////////////////////////////////////
    //// HELPER FUNCTIONS

    function dleq_verify(
        uint256[2] memory x1, uint256[2] memory y1,
        uint256[2] memory x2, uint256[2] memory y2,
        uint256[2] memory proof
    )
    private returns (bool proof_is_valid)
    {
        uint256[2] memory tmp1;
        uint256[2] memory tmp2;

        tmp1 = bn128_multiply([x1[0], x1[1], proof[1]]);
        tmp2 = bn128_multiply([y1[0], y1[1], proof[0]]);
        uint256[2] memory a1 = bn128_add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        tmp1 = bn128_multiply([x2[0], x2[1], proof[1]]);
        tmp2 = bn128_multiply([y2[0], y2[1], proof[0]]);
        uint256[2] memory a2 = bn128_add([tmp1[0], tmp1[1], tmp2[0], tmp2[1]]);

        uint256 challenge = uint256(keccak256(abi.encodePacked(a1, a2, x1, y1, x2, y2)));
        proof_is_valid = challenge == proof[0];
    }


    function bn128_is_on_curve(uint256[2] memory point)
    private pure returns(bool)
    {
        // check if the provided point is on the bn128 curve (y**2 = x**3 + 3)
        return
            mulmod(point[1], point[1], FIELD_MODULUS) ==
            addmod(
                mulmod(
                    point[0],
                    mulmod(point[0], point[0], FIELD_MODULUS),
                    FIELD_MODULUS
                ),
                3,
                FIELD_MODULUS
            );
    }

    function bn128_add(uint256[4] memory input)
    public returns (uint256[2] memory result) {
        // computes P + Q
        // input: 4 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) x-coordinate of point Q
        //  *) y-coordinate of point Q

        bool success;
        assembly {
            // 0x06     id of precompiled bn256Add contract
            // 0        number of ether to transfer
            // 128      size of call parameters, i.e. 128 bytes total
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := call(not(0), 0x06, 0, input, 128, result, 64)
        }
        require(success, "elliptic curve addition failed");
    }

    function bn128_multiply(uint256[3] memory input)
    public returns (uint256[2] memory result) {
        // computes P*x
        // input: 3 values of 256 bit each
        //  *) x-coordinate of point P
        //  *) y-coordinate of point P
        //  *) scalar x

        bool success;
        assembly {
            // 0x07     id of precompiled bn256ScalarMul contract
            // 0        number of ether to transfer
            // 96       size of call parameters, i.e. 96 bytes total (256 bit for x, 256 bit for y, 256 bit for scalar)
            // 64       size of call return value, i.e. 64 bytes / 512 bit for a BN256 curve point
            success := call(not(0), 0x07, 0, input, 96, result, 64)
        }
        require(success, "elliptic curve multiplication failed");
    }

    function bn128_check_pairing(uint256[12] memory input)
    public returns (bool) {
        uint256[1] memory result;
        bool success;
        assembly {
            // 0x08     id of precompiled bn256Pairing contract     (checking the elliptic curve pairings)
            // 0        number of ether to transfer
            // 384       size of call parameters, i.e. 12*256 bits == 384 bytes
            // 32        size of result (one 32 byte boolean!)
            success := call(sub(gas(), 2000), 0x08, 0, input, 384, result, 32)
        }
        require(success, "elliptic curve pairing failed");
        return result[0] == 1;
    }
}