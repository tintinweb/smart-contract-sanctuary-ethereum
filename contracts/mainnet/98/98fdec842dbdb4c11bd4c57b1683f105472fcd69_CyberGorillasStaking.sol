// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./CyberGorillas.sol";
import "./GrillaToken.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./RewardBoostProvider.sol";
import "./Ownable.sol";

/*
   ______      __              ______           _ ____          
  / ____/_  __/ /_  ___  _____/ ____/___  _____(_) / /___ ______
 / /   / / / / __ \/ _ \/ ___/ / __/ __ \/ ___/ / / / __ `/ ___/
/ /___/ /_/ / /_/ /  __/ /  / /_/ / /_/ / /  / / / / /_/ (__  ) 
\____/\__, /_.___/\___/_/   \____/\____/_/  /_/_/_/\__,_/____/  
     /____/                                                     

*/

/// @title Cyber Gorillas Staking
/// @author delta devs (https://twitter.com/deltadevelopers)
contract CyberGorillasStaking is Ownable {
    /*///////////////////////////////////////////////////////////////
                        CONTRACT STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice An instance of the GRILLA token, paid out as staking reward.
    GrillaToken public rewardsToken;
    /// @notice An ERC721 instance of the Cyber Gorillas contract.
    ERC721 public gorillaContract;

    /// @notice An address slot for a future contract to allow users to withdraw their rewards from multiple staking contracts in one call.
    address public rewardAggregator;

    /// @notice The reward rate for staking a regular gorilla.
    /// @dev The reward rate is fixed to 10 * 1E18 GRILLA every 86400 seconds, 1157407407407400 per second.
    uint256 constant normalRate = (100 * 1E18) / uint256(1 days);

    /// @notice The reward rate for staking a genesis gorilla.
    /// @dev The reward rate is fixed to 15 * 1E18 GRILLA every 86400 seconds, 1736111111111110 per second.
    uint256 constant genesisRate = (150 * 1E18) / uint256(1 days);

    /*///////////////////////////////////////////////////////////////
                    GORILLA METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Keeps track of which gorilla's have the genesis trait.
    mapping(uint256 => bool) private genesisTokens;
    /// @notice A list of reward boost providers.
    RewardBoostProvider[] rewardBoostProviders;

    /*///////////////////////////////////////////////////////////////
                        STAKING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the owner of the specified gorilla.
    mapping(uint256 => address) public tokenToAddr;
    /// @notice Returns the reward amount for the specified address.
    mapping(address => uint256) public rewards;
    /// @notice Returns the number of normal gorillas staked by specified address.
    mapping(address => uint256) public _balancesNormal;
    /// @notice Returns the number of genesis gorillas staked by specified address.
    mapping(address => uint256) public _balancesGenesis;
    /// @notice Returns the start time of staking rewards accumulation for a specified address.
    /// @dev The UNIX timestamp in seconds in which staking rewards were last claimed.
    /// This is later compared with block.timestamp to calculate the accumulated staking rewards.
    mapping(address => uint256) public _updateTimes;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _gorillaContract, address _rewardsToken) {
        gorillaContract = ERC721(_gorillaContract);
        rewardsToken = GrillaToken(_rewardsToken);
    }

    /*///////////////////////////////////////////////////////////////
                            SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the contract deployer to specify which gorillas are to be considered of type genesis.
    /// @param genesisIndexes An array of indexes specifying which gorillas are of type genesis.
    function uploadGenesisArray(uint256[] memory genesisIndexes)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < genesisIndexes.length; i++) {
            genesisTokens[genesisIndexes[i]] = true;
        }
    }

    /*///////////////////////////////////////////////////////////////
                                VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the accumulated staking rewards of the function caller.
    /// @return The amount of GRILLA earned while staking.
    function viewReward() public view returns (uint256) {
        return rewards[msg.sender] + rewardDifferential(msg.sender);
    }

    /// @notice Calculates the accumulated staking reward for the requested address.
    /// @param account The address of the staker.
    /// @return The amount of GRILLA earned while staking.
    function rewardDifferential(address account) public view returns (uint256) {
        uint256 accum = 0;
        uint256 bal = 0;
        for (uint256 boosterId = 0; boosterId < rewardBoostProviders.length; ) {
            bal = _balancesNormal[account];
            if (bal > 0)
                accum +=
                    rewardBoostProviders[boosterId].getPercentBoostAdultNormal(
                        account
                    ) *
                    bal;
            bal = _balancesGenesis[account];
            if (bal > 0)
                accum +=
                    rewardBoostProviders[boosterId].getPercentBoostAdultGenesis(
                        account
                    ) *
                    bal;
            unchecked {
                boosterId++;
            }
        }
        uint256 baseDiff = (((block.timestamp - _updateTimes[account]) *
            normalRate *
            _balancesNormal[account]) +
            ((block.timestamp - _updateTimes[account]) *
                genesisRate *
                _balancesGenesis[account]));
        return baseDiff + (baseDiff * accum) / 100;
    }

    /// @notice Returns true if gorilla has the genesis trait, false otherwise.
    /// @return Whether the requested gorilla has the genesis trait.
    function isGenesis(uint256 tokenId) private view returns (bool) {
        return genesisTokens[tokenId];
    }

    /// @notice Returns true if the requested address is staking at least one genesis gorilla, false otherwise.
    /// @return Whether the requested address is staking genesis gorillas.
    function isStakingGenesis(address account) public view returns (bool) {
        return _balancesGenesis[account] > 0;
    }

    /// @notice Returns true if the requested address is staking normal gorillas, false otherwise.
    /// @return Whether the requested address is staking normal gorillas.
    function isStakingNormal(address account) public view returns (bool) {
        return _balancesNormal[account] > 0;
    }

    /// @notice Modifier which updates the timestamp of when a staker last withdrew staking rewards.
    /// @param account The address of the staker.
    modifier updateReward(address account) {
        uint256 reward = rewardDifferential(account);
        _updateTimes[account] = block.timestamp;
        rewards[account] += reward;
        _;
    }

    /// @notice Sets the reward aggregator.
    /// @param _rewardAggregator The address of the reward aggregation contract.
    function setRewardAggregator(address _rewardAggregator) public onlyOwner {
        rewardAggregator = _rewardAggregator;
    }

    /// @notice Adds a reward booster.
    /// @param booster The address of the booster.
    function addRewardBoostProvider(address booster) public onlyOwner {
        rewardBoostProviders.push(RewardBoostProvider(booster));
    }

    /// @notice Remove a specific reward booster at a specific index.
    /// @param index Index of the booster to remove.
    function removeRewardBoostProvider(uint256 index) public onlyOwner {
        delete rewardBoostProviders[index];
    }

    /*///////////////////////////////////////////////////////////////
                            STAKING LOGIC
    //////////////////////////////////////////////////////////////*/

    // TODO: This function is only for testing, can be removed
    // REASONING: Nothing else calls it, and a user would not spend the gas
    //            necessary in order to updateReward()
    function earned(address account)
        public
        updateReward(account)
        returns (uint256)
    {
        return rewards[account];
    }

    /// @notice Allows a staker to withdraw their rewards.
    /// @return The amount of GRILLA earned from staking.
    function withdrawReward()
        public
        updateReward(msg.sender)
        returns (uint256)
    {
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        rewardsToken.stakerMint(msg.sender, reward);
        return reward;
    }

    /// @notice Allows a contract to withdraw the rewards on behalf of a user.
    /// @return The amount of GRILLA earned from staking.
    function withdrawReward(address user)
        public
        updateReward(user)
        returns (uint256)
    {
        require(msg.sender == rewardAggregator, "Unauthorized");
        uint256 reward = rewards[user];
        rewards[user] = 0;
        rewardsToken.stakerMint(user, reward);
        return reward;
    }

    /// @notice Allows a holder to stake a gorilla.
    /// @dev First checks whether the specified gorilla has the genesis trait. Updates balances accordingly.
    /// unchecked, because no arithmetic overflow is possible.
    /// @param _tokenId A specific gorilla, identified by its token ID.
    function stake(uint256 _tokenId) public updateReward(msg.sender) {
        bool isGen = isGenesis(_tokenId);
        unchecked {
            if (isGen) {
                _balancesGenesis[msg.sender]++;
            } else {
                _balancesNormal[msg.sender]++;
            }
        }
        tokenToAddr[_tokenId] = msg.sender;
        gorillaContract.transferFrom(msg.sender, address(this), _tokenId);
    }

    /// @notice Allows a staker to stake multiple gorillas at once.
    /// @param tokenIds An array of token IDs, representing multiple gorillas.
    function stakeMultiple(uint256[] memory tokenIds)
        public
        updateReward(msg.sender)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            stake(tokenIds[i]);
        }
    }

    /// @notice Allows a staker to unstake a staked gorilla.
    /// @param _tokenId A specific gorilla, identified by its token ID.
    function unstake(uint256 _tokenId) public updateReward(msg.sender) {
        require(tokenToAddr[_tokenId] == msg.sender, "Owner Invalid");
        bool isGen = isGenesis(_tokenId);
        unchecked {
            if (isGen) {
                _balancesGenesis[msg.sender]--;
            } else {
                _balancesNormal[msg.sender]--;
            }
        }
        delete tokenToAddr[_tokenId];
        gorillaContract.transferFrom(address(this), msg.sender, _tokenId);
    }

    /// @notice Allows a staker to unstake multiple gorillas at once.
    /// @param tokenIds An array of token IDs, representing multiple gorillas.
    function unstakeMultiple(uint256[] memory tokenIds)
        public
        updateReward(msg.sender)
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            unstake(tokenIds[i]);
        }
    }
}