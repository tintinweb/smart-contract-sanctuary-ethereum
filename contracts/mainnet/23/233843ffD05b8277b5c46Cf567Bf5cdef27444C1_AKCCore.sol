// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AKCCore is Ownable, AccessControl, IERC721Receiver {

    /** 
     * @dev ROLES 
     */
    bytes32 public constant CREATOR_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CLAIMER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant MODIFIER_ROLE = keccak256("BURNER_ROLE");

    /** 
     * @dev CORE DATA STRUCTURES 
     */
    struct Tribe {
        uint256 createdAt;
        uint256 lastClaimedTimeStamp;
        uint256 spec;
    }

    struct TribeSpec {
        uint256 price;
        uint256 rps;
        string name;
    }    

    /** 
     * @dev TRACKING DATA 
     */
    mapping(address => uint256[]) public userToTribes;
    mapping(address => mapping(uint256 => uint256)) public userToEarnings;
    TribeSpec[] public tribeSpecs;

    /**
     * @dev CREATION LOGIC
     */
    uint256 maxBatchTribes = 50;

    /**
     * @dev AKC STAKING
     */
    IERC721 public akc;
    mapping(address => mapping(uint256 => uint256)) public userToAKC; // spec to akc id
    uint256 public akcStakeBoost = 8;
    uint256 public capsuleSpecId = 257;
    uint256 public capsuleEarnRate = 2 ether;

    /**
     * @dev AFFILIATE
     */
    uint256 public affiliatePercentage = 5;
    uint256 public affiliateKickback = 5;
    mapping(address => uint256) public userToAffiliateEarnings;
    

    /**
     * @dev EVENTS
     */
    event TribeCreated(address indexed owner, uint256 indexed tribeSpec);
    event ClaimedReward(address indexed owner, uint256 indexed reward);
    event StakeAKC(address indexed staker, uint256 indexed akc, uint256 indexed spec);
    event UnStakeAKC(address indexed staker, uint256 indexed akc, uint256 indexed spec);
    event CreateNewTribeSpecEvent(uint256 indexed price, uint256 indexed rps, string indexed name);
    event UpdateTribeSpecEvent(uint256 indexed price, uint256 indexed rps, string indexed name);
    event SuspendTribesOfUserEvent(address indexed user);

    event SetMaxBatchTribesEvent(uint256 indexed newBatch);
    event SetAkcStakeBoostEvent(uint256 indexed akcStakeBoost);

    constructor(
        uint256[] memory tribePrices,
        uint256[] memory tribeRPS,
        string[] memory names,
        address _akc
    ) {
        _setupRole(CREATOR_ROLE, msg.sender);
        _setupRole(CLAIMER_ROLE, msg.sender);
        _setupRole(MODIFIER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        require(tribePrices.length > 0, "HAVE TO SPECIFY INITIALIZER TRIBES");
        require(tribePrices.length == tribeRPS.length, "TRIBE PRICES MUST MATCH RPS");
        require(tribePrices.length == names.length, "TRIBE PRICES MUST MATCH NAMES");

        for (uint i = 0; i < tribePrices.length; i++) {
            uint256 price = tribePrices[i];
            uint256 rps = tribeRPS[i];
            string memory name = names[i];

            createNewTribeSpec(price, rps, name);          
        }

        akc = IERC721(_akc);
    }


    /** === CREATING === */


    function createSingleTribe(address newOwner, uint256 spec) 
        external 
        onlyRole(CREATOR_ROLE) {
            require(spec < tribeSpecs.length, "INVALID TRIBE SPEC");

            uint256 tribe = block.timestamp;
            tribe |= block.timestamp << 32;
            tribe |= spec << 64;

            userToTribes[newOwner].push(tribe);

            emit TribeCreated(newOwner, spec);
    }

    function createManyTribes(address[] calldata newOwners, uint256[] calldata specs)
        external 
        onlyRole(CREATOR_ROLE) {
            require(newOwners.length == specs.length, "NEWOWNERS MUST MATCH SPEC");
            require(newOwners.length < maxBatchTribes, "NEWOWNERS EXCEEDS MAX BATCH");

            for (uint i = 0; i < newOwners.length; i++) {
                address newOwner = newOwners[i];
                uint256 spec = specs[i];

                require(spec < tribeSpecs.length, "INVALID TRIBE SPEC");

                uint256 tribe = block.timestamp;
                tribe |= block.timestamp << 32;
                tribe |= spec << 64;

                userToTribes[newOwner].push(tribe);

                emit TribeCreated(newOwner, spec);
            }
        }


    /** === CLAIMING === */


    function claimRewardOfTribeByIndex(address tribeOwner, uint256 tribeIndex) 
        public
        onlyRole(CLAIMER_ROLE)
        returns(uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);
            uint256 lastClaimedTimeStamp = getLastClaimedTimeFromTribe(tribe);

            TribeSpec memory tribeSpec = tribeSpecs[spec];
            
            uint256 newTribe = getCreatedAtFromTribe(tribe);  
            newTribe |= block.timestamp << 32;
            newTribe |= spec << 64;
            userToTribes[tribeOwner][tribeIndex] = newTribe;

            uint256 interval = (block.timestamp - lastClaimedTimeStamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {
                uint256 stakeTime = getAkcTimestampFromAKCData(userToAKC[tribeOwner][spec]);
                akcBoost = stakeTime > lastClaimedTimeStamp ? 
                            (tribeSpec.rps * (block.timestamp - stakeTime) / 86400) * akcStakeBoost / 100 : 
                            reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;            
            if (interval / 86400 >= 90) {
                timeBoost = reward * 50 / 100;
            } else if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;

            userToEarnings[tribeOwner][spec] += reward;

            return reward;
        }
    
    function claimRewardFromCapsule(address tribeOwner)
        internal 
        returns (uint256) {
            uint256 capsuleData = userToAKC[tribeOwner][capsuleSpecId];
            if (capsuleData == 0) {
                return 0;
            }

            uint256 kongId = getAkcIdFromAKCData(capsuleData);
            uint256 lastClaimed = getAkcTimestampFromAKCData(capsuleData);
            uint256 interval = (block.timestamp - lastClaimed);
            uint256 reward = capsuleEarnRate * interval / 86400;

            uint256 newData = kongId;
            newData |= block.timestamp << 128;
            userToAKC[tribeOwner][capsuleSpecId] = newData;         

            return reward;
        }

    function claimAllRewards(address tribeOwner)
        external
        onlyRole(CLAIMER_ROLE)
        returns(uint256) {
            require(userToTribes[tribeOwner].length > 0 || userToAKC[tribeOwner][capsuleSpecId] != 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += claimRewardOfTribeByIndex(tribeOwner, i);
            }

            totalReward += claimRewardFromCapsule(tribeOwner);

            emit ClaimedReward(tribeOwner, totalReward);

            return totalReward;
        }


     /** === STAKING === */


     function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function stakeAKC(address staker, uint256 akcId, uint256 spec)
        external
        onlyRole(CLAIMER_ROLE) {
            require(spec < tribeSpecs.length || spec == capsuleSpecId, "SPEC OUT OF BOUNDS");
            require(userToAKC[staker][spec] == 0, "ANOTHER KONG ALREADY STAKED IN SPEC");
            require(getTotalTribesByspec(staker, spec) > 0 || spec == capsuleSpecId, "USER DOES NOT OWN SPEC");
            require(akc.ownerOf(akcId) == address(this), "KONG NOT TRANSFERED TO CONTRACT");

            uint256 data = akcId;
            data |= block.timestamp << 128;
            userToAKC[staker][spec] = data;            

            emit StakeAKC(staker, akcId, spec);
        }

    function unstakeAKC(address staker, uint256 akcId, uint256 spec)
        external
        onlyRole(CLAIMER_ROLE) {
            require(userToAKC[staker][spec] != 0, "NO KONG STAKED IN SPEC");
            require(akc.ownerOf(akcId) != address(this), "KONG STILL IN CONTRACT");

            uint256 akcFromData = getAkcIdFromAKCData(userToAKC[staker][spec]);
            require(akcFromData == akcId, "CANNOT UNSTAKE AKC YOU DON'T OWN");

            delete userToAKC[staker][spec];

            emit UnStakeAKC(staker, akcId, spec);   
        }
    

    /** === AFFILIATE === */


    function registerAffiliate(address affiliate, uint256 earned)
        external
        onlyRole(CLAIMER_ROLE) {
            uint256 affData = userToAffiliateEarnings[affiliate];            
            uint amount = getAmountOfAffiliatesFromAffiliate(affData);
            uint256 totalEarned = getEarnedFromAffiliate(affData);

            uint256 newData = (totalEarned + earned) / (10**14);
            newData |= (amount + 1) << 128;
            userToAffiliateEarnings[affiliate] = newData;
        }


    /** === GETTERS === */


    function getCreatedAtFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {
            return uint256(uint32(tribe));
        }
    
    function getLastClaimedTimeFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {
            return uint256(uint32(tribe >> 32));
        }
    
    function getSpecFromTribe(uint256 tribe)
        public
        pure
        returns(uint256) {
            return uint256(uint8(tribe >> 64));
        }

    function getAkcIdFromAKCData(uint256 akcData)
        public
        pure
        returns(uint256) {
            return uint256(uint128(akcData));
        }

    function getAkcTimestampFromAKCData(uint256 akcData)
        public
        pure
        returns(uint256) {
            return uint256(uint128(akcData >> 128));
        }
    
    function getEarnedFromAffiliate(uint256 affiliateData)
        public
        pure
        returns(uint256) {
            return uint256(uint128(affiliateData)) * (10 ** 14);
        }
        
    function getAmountOfAffiliatesFromAffiliate(uint256 affiliateData)
        public
        pure
        returns(uint256) {
            return uint256(uint128(affiliateData >> 128));
        }


    /** === VIEWING === */


    function getTribeAmount(address tribeOwner)
        external
        view
        returns(uint256) {
            return userToTribes[tribeOwner].length;
        }
    
    function getTribeSpecAmount()
        external
        view 
        returns(uint256) {
            return tribeSpecs.length;
        }

    function getTotalTribesByspec(address tribeOwner, uint256 spec)
        public
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            if (spec >= tribeSpecs.length) {
                return 0;
            }
            uint256 total = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                if (getSpecFromTribe(userToTribes[tribeOwner][i]) == spec) {
                    total++;
                }
            }

            return total;
        }
    
    function getTribeStructFromTribe(uint256 tribe) 
        public
        pure
        returns (Tribe memory _tribe) {
            _tribe.createdAt = getCreatedAtFromTribe(tribe);
            _tribe.lastClaimedTimeStamp = getLastClaimedTimeFromTribe(tribe);
            _tribe.spec = getSpecFromTribe(tribe);
        }
    
    function getLastClaimedOfUser(address tribeOwner)
        external
        view
        returns(uint256) {
            if (userToTribes[tribeOwner].length == 0) {
                return 0;
            } else {
                uint256 firstTribe = userToTribes[tribeOwner][0];
                return getLastClaimedTimeFromTribe(firstTribe);
            }
        }

    function getTribeAmountBySpec(address tribeOwner, uint256 spec) 
        external
        view
        returns(uint256) {
            require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");

            uint256 counter = 0;
            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                uint256 tribe = userToTribes[tribeOwner][i];
                uint256 tribeSpec = getSpecFromTribe(tribe);
                if (tribeSpec == spec) {
                    counter++;
                }
            }

            return counter;
        }

    function getTribeOfUserByIndexAndSpec(address tribeOwner, uint256 tribeIndex, uint256 spec)
        external
        view
        returns (Tribe memory) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");
            require(spec < tribeSpecs.length, "INVALID TRIBE SPEC");

            uint256 counter = 0;
            uint256 tribeInstance;
            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                uint256 tribe = userToTribes[tribeOwner][i];
                uint256 tribeSpec = getSpecFromTribe(tribe);
                if (tribeSpec == spec) {
                    if (counter == tribeIndex) {
                        tribeInstance = tribe;
                        break;
                    } else {
                        counter++;
                    }
                }
            }

            return getTribeStructFromTribe(tribeInstance);
        }

    function getTribeRewardByIndex(address tribeOwner, uint256 tribeIndex)
        public
        view
        returns (uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);
            uint256 lastClaimedTimeStamp = getLastClaimedTimeFromTribe(tribe);

            TribeSpec memory tribeSpec = tribeSpecs[spec];
                        
            uint256 interval = (block.timestamp - lastClaimedTimeStamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {
                uint256 stakeTime = getAkcTimestampFromAKCData(userToAKC[tribeOwner][spec]);
                akcBoost = stakeTime > lastClaimedTimeStamp ? 
                            (tribeSpec.rps * (block.timestamp - stakeTime) / 86400) * akcStakeBoost / 100 : 
                            reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;            
            if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;         

            return reward;
        }

    function getTribeRewardByIndexAndSpec(address tribeOwner, uint256 tribeIndex, uint256 targetSpec)
        public
        view
        returns (uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);

            if (spec != targetSpec)
                return 0;

            uint256 lastClaimedTimeStamp = getLastClaimedTimeFromTribe(tribe);

            TribeSpec memory tribeSpec = tribeSpecs[spec];
                       
            uint256 interval = (block.timestamp - lastClaimedTimeStamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {
                uint256 stakeTime = getAkcTimestampFromAKCData(userToAKC[tribeOwner][spec]);
                akcBoost = stakeTime > lastClaimedTimeStamp ? 
                            (tribeSpec.rps * (block.timestamp - stakeTime) / 86400) * akcStakeBoost / 100 : 
                            reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;            
            if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;

            return reward;
        }
    
    function getTribeRewardByIndexAndTimestamp(address tribeOwner, uint256 tribeIndex, uint256 timestamp)
        public
        view
        returns (uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);

            uint256 lastClaimedTimeStamp = getCreatedAtFromTribe(tribe);
            lastClaimedTimeStamp = lastClaimedTimeStamp > timestamp ? lastClaimedTimeStamp : timestamp;

            TribeSpec memory tribeSpec = tribeSpecs[spec];
                       
            uint256 interval = (block.timestamp - lastClaimedTimeStamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {
                uint256 stakeTime = getAkcTimestampFromAKCData(userToAKC[tribeOwner][spec]);
                akcBoost = stakeTime > lastClaimedTimeStamp ? 
                            (tribeSpec.rps * (block.timestamp - stakeTime) / 86400) * akcStakeBoost / 100 : 
                            reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;
            interval = block.timestamp - getLastClaimedTimeFromTribe(tribe);       
            if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;

            return reward;
        }

    function getTribeRewardByIndexAndTimestampDisregardCreate(address tribeOwner, uint256 tribeIndex, uint256 timestamp)
        public
        view
        returns (uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);
            uint256 lastClaimedTimeStamp = getLastClaimedTimeFromTribe(tribe);            

            TribeSpec memory tribeSpec = tribeSpecs[spec];
                       
            uint256 interval = (block.timestamp - timestamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {                
                akcBoost = reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;            
            interval = block.timestamp - lastClaimedTimeStamp;
            if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;

            return reward;
        }

    function getTribeRewardByIndexAndTimestampAndSpec(address tribeOwner, uint256 tribeIndex, uint256 timestamp, uint256 targetSpec)
        public
        view
        returns (uint256) {
            require(userToTribes[tribeOwner].length > tribeIndex, "TRIBE INDEX OUT OF BOUNDS");

            uint256 tribe = userToTribes[tribeOwner][tribeIndex];
            uint256 spec = getSpecFromTribe(tribe);

            if (spec != targetSpec)
                return 0;

            uint256 lastClaimedTimeStamp = getCreatedAtFromTribe(tribe);
            lastClaimedTimeStamp = lastClaimedTimeStamp > timestamp ? lastClaimedTimeStamp : timestamp;

            TribeSpec memory tribeSpec = tribeSpecs[spec];
                       
            uint256 interval = (block.timestamp - lastClaimedTimeStamp);
            uint256 reward = tribeSpec.rps * interval / 86400;

            uint256 akcBoost;
            if (userToAKC[tribeOwner][spec] != 0) {
                uint256 stakeTime = getAkcTimestampFromAKCData(userToAKC[tribeOwner][spec]);
                akcBoost = stakeTime > lastClaimedTimeStamp ? 
                            (tribeSpec.rps * (block.timestamp - stakeTime) / 86400) * akcStakeBoost / 100 : 
                            reward * akcStakeBoost / 100;
            }

            /// @dev Time BOOST
            uint256 timeBoost;     
            interval = block.timestamp - getLastClaimedTimeFromTribe(tribe);       
            if (interval / 86400 >= 60) {
                timeBoost = reward * 40 / 100;
            } else if (interval / 86400 >= 30) {
                timeBoost = reward * 25 / 100;
            } else if (interval / 86400 >= 14) {
                timeBoost = reward * 12 / 100;
            } else if (interval / 86400 >= 7) {
                timeBoost = reward * 5 / 100;
            } else if (interval / 86400 >= 3) {
                timeBoost = reward * 2 / 100;
            }

            reward = reward + akcBoost + timeBoost;

            return reward;
        }
    
    function getCapsuleRewards(address capsuleOwner, uint256 timestamp)
        public
        view
        returns(uint256) {
            uint256 capsuleData = userToAKC[capsuleOwner][capsuleSpecId];
            if (capsuleData == 0) {
                return 0;
            }
            
            uint256 lastClaimed = getAkcTimestampFromAKCData(capsuleData);
            if (timestamp != 0)
                lastClaimed = timestamp;
            uint256 interval = (block.timestamp - lastClaimed);
            uint256 reward = capsuleEarnRate * interval / 86400;               

            return reward;
        }
    
    function getAllRewards(address tribeOwner)
        external
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += getTribeRewardByIndex(tribeOwner, i);
            }

            totalReward += getCapsuleRewards(tribeOwner, 0);

            return totalReward;
        }

    function getAllRewardsBySpec(address tribeOwner, uint256 spec)
        external
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += getTribeRewardByIndexAndSpec(tribeOwner, i, spec);
            }

            return totalReward;
        }
    
    function getAllRewardsByTimestamp(address tribeOwner, uint256 timestamp)
        public
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += getTribeRewardByIndexAndTimestamp(tribeOwner, i, timestamp);
            }

            totalReward += getCapsuleRewards(tribeOwner, timestamp);

            return totalReward;
        }

    function getAllRewardsByTimestampDisregardCreate(address tribeOwner, uint256 timestamp)
        public
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += getTribeRewardByIndexAndTimestampDisregardCreate(tribeOwner, i, timestamp);
            }

            totalReward += getCapsuleRewards(tribeOwner, timestamp);

            return totalReward;
        }
        
    function getAllRewardsByTimestampAndSpec(address tribeOwner, uint256 timestamp, uint256 spec)
        external
        view
        returns(uint256) {
            //require(userToTribes[tribeOwner].length > 0, "USER DOESN'T OWN ANY TRIBES");
            uint256 totalReward = 0;

            for (uint i = 0; i < userToTribes[tribeOwner].length; i++) {
                totalReward += getTribeRewardByIndexAndTimestampAndSpec(tribeOwner, i, timestamp, spec);
            }

             return totalReward;
        }

    function getAllStakedKongsOfUser(address staker)
        external
        view
        returns(uint256[] memory) {
            uint256[] memory kongs = new uint256[](tribeSpecs.length);
            for (uint i = 0; i < tribeSpecs.length; i++) {
                uint data = userToAKC[staker][i];
                uint kong = getAkcIdFromAKCData(data);
                kongs[i] = kong;
            }
            return kongs;
        }
    
    function getAllRewardsOfUsersByTimestamp(address[] calldata wallets, uint256 timestamp)
        external
        view
        returns (uint256[] memory) {
            uint256[] memory rewards = new uint256[](wallets.length);
            for (uint i = 0; i < wallets.length; i++) {
                uint reward = getAllRewardsByTimestamp(wallets[i], timestamp);
                rewards[i] = reward;
            }
            return rewards;
        }

    function getDiscountFactor(address tribeOwner)
        external
        view
        returns(uint256) {
            uint256 discount;
            uint256 tribeAmount = userToTribes[tribeOwner].length;
            
            if (tribeAmount >= 50) {
                discount = 20;
            } else if (tribeAmount >= 20) {
                discount = 15;
            } else if (tribeAmount >= 15) {
                discount = 12;
            } else if (tribeAmount >= 10) {
                discount = 8;
            } else if (tribeAmount >= 5) {
                discount = 4;
            } else if (tribeAmount >= 2) {
                discount = 2;
            }
            
            return discount;
        }
    

    /** === MODIFIER ONLY === */


    function createNewTribeSpec(uint256 price, uint256 rps, string memory name)
        public
        onlyRole(MODIFIER_ROLE) {
            TribeSpec memory tribeSpec = TribeSpec({
                price: price,
                rps: rps,
                name: name
            });

            tribeSpecs.push(tribeSpec);

            emit CreateNewTribeSpecEvent(price, rps, name);
        }

    function updateTribeSpec(uint256 index, uint256 newPrice, uint256 newRps)
        external
        onlyRole(MODIFIER_ROLE) {
            require(index < tribeSpecs.length, "INDEX OUT OF BOUNDS");

            TribeSpec storage tribeSpec = tribeSpecs[index];
            tribeSpec.price = newPrice;
            tribeSpec.rps = newRps;

            emit UpdateTribeSpecEvent(newPrice, newRps, tribeSpec.name);
        }
    
    function suspendTribesOfUser(address tribeOwner) 
        external 
        onlyRole(MODIFIER_ROLE) {
            require(userToTribes[tribeOwner].length > 0, "USER HAS NO TRIBES");            
            delete userToTribes[tribeOwner];

            emit SuspendTribesOfUserEvent(tribeOwner);
        }
    
    function setMaxBatchTribes(uint256 newBatch)
        external 
        onlyRole(MODIFIER_ROLE) {
            maxBatchTribes = newBatch;

            emit SetMaxBatchTribesEvent(newBatch);
        }
    
    function setAKCStakingBoostPercentage(uint256 newPercentage)
        external
        onlyRole(MODIFIER_ROLE) {
            akcStakeBoost = newPercentage;

            emit SetAkcStakeBoostEvent(newPercentage);
        }
    
    function akcNFTApproveForAll(address approved, bool isApproved)
        external
        onlyRole(MODIFIER_ROLE) {
            akc.setApprovalForAll(approved, isApproved);
        }

    function setCapsuleEarnRate(uint256 newRate)
        external
        onlyRole(MODIFIER_ROLE) {
            capsuleEarnRate = newRate;
        }

    function setAffiliatePercentage(uint256 newPercentage)
        external
        onlyRole(MODIFIER_ROLE) {
            affiliatePercentage = newPercentage;
        }

    function setAffiliateKickBack(uint256 newKickback)
        external
        onlyRole(MODIFIER_ROLE) {
            affiliateKickback = newKickback;
        }
    
    function withdrawEth(uint256 percentage, address _to)
        external
        onlyOwner
    {
        payable(_to).transfer((address(this).balance * percentage) / 100);
    }

    function withdrawERC20(
        uint256 percentage,
        address _erc20Address,
        address _to
    ) external onlyOwner {
        uint256 amountERC20 = ERC20(_erc20Address).balanceOf(address(this));
        ERC20(_erc20Address).transfer(_to, (amountERC20 * percentage) / 100);
    }

    function withdrawStuckKong(uint256 kongId, address _to) external onlyOwner {
        require(akc.ownerOf(kongId) == address(this), "CORE DOES NOT OWN KONG");
        akc.transferFrom(address(this), _to, kongId);
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}