// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721A.sol";
import "../delegatecash/IDelegationRegistry.sol";
import "../weth/IWETH.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";


/** Dead Will Rise presented by Gutter Punks
  * Contract by 0xth0mas (0xjustadev)
  * Gas optimization credit 0xDelco
*/

contract DeadWillRise is ERC721A, Ownable {

    event IndividualDailyActivity(uint256 tokenId, uint256 currentDay, uint256 riskChoice, uint256 activityOutcome);
    event IndividualCured(uint256 tokenId);
    event GroupDailyActivity(uint256 groupNum, uint256 currentDay, uint256 riskChoice, uint256 activityOutcome);
    event InfectionSpreading(uint256 currentProgress, uint256 infectionRate);
    event GroupRegistered(uint256 groupNum, address collectionAddress, address groupManager);
    event GroupTransferred(uint256 groupNum, address collectionAddress, address groupManager);

    struct IndividualData {
        uint32 lastBlock;
        uint32 lastScore;
        uint32 individualSeed;
        uint32 groupNumber;
        bool bitten; // potential outcome from an activity, when bitten individual score rate decreases substantially
    }

    struct GroupData {
        uint32 lastBlock;
        uint32 lastScore;
        uint32 groupSeed;
        uint32 totalMembers;
    }

    struct InfectionData {
        uint32 lastBlock;
        uint32 lastProgress;
        uint32 infectionRate; // rate that the infection progress will increase per block
    }

    struct ActivityRecord {
        uint32 riskChoice; // 1 = low risk, 2 = medium risk, 3 = high risk
        uint32 activityOutcome; // 1 = small reward, 2 = medium reward, 3 = large reward, 4 = devastation
    }

    uint256 public constant INDIVIDUAL_DAILY_ACTIVITY_COST = 0.001 ether;
    uint256 public constant GROUP_DAILY_ACTIVITY_COST = 0.01 ether;
    uint256 public constant GROUP_REGISTRATION_COST = 0.1 ether;
    uint256 public constant FINAL_CURE_COST = 10 ether;
    uint32 constant CURE_PROGRESS_INCREMENT = 72000;

    uint8 constant RISK_LEVEL_LOW = 1;
    uint8 constant RISK_LEVEL_MEDIUM = 2;
    uint8 constant RISK_LEVEL_HIGH = 3;
    uint8 constant ACTIVITY_OUTCOME_SMALL = 1;
    uint8 constant ACTIVITY_OUTCOME_MEDIUM = 2;
    uint8 constant ACTIVITY_OUTCOME_LARGE = 3;
    uint8 constant ACTIVITY_OUTCOME_DEVASTATED = 4;
    uint8 constant ACTIVITY_OUTCOME_CURED = 5;
    uint8 constant ACTIVITY_OUTCOME_STILL_A_ZOMBIE = 6;

    uint8 public constant MAX_DAY = 19;

    // Individuals will have a rate between 100-150 if unbitten, 25-37 if bitten
    uint32 constant INDIVIDUAL_BASE_RATE = 100;
    uint32 constant INDIVIDUAL_VARIABLE_RATE = 50;
    uint32 constant INDIVIDUAL_MAXIMUM_LUCK = 1000; // luck used to determine outcome of activities
    uint32 constant TOTAL_MAXIMUM_LUCK = 10000; // luck used to determine outcome of activities
    uint32 constant RISK_LOW_OUTCOME_LARGE = 9900;
    uint32 constant RISK_LOW_OUTCOME_MEDIUM = 9500;
    uint32 constant RISK_LOW_OUTCOME_SMALL = 100;
    uint32 constant RISK_MEDIUM_OUTCOME_LARGE = 9000;
    uint32 constant RISK_MEDIUM_OUTCOME_MEDIUM = 7500;
    uint32 constant RISK_MEDIUM_OUTCOME_SMALL = 1000;
    uint32 constant RISK_HIGH_OUTCOME_LARGE = 7500;
    uint32 constant RISK_HIGH_OUTCOME_MEDIUM = 5000;
    uint32 constant RISK_HIGH_OUTCOME_SMALL = 3300;
    uint32 constant RANDOM_CURE_CHANCE = 9500;
    uint32 constant INDIVIDUAL_REWARD_OUTCOME_LARGE = 360000;
    uint32 constant INDIVIDUAL_REWARD_OUTCOME_MEDIUM = 180000;
    uint32 constant INDIVIDUAL_REWARD_OUTCOME_SMALL = 72000;
    uint32 constant GROUP_REWARD_OUTCOME_LARGE = 36000;
    uint32 constant GROUP_REWARD_OUTCOME_MEDIUM = 18000;
    uint32 constant GROUP_REWARD_OUTCOME_SMALL = 3600;

    // Group scoring rate will increase by 1 for every 10th member that joins, 1 member = 1, 9 members = 1, 10 members = 2, 95 members = 10
    uint32 constant GROUP_BASE_RATE = 1;
    uint32 constant GROUP_VARIABLE_RATE = 10;
    uint32 constant GROUP_RATE_MULTIPLIER = 1;

    uint256 public constant MAX_SUPPLY = 5000;

    bool public eventOver;
    uint64 public eventStartTime;
    uint32 public eventStartBlock;

    uint32 public collectionSeed; // random seed set at start of game, collection seed == 0 means event not started
    uint32 public groupsRegistered; // current count of groups registered for Dead Will Rise

    bool public groupRegistrationOpen;
    bool public publicMintOpen;

    uint32 public maxPerWalletPerGroup = 1;
    uint32 public maxPerGroup = 500;
    uint32 public cureSupply = 500;

    uint32 public lastSurvivorTokenID; // declared at end of game
    uint32 public winningGroupNumber; // declared at end of game
    uint32 constant BLOCKS_PER_DAY = 7200;
    uint32 constant WITHDRAWAL_DELAY = 3600; // blocks to wait after winners declared for withdrawal
    uint32 constant LATE_JOINER_PROGRESS = 21600;

    InfectionData public infectionProgress; // current infection data - currentProgress = lastProgress + (block.number - lastBlock) * infectionRate
    mapping(address => uint256) public groupNumbers; // key = ERC-721 collection address, value = group number
    mapping(uint256 => address) public groupNumberToCollection; // key = group number, value = ERC-721 collection address
    mapping(uint256 => GroupData) public groupRecord; // key = group number, value = group data
    mapping(uint256 => address) public groupManager; // key = group number, value = current manager of group, will receive payout if group wins
    mapping(uint256 => ActivityRecord) public groupActivity; // key = groupNumber<<32 + day, value = activity results
    mapping(uint256 => IndividualData) public individualRecord; // key = tokenId, value = individual data
    mapping(uint256 => ActivityRecord) public individualActivity; // key = tokenId<<32 + day, value = activity results

    mapping(uint256 => uint256) public mintCount; // key = account<<32 + groupNumber, value = # minted

    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IDelegationRegistry delegateCash = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    string internal _baseTokenURI;
    string internal _placeholderURI;
    string internal _contractURI;

    string public constant TOKEN_URI_SEPARATOR = "/";
    bool public includeStatsInURI = true;

    modifier eventInProgress() {
        require(collectionSeed > 0 && !eventOver);
        _;
    }

    modifier eventEnded() {
        require(eventOver);
        _;
    }

    modifier canWithdraw() {
        require(uint32(block.number) > (infectionProgress.lastBlock + WITHDRAWAL_DELAY));
        _;
    }

    constructor(string memory mContractURI, string memory mPlaceholderURI) ERC721A("Dead Will Rise", "DWR") {
        _contractURI = mContractURI;
        _placeholderURI = mPlaceholderURI;
    }

    // to receive royalties and/or donations
    receive() external payable { }
    fallback() external payable { }
    //unwrap WETH from any royalties paid in WETH
    function unwrapWETH() external onlyOwner {
        uint256 wethBalance = weth.balanceOf(address(this));
        weth.withdraw(wethBalance);
    }

    /** GAME MANAGEMENT FUNCTIONS
    */ 
    function startEvent(uint32 _infectionRate) external onlyOwner {
        require(collectionSeed == 0);
        eventStartTime = uint64(block.timestamp);
        collectionSeed = uint32(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))));
        infectionProgress.lastBlock = uint32(block.number);
        infectionProgress.infectionRate = _infectionRate;
        emit InfectionSpreading(infectionProgress.lastProgress, infectionProgress.infectionRate);
        eventStartBlock = uint32(block.number);
    }

    function endEvent() external onlyOwner eventInProgress {
        require(!eventOver);
        infectionProgress.lastProgress = this.currentInfectionProgress();
        infectionProgress.lastBlock = uint32(block.number);
        infectionProgress.infectionRate = 0;
        emit InfectionSpreading(infectionProgress.lastProgress, infectionProgress.infectionRate);
        eventOver = true;
    }

    function resumeEvent(uint32 _infectionRate) external onlyOwner eventEnded {
        require(eventOver);
        infectionProgress.lastProgress = this.currentInfectionProgress();
        infectionProgress.lastBlock = uint32(block.number);
        infectionProgress.infectionRate = _infectionRate;
        emit InfectionSpreading(infectionProgress.lastProgress, infectionProgress.infectionRate);
        eventOver = false;
    }

    function setInfectionRate(uint32 _infectionRate, uint32 _progressAdder) external onlyOwner eventInProgress {
        infectionProgress.lastProgress = this.currentInfectionProgress() + _progressAdder;
        infectionProgress.lastBlock = uint32(block.number);
        infectionProgress.infectionRate = _infectionRate;
        emit InfectionSpreading(infectionProgress.lastProgress, infectionProgress.infectionRate);
    }

    function setInfectionProgress(uint32 _infectionProgress) external onlyOwner {
        infectionProgress.lastProgress = _infectionProgress;
        emit InfectionSpreading(infectionProgress.lastProgress, infectionProgress.infectionRate);
    }

    /** Save gas vs iterating collection for winner by declaring winner and allow anyone to challenge that another token has a higher score
        Winner can be declared after event has ended but withdrawals are delayed until 12 hours after event ends to allow for challenges
        In the event of a tie, first to declare wins... because this is an apocalypse and you have to be ready.
    */
    function declareLastSurvivor(uint256 tokenId) external eventEnded {
        uint256 _currentTokenID = lastSurvivorTokenID;
        if(_currentTokenID == 0 || this.getIndividualScore(tokenId) > this.getIndividualScore(_currentTokenID)) {
            lastSurvivorTokenID = uint32(tokenId);
        } else {
            revert();
        }
    }

    /** Save gas vs iterating groups for winner by declaring winner and allow anyone to challenge that another group has a higher score
        Winner can be declared after event has ended but withdrawals are delayed until 12 hours after event ends to allow for challenges
        In the event of a tie, first to declare wins... because this is an apocalypse and you have to be ready.
    */ 
    function declareWinningGroup(uint32 groupNumber) external eventEnded {
        uint32 _currentGroupNumber = winningGroupNumber;
        if(_currentGroupNumber == 0 || this.getGroupScore(groupNumber) > this.getGroupScore(_currentGroupNumber)) {
            winningGroupNumber = groupNumber;
        } else {
            revert();
        }
    }

    uint256 public totalWithdrawn;
    uint256 public totalSwept;
    uint256 public hostBalance;
    uint256 public groupBalance;
    uint256 public survivorBalance;

    /** Sweep rewards into a balance mapping first to avoid survivor/group owner set to contract with revert
    */
    function sweepRewards() external onlyOwner canWithdraw {
        uint256 currentPool = totalWithdrawn + address(this).balance - totalSwept;
        totalSwept = totalSwept + currentPool;

        uint256 survivorShare = currentPool * 30 / 100;
        uint256 groupShare = currentPool * 20 / 100;
        uint256 hostShare = (currentPool - survivorShare - groupShare);

        hostBalance += hostShare;
        groupBalance += groupShare;
        survivorBalance += survivorShare;
    }

    function withdraw(uint256 share) external onlyOwner {
        address recipient;
        uint256 recipientBalance;
        if(share == 1) {
            recipient = owner();
            recipientBalance = hostBalance;
            hostBalance = 0;
        } else if(share == 2) {
            recipient = groupManager[winningGroupNumber];
            recipientBalance = groupBalance;
            groupBalance = 0;
        } else if(share == 3) {
            recipient = ownerOf(lastSurvivorTokenID);
            recipientBalance = survivorBalance;
            survivorBalance = 0;
        }
        require(recipientBalance > 0);
        (bool sent, ) = payable(recipient).call{value: recipientBalance}("");
        require(sent);
        totalWithdrawn = totalWithdrawn + recipientBalance;
    }

    /** SCORE FUNCTIONS 
    */

    function currentInfectionProgress() external view returns (uint32) {
        if(eventOver) return infectionProgress.lastProgress;
        return (infectionProgress.lastProgress + (uint32(block.number) - infectionProgress.lastBlock) * infectionProgress.infectionRate);
    }

    function getIndividualScore(uint256 tokenId) external view returns (uint32) {
        require(_exists(tokenId));
        if(eventStartTime == 0) return 0;
        uint32 _endBlock = uint32(block.number);
        if(eventOver) _endBlock = infectionProgress.lastBlock;
        IndividualData memory individual = individualRecord[tokenId];
        uint32 _lastBlock = individual.lastBlock;
        if(_lastBlock == 0) _lastBlock = eventStartBlock;
        return (individual.lastScore + (_endBlock - _lastBlock) * this.getIndividualRate(tokenId,false) + this.getGroupScore(individual.groupNumber));
    }

    function getIndividualOnlyScore(uint256 tokenId) external view returns (uint32) {
        require(_exists(tokenId));
        if(eventStartTime == 0) return 0;
        uint32 _endBlock = uint32(block.number);
        if(eventOver) _endBlock = infectionProgress.lastBlock;
        IndividualData memory individual = individualRecord[tokenId];
        uint32 _lastBlock = individual.lastBlock;
        if(_lastBlock == 0) _lastBlock = eventStartBlock;
        return (individual.lastScore + (_endBlock - _lastBlock) * this.getIndividualRate(tokenId,false));
    }

    function getIndividualRate(uint256 tokenId, bool ignoreBite) external view returns (uint32) {
        if(eventStartTime == 0) return 0;
        IndividualData memory individual = individualRecord[tokenId];
        uint32 _individualRate = uint32(uint256(keccak256(abi.encodePacked(individual.individualSeed, collectionSeed)))) % INDIVIDUAL_VARIABLE_RATE + INDIVIDUAL_BASE_RATE;
        if(individual.bitten && !ignoreBite) { _individualRate = _individualRate / 4; }
        return _individualRate;
    }

    function getIndividualLuck(uint256 tokenId) external view returns (uint32) {
        if(eventStartTime == 0) return 0;
        IndividualData memory individual = individualRecord[tokenId];
        uint32 _individualLuck = uint32(uint256(keccak256(abi.encodePacked(collectionSeed, individual.individualSeed)))) % INDIVIDUAL_MAXIMUM_LUCK;
        return _individualLuck;
    }

    function getGroupScoreByAddress(address _collectionAddress) external view returns(uint32) {
        return this.getGroupScore(uint32(groupNumbers[_collectionAddress]));
    }

    function getGroupScore(uint32 _groupNumber) external view returns (uint32) {
        if(_groupNumber == 0) return 0;
        if(eventStartTime == 0) return 0;
        uint32 _endBlock = uint32(block.number);
        if(eventOver) _endBlock = infectionProgress.lastBlock;
        GroupData memory group = groupRecord[uint256(_groupNumber)];
        uint32 _lastBlock = group.lastBlock;
        if(_lastBlock == 0) _lastBlock = eventStartBlock;
        return (group.lastScore + (_endBlock - _lastBlock) * this.getGroupRate(_groupNumber));
    }

    function getGroupRate(uint32 _groupNumber) external view returns (uint32) {
        if(eventStartTime == 0) return 0;
        if(_groupNumber == 0 || _groupNumber > groupsRegistered) return 0;
        uint32 _totalMembers = groupRecord[uint256(_groupNumber)].totalMembers;
        return (_totalMembers / GROUP_VARIABLE_RATE + GROUP_BASE_RATE) * GROUP_RATE_MULTIPLIER;
    }

    /** DAILY ACTIVITY FUNCTIONS 
    */
    function currentDay() external view returns (uint32) {
        if(eventStartTime == 0) return 0;
        uint32 _currentDay = uint32((block.timestamp - uint256(eventStartTime)) / 1 days + 1);
        if(_currentDay > MAX_DAY) { _currentDay = MAX_DAY; }
        return _currentDay;
    }

    function getIndividualDailyActivityRecords(uint256 tokenId) external view returns(ActivityRecord[] memory) {
        uint256 numRecords = this.currentDay();
        ActivityRecord[] memory records = new ActivityRecord[](numRecords);
        for(uint256 i = 1;i <= numRecords;i++) {
            records[i-1] = individualActivity[((tokenId << 32) + i)];
        }
        return records;
    }

    function getGroupDailyActivityRecords(uint32 _groupNumber) external view returns(ActivityRecord[] memory) {
        uint256 numRecords = this.currentDay();
        ActivityRecord[] memory records = new ActivityRecord[](numRecords);
        for(uint256 i = 1;i <= numRecords;i++) {
            records[i-1] = groupActivity[((uint256(_groupNumber) << 32) + i)];
        }
        return records;
    }

    function getGroupDailyActivityRecordsByAddress(address _collectionAddress) external view returns(ActivityRecord[] memory) {
        return this.getGroupDailyActivityRecords(uint32(groupNumbers[_collectionAddress]));
    }
    
    function cureIndividual(uint256 tokenId) external payable eventInProgress {
        require(ownerOf(tokenId) == msg.sender);
        require(cureSupply > 0);

        IndividualData memory individual = individualRecord[tokenId];
        if(individual.lastBlock == 0) { individual.lastBlock = eventStartBlock; }
        individual.lastScore = (individual.lastScore + (uint32(block.number) - individual.lastBlock) * this.getIndividualRate(tokenId,false));
        individual.lastBlock = uint32(block.number);
        uint32 _groupScore = this.getGroupScore(individual.groupNumber);
        uint32 _totalScore = (individual.lastScore + _groupScore);
        uint32 _currentInfectionProgress = this.currentInfectionProgress();
        uint256 cureCost = FINAL_CURE_COST / cureSupply;
        
        if(_totalScore >= _currentInfectionProgress && individual.bitten) { // half cost if bitten but not fully zombie yet
            cureCost = cureCost / 2;
        } else if(_totalScore < _currentInfectionProgress) {
            individual.lastScore = (_currentInfectionProgress + CURE_PROGRESS_INCREMENT) - _groupScore; // bump score over infection level
        } else {
            cureCost = cureCost * 5; // greedy people that don't need a cure pay 5x
        }
        individual.bitten = false;

        cureSupply = cureSupply - 1;
        individualRecord[tokenId] = individual;
        require(msg.value >= cureCost);
        emit IndividualCured(tokenId);
    }

    function dailyActivityIndividual(uint256 tokenId, uint32 _riskChoice) external payable eventInProgress {
        require(_riskChoice >= RISK_LEVEL_LOW && _riskChoice <= RISK_LEVEL_HIGH);
        require(msg.value >= INDIVIDUAL_DAILY_ACTIVITY_COST);
        require(ownerOf(tokenId) == msg.sender);

        uint256 _currentDay = uint256(this.currentDay());
        uint256 individualDayKey = (tokenId << 32) + _currentDay;
        ActivityRecord memory activity = individualActivity[individualDayKey];
        require(activity.riskChoice == 0);
        uint32 _activityOutcome = 0;
        
        IndividualData memory individual = individualRecord[tokenId];
        if(individual.lastBlock == 0) { individual.lastBlock = eventStartBlock; }
        individual.lastScore = (individual.lastScore + (uint32(block.number) - individual.lastBlock) * this.getIndividualRate(tokenId,false));
        individual.lastBlock = uint32(block.number);
        uint32 _groupScore = this.getGroupScore(individual.groupNumber);
        uint32 _currentInfectionProgress = this.currentInfectionProgress();
        uint32 _individualLuck = this.getIndividualLuck(tokenId);

        uint32 _seed = (uint32(uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,tokenId)))) % TOTAL_MAXIMUM_LUCK) + _individualLuck;

        if((individual.lastScore + _groupScore) >= _currentInfectionProgress) {
            if(_riskChoice == RISK_LEVEL_LOW) {
                if(_seed > RISK_LOW_OUTCOME_LARGE) {
                    _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_LARGE;
                } else if(_seed > RISK_LOW_OUTCOME_MEDIUM) {
                    _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_MEDIUM;
                } else if(_seed > RISK_LOW_OUTCOME_SMALL) {
                    _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_SMALL;
                } else {
                    _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                    individual.bitten = true;
                }
            } else if(_riskChoice == RISK_LEVEL_MEDIUM) {
                if(_seed > RISK_MEDIUM_OUTCOME_LARGE) {
                    _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_LARGE;
                } else if(_seed > RISK_MEDIUM_OUTCOME_MEDIUM) {
                    _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_MEDIUM;
                } else if(_seed > RISK_MEDIUM_OUTCOME_SMALL) {
                    _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_SMALL;
                } else {
                    _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                    individual.bitten = true;
                }
            } else if(_riskChoice == RISK_LEVEL_HIGH) {
                if(_seed > RISK_HIGH_OUTCOME_LARGE) {
                    _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_LARGE;
                } else if(_seed > RISK_HIGH_OUTCOME_MEDIUM) {
                    _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_MEDIUM;
                } else if(_seed > RISK_HIGH_OUTCOME_SMALL) {
                    _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                    individual.lastScore += INDIVIDUAL_REWARD_OUTCOME_SMALL;
                } else {
                    _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                    individual.bitten = true;
                }
            }
        } else { // already a zombie, chance to recover
            if(_seed > RANDOM_CURE_CHANCE) {
                _riskChoice = 1;
                individual.lastScore = (_currentInfectionProgress + LATE_JOINER_PROGRESS) - _groupScore;
                _activityOutcome = ACTIVITY_OUTCOME_CURED;
                individual.bitten = false;
            } else {
                _riskChoice = 1;
                _activityOutcome = ACTIVITY_OUTCOME_STILL_A_ZOMBIE;
            }
        }

        activity.riskChoice = _riskChoice;
        activity.activityOutcome = _activityOutcome;

        individualActivity[individualDayKey] = activity;
        individualRecord[tokenId] = individual;

        emit IndividualDailyActivity(tokenId, _currentDay, _riskChoice, _activityOutcome);
    }

    function dailyActivityGroup(uint32 _groupNumber, uint32 _riskChoice) external payable eventInProgress {
        require(_riskChoice >= RISK_LEVEL_LOW && _riskChoice <= RISK_LEVEL_HIGH);
        require(msg.value >= GROUP_DAILY_ACTIVITY_COST);
        require(groupManager[_groupNumber] == msg.sender);

        uint256 _currentDay = uint256(this.currentDay());
        uint256 groupDayKey = (uint256(_groupNumber) << 32) + _currentDay;
        ActivityRecord memory activity = groupActivity[groupDayKey];
        require(activity.riskChoice == 0);
        uint32 _activityOutcome = 0;
        
        GroupData memory group = groupRecord[uint256(_groupNumber)];
        if(group.lastBlock == 0) { group.lastBlock = eventStartBlock; }
        group.lastScore = (group.lastScore + (uint32(block.number) - group.lastBlock) * this.getGroupRate(_groupNumber));
        group.lastBlock = uint32(block.number);

        uint32 _seed = (uint32(uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty,_groupNumber)))) % TOTAL_MAXIMUM_LUCK);

        if(_riskChoice == RISK_LEVEL_LOW) {
            if(_seed > RISK_LOW_OUTCOME_LARGE) {
                _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                group.lastScore += GROUP_REWARD_OUTCOME_LARGE;
            } else if(_seed > RISK_LOW_OUTCOME_MEDIUM) {
                _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                group.lastScore += GROUP_REWARD_OUTCOME_MEDIUM;
            } else if(_seed > RISK_LOW_OUTCOME_SMALL) {
                _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                group.lastScore += GROUP_REWARD_OUTCOME_SMALL;
            } else {
                _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                group.lastScore /= 2;
            }
        } else if(_riskChoice == RISK_LEVEL_MEDIUM) {
            if(_seed > RISK_MEDIUM_OUTCOME_LARGE) {
                _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                group.lastScore += GROUP_REWARD_OUTCOME_LARGE;
            } else if(_seed > RISK_MEDIUM_OUTCOME_MEDIUM) {
                _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                group.lastScore += GROUP_REWARD_OUTCOME_MEDIUM;
            } else if(_seed > RISK_MEDIUM_OUTCOME_SMALL) {
                _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                group.lastScore += GROUP_REWARD_OUTCOME_SMALL;
            } else {
                _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                group.lastScore /= 2;
            }
        } else if(_riskChoice == RISK_LEVEL_HIGH) {
            if(_seed > RISK_HIGH_OUTCOME_LARGE) {
                _activityOutcome = ACTIVITY_OUTCOME_LARGE;
                group.lastScore += GROUP_REWARD_OUTCOME_LARGE;
            } else if(_seed > RISK_HIGH_OUTCOME_MEDIUM) {
                _activityOutcome = ACTIVITY_OUTCOME_MEDIUM;
                group.lastScore += GROUP_REWARD_OUTCOME_MEDIUM;
            } else if(_seed > RISK_HIGH_OUTCOME_SMALL) {
                _activityOutcome = ACTIVITY_OUTCOME_SMALL;
                group.lastScore += GROUP_REWARD_OUTCOME_SMALL;
            } else {
                _activityOutcome = ACTIVITY_OUTCOME_DEVASTATED;
                group.lastScore /= 2;
            }
        }

        activity.riskChoice = _riskChoice;
        activity.activityOutcome = _activityOutcome;

        groupActivity[groupDayKey] = activity;
        groupRecord[uint256(_groupNumber)] = group;

        emit GroupDailyActivity(_groupNumber, _currentDay, _riskChoice, _activityOutcome);
    }

    /** GROUP MANAGEMENT FUNCTIONS
    */

    /**  Register a group to Dead Will Rise, claims ownership
    */
    function registerGroup(address _collectionAddress) external payable {
        require(groupRegistrationOpen);
        require(msg.value >= GROUP_REGISTRATION_COST);
        require(groupNumbers[_collectionAddress] == 0);
        require(IERC721(_collectionAddress).supportsInterface(type(IERC721).interfaceId));
        groupsRegistered = groupsRegistered + 1;
        uint256 newGroupNumber = groupsRegistered;
        GroupData memory newGroup;
        newGroup.groupSeed = uint32(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, _collectionAddress))));
        if(eventStartBlock > 0) {
            newGroup.lastBlock = uint32(block.number);
        }

        groupNumberToCollection[newGroupNumber] = _collectionAddress;
        groupNumbers[_collectionAddress] = newGroupNumber;
        groupRecord[newGroupNumber] = newGroup;
        groupManager[newGroupNumber] = msg.sender;
        emit GroupRegistered(newGroupNumber, _collectionAddress, msg.sender);
    }

    /** Transfer management of a group to a new user
    *   Current group manager can transfer ownership anytime
    */
    function transferGroupManagement(address _collectionAddress, address _newManager) external {
        uint256 _groupNumber = groupNumbers[_collectionAddress];
        require(groupManager[_groupNumber] == msg.sender);
        groupManager[_groupNumber] = _newManager;
        emit GroupTransferred(_groupNumber, _collectionAddress, _newManager);
    }

    /** MINTING FUNCTIONS
    */
    function setMintingVariables(bool _groupOpen, bool _publicOpen, uint32 _maxPerWalletPerGroup, uint32 _maxPerGroup) external onlyOwner {
        groupRegistrationOpen = _groupOpen;
        publicMintOpen = _publicOpen;
        maxPerWalletPerGroup = _maxPerWalletPerGroup;
        maxPerGroup = _maxPerGroup;
    }

    function getCurrentRegistrationCost() external view returns (uint256) {
        if(eventStartBlock > 0) {
            uint256 _currentDay = this.currentDay();
            if(_currentDay == MAX_DAY) {
                return 5000 ether;
            } else {
                return address(this).balance * 50 / 100 / (MAX_DAY - _currentDay);
            }
        } else {
            return 0;
        }
    }

    function mintInner(address _to, address _collectionAddress, address _onBehalfOf) internal {
        uint256 tokenId = totalSupply() + 1;
        require(tokenId <= MAX_SUPPLY);

        uint32 _groupNumber = uint32(groupNumbers[_collectionAddress]);
        require((groupRegistrationOpen && _groupNumber > 0) || publicMintOpen);

        uint256 mintKey = (uint256(uint160(_onBehalfOf)) << 32) + _groupNumber;
        uint256 currentCount = mintCount[mintKey];
        require(currentCount + 1 <= maxPerWalletPerGroup);

        uint256 _eventStartBlock = eventStartBlock;
        IndividualData memory individual;
        individual.individualSeed = uint32(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, mintKey))));
        if(_eventStartBlock > 0) {
            individual.lastBlock = uint32(block.number);
            individual.lastScore = this.currentInfectionProgress() * 110 / 100;
            require(msg.value >= this.getCurrentRegistrationCost());
        }
        if(_groupNumber > 0) {
            require(IERC721(_collectionAddress).balanceOf(_onBehalfOf) > 0);
            GroupData memory group = groupRecord[_groupNumber];
            group.totalMembers = group.totalMembers + 1;
            require(group.totalMembers <= maxPerGroup);
            if(_eventStartBlock > 0) {
                group.lastScore = this.getGroupScore(_groupNumber);
                group.lastBlock = uint32(block.number);
            }
            individual.groupNumber = _groupNumber;
            groupRecord[_groupNumber] = group;
        }

        _safeMint(_to, 1);
        mintCount[mintKey] = currentCount + 1;
        individualRecord[tokenId] = individual;
    }

    function delegateMint(address _collectionAddress, address _onBehalfOf) external payable {
        require(delegateCash.checkDelegateForAll(msg.sender, _onBehalfOf) || delegateCash.checkDelegateForContract(msg.sender, _onBehalfOf, _collectionAddress));
        mintInner(msg.sender, _collectionAddress, _onBehalfOf);
    }

    function mintIndividual() external payable {
        mintInner(msg.sender, address(0x0), msg.sender);
    }

    function mintToGroup(address _collectionAddress) external payable {
        mintInner(msg.sender, _collectionAddress, msg.sender);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setPlaceholderURI(string calldata placeholderURI) external onlyOwner {
        _placeholderURI = placeholderURI;
    }

    function setContractURI(string calldata newContractURI) external onlyOwner {
        _contractURI = newContractURI;
    }

    function setIncludeStatsInURI(bool _stats) external onlyOwner {
        includeStatsInURI = _stats;
    }

    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId));

        if (eventStartTime == 0) {
            return _placeholderURI;
        }

        string memory baseURI = _baseTokenURI;
        string memory infectionStatus = 'H';
        if(this.getIndividualScore(tokenId) < this.currentInfectionProgress()) { infectionStatus = 'Z'; }
        if(includeStatsInURI) {
            uint32 individualLuck = this.getIndividualLuck(tokenId);
            uint32 individualRate = this.getIndividualRate(tokenId,true);
            return bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, infectionStatus, _toString(tokenId), TOKEN_URI_SEPARATOR, _toString(individualRate), TOKEN_URI_SEPARATOR, _toString(individualLuck)))
                : "";
        } else {
            return bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, infectionStatus, _toString(tokenId)))
                : "";
        }
    }

    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                if (ownerOf(i) == owner) {
                    uint256 _individualScore = this.getIndividualScore(i);
                    tokenIds[tokenIdsIdx++] = (i<<32)+_individualScore;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IWETH {
    function balanceOf(address src) external view returns (uint);
    function allowance(address src, address guy) external view returns (uint);
    function deposit() external payable;
    function withdraw(uint wad) external;
    function totalSupply() external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Bypass for a `--via-ir` bug (https://github.com/chiru-labs/ERC721A/pull/364).
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public payable virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                // The `iszero(eq(,))` check ensures that large values of `quantity`
                // that overflows uint256 will make the loop run out of gas.
                // The compiler will optimize the `iszero` away for performance.
                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external payable;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
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