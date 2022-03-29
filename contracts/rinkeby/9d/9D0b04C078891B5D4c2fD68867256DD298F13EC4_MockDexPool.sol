// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../Bridge.sol";
import "../../amm_pool/SolanaSerialize.sol";

/**
 * @notice This is for test purpose.
 *
 * @dev Short life cycle
 * @dev POOL_1#sendRequestTest --> {logic bridge} --> POOL_2#setPendingRequestsDone
 */
contract MockDexPool is SolanaSerialize {
    bytes8 private SET_VALUE_SIGHASH = sigHash("global:set_value");
    string constant private SET_REQUEST_TYPE = "setRequest";
    uint256 public testData = 0;
    address public bridge;
    mapping(bytes32 => uint256) public requests;
    bytes32[] public doubleRequestIds;
    uint256 public totalRequests = 0;

    event RequestSent(bytes32 reqId);
    event RequestReceived(uint256 data);
    event RequestReceivedV2(bytes32 reqId, uint256 data);

    constructor(address _bridge) {
        bridge = _bridge;
    }

    /**
     * @notice send request like second part of pool
     *
     * @dev LIFE CYCLE
     * @dev ${this pool} -> POOL_2
     * @dev ${this func} ->  bridge#transmitRequest -> node -> adpater#receiveRequest -> mockDexPool_2#receiveRequestTest -> bridge#transmitResponse(reqId) -> node -> adpater#receiveResponse -> mockDexPool_1#setPendingRequestsDone
     *
     */
    function sendRequestTestV2(uint256 testData_, address secondPartPool, address oppBridge, uint chainId) external {
        require(secondPartPool != address(0), "BAD ADDRESS");
        // todo some stuff on this part pool
        // ...

        uint256 nonce = Bridge(bridge).getNonce(msg.sender);
        bytes32 requestId = Bridge(bridge).prepareRqId(
            bytes32(uint256(uint160(oppBridge))),
            chainId,
            bytes32(uint256(uint160(secondPartPool))),
            bytes32(uint256(uint160(msg.sender))),
            nonce
        );
        bytes memory output = abi.encodeWithSelector(
            bytes4(keccak256(bytes('receiveRequestTest(uint256,bytes32)'))),
            testData_,
            requestId
        );
        Bridge(bridge).transmitRequestV2(
            output, secondPartPool, oppBridge, chainId, requestId, msg.sender, nonce);

        emit RequestSent(requestId);
    }

    /**
     * @notice receive request on the second part of pool
     *
     * @dev LIFE CYCLE
     * @dev POOL_1 -> ${this pool}
     * @dev mockDexPool_1#sendRequestTest -> bridge#transmitRequest -> node -> adpater#receiveRequest -> ${this func} -> bridge#transmitResponse(reqId) -> node -> adpater#receiveResponse -> mockDexPool_1#setPendingRequestsDone
     */
    function receiveRequestTest(uint256 _testData, bytes32 _reqId) public {
        require(msg.sender == bridge, "ONLY CERTAIN BRIDGE");

        if (requests[_reqId] != 0) {
            doubleRequestIds.push(_reqId);
        }
        requests[_reqId]++;
        totalRequests++;

        testData = _testData;
        emit RequestReceived(_testData);
        emit RequestReceivedV2(_reqId, _testData);
    }

    function sendTestRequestToSolana(bytes32 testStubPID_, bytes32 solBridgePID_, bytes32 dataAcc_, bytes32 bridgePDASigner_, uint256 testData_, uint chainId) external {
        testData_; // silence warning

        require(chainId == SOLANA_CHAIN_ID, "incorrect chainID");
        uint256 nonce = Bridge(bridge).getNonce(msg.sender);

        bytes32 requestId = Bridge(bridge).prepareRqId( testStubPID_, chainId, dataAcc_, bytes32(uint256(uint160(msg.sender))) , nonce);
//                        bool success = Bridge(bridge).transmitSolanaRequest(out, secondPartPool, oppBridge, chainId, requestId, msg.sender, nonce);
        SolanaAccountMeta[] memory accounts = new SolanaAccountMeta[](2);

        accounts[0] = SolanaAccountMeta({
        pubkey: dataAcc_,
        isSigner: false,
        isWritable: true
        });

        accounts[1] = SolanaAccountMeta({
        pubkey: bridgePDASigner_,
        isSigner: true,
        isWritable: true
        });

        Bridge(bridge).transmitRequestV2ToSolana(
            serializeSolanaStandaloneInstruction(
                SolanaStandaloneInstruction(
                /* programId: */
                    testStubPID_,
                /* accounts: */
                    accounts,
                /* data: */
                    abi.encodePacked(SET_VALUE_SIGHASH, testData_)
                )
            ),
                testStubPID_,
                solBridgePID_,
            SOLANA_CHAIN_ID,
            requestId,
            msg.sender,
            nonce
        );

        emit RequestSent(requestId);
    }

    function sigHash(string memory _data) public pure returns (bytes8) {
        return bytes8(sha256(bytes(_data)));
    }

    function doubles() public view returns(bytes32[] memory) {
        return doubleRequestIds;
    }

    function doubleRequestError() public view returns(uint256) {
        return doubleRequestIds.length;
    }

    function clearStats() public {
        delete doubleRequestIds;
        totalRequests = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-newone/utils/Address.sol";
import "@openzeppelin/contracts-newone/utils/cryptography/ECDSA.sol";

import "../amm_pool/RelayRecipient.sol";
import "../utils/Block.sol";
import "../utils/Merkle.sol";
import "../utils/ReqIdFilter.sol";
import "../utils/Typecast.sol";
import "./bls/BlsSignatureVerification.sol";
import "./core/BridgeCore.sol";
import "./interface/INodeRegistry.sol";

contract Bridge is BridgeCore, RelayRecipient, BlsSignatureVerification, Typecast {
    using AddressUpgradeable for address;
    using ReqIdFilter for ReqIdFilter.Data;

    string public versionRecipient;
    E2Point private epochKey; // Aggregated public key of all paricipants of the current epoch
    address public dao; // Address of the DAO
    uint8 public epochParticipantsNum; // Number of participants contributed to the epochKey
    uint32 public epochNum; // Sequential number of the epoch

    ReqIdFilter.Data private reqIdFilter; // Filteres request ID against repetition

    event NewEpoch(bytes oldEpochKey, bytes newEpochKey, bool requested, uint32 epochNum);

    //event OwnershipTransferred(address indexed previousDao, address indexed newDao);

    function initialize(address forwarder) public initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();

        versionRecipient = "2.2.3";
        dao = _msgSender();
        _setTrustedForwarder(forwarder);
    }

    modifier onlyTrustedContract(address receiveSide, address oppositeBridge) {
        require(
            contractBind[castToBytes32(address(_msgSender()))][castToBytes32(oppositeBridge)][
                castToBytes32(receiveSide)
            ] == true,
            "Bridge: untrusted contract"
        );
        _;
    }

    modifier onlyTrustedContractBytes32(bytes32 receiveSide, bytes32 oppositeBridge) {
        require(
            contractBind[castToBytes32(address(_msgSender()))][oppositeBridge][receiveSide] == true,
            "Bridge: untrusted contract"
        );
        _;
    }

    modifier onlyDao() {
        require(_msgSender() == dao, "Bridge: only DAO");
        _;
    }

    function getEpoch()
        public
        view
        returns (
            bytes memory,
            uint8,
            uint32
        )
    {
        return (abi.encode(epochKey), epochParticipantsNum, epochNum);
    }

    function statFilterLen() external view returns (uint256) {
        return reqIdFilter.length();
    }

    /**
     * @dev Updates current epoch.
     * @param _newKey aggregated public key of all new epoch participants
     * @param _votersPubKey aggregated public key of the old epoch participants, who voted for the update
     * @param _votersSignature aggregated signature of the old epoch participants, who voted for the update
     * @param _votersMask bitmask of old epoch participants, who voted, amoung all participants
     * @param _newEpochParticipantsNum number of the participants
     */
    function updateEpoch(
        bytes calldata _newKey,
        bytes calldata _votersPubKey,
        bytes calldata _votersSignature,
        uint256 _votersMask,
        uint8 _newEpochParticipantsNum,
        uint32 _newEpochNum
    ) external {
        require(epochNum + 1 == _newEpochNum, "Bridge: wrong epoch number");

        E2Point memory newKey = decodeE2Point(_newKey);
        E2Point memory votersPubKey = decodeE2Point(_votersPubKey);
        E1Point memory votersSignature = decodeE1Point(_votersSignature);

        if (epochKey.x[0] != 0 || epochKey.x[1] != 0) {
            require(popcnt(_votersMask) >= (uint256(epochParticipantsNum) * 2) / 3, "Bridge: not enough participants"); // TODO configure
            require(
                epochParticipantsNum == 255 || _votersMask < (1 << epochParticipantsNum),
                "Bridge: bitmask too big"
            );
            bytes memory data = abi.encodePacked(newKey.x, newKey.y, _newEpochParticipantsNum, _newEpochNum);
            require(
                verifyMultisig(epochKey, votersPubKey, data, votersSignature, _votersMask),
                "Bridge: multisig mismatch"
            );
        }

        emit NewEpoch(abi.encode(epochKey), abi.encode(newKey), false, _newEpochNum);
        epochKey = newKey;
        epochParticipantsNum = _newEpochParticipantsNum; // TODO: require minimum
        epochNum = _newEpochNum;
        reqIdFilter.clear();
    }

    /**
     * @dev Transmit crosschain request v2.
     * @param _selector call data
     * @param receiveSide receive contract address
     * @param oppositeBridge opposite bridge address
     * @param chainId opposite chain ID
     * @param requestId request ID
     * @param sender sender's address
     * @param nonce sender's nonce
     */
    function transmitRequestV2(
        bytes calldata _selector,
        address receiveSide,
        address oppositeBridge,
        uint256 chainId,
        bytes32 requestId,
        address sender,
        uint256 nonce
    ) external onlyTrustedContract(receiveSide, oppositeBridge) returns (bool) {
        verifyAndUpdateNonce(sender, nonce);
        emit OracleRequest("setRequest", address(this), requestId, _selector, receiveSide, oppositeBridge, chainId);
        return true;
    }

    /**
     * @dev Transmit crosschain request v2 with bytes32 to Solana.
     * @param _selector call data
     * @param receiveSide receive contract address
     * @param oppositeBridge opposite bridge address
     * @param chainId opposite chain ID
     * @param requestId request ID
     * @param sender sender's address
     * @param nonce sender's nonce
     */
    function transmitRequestV2ToSolana(
        bytes calldata _selector,
        bytes32 receiveSide,
        bytes32 oppositeBridge,
        uint256 chainId,
        bytes32 requestId,
        address sender,
        uint256 nonce
    ) external onlyTrustedContractBytes32(receiveSide, oppositeBridge) returns (bool) {
        verifyAndUpdateNonce(sender, nonce);
        emit OracleRequestSolana(
            "setRequest",
            castToBytes32(address(this)),
            requestId,
            _selector,
            oppositeBridge,
            chainId
        );
        return true;
    }

    /**
     * @dev Receive crosschain request v2.
     * @param _blockHeader block header serialization
     * @param _txMerkleProve OracleRequest transaction payload and its Merkle audit path
     * @param _votersPubKey aggregated public key of the old epoch participants, who voted for the block
     * @param _votersSignature aggregated signature of the old epoch participants, who voted for the block
     * @param _votersMask bitmask of epoch participants, who voted, amoung all participants
     */
    function receiveRequestV2(
        bytes calldata _blockHeader,
        bytes calldata _txMerkleProve,
        bytes calldata _votersPubKey,
        bytes calldata _votersSignature,
        uint256 _votersMask
    ) external {
        require(epochKey.x[0] != 0 || epochKey.x[1] != 0, "Bridge: epoch not set");
        require(popcnt(_votersMask) >= (uint256(epochParticipantsNum) * 2) / 3, "Bridge: not enough participants"); // TODO configure
        require(epochParticipantsNum == 255 || _votersMask < (1 << epochParticipantsNum), "Bridge: bitmask too big");

        // Verify the block signature
        E2Point memory votersPubKey = decodeE2Point(_votersPubKey);
        E1Point memory votersSignature = decodeE1Point(_votersSignature);
        require(
            verifyMultisig(epochKey, votersPubKey, _blockHeader, votersSignature, _votersMask),
            "Bridge: multisig mismatch"
        );

        // Verify that the transaction is really in the block
        bytes memory payload = Merkle.prove(_txMerkleProve, Block.transactionsRoot(_blockHeader));

        // Make the call
        (address bridgeFrom, bytes32 reqId, bytes memory sel, address receiveSide) = Block.oracleRequestTx(payload);
        require(reqIdFilter.testAndSet(reqId) == false, "Already seen");
        bytes memory data = receiveSide.functionCall(sel, "Bridge: receiveRequestV2: failed");
        require(
            data.length == 0 || abi.decode(data, (bool)),
            "Bridge: receiveRequestV2: unable to decode returned data"
        );
        emit ReceiveRequest(reqId, receiveSide, bytes32(bytes20(bridgeFrom)));
    }

    /**
     * @dev Request updating epoch. Only DAO may call it.
     * @param resetEpoch true to reset the epoch to zero so anyone can set up a new one, without any check,
     *                   false to request the change from the current one, so current participants must
     *                   successfully vote for it
     */
    function daoUpdateEpochRequest(bool resetEpoch) public virtual onlyDao {
        bytes memory epochKeyBytes = abi.encode(epochKey);
        if (resetEpoch) {
            epochNum++;
            E2Point memory zero;
            emit NewEpoch(epochKeyBytes, abi.encode(zero), true, epochNum);
            epochKey = zero;
        } else {
            emit NewEpoch(epochKeyBytes, epochKeyBytes, true, epochNum);
        }
    }

    /**
     * @dev Transfer DAO to another address.
     */
    function daoTransferOwnership(address newDao) external {
        require(dao == address(0) || _msgSender() == dao, "Bridge: only DAO");
        emit OwnershipTransferred(dao, newDao);
        dao = newDao;
    }

    function decodeE2Point(bytes memory _pubKey) private pure returns (E2Point memory pubKey) {
        uint256[] memory output = new uint256[](4);
        for (uint256 i = 32; i <= output.length * 32; i += 32) {
            assembly {
                mstore(add(output, i), mload(add(_pubKey, i)))
            }
        }

        pubKey.x[0] = output[0];
        pubKey.x[1] = output[1];
        pubKey.y[0] = output[2];
        pubKey.y[1] = output[3];
    }

    function decodeE1Point(bytes memory _sig) private pure returns (E1Point memory signature) {
        uint256[] memory output = new uint256[](2);
        for (uint256 i = 32; i <= output.length * 32; i += 32) {
            assembly {
                mstore(add(output, i), mload(add(_sig, i)))
            }
        }

        signature.x = output[0];
        signature.y = output[1];
    }

    function popcnt(uint256 mask) private pure returns (uint256 cnt) {
        while (mask != 0) {
            mask = mask & (mask - 1);
            cnt++;
        }
    }

    function setTrustedForwarder(address _forwarder) external onlyOwner {
        return _setTrustedForwarder(_forwarder);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract SolanaSerialize {
    // Solana constants
    uint256 public constant SOLANA_CHAIN_ID = 501501501;
    // base58: TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA
    bytes32 public constant SOLANA_TOKEN_PROGRAM = 0x06ddf6e1d765a193d9cbe146ceeb79ac1cb485ed5f5b37913a8cf5857eff00a9;
    // base58: 11111111111111111111111111111111
    bytes32 public constant SOLANA_SYSTEM_PROGRAM = 0x0;
    // base58: SysvarRent111111111111111111111111111111111
    bytes32 public constant SOLANA_RENT = 0x06a7d517192c5c51218cc94c3d4af17f58daee089ba1fd44e3dbd98a00000000;

    struct SolanaAccountMeta {
        bytes32 pubkey;
        bool isSigner;
        bool isWritable;
    }

    struct SolanaStandaloneInstruction {
        bytes32 programId;
        SolanaAccountMeta[] accounts;
        bytes data;
    }

    function serializeSolanaStandaloneInstruction(SolanaStandaloneInstruction memory ix)
        public
        pure
        returns (
            bytes memory /* data */
        )
    {
        uint32 _len = uint32(ix.accounts.length);
        // swap bytes
        _len = ((_len & 0xFF00FF00) >> 8) | ((_len & 0x00FF00FF) << 8);
        // swap 2-byte long pairs
        _len = (_len >> 16) | (_len << 16);

        bytes memory _data = abi.encodePacked(_len);
        bytes memory _d;
        for (uint256 i = 0; i < ix.accounts.length; i++) {
            _d = abi.encodePacked(ix.accounts[i].pubkey, ix.accounts[i].isSigner, ix.accounts[i].isWritable);
            _data = abi.encodePacked(_data, _d);
        }

        _data = abi.encodePacked(_data, ix.programId);

        _len = uint32(ix.data.length);
        // swap bytes
        _len = ((_len & 0xFF00FF00) >> 8) | ((_len & 0x00FF00FF) << 8);
        // swap 2-byte long pairs
        _len = (_len >> 16) | (_len << 16);

        _data = abi.encodePacked(_data, _len);
        _data = abi.encodePacked(_data, ix.data);

        return (_data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
        } else if (signature.length == 64) {
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let vs := mload(add(signature, 0x40))
                r := mload(add(signature, 0x20))
                s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
                v := add(shr(255, vs), 27)
            }
        } else {
            revert("ECDSA: invalid signature length");
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract RelayRecipient is ContextUpgradeable, OwnableUpgradeable {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../utils/ZeroCopySource.sol";
import "../utils/Utils.sol";

library Block {
    function transactionsRoot(bytes calldata _payload) internal pure returns (bytes32 txRootHash) {
        txRootHash = Utils.bytesToBytes32(_payload[72:104]);
    }

    function oracleRequestTx(bytes memory _payload) internal pure returns (address bridgeFrom, bytes32 reqId, bytes memory sel, address receiveSide) {
        uint256 off = 0;
        (bridgeFrom, off) = ZeroCopySource.NextAddress(_payload, off);
        (reqId, off) = ZeroCopySource.NextHash(_payload, off);
        (sel, off) = ZeroCopySource.NextVarBytes(_payload, off);
        (receiveSide, off) = ZeroCopySource.NextAddress(_payload, off);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ZeroCopySource.sol";

library Merkle {

    /* @notice          Do hash leaf as the multi-chain does
    *  @param _data     Data in bytes format
    *  @return          Hashed value in bytes32 format
    */
    function hashLeaf(bytes memory _data) internal pure returns (bytes32 result)  {
        result = sha256(abi.encodePacked(uint8(0x0), _data));
    }

    /* @notice          Do hash children as the multi-chain does
    *  @param _l        Left node
    *  @param _r        Right node
    *  @return          Hashed value in bytes32 format
    */
    function hashChildren(bytes32 _l, bytes32  _r) internal pure returns (bytes32 result)  {
        result = sha256(abi.encodePacked(bytes1(0x01), _l, _r));
    }

    /* @notice                  Verify merkle proove
    *  @param _auditPath        Merkle path
    *  @param _root             Merkle tree root
    *  @return                  The verified value included in _auditPath
    */
    function prove(bytes memory _auditPath, bytes32 _root) internal pure returns (bytes memory) {
        uint256 off = 0;
        bytes memory value;
        (value, off) = ZeroCopySource.NextVarBytes(_auditPath, off);

        bytes32 hash = hashLeaf(value);
        uint size = (_auditPath.length - off) / 33;
        bytes32 nodeHash;
        uint8 pos;
        for (uint i = 0; i < size; i++) {
            (pos, off) = ZeroCopySource.NextUint8(_auditPath, off);
            (nodeHash, off) = ZeroCopySource.NextHash(_auditPath, off);
            if (pos == 0x00) {
                hash = hashChildren(nodeHash, hash);
            } else if (pos == 0x01) {
                hash = hashChildren(hash, nodeHash);
            } else {
                revert("merkleProve eod");
            }
        }
        require(hash == _root, "merkleProve root");
        return value;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library ReqIdFilter {
    struct Data {
        mapping(bytes32 => bool) filter;
        bytes32[] used;
    }

    function length(Data storage data) internal view returns(uint256) {
        return data.used.length;
    }

    function testAndSet(Data storage data, bytes32 id) internal returns(bool) {
        if (data.filter[id]) return true;
        data.filter[id] = true;
        data.used.push(id);
        return false;
    }

    function clear(Data storage data) internal {
        for (uint256 i = 0; i < data.used.length; i++) data.filter[data.used[i]] = false;
        delete data.used;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract Typecast {
    function castToAddress(bytes32 x) public pure returns (address) {
        return address(uint160(uint256(x)));
    }

    function castToBytes32(address a) public pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./ModUtils.sol";

/**
 * Verify BLS Threshold Signed values.
 *
 * Much of the code in this file is derived from here:
 * https://github.com/ConsenSys/gpact/blob/main/common/common/src/main/solidity/BlsSignatureVerification.sol
 */
contract BlsSignatureVerification {
    using ModUtils for uint256;

    struct E1Point {
        uint x;
        uint y;
    }

    // Note that the ordering of the elements in each array needs to be the reverse of what you would
    // normally have, to match the ordering expected by the precompile.
    struct E2Point {
        uint[2] x;
        uint[2] y;
    }

    // p is a prime over which we form a basic field
    // Taken from go-ethereum/crypto/bn256/cloudflare/constants.go
    uint256 constant p = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    /**
     * Checks if BLS signature is valid.
     *
     * @param _publicKey Public verification key associated with the secret key that signed the message.
     * @param _message Message that was signed as a bytes array.
     * @param _signature Signature over the message.
     * @return True if the message was correctly signed.
     */
    function verify(
        E2Point memory _publicKey,
        bytes memory _message,
        E1Point memory _signature
    ) internal view returns (bool) {
        return verifyForPoint(_publicKey, hashToCurveE1(_message), _signature);
    }

    /**
     * Checks if BLS signature is valid for a message represented as a curve point.
     *
     * @param _publicKey Public verification key associated with the secret key that signed the message.
     * @param _message Message that was signed as a point on curve E1.
     * @param _signature Signature over the message.
     * @return True if the message was correctly signed.
     */
    function verifyForPoint(
        E2Point memory _publicKey,
        E1Point memory _message,
        E1Point memory _signature
    ) internal view returns (bool) {
        E1Point[] memory e1points = new E1Point[](2);
        E2Point[] memory e2points = new E2Point[](2);
        e1points[0] = negate(_signature);
        e1points[1] = _message;
        e2points[0] = G2();
        e2points[1] = _publicKey;
        return pairing(e1points, e2points);
    }

    /**
     * Checks if BLS multisignature is valid.
     *
     * @param _aggregatedPublicKey Sum of all public keys
     * @param _partPublicKey Sum of participated public keys
     * @param _message Message that was signed
     * @param _partSignature Signature over the message
     * @param _signersBitmask Bitmask of participants in this signature
     * @return True if the message was correctly signed by the given participants.
     */
    function verifyMultisig(
        E2Point memory _aggregatedPublicKey,
        E2Point memory _partPublicKey,
        bytes memory _message,
        E1Point memory _partSignature,
        uint _signersBitmask
    ) internal view returns (bool) {
        E1Point memory sum = E1Point(0, 0);
        uint index = 0;
        uint mask = 1;
        while (_signersBitmask != 0) {
            if (_signersBitmask & mask != 0) {
                _signersBitmask -= mask;
                sum = addCurveE1(sum, hashToCurveE1(abi.encodePacked(_aggregatedPublicKey.x, _aggregatedPublicKey.y, index)));
            }
            mask <<= 1;
            index ++;
        }

        E1Point[] memory e1points = new E1Point[](3);
        E2Point[] memory e2points = new E2Point[](3);
        e1points[0] = negate(_partSignature);
        e1points[1] = hashToCurveE1(abi.encodePacked(_aggregatedPublicKey.x, _aggregatedPublicKey.y, _message));
        e1points[2] = sum;
        e2points[0] = G2();
        e2points[1] = _partPublicKey;
        e2points[2] = _aggregatedPublicKey;
        return pairing(e1points, e2points);
    }

    /**
     * @return The generator of E1.
     */
    function G1() private pure returns (E1Point memory) {
        return E1Point(1, 2);
    }

    /**
     * @return The generator of E2.
     */
    function G2() private pure returns (E2Point memory) {
        return E2Point({
            x: [
                11559732032986387107991004021392285783925812861821192530917403151452391805634,
                10857046999023057135944570762232829481370756359578518086990519993285655852781
            ],
            y: [
                 4082367875863433681332203403145435568316851327593401208105741076214120093531,
                 8495653923123431417604973247489272438418190587263600148770280649306958101930
            ]
          });
    }



    /**
     * Negate a point: Assuming the point isn't at infinity, the negation is same x value with -y.
     *
     * @dev Negates a point in E1.
     * @param _point Point to negate.
     * @return The negated point.
     */
    function negate(E1Point memory _point) private pure returns (E1Point memory) {
        if (isAtInfinity(_point)) {
            return E1Point(0, 0);
        }
        return E1Point(_point.x, p - (_point.y % p));
    }

    /**
     * Computes the pairing check e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *
     * @param _e1points List of points in E1.
     * @param _e2points List of points in E2.
     * @return True if pairing check succeeds.
     */
    function pairing(E1Point[] memory _e1points, E2Point[] memory _e2points) private view returns (bool) {
        require(_e1points.length == _e2points.length, "Point count mismatch.");

        uint elements = _e1points.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);

        for (uint i = 0; i < elements; i++) {
            input[i * 6 + 0] = _e1points[i].x;
            input[i * 6 + 1] = _e1points[i].y;
            input[i * 6 + 2] = _e2points[i].x[0];
            input[i * 6 + 3] = _e2points[i].x[1];
            input[i * 6 + 4] = _e2points[i].y[0];
            input[i * 6 + 5] = _e2points[i].y[1];
        }

        uint[1] memory out;
        bool success;
        assembly {
            // Start at memory offset 0x20 rather than 0 as input is a variable length array.
            // Location 0 is the length field.
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
        // The pairing operation will fail if the input data isn't the correct size (this won't happen
        // given the code above), or if one of the points isn't on the curve.
        require(success, "Pairing operation failed.");
        return out[0] != 0;
    }

    /**
     * Multiplies a point in E1 by a scalar.
     * @param _point E1 point to multiply.
     * @param _scalar Scalar to multiply.
     * @return The resulting E1 point.
     */
    function curveMul(E1Point memory _point, uint _scalar) private view returns (E1Point memory) {
        uint[3] memory input;
        input[0] = _point.x;
        input[1] = _point.y;
        input[2] = _scalar;

        bool success;
        E1Point memory result;
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x60, result, 0x40)
        }
        require(success, "Point multiplication failed.");
        return result;
    }

    /**
     * Check to see if the point is the point at infinity.
     *
     * @param _point a point on E1.
     * @return true if the point is the point at infinity.
     */
    function isAtInfinity(E1Point memory _point) private pure returns (bool){
        return (_point.x == 0 && _point.y == 0);
    }

    /**
     * @dev Hash a byte array message, m, and map it deterministically to a
     * point on G1. Note that this approach was chosen for its simplicity /
     * lower gas cost on the EVM, rather than good distribution of points on
     * G1.
     */
    function hashToCurveE1(bytes memory m)
        internal
        view returns(E1Point memory)
    {
        bytes32 h = sha256(m);
        uint256 x = uint256(h) % p;
        uint256 y;

        while (true) {
            y = YFromX(x);
            if (y > 0) {
                return E1Point(x, y);
            }
            x += 1;
        }
        revert("hashToCurveE1: unreachable end point");
    }

    /**
     * @dev g1YFromX computes a Y value for a G1 point based on an X value.
     * This computation is simply evaluating the curve equation for Y on a
     * given X, and allows a point on the curve to be represented by just
     * an X value + a sign bit.
     */
    function YFromX(uint256 x)
        internal
        view returns(uint256)
    {
        return ((x.modExp(3, p) + 3) % p).modSqrt(p);
    }


    /// @dev return the sum of two points of G1
    function addCurveE1(E1Point memory _p1, E1Point memory _p2) internal view returns (E1Point memory res) {
        uint[4] memory input;
        input[0] = _p1.x;
        input[1] = _p1.y;
        input[2] = _p2.x;
        input[3] = _p2.y;
        bool success;
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0x80, res, 0x40)
        }
        require(success, "Add points failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract BridgeCore {
    address public _listNode;

    mapping(address => uint256) internal nonces;
    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => bool))) internal contractBind;
    mapping(bytes32 => bool) private is_in;

    event OracleRequest(
        string requestType,
        address bridge,
        bytes32 requestId,
        bytes selector,
        address receiveSide,
        address oppositeBridge,
        uint256 chainid
    );

    event OracleRequestSolana(
        string requestType,
        bytes32 bridge,
        bytes32 requestId,
        bytes selector,
        bytes32 oppositeBridge,
        uint256 chainid
    );

    event ReceiveRequest(bytes32 reqId, address receiveSide, bytes32 bridgeFrom);

    /**
     * @dev Mandatory for all participants who wants to use their own contracts
     * 1. Contract A (chain A) should be binded with Contract B (chain B) only once! It's not allowed to switch Contract A (chain A) to Contract C (chain B).
     * to prevent malicious behaviour.
     * 2. Contract A (chain A) could be binded with several contracts where every contract from another chain.
     * For ex: Contract A (chain A) --> Contract B (chain B) + Contract A (chain A) --> Contract B' (chain B') ... etc
     * @param from padded sender's address
     * @param oppositeBridge padded opposite bridge address
     * @param to padded recipient address
     */
    function addContractBind(
        bytes32 from,
        bytes32 oppositeBridge,
        bytes32 to
    ) external virtual /**  onlyOwner*/
    {
        require(to != "", "Bridge: invalid 'to' address");
        require(from != "", "Bridge: invalid 'from' address");
        // TODO
        // to prevent malicious behaviour like switching between older and newer contracts (need to use DAO/Owner for this!)
        contractBind[from][oppositeBridge][to] = true;
    }

    /**
     * @dev Prepares a request ID with the given arguments.
     * @param oppositeBridge padded opposite bridge address
     * @param chainId opposite chain ID
     * @param receiveSide padded receive contract address
     * @param from padded sender's address
     * @param nonce current nonce
     */
    function prepareRqId(
        bytes32 oppositeBridge,
        uint256 chainId,
        bytes32 receiveSide,
        bytes32 from,
        uint256 nonce
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(from, nonce, chainId, block.chainid, receiveSide, oppositeBridge));
    }

    /**
     * @dev Get the nonce of the current sender.
     * @param from sender's address
     */
    function getNonce(address from) public view returns (uint256) {
        return nonces[from];
    }

    /**
     * @dev Verifies and updates the sender's nonce.
     * @param from sender's address
     * @param nonce provided sender's nonce
     */
    function verifyAndUpdateNonce(address from, uint256 nonce) internal {
        require(nonces[from]++ == nonce, "Bridge: nonce mismatch");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IRelayerPool.sol";

interface INodeRegistry {
    struct Node {
        address owner;
        address pool;
        address nodeIdAddress;
        string  blsPubKey;
        uint256 nodeId;
    }

    function addNode(Node memory node) external;

    function getNode(address _nodeIdAddress) external view returns (Node memory);

    function getNodes() external view returns (Node[] memory);

    function getBLSPubKeys() external view returns (string[] memory);

    function convertToString(address account) external pure returns (string memory s);

    function nodeExists(address _nodeIdAddr) external view returns (bool);

    function checkPermissionTrustList(address _node) external view returns (bool);

    //TODO
    function setRelayerFee(uint256 _fee, address _nodeIdAddress) external;

    function setRelayerStatus(IRelayerPool.RelayerStatus _status, address _nodeIdAddress) external;

    function createRelayer(
        Node memory _node,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @dev Wrappers over decoding and deserialization operation from bytes into bassic types in Solidity for PolyNetwork cross chain utility.
 *
 * Decode into basic types in Solidity from bytes easily. It's designed to be used 
 * for PolyNetwork cross chain application, and the decoding rules on Ethereum chain 
 * and the encoding rule on other chains should be consistent, and . Here we
 * follow the underlying deserialization rule with implementation found here: 
 * https://github.com/polynetwork/poly/blob/master/common/zero_copy_source.go
 *
 * Using this library instead of the unchecked serialization method can help reduce
 * the risk of serious bugs and handfule, so it's recommended to use it.
 *
 * Please note that risk can be minimized, yet not eliminated.
 */
library ZeroCopySource {
    /* @notice              Read next byte as boolean type starting at offset from buff
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the boolean value
    *  @return              The the read boolean value and new offset
    */
    function NextBool(bytes memory buff, uint256 offset) internal pure returns(bool, uint256) {
        require(offset + 1 <= buff.length && offset < offset + 1, "Offset exceeds limit");
        // byte === bytes1
        uint8 v;
        assembly{
            v := mload(add(add(buff, 0x20), offset))
        }
        bool value;
        if (v == 0x01) {
		    value = true;
    	} else if (v == 0x00) {
            value = false;
        } else {
            revert("NextBool value error");
        }
        return (value, offset + 1);
    }

    /* @notice              Read next byte as uint8 starting at offset from buff
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the byte value
    *  @return              The read uint8 value and new offset
    */
    function NextUint8(bytes memory buff, uint256 offset) internal pure returns (uint8, uint256) {
        require(offset + 1 <= buff.length && offset < offset + 1, "NextUint8, Offset exceeds maximum");
        uint8 v;
        assembly{
            let tmpbytes := mload(0x40)
            let bvalue := mload(add(add(buff, 0x20), offset))
            mstore8(tmpbytes, byte(0, bvalue))
            mstore(0x40, add(tmpbytes, 0x01))
            v := mload(sub(tmpbytes, 0x1f))
        }
        return (v, offset + 1);
    }

    /* @notice              Read next two bytes as uint16 type starting from offset
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the uint16 value
    *  @return              The read uint16 value and updated offset
    */
    function NextUint16(bytes memory buff, uint256 offset) internal pure returns (uint16, uint256) {
        require(offset + 2 <= buff.length && offset < offset + 2, "NextUint16, offset exceeds maximum");
        
        uint16 v;
        assembly {
            let tmpbytes := mload(0x40)
            let bvalue := mload(add(add(buff, 0x20), offset))
            mstore8(tmpbytes, byte(0x01, bvalue))
            mstore8(add(tmpbytes, 0x01), byte(0, bvalue))
            mstore(0x40, add(tmpbytes, 0x02))
            v := mload(sub(tmpbytes, 0x1e))
        }
        return (v, offset + 2);
    }


    /* @notice              Read next four bytes as uint32 type starting from offset
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the uint32 value
    *  @return              The read uint32 value and updated offset
    */
    function NextUint32(bytes memory buff, uint256 offset) internal pure returns (uint32, uint256) {
        require(offset + 4 <= buff.length && offset < offset + 4, "NextUint32, offset exceeds maximum");
        uint32 v;
        assembly {
            let tmpbytes := mload(0x40)
            let byteLen := 0x04
            for {
                let tindex := 0x00
                let bindex := sub(byteLen, 0x01)
                let bvalue := mload(add(add(buff, 0x20), offset))
            } lt(tindex, byteLen) {
                tindex := add(tindex, 0x01)
                bindex := sub(bindex, 0x01)
            }{
                mstore8(add(tmpbytes, tindex), byte(bindex, bvalue))
            }
            mstore(0x40, add(tmpbytes, byteLen))
            v := mload(sub(tmpbytes, sub(0x20, byteLen)))
        }
        return (v, offset + 4);
    }

    /* @notice              Read next eight bytes as uint64 type starting from offset
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the uint64 value
    *  @return              The read uint64 value and updated offset
    */
    function NextUint64(bytes memory buff, uint256 offset) internal pure returns (uint64, uint256) {
        require(offset + 8 <= buff.length && offset < offset + 8, "NextUint64, offset exceeds maximum");
        uint64 v;
        assembly {
            let tmpbytes := mload(0x40)
            let byteLen := 0x08
            for {
                let tindex := 0x00
                let bindex := sub(byteLen, 0x01)
                let bvalue := mload(add(add(buff, 0x20), offset))
            } lt(tindex, byteLen) {
                tindex := add(tindex, 0x01)
                bindex := sub(bindex, 0x01)
            }{
                mstore8(add(tmpbytes, tindex), byte(bindex, bvalue))
            }
            mstore(0x40, add(tmpbytes, byteLen))
            v := mload(sub(tmpbytes, sub(0x20, byteLen)))
        }
        return (v, offset + 8);
    }

    /* @notice              Read next 32 bytes as uint256 type starting from offset,
                            there are limits considering the numerical limits in multi-chain
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the uint256 value
    *  @return              The read uint256 value and updated offset
    */
    function NextUint255(bytes memory buff, uint256 offset) internal pure returns (uint256, uint256) {
        require(offset + 32 <= buff.length && offset < offset + 32, "NextUint255, offset exceeds maximum");
        uint256 v;
        assembly {
            let tmpbytes := mload(0x40)
            let byteLen := 0x20
            for {
                let tindex := 0x00
                let bindex := sub(byteLen, 0x01)
                let bvalue := mload(add(add(buff, 0x20), offset))
            } lt(tindex, byteLen) {
                tindex := add(tindex, 0x01)
                bindex := sub(bindex, 0x01)
            }{
                mstore8(add(tmpbytes, tindex), byte(bindex, bvalue))
            }
            mstore(0x40, add(tmpbytes, byteLen))
            v := mload(tmpbytes)
        }
        require(v <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "Value exceeds the range");
        return (v, offset + 32);
    }
    /* @notice              Read next variable bytes starting from offset,
                            the decoding rule coming from multi-chain
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the bytes value
    *  @return              The read variable bytes array value and updated offset
    */
    function NextVarBytes(bytes memory buff, uint256 offset) internal pure returns(bytes memory, uint256) {
        uint len;
        (len, offset) = NextVarUint(buff, offset);
        require(offset + len <= buff.length && offset < offset + len, "NextVarBytes, offset exceeds maximum");
        bytes memory tempBytes;
        assembly{
            switch iszero(len)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(len, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, len)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(buff, lengthmod), mul(0x20, iszero(lengthmod))), offset)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, len)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return (tempBytes, offset + len);
    }
    /* @notice              Read next 32 bytes starting from offset,
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the bytes value
    *  @return              The read bytes32 value and updated offset
    */
    function NextHash(bytes memory buff, uint256 offset) internal pure returns (bytes32 , uint256) {
        require(offset + 32 <= buff.length && offset < offset + 32, "NextHash, offset exceeds maximum");
        bytes32 v;
        assembly {
            v := mload(add(buff, add(offset, 0x20)))
        }
        return (v, offset + 32);
    }

    /* @notice              Read next 20 bytes starting from offset,
    *  @param buff          Source bytes array
    *  @param offset        The position from where we read the bytes value
    *  @return              The read bytes20 value and updated offset
    */
    function NextAddress(bytes memory buff, uint256 offset) internal pure returns (address, uint256) {
        require(offset + 20 <= buff.length && offset < offset + 20, "NextAddress, offset exceeds maximum");
        bytes20 v;
        assembly {
            v := mload(add(buff, add(offset, 0x20)))
        }
        return (address(v), offset + 20);
    }
    
    function NextVarUint(bytes memory buff, uint256 offset) internal pure returns(uint, uint256) {
        uint8 v;
        (v, offset) = NextUint8(buff, offset);

        uint value;
        if (v == 0xFD) {
            // return NextUint16(buff, offset);
            (value, offset) = NextUint16(buff, offset);
            require(value >= 0xFD && value <= 0xFFFF, "NextUint16, value outside range");
            return (value, offset);
        } else if (v == 0xFE) {
            // return NextUint32(buff, offset);
            (value, offset) = NextUint32(buff, offset);
            require(value > 0xFFFF && value <= 0xFFFFFFFF, "NextVarUint, value outside range");
            return (value, offset);
        } else if (v == 0xFF) {
            // return NextUint64(buff, offset);
            (value, offset) = NextUint64(buff, offset);
            require(value > 0xFFFFFFFF, "NextVarUint, value outside range");
            return (value, offset);
        } else{
            // return (uint8(v), offset);
            value = uint8(v);
            require(value < 0xFD, "NextVarUint, value outside range");
            return (value, offset);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Utils {
    /* @notice      Convert the bytes array to bytes32 type, the bytes array length must be 32
    *  @param _bs   Source bytes array
    *  @return      bytes32
    */
    function bytesToBytes32(bytes memory _bs) internal pure returns (bytes32 value) {
        require(_bs.length == 32, "bytes length is not 32.");
        assembly {
            // load 32 bytes from memory starting from position _bs + 0x20 since the first 0x20 bytes stores _bs length
            value := mload(add(_bs, 0x20))
        }
    }

    /* @notice      Convert bytes to uint256
    *  @param _b    Source bytes should have length of 32
    *  @return      uint256
    */
    function bytesToUint256(bytes memory _bs) internal pure returns (uint256 value) {
        require(_bs.length == 32, "bytes length is not 32.");
        assembly {
            // load 32 bytes from memory starting from position _bs + 32
            value := mload(add(_bs, 0x20))
        }
        require(value <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "Value exceeds the range");
    }

    /* @notice      Convert uint256 to bytes
    *  @param _b    uint256 that needs to be converted
    *  @return      bytes
    */
    function uint256ToBytes(uint256 _value) internal pure returns (bytes memory bs) {
        require(_value <= 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff, "Value exceeds the range");
        assembly {
            // Get a location of some free memory and store it in result as
            // Solidity does for memory variables.
            bs := mload(0x40)
            // Put 0x20 at the first word, the length of bytes for uint256 value
            mstore(bs, 0x20)
            //In the next word, put value in bytes format to the next 32 bytes
            mstore(add(bs, 0x20), _value)
            // Update the free-memory pointer by padding our last write location to 32 bytes
            mstore(0x40, add(bs, 0x40))
        }
    }

    /* @notice      Convert bytes to address
    *  @param _bs   Source bytes: bytes length must be 20
    *  @return      Converted address from source bytes
    */
    function bytesToAddress(bytes memory _bs) internal pure returns (address addr)
    {
        require(_bs.length == 20, "bytes length does not match address");
        assembly {
            // for _bs, first word store _bs.length, second word store _bs.value
            // load 32 bytes from mem[_bs+20], convert it into Uint160, meaning we take last 20 bytes as addr (address).
            addr := mload(add(_bs, 0x14))
        }

    }
    
    /* @notice      Convert address to bytes
    *  @param _addr Address need to be converted
    *  @return      Converted bytes from address
    */
    function addressToBytes(address _addr) internal pure returns (bytes memory bs){
        assembly {
            // Get a location of some free memory and store it in result as
            // Solidity does for memory variables.
            bs := mload(0x40)
            // Put 20 (address byte length) at the first word, the length of bytes for uint256 value
            mstore(bs, 0x14)
            // logical shift left _a by 12 bytes, change _a from right-aligned to left-aligned
            mstore(add(bs, 0x20), shl(96, _addr))
            // Update the free-memory pointer by padding our last write location to 32 bytes
            mstore(0x40, add(bs, 0x40))
       }
    }

    /* @notice              Compare if two bytes are equal, which are in storage and memory, seperately
                            Refer from https://github.com/summa-tx/bitcoin-spv/blob/master/solidity/contracts/BytesLib.sol#L368
    *  @param _preBytes     The bytes stored in storage
    *  @param _postBytes    The bytes stored in memory
    *  @return              Bool type indicating if they are equal
    */
    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // fslot can contain both the length and contents of the array
                // if slength < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                // slength != 0
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    /* @notice              Slice the _bytes from _start index till the result has length of _length
                            Refer from https://github.com/summa-tx/bitcoin-spv/blob/master/solidity/contracts/BytesLib.sol#L246
    *  @param _bytes        The original bytes needs to be sliced
    *  @param _start        The index of _bytes for the start of sliced bytes
    *  @param _length       The index of _bytes for the end of sliced bytes
    *  @return              The sliced bytes
    */
    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                // lengthmod <= _length % 32
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
    /* @notice              Check if the elements number of _signers within _keepers array is no less than _m
    *  @param _keepers      The array consists of serveral address
    *  @param _signers      Some specific addresses to be looked into
    *  @param _m            The number requirement paramter
    *  @return              True means containment, false meansdo do not contain.
    */
    function containMAddresses(address[] memory _keepers, address[] memory _signers, uint _m) internal pure returns (bool){
        uint m = 0;
        for(uint i = 0; i < _signers.length; i++){
            for (uint j = 0; j < _keepers.length; j++) {
                if (_signers[i] == _keepers[j]) {
                    m++;
                    delete _keepers[j];
                }
            }
        }
        return m >= _m;
    }

    /* @notice              TODO
    *  @param key
    *  @return
    */
    function compressMCPubKey(bytes memory key) internal pure returns (bytes memory newkey) {
         require(key.length >= 67, "key lenggh is too short");
         newkey = slice(key, 0, 35);
         if (uint8(key[66]) % 2 == 0){
             newkey[2] = 0x02;
         } else {
             newkey[2] = 0x03;
         }
         return newkey;
    }
    
    /**
     * @dev Returns true if `account` is a contract.
     *      Refer from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L18
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library ModUtils {

    /**
     * @dev Wrap the modular exponent pre-compile introduced in Byzantium.
     * Returns base^exponent mod p.
     */
    function modExp(uint256 base, uint256 exponent, uint256 p)
        internal
        view returns(uint256 o)
    {
        /* solium-disable-next-line */
        assembly {
            // Args for the precompile: [<length_of_BASE> <length_of_EXPONENT>
            // <length_of_MODULUS> <BASE> <EXPONENT> <MODULUS>]
            let output := mload(0x40)
            let args := add(output, 0x20)
            mstore(args, 0x20)
            mstore(add(args, 0x20), 0x20)
            mstore(add(args, 0x40), 0x20)
            mstore(add(args, 0x60), base)
            mstore(add(args, 0x80), exponent)
            mstore(add(args, 0xa0), p)

            // 0x05 is the modular exponent contract address
            if iszero(staticcall(not(0), 0x05, args, 0xc0, output, 0x20)) {
                revert(0, 0)
            }
            o := mload(output)
        }
    }

    /**
     * @dev Calculates and returns the square root of a mod p if such a square
     * root exists. The modulus p must be an odd prime. If a square root does
     * not exist, function returns 0.
     */
    function modSqrt(uint256 a, uint256 p)
        internal
        view returns(uint256)
    {

        if (legendre(a, p) != 1) {
            return 0;
        }

        if (a == 0) {
            return 0;
        }

        if (p % 4 == 3) {
            return modExp(a, (p + 1) / 4, p);
        }

        uint256 s = p - 1;
        uint256 e = 0;

        while (s % 2 == 0) {
            s = s / 2;
            e = e + 1;
        }

        // Note the smaller int- finding n with Legendre symbol or -1
        // should be quick
        uint256 n = 2;
        while (legendre(n, p) != -1) {
            n = n + 1;
        }

        uint256 x = modExp(a, (s + 1) / 2, p);
        uint256 b = modExp(a, s, p);
        uint256 g = modExp(n, s, p);
        uint256 r = e;
        uint256 gs = 0;
        uint256 m = 0;
        uint256 t = b;

        while (true) {
            t = b;
            m = 0;

            for (m = 0; m < r; m++) {
                if (t == 1) {
                    break;
                }
                t = modExp(t, 2, p);
            }

            if (m == 0) {
                return x;
            }

            gs = modExp(g, uint256(2) ** (r - m - 1), p);
            g = (gs * gs) % p;
            x = (x * gs) % p;
            b = (b * g) % p;
            r = m;
        }
        revert("modSqrt: unreachable end point");
    }

    /**
     * @dev Calculates the Legendre symbol of the given a mod p.
     * @return Returns 1 if a is a quadratic residue mod p, -1 if it is
     * a non-quadratic residue, and 0 if a is 0.
     */
    function legendre(uint256 a, uint256 p)
        internal
        view returns(int256)
    {
        uint256 raised = modExp(a, (p - 1) / uint256(2), p);

        if (raised == 0 || raised == 1) {
            return int256(raised);
        } else if (raised == p - 1) {
            return -1;
        }

        revert("Failed to calculate legendre.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRelayerPool {
    enum RelayerType {
        Validator,
        Fisher
    }
    enum RelayerStatus {
        Inactive,
        Online,
        Offline,
        BlackListed
    }

    struct Deposit {
        address user; 
        uint256 lockTill; 
        uint256 amount;
    }

    function getTotalDeposit() external view returns (uint256);

    function getDeposit(uint256 _depositId)
        external
        view
        returns (
            address user,
            uint256 amount,
            uint256 lockTill
        );

    function withdraw(uint256 _depositId, uint256 _amount) external;

    function deposit(uint256 _amount) external;

    function harvestMyReward() external;

    function harvestPoolReward() external;

    function setRelayerStatus(RelayerStatus _status) external;

    function setRelayerFeeNumerator(uint256 _value) external;

    function setEmissionAnnualRateNumerator(uint256 _value) external;
}