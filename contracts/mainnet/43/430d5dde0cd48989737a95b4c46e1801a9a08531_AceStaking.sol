// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Sender.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";
import "@openzeppelin/contracts/utils/introspection/ERC1820Implementer.sol";

contract AceStaking is
    Ownable,
    ReentrancyGuard,
    IERC721Receiver,
    IERC777Sender,
    IERC777Recipient,
    ERC1820Implementer
{
    // Interfaces for ERC777 and ERC721
    IERC777 public immutable rewardsToken;
    mapping(address => IERC721) public nftContracts;
    address[] public nftContractAddresses;

    // Reward Settings
    mapping(address => uint256) public rewardsForContract;
    mapping(address => mapping(uint256 => uint256))
        public additionalRewardsForToken;

    uint256 public rewardPeriodInSeconds;
    uint256 public totalTokensStakedCount;
    address internal REWARD_UPDATER;

    // Definition of Staker
    struct Staker {
        uint256 unclaimedRewards;
        uint256 lifetimeRewards;
        uint256 lastRewardedAt;
        uint256 lastClaimedAt;
    }

    // This is how we expect Tokens to be sent
    struct TokenData {
        address contractAddress;
        uint256 tokenIdentifier;
    }

    // How we keep track of a Staked token
    struct StakedToken {
        address contractAddress;
        uint256 tokenIdentifier;
        uint256 lastRewardedAt;
        uint256 stakedAt;
    }

    event UnstakedNFT(StakedToken stakedToken, address indexed staker);
    event StakedNFT(StakedToken stakedToken, address indexed staker);
    event RewardClaimed(address indexed staker, uint256 indexed amount);

    address[] public currentStakers;
    mapping(address => Staker) public stakers;
    mapping(address => StakedToken[]) public stakedTokensForAddress;
    mapping(address => mapping(uint256 => address)) public stakedTokenOwner;
    mapping(uint256 => mapping(address => uint256))
        internal sharesForWalletInRound;
    mapping(uint256 => address[]) internal walletsToRewardInRound;
    uint256 internal currentRoundId;

    uint256 public slashingPeriod = 24;

    // ERC777 Definitions
    event TokensToSendCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    event TokensReceivedCalled(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes data,
        bytes operatorData,
        address token,
        uint256 fromBalance,
        uint256 toBalance
    );

    bool private _shouldRevertSend;
    bool private _shouldRevertReceive;

    IERC1820Registry internal constant _ERC1820_REGISTRY =
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH =
        keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH =
        keccak256("ERC777TokensRecipient");

    /**
     * @dev Setsup the new Contract.
     *
     * @param _rewardsToken A ERC777 Token. Can't be changed!
     * @param _rewardPeriodInSeconds Every x Seconds the Reward gets emitted. Can't be changed! Needs to be at least 60 Seconds but at least a day is recommneded.
     */
    constructor(IERC777 _rewardsToken, uint256 _rewardPeriodInSeconds) {
        require(
            _rewardPeriodInSeconds > 60,
            "AceStaking: Rewards need to be paid at least once per minute"
        );
        rewardsToken = _rewardsToken;
        rewardPeriodInSeconds = _rewardPeriodInSeconds;
        REWARD_UPDATER = msg.sender;
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_RECIPIENT_INTERFACE_HASH,
            address(this)
        );
        _ERC1820_REGISTRY.setInterfaceImplementer(
            address(this),
            _TOKENS_SENDER_INTERFACE_HASH,
            address(this)
        );
    }

    /**
     * @dev Call this function to add a new NFT Contract to be accepted for staking.
     * Each contract can have differen rewards.
     *
     * Requirements: onlyOwner can add new Contracts; Contract needs to be ERC721 compliant.
     * @param _nftContract A ERC721 Contract that can be used for staking.
     * @param _reward ERC777 Token Value that is rewarded for each token every rewardPeriodInSeconds.
     */
    function addNFTContract(IERC721 _nftContract, uint256 _reward)
        public
        onlyOwner
    {
        nftContracts[address(_nftContract)] = _nftContract;
        nftContractAddresses.push(address(_nftContract));
        rewardsForContract[address(_nftContract)] = _reward;
    }

    /**
     * @dev Call this function to remove a NFT contract from beeing accepted for staking.
     * All tokens remain in the contract but wont receive any further rewards. They can be withdrawn by
     * the token owner.
     * Warning: Additional Rewards might stay in place, so call setAdditionalRewardsForTokens first and set their reward to 0.
     *
     * Requirements: onlyOwner can remove Contracts; Contract needs to be ERC721 compliant and already added through addNFTContract.
     * @param _nftContract A ERC721 Contract that should be removed from staking.
     */
    function removeNFTContract(address _nftContract) public onlyOwner {
        require(
            nftContracts[_nftContract] == IERC721(_nftContract),
            "AceStaking: Unkown Contract"
        );

        nftContracts[address(_nftContract)] = IERC721(address(0));
        rewardsForContract[address(_nftContract)] = 0;
        for (uint256 i; i < nftContractAddresses.length; i = unsafe_inc(i)) {
            if (nftContractAddresses[i] == _nftContract) {
                nftContractAddresses[i] = nftContractAddresses[
                    nftContractAddresses.length - 1
                ];
                nftContractAddresses.pop();
            }
        }
    }

    /**
     * @dev This function allows the contract owner to set an additional bonus that is
     * added for each token. The reward is added on top to the default reward for the contract.
     *
     * Requirements: onlyOwner or rewardUpdate (external contract) can remove Contracts; Contract needs to be ERC721 compliant
     * and already added through addNFTContract.
     * @param _nftContract A ERC721 Contract that is accepted by the contract.
     * @param _tokenIdentifiers Array of Identifiers that should receive the additional reward
     * @param _additionalReward ERC777 Token Value that is rewarded for each token every rewardPeriodInSeconds additionally to the default reward.
     */
    function setAdditionalRewardsForTokens(
        IERC721 _nftContract,
        uint256[] memory _tokenIdentifiers,
        uint256 _additionalReward
    ) external onlyRewardUpdater {
        require(
            nftContracts[address(_nftContract)] == IERC721(_nftContract),
            "AceStaking: Unkown Contract"
        );

        uint256 tokenCounter = _tokenIdentifiers.length;
        for (uint256 i; i < tokenCounter; i = unsafe_inc(i)) {
            additionalRewardsForToken[address(_nftContract)][
                _tokenIdentifiers[i]
            ] = _additionalReward;
        }
    }

    /**
     * @dev You need to claim your rewards at least once within this period.
     * If not you won't get any new rewards until you claim again.
     *
     * Requirements: onlyOwner can change that value
     *
     * @param _slashingPeriod Amount of Periods after that rewards get slashed
     */
    function setSlashingPeriod(uint256 _slashingPeriod) external onlyOwner {
        slashingPeriod = _slashingPeriod;
    }

    /**
     * @dev We reward a Bonus depending on different traits in some periods.
     * The choosen traits and to be rewareded tokens are calculated off-chain.
     * Tokens need to be staked when the reward is paid and already staked in the Snapshot of Tokens that is sent.
     * If you want to learn more about how our trait based bonus works take a look at our website.
     *
     * @param _tokens Array of TokenData(contractAddress, tokenId)
     * @param _totalBonus Amount of Tokens that should be distributed among sent tokens
     */
    function rewardBonus(TokenData[] calldata _tokens, uint256 _totalBonus)
        external
        onlyRewardUpdater
    {
        uint256 stakedTokensLength = _tokens.length;
        require(stakedTokensLength > 0, "AceStaking: No Tokens");
        require(
            _totalBonus > 0,
            "AceStaking: No Bonus to be distributed"
        );

        uint256 totalShares;
        currentRoundId += 1;
        for (uint256 i; i < stakedTokensLength; i = unsafe_inc(i)) {
            address _staker = stakedTokenOwner[_tokens[i].contractAddress][
                _tokens[i].tokenIdentifier
            ];
            if (_staker != address(0)) {
                sharesForWalletInRound[currentRoundId][_staker] += 100;
                walletsToRewardInRound[currentRoundId].push(_staker);
                totalShares += 1;
            }
        }

        require(totalShares > 0, "AceStaking: No shares to distribute");

        uint256 walletsToRewardLength = walletsToRewardInRound[currentRoundId]
            .length;
        for (uint256 i; i < walletsToRewardLength; i = unsafe_inc(i)) {
            address walletToCheck = walletsToRewardInRound[currentRoundId][i];
            if (sharesForWalletInRound[currentRoundId][walletToCheck] > 0) {
                uint256 rewardsForWallet = (sharesForWalletInRound[
                    currentRoundId
                ][walletToCheck] / totalShares) * (_totalBonus / 100);

                stakers[walletToCheck].unclaimedRewards += rewardsForWallet;
                stakers[walletToCheck].lifetimeRewards += rewardsForWallet;

                sharesForWalletInRound[currentRoundId][walletToCheck] = 0;
            }
        }
    }

    /**
     * @dev Function to estimate rewards for specific token on a contract in one period.
     * Token ID could be out of range we don't care since this is just for
     * simulating unstaked token rewards for UI.
     *
     * Requirements: nftContractAddress needs to be registereed on the staking contract.
     * @param nftContractAddress A ERC721 Contract of the token
     * @param tokenIdentifier Token Identifier that you want an estimation for
     */
    function estimateRewardsForToken(
        address nftContractAddress,
        uint256 tokenIdentifier
    ) public view returns (uint256) {
        require(
            nftContracts[nftContractAddress] == IERC721(nftContractAddress),
            "AceStaking: Unkown Contract"
        );
        return rewardsForToken(nftContractAddress, tokenIdentifier);
    }

    /**
     * @dev Returns multiple stats for the address. Returns those values:
     * - totalTokensStaked: Count of Tokens for this Wallet on the Staking Contract
     * - unclaimedRewards: Rewards that can be claimed but are unclaimed by the user
     * - unaccountedRewards: Rewards that are not ready to be claimed
     * because the current period did not finish yet. If tokens were staked on different
     * start times this number might never be 0.
     * - lifetimeRewards: Just counting up what a user earned over life
     *
     * @param _stakerAddress Wallet Address that has staked tokens on the contract
     */
    function stakerStats(address _stakerAddress)
        public
        view
        returns (
            uint256 totalTokensStaked,
            uint256 unclaimedRewards,
            uint256 unaccountedRewards,
            uint256 lifetimeRewards
        )
    {
        Staker memory staker = stakers[_stakerAddress];
        uint256 claimableRewards = calculateUnaccountedRewards(
            _stakerAddress,
            false
        );
        return (
            stakedTokensForAddress[_stakerAddress].length,
            staker.unclaimedRewards + claimableRewards,
            calculateUnaccountedRewards(_stakerAddress, true),
            staker.lifetimeRewards + claimableRewards
        );
    }

    /**
     * @dev Function to unstake all tokens for the msg.sender.
     * Also rewards msg.sender for all of his staked tokens his staked tokens and ejects all tokens after this.
     * If you have many tokens staked (50+) we recommend unstaking them in badges to not hit the gas limit of a block.
     */
    function unstakeAllTokens() external nonReentrant {
        StakedToken[] memory stakedTokens = stakedTokensForAddress[msg.sender];
        uint256 stakedTokensLength = stakedTokens.length;
        require(stakedTokensLength > 0, "AceStaking: No Tokens found");
        rewardStaker(msg.sender);
        for (uint256 i; i < stakedTokensLength; i = unsafe_inc(i)) {
            ejectToken(
                stakedTokens[i].contractAddress,
                stakedTokens[i].tokenIdentifier
            );
        }
    }

    /**
     * @dev Unstake a Set of Tokens for msg.sender.
     * Also rewards msg.sender for all of his staked tokens his staked tokens and ejects all sent tokens after this.
     *
     * @param _tokens Array of TokenData(contractAddress, tokenId)
     */
    function unstake(TokenData[] calldata _tokens) external nonReentrant {
        uint256 stakedTokensLength = _tokens.length;
        require(stakedTokensLength > 0, "AceStaking: No Tokens found");
        rewardStaker(msg.sender);
        for (uint256 i; i < stakedTokensLength; i = unsafe_inc(i)) {
            ejectToken(_tokens[i].contractAddress, _tokens[i].tokenIdentifier);
        }
    }

    /**
     * @dev Emergency Unstake Function: Unstake without any reward calculation.
     * !!! NOT RECOMMENDED, YOU MIGHT LOSE UNACCOUNTED REWARDS !!!
     * When to use? This function consumes less gas then the normal unstake since we do not reward all tokens before unstaking.
     * In case you hit the block limit for gas (very unlikely) we have a way to withdrawal your tokens somehow.
     * @param _tokens Array of TokenData(contractAddress, tokenId)
     */
    function emergencyUnstake(TokenData[] calldata _tokens)
        external
        nonReentrant
    {
        uint256 stakedTokensLength = _tokens.length;
        require(stakedTokensLength > 0, "AceStaking: No Tokens in calldata");
        for (uint256 i; i < stakedTokensLength; i = unsafe_inc(i)) {
            ejectToken(_tokens[i].contractAddress, _tokens[i].tokenIdentifier);
        }
    }

    /**
     * @dev This function transfers tokens to the contract with transferFrom.
     * thusfor we need to call addToken manually but we save a little on gas.
     *
     * Requirements: All token contracts need to be added to this contract and be approved by the user.
     *
     * @param _tokens Array of TokenData(contractAddress, tokenId)
     */
    function stake(TokenData[] calldata _tokens) external {
        beforeTokensAdded(msg.sender);
        uint256 tokensLength = _tokens.length;
        for (uint256 i; i < tokensLength; i = unsafe_inc(i)) {
            IERC721(_tokens[i].contractAddress).transferFrom(
                msg.sender,
                address(this),
                _tokens[i].tokenIdentifier
            );
            addToken(
                _tokens[i].contractAddress,
                _tokens[i].tokenIdentifier,
                msg.sender
            );
        }
    }

    /**
     * @dev Call this function to get your ERC777 Token rewards transfered to your wallet.
     * This is an expensive call since we calculate your current earnings and send them in one
     * Transaction to your wallet.
     *
     */
    function claimRewards() external nonReentrant {
        rewardStaker(msg.sender);
        require(
            stakers[msg.sender].unclaimedRewards > 0,
            "AceStaking: Nothing to claim"
        );
        IERC777(rewardsToken).send(
            msg.sender,
            stakers[msg.sender].unclaimedRewards,
            ""
        );
        emit RewardClaimed(msg.sender, stakers[msg.sender].unclaimedRewards);
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].lastClaimedAt = block.timestamp;
    }

    /**
     * @dev This function determains how many periods should be calculated for rewarding.
     *
     * @param _lastRewardedAt timestamp when the token was rewarded last
     * @param _lastClaimedAt timestamp when ist was last claimed
     *
     */
    function rewardPeriods(uint256 _lastRewardedAt, uint256 _lastClaimedAt)
        internal
        view
        returns (uint256 _rewardPeriodCounter)
    {
        uint256 referenceTimestamp = block.timestamp;
        if (
            referenceTimestamp >
            (_lastClaimedAt + slashingPeriod * rewardPeriodInSeconds)
        ) {
            referenceTimestamp =
                _lastClaimedAt +
                slashingPeriod *
                rewardPeriodInSeconds;
        }
        return (referenceTimestamp - _lastRewardedAt) / rewardPeriodInSeconds;
    }

    /**
     * @dev Calculates Rewards for a User and accounts them to his entry.
     *
     * @param _stakerAddress staker that should be rewarded
     *
     */
    function rewardUnaccountedRewards(address _stakerAddress)
        internal
        returns (uint256 _rewards)
    {
        StakedToken[] memory stakedTokens = stakedTokensForAddress[
            _stakerAddress
        ];
        uint256 totalRewards;
        uint256 stakedTokensCount = stakedTokens.length;
        for (uint256 i; i < stakedTokensCount; i = unsafe_inc(i)) {
            uint256 periodsToReward = rewardPeriods(
                stakedTokens[i].lastRewardedAt,
                stakers[_stakerAddress].lastClaimedAt
            );

            if (periodsToReward > 0) {
                totalRewards +=
                    periodsToReward *
                    rewardsForToken(
                        stakedTokens[i].contractAddress,
                        stakedTokens[i].tokenIdentifier
                    );
                if (periodsToReward == slashingPeriod) {
                    stakedTokensForAddress[_stakerAddress][i].lastRewardedAt =
                        stakedTokensForAddress[_stakerAddress][i].stakedAt +
                        (
                            uint256(
                                (block.timestamp -
                                    stakedTokensForAddress[_stakerAddress][i]
                                        .stakedAt) / rewardPeriodInSeconds
                            )
                        ) *
                        rewardPeriodInSeconds;
                } else {
                    stakedTokensForAddress[_stakerAddress][i].lastRewardedAt =
                        stakedTokensForAddress[_stakerAddress][i].stakedAt +
                        periodsToReward *
                        rewardPeriodInSeconds;
                }
            }
        }
        return totalRewards;
    }

    /**
     * @dev Calculates Rewards for a User but does not account them.
     *
     * @param _stakerAddress staker that should be rewarded
     * @param _simulateUnaccounted include unaccounted rewards that can't be claimed yet
     *
     */
    function calculateUnaccountedRewards(
        address _stakerAddress,
        bool _simulateUnaccounted
    ) internal view returns (uint256 _rewards) {
        StakedToken[] memory stakedTokens = stakedTokensForAddress[
            _stakerAddress
        ];
        uint256 totalRewards;
        uint256 stakedTokensCount = stakedTokens.length;
        for (uint256 i; i < stakedTokensCount; i = unsafe_inc(i)) {
            uint256 periodsToReward = rewardPeriods(
                stakedTokens[i].lastRewardedAt,
                stakers[_stakerAddress].lastClaimedAt
            );

            uint256 tokenReward = rewardsForToken(
                stakedTokens[i].contractAddress,
                stakedTokens[i].tokenIdentifier
            );
            if (_simulateUnaccounted) {
                totalRewards +=
                    ((((block.timestamp - stakedTokens[i].lastRewardedAt) *
                        100) / rewardPeriodInSeconds) * tokenReward) /
                    100 -
                    periodsToReward *
                    tokenReward;
            } else {
                totalRewards += tokenReward * periodsToReward;
            }
        }
        return totalRewards;
    }

    /**
     * @dev Summarize rewards for a specific token on a contract.
     * Sums up default rewards for contract and bonus for token identifier.
     *
     * @param nftContractAddress Contract to check
     * @param tokenIdentifier Token Identifier to check
     *
     */
    function rewardsForToken(
        address nftContractAddress,
        uint256 tokenIdentifier
    ) internal view returns (uint256) {
        return
            rewardsForContract[nftContractAddress] +
            additionalRewardsForToken[nftContractAddress][tokenIdentifier];
    }

    /**
     * @dev Function that moves all unaccounted rewards to unclaimed.
     * This call is required to keep our internal balance sheets up to date.
     * Depending on Token Amount this is very expensive to call since we loop through all tokens!
     *
     * @param _address Wallet Address that should be rewarded
     *
     */
    function rewardStaker(address _address) internal {
        uint256 unaccountedRewards = rewardUnaccountedRewards(_address);
        stakers[_address].lastRewardedAt = block.timestamp;
        stakers[_address].unclaimedRewards += unaccountedRewards;
        stakers[_address].lifetimeRewards += unaccountedRewards;
    }

    /**
     * @dev Internal function to send a token back to a user. Also
     * removes / updates all contract internal trackings.
     *
     * Requirements: msg.sender needs to be the wallet that sent the token to the contract.
     *
     * @param nftContractAddress Contract for the token to be ejected
     * @param tokenIdentifier Token Identifier for the token to be ejected
     *
     */
    function ejectToken(address nftContractAddress, uint256 tokenIdentifier)
        internal
    {
        require(
            stakedTokenOwner[nftContractAddress][tokenIdentifier] == msg.sender,
            "AceStaking: Not your token..."
        );

        IERC721(nftContractAddress).transferFrom(
            address(this),
            msg.sender,
            tokenIdentifier
        );

        for (
            uint256 i;
            i < stakedTokensForAddress[msg.sender].length;
            i = unsafe_inc(i)
        ) {
            if (
                stakedTokensForAddress[msg.sender][i].tokenIdentifier ==
                tokenIdentifier &&
                stakedTokensForAddress[msg.sender][i].contractAddress ==
                nftContractAddress
            ) {
                emit UnstakedNFT(
                    stakedTokensForAddress[msg.sender][i],
                    msg.sender
                );
                stakedTokensForAddress[msg.sender][i] = stakedTokensForAddress[
                    msg.sender
                ][stakedTokensForAddress[msg.sender].length - 1];
                stakedTokensForAddress[msg.sender].pop();
            }
        }

        if (stakedTokensForAddress[msg.sender].length == 0) {
            for (uint256 i; i < currentStakers.length; i = unsafe_inc(i)) {
                if (currentStakers[i] == msg.sender) {
                    currentStakers[i] = currentStakers[
                        currentStakers.length - 1
                    ];
                    currentStakers.pop();
                }
            }
        }

        stakedTokenOwner[msg.sender][tokenIdentifier] = address(0);
        totalTokensStakedCount -= 1;
    }

    /**
     * @dev Helper that should be called before any token is added. Needs to be called
     * only once per batch. It basically setup the staker object.
     *
     * @param _staker Wallet Address for Staker
     */
    function beforeTokensAdded(address _staker) internal {
        if (stakedTokensForAddress[_staker].length == 0) {
            if (stakers[_staker].lastRewardedAt > 0) {
                // This wallet already staked before and was at least rewarded once.
                stakers[_staker].lastRewardedAt = block.timestamp;
                stakers[_staker].lastClaimedAt = block.timestamp;
            } else {
                // This wallet is new to us
                stakers[_staker] = Staker(
                    stakers[_staker].unclaimedRewards,
                    stakers[_staker].lifetimeRewards,
                    block.timestamp,
                    block.timestamp
                );
            }
            currentStakers.push(_staker);
        }
    }

    /**
     * @dev Function to add a token and regiter it in all mappings that we need to
     * return and reward a token.
     *
     * @param nftContractAddress Contract of the token
     * @param tokenIdentifier The Identifier of a token
     * @param tokenOwnerAddress The address of the current owner
     */
    function addToken(
        address nftContractAddress,
        uint256 tokenIdentifier,
        address tokenOwnerAddress
    ) internal {
        require(
            nftContracts[nftContractAddress] == IERC721(nftContractAddress),
            "AceStaking: Unkown Contract"
        );

        StakedToken memory newToken = StakedToken(
            nftContractAddress,
            tokenIdentifier,
            block.timestamp,
            block.timestamp
        );
        stakedTokenOwner[nftContractAddress][
            tokenIdentifier
        ] = tokenOwnerAddress;

        stakedTokensForAddress[tokenOwnerAddress].push(newToken);
        totalTokensStakedCount += 1;
        emit StakedNFT(newToken, tokenOwnerAddress);
    }

    function unsafe_inc(uint256 x) private pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}. Also registers token in our TokenRegistry.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address, // operator not required
        address tokenOwnerAddress,
        uint256 tokenIdentifier,
        bytes memory
    ) public virtual override returns (bytes4) {
        beforeTokensAdded(tokenOwnerAddress);
        addToken(msg.sender, tokenIdentifier, tokenOwnerAddress);
        return this.onERC721Received.selector;
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        if (_shouldRevertSend) {
            revert();
        }

        IERC777 token = IERC777(_msgSender());

        uint256 fromBalance = token.balanceOf(from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = token.balanceOf(to);

        emit TokensToSendCalled(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            address(token),
            fromBalance,
            toBalance
        );
    }

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {
        if (_shouldRevertReceive) {
            revert();
        }

        IERC777 token = IERC777(_msgSender());

        uint256 fromBalance = token.balanceOf(from);
        // when called due to burn, to will be the zero address, which will have a balance of 0
        uint256 toBalance = token.balanceOf(to);

        emit TokensReceivedCalled(
            operator,
            from,
            to,
            amount,
            userData,
            operatorData,
            address(token),
            fromBalance,
            toBalance
        );
    }


    /**
     * @dev This address is allowed to change the rewards for a specific token.
     * Since opening a chest door results in a different reward, this is implemented in the chest door opener contract later.
     *
     * @param _REWARD_UPDATER Address that is allowed to modify rewards
     */
    function setRewardUpdater(address _REWARD_UPDATER) external onlyOwner {
        REWARD_UPDATER = _REWARD_UPDATER;
    }

    modifier onlyRewardUpdater() {
        require(
            msg.sender == REWARD_UPDATER || msg.sender == owner(),
            "AceStaking: Only REWARD_UPDATE or OWNER."
        );
        _;
    }
}

