// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./IJetStaking.sol";
// import "./Staking/IStaking.sol";
import "./Pausable.sol";
// import "./JetStaking.sol";
// import "hardhat/console.sol";


/// @title A Voting contract for projects
/// @author hanzel.anchia
/// @notice Contract for voting projects using fungible tokens
/// @dev It uses an extention of ERC20 to represent the vote tokens, this contract has dependencies on JetStaking contract
contract VotingV2 is Initializable, Pausable {
    // using SafeERC20Upgradeable for JetStaking;

    IJetStaking public jetStaking;
    uint256 public decimals; //1e18 decimals
    
    struct Kpi {
        uint256 percentageOfReward;
        uint256 obtainedPercentage;
        bool previouslyUpdated;
    }

    struct Project {
        string name;
        address ownerWallet;
        uint256 requestedWeightedBudget;
        uint256 numberOfVotes;
        uint256 seasonId;
        uint256 numberOfKpis; // from 1 to any
        mapping(uint256 => Kpi) kpis; //[0x1=> 12, 0x2=>33]
        mapping(address => uint256) votesPerUser; //[0x1=> 12, 0x2=>33]
        address[] usersVoted; // [0x1,0x2]
        uint256[] grantParts; // [0=>80%(prepayment), 1=> 10%. 2=> 10%]
        uint256[] grantPartDates; // [0=>prepayment, 1=> 01/02/2022. 01/05/2022]
    }

    struct Coefficient {
        uint256 operationalBudget;
        uint256 marketingBudget;
        uint256 longTermIncentives;
        uint256 protocolSpecificIncentives;
        uint256 liquity; // For each 3 months
        uint256 creationDate;
    }

    struct Season {
        uint256 totalVotes;
        uint256 totalAllocation; // It changes for each eason, not stored in a struct in JetStaking
        uint256 rewardPercentage; // NEW - % of the allocation for the payment of rewards
        uint256 grantPool; // Available for projects: totalAllocation - (totalAllocation * rewardPercentage) 
        uint256 rewardPool; // Available for projects: totalAllocation * rewardPercentage 
        uint256[] projectsInSeason; // with the length we can get all the available projects
        // uint256 totalAllocatedBudget; // NEW - PROJECTS THAT SUCCEEDED better to calculate it 
        // uint256 allocationEfficiency; // NEW - totalAllocatedBudget/totalAllocation
        uint256 conditionalRewardPercentage;
        uint256 unconditionalRewardPercentage;
        uint256 coefficientInUse; // refers to the version number of the coefficient
    }

    struct ProjectResult {
        uint256 projectId;
        uint256 neededPercentage;
        uint256 neededNumberOfVotes;
        uint256 obtainedNumberOfVotes;
        bool reachedGoal;
    }
    
    uint256 public projectCounterId;
    uint256 public coefficientCounterId;
    uint256[] public seasonsVotedIds; // All the voted seasons
    mapping(uint256 => Season) public seasonsVoted; // Information of the voted seasons
    mapping(uint256 => Project) public projects; // Available projects
    mapping(uint256 => Coefficient) public coefficients;

    event ProjectPublished(uint256 indexed seasonId, uint256 indexed projectId, address publisher, uint256 time);
    event VoteEmitted(uint256 indexed seasonId, uint256 indexed projectId, address indexed voter, uint256 numberOfVotes);
    event KpiUpdated(uint256 indexed projectId, address indexed publisher, uint256 kpiNumber, uint256 value);
    event SeasonAllocationChanged(uint256 indexed seasonId, address indexed publisher, uint256 oldAllocation, uint256 newAllocation, uint256 time);
    event SeasonRewardDistributionChanged(
        uint256 indexed seasonId, 
        address indexed publisher, 
        uint256 oldConditional, 
        uint256 newConditional, 
        uint256 oldUnconditional, 
        uint256 newUnconditional,
        uint256 time
    );

    function initialize(address _jetStaking) public 
    initializer {
        jetStaking = IJetStaking(_jetStaking);
        __Ownable_init(); // Sets deployer address as owner
        __Pausable_init();
        decimals = 1 ether; // 1e18 decimals
        projectCounterId = 1;
        _setInitialCoefficients();
    }

    function getNumberFixed() public pure returns (uint256){
        return 987654321;
    } 

    /// @notice To be called by the curators. Requires the project information and publishes it to the current season.
    /// @dev The numeric values come formatted to 1E18.
    /// @param _name The project name
    /// @param _ownerWallet Address of the owner
    /// @param _grantStructure uint256 operationalBudget=0  marketingBudget = 1; longTermIncentives = 2; 
    /// protocolSpecificIncentives = 3; liquity = 4; numberOfMonths = 5;
    /// @param _grantParts Percentage in which the parts will be distributed. 
    /// @param _grantPartDates The different dates in which the payments should be done. The first one is the prepayment. 
    /// example [prepaymentDate, milestone1Date, milestone2Date]
    function publishProject(
        string memory _name,
        address _ownerWallet,
        uint256[6] calldata _grantStructure,
        uint256[] calldata _grantParts,
        uint256[] calldata _grantPartDates
    ) public onlyCurator
    returns (uint256 projectId) {
        _validateProjectParams(_name, _ownerWallet, _grantParts, _grantPartDates);
        uint256 seasonId = getCurrentSeasonId();
        validateAplicationVotingPeriod(seasonId);
        Season storage season = seasonsVoted[seasonId];
        if(season.projectsInSeason.length == 0) {
            seasonsVotedIds.push(seasonId); // Saving available options
        }
        Project storage project = projects[projectCounterId];
        project.name = _name;
        project.ownerWallet = _ownerWallet;
        project.requestedWeightedBudget = _getProjectRequestedWeightedBudget(_grantStructure, seasonId);
        project.numberOfKpis = _grantParts.length - 1; // not counting the prepayment
        project.grantParts = _grantParts; 
        project.grantPartDates = _grantPartDates;
        project.seasonId = seasonId;
        _setKpiPercentages(project, _grantParts);
        season.projectsInSeason.push(projectCounterId);
        emit ProjectPublished(seasonId, projectCounterId, msg.sender, block.timestamp);
        projectCounterId++;
        projectId = projectCounterId;
    }

    /// @notice To be called by any user. Allows users to vote for a project  
    /// @dev (Transfers VOTE tokens to this contract)
    /// @param _projectId Id of the project to vote
    /// @param _numberOfVotes votes to provide to the project
    function vote(uint256 _projectId, uint256 _numberOfVotes) public whenNotPaused {
        require(_numberOfVotes > 0, "No votes provided");
        uint256 seasonId = getCurrentSeasonId();
        validateVotingPeriod(seasonId);
        Project storage project = projects[_projectId];
        require(bytes(project.name).length > 0, "ProjectId does not exist in the current season");
        // It should be previously approved by the VOTE token to transferfrom the tokens
        bool success = jetStaking.transferFrom(msg.sender, address(this), _numberOfVotes);
        require(success, "Error in transfer from");
        project.numberOfVotes += _numberOfVotes;
        if (project.votesPerUser[msg.sender] == 0) {
            project.usersVoted.push(msg.sender);
        }
        project.votesPerUser[msg.sender] += _numberOfVotes;
        seasonsVoted[seasonId].totalVotes += _numberOfVotes;
        emit VoteEmitted(seasonId, _projectId, msg.sender, _numberOfVotes); // May not be necessary
    }

    /// @notice To be called by curators. Allows curators to specify the kpi percentage obtained in a specific kpi number.
    /// @param _projectId Id of the project to vote
    /// @param _kpiNumber Number of kpi to be assigned
    /// @param _obtainedPercentage percentage obtained in the kpi formatted to 1E18.
    function updateKpi(
        uint256 _projectId, 
        uint256 _kpiNumber, 
        uint256 _obtainedPercentage
        ) public onlyCurator {
            // Missing restriction for a certain period
            Project storage project = projects[_projectId];
            require(bytes(project.name).length > 0, "ProjectId does not exist");
            require(_kpiNumber > 0 && _kpiNumber <= project.numberOfKpis, "Kpi number does not exist");
            require(_obtainedPercentage <= decimals, "Obtained Kpi percentage out of bounds");
            require(project.kpis[_kpiNumber].previouslyUpdated == false, "Unable to update kpi again");
            project.kpis[_kpiNumber].obtainedPercentage = _obtainedPercentage;
            project.kpis[_kpiNumber].previouslyUpdated = true;
            emit KpiUpdated(_projectId, msg.sender, _kpiNumber, _obtainedPercentage);
    }

    /// @notice To be called by anyone. Get the results of the voting process for all the projects of the season.
    /// @param _seasonId Id of the season
    // Returns the projectId, the needed number of votes, the obtained number of votes, and if they reached the goal
    // Also, includes information about the current season like the total number of votes, allocation total allocated budget, and allocation efficiency
    function getSeasonVotingResults(uint256 _seasonId) public view returns (
        Season memory season, 
        ProjectResult[] memory projectResults, 
        uint256 totalAllocatedBudget, 
        uint256 allocationEfficiency){
        season = seasonsVoted[_seasonId];
        uint256 amountOfProjects = season.projectsInSeason.length;
        require(amountOfProjects > 0, "No projects in this season");
        projectResults = new ProjectResult[](amountOfProjects);
        for(uint256 i = 0; i < amountOfProjects; i++) {
            uint256 _projectId = season.projectsInSeason[i];
            Project storage project = projects[_projectId];
            (uint256 _neededPercentage, 
            uint256 _neededNumberOfVotes, 
            uint256 _obtainedNumberOfVotes, 
            bool _reachedGoal) = getProjectVotingResult(season, project);
            if(_reachedGoal) {
                totalAllocatedBudget += project.requestedWeightedBudget;
            }
            ProjectResult memory projectResult = ProjectResult({
                projectId: _projectId,
                neededPercentage: _neededPercentage,
                neededNumberOfVotes: _neededNumberOfVotes,
                obtainedNumberOfVotes: _obtainedNumberOfVotes,
                reachedGoal: _reachedGoal
            });
            projectResults[i] = projectResult;
        }
        allocationEfficiency = (totalAllocatedBudget * decimals) / season.grantPool;
    }

    /// @notice Used internally to calculate results.
    /// @param _season season struct to be used
    /// @param _project project struct to be used
    /// @dev return values need to be formatted to 1E18
    function getProjectVotingResult(Season memory _season, Project storage _project) internal view returns (  
        uint256 neededPercentage, 
        uint256 neededNumberOfVotes, 
        uint256 obtainedNumberOfVotes, 
        bool reachedGoal) {
        neededPercentage = (_project.requestedWeightedBudget * decimals) / _season.grantPool;
        neededNumberOfVotes = neededPercentage * _season.totalVotes;
        obtainedNumberOfVotes = _project.numberOfVotes * decimals;
        reachedGoal = obtainedNumberOfVotes >= neededNumberOfVotes;
    }

    /// @notice Returns the obtained condional reward amount for a Kpi in a specific project
    /// @dev return values need to be formatted to 1E18
    /// @param _projectId Id of the project to get the conditional rewards 
    /// @param _kpiNumber kpi to calculate results
    function getProjectConditionalRewardForKpi(uint256 _projectId, uint256 _kpiNumber) external view returns (
        uint256 totalConditionalAmount,
        uint256 maximumObtainableConditional,
        uint256 obtainedConditionalRewardAmount,
        uint256 kpiDate,
        bool reachedGoal
    ){
        Project storage project = projects[_projectId];
        require(bytes(project.name).length > 0, "ProjectId does not exist");
        require(_kpiNumber > 0 && _kpiNumber <= project.numberOfKpis, "Invalid kpi number");
        Season memory season = seasonsVoted[project.seasonId];
        (,,, reachedGoal) = getProjectVotingResult(season, project);
        (,,uint256 totalAllocatedBudget, uint256 allocationEfficiency) = getSeasonVotingResults(project.seasonId);
        totalConditionalAmount = (season.rewardPool * season.conditionalRewardPercentage * allocationEfficiency) / decimals**2;
        kpiDate = project.grantPartDates[_kpiNumber];
        if(reachedGoal){
            uint256 conditionalRewardsMax = (((project.requestedWeightedBudget * decimals) / totalAllocatedBudget) * totalConditionalAmount) / decimals;
            maximumObtainableConditional = (conditionalRewardsMax * project.kpis[_kpiNumber].percentageOfReward) / decimals;
            obtainedConditionalRewardAmount = (maximumObtainableConditional * project.kpis[_kpiNumber].obtainedPercentage) / decimals;    
        }
    }

    /// @notice  Returns the uncondional reward amount to be distributed to a project
    /// @dev return values need to be formatted to 1E18
    /// @param _projectId Id of the project to get the unconditional rewards 
    function getProjectUnconditionalRewards(uint256 _projectId) external view returns (
        uint256 totalUnconditionalReward, 
        uint256 obtainedPercentageOfVotes,  
        uint256 projectUnconditionalReward){
        Project storage project = projects[_projectId];
        require(bytes(project.name).length > 0, "Invalid project");
        Season memory season = seasonsVoted[project.seasonId];
        totalUnconditionalReward = (season.rewardPool * season.unconditionalRewardPercentage) / decimals;
        obtainedPercentageOfVotes = (project.numberOfVotes * decimals) / season.totalVotes;
        projectUnconditionalReward = (totalUnconditionalReward * obtainedPercentageOfVotes) / decimals;
    }

    /// @notice Access to grant information of a project
    /// @param  _projectId Id of the project to get the unconditional rewards
    function getProjectGrantInformation(uint256 _projectId) external view returns (
        uint256 requestedWeightedBudget, 
        uint256[] memory grantParts, 
        uint256[] memory grantPartDates){
        Project storage project = projects[_projectId];
        require(bytes(project.name).length > 0, "ProjectId does not exist");
        requestedWeightedBudget = project.requestedWeightedBudget;
        grantParts = new uint256[](project.grantParts.length);
        grantPartDates = new uint256[](project.grantParts.length);
        grantParts = project.grantParts;
        grantPartDates = project.grantPartDates;
    }

    /// @notice Gets the information of all the kpis of a project
    /// @param _projectId Id of the project to get the kpis
    function getProjectObtainedKpis(uint256 _projectId) external view returns (Kpi[] memory kpis) {
        Project storage project = projects[_projectId];
        kpis = new Kpi[](project.numberOfKpis);
        uint256 numberOfKpi = 1;
        for(uint256 i = 0; i < project.numberOfKpis; i++) {
            kpis[i] = project.kpis[numberOfKpi];
            numberOfKpi++;
        }
    }

    /// @notice get current season reference id, change over time
    /// @dev combined with the seasons public array can get the current season information
    function getCurrentSeasonId() public view returns (uint256) {
        return jetStaking.currentSeason();
    }

    // @notice shows the available project ids in a season
    function getProjectsInSeason(uint256 _seasonId) external view returns (uint256[] memory) {
        return seasonsVoted[_seasonId].projectsInSeason;
    }

    /// @notice To be called by administrators. Allows the editability of the Season Allocation.
    /// @dev This can modify previous, current and upcoming seasons.
    /// It recalculates the grant and reward pool each time it is used.
    /// @param _seasonId id of the season to update
    /// @param _totalAllocation new total allocation of the season
    function setSeasonAllocation(
        uint256 _seasonId, 
        uint256 _totalAllocation) 
        public onlyAdmin {
        Season storage season = seasonsVoted[_seasonId];
        uint256 oldAllocation = season.totalAllocation;
        season.totalAllocation = _totalAllocation;
        season.rewardPool = (season.totalAllocation * season.rewardPercentage) / decimals;
        season.grantPool = season.totalAllocation - season.rewardPool;
        emit SeasonAllocationChanged(_seasonId, msg.sender, oldAllocation, _totalAllocation, block.timestamp);
    }
    
    /// @notice To be called by administrators. Sets the reward percentage of the season, not editable.
    /// @dev It recalculates the grant and reward pool when it is used.
    /// This can modify previous, current and upcoming seasons.
    /// @param _seasonId id of the season to update
    /// @param _rewardPercentage new reward percentage of the season
    function setSeasonRewardPercentage(
        uint256 _seasonId, 
        uint256 _rewardPercentage) 
        public onlyAdmin {
        Season storage season = seasonsVoted[_seasonId];
        require(season.rewardPercentage == 0, "Season reward percentage has alredy been set");
        require(_rewardPercentage <= decimals, "Season reward percentage out of bounds");
        season.rewardPercentage = _rewardPercentage;
        season.rewardPool = (season.totalAllocation * season.rewardPercentage) / decimals;
        season.grantPool = season.totalAllocation - season.rewardPool;

        // Set default reward distribution
        if(season.conditionalRewardPercentage == 0 && season.unconditionalRewardPercentage == 0){
            season.conditionalRewardPercentage = 8E17;
            season.unconditionalRewardPercentage = 2E17;
        }
    }

    /// @notice Allows to change the portion of the reward for conditional and unconditional rewards of the season.
    /// @dev To be called by an administrator
    /// @param _seasonId id of the season to update
    /// @param _conditionalRewardPercentage percentage of reward pool for conditional rewards
    /// @param _unconditionalRewardPercentage percentage of reward pool for unconditional rewards
    function changeSeasonRewardDistribution(
        uint256 _seasonId, 
        uint256 _conditionalRewardPercentage, 
        uint256 _unconditionalRewardPercentage) 
        external onlyAdmin {
        Season storage season = seasonsVoted[_seasonId];
        require(_conditionalRewardPercentage > 0, "Error conditional reward percentage equals 0");
        require(_unconditionalRewardPercentage > 0, "Error unconditional reward percentage equals 0");
        require((_conditionalRewardPercentage + _unconditionalRewardPercentage) <= decimals, "Percentages out of bounds");
        uint256 oldConditional = season.conditionalRewardPercentage;
        uint256 oldUnconditional = season.unconditionalRewardPercentage;
        season.conditionalRewardPercentage =  _conditionalRewardPercentage;
        season.unconditionalRewardPercentage = _unconditionalRewardPercentage;
        emit SeasonRewardDistributionChanged(
            _seasonId, 
            msg.sender, 
            oldConditional, 
            _conditionalRewardPercentage, 
            oldUnconditional, 
            _unconditionalRewardPercentage,
            block.timestamp
        );
    }

    /// @notice Private function, Received the grant distribution and calculates the requested weighted budget using the stored coefficients
    /// @param grantStructure stucture with the categories of distribution to calculate the requested weighted budget
    /// @param _seasonId id of the seaon to be calculated
    function _getProjectRequestedWeightedBudget(uint256[6] calldata grantStructure, uint256 _seasonId) private view  
        returns (uint256 requestedWeightedBudget){
        uint256 operationalBudget = grantStructure[0];
        uint256 marketingBudget = grantStructure[1];
        uint256 longTermIncentives = grantStructure[2];
        uint256 protocolSpecificIncentives = grantStructure[3];
        uint256 liquity = grantStructure[4];
        uint256 numberOfMonths = grantStructure[5]; // TODO: Validate this param, if possible
        uint256 coefficientmultiplier = _getCoefficientMultiplier(numberOfMonths);
        uint256 coefficientId = getSuitableCoefficientId(_seasonId);
        Coefficient memory coefficient = coefficients[coefficientId];
        requestedWeightedBudget += (operationalBudget * coefficient.operationalBudget) / decimals;
        requestedWeightedBudget += (marketingBudget * coefficient.marketingBudget) / decimals;
        requestedWeightedBudget += (longTermIncentives * coefficient.longTermIncentives) / decimals;
        requestedWeightedBudget += (protocolSpecificIncentives * coefficient.protocolSpecificIncentives) / decimals;
        requestedWeightedBudget += (liquity * coefficientmultiplier * coefficient.liquity) / decimals;
    }

    /// @notice Private function, Used to calculate how many times the coefficient has to be applied depending on the number of months
    /// @dev returns the coefficient multipler to be used to calculate the liquity requested weighted budget 
    function _getCoefficientMultiplier(uint256 _numberOfMonths) private pure returns (uint256){
        uint256 divider = 3;
        if(_numberOfMonths % divider == 0) return _numberOfMonths / divider;
        return (_numberOfMonths + (divider - (_numberOfMonths % divider))) / divider;
    }

    /// @notice Validates that the a season period to vote is allowed
    function validateVotingPeriod(uint256 seasonId) internal view {
        (,,,,, uint256 startVoting, uint256 endVoting,,) = jetStaking.seasons(seasonId);
        require(startVoting < block.timestamp && endVoting > block.timestamp, "Voting period not allowed");
    }

    /// @notice Validates that the season period to publish projects is allowed
    function validateAplicationVotingPeriod(uint256 seasonId) internal view {
        (,uint256 applicationStart,,, uint256 applicationVotingEnd,,,,) = jetStaking.seasons(seasonId);
        require(applicationStart < block.timestamp && applicationVotingEnd > block.timestamp, "Voting period not allowed");
        require(seasonsVoted[seasonId].grantPool > 0, "Season grant pool has not been established");
        require(seasonsVoted[seasonId].rewardPool > 0, "Season reward pool has not been established");
    }
    
    /// @notice Validates that the inputs of the project are valid
    function _validateProjectParams(
        string memory _name,
        address _ownerWallet,
        uint256[] calldata _grantParts,
        uint256[] calldata _grantPartDates)
        private view {
        require(bytes(_name).length > 0, "Invalid project name");
        require(_ownerWallet != address(0), "Invalid project owner wallet");
        require(_grantPartDates.length == _grantParts.length, "Grant part and dates length must be the same");
        _validateGrantParts(_grantParts);
    }

    /// @notice Validates that grant distribution is in the correct format
    function _validateGrantParts(uint256[] calldata _grantParts) private view {
        uint256 totalPercentages;
        for(uint256 i = 0; i < _grantParts.length; i++) {
            require(_grantParts[i] > 0 && _grantParts[i] <= decimals, "Part distribution percentage out of bounds");
            totalPercentages += _grantParts[i];
            require(totalPercentages <= decimals, "Total percentages are greater than 100 percent");
        }
        require(totalPercentages == decimals, "Total percentages are less than 100 percent");
    }

    /// @notice  Allows to change the default coefficients to be used by the seasons that have not started.
    /// @dev To be called by Administrators. Changes the new default coefficients for upcoming seasons
    function changeCoefficients (
        uint256 _operationalBudget,
        uint256 _marketingBudget,
        uint256 _longTermIncentives,
        uint256 _protocolSpecificIncentives,
        uint256 _liquity
        ) external onlyAdmin {
        _changeCoefficients(_operationalBudget, _marketingBudget, _longTermIncentives, _protocolSpecificIncentives, _liquity);
    }

    /// @notice Private fuction, Sets the initial default values for the coefficients when the contract is deployed
    function _setInitialCoefficients() private {
        uint256 _operationalBudget = 1.5E18;
        uint256 _marketingBudget = 5E17;
        uint256 _longTermIncentives = 5E17;
        uint256 _protocolSpecificIncentives = 1E18;
        uint256 _liquity = 2.5E17;
        _changeCoefficients(_operationalBudget, _marketingBudget, _longTermIncentives, _protocolSpecificIncentives, _liquity);
    }
    
    /// @notice Private fuction,  Allows to change the default coefficients to be used by the seasons that have not started.
    function _changeCoefficients(
        uint256 _operationalBudget,
        uint256 _marketingBudget,
        uint256 _longTermIncentives,
        uint256 _protocolSpecificIncentives,
        uint256 _liquity
        ) private {
        coefficientCounterId++;
        Coefficient storage coefficient = coefficients[coefficientCounterId];
        coefficient.operationalBudget = _operationalBudget;
        coefficient.marketingBudget = _marketingBudget;
        coefficient.longTermIncentives = _longTermIncentives;
        coefficient.protocolSpecificIncentives = _protocolSpecificIncentives;
        coefficient.liquity = _liquity;
        coefficient.creationDate = block.timestamp;
    }

    /// @notice Gets the most recent and applicable coefficient to be used in a season depending on the creation date.
    /// @dev Everytime the coefficients are updated the coefficient id changes, this function gets the correct id for a season
    /// @param _seasonId id of the season to be used to look for the coefficient creation date
    function getSuitableCoefficientId(uint256 _seasonId) public view returns (uint256){
        (uint256 startSeason,,,,,,,,) = jetStaking.seasons(_seasonId);
        for(uint256 i = coefficientCounterId; i >= 1; i--) {
            if (startSeason > coefficients[i].creationDate){
                return i;
            }
        }
        return 1; // If not suitable coefficient found use the initial default
    }

    /// @notice Private function, sets the kpi reward percentages to be allocated for each number of kpi
    /// @param _project project reference to be modified
    function _setKpiPercentages(Project storage _project, uint256[] calldata grantParts) private {
        uint256 divider = decimals - grantParts[grantParts.length-1];
        for(uint256 i = 1; i < grantParts.length; i++) {
            _project.kpis[i].percentageOfReward = (grantParts[i-1] * decimals) / divider;
        }
    }

    /// @notice Sets the kpi reward percentages to be allocated for each number of kpi and how the project should receive the grant
    /// @param _projectId id of the project to be modified
    /// @param _grantParts new grant distribution percentages
    function updateGrantParts(uint256 _projectId, uint256[] calldata _grantParts) external onlyCurator {
        Project storage project = projects[_projectId];
        require(bytes(project.name).length > 0, "ProjectId does not exist");
        require(_grantParts.length == project.grantParts.length, "Unable to modify the grant parts length");
        _validateGrantParts(_grantParts);
        _setKpiPercentages(project, _grantParts);
        project.grantParts = _grantParts;
        project.numberOfKpis = _grantParts.length-1;
    }

    /// @notice Returns the users who voted for a project and the amount of votes per user
    /// @param _projectId id of the project to be requested
    function getVotesPerProject(uint256 _projectId) external view returns (
        uint256 totalNumberOfVotes,
        address[] memory users, 
        uint256[] memory votes) {
        Project storage project = projects[_projectId];
        totalNumberOfVotes = project.numberOfVotes;
        uint256 amountOfUsers = project.usersVoted.length;
        users = new address[](amountOfUsers);
        votes = new uint256[](amountOfUsers);
        users = project.usersVoted;
        for(uint256 i = 0; i < amountOfUsers; i++) {
            votes[i] = project.votesPerUser[users[i]];
        }
    }
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
pragma solidity 0.8.10;
// ============================== Testing purposes ==============================
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

// interface IJetStaking is IERC20Upgradeable {

//     function stake(uint256 amount, uint256 seasonAmount) external;
//     function unstake (uint256 depositId) external;

//     function claimVote(uint256 depositId) external;
//     function claimRewards(uint256 depositId, uint index, address user) external;

//     function updateSeasonDuration(uint256 newDuration) external;
//     function burn(address user, uint256 amount) external;

//     function seasons(uint256 seasonId) external view returns (
//         uint256 startSeason,
//         uint256 applicationStart,
//         uint256 applicationEnd,
//         uint256 applicationVotingStart,
//         uint256 applicationVotingEnd, 
//         uint256 startVoting,
//         uint256 endVoting,
//         uint256 endSeason,
//         uint256 decayStart
//     ); 

//     function currentSeason() external view returns(uint256);
// }
// ================================================================================

interface IJetStaking {

    function stake(uint256 amount, uint256 seasonAmount) external;
    function unstake (uint256 depositId) external;

    function claimVote(uint256 depositId) external;
    function claimRewards(uint256 depositId, uint index, address user) external;

    function updateSeasonDuration(uint256 newDuration) external;
    function burn(address user, uint256 amount) external;

    function seasons(uint256 seasonId) external view returns (
        uint256 startSeason,
        uint256 applicationStart,
        uint256 applicationEnd,
        uint256 applicationVotingStart,
        uint256 applicationVotingEnd, 
        uint256 startVoting,
        uint256 endVoting,
        uint256 endSeason,
        uint256 decayStart
    ); 

    function currentSeason() external view returns(uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


/**
* @title Pausable
* @dev Base contract which allows children to implement an emergency stop mechanism.
*/
contract Pausable is Initializable, OwnableUpgradeable {

    event Pause();
    event Unpause();
    event NotPausable();

    bool public paused;
    bool public canPause;

    mapping (address => bool) public isAdmin;
    mapping (address => bool) public isCurator;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Sender is not an admin");
        _;
    }

    modifier onlyCurator() {
        require(isCurator[msg.sender], "Sender is not a curator");
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused || isAdmin[msg.sender]);
        _;
    }

    /**
    * @dev Modifier to make a function callable only when the contract is paused.
    */
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function __Pausable_init() onlyInitializing internal {
        canPause = true;
    }

    /**
    * @dev called by the owner to pause, triggers stopped state
    **/
    function pause() public onlyAdmin whenNotPaused {
        require(canPause == true);
        paused = true;
        emit Pause();
    }

    /**
    * @dev called by the owner to unpause, returns to normal state
    */
    function unpause() public onlyAdmin whenPaused {
        require(paused == true);
        paused = false;
        emit Unpause();
    }
  
    /**
    * @dev Prevent the token from ever being paused again
    **/
    function notPausable() public onlyAdmin {
        paused = false;
        canPause = false;
        emit NotPausable();
    }

    function addAdmin(address _admin) public onlyOwner {
        isAdmin[_admin] = true;
    }

    function removeAdmin(address _admin) public onlyOwner {
        isAdmin[_admin] = false;
    }

    function addCurator(address _curator) public onlyAdmin {
        isCurator[_curator] = true;
    }

    function removeCurator(address _curator) public onlyAdmin {
        isCurator[_curator] = false;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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