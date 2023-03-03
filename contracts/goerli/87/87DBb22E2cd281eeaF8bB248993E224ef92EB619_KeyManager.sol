pragma solidity ^0.8.0;

import "IKeyManager.sol";
import "SchnorrSECP256K1.sol";
import "Shared.sol";

/**
 * @title    KeyManager contract
 * @notice   Holds the aggregate and governance keys, functions to update them,
 *           and consumeKeyNonce so other contracts can verify signatures and updates _lastValidateTime
 */
contract KeyManager is SchnorrSECP256K1, Shared, IKeyManager {
    uint256 private constant _AGG_KEY_TIMEOUT = 2 days;

    /// @dev    The current (schnorr) aggregate key.
    Key private _aggKey;
    /// @dev    The current governance key.
    address private _govKey;
    /// @dev    The current community key.
    address private _commKey;
    /// @dev    The last time that a sig was verified (used for a dead man's switch)
    uint256 private _lastValidateTime;
    mapping(uint256 => bool) private _isNonceUsedByAggKey;
    /// @dev    Whitelist for who can call canConsumeNonce
    mapping(address => bool) private _canConsumeKeyNonce;
    bool private _canConsumeKeyNonceSet;
    uint256 private _numberWhitelistedAddresses;

    constructor(
        Key memory initialAggKey,
        address initialGovKey,
        address initialCommKey
    ) nzAddr(initialGovKey) nzAddr(initialCommKey) nzKey(initialAggKey) validAggKey(initialAggKey) {
        _aggKey = initialAggKey;
        _govKey = initialGovKey;
        _commKey = initialCommKey;
        _lastValidateTime = block.timestamp;
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Sets the specific addresses that can call consumeKeyNonce. This
     *          function can only ever be called once! Yes, it's possible to
     *          frontrun this, but honestly, it's fine in practice - it just
     *          needs to be set up successfully once, which is trivial
     * @param addrs   The addresses to whitelist
     */
    function setCanConsumeKeyNonce(address[] calldata addrs) external override {
        require(!_canConsumeKeyNonceSet, "KeyManager: already set");
        _canConsumeKeyNonceSet = true;

        for (uint256 i = 0; i < addrs.length; i++) {
            // Avoid duplicated newAddrs. Otherwise we could brick the updateCanConsumeKeyNonce
            // since it relies on the _numberWhitelistedAddresses and it has this check
            require(!_canConsumeKeyNonce[addrs[i]], "KeyManager: address already whitelisted");
            _canConsumeKeyNonce[addrs[i]] = true;
        }

        _numberWhitelistedAddresses = addrs.length;

        emit AggKeyNonceConsumersSet(addrs);
    }

    /**
     * @notice  Replaces all the addresses that can call consumeKeyNonce. Must delist all addresses and then
                add an arbitrary number of new addresses. To be used if any other contracts is updated.
     * @param currentAddrs   List of current whitelisted addresses
     * @param newAddrs   List of new addresses to whitelist
     */
    function updateCanConsumeKeyNonce(
        SigData calldata sigData,
        address[] calldata currentAddrs,
        address[] calldata newAddrs
    )
        external
        override
        consumesKeyNonce(
            sigData,
            keccak256(
                abi.encodeWithSelector(
                    this.updateCanConsumeKeyNonce.selector,
                    SigData(sigData.keyManAddr, sigData.chainID, 0, 0, sigData.nonce, address(0)),
                    currentAddrs,
                    newAddrs
                )
            )
        )
    {
        require(currentAddrs.length == _numberWhitelistedAddresses, "KeyManager: array incorrect length");

        // Remove current whitelisted addresses
        for (uint256 i = 0; i < currentAddrs.length; i++) {
            require(_canConsumeKeyNonce[currentAddrs[i]], "KeyManager: cannot dewhitelist");
            _canConsumeKeyNonce[currentAddrs[i]] = false;
        }

        //  Whitelist any number of new addresses
        for (uint256 i = 0; i < newAddrs.length; i++) {
            // Avoid duplicated newAddrs
            require(!_canConsumeKeyNonce[newAddrs[i]], "KeyManager: address already whitelisted");
            _canConsumeKeyNonce[newAddrs[i]] = true;
        }

        _numberWhitelistedAddresses = newAddrs.length;

        emit AggKeyNonceConsumersUpdated(currentAddrs, newAddrs);
    }

    /**
     * @notice  Checks the validity of a signature and msgHash, then updates _lastValidateTime
     * @dev     It would be nice to split this up, but these checks
     *          need to be made atomicly always. This needs to be available
     *          in this contract and in the Vault etc
     * @param sigData   The keccak256 hash over the msg (uint256) (here that's normally
     *                  a hash over the calldata to the function with an empty sigData)
     *                  from the current aggregate key (uint256)
     * @param contractMsgHash   The hash of the thing being signed but generated by the contract
     *                  to check it against the hash in sigData (bytes32) (here that's normally
     *                  a hash over the calldata to the function with an empty sigData)
     */
    function _consumeKeyNonce(SigData calldata sigData, bytes32 contractMsgHash) internal {
        Key memory key = _aggKey;
        // We require the msgHash param in the sigData is equal to the contract
        // message hash (the rules coded into the contract)
        require(sigData.msgHash == uint256(contractMsgHash), "KeyManager: invalid msgHash");
        require(
            verifySignature(sigData.msgHash, sigData.sig, key.pubKeyX, key.pubKeyYParity, sigData.kTimesGAddress),
            "KeyManager: Sig invalid"
        );
        require(!_isNonceUsedByAggKey[sigData.nonce], "KeyManager: nonce already used");
        require(sigData.keyManAddr == address(this), "KeyManager: wrong keyManAddr");
        require(sigData.chainID == block.chainid, "KeyManager: wrong chainID");

        _lastValidateTime = block.timestamp;
        _isNonceUsedByAggKey[sigData.nonce] = true;

        // Disable because tx.origin is not being used in the logic
        // solhint-disable-next-line avoid-tx-origin
        emit SignatureAccepted(sigData, tx.origin);
    }

    /**
     * @notice  Checks that the msg.sender is whitelisted before verifying the signature.
     * @dev     Split this function from consumeKeyNonceWhitelisted so the functions in this contract
     *          can skip the whitelisting check.
     */
    function consumeKeyNonce(SigData calldata sigData, bytes32 contractMsgHash) external override {
        require(_canConsumeKeyNonce[msg.sender], "KeyManager: not whitelisted");
        _consumeKeyNonce(sigData, contractMsgHash);
    }

    /**
     * @notice  Set a new aggregate key. Requires a signature from the current aggregate key
     * @param sigData   The keccak256 hash over the msg (uint256) (which is the calldata
     *                  for this function with empty msgHash and sig) and sig over that hash
     *                  from the current aggregate key (uint256)
     * @param newAggKey The new aggregate key to be set. The x component of the pubkey (uint256),
     *                  the parity of the y component (uint8)
     */
    function setAggKeyWithAggKey(
        SigData calldata sigData,
        Key calldata newAggKey
    )
        external
        override
        nzKey(newAggKey)
        validAggKey(newAggKey)
        consumesKeyNonce(
            sigData,
            keccak256(
                abi.encodeWithSelector(
                    this.setAggKeyWithAggKey.selector,
                    SigData(sigData.keyManAddr, sigData.chainID, 0, 0, sigData.nonce, address(0)),
                    newAggKey
                )
            )
        )
    {
        emit AggKeySetByAggKey(_aggKey, newAggKey);
        _aggKey = newAggKey;
    }

    /**
     * @notice  Set a new aggregate key. Can only be called by the current governance key
     * @param newAggKey The new aggregate key to be set. The x component of the pubkey (uint256),
     *                  the parity of the y component (uint8)
     */
    function setAggKeyWithGovKey(
        Key calldata newAggKey
    ) external override nzKey(newAggKey) validAggKey(newAggKey) timeoutEmergency onlyGovernor {
        emit AggKeySetByGovKey(_aggKey, newAggKey);
        _aggKey = newAggKey;
    }

    /**
     * @notice  Set a new aggregate key. Requires a signature from the current aggregate key
     * @param sigData   The keccak256 hash over the msg (uint256) (which is the calldata
     *                  for this function with empty msgHash and sig) and sig over that hash
     *                  from the current aggregate key (uint256)
     * @param newGovKey The new governance key to be set.

     */
    function setGovKeyWithAggKey(
        SigData calldata sigData,
        address newGovKey
    )
        external
        override
        nzAddr(newGovKey)
        consumesKeyNonce(
            sigData,
            keccak256(
                abi.encodeWithSelector(
                    this.setGovKeyWithAggKey.selector,
                    SigData(sigData.keyManAddr, sigData.chainID, 0, 0, sigData.nonce, address(0)),
                    newGovKey
                )
            )
        )
    {
        emit GovKeySetByAggKey(_govKey, newGovKey);
        _govKey = newGovKey;
    }

    /**
     * @notice  Set a new governance key. Can only be called by current governance key
     * @param newGovKey    The new governance key to be set.
     */
    function setGovKeyWithGovKey(address newGovKey) external override nzAddr(newGovKey) onlyGovernor {
        emit GovKeySetByGovKey(_govKey, newGovKey);
        _govKey = newGovKey;
    }

    /**
     * @notice  Set a new community key. Requires a signature from the current aggregate key
     * @param sigData   The keccak256 hash over the msg (uint256) (which is the calldata
     *                  for this function with empty msgHash and sig) and sig over that hash
     *                  from the current aggregate key (uint256)
     * @param newCommKey The new community key to be set.

     */
    function setCommKeyWithAggKey(
        SigData calldata sigData,
        address newCommKey
    )
        external
        override
        nzAddr(newCommKey)
        consumesKeyNonce(
            sigData,
            keccak256(
                abi.encodeWithSelector(
                    this.setCommKeyWithAggKey.selector,
                    SigData(sigData.keyManAddr, sigData.chainID, 0, 0, sigData.nonce, address(0)),
                    newCommKey
                )
            )
        )
    {
        emit CommKeySetByAggKey(_commKey, newCommKey);
        _commKey = newCommKey;
    }

    /**
     * @notice  Update the Community Key. Can only be called by the current Community Key.
     * @param newCommKey   New Community key address.
     */
    function setCommKeyWithCommKey(address newCommKey) external override onlyCommunityKey nzAddr(newCommKey) {
        emit CommKeySetByCommKey(_commKey, newCommKey);
        _commKey = newCommKey;
    }

    /**
     * @notice Withdraw any native tokens on this contract. The intended execution of this contract doesn't
     * require any native tokens. This function is just to recover any tokens that might have been sent to
     * this contract by accident (or any other reason).
     */
    function govWithdrawNative() external override onlyGovernor {
        uint256 amount = address(this).balance;

        // Could use msg.sender but hardcoding the get call just for extra safety
        address recipient = _getGovernanceKey();
        payable(recipient).transfer(amount);
    }

    /**
     * @notice Emit an event containing an action message. Can only be called by the governor.
     */
    function govAction(bytes32 message) external override onlyGovernor {
        emit GovernanceAction(message);
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  Non-state-changing functions            //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /**
     * @notice  Get the current aggregate key
     * @return  The Key struct for the aggregate key
     */
    function getAggregateKey() external view override returns (Key memory) {
        return _aggKey;
    }

    /**
     * @notice  Get the current governance key
     * @return  The Key struct for the governance key
     */
    function getGovernanceKey() external view override returns (address) {
        return _getGovernanceKey();
    }

    /**
     * @notice  Get the current community key
     * @return  The Key struct for the community key
     */
    function getCommunityKey() external view override returns (address) {
        return _getCommunityKey();
    }

    /**
     * @notice  Get the last time that a function was called which
     *          required a signature from _aggregateKeyData or _governanceKeyData
     * @return  The last time consumeKeyNonce was called, in unix time (uint256)
     */
    function getLastValidateTime() external view override returns (uint256) {
        return _lastValidateTime;
    }

    /**
     * @notice  Get whether or not the specific keyID has used this nonce before
     *          since it cannot be used again
     * @return  Whether the nonce has already been used (bool)
     */
    function isNonceUsedByAggKey(uint256 nonce) external view override returns (bool) {
        return _isNonceUsedByAggKey[nonce];
    }

    /**
     * @notice  Get whether addr is whitelisted for validating a sig
     * @param addr  The address to check
     * @return  Whether or not addr is whitelisted or not
     */
    function canConsumeKeyNonce(address addr) external view override returns (bool) {
        return _canConsumeKeyNonce[addr];
    }

    /**
     * @notice  Get whether or not _canConsumeKeyNonce has already been set, which
     *          prevents it from being set again
     * @return  The value of _canConsumeKeyNonceSet
     */
    function canConsumeKeyNonceSet() external view override returns (bool) {
        return _canConsumeKeyNonceSet;
    }

    /**
     * @notice  Get number of whitelisted addresses
     * @return  The value of _numberWhitelistedAddresses
     */
    function getNumberWhitelistedAddresses() external view override returns (uint256) {
        return _numberWhitelistedAddresses;
    }

    /**
     *  @notice Allows this contract to receive native
     */
    receive() external payable {}

    /**
     * @notice  Get the current governance key
     * @return  The Key struct for the governance key
     */
    function _getGovernanceKey() internal view returns (address) {
        return _govKey;
    }

    /**
     * @notice  Get the current community key
     * @return  The Key struct for the community key
     */
    function _getCommunityKey() internal view returns (address) {
        return _commKey;
    }

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                          Modifiers                       //
    //                                                          //
    //////////////////////////////////////////////////////////////

    /// @dev    Check that enough time has passed for setAggKeyWithGovKey. Needs
    ///         to be done as a modifier so that it can happen before consumeKeyNonce
    modifier timeoutEmergency() {
        require(block.timestamp - _lastValidateTime >= _AGG_KEY_TIMEOUT, "KeyManager: not enough time");
        _;
    }

    /// @dev    Check that an aggregate key is capable of having its signatures
    ///         verified by the schnorr lib.
    modifier validAggKey(Key memory key) {
        verifySigningKeyX(key.pubKeyX);
        _;
    }

    /// @dev    Check that the sender is the governance address
    modifier onlyGovernor() {
        require(msg.sender == _getGovernanceKey(), "KeyManager: not governor");
        _;
    }

    /// @dev    Check that the caller is the Community Key address.
    modifier onlyCommunityKey() {
        require(msg.sender == _getCommunityKey(), "KeyManager: not Community Key");
        _;
    }

    /// @dev    Call consumeKeyNonceWhitelisted
    modifier consumesKeyNonce(SigData calldata sigData, bytes32 contractMsgHash) {
        _consumeKeyNonce(sigData, contractMsgHash);
        _;
    }
}

pragma solidity ^0.8.0;

import "IShared.sol";

/**
 * @title    KeyManager interface
 * @notice   The interface for functions KeyManager implements
 */
interface IKeyManager is IShared {
    event AggKeySetByAggKey(Key oldAggKey, Key newAggKey);
    event AggKeySetByGovKey(Key oldAggKey, Key newAggKey);
    event GovKeySetByAggKey(address oldGovKey, address newGovKey);
    event GovKeySetByGovKey(address oldGovKey, address newGovKey);
    event CommKeySetByAggKey(address oldCommKey, address newCommKey);
    event CommKeySetByCommKey(address oldCommKey, address newCommKey);
    event SignatureAccepted(SigData sigData, address signer);
    event AggKeyNonceConsumersSet(address[] addrs);
    event AggKeyNonceConsumersUpdated(address[] currentAddrs, address[] newAddrs);
    event GovernanceAction(bytes32 message);

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  State-changing functions                //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function setCanConsumeKeyNonce(address[] calldata addrs) external;

    function updateCanConsumeKeyNonce(
        SigData calldata sigData,
        address[] calldata currentAddrs,
        address[] calldata newAddrs
    ) external;

    function consumeKeyNonce(SigData memory sigData, bytes32 contractMsgHash) external;

    function setAggKeyWithAggKey(SigData memory sigData, Key memory newAggKey) external;

    function setAggKeyWithGovKey(Key memory newAggKey) external;

    function setGovKeyWithAggKey(SigData calldata sigData, address newGovKey) external;

    function setGovKeyWithGovKey(address newGovKey) external;

    function setCommKeyWithAggKey(SigData calldata sigData, address newCommKey) external;

    function setCommKeyWithCommKey(address newCommKey) external;

    function govWithdrawNative() external;

    function govAction(bytes32 message) external;

    //////////////////////////////////////////////////////////////
    //                                                          //
    //                  Non-state-changing functions            //
    //                                                          //
    //////////////////////////////////////////////////////////////

    function getAggregateKey() external view returns (Key memory);

    function getGovernanceKey() external view returns (address);

    function getCommunityKey() external view returns (address);

    function isNonceUsedByAggKey(uint256 nonce) external view returns (bool);

    function getLastValidateTime() external view returns (uint256);

    function canConsumeKeyNonce(address addr) external view returns (bool);

    function canConsumeKeyNonceSet() external view returns (bool);

    function getNumberWhitelistedAddresses() external view returns (uint256);
}

pragma solidity ^0.8.0;
import "IERC20.sol";

/**
 * @title    Shared interface
 * @notice   Holds structs needed by other interfaces
 */
interface IShared {
    /**
     * @dev  SchnorrSECP256K1 requires that each key has a public key part (x coordinate),
     *       a parity for the y coordinate (0 if the y ordinate of the public key is even, 1
     *       if it's odd)
     */
    struct Key {
        uint256 pubKeyX;
        uint8 pubKeyYParity;
    }

    /**
     * @dev  Contains a signature and the msgHash that the signature is over. Kept as a single
     *       struct since they should always be used together
     */
    struct SigData {
        address keyManAddr;
        uint256 chainID;
        uint256 msgHash;
        uint256 sig;
        uint256 nonce;
        address kTimesGAddress;
    }

    /**
     * @param token The address of the token to be transferred
     * @param recipient The address of the recipient of the transfer
     * @param amount    The amount to transfer, in wei (uint)
     */
    struct TransferParams {
        address token;
        address payable recipient;
        uint256 amount;
    }

    /**
     * @param swapID    The unique identifier for this swap (bytes32), used for create2
     * @param token     The token to be transferred
     */
    struct DeployFetchParams {
        bytes32 swapID;
        address token;
    }

    /**
     * @param fetchContract   The address of the deployed Deposit contract
     * @param token     The token to be transferred
     */
    struct FetchParams {
        address payable fetchContract;
        address token;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

pragma solidity ^0.8.0;

/// @notice Slightly modified from https://github.com/smartcontractkit/chainlink/pull/1272/files
abstract contract SchnorrSECP256K1 {
    // See https://en.bitcoin.it/wiki/Secp256k1 for this constant.
    // Group order of secp256k1
    uint256 private constant Q =
        // solium-disable-next-line indentation
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    // solium-disable-next-line zeppelin/no-arithmetic-operations
    uint256 private constant HALF_Q = (Q >> 1) + 1;

    /** **************************************************************************
      @notice verifySignature returns true iff passed a valid Schnorr signature.

      @dev See https://en.wikipedia.org/wiki/Schnorr_signature for reference.

      @dev In what follows, let d be your secret key, PK be your public key,
      PKx be the x ordinate of your public key, and PKyp be the parity bit for
      the y ordinate (i.e., 0 if PKy is even, 1 if odd.)
      **************************************************************************
      @dev TO CREATE A VALID SIGNATURE FOR THIS METHOD

      @dev First PKx must be less than HALF_Q. Then follow these instructions
           (see evm/test/schnorr_test.js, for an example of carrying them out):
      @dev 1. Hash the target message to a uint256, called msgHash here, using
              keccak256

      @dev 2. Pick k uniformly and cryptographically securely randomly from
              {0,...,Q-1}. It is critical that k remains confidential, as your
              private key can be reconstructed from k and the signature.

      @dev 3. Compute k*g in the secp256k1 group, where g is the group
              generator. (This is the same as computing the public key from the
              secret key k. But it's OK if k*g's x ordinate is greater than
              HALF_Q.)

      @dev 4. Compute the ethereum address for k*g. This is the lower 160 bits
              of the keccak hash of the concatenated affine coordinates of k*g,
              as 32-byte big-endians. (For instance, you could pass k to
              ethereumjs-utils's privateToAddress to compute this, though that
              should be strictly a development convenience, not for handling
              live secrets, unless you've locked your javascript environment
              down very carefully.) Call this address
              nonceTimesGeneratorAddress.

      @dev 5. Compute e=uint256(keccak256(PKx as a 32-byte big-endian
                                        ‖ PKyp as a single byte
                                        ‖ msgHash
                                        ‖ nonceTimesGeneratorAddress))
              This value e is called "msgChallenge" in verifySignature's source
              code below. Here "‖" means concatenation of the listed byte
              arrays.

      @dev 6. Let d be your secret key. Compute s = (k - d * e) % Q. Add Q to
              it, if it's negative. This is your signature. (d is your secret
              key.)
      **************************************************************************
      @dev TO VERIFY A SIGNATURE

      @dev Given a signature (s, e) of msgHash, constructed as above, compute
      S=e*PK+s*generator in the secp256k1 group law, and then the ethereum
      address of S, as described in step 4. Call that
      nonceTimesGeneratorAddress. Then call the verifySignature method as:

      @dev    verifySignature(PKx, PKyp, s, msgHash,
                              nonceTimesGeneratorAddress)
      **************************************************************************
      @dev This signging scheme deviates slightly from the classical Schnorr
      signature, in that the address of k*g is used in place of k*g itself,
      both when calculating e and when verifying sum S as described in the
      verification paragraph above. This reduces the difficulty of
      brute-forcing a signature by trying random secp256k1 points in place of
      k*g in the signature verification process from 256 bits to 160 bits.
      However, the difficulty of cracking the public key using "baby-step,
      giant-step" is only 128 bits, so this weakening constitutes no compromise
      in the security of the signatures or the key.

      @dev The constraint signingPubKeyX < HALF_Q comes from Eq. (281), p. 24
      of Yellow Paper version 78d7b9a. ecrecover only accepts "s" inputs less
      than HALF_Q, to protect against a signature- malleability vulnerability in
      ECDSA. Schnorr does not have this vulnerability, but we must account for
      ecrecover's defense anyway. And since we are abusing ecrecover by putting
      signingPubKeyX in ecrecover's "s" argument the constraint applies to
      signingPubKeyX, even though it represents a value in the base field, and
      has no natural relationship to the order of the curve's cyclic group.
      **************************************************************************
      @param msgHash is a 256-bit hash of the message being signed.
      @param signature is the actual signature, described as s in the above
             instructions.
      @param signingPubKeyX is the x ordinate of the public key. This must be
             less than HALF_Q.
      @param pubKeyYParity is 0 if the y ordinate of the public key is even, 1
             if it's odd.
      @param nonceTimesGeneratorAddress is the ethereum address of k*g in the
             above instructions
      **************************************************************************
      @return True if passed a valid signature, false otherwise. */

    function verifySignature(
        uint256 msgHash,
        uint256 signature,
        uint256 signingPubKeyX,
        uint8 pubKeyYParity,
        address nonceTimesGeneratorAddress
    ) internal pure returns (bool) {
        require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
        // Avoid signature malleability from multiple representations for ℤ/Qℤ elts
        require(signature < Q, "Sig must be reduced modulo Q");

        // Forbid trivial inputs, to avoid ecrecover edge cases. The main thing to
        // avoid is something which causes ecrecover to return 0x0: then trivial
        // signatures could be constructed with the nonceTimesGeneratorAddress input
        // set to 0x0.
        //
        // solium-disable-next-line indentation
        require(
            nonceTimesGeneratorAddress != address(0) && signingPubKeyX > 0 && signature > 0 && msgHash > 0,
            "No zero inputs allowed"
        );

        uint256 msgChallenge = uint256(
            keccak256(abi.encodePacked(signingPubKeyX, pubKeyYParity, msgHash, nonceTimesGeneratorAddress))
        );

        // Verify msgChallenge * signingPubKey + signature * generator ==
        //        nonce * generator
        //
        // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
        // The point corresponding to the address returned by
        // ecrecover(-s*r,v,r,e*r) is (r⁻¹ mod Q)*(e*r*R-(-s)*r*g)=e*R+s*g, where R
        // is the (v,r) point. See https://crypto.stackexchange.com/a/18106
        //
        // solium-disable-next-line indentation
        address recoveredAddress = ecrecover(
            // solium-disable-next-line zeppelin/no-arithmetic-operations
            bytes32(Q - mulmod(signingPubKeyX, signature, Q)),
            // https://ethereum.github.io/yellowpaper/paper.pdf p. 24, "The
            // value 27 represents an even y value and 28 represents an odd
            // y value."
            (pubKeyYParity == 0) ? 27 : 28,
            bytes32(signingPubKeyX),
            bytes32(mulmod(msgChallenge, signingPubKeyX, Q))
        );
        require(recoveredAddress != address(0), "Schnorr: recoveredAddress is 0");

        return nonceTimesGeneratorAddress == recoveredAddress;
    }

    function verifySigningKeyX(uint256 signingPubKeyX) internal pure {
        require(signingPubKeyX < HALF_Q, "Public-key x >= HALF_Q");
    }
}

pragma solidity ^0.8.0;

import "IShared.sol";

/**
 * @title    Shared contract
 * @notice   Holds constants and modifiers that are used in multiple contracts
 * @dev      It would be nice if this could be a library, but modifiers can't be exported :(
 */

abstract contract Shared is IShared {
    /// @dev The address used to indicate whether transfer should send native or a token
    address internal constant _NATIVE_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant _ZERO_ADDR = address(0);
    bytes32 internal constant _NULL = "";
    uint256 internal constant _E_18 = 1e18;

    /// @dev    Checks that a uint isn't zero/empty
    modifier nzUint(uint256 u) {
        require(u != 0, "Shared: uint input is empty");
        _;
    }

    /// @dev    Checks that an address isn't zero/empty
    modifier nzAddr(address a) {
        require(a != _ZERO_ADDR, "Shared: address input is empty");
        _;
    }

    /// @dev    Checks that a bytes32 isn't zero/empty
    modifier nzBytes32(bytes32 b) {
        require(b != _NULL, "Shared: bytes32 input is empty");
        _;
    }

    /// @dev    Checks that the pubKeyX is populated
    modifier nzKey(Key memory key) {
        require(key.pubKeyX != 0, "Shared: pubKeyX is empty");
        _;
    }
}