//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4 <0.9.0;
pragma abicoder v2;

import "../interfaces/IAggregator.sol";
import "../interfaces/IEntryPoint.sol";
import {BLSOpen} from "./lib/BLSOpen.sol";
import "./IBLSAccount.sol";
import "./BLSHelper.sol";

/**
 * A BLS-based signature aggregator, to validate aggregated signature of multiple UserOps if BLSAccount
 */
contract BLSSignatureAggregator is IAggregator {
    using UserOperationLib for UserOperation;

    bytes32 public constant BLS_DOMAIN = keccak256("eip4337.bls.domain");

    function getUserOpPublicKey(UserOperation memory userOp)
        public
        view
        returns (uint256[4] memory publicKey)
    {
        bytes memory initCode = userOp.initCode;
        if (initCode.length > 0) {
            publicKey = getTrailingPublicKey(initCode);
        } else {
            return IBLSAccount(userOp.sender).getBlsPublicKey();
        }
    }

    /**
     * return the trailing 4 words of input data
     */
    function getTrailingPublicKey(bytes memory data)
        public
        pure
        returns (uint256[4] memory publicKey)
    {
        uint256 len = data.length;
        require(len > 32 * 4, "data to short for sig");

        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            // actual buffer starts at data+32, so last 128 bytes start at data+32+len-128 = data+len-96
            let ofs := sub(add(data, len), 96)
            mstore(publicKey, mload(ofs))
            mstore(add(publicKey, 32), mload(add(ofs, 32)))
            mstore(add(publicKey, 64), mload(add(ofs, 64)))
            mstore(add(publicKey, 96), mload(add(ofs, 96)))
        }
    }

    function validateSignatures(
        UserOperation[] calldata userOps,
        bytes calldata signature
    ) external view override {
        require(signature.length == 64, "BLS: invalid signature");
        uint256[2] memory blsSignature = abi.decode(signature, (uint256[2]));

        uint256 userOpsLen = userOps.length;
        uint256[4][] memory blsPublicKeys = new uint256[4][](userOpsLen);
        uint256[2][] memory messages = new uint256[2][](userOpsLen);
        for (uint256 i = 0; i < userOpsLen; i++) {
            UserOperation memory userOp = userOps[i];
            IBLSAccount blsAccount = IBLSAccount(userOp.sender);

            blsPublicKeys[i] = blsAccount.getBlsPublicKey{gas: 30000}();

            messages[i] = _userOpToMessage(
                userOp,
                keccak256(abi.encode(blsPublicKeys[i]))
            );
        }
        require(
            BLSOpen.verifyMultiple(blsSignature, blsPublicKeys, messages),
            "BLS: validateSignatures failed"
        );
    }

    /**
     * get a hash of userOp
     * NOTE: this hash is not the same as UserOperation.hash()
     *  (slightly less efficient, since it uses memory userOp)
     */
    function internalUserOpHash(UserOperation memory userOp)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    userOp.sender,
                    userOp.nonce,
                    keccak256(userOp.initCode),
                    keccak256(userOp.callData),
                    userOp.callGasLimit,
                    userOp.verificationGasLimit,
                    userOp.preVerificationGas,
                    userOp.maxFeePerGas,
                    userOp.maxPriorityFeePerGas,
                    keccak256(userOp.paymasterAndData)
                )
            );
    }

    /**
     * return the BLS "message" for the given UserOp.
     * the account checks the signature over this value  using its public-key
     */
    function userOpToMessage(UserOperation memory userOp)
        public
        view
        returns (uint256[2] memory)
    {
        bytes32 hashPublicKey = _getUserOpPubkeyHash(userOp);
        return _userOpToMessage(userOp, hashPublicKey);
    }

    function _userOpToMessage(
        UserOperation memory userOp,
        bytes32 publicKeyHash
    ) internal view returns (uint256[2] memory) {
        bytes32 userOpHash = _getUserOpHash(userOp, publicKeyHash);
        return BLSOpen.hashToPoint(BLS_DOMAIN, abi.encodePacked(userOpHash));
    }

    //return the public-key hash of a userOp.
    function _getUserOpPubkeyHash(UserOperation memory userOp)
        internal
        view
        returns (bytes32 hashPublicKey)
    {
        return keccak256(abi.encode(getUserOpPublicKey(userOp)));
    }

    function getUserOpHash(UserOperation memory userOp)
        public
        view
        returns (bytes32)
    {
        bytes32 hashPublicKey = _getUserOpPubkeyHash(userOp);
        return _getUserOpHash(userOp, hashPublicKey);
    }

    function _getUserOpHash(UserOperation memory userOp, bytes32 hashPublicKey)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    internalUserOpHash(userOp),
                    hashPublicKey,
                    address(this),
                    block.chainid
                )
            );
    }

    /**
     * validate signature of a single userOp
     * This method is called after EntryPoint.simulateUserOperation() returns an aggregator.
     * First it validates the signature over the userOp. then it return data to be used when creating the handleOps:
     * @param userOp the userOperation received from the user.
     * @return sigForUserOp the value to put into the signature field of the userOp when calling handleOps.
     *    (usually empty, unless account and aggregator support some kind of "multisig"
     */
    function validateUserOpSignature(UserOperation calldata userOp)
        external
        view
        returns (bytes memory sigForUserOp)
    {
        uint256[2] memory signature = abi.decode(
            userOp.signature,
            (uint256[2])
        );
        uint256[4] memory pubkey = getUserOpPublicKey(userOp);
        uint256[2] memory message = userOpToMessage(userOp);

        require(
            BLSOpen.verifySingle(signature, pubkey, message),
            "BLS: wrong sig"
        );
        return "";
    }

    //copied from BLS.sol
    uint256 public constant N =
        21888242871839275222246405745257275088696311157297823662689037894645226208583;

    /**
     * aggregate multiple signatures into a single value.
     * This method is called off-chain to calculate the signature to pass with handleOps()
     * bundler MAY use optimized custom code perform this aggregation
     * @param userOps array of UserOperations to collect the signatures from.
     * @return aggregatesSignature the aggregated signature
     */
    function aggregateSignatures(UserOperation[] calldata userOps)
        external
        pure
        returns (bytes memory aggregatesSignature)
    {
        BLSHelper.XY[] memory points = new BLSHelper.XY[](userOps.length);
        for (uint256 i = 0; i < points.length; i++) {
            (uint256 x, uint256 y) = abi.decode(
                userOps[i].signature,
                (uint256, uint256)
            );
            points[i] = BLSHelper.XY(x, y);
        }
        BLSHelper.XY memory sum = BLSHelper.sum(points, N);
        return abi.encode(sum.x, sum.y);
    }

    /**
     * allow staking for this aggregator
     * there is no limit on stake  or delay, but it is not a problem, since it is a permissionless
     * signature aggregator, which doesn't support unstaking.
     */
    function addStake(IEntryPoint entryPoint, uint32 delay) external payable {
        entryPoint.addStake{value: msg.value}(delay);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

/**
 * Aggregated Signatures validator.
 */
interface IAggregator {
    /**
     * validate aggregated signature.
     * revert if the aggregated signature does not match the given list of operations.
     */
    function validateSignatures(
        UserOperation[] calldata userOps,
        bytes calldata signature
    ) external view;

    /**
     * validate signature of a single userOp
     * This method is called by EntryPoint.simulateUserOperation() if the account has an aggregator.
     * First it validates the signature over the userOp. then it return data to be used when creating the handleOps:
     * @param userOp the userOperation received from the user.
     * @return sigForUserOp the value to put into the signature field of the userOp when calling handleOps.
     *    (usually empty, unless account and aggregator support some kind of "multisig"
     */
    function validateUserOpSignature(UserOperation calldata userOp)
        external
        view
        returns (bytes memory sigForUserOp);

    /**
     * aggregate multiple signatures into a single value.
     * This method is called off-chain to calculate the signature to pass with handleOps()
     * bundler MAY use optimized custom code perform this aggregation
     * @param userOps array of UserOperations to collect the signatures from.
     * @return aggregatesSignature the aggregated signature
     */
    function aggregateSignatures(UserOperation[] calldata userOps)
        external
        view
        returns (bytes memory aggregatesSignature);
}

/**
 ** Account-Abstraction (EIP-4337) singleton EntryPoint implementation.
 ** Only one instance required on each chain.
 **/
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "./UserOperation.sol";
import "./IStakeManager.sol";
import "./IAggregator.sol";

interface IEntryPoint is IStakeManager {
    /***
     * An event emitted after each successful request
     * @param userOpHash - unique identifier for the request (hash its entire content, except signature).
     * @param sender - the account that generates this request.
     * @param paymaster - if non-null, the paymaster that pays for this request.
     * @param nonce - the nonce value from the request
     * @param actualGasCost - the total cost (in gas) of this request.
     * @param actualGasPrice - the actual gas price the sender agreed to pay.
     * @param success - true if the sender transaction succeeded, false if reverted.
     */
    event UserOperationEvent(
        bytes32 indexed userOpHash,
        address indexed sender,
        address indexed paymaster,
        uint256 nonce,
        uint256 actualGasCost,
        uint256 actualGasPrice,
        bool success
    );

    /**
     * An event emitted if the UserOperation "callData" reverted with non-zero length
     * @param userOpHash the request unique identifier.
     * @param sender the sender of this request
     * @param nonce the nonce used in the request
     * @param revertReason - the return bytes from the (reverted) call to "callData".
     */
    event UserOperationRevertReason(
        bytes32 indexed userOpHash,
        address indexed sender,
        uint256 nonce,
        bytes revertReason
    );

    /**
     * a custom revert error of handleOps, to identify the offending op.
     *  NOTE: if simulateValidation passes successfully, there should be no reason for handleOps to fail on it.
     *  @param opIndex - index into the array of ops to the failed one (in simulateValidation, this is always zero)
     *  @param paymaster - if paymaster.validatePaymasterUserOp fails, this will be the paymaster's address. if validateUserOp failed,
     *       this value will be zero (since it failed before accessing the paymaster)
     *  @param reason - revert reason
     *   Should be caught in off-chain handleOps simulation and not happen on-chain.
     *   Useful for mitigating DoS attempts against batchers or for troubleshooting of account/paymaster reverts.
     */
    error FailedOp(uint256 opIndex, address paymaster, string reason);

    /**
     * error case when a signature aggregator fails to verify the aggregated signature it had created.
     */
    error SignatureValidationFailed(address aggregator);

    //UserOps handled, per aggregator
    struct UserOpsPerAggregator {
        UserOperation[] userOps;
        // aggregator address
        IAggregator aggregator;
        // aggregated signature
        bytes signature;
    }

    /**
     * Execute a batch of UserOperation.
     * no signature aggregator is used.
     * if any account requires an aggregator (that is, it returned an "actualAggregator" when
     * performing simulateValidation), then handleAggregatedOps() must be used instead.
     * @param ops the operations to execute
     * @param beneficiary the address to receive the fees
     */
    function handleOps(
        UserOperation[] calldata ops,
        address payable beneficiary
    ) external;

    /**
     * Execute a batch of UserOperation with Aggregators
     * @param opsPerAggregator the operations to execute, grouped by aggregator (or address(0) for no-aggregator accounts)
     * @param beneficiary the address to receive the fees
     */
    function handleAggregatedOps(
        UserOpsPerAggregator[] calldata opsPerAggregator,
        address payable beneficiary
    ) external;

    /**
     * generate a request Id - unique identifier for this request.
     * the request ID is a hash over the content of the userOp (except the signature), the entrypoint and the chainid.
     */
    function getUserOpHash(UserOperation calldata userOp)
        external
        view
        returns (bytes32);

    /**
     * Simulate a call to account.validateUserOp and paymaster.validatePaymasterUserOp.
     * @dev this method always revert. Successful result is SimulationResult error. other errors are failures.
     * @dev The node must also verify it doesn't use banned opcodes, and that it doesn't reference storage outside the account's data.
     * @param userOp the user operation to validate.
     */
    function simulateValidation(UserOperation calldata userOp) external;

    /**
     * Successful result from simulateValidation.
     * @param preOpGas the gas used for validation (including preValidationGas)
     * @param prefund the required prefund for this operation
     * @param deadline until what time this userOp is valid (the minimum value of account and paymaster's deadline)
     * @param paymasterInfo stake information about the paymaster (if any)
     */
    error SimulationResult(
        uint256 preOpGas,
        uint256 prefund,
        uint256 deadline,
        PaymasterInfo paymasterInfo
    );

    /**
     * returned paymaster info.
     * If the UserOperation contains a paymaster, these fields are filled with the paymaster's stake value and delay.
     * A bundler must verify these values are above the minimal required values, or else reject the UserOperation.
     */
    struct PaymasterInfo {
        uint256 paymasterStake;
        uint256 paymasterUnstakeDelay;
    }

    /**
     * Successful result from simulateValidation, if the account returns a signature aggregator
     * @param preOpGas the gas used for validation (including preValidationGas)
     * @param prefund the required prefund for this operation
     * @param deadline until what time this userOp is valid (the minimum value of account and paymaster's deadline)
     * @param paymasterInfo stake information about the paymaster (if any)
     * @param aggregationInfo signature aggregation info (if the account requires signature aggregator)
     *      bundler MUST use it to verify the signature, or reject the UserOperation
     */
    error SimulationResultWithAggregation(
        uint256 preOpGas,
        uint256 prefund,
        uint256 deadline,
        PaymasterInfo paymasterInfo,
        AggregationInfo aggregationInfo
    );

    /**
     * returned aggregated signature info.
     * the aggregator returned by the account, and its current stake.
     */
    struct AggregationInfo {
        address actualAggregator;
        uint256 aggregatorStake;
        uint256 aggregatorUnstakeDelay;
    }

    /**
     * Get counterfactual sender address.
     *  Calculate the sender contract address that will be generated by the initCode and salt in the UserOperation.
     * this method always revert, and returns the address in SenderAddressResult error
     * @param initCode the constructor code to be passed into the UserOperation.
     */
    function getSenderAddress(bytes memory initCode) external;

    /**
     * return value of getSenderAddress
     */
    error SenderAddressResult(address sender);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {BLS} from "./hubble-contracts/contracts/libs/BLS.sol";

library BLSOpen {
    function verifySingle(
        uint256[2] memory signature,
        uint256[4] memory pubkey,
        uint256[2] memory message
    ) external view returns (bool) {
        uint256[4][] memory pubkeys = new uint256[4][](1);
        uint256[2][] memory messages = new uint256[2][](1);
        pubkeys[0] = pubkey;
        messages[0] = message;

        (bool verified, bool callSuccess) = BLS.verifyMultiple(
            signature,
            pubkeys,
            messages
        );
        return callSuccess && verified;

        // // NB: (result, success) opposite of `call` convention (success, result).
        // (bool verified, bool callSuccess) = BLS.verifySingle(
        //     signature,
        //     pubkey,
        //     message
        // );
        // return callSuccess && verified;
    }

    function verifyMultiple(
        uint256[2] memory signature,
        uint256[4][] memory pubkeys,
        uint256[2][] memory messages
    ) external view returns (bool) {
        (bool verified, bool callSuccess) = BLS.verifyMultiple(
            signature,
            pubkeys,
            messages
        );
        return callSuccess && verified;
    }

    function hashToPoint(bytes32 domain, bytes memory message)
        external
        view
        returns (uint256[2] memory)
    {
        return BLS.hashToPoint(domain, message);
    }

    function isZeroBLSKey(uint256[4] memory blsKey) public pure returns (bool) {
        bool isZero = true;
        for (uint256 i = 0; isZero && i < 4; i++) {
            isZero = (blsKey[i] == 0);
        }
        return isZero;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.12;

import "../interfaces/IAggregatedAccount.sol";

/**
 * a BLS account should expose its own public key.
 */
interface IBLSAccount is IAggregatedAccount {
    function getBlsPublicKey() external view returns (uint256[4] memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

// code taken from : https://github.com/witnet/elliptic-curve-solidity/blob/master/contracts/EllipticCurve.sol
// missing core functions from "thehubbleproject/bls": jacAdd (and sum)
library BLSHelper {
    struct XY {
        uint256 x;
        uint256 y;
    }

    /**
     * sum all the points in the array
     * NOTE: the "ecAdd" (below) has a special case where x1==y2.
     * @param points an array of bytes32[2], representing an (x,y) of a point
     * @param _pp the modulus of the curve
     * @return ret the sum of all points
     */
    function sum(XY[] memory points, uint256 _pp)
        internal
        pure
        returns (XY memory ret)
    {
        uint256 x = points[0].x;
        uint256 y = points[0].y;
        uint256 z = 1;

        for (uint256 i = 1; i < points.length; i++) {
            (x, y, z) = jacAdd(x, y, z, points[i].x, points[i].y, 1, _pp);
        }
        (x, y) = toAffine(x, y, z, _pp);
        ret.x = x;
        ret.y = y;
    }

    /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2).
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _z1 coordinate z of P1
    /// @param _x2 coordinate x of square
    /// @param _y2 coordinate y of square
    /// @param _z2 coordinate z of square
    /// @param _pp the modulus
    /// @return (qx, qy, qz) P1+square in Jacobian
    function jacAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _z1,
        uint256 _x2,
        uint256 _y2,
        uint256 _z2,
        uint256 _pp
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_x1 == 0 && _y1 == 0) return (_x2, _y2, _z2);
        if (_x2 == 0 && _y2 == 0) return (_x1, _y1, _z1);

        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
        uint256[4] memory zs;
        // z1^2, z1^3, z2^2, z2^3
        zs[0] = mulmod(_z1, _z1, _pp);
        zs[1] = mulmod(_z1, zs[0], _pp);
        zs[2] = mulmod(_z2, _z2, _pp);
        zs[3] = mulmod(_z2, zs[2], _pp);

        // u1, s1, u2, s2
        zs = [
            mulmod(_x1, zs[2], _pp),
            mulmod(_y1, zs[3], _pp),
            mulmod(_x2, zs[0], _pp),
            mulmod(_y2, zs[1], _pp)
        ];

        // In case of zs[0] == zs[2] && zs[1] == zs[3], double function should be used
        require(
            zs[0] != zs[2] || zs[1] != zs[3],
            "Use jacDouble function instead"
        );

        uint256[4] memory hr;
        //h
        hr[0] = addmod(zs[2], _pp - zs[0], _pp);
        //r
        hr[1] = addmod(zs[3], _pp - zs[1], _pp);
        //h^2
        hr[2] = mulmod(hr[0], hr[0], _pp);
        // h^3
        hr[3] = mulmod(hr[2], hr[0], _pp);
        // qx = -h^3  -2u1h^2+r^2
        uint256 qx = addmod(mulmod(hr[1], hr[1], _pp), _pp - hr[3], _pp);
        qx = addmod(qx, _pp - mulmod(2, mulmod(zs[0], hr[2], _pp), _pp), _pp);
        // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
        uint256 qy = mulmod(
            hr[1],
            addmod(mulmod(zs[0], hr[2], _pp), _pp - qx, _pp),
            _pp
        );
        qy = addmod(qy, _pp - mulmod(zs[1], hr[3], _pp), _pp);
        // qz = h*z1*z2
        uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, _pp), _pp);
        return (qx, qy, qz);
    }

    /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
    /// @param _x coordinate x
    /// @param _y coordinate y
    /// @param _z coordinate z
    /// @param _pp the modulus
    /// @return (x', y') affine coordinates
    function toAffine(
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        uint256 zInv = invMod(_z, _pp);
        uint256 zInv2 = mulmod(zInv, zInv, _pp);
        uint256 x2 = mulmod(_x, zInv2, _pp);
        uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, _pp), _pp);

        return (x2, y2);
    }

    /// @dev Modular euclidean inverse of a number (mod p).
    /// @param _x The number
    /// @param _pp The modulus
    /// @return q such that x*q = 1 (mod _pp)
    function invMod(uint256 _x, uint256 _pp) internal pure returns (uint256) {
        require(_x != 0 && _x != _pp && _pp != 0, "Invalid number");
        uint256 q = 0;
        uint256 newT = 1;
        uint256 r = _pp;
        uint256 t;
        while (_x != 0) {
            t = r / _x;
            (q, newT) = (newT, addmod(q, (_pp - mulmod(t, newT, _pp)), _pp));
            (r, _x) = (_x, r - t * _x);
        }

        return q;
    }

    /// @dev Doubles a points (x, y, z).
    /// @param _x coordinate x of P1
    /// @param _y coordinate y of P1
    /// @param _z coordinate z of P1
    /// @param _aa the a scalar in the curve equation
    /// @param _pp the modulus
    /// @return (qx, qy, qz) 2P in Jacobian
    function jacDouble(
        uint256 _x,
        uint256 _y,
        uint256 _z,
        uint256 _aa,
        uint256 _pp
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (_z == 0) return (_x, _y, _z);

        // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
        // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
        // x, y, z at this point represent the squares of _x, _y, _z
        uint256 x = mulmod(_x, _x, _pp); //x1^2
        uint256 y = mulmod(_y, _y, _pp); //y1^2
        uint256 z = mulmod(_z, _z, _pp); //z1^2

        // s
        uint256 s = mulmod(4, mulmod(_x, y, _pp), _pp);
        // m
        uint256 m = addmod(
            mulmod(3, x, _pp),
            mulmod(_aa, mulmod(z, z, _pp), _pp),
            _pp
        );

        // x, y, z at this point will be reassigned and rather represent qx, qy, qz from the paper
        // This allows to reduce the gas cost and stack footprint of the algorithm
        // qx
        x = addmod(mulmod(m, m, _pp), _pp - addmod(s, s, _pp), _pp);
        // qy = -8*y1^4 + M(S-T)
        y = addmod(
            mulmod(m, addmod(s, _pp - x, _pp), _pp),
            _pp - mulmod(8, mulmod(y, y, _pp), _pp),
            _pp
        );
        // qz = 2*y1*z1
        z = mulmod(2, mulmod(_y, _z, _pp), _pp);

        return (x, y, z);
    }

    /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
    /// @param _x1 coordinate x of P1
    /// @param _y1 coordinate y of P1
    /// @param _x2 coordinate x of P2
    /// @param _y2 coordinate y of P2
    /// @param _aa constant of the curve
    /// @param _pp the modulus
    /// @return (qx, qy) = P1+P2 in affine coordinates
    function ecAdd(
        uint256 _x1,
        uint256 _y1,
        uint256 _x2,
        uint256 _y2,
        uint256 _aa,
        uint256 _pp
    ) internal pure returns (uint256, uint256) {
        uint256 x = 0;
        uint256 y = 0;
        uint256 z = 0;

        // Double if x1==x2 else add
        if (_x1 == _x2) {
            // y1 = -y2 mod p
            if (addmod(_y1, _y2, _pp) == 0) {
                return (0, 0);
            } else {
                // P1 = P2
                (x, y, z) = jacDouble(_x1, _y1, 1, _aa, _pp);
            }
        } else {
            (x, y, z) = jacAdd(_x1, _y1, 1, _x2, _y2, 1, _pp);
        }
        // Get back to affine
        return toAffine(x, y, z, _pp);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

/* solhint-disable no-inline-assembly */

/**
 * User Operation struct
 * @param sender the sender account of this request
 * @param nonce unique value the sender uses to verify it is not a replay.
 * @param initCode if set, the account contract will be created by this constructor
 * @param callData the method call to execute on this account.
 * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp
 * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
 * @param maxFeePerGas same as EIP-1559 gas parameter
 * @param maxPriorityFeePerGas same as EIP-1559 gas parameter
 * @param paymasterAndData if set, this field hold the paymaster address and "paymaster-specific-data". the paymaster will pay for the transaction instead of the sender
 * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
 */
struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGasLimit;
    uint256 verificationGasLimit;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}

