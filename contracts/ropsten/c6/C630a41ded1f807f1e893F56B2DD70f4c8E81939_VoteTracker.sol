// SPDX-License-Identifier: MIT
// solhint-disable max-states-count

pragma solidity ^0.8.2;
pragma abicoder v2;

import "../interfaces/IVoteTracker.sol";
import "../interfaces/IBalanceTracker.sol";

import "../interfaces/events/EventWrapper.sol";
import "../interfaces/events/CycleRolloverEvent.sol";
import "../interfaces/events/BalanceUpdateEvent.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {PausableUpgradeable as Pausable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {OwnableUpgradeable as Ownable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/events/EventReceiver.sol";
import "../interfaces/structs/UserVotePayload.sol";

// solhint-disable var-name-mixedcase
contract VoteTracker is Initializable, EventReceiver, IVoteTracker, Ownable, Pausable {
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.Bytes32Set;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public constant ONE_WITH_EIGHTEEN_PRECISION = 1_000_000_000_000_000_000;

    /// @dev EIP191 header for EIP712 prefix
    string public constant EIP191_HEADER = "\x19\x01";

    bytes32 public immutable EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 public immutable USER_VOTE_PAYLOAD_TYPEHASH =
        keccak256(
            "UserVotePayload(address account,bytes32 voteSessionKey,uint256 nonce,uint256 chainId,uint256 totalVotes,UserVoteAllocationItem[] allocations)UserVoteAllocationItem(bytes32 reactorKey,uint256 amount)"
        );

    bytes32 public immutable USER_VOTE_ALLOCATION_ITEM_TYPEHASH =
        keccak256("UserVoteAllocationItem(bytes32 reactorKey,uint256 amount)");

    bytes32 public immutable DOMAIN_NAME = keccak256("Tokemak Voting");
    bytes32 public immutable DOMAIN_VERSION = keccak256("1");

    bytes32 public constant EVENT_TYPE_DEPOSIT = bytes32("Deposit");
    bytes32 public constant EVENT_TYPE_TRANSFER = bytes32("Transfer");
    bytes32 public constant EVENT_TYPE_SLASH = bytes32("Slash");
    bytes32 public constant EVENT_TYPE_WITHDRAW = bytes32("Withdraw");
    bytes32 public constant EVENT_TYPE_CYCLECOMPLETE = bytes32("Cycle Complete");
    bytes32 public constant EVENT_TYPE_VOTE = bytes32("Vote");
    bytes32 public constant EVENT_TYPE_WITHDRAWALREQUEST = bytes32("Withdrawal Request");

    //Normally these would only be generated during construction against the current chain id
    //However, our users will be signing while connected to mainnet so we'll need a diff
    //chainId than we're running on. We'll validate the intended chain in the message itself
    //against the actual chain the contract is running on.
    bytes32 public currentDomainSeparator;
    uint256 public currentSigningChainId;

    //For when the users decide to connect to the network and submit directly
    //We'll want domain to be the actual chain
    NetworkSettings public networkSettings;

    /// @dev All publically accessible but you can use getUserVotes() to pull it all together
    mapping(address => UserVoteDetails) public userVoteDetails;
    mapping(address => bytes32[]) public userVoteKeys;
    mapping(address => mapping(bytes32 => uint256)) public userVoteItems;

    /// @dev Stores the users next valid vote nonce
    mapping(address => uint256) public override userNonces;

    /// @dev Stores the last block during which a user voted through our proxy
    mapping(address => uint256) public override lastUserProxyVoteBlock;

    VoteTrackSettings public settings;

    address[] public votingTokens;

    mapping(address => uint256) public voteMultipliers;

    /// @dev Total of all user aggregations
    /// @dev getSystemAggregation() to reconstruct
    EnumerableSet.Bytes32Set private allowedreactorKeys;
    mapping(bytes32 => uint256) public systemAggregations;
    mapping(bytes32 => address) public placementTokens;

    mapping(address => bool) public override proxySubmitters;

    // solhint-disable-next-line func-visibility
    function initialize(
        address eventProxy,
        bytes32 initialVoteSession,
        address balanceTracker,
        uint256 signingOnChain,
        VoteTokenMultipler[] memory voteTokens
    ) public initializer {
        require(initialVoteSession.length > 0, "INVALID_SESSION_KEY");
        require(voteTokens.length > 0, "NO_VOTE_TOKENS");

        __Ownable_init_unchained();
        __Pausable_init_unchained();

        EventReceiver(address(this)).init(eventProxy);

        settings.voteSessionKey = initialVoteSession;
        settings.balanceTrackerAddress = balanceTracker;

        setVoteMultiplers(voteTokens);
        _setSigningChainId(signingOnChain);

        networkSettings.chainId = _getChainID();
        networkSettings.domainSeparator = _buildDomainSeparator(_getChainID());
    }

    /// @notice Vote for the assets and reactors you wish to see liquidity deployed for
    /// @param userVotePayload Users vote percent breakdown
    /// @param signature Account signature
    function vote(UserVotePayload memory userVotePayload, Signature memory signature)
        external
        override
        whenNotPaused
    {
        uint256 domainChain = _getChainID();

        require(domainChain == userVotePayload.chainId, "INVALID_PAYLOAD_CHAIN");

        // Rate limiting when using our proxy apis
        // Users can only submit every X blocks
        if (proxySubmitters[msg.sender]) {
            require(
                lastUserProxyVoteBlock[userVotePayload.account].add(settings.voteEveryBlockLimit) <
                    block.number,
                "TOO_FREQUENT_VOTING"
            );
            lastUserProxyVoteBlock[userVotePayload.account] = block.number;
            domainChain = currentSigningChainId;
        }

        // Validate the signer is the account the votes are on behalf of
        address signatureSigner = _hash(domainChain, userVotePayload, signature.signatureType)
            .recover(signature.v, signature.r, signature.s);
        require(signatureSigner == userVotePayload.account, "MISMATCH_SIGNER");

        _vote(userVotePayload);
    }

    function voteDirect(UserVotePayload memory userVotePayload) external override whenNotPaused {
        require(msg.sender == userVotePayload.account, "MUST_BE_SENDER");
        require(userVotePayload.chainId == networkSettings.chainId, "INVALID_PAYLOAD_CHAIN");

        _vote(userVotePayload);
    }

    /// @notice Updates the users and system aggregation based on their current balances
    /// @param accounts Accounts list that just had their balance updated
    /// @dev Should call back to BalanceTracker to pull that accounts current balance
    function updateUserVoteTotals(address[] memory accounts) public override {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            require(account != address(0), "INVALID_ADDRESS");

            bytes32[] memory keys = userVoteKeys[account];
            uint256 maxAvailableVotes = getMaxVoteBalance(account);
            uint256 maxVotesToUse = Math.min(
                maxAvailableVotes,
                userVoteDetails[account].totalUsedVotes
            );

            //Grab their current aggregation and back it out of the system aggregation
            bytes32[] storage currentAccountVoteKeys = userVoteKeys[account];
            uint256 userAggLength = currentAccountVoteKeys.length;

            if (userAggLength > 0) {
                for (uint256 k = userAggLength; k > 0; k--) {
                    uint256 amt = userVoteItems[account][currentAccountVoteKeys[k - 1]];
                    systemAggregations[currentAccountVoteKeys[k - 1]] = systemAggregations[
                        currentAccountVoteKeys[k - 1]
                    ].sub(amt);
                    currentAccountVoteKeys.pop();
                }
            }

            //Compute new aggregations
            uint256 total = 0;
            if (maxVotesToUse > 0) {
                for (uint256 j = 0; j < keys.length; j++) {
                    UserVoteAllocationItem memory placement = UserVoteAllocationItem({
                        reactorKey: keys[j],
                        amount: userVoteItems[account][keys[j]]
                    });

                    placement.amount = maxVotesToUse.mul(placement.amount).div(
                        userVoteDetails[account].totalUsedVotes
                    );
                    total = total.add(placement.amount);

                    //Update user aggregation
                    userVoteItems[account][placement.reactorKey] = placement.amount;
                    userVoteKeys[account].push(placement.reactorKey);

                    //Update system aggregation
                    systemAggregations[placement.reactorKey] = systemAggregations[
                        placement.reactorKey
                    ].add(placement.amount);
                }
            } else {
                //If these values are left, then when the user comes back and tries to vote
                //again, the total used won't line up
                for (uint256 j = 0; j < keys.length; j++) {
                    userVoteItems[account][keys[j]] = 0;
                }
            }

            //Call here emits
            //Update users aggregation details
            userVoteDetails[account] = UserVoteDetails({
                totalUsedVotes: total,
                totalAvailableVotes: maxAvailableVotes
            });

            emit UserAggregationUpdated(account);
        }
    }

    function getUserVotes(address account) public view override returns (UserVotes memory) {
        bytes32[] memory keys = userVoteKeys[account];
        UserVoteAllocationItem[] memory placements = new UserVoteAllocationItem[](keys.length);
        for (uint256 i = 0; i < keys.length; i++) {
            placements[i] = UserVoteAllocationItem({
                reactorKey: keys[i],
                amount: userVoteItems[account][keys[i]]
            });
        }
        return UserVotes({votes: placements, details: userVoteDetails[account]});
    }

    function getSystemVotes() public view override returns (SystemVotes memory systemVotes) {
        uint256 placements = allowedreactorKeys.length();
        SystemAllocation[] memory votes = new SystemAllocation[](placements);
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < placements; i++) {
            votes[i] = SystemAllocation({
                reactorKey: allowedreactorKeys.at(i),
                totalVotes: systemAggregations[allowedreactorKeys.at(i)],
                token: placementTokens[allowedreactorKeys.at(i)]
            });
            totalVotes = totalVotes.add(votes[i].totalVotes);
        }

        systemVotes = SystemVotes({
            details: SystemVoteDetails({
                voteSessionKey: settings.voteSessionKey,
                totalVotes: totalVotes
            }),
            votes: votes
        });
    }

    function getMaxVoteBalance(address account) public view override returns (uint256) {
        TokenBalance[] memory balances = IBalanceTracker(settings.balanceTrackerAddress).getBalance(
            account,
            votingTokens
        );
        return _getVotingPower(balances);
    }

    function getVotingPower(TokenBalance[] memory balances)
        external
        view
        override
        returns (uint256 votes)
    {
        votes = _getVotingPower(balances);
    }

    /// @notice Set the contract that should be used to lookup user balances
    /// @param contractAddress Address of the contract
    function setBalanceTrackerAddress(address contractAddress) external override onlyOwner {
        settings.balanceTrackerAddress = contractAddress;

        emit BalanceTrackerAddressSet(contractAddress);
    }

    function setProxySubmitters(address[] calldata submitters, bool allowed)
        public
        override
        onlyOwner
    {
        uint256 length = submitters.length;
        for (uint256 i = 0; i < length; i++) {
            proxySubmitters[submitters[i]] = allowed;
        }

        emit ProxySubmitterSet(submitters, allowed);
    }

    function setReactorKeys(VotingLocation[] memory reactorKeys, bool allowed)
        public
        override
        onlyOwner
    {
        uint256 length = reactorKeys.length;

        for (uint256 i = 0; i < length; i++) {
            if (allowed) {
                require(allowedreactorKeys.add(reactorKeys[i].key), "ADD_FAIL");
                placementTokens[reactorKeys[i].key] = reactorKeys[i].token;
            } else {
                require(allowedreactorKeys.remove(reactorKeys[i].key), "REMOVE_FAIL");
                delete placementTokens[reactorKeys[i].key];
            }
        }

        bytes32[] memory validKeys = getReactorKeys();

        emit ReactorKeysSet(validKeys);
    }

    function setVoteMultiplers(VoteTokenMultipler[] memory multipliers) public override onlyOwner {
        uint256 votingTokenLength = votingTokens.length;
        if (votingTokenLength > 0) {
            for (uint256 i = 0; i < votingTokenLength; i++) {
                votingTokens.pop();
                voteMultipliers[multipliers[i].token] = 0;
            }
        }

        for (uint256 i = 0; i < multipliers.length; i++) {
            require(multipliers[i].multiplier > 0, "MULTIPLIER_MUST_EXIST");
            require(voteMultipliers[multipliers[i].token] == 0, "ALREADY_EXISTS");

            voteMultipliers[multipliers[i].token] = multipliers[i].multiplier;
            votingTokens.push(multipliers[i].token);
        }

        emit VoteMultipliersSet(multipliers);
    }

    function getVotingTokens() external view override returns (address[] memory tokens) {
        uint256 length = votingTokens.length;
        tokens = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = votingTokens[i];
        }
    }

    function setProxyRateLimit(uint256 voteEveryBlockLimit) external override onlyOwner {
        settings.voteEveryBlockLimit = voteEveryBlockLimit;

        emit ProxyRateLimitSet(voteEveryBlockLimit);
    }

    function getReactorKeys() public view override returns (bytes32[] memory reactorKeys) {
        uint256 length = allowedreactorKeys.length();
        reactorKeys = new bytes32[](length);

        for (uint256 i = 0; i < length; i++) {
            reactorKeys[i] = allowedreactorKeys.at(i);
        }
    }

    function getSettings() external view override returns (VoteTrackSettings memory) {
        return settings;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _onEventReceive(
        address,
        bytes32 eventType,
        bytes calldata data
    ) internal virtual override {
        if (eventType == EVENT_TYPE_CYCLECOMPLETE) {
            _onCycleRollover(data);
        } else if (
            eventType == EVENT_TYPE_DEPOSIT ||
            eventType == EVENT_TYPE_TRANSFER ||
            eventType == EVENT_TYPE_WITHDRAW ||
            eventType == EVENT_TYPE_SLASH ||
            eventType == EVENT_TYPE_WITHDRAWALREQUEST
        ) {
            _onBalanceChange(eventType, data);
        } else if (eventType == EVENT_TYPE_VOTE) {
            _onEventVote(data);
        } else {
            revert("INVALID_EVENT_TYPE");
        }
    }

    function _removeUserVoteKey(address account, bytes32 reactorKey) internal whenNotPaused {
        for (uint256 i = 0; i < userVoteKeys[account].length; i++) {
            if (userVoteKeys[account][i] == reactorKey) {
                userVoteKeys[account][i] = userVoteKeys[account][userVoteKeys[account].length - 1];
                userVoteKeys[account].pop();
                break;
            }
        }
    }

    function _vote(UserVotePayload memory userVotePayload) internal whenNotPaused {
        address account = userVotePayload.account;
        uint256 totalUsedVotes = userVoteDetails[account].totalUsedVotes;

        require(
            settings.voteSessionKey == userVotePayload.voteSessionKey,
            "NOT_CURRENT_VOTE_SESSION"
        );
        require(userNonces[account] == userVotePayload.nonce, "INVALID_NONCE");

        // Ensure the message cannot be replayed
        userNonces[userVotePayload.account] = userNonces[userVotePayload.account].add(1);

        for (uint256 i = 0; i < userVotePayload.allocations.length; i++) {
            bytes32 reactorKey = userVotePayload.allocations[i].reactorKey;
            uint256 amount = userVotePayload.allocations[i].amount;

            //Ensure where they are voting is allowed
            require(allowedreactorKeys.contains(reactorKey), "PLACEMENT_NOT_ALLOWED");

            // check if user has already voted for this reactor
            if (userVoteItems[account][reactorKey] > 0) {
                if (amount == 0) {
                    _removeUserVoteKey(account, reactorKey);
                }

                uint256 currentAmount = userVoteItems[account][reactorKey];

                // increase or decrease systemAggregations[reactorKey] by the difference between currentAmount and amount
                if (currentAmount > amount) {
                    systemAggregations[reactorKey] = systemAggregations[reactorKey].sub(
                        currentAmount - amount
                    );
                    totalUsedVotes = totalUsedVotes.sub(currentAmount - amount);
                } else if (currentAmount < amount) {
                    systemAggregations[reactorKey] = systemAggregations[reactorKey].add(
                        amount - currentAmount
                    );
                    totalUsedVotes = totalUsedVotes.add(amount - currentAmount);
                }
                userVoteItems[account][reactorKey] = amount;
            } else {
                if (amount > 0) {
                    userVoteKeys[account].push(reactorKey);
                    userVoteItems[account][reactorKey] = amount;
                    systemAggregations[reactorKey] = systemAggregations[reactorKey].add(amount);
                    totalUsedVotes = totalUsedVotes.add(amount);
                }
            }
        }

        require(totalUsedVotes == userVotePayload.totalVotes, "VOTE_TOTAL_MISMATCH");

        uint256 totalAvailableVotes = getMaxVoteBalance(account);
        require(totalUsedVotes <= totalAvailableVotes, "NOT_ENOUGH_VOTES");

        //Update users aggregation details
        userVoteDetails[account] = UserVoteDetails({
            totalUsedVotes: totalUsedVotes,
            totalAvailableVotes: totalAvailableVotes
        });

        UserVotes memory votes = getUserVotes(account);

        emit UserVoted(account, votes);
    }

    function _setSigningChainId(uint256 chainId) private {
        currentSigningChainId = chainId;
        currentDomainSeparator = _buildDomainSeparator(chainId);

        emit SigningChainIdSet(chainId);
    }

    function _onEventVote(bytes calldata data) private {
        (, bytes memory e) = abi.decode(data, (bytes32, bytes));

        UserVotePayload memory userVotePayload = abi.decode(e, (UserVotePayload));

        uint256 domainChain = _getChainID();

        require(domainChain == userVotePayload.chainId, "INVALID_PAYLOAD_CHAIN");
        _vote(userVotePayload);
    }

    function _getVotingPower(TokenBalance[] memory balances) private view returns (uint256 votes) {
        for (uint256 i = 0; i < balances.length; i++) {
            votes = votes.add(
                balances[i].amount.mul(voteMultipliers[balances[i].token]).div(
                    ONE_WITH_EIGHTEEN_PRECISION
                )
            );
        }
    }

    function _onCycleRollover(bytes calldata data) private {
        SystemVotes memory lastAgg = getSystemVotes();
        CycleRolloverEvent memory e = abi.decode(data, (CycleRolloverEvent));
        bytes32 newKey = bytes32(e.cycleIndex);
        settings.voteSessionKey = newKey;
        emit VoteSessionRollover(newKey, lastAgg);
    }

    function _onBalanceChange(bytes32 eventType, bytes calldata data) private {
        BalanceUpdateEvent memory e = abi.decode(data, (BalanceUpdateEvent));
        address[] memory accounts = new address[](1);
        accounts[0] = e.account;

        updateUserVoteTotals(accounts);

        if (eventType == EVENT_TYPE_WITHDRAWALREQUEST) {
            UserVotes memory postVotes = getUserVotes(e.account);
            emit WithdrawalRequestApplied(e.account, postVotes);
        }
    }

    function _getChainID() private view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function _domainSeparatorV4(uint256 domainChain) internal view virtual returns (bytes32) {
        if (domainChain == currentSigningChainId) {
            return currentDomainSeparator;
        } else if (domainChain == networkSettings.chainId) {
            return networkSettings.domainSeparator;
        } else {
            return _buildDomainSeparator(domainChain);
        }
    }

    function _buildDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    DOMAIN_NAME,
                    DOMAIN_VERSION,
                    chainId,
                    address(this)
                )
            );
    }

    function _hash(
        uint256 domainChain,
        UserVotePayload memory userVotePayload,
        SignatureType signatureType
    ) private view returns (bytes32) {
        bytes32 x = keccak256(
            abi.encodePacked(
                EIP191_HEADER,
                _domainSeparatorV4(domainChain),
                _hashUserVotePayload(userVotePayload)
            )
        );

        if (signatureType == SignatureType.ETHSIGN) {
            x = x.toEthSignedMessageHash();
        }

        return x;
    }

    function _hashUserVotePayload(UserVotePayload memory userVote) private view returns (bytes32) {
        bytes32[] memory encodedVotes = new bytes32[](userVote.allocations.length);
        for (uint256 ix = 0; ix < userVote.allocations.length; ix++) {
            encodedVotes[ix] = _hashUserVoteAllocationItem(userVote.allocations[ix]);
        }

        return
            keccak256(
                abi.encode(
                    USER_VOTE_PAYLOAD_TYPEHASH,
                    userVote.account,
                    userVote.voteSessionKey,
                    userVote.nonce,
                    userVote.chainId,
                    userVote.totalVotes,
                    keccak256(abi.encodePacked(encodedVotes))
                )
            );
    }

    function _hashUserVoteAllocationItem(UserVoteAllocationItem memory voteAllocation)
        private
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    USER_VOTE_ALLOCATION_ITEM_TYPEHASH,
                    voteAllocation.reactorKey,
                    voteAllocation.amount
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
pragma abicoder v2;

