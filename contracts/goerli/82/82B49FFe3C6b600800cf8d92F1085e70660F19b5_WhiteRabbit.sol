// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./WhiteRabbitProducerPass.sol";

contract WhiteRabbit is Ownable, ERC1155Holder {
    using Strings for uint256;
    using SafeMath for uint256;

    // The Producer Pass contract used for staking/voting on episodes
    WhiteRabbitProducerPass private whiteRabbitProducerPass;
    // The total number of episodes that make up the film
    uint256 private _numberOfEpisodes;
    // A mapping from episodeId to whether or not voting is enabled
    mapping(uint256 => bool) public votingEnabledForEpisode;

    // The address of the White Rabbit token ($WRAB)
    address public whiteRabbitTokenAddress;
    // The initial fixed supply of White Rabbit tokens
    uint256 public tokenInitialFixedSupply;

    // The wallet addresses of the two artists creating the film
    address private _artist1Address;
    address private _artist2Address;

    // The percentage of White Rabbit tokens that will go to the artists
    uint256 public artistTokenAllocationPercentage;
    // The number of White Rabbit tokens to send to each artist per episode
    uint256 public artistTokenPerEpisodePerArtist;
    // A mapping from episodeId to a boolean indicating whether or not
    // White Rabbit tokens have been transferred the artists yet
    mapping(uint256 => bool) public hasTransferredTokensToArtistForEpisode;

    // The percentage of White Rabbit tokens that will go to producers (via Producer Pass staking)
    uint256 public producersTokenAllocationPercentage;
    // The number of White Rabbit tokens to send to producers per episode
    uint256 public producerPassTokenAllocationPerEpisode;
    // The base number of White Rabbit tokens to allocate to producers per episode
    uint256 public producerPassTokenBaseAllocationPerEpisode;
    // The number of White Rabbit tokens to allocate to producers who stake early
    uint256 public producerPassTokenEarlyStakingBonusAllocationPerEpisode;
    // The number of White Rabbit tokens to allocate to producers who stake for the winning option
    uint256 public producerPassTokenWinningBonusAllocationPerEpisode;

    // The percentage of White Rabbit tokens that will go to the platform team
    uint256 public teamTokenAllocationPercentage;
    // Whether or not the team has received its share of White Rabbit tokens
    bool public teamTokenAllocationDistributed;

    // Event emitted when a Producer Pass is staked to vote for an episode option
    event ProducerPassStaked(
        address indexed account,
        uint256 episodeId,
        uint256 voteId,
        uint256 amount,
        uint256 tokenAmount
    );
    // Event emitted when a Producer Pass is unstaked after voting is complete
    event ProducerPassUnstaked(
        address indexed account,
        uint256 episodeId,
        uint256 voteId,
        uint256 tokenAmount
    );

    // The list of episode IDs (e.g. [1, 2, 3, 4])
    uint256[] public episodes;

    // The voting option IDs by episodeId (e.g. 1 => [1, 2])
    mapping(uint256 => uint256[]) private _episodeOptions;

    // The total vote counts for each episode voting option, agnostic of users
    // _episodeVotesByOptionId[episodeId][voteOptionId] => number of votes
    mapping(uint256 => mapping(uint256 => uint256))
        private _episodeVotesByOptionId;

    // A mapping from episodeId to the winning vote option
    // 0 means no winner has been declared yet
    mapping(uint256 => uint256) public winningVoteOptionByEpisode;

    // A mapping of how many Producer Passes have been staked per user per episode per option
    // e.g. _usersStakedEpisodeVotingOptionsCount[address][episodeId][voteOptionId] => number staked
    // These values will be updated/decremented when Producer Passes are unstaked
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        private _usersStakedEpisodeVotingOptionsCount;

    // A mapping of the *history* how many Producer Passes have been staked per user per episode per option
    // e.g. _usersStakedEpisodeVotingHistoryCount[address][episodeId][voteOptionId] => number staked
    // Note: These values DO NOT change after Producer Passes are unstaked
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        private _usersStakedEpisodeVotingHistoryCount;

    // The base URI for episode metadata
    string private _episodeBaseURI;
    // The base URI for episode voting option metadata
    string private _episodeOptionBaseURI;

    /**
     * @dev Initializes the contract by setting up the Producer Pass contract to be used
     */
    constructor(address whiteRabbitProducerPassContract) {
        whiteRabbitProducerPass = WhiteRabbitProducerPass(
            whiteRabbitProducerPassContract
        );
    }

    /**
     * @dev Sets the Producer Pass contract to be used
     */
    function setWhiteRabbitProducerPassContract(
        address whiteRabbitProducerPassContract
    ) external onlyOwner {
        whiteRabbitProducerPass = WhiteRabbitProducerPass(
            whiteRabbitProducerPassContract
        );
    }

    /**
     * @dev Sets the base URI for episode metadata
     */
    function setEpisodeBaseURI(string memory baseURI) external onlyOwner {
        _episodeBaseURI = baseURI;
    }

    /**
     * @dev Sets the base URI for episode voting option metadata
     */
    function setEpisodeOptionBaseURI(string memory baseURI) external onlyOwner {
        _episodeOptionBaseURI = baseURI;
    }

    /**
     * @dev Sets the list of episode IDs (e.g. [1, 2, 3, 4])
     *
     * This will be updated every time a new episode is added.
     */
    function setEpisodes(uint256[] calldata _episodes) external onlyOwner {
        episodes = _episodes;
    }

    /**
     * @dev Sets the voting option IDs for a given episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function setEpisodeOptions(
        uint256 episodeId,
        uint256[] calldata episodeOptionIds
    ) external onlyOwner {
        require(episodeId <= episodes.length, "Episode does not exist");
        _episodeOptions[episodeId] = episodeOptionIds;
    }

    /**
     * @dev Retrieves the voting option IDs for a given episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function getEpisodeOptions(uint256 episodeId)
        public
        view
        returns (uint256[] memory)
    {
        require(episodeId <= episodes.length, "Episode does not exist");
        return _episodeOptions[episodeId];
    }

    /**
     * @dev Retrieves the number of episodes currently available.
     */
    function getCurrentEpisodeCount() external view returns (uint256) {
        return episodes.length;
    }

    /**
     * @dev Constructs the metadata URI for a given episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function episodeURI(uint256 episodeId)
        public
        view
        virtual
        returns (string memory)
    {
        require(episodeId <= episodes.length, "Episode does not exist");
        string memory baseURI = episodeBaseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, episodeId.toString(), ".json")
                )
                : "";
    }

    /**
     * @dev Constructs the metadata URI for a given episode voting option.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - The episode voting option ID is valid
     */
    function episodeOptionURI(uint256 episodeId, uint256 episodeOptionId)
        public
        view
        virtual
        returns (string memory)
    {
        // TODO: DRY up these requirements? ("Episode does not exist", "Invalid voting option")
        require(episodeId <= episodes.length, "Episode does not exist");

        string memory baseURI = episodeOptionBaseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        _episodeOptionBaseURI,
                        episodeId.toString(),
                        "/",
                        episodeOptionId.toString(),
                        ".json"
                    )
                )
                : "";
    }

    /**
     * @dev Getter for the `_episodeBaseURI`
     */
    function episodeBaseURI() internal view virtual returns (string memory) {
        return _episodeBaseURI;
    }

    /**
     * @dev Getter for the `_episodeOptionBaseURI`
     */
    function episodeOptionBaseURI()
        internal
        view
        virtual
        returns (string memory)
    {
        return _episodeOptionBaseURI;
    }

    /**
     * @dev Retrieves the voting results for a given episode's voting option ID
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - Voting is no longer enabled for the given episode
     * - Voting has completed and a winning option has been declared
     */
    function episodeVotes(uint256 episodeId, uint256 episodeOptionId)
        public
        view
        virtual
        returns (uint256)
    {
        require(episodeId <= episodes.length, "Episode does not exist");
        require(!votingEnabledForEpisode[episodeId], "Voting is still enabled");
        require(
            winningVoteOptionByEpisode[episodeId] > 0,
            "Voting not finished"
        );
        return _episodeVotesByOptionId[episodeId][episodeOptionId];
    }

    /**
     * @dev Retrieves the number of Producer Passes that the user has staked
     * for a given episode and voting option at this point in time.
     *
     * Note that this number will change after a user has unstaked.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function userStakedProducerPassCount(
        uint256 episodeId,
        uint256 episodeOptionId
    ) public view virtual returns (uint256) {
        require(episodeId <= episodes.length, "Episode does not exist");
        return
            _usersStakedEpisodeVotingOptionsCount[msg.sender][episodeId][
                episodeOptionId
            ];
    }

    /**
     * @dev Retrieves the historical number of Producer Passes that the user
     * has staked for a given episode and voting option.
     *
     * Note that this number will not change as a result of unstaking.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function userStakedProducerPassCountHistory(
        uint256 episodeId,
        uint256 episodeOptionId
    ) public view virtual returns (uint256) {
        require(episodeId <= episodes.length, "Episode does not exist");
        return
            _usersStakedEpisodeVotingHistoryCount[msg.sender][episodeId][
                episodeOptionId
            ];
    }

    /**
     * @dev Stakes Producer Passes for the given episode's voting option ID,
     * with the ability to specify an `amount`. Staking is used to vote for the option
     * that the user would like to see producers for the next episode.
     *
     * Emits a `ProducerPassStaked` event indicating that the staking was successful,
     * including the total number of White Rabbit tokens allocated as a result.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - Voting is enabled for the given episode
     * - The user is attempting to stake more than zero Producer Passes
     * - The user has enough Producer Passes to stake
     * - The episode voting option is valid
     * - A winning option hasn't been declared yet
     */
    function stakeProducerPass(
        uint256 episodeId,
        uint256 voteOptionId,
        uint256 amount
    ) public {
        require(episodeId <= episodes.length, "Episode does not exist");
        require(votingEnabledForEpisode[episodeId], "Voting not enabled");
        require(amount > 0, "Cannot stake 0");
        require(
            whiteRabbitProducerPass.balanceOf(msg.sender, episodeId) >= amount,
            "Insufficient pass balance"
        );
        uint256[] memory votingOptionsForThisEpisode = _episodeOptions[
            episodeId
        ];
        // vote options should be [1, 2], ID <= length
        require(
            votingOptionsForThisEpisode.length >= voteOptionId,
            "Invalid voting option"
        );
        uint256 winningVoteOptionId = winningVoteOptionByEpisode[episodeId];
        // rely on winningVoteOptionId to determine that this episode is valid for voting on
        require(winningVoteOptionId == 0, "Winner already declared");

        // user's vote count for selected episode & option
        uint256 userCurrentVoteCount = _usersStakedEpisodeVotingOptionsCount[
            msg.sender
        ][episodeId][voteOptionId];

        // Get total vote count of this option user is voting/staking for
        uint256 currentTotalVoteCount = _episodeVotesByOptionId[episodeId][
            voteOptionId
        ];

        // Get total vote count from every option of this episode for bonding curve calculation
        uint256 totalVotesForEpisode = 0;

        for (uint256 i = 0; i < votingOptionsForThisEpisode.length; i++) {
            uint256 currentVotingOptionId = votingOptionsForThisEpisode[i];
            totalVotesForEpisode += _episodeVotesByOptionId[episodeId][
                currentVotingOptionId
            ];
        }

        // calculate token rewards here
        uint256 tokensAllocated = getTokenAllocationForUserBeforeStaking(
            episodeId,
            amount
        );
        uint256 userNewVoteCount = userCurrentVoteCount + amount;
        _usersStakedEpisodeVotingOptionsCount[msg.sender][episodeId][
            voteOptionId
        ] = userNewVoteCount;
        _usersStakedEpisodeVotingHistoryCount[msg.sender][episodeId][
            voteOptionId
        ] = userNewVoteCount;
        _episodeVotesByOptionId[episodeId][voteOptionId] =
            currentTotalVoteCount +
            amount;

        // Take custody of producer passes from user
        whiteRabbitProducerPass.safeTransferFrom(
            msg.sender,
            address(this),
            episodeId,
            amount,
            ""
        );
        // Distribute wr tokens to user
        IERC20(whiteRabbitTokenAddress).transfer(msg.sender, tokensAllocated);

        emit ProducerPassStaked(
            msg.sender,
            episodeId,
            voteOptionId,
            amount,
            tokensAllocated
        );
    }

    /**
     * @dev Unstakes Producer Passes for the given episode's voting option ID and
     * sends White Rabbit tokens to the user's wallet if they staked for the winning side.
     *
     *
     * Emits a `ProducerPassUnstaked` event indicating that the unstaking was successful,
     * including the total number of White Rabbit tokens allocated as a result.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - Voting is not enabled for the given episode
     * - The episode voting option is valid
     * - A winning option has been declared
     */
    function unstakeProducerPasses(uint256 episodeId, uint256 voteOptionId)
        public
    {
        require(!votingEnabledForEpisode[episodeId], "Voting is still enabled");
        uint256 stakedProducerPassCount = _usersStakedEpisodeVotingOptionsCount[
            msg.sender
        ][episodeId][voteOptionId];
        require(stakedProducerPassCount > 0, "No producer passes staked");
        uint256 winningBonus = getUserWinningBonus(episodeId, voteOptionId) *
            stakedProducerPassCount;

        _usersStakedEpisodeVotingOptionsCount[msg.sender][episodeId][
            voteOptionId
        ] = 0;
        if (winningBonus > 0) {
            IERC20(whiteRabbitTokenAddress).transfer(msg.sender, winningBonus);
        }
        whiteRabbitProducerPass.safeTransferFrom(
            address(this),
            msg.sender,
            episodeId,
            stakedProducerPassCount,
            ""
        );

        emit ProducerPassUnstaked(
            msg.sender,
            episodeId,
            voteOptionId,
            winningBonus
        );
    }

    /**
     * @dev Calculates the number of White Rabbit tokens to award the user for unstaking
     * their Producer Passes for a given episode's voting option ID.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - Voting is not enabled for the given episode
     * - The episode voting option is valid
     * - A winning option has been declared
     */
    function getUserWinningBonus(uint256 episodeId, uint256 episodeOptionId)
        public
        view
        returns (uint256)
    {
        uint256 winningVoteOptionId = winningVoteOptionByEpisode[episodeId];
        require(winningVoteOptionId > 0, "Voting is not finished");
        require(!votingEnabledForEpisode[episodeId], "Voting is still enabled");

        bool isWinningOption = winningVoteOptionId == episodeOptionId;
        uint256 numberOfWinningVotes = _episodeVotesByOptionId[episodeId][
            episodeOptionId
        ];
        uint256 winningBonus = 0;

        if (isWinningOption && numberOfWinningVotes > 0) {
            winningBonus =
                producerPassTokenWinningBonusAllocationPerEpisode /
                numberOfWinningVotes;
        }
        return winningBonus;
    }

    /**
     * @dev This method is only for the owner since we want to hide the voting results from the public
     * until after voting has ended. Users can verify the veracity of this via the `episodeVotes` method
     * which can be called publicly after voting has finished for an episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function getTotalVotesForEpisode(uint256 episodeId)
        external
        view
        onlyOwner
        returns (uint256[] memory)
    {
        uint256[] memory votingOptionsForThisEpisode = _episodeOptions[
            episodeId
        ];
        uint256[] memory totalVotes = new uint256[](
            votingOptionsForThisEpisode.length
        );

        for (uint256 i = 0; i < votingOptionsForThisEpisode.length; i++) {
            uint256 currentVotingOptionId = votingOptionsForThisEpisode[i];
            uint256 votesForEpisode = _episodeVotesByOptionId[episodeId][
                currentVotingOptionId
            ];

            totalVotes[i] = votesForEpisode;
        }

        return totalVotes;
    }

    /**
     * @dev Owner method to toggle the voting state of a given episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     * - The voting state is different than the current state
     * - A winning option has not yet been declared
     */
    function setVotingEnabledForEpisode(uint256 episodeId, bool enabled)
        public
        onlyOwner
    {
        require(episodeId <= episodes.length, "Episode does not exist");
        require(
            votingEnabledForEpisode[episodeId] != enabled,
            "Voting state unchanged"
        );
        // if winner already set, don't allow re-opening of voting
        if (enabled) {
            require(
                winningVoteOptionByEpisode[episodeId] == 0,
                "Winner for episode already set"
            );
        }
        votingEnabledForEpisode[episodeId] = enabled;
    }

    /**
     * @dev Sets up the distribution parameters for White Rabbit (WRAB) tokens.
     *
     * - We will create fractionalized NFT basket first, which will represent the finished film NFT
     * - Tokens will be stored on platform and distributed to artists and producers as the film progresses
     *   - Artist distribution happens when new episodes are uploaded
     *   - Producer distribution happens when Producer Passes are staked and unstaked (with a bonus for winning the vote)
     *
     * Requirements:
     *
     * - The allocation percentages do not exceed 100%
     */
    function startWhiteRabbitShowWithParams(
        address tokenAddress,
        address artist1Address,
        address artist2Address,
        uint256 numberOfEpisodes,
        uint256 producersAllocationPercentage,
        uint256 artistAllocationPercentage,
        uint256 teamAllocationPercentage
    ) external onlyOwner {
        require(
            (producersAllocationPercentage +
                artistAllocationPercentage +
                teamAllocationPercentage) <= 100,
            "Total percentage exceeds 100"
        );
        whiteRabbitTokenAddress = tokenAddress;
        tokenInitialFixedSupply = IERC20(whiteRabbitTokenAddress).totalSupply();
        _artist1Address = artist1Address;
        _artist2Address = artist2Address;
        _numberOfEpisodes = numberOfEpisodes;
        producersTokenAllocationPercentage = producersAllocationPercentage;
        artistTokenAllocationPercentage = artistAllocationPercentage;
        teamTokenAllocationPercentage = teamAllocationPercentage;
        // If total supply is 1000000 and pct is 40 => (1000000 * 40) / (7 * 100 * 2) => 28571
        artistTokenPerEpisodePerArtist =
            (tokenInitialFixedSupply * artistTokenAllocationPercentage) /
            (_numberOfEpisodes * 100 * 2); // 2 for 2 artists
        // If total supply is 1000000 and pct is 40 => (1000000 * 40) / (7 * 100) => 57142
        producerPassTokenAllocationPerEpisode =
            (tokenInitialFixedSupply * producersTokenAllocationPercentage) /
            (_numberOfEpisodes * 100);
    }

    /**
     * @dev Sets the White Rabbit (WRAB) token distrubution for producers.
     * This distribution is broken into 3 categories:
     * - Base allocation (every Producer Pass gets the same)
     * - Early staking bonus (bonding curve distribution where earlier stakers are rewarded more)
     * - Winning bonus (extra pot split among winning voters)
     *
     * Requirements:
     *
     * - The allocation percentages do not exceed 100%
     */
    function setProducerPassWhiteRabbitTokensAllocationParameters(
        uint256 earlyStakingBonus,
        uint256 winningVoteBonus
    ) external onlyOwner {
        require(
            (earlyStakingBonus + winningVoteBonus) <= 100,
            "Total percentage exceeds 100"
        );
        uint256 basePercentage = 100 - earlyStakingBonus - winningVoteBonus;
        producerPassTokenBaseAllocationPerEpisode =
            (producerPassTokenAllocationPerEpisode * basePercentage) /
            100;
        producerPassTokenEarlyStakingBonusAllocationPerEpisode =
            (producerPassTokenAllocationPerEpisode * earlyStakingBonus) /
            100;
        producerPassTokenWinningBonusAllocationPerEpisode =
            (producerPassTokenAllocationPerEpisode * winningVoteBonus) /
            100;
    }

    /**
     * @dev Calculates the number of White Rabbit tokens the user would receive if the
     * provided `amount` of Producer Passes is staked for the given episode.
     *
     * Requirements:
     *
     * - The provided episode ID exists in our list of `episodes`
     */
    function getTokenAllocationForUserBeforeStaking(
        uint256 episodeId,
        uint256 amount
    ) public view returns (uint256) {
        ProducerPass memory pass = whiteRabbitProducerPass
            .getEpisodeToProducerPass(episodeId);
        uint256 maxSupply = pass.maxSupply;
        uint256 basePerPass = SafeMath.div(
            producerPassTokenBaseAllocationPerEpisode,
            maxSupply
        );

        // Get total vote count from every option of this episode for bonding curve calculation
        uint256[] memory votingOptionsForThisEpisode = _episodeOptions[
            episodeId
        ];
        uint256 totalVotesForEpisode = 0;
        for (uint256 i = 0; i < votingOptionsForThisEpisode.length; i++) {
            uint256 currentVotingOptionId = votingOptionsForThisEpisode[i];
            totalVotesForEpisode += _episodeVotesByOptionId[episodeId][
                currentVotingOptionId
            ];
        }

        // Below calculates number of tokens user will receive if staked
        // using a linear bonding curve where early stakers get more
        // Y = aX (where X = number of stakers, a = Slope, Y = tokens each staker receives)
        uint256 maxBonusY = 1000 *
            ((producerPassTokenEarlyStakingBonusAllocationPerEpisode * 2) /
                maxSupply);
        uint256 slope = SafeMath.div(maxBonusY, maxSupply);

        uint256 y1 = (slope * (maxSupply - totalVotesForEpisode));
        uint256 y2 = (slope * (maxSupply - totalVotesForEpisode - amount));
        uint256 earlyStakingBonus = (amount * (y1 + y2)) / 2;
        return basePerPass * amount + earlyStakingBonus / 1000;
    }

    function endVotingForEpisode(uint256 episodeId) external onlyOwner {
        uint256[] memory votingOptionsForThisEpisode = _episodeOptions[
            episodeId
        ];
        uint256 winningOptionId = 0;
        uint256 totalVotesForWinningOption = 0;

        for (uint256 i = 0; i < votingOptionsForThisEpisode.length; i++) {
            uint256 currentOptionId = votingOptionsForThisEpisode[i];
            uint256 votesForEpisode = _episodeVotesByOptionId[episodeId][
                currentOptionId
            ];

            if (votesForEpisode >= totalVotesForWinningOption) {
                winningOptionId = currentOptionId;
                totalVotesForWinningOption = votesForEpisode;
            }
        }

        setVotingEnabledForEpisode(episodeId, false);
        winningVoteOptionByEpisode[episodeId] = winningOptionId;
    }

    /**
     * @dev Manually sets the winning voting option for a given episode.
     * Only call this method to break a tie among voting options for an episode.
     *
     * Requirements:
     *
     * - This should only be called for ties
     */
    function endVotingForEpisodeOverride(
        uint256 episodeId,
        uint256 winningOptionId
    ) external onlyOwner {
        setVotingEnabledForEpisode(episodeId, false);
        winningVoteOptionByEpisode[episodeId] = winningOptionId;
    }

    /**
     * Token distribution for artists and team
     */

    /**
     * @dev Sends the artists their allocation of White Rabbit tokens after an episode is launched.
     *
     * Requirements:
     *
     * - The artists have not yet received their tokens for the given episode
     */
    function sendArtistTokensForEpisode(uint256 episodeId) external onlyOwner {
        require(
            !hasTransferredTokensToArtistForEpisode[episodeId],
            "Artist tokens distributed"
        );

        hasTransferredTokensToArtistForEpisode[episodeId] = true;

        IERC20(whiteRabbitTokenAddress).transfer(
            _artist1Address,
            artistTokenPerEpisodePerArtist
        );
        IERC20(whiteRabbitTokenAddress).transfer(
            _artist2Address,
            artistTokenPerEpisodePerArtist
        );
    }

    /**
     * @dev Transfers White Rabbit tokens to the team based on the `teamTokenAllocationPercentage`
     *
     * Requirements:
     *
     * - The tokens have not yet been distributed to the team
     */
    function withdrawTokensForTeamAllocation(address[] calldata teamAddresses)
        external
        onlyOwner
    {
        require(!teamTokenAllocationDistributed, "Team tokens distributed");

        uint256 teamBalancePerMember = (teamTokenAllocationPercentage *
            tokenInitialFixedSupply) / (100 * teamAddresses.length);
        for (uint256 i = 0; i < teamAddresses.length; i++) {
            IERC20(whiteRabbitTokenAddress).transfer(
                teamAddresses[i],
                teamBalancePerMember
            );
        }

        teamTokenAllocationDistributed = true;
    }

    /**
     * @dev Transfers White Rabbit tokens to the team based on the platform allocation
     *
     * Requirements:
     *
     * - All Episodes finished
     * - Voting completed
     */
    function withdrawPlatformReserveTokens() external onlyOwner {
        require(episodes.length == _numberOfEpisodes, "Show not ended");
        require(
            !votingEnabledForEpisode[_numberOfEpisodes],
            "Last episode still voting"
        );
        uint256 leftOverBalance = IERC20(whiteRabbitTokenAddress).balanceOf(
            address(this)
        );
        IERC20(whiteRabbitTokenAddress).transfer(msg.sender, leftOverBalance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

struct ProducerPass {
    uint256 price;
    uint256 episodeId;
    uint256 maxSupply;
    uint256 maxPerWallet;
    uint256 openMintTimestamp; // unix timestamp in seconds
    bytes32 merkleRoot;
}

contract WhiteRabbitProducerPass is ERC1155, ERC1155Supply, Ownable {
    using Strings for uint256;

    // The name of the token ("White Rabbit Producer Pass")
    string public name;
    // The token symbol ("WRPP")
    string public symbol;

    // The wallet addresses of the two artists creating the film
    address payable private artistAddress1;
    address payable private artistAddress2;
    // The wallet addresses of the three developers managing the film
    address payable private devAddress1;
    address payable private devAddress2;
    address payable private devAddress3;

    // The royalty percentages for the artists and developers
    uint256 private constant ARTIST_ROYALTY_PERCENTAGE = 60;
    uint256 private constant DEV_ROYALTY_PERCENTAGE = 40;

    // A mapping of the number of Producer Passes minted per episodeId per user
    // userPassesMintedPerTokenId[msg.sender][episodeId] => number of minted passes
    mapping(address => mapping(uint256 => uint256))
        private userPassesMintedPerTokenId;

    // A mapping from episodeId to its Producer Pass
    mapping(uint256 => ProducerPass) private episodeToProducerPass;

    // Event emitted when a Producer Pass is bought
    event ProducerPassBought(
        uint256 episodeId,
        address indexed account,
        uint256 amount
    );

    /**
     * @dev Initializes the contract by setting the name and the token symbol
     */
    constructor(string memory baseURI) ERC1155(baseURI) {
        name = "White Rabbit Producer Pass";
        symbol = "WRPP";
    }

    /**
     * @dev Checks if the provided Merkle Proof is valid for the given root hash.
     */
    function isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root)
        internal
        view
        returns (bool)
    {
        return
            MerkleProof.verify(
                merkleProof,
                root,
                keccak256(abi.encodePacked(msg.sender))
            );
    }

    /**
     * @dev Retrieves the Producer Pass for a given episode.
     */
    function getEpisodeToProducerPass(uint256 episodeId)
        external
        view
        returns (ProducerPass memory)
    {
        return episodeToProducerPass[episodeId];
    }

    /**
     * @dev Contracts the metadata URI for the Producer Pass of the given episodeId.
     *
     * Requirements:
     *
     * - The Producer Pass exists for the given episode
     */
    function uri(uint256 episodeId)
        public
        view
        override
        returns (string memory)
    {
        require(
            episodeToProducerPass[episodeId].episodeId != 0,
            "Invalid episode"
        );
        return
            string(
                abi.encodePacked(
                    super.uri(episodeId),
                    episodeId.toString(),
                    ".json"
                )
            );
    }

    /**
     * Owner-only methods
     */

    /**
     * @dev Sets the base URI for the Producer Pass metadata.
     */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }

    /**
     * @dev Sets the parameters on the Producer Pass struct for the given episode.
     */
    function setProducerPass(
        uint256 price,
        uint256 episodeId,
        uint256 maxSupply,
        uint256 maxPerWallet,
        uint256 openMintTimestamp,
        bytes32 merkleRoot
    ) external onlyOwner {
        episodeToProducerPass[episodeId] = ProducerPass(
            price,
            episodeId,
            maxSupply,
            maxPerWallet,
            openMintTimestamp,
            merkleRoot
        );
    }

    /**
     * @dev Withdraws the balance and distributes it to the artists and developers
     * based on the `ARTIST_ROYALTY_PERCENTAGE` and `DEV_ROYALTY_PERCENTAGE`.
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 artistBalance = (balance * ARTIST_ROYALTY_PERCENTAGE) / 100;
        uint256 balancePerArtist = artistBalance / 2;
        uint256 devBalance = (balance * DEV_ROYALTY_PERCENTAGE) / 100;
        uint256 balancePerDev = devBalance / 3;

        bool success;
        // Transfer artist balances
        (success, ) = artistAddress1.call{value: balancePerArtist}("");
        require(success, "Withdraw unsuccessful");

        (success, ) = artistAddress2.call{value: balancePerArtist}("");
        require(success, "Withdraw unsuccessful");

        // Transfer dev balances
        (success, ) = devAddress1.call{value: balancePerDev}("");
        require(success, "Withdraw unsuccessful");

        (success, ) = devAddress2.call{value: balancePerDev}("");
        require(success, "Withdraw unsuccessful");

        (success, ) = devAddress3.call{value: balancePerDev}("");
        require(success, "Withdraw unsuccessful");
    }

    /**
     * @dev Sets the royalty addresses for the two artists and three developers.
     */
    function setRoyaltyAddresses(
        address _a1,
        address _a2,
        address _d1,
        address _d2,
        address _d3
    ) external onlyOwner {
        artistAddress1 = payable(_a1);
        artistAddress2 = payable(_a2);
        devAddress1 = payable(_d1);
        devAddress2 = payable(_d2);
        devAddress3 = payable(_d3);
    }

    /**
     * @dev Creates a reserve of Producer Passes to set aside for gifting.
     *
     * Requirements:
     *
     * - There are enough Producer Passes to mint for the given episode
     * - The supply for the given episode does not exceed the maxSupply of the Producer Pass
     */
    function reserveProducerPassesForGifting(
        uint256 episodeId,
        uint256 amountEachAddress,
        address[] calldata addresses
    ) public onlyOwner {
        ProducerPass memory pass = episodeToProducerPass[episodeId];
        require(amountEachAddress > 0, "Amount cannot be 0");
        require(totalSupply(episodeId) < pass.maxSupply, "No passes to mint");
        require(
            totalSupply(episodeId) + amountEachAddress * addresses.length <=
                pass.maxSupply,
            "Cannot mint that many"
        );
        require(addresses.length > 0, "Need addresses");
        for (uint256 i = 0; i < addresses.length; i++) {
            address add = addresses[i];
            _mint(add, episodeId, amountEachAddress, "");
        }
    }

    /**
     * @dev Mints a set number of Producer Passes for a given episode.
     *
     * Emits a `ProducerPassBought` event indicating the Producer Pass was minted successfully.
     *
     * Requirements:
     *
     * - The current time is within the minting window for the given episode
     * - There are Producer Passes available to mint for the given episode
     * - The user is not trying to mint more than the maxSupply
     * - The user is not trying to mint more than the maxPerWallet
     * - The user has enough ETH for the transaction
     */
    function mintProducerPass(uint256 episodeId, uint256 amount)
        external
        payable
    {
        ProducerPass memory pass = episodeToProducerPass[episodeId];
        require(
            block.timestamp >= pass.openMintTimestamp,
            "Mint is not available"
        );
        require(totalSupply(episodeId) < pass.maxSupply, "Sold out");
        require(
            totalSupply(episodeId) + amount <= pass.maxSupply,
            "Cannot mint that many"
        );

        uint256 totalMintedPasses = userPassesMintedPerTokenId[msg.sender][
            episodeId
        ];
        require(
            totalMintedPasses + amount <= pass.maxPerWallet,
            "Exceeding maximum per wallet"
        );
        require(msg.value == pass.price * amount, "Not enough eth");

        userPassesMintedPerTokenId[msg.sender][episodeId] =
            totalMintedPasses +
            amount;
        _mint(msg.sender, episodeId, amount, "");

        emit ProducerPassBought(episodeId, msg.sender, amount);
    }

    /**
     * @dev For those on with early access (on the whitelist),
     * mints a set number of Producer Passes for a given episode.
     *
     * Emits a `ProducerPassBought` event indicating the Producer Pass was minted successfully.
     *
     * Requirements:
     *
     * - Provides a valid Merkle proof, indicating the user is on the whitelist
     * - There are Producer Passes available to mint for the given episode
     * - The user is not trying to mint more than the maxSupply
     * - The user is not trying to mint more than the maxPerWallet
     * - The user has enough ETH for the transaction
     */
    function earlyMintProducerPass(
        uint256 episodeId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable {
        ProducerPass memory pass = episodeToProducerPass[episodeId];
        require(
            isValidMerkleProof(merkleProof, pass.merkleRoot),
            "Not authorized to mint"
        );
        require(totalSupply(episodeId) < pass.maxSupply, "Sold out");
        require(
            totalSupply(episodeId) + amount <= pass.maxSupply,
            "Cannot mint that many"
        );
        uint256 totalMintedPasses = userPassesMintedPerTokenId[msg.sender][
            episodeId
        ];
        require(
            totalMintedPasses + amount <= pass.maxPerWallet,
            "Exceeding maximum per wallet"
        );
        require(msg.value == pass.price * amount, "Not enough eth");

        userPassesMintedPerTokenId[msg.sender][episodeId] =
            totalMintedPasses +
            amount;
        _mint(msg.sender, episodeId, amount, "");
        emit ProducerPassBought(episodeId, msg.sender, amount);
    }

    /**
     * @dev Retrieves the number of Producer Passes a user has minted by episodeId.
     */
    function userPassesMintedByEpisodeId(uint256 episodeId)
        external
        view
        returns (uint256)
    {
        return userPassesMintedPerTokenId[msg.sender][episodeId];
    }

    /**
     * @dev Boilerplate override for `_beforeTokenTransfer`
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}