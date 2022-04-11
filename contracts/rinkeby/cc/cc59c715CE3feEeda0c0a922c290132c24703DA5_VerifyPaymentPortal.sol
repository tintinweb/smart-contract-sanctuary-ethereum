// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @dev The scale of all fixed point math. This is adopting the conventions of
/// both ETH (wei) and most ERC20 tokens, so is hopefully uncontroversial.
uint256 constant FP_DECIMALS = 18;
/// @dev The number `1` in the standard fixed point math scaling. Most of the
/// differences between fixed point math and regular math is multiplying or
/// dividing by `ONE` after the appropriate scaling has been applied.
uint256 constant FP_ONE = 10**FP_DECIMALS;

/// @title FixedPointMath
/// @notice Sometimes we want to do math with decimal values but all we have
/// are integers, typically uint256 integers. Floats are very complex so we
/// don't attempt to simulate them. Instead we provide a standard definition of
/// "one" as 10 ** 18 and scale everything up/down to this as fixed point math.
/// Overflows are errors as per Solidity.
library FixedPointMath {
    /// Scale a fixed point decimal of some scale factor to match `DECIMALS`.
    /// @param a_ Some fixed point decimal value.
    /// @param aDecimals_ The number of fixed decimals of `a_`.
    /// @return `a_` scaled to match `DECIMALS`.
    function scale18(uint256 a_, uint256 aDecimals_)
        internal
        pure
        returns (uint256)
    {
        if (FP_DECIMALS == aDecimals_) {
            return a_;
        } else if (FP_DECIMALS > aDecimals_) {
            return a_ * 10**(FP_DECIMALS - aDecimals_);
        } else {
            return a_ / 10**(aDecimals_ - FP_DECIMALS);
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` to some other scale.
    /// @param a_ A `DECIMALS` fixed point decimals.
    /// @param targetDecimals_ The new scale of `a_`.
    /// @return `a_` rescaled from `DECIMALS` to `targetDecimals_`.
    function scaleN(uint256 a_, uint256 targetDecimals_)
        internal
        pure
        returns (uint256)
    {
        if (targetDecimals_ == FP_DECIMALS) {
            return a_;
        } else if (FP_DECIMALS > targetDecimals_) {
            return a_ / 10**(FP_DECIMALS - targetDecimals_);
        } else {
            return a_ * 10**(targetDecimals_ - FP_DECIMALS);
        }
    }

    /// Scale a fixed point up or down by `scaleBy_` orders of magnitude.
    /// The caller MUST ensure the end result matches `DECIMALS` if other
    /// functions in this library are to work correctly.
    /// Notably `scaleBy` is a SIGNED integer so scaling down by negative OOMS
    /// is supported.
    /// @param a_ Some integer of any scale.
    /// @param scaleBy_ OOMs to scale `a_` up or down by.
    /// @return `a_` rescaled according to `scaleBy_`.
    function scaleBy(uint256 a_, int8 scaleBy_)
        internal
        pure
        returns (uint256)
    {
        if (scaleBy_ == 0) {
            return a_;
        } else if (scaleBy_ > 0) {
            return a_ * 10**uint8(scaleBy_);
        } else {
            return a_ / 10**(~uint8(scaleBy_) + 1);
        }
    }

    /// Fixed point multiplication in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return `a_` multiplied by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointMul(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        return (a_ * b_) / FP_ONE;
    }

    /// Fixed point division in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return `a_` divided by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointDiv(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        return (a_ * FP_ONE) / b_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of
  data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
    error WriteError();

    /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
    function write(bytes memory _data) internal returns (address pointer) {
        // Append 00 to _data so contract can't be called
        // Build init code
        bytes memory code = Bytecode.creationCodeFor(
            abi.encodePacked(hex"00", _data)
        );

        // Deploy contract using create
        assembly {
            pointer := create(0, add(code, 32), mload(code))
        }

        // Address MUST be non-zero
        if (pointer == address(0)) revert WriteError();
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first
    byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
    function read(address _pointer) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first
    byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
    function read(address _pointer, uint256 _start)
        internal
        view
        returns (bytes memory)
    {
        return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first
    byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
    function read(
        address _pointer,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

library Bytecode {
    error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

    /**
    @notice Generate a creation code that results on a contract with `_code` as
    bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
    function creationCodeFor(bytes memory _code)
        internal
        pure
        returns (bytes memory)
    {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

        return
            abi.encodePacked(
                hex"63",
                uint32(_code.length),
                hex"80_60_0E_60_00_39_60_00_F3",
                _code
            );
    }

    /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }

    /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
    function codeAt(
        address _addr,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory oCode) {
        uint256 csize = codeSize(_addr);
        if (csize == 0) return bytes("");

        if (_start > csize) return bytes("");
        if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

        unchecked {
            uint256 reqSize = _end - _start;
            uint256 maxSize = csize - _start;

            uint256 size = maxSize < reqSize ? maxSize : reqSize;

            assembly {
                // allocate output byte array - this could also be done without
                // assembly
                // by using o_code = new bytes(size)
                oCode := mload(0x40)
                // new "memory end" including padding
                mstore(
                    0x40,
                    add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f)))
                )
                // store length in memory
                mstore(oCode, size)
                // actually retrieve the code, this needs assembly
                extcodecopy(_addr, add(oCode, 0x20), _start, size)
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {Evidence} from "./Verify.sol";

/// Deployers of `Verify` contracts (e.g. via `VerifyFactory`) may want to
/// apply additional processing and/or restrictions to each of the basic
/// verification actions. Examples may be reading from onchain state or
/// requiring token transfers to complete before allowing an add/approve to
/// complete successfully. The reason this is an interface rather than
/// implementors extending `Verify` directly is that it allows for more
/// implementations to sit under a single `VerifyFactory` which in turn allows
/// a more readily composed ecosystem of verified accounts.
///
/// There's no reentrancy concerns for external calls from the `Verify`
/// contract to the `IVerifyCallback` contract because:
/// - All the callbacks happen after state changes in `Verify`
/// - All `Verify` actions are bound to the authority of the `msg.sender`
/// The `IVerifyCallback` contract can and should rollback transactions if
/// their restrictions/processing requirements are not met, but otherwise have
/// no more authority over the `Verify` state than anon users.
///
/// The security model for platforms consuming `Verify` contracts is that they
/// should index or otherwise filter children from the `VerifyFactory` down to
/// those that also set a supported `IVerifyCallback` contract. The factory is
/// completely agnostic to callback concerns and doesn't even require that a
/// callback contract be set at all.
interface IVerifyCallback {
    /// Additional processing after an address has been added.
    /// SHOULD revert/rollback transactions if processing fails.
    /// @param adder_ The `msg.sender` in the `add`. Will be the addee.
    /// @param evidence_ The evidence associated with the add.
    function afterAdd(address adder_, Evidence calldata evidence_) external;

    /// Additional processing after a batch of approvals.
    /// SHOULD revert/rollback transactions if processing fails.
    /// @param approver_ The `msg.sender` that authorized the approvals.
    /// @param evidences_ All evidences associated with the approvals.
    function afterApprove(address approver_, Evidence[] calldata evidences_)
        external;

    /// Additional processing after a batch of bannings.
    /// SHOULD revert/rollback transactions if processing fails.
    /// @param banner_ The `msg.sender` that authorized the bannings.
    /// @param evidences_ All evidences associated with the bannings.
    function afterBan(address banner_, Evidence[] calldata evidences_) external;

    /// Additional processing after a batch of removals.
    /// SHOULD revert/rollback transactions if processing fails.
    /// @param remover_ The `msg.sender` that authorized the removals.
    /// @param evidences_ All evidences associated with the removals.
    function afterRemove(address remover_, Evidence[] calldata evidences_)
        external;
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "./IVerifyCallback.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/VerifyConstants.sol";

/// Records the block a verify session reaches each status.
/// If a status is not reached it is left as UNINITIALIZED, i.e. 0xFFFFFFFF.
/// Most accounts will never be banned so most accounts will never reach every
/// status, which is a good thing.
/// @param addedSince Block the address was added else 0xFFFFFFFF.
/// @param approvedSince Block the address was approved else 0xFFFFFFFF.
/// @param bannedSince Block the address was banned else 0xFFFFFFFF.
struct State {
    uint32 addedSince;
    uint32 approvedSince;
    uint32 bannedSince;
}

/// Structure of arbitrary evidence to support any action taken.
/// Priviledged roles are expected to provide evidence just as applicants as an
/// audit trail will be preserved permanently in the logs.
/// @param account The account this evidence is relevant to.
/// @param data Arbitrary bytes representing evidence. MAY be e.g. a reference
/// to a sufficiently decentralised external system such as an IPFS hash.
struct Evidence {
    address account;
    bytes data;
}

/// Config to initialize a Verify contract with.
/// @param admin The address to ASSIGN ALL ADMIN ROLES to initially. This
/// address is free and encouraged to delegate fine grained permissions to
/// many other sub-admin addresses, then revoke it's own "root" access.
/// @param callback The address of the `IVerifyCallback` contract if it exists.
/// MAY be `address(0)` to signify that callbacks should NOT run.
struct VerifyConfig {
    address admin;
    address callback;
}

/// @title Verify
/// Trust-minimised contract to record the state of some verification process.
/// When some off-chain identity is to be reified on chain there is inherently
/// some multi-party, multi-faceted trust relationship. For example, the DID
/// (Decentralized Identifiers) specification from W3C outlines that the
/// controller and the subject of an identity are two different entities.
///
/// This is because self-identification is always problematic to the point of
/// being uselessly unbelievable.
///
/// For example, I can simply say "I am the queen of England" and what
/// onchain mechanism could possibly check, let alone stop me?
/// The same problem exists in any situation where some priviledge or right is
/// associated with identity. Consider passports, driver's licenses,
/// celebrity status, age, health, accredited investor, social media account,
/// etc. etc.
///
/// Typically crypto can't and doesn't want to deal with this issue. The usual
/// scenario is that some system demands personal information, which leads to:
///
/// - Data breaches that put individual's safety at risk. Consider the December
///   2020 leak from Ledger that dumped 270 000 home addresses and phone
///   numbers, and another million emails, of hardware wallet owners on a
///   public forum.
/// - Discriminatory access, undermining an individual's self-sovereign right
///   to run a full node, self-host a GUI and broadcast transactions onchain.
///   Consider the dydx airdrop of 2021 where metadata about a user's access
///   patterns logged on a server were used to deny access to presumed
///   Americans over regulatory fears.
/// - An entrenched supply chain of centralized actors from regulators, to
///   government databases, through KYC corporations, platforms, etc. each of
///   which holds an effective monopoly over, and ability to manipulate user's
///   "own" identity.
///
/// These examples and others are completely antithetical to and undermine the
/// safety of an opt-in, permissionless system based on pseudonomous actors
/// self-signing actions into a shared space.
///
/// That said, one can hardly expect a permissionless pseudonomous system
/// founded on asynchronous value transfers to succeed without at least some
/// concept of curation and reputation.
///
/// Anon, will you invest YOUR money in anon's project?
///
/// Clearly for every defi blue chip there are 10 000 scams and nothing onchain
/// can stop a scam, this MUST happen at the social layer.
///
/// Rain protocol is agnostic to how this verification happens. A government
/// regulator is going to want a government issued ID cross-referenced against
/// international sanctions. A fan of some social media influencer wants to
/// see a verified account on that platform. An open source software project
/// should show a github profile. A security token may need evidence from an
/// accountant showing accredited investor status. There are so many ways in
/// which BOTH sides of a fundraise may need to verify something about
/// themselves to each other via a THIRD PARTY that Rain cannot assume much.
///
/// The trust model and process for Rain verification is:
///
/// - There are many `Verify` contracts, each represents a specific
///   verification method with a (hopefully large) set of possible reviewers.
/// - The verifyee compiles some evidence that can be referenced in some
///   relevant system. It could be a session ID in a KYC provider's database or
///   a tweet from a verified account, etc. The evidence is passed to the
///   `Verify` contract as raw bytes so it is opaque onchain, but visible as an
///   event to verifiers.
/// - The verifyee calls `add` _for themselves_ to initialize their state and
///   emit the evidence for their account, after which they _cannot change_
///   their submission without appealing to someone who can remove. This costs
///   gas, so why don't we simply ask the user to sign something and have an
///   approver verify the signed data? Because we want to leverage both the
///   censorship resistance and asynchronous nature of the underlying
///   blockchain. Assuming there are N possible approvers, we want ANY 1 of
///   those N approvers to be able to review and approve an application. If the
///   user is forced to submit their application directly to one SPECIFIC
///   approver we lose this property. In the gasless model the user must then
///   rely on their specific approver both being online and not to censor the
///   request. It's also possible that many accounts add the same evidence,
///   after all it will be public in the event logs, so it is important for
///   approvers to verify the PAIRING between account and evidence.
/// - ANY account with the `APPROVER` role can review the evidence by
///   inspecting the event logs. IF the evidence is valid then the `approve`
///   function should be called by the approver.
/// - ANY account with the `BANNER` role can veto either an add OR a prior
///   approval. In the case of a false positive, i.e. where an account was
///   mistakenly approved, an appeal can be made to a banner to update the
///   status. Bad accounts SHOULD BE BANNED NOT REMOVED. When an account is
///   removed, its onchain state is once again open for the attacker to
///   resubmit new fraudulent evidence and potentially be reapproved.
///   Once an account is banned, any attempt by the account holder to change
///   their status, or an approver to approve will be rejected. Downstream
///   consumers of a `State` MUST check for an existing ban.
///   - ANY account with the `REMOVER` role can scrub the `State` from an
///   account. Of course, this is a blockchain so the state changes are all
///   still visible to full nodes and indexers in historical data, in both the
///   onchain history and the event logs for each state change. This allows an
///   account to appeal to a remover in the case of a MISTAKEN BAN or also in
///   the case of a MISTAKEN ADD (e.g. mistake in evidence), effecting a
///   "hard reset" at the contract storage level.
///
/// Banning some account with an invalid session is NOT required. It is
/// harmless for an added session to remain as `Status.Added` indefinitely.
/// For as long as no approver decides to approve some invalid added session it
/// MUST be treated as equivalent to a ban by downstream contracts. This is
/// important so that admins are only required to spend gas on useful actions.
///
/// In addition to `Approve`, `Ban`, `Remove` there are corresponding events
/// `RequestApprove`, `RequestBan`, `RequestRemove` that allow for admins to be
/// notified that some new evidence must be considered that may lead to each
/// action. `RequestApprove` is automatically submitted as part of the `add`
/// call, but `RequestBan` and `RequestRemove` must be manually called
///
/// Rain uses standard Open Zeppelin `AccessControl` and is agnostic to how the
/// approver/remover/banner roles and associated admin roles are managed.
/// Ideally the more credibly neutral qualified parties assigend to each role
/// for each `Verify` contract the better. This improves the censorship
/// resistance of the verification process and the responsiveness of the
/// end-user experience.
///
/// Ideally the admin account assigned at deployment would renounce their admin
/// rights after establishing a more granular and appropriate set of accounts
/// with each specific role.
contract Verify is AccessControl, Initializable {
    /// Any state never held is UNINITIALIZED.
    /// Note that as per default evm an unset state is 0 so always check the
    /// `addedSince` block on a `State` before trusting an equality check on
    /// any other block number.
    /// (i.e. removed or never added)
    uint32 private constant UNINITIALIZED = type(uint32).max;

    /// Emitted when the `Verify` contract is initialized.
    event Initialize(address sender, VerifyConfig config);

    /// Emitted when evidence is first submitted to approve an account.
    /// The requestor is always the `msg.sender` of the user calling `add`.
    /// @param sender The `msg.sender` that submitted its own evidence.
    /// @param evidence The evidence to support an approval.
    /// NOT written to contract storage.
    event RequestApprove(address sender, Evidence evidence);
    /// Emitted when a previously added account is approved.
    /// @param sender The `msg.sender` that approved `account`.
    /// @param evidence The approval data.
    event Approve(address sender, Evidence evidence);

    /// Currently approved accounts can request that any account be banned.
    /// The requestor is expected to provide supporting data for the ban.
    /// The requestor MAY themselves be banned if vexatious.
    /// @param sender The `msg.sender` requesting a ban of `account`.
    /// @param evidence Account + data the `requestor` feels will strengthen
    /// its case for the ban. NOT written to contract storage.
    event RequestBan(address sender, Evidence evidence);
    /// Emitted when an added or approved account is banned.
    /// @param sender The `msg.sender` that banned `account`.
    /// @param evidence Account + the evidence to support a ban.
    /// NOT written to contract storage.
    event Ban(address sender, Evidence evidence);

    /// Currently approved accounts can request that any account be removed.
    /// The requestor is expected to provide supporting data for the removal.
    /// The requestor MAY themselves be banned if vexatious.
    /// @param sender The `msg.sender` requesting a removal of `account`.
    /// @param evidence `Evidence` to justify a removal.
    event RequestRemove(address sender, Evidence evidence);
    /// Emitted when an account is scrubbed from blockchain state.
    /// Historical logs still visible offchain of course.
    /// @param sender The `msg.sender` that removed `account`.
    /// @param evidence `Evidence` to justify the removal.
    event Remove(address sender, Evidence evidence);

    /// Admin role for `APPROVER`.
    bytes32 public constant APPROVER_ADMIN = keccak256("APPROVER_ADMIN");
    /// Role for `APPROVER`.
    bytes32 public constant APPROVER = keccak256("APPROVER");

    /// Admin role for `REMOVER`.
    bytes32 public constant REMOVER_ADMIN = keccak256("REMOVER_ADMIN");
    /// Role for `REMOVER`.
    bytes32 public constant REMOVER = keccak256("REMOVER");

    /// Admin role for `BANNER`.
    bytes32 public constant BANNER_ADMIN = keccak256("BANNER_ADMIN");
    /// Role for `BANNER`.
    bytes32 public constant BANNER = keccak256("BANNER");

    /// Account => State
    mapping(address => State) private states;

    /// Optional IVerifyCallback contract.
    /// MAY be address 0.
    IVerifyCallback public callback = IVerifyCallback(address(0));

    /// Initializes the `Verify` contract e.g. as cloned by a factory.
    /// @param config_ The config required to initialize the contract.
    function initialize(VerifyConfig calldata config_) external initializer {
        require(config_.admin != address(0), "0_ACCOUNT");

        // `APPROVER_ADMIN` can admin each other in addition to
        // `APPROVER` addresses underneath.
        _setRoleAdmin(APPROVER_ADMIN, APPROVER_ADMIN);
        _setRoleAdmin(APPROVER, APPROVER_ADMIN);

        // `REMOVER_ADMIN` can admin each other in addition to
        // `REMOVER` addresses underneath.
        _setRoleAdmin(REMOVER_ADMIN, REMOVER_ADMIN);
        _setRoleAdmin(REMOVER, REMOVER_ADMIN);

        // `BANNER_ADMIN` can admin each other in addition to
        // `BANNER` addresses underneath.
        _setRoleAdmin(BANNER_ADMIN, BANNER_ADMIN);
        _setRoleAdmin(BANNER, BANNER_ADMIN);

        // It is STRONGLY RECOMMENDED that the `admin_` delegates specific
        // admin roles then revokes the `X_ADMIN` roles. From themselves.
        // It is ALSO RECOMMENDED that each of the sub-`X_ADMIN` roles revokes
        // their admin rights once sufficient approvers/removers/banners have
        // been assigned, if possible. Admins can instantly/atomically assign
        // and revoke admin priviledges from each other, so a compromised key
        // can irreperably damage a `Verify` contract instance.
        _grantRole(APPROVER_ADMIN, config_.admin);
        _grantRole(REMOVER_ADMIN, config_.admin);
        _grantRole(BANNER_ADMIN, config_.admin);

        callback = IVerifyCallback(config_.callback);

        emit Initialize(msg.sender, config_);
    }

    /// Typed accessor into states.
    /// @param account_ The account to return the current `State` for.
    function state(address account_) external view returns (State memory) {
        return states[account_];
    }

    /// Derives a single `Status` from a `State` and a reference block number.
    /// @param state_ The raw `State` to reduce into a `Status`.
    /// @param blockNumber_ The block number to compare `State` against.
    function statusAtBlock(State memory state_, uint256 blockNumber_)
        public
        pure
        returns (uint256)
    {
        // The state hasn't even been added so is picking up block zero as the
        // evm fallback value. In this case if we checked other blocks using
        // a `<=` equality they would incorrectly return `true` always due to
        // also having a `0` fallback value.
        // Using `< 1` here to silence slither.
        if (state_.addedSince < 1) {
            return VerifyConstants.STATUS_NIL;
        }
        // Banned takes priority over everything.
        else if (state_.bannedSince <= blockNumber_) {
            return VerifyConstants.STATUS_BANNED;
        }
        // Approved takes priority over added.
        else if (state_.approvedSince <= blockNumber_) {
            return VerifyConstants.STATUS_APPROVED;
        }
        // Added is lowest priority.
        else if (state_.addedSince <= blockNumber_) {
            return VerifyConstants.STATUS_ADDED;
        }
        // The `addedSince` block is after `blockNumber_` so `Status` is nil
        // relative to `blockNumber_`.
        else {
            return VerifyConstants.STATUS_NIL;
        }
    }

    /// Requires that `msg.sender` is approved as at the current block.
    modifier onlyApproved() {
        require(
            statusAtBlock(states[msg.sender], block.number) ==
                VerifyConstants.STATUS_APPROVED,
            "ONLY_APPROVED"
        );
        _;
    }

    /// @dev Builds a new `State` for use by `add` and `approve`.
    function newState() private view returns (State memory) {
        return State(uint32(block.number), UNINITIALIZED, UNINITIALIZED);
    }

    /// An account adds their own verification evidence.
    /// Internally `msg.sender` is used; delegated `add` is not supported.
    /// @param data_ The evidence to support approving the `msg.sender`.
    function add(bytes calldata data_) external {
        State memory state_ = states[msg.sender];
        uint256 currentStatus_ = statusAtBlock(state_, block.number);
        require(
            currentStatus_ != VerifyConstants.STATUS_APPROVED &&
                currentStatus_ != VerifyConstants.STATUS_BANNED,
            "ALREADY_EXISTS"
        );
        // An account that hasn't already been added need a new state.
        // If an account has already been added but not approved or banned
        // they can emit many `RequestApprove` events without changing
        // their state. This facilitates multi-step workflows for the KYC
        // provider, e.g. to implement a commit+reveal scheme or simply
        // request additional evidence from the applicant before final
        // verdict.
        if (currentStatus_ == VerifyConstants.STATUS_NIL) {
            states[msg.sender] = newState();
        }
        Evidence memory evidence_ = Evidence(msg.sender, data_);
        emit RequestApprove(msg.sender, evidence_);

        // Call the `afterAdd_` hook to allow inheriting contracts to enforce
        // requirements.
        // The inheriting contract MUST `require` or otherwise enforce its
        // needs to rollback a bad add.
        if (address(callback) != address(0)) {
            callback.afterAdd(msg.sender, evidence_);
        }
    }

    /// An `APPROVER` can review added evidence and approve accounts.
    /// Typically many approvals would be submitted in a single call which is
    /// more convenient and gas efficient than sending individual transactions
    /// for every approval. However, as there are many individual agents
    /// acting concurrently and independently this requires that the approval
    /// process be infallible so that no individual approval can rollback the
    /// entire batch due to the actions of some other approver/banner. It is
    /// possible to approve an already approved or banned account. The
    /// `Approve` event will always emit but the approved block will only be
    /// set if it was previously uninitialized. A banned account will always
    /// be seen as banned when calling `statusAtBlock` regardless of the
    /// approval block, even if the approval is more recent than the ban. The
    /// only way to reset a ban is to remove and reapprove the account.
    /// @param evidences_ All evidence for all approvals.
    function approve(Evidence[] calldata evidences_)
        external
        onlyRole(APPROVER)
    {
        uint256 dirty_ = 0;
        State memory state_;
        for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
            state_ = states[evidences_[i_].account];
            // If the account hasn't been added an approver can still add and
            // approve it on their behalf.
            if (state_.addedSince < 1) {
                state_ = newState();
                dirty_ = 1;
            }
            // If the account hasn't been approved we approve it. As there are
            // many approvers operating independently and concurrently we do
            // NOT `require` the approval be unique, but we also do NOT change
            // the block as the oldest approval is most important. However we
            // emit an event for every approval even if the state does not
            // change.
            // It is possible to approve a banned account but `statusAtBlock`
            // will ignore the approval time for any banned account and use the
            // banned block only.
            if (state_.approvedSince == UNINITIALIZED) {
                state_.approvedSince = uint32(block.number);
                dirty_ = 1;
            }

            if (dirty_ > 0) {
                states[evidences_[i_].account] = state_;
                dirty_ = 0;
            }

            // Always emit an `Approve` event even if we didn't write state.
            // This ensures that supporting evidence hits the logs for offchain
            // review.
            emit Approve(msg.sender, evidences_[i_]);
        }
        if (address(callback) != address(0)) {
            callback.afterApprove(msg.sender, evidences_);
        }
    }

    /// Any approved address can request some other address be approved.
    /// Frivolous requestors SHOULD expect to find themselves banned.
    /// @param evidences_ Array of evidences to request approvals for.
    function requestApprove(Evidence[] calldata evidences_)
        external
        onlyApproved
    {
        for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
            emit RequestApprove(msg.sender, evidences_[i_]);
        }
    }

    /// A `BANNER` can ban an added OR approved account.
    /// @param evidences_ All evidence appropriate for all bans.
    function ban(Evidence[] calldata evidences_) external onlyRole(BANNER) {
        uint256 dirty_ = 0;
        State memory state_;
        for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
            state_ = states[evidences_[i_].account];

            // There is no requirement that an account be formally added before
            // it is banned. For example some fraud may be detected in an
            // affiliated `Verify` contract and the evidence can be used to ban
            // the same address in the current contract.
            if (state_.addedSince < 1) {
                state_ = newState();
                dirty_ = 1;
            }
            // Respect prior bans by leaving the older block number in place.
            if (state_.bannedSince == UNINITIALIZED) {
                state_.bannedSince = uint32(block.number);
                dirty_ = 1;
            }

            if (dirty_ > 0) {
                states[evidences_[i_].account] = state_;
                dirty_ = 0;
            }

            // Always emit a `Ban` event even if we didn't write state. This
            // ensures that supporting evidence hits the logs for offchain
            // review.
            emit Ban(msg.sender, evidences_[i_]);
        }

        if (address(callback) != address(0)) {
            callback.afterBan(msg.sender, evidences_);
        }
    }

    /// Any approved address can request some other address be banned.
    /// Frivolous requestors SHOULD expect to find themselves banned.
    /// @param evidences_ Array of evidences to request banning for.
    function requestBan(Evidence[] calldata evidences_) external onlyApproved {
        for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
            emit RequestBan(msg.sender, evidences_[i_]);
        }
    }

    /// A `REMOVER` can scrub state mapping from an account.
    /// A malicious account MUST be banned rather than removed.
    /// Removal is useful to reset the whole process in case of some mistake.
    /// @param evidences_ All evidence to suppor the removal.
    function remove(Evidence[] calldata evidences_) external onlyRole(REMOVER) {
        State memory state_;
        for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
            state_ = states[evidences_[i_].account];
            if (state_.addedSince > 0) {
                delete (states[evidences_[i_].account]);
            }
            emit Remove(msg.sender, evidences_[i_]);
        }

        if (address(callback) != address(0)) {
            callback.afterRemove(msg.sender, evidences_);
        }
    }

    /// Any approved address can request some other address be removed.
    /// Frivolous requestors SHOULD expect to find themselves banned.
    /// @param evidences_ Array of evidences to request removal of.
    function requestRemove(Evidence[] calldata evidences_)
        external
        onlyApproved
    {
        for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
            emit RequestRemove(msg.sender, evidences_[i_]);
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// Summary statuses derived from a `State` by comparing the `Since` times
/// against a specific block number.
library VerifyConstants {
    /// Account has not interacted with the system yet or was removed.
    uint256 internal constant STATUS_NIL = 0;
    /// Account has added evidence for themselves.
    uint256 internal constant STATUS_ADDED = 1;
    /// Approver has reviewed added/approve evidence and approved the account.
    uint256 internal constant STATUS_APPROVED = 2;
    /// Banner has reviewed a request to ban an account and banned it.
    uint256 internal constant STATUS_BANNED = 3;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@beehiveinnovation/rain-protocol/contracts/math/FixedPointMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @dev USDT token contract is already deployed and can never change its
/// decimals value.
uint256 constant USDT_DECIMALS = 6;

/// @dev 0.3% as FixedPointMath.DECIMALS. If the Uniswap fee ever changes this
/// constant should be moved to an immutable value.
/// Compile time constant equivalent to `FixedPointMath.scale18(997, 3)`.
uint256 constant UNISWAP_FEE = 997 * 10**(FP_DECIMALS - 3);

/// @title ALBTOracle
/// @notice Chainlink AggregatorV3Interface defines a robust interface into
/// oracle prices that is simultaneously under and overpowered for our needs.
/// All we need is a single 18 fixed point decimal price value representing the
/// conversion of USDT to ALBT for some USDT amount. We do NOT need the round
/// data returned by Chainlink but we do need the decimals reported by the feed
/// to be scaled correctly for standard fixed point math. We also want all our
/// prices to be handled as `uint256` values, not as Chainlink `int256` prices.
contract ALBTOracle {
    using SafeCast for int256;
    using FixedPointMath for uint256;

    /// @dev Chainlink price feed aggregator.
    AggregatorV3Interface private immutable priceFeed;

    /// @param priceFeed_ Address of the Chainlink price feed.
    constructor(address priceFeed_) {
        require(
            priceFeed_ != address(0),
            "ALBTOracle: Price feed address cannot be 0"
        );
        priceFeed = AggregatorV3Interface(priceFeed_);
    }

    /// Calculate the amount of ALBT you will get for an amount of USDT, using
    /// the chainlink price feed.
    /// @param usdtAmount_ USDT amount to calculate ALBT equivalent amount_ of.
    /// USDT amount input is in `USDT_DECIMALS` and ALBT output is standard 18
    /// decimal fixed point ERC20 amount.
    function calculateUSDTtoALBT(uint256 usdtAmount_)
        internal
        view
        returns (uint256)
    {
        (, int256 price_, , , ) = priceFeed.latestRoundData();
        return
            usdtAmount_
                .scale18(USDT_DECIMALS)
                .fixedPointMul(UNISWAP_FEE)
                .fixedPointDiv(
                    price_.toUint256().scale18(priceFeed.decimals())
                );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@beehiveinnovation/rain-protocol/contracts/math/FixedPointMath.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Defines a single share of some payment.
/// Not useful individually but a Share[] can define a list of split payments.
/// The total of all shares in a Share[] must add to `FP_ONE`.
/// @param recipient of this share.
/// @param fractional share for this recipient as an 18 fixed point decimal.
struct Share {
    address recipient;
    uint256 share;
}

/// @title SplitPayment
/// @notice Implements a "push" model of payment across "arbitrary" shares of
/// recipients. "Arbitrary" is in quotes because gas ensures we won't achieve
/// particularly long lists of shares in practise, and statistically the risk
/// of a payment rollback increases as the recipients list becomes longer.
/// For short lists over trusted tokens and recipients this can be a useful
/// construct to easily push out payments inline with other operations.
library SplitPayment {
    using SafeERC20 for IERC20;
    using FixedPointMath for uint256;

    /// Enforces that the passed shares meet standard integrity requirements.
    /// It is best to do these once upon construction/initialization and then
    /// never again. E.g. try to avoid running the integrity checks alonside
    /// every `splitTransfer` call unless the shares really might change every
    /// transfer.
    /// @param shares_ An array of shares to ensure overall integrity of.
    function enforceSharesIntegrity(Share[] memory shares_) internal pure {
        require(shares_.length > 0, "SplitPayment: 0 shares");
        uint256 totalShares_ = 0;
        for (uint256 i_ = 0; i_ < shares_.length; i_++) {
            require(
                shares_[i_].recipient != address(0),
                "SplitPayment: 0 recipient address"
            );
            require(shares_[i_].share > 0, "SplitPayment: 0 share");
            totalShares_ += shares_[i_].share;
        }
        require(
            totalShares_ == FP_ONE,
            "SplitPayment: Shares total is not 10**18"
        );
    }

    /// Processes transfers according to an array of shares.
    /// Does NOT check the integrity of the shares; assumes
    /// `enforceSharesIntegrity` has been run at least once over the inputs.
    /// @param token_ The token to transfer. May be either approved or owned
    /// by the sending contract.
    /// @param from_ The address to send the token. May NOT be the calling
    /// contract if appropriate approvals have been made by the owner.
    /// @param totalAmount_ The total amount to transfer across all shares.
    /// @param shares_ The share splits to spread `totalAmount_` across.
    function splitTransfer(
        address token_,
        address from_,
        uint256 totalAmount_,
        Share[] memory shares_
    ) internal {
        unchecked {
            bool fromThis_ = from_ == address(this);
            for (uint256 i_ = 0; i_ < shares_.length; i_++) {
                // FixedPointMath uses checked math so disallows overflow.
                // Integrity checks disallow `0` shares.
                uint256 amount_ = totalAmount_.fixedPointMul(shares_[i_].share);
                if (fromThis_) {
                    IERC20(token_).safeTransfer(shares_[i_].recipient, amount_);
                } else {
                    IERC20(token_).safeTransferFrom(
                        from_,
                        shares_[i_].recipient,
                        amount_
                    );
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@beehiveinnovation/rain-protocol/contracts/verify/Verify.sol";
import "@beehiveinnovation/rain-protocol/contracts/verify/IVerifyCallback.sol";
import "@beehiveinnovation/rain-protocol/contracts/sstore2/SSTORE2.sol";
import "../payment/SplitPayment.sol";
import "../oracle/ALBTOracle.sol";

/// Payment config shared by ever approver.
/// @param albt The ALBT token contract.
/// @param shares The shares split for all payents as per SplitPayment.
/// @param USDTPrice The per-approval price denominated in USDT. Will be
/// converted to ALBT amount by the oracle.
struct PaymentConfig {
    address albt;
    Share[] shares;
    uint256 USDTPrice;
}

/// Config required to construct the contract.
/// Everything here is deployed immutably so changes imply a new contract.
/// @param paymentConfig PaymentConfig as above.
/// @param priceFeed USDT conversion price feed for ALBT payments.
struct ConstructionConfig {
    PaymentConfig paymentConfig;
    address priceFeed;
}

contract VerifyPaymentPortal is IVerifyCallback, ALBTOracle {
    /// Contract was constructed.
    /// @param sender The `msg.sender` that deployed the contract.
    /// @param config All the construction configuration.
    event Construction(address sender, ConstructionConfig config);

    /// A new ALBT limit has been set for a (potential) approver.
    /// @param sender the `msg.sender`. Does NOT imply the sender can actually
    /// approve anything in any particular `Verify` contract.
    /// @param limit The new ALBT-denominated per-approval cost limit.
    event ALBTLimit(address sender, uint256 limit);

    /// @dev SSTORE2 pointer to the payment config.
    address private immutable paymentConfigPointer;

    /// @dev maximum ALBT denominated cost that approvers will pay per approval.
    mapping(address => uint256) private albtLimits;

    constructor(ConstructionConfig memory config_)
        ALBTOracle(config_.priceFeed)
    {
        require(
            config_.paymentConfig.albt != address(0),
            "VerifyPaymentPortal: Zero token address."
        );
        require(
            config_.paymentConfig.shares[0].recipient ==
                address(type(uint160).max),
            // solhint-disable-next-line max-line-length
            "VerifyPaymentPortal: First share (approvee placeholder) is NOT 0xFF..."
        );
        SplitPayment.enforceSharesIntegrity(config_.paymentConfig.shares);
        paymentConfigPointer = SSTORE2.write(abi.encode(config_.paymentConfig));
        emit Construction(msg.sender, config_);
    }

    /// Anyone can set a limit of how much ALBT they would be willing to pay as
    /// gratuity in `afterApprove`.
    /// Of course, not anyone can actually process an approval so the limit is
    /// hypothetical only. Any attempted payment (e.g. due to unfavourable
    /// exchange rates from the oracle) above this limit will rollback an
    /// approval.
    /// @param limit_ The per-approval ALBT limit.
    function setALBTLimit(uint256 limit_) external {
        albtLimits[msg.sender] = limit_;
        emit ALBTLimit(msg.sender, limit_);
    }

    /// We require that the approver pays each of the approvees as gratuity for
    /// access to the private data required for completion of the KYC process.
    /// Every payment is the same for every approval at the current fx rates.
    /// Every payment is per-approval and subject to the cost limit set by the
    /// approver. The approver MUST set a limit for themselves as the unset
    /// costLimit is zero.
    /// The exchange rates for token/UDST price
    /// @inheritdoc IVerifyCallback
    function afterApprove(address approver_, Evidence[] calldata evidences_)
        external
    {
        PaymentConfig memory paymentConfig_ = abi.decode(
            SSTORE2.read(paymentConfigPointer),
            (PaymentConfig)
        );
        uint256 amount_ = calculateUSDTtoALBT(paymentConfig_.USDTPrice);
        require(
            amount_ <= albtLimits[approver_],
            "VerifyPaymentPortal: Required ALBT exceeds user limit."
        );
        for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
            // Override first share recipient as approved account.
            paymentConfig_.shares[0].recipient = evidences_[i_].account;
            SplitPayment.splitTransfer(
                paymentConfig_.albt,
                approver_,
                amount_,
                paymentConfig_.shares
            );
        }
    }

    /// @inheritdoc IVerifyCallback
    function afterAdd(address, Evidence calldata) external {}

    /// @inheritdoc IVerifyCallback
    function afterBan(address, Evidence[] calldata) external {}

    /// @inheritdoc IVerifyCallback
    function afterRemove(address, Evidence[] calldata) external {}
}