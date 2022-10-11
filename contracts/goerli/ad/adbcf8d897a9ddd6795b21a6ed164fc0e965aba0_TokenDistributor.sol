// SPDX-License-Identifier: Beta Software
// http://ipfs.io/ipfs/QmbGX2MFCaMAsMNMugRFND6DtYygRkwkvrqEyTKhTdBLo5
pragma solidity 0.8.17;

import "../globals/IGlobals.sol";
import "../globals/LibGlobals.sol";
import "../tokens/IERC20.sol";
import "../utils/LibAddress.sol";
import "../utils/LibERC20Compat.sol";
import "../utils/LibRawResult.sol";
import "../utils/LibSafeCast.sol";

import "./ITokenDistributor.sol";

/// @notice Creates token distributions for parties (or any contract that
///         implements `ITokenDistributorParty`).
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
        ITokenDistributorParty party;
        TokenType tokenType;
        address token;
        uint256 currentTokenBalance;
        address payable feeRecipient;
        uint16 feeBps;
    }

    error OnlyPartyDaoError(address notDao, address partyDao);
    error OnlyPartyDaoAuthorityError(address notDaoAuthority);
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
    mapping(ITokenDistributorParty => uint256) public lastDistributionIdPerParty;
    /// Last known balance of a token, identified by an ID derived from the token.
    /// Gets lazily updated when creating and claiming a distribution (transfers).
    /// Allows one to simply transfer and call `createDistribution()` without
    /// fussing with allowances.
    mapping(bytes32 => uint256) private _storedBalances;
    // tokenDistributorParty => distributionId => DistributionState
    mapping(ITokenDistributorParty => mapping(uint256 => DistributionState)) private _distributionStates;

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
        ITokenDistributorParty party,
        address payable feeRecipient,
        uint16 feeBps
    )
        external
        payable
        returns (DistributionInfo memory info)
    {
        info = _createDistribution(CreateDistributionArgs({
            party: party,
            tokenType: TokenType.Native,
            token: NATIVE_TOKEN_ADDRESS,
            currentTokenBalance: address(this).balance,
            feeRecipient: feeRecipient,
            feeBps: feeBps
        }));
    }

    /// @inheritdoc ITokenDistributor
    function createErc20Distribution(
        IERC20 token,
        ITokenDistributorParty party,
        address payable feeRecipient,
        uint16 feeBps
    )
        external
        returns (DistributionInfo memory info)
    {
        info = _createDistribution(CreateDistributionArgs({
            party: party,
            tokenType: TokenType.Erc20,
            token: address(token),
            currentTokenBalance: token.balanceOf(address(this)),
            feeRecipient: feeRecipient,
            feeBps: feeBps
        }));
    }

    /// @inheritdoc ITokenDistributor
    function claim(DistributionInfo calldata info, uint256 partyTokenId)
        public
        returns (uint128 amountClaimed)
    {
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
        amountClaimed = getClaimAmount(info.party, info.memberSupply, partyTokenId);

        // Cap at the remaining member supply. Otherwise a malicious
        // party could drain more than the distribution supply.
        uint128 remainingMemberSupply = state.remainingMemberSupply;
        amountClaimed = amountClaimed > remainingMemberSupply
            ? remainingMemberSupply
            : amountClaimed;
        state.remainingMemberSupply = remainingMemberSupply - amountClaimed;

        // Transfer tokens owed.
        _transfer(
            info.tokenType,
            info.token,
            payable(msg.sender),
            amountClaimed
        );
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
    function claimFee(DistributionInfo calldata info, address payable recipient)
        public
    {
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
        _transfer(
            info.tokenType,
            info.token,
            recipient,
            info.fee
        );
        emit DistributionFeeClaimed(
            info.party,
            info.feeRecipient,
            info.tokenType,
            info.token,
            info.fee
        );
    }

    /// @inheritdoc ITokenDistributor
    function batchClaim(DistributionInfo[] calldata infos, uint256[] calldata partyTokenIds)
        external
        returns (uint128[] memory amountsClaimed)
    {
        amountsClaimed = new uint128[](infos.length);
        for (uint256 i = 0; i < infos.length; ++i) {
            amountsClaimed[i] = claim(infos[i], partyTokenIds[i]);
        }
    }

    /// @inheritdoc ITokenDistributor
    function batchClaimFee(DistributionInfo[] calldata infos, address payable[] calldata recipients)
        external
    {
        for (uint256 i = 0; i < infos.length; ++i) {
            claimFee(infos[i], recipients[i]);
        }
    }

    /// @inheritdoc ITokenDistributor
    function getClaimAmount(
        ITokenDistributorParty party,
        uint256 memberSupply,
        uint256 partyTokenId
    )
        public
        view
        returns (uint128)
    {
        // getDistributionShareOf() is the fraction of the memberSupply partyTokenId
        // is entitled to, scaled by 1e18.
        // We round up here to prevent dust amounts getting trapped in this contract.
        return (
            (
                uint256(party.getDistributionShareOf(partyTokenId))
                * memberSupply
                + (1e18 - 1)
            )
            / 1e18
        ).safeCastUint256ToUint128();
    }

    /// @inheritdoc ITokenDistributor
    function wasFeeClaimed(ITokenDistributorParty party, uint256 distributionId)
        external
        view
        returns (bool)
    {
        return _distributionStates[party][distributionId].wasFeeClaimed;
    }

    /// @inheritdoc ITokenDistributor
    function hasPartyTokenIdClaimed(
        ITokenDistributorParty party,
        uint256 partyTokenId,
        uint256 distributionId
    )
        external
        view returns (bool)
    {
        return _distributionStates[party][distributionId].hasPartyTokenClaimed[partyTokenId];
    }

    /// @inheritdoc ITokenDistributor
    function getRemainingMemberSupply(
        ITokenDistributorParty party,
        uint256 distributionId
    )
        external
        view
        returns (uint128)
    {
        return _distributionStates[party][distributionId].remainingMemberSupply;
    }

    /// @notice As the DAO, execute an arbitrary delegatecall from this contract.
    /// @dev Emergency actions must not be revoked for this to work.
    /// @param targetAddress The contract to delegatecall into.
    /// @param targetCallData The data to pass to the call.
    function emergencyExecute(
        address targetAddress,
        bytes calldata targetCallData
    )
        external
        onlyPartyDao
        onlyIfEmergencyActionsAllowed
    {
        (bool success, bytes memory res) = targetAddress.delegatecall(targetCallData);
        if (!success) {
            res.rawRevert();
        }
    }

    function _createDistribution(CreateDistributionArgs memory args)
        private
        returns (DistributionInfo memory info)
    {
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
        uint128 fee = supply * args.feeBps / 1e4;
        uint128 memberSupply = supply - fee;

        info = DistributionInfo({
            tokenType: args.tokenType,
            distributionId: ++lastDistributionIdPerParty[args.party],
            token: args.token,
            party: args.party,
            memberSupply: memberSupply,
            feeRecipient: args.feeRecipient,
            fee: fee
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
    )
        private
    {
        bytes32 balanceId = _getBalanceId(tokenType, token);
        // Reduce stored token balance.
        uint256 storedBalance = _storedBalances[balanceId] - amount;
        // Temporarily set to max as a reentrancy guard. An interesing attack
        // could occur if we didn't do this where an attacker could `claim()` and
        // reenter upon transfer (eg. in the `tokensToSend` hook of an ERC777) to
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

    function _getDistributionHash(DistributionInfo memory info)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            hash := keccak256(info, 0xe0)
        }
    }

    function _getBalanceId(TokenType tokenType, address token)
        private
        pure
        returns (bytes32 balanceId)
    {
        if (tokenType == TokenType.Native) {
            return bytes32(uint256(uint160(NATIVE_TOKEN_ADDRESS)));
        }
        assert(tokenType == TokenType.Erc20);
        return bytes32(uint256(uint160(token)));
    }
}

// SPDX-License-Identifier: Beta Software
// http://ipfs.io/ipfs/QmbGX2MFCaMAsMNMugRFND6DtYygRkwkvrqEyTKhTdBLo5
pragma solidity 0.8.17;

import "../utils/Implementation.sol";

// Single registry of global values controlled by multisig.
// See `LibGlobals` for all valid keys.
interface IGlobals {
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

// SPDX-License-Identifier: Beta Software
// http://ipfs.io/ipfs/QmbGX2MFCaMAsMNMugRFND6DtYygRkwkvrqEyTKhTdBLo5
pragma solidity 0.8.17;

// Valid keys in `IGlobals`. Append-only.
library LibGlobals {
    uint256 internal constant GLOBAL_PARTY_IMPL                     = 1;
    uint256 internal constant GLOBAL_PROPOSAL_ENGINE_IMPL           = 2;
    uint256 internal constant GLOBAL_PARTY_FACTORY                  = 3;
    uint256 internal constant GLOBAL_GOVERNANCE_NFT_RENDER_IMPL     = 4;
    uint256 internal constant GLOBAL_CF_NFT_RENDER_IMPL             = 5;
    uint256 internal constant GLOBAL_OS_ZORA_AUCTION_TIMEOUT        = 6;
    uint256 internal constant GLOBAL_OS_ZORA_AUCTION_DURATION       = 7;
    uint256 internal constant GLOBAL_AUCTION_CF_IMPL                = 8;
    uint256 internal constant GLOBAL_BUY_CF_IMPL                    = 9;
    uint256 internal constant GLOBAL_COLLECTION_BUY_CF_IMPL         = 10;
    uint256 internal constant GLOBAL_DAO_WALLET                     = 11;
    uint256 internal constant GLOBAL_TOKEN_DISTRIBUTOR              = 12;
    uint256 internal constant GLOBAL_OPENSEA_CONDUIT_KEY            = 13;
    uint256 internal constant GLOBAL_OPENSEA_ZONE                   = 14;
    uint256 internal constant GLOBAL_PROPOSAL_MAX_CANCEL_DURATION   = 15;
    uint256 internal constant GLOBAL_ZORA_MIN_AUCTION_DURATION      = 16;
    uint256 internal constant GLOBAL_ZORA_MAX_AUCTION_DURATION      = 17;
    uint256 internal constant GLOBAL_ZORA_MAX_AUCTION_TIMEOUT       = 18;
    uint256 internal constant GLOBAL_OS_MIN_ORDER_DURATION          = 19;
    uint256 internal constant GLOBAL_OS_MAX_ORDER_DURATION          = 20;
    uint256 internal constant GLOBAL_DISABLE_PARTY_ACTIONS          = 21;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

library LibAddress {
    error EthTransferFailed(address receiver, bytes errData);

    // Transfer ETH with full gas stipend.
    function transferEth(address payable receiver, uint256 amount)
        internal
    {
        (bool s, bytes memory r) = receiver.call{value: amount}("");
        if (!s) {
            revert EthTransferFailed(receiver, r);
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "../tokens/IERC20.sol";

// Compatibility helpers for ERC20s.
library LibERC20Compat {
    error NotATokenError(IERC20 token);
    error TokenTransferFailedError(IERC20 token, address to, uint256 amount);

    // Perform an `IERC20.transfer()` handling non-compliant implementations.
    function compatTransfer(IERC20 token, address to, uint256 amount)
        internal
    {
        (bool s, bytes memory r) =
            address(token).call(abi.encodeCall(IERC20.transfer, (to, amount)));
        if (s) {
            if (r.length == 0) {
                uint256 cs;
                assembly { cs := extcodesize(token) }
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

library LibRawResult {
    // Revert with the data in `b`.
    function rawRevert(bytes memory b)
        internal
        pure
    {
        assembly { revert(add(b, 32), mload(b)) }
    }

    // Return with the data in `b`.
    function rawReturn(bytes memory b)
        internal
        pure
    {
        assembly { return(add(b, 32), mload(b)) }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

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

    function safeCastUint256ToInt128(uint256 x)
        internal
        pure
        returns (int128)
    {
        if (x > uint256(uint128(type(int128).max))) {
            revert Uint256ToInt128CastOutOfRangeError(x);
        }
        return int128(uint128(x));
    }

    function safeCastUint256ToUint40(uint256 x)
        internal
        pure
        returns (uint40)
    {
        if (x > uint256(type(uint40).max)) {
            revert Uint256ToUint40CastOutOfRangeError(x);
        }
        return uint40(x);
    }
}

// SPDX-License-Identifier: Beta Software
// http://ipfs.io/ipfs/QmbGX2MFCaMAsMNMugRFND6DtYygRkwkvrqEyTKhTdBLo5
pragma solidity 0.8.17;

import "../tokens/IERC20.sol";

import "./ITokenDistributorParty.sol";

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
        ITokenDistributorParty party;
        // Who can claim `fee`.
        address payable feeRecipient;
        // The token being distributed.
        address token;
        // Total amount of `token` that can be claimed by party members.
        uint128 memberSupply;
        // Amount of `token` to be redeemed by `feeRecipient`.
        uint128 fee;
    }

    event DistributionCreated(
        ITokenDistributorParty indexed party,
        DistributionInfo info
    );
    event DistributionFeeClaimed(
        ITokenDistributorParty indexed party,
        address indexed feeRecipient,
        TokenType tokenType,
        address token,
        uint256 amount
    );
    event DistributionClaimedByPartyToken(
        ITokenDistributorParty indexed party,
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
    /// @param info Information on the created distribution.
    function createNativeDistribution(
        ITokenDistributorParty party,
        address payable feeRecipient,
        uint16 feeBps
    )
        external
        payable
        returns (DistributionInfo memory info);

    /// @notice Create a new distribution for an outstanding ERC20 token balance
    ///         governed by a party.
    /// @dev ERC20 tokens should be transferred directly into this contract
    ///      immediately prior (same tx) to calling `createDistribution()` or
    ///      attached to the call itself.
    /// @param token The ERC20 token to distribute.
    /// @param party The party whose members can claim the distribution.
    /// @param feeRecipient Who can claim `fee`.
    /// @param feeBps Percentage (in bps) of the distribution `feeRecipient` receives.
    /// @param info Information on the created distribution.
    function createErc20Distribution(
        IERC20 token,
        ITokenDistributorParty party,
        address payable feeRecipient,
        uint16 feeBps
    )
        external
        returns (DistributionInfo memory info);

    /// @notice Claim a portion of a distribution owed to a `partyTokenId` belonging
    ///         to the party that created the distribution. The caller
    ///         must own this token.
    /// @param info Information on the distribution being claimed.
    /// @param partyTokenId The ID of the party token to claim for.
    /// @param amountClaimed The amount of the distribution claimed.
    function claim(DistributionInfo calldata info, uint256 partyTokenId)
        external
        returns (uint128 amountClaimed);

    /// @notice Claim the fee for a distribution. Only a distribution's `feeRecipient`
    ///         can call this.
    /// @param info Information on the distribution being claimed.
    /// @param recipient The address to send the fee to.
    function claimFee(DistributionInfo calldata info, address payable recipient)
        external;

    /// @notice Batch version of `claim()`.
    /// @param infos Information on the distributions being claimed.
    /// @param partyTokenIds The ID of the party tokens to claim for.
    /// @param amountsClaimed The amount of the distributions claimed.
    function batchClaim(DistributionInfo[] calldata infos, uint256[] calldata partyTokenIds)
        external
        returns (uint128[] memory amountsClaimed);

    /// @notice Batch version of `claimFee()`.
    /// @param infos Information on the distributions to claim fees for.
    /// @param recipients The addresses to send the fees to.
    function batchClaimFee(DistributionInfo[] calldata infos, address payable[] calldata recipients)
        external;

    /// @notice Compute the amount of a distribution's token are owed to a party
    ///         member, identified by the `partyTokenId`.
    /// @param party The party to use for computing the claim amount.
    /// @param memberSupply Total amount of tokens that can be claimed in the distribution.
    /// @param partyTokenId The ID of the party token to claim for.
    /// @return claimAmount The amount of the distribution owed to the party member.
    function getClaimAmount(
        ITokenDistributorParty party,
        uint256 memberSupply,
        uint256 partyTokenId
    )
        external
        view
        returns (uint128);

    /// @notice Check whether the fee has been claimed for a distribution.
    /// @param party The party to use for checking whether the fee has been claimed.
    /// @param distributionId The ID of the distribution to check.
    /// @return feeClaimed Whether the fee has been claimed.
    function wasFeeClaimed(ITokenDistributorParty party, uint256 distributionId)
        external
        view
        returns (bool);

    /// @notice Check whether a `partyTokenId` has claimed their share of a distribution.
    /// @param party The party to use for checking whether the `partyTokenId` has claimed.
    /// @param partyTokenId The ID of the party token to check.
    /// @param distributionId The ID of the distribution to check.
    /// @return hasClaimed Whether the `partyTokenId` has claimed.
    function hasPartyTokenIdClaimed(
        ITokenDistributorParty party,
        uint256 partyTokenId,
        uint256 distributionId
    )
        external
        view returns (bool);

    /// @notice Get how much unclaimed member tokens are left in a distribution.
    /// @param party The party to use for checking the unclaimed member tokens.
    /// @param distributionId The ID of the distribution to check.
    /// @return remainingMemberSupply The amount of distribution supply remaining.
    function getRemainingMemberSupply(
        ITokenDistributorParty party,
        uint256 distributionId
    )
        external
        view
        returns (uint128);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

// Base contract for all contracts intended to be delegatecalled into.
abstract contract Implementation {
    error OnlyDelegateCallError();
    error OnlyConstructorError();

    address public immutable IMPL;

    constructor() { IMPL = address(this); }

    // Reverts if the current function context is not inside of a delegatecall.
    modifier onlyDelegateCall() virtual {
        if (address(this) == IMPL) {
            revert OnlyDelegateCallError();
        }
        _;
    }

    // Reverts if the current function context is not inside of a constructor.
    modifier onlyConstructor() {
        uint256 codeSize;
        assembly { codeSize := extcodesize(address()) }
        if (codeSize != 0) {
            revert OnlyConstructorError();
        }
        _;
    }
}

// SPDX-License-Identifier: Beta Software
// http://ipfs.io/ipfs/QmbGX2MFCaMAsMNMugRFND6DtYygRkwkvrqEyTKhTdBLo5
pragma solidity 0.8.17;

// Interface the caller of `ITokenDistributor.createDistribution()` must implement.
interface ITokenDistributorParty {
    /// @notice Return the owner of a token.
    /// @param tokenId The token ID to query.
    /// @return owner The owner of `tokenId`.
    function ownerOf(uint256 tokenId) external view returns (address);
    /// @notice Return the distribution share of a token. Denominated fractions
    ///         of 1e18. I.e., 1e18 = 100%.
    /// @param tokenId The token ID to query.
    /// @return share The distribution percentage of `tokenId`.
    function getDistributionShareOf(uint256 tokenId) external view returns (uint256);
}