// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {

  constructor(
    address newOwner
  )
    ConfirmedOwnerWithProposal(
      newOwner,
      address(0)
    )
  {
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {

  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor(
    address newOwner,
    address pendingOwner
  ) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(
    address to
  )
    public
    override
    onlyOwner()
  {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
    override
  {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner()
    public
    view
    override
    returns (
      address
    )
  {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(
    address to
  )
    private
  {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership()
    internal
    view
  {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner()
    external
    returns (
      address
    );

  function transferOwnership(
    address recipient
  )
    external;

  function acceptOwnership()
    external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";

/**
 * @title The OwnerIsCreator contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract OwnerIsCreator is ConfirmedOwner {

  constructor(
  )
    ConfirmedOwner(
      msg.sender
    )
  {
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IVRFConsumer.sol";
import "./HashToCurve.sol";
import "./DKGClient.sol";
import "./DKG.sol";
import "./OCR2Abstract.sol";
import "./OwnerIsCreator.sol";
import "./Debug.sol";

// If the compiler complains that this is too large for mainnet deployment, it
// can be reduced in size with "solc --revert-strings --optimize-runs 1"

contract VRF is HashToCurve, OCR2Abstract, OwnerIsCreator, DKGClient, Debug {

  // Proof contains everything needed to efficiently compute the VRF output of
  // the given input, and verify it against the given public key.
  //
  // Note that the final input is calculate onchain, from the blockhash and the
  // request commitment.
  struct Proof{
    G2Point pubKey; // Public key of the VRF provider
    G1Point output; // "Signature" output of VRF; actual output is hash of this.
    FProof f1;      // Auxillary data used to compute/verify hash-to-curve of input
    FProof f2;
  }

  DKG s_keyProvider;
  bytes32 public s_keyID;
  bytes32 public s_provingKeyHash;

  constructor(DKG _keyProvider, bytes32 _keyID) {
    s_keyProvider = _keyProvider;
    s_keyID = _keyID;
  }

  function vrfOutput(
    bytes32 input, Proof memory p
  ) public view returns (bytes32 output) {
    require(keccak256(abi.encodePacked(p.pubKey.p)) == s_provingKeyHash,
            "wrong public key");
    G1Point memory hashPoint = hashToCurve(input, p.f1, p.f2);
    require(discreteLogsMatch(hashPoint, p.output, p.pubKey), "bad VRF proof");
    require(p.output.p[0] < P && p.output.p[1] < P,
            "bad representation of output pt");
    return keccak256(abi.encodePacked(p.output.p));
  }

  struct Request{
    bytes32 requestID;
    uint256 seed;
    uint32 numWords;
    address sender;
  }

  mapping(address /* requester */ => uint256 /* current nonce */) public s_nonce;
  mapping(bytes32 /* requestID */ => bytes32 /* commitment */) private s_commitments;

  event RandomWordsRequested(
    bytes32 requestID, uint256 seed, uint32 numWords, address sender
  );
  event RandomWordsFulfilled(
    bytes32 indexed requestID, uint256[] output, bool success, bytes errorData
  );

  // requestRandomWords initiates a request for the VRF output
  function requestRandomWords(
    uint256 seed, uint32 numWords
  ) external returns (bytes32 requestID) {
    Request memory r;
    r.sender = msg.sender;
    uint256 currentNonce = s_nonce[r.sender];
    bytes32 keyID = s_keyID;
    r.requestID = keccak256(abi.encodePacked(r.sender, keyID, currentNonce));
    r.seed = seed;
    r.numWords = numWords;
    s_commitments[r.requestID] = commitment(r);
    emit RandomWordsRequested(r.requestID, r.seed, r.numWords, r.sender);
    s_nonce[r.sender] = currentNonce+1;
    return r.requestID;
  }

  function fulfillRandomWords(Request memory r, Proof memory p) public {
    bytes32 m_commitment = s_commitments[r.requestID];
    bytes32 expectedCommitment = commitment(r);
    require(m_commitment == expectedCommitment, "request lookup failed");
    bytes32 randomness = vrfOutput(m_commitment, p);
    delete s_commitments[r.requestID]; // Prevent replay of proof & re-entrance
    uint256[] memory response = new uint256[](r.numWords);
    for (uint256 i = 0; i < r.numWords; i++) {
      response[i] = uint256(keccak256(abi.encodePacked(randomness, i)));
    }
    try IVRFConsumer(r.sender).rawFulfillRandomWords(r.requestID, response) {
      emit RandomWordsFulfilled(r.requestID, response, true, new bytes(0));
    } catch (bytes memory errorData) {
      emit RandomWordsFulfilled(r.requestID, response, false, errorData);
    }
  }

  function commitment( // Returns the index for the specified request
    Request memory r
  ) internal pure returns (bytes32 commitment_) {
    bytes memory hashMsg = abi.encodePacked(
      r.requestID, r.seed, r.numWords, r.sender
    );
    return keccak256(hashMsg);
  }

  // DKGClient methods

  // newKeyRequested removes the proving key in response to a new key being
  // requested on the key provider.
  function newKeyRequested() external override fromKeyProvider() {
    bytes32 zero;
    s_provingKeyHash = zero;
  }

  // keyGenerated records the new proving key in response to the key provider
  // reporting it.
  function keyGenerated(KeyData memory kd) external override fromKeyProvider() {
    s_provingKeyHash = keccak256(abi.encodePacked(kd.publicKey));
  }

  // OCR2 methods

  // _report decodes the request and response proof from the report, and
  // passes it to fulfillRandomWords for verification and response to caller
  //
  // The format for the report can be constructed from the input arguments to
  // fulfillRandomWords.
  function _report(
    bytes32 /* configDigest */, uint40 epochAndRound, bytes memory report
  ) internal virtual {
    (Request memory r, Proof memory p) = abi.decode(report, (Request, Proof));
    fulfillRandomWords(r, p);
    // See, e.g.
    // https://github.com/smartcontractkit/offchain-reporting/blob/28dd19OffchainAggregator.sol#L343
    epochOfLastReport = uint32(epochAndRound >> 8);
  }

  // _payTransmitter should be filled in once the transmission reimbursement
  // logic has been decided.
  function _payTransmitter(uint32 initialGas, address transmitter) internal {}

  // Following methods are mostly cribbed from OCR2Base.sol

  function typeAndVersion() external override pure returns (string memory) {
    return "VRF 0.0.1";
  }

  uint32 epochOfLastReport; // epoch at the time of the last-reported distributed key

  uint256 constant private maxUint32 = (1 << 32) - 1;

  // Storing these fields used on the hot path in a ConfigInfo variable reduces the
  // retrieval of all of them to a single SLOAD. If any further fields are
  // added, make sure that storage of the struct still takes at most 32 bytes.
  struct ConfigInfo {
    bytes32 latestConfigDigest;
    uint8 f;
    uint8 n;
  }
  ConfigInfo internal s_configInfo;

  // incremented each time a new config is posted. This count is incorporated
  // into the config digest, to prevent replay attacks.
  uint32 internal s_configCount;
  uint32 internal s_latestConfigBlockNumber; // makes it easier for offchain systems
                                             // to extract config from logs.
  // Used for s_oracles[a].role, where a is an address, to track the purpose
  // of the address, or to indicate that the address is unset.
  enum Role {
    // No oracle role has been set for address a
    Unset,
    // Signing address for the s_oracles[a].index'th oracle. I.e., report
    // signatures from this oracle should ecrecover back to address a.
    Signer,
    // Transmission address for the s_oracles[a].index'th oracle. I.e., if a
    // report is received by OCR2Aggregator.transmit in which msg.sender is
    // a, it is attributed to the s_oracles[a].index'th oracle.
    Transmitter
  }

  struct Oracle {
    uint8 index; // Index of oracle in s_signers/s_transmitters
    Role role;   // Role of the address which mapped to this struct
  }

  mapping (address /* signer OR transmitter address */ => Oracle)
    internal s_oracles;

  // s_signers contains the signing address of each oracle
  address[] internal s_signers;

  // s_transmitters contains the transmission address of each oracle,
  // i.e. the address the oracle actually sends transactions to the contract from
  address[] internal s_transmitters;

  function latestConfigDigestAndEpoch() external view override returns (
    bool scanLogs, bytes32 configDigest, uint32 epoch) {
    return (false, s_configInfo.latestConfigDigest, epochOfLastReport);
  }

  function latestConfigDetails() external view override returns (
    uint32 configCount,
    uint32 blockNumber,
    bytes32 configDigest
  ) {
    return (
      configCount, s_latestConfigBlockNumber, s_configInfo.latestConfigDigest
    );
  }

  // Reverts transaction if config args are invalid
  modifier checkConfigValid (
    uint256 _numSigners, uint256 _numTransmitters, uint256 _f
  ) {
    require(_numSigners <= maxNumOracles, "too many signers");
    require(_f > 0, "f must be positive");
    require(
      _numSigners == _numTransmitters,
      "oracle addresses out of registration"
    );
    require(_numSigners > 3*_f, "faulty-oracle f too high");
    _;
  }

  struct SetConfigArgs {
    address[] signers;
    address[] transmitters;
    uint8 f;
    bytes onchainConfig;
    uint64 offchainConfigVersion;
    bytes offchainConfig;
  }

  /**
   * @notice sets offchain reporting protocol configuration incl. participating oracles
   * @param _signers addresses with which oracles sign the reports
   * @param _transmitters addresses oracles use to transmit the reports
   * @param _f number of faulty oracles the system can tolerate
   * @param _onchainConfig encoded on-chain contract configuration
   * @param _offchainConfigVersion version number for offchainEncoding schema
   * @param _offchainConfig encoded off-chain oracle configuration
   */
  function setConfig(
    address[] memory _signers,
    address[] memory _transmitters,
    uint8 _f,
    bytes memory _onchainConfig,
    uint64 _offchainConfigVersion,
    bytes memory _offchainConfig
  )
    external override
    checkConfigValid(_signers.length, _transmitters.length, _f)
    onlyOwner()
  {
    SetConfigArgs memory args = SetConfigArgs({
      signers: _signers,
      transmitters: _transmitters,
      f: _f,
      onchainConfig: _onchainConfig,
      offchainConfigVersion: _offchainConfigVersion,
      offchainConfig: _offchainConfig
    });

    // remove any old signer/transmitter addresses
    while (s_signers.length != 0) {
      uint lastIdx = s_signers.length - 1;
      address signer = s_signers[lastIdx];
      address transmitter = s_transmitters[lastIdx];
      delete s_oracles[signer];
      delete s_oracles[transmitter];
      s_signers.pop();
      s_transmitters.pop();
    }

    // add new signer/transmitter addresses
    for (uint i = 0; i < args.signers.length; i++) {
      require(
        s_oracles[args.signers[i]].role == Role.Unset,
        "repeated signer address"
      );
      s_oracles[args.signers[i]] = Oracle(uint8(i), Role.Signer);
      require(
        s_oracles[args.transmitters[i]].role == Role.Unset,
        "repeated transmitter address"
      );
      s_oracles[args.transmitters[i]] = Oracle(uint8(i), Role.Transmitter);
      s_signers.push(args.signers[i]);
      s_transmitters.push(args.transmitters[i]);
    }
    s_configInfo.f = args.f;
    uint32 previousConfigBlockNumber = s_latestConfigBlockNumber;
    s_latestConfigBlockNumber = uint32(block.number);
    s_configCount += 1;
    {
      s_configInfo.latestConfigDigest = configDigestFromConfigData(
        block.chainid,
        address(this),
        s_configCount,
        args.signers,
        args.transmitters,
        args.f,
        args.onchainConfig,
        args.offchainConfigVersion,
        args.offchainConfig
      );
    }
    s_configInfo.n = uint8(args.signers.length);

    emit ConfigSet(
      previousConfigBlockNumber,
      s_configInfo.latestConfigDigest,
      s_configCount,
      args.signers,
      args.transmitters,
      args.f,
      args.onchainConfig,
      args.offchainConfigVersion,
      args.offchainConfig
    );
  }

  function configDigestFromConfigData(
    uint256 _chainId,
    address _contractAddress,
    uint64 _configCount,
    address[] memory _signers,
    address[] memory _transmitters,
    uint8 _f,
    bytes memory _onchainConfig,
    uint64 _encodedConfigVersion,
    bytes memory _encodedConfig
  ) internal pure returns (bytes32) {
    bytes memory hMsg = abi.encode(
      _chainId, _contractAddress, _configCount, _signers, _transmitters, _f,
      _onchainConfig, _encodedConfigVersion, _encodedConfig
    );
    uint256 h = uint256(keccak256(hMsg));
    uint256 prefixMask = type(uint256).max << (256-16); // 0xFFFF00..00
    uint256 prefix = 0x0001 << (256-16); // 0x000100..00
    return bytes32((prefix & prefixMask) | (h & ~prefixMask));
  }

  // The constant-length components of the msg.data sent to transmit.
  // See the "If we wanted to call sam" example on for example reasoning
  // https://solidity.readthedocs.io/en/v0.7.2/abi-spec.html
  uint16 private constant TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT =
    4 + // function selector
    32 * 3 + // 3 words containing reportContext
    32 + // word containing start location of abiencoded report value
    32 + // word containing length of report
    32 + // word containing length rs
    32 + // word containing length of ss
    0; // placeholder

  function requireExpectedMsgDataLength(bytes calldata report) private pure {
    // calldata will never be big enough to make this overflow
    uint256 expected = uint256(TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT) +
      report.length; // one byte per entry in _report
    require(msg.data.length == expected, "calldata length mismatch");
  }

  // Stub to satisfy OCR2Abstract constraint. We don't use this because
  // per-oracle signatures are unnecessary for a VRF response, which we can
  // efficiently verify onchain. See transmitVRFResponse instead
  function transmit(
    bytes32[3] calldata, bytes calldata,
    bytes32[] calldata, bytes32[] calldata, bytes32
  ) external override {}

  // transmitVRFResponse should be used by offchain oracles instead of transmit,
  // to avoid having to send in empty (unused) signature data
  function transmitVRFResponse (
    bytes32[3] calldata reportContext,
    bytes calldata report
  ) external {
    bytes32 zero;
    require(s_provingKeyHash != zero, "no key available");

    uint256 initialGas = gasleft(); // This line must come first

    // reportContext consists of:
    // reportContext[0]: ConfigDigest
    // reportContext[1]: 27 byte padding, 4-byte epoch and 1-byte round
    // reportContext[2]: ExtraHash
    bytes32 configDigest = reportContext[0];
    uint40 epochAndRound = uint40(uint256(reportContext[1]));

    _report(configDigest, epochAndRound, report);

    emit Transmitted(configDigest, uint32(epochAndRound >> 8));

    ConfigInfo memory configInfo = s_configInfo;

    require(configInfo.latestConfigDigest == configDigest,
            "configDigest mismatch");

    assert(initialGas < maxUint32);
    _payTransmitter(uint32(initialGas), msg.sender);
  }

  // fromKeyProvider errors unless the modified function is called by the
  // designated key provider.
  modifier fromKeyProvider() {
    require(msg.sender == address(s_keyProvider),
            "key info must come from provider");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

abstract contract IVRFConsumer {
    address immutable vrf;
    constructor(address _vrf) { vrf = _vrf; }

    function fulfillRandomWords(
        bytes32 requestID, uint256[] memory response
    ) internal virtual;

    function rawFulfillRandomWords(
        bytes32 requestID, uint256[] memory randomWords
    ) external {
        require(vrf == msg.sender, "only coordinator can fulfill");
        fulfillRandomWords(requestID, randomWords);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ECCArithmetic.sol";

contract HashToCurve is ECCArithmetic {

    // hashToCurve returns the hash-to-curve value for m. f1 and f2 must
    // contain the auxillary information necessary to compute the values f(t₁)
    // and f(t₂), where t₁=𝔥₁(m) and t₂=𝔥₂(m) (See function f below.) The final
    // hash-to-curve value is f(t₁)+f(t₂).
    // ( https://www.di.ens.fr/~fouque/pub/latincrypt12.pdf#page=12, eqn (15))
    function hashToCurve(
        bytes32 m, // message to hash
        FProof memory f1, // Arguments to f for 𝔥₁(m)
        FProof memory f2  // Arguments to f for 𝔥₂(m)
    ) public view returns /* Hash-to-curve of  m */ (G1Point memory hashPoint) {
        uint256[2] memory hashes = getHashes(m); // Will contain t₁=𝔥₁(m), t₂=𝔥₂(m)
        G1Point memory f1point = f(hashes[0], f1);
        G1Point memory f2point = f(hashes[1], f2);
        return addG1(f1point, f2point);
    }

    // FProof contains the auxillary information used to efficiently verify
    // onchain a hash-to-curve value.
    //
    // The actual input to f, t, is not provided here, as it is computed onchain
    // from recursive hashing of the input message.
    //
    // The yᵢ values need only be provided up to the first one where xᵢ³+B is a
    // square. Leaving the subsequent values as zero will save a bit of gas.
    //
    // Similarly, tInvSquared need only be provided if the first valid x ordinate is x₃.
    struct FProof {
        uint256 denomInv;               // (1+B+t²)⁻¹ mod P
        uint256 tInvSquared;                   // t⁻² mod P
        uint256 y1; // pseudo square root of √(x₁³+B) mod P
        uint256 y2; // pseudo square root of √(x₂³+B) mod P
        uint256 y3; // pseudo square root of √(x₃³+B) mod P
    }

    // √(-3) mod P
    // https://www.di.ens.fr/~fouque/pub/latincrypt12.pdf#page=8 eqn's (7)-(9)
    // >>> sqrpwr = (P+1)>>2 # Works because P+1 is even
    // >>> pow(P-3, sqrpwr, P) # P-3 ≡ -3 mod P
    uint256 constant private SQR_MINUS_3 =
        // solium-disable-next-line indentation
        0xb3c4d79d41a91759a9e4c7e359b6b89eaec68e62effffffd;

    // Largest multiple of P which will fit into 2²⁵⁶
    // >>> (2**256 - (2**256 % P))/P
    uint256 constant private P_TIMES_MAXUINT256_DIV_P = 5 * P;

    // 2⁻¹ mod P
    // >>> pow(2, P-2, P)
    uint256 constant private HALF_MOD_P =
        // solium-disable-next-line indentation
        0x183227397098d014dc2822db40c0ac2ecbc0b548b438e5469e10460b6c3e7ea4;

    // 3⁻¹ mod P
    // >>> pow(3, P-2, P)
    uint256 constant private THIRD_MOD_P =
        // solium-disable-next-line indentation
        0x2042def740cbc01bd03583cf0100e593ba56470b9af68708d2c05d6490535385;

    // Constant term used in expression for v (Eq. 7.)
    // >>> ((SQR_MINUS_3 -1) * HALF_MOD_P) % P
    uint256 constant private V_CONST = // (-1+√(-3))/2 mod P
        0x59e26bcea0d48bacd4f263f1acdb5c4f5763473177fffffe;

    // >>> pow(B+1, sqrpwr, P)
    uint256 constant private SQR_ONE_PLUS_B = 2;

    // https://www.di.ens.fr/~fouque/pub/latincrypt12.pdf#page=8, eqn's (7)-(9)
    // It's more gas-efficient to pass in the inverses mod P, than to compute
    // them on-chain (~512 gas for the extra parameter, vs ~4,000 gas for
    // Euclid's algorithm.)
    //
    // The yᵢ values need only be provided up to the first one where xᵢ³+B is a
    // square. Leaving the subsequent values as zero will save a bit of gas.
    // Similarly, if x₁ or x₂ is valid, tInvSquared can be set to zero, since it
    // is only needed for validation of x₃.
    //
    // Note that this differs slightly from Definition 2 at the top of p. 9,
    // because we require the y ordinate to match the parity of the value of t
    // reduced mod P, instead of requiring it to match the quadratic residue
    // (which is the role in Definition 2 of the χ_q(t) factor.) The parity is
    // much cheaper to compute/verify than the quadratic residue, in the EVM
    // context.
    function f(uint256 t, FProof memory fp)
        internal pure returns (G1Point memory fpoint) // Point on curve
    {
        // Cryptographically impossible; could be dropped.
        if (t == 0) { // Display formula just before §4, p. 9.
            return G1Point([V_CONST, SQR_ONE_PLUS_B]);
        }

        require(t < P_TIMES_MAXUINT256_DIV_P, "t not a uniform sample");
        uint256 tSquared = mulmod(t, t, P);
        uint256 denom = 1 + B + tSquared; // 1 + B + t²
        require(mulmod(denom, fp.denomInv, P) == 1, "wrong inverse for denom");
        // (√(-3))t²/(1+B+t²); Eq. (7)
        uint256 secondTerm = mulmod(mulmod(SQR_MINUS_3, tSquared, P), fp.denomInv, P);
        // v = (-1+√(-3))/2 - (√(-3))t²/(1+B+t²); Eq. (7)
        uint256 v = addmod(V_CONST, P-secondTerm, P);
        uint256 tParity = t % 2; // parity of y must match this

        // One of the following three solidity blocks is mathematically
        // guaranteed to return, if all the function inputs are valid; see §3
        // argument: https://www.di.ens.fr/~fouque/pub/latincrypt12.pdf#page=7

        { // Eq. (7)
            uint256 x1 = v; // Eq. (7)
            uint256 y1Squared = addmod(mulmod(x1, mulmod(x1, x1, P), P), B, P); // (x₁³+B) mod P
            uint256 py1Squared = mulmod(fp.y1, fp.y1, P);
            if (py1Squared == y1Squared) { // y₁ is an actual square root, so (x₁,±y₁) is our point
                require(fp.y1 < P, "y1 too large"); // force unique reperesentation of y₁
                require((fp.y1 % 2) == tParity, "y1 parity must match t's");
                fpoint.p[0] = x1;
                fpoint.p[1] = fp.y1;
                return fpoint;
            }
            // Since y₁ is not the square root of y1Squared, it must be the
            // pseudo square root, i.e., its square is the negative of
            // y1Squared. Verify that before dropping through to x₂.
            require(py1Squared == P - y1Squared, "y1!=pseudo sqr of x1^3+B");
        }

        { // Eq. (8)
            uint256 x2 = P - addmod(1, v, P); // -1 - v; Eq. (8)
            uint256 y2Squared = addmod(mulmod(x2, mulmod(x2, x2, P), P), B, P); // (x₂³+B) mod P
            uint256 py2Squared = mulmod(fp.y2, fp.y2, P);
            if (py2Squared == y2Squared) { // y₂ is an actual square root, so (x₂,±y₂) is our point
                require(fp.y2 < P, "y2 too large"); // force unique reperesentation of y₂
                require((fp.y2 % 2) == tParity, "y2 parity must match t's");
                fpoint.p[0] = x2;
                fpoint.p[1] = fp.y2;
                return fpoint;
            }
            // Since y₂ is not the square root of y1Squared, it must be the
            // pseudo square root, i.e., its square is the negative of y2Squared
            require(py2Squared == P - y2Squared, "y2!=pseudo sqr of x2^3+B");
        }

        { // Eq. (9). At this point, (x₃,±y₃) MUST be our point
            require(mulmod(tSquared, fp.tInvSquared, P) == 1, "tInvSquared*t**2 !== 1 mod P");
            secondTerm = mulmod(mulmod(mulmod(denom, denom, P), fp.tInvSquared, P), THIRD_MOD_P, P);
            uint256 x3 = addmod(1, P - secondTerm, P); // 1 - (1+B+t²)²/(3t²); Eq. (9)
            uint256 y3Squared = addmod(mulmod(x3, mulmod(x3, x3, P), P), B, P); // (x₃³+B) mod P
            require(mulmod(fp.y3, fp.y3, P) == y3Squared, "did not obtain a curve point");
            require(fp.y3 < P, "y2 too large"); // force unique reperesentation of y₃
            require((fp.y3 % 2) == tParity, "y3 parity must match t's");
            fpoint.p[0] = x3;
            fpoint.p[1] = fp.y3;
            return fpoint;
        }
    }

    function getHashes(bytes32 m) internal pure returns (uint256[2] memory hashes) {
        (uint256 hashCount, uint256 cycleCount) = (0, 0);
        // Recursively hash m until two values have been found which are less
        // than the maximum multiple of P. This ensures that we have uniform
        // samples from {0, ..., P-1}.
        while (hashCount < 2) {
            m = keccak256(abi.encodePacked(m));
            uint256 mn = uint256(m);
            if (mn < P_TIMES_MAXUINT256_DIV_P) { // Succeeds about 94.5% of the time, for AltBN-128 G1.
                hashes[hashCount] = mn % P;
                hashCount++;
            }
            cycleCount++;
            // This is cryptographically impossible to fail; difficulty under
            // random-oracle assumption is about 129 bits. (See design doc.)
            require(cycleCount <= 32, "attempted too many hashes");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./KeyDataStruct.sol";

// DKGClient's are called when there is new information about the keyID they are
// associated with.
//
// WARNING: IMPLEMENTATIONS **MUST** CHECK THAT CALLS COME FROM THE EXPECTED DKG CONTRACT
interface DKGClient is KeyDataStruct {

  // newKeyRequested is called when a new key is requested for the given keyID,
  // on the DKG contract.
  function newKeyRequested() external;

  // keyGenerated is called when key data for given keyID is reported on the DKG
  // contract.
  function keyGenerated(KeyData memory kd) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./DKGClient.sol";
import "./Debug.sol";
import "./KeyDataStruct.sol";
import "./OCR2Abstract.sol";
import "./OwnerIsCreator.sol";

contract DKG is KeyDataStruct, OCR2Abstract, OwnerIsCreator, Debug {

  // keyIDClients lists the client contracts which must be contacted when a new
  // key is requested for a given keyID, or when the key is provided. These
  // lists are adjusted using addClient and removeClient.
  mapping(bytes32 /* keyID */ => DKGClient[]) s_keyIDClients;

  mapping(bytes32 /* keyID */ =>
          mapping(bytes32 /* config digest */ => KeyData)
         ) s_keys;

  // _report stores the key data from a report, and reports it via an event.
  //
  // See golang contract.KeyData#Marshal and contract.Unmarshal for format.
  function _report(
    bytes32 configDigest, uint40 epochAndRound, bytes memory report
  ) internal {
    bytes32 keyID;
    bytes memory key;
    bytes32[] memory hashes;
    (keyID, key, hashes) = abi.decode(report, (bytes32,bytes,bytes32[]));
    KeyData memory kd = KeyData(key, hashes);

    DKGClient[] memory clients = s_keyIDClients[keyID];
    for (uint256 i = 0; i < clients.length; i++) {
      try clients[i].keyGenerated(kd) {} catch (bytes memory errorData) {
        emit DKGClientError(clients[i], errorData);
      }
    }

    s_keys[keyID][configDigest] = kd;

    // If offchain processes were listening for this event, we could get rid of
    // the above storage, but for now that's a micro-optimization.
    emit KeyGenerated(configDigest, keyID, kd);

    // See, e.g.
    // https://github.com/smartcontractkit/offchain-reporting/blob/28dd19OffchainAggregator.sol#L343
    epochOfLastReport = uint32(epochAndRound >> 8);
  }

  // KeyGenerated is emmitted when a key is reported for the given configDigest/processID.
  event KeyGenerated(bytes32 indexed configDigest, bytes32 indexed keyID, KeyData key);

  event DKGClientError(DKGClient client, bytes errorData);

  function getKey(
    bytes32 _keyID, bytes32 _configDigest
  ) external view returns (KeyData memory) {
    return s_keys[_keyID][_configDigest];
  }

  // addClient will add the given clientAddress to the list of clients which
  // should be updated when new key information is available for the given keyID
  function addClient(bytes32 keyID, DKGClient clientAddress) external onlyOwner() {
    s_keyIDClients[keyID].push(clientAddress);
  }

  // removeClient removes all instances of clientAddress from the list for the
  // given keyID.
  function removeClient(bytes32 keyID, DKGClient clientAddress) external onlyOwner() {
    DKGClient[] memory clients = s_keyIDClients[keyID];

    // Potentially overlong list with all instances of clientAddress removed
    DKGClient[] memory newClients = new DKGClient[](clients.length);
    uint256 found;
    for (uint256 i = 0; i < clients.length; i++) {
      if (clients[i] != clientAddress) {
        newClients[i-found] = clientAddress;
      } else {
        found++;
      }
    }

    // List of correct length with clientAddress removed. Could just bash the
    // length of newClients in assembly, instead, if this is too inefficient.
    DKGClient[] memory finalClients = new DKGClient[](clients.length - found);
    for (uint256 i = 0; i < clients.length - found; i++) {
      finalClients[i] = newClients[i];
    }
    s_keyIDClients[keyID] = finalClients;
  }

  // _afterSetConfig reports that a new key for the given keyID (encoded as the
  // only contents of the _onchainConfig) has been requested, via an event
  // emmission.
  function _afterSetConfig(
    uint8 /* _f */, bytes memory _onchainConfig, bytes32 _configDigest
  ) internal {
    // convert _onchainConfig bytes to bytes32
    bytes32 keyID;
    bytes32 zero;
    require(_onchainConfig.length == 32, "wrong length for onchainConfig");
    assembly {
      keyID := mload(add(_onchainConfig, 0x20))
    }
    require(keyID != zero, "failed to copy keyID");

    KeyData memory zeroKey;
    s_keys[keyID][_configDigest] = zeroKey;

    DKGClient[] memory clients = s_keyIDClients[keyID];
    for (uint256 i = 0; i < clients.length; i++) {
      clients[i].newKeyRequested();
    }
  }

  // Following methods are mostly cribbed from OCR2Base.sol

  function _beforeSetConfig(uint8 _f, bytes memory _onchainConfig) internal {}
  function _payTransmitter(uint32 initialGas, address transmitter) internal {}

  function typeAndVersion() external override pure returns (string memory) {
    return "DKG 0.0.1";
  }

  uint32 epochOfLastReport; // epoch at the time of the last-reported distributed key

  uint256 constant private maxUint32 = (1 << 32) - 1;

  // Storing these fields used on the hot path in a ConfigInfo variable reduces the
  // retrieval of all of them to a single SLOAD. If any further fields are
  // added, make sure that storage of the struct still takes at most 32 bytes.
  struct ConfigInfo {
    bytes32 latestConfigDigest;
    uint8 f;
    uint8 n;
  }
  ConfigInfo internal s_configInfo;

  // incremented each time a new config is posted. This count is incorporated
  // into the config digest, to prevent replay attacks.
  uint32 internal s_configCount;
  uint32 internal s_latestConfigBlockNumber; // makes it easier for offchain systems
                                             // to extract config from logs.
  // Used for s_oracles[a].role, where a is an address, to track the purpose
  // of the address, or to indicate that the address is unset.
  enum Role {
    // No oracle role has been set for address a
    Unset,
    // Signing address for the s_oracles[a].index'th oracle. I.e., report
    // signatures from this oracle should ecrecover back to address a.
    Signer,
    // Transmission address for the s_oracles[a].index'th oracle. I.e., if a
    // report is received by OCR2Aggregator.transmit in which msg.sender is
    // a, it is attributed to the s_oracles[a].index'th oracle.
    Transmitter
  }

  struct Oracle {
    uint8 index; // Index of oracle in s_signers/s_transmitters
    Role role;   // Role of the address which mapped to this struct
  }

  mapping (address /* signer OR transmitter address */ => Oracle)
    internal s_oracles;

  // s_signers contains the signing address of each oracle
  address[] internal s_signers;

  // s_transmitters contains the transmission address of each oracle,
  // i.e. the address the oracle actually sends transactions to the contract from
  address[] internal s_transmitters;

  function latestConfigDigestAndEpoch() external view override returns (
    bool scanLogs, bytes32 configDigest, uint32 epoch) {
    return (false, s_configInfo.latestConfigDigest, epochOfLastReport);
  }

  function latestConfigDetails() external view override returns (
    uint32 configCount,
    uint32 blockNumber,
    bytes32 configDigest
  ) {
    return (
      configCount, s_latestConfigBlockNumber, s_configInfo.latestConfigDigest
    );
  }

  // Reverts transaction if config args are invalid
  modifier checkConfigValid (
    uint256 _numSigners, uint256 _numTransmitters, uint256 _f
  ) {
    require(_numSigners <= maxNumOracles, "too many signers");
    require(_f > 0, "f must be positive");
    require(
      _numSigners == _numTransmitters,
      "oracle addresses out of registration"
    );
    require(_numSigners > 3*_f, "faulty-oracle f too high");
    _;
  }

  struct SetConfigArgs {
    address[] signers;
    address[] transmitters;
    uint8 f;
    bytes onchainConfig;
    uint64 offchainConfigVersion;
    bytes offchainConfig;
  }

  /**
   * @notice sets offchain reporting protocol configuration incl. participating oracles
   * @param _signers addresses with which oracles sign the reports
   * @param _transmitters addresses oracles use to transmit the reports
   * @param _f number of faulty oracles the system can tolerate
   * @param _onchainConfig encoded on-chain contract configuration
   * @param _offchainConfigVersion version number for offchainEncoding schema
   * @param _offchainConfig encoded off-chain oracle configuration
   */
  function setConfig(
    address[] memory _signers,
    address[] memory _transmitters,
    uint8 _f,
    bytes memory _onchainConfig,
    uint64 _offchainConfigVersion,
    bytes memory _offchainConfig
  )
    external override
    checkConfigValid(_signers.length, _transmitters.length, _f)
    onlyOwner()
  {
    SetConfigArgs memory args = SetConfigArgs({
      signers: _signers,
      transmitters: _transmitters,
      f: _f,
      onchainConfig: _onchainConfig,
      offchainConfigVersion: _offchainConfigVersion,
      offchainConfig: _offchainConfig
    });

    _beforeSetConfig(
      args.f,
      args.onchainConfig
    );

    while (s_signers.length != 0) { // remove any old signer/transmitter addresses
      uint lastIdx = s_signers.length - 1;
      address signer = s_signers[lastIdx];
      address transmitter = s_transmitters[lastIdx];
      delete s_oracles[signer];
      delete s_oracles[transmitter];
      s_signers.pop();
      s_transmitters.pop();
    }

    for (uint i = 0; i < args.signers.length; i++) { // add new signer/transmitter addresses
      require(
        s_oracles[args.signers[i]].role == Role.Unset,
        "repeated signer address"
      );
      s_oracles[args.signers[i]] = Oracle(uint8(i), Role.Signer);
      require(
        s_oracles[args.transmitters[i]].role == Role.Unset,
        "repeated transmitter address"
      );
      s_oracles[args.transmitters[i]] = Oracle(uint8(i), Role.Transmitter);
      s_signers.push(args.signers[i]);
      s_transmitters.push(args.transmitters[i]);
    }
    s_configInfo.f = args.f;
    uint32 previousConfigBlockNumber = s_latestConfigBlockNumber;
    s_latestConfigBlockNumber = uint32(block.number);
    s_configCount += 1;
    bytes32 lcd;
    {
      lcd = configDigestFromConfigData(
        block.chainid,
        address(this),
        s_configCount,
        args.signers,
        args.transmitters,
        args.f,
        args.onchainConfig,
        args.offchainConfigVersion,
        args.offchainConfig
      );
      s_configInfo.latestConfigDigest = lcd;
    }
    s_configInfo.n = uint8(args.signers.length);

    emit ConfigSet(
      previousConfigBlockNumber,
      s_configInfo.latestConfigDigest,
      s_configCount,
      args.signers,
      args.transmitters,
      args.f,
      args.onchainConfig,
      args.offchainConfigVersion,
      args.offchainConfig
    );

    _afterSetConfig(
      args.f,
      args.onchainConfig,
      lcd
    );
  }

  function configDigestFromConfigData(
    uint256 _chainId,
    address _contractAddress,
    uint64 _configCount,
    address[] memory _signers,
    address[] memory _transmitters,
    uint8 _f,
    bytes memory _onchainConfig,
    uint64 _encodedConfigVersion,
    bytes memory _encodedConfig
  ) internal pure returns (bytes32) {
    uint256 h = uint256(keccak256(abi.encode(_chainId, _contractAddress, _configCount,
                                             _signers, _transmitters, _f, _onchainConfig, _encodedConfigVersion, _encodedConfig
                                            )));
    uint256 prefixMask = type(uint256).max << (256-16); // 0xFFFF00..00
    uint256 prefix = 0x0001 << (256-16); // 0x000100..00
    return bytes32((prefix & prefixMask) | (h & ~prefixMask));
  }

  // The constant-length components of the msg.data sent to transmit.
  // See the "If we wanted to call sam" example on for example reasoning
  // https://solidity.readthedocs.io/en/v0.7.2/abi-spec.html
  uint16 constant TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT =
    4 + // function selector
    32 * 3 + // 3 words containing reportContext
    32 + // word containing start location of abiencoded report value
    32 + // word containing location start of abiencoded rs value
    32 + // word containing start location of abiencoded ss value
    32 + // rawVs value
    32 + // word containing length of report
    32 + // word containing length rs
    32 + // word containing length of ss
    0; // placeholder

  function requireExpectedMsgDataLength(
    bytes calldata report, bytes32[] calldata rs, bytes32[] calldata ss
  )
    private
    pure
  {
    // calldata will never be big enough to make this overflow
    uint256 expected = uint256(TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT) +
      report.length + // one byte per entry in _report
      rs.length * 32 + // 32 bytes per entry in _rs
      ss.length * 32 + // 32 bytes per entry in _ss
      0; // placeholder
    require(msg.data.length == expected, "calldata length mismatch");
  }

  /**
   * @notice transmit is called to post a new report to the contract
   * @param report serialized report, which the signatures are signing.
   * @param rs ith element is the R components of the ith signature on report. Must have at most maxNumOracles entries
   * @param ss ith element is the S components of the ith signature on report. Must have at most maxNumOracles entries
   * @param rawVs ith element is the the V component of the ith signature
   */
  function transmit(
    // NOTE: If these parameters are changed, expectedMsgDataLength and/or
    // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
    bytes32[3] calldata reportContext,
    bytes calldata report,
    bytes32[] calldata rs, bytes32[] calldata ss, bytes32 rawVs // signatures
  )
    external override
  {
    uint256 initialGas = gasleft(); // This line must come first

    {
      // reportContext consists of:
      // reportContext[0]: ConfigDigest
      // reportContext[1]: 27 byte padding, 4-byte epoch and 1-byte round
      // reportContext[2]: ExtraHash
      bytes32 configDigest = reportContext[0];
      uint40 epochAndRound = uint40(uint256(reportContext[1]));

      _report(configDigest, epochAndRound, report);

      emit Transmitted(configDigest, uint32(epochAndRound >> 8));

      ConfigInfo memory configInfo = s_configInfo;
      require(configInfo.latestConfigDigest == configDigest, "configDigest mismatch");

      requireExpectedMsgDataLength(report, rs, ss);
      _requireValidSignatures(reportContext, report, rs, ss, rawVs, configInfo);
    }

    assert(initialGas < maxUint32);
    _payTransmitter(uint32(initialGas), msg.sender);
  }

  function _requireValidSignatures(
      bytes32[3] calldata reportContext,
      bytes calldata report,
      bytes32[] calldata rs, bytes32[] calldata ss, bytes32 rawVs, // signatures
      ConfigInfo memory configInfo
  ) internal virtual {
    {
      uint256 expectedNumSignatures = (configInfo.n + configInfo.f)/2 + 1; // require unique answer
      // require(rs.length == expectedNumSignatures, "wrong number of signatures");
      bytes memory numsigs = new bytes(1);
      numsigs[0] = bytes1(uint8(expectedNumSignatures));
      require(rs.length == expectedNumSignatures, bytesToString(numsigs));
      require(rs.length == ss.length, "signatures out of registration");

      Oracle memory transmitter = s_oracles[msg.sender];
      require( // Check that sender is authorized to report
        transmitter.role == Role.Transmitter &&
        msg.sender == s_transmitters[transmitter.index],
        "unauthorized transmitter"
      );
    }

    { // Verify signatures attached to report
      bytes32 h = keccak256(abi.encodePacked(keccak256(report), reportContext));
      bool[maxNumOracles] memory signed;

      Oracle memory o;
      for (uint i = 0; i < rs.length; i++) {
        address signer = ecrecover(h, uint8(rawVs[i])+27, rs[i], ss[i]);
        o = s_oracles[signer];
        require(o.role == Role.Signer, "address not authorized to sign");
        require(!signed[o.index], "non-unique signature");
        signed[o.index] = true;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/TypeAndVersionInterface.sol";


abstract contract OCR2Abstract is TypeAndVersionInterface {
  // Maximum number of oracles the offchain reporting protocol is designed for
  uint256 constant internal maxNumOracles = 31;

  /**
   * @notice triggers a new run of the offchain reporting protocol
   * @param previousConfigBlockNumber block in which the previous config was set, to simplify historic analysis
   * @param configDigest configDigest of this configuration
   * @param configCount ordinal number of this config setting among all config settings over the life of this contract
   * @param signers ith element is address ith oracle uses to sign a report
   * @param transmitters ith element is address ith oracle uses to transmit a report via the transmit method
   * @param f maximum number of faulty/dishonest oracles the protocol can tolerate while still working correctly
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version of the serialization format used for "offchainConfig" parameter
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   */
  event ConfigSet(
    uint32 previousConfigBlockNumber,
    bytes32 configDigest,
    uint64 configCount,
    address[] signers,
    address[] transmitters,
    uint8 f,
    bytes onchainConfig,
    uint64 offchainConfigVersion,
    bytes offchainConfig
  );

  /**
   * @notice sets offchain reporting protocol configuration incl. participating oracles
   * @param signers addresses with which oracles sign the reports
   * @param transmitters addresses oracles use to transmit the reports
   * @param f number of faulty oracles the system can tolerate
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version number for offchainEncoding schema
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   */
  function setConfig(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  )
    external
    virtual;

  /**
   * @notice information about current offchain reporting protocol configuration
   * @return configCount ordinal number of current config, out of all configs applied to this contract so far
   * @return blockNumber block at which this config was set
   * @return configDigest domain-separation tag for current config (see _configDigestFromConfigData)
   */
  function latestConfigDetails()
    external
    view
    virtual
    returns (
      uint32 configCount,
      uint32 blockNumber,
      bytes32 configDigest
    );

  function _configDigestFromConfigData(
    uint256 chainId,
    address contractAddress,
    uint64 configCount,
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  )
    internal
    pure
    returns (bytes32)
  {
    uint256 h = uint256(keccak256(abi.encode(chainId, contractAddress, configCount,
      signers, transmitters, f, onchainConfig, offchainConfigVersion, offchainConfig
    )));
    uint256 prefixMask = type(uint256).max << (256-16); // 0xFFFF00..00
    uint256 prefix = 0x0001 << (256-16); // 0x000100..00
    return bytes32((prefix & prefixMask) | (h & ~prefixMask));
  }

  /**
  * @notice optionally emited to indicate the latest configDigest and epoch for
     which a report was successfully transmited. Alternatively, the contract may
     use latestConfigDigestAndEpoch with scanLogs set to false.
  */
  event Transmitted(
    bytes32 configDigest,
    uint32 epoch
  );

  /**
   * @notice optionally returns the latest configDigest and epoch for which a
     report was successfully transmitted. Alternatively, the contract may return
     scanLogs set to true and use Transmitted events to provide this information
     to offchain watchers.
   * @return scanLogs indicates whether to rely on the configDigest and epoch
     returned or whether to scan logs for the Transmitted event instead.
   * @return configDigest
   * @return epoch
   */
  function latestConfigDigestAndEpoch()
    external
    view
    virtual
    returns(
      bool scanLogs,
      bytes32 configDigest,
      uint32 epoch
    );

  /**
   * @notice transmit is called to post a new report to the contract
   * @param report serialized report, which the signatures are signing.
   * @param rs ith element is the R components of the ith signature on report. Must have at most maxNumOracles entries
   * @param ss ith element is the S components of the ith signature on report. Must have at most maxNumOracles entries
   * @param rawVs ith element is the the V component of the ith signature
   */
  function transmit(
    // NOTE: If these parameters are changed, expectedMsgDataLength and/or
    // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
    bytes32[3] calldata reportContext,
    bytes calldata report,
    bytes32[] calldata rs, bytes32[] calldata ss, bytes32 rawVs // signatures
  )
    external
    virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Debug {

    // Cribbed from https://stackoverflow.com/questions/67893318/solidity-how-to-represent-bytes32-as-string
    function bytesToString(bytes memory _bytes) public pure returns (string memory) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(2*_bytes.length);
        for (i = 0; i < bytesArray.length; i++) {

            uint8 _f = uint8(_bytes[i/2] & 0x0f);
            uint8 _l = uint8(_bytes[i/2] >> 4);

            bytesArray[i] = bytes1(toASCII(_l));
            i = i + 1;
            bytesArray[i] = bytes1(toASCII(_f));
        }
        return string(bytesArray);
    }

    function bytes32ToString(bytes32 s) public pure returns (string memory) {
      bytes memory b = new bytes(32);
      for (uint256 i = 0; i < 32; i++) {
        b[i] = s[i];
      }
      return bytesToString(b);
    }

    function toASCII(uint8 _uint8) public pure returns (uint8) {
        if(_uint8 < 10) {
            return _uint8 + 48;
        } else {
            return _uint8 + 87;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract ECCArithmetic {

  // constant term in affine curve equation: y²=x³+b
  uint256 constant B = 3;

  // Base field for G1 is 𝔽ₚ
  // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-196.md#specification
  uint256 constant P =
    // solium-disable-next-line indentation
    0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd47;

  // #E(𝔽ₚ), number of points on  G1/G2Add
  // https://github.com/ethereum/go-ethereum/blob/2388e42/crypto/bn256/cloudflare/constants.go#L23
  uint256 constant Q =
    0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;

  struct G1Point { uint256[2] p; }

  struct G2Point { uint256[4] p; }

  function checkPointOnCurve(G1Point memory p) internal pure {
    require(p.p[0] < P, "x not in F_P");
    require(p.p[1] < P, "y not in F_P");
    uint256 rhs = addmod(mulmod(mulmod(p.p[0], p.p[0], P), p.p[0], P), B, P);
    require(mulmod(p.p[1], p.p[1], P) == rhs, "point not on curve");
  }

  function _addG1(G1Point memory p1, G1Point memory p2)
    internal view returns (G1Point memory sum)
  {
    checkPointOnCurve(p1);
    checkPointOnCurve(p2);

    uint256[4] memory summands;
    summands[0] = p1.p[0];
    summands[1] = p1.p[1];
    summands[2] = p2.p[0];
    summands[3] = p2.p[1];
    uint256[2] memory result;
    uint256 callresult;
    assembly { // solhint-disable-line no-inline-assembly
    callresult := staticcall(
      // gas cost. https://eips.ethereum.org/EIPS/eip-1108 ,
      // https://github.com/ethereum/go-ethereum/blob/9d10856/params/protocol_params.go#L124
      150,
      // g1add https://github.com/ethereum/go-ethereum/blob/9d10856/core/vm/contracts.go#L89
      0x6,
      summands, // input
      0x80,     // input length: 4 words
      result,      // output
      0x40      // output length: 2 words
    )
        }
    require(callresult != 0, "addg1 call failed");
    sum.p[0] = result[0];
    sum.p[1] = result[1];
    return sum;
  }

  function addG1(G1Point memory p1, G1Point memory p2)
    internal view returns (G1Point memory)
  {
    G1Point memory sum = _addG1(p1, p2);
    // This failure is mathematically possible from a legitimate return
    // value, but vanishingly unlikely, and almost certainly instead
    // reflects a failure in the precompile.
    require(sum.p[0] != 0 && sum.p[1] != 0, "addg1 failed: zero ordinate");
    return sum;
  }

  // Coordinates for generator of G2.
  uint256 constant g2GenXA = 0x198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2;
  uint256 constant g2GenXB = 0x1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed;
  uint256 constant g2GenYA = 0x090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b;
  uint256 constant g2GenYB = 0x12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa;

  uint256 constant pairingGasCost = 34_000 * 2 + 45_000; // Gas cost as of Istanbul; see EIP-1108
  uint256 constant pairingPrecompileAddress = 0x8;
  uint256 constant pairingInputLength = 12 * 0x20;
  uint256 constant pairingOutputLength = 0x20;

  // discreteLogsMatch returns true iff signature = sk*base, where sk is the
  // secret key associated with pubkey, i.e. pubkey = sk*<G2 generator>
  //
  // This is used for signature/VRF verification. In actual use, g1Base is the
  // hash-to-curve to be signed/exponentiated, and pubkey is the public key
  // the signature pertains to.
  function discreteLogsMatch(
    G1Point memory g1Base, G1Point memory signature, G2Point memory pubkey
  ) internal view returns (bool) {
    // It is not necessary to check that the points are in their respective
    // groups; the pairing check fails if that's not the case.

    // Let g1, g2 be the canonical generators of G1, G2, respectively..
    // Let l be the (unknown) discrete log of g1Base w.r.t. the G1 generator.
    //
    // In the happy path, the result of the first pairing in the following
    // will be -l*log_{g2}(pubkey) * e(g1,g2) = -l * sk * e(g1,g2), of the
    // second will be sk * l * e(g1,g2) = l * sk * e(g1,g2). Thus the two
    // terms will cancel, and the pairing function will return one. See
    // EIP-197.
    G1Point[] memory g1s = new G1Point[](2);
    G2Point[] memory g2s = new G2Point[](2);
    g1s[0] = G1Point([g1Base.p[0], P-g1Base.p[1]]);
    g1s[1] = signature;
    g2s[0] = pubkey;
    g2s[1] = G2Point([g2GenXA, g2GenXB, g2GenYA, g2GenYB]);
    return pairing(g1s, g2s);
  }

  function negateG1(G1Point memory p) internal pure returns (G1Point memory neg) {
    neg.p[0] = p.p[0];
    neg.p[1] = P-p.p[1];
  }

  /// @return the result of computing the pairing check
  /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
  /// return true.
  //
  // Cribbed from https://gist.github.com/BjornvdLaan/ca6dd4e3993e1ef392f363ec27fe74c4
  function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
    require(p1.length == p2.length);
    uint elements = p1.length;
    uint inputSize = elements * 6;
    uint[] memory input = new uint[](inputSize);

    for (uint i = 0; i < elements; i++)
      {
        input[i * 6 + 0] = p1[i].p[0];
        input[i * 6 + 1] = p1[i].p[1];
        input[i * 6 + 2] = p2[i].p[0];
        input[i * 6 + 3] = p2[i].p[1];
        input[i * 6 + 4] = p2[i].p[2];
        input[i * 6 + 5] = p2[i].p[3];
      }

    uint[1] memory out;
    bool success;

    assembly {
    success := staticcall(pairingGasCost, 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        }
    require(success);
    return out[0] != 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface KeyDataStruct {
  struct KeyData {
    bytes publicKey; // distrbuted key
    bytes32[] hashes; // hashes of shares used to construct key
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TypeAndVersionInterface{
  function typeAndVersion()
    external
    pure
    returns (string memory);
}