import "./events/IEventReceiver.sol";
import "./structs/TokenBalance.sol";
import "./structs/UserVotePayload.sol";
import "./structs/Signature.sol";

/**
 *  @title Track and tally votes made to reactors, exchanges, pairs, etc.
 *  Setup to accept votes submitted directly, via a bridge, or the gasless API
 *  with an EIP712/eth_sign'd message
 */
interface IVoteTracker is IEventReceiver {
    //Collpased simple settings
    struct VoteTrackSettings {
        address balanceTrackerAddress;
        uint256 voteEveryBlockLimit;
        uint256 lastProcessedEventId;
        bytes32 voteSessionKey;
    }

    //Colapsed NETWORK settings
    struct NetworkSettings {
        bytes32 domainSeparator;
        uint256 chainId;
    }

    struct UserVotes {
        UserVoteDetails details;
        UserVoteAllocationItem[] votes;
    }

    struct UserVoteDetails {
        uint256 totalUsedVotes;
        uint256 totalAvailableVotes;
    }

    struct SystemVotes {
        SystemVoteDetails details;
        SystemAllocation[] votes;
    }

    struct SystemVoteDetails {
        bytes32 voteSessionKey;
        uint256 totalVotes;
    }

    struct SystemAllocation {
        address token;
        bytes32 reactorKey;
        uint256 totalVotes;
    }

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    struct VoteTokenMultipler {
        address token;
        uint256 multiplier;
    }