library UserOperationLib {
    function getSender(UserOperation calldata userOp)
        internal
        pure
        returns (address)
    {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {
            data := calldataload(userOp)
        }
        return address(uint160(data));
    }

    //relayer/miner might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp)
        internal
        view
        returns (uint256)
    {
        unchecked {
            uint256 maxFeePerGas = userOp.maxFeePerGas;
            uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
            if (maxFeePerGas == maxPriorityFeePerGas) {
                //legacy mode (for networks that don't support basefee opcode)
                return maxFeePerGas;
            }
            return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
        }
    }

    function pack(UserOperation calldata userOp)
        internal
        pure
        returns (bytes memory ret)
    {
        //lighter signature scheme. must match UserOp.ts#packUserOp
        bytes calldata sig = userOp.signature;
        // copy directly the userOp from calldata up to (but not including) the signature.
        // this encoding depends on the ABI encoding of calldata, but is much lighter to copy
        // than referencing each field separately.
        assembly {
            let ofs := userOp
            let len := sub(sub(sig.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
    }

    function hash(UserOperation calldata userOp)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.12;

/**
 * manage deposits and stakes.
 * deposit is just a balance used to pay for UserOperations (either by a paymaster or an account)
 * stake is value locked for at least "unstakeDelay" by a paymaster.
 */
interface IStakeManager {
    event Deposited(address indexed account, uint256 totalDeposit);

    event Withdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeLocked(
        address indexed account,
        uint256 totalStaked,
        uint256 withdrawTime
    );

    /// Emitted once a stake is scheduled for withdrawal
    event StakeUnlocked(address indexed account, uint256 withdrawTime);

    event StakeWithdrawn(
        address indexed account,
        address withdrawAddress,
        uint256 amount
    );

    /**
     * @param deposit the account's deposit
     * @param staked true if this account is staked as a paymaster
     * @param stake actual amount of ether staked for this paymaster.
     * @param unstakeDelaySec minimum delay to withdraw the stake. must be above the global unstakeDelaySec
     * @param withdrawTime - first block timestamp where 'withdrawStake' will be callable, or zero if already locked
     * @dev sizes were chosen so that (deposit,staked) fit into one cell (used during handleOps)
     *    and the rest fit into a 2nd cell.
     *    112 bit allows for 2^15 eth
     *    64 bit for full timestamp
     *    32 bit allow 150 years for unstake delay
     */
    struct DepositInfo {
        uint112 deposit;
        bool staked;
        uint112 stake;
        uint32 unstakeDelaySec;
        uint64 withdrawTime;
    }

    function getDepositInfo(address account)
        external
        view
        returns (DepositInfo memory info);

    /// return the deposit (for gas payment) of the account
    function balanceOf(address account) external view returns (uint256);

    /**
     * add to the deposit of the given account
     */
    function depositTo(address account) external payable;

    /**
     * add to the account's stake - amount and delay
     * any pending unstake is first cancelled.
     * @param _unstakeDelaySec the new lock duration before the deposit can be withdrawn.
     */
    function addStake(uint32 _unstakeDelaySec) external payable;

    /**
     * attempt to unlock the stake.
     * the value can be withdrawn (using withdrawStake) after the unstake delay.
     */
    function unlockStake() external;

    /**
     * withdraw from the (unlocked) stake.
     * must first call unlockStake and wait for the unstakeDelay to pass
     * @param withdrawAddress the address to send withdrawn value.
     */
    function withdrawStake(address payable withdrawAddress) external;

    /**
     * withdraw from the deposit.
     * @param withdrawAddress the address to send withdrawn value.
     * @param withdrawAmount the amount to withdraw.
     */
    function withdrawTo(address payable withdrawAddress, uint256 withdrawAmount)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {ModexpInverse, ModexpSqrt} from "./ModExp.sol";
import {BNPairingPrecompileCostEstimator} from "./BNPairingPrecompileCostEstimator.sol";

/**
    @title  Boneh–Lynn–Shacham (BLS) signature scheme on Barreto-Naehrig 254 bit curve (BN-254)
    @notice We use BLS signature aggregation to reduce the size of signature data to store on chain.
    @dev We use G1 points for signatures and messages, and G2 points for public keys
 */
library BLS {
    // Field order
    // prettier-ignore
    uint256 private constant N = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    // Negated genarator of G2
    // prettier-ignore
    uint256 private constant N_G2_X1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    // prettier-ignore
    uint256 private constant N_G2_X0 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    // prettier-ignore
    uint256 private constant N_G2_Y1 = 17805874995975841540914202342111839520379459829704422454583296818431106115052;
    // prettier-ignore
    uint256 private constant N_G2_Y0 = 13392588948715843804641432497768002650278120570034223513918757245338268106653;

    // sqrt(-3)
    // prettier-ignore
    uint256 private constant Z0 = 0x0000000000000000b3c4d79d41a91759a9e4c7e359b6b89eaec68e62effffffd;
    // (sqrt(-3) - 1)  / 2
    // prettier-ignore
    uint256 private constant Z1 = 0x000000000000000059e26bcea0d48bacd4f263f1acdb5c4f5763473177fffffe;

    // prettier-ignore
    uint256 private constant T24 = 0x1000000000000000000000000000000000000000000000000;
    // prettier-ignore
    uint256 private constant MASK24 = 0xffffffffffffffffffffffffffffffffffffffffffffffff;

    // estimator address
    //    address private constant COST_ESTIMATOR_ADDRESS =  new 0x22E4a5251C1F02de8369Dd6f192033F6CB7531A4;

    function verifySingle(
        uint256[2] memory signature,
        uint256[4] memory pubkey,
        uint256[2] memory message
    ) internal view returns (bool, bool) {
        uint256[12] memory input = [
            signature[0],
            signature[1],
            N_G2_X1,
            N_G2_X0,
            N_G2_Y1,
            N_G2_Y0,
            message[0],
            message[1],
            pubkey[1],
            pubkey[0],
            pubkey[3],
            pubkey[2]
        ];
        uint256[1] memory out;
        uint256 precompileGasCost = gasleft();
        //            BNPairingPrecompileCostEstimator(COST_ESTIMATOR_ADDRESS).getGasCost(
        //                2
        //            );
        bool callSuccess;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            callSuccess := staticcall(
                precompileGasCost,
                8,
                input,
                384,
                out,
                0x20
            )
        }
        if (!callSuccess) {
            return (false, false);
        }
        return (out[0] != 0, true);
    }

    function verifyMultiple(
        uint256[2] memory signature,
        uint256[4][] memory pubkeys,
        uint256[2][] memory messages
    ) internal view returns (bool checkResult, bool callSuccess) {
        uint256 size = pubkeys.length;
        require(size > 0, "BLS: number of public key is zero");
        require(
            size == messages.length,
            "BLS: number of public keys and messages must be equal"
        );
        uint256 inputSize = (size + 1) * 6;
        uint256[] memory input = new uint256[](inputSize);
        input[0] = signature[0];
        input[1] = signature[1];
        input[2] = N_G2_X1;
        input[3] = N_G2_X0;
        input[4] = N_G2_Y1;
        input[5] = N_G2_Y0;
        for (uint256 i = 0; i < size; i++) {
            input[i * 6 + 6] = messages[i][0];
            input[i * 6 + 7] = messages[i][1];
            input[i * 6 + 8] = pubkeys[i][1];
            input[i * 6 + 9] = pubkeys[i][0];
            input[i * 6 + 10] = pubkeys[i][3];
            input[i * 6 + 11] = pubkeys[i][2];
        }
        uint256[1] memory out;

        // prettier-ignore
        uint256 precompileGasCost = gasleft();
        //        uint256 precompileGasCost = BNPairingPrecompileCostEstimator(COST_ESTIMATOR_ADDRESS).getGasCost(size + 1);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            callSuccess := staticcall(
                precompileGasCost,
                8,
                add(input, 0x20),
                mul(inputSize, 0x20),
                out,
                0x20
            )
        }
        if (!callSuccess) {
            return (false, false);
        }
        return (out[0] != 0, true);
    }

    /**
    @notice Fouque-Tibouchi Hash to Curve
     */
    function hashToPoint(bytes32 domain, bytes memory message)
        internal
        view
        returns (uint256[2] memory)
    {
        uint256[2] memory u = hashToField(domain, message);
        uint256[2] memory p0 = mapToPoint(u[0]);
        uint256[2] memory p1 = mapToPoint(u[1]);
        uint256[4] memory bnAddInput;
        bnAddInput[0] = p0[0];
        bnAddInput[1] = p0[1];
        bnAddInput[2] = p1[0];
        bnAddInput[3] = p1[1];
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, bnAddInput, 128, p0, 64)
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "BLS: bn add call failed");
        return p0;
    }

    function mapToPoint(uint256 _x)
        internal
        pure
        returns (uint256[2] memory p)
    {
        require(_x < N, "mapToPointFT: invalid field element");
        uint256 x = _x;

        (, bool decision) = sqrt(x);

        uint256 a0 = mulmod(x, x, N);
        a0 = addmod(a0, 4, N);
        uint256 a1 = mulmod(x, Z0, N);
        uint256 a2 = mulmod(a1, a0, N);
        a2 = inverse(a2);
        a1 = mulmod(a1, a1, N);
        a1 = mulmod(a1, a2, N);

        // x1
        a1 = mulmod(x, a1, N);
        x = addmod(Z1, N - a1, N);
        // check curve
        a1 = mulmod(x, x, N);
        a1 = mulmod(a1, x, N);
        a1 = addmod(a1, 3, N);
        bool found;
        (a1, found) = sqrt(a1);
        if (found) {
            if (!decision) {
                a1 = N - a1;
            }
            return [x, a1];
        }

        // x2
        x = N - addmod(x, 1, N);
        // check curve
        a1 = mulmod(x, x, N);
        a1 = mulmod(a1, x, N);
        a1 = addmod(a1, 3, N);
        (a1, found) = sqrt(a1);
        if (found) {
            if (!decision) {
                a1 = N - a1;
            }
            return [x, a1];
        }

        // x3
        x = mulmod(a0, a0, N);
        x = mulmod(x, x, N);
        x = mulmod(x, a2, N);
        x = mulmod(x, a2, N);
        x = addmod(x, 1, N);
        // must be on curve
        a1 = mulmod(x, x, N);
        a1 = mulmod(a1, x, N);
        a1 = addmod(a1, 3, N);
        (a1, found) = sqrt(a1);
        require(found, "BLS: bad ft mapping implementation");
        if (!decision) {
            a1 = N - a1;
        }
        return [x, a1];
    }

    function isValidSignature(uint256[2] memory signature)
        internal
        pure
        returns (bool)
    {
        if ((signature[0] >= N) || (signature[1] >= N)) {
            return false;
        } else {
            return isOnCurveG1(signature);
        }
    }

    function isOnCurveG1(uint256[2] memory point)
        internal
        pure
        returns (bool _isOnCurve)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let t0 := mload(point)
            let t1 := mload(add(point, 32))
            let t2 := mulmod(t0, t0, N)
            t2 := mulmod(t2, t0, N)
            t2 := addmod(t2, 3, N)
            t1 := mulmod(t1, t1, N)
            _isOnCurve := eq(t1, t2)
        }
    }

    function isOnCurveG2(uint256[4] memory point)
        internal
        pure
        returns (bool _isOnCurve)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            // x0, x1
            let t0 := mload(point)
            let t1 := mload(add(point, 32))
            // x0 ^ 2
            let t2 := mulmod(t0, t0, N)
            // x1 ^ 2
            let t3 := mulmod(t1, t1, N)
            // 3 * x0 ^ 2
            let t4 := add(add(t2, t2), t2)
            // 3 * x1 ^ 2
            let t5 := addmod(add(t3, t3), t3, N)
            // x0 * (x0 ^ 2 - 3 * x1 ^ 2)
            t2 := mulmod(add(t2, sub(N, t5)), t0, N)
            // x1 * (3 * x0 ^ 2 - x1 ^ 2)
            t3 := mulmod(add(t4, sub(N, t3)), t1, N)

            // x ^ 3 + b
            t0 := addmod(
                t2,
                0x2b149d40ceb8aaae81be18991be06ac3b5b4c5e559dbefa33267e6dc24a138e5,
                N
            )
            t1 := addmod(
                t3,
                0x009713b03af0fed4cd2cafadeed8fdf4a74fa084e52d1852e4a2bd0685c315d2,
                N
            )

            // y0, y1
            t2 := mload(add(point, 64))
            t3 := mload(add(point, 96))
            // y ^ 2
            t4 := mulmod(addmod(t2, t3, N), addmod(t2, sub(N, t3), N), N)
            t3 := mulmod(shl(1, t2), t3, N)

            // y ^ 2 == x ^ 3 + b
            _isOnCurve := and(eq(t0, t4), eq(t1, t3))
        }
    }

    function sqrt(uint256 xx) internal pure returns (uint256 x, bool hasRoot) {
        x = ModexpSqrt.run(xx);
        hasRoot = mulmod(x, x, N) == xx;
    }

    function inverse(uint256 a) internal pure returns (uint256) {
        return ModexpInverse.run(a);
    }

    function hashToField(bytes32 domain, bytes memory messages)
        internal
        pure
        returns (uint256[2] memory)
    {
        bytes memory _msg = expandMsgTo96(domain, messages);
        uint256 u0;
        uint256 u1;
        uint256 a0;
        uint256 a1;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let p := add(_msg, 24)
            u1 := and(mload(p), MASK24)
            p := add(_msg, 48)
            u0 := and(mload(p), MASK24)
            a0 := addmod(mulmod(u1, T24, N), u0, N)
            p := add(_msg, 72)
            u1 := and(mload(p), MASK24)
            p := add(_msg, 96)
            u0 := and(mload(p), MASK24)
            a1 := addmod(mulmod(u1, T24, N), u0, N)
        }
        return [a0, a1];
    }

    function expandMsgTo96(bytes32 domain, bytes memory message)
        internal
        pure
        returns (bytes memory)
    {
        // zero<64>|msg<var>|lib_str<2>|I2OSP(0, 1)<1>|dst<var>|dst_len<1>
        uint256 t0 = message.length;
        bytes memory msg0 = new bytes(32 + t0 + 64 + 4);
        bytes memory out = new bytes(96);
        // b0
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let p := add(msg0, 96)
            for {
                let z := 0
            } lt(z, t0) {
                z := add(z, 32)
            } {
                mstore(add(p, z), mload(add(message, add(z, 32))))
            }
            p := add(p, t0)

            mstore8(p, 0)
            p := add(p, 1)
            mstore8(p, 96)
            p := add(p, 1)
            mstore8(p, 0)
            p := add(p, 1)

            mstore(p, domain)
            p := add(p, 32)
            mstore8(p, 32)
        }
        bytes32 b0 = sha256(msg0);
        bytes32 bi;
        t0 = 32 + 34;

        // resize intermediate message
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(msg0, t0)
        }

        // b1

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(add(msg0, 32), b0)
            mstore8(add(msg0, 64), 1)
            mstore(add(msg0, 65), domain)
            mstore8(add(msg0, add(32, 65)), 32)
        }

        bi = sha256(msg0);

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(add(out, 32), bi)
        }

        // b2

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let t := xor(b0, bi)
            mstore(add(msg0, 32), t)
            mstore8(add(msg0, 64), 2)
            mstore(add(msg0, 65), domain)
            mstore8(add(msg0, add(32, 65)), 32)
        }

        bi = sha256(msg0);

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(add(out, 64), bi)
        }

        // b3

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let t := xor(b0, bi)
            mstore(add(msg0, 32), t)
            mstore8(add(msg0, 64), 3)
            mstore(add(msg0, 65), domain)
            mstore8(add(msg0, add(32, 65)), 32)
        }

        bi = sha256(msg0);

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(add(out, 96), bi)
        }

        return out;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

