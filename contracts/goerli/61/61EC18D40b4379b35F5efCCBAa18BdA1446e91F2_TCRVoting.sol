// SPDX-License-Identifier: MIT
// @authors: [@askmasteratwork]

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/StringUtils.sol";

/**
 *  @title TCRVoting
 *  This contract is a curated registry to include an NFT project to the registry.
 */

contract TCRVoting is Ownable, ReentrancyGuard {
    //////////////////////////////////////////////
    // events //
    //////////////////////////////////////////////

    /** @dev To be raised when a curator status updated.
     *  @param curator Wallet address of the Curator.
     *  @param status Status of the curator.
     *  @param executor is the executor of this event.
     */

    event CuratorStatusUpdated(
        address indexed curator,
        bool status,
        address executor
    );

    /** @dev To be raised when a curator status updated.
     *  @param contributor is the Creator of the registration.
     *  @param collectionName is the NFT collection name.
     *  @param submittedTime is submission time of NFT Project.
     *  @param submissionExpireTime is the Expiry time of registration.
     *  @param collection is the NFT collection address.
     *  @param nftInfo is the extra data of collection.
     *  @param registryId is the registry Id.
     */

    event NewRegistry(
        address indexed contributor,
        string collectionName,
        uint256 submittedTime,
        uint256 submissionExpireTime,
        uint256 submissionAmount,
        address collection,
        string nftInfo,
        bytes32 registryId
    );

    /** @dev To be raised when a registry is challenged.
     *  @param curator is user who challenged.
     *  @param registryId is the registry Id.
     *  @param timestamp is the time executed this event.
     */

    event ProjectChallenged(
        address indexed curator,
        bytes32 registryId,
        uint256 timestamp,
        uint256 challengeAmount
    );

    /** @dev To be raised when voted.
     *  @param curator is user who challenged.
     *  @param registryId is the registry Id.
     *  @param voteAmount is the amount put for the vote.
     *  @param isAccepted is the status of the user opinion.
     *  @param timestamp is the time executed this event.
     */

    event Voted(
        address indexed curator,
        bytes32 registryId,
        uint256 voteAmount,
        bool isAccepted,
        uint256 timestamp
    );

    /** @dev To be raised when registry status changed.
     *  @param contributor is user who challenged.
     *  @param registryId is the registry Id.
     *  @param isAccepted is the status of the user opinion.
     *  @param timestamp is the time executed this event.
     */

    event UpdatedRegistryStatus(
        address indexed contributor,
        bytes32 registryId,
        bool isAccepted,
        uint256 timestamp
    );

    /** @dev To be raised when user claimed rewards.
     *  @param registryId is the registry Id.
     *  @param claimedBy is the wallet address of the claimed.
     *  @param amount is the amount that is being claimed.
     *  @param claimedOn is the time executed this event.
     */

    event RewardsClaimed(
        bytes32 registryId,
        address claimedBy,
        uint256 amount,
        uint256 claimedOn
    );

    /** @dev To be raised when user claimed rewards.
     *  @param registryId is the registry Id.
     *  @param stakedBy is the wallet address of the staked.
     *  @param amount is the amount that is being claimed.
     *  @param claimedOn is the time executed this event.
     */
    event StakeClaimed(
        bytes32 registryId,
        address stakedBy,
        uint256 amount,
        uint256 claimedOn
    );

    constructor(address tokenAddress) {
        require(tokenAddress != address(0), "Initiate:: Invalid tokenAddress");
        TCRToken = tokenAddress;
    }

    //////////////////////////////////////////////
    // structs //
    //////////////////////////////////////////////

    /** @dev Registry: Struct for storing information about NFT registries
        var contributor - is the user who request to add to the registry
        collection - the NFT contract that needs to be added to registry
        challengedBy - is the user who challenged the registry
        data - this has the JSON data of the NFT project
        popularity - is the popularly of the project
        isAccepted - flag to check if the final outcome of the registry
        isFinalised - flag to check if the decision made on the registry or not
        isChallenged - flag to check if the registry is challenged or not
        submissionInfo - finance & validities of the registy
        votes - a nested struct that has votes data
        rewards - a nested struct that has rewards data
    */

    struct Registry {
        string collectionName;
        address contributor;
        address collection;
        address challengedBy;
        string data;
        uint256 popularity;
        bool isAccepted;
        bool isFinalised;
        bool isChallenged;
        SubmissionInfo submissionInfo;
        Votes votes;
        Rewards rewards;
    }

    /** @dev SubmissionInfo: Struct for storing timelines & durations
        submittedTime - is the time when the registry is being created
        submissionExpireTime - is the time when registry submission expires
        challengeExpireTime - is the time when the registry challenge expires
        submissionAmount - is the amount that is submitted to create registry
        challengeAmount - is the amount that is used to challenge the registry
    */

    struct SubmissionInfo {
        uint256 submittedTime;
        uint256 submissionExpireTime;
        uint256 challengeExpireTime;
        uint256 submissionAmount;
        uint256 challengeAmount;
    }

    /** @dev Votes: Struct for storing votes and voting amounts
        totalUpVotesAmount - is the total amount that is used to upvote
        totalDownVotesAmount - is the total amount that is used to downvote
        upVotedCurators - is the array of user who upvoted
        upVotedCuratorsAmount - is the mapping of users that upvoted & thier amounts
        downVotedCurators - is the array of user who downvoted
        downVotedCuratorsAmount - is the mapping of users that downvoted & thier amounts
    */

    struct Votes {
        uint256 totalUpVotesAmount;
        uint256 totalDownVotesAmount;
        address[] upVotedCurators;
        mapping(address => uint256) upVotedCuratorsAmount;
        address[] downVotedCurators;
        mapping(address => uint256) downVotedCuratorsAmount;
    }

    /** @dev Rewards: Struct for storing rewards amount
        rewards - is the mapping of users & amount
        stake - is the mapping of the users & staked amount
        isClaimedReward - is that flag to check if the user claimed the reward or not
        isClaimedStake - is that flag to check if the user claimed the stake or not
    */

    struct Rewards {
        mapping(address => uint256) rewards;
        mapping(address => uint256) stake;
        mapping(address => bool) isClaimedReward;
        mapping(address => bool) isClaimedStake;
    }

    //////////////////////////////////////////////
    // mappings //
    //////////////////////////////////////////////

    /// @dev Mapping of registries
    mapping(bytes32 => Registry) private registries;

    /// @dev Mapping of Curators and Status
    mapping(address => bool) public curators;

    /// @dev Mapping of Contributor and List of Proposed Registries
    mapping(address => bytes32[]) private contributorProposedRegistries;

    /// @dev Mapping of Curator and List of Voted Registries
    mapping(address => bytes32[]) private curatorVotedRegistries;

    /// @dev Mapping of Curator, Registry & Status
    mapping(address => mapping(bytes32 => bool)) public curatorVoteInfo;

    /// @dev Mapping of Curator and List of Challenged Registries
    mapping(address => bytes32[]) private curatorChallengedRegistries;

    //////////////////////////////////////////////
    // variables //
    //////////////////////////////////////////////

    /// @dev List of Registries
    bytes32[] public registryList;

    /// @dev List of Accepted Registries
    bytes32[] public acceptedRegistry;

    /// @dev List of Challenged Registries
    bytes32[] public allChallengeRegistries;

    /// @dev Rewards that will be paid to successful submission
    uint256 public successSubmissionRewards = 100 ether;

    /// @dev Duration of the Registration Period from the Submission to the Registry
    uint256 public registrationPeriod = 600; // 10 minutes

    /// @dev Duration of the Challenge Period from the Expiry of the Registration Period
    uint256 public challengePeriod = 600; // 10 minutes

    /// @dev TCR token that is used to accept as payment token for registration, vote & etc..
    address public TCRToken;

    //////////////////////////////////////////////
    // admin //
    //////////////////////////////////////////////

    /** @dev Allow or remove Curators.
     *  @param curator is the Wallet address of the curator.
     *  @param status is the status of the curator.
     */

    // Update the Curator status
    function updateCuratorStatus(address curator, bool status)
        public
        onlyOwner
    {
        require(
            curators[curator] != status,
            "UpdateCuratorStatus:: No change in status"
        );
        curators[curator] = status;
        emit CuratorStatusUpdated(curator, status, msg.sender);
    }

    /** @dev This function is called by owner when the up votes and down votes are equal.
     *  @param registryId is the registration id of the registry.
     *  @param isAccepted is the status of the registry.
     */

    function finaliseByCommunity(bytes32 registryId, bool isAccepted)
        external
        nonReentrant
        onlyOwner
    {
        require(
            isProjectExist(registryId),
            "FinaliseByCommunity:: No Registry Exist"
        );
        require(
            registries[registryId].isChallenged,
            "FinaliseByCommunity:: Is Challenge Opened?"
        );
        require(
            block.timestamp <
                registries[registryId].submissionInfo.challengeExpireTime,
            "FinaliseByCommunity:: Challenge not closed yet"
        );
        require(
            !registries[registryId].isAccepted,
            "FinaliseByCommunity:: Can not Challenge already Accepted project"
        );

        uint256 totalUpVoteAmount = registries[registryId]
            .votes
            .totalUpVotesAmount;
        uint256 totalDownVoteAmount = registries[registryId]
            .votes
            .totalDownVotesAmount;

        require(
            totalUpVoteAmount == totalDownVoteAmount,
            "FinaliseByCommunity:: Can only finalise if the votes are equal"
        );

        registries[registryId].isFinalised = true;

        if (isAccepted) {
            includeToRegistry(registryId);
        } else {
            excludeToRegistry(registryId);
        }
    }

    event RegistrationPeriodUpdated(
        uint256 oldPeriod,
        uint256 newPeriod,
        uint256 timestamp,
        address caller
    );

    function updateRegistrationPeriod(uint256 newPeriod) external onlyOwner {
        require(
            newPeriod > 0,
            "UpdateRegistrationPeriod:: newPeriod can not be zero"
        );
        emit RegistrationPeriodUpdated(
            registrationPeriod,
            newPeriod,
            block.timestamp,
            msg.sender
        );
        registrationPeriod = newPeriod;
    }

    event ChallengePeriodUpdated(
        uint256 oldPeriod,
        uint256 newPeriod,
        uint256 timestamp,
        address caller
    );

    function updateChallengePeriod(uint256 newPeriod) external onlyOwner {
        require(
            newPeriod > 0,
            "UpdateChallengePeriod:: newPeriod can not be zero"
        );
        emit ChallengePeriodUpdated(
            challengePeriod,
            newPeriod,
            block.timestamp,
            msg.sender
        );
        challengePeriod = newPeriod;
    }

    //////////////////////////////////////////////
    // view //
    //////////////////////////////////////////////

    /** @dev This function returns the count registries.
     *  @return The count of all registries.
     */
    function getAllRegistriesCount() public view returns (uint256) {
        return registryList.length;
    }

    /** @dev This function returns count of accepted registrations.
     *  @return The count of all registries.
     */
    function getAcceptedRegistriesCount() public view returns (uint256) {
        return acceptedRegistry.length;
    }

    /** @dev This function returns count of active challenges & registerIds.
     *  @return The count of active challenges.
     *  @return The list of active challenges registerIds.
     */
    function getActiveChallenges()
        public
        view
        returns (uint256, bytes32[] memory)
    {
        uint256 noOfChallenges = 0;
        for (uint256 i = 0; i < allChallengeRegistries.length; i++) {
            if (
                registries[allChallengeRegistries[i]].isChallenged == true &&
                registries[allChallengeRegistries[i]].isFinalised == false
            ) {
                noOfChallenges = noOfChallenges + 1;
            }
        }
        bytes32[] memory challenges = new bytes32[](noOfChallenges);
        for (uint256 i = 0; i < allChallengeRegistries.length; i++) {
            if (
                registries[allChallengeRegistries[i]].isChallenged == true &&
                registries[allChallengeRegistries[i]].isFinalised == false
            ) {
                challenges[i] = allChallengeRegistries[i];
            }
        }
        return (noOfChallenges, challenges);
    }

    /** @dev This function returns registery base info.
     *  @param registryId is the id of the registry which user wants to retrive
     *  @return contributor, collection & challengedBy address in array.
     *  @return the ipfs hash of data.
     *  @return the status of isAccepted, isFinalised, isChallenged.
     */
    function getProjectBaseInfo(bytes32 registryId)
        public
        view
        returns (
            address[3] memory,
            string memory,
            uint256,
            bool[3] memory,
            string memory
        )
    {
        return (
            [
                registries[registryId].contributor,
                registries[registryId].collection,
                registries[registryId].challengedBy
            ],
            registries[registryId].data,
            registries[registryId].popularity,
            [
                registries[registryId].isAccepted,
                registries[registryId].isFinalised,
                registries[registryId].isChallenged
            ],
            registries[registryId].collectionName
        );
    }

    /** @dev This function returns registery base info.
     *  @param registryId is the id of the registry which user wants to retrive
     *  @return contributor of the project.
     *  @return the ipfs hash of data.
     *  @return the status of isAccepted, isFinalised, isChallenged.
     *  @return totalUpVotesAmount & totalDownVotesAmount.
     */
    function getProjectInfo(bytes32 registryId)
        public
        view
        returns (
            address,
            string memory,
            bool[3] memory,
            uint256[2] memory,
            string memory
        )
    {
        return (
            registries[registryId].contributor,
            registries[registryId].data,
            [
                registries[registryId].isAccepted,
                registries[registryId].isFinalised,
                registries[registryId].isChallenged
            ],
            [
                registries[registryId].votes.totalUpVotesAmount,
                registries[registryId].votes.totalDownVotesAmount
            ],
            registries[registryId].collectionName
        );
    }

    /** @dev This function returns registery Finance & Validities info.
     *  @param registryId is the id of the registry which user wants to retrive
     *  @return submittedTime, submissionExpireTime, challengeExpireTime, submissionAmount and challengeAmount.
     *  @return upVotedCurators & downVotedCurators of registry Id.
     */
    function getProjectFinAndValInfo(bytes32 registryId)
        public
        view
        returns (
            uint256[5] memory,
            address[] memory,
            address[] memory
        )
    {
        return (
            [
                registries[registryId].submissionInfo.submittedTime,
                registries[registryId].submissionInfo.submissionExpireTime,
                registries[registryId].submissionInfo.challengeExpireTime,
                registries[registryId].submissionInfo.submissionAmount,
                registries[registryId].submissionInfo.challengeAmount
            ],
            registries[registryId].votes.upVotedCurators,
            registries[registryId].votes.downVotedCurators
        );
    }

    /** @dev This function returns vote info.
     *  @param registryId is the id of the registry which user wants to retrive
     *  @return total up votes amount.
     *  @return total down votes amount.
     *  @return list of up voted curators.
     *  @return list of down voted curators.
     */
    function getProjectVoteInfo(bytes32 registryId)
        public
        view
        returns (
            uint256,
            uint256,
            address[] memory,
            address[] memory
        )
    {
        return (
            registries[registryId].votes.totalUpVotesAmount,
            registries[registryId].votes.totalDownVotesAmount,
            registries[registryId].votes.upVotedCurators,
            registries[registryId].votes.downVotedCurators
        );
    }

    /** @dev This function returns Keccak-256 hash.
     *  @param collection is the collection address
     *  @return Keccak-256 hash of collection.
     */
    function getkeccak256(address collection) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(collection));
    }

    /** @dev This function returns if the registry exist or not.
     *  @param registryId is the registry id
     *  @return true or false of the existence of the registry.
     */
    function isProjectExist(bytes32 registryId) public view returns (bool) {
        if (registries[registryId].collection == address(0)) {
            return false;
        } else {
            return true;
        }
    }

    /** @dev This function returns if the registry is in submission period or not.
     *  @param registryId is the registry id
     *  @return if the given registryId is in submission period or not.
     */
    function isInSubmissionPeriod(bytes32 registryId)
        public
        view
        returns (bool)
    {
        return
            block.timestamp >
            registries[registryId].submissionInfo.submissionExpireTime;
    }

    /** @dev This function returns if the registry is in submission period or not.
     *  @param registryId is the registry id
     *  @return if the given registryId is in submission period or not.
     */
    function isInSubmissionPeriodForCurator(bytes32 registryId)
        public
        view
        returns (bool)
    {
        return
            block.timestamp <
            registries[registryId].submissionInfo.submissionExpireTime;
    }

    /** @dev This function returns if the registry is in challenge period or not.
     *  @param registryId is the registry id
     *  @return if the given registryId is in challenge period or not.
     */
    function isInChallengePeriod(bytes32 registryId)
        public
        view
        returns (bool)
    {
        return
            block.timestamp <
            registries[registryId].submissionInfo.challengeExpireTime;
    }

    /** @dev This function returns if a specific curator is voted for a registry or not.
     *  @param registryId is the registry id
     *  @param curator is the address of the curator
     *  @return true or false.
     */
    function isCuratorVotedForRegistry(bytes32 registryId, address curator)
        public
        view
        returns (bool)
    {
        return curatorVoteInfo[curator][registryId];
    }

    /** @dev This function returns if a specific wallet is a curator or not.
     *  @param curator is the address of the curator
     *  @return true or false.
     */
    function isCurator(address curator) public view returns (bool) {
        return curators[curator];
    }

    /** @dev This function returns list of registries from a contributor.
     *  @param contributor is the address of the contributor
     *  @return the list of submitted nft projects.
     */
    function getcontributorProposedRegistriesList(address contributor)
        public
        view
        returns (bytes32[] memory)
    {
        return contributorProposedRegistries[contributor];
    }

    /** @dev This function returns list of registries from a courator.
     *  @param courator is the address of the courator
     *  @return the list of voted nft projects.
     */
    function getcuratorVotedRegistriesList(address courator)
        public
        view
        returns (bytes32[] memory)
    {
        return curatorVotedRegistries[courator];
    }

    /** @dev This function returns list of registries challenged by a courator.
     *  @param courator is the address of the courator
     *  @return the list of challenged nft projects.
     */
    function getcuratorChallengedRegistriesList(address courator)
        public
        view
        returns (bytes32[] memory)
    {
        return curatorChallengedRegistries[courator];
    }

    function getUpVotesCount(bytes32 registryId)
        public
        view
        returns (uint256, uint256)
    {
        return (
            registries[registryId].votes.totalUpVotesAmount,
            registries[registryId].votes.totalDownVotesAmount
        );
    }

    function getProjectPopularity(bytes32 registryId)
        public
        view
        returns (uint256)
    {
        uint256 whole = registries[registryId].votes.totalUpVotesAmount +
            registries[registryId].votes.totalDownVotesAmount;
        uint256 upVotes = registries[registryId].votes.totalUpVotesAmount;
        return (upVotes * 100) / whole;
    }

    function registryStatus(bytes32 registryId)
        public
        view
        returns (
            bool,
            bool,
            bool
        )
    {
        return (
            registries[registryId].isAccepted,
            registries[registryId].isFinalised,
            registries[registryId].isChallenged
        );
    }

    function simulateRewardStake(bytes32 registryId, address wallet)
        public
        view
        returns (uint256, uint256)
    {
        return (
            registries[registryId].rewards.stake[wallet],
            registries[registryId].rewards.rewards[wallet]
        );
    }

    function getUserVotedAmount(bytes32 registryId, address wallet)
        public
        view
        returns (uint256, uint256)
    {
        return (
            registries[registryId].votes.upVotedCuratorsAmount[wallet],
            registries[registryId].votes.downVotedCuratorsAmount[wallet]
        );
    }

    //////////////////////////////////////////////
    // external //
    //////////////////////////////////////////////

    /** @dev This function submit the registration to join in registry.
     *  @param collection is the address of the NFT collection
     *  @param data ipfs hash of the data
     *  @param submissionAmount is the amount that contributor want to submit during the submission period
     */
    function submitRegistration(
        address collection,
        string memory collectionName,
        string memory data,
        uint256 submissionAmount
    ) external nonReentrant {
        require(collection != address(0), "SubmitProject:: Invalid collection");
        require(StringUtils.strlen(data) > 0, "SubmitProject:: Invalid data");
        require(
            StringUtils.strlen(collectionName) > 0,
            "SubmitProject:: Invalid collectionName"
        );
        bytes32 _registryId = getkeccak256(collection);
        require(
            !isProjectExist(_registryId),
            "SubmitProject:: Duplicate request"
        );
        address _contributor = msg.sender;
        TransferHelper.safeTransferFrom(
            TCRToken,
            _contributor,
            address(this),
            submissionAmount
        );
        registryList.push(_registryId);
        registries[_registryId].collectionName = collectionName;
        registries[_registryId].contributor = _contributor;
        registries[_registryId].collection = collection;
        registries[_registryId].data = data;
        registries[_registryId].submissionInfo.submittedTime = block.timestamp;
        registries[_registryId].submissionInfo.submissionExpireTime =
            block.timestamp +
            registrationPeriod;
        registries[_registryId]
            .submissionInfo
            .submissionAmount = submissionAmount;
        registries[_registryId].votes.totalUpVotesAmount = submissionAmount;
        registries[_registryId].votes.upVotedCurators.push(_contributor);
        registries[_registryId].votes.upVotedCuratorsAmount[
            _contributor
        ] = submissionAmount;
        contributorProposedRegistries[_contributor].push(_registryId);

        emit NewRegistry(
            _contributor,
            collectionName,
            block.timestamp,
            block.timestamp + registrationPeriod,
            submissionAmount,
            collection,
            data,
            _registryId
        );
    }

    /** @dev This function allows contributor or anyone to approve the registration
     *  @notice This can be called only after submission period expires and no challenge initiated
     *  @param registryId is the register id of the submission
     */
    function acceptRegistration(bytes32 registryId) external nonReentrant {
        require(
            isProjectExist(registryId),
            "AcceptRegistration:: No Registry Exist"
        );
        require(
            !registries[registryId].isChallenged,
            "AccepteRegistration:: Can not accept Challenged Registry"
        );
        require(
            isInSubmissionPeriod(registryId),
            "AccepteRegistration:: To Early to finalise"
        );
        uint256 rewardsCalculation = successSubmissionRewards +
            registries[registryId].submissionInfo.submissionAmount;
        TransferHelper.safeTransfer(TCRToken, msg.sender, rewardsCalculation);

        registries[registryId].isFinalised = true;
        registries[registryId].isAccepted = true;

        registries[registryId].rewards.stake[msg.sender] = 0;
        registries[registryId].rewards.isClaimedStake[msg.sender] = true;

        registries[registryId].rewards.rewards[msg.sender] = 0;
        registries[registryId].rewards.isClaimedReward[msg.sender] = true;

        acceptedRegistry.push(registryId);

        emit UpdatedRegistryStatus(
            registries[registryId].contributor,
            registryId,
            true,
            block.timestamp
        );
    }

    /** @dev This function allows curator to challenge the registry
     *  @param registryId is the register id of the submission
     *  @param challengeAmount is the amount that curator wants to challenge
     */
    function challengeProject(bytes32 registryId, uint256 challengeAmount)
        external
        nonReentrant
    {
        address curator = msg.sender;
        require(isProjectExist(registryId), "ChallengeProject:: Not found");
        require(
            isInSubmissionPeriodForCurator(registryId),
            "ChallengeProject:: Not in challenge window"
        );
        require(
            isCurator(msg.sender),
            "ChallengeProject:: Only Curators can vote"
        );
        require(
            !registries[registryId].isAccepted,
            "ChallengeProject:: Can not Challenge already Accepted project"
        );
        require(
            !registries[registryId].isChallenged,
            "ChallengeProject:: Already Challenged by Curator"
        );
        require(
            registries[registryId].contributor != curator,
            "ChallengeProject:: You can not challenge yourself"
        );
        require(
            challengeAmount >=
                registries[registryId].submissionInfo.submissionAmount,
            "ChallengeProject:; ChallengeAmount can not be less than submission amount"
        );

        TransferHelper.safeTransferFrom(
            TCRToken,
            curator,
            address(this),
            challengeAmount
        );
        registries[registryId].submissionInfo.challengeExpireTime =
            block.timestamp +
            challengePeriod;
        registries[registryId].votes.totalDownVotesAmount = challengeAmount;
        registries[registryId].submissionInfo.challengeAmount = challengeAmount;
        registries[registryId].votes.downVotedCurators.push(curator);
        registries[registryId].votes.downVotedCuratorsAmount[
            curator
        ] = challengeAmount;
        registries[registryId].rewards.stake[curator] = challengeAmount;
        registries[registryId].challengedBy = curator;
        registries[registryId].isChallenged = true;
        allChallengeRegistries.push(registryId);
        curatorVoteInfo[curator][registryId] = true;
        curatorChallengedRegistries[curator].push(registryId);
        emit ProjectChallenged(
            curator,
            registryId,
            block.timestamp,
            challengeAmount
        );
    }

    /** @dev This function allows curators to vote for a registry
     *  @param registryId is the register id of the submission
     *  @param isAccepted is the opinion of the curator to vote, true to include and false to exclude
     *  @param voteAmount is the amount that curator wants to vote
     */
    function vote(
        bytes32 registryId,
        bool isAccepted,
        uint256 voteAmount
    ) public nonReentrant {
        require(isProjectExist(registryId), "Vote:: No Registry Exist");

        require(
            registries[registryId].isChallenged,
            "Vote:: Is Challenge Opened?"
        );
        require(isCurator(msg.sender), "Vote:: Only Curators can vote");
        require(
            isInChallengePeriod(registryId),
            "Vote:: Not in challenge window"
        );
        require(
            !registries[registryId].isAccepted,
            "Vote:: Can not Challenge already Accepted project"
        );
        require(
            !isCuratorVotedForRegistry(registryId, msg.sender),
            "Vote:: Already Voted"
        );

        address _curator = msg.sender;

        TransferHelper.safeTransferFrom(
            TCRToken,
            _curator,
            address(this),
            voteAmount
        );
        if (isAccepted == true) {
            registries[registryId].votes.upVotedCurators.push(_curator);
            registries[registryId].votes.upVotedCuratorsAmount[
                _curator
            ] = voteAmount;
            registries[registryId].rewards.stake[_curator] = voteAmount;
            registries[registryId].votes.totalUpVotesAmount =
                registries[registryId].votes.totalUpVotesAmount +
                voteAmount;
        } else {
            registries[registryId].votes.downVotedCurators.push(_curator);
            registries[registryId].votes.downVotedCuratorsAmount[
                _curator
            ] = voteAmount;
            registries[registryId].rewards.stake[_curator] = voteAmount;
            registries[registryId].votes.totalDownVotesAmount =
                registries[registryId].votes.totalDownVotesAmount +
                voteAmount;
        }

        curatorVoteInfo[_curator][registryId] = true;
        curatorVotedRegistries[_curator].push(registryId);

        emit Voted(
            _curator,
            registryId,
            voteAmount,
            isAccepted,
            block.timestamp
        );
    }

    /** @dev This function allows any one to finalise the registry
     *  @notice This can be called only if the challange period is passed, this will also determine include or exclude to registry
     *  @param registryId is the register id of the submission
     */
    function finalise(bytes32 registryId) external nonReentrant {
        require(isProjectExist(registryId), "Finalise:: No Registry Exist");

        require(
            !registries[registryId].isAccepted,
            "Finalise:: Can not Challenge already Accepted project"
        );

        if (!registries[registryId].isChallenged) {
            require(
                block.timestamp >
                    registries[registryId].submissionInfo.submissionExpireTime,
                "Finalise:: Challenge not closed yet"
            );
        }

        if (registries[registryId].isChallenged) {
            require(
                block.timestamp >
                    registries[registryId].submissionInfo.challengeExpireTime,
                "Finalise:: Challenge not closed yet"
            );
        }

        uint256 totalUpVoteAmount = registries[registryId]
            .votes
            .totalUpVotesAmount;
        uint256 totalDownVoteAmount = registries[registryId]
            .votes
            .totalDownVotesAmount;

        registries[registryId].isFinalised = true;

        if (totalUpVoteAmount < totalDownVoteAmount) {
            excludeToRegistry(registryId);
        } else if (totalUpVoteAmount > totalDownVoteAmount) {
            includeToRegistry(registryId);
        } else {
            revert(
                "Equal number of votes, Community to decide based on reputation, quality, or merit of the Project"
            );
        }
    }

    /** @dev This function allows users to claim rewards based on inclusion or exclustion of the project
     *  @notice This can be called only after the project is finalised
     *  @param registryId is the register id of the submission
     */
    function claimRewards(bytes32 registryId) external nonReentrant {
        require(
            registries[registryId].isFinalised,
            "ClaimRewards:: Registry not finalised"
        );
        uint256 rewards = registries[registryId].rewards.rewards[msg.sender];
        if (rewards > 0) {
            registries[registryId].rewards.rewards[msg.sender] = 0;
            registries[registryId].rewards.isClaimedReward[msg.sender] = true;
            TransferHelper.safeTransfer(TCRToken, msg.sender, rewards);
            emit RewardsClaimed(
                registryId,
                msg.sender,
                rewards,
                block.timestamp
            );
        } else {
            revert("ClaimRewards:: Invalid Amount");
        }
    }

    /** @dev This function allows users to claim user stake that put on registry
     *  @notice This can be called only after the project is finalised
     *  @param registryId is the register id of the submission
     */
    function withdrawStake(bytes32 registryId) external nonReentrant {
        require(
            registries[registryId].isFinalised,
            "WithdrawStake:: Registry not finalised"
        );
        uint256 stake = registries[registryId].rewards.stake[msg.sender];
        if (stake > 0) {
            registries[registryId].rewards.stake[msg.sender] = 0;
            registries[registryId].rewards.isClaimedStake[msg.sender] = true;
            TransferHelper.safeTransfer(TCRToken, msg.sender, stake);
            emit StakeClaimed(registryId, msg.sender, stake, block.timestamp);
        } else {
            revert("WithdrawStake:: Invalid Amount");
        }
    }

    //////////////////////////////////////////////
    // internal //
    //////////////////////////////////////////////

    function includeToRegistry(bytes32 registryId) internal {
        if (registries[registryId].isChallenged) {
            uint256 submissionAmount = registries[registryId]
                .submissionInfo
                .challengeAmount;
            uint256 noOfCurators = registries[registryId]
                .votes
                .upVotedCurators
                .length;
            uint256 distribute = submissionAmount / noOfCurators;
            for (uint256 i = 0; i < noOfCurators; i++) {
                registries[registryId].rewards.rewards[
                    registries[registryId].votes.upVotedCurators[i]
                ] = distribute;
            }
        }
        registries[registryId].isAccepted = true;
        acceptedRegistry.push(registryId);
        emit UpdatedRegistryStatus(
            registries[registryId].contributor,
            registryId,
            true,
            block.timestamp
        );
    }

    function excludeToRegistry(bytes32 registryId) internal {
        uint256 submissionAmount = registries[registryId]
            .submissionInfo
            .submissionAmount;
        uint256 noOfCurators = registries[registryId]
            .votes
            .downVotedCurators
            .length;
        uint256 distribute = submissionAmount / noOfCurators;
        for (uint256 i = 0; i < noOfCurators; i++) {
            registries[registryId].rewards.rewards[
                registries[registryId].votes.downVotedCurators[i]
            ] = distribute;
        }
        registries[registryId].isAccepted = false;
        emit UpdatedRegistryStatus(
            registries[registryId].contributor,
            registryId,
            false,
            block.timestamp
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.4;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint256) {
        uint256 len;
        uint256 i = 0;
        uint256 bytelength = bytes(s).length;
        for (len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if (b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}