    struct VotingLocation {
        address token;
        bytes32 key;
    }

    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event UserAggregationUpdated(address account);
    event UserVoted(address account, UserVotes votes);
    event WithdrawalRequestApplied(address account, UserVotes postApplicationVotes);
    event VoteSessionRollover(bytes32 newKey, SystemVotes votesAtRollover);
    event BalanceTrackerAddressSet(address contractAddress);
    event ProxySubmitterSet(address[] accounts, bool allowed);
    event ReactorKeysSet(bytes32[] allValidKeys);
    event VoteMultipliersSet(VoteTokenMultipler[] multipliers);
    event ProxyRateLimitSet(uint256 voteEveryBlockLimit);
    event SigningChainIdSet(uint256 chainId);

    /// @notice Get the current nonce an account should use to vote with
    /// @param account Account to query
    /// @return nonce Nonce that shoul dbe used to vote with
    function userNonces(address account) external returns (uint256 nonce);

    /// @notice Get the last block a user submitted a vote through a relayer
    /// @param account Account to check
    /// @return blockNumber
    function lastUserProxyVoteBlock(address account) external returns (uint256 blockNumber);

    /// @notice Check if an account is currently configured as a relayer
    /// @param account Account to check
    /// @return allowed
    function proxySubmitters(address account) external returns (bool allowed);

