// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/******************************************************************************\
* Staking contract for https://twitter.com/OccultTower
* Custom implementation of the StakingRewards contract by Synthetix.
* Can stake any NFT 721 and receive reward in any ERC20
/******************************************************************************/

import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ERC721Holder.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract Staker is ERC721Holder, ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    event PaymentReceived(address from, uint256 amount);

    bool public paused = true;
    uint16 public totalStake;
    uint16 public totalBurnt;
    uint16 public stakeCount;
    uint16 public burntCount;
    uint64 stakingDuration = 365 * 3 days;
    uint256 startPeriod;
    uint256 endPeriod;
    uint256 constant internal _precision = 1E18;
    mapping(address => uint256) userStartTime;
    mapping(address => uint256) rewards;
    mapping(address => uint16) burntBalance;
    mapping(address => uint16) stakedBalance;
    mapping(uint16 => address) stakedAssets;
    mapping(uint16 => address) burnt;
    mapping(address => uint16[]) userBurnt;
    mapping(address => uint16[]) userStaked;

    IERC721 public stakingToken721 = IERC721(0x73e6E8ef2F14878574D435B3c670275baabd9b88);
    IERC20 public stakingToken20 = IERC20(0xdD99df621625AE3f5B926392b09C16b21aA9a8Bd);

    constructor() payable {
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
    
    // pause staking
    function pause(bool _paused) public onlyOwner {
        if (_paused == false) {
            require(stakingToken20.balanceOf(address(this)) > 0,"Staking: missing reward token");

            if (startPeriod == 0) {
                startPeriod = block.timestamp;
                endPeriod = block.timestamp + stakingDuration;
            }
        }
        paused = _paused;
    }

    //block number when user started staking
    function userStart(address user) public view returns (uint256) {
        return (userStartTime[user]);
    }

    //number of rewards claimed for a user
    function userRewards(address user) public view returns (uint256) {
        return (rewards[user]);
    }

    //number of NFT staked by a user
    function userStakeBalance(address user) public view returns (uint256) {
        return (stakedBalance[user]);
    }

    //number of NFT burnt by a user
    function userBurntBalance(address user) public view returns (uint256) {
        return (burntBalance[user]);
    }

    //pending rewards that can be claimed by a user
    //function userPending(address user) public view returns (uint256) {
    function userPending(address user) public view returns (uint256) {
        return (_calculateRewards(user));
    }

    //show balance of token in contract
    function coinBalance() public view returns (uint256) {
        return stakingToken20.balanceOf(address(this));
    }

    //shows a list of burnt NFT of a user 
    function burntList(address user) public view returns (uint16[] memory ids) {
        return (userBurnt[user]);
    }

    //shows a list of NFT staked by a user
    function stakeList(address user) public view returns (uint16[] memory) {
        return (userStaked[user]);
    }

    function nftList(address user) public view returns (uint256 count, uint256[200] memory ownedList) {
        uint256 i;
        uint256 j;
        address nftOwner;
        uint256 ownerBalance;
        uint256[200] memory list;

        ownerBalance = stakingToken721.balanceOf(user);

        for (i = 0; i <= 7777; i += 1) {
            nftOwner = stakingToken721.ownerOf(i);
            if (nftOwner == user) {
                list[j] = i;
                j += 1;
                if (j == ownerBalance) {
                    break;
                }
            }
        }
        return (ownerBalance, list);
    }

    //allows user to burn a list of NFTs
    function burnNFT(uint16[] memory tokenIds) external nonReentrant {
        uint16 amount;
        bool newBurner;

        require(Address.isContract(msg.sender) == false, "Staking: no contracts");
        require(paused == false, "Staking: is paused");
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        require(stakingToken721.isApprovedForAll(msg.sender, address(this)) == true,
            "Staking: First must setApprovalForAll in the NFT to this contract");

        if (userBurnt[msg.sender].length == 0) {
            newBurner = true;
        }

        for (uint16 i = 0; i < tokenIds.length; i += 1) {
            require(stakingToken721.ownerOf(tokenIds[i]) == msg.sender, "Staking: not owner of NFT");

            // Increment the amount which will be staked
            amount += 1;
            // Save who is the staker/depositor of the token
            burnt[tokenIds[i]] = msg.sender;
            userBurnt[msg.sender].push(tokenIds[i]);

            // Transfer user's NFTs to the staking contract
            stakingToken721.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, tokenIds[i]);
        }
        burntBalance[msg.sender] += amount;
        totalBurnt += amount;

        if (amount > 0 && newBurner == true) {
            burntCount += 1;
        }

    }

    //allows admin to record a list of burnt NFT where the NFT was burnt without using this contract
	function addBurnt(address[] calldata users, uint16[] calldata ids) external onlyOwner {
        uint16 i;
        uint16 j;
        address old;
        bool newBurner;
        uint16 amount;

        require(users.length == ids.length, "Staking: The number of addresses is not matching the number of ids");

        for (i = 0; i < users.length; i++) {

            amount = 0;
            if (userBurnt[users[i]].length == 0) {
                newBurner = true;
            }

            require(stakingToken721.ownerOf(ids[i]) == 0x000000000000000000000000000000000000dEaD, "Staking: NFT must be burnt");

            if (burnt[ids[i]] == users[i]) {
                //skip as already recorded
            } else if (burnt[ids[i]] == address(0)) {
                //record burnt nft
                burnt[ids[i]] = users[i];
                userBurnt[users[i]].push(ids[i]);
                burntBalance[msg.sender] += 1;
                totalBurnt += 1;

                if (newBurner == true) {
                    burntCount += 1;
                    newBurner = false;
                }

            } else if (burnt[ids[i]] != users[i]) {
                //change address that burnt nft
                old = burnt[ids[i]];

                for (j = 0; j < userBurnt[old].length; j++) {
                    if (userBurnt[old][j] == ids[i]) {
                        userBurnt[old][j] = userBurnt[old][userBurnt[old].length-1];
                        userBurnt[old].pop();
                        burntBalance[old] -= 1;
                        break;
                    }
                }

                burnt[ids[i]] = users[i];
                userBurnt[users[i]].push(ids[i]);

                if (newBurner == true) {
                    burntCount += 1;
                    newBurner = false;
                }

                if (userBurnt[old].length == 0) {
                    burntCount -= 1;
                }
            }
        }
    }

    /// @notice Stakes user's NFTs
    /// @param tokenIds The tokenIds of the NFTs which will be staked
    function stake(uint16[] memory tokenIds) external nonReentrant {
        uint16 amount;
        bool newStaker;

        require(Address.isContract(msg.sender) == false, "Staking: no contracts");
        require(paused == false, "Staking: is paused");
        require(tokenIds.length != 0, "Staking: No tokenIds provided");

        require(stakingToken721.isApprovedForAll(msg.sender, address(this)) == true,
            "Staking: First must setApprovalForAll in the NFT to this contract");

        if (userStaked[msg.sender].length == 0) {
            newStaker = true;
        }

        for (uint16 i = 0; i < tokenIds.length; i += 1) {
            require(tokenIds[i] > 0, "Staking: does not support id 0");
            require(stakingToken721.ownerOf(tokenIds[i]) == msg.sender, "Staking: not owner of NFT");

            // Increment the amount which will be staked
            amount += 1;
            // Save who is the staker/depositor of the token
            stakedAssets[tokenIds[i]] = msg.sender;
            userStaked[msg.sender].push(tokenIds[i]);

            // Transfer user's NFTs to the staking contract
            stakingToken721.transferFrom(msg.sender, address(this), tokenIds[i]);
        }

        if (amount > 0 && newStaker == true) {
            stakeCount += 1;
        }

        stakedBalance[msg.sender] += amount;
        totalStake += amount;

        if (userStartTime[msg.sender] == 0) {
            userStartTime[msg.sender] = block.timestamp;
        }
    }

    /// @notice Withdraws a list of staked user's NFTs. If no list is provided it will unstake all.
    function withdraw(uint16[] memory tokenIds) external nonReentrant {
        uint16 i;
        uint16 j;
        uint16 clean;
        bool hasStake;
        bool cleaned;

        require(Address.isContract(msg.sender) == false, "Staking: no contracts");

        //claim reward
        _getReward();

        if (userStaked[msg.sender].length > 0) {
            hasStake = true;
        }

        if (tokenIds.length == 0) {
            //unstake all
            for (i = 0; i < userStaked[msg.sender].length; i += 1) {
                j = userStaked[msg.sender][i];
                if (j > 0) {
                    if (stakedAssets[j] == msg.sender) {
                        stakedAssets[j] = address(0);
                        totalStake -= 1;
                        userStaked[msg.sender][i] = 0;

                        if (stakingToken721.ownerOf(j) == address(this)) {
                            // Transfer user's NFTs back to user
                            stakingToken721.safeTransferFrom(address(this), msg.sender, j);
                        }
                    }
                }
            }
            stakedBalance[msg.sender] = 0;

        } else {
            //unstake chosen id
            for (i = 0; i < tokenIds.length; i += 1) {
                for (j = 0; j < userStaked[msg.sender].length; j += 1) {
                    if (userStaked[msg.sender][j] == tokenIds[i]) {
                        if (stakedAssets[tokenIds[i]] == msg.sender) {
                            stakedAssets[tokenIds[i]] = address(0);
                            totalStake -= 1;
                            stakedBalance[msg.sender] -= 1;
                            userStaked[msg.sender][j] = 0;

                            if (stakingToken721.ownerOf(tokenIds[i]) == address(this)) {
                                // Transfer user's NFTs back to user
                                stakingToken721.safeTransferFrom(address(this), msg.sender, tokenIds[i]);
                            }
                        }
                    }
                }
            }
        }

        //remove 0 ids
        cleaned = false;
        while (cleaned == false) {
            for (i = 0; i < userStaked[msg.sender].length; i += 1) {
                clean = 0;
                if (userStaked[msg.sender].length > 1) {
                    if (userStaked[msg.sender][i] == 0) {
                        userStaked[msg.sender][i] = userStaked[msg.sender][userStaked[msg.sender].length-1];
                        userStaked[msg.sender].pop();
                        clean += 1;
                        break;
                    }
                } else {
                    userStaked[msg.sender].pop();
                }
            }
            if (clean == 0) {
                cleaned = true;
            }
        }

        if (hasStake == true && userStaked[msg.sender].length == 0) {
            stakeCount -= 1;
        }
    }

    //user can claim reward
    function getReward() external nonReentrant {
        require(Address.isContract(msg.sender) == false, "Staking: No contracts");
        _getReward();
    }

    //code to claim reward
    function _getReward() internal {
        uint256 reward;

        // update the current reward balance
        _updateRewards();
        reward = rewards[msg.sender];

        //if token is running out then pay out the balance remaining
        if (reward > stakingToken20.balanceOf(address(this))) {
            reward = stakingToken20.balanceOf(address(this));
        }

        if (reward > 0) {
            SafeERC20.safeTransfer(stakingToken20, msg.sender, reward);
        }

        rewards[msg.sender] -= reward;
    }

    /**
     * @notice function that update pending rewards
     * and shift them to rewardsToClaim
     * @dev update rewards claimable
     * and check the time spent since deposit for the `msg.sender`
     */
    function _updateRewards() internal {

        rewards[msg.sender] = _calculateRewards(msg.sender);
        
        if (block.timestamp >= endPeriod) {
            userStartTime[msg.sender] = endPeriod;
        } else {
            userStartTime[msg.sender] = block.timestamp;
        }
    }

    /**
     * @notice calculate rewards based on the number of staked and burnt NFTs
     * @dev the higher is the precision and the more the time remaining will be precise
     * @param stakeHolder, address of the user to be checked
     * @return uint256 amount of claimable tokens of the specified address
     */
     
    //function _calculateRewards(address stakeHolder) internal view returns (uint256) {
    function _calculateRewards(address stakeHolder) internal view returns (uint256) {
        uint256 cal;
        uint256 totalStakeBonus;
        uint256 totalBurntCount;
        uint256 bonusPoolTokens;
        uint256 bonusPoolDailyDist;
        uint256 burntTokenCount;
        uint256 dailyTokenDist;
        uint256 stakingBonusCount;
        uint256 burntTokenMult;
        uint256 dailyBonusPoolDist;
        uint256 yearlyTokenDist;

        if (stakedBalance[stakeHolder] == 0 || burntBalance[stakeHolder] == 0 || startPeriod == 0) {
            cal = 0;
        } else {

            totalStakeBonus = _precision * (totalStake - stakeCount);
            totalBurntCount = _precision * (totalBurnt - burntCount);
            bonusPoolTokens = totalStakeBonus + totalBurntCount * 5 / 4;
            if (bonusPoolTokens == 0) {
                bonusPoolTokens = 1;
            }
            bonusPoolDailyDist = _precision * _precision * 2223 / bonusPoolTokens;
            burntTokenCount = burntBalance[stakeHolder] - 1;
            dailyTokenDist = _precision * (stakedBalance[stakeHolder] + burntTokenCount);
            stakingBonusCount = stakedBalance[stakeHolder] - 1;
            burntTokenMult = burntTokenCount * 5 / 4;
            dailyBonusPoolDist = (stakingBonusCount + burntTokenMult) * bonusPoolDailyDist;
            yearlyTokenDist = (dailyTokenDist + dailyBonusPoolDist) * 365;

            cal = yearlyTokenDist * _percentageTimeRemaining(stakeHolder) * (stakingDuration / 365 days) / _precision;
        }

        return (cal + rewards[stakeHolder]);
    }

    /**
     * @notice function that returns the remaining time in seconds of the staking period
     * @dev the higher is the precision and the more the time remaining will be precise
     * @param stakeHolder, address of the user to be checked
     * @return uint256 percentage of time remaining * precision
     */
    function _percentageTimeRemaining(address stakeHolder) internal view returns (uint256) {
        uint256 startTime;
        uint256 timeRemaining;

        if (endPeriod > block.timestamp) {
            if (startPeriod > userStartTime[stakeHolder]) {
                startTime = startPeriod;
            } else {
                startTime = userStartTime[stakeHolder];
            }

            timeRemaining = stakingDuration - (block.timestamp - startTime);
            return (_precision * (stakingDuration - timeRemaining)) / stakingDuration;
        } else {

            if (startPeriod > userStartTime[stakeHolder]) {
                startTime = 0;
            } else {
                startTime = stakingDuration - (endPeriod - userStartTime[stakeHolder]);
            }
            return ((_precision * (stakingDuration - startTime)) / stakingDuration);
        }
    }
}