/**
    @title Compute Inverse by Modular Exponentiation
    @notice Compute $input^(N - 2) mod N$ using Addition Chain method.
    Where     N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
    and   N - 2 = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd45
    @dev the function body is generated with the modified addchain script
    see https://github.com/kobigurk/addchain/commit/2c37a2ace567a9bdc680b4e929c94aaaa3ec700f
 */
library ModexpInverse {
    function run(uint256 t2) internal pure returns (uint256 t0) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let
                n
            := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
            t0 := mulmod(t2, t2, n)
            let t5 := mulmod(t0, t2, n)
            let t1 := mulmod(t5, t0, n)
            let t3 := mulmod(t5, t5, n)
            let t8 := mulmod(t1, t0, n)
            let t4 := mulmod(t3, t5, n)
            let t6 := mulmod(t3, t1, n)
            t0 := mulmod(t3, t3, n)
            let t7 := mulmod(t8, t3, n)
            t3 := mulmod(t4, t3, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t7, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t7, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t4, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t7, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t3, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t3, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t4, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t3, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
        }
    }
}

/**
    @title Compute Squre Root by Modular Exponentiation
    @notice Compute $input^{(N + 1) / 4} mod N$ using Addition Chain method.
    Where           N = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47
    and   (N + 1) / 4 = 0xc19139cb84c680a6e14116da060561765e05aa45a1c72a34f082305b61f3f52
 */