    /// @notice Get the tokens that are currently used to calculate voting power
    /// @return tokens
    function getVotingTokens() external view returns (address[] memory tokens);

    /// @notice Allows backfilling of current balance
    /// @param userVotePayload Users vote percent breakdown
    /// @param signature Account signature
    function vote(UserVotePayload calldata userVotePayload, Signature memory signature) external;

    function voteDirect(UserVotePayload memory userVotePayload) external;

    /// @notice Updates the users and system aggregation based on their current balances
    /// @param accounts Accounts that just had their balance updated
    /// @dev Should call back to BalanceTracker to pull that accounts current balance
    function updateUserVoteTotals(address[] memory accounts) external;

    /// @notice Set the contract that should be used to lookup user balances
    /// @param contractAddress Address of the contract
    function setBalanceTrackerAddress(address contractAddress) external;

    /// @notice Toggle the accounts that are currently used to relay votes and thus subject to rate limits
    /// @param submitters Relayer account array
    /// @param allowed Add or remove the account
    function setProxySubmitters(address[] calldata submitters, bool allowed) external;

    /// @notice Get the reactors we are currently accepting votes for
    /// @return reactorKeys Reactor keys we are currently accepting
    function getReactorKeys() external view returns (bytes32[] memory reactorKeys);

    /// @notice Set the reactors that we are currently accepting votes for
    /// @param reactorKeys Array for token+key where token is the underlying ERC20 for the reactor and key is asset-default|exchange
    /// @param allowed Add or remove the keys from use
    /// @dev Only current reactor keys will be returned from getSystemVotes()
    function setReactorKeys(VotingLocation[] memory reactorKeys, bool allowed) external;

