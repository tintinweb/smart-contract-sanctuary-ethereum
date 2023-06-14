// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../globals/IGlobals.sol";
import "../globals/LibGlobals.sol";
import "../tokens/IERC20.sol";
import "../utils/LibAddress.sol";
import "../utils/LibERC20Compat.sol";
import "../utils/LibRawResult.sol";
import "../utils/LibSafeCast.sol";

import "./ITokenDistributor.sol";

/// @notice Creates token distributions for parties.
contract TokenDistributor is ITokenDistributor {
    using LibAddress for address payable;
    using LibERC20Compat for IERC20;
    using LibRawResult for bytes;
    using LibSafeCast for uint256;

    struct DistributionState {
        // The hash of the `DistributionInfo`.
        bytes32 distributionHash;
        // The remaining member supply.
        uint128 remainingMemberSupply;
        // Whether the distribution's feeRecipient has claimed its fee.
        bool wasFeeClaimed;
        // Whether a governance token has claimed its distribution share.
        mapping(uint256 => bool) hasPartyTokenClaimed;
    }

    // Arguments for `_createDistribution()`.
    struct CreateDistributionArgs {
        Party party;
        TokenType tokenType;
        address token;
        uint256 currentTokenBalance;
        address payable feeRecipient;
        uint16 feeBps;
    }

    event EmergencyExecute(address target, bytes data);

    error OnlyPartyDaoError(address notDao, address partyDao);
    error InvalidDistributionInfoError(DistributionInfo info);
    error DistributionAlreadyClaimedByPartyTokenError(uint256 distributionId, uint256 partyTokenId);
    error DistributionFeeAlreadyClaimedError(uint256 distributionId);
    error MustOwnTokenError(address sender, address expectedOwner, uint256 partyTokenId);
    error EmergencyActionsNotAllowedError();
    error InvalidDistributionSupplyError(uint128 supply);
    error OnlyFeeRecipientError(address caller, address feeRecipient);
    error InvalidFeeBpsError(uint16 feeBps);

    // Token address used to indicate a native distribution (i.e. distribution of ETH).
    address private constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice The `Globals` contract storing global configuration values. This contract
    ///         is immutable and it’s address will never change.
    IGlobals public immutable GLOBALS;
    /// @notice Timestamp when the DAO is no longer allowed to call emergency functions.
    uint40 public immutable EMERGENCY_DISABLED_TIMESTAMP;

    /// @notice Last distribution ID for a party.
    mapping(Party => uint256) public lastDistributionIdPerParty;
    /// Last known balance of a token, identified by an ID derived from the token.
    /// Gets lazily updated when creating and claiming a distribution (transfers).
    /// Allows one to simply transfer and call `createDistribution()` without
    /// fussing with allowances.
    mapping(bytes32 => uint256) private _storedBalances;
    // tokenDistributorParty => distributionId => DistributionState
    mapping(Party => mapping(uint256 => DistributionState)) private _distributionStates;

    // msg.sender == DAO
    modifier onlyPartyDao() {
        {
            address partyDao = GLOBALS.getAddress(LibGlobals.GLOBAL_DAO_WALLET);
            if (msg.sender != partyDao) {
                revert OnlyPartyDaoError(msg.sender, partyDao);
            }
        }
        _;
    }

    // emergencyActionsDisabled == false
    modifier onlyIfEmergencyActionsAllowed() {
        if (block.timestamp > EMERGENCY_DISABLED_TIMESTAMP) {
            revert EmergencyActionsNotAllowedError();
        }
        _;
    }

    // Set the `Globals` contract.
    constructor(IGlobals globals, uint40 emergencyDisabledTimestamp) {
        GLOBALS = globals;
        EMERGENCY_DISABLED_TIMESTAMP = emergencyDisabledTimestamp;
    }

    /// @inheritdoc ITokenDistributor
    function createNativeDistribution(
        Party party,
        address payable feeRecipient,
        uint16 feeBps
    ) external payable returns (DistributionInfo memory info) {
        info = _createDistribution(
            CreateDistributionArgs({
                party: party,
                tokenType: TokenType.Native,
                token: NATIVE_TOKEN_ADDRESS,
                currentTokenBalance: address(this).balance,
                feeRecipient: feeRecipient,
                feeBps: feeBps
            })
        );
    }

    /// @inheritdoc ITokenDistributor
    function createErc20Distribution(
        IERC20 token,
        Party party,
        address payable feeRecipient,
        uint16 feeBps
    ) external returns (DistributionInfo memory info) {
        info = _createDistribution(
            CreateDistributionArgs({
                party: party,
                tokenType: TokenType.Erc20,
                token: address(token),
                currentTokenBalance: token.balanceOf(address(this)),
                feeRecipient: feeRecipient,
                feeBps: feeBps
            })
        );
    }

    /// @inheritdoc ITokenDistributor
    function claim(
        DistributionInfo calldata info,
        uint256 partyTokenId
    ) public returns (uint128 amountClaimed) {
        // Caller must own the party token.
        {
            address ownerOfPartyToken = info.party.ownerOf(partyTokenId);
            if (msg.sender != ownerOfPartyToken) {
                revert MustOwnTokenError(msg.sender, ownerOfPartyToken, partyTokenId);
            }
        }
        // DistributionInfo must be correct for this distribution ID.
        DistributionState storage state = _distributionStates[info.party][info.distributionId];
        if (state.distributionHash != _getDistributionHash(info)) {
            revert InvalidDistributionInfoError(info);
        }
        // The partyTokenId must not have claimed its distribution yet.
        if (state.hasPartyTokenClaimed[partyTokenId]) {
            revert DistributionAlreadyClaimedByPartyTokenError(info.distributionId, partyTokenId);
        }
        // Mark the partyTokenId as having claimed their distribution.
        state.hasPartyTokenClaimed[partyTokenId] = true;

        // Compute amount owed to partyTokenId.
        amountClaimed = getClaimAmount(info, partyTokenId);

        // Cap at the remaining member supply. Otherwise a malicious
        // party could drain more than the distribution supply.
        uint128 remainingMemberSupply = state.remainingMemberSupply;
        amountClaimed = amountClaimed > remainingMemberSupply
            ? remainingMemberSupply
            : amountClaimed;
        state.remainingMemberSupply = remainingMemberSupply - amountClaimed;

        // Transfer tokens owed.
        _transfer(info.tokenType, info.token, payable(msg.sender), amountClaimed);
        emit DistributionClaimedByPartyToken(
            info.party,
            partyTokenId,
            msg.sender,
            info.tokenType,
            info.token,
            amountClaimed
        );
    }

    /// @inheritdoc ITokenDistributor
    function claimFee(DistributionInfo calldata info, address payable recipient) public {
        // DistributionInfo must be correct for this distribution ID.
        DistributionState storage state = _distributionStates[info.party][info.distributionId];
        if (state.distributionHash != _getDistributionHash(info)) {
            revert InvalidDistributionInfoError(info);
        }
        // Caller must be the fee recipient.
        if (info.feeRecipient != msg.sender) {
            revert OnlyFeeRecipientError(msg.sender, info.feeRecipient);
        }
        // Must not have claimed the fee yet.
        if (state.wasFeeClaimed) {
            revert DistributionFeeAlreadyClaimedError(info.distributionId);
        }
        // Mark the fee as claimed.
        state.wasFeeClaimed = true;
        // Transfer the tokens owed.
        _transfer(info.tokenType, info.token, recipient, info.fee);
        emit DistributionFeeClaimed(
            info.party,
            info.feeRecipient,
            info.tokenType,
            info.token,
            info.fee
        );
    }

    /// @inheritdoc ITokenDistributor
    function batchClaim(
        DistributionInfo[] calldata infos,
        uint256[] calldata partyTokenIds
    ) external returns (uint128[] memory amountsClaimed) {
        amountsClaimed = new uint128[](infos.length);
        for (uint256 i = 0; i < infos.length; ++i) {
            amountsClaimed[i] = claim(infos[i], partyTokenIds[i]);
        }
    }

    /// @inheritdoc ITokenDistributor
    function batchClaimFee(
        DistributionInfo[] calldata infos,
        address payable[] calldata recipients
    ) external {
        for (uint256 i = 0; i < infos.length; ++i) {
            claimFee(infos[i], recipients[i]);
        }
    }

    /// @inheritdoc ITokenDistributor
    function getClaimAmount(
        DistributionInfo calldata info,
        uint256 partyTokenId
    ) public view returns (uint128) {
        Party party = info.party;

        // Check which method to use for calculating claim amount based on
        // version of Party contract.
        (bool success, bytes memory response) = address(party).staticcall(
            abi.encodeCall(party.VERSION_ID, ())
        );

        // Check the version ID.
        if (success && abi.decode(response, (uint16)) >= 1) {
            uint256 shareOfSupply = ((info.party.getDistributionShareOf(partyTokenId)) * 1e18) /
                info.totalShares;

            return
                // We round up here to prevent dust amounts getting trapped in this contract.
                ((shareOfSupply * info.memberSupply + (1e18 - 1)) / 1e18)
                    .safeCastUint256ToUint128();
        } else {
            // Use method of calculating claim amount for backwards
            // compatibility with older parties where getDistributionShareOf()
            // returned the fraction of the memberSupply partyTokenId is
            // entitled to, scaled by 1e18.
            uint256 shareOfSupply = party.getDistributionShareOf(partyTokenId);

            return
                // We round up here to prevent dust amounts getting trapped in this contract.
                ((shareOfSupply * info.memberSupply + (1e18 - 1)) / 1e18)
                    .safeCastUint256ToUint128();
        }
    }

    /// @inheritdoc ITokenDistributor
    function wasFeeClaimed(Party party, uint256 distributionId) external view returns (bool) {
        return _distributionStates[party][distributionId].wasFeeClaimed;
    }

    /// @inheritdoc ITokenDistributor
    function hasPartyTokenIdClaimed(
        Party party,
        uint256 partyTokenId,
        uint256 distributionId
    ) external view returns (bool) {
        return _distributionStates[party][distributionId].hasPartyTokenClaimed[partyTokenId];
    }

    /// @inheritdoc ITokenDistributor
    function getRemainingMemberSupply(
        Party party,
        uint256 distributionId
    ) external view returns (uint128) {
        return _distributionStates[party][distributionId].remainingMemberSupply;
    }

    /// @notice As the DAO, execute an arbitrary delegatecall from this contract.
    /// @dev Emergency actions must not be revoked for this to work.
    /// @param targetAddress The contract to delegatecall into.
    /// @param targetCallData The data to pass to the call.
    function emergencyExecute(
        address targetAddress,
        bytes calldata targetCallData
    ) external onlyPartyDao onlyIfEmergencyActionsAllowed {
        (bool success, bytes memory res) = targetAddress.delegatecall(targetCallData);
        if (!success) {
            res.rawRevert();
        }
        emit EmergencyExecute(targetAddress, targetCallData);
    }

    function _createDistribution(
        CreateDistributionArgs memory args
    ) private returns (DistributionInfo memory info) {
        if (args.feeBps > 1e4) {
            revert InvalidFeeBpsError(args.feeBps);
        }
        uint128 supply;
        {
            bytes32 balanceId = _getBalanceId(args.tokenType, args.token);
            supply = (args.currentTokenBalance - _storedBalances[balanceId])
                .safeCastUint256ToUint128();
            // Supply must be nonzero.
            if (supply == 0) {
                revert InvalidDistributionSupplyError(supply);
            }
            // Update stored balance.
            _storedBalances[balanceId] = args.currentTokenBalance;
        }

        // Create a distribution.
        uint128 fee = (supply * args.feeBps) / 1e4;
        uint128 memberSupply = supply - fee;

        info = DistributionInfo({
            tokenType: args.tokenType,
            distributionId: ++lastDistributionIdPerParty[args.party],
            token: args.token,
            party: args.party,
            memberSupply: memberSupply,
            feeRecipient: args.feeRecipient,
            fee: fee,
            totalShares: args.party.getGovernanceValues().totalVotingPower
        });
        (
            _distributionStates[args.party][info.distributionId].distributionHash,
            _distributionStates[args.party][info.distributionId].remainingMemberSupply
        ) = (_getDistributionHash(info), memberSupply);
        emit DistributionCreated(args.party, info);
    }

    function _transfer(
        TokenType tokenType,
        address token,
        address payable recipient,
        uint256 amount
    ) private {
        bytes32 balanceId = _getBalanceId(tokenType, token);
        // Reduce stored token balance.
        uint256 storedBalance = _storedBalances[balanceId] - amount;
        // Temporarily set to max as a reentrancy guard. An interesing attack
        // could occur if we didn't do this where an attacker could `claim()` and
        // reenter upon transfer (e.g. in the `tokensToSend` hook of an ERC777) to
        // `createERC20Distribution()`. Since the `balanceOf(address(this))`
        // would not of been updated yet, the supply would be miscalculated and
        // the attacker would create a distribution that essentially steals from
        // the last distribution they were claiming from. Here, we prevent that
        // by causing an arithmetic underflow with the supply calculation if
        // this were to be attempted.
        _storedBalances[balanceId] = type(uint256).max;
        if (tokenType == TokenType.Native) {
            recipient.transferEth(amount);
        } else {
            assert(tokenType == TokenType.Erc20);
            IERC20(token).compatTransfer(recipient, amount);
        }
        _storedBalances[balanceId] = storedBalance;
    }

    function _getDistributionHash(
        DistributionInfo memory info
    ) internal pure returns (bytes32 hash) {
        assembly {
            hash := keccak256(info, 0x100)
        }
    }

    function _getBalanceId(
        TokenType tokenType,
        address token
    ) private pure returns (bytes32 balanceId) {
        if (tokenType == TokenType.Native) {
            return bytes32(uint256(uint160(NATIVE_TOKEN_ADDRESS)));
        }
        assert(tokenType == TokenType.Erc20);
        return bytes32(uint256(uint160(token)));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../utils/Implementation.sol";

// Single registry of global values controlled by multisig.
// See `LibGlobals` for all valid keys.
interface IGlobals {
    function multiSig() external view returns (address);

    function getBytes32(uint256 key) external view returns (bytes32);

    function getUint256(uint256 key) external view returns (uint256);

    function getBool(uint256 key) external view returns (bool);

    function getAddress(uint256 key) external view returns (address);

    function getImplementation(uint256 key) external view returns (Implementation);

    function getIncludesBytes32(uint256 key, bytes32 value) external view returns (bool);

    function getIncludesUint256(uint256 key, uint256 value) external view returns (bool);

    function getIncludesAddress(uint256 key, address value) external view returns (bool);

    function setBytes32(uint256 key, bytes32 value) external;

    function setUint256(uint256 key, uint256 value) external;

    function setBool(uint256 key, bool value) external;

    function setAddress(uint256 key, address value) external;

    function setIncludesBytes32(uint256 key, bytes32 value, bool isIncluded) external;

    function setIncludesUint256(uint256 key, uint256 value, bool isIncluded) external;

    function setIncludesAddress(uint256 key, address value, bool isIncluded) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

// Valid keys in `IGlobals`. Append-only.
library LibGlobals {
    // The Globals commented out below were depreciated in 1.2; factories
    // can now choose the implementation address to deploy and no longer
    // deploy the latest implementation. They will no longer be updated
    // in future releases.
    //
    // See https://github.com/PartyDAO/party-migrations for
    // implementation addresses by release.

    uint256 internal constant GLOBAL_PARTY_IMPL = 1;
    uint256 internal constant GLOBAL_PROPOSAL_ENGINE_IMPL = 2;
    // uint256 internal constant GLOBAL_PARTY_FACTORY = 3;
    uint256 internal constant GLOBAL_GOVERNANCE_NFT_RENDER_IMPL = 4;
    uint256 internal constant GLOBAL_CF_NFT_RENDER_IMPL = 5;
    uint256 internal constant GLOBAL_OS_ZORA_AUCTION_TIMEOUT = 6;
    uint256 internal constant GLOBAL_OS_ZORA_AUCTION_DURATION = 7;
    // uint256 internal constant GLOBAL_AUCTION_CF_IMPL = 8;
    // uint256 internal constant GLOBAL_BUY_CF_IMPL = 9;
    // uint256 internal constant GLOBAL_COLLECTION_BUY_CF_IMPL = 10;
    uint256 internal constant GLOBAL_DAO_WALLET = 11;
    uint256 internal constant GLOBAL_TOKEN_DISTRIBUTOR = 12;
    uint256 internal constant GLOBAL_OPENSEA_CONDUIT_KEY = 13;
    uint256 internal constant GLOBAL_OPENSEA_ZONE = 14;
    uint256 internal constant GLOBAL_PROPOSAL_MAX_CANCEL_DURATION = 15;
    uint256 internal constant GLOBAL_ZORA_MIN_AUCTION_DURATION = 16;
    uint256 internal constant GLOBAL_ZORA_MAX_AUCTION_DURATION = 17;
    uint256 internal constant GLOBAL_ZORA_MAX_AUCTION_TIMEOUT = 18;
    uint256 internal constant GLOBAL_OS_MIN_ORDER_DURATION = 19;
    uint256 internal constant GLOBAL_OS_MAX_ORDER_DURATION = 20;
    uint256 internal constant GLOBAL_DISABLE_PARTY_ACTIONS = 21;
    uint256 internal constant GLOBAL_RENDERER_STORAGE = 22;
    uint256 internal constant GLOBAL_PROPOSAL_MIN_CANCEL_DURATION = 23;
    // uint256 internal constant GLOBAL_ROLLING_AUCTION_CF_IMPL = 24;
    // uint256 internal constant GLOBAL_COLLECTION_BATCH_BUY_CF_IMPL = 25;
    uint256 internal constant GLOBAL_METADATA_REGISTRY = 26;
    // uint256 internal constant GLOBAL_CROWDFUND_FACTORY = 27;
    // uint256 internal constant GLOBAL_INITIAL_ETH_CF_IMPL = 28;
    // uint256 internal constant GLOBAL_RERAISE_ETH_CF_IMPL = 29;
    uint256 internal constant GLOBAL_SEAPORT = 30;
    uint256 internal constant GLOBAL_CONDUIT_CONTROLLER = 31;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Minimal ERC20 interface.
interface IERC20 {
    event Transfer(address indexed owner, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 allowance);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 allowance) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

library LibAddress {
    error EthTransferFailed(address receiver, bytes errData);

    // Transfer ETH with full gas stipend.
    function transferEth(address payable receiver, uint256 amount) internal {
        if (amount == 0) return;

        (bool s, bytes memory r) = receiver.call{ value: amount }("");
        if (!s) {
            revert EthTransferFailed(receiver, r);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../tokens/IERC20.sol";

// Compatibility helpers for ERC20s.
library LibERC20Compat {
    error NotATokenError(IERC20 token);
    error TokenTransferFailedError(IERC20 token, address to, uint256 amount);

    // Perform an `IERC20.transfer()` handling non-compliant implementations.
    function compatTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool s, bytes memory r) = address(token).call(
            abi.encodeCall(IERC20.transfer, (to, amount))
        );
        if (s) {
            if (r.length == 0) {
                uint256 cs;
                assembly {
                    cs := extcodesize(token)
                }
                if (cs == 0) {
                    revert NotATokenError(token);
                }
                return;
            }
            if (abi.decode(r, (bool))) {
                return;
            }
        }
        revert TokenTransferFailedError(token, to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

library LibRawResult {
    // Revert with the data in `b`.
    function rawRevert(bytes memory b) internal pure {
        assembly {
            revert(add(b, 32), mload(b))
        }
    }

    // Return with the data in `b`.
    function rawReturn(bytes memory b) internal pure {
        assembly {
            return(add(b, 32), mload(b))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

library LibSafeCast {
    error Uint256ToUint96CastOutOfRange(uint256 v);
    error Uint256ToInt192CastOutOfRange(uint256 v);
    error Int192ToUint96CastOutOfRange(int192 i192);
    error Uint256ToInt128CastOutOfRangeError(uint256 u256);
    error Uint256ToUint128CastOutOfRangeError(uint256 u256);
    error Uint256ToUint40CastOutOfRangeError(uint256 u256);

    function safeCastUint256ToUint96(uint256 v) internal pure returns (uint96) {
        if (v > uint256(type(uint96).max)) {
            revert Uint256ToUint96CastOutOfRange(v);
        }
        return uint96(v);
    }

    function safeCastUint256ToUint128(uint256 v) internal pure returns (uint128) {
        if (v > uint256(type(uint128).max)) {
            revert Uint256ToUint128CastOutOfRangeError(v);
        }
        return uint128(v);
    }

    function safeCastUint256ToInt192(uint256 v) internal pure returns (int192) {
        if (v > uint256(uint192(type(int192).max))) {
            revert Uint256ToInt192CastOutOfRange(v);
        }
        return int192(uint192(v));
    }

    function safeCastUint96ToInt192(uint96 v) internal pure returns (int192) {
        return int192(uint192(v));
    }

    function safeCastInt192ToUint96(int192 i192) internal pure returns (uint96) {
        if (i192 < 0 || i192 > int192(uint192(type(uint96).max))) {
            revert Int192ToUint96CastOutOfRange(i192);
        }
        return uint96(uint192(i192));
    }

    function safeCastUint256ToInt128(uint256 x) internal pure returns (int128) {
        if (x > uint256(uint128(type(int128).max))) {
            revert Uint256ToInt128CastOutOfRangeError(x);
        }
        return int128(uint128(x));
    }

    function safeCastUint256ToUint40(uint256 x) internal pure returns (uint40) {
        if (x > uint256(type(uint40).max)) {
            revert Uint256ToUint40CastOutOfRangeError(x);
        }
        return uint40(x);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../tokens/IERC20.sol";

import "../party/Party.sol";

/// @notice Creates token distributions for parties.
interface ITokenDistributor {
    enum TokenType {
        Native,
        Erc20
    }

    // Info on a distribution, created by createDistribution().
    struct DistributionInfo {
        // Type of distribution/token.
        TokenType tokenType;
        // ID of the distribution. Assigned by createDistribution().
        uint256 distributionId;
        // The party whose members can claim the distribution.
        Party party;
        // Who can claim `fee`.
        address payable feeRecipient;
        // The token being distributed.
        address token;
        // Total amount of `token` that can be claimed by party members.
        uint128 memberSupply;
        // Amount of `token` to be redeemed by `feeRecipient`.
        uint128 fee;
        // Total shares at time distribution was created.
        uint96 totalShares;
    }

    event DistributionCreated(Party indexed party, DistributionInfo info);
    event DistributionFeeClaimed(
        Party indexed party,
        address indexed feeRecipient,
        TokenType tokenType,
        address token,
        uint256 amount
    );
    event DistributionClaimedByPartyToken(
        Party indexed party,
        uint256 indexed partyTokenId,
        address indexed owner,
        TokenType tokenType,
        address token,
        uint256 amountClaimed
    );

    /// @notice Create a new distribution for an outstanding native token balance
    ///         governed by a party.
    /// @dev Native tokens should be transferred directly into this contract
    ///      immediately prior (same tx) to calling `createDistribution()` or
    ///      attached to the call itself.
    /// @param party The party whose members can claim the distribution.
    /// @param feeRecipient Who can claim `fee`.
    /// @param feeBps Percentage (in bps) of the distribution `feeRecipient` receives.
    /// @return info Information on the created distribution.
    function createNativeDistribution(
        Party party,
        address payable feeRecipient,
        uint16 feeBps
    ) external payable returns (DistributionInfo memory info);

    /// @notice Create a new distribution for an outstanding ERC20 token balance
    ///         governed by a party.
    /// @dev ERC20 tokens should be transferred directly into this contract
    ///      immediately prior (same tx) to calling `createDistribution()` or
    ///      attached to the call itself.
    /// @param token The ERC20 token to distribute.
    /// @param party The party whose members can claim the distribution.
    /// @param feeRecipient Who can claim `fee`.
    /// @param feeBps Percentage (in bps) of the distribution `feeRecipient` receives.
    /// @return info Information on the created distribution.
    function createErc20Distribution(
        IERC20 token,
        Party party,
        address payable feeRecipient,
        uint16 feeBps
    ) external returns (DistributionInfo memory info);

    /// @notice Claim a portion of a distribution owed to a `partyTokenId` belonging
    ///         to the party that created the distribution. The caller
    ///         must own this token.
    /// @param info Information on the distribution being claimed.
    /// @param partyTokenId The ID of the party token to claim for.
    /// @return amountClaimed The amount of the distribution claimed.
    function claim(
        DistributionInfo calldata info,
        uint256 partyTokenId
    ) external returns (uint128 amountClaimed);

    /// @notice Claim the fee for a distribution. Only a distribution's `feeRecipient`
    ///         can call this.
    /// @param info Information on the distribution being claimed.
    /// @param recipient The address to send the fee to.
    function claimFee(DistributionInfo calldata info, address payable recipient) external;

    /// @notice Batch version of `claim()`.
    /// @param infos Information on the distributions being claimed.
    /// @param partyTokenIds The ID of the party tokens to claim for.
    /// @return amountsClaimed The amount of the distributions claimed.
    function batchClaim(
        DistributionInfo[] calldata infos,
        uint256[] calldata partyTokenIds
    ) external returns (uint128[] memory amountsClaimed);

    /// @notice Batch version of `claimFee()`.
    /// @param infos Information on the distributions to claim fees for.
    /// @param recipients The addresses to send the fees to.
    function batchClaimFee(
        DistributionInfo[] calldata infos,
        address payable[] calldata recipients
    ) external;

    /// @notice Compute the amount of a distribution's token are owed to a party
    ///         member, identified by the `partyTokenId`.
    /// @param info Information on the distribution being claimed.
    /// @param partyTokenId The ID of the party token to claim for.
    /// @return claimAmount The amount of the distribution owed to the party member.
    function getClaimAmount(
        DistributionInfo calldata info,
        uint256 partyTokenId
    ) external view returns (uint128);

    /// @notice Check whether the fee has been claimed for a distribution.
    /// @param party The party to use for checking whether the fee has been claimed.
    /// @param distributionId The ID of the distribution to check.
    /// @return feeClaimed Whether the fee has been claimed.
    function wasFeeClaimed(Party party, uint256 distributionId) external view returns (bool);

    /// @notice Check whether a `partyTokenId` has claimed their share of a distribution.
    /// @param party The party to use for checking whether the `partyTokenId` has claimed.
    /// @param partyTokenId The ID of the party token to check.
    /// @param distributionId The ID of the distribution to check.
    /// @return hasClaimed Whether the `partyTokenId` has claimed.
    function hasPartyTokenIdClaimed(
        Party party,
        uint256 partyTokenId,
        uint256 distributionId
    ) external view returns (bool);

    /// @notice Get how much unclaimed member tokens are left in a distribution.
    /// @param party The party to use for checking the unclaimed member tokens.
    /// @param distributionId The ID of the distribution to check.
    /// @return remainingMemberSupply The amount of distribution supply remaining.
    function getRemainingMemberSupply(
        Party party,
        uint256 distributionId
    ) external view returns (uint128);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

// Base contract for all contracts intended to be delegatecalled into.
abstract contract Implementation {
    error OnlyDelegateCallError();
    error OnlyConstructorError();

    address public immutable IMPL;

    constructor() {
        IMPL = address(this);
    }

    // Reverts if the current function context is not inside of a delegatecall.
    modifier onlyDelegateCall() virtual {
        if (address(this) == IMPL) {
            revert OnlyDelegateCallError();
        }
        _;
    }

    // Reverts if the current function context is not inside of a constructor.
    modifier onlyConstructor() {
        if (address(this).code.length != 0) {
            revert OnlyConstructorError();
        }
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../tokens/IERC721.sol";

import "./PartyGovernanceNFT.sol";
import "./PartyGovernance.sol";

/// @notice The governance contract that also custodies the precious NFTs. This
///         is also the Governance NFT 721 contract.
contract Party is PartyGovernanceNFT {
    // Arguments used to initialize the party.
    struct PartyOptions {
        PartyGovernance.GovernanceOpts governance;
        ProposalStorage.ProposalEngineOpts proposalEngine;
        string name;
        string symbol;
        uint256 customizationPresetId;
    }

    // Arguments used to initialize the `PartyGovernanceNFT`.
    struct PartyInitData {
        PartyOptions options;
        IERC721[] preciousTokens;
        uint256[] preciousTokenIds;
        address[] authorities;
        uint40 rageQuitTimestamp;
    }

    /// @notice Version ID of the party implementation contract.
    uint16 public constant VERSION_ID = 1;

    // Set the `Globals` contract.
    constructor(IGlobals globals) PartyGovernanceNFT(globals) {}

    /// @notice Initializer to be delegatecalled by `Proxy` constructor. Will
    ///         revert if called outside the constructor.
    /// @param initData Options used to initialize the party governance.
    function initialize(PartyInitData memory initData) external onlyConstructor {
        PartyGovernanceNFT._initialize(
            initData.options.name,
            initData.options.symbol,
            initData.options.customizationPresetId,
            initData.options.governance,
            initData.options.proposalEngine,
            initData.preciousTokens,
            initData.preciousTokenIds,
            initData.authorities,
            initData.rageQuitTimestamp
        );
    }

    receive() external payable {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Minimal ERC721 interface.
interface IERC721 {
    event Transfer(address indexed owner, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed operator, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function approve(address operator, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool isApproved) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function getApproved(uint256 tokenId) external view returns (address);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../utils/ReadOnlyDelegateCall.sol";
import "../utils/LibSafeCast.sol";
import "../utils/LibAddress.sol";
import "openzeppelin/contracts/interfaces/IERC2981.sol";
import "../globals/IGlobals.sol";
import "../tokens/IERC721.sol";
import "../vendor/solmate/ERC721.sol";
import "./PartyGovernance.sol";
import "../renderers/RendererStorage.sol";

/// @notice ERC721 functionality built on top of `PartyGovernance`.
contract PartyGovernanceNFT is PartyGovernance, ERC721, IERC2981 {
    using LibSafeCast for uint256;
    using LibSafeCast for uint96;
    using LibERC20Compat for IERC20;
    using LibAddress for address payable;

    error OnlyAuthorityError();
    error OnlySelfError();
    error UnauthorizedToBurnError();
    error FixedRageQuitTimestampError(uint40 rageQuitTimestamp);
    error CannotRageQuitError(uint40 rageQuitTimestamp);
    error CannotDisableRageQuitAfterInitializationError();
    error InvalidTokenOrderError();
    error BelowMinWithdrawAmountError(uint256 amount, uint256 minAmount);
    error NothingToBurnError();

    event AuthorityAdded(address indexed authority);
    event AuthorityRemoved(address indexed authority);
    event RageQuitSet(uint40 oldRageQuitTimestamp, uint40 newRageQuitTimestamp);
    event Burn(address caller, uint256 tokenId, uint256 votingPower);
    event RageQuit(address caller, uint256[] tokenIds, IERC20[] withdrawTokens, address receiver);

    uint40 private constant ENABLE_RAGEQUIT_PERMANENTLY = 0x6b5b567bfe; // uint40(uint256(keccak256("ENABLE_RAGEQUIT_PERMANENTLY")))
    uint40 private constant DISABLE_RAGEQUIT_PERMANENTLY = 0xab2cb21860; // uint40(uint256(keccak256("DISABLE_RAGEQUIT_PERMANENTLY")))

    // Token address used to indicate ETH.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // The `Globals` contract storing global configuration values. This contract
    // is immutable and its address will never change.
    IGlobals private immutable _GLOBALS;

    /// @notice The number of tokens that have been minted.
    uint96 public tokenCount;
    /// @notice The total minted voting power.
    ///         Capped to `_governanceValues.totalVotingPower` unless minting
    ///         party cards for initial crowdfund.
    uint96 public mintedVotingPower;
    /// @notice The timestamp until which ragequit is enabled. Can be set to the
    ///         `ENABLE_RAGEQUIT_PERMANENTLY`/`DISABLE_RAGEQUIT_PERMANENTLY`
    ///         values to enable/disable ragequit permanently.
    ///         `DISABLE_RAGEQUIT_PERMANENTLY` can only be set during
    ///         initialization.
    uint40 public rageQuitTimestamp;
    /// @notice The voting power of `tokenId`.
    mapping(uint256 => uint256) public votingPowerByTokenId;
    /// @notice Address with authority to mint cards and update voting power for the party.
    mapping(address => bool) public isAuthority;

    modifier onlyAuthority() {
        if (!isAuthority[msg.sender]) {
            revert OnlyAuthorityError();
        }
        _;
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert OnlySelfError();
        }
        _;
    }

    // Set the `Globals` contract. The name or symbol of ERC721 does not matter;
    // it will be set in `_initialize()`.
    constructor(IGlobals globals) payable PartyGovernance(globals) ERC721("", "") {
        _GLOBALS = globals;
    }

    // Initialize storage for proxy contracts.
    function _initialize(
        string memory name_,
        string memory symbol_,
        uint256 customizationPresetId,
        PartyGovernance.GovernanceOpts memory governanceOpts,
        ProposalStorage.ProposalEngineOpts memory proposalEngineOpts,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds,
        address[] memory authorities,
        uint40 rageQuitTimestamp_
    ) internal {
        PartyGovernance._initialize(
            governanceOpts,
            proposalEngineOpts,
            preciousTokens,
            preciousTokenIds
        );
        name = name_;
        symbol = symbol_;
        rageQuitTimestamp = rageQuitTimestamp_;
        unchecked {
            for (uint256 i; i < authorities.length; ++i) {
                isAuthority[authorities[i]] = true;
            }
        }
        if (customizationPresetId != 0) {
            RendererStorage(_GLOBALS.getAddress(LibGlobals.GLOBAL_RENDERER_STORAGE))
                .useCustomizationPreset(customizationPresetId);
        }
    }

    /// @inheritdoc ERC721
    function ownerOf(uint256 tokenId) public view override returns (address owner) {
        return ERC721.ownerOf(tokenId);
    }

    /// @inheritdoc EIP165
    function supportsInterface(
        bytes4 interfaceId
    ) public pure override(PartyGovernance, ERC721, IERC165) returns (bool) {
        return
            PartyGovernance.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256) public view override returns (string memory) {
        _delegateToRenderer();
        return ""; // Just to make the compiler happy.
    }

    /// @notice Returns a URI for the storefront-level metadata for your contract.
    function contractURI() external view returns (string memory) {
        _delegateToRenderer();
        return ""; // Just to make the compiler happy.
    }

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    function royaltyInfo(uint256, uint256) external view returns (address, uint256) {
        _delegateToRenderer();
        return (address(0), 0); // Just to make the compiler happy.
    }

    /// @notice Return the distribution share amount of a token. Included as an alias
    ///         for `votePowerByTokenId` for backwards compatibility with old
    ///         `TokenDistributor` implementations.
    /// @param tokenId The token ID to query.
    /// @return share The distribution shares of `tokenId`.
    function getDistributionShareOf(uint256 tokenId) public view returns (uint256) {
        return votingPowerByTokenId[tokenId];
    }

    /// @notice Return the voting power share of a token. Denominated
    ///         fractions of 1e18. I.e., 1e18 = 100%.
    /// @param tokenId The token ID to query.
    /// @return share The voting power percentage of `tokenId`.
    function getVotingPowerShareOf(uint256 tokenId) public view returns (uint256) {
        uint256 totalVotingPower = _governanceValues.totalVotingPower;
        return
            totalVotingPower == 0 ? 0 : (votingPowerByTokenId[tokenId] * 1e18) / totalVotingPower;
    }

    /// @notice Mint a governance NFT for `owner` with `votingPower` and
    ///         immediately delegate voting power to `delegate.` Only callable
    ///         by an authority.
    /// @param owner The owner of the NFT.
    /// @param votingPower The voting power of the NFT.
    /// @param delegate The address to delegate voting power to.
    function mint(
        address owner,
        uint256 votingPower,
        address delegate
    ) external onlyAuthority returns (uint256 tokenId) {
        uint96 mintedVotingPower_ = mintedVotingPower;
        uint96 totalVotingPower = _governanceValues.totalVotingPower;

        // Cap voting power to remaining unminted voting power supply.
        uint96 votingPower_ = votingPower.safeCastUint256ToUint96();
        // Allow minting past total voting power if minting party cards for
        // initial crowdfund when there is no total voting power.
        if (totalVotingPower != 0 && totalVotingPower - mintedVotingPower_ < votingPower_) {
            unchecked {
                votingPower_ = totalVotingPower - mintedVotingPower_;
            }
        }

        // Update state.
        unchecked {
            tokenId = ++tokenCount;
        }
        mintedVotingPower += votingPower_;
        votingPowerByTokenId[tokenId] = votingPower_;

        // Use delegate from party over the one set during crowdfund.
        address delegate_ = delegationsByVoter[owner];
        if (delegate_ != address(0)) {
            delegate = delegate_;
        }

        _adjustVotingPower(owner, votingPower_.safeCastUint96ToInt192(), delegate);
        _safeMint(owner, tokenId);
    }

    /// @notice Add voting power to an existing NFT. Only callable by an
    ///         authority.
    /// @param tokenId The ID of the NFT to add voting power to.
    /// @param votingPower The amount of voting power to add.
    function addVotingPower(uint256 tokenId, uint256 votingPower) external onlyAuthority {
        uint96 mintedVotingPower_ = mintedVotingPower;
        uint96 totalVotingPower = _governanceValues.totalVotingPower;
        // Cap voting power to remaining unminted voting power supply.
        uint96 votingPower_ = votingPower.safeCastUint256ToUint96();
        // Allow minting past total voting power if minting party cards for
        // initial crowdfund when there is no total voting power.
        if (totalVotingPower != 0 && totalVotingPower - mintedVotingPower_ < votingPower_) {
            unchecked {
                votingPower_ = totalVotingPower - mintedVotingPower_;
            }
        }

        // Update state.
        mintedVotingPower += votingPower_;
        votingPowerByTokenId[tokenId] += votingPower_;

        _adjustVotingPower(ownerOf(tokenId), votingPower_.safeCastUint96ToInt192(), address(0));
    }

    /// @notice Update the total voting power of the party. Only callable by
    ///         an authority.
    /// @param newVotingPower The new total voting power to add.
    function increaseTotalVotingPower(uint96 newVotingPower) external onlyAuthority {
        _governanceValues.totalVotingPower += newVotingPower;
    }

    /// @notice Burn governance NFTs and remove their voting power. Can only
    ///         be called by an authority before the party has started.
    /// @param tokenIds The IDs of the governance NFTs to burn.
    function burn(uint256[] memory tokenIds) public onlyAuthority {
        // Authority needs to be able to burn cards during the initial
        // crowdfund to process refunds but not after the party has started.
        if (_governanceValues.totalVotingPower != 0) revert UnauthorizedToBurnError();

        // Used to update voting power state of party at the end.
        _burnAndUpdateVotingPower(tokenIds, false);
    }

    function _burnAndUpdateVotingPower(
        uint256[] memory tokenIds,
        bool checkIfAuthorizedToBurn
    ) private returns (uint96 totalVotingPowerBurned) {
        for (uint256 i; i < tokenIds.length; ++i) {
            uint256 tokenId = tokenIds[i];

            // Check if caller is authorized to burn the token.
            address owner = ownerOf(tokenId);
            if (checkIfAuthorizedToBurn) {
                if (
                    msg.sender != owner &&
                    getApproved[tokenId] != msg.sender &&
                    !isApprovedForAll[owner][msg.sender]
                ) {
                    revert UnauthorizedToBurnError();
                }
            }

            // Must be retrieved before updating voting power for token to be burned.
            uint96 votingPower = votingPowerByTokenId[tokenId].safeCastUint256ToUint96();

            totalVotingPowerBurned += votingPower;

            // Update voting power for token to be burned.
            delete votingPowerByTokenId[tokenId];
            _adjustVotingPower(owner, -votingPower.safeCastUint96ToInt192(), address(0));

            // Burn token.
            _burn(tokenId);

            emit Burn(msg.sender, tokenId, votingPower);
        }

        // Update minted voting power.
        mintedVotingPower -= totalVotingPowerBurned;
    }

    /// @notice Burn governance NFT and remove its voting power. Can only be
    ///         called by an authority before the party has started.
    /// @param tokenId The ID of the governance NFTs to burn.
    function burn(uint256 tokenId) external {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        burn(tokenIds);
    }

    /// @notice Set the timestamp until which ragequit is enabled.
    /// @param newRageQuitTimestamp The new ragequit timestamp.
    function setRageQuit(uint40 newRageQuitTimestamp) external onlyHost {
        // Prevent disabling ragequit after initialization.
        if (newRageQuitTimestamp == DISABLE_RAGEQUIT_PERMANENTLY) {
            revert CannotDisableRageQuitAfterInitializationError();
        }

        uint40 oldRageQuitTimestamp = rageQuitTimestamp;

        // Prevent setting timestamp if it is permanently enabled/disabled.
        if (
            oldRageQuitTimestamp == ENABLE_RAGEQUIT_PERMANENTLY ||
            oldRageQuitTimestamp == DISABLE_RAGEQUIT_PERMANENTLY
        ) {
            revert FixedRageQuitTimestampError(oldRageQuitTimestamp);
        }

        emit RageQuitSet(oldRageQuitTimestamp, rageQuitTimestamp = newRageQuitTimestamp);
    }

    /// @notice Burn a governance NFT and withdraw a fair share of fungible tokens from the party.
    /// @param tokenIds The IDs of the governance NFTs to burn.
    /// @param withdrawTokens The fungible tokens to withdraw. Specify the
    ///                       `ETH_ADDRESS` value to withdraw ETH.
    /// @param minWithdrawAmounts The minimum amount of to withdraw for each token.
    /// @param receiver The address to receive the withdrawn tokens.
    function rageQuit(
        uint256[] calldata tokenIds,
        IERC20[] calldata withdrawTokens,
        uint256[] calldata minWithdrawAmounts,
        address receiver
    ) external {
        if (tokenIds.length == 0) revert NothingToBurnError();

        // Check if ragequit is allowed.
        uint40 currentRageQuitTimestamp = rageQuitTimestamp;
        if (currentRageQuitTimestamp != ENABLE_RAGEQUIT_PERMANENTLY) {
            if (
                currentRageQuitTimestamp == DISABLE_RAGEQUIT_PERMANENTLY ||
                currentRageQuitTimestamp < block.timestamp
            ) {
                revert CannotRageQuitError(currentRageQuitTimestamp);
            }
        }

        // Used as a reentrancy guard. Will be updated back after ragequit.
        rageQuitTimestamp = DISABLE_RAGEQUIT_PERMANENTLY;

        // Update last rage quit timestamp.
        lastRageQuitTimestamp = uint40(block.timestamp);

        // Sum up total amount of each token to withdraw.
        uint256[] memory withdrawAmounts = new uint256[](withdrawTokens.length);
        {
            IERC20 prevToken;
            for (uint256 i; i < withdrawTokens.length; ++i) {
                IERC20 token = withdrawTokens[i];

                // Check if order of tokens to transfer is valid.
                // Prevent null and duplicate transfers.
                if (prevToken >= token) revert InvalidTokenOrderError();

                prevToken = token;

                // Check token's balance.
                uint256 balance = address(token) == ETH_ADDRESS
                    ? address(this).balance
                    : token.balanceOf(address(this));

                // Add fair share of tokens from the party to total.
                for (uint256 j; j < tokenIds.length; ++j) {
                    // Must be retrieved before burning the token.
                    uint256 shareOfVotingPower = getVotingPowerShareOf(tokenIds[j]);

                    withdrawAmounts[i] += (balance * shareOfVotingPower) / 1e18;
                }
            }
        }
        {
            // Burn caller's party cards. This will revert if caller is not the
            // the owner or approved for any of the card they are attempting to
            // burn or if there are duplicate token IDs.
            uint96 totalVotingPowerBurned = _burnAndUpdateVotingPower(tokenIds, true);

            // Update total voting power of party.
            _governanceValues.totalVotingPower -= totalVotingPowerBurned;
        }
        {
            uint16 feeBps_ = feeBps;
            for (uint256 i; i < withdrawTokens.length; ++i) {
                IERC20 token = withdrawTokens[i];
                uint256 amount = withdrawAmounts[i];

                // Take fee from amount.
                uint256 fee = (amount * feeBps_) / 1e4;

                if (fee > 0) {
                    amount -= fee;

                    // Transfer fee to fee recipient.
                    if (address(token) == ETH_ADDRESS) {
                        payable(feeRecipient).transferEth(fee);
                    } else {
                        token.compatTransfer(feeRecipient, fee);
                    }
                }

                if (amount > 0) {
                    uint256 minAmount = minWithdrawAmounts[i];

                    // Check amount is at least minimum.
                    if (amount < minAmount) {
                        revert BelowMinWithdrawAmountError(amount, minAmount);
                    }

                    // Transfer token from party to recipient.
                    if (address(token) == ETH_ADDRESS) {
                        payable(receiver).transferEth(amount);
                    } else {
                        token.compatTransfer(receiver, amount);
                    }
                }
            }
        }

        // Update ragequit timestamp back to before.
        rageQuitTimestamp = currentRageQuitTimestamp;

        emit RageQuit(msg.sender, tokenIds, withdrawTokens, receiver);
    }

    /// @inheritdoc ERC721
    function transferFrom(address owner, address to, uint256 tokenId) public override {
        // Transfer voting along with token.
        _transferVotingPower(owner, to, votingPowerByTokenId[tokenId]);
        super.transferFrom(owner, to, tokenId);
    }

    /// @inheritdoc ERC721
    function safeTransferFrom(address owner, address to, uint256 tokenId) public override {
        // super.safeTransferFrom() will call transferFrom() first which will
        // transfer voting power.
        super.safeTransferFrom(owner, to, tokenId);
    }

    /// @inheritdoc ERC721
    function safeTransferFrom(
        address owner,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public override {
        // super.safeTransferFrom() will call transferFrom() first which will
        // transfer voting power.
        super.safeTransferFrom(owner, to, tokenId, data);
    }

    /// @notice Add a new authority.
    /// @dev Used in `AddAuthorityProposal`. Only the party itself can add
    ///      authorities to prevent it from being used anywhere else.
    function addAuthority(address authority) external onlySelf {
        isAuthority[authority] = true;

        emit AuthorityAdded(authority);
    }

    /// @notice Relinquish the authority role.
    function abdicateAuthority() external onlyAuthority {
        delete isAuthority[msg.sender];

        emit AuthorityRemoved(msg.sender);
    }

    function _delegateToRenderer() private view {
        _readOnlyDelegateCall(
            // Instance of IERC721Renderer.
            _GLOBALS.getAddress(LibGlobals.GLOBAL_GOVERNANCE_NFT_RENDER_IMPL),
            msg.data
        );
        assert(false); // Will not be reached.
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../distribution/ITokenDistributor.sol";
import "../utils/ReadOnlyDelegateCall.sol";
import "../tokens/IERC721.sol";
import "../tokens/IERC20.sol";
import "../tokens/IERC1155.sol";
import "../tokens/ERC721Receiver.sol";
import "../tokens/ERC1155Receiver.sol";
import "../utils/LibERC20Compat.sol";
import "../utils/LibRawResult.sol";
import "../utils/LibSafeCast.sol";
import "../globals/IGlobals.sol";
import "../globals/LibGlobals.sol";
import "../proposals/IProposalExecutionEngine.sol";
import "../proposals/LibProposal.sol";
import "../proposals/ProposalStorage.sol";

import "./Party.sol";
import "./IPartyFactory.sol";

/// @notice Base contract for a Party encapsulating all governance functionality.
abstract contract PartyGovernance is
    ERC721Receiver,
    ERC1155Receiver,
    ProposalStorage,
    Implementation,
    ReadOnlyDelegateCall
{
    using LibERC20Compat for IERC20;
    using LibRawResult for bytes;
    using LibSafeCast for uint256;
    using LibSafeCast for int192;
    using LibSafeCast for uint96;

    // States a proposal can be in.
    enum ProposalStatus {
        // The proposal does not exist.
        Invalid,
        // The proposal has been proposed (via `propose()`), has not been vetoed
        // by a party host, and is within the voting window. Members can vote on
        // the proposal and party hosts can veto the proposal.
        Voting,
        // The proposal has either exceeded its voting window without reaching
        // `passThresholdBps` of votes or was vetoed by a party host.
        Defeated,
        // The proposal reached at least `passThresholdBps` of votes but is still
        // waiting for `executionDelay` to pass before it can be executed. Members
        // can continue to vote on the proposal and party hosts can veto at this time.
        Passed,
        // Same as `Passed` but now `executionDelay` has been satisfied. Any member
        // may execute the proposal via `execute()`, unless `maxExecutableTime`
        // has arrived.
        Ready,
        // The proposal has been executed at least once but has further steps to
        // complete so it needs to be executed again. No other proposals may be
        // executed while a proposal is in the `InProgress` state. No voting or
        // vetoing of the proposal is allowed, however it may be forcibly cancelled
        // via `cancel()` if the `cancelDelay` has passed since being first executed.
        InProgress,
        // The proposal was executed and completed all its steps. No voting or
        // vetoing can occur and it cannot be cancelled nor executed again.
        Complete,
        // The proposal was executed at least once but did not complete before
        // `cancelDelay` seconds passed since the first execute and was forcibly cancelled.
        Cancelled
    }

    struct GovernanceOpts {
        // Address of initial party hosts.
        address[] hosts;
        // How long people can vote on a proposal.
        uint40 voteDuration;
        // How long to wait after a proposal passes before it can be
        // executed.
        uint40 executionDelay;
        // Minimum ratio of accept votes to consider a proposal passed,
        // in bps, where 10,000 == 100%.
        uint16 passThresholdBps;
        // Total voting power of governance NFTs.
        uint96 totalVotingPower;
        // Fee bps for distributions.
        uint16 feeBps;
        // Fee recipeint for distributions.
        address payable feeRecipient;
    }

    // Subset of `GovernanceOpts` that are commonly read together for
    // efficiency.
    struct GovernanceValues {
        uint40 voteDuration;
        uint40 executionDelay;
        uint16 passThresholdBps;
        uint96 totalVotingPower;
    }

    // A snapshot of voting power for a member.
    struct VotingPowerSnapshot {
        // The timestamp when the snapshot was taken.
        uint40 timestamp;
        // Voting power that was delegated to this user by others.
        uint96 delegatedVotingPower;
        // The intrinsic (not delegated from someone else) voting power of this user.
        uint96 intrinsicVotingPower;
        // Whether the user was delegated to another at this snapshot.
        bool isDelegated;
    }

    // Proposal details chosen by proposer.
    struct Proposal {
        // Time beyond which the proposal can no longer be executed.
        // If the proposal has already been executed, and is still InProgress,
        // this value is ignored.
        uint40 maxExecutableTime;
        // The minimum seconds this proposal can remain in the InProgress status
        // before it can be cancelled.
        uint40 cancelDelay;
        // Encoded proposal data. The first 4 bytes are the proposal type, followed
        // by encoded proposal args specific to the proposal type. See
        // ProposalExecutionEngine for details.
        bytes proposalData;
    }

    // Accounting and state tracking values for a proposal.
    struct ProposalStateValues {
        // When the proposal was proposed.
        uint40 proposedTime;
        // When the proposal passed the vote.
        uint40 passedTime;
        // When the proposal was first executed.
        uint40 executedTime;
        // When the proposal completed.
        uint40 completedTime;
        // Number of accept votes.
        uint96 votes; // -1 == vetoed
        // Number of total voting power at time proposal created.
        uint96 totalVotingPower;
    }

    // Storage states for a proposal.
    struct ProposalState {
        // Accounting and state tracking values.
        ProposalStateValues values;
        // Hash of the proposal.
        bytes32 hash;
        // Whether a member has voted for (accepted) this proposal already.
        mapping(address => bool) hasVoted;
    }

    event Proposed(uint256 proposalId, address proposer, Proposal proposal);
    event ProposalAccepted(uint256 proposalId, address voter, uint256 weight);
    event EmergencyExecute(address target, bytes data, uint256 amountEth);

    event ProposalPassed(uint256 indexed proposalId);
    event ProposalVetoed(uint256 indexed proposalId, address host);
    event ProposalExecuted(uint256 indexed proposalId, address executor, bytes nextProgressData);
    event ProposalCancelled(uint256 indexed proposalId);
    event DistributionCreated(
        ITokenDistributor.TokenType tokenType,
        address token,
        uint256 tokenId
    );
    event VotingPowerDelegated(address indexed owner, address indexed delegate);
    event HostStatusTransferred(address oldHost, address newHost);
    event EmergencyExecuteDisabled();

    error MismatchedPreciousListLengths();
    error BadProposalStatusError(ProposalStatus status);
    error BadProposalHashError(bytes32 proposalHash, bytes32 actualHash);
    error ExecutionTimeExceededError(uint40 maxExecutableTime, uint40 timestamp);
    error OnlyPartyHostError();
    error OnlyActiveMemberError();
    error InvalidDelegateError();
    error BadPreciousListError();
    error OnlyPartyDaoError(address notDao, address partyDao);
    error OnlyPartyDaoOrHostError(address notDao, address partyDao);
    error OnlyWhenEmergencyActionsAllowedError();
    error OnlyWhenEnabledError();
    error AlreadyVotedError(address voter);
    error InvalidNewHostError();
    error ProposalCannotBeCancelledYetError(uint40 currentTime, uint40 cancelTime);
    error InvalidBpsError(uint16 bps);
    error DistributionsRequireVoteError();
    error PartyNotStartedError();
    error CannotRageQuitAndAcceptError();

    uint256 private constant UINT40_HIGH_BIT = 1 << 39;
    uint96 private constant VETO_VALUE = type(uint96).max;

    // The `Globals` contract storing global configuration values. This contract
    // is immutable and it’s address will never change.
    IGlobals private immutable _GLOBALS;

    /// @notice Whether the DAO has emergency powers for this party.
    bool public emergencyExecuteDisabled;
    /// @notice Distribution fee bps.
    uint16 public feeBps;
    /// @notice Distribution fee recipient.
    address payable public feeRecipient;
    /// @notice The timestamp of the last time `rageQuit()` was called.
    uint40 public lastRageQuitTimestamp;
    /// @notice The hash of the list of precious NFTs guarded by the party.
    bytes32 public preciousListHash;
    /// @notice The last proposal ID that was used. 0 means no proposals have been made.
    uint256 public lastProposalId;
    /// @notice Whether an address is a party host.
    mapping(address => bool) public isHost;
    /// @notice The last person a voter delegated its voting power to.
    mapping(address => address) public delegationsByVoter;
    // Governance parameters for this party.
    GovernanceValues internal _governanceValues;
    // ProposalState by proposal ID.
    mapping(uint256 => ProposalState) private _proposalStateByProposalId;
    // Snapshots of voting power per user, each sorted by increasing time.
    mapping(address => VotingPowerSnapshot[]) private _votingPowerSnapshotsByVoter;

    modifier onlyHost() {
        if (!isHost[msg.sender]) {
            revert OnlyPartyHostError();
        }
        _;
    }

    // Caller must have voting power at the current time.
    modifier onlyActiveMember() {
        {
            VotingPowerSnapshot memory snap = _getLastVotingPowerSnapshotForVoter(msg.sender);
            // Must have either delegated voting power or intrinsic voting power.
            if (snap.intrinsicVotingPower == 0 && snap.delegatedVotingPower == 0) {
                revert OnlyActiveMemberError();
            }
        }
        _;
    }

    // Only the party DAO multisig can call.
    modifier onlyPartyDao() {
        {
            address partyDao = _GLOBALS.getAddress(LibGlobals.GLOBAL_DAO_WALLET);
            if (msg.sender != partyDao) {
                revert OnlyPartyDaoError(msg.sender, partyDao);
            }
        }
        _;
    }

    // Only the party DAO multisig or a party host can call.
    modifier onlyPartyDaoOrHost() {
        address partyDao = _GLOBALS.getAddress(LibGlobals.GLOBAL_DAO_WALLET);
        if (msg.sender != partyDao && !isHost[msg.sender]) {
            revert OnlyPartyDaoOrHostError(msg.sender, partyDao);
        }
        _;
    }

    // Only if `emergencyExecuteDisabled` is not true.
    modifier onlyWhenEmergencyExecuteAllowed() {
        if (emergencyExecuteDisabled) {
            revert OnlyWhenEmergencyActionsAllowedError();
        }
        _;
    }

    modifier onlyWhenNotGloballyDisabled() {
        if (_GLOBALS.getBool(LibGlobals.GLOBAL_DISABLE_PARTY_ACTIONS)) {
            revert OnlyWhenEnabledError();
        }
        _;
    }

    // Set the `Globals` contract.
    constructor(IGlobals globals) {
        _GLOBALS = globals;
    }

    // Initialize storage for proxy contracts and initialize the proposal execution engine.
    function _initialize(
        GovernanceOpts memory govOpts,
        ProposalStorage.ProposalEngineOpts memory proposalEngineOpts,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    ) internal virtual {
        // Check BPS are valid.
        if (govOpts.feeBps > 1e4) {
            revert InvalidBpsError(govOpts.feeBps);
        }
        if (govOpts.passThresholdBps > 1e4) {
            revert InvalidBpsError(govOpts.passThresholdBps);
        }
        // Initialize the proposal execution engine.
        _initProposalImpl(
            IProposalExecutionEngine(_GLOBALS.getAddress(LibGlobals.GLOBAL_PROPOSAL_ENGINE_IMPL)),
            abi.encode(proposalEngineOpts)
        );
        // Set the governance parameters.
        _governanceValues = GovernanceValues({
            voteDuration: govOpts.voteDuration,
            executionDelay: govOpts.executionDelay,
            passThresholdBps: govOpts.passThresholdBps,
            totalVotingPower: govOpts.totalVotingPower
        });
        // Set fees.
        feeBps = govOpts.feeBps;
        feeRecipient = govOpts.feeRecipient;
        // Set the precious list.
        _setPreciousList(preciousTokens, preciousTokenIds);
        // Set the party hosts.
        for (uint256 i = 0; i < govOpts.hosts.length; ++i) {
            isHost[govOpts.hosts[i]] = true;
        }
    }

    /// @dev Forward all unknown read-only calls to the proposal execution engine.
    ///      Initial use case is to facilitate eip-1271 signatures.
    fallback() external {
        _readOnlyDelegateCall(address(_getSharedProposalStorage().engineImpl), msg.data);
    }

    /// @inheritdoc EIP165
    /// @dev Combined logic for `ERC721Receiver` and `ERC1155Receiver`.
    function supportsInterface(
        bytes4 interfaceId
    ) public pure virtual override(ERC721Receiver, ERC1155Receiver) returns (bool) {
        return
            ERC721Receiver.supportsInterface(interfaceId) ||
            ERC1155Receiver.supportsInterface(interfaceId);
    }

    /// @notice Get the current `ProposalExecutionEngine` instance.
    function getProposalExecutionEngine() external view returns (IProposalExecutionEngine) {
        return _getSharedProposalStorage().engineImpl;
    }

    /// @notice Get the current `ProposalEngineOpts` options.
    function getProposalEngineOpts() external view returns (ProposalEngineOpts memory) {
        return _getSharedProposalStorage().opts;
    }

    /// @notice Get the total voting power of `voter` at a `timestamp`.
    /// @param voter The address of the voter.
    /// @param timestamp The timestamp to get the voting power at.
    /// @return votingPower The total voting power of `voter` at `timestamp`.
    function getVotingPowerAt(
        address voter,
        uint40 timestamp
    ) external view returns (uint96 votingPower) {
        return getVotingPowerAt(voter, timestamp, type(uint256).max);
    }

    /// @notice Get the total voting power of `voter` at a snapshot `snapIndex`, with checks to
    ///         make sure it is the latest voting snapshot =< `timestamp`.
    /// @param voter The address of the voter.
    /// @param timestamp The timestamp to get the voting power at.
    /// @param snapIndex The index of the snapshot to get the voting power at.
    /// @return votingPower The total voting power of `voter` at `timestamp`.
    function getVotingPowerAt(
        address voter,
        uint40 timestamp,
        uint256 snapIndex
    ) public view returns (uint96 votingPower) {
        VotingPowerSnapshot memory snap = _getVotingPowerSnapshotAt(voter, timestamp, snapIndex);
        return (snap.isDelegated ? 0 : snap.intrinsicVotingPower) + snap.delegatedVotingPower;
    }

    /// @notice Get the state of a proposal.
    /// @param proposalId The ID of the proposal.
    /// @return status The status of the proposal.
    /// @return values The state of the proposal.
    function getProposalStateInfo(
        uint256 proposalId
    ) external view returns (ProposalStatus status, ProposalStateValues memory values) {
        values = _proposalStateByProposalId[proposalId].values;
        status = _getProposalStatus(values);
    }

    /// @notice Retrieve fixed governance parameters.
    /// @return gv The governance parameters of this party.
    function getGovernanceValues() external view returns (GovernanceValues memory gv) {
        return _governanceValues;
    }

    /// @notice Get the hash of a proposal.
    /// @dev Proposal details are not stored on-chain so the hash is used to enforce
    ///      consistency between calls.
    /// @param proposal The proposal to hash.
    /// @return proposalHash The hash of the proposal.
    function getProposalHash(Proposal memory proposal) public pure returns (bytes32 proposalHash) {
        // Hash the proposal in-place. Equivalent to:
        // keccak256(abi.encode(
        //   proposal.maxExecutableTime,
        //   proposal.cancelDelay,
        //   keccak256(proposal.proposalData)
        // ))
        bytes32 dataHash = keccak256(proposal.proposalData);
        assembly {
            // Overwrite the data field with the hash of its contents and then
            // hash the struct.
            let dataPos := add(proposal, 0x40)
            let t := mload(dataPos)
            mstore(dataPos, dataHash)
            proposalHash := keccak256(proposal, 0x60)
            // Restore the data field.
            mstore(dataPos, t)
        }
    }

    /// @notice Get the index of the most recent voting power snapshot <= `timestamp`.
    /// @param voter The address of the voter.
    /// @param timestamp The timestamp to get the snapshot index at.
    /// @return index The index of the snapshot.
    function findVotingPowerSnapshotIndex(
        address voter,
        uint40 timestamp
    ) public view returns (uint256 index) {
        VotingPowerSnapshot[] storage snaps = _votingPowerSnapshotsByVoter[voter];

        // Derived from Open Zeppelin binary search
        // ref: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Checkpoints.sol#L39
        uint256 high = snaps.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = (low + high) / 2;
            if (snaps[mid].timestamp > timestamp) {
                // Entry is too recent.
                high = mid;
            } else {
                // Entry is older. This is our best guess for now.
                low = mid + 1;
            }
        }

        // Return `type(uint256).max` if no valid voting snapshots found.
        return high == 0 ? type(uint256).max : high - 1;
    }

    /// @notice Pledge your intrinsic voting power to a new delegate, removing it from
    ///         the old one (if any).
    /// @param delegate The address to delegating voting power to.
    function delegateVotingPower(address delegate) external {
        _adjustVotingPower(msg.sender, 0, delegate);
        emit VotingPowerDelegated(msg.sender, delegate);
    }

    /// @notice Transfer party host status to another.
    /// @param newPartyHost The address of the new host.
    function abdicateHost(address newPartyHost) external onlyHost {
        // 0 is a special case burn address.
        if (newPartyHost != address(0)) {
            // Cannot transfer host status to an existing host.
            if (isHost[newPartyHost]) {
                revert InvalidNewHostError();
            }
            isHost[newPartyHost] = true;
        }
        isHost[msg.sender] = false;
        emit HostStatusTransferred(msg.sender, newPartyHost);
    }

    /// @notice Create a token distribution by moving the party's entire balance
    ///         to the `TokenDistributor` contract and immediately creating a
    ///         distribution governed by this party.
    /// @dev The `feeBps` and `feeRecipient` this party was created with will be
    ///      propagated to the distribution. Party members are entitled to a
    ///      share of the distribution's tokens proportionate to their relative
    ///      voting power in this party (less the fee).
    /// @dev Allow this to be called by the party itself for `FractionalizeProposal`.
    /// @param tokenType The type of token to distribute.
    /// @param token The address of the token to distribute.
    /// @param tokenId The ID of the token to distribute. Currently unused but
    ///                may be used in the future to support other distribution types.
    /// @return distInfo The information about the created distribution.
    function distribute(
        uint256 amount,
        ITokenDistributor.TokenType tokenType,
        address token,
        uint256 tokenId
    )
        external
        onlyWhenNotGloballyDisabled
        returns (ITokenDistributor.DistributionInfo memory distInfo)
    {
        // Ignore if the party is calling functions on itself, like with
        // `FractionalizeProposal` and `DistributionProposal`.
        if (msg.sender != address(this)) {
            // Must not require a vote to create a distribution, otherwise
            // distributions can only be created through a distribution
            // proposal.
            if (_getSharedProposalStorage().opts.distributionsRequireVote) {
                revert DistributionsRequireVoteError();
            }
            // Must be an active member.
            VotingPowerSnapshot memory snap = _getLastVotingPowerSnapshotForVoter(msg.sender);
            if (snap.intrinsicVotingPower == 0 && snap.delegatedVotingPower == 0) {
                revert OnlyActiveMemberError();
            }
        }
        // Prevent creating a distribution if the party has not started.
        if (_governanceValues.totalVotingPower == 0) {
            revert PartyNotStartedError();
        }
        // Get the address of the token distributor.
        ITokenDistributor distributor = ITokenDistributor(
            _GLOBALS.getAddress(LibGlobals.GLOBAL_TOKEN_DISTRIBUTOR)
        );
        emit DistributionCreated(tokenType, token, tokenId);
        // Create a native token distribution.
        address payable feeRecipient_ = feeRecipient;
        uint16 feeBps_ = feeBps;
        if (tokenType == ITokenDistributor.TokenType.Native) {
            return
                distributor.createNativeDistribution{ value: amount }(
                    Party(payable(address(this))),
                    feeRecipient_,
                    feeBps_
                );
        }
        // Otherwise must be an ERC20 token distribution.
        assert(tokenType == ITokenDistributor.TokenType.Erc20);
        IERC20(token).compatTransfer(address(distributor), amount);
        return
            distributor.createErc20Distribution(
                IERC20(token),
                Party(payable(address(this))),
                feeRecipient_,
                feeBps_
            );
    }

    /// @notice Make a proposal for members to vote on and cast a vote to accept it
    ///         as well.
    /// @dev Only an active member (has voting power) can call this.
    ///      Afterwards, members can vote to support it with `accept()` or a party
    ///      host can unilaterally reject the proposal with `veto()`.
    /// @param proposal The details of the proposal.
    /// @param latestSnapIndex The index of the caller's most recent voting power
    ///                        snapshot before the proposal was created. Should
    ///                        be retrieved off-chain and passed in.
    function propose(
        Proposal memory proposal,
        uint256 latestSnapIndex
    ) external onlyActiveMember returns (uint256 proposalId) {
        proposalId = ++lastProposalId;
        // Store the time the proposal was created and the proposal hash.
        (
            _proposalStateByProposalId[proposalId].values,
            _proposalStateByProposalId[proposalId].hash
        ) = (
            ProposalStateValues({
                proposedTime: uint40(block.timestamp),
                passedTime: 0,
                executedTime: 0,
                completedTime: 0,
                votes: 0,
                totalVotingPower: _governanceValues.totalVotingPower
            }),
            getProposalHash(proposal)
        );
        emit Proposed(proposalId, msg.sender, proposal);
        accept(proposalId, latestSnapIndex);
    }

    /// @notice Vote to support a proposed proposal.
    /// @dev The voting power cast will be the effective voting power of the caller
    ///      just before `propose()` was called (see `getVotingPowerAt()`).
    ///      If the proposal reaches `passThresholdBps` acceptance ratio then the
    ///      proposal will be in the `Passed` state and will be executable after
    ///      the `executionDelay` has passed, putting it in the `Ready` state.
    /// @param proposalId The ID of the proposal to accept.
    /// @param snapIndex The index of the caller's last voting power snapshot
    ///                  before the proposal was created. Should be retrieved
    ///                  off-chain and passed in.
    /// @return totalVotes The total votes cast on the proposal.
    function accept(uint256 proposalId, uint256 snapIndex) public returns (uint256 totalVotes) {
        // Get the information about the proposal.
        ProposalState storage info = _proposalStateByProposalId[proposalId];
        ProposalStateValues memory values = info.values;

        // Can only vote in certain proposal statuses.
        {
            ProposalStatus status = _getProposalStatus(values);
            // Allow voting even if the proposal is passed/ready so it can
            // potentially reach 100% consensus, which unlocks special
            // behaviors for certain proposal types.
            if (
                status != ProposalStatus.Voting &&
                status != ProposalStatus.Passed &&
                status != ProposalStatus.Ready
            ) {
                revert BadProposalStatusError(status);
            }
        }

        // Prevent voting in the same block as the last rage quit timestamp.
        // This is to prevent an exploit where a member can rage quit to reduce
        // the total voting power of the party, then propose and vote in the
        // same block since `getVotingPowerAt()` uses `values.proposedTime - 1`.
        // This would allow them to use the voting power snapshot just before
        // their card was burned to vote, potentially passing a proposal that
        // would have otherwise not passed.
        if (lastRageQuitTimestamp == block.timestamp) {
            revert CannotRageQuitAndAcceptError();
        }

        // Cannot vote twice.
        if (info.hasVoted[msg.sender]) {
            revert AlreadyVotedError(msg.sender);
        }
        // Mark the caller as having voted.
        info.hasVoted[msg.sender] = true;

        // Increase the total votes that have been cast on this proposal.
        uint96 votingPower = getVotingPowerAt(msg.sender, values.proposedTime - 1, snapIndex);
        values.votes += votingPower;
        info.values = values;
        emit ProposalAccepted(proposalId, msg.sender, votingPower);

        // Update the proposal status if it has reached the pass threshold.
        if (
            values.passedTime == 0 &&
            _areVotesPassing(
                values.votes,
                values.totalVotingPower,
                _governanceValues.passThresholdBps
            )
        ) {
            info.values.passedTime = uint40(block.timestamp);
            emit ProposalPassed(proposalId);
        }
        return values.votes;
    }

    /// @notice As a party host, veto a proposal, unilaterally rejecting it.
    /// @dev The proposal will never be executable and cannot be voted on anymore.
    ///      A proposal that has been already executed at least once (in the `InProgress` status)
    ///      cannot be vetoed.
    /// @param proposalId The ID of the proposal to veto.
    function veto(uint256 proposalId) external onlyHost {
        // Setting `votes` to -1 indicates a veto.
        ProposalState storage info = _proposalStateByProposalId[proposalId];
        ProposalStateValues memory values = info.values;

        {
            ProposalStatus status = _getProposalStatus(values);
            // Proposal must be in one of the following states.
            if (
                status != ProposalStatus.Voting &&
                status != ProposalStatus.Passed &&
                status != ProposalStatus.Ready
            ) {
                revert BadProposalStatusError(status);
            }
        }

        // -1 indicates veto.
        info.values.votes = VETO_VALUE;
        emit ProposalVetoed(proposalId, msg.sender);
    }

    /// @notice Executes a proposal that has passed governance.
    /// @dev The proposal must be in the `Ready` or `InProgress` status.
    ///      A `ProposalExecuted` event will be emitted with a non-empty `nextProgressData`
    ///      if the proposal has extra steps (must be executed again) to carry out,
    ///      in which case `nextProgressData` should be passed into the next `execute()` call.
    ///      The `ProposalExecutionEngine` enforces that only one `InProgress` proposal
    ///      is active at a time, so that proposal must be completed or cancelled via `cancel()`
    ///      in order to execute a different proposal.
    ///      `extraData` is optional, off-chain data a proposal might need to execute a step.
    /// @param proposalId The ID of the proposal to execute.
    /// @param proposal The details of the proposal.
    /// @param preciousTokens The tokens that the party considers precious.
    /// @param preciousTokenIds The token IDs associated with each precious token.
    /// @param progressData The data returned from the last `execute()` call, if any.
    /// @param extraData Off-chain data a proposal might need to execute a step.
    function execute(
        uint256 proposalId,
        Proposal memory proposal,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds,
        bytes calldata progressData,
        bytes calldata extraData
    ) external payable onlyActiveMember onlyWhenNotGloballyDisabled onlyDelegateCall {
        // Get information about the proposal.
        ProposalState storage proposalState = _proposalStateByProposalId[proposalId];
        // Proposal details must remain the same from `propose()`.
        _validateProposalHash(proposal, proposalState.hash);
        ProposalStateValues memory values = proposalState.values;
        ProposalStatus status = _getProposalStatus(values);
        // The proposal must be executable or have already been executed but still
        // has more steps to go.
        if (status != ProposalStatus.Ready && status != ProposalStatus.InProgress) {
            revert BadProposalStatusError(status);
        }
        if (status == ProposalStatus.Ready) {
            // If the proposal has not been executed yet, make sure it hasn't
            // expired. Note that proposals that have been executed
            // (but still have more steps) ignore `maxExecutableTime`.
            if (proposal.maxExecutableTime < block.timestamp) {
                revert ExecutionTimeExceededError(
                    proposal.maxExecutableTime,
                    uint40(block.timestamp)
                );
            }
            proposalState.values.executedTime = uint40(block.timestamp);
        }
        // Check that the precious list is valid.
        if (!_isPreciousListCorrect(preciousTokens, preciousTokenIds)) {
            revert BadPreciousListError();
        }
        // Preemptively set the proposal to completed to avoid it being executed
        // again in a deeper call.
        proposalState.values.completedTime = uint40(block.timestamp);
        // Execute the proposal.
        bool completed = _executeProposal(
            proposalId,
            proposal,
            preciousTokens,
            preciousTokenIds,
            _getProposalFlags(values),
            progressData,
            extraData
        );
        if (!completed) {
            // Proposal did not complete.
            proposalState.values.completedTime = 0;
        }
    }

    /// @notice Cancel a (probably stuck) InProgress proposal.
    /// @dev `proposal.cancelDelay` seconds must have passed since it was first
    ///      executed for this to be valid. The currently active proposal will
    ///      simply be yeeted out of existence so another proposal can execute.
    ///      This is intended to be a last resort and can leave the party in a
    ///      broken state. Whenever possible, active proposals should be
    ///      allowed to complete their lifecycle.
    /// @param proposalId The ID of the proposal to cancel.
    /// @param proposal The details of the proposal to cancel.
    function cancel(uint256 proposalId, Proposal calldata proposal) external onlyActiveMember {
        // Get information about the proposal.
        ProposalState storage proposalState = _proposalStateByProposalId[proposalId];
        // Proposal details must remain the same from `propose()`.
        _validateProposalHash(proposal, proposalState.hash);
        ProposalStateValues memory values = proposalState.values;
        {
            // Must be `InProgress`.
            ProposalStatus status = _getProposalStatus(values);
            if (status != ProposalStatus.InProgress) {
                revert BadProposalStatusError(status);
            }
        }
        {
            // Limit the `cancelDelay` to the global max and min cancel delay
            // to mitigate parties accidentally getting stuck forever by setting an
            // unrealistic `cancelDelay` or being reckless with too low a
            // cancel delay.
            uint256 cancelDelay = proposal.cancelDelay;
            uint256 globalMaxCancelDelay = _GLOBALS.getUint256(
                LibGlobals.GLOBAL_PROPOSAL_MAX_CANCEL_DURATION
            );
            uint256 globalMinCancelDelay = _GLOBALS.getUint256(
                LibGlobals.GLOBAL_PROPOSAL_MIN_CANCEL_DURATION
            );
            if (globalMaxCancelDelay != 0) {
                // Only if we have one set.
                if (cancelDelay > globalMaxCancelDelay) {
                    cancelDelay = globalMaxCancelDelay;
                }
            }
            if (globalMinCancelDelay != 0) {
                // Only if we have one set.
                if (cancelDelay < globalMinCancelDelay) {
                    cancelDelay = globalMinCancelDelay;
                }
            }
            uint256 cancelTime = values.executedTime + cancelDelay;
            // Must not be too early.
            if (block.timestamp < cancelTime) {
                revert ProposalCannotBeCancelledYetError(
                    uint40(block.timestamp),
                    uint40(cancelTime)
                );
            }
        }
        // Mark the proposal as cancelled by setting the completed time to the current
        // time with the high bit set.
        proposalState.values.completedTime = uint40(block.timestamp | UINT40_HIGH_BIT);
        {
            // Delegatecall into the proposal engine impl to perform the cancel.
            (bool success, bytes memory resultData) = (
                address(_getSharedProposalStorage().engineImpl)
            ).delegatecall(abi.encodeCall(IProposalExecutionEngine.cancelProposal, (proposalId)));
            if (!success) {
                resultData.rawRevert();
            }
        }
        emit ProposalCancelled(proposalId);
    }

    /// @notice As the DAO, execute an arbitrary function call from this contract.
    /// @dev Emergency actions must not be revoked for this to work.
    /// @param targetAddress The contract to call.
    /// @param targetCallData The data to pass to the contract.
    /// @param amountEth The amount of ETH to send to the contract.
    function emergencyExecute(
        address targetAddress,
        bytes calldata targetCallData,
        uint256 amountEth
    ) external payable onlyPartyDao onlyWhenEmergencyExecuteAllowed onlyDelegateCall {
        (bool success, bytes memory res) = targetAddress.call{ value: amountEth }(targetCallData);
        if (!success) {
            res.rawRevert();
        }
        emit EmergencyExecute(targetAddress, targetCallData, amountEth);
    }

    /// @notice Revoke the DAO's ability to call emergencyExecute().
    /// @dev Either the DAO or the party host can call this.
    function disableEmergencyExecute() external onlyPartyDaoOrHost {
        emergencyExecuteDisabled = true;
        emit EmergencyExecuteDisabled();
    }

    function _executeProposal(
        uint256 proposalId,
        Proposal memory proposal,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds,
        uint256 flags,
        bytes memory progressData,
        bytes memory extraData
    ) private returns (bool completed) {
        // Setup the arguments for the proposal execution engine.
        IProposalExecutionEngine.ExecuteProposalParams
            memory executeParams = IProposalExecutionEngine.ExecuteProposalParams({
                proposalId: proposalId,
                proposalData: proposal.proposalData,
                progressData: progressData,
                extraData: extraData,
                preciousTokens: preciousTokens,
                preciousTokenIds: preciousTokenIds,
                flags: flags
            });
        // Get the progress data returned after the proposal is executed.
        bytes memory nextProgressData;
        {
            // Execute the proposal.
            (bool success, bytes memory resultData) = address(
                _getSharedProposalStorage().engineImpl
            ).delegatecall(
                    abi.encodeCall(IProposalExecutionEngine.executeProposal, (executeParams))
                );
            if (!success) {
                resultData.rawRevert();
            }
            nextProgressData = abi.decode(resultData, (bytes));
        }
        emit ProposalExecuted(proposalId, msg.sender, nextProgressData);
        // If the returned progress data is empty, then the proposal completed
        // and it should not be executed again.
        return nextProgressData.length == 0;
    }

    // Get the most recent voting power snapshot <= timestamp using `hintindex` as a "hint".
    function _getVotingPowerSnapshotAt(
        address voter,
        uint40 timestamp,
        uint256 hintIndex
    ) internal view returns (VotingPowerSnapshot memory snap) {
        VotingPowerSnapshot[] storage snaps = _votingPowerSnapshotsByVoter[voter];
        uint256 snapsLength = snaps.length;
        if (snapsLength != 0) {
            if (
                // Hint is within bounds.
                hintIndex < snapsLength &&
                // Snapshot is not too recent.
                snaps[hintIndex].timestamp <= timestamp &&
                // Snapshot is not too old.
                (hintIndex == snapsLength - 1 || snaps[hintIndex + 1].timestamp > timestamp)
            ) {
                return snaps[hintIndex];
            }

            // Hint was wrong, fallback to binary search to find snapshot.
            hintIndex = findVotingPowerSnapshotIndex(voter, timestamp);
            // Check that snapshot was found.
            if (hintIndex != type(uint256).max) {
                return snaps[hintIndex];
            }
        }

        // No snapshot found.
        return snap;
    }

    // Transfers some voting power of `from` to `to`. The total voting power of
    // their respective delegates will be updated as well.
    function _transferVotingPower(address from, address to, uint256 power) internal {
        int192 powerI192 = power.safeCastUint256ToInt192();
        _adjustVotingPower(from, -powerI192, address(0));
        _adjustVotingPower(to, powerI192, address(0));
    }

    // Increase `voter`'s intrinsic voting power and update their delegate if delegate is nonzero.
    function _adjustVotingPower(address voter, int192 votingPower, address delegate) internal {
        VotingPowerSnapshot memory oldSnap = _getLastVotingPowerSnapshotForVoter(voter);
        address oldDelegate = delegationsByVoter[voter];
        // If `oldDelegate` is zero and `voter` never delegated, then have
        // `voter` delegate to themself.
        oldDelegate = oldDelegate == address(0) ? voter : oldDelegate;
        // If the new `delegate` is zero, use the current (old) delegate.
        delegate = delegate == address(0) ? oldDelegate : delegate;

        VotingPowerSnapshot memory newSnap = VotingPowerSnapshot({
            timestamp: uint40(block.timestamp),
            delegatedVotingPower: oldSnap.delegatedVotingPower,
            intrinsicVotingPower: (oldSnap.intrinsicVotingPower.safeCastUint96ToInt192() +
                votingPower).safeCastInt192ToUint96(),
            isDelegated: delegate != voter
        });
        _insertVotingPowerSnapshot(voter, newSnap);
        delegationsByVoter[voter] = delegate;
        // Handle rebalancing delegates.
        _rebalanceDelegates(voter, oldDelegate, delegate, oldSnap, newSnap);
    }

    // Update the delegated voting power of the old and new delegates delegated to
    // by `voter` based on the snapshot change.
    function _rebalanceDelegates(
        address voter,
        address oldDelegate,
        address newDelegate,
        VotingPowerSnapshot memory oldSnap,
        VotingPowerSnapshot memory newSnap
    ) private {
        if (newDelegate == address(0) || oldDelegate == address(0)) {
            revert InvalidDelegateError();
        }
        if (oldDelegate != voter && oldDelegate != newDelegate) {
            // Remove past voting power from old delegate.
            VotingPowerSnapshot memory oldDelegateSnap = _getLastVotingPowerSnapshotForVoter(
                oldDelegate
            );
            VotingPowerSnapshot memory updatedOldDelegateSnap = VotingPowerSnapshot({
                timestamp: uint40(block.timestamp),
                delegatedVotingPower: oldDelegateSnap.delegatedVotingPower -
                    oldSnap.intrinsicVotingPower,
                intrinsicVotingPower: oldDelegateSnap.intrinsicVotingPower,
                isDelegated: oldDelegateSnap.isDelegated
            });
            _insertVotingPowerSnapshot(oldDelegate, updatedOldDelegateSnap);
        }
        if (newDelegate != voter) {
            // Not delegating to self.
            // Add new voting power to new delegate.
            VotingPowerSnapshot memory newDelegateSnap = _getLastVotingPowerSnapshotForVoter(
                newDelegate
            );
            uint96 newDelegateDelegatedVotingPower = newDelegateSnap.delegatedVotingPower +
                newSnap.intrinsicVotingPower;
            if (newDelegate == oldDelegate) {
                // If the old and new delegate are the same, subtract the old
                // intrinsic voting power of the voter, or else we will double
                // count a portion of it.
                newDelegateDelegatedVotingPower -= oldSnap.intrinsicVotingPower;
            }
            VotingPowerSnapshot memory updatedNewDelegateSnap = VotingPowerSnapshot({
                timestamp: uint40(block.timestamp),
                delegatedVotingPower: newDelegateDelegatedVotingPower,
                intrinsicVotingPower: newDelegateSnap.intrinsicVotingPower,
                isDelegated: newDelegateSnap.isDelegated
            });
            _insertVotingPowerSnapshot(newDelegate, updatedNewDelegateSnap);
        }
    }

    // Append a new voting power snapshot, overwriting the last one if possible.
    function _insertVotingPowerSnapshot(address voter, VotingPowerSnapshot memory snap) private {
        VotingPowerSnapshot[] storage voterSnaps = _votingPowerSnapshotsByVoter[voter];
        uint256 n = voterSnaps.length;
        // If same timestamp as last entry, overwrite the last snapshot, otherwise append.
        if (n != 0) {
            VotingPowerSnapshot memory lastSnap = voterSnaps[n - 1];
            if (lastSnap.timestamp == snap.timestamp) {
                voterSnaps[n - 1] = snap;
                return;
            }
        }
        voterSnaps.push(snap);
    }

    function _getLastVotingPowerSnapshotForVoter(
        address voter
    ) private view returns (VotingPowerSnapshot memory snap) {
        VotingPowerSnapshot[] storage voterSnaps = _votingPowerSnapshotsByVoter[voter];
        uint256 n = voterSnaps.length;
        if (n != 0) {
            snap = voterSnaps[n - 1];
        }
    }

    function _getProposalFlags(ProposalStateValues memory pv) private pure returns (uint256) {
        if (_isUnanimousVotes(pv.votes, pv.totalVotingPower)) {
            return LibProposal.PROPOSAL_FLAG_UNANIMOUS;
        }
        return 0;
    }

    function _getProposalStatus(
        ProposalStateValues memory pv
    ) private view returns (ProposalStatus status) {
        // Never proposed.
        if (pv.proposedTime == 0) {
            return ProposalStatus.Invalid;
        }
        // Executed at least once.
        if (pv.executedTime != 0) {
            if (pv.completedTime == 0) {
                return ProposalStatus.InProgress;
            }
            // completedTime high bit will be set if cancelled.
            if (pv.completedTime & UINT40_HIGH_BIT == UINT40_HIGH_BIT) {
                return ProposalStatus.Cancelled;
            }
            return ProposalStatus.Complete;
        }
        // Vetoed.
        if (pv.votes == type(uint96).max) {
            return ProposalStatus.Defeated;
        }
        uint40 t = uint40(block.timestamp);
        GovernanceValues memory gv = _governanceValues;
        if (pv.passedTime != 0) {
            // Ready.
            if (pv.passedTime + gv.executionDelay <= t) {
                return ProposalStatus.Ready;
            }
            // If unanimous, we skip the execution delay.
            if (_isUnanimousVotes(pv.votes, pv.totalVotingPower)) {
                return ProposalStatus.Ready;
            }
            // Passed.
            return ProposalStatus.Passed;
        }
        // Voting window expired.
        if (pv.proposedTime + gv.voteDuration <= t) {
            return ProposalStatus.Defeated;
        }
        return ProposalStatus.Voting;
    }

    function _isUnanimousVotes(
        uint96 totalVotes,
        uint96 totalVotingPower
    ) private pure returns (bool) {
        uint256 acceptanceRatio = (totalVotes * 1e4) / totalVotingPower;
        // If >= 99.99% acceptance, consider it unanimous.
        // The minting formula for voting power is a bit lossy, so we check
        // for slightly less than 100%.
        return acceptanceRatio >= 0.9999e4;
    }

    function _areVotesPassing(
        uint96 voteCount,
        uint96 totalVotingPower,
        uint16 passThresholdBps
    ) private pure returns (bool) {
        return (uint256(voteCount) * 1e4) / uint256(totalVotingPower) >= uint256(passThresholdBps);
    }

    function _setPreciousList(
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    ) private {
        if (preciousTokens.length != preciousTokenIds.length) {
            revert MismatchedPreciousListLengths();
        }
        preciousListHash = _hashPreciousList(preciousTokens, preciousTokenIds);
    }

    function _isPreciousListCorrect(
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    ) private view returns (bool) {
        return preciousListHash == _hashPreciousList(preciousTokens, preciousTokenIds);
    }

    function _hashPreciousList(
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    ) internal pure returns (bytes32 h) {
        assembly {
            mstore(0x00, keccak256(add(preciousTokens, 0x20), mul(mload(preciousTokens), 0x20)))
            mstore(0x20, keccak256(add(preciousTokenIds, 0x20), mul(mload(preciousTokenIds), 0x20)))
            h := keccak256(0x00, 0x40)
        }
    }

    // Assert that the hash of a proposal matches expectedHash.
    function _validateProposalHash(Proposal memory proposal, bytes32 expectedHash) private pure {
        bytes32 actualHash = getProposalHash(proposal);
        if (expectedHash != actualHash) {
            revert BadProposalHashError(actualHash, expectedHash);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "./LibRawResult.sol";

interface IReadOnlyDelegateCall {
    // Marked `view` so that `_readOnlyDelegateCall` can be `view` as well.
    function delegateCallAndRevert(address impl, bytes memory callData) external view;
}

// Inherited by contracts to perform read-only delegate calls.
abstract contract ReadOnlyDelegateCall {
    using LibRawResult for bytes;

    // Delegatecall into implement and revert with the raw result.
    function delegateCallAndRevert(address impl, bytes memory callData) external {
        // Attempt to gate to only `_readOnlyDelegateCall()` invocations.
        require(msg.sender == address(this));
        (bool s, bytes memory r) = impl.delegatecall(callData);
        // Revert with success status and return data.
        abi.encode(s, r).rawRevert();
    }

    // Perform a `delegateCallAndRevert()` then return the raw result data.
    function _readOnlyDelegateCall(address impl, bytes memory callData) internal view {
        try IReadOnlyDelegateCall(address(this)).delegateCallAndRevert(impl, callData) {
            // Should never happen.
            assert(false);
        } catch (bytes memory r) {
            (bool success, bytes memory resultData) = abi.decode(r, (bool, bytes));
            if (!success) {
                resultData.rawRevert();
            }
            resultData.rawReturn();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: AGPL-3.0-only
// Based on solmate commit 1681dc505f4897ef636f0435d01b1aa027fdafaf (v6.4.0)
//  @ https://github.com/Rari-Capital/solmate/blob/1681dc505f4897ef636f0435d01b1aa027fdafaf/src/tokens/ERC1155.sol
// Only modified to inherit IERC721 and EIP165.
pragma solidity >=0.8.0;

// NOTE: Only modified to inherit IERC20 and EIP165
import "../../tokens/IERC721.sol";
import "../../utils/EIP165.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is IERC721, EIP165 {
    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id /* view */) public virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        // NOTE: modified from original to call super.
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(address to, uint256 id, bytes memory data) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "solmate/utils/SSTORE2.sol";
import "../utils/Multicall.sol";

contract RendererStorage is Multicall {
    error AlreadySetError();
    error NotOwnerError(address caller, address owner);

    event OwnershipTransferred(address previousOwner, address newOwner);

    uint256 constant CROWDFUND_CARD_DATA = 0;
    uint256 constant PARTY_CARD_DATA = 1;

    /// @notice Address allowed to store new data.
    address public owner;

    /// @notice Customization presets by ID, used for rendering cards. Begins at
    ///         1, 0 is reserved to indicate in `getPresetFor()` that a
    ///         party instance use the preset set by the crowdfund instance that
    ///         created it.
    mapping(uint256 => bytes) public customizationPresets;
    /// @notice Customization preset used by a crowdfund or party instance.
    mapping(address => uint256) public getPresetFor;
    /// @notice Addresses where URI data chunks are stored.
    mapping(uint256 => address) public files;

    modifier onlyOwner() {
        address owner_ = owner;
        if (msg.sender != owner_) {
            revert NotOwnerError(msg.sender, owner_);
        }

        _;
    }

    constructor(address _owner) {
        // Set the address allowed to write new data.
        owner = _owner;

        // Write URI data used by V1 of the renderers:

        files[CROWDFUND_CARD_DATA] = SSTORE2.write(
            bytes(
                '<path class="o" d="M118.4 419.5h5.82v1.73h-4.02v1.87h3.74v1.73h-3.74v1.94h4.11v1.73h-5.91v-9Zm9.93 1.76h-2.6v-1.76h7.06v1.76h-2.61v7.24h-1.85v-7.24Zm6.06-1.76h1.84v3.55h3.93v-3.55H142v9h-1.84v-3.67h-3.93v3.67h-1.84v-9Z"/><path class="o" d="M145 413a4 4 0 0 1 4 4v14a4 4 0 0 1-4 4H35a4 4 0 0 1-4-4v-14a4 4 0 0 1 4-4h110m0-1H35a5 5 0 0 0-5 5v14a5 5 0 0 0 5 5h110a5 5 0 0 0 5-5v-14a5 5 0 0 0-5-5Z"/><path d="M239.24 399.83h3.04c1.7 0 2.82 1 2.82 2.55 0 2.1-1.27 3.32-3.57 3.32h-1.97l-.71 3.3h-1.56l1.96-9.17Zm2.34 4.38c1.23 0 1.88-.58 1.88-1.68 0-.73-.49-1.2-1.48-1.2h-1.51l-.6 2.88h1.7Zm3.57 1.86c0-2.27 1.44-3.83 3.57-3.83 1.82 0 3.06 1.25 3.06 3.09 0 2.28-1.43 3.83-3.57 3.83-1.82 0-3.06-1.25-3.06-3.09Zm3.13 1.74c1.19 0 1.93-1.02 1.93-2.52 0-1.06-.62-1.69-1.56-1.69-1.19 0-1.93 1.02-1.93 2.52 0 1.06.62 1.69 1.56 1.69Zm4.74-5.41h1.49l.28 4.73 2.25-4.73h1.64l.23 4.77 2.25-4.77h1.56l-3.3 6.61h-1.62l-.25-5.04-2.42 5.04h-1.63l-.48-6.61Zm9.54 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm3.46-2.59h1.55l-.28 1.28c.81-1.7 2.56-1.36 2.77-1.29l-.35 1.46c-.18-.06-2.3-.63-2.82 1.68l-.74 3.48h-1.55l1.42-6.61Zm3.91 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm2.25 1.36c0-2.44 1.36-4.1 3.26-4.1 1 0 1.76.53 2.05 1.31l.79-3.72h1.55l-1.96 9.17h-1.55l.2-.92a2.15 2.15 0 0 1-1.92 1.08c-1.49 0-2.43-1.18-2.43-2.82Zm3 1.51c.88 0 1.51-.58 1.73-1.56l.17-.81c.24-1.1-.31-1.93-1.36-1.93-1.19 0-1.94 1.08-1.94 2.59 0 1.06.55 1.71 1.4 1.71Zm9.6-.01-.25 1.16h-1.55l1.96-9.17h1.55l-.73 3.47a2.35 2.35 0 0 1 1.99-1.05c1.49 0 2.35 1.16 2.35 2.76 0 2.52-1.36 4.16-3.21 4.16-.98 0-1.81-.53-2.1-1.32Zm1.83.01c1.16 0 1.87-1.06 1.87-2.61 0-1.04-.5-1.69-1.39-1.69s-1.52.56-1.73 1.55l-.17.79c-.24 1.14.34 1.97 1.42 1.97Zm5.68 1.16-1.04-6.62h1.52l.66 4.75 2.66-4.75h1.69l-5.31 9.13h-1.73l1.55-2.51Zm23.48-6.8a42.14 42.14 0 0 0-.75 6.01 43.12 43.12 0 0 0 5.58 2.35 42.54 42.54 0 0 0 5.58-2.35 45.32 45.32 0 0 0-.75-6.01c-.91-.79-2.6-2.21-4.83-3.66a42.5 42.5 0 0 0-4.83 3.66Zm13.07-7.95s.82-.29 1.76-.45a14.9 14.9 0 0 0-9.53-3.81c.66.71 1.28 1.67 1.84 2.75 1.84.22 4.07.7 5.92 1.51Zm-2.71 18.36c-2.06-.4-4.05-.97-5.53-1.51a38.65 38.65 0 0 1-5.53 1.51c.12 1.5.35 3.04.76 4.58 0 0 1.54 1.82 4.78 2.8 3.23-.98 4.78-2.8 4.78-2.8.4-1.53.64-3.08.76-4.58Zm-13.77-18.37a22.3 22.3 0 0 1 5.93-1.51 12.4 12.4 0 0 1 1.84-2.75 14.97 14.97 0 0 0-9.53 3.81c.95.16 1.76.45 1.76.45Zm-4.72 8.77a25.74 25.74 0 0 0 3.58 2.94 37.48 37.48 0 0 1 4.08-4.04c.27-1.56.77-3.57 1.46-5.55a25.24 25.24 0 0 0-4.34-1.63s-2.35.42-4.81 2.74c-.77 3.29.04 5.54.04 5.54Zm25.92 0s.81-2.25.04-5.54c-2.46-2.31-4.81-2.74-4.81-2.74-1.53.42-2.99.99-4.34 1.63a37.79 37.79 0 0 1 1.46 5.55 37.44 37.44 0 0 1 4.08 4.04 25.86 25.86 0 0 0 3.58-2.94Zm-26.38.2s-.66-.56-1.27-1.3c-.7 3.34-.27 6.93 1.46 10.16.28-.93.8-1.94 1.46-2.97a22.32 22.32 0 0 1-1.66-5.88Zm8.24 14.27a22.07 22.07 0 0 1-4.27-4.38c-1.22.06-2.36 0-3.3-.22a14.91 14.91 0 0 0 8.07 6.34c-.34-.9-.5-1.75-.5-1.75Zm18.6-14.27s.66-.56 1.27-1.3c.7 3.34.27 6.93-1.46 10.16-.28-.93-.8-1.94-1.46-2.97a22.32 22.32 0 0 0 1.66-5.88Zm-8.24 14.27a22.07 22.07 0 0 0 4.27-4.38c1.22.06 2.36 0 3.3-.22a14.91 14.91 0 0 1-8.07 6.34c.34-.9.5-1.75.5-1.75ZM330 391.84l-4.12 2.45 1.26 3.91h5.72l1.26-3.91-4.12-2.45Zm-11.4 19.74 4.18 2.35 2.75-3.05-2.86-4.95-4.02.86-.06 4.79Zm22.79 0-.06-4.79-4.02-.86-2.86 4.95 2.75 3.05 4.18-2.35Z" style="fill:#00c1fa"/><use height="300" transform="matrix(1 0 0 .09 29.85 444)" width="300.15" xlink:href="#a"/><use height="21.15" transform="translate(30 446.92)" width="300" xlink:href="#b"/><g><path d="m191.54 428.67-28.09-24.34A29.98 29.98 0 0 0 143.8 397H30a15 15 0 0 0-15 15v98a15 15 0 0 0 15 15h300a15 15 0 0 0 15-15v-59a15 15 0 0 0-15-15H211.19a30 30 0 0 1-19.65-7.33Z" style="fill:url(#i)"/></g></svg>'
            )
        );

        files[PARTY_CARD_DATA] = SSTORE2.write(
            bytes(
                ' d="M188 444.3h2.4l2.6 8.2 2.7-8.2h2.3l-3.7 10.7h-2.8l-3.5-10.7zm10.5 5.3c0-3.2 2.2-5.6 5.3-5.6 3.1 0 5.3 2.3 5.3 5.6 0 3.2-2.2 5.5-5.3 5.5-3.1.1-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.4 0-2.1-1.1-3.5-3-3.5s-3 1.3-3 3.5c0 2.1 1.1 3.4 3 3.4zm8.7-6.7h-3.1v-2.1h8.4v2.1h-3.1v8.6h-2.2v-8.6zm6.9-2.1h2.2V455h-2.2v-10.7zm4.3 0h2.9l4 8.2v-8.2h2.1V455h-2.9l-4-8.2v8.2h-2.1v-10.7zm10.6 5.4c0-3.4 2.3-5.6 6-5.6 1.2 0 2.3.2 3.1.6v2.3c-.9-.6-1.9-.8-3.1-.8-2.4 0-3.8 1.3-3.8 3.5 0 2.1 1.3 3.4 3.5 3.4.5 0 .9-.1 1.3-.2v-2.2h-2.2v-1.9h4.3v5.6c-1 .5-2.2.8-3.4.8-3.5 0-5.7-2.2-5.7-5.5zm15.1-5.4h4.3c2.3 0 3.7 1.3 3.7 3.5s-1.4 3.5-3.7 3.5h-2.1v3.7h-2.2v-10.7zm4.1 5c1.1 0 1.6-.5 1.6-1.5s-.5-1.5-1.6-1.5h-1.9v2.9h1.9zm4.8.3c0-3.2 2.2-5.6 5.3-5.6 3.1 0 5.3 2.3 5.3 5.6 0 3.2-2.2 5.5-5.3 5.5-3.1.1-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.4 0-2.1-1.1-3.5-3-3.5s-3 1.3-3 3.5c0 2.1 1.1 3.4 3 3.4zm5.8-8.8h2.3l1.7 7.8 1.9-7.8h2.4l1.8 7.8 1.8-7.8h2.3l-2.7 10.7h-2.5l-1.9-8.2-1.8 8.2h-2.5l-2.8-10.7zm15.4 0h6.9v2.1H287v2.2h4.5v2.1H287v2.3h4.9v2.1h-7v-10.8zm9 0h4.5c2 0 3.3 1.3 3.3 3.2 0 1.9-1.2 3.1-3 3.2l3.5 4.3h-2.7l-3.5-4.4v4.4h-2.1v-10.7zm4.1 4.8c1 0 1.5-.5 1.5-1.4 0-.9-.6-1.4-1.5-1.4h-2v2.9h2zM30 444.3h4.3c3 0 5.2 2.1 5.2 5.4s-2.1 5.4-5.2 5.4H30v-10.8zm4 8.6c2.1 0 3.2-1.2 3.2-3.2s-1.2-3.3-3.2-3.3h-1.8v6.5H34zm7.7-8.6h2.2V455h-2.2v-10.7zm4.8 10V452c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.7-1.5-2.7-3.1 0-2 1.5-3.2 3.9-3.2 1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4-1.1-.2-2.3-.5-3.3-1.1zm12-7.9h-3.1v-2.1h8.4v2.1h-3.1v8.6h-2.2v-8.6zm7.5-2.1h4.5c2 0 3.3 1.3 3.3 3.2 0 1.9-1.2 3.1-3 3.2l3.5 4.3h-2.7l-3.5-4.4v4.4H66v-10.7zm4.1 4.8c1 0 1.5-.5 1.5-1.4s-.6-1.4-1.5-1.4h-2v2.9h2zm6.1-4.8h2.2V455h-2.2v-10.7zm5 0h4.5c2 0 3.2 1.1 3.2 2.8 0 1.1-.5 1.9-1.4 2.3 1.1.3 1.8 1.3 1.8 2.5 0 1.9-1.3 3.1-3.5 3.1h-4.6v-10.7zm4.2 4.4c.9 0 1.4-.5 1.4-1.3s-.5-1.3-1.4-1.3h-2.1v2.5l2.1.1zm.3 4.4c.9 0 1.5-.5 1.5-1.3s-.6-1.3-1.5-1.3h-2.4v2.6h2.4zm5.7-2.5v-6.3h2.2v6.3c0 1.6.9 2.5 2.3 2.5s2.3-.9 2.3-2.5v-6.3h2.2v6.3c0 2.9-1.7 4.6-4.5 4.6s-4.6-1.7-4.5-4.6zm14.2-4.2h-3.1v-2.1h8.4v2.1h-3.1v8.6h-2.2v-8.6zm7.5-2.1h2.2V455h-2.2v-10.7zm4.5 5.3c0-3.2 2.2-5.6 5.3-5.6s5.3 2.3 5.3 5.6-2.2 5.5-5.3 5.5-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.5s-1.2-3.5-3-3.5-3 1.3-3 3.5 1.1 3.5 3 3.5zm7.5-8.8h2.9l4 8.2v-8.2h2.1V455h-2.9l-4-8.2v8.2h-2.1v-10.7zm11.7 10V452c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.6-1.5-2.6-3.1 0-2 1.5-3.2 3.9-3.2 1.1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4a9.7 9.7 0 0 1-3.4-1.1zM30 259.3h4.3c2.2 0 3.7 1.3 3.7 3.5s-1.4 3.5-3.7 3.5h-2.1v3.7H30v-10.7zm4.1 5c1.1 0 1.6-.5 1.6-1.5s-.5-1.5-1.6-1.5h-1.9v2.9h1.9zm6.1-5h4.5c2 0 3.3 1.3 3.3 3.2 0 1.9-1.2 3.1-3 3.2l3.5 4.3h-2.7l-3.5-4.4v4.4h-2.1v-10.7zm4.1 4.8c1 0 1.5-.5 1.5-1.4s-.6-1.4-1.5-1.4h-2v2.9h2zm5.4.5c0-3.2 2.2-5.6 5.3-5.6s5.3 2.3 5.3 5.6-2.2 5.5-5.3 5.5-5.3-2.2-5.3-5.5zm5.3 3.5c1.8 0 3-1.3 3-3.5s-1.2-3.5-3-3.5-3 1.3-3 3.5 1.1 3.5 3 3.5zm7.6-8.8h4.3c2.2 0 3.7 1.3 3.7 3.5s-1.4 3.5-3.7 3.5h-2.1v3.7h-2.2v-10.7zm4.1 5c1.1 0 1.6-.5 1.6-1.5s-.6-1.5-1.6-1.5h-1.9v2.9h1.9zm5.4.4c0-3.2 2.2-5.6 5.3-5.6s5.3 2.3 5.3 5.6-2.2 5.5-5.3 5.5-5.3-2.3-5.3-5.5zm5.4 3.4c1.8 0 3-1.3 3-3.5s-1.2-3.5-3-3.5-3 1.3-3 3.5 1.1 3.5 3 3.5zm7.2 1.2V267c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.7-1.5-2.7-3.1 0-2 1.5-3.2 3.9-3.2 1.1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4-1.1-.2-2.3-.5-3.3-1.1zm12.2-10h2.8l3.7 10.7h-2.3l-.8-2.5h-4l-.8 2.5h-2.2l3.6-10.7zm2.8 6.3-1.4-4.2-1.4 4.2h2.8zm5.7-6.3h2.2v8.6h4.7v2.1h-6.9v-10.7zm9.1 10V267c1 .7 2.1 1.1 3.2 1.1s1.7-.5 1.7-1.2-.4-1-1.2-1.2l-1.2-.3c-1.8-.5-2.7-1.5-2.7-3.1 0-2 1.5-3.2 3.9-3.2 1.1 0 2.1.2 2.9.7v2.3c-.9-.6-1.9-.8-3-.8-.9 0-1.6.4-1.6 1.1 0 .6.4.9 1.2 1.1l1.3.4c1.8.5 2.6 1.4 2.6 3.1 0 2.1-1.5 3.4-3.8 3.4-1.1-.2-2.3-.5-3.3-1.1zm-84.5-70h2.9l4 8.2v-8.2H39V210h-2.9l-4-8.2v8.2H30v-10.7zm14.7 0h2.8l3.7 10.7h-2.3l-.8-2.6h-4l-.8 2.6H41l3.7-10.7zm2.8 6.2-1.4-4.2-1.4 4.2h2.8zm5.7-6.2h3.3l2.5 8.2 2.5-8.2h3.3V210h-2v-8.6L60 210h-2.1l-2.7-8.5v8.5h-2v-10.7zm14.4 0h6.9v2.1h-4.8v2.2h4.4v2.1h-4.4v2.3h4.9v2.1h-7v-10.8z" /><path d="M239.24 24.83h3.04c1.7 0 2.82 1 2.82 2.55 0 2.1-1.27 3.32-3.57 3.32h-1.97l-.71 3.3h-1.56l1.96-9.17Zm2.34 4.38c1.23 0 1.88-.58 1.88-1.68 0-.73-.49-1.2-1.48-1.2h-1.51l-.6 2.88h1.7Zm3.57 1.86c0-2.27 1.44-3.83 3.57-3.83 1.82 0 3.06 1.25 3.06 3.09 0 2.28-1.43 3.83-3.57 3.83-1.82 0-3.06-1.25-3.06-3.09Zm3.13 1.74c1.19 0 1.93-1.02 1.93-2.52 0-1.06-.62-1.69-1.56-1.69-1.19 0-1.93 1.02-1.93 2.52 0 1.06.62 1.69 1.56 1.69Zm4.74-5.41h1.49l.28 4.73 2.25-4.73h1.64l.23 4.77 2.25-4.77h1.56l-3.3 6.61h-1.62l-.25-5.04-2.42 5.04h-1.63l-.48-6.61Zm9.54 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm3.46-2.59h1.55l-.28 1.28c.81-1.7 2.56-1.36 2.77-1.29l-.35 1.46c-.18-.06-2.3-.63-2.82 1.68l-.74 3.48h-1.55l1.42-6.61Zm3.91 3.66c0-2.27 1.45-3.81 3.6-3.81 2 0 3.05 1.58 2.33 3.92h-4.46c0 1.1.81 1.68 2.05 1.68.8 0 1.45-.2 2.1-.59l-.31 1.46a4.2 4.2 0 0 1-2.04.44c-2.06 0-3.26-1.19-3.26-3.11Zm4.7-1.07c.12-.86-.31-1.46-1.22-1.46s-1.57.61-1.82 1.46h3.05Zm2.25 1.36c0-2.44 1.36-4.1 3.26-4.1 1 0 1.76.53 2.05 1.31l.79-3.72h1.55l-1.96 9.17h-1.55l.2-.92a2.15 2.15 0 0 1-1.92 1.08c-1.49 0-2.43-1.18-2.43-2.82Zm3 1.51c.88 0 1.51-.58 1.73-1.56l.17-.81c.24-1.1-.31-1.93-1.36-1.93-1.19 0-1.94 1.08-1.94 2.59 0 1.06.55 1.71 1.4 1.71Zm9.6-.01-.25 1.16h-1.55l1.96-9.17h1.55l-.73 3.47a2.35 2.35 0 0 1 1.99-1.05c1.49 0 2.35 1.16 2.35 2.76 0 2.52-1.36 4.16-3.21 4.16-.98 0-1.81-.53-2.1-1.32Zm1.83.01c1.16 0 1.87-1.06 1.87-2.61 0-1.04-.5-1.69-1.39-1.69s-1.52.56-1.73 1.55l-.17.79c-.24 1.14.34 1.97 1.42 1.97Zm5.68 1.16-1.04-6.62h1.52l.66 4.75 2.66-4.75h1.69l-5.31 9.13h-1.73l1.55-2.51Zm23.47-6.8c.91-.79 2.6-2.21 4.83-3.66a42.5 42.5 0 0 1 4.83 3.66c.23 1.18.62 3.36.75 6.01a43.12 43.12 0 0 1-5.58 2.35 42.54 42.54 0 0 1-5.58-2.35c.14-2.65.53-4.83.75-6.01Zm13.07-7.95s.82-.29 1.76-.45a14.9 14.9 0 0 0-9.53-3.81c.66.71 1.28 1.67 1.84 2.75 1.84.22 4.07.7 5.92 1.51Zm-2.71 18.36c-2.06-.4-4.05-.97-5.53-1.51a38.65 38.65 0 0 1-5.53 1.51c.12 1.5.35 3.04.76 4.58 0 0 1.54 1.82 4.78 2.8 3.23-.98 4.78-2.8 4.78-2.8.4-1.53.64-3.08.76-4.58Zm-13.77-18.37a22.3 22.3 0 0 1 5.93-1.51 12.4 12.4 0 0 1 1.84-2.75 14.97 14.97 0 0 0-9.53 3.81c.95.16 1.76.45 1.76.45Zm-4.72 8.77a25.74 25.74 0 0 0 3.58 2.94 37.48 37.48 0 0 1 4.08-4.04c.27-1.56.77-3.57 1.46-5.55a25.24 25.24 0 0 0-4.34-1.63s-2.35.42-4.81 2.74c-.77 3.29.04 5.54.04 5.54Zm25.92 0s.81-2.25.04-5.54c-2.46-2.31-4.81-2.74-4.81-2.74-1.53.42-2.99.99-4.34 1.63a37.79 37.79 0 0 1 1.46 5.55 37.44 37.44 0 0 1 4.08 4.04 25.86 25.86 0 0 0 3.58-2.94Zm-26.38.2s-.66-.56-1.27-1.3c-.7 3.34-.27 6.93 1.46 10.16.28-.93.8-1.94 1.46-2.97a22.32 22.32 0 0 1-1.66-5.88Zm8.24 14.27a22.07 22.07 0 0 1-4.27-4.38c-1.22.06-2.36 0-3.3-.22a14.91 14.91 0 0 0 8.07 6.34c-.34-.9-.5-1.75-.5-1.75Zm18.6-14.27s.66-.56 1.27-1.3c.7 3.34.27 6.93-1.46 10.16-.28-.93-.8-1.94-1.46-2.97a22.32 22.32 0 0 0 1.66-5.88Zm-8.24 14.27a22.07 22.07 0 0 0 4.27-4.38c1.22.06 2.36 0 3.3-.22a14.91 14.91 0 0 1-8.07 6.34c.34-.9.5-1.75.5-1.75Zm-5.18-25.66-4.12 2.45 1.26 3.91h5.72l1.26-3.91-4.12-2.45Zm-11.4 19.74 4.18 2.35 2.75-3.05-2.86-4.95-4.02.86-.06 4.79Zm22.79 0-.06-4.79-4.02-.86-2.86 4.95 2.75 3.05 4.18-2.35Z" style="fill:#00c1fa"/><path d="M106.67 109.1a304.9 304.9 0 0 0-3.72-10.89c5.04-5.53 35.28-40.74 24.54-68.91 10.57 10.67 8.19 28.85 3.59 41.95-4.79 13.14-13.43 26.48-24.4 37.84Zm30.89 20.82c-5.87 6.12-20.46 17.92-21.67 18.77a99.37 99.37 0 0 0 7.94 6.02 133.26 133.26 0 0 0 20.09-18.48 353.47 353.47 0 0 0-6.36-6.31Zm-29.65-16.74a380.9 380.9 0 0 1 3.13 11.56c-4.8-1.37-8.66-2.53-12.36-3.82a123.4 123.4 0 0 1-21.16 13.21l15.84 5.47c14.83-8.23 28.13-20.82 37.81-34.68 0 0 8.56-12.55 12.42-23.68 2.62-7.48 4.46-16.57 3.49-24.89-2.21-12.27-6.95-15.84-9.32-17.66 6.16 5.72 3.25 27.8-2.79 39.89-6.08 12.16-15.73 24.27-27.05 34.59Zm59.05-37.86c-.03 7.72-3.05 15.69-6.44 22.69 1.7 2.2 3.18 4.36 4.42 6.49 7.97-16.51 3.74-26.67 2.02-29.18ZM61.18 128.51l12.5 4.3a101.45 101.45 0 0 0 21.42-13.19 163.26 163.26 0 0 1-10.61-4.51 101.28 101.28 0 0 1-23.3 13.4Zm87.78-42.73c.86.77 5.44 5.18 6.75 6.59 6.39-16.61.78-28.86-1.27-30.56.72 8.05-2.02 16.51-5.48 23.98Zm-14.29 40.62-2.47-15.18a142.42 142.42 0 0 1-35.74 29.45c6.81 2.36 12.69 4.4 15.45 5.38a115.98 115.98 0 0 0 22.75-19.66Zm-42.62 34.73c4.48 2.93 12.94 4.24 18.8 1.23 6.03-3.84-.6-8.34-8.01-9.88-9.8-2.03-16.82 1.22-13.4 6.21.41.6 1.19 1.5 2.62 2.44m-1.84.4c-3.56-2.37-6.77-7.2-.23-10.08 10.41-3.43 28.39 3.2 24.99 9.22-.58 1.04-1.46 1.6-2.38 2.19h-.03v.02h-.03v.02h-.03c-7.04 3.65-17.06 2.13-22.3-1.36m5.48-3.86a4.94 4.94 0 0 0 5.06.49l1.35-.74-4.68-2.38-1.47.79c-.38.22-1.53.88-.26 1.84m-1.7.59c-2.35-1.57-.78-2.61-.02-3.11 1.09-.57 2.19-1.15 3.28-1.77 6.95 3.67 7.22 3.81 13.19 6.17l-1.38.81c-1.93-.78-4.52-1.82-6.42-2.68.86 1.4 1.99 3.27 2.9 4.64l-1.68.87c-.75-1.28-1.76-2.99-2.47-4.29-3.19 2.06-6.99-.36-7.42-.64" style="fill:url(#f2)"/><path d="M159.13 52.37C143.51 24.04 119.45 15 103.6 15c-11.92 0-25.97 5.78-36.84 13.17 9.54 4.38 21.86 15.96 22.02 16.11-7.94-3.05-17.83-6.72-33.23-7.87a135.1 135.1 0 0 0-19.77 20.38c.77 7.66 2.88 15.68 2.88 15.68-6.28-4.75-11.02-4.61-18 9.45-5.4 12.66-6.93 24.25-4.65 33.18 0 0 4.72 26.8 36.23 40.07-1.3-4.61-1.58-9.91-.93-15.73a87.96 87.96 0 0 1-15.63-9.87c.79-6.61 2.79-13.82 6-21.36 4.42-10.66 4.35-15.14 4.35-15.19.03.07 5.48 12.43 12.95 22.08 4.23-8.84 9.46-16.08 13.67-21.83l-3.77-6.75a143.73 143.73 0 0 1 18.19-18.75c2.05 1.07 4.79 2.47 6.84 3.58 8.68-7.27 19.25-14.05 30.56-18.29-7-11.49-16.02-19.27-16.02-19.27s27.7 2.74 42.02 15.69a25.8 25.8 0 0 1 8.65 2.89ZM28.58 107.52a70.1 70.1 0 0 0-2.74 12.52 55.65 55.65 0 0 1-6.19-8.84 69.17 69.17 0 0 1 2.65-12.1c1.77-5.31 3.35-5.91 5.86-2.23v-.05c2.14 3.07 1.81 6.14.42 10.7ZM61.69 72.2l-.05.05a221.85 221.85 0 0 1-7.77-18.1l.14-.14a194.51 194.51 0 0 1 18.56 6.98 144.44 144.44 0 0 0-10.88 11.22Zm54.84-47.38c-4.42.7-9.02 1.95-13.67 3.72a65.03 65.03 0 0 0-7.81-5.31 66.04 66.04 0 0 1 13.02-3.54c1.53-.19 6.23-.79 10.32 2.42v-.05c2.47 1.91.14 2.37-1.86 2.75Z" style="fill:url(#h)"/>'
            )
        );
    }

    /// @notice Transfer ownership to a new owner.
    /// @param newOwner The address to transfer ownership to.
    function transferOwnership(address newOwner) external onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Write data to be accessed by a given file key.
    /// @param key The key to access the written data.
    /// @param data The data to be written.
    function writeFile(uint256 key, string memory data) external onlyOwner {
        files[key] = SSTORE2.write(bytes(data));
    }

    /// @notice Read data using a given file key.
    /// @param key The key to access the stored data.
    /// @return data The data stored at the given key.
    function readFile(uint256 key) external view returns (string memory data) {
        return string(SSTORE2.read(files[key]));
    }

    /// @notice Create or set a customization preset for renderers to use.
    /// @param id The ID of the customization preset.
    /// @param customizationData Data decoded by renderers used to render the SVG according to the preset.
    function createCustomizationPreset(
        uint256 id,
        bytes memory customizationData
    ) external onlyOwner {
        customizationPresets[id] = customizationData;
    }

    /// @notice For crowdfund or party instances to set the customization preset they want to use.
    /// @param id The ID of the customization preset.
    function useCustomizationPreset(uint256 id) external {
        getPresetFor[msg.sender] = id;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

// Minimal ERC1155 interface.
interface IERC1155 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setApprovalForAll(address operator, bool approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function balanceOf(address owner, uint256 tokenId) external view returns (uint256);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) external view returns (uint256[] memory balances);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "./IERC721Receiver.sol";
import "../utils/EIP165.sol";
import "../vendor/solmate/ERC721.sol";

/// @notice Mixin for contracts that want to receive ERC721 tokens.
/// @dev Use this instead of solmate's ERC721TokenReceiver because the
///      compiler has issues when overriding EIP165/IERC721Receiver functions.
abstract contract ERC721Receiver is IERC721Receiver, EIP165, ERC721TokenReceiver {
    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override(IERC721Receiver, ERC721TokenReceiver) returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @inheritdoc EIP165
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return
            EIP165.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721Receiver).interfaceId;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

import "../vendor/solmate/ERC1155.sol";
import "../utils/EIP165.sol";

abstract contract ERC1155Receiver is EIP165, ERC1155TokenReceiverBase {
    /// @inheritdoc EIP165
    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(ERC1155TokenReceiverBase).interfaceId;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../tokens/IERC721.sol";

// Upgradeable proposals logic contract interface.
interface IProposalExecutionEngine {
    struct ExecuteProposalParams {
        uint256 proposalId;
        bytes proposalData;
        bytes progressData;
        bytes extraData;
        uint256 flags;
        IERC721[] preciousTokens;
        uint256[] preciousTokenIds;
    }

    function initialize(address oldImpl, bytes memory initData) external;

    /// @notice Execute a proposal.
    /// @dev Must be delegatecalled into by PartyGovernance.
    ///      If the proposal is incomplete, continues its next step (if possible).
    ///      If another proposal is incomplete, this will fail. Only one
    ///      incomplete proposal is allowed at a time.
    /// @param params The data needed to execute the proposal.
    /// @return nextProgressData Bytes to be passed into the next `execute()` call,
    ///         if the proposal execution is incomplete. Otherwise, empty bytes
    ///         to indicate the proposal is complete.
    function executeProposal(
        ExecuteProposalParams memory params
    ) external returns (bytes memory nextProgressData);

    /// @notice Forcibly cancel an incomplete proposal.
    /// @param proposalId The ID of the proposal to cancel.
    /// @dev This is intended to be a last resort as it can leave a party in a
    ///      broken step. Whenever possible, proposals should be allowed to
    ///      complete their entire lifecycle.
    function cancelProposal(uint256 proposalId) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../tokens/IERC721.sol";

library LibProposal {
    uint256 internal constant PROPOSAL_FLAG_UNANIMOUS = 0x1;

    function isTokenPrecious(
        IERC721 token,
        IERC721[] memory preciousTokens
    ) internal pure returns (bool) {
        for (uint256 i; i < preciousTokens.length; ++i) {
            if (token == preciousTokens[i]) {
                return true;
            }
        }
        return false;
    }

    function isTokenIdPrecious(
        IERC721 token,
        uint256 tokenId,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds
    ) internal pure returns (bool) {
        for (uint256 i; i < preciousTokens.length; ++i) {
            if (token == preciousTokens[i] && tokenId == preciousTokenIds[i]) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "./IProposalExecutionEngine.sol";
import "../utils/LibRawResult.sol";

// The storage bucket shared by `PartyGovernance` and the `ProposalExecutionEngine`.
// Read this for more context on the pattern motivating this:
// https://github.com/dragonfly-xyz/useful-solidity-patterns/tree/main/patterns/explicit-storage-buckets
abstract contract ProposalStorage {
    using LibRawResult for bytes;

    struct SharedProposalStorage {
        IProposalExecutionEngine engineImpl;
        ProposalEngineOpts opts;
    }

    struct ProposalEngineOpts {
        // Whether the party can add new authorities with the add authority proposal.
        bool enableAddAuthorityProposal;
        // Whether the party can spend ETH from the party's balance with
        // arbitrary call proposals.
        bool allowArbCallsToSpendPartyEth;
        // Whether operators can spend ETH from the party's balance with the
        // operator proposal.
        bool allowOperatorsToSpendPartyEth;
        // Whether distributions require a vote or can be executed by any active member.
        bool distributionsRequireVote;
    }

    uint256 internal constant PROPOSAL_FLAG_UNANIMOUS = 0x1;
    uint256 private constant SHARED_STORAGE_SLOT =
        uint256(keccak256("ProposalStorage.SharedProposalStorage"));

    function _initProposalImpl(IProposalExecutionEngine impl, bytes memory initData) internal {
        SharedProposalStorage storage stor = _getSharedProposalStorage();
        IProposalExecutionEngine oldImpl = stor.engineImpl;
        stor.engineImpl = impl;
        (bool s, bytes memory r) = address(impl).delegatecall(
            abi.encodeCall(IProposalExecutionEngine.initialize, (address(oldImpl), initData))
        );
        if (!s) {
            r.rawRevert();
        }
    }

    function _getSharedProposalStorage()
        internal
        pure
        returns (SharedProposalStorage storage stor)
    {
        uint256 s = SHARED_STORAGE_SLOT;
        assembly {
            stor.slot := s
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../globals/IGlobals.sol";
import "../tokens/IERC721.sol";

import "./Party.sol";

// Creates generic Party instances.
interface IPartyFactory {
    event PartyCreated(
        Party indexed party,
        Party.PartyOptions opts,
        IERC721[] preciousTokens,
        uint256[] preciousTokenIds,
        address creator
    );

    /// @notice Deploy a new party instance.
    /// @param partyImpl The implementation of the party to deploy.
    /// @param authorities The addresses set as authorities for the party.
    /// @param opts Options used to initialize the party. These are fixed
    ///             and cannot be changed later.
    /// @param preciousTokens The tokens that are considered precious by the
    ///                       party.These are protected assets and are subject
    ///                       to extra restrictions in proposals vs other
    ///                       assets.
    /// @param preciousTokenIds The IDs associated with each token in `preciousTokens`.
    /// @param rageQuitTimestamp The timestamp until which ragequit is enabled.
    /// @return party The newly created `Party` instance.
    function createParty(
        Party partyImpl,
        address[] memory authorities,
        Party.PartyOptions calldata opts,
        IERC721[] memory preciousTokens,
        uint256[] memory preciousTokenIds,
        uint40 rageQuitTimestamp
    ) external returns (Party party);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

abstract contract EIP165 {
    /// @notice Query if a contract implements an interface.
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @return `true` if the contract implements `interfaceId` and
    ///         `interfaceId` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return interfaceId == this.supportsInterface.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.20;

import "../utils/LibRawResult.sol";

abstract contract Multicall {
    using LibRawResult for bytes;

    /// @notice Perform multiple delegatecalls on ourselves.
    function multicall(bytes[] calldata multicallData) external {
        for (uint256 i; i < multicallData.length; ++i) {
            (bool s, bytes memory r) = address(this).delegatecall(multicallData[i]);
            if (!s) {
                r.rawRevert();
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0-only
// Based on solmate commit 1681dc505f4897ef636f0435d01b1aa027fdafaf (v6.4.0)
//  @ https://github.com/Rari-Capital/solmate/blob/1681dc505f4897ef636f0435d01b1aa027fdafaf/src/tokens/ERC1155.sol
// Only modified to inherit IERC1155 and rename ERC1155TokenReceiver -> ERC1155TokenReceiverBase.
pragma solidity ^0.8;

import "../../tokens/IERC1155.sol";

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 is IERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiverBase(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiverBase.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiverBase(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiverBase.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) public view virtual returns (uint256[] memory balances) {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiverBase(to).onERC1155Received(
                    msg.sender,
                    address(0),
                    id,
                    amount,
                    data
                ) == ERC1155TokenReceiverBase.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiverBase(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) == ERC1155TokenReceiverBase.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiverBase {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiverBase.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiverBase.onERC1155BatchReceived.selector;
    }
}