/** created with bowline.app **/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820Registry {
    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);

    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC1820Implementer.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for an ERC1820 implementer, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820#interface-implementation-erc1820implementerinterface[EIP].
 * Used by contracts that will be registered as implementers in the
 * {IERC1820Registry}.
 */
interface IERC1820Implementer {
    /**
     * @dev Returns a special value (`ERC1820_ACCEPT_MAGIC`) if this contract
     * implements `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC1820Implementer.sol)

pragma solidity ^0.8.0;

import "./IERC1820Implementer.sol";

/**
 * @dev Implementation of the {IERC1820Implementer} interface.
 *
 * Contracts may inherit from this and call {_registerInterfaceForAddress} to
 * declare their willingness to be implementers.
 * {IERC1820Registry-setInterfaceImplementer} should then be called for the
 * registration to be complete.
 */
contract ERC1820Implementer is IERC1820Implementer {
    bytes32 private constant _ERC1820_ACCEPT_MAGIC = keccak256("ERC1820_ACCEPT_MAGIC");

    mapping(bytes32 => mapping(address => bool)) private _supportedInterfaces;

    /**
     * @dev See {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address account)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _supportedInterfaces[interfaceHash][account] ? _ERC1820_ACCEPT_MAGIC : bytes32(0x00);
    }

    /**
     * @dev Declares the contract as willing to be an implementer of
     * `interfaceHash` for `account`.
     *
     * See {IERC1820Registry-setInterfaceImplementer} and
     * {IERC1820Registry-interfaceHash}.
     */
    function _registerInterfaceForAddress(bytes32 interfaceHash, address account) internal virtual {
        _supportedInterfaces[interfaceHash][account] = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC777/IERC777Sender.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 * their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Sender {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}