    /// @notice Current votes for the account
    /// @param account Account to get votes for
    /// @return Votes for the current account
    function getUserVotes(address account) external view returns (UserVotes memory);

    /// @notice Current total votes for the system
    /// @return systemVotes
    function getSystemVotes() external view returns (SystemVotes memory systemVotes);

    /// @notice Get the current voting power for an account
    /// @param account Account to check
    /// @return Current voting power
    function getMaxVoteBalance(address account) external view returns (uint256);

    /// @notice Given a set of token balances, determine the voting power given current multipliers
    /// @param balances Token+Amount to use for calculating votes
    /// @return votes Voting power
    function getVotingPower(TokenBalance[] memory balances) external view returns (uint256 votes);

    /// @notice Set the voting power tokens get
    /// @param multipliers Token and multipliers to set. Multipliers should have 18 precision
    function setVoteMultiplers(VoteTokenMultipler[] memory multipliers) external;

    /// @notice Set the rate limit for using the proxy submission route
    /// @param voteEveryBlockLimit Minimum block gap between proxy submissions
    function setProxyRateLimit(uint256 voteEveryBlockLimit) external;

    /// @notice Returns general settings and current system vote details
    function getSettings() external view returns (VoteTrackSettings memory settings);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
pragma abicoder v2;

import "./events/IEventReceiver.sol";
import "./structs/TokenBalance.sol";

interface IBalanceTracker is IEventReceiver {