library ModexpSqrt {
    function run(uint256 t6) internal pure returns (uint256 t0) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let
                n
            := 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47

            t0 := mulmod(t6, t6, n)
            let t4 := mulmod(t0, t6, n)
            let t2 := mulmod(t4, t0, n)
            let t3 := mulmod(t4, t4, n)
            let t8 := mulmod(t2, t0, n)
            let t1 := mulmod(t3, t4, n)
            let t5 := mulmod(t3, t2, n)
            t0 := mulmod(t3, t3, n)
            let t7 := mulmod(t8, t3, n)
            t3 := mulmod(t1, t3, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t4, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t4, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t7, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t4, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t7, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t4, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t4, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t8, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t7, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t3, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t6, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t4, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t5, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t4, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t4, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t3, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t3, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t2, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t0, n)
            t0 := mulmod(t0, t1, n)
            t0 := mulmod(t0, t0, n)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

contract BNPairingPrecompileCostEstimator {
    uint256 public baseCost;
    uint256 public perPairCost;

    // G1 Generator
    uint256 private constant G1_X = 1;
    uint256 private constant G1_Y = 2;

    // G2 genarator
    // prettier-ignore
    uint256 private constant G2_X0 = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    // prettier-ignore
    uint256 private constant G2_X1 = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    // prettier-ignore
    uint256 private constant G2_Y0 = 8495653923123431417604973247489272438418190587263600148770280649306958101930;
    // prettier-ignore
    uint256 private constant G2_Y1 = 4082367875863433681332203403145435568316851327593401208105741076214120093531;

    // G2 negated genarator y coordinates
    // prettier-ignore
    uint256 private constant N_G2_Y0 = 13392588948715843804641432497768002650278120570034223513918757245338268106653;
    // prettier-ignore
    uint256 private constant N_G2_Y1 = 17805874995975841540914202342111839520379459829704422454583296818431106115052;

    function run() external {
        _run();
    }

    function getGasCost(uint256 pairCount) external view returns (uint256) {
        return pairCount * perPairCost + baseCost;
    }

    function _run() internal {
        uint256 gasCost1Pair = _gasCost1Pair();
        uint256 gasCost2Pair = _gasCost2Pair();
        perPairCost = gasCost2Pair - gasCost1Pair;
        baseCost = gasCost1Pair - perPairCost;
    }

    function _gasCost1Pair() internal view returns (uint256) {
        uint256[6] memory input = [G1_X, G1_Y, G2_X1, G2_X0, G2_Y1, G2_Y0];
        uint256[1] memory out;
        bool callSuccess;
        uint256 suppliedGas = gasleft() - 2000;
        require(
            gasleft() > 2000,
            "BNPairingPrecompileCostEstimator: not enough gas, single pair"
        );
        uint256 gasT0 = gasleft();
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            callSuccess := staticcall(suppliedGas, 8, input, 192, out, 0x20)
        }
        uint256 gasCost = gasT0 - gasleft();
        require(
            callSuccess,
            "BNPairingPrecompileCostEstimator: single pair call is failed"
        );
        require(
            out[0] == 0,
            "BNPairingPrecompileCostEstimator: single pair call result must be 0"
        );
        return gasCost;
    }

    function _gasCost2Pair() internal view returns (uint256) {
        uint256[12] memory input = [
            G1_X,
            G1_Y,
            G2_X1,
            G2_X0,
            G2_Y1,
            G2_Y0,
            G1_X,
            G1_Y,
            G2_X1,
            G2_X0,
            N_G2_Y1,
            N_G2_Y0
        ];
        uint256[1] memory out;
        bool callSuccess;
        uint256 suppliedGas = gasleft() - 2000;
        require(
            gasleft() > 2000,
            "BNPairingPrecompileCostEstimator: not enough gas, couple pair"
        );
        uint256 gasT0 = gasleft();
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            callSuccess := staticcall(suppliedGas, 8, input, 384, out, 0x20)
        }
        uint256 gasCost = gasT0 - gasleft();
        require(
            callSuccess,
            "BNPairingPrecompileCostEstimator: couple pair call is failed"
        );
        require(
            out[0] == 1,
            "BNPairingPrecompileCostEstimator: couple pair call result must be 1"
        );
        return gasCost;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";
import "./IAccount.sol";
import "./IAggregator.sol";

/**
 * Aggregated account, that support IAggregator.
 * - the validateUserOp will be called only after the aggregator validated this account (with all other accounts of this aggregator).
 * - the validateUserOp MUST valiate the aggregator parameter, and MAY ignore the userOp.signature field.
 */
interface IAggregatedAccount is IAccount {
    /**
     * return the address of the signature aggregator the account supports.
     */
    function getAggregator() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

import "./UserOperation.sol";

interface IAccount {
    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp the operation that is about to be executed.
     * @param userOpHash hash of the user's request data. can be used as the basis for signature.
     * @param aggregator the aggregator used to validate the signature. NULL for non-aggregated signature accounts.
     * @param missingAccountFunds missing funds on the account's deposit in the entrypoint.
     *      This is the minimum amount to transfer to the sender(entryPoint) to be able to make the call.
     *      The excess is left as a deposit in the entrypoint, for future calls.
     *      can be withdrawn anytime using "entryPoint.withdrawTo()"
     *      In case there is a paymaster in the request (or the current deposit is high enough), this value will be zero.
     * @return deadline the last block timestamp this operation is valid, or zero if it is valid indefinitely.
     *      Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        address aggregator,
        uint256 missingAccountFunds
    ) external returns (uint256 deadline);
}