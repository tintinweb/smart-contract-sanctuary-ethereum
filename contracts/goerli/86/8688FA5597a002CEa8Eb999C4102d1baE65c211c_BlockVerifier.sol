pragma solidity ^0.7.0;

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022

import "../../lib/ReentrancyGuard.sol";
import "../../thirdparty/verifiers/BatchVerifier.sol";
import "../../thirdparty/verifiers/Verifier.sol";
import "../iface/ExchangeData.sol";
import "../iface/IBlockVerifier.sol";
import "./VerificationKeys.sol";

/// @title An Implementation of IBlockVerifier.
/// @author Brecht Devos - <[email protected]>
contract BlockVerifier is ReentrancyGuard, IBlockVerifier
{
    struct Circuit
    {
        bool registered;
        bool enabled;
        uint[18] verificationKey;
    }

    mapping (uint8 => mapping (uint16 => mapping (uint8 => Circuit))) public circuits;

    constructor() Claimable() {}

    function registerCircuit(
        uint8    blockType,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        Circuit storage circuit = circuits[blockType][blockSize][blockVersion];

        require(circuit.registered == false, "ALREADY_REGISTERED");

        // Store the verification key on-chain.
        for (uint i = 0; i < 18; i++) {
            circuit.verificationKey[i] = vk[i];
        }
        circuit.registered = true;
        circuit.enabled = true;

        emit CircuitRegistered(
            blockType,
            blockSize,
            blockVersion
        );
    }

    function disableCircuit(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        override
        nonReentrant
        onlyOwner
    {
        Circuit storage circuit = circuits[blockType][blockSize][blockVersion];
        require(circuit.registered == true, "NOT_REGISTERED");
        require(circuit.enabled == true, "ALREADY_DISABLED");

        // Disable the circuit
        circuit.enabled = false;

        emit CircuitDisabled(
            blockType,
            blockSize,
            blockVersion
        );
    }

    function verifyProofs(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion,
        uint[] calldata publicInputs,
        uint[] calldata proofs
        )
        external
        override
        view
        returns (bool)
    {
        // First try to find the verification key in the hard coded list
        (uint[14] memory _vk, uint[4] memory _vk_gammaABC, bool found) = VerificationKeys.getKey(
            blockType,
            blockSize,
            blockVersion
        );
        if (!found) {
            Circuit storage circuit = circuits[blockType][blockSize][blockVersion];
            require(circuit.registered == true, "NOT_REGISTERED");
            require(circuit.enabled == true, "NOT_ENABLED");

            // Load the verification key from storage.
            uint[18] storage vk = circuit.verificationKey;
            _vk = [
                vk[0], vk[1], vk[2], vk[3], vk[4], vk[5], vk[6],
                vk[7], vk[8], vk[9], vk[10], vk[11], vk[12], vk[13]
            ];
            _vk_gammaABC = [vk[14], vk[15], vk[16], vk[17]];
        }

        // Verify the proof.
        // Batched proof verification has a fixed overhead which makes it more
        // expensive to verify a single proof compared to the non-batched code
        // This is why we don't use the batched verification code here when only
        // a single proof needs to be verified.
        if (publicInputs.length == 1) {
            return Verifier.Verify(_vk, _vk_gammaABC, proofs, publicInputs);
        } else {
            return BatchVerifier.BatchVerify(
                _vk,
                _vk_gammaABC,
                proofs,
                publicInputs,
                publicInputs.length
            );
        }
    }

    function isCircuitRegistered(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        override
        view
        returns (bool)
    {
        return circuits[blockType][blockSize][blockVersion].registered;
    }

    function isCircuitEnabled(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        override
        view
        returns (bool)
    {
        return circuits[blockType][blockSize][blockVersion].enabled;
    }

    function getVerificationKey(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        public
        view
        returns (uint[18] memory)
    {
        return circuits[blockType][blockSize][blockVersion].verificationKey;
    }
}

// SPDX-License-Identifier: UNLICENSED
// This code is taken from https://github.com/HarryR/ethsnarks/blob/master/contracts/Verifier.sol
// this code is taken from https://github.com/JacobEberhardt/ZoKrates
pragma solidity ^0.7.0;

library Verifier
{
    function ScalarField ()
        internal
        pure
        returns (uint256)
    {
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function NegateY( uint256 Y )
        internal pure returns (uint256)
    {
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        return q - (Y % q);
    }


    /*
    * This implements the Solidity equivalent of the following Python code:

        from py_ecc.bn128 import *

        data = # ... arguments to function [in_vk, vk_gammaABC, in_proof, proof_inputs]

        vk = [int(_, 16) for _ in data[0]]
        ic = [FQ(int(_, 16)) for _ in data[1]]
        proof = [int(_, 16) for _ in data[2]]
        inputs = [int(_, 16) for _ in data[3]]

        it = iter(ic)
        ic = [(_, next(it)) for _ in it]
        vk_alpha = [FQ(_) for _ in vk[:2]]
        vk_beta = (FQ2(vk[2:4][::-1]), FQ2(vk[4:6][::-1]))
        vk_gamma = (FQ2(vk[6:8][::-1]), FQ2(vk[8:10][::-1]))
        vk_delta = (FQ2(vk[10:12][::-1]), FQ2(vk[12:14][::-1]))

        assert is_on_curve(vk_alpha, b)
        assert is_on_curve(vk_beta, b2)
        assert is_on_curve(vk_gamma, b2)
        assert is_on_curve(vk_delta, b2)

        proof_A = [FQ(_) for _ in proof[:2]]
        proof_B = (FQ2(proof[2:4][::-1]), FQ2(proof[4:-2][::-1]))
        proof_C = [FQ(_) for _ in proof[-2:]]

        assert is_on_curve(proof_A, b)
        assert is_on_curve(proof_B, b2)
        assert is_on_curve(proof_C, b)

        vk_x = ic[0]
        for i, s in enumerate(inputs):
            vk_x = add(vk_x, multiply(ic[i + 1], s))

        check_1 = pairing(proof_B, proof_A)
        check_2 = pairing(vk_beta, neg(vk_alpha))
        check_3 = pairing(vk_gamma, neg(vk_x))
        check_4 = pairing(vk_delta, neg(proof_C))

        ok = check_1 * check_2 * check_3 * check_4
        assert ok == FQ12.one()
    */
    function Verify(
        uint256[14] memory in_vk,
        uint256[4] memory vk_gammaABC,
        uint256[] memory in_proof,
        uint256[] memory proof_inputs
        )
        internal
        view
        returns (bool)
    {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        require(((vk_gammaABC.length / 2) - 1) == proof_inputs.length, "INVALID_VALUE");

        // Compute the linear combination vk_x
        uint256[3] memory mul_input;
        uint256[4] memory add_input;
        bool success;
        uint m = 2;

        // First two fields are used as the sum
        add_input[0] = vk_gammaABC[0];
        add_input[1] = vk_gammaABC[1];

        // Performs a sum of gammaABC[0] + sum[ gammaABC[i+1]^proof_inputs[i] ]
        for (uint i = 0; i < proof_inputs.length; i++) {
            require(proof_inputs[i] < snark_scalar_field, "INVALID_INPUT");
            mul_input[0] = vk_gammaABC[m++];
            mul_input[1] = vk_gammaABC[m++];
            mul_input[2] = proof_inputs[i];

            assembly {
                // ECMUL, output to last 2 elements of `add_input`
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x80, add(add_input, 0x40), 0x60)
            }
            if (!success) {
                return false;
            }

            assembly {
                // ECADD
                success := staticcall(sub(gas(), 2000), 6, add_input, 0xc0, add_input, 0x60)
            }
            if (!success) {
                return false;
            }
        }

        uint[24] memory input = [
            // (proof.A, proof.B)
            in_proof[0], in_proof[1],                           // proof.A   (G1)
            in_proof[2], in_proof[3], in_proof[4], in_proof[5], // proof.B   (G2)

            // (-vk.alpha, vk.beta)
            in_vk[0], NegateY(in_vk[1]),                        // -vk.alpha (G1)
            in_vk[2], in_vk[3], in_vk[4], in_vk[5],             // vk.beta   (G2)

            // (-vk_x, vk.gamma)
            add_input[0], NegateY(add_input[1]),                // -vk_x     (G1)
            in_vk[6], in_vk[7], in_vk[8], in_vk[9],             // vk.gamma  (G2)

            // (-proof.C, vk.delta)
            in_proof[6], NegateY(in_proof[7]),                  // -proof.C  (G1)
            in_vk[10], in_vk[11], in_vk[12], in_vk[13]          // vk.delta  (G2)
        ];

        uint[1] memory out;
        assembly {
            success := staticcall(sub(gas(), 2000), 8, input, 768, out, 0x20)
        }
        return success && out[0] != 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
// This code is taken from https://github.com/matter-labs/Groth16BatchVerifier/blob/master/BatchedSnarkVerifier/contracts/BatchVerifier.sol
// Thanks Harry from ETHSNARKS for base code
pragma solidity ^0.7.0;

library BatchVerifier {
    function GroupOrder ()
        public pure returns (uint256)
    {
        return 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    }

    function NegateY( uint256 Y )
        internal pure returns (uint256)
    {
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        return q - (Y % q);
    }

    function getProofEntropy(
        uint256[] memory in_proof,
        uint256[] memory proof_inputs,
        uint proofNumber
    )
        internal pure returns (uint256)
    {
        // Truncate the least significant 3 bits from the 256bit entropy so it fits the scalar field
        return uint(
            keccak256(
                abi.encodePacked(
                    in_proof[proofNumber*8 + 0], in_proof[proofNumber*8 + 1], in_proof[proofNumber*8 + 2], in_proof[proofNumber*8 + 3],
                    in_proof[proofNumber*8 + 4], in_proof[proofNumber*8 + 5], in_proof[proofNumber*8 + 6], in_proof[proofNumber*8 + 7],
                    proof_inputs[proofNumber]
                )
            )
        ) >> 3;
    }

    function accumulate(
        uint256[] memory in_proof,
        uint256[] memory proof_inputs, // public inputs, length is num_inputs * num_proofs
        uint256 num_proofs
    ) internal view returns (
        bool success,
        uint256[] memory proofsAandC,
        uint256[] memory inputAccumulators
    ) {
        uint256 q = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        uint256 numPublicInputs = proof_inputs.length / num_proofs;
        uint256[] memory entropy = new uint256[](num_proofs);
        inputAccumulators = new uint256[](numPublicInputs + 1);

        for (uint256 proofNumber = 0; proofNumber < num_proofs; proofNumber++) {
            if (proofNumber == 0) {
                entropy[proofNumber] = 1;
            } else {
                // entropy[proofNumber] = uint(blockhash(block.number - proofNumber)) % q;
                // Safer entropy:
                entropy[proofNumber] = getProofEntropy(in_proof, proof_inputs, proofNumber);
            }
            require(entropy[proofNumber] != 0, "Entropy should not be zero");
            // here multiplication by 1 is implied
            inputAccumulators[0] = addmod(inputAccumulators[0], entropy[proofNumber], q);
            for (uint256 i = 0; i < numPublicInputs; i++) {
                require(proof_inputs[proofNumber * numPublicInputs + i] < q, "INVALID_INPUT");
                // accumulate the exponent with extra entropy mod q
                inputAccumulators[i+1] = addmod(inputAccumulators[i+1], mulmod(entropy[proofNumber], proof_inputs[proofNumber * numPublicInputs + i], q), q);
            }
            // coefficient for +vk.alpha (mind +) is the same as inputAccumulator[0]
        }

        // inputs for scalar multiplication
        uint256[3] memory mul_input;

        // use scalar multiplications to get proof.A[i] * entropy[i]

        proofsAandC = new uint256[](num_proofs*2 + 2);

        proofsAandC[0] = in_proof[0];
        proofsAandC[1] = in_proof[1];

        for (uint256 proofNumber = 1; proofNumber < num_proofs; proofNumber++) {
            require(entropy[proofNumber] < q, "INVALID_INPUT");
            mul_input[0] = in_proof[proofNumber*8];
            mul_input[1] = in_proof[proofNumber*8 + 1];
            mul_input[2] = entropy[proofNumber];
            assembly {
                // ECMUL, output proofsA[i]
                // success := staticcall(sub(gas, 2000), 7, mul_input, 0x60, add(add(proofsAandC, 0x20), mul(proofNumber, 0x40)), 0x40)
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x60, mul_input, 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }
            proofsAandC[proofNumber*2] = mul_input[0];
            proofsAandC[proofNumber*2 + 1] = mul_input[1];
        }

        // use scalar multiplication and addition to get sum(proof.C[i] * entropy[i])

        uint256[4] memory add_input;

        add_input[0] = in_proof[6];
        add_input[1] = in_proof[7];

        for (uint256 proofNumber = 1; proofNumber < num_proofs; proofNumber++) {
            mul_input[0] = in_proof[proofNumber*8 + 6];
            mul_input[1] = in_proof[proofNumber*8 + 7];
            mul_input[2] = entropy[proofNumber];
            assembly {
                // ECMUL, output proofsA
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x60, add(add_input, 0x40), 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }

            assembly {
                // ECADD from two elements that are in add_input and output into first two elements of add_input
                success := staticcall(sub(gas(), 2000), 6, add_input, 0x80, add_input, 0x40)
            }
            if (!success) {
                return (false, proofsAandC, inputAccumulators);
            }
        }

        proofsAandC[num_proofs*2] = add_input[0];
        proofsAandC[num_proofs*2 + 1] = add_input[1];
    }

    function prepareBatches(
        uint256[14] memory in_vk,
        uint256[4] memory vk_gammaABC,
        uint256[] memory inputAccumulators
    ) internal view returns (
        bool success,
        uint256[4] memory finalVksAlphaX
    ) {
        // Compute the linear combination vk_x using accumulator
        // First two fields are used as the sum and are initially zero
        uint256[4] memory add_input;
        uint256[3] memory mul_input;

        // Performs a sum(gammaABC[i] * inputAccumulator[i])
        for (uint256 i = 0; i < inputAccumulators.length; i++) {
            mul_input[0] = vk_gammaABC[2*i];
            mul_input[1] = vk_gammaABC[2*i + 1];
            mul_input[2] = inputAccumulators[i];

            assembly {
                // ECMUL, output to the last 2 elements of `add_input`
                success := staticcall(sub(gas(), 2000), 7, mul_input, 0x60, add(add_input, 0x40), 0x40)
            }
            if (!success) {
                return (false, finalVksAlphaX);
            }

            assembly {
                // ECADD from four elements that are in add_input and output into first two elements of add_input
                success := staticcall(sub(gas(), 2000), 6, add_input, 0x80, add_input, 0x40)
            }
            if (!success) {
                return (false, finalVksAlphaX);
            }
        }

        finalVksAlphaX[2] = add_input[0];
        finalVksAlphaX[3] = add_input[1];

        // add one extra memory slot for scalar for multiplication usage
        uint256[3] memory finalVKalpha;
        finalVKalpha[0] = in_vk[0];
        finalVKalpha[1] = in_vk[1];
        finalVKalpha[2] = inputAccumulators[0];

        assembly {
            // ECMUL, output to first 2 elements of finalVKalpha
            success := staticcall(sub(gas(), 2000), 7, finalVKalpha, 0x60, finalVKalpha, 0x40)
        }
        if (!success) {
            return (false, finalVksAlphaX);
        }

        finalVksAlphaX[0] = finalVKalpha[0];
        finalVksAlphaX[1] = finalVKalpha[1];
    }

    // original equation
    // e(proof.A, proof.B)*e(-vk.alpha, vk.beta)*e(-vk_x, vk.gamma)*e(-proof.C, vk.delta) == 1
    // accumulation of inputs
    // gammaABC[0] + sum[ gammaABC[i+1]^proof_inputs[i] ]

    function BatchVerify (
        uint256[14] memory in_vk, // verifying key is always constant number of elements
        uint256[4] memory vk_gammaABC, // variable length, depends on number of inputs
        uint256[] memory in_proof, // proof itself, length is 8 * num_proofs
        uint256[] memory proof_inputs, // public inputs, length is num_inputs * num_proofs
        uint256 num_proofs
    )
    internal
    view
    returns (bool success)
    {
        require(in_proof.length == num_proofs * 8, "Invalid proofs length for a batch");
        require(proof_inputs.length % num_proofs == 0, "Invalid inputs length for a batch");
        require(((vk_gammaABC.length / 2) - 1) == proof_inputs.length / num_proofs, "Invalid verification key");

        // strategy is to accumulate entropy separately for some proof elements
        // (accumulate only for G1, can't in G2) of the pairing equation, as well as input verification key,
        // postpone scalar multiplication as much as possible and check only one equation
        // by using 3 + num_proofs pairings only plus 2*num_proofs + (num_inputs+1) + 1 scalar multiplications compared to naive
        // 4*num_proofs pairings and num_proofs*(num_inputs+1) scalar multiplications

        bool valid;
        uint256[] memory proofsAandC;
        uint256[] memory inputAccumulators;
        (valid, proofsAandC, inputAccumulators) = accumulate(in_proof, proof_inputs, num_proofs);
        if (!valid) {
            return false;
        }

        uint256[4] memory finalVksAlphaX;
        (valid, finalVksAlphaX) = prepareBatches(in_vk, vk_gammaABC, inputAccumulators);
        if (!valid) {
            return false;
        }

        uint256[] memory inputs = new uint256[](6*num_proofs + 18);
        // first num_proofs pairings e(ProofA, ProofB)
        for (uint256 proofNumber = 0; proofNumber < num_proofs; proofNumber++) {
            inputs[proofNumber*6] = proofsAandC[proofNumber*2];
            inputs[proofNumber*6 + 1] = proofsAandC[proofNumber*2 + 1];
            inputs[proofNumber*6 + 2] = in_proof[proofNumber*8 + 2];
            inputs[proofNumber*6 + 3] = in_proof[proofNumber*8 + 3];
            inputs[proofNumber*6 + 4] = in_proof[proofNumber*8 + 4];
            inputs[proofNumber*6 + 5] = in_proof[proofNumber*8 + 5];
        }

        // second pairing e(-finalVKaplha, vk.beta)
        inputs[num_proofs*6] = finalVksAlphaX[0];
        inputs[num_proofs*6 + 1] = NegateY(finalVksAlphaX[1]);
        inputs[num_proofs*6 + 2] = in_vk[2];
        inputs[num_proofs*6 + 3] = in_vk[3];
        inputs[num_proofs*6 + 4] = in_vk[4];
        inputs[num_proofs*6 + 5] = in_vk[5];

        // third pairing e(-finalVKx, vk.gamma)
        inputs[num_proofs*6 + 6] = finalVksAlphaX[2];
        inputs[num_proofs*6 + 7] = NegateY(finalVksAlphaX[3]);
        inputs[num_proofs*6 + 8] = in_vk[6];
        inputs[num_proofs*6 + 9] = in_vk[7];
        inputs[num_proofs*6 + 10] = in_vk[8];
        inputs[num_proofs*6 + 11] = in_vk[9];

        // fourth pairing e(-proof.C, finalVKdelta)
        inputs[num_proofs*6 + 12] = proofsAandC[num_proofs*2];
        inputs[num_proofs*6 + 13] = NegateY(proofsAandC[num_proofs*2 + 1]);
        inputs[num_proofs*6 + 14] = in_vk[10];
        inputs[num_proofs*6 + 15] = in_vk[11];
        inputs[num_proofs*6 + 16] = in_vk[12];
        inputs[num_proofs*6 + 17] = in_vk[13];

        uint256 inputsLength = inputs.length * 32;
        uint[1] memory out;
        require(inputsLength % 192 == 0, "Inputs length should be multiple of 192 bytes");

        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(inputs, 0x20), inputsLength, out, 0x20)
        }
        return success && out[0] == 1;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title ReentrancyGuard
/// @author Brecht Devos - <[email protected]>
/// @dev Exposes a modifier that guards a function against reentrancy
///      Changing the value of the same storage value multiple times in a transaction
///      is cheap (starting from Istanbul) so there is no need to minimize
///      the number of times the value is changed
contract ReentrancyGuard
{
    //The default value must be 0 in order to work behind a proxy.
    uint private _guardValue;

    // Use this modifier on a function to prevent reentrancy
    modifier nonReentrant()
    {
        // Check if the guard value has its original value
        require(_guardValue == 0, "REENTRANCY");

        // Set the value to something else
        _guardValue = 1;

        // Function body
        _;

        // Set the value back
        _guardValue = 0;
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;


/// @title Ownable
/// @author Brecht Devos - <[email protected]>
/// @dev The Ownable contract has an owner address, and provides basic
///      authorization control functions, this simplifies the implementation of
///      "user permissions".
contract Ownable
{
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @dev The Ownable constructor sets the original `owner` of the contract
    ///      to the sender.
    constructor()
    {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to transfer control of the contract to a
    ///      new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        virtual
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

import "./Ownable.sol";


/// @title Claimable
/// @author Brecht Devos - <[email protected]>
/// @dev Extension for the Ownable contract, where the ownership needs
///      to be claimed. This allows the new owner to accept the transfer.
contract Claimable is Ownable
{
    address public pendingOwner;

    /// @dev Modifier throws if called by any account other than the pendingOwner.
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    /// @dev Allows the current owner to set the pendingOwner address.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(
        address newOwner
        )
        public
        override
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    /// @dev Allows the pendingOwner address to finalize the transfer.
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;


/// @title Hard coded verification keys
/// @dev Generated on 18-Jul-2022 16:56:48, CST
/// @author Berg Jefferson - <[email protected]>
library VerificationKeys
{
    function getKey(
        uint blockType,
        uint blockSize,
        uint blockVersion
        )
        internal
        pure
        returns (uint[14] memory vk, uint[4] memory vk_gammaABC, bool found)
    {
        if (blockType == 0 && blockSize == 320 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              10281411527352048689531947275247127593081118036396478391442821647666120308913,
              14183766028271644690470780121877355548484926092796433542558999536886188797553,
              14349647251177890270720878224680774493644831098564173078581106028536056029223,
              15540448762688867075244269528277703422600214973471138114466012441044685509617
            ];
            vk_gammaABC = [
              2036556296679026605970417947515419195316778870434507698326069579149296210962,
              15349395870630460495061082402789532847406129257251762630279852649806199549853,
              2970255263746651339212945286134273939894820279936213692999533488550413757005,
              20792110978196173681712627864437491850879240957095988115137813293532563193144
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 170 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              4682956840302592794117972770732445682263226956788713975934573863025791110303,
              16388848861784882888589634675145717963592918816432396564828229704061563785209,
              17374855162930851919868736484596498864648735838219181623769762056149693254153,
              19151407009613833113563526940782946598731877452289219330880970240504238030391
            ];
            vk_gammaABC = [
              14277877491890615483788923438557660958420882868332469876219233439317058131714,
              17763719798841200282935388779879967660154386860649176565473486252266461816244,
              11676440789910270300805377502224217134463843339809794860688448139316117328273,
              2550682711891728640045096199092753295207803069012232991501293755789969913664
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 85 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              7176572436556340075494288443996968532283303781781727452170706971225381465456,
              16974633487402837120290705904970824777342149734047518756125810733295679483401,
              701124790896773824097555437817531168131539378259519484384912937099759446184,
              10413816355642916256252679014026612316390050207594924083742901898785171328296
            ];
            vk_gammaABC = [
              16577416683973189932177788112116668199694051930641644285264304846213834235781,
              8029124028901271703727249176267437825833448231262511110292326042239647426173,
              17164092919283319521890516803883671695099789389371545881183117706244506903503,
              12213032100002461288473760183078425124449127549097495533178521131012070789010
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 42 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              15991122211399014054858520545695515058992825947661419737316587061521089547115,
              10087301294407364395881490842035696810370038670172092730950488223488978860300,
              1475443887588386146266576117442642124181882705861470672553565939002278514472,
              18205018162955350608738335811130499992456092320051659374558313621251945051172
            ];
            vk_gammaABC = [
              11701666985805172207714976508629269208942276007531431070823617503859097856975,
              10081450245900171073611938777581003349442436088415374305589757561264604800905,
              6028260966411862903781219033850779543076525648793061295030395467354330833156,
              20262359318070559490611845745591700279454349880824732391760528882106422988393
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 20 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              4417602906978363333364539119320966552370726265813898789256384585078837390325,
              991306936432055864498290372119289294419760628409022834558954454801904066104,
              12905390383568132357564809092281370158294691219380752885361174669514602348689,
              20039526902544359258862977146902692843362181008581860198599235351698976321432
            ];
            vk_gammaABC = [
              5429535145598861903493122446598043028382019646721032879633796522908942368785,
              1594353559290590718822412556322849823880750114639389230212676576803572400567,
              7283605362129442098734434572970704215356783924569644755813234600492390681179,
              3681370426949555695979263921239784991447868245163814206854981665812768157990
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 10 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              5589845853692782918093798700451361218403826782596297099044680334081719512766,
              16872568814719374508137776421494919679598593816968091647888829987641202317026,
              9213911990469912458915358010803544007265138890761628989572682166650184075828,
              6628266818813536300630992540891301894070396127406500679289605594288504130293
            ];
            vk_gammaABC = [
              5378079414375850537507246593130226014126808587722207910960361143396242273340,
              9545472785278840640630004644579299385027334707848211218843089747665483294884,
              3602919804732032634992146901578180017522667425908714034264579560277125106745,
              16141863154397234458253515947259415515922258049666230632249761283586065498664
            ];
            found = true;
        } else if (blockType == 0 && blockSize == 5 && blockVersion == 0) {
            vk = [
              16793088828761447659194981100824992847265780332868459083455944085990813660003,
              7171817661952153622715226685091268120539725174753669007760137371648250991881,
              9348942992461078053111340264031229109307292525381188585386598416653094746146,
              7000808205945708837626583581937549432639670223920654839292245259240931345079,
              8086313864518839365013769589150291755491653280780905775483949168501529075376,
              15353756590565357110735068195722648775179040886283053051713677884218506863285,
              11559732032986387107991004021392285783925812861821192530917403151452391805634,
              10857046999023057135944570762232829481370756359578518086990519993285655852781,
              4082367875863433681332203403145435568316851327593401208105741076214120093531,
              8495653923123431417604973247489272438418190587263600148770280649306958101930,
              740762425135898939855909783827111402857327519032730032890074379422624835096,
              4269737538950126719147228602045146595446702787375606107810931493230002422909,
              16783530978016627329294141456128139892048905473999974821959721444983766807413,
              6044744913703755482072657932054313497583646935032862350258569946795772765536
            ];
            vk_gammaABC = [
              14979171551378673983218799401899226916444141930376281160798273912346257564167,
              202192970803325769224285261255485590655157422637474488924213158809414449002,
              113876707811528671593245045046838668773075968485353445397500408985444199547,
              13855223698095345829184539308103509884437770510363661924460511005730452504890
            ];
            found = true;
        } else {
            found = false;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;

import "../../lib/Claimable.sol";


/// @title ILoopringV3
/// @author Brecht Devos - <[email protected]>
/// @author Daniel Wang  - <[email protected]>
abstract contract ILoopringV3 is Claimable
{
    // == Events ==
    event ExchangeStakeDeposited(address exchangeAddr, uint amount);
    event ExchangeStakeWithdrawn(address exchangeAddr, uint amount);
    event ExchangeStakeBurned(address exchangeAddr, uint amount);
    event SettingsUpdated(uint time);

    // == Public Variables ==
    mapping (address => uint) internal exchangeStake;

    uint    public totalStake;
    address public blockVerifierAddress;
    uint    public forcedWithdrawalFee;
    uint8   public protocolFeeBips;
    

    address payable public protocolFeeVault;

    // == Public Functions ==

    /// @dev Returns the LRC token address
    /// @return the LRC token address
    function lrcAddress()
        external
        view
        virtual
        returns (address);

    /// @dev Updates the global exchange settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateSettings(
        address payable _protocolFeeVault,   // address(0) not allowed
        uint    _forcedWithdrawalFee
        )
        external
        virtual;

    /// @dev Updates the global protocol fee settings.
    ///      This function can only be called by the owner of this contract.
    ///
    ///      Warning: these new values will be used by existing and
    ///      new Loopring exchanges.
    function updateProtocolFeeSettings(
        uint8 _protocolFeeBips
        )
        external
        virtual;

    /// @dev Gets the amount of staked LRC for an exchange.
    /// @param exchangeAddr The address of the exchange
    /// @return stakedLRC The amount of LRC
    function getExchangeStake(
        address exchangeAddr
        )
        external
        virtual
        view
        returns (uint stakedLRC);

    /// @dev Burns a certain amount of staked LRC for a specific exchange.
    ///      This function is meant to be called only from exchange contracts.
    /// @return burnedLRC The amount of LRC burned. If the amount is greater than
    ///         the staked amount, all staked LRC will be burned.
    function burnExchangeStake(
        uint amount
        )
        external
        virtual
        returns (uint burnedLRC);

    /// @dev Stakes more LRC for an exchange.
    /// @param  exchangeAddr The address of the exchange
    /// @param  amountLRC The amount of LRC to stake
    /// @return stakedLRC The total amount of LRC staked for the exchange
    function depositExchangeStake(
        address exchangeAddr,
        uint    amountLRC
        )
        external
        virtual
        returns (uint stakedLRC);

    /// @dev Withdraws a certain amount of staked LRC for an exchange to the given address.
    ///      This function is meant to be called only from within exchange contracts.
    /// @param  recipient The address to receive LRC
    /// @param  requestedAmount The amount of LRC to withdraw
    /// @return amountLRC The amount of LRC withdrawn
    function withdrawExchangeStake(
        address recipient,
        uint    requestedAmount
        )
        external
        virtual
        returns (uint amountLRC);

    /// @dev Gets the protocol fee values for an exchange.
    /// @return feeBips The protocol fee
    function getProtocolFeeValues(
        )
        external
        virtual
        view
        returns (
            uint8 feeBips
        );
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022
pragma solidity ^0.7.0;


/// @title IDepositContract.
/// @dev   Contract storing and transferring funds for an exchange.
///
///        ERC1155 tokens can be supported by registering pseudo token addresses calculated
///        as `address(keccak256(real_token_address, token_params))`. Then the custom
///        deposit contract can look up the real token address and paramsters with the
///        pseudo token address before doing the transfers.
/// @author Brecht Devos - <[email protected]>
interface IDepositContract
{
    /// @dev Returns if a token is suppoprted by this contract.
    function isTokenSupported(address token)
        external
        view
        returns (bool);

    /// @dev Transfers tokens from a user to the exchange. This function will
    ///      be called when a user deposits funds to the exchange.
    ///      In a simple implementation the funds are simply stored inside the
    ///      deposit contract directly. More advanced implementations may store the funds
    ///      in some DeFi application to earn interest, so this function could directly
    ///      call the necessary functions to store the funds there.
    ///
    ///      This function needs to throw when an error occurred!
    ///
    ///      This function can only be called by the exchange.
    ///
    /// @param from The address of the account that sends the tokens.
    /// @param token The address of the token to transfer (`0x0` for ETH).
    /// @param amount The amount of tokens to transfer.
    /// @param extraData Opaque data that can be used by the contract to handle the deposit
    /// @return amountReceived The amount to deposit to the user's account in the Merkle tree
    function deposit(
        address from,
        address token,
        uint248  amount,
        bytes   calldata extraData
        )
        external
        payable
        returns (uint248 amountReceived);

    /// @dev Transfers tokens from the exchange to a user. This function will
    ///      be called when a withdrawal is done for a user on the exchange.
    ///      In the simplest implementation the funds are simply stored inside the
    ///      deposit contract directly so this simply transfers the requested tokens back
    ///      to the user. More advanced implementations may store the funds
    ///      in some DeFi application to earn interest so the function would
    ///      need to get those tokens back from the DeFi application first before they
    ///      can be transferred to the user.
    ///
    ///      This function needs to throw when an error occurred!
    ///
    ///      This function can only be called by the exchange.
    ///
    /// @param from The address from which 'amount' tokens are transferred.
    /// @param to The address to which 'amount' tokens are transferred.
    /// @param token The address of the token to transfer (`0x0` for ETH).
    /// @param amount The amount of tokens transferred.
    function withdraw(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        payable;

    /// @dev Transfers tokens (ETH not supported) for a user using the allowance set
    ///      for the exchange. This way the approval can be used for all functionality (and
    ///      extended functionality) of the exchange.
    ///      Should NOT be used to deposit/withdraw user funds, `deposit`/`withdraw`
    ///      should be used for that as they will contain specialised logic for those operations.
    ///      This function can be called by the exchange to transfer onchain funds of users
    ///      necessary for Agent functionality.
    ///
    ///      This function needs to throw when an error occurred!
    ///
    ///      This function can only be called by the exchange.
    ///
    /// @param from The address of the account that sends the tokens.
    /// @param to The address to which 'amount' tokens are transferred.
    /// @param token The address of the token to transfer (ETH is and cannot be suppported).
    /// @param amount The amount of tokens transferred.
    function transfer(
        address from,
        address to,
        address token,
        uint    amount
        )
        external
        payable;

    /// @dev Checks if the given address is used for depositing ETH or not.
    ///      Is used while depositing to send the correct ETH amount to the deposit contract.
    ///
    ///      Note that 0x0 is always registered for deposting ETH when the exchange is created!
    ///      This function allows additional addresses to be used for depositing ETH, the deposit
    ///      contract can implement different behaviour based on the address value.
    ///
    /// @param addr The address to check
    /// @return True if the address is used for depositing ETH, else false.
    function isETH(address addr)
        external
        view
        returns (bool);
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022

import "../../lib/Claimable.sol";

/// @title IBlockVerifier
/// @author Brecht Devos - <[email protected]>
abstract contract IBlockVerifier is Claimable
{
    // -- Events --

    event CircuitRegistered(
        uint8  indexed blockType,
        uint16         blockSize,
        uint8          blockVersion
    );

    event CircuitDisabled(
        uint8  indexed blockType,
        uint16         blockSize,
        uint8          blockVersion
    );

    // -- Public functions --

    /// @dev Sets the verifying key for the specified circuit.
    ///      Every block permutation needs its own circuit and thus its own set of
    ///      verification keys. Only a limited number of block sizes per block
    ///      type are supported.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param vk The verification key
    function registerCircuit(
        uint8    blockType,
        uint16   blockSize,
        uint8    blockVersion,
        uint[18] calldata vk
        )
        external
        virtual;

    /// @dev Disables the use of the specified circuit.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    function disableCircuit(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual;

    /// @dev Verifies blocks with the given public data and proofs.
    ///      Verifying a block makes sure all requests handled in the block
    ///      are correctly handled by the operator.
    /// @param blockType The type of block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @param publicInputs The hash of all the public data of the blocks
    /// @param proofs The ZK proofs proving that the blocks are correct
    /// @return True if the block is valid, false otherwise
    function verifyProofs(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion,
        uint[] calldata publicInputs,
        uint[] calldata proofs
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Checks if a circuit with the specified parameters is registered.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is registered, false otherwise
    function isCircuitRegistered(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Checks if a circuit can still be used to commit new blocks.
    /// @param blockType The type of the block
    /// @param blockSize The number of requests handled in the block
    /// @param blockVersion The block version (i.e. which circuit version needs to be used)
    /// @return True if the circuit is enabled, false otherwise
    function isCircuitEnabled(
        uint8  blockType,
        uint16 blockSize,
        uint8  blockVersion
        )
        external
        virtual
        view
        returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
pragma solidity ^0.7.0;

interface IAgent{}

abstract contract IAgentRegistry
{
    /// @dev Returns whether an agent address is an agent of an account owner
    /// @param owner The account owner.
    /// @param agent The agent address
    /// @return True if the agent address is an agent for the account owner, else false
    function isAgent(
        address owner,
        address agent
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Returns whether an agent address is an agent of all account owners
    /// @param owners The account owners.
    /// @param agent The agent address
    /// @return True if the agent address is an agent for the account owner, else false
    function isAgent(
        address[] calldata owners,
        address            agent
        )
        external
        virtual
        view
        returns (bool);

    /// @dev Returns whether an agent address is a universal agent.
    /// @param agent The agent address
    /// @return True if the agent address is a universal agent, else false
    function isUniversalAgent(address agent)
        public
        virtual
        view
        returns (bool);
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: Apache-2.0
// Copyright 2017 Loopring Technology Limited.
// Modified by DeGate DAO, 2022

import "./IAgentRegistry.sol";
import "./IBlockVerifier.sol";
import "./IDepositContract.sol";
import "./ILoopringV3.sol";

/// @title ExchangeData
/// @dev All methods in this lib are internal, therefore, there is no need
///      to deploy this library independently.
/// @author Daniel Wang  - <[email protected]>
/// @author Brecht Devos - <[email protected]>
library ExchangeData
{
    // -- Enums --
    enum TransactionType
    {
        NOOP,
        DEPOSIT,
        WITHDRAWAL,
        TRANSFER,
        SPOT_TRADE,
        ACCOUNT_UPDATE,
        ORDER_CANCEL,
        BATCH_SPOT_TRADE,
        APPKEY_UPDATE
    }

    // -- Structs --
    struct Token
    {
        address token;
    }

    struct ProtocolFeeData
    {
        uint32 syncedAt; // only valid before 2105 (85 years to go)
        uint8  protocolFeeBips;
        uint8  previousProtocolFeeBips;

        uint32 executeTimeOfNextProtocolFeeBips;
        uint8  nextProtocolFeeBips;
    }

    // General auxiliary data for each conditional transaction
    struct AuxiliaryData
    {
        bytes data;
    }

    // This is the (virtual) block the owner  needs to submit onchain to maintain the
    // per-exchange (virtual) blockchain.
    struct Block
    {
        uint8      blockType;
        uint16     blockSize;
        uint8      blockVersion;
        bytes      data;
        uint256[8] proof;

        // Whether we should store the @BlockInfo for this block on-chain.
        bool storeBlockInfoOnchain;

        // Block specific data that is only used to help process the block on-chain.
        // It is not used as input for the circuits and it is not necessary for data-availability.
        // This bytes array contains the abi encoded AuxiliaryData[] data.
        bytes auxiliaryData;

        // Arbitrary data, mainly for off-chain data-availability, i.e.,
        // the multihash of the IPFS file that contains the block data.
        bytes offchainData;
    }

    struct BlockInfo
    {
        // The time the block was submitted on-chain.
        uint32  timestamp;
        // The public data hash of the block (the 28 most significant bytes).
        bytes28 blockDataHash;
    }

    // Represents an onchain deposit request.
    struct Deposit
    {
        uint248 amount;
        uint64 timestamp;
    }

    // A forced withdrawal request.
    // If the actual owner of the account initiated the request (we don't know who the owner is
    // at the time the request is being made) the full balance will be withdrawn.
    struct ForcedWithdrawal
    {
        address owner;
        uint64  timestamp;
    }

    struct Constants
    {
        uint SNARK_SCALAR_FIELD;
        uint MAX_OPEN_FORCED_REQUESTS;
        uint MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE;
        uint TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS;
        uint MAX_NUM_ACCOUNTS;
        uint MAX_NUM_TOKENS;
        uint MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED;
        uint MIN_TIME_IN_SHUTDOWN;
        uint TX_DATA_AVAILABILITY_SIZE;
        uint MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND;
        uint MAX_FORCED_WITHDRAWAL_FEE;
        uint MAX_PROTOCOL_FEE_BIPS;
        uint DEFAULT_PROTOCOL_FEE_BIPS;
    }

    // This is the prime number that is used for the alt_bn128 elliptic curve, see EIP-196.
    uint public constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

    uint public constant MAX_OPEN_FORCED_REQUESTS = 100;
    uint public constant MAX_AGE_FORCED_REQUEST_UNTIL_WITHDRAW_MODE = 1 days;
    uint public constant TIMESTAMP_HALF_WINDOW_SIZE_IN_SECONDS = 7 days;
    uint public constant BINARY_TREE_DEPTH_ACCOUNTS = 32;
    uint public constant MAX_NUM_ACCOUNTS = 2 ** BINARY_TREE_DEPTH_ACCOUNTS;
    uint public constant BINARY_TREE_DEPTH_TOKENS = 32;
    uint public constant MAX_NUM_TOKENS = 2 ** BINARY_TREE_DEPTH_TOKENS;
    uint public constant MAX_NUM_RESERVED_TOKENS = 32;
    uint public constant MAX_NUM_NORMAL_TOKENS = 2 ** BINARY_TREE_DEPTH_TOKENS - 32;

    uint public constant MIN_AGE_PROTOCOL_FEES_UNTIL_UPDATED = 1 days;
    uint public constant MIN_TIME_IN_SHUTDOWN = 3 days;
    uint32 public constant MAX_AGE_DEPOSIT_UNTIL_WITHDRAWABLE_UPPERBOUND = 1 days;
    uint32 public constant ACCOUNTID_PROTOCOLFEE = 0;

    // The amount of bytes each rollup transaction uses in the block data for data-availability.
    // This is the maximum amount of bytes of all different transaction types.
    uint public constant TX_DATA_AVAILABILITY_SIZE = 83;
    uint public constant TX_DATA_AVAILABILITY_SIZE_PART_1 = 80;
    uint public constant TX_DATA_AVAILABILITY_SIZE_PART_2 = 3;

    uint public constant MAX_FORCED_WITHDRAWAL_FEE = 0.25 ether;

    uint8 public constant MAX_PROTOCOL_FEE_BIPS = 100;
    uint8 public constant DEFAULT_PROTOCOL_FEE_BIPS = 18;

    struct AccountLeaf
    {
        uint32   accountID;
        address  owner;
        uint     pubKeyX;
        uint     pubKeyY;
        uint32   nonce;
    }

    struct BalanceLeaf
    {
        uint32  tokenID;
        uint248 balance;
    }

    struct MerkleProof
    {
        ExchangeData.AccountLeaf accountLeaf;
        ExchangeData.BalanceLeaf balanceLeaf;
        uint[48]                 accountMerkleProof;
        uint[48]                 balanceMerkleProof;
    }

    struct BlockContext
    {
        bytes32 DOMAIN_SEPARATOR;
        uint32  timestamp;
    }

   struct DepositState {
        uint256 freeDepositMax;
        uint256 freeDepositRemained;
        uint256 lastDepositBlockNum;
        uint256 freeSlotPerBlock;
        uint256 depositFee;
    }

    struct ModeTime {
        // Time when the exchange was shutdown
        uint shutdownModeStartTime;

        // Time when the exchange has entered withdrawal mode
        uint withdrawalModeStartTime;
    }

    // Represents the entire exchange state except the owner of the exchange.
    struct State
    {
        uint32  maxAgeDepositUntilWithdrawable;
        bytes32 DOMAIN_SEPARATOR;

        ILoopringV3      loopring;
        IBlockVerifier   blockVerifier;
        IAgentRegistry   agentRegistry;
        IDepositContract depositContract;
        DepositState depositState;
        // The merkle root of the offchain data stored in a Merkle tree. The Merkle tree
        // stores balances for users using an account model.
        bytes32 merkleRoot;
        bytes32 merkleAssetRoot;

        // List of all blocks
        mapping(uint => BlockInfo) blocks;
        uint  numBlocks;

        // List of all tokens
        Token[] reservedTokens;
        Token[] normalTokens;

        // A map from a tokenID to deposit balance
        mapping(uint32 => uint248) tokenIdToDepositBalance;

        // A map from a token to its tokenID + 1
        mapping (address => uint32) tokenToTokenId;
        mapping (uint32 => address) tokenIdToToken;

        // A map from an accountID to a tokenID to if the balance is withdrawn
        mapping (uint32 => mapping (uint32 => bool)) withdrawnInWithdrawMode;

        // A map from an account to a token to the amount withdrawable for that account.
        // This is only used when the automatic distribution of the withdrawal failed.
        mapping (address => mapping (uint32 => uint248)) amountWithdrawable;

        // A map from an account to a token to the forced withdrawal (always full balance)
        mapping (uint32 => mapping (uint32 => ForcedWithdrawal)) pendingForcedWithdrawals;

        // A map from an address to a token to a deposit
        mapping (address => mapping (uint32 => Deposit)) pendingDeposits;

        // A map from an account owner to an approved transaction hash to if the transaction is approved or not
        mapping (address => mapping (bytes32 => bool)) approvedTx;

        // A map from an account owner to a destination address to a tokenID to an amount to a storageID to a new recipient address
        mapping (address => mapping (address => mapping (uint32 => mapping (uint => mapping (uint32 => address))))) withdrawalRecipient;

        // Counter to keep track of how many of forced requests are open so we can limit the work that needs to be done by the owner
        uint32 numPendingForcedTransactions;

        // Cached data for the protocol fee
        ProtocolFeeData protocolFeeData;

        ModeTime modeTime;

        // Last time the protocol fee was withdrawn for a specific token
        mapping (address => uint) protocolFeeLastWithdrawnTime;
    }
}