    struct SetTokenBalance {
        address account;
        address token;
        uint256 amount;
    }

    /// @param account User address
    /// @param token Token address
    /// @param amount User balance set for the user-token key
    /// @param stateSynced True if the event is from the L1 to L2 state sync. False if backfill
    /// @param applied False if the update was not actually recorded. Only applies to backfill updates that are skipped
    event BalanceUpdate(address account, address token, uint256 amount, bool stateSynced, bool applied);

    /// @notice Retrieve the current balances for the supplied account and tokens
    function getBalance(address account, address[] calldata tokens) external view returns (TokenBalance[] memory userBalances);

    /// @notice Allows backfilling of current balance
    /// @dev onlyOwner. Only allows unset balances to be updated
    function setBalance(SetTokenBalance[] calldata balances) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/// @notice Simple structure for events sent to Governance layer
struct EventWrapper {
    bytes32 eventType;
    bytes data;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/// @notice Event sent to Governance layer when a cycle rollover is complete
struct CycleRolloverEvent {
    bytes32 eventSig;
    uint256 cycleIndex;
    uint256 timestamp;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/// @notice Event sent to Governance layer when a users balance changes
struct BalanceUpdateEvent {
    bytes32 eventSig;
    address account;
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
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
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

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
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
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
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
pragma abicoder v2;

import "./IEventReceiver.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Base contract for receiving events through our Event Proxy
abstract contract EventReceiver is Initializable, IEventReceiver {
    address public eventProxy;

    event ProxyAddressSet(address proxyAddress);

    function init(address eventProxyAddress) public initializer {
        require(eventProxyAddress != address(0), "INVALID_ROOT_PROXY");

        _setEventProxyAddress(eventProxyAddress);
    }

    /// @notice Receive an encoded event from a contract on a different chain
    /// @param sender Contract address of sender on other chain
    /// @param eventType Encoded event type
    /// @param data Event Event data
    function onEventReceive(
        address sender,
        bytes32 eventType,
        bytes calldata data
    ) external override {
        require(msg.sender == eventProxy, "EVENT_PROXY_ONLY");

        _onEventReceive(sender, eventType, data);
    }

    /// @notice Implemented by child contracts to process events
    /// @param sender Contract address of sender on other chain
    /// @param eventType Encoded event type
    /// @param data Event Event data
    function _onEventReceive(
        address sender,
        bytes32 eventType,
        bytes calldata data
    ) internal virtual;

    /// @notice Configures the contract that can send events to this contract
    /// @param eventProxyAddress New sender address
    function _setEventProxyAddress(address eventProxyAddress) private {
        eventProxy = eventProxyAddress;

        emit ProxyAddressSet(eventProxy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/// @notice Vote payload to be submitted to Vote Tracker
struct UserVotePayload {
    address account;
    bytes32 voteSessionKey;
    uint256 nonce;
    uint256 chainId;
    uint256 totalVotes;
    UserVoteAllocationItem[] allocations;
}

/// @notice Individual allocation to an asset, exchange, or asset-pair
struct UserVoteAllocationItem {
    bytes32 reactorKey;
    uint256 amount; //18 Decimals
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
pragma abicoder v2;

interface IEventReceiver {
    /// @notice Receive an encoded event from a contract on a different chain
    /// @param sender Contract address of sender on other chain
    /// @param eventType Encoded event type
    /// @param data Event Event data
    function onEventReceive(
        address sender,
        bytes32 eventType,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

/// @notice Simple mapping of token to amount
struct TokenBalance {
    address token;
    uint256 amount;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// @notice Denotes the type of signature being submitted to contracts that support multiple
enum SignatureType {
    INVALID,
    // Specifically signTypedData_v4
    EIP712,
    // Specifically personal_sign
    ETHSIGN
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
                /// @solidity memory-safe-assembly
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