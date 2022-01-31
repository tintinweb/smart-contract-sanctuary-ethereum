pragma solidity 0.8.11;

// SPDX-License-Identifier: MIT

import "./IContract.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";

contract Clover_Seeds_Stake is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 public CloverFieldCarbonRewardRate = 4e20;
    uint256 public CloverFieldPearlRewardRate = 5e20;
    uint256 public CloverFieldRubyRewardRate = 6e20;
    uint256 public CloverFieldDiamondRewardRate = 15e20;

    uint256 public CloverYardCarbonRewardRate = 2e19;
    uint256 public CloverYardPearlRewardRate = 25e18;
    uint256 public CloverYardRubyRewardRate = 3e19;
    uint256 public CloverYardDiamondRewardRate = 6e19;

    uint256 public CloverPotCarbonRewardRate = 1e18;
    uint256 public CloverPotPearlRewardRate = 15e17;
    uint256 public CloverPotRubyRewardRate = 2e18;
    uint256 public CloverPotDiamondRewardRate = 4e18;

    uint256 public rewardInterval = 1 days;
    uint256 public teamFee = 1000;
    uint256 public totalClaimedRewards;
    uint256 public teamFeeTotal;
    uint256 public waterInterval = 2 days;

    address public Seeds_Token;
    address public Seeds_NFT_Token;
    address public Clover_Seeds_Controller;
    address public Clover_Seeds_Picker;
    address public teamWallet;
    
    bool public isStakingEnabled = false;
    bool public isTeamFeeActiveted = false;
    bool public canClaimReward = false;

    address[] public CloverField;

    address[] public CloverYard;

    address[] public CloverPot;

    EnumerableSet.AddressSet private holders;

    mapping (address => uint256) public depositedCloverFieldCarbon;
    mapping (address => uint256) public depositedCloverFieldPearl;
    mapping (address => uint256) public depositedCloverFieldRuby;
    mapping (address => uint256) public depositedCloverFieldDiamond;

    mapping (address => uint256) public depositedCloverYardCarbon;
    mapping (address => uint256) public depositedCloverYardPearl;
    mapping (address => uint256) public depositedCloverYardRuby;
    mapping (address => uint256) public depositedCloverYardDiamond;

    mapping (address => uint256) public depositedCloverPotCarbon;
    mapping (address => uint256) public depositedCloverPotPearl;
    mapping (address => uint256) public depositedCloverPotRuby;
    mapping (address => uint256) public depositedCloverPotDiamond;
    
    mapping (address => uint256) public stakingTime;
    mapping (address => uint256) public totalDepositedTokens;
    mapping (address => uint256) public totalEarnedTokens;
    mapping (address => uint256) public lastClaimedTime;
    mapping (address => uint256) public lastWatered;

    mapping(uint256 => address) private _owners;

    event RewardsTransferred(address holder, uint256 amount);

    constructor(address _teamWallet, address _Clover_Seeds_Picker, address _Seeds_Token, address _Seeds_NFT_Token, address _Clover_Seeds_Controller) {
        Clover_Seeds_Picker = _Clover_Seeds_Picker;
        Seeds_Token = _Seeds_Token;
        Seeds_NFT_Token = _Seeds_NFT_Token;
        Clover_Seeds_Controller = _Clover_Seeds_Controller;
        teamWallet = _teamWallet;

        CloverField.push(address(0));
        CloverYard.push(address(0));
        CloverPot.push(address(0));
    }

    function randomNumberForCloverField() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, CloverField)));
    }

    function getLuckyWalletForCloverField() public view returns (address) {
        uint256 luckyWallet = randomNumberForCloverField() % CloverField.length;
        return CloverField[luckyWallet];
    }

    function randomNumberForCloverYard() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, CloverYard)));
    }

    function getLuckyWalletForCloverYard() public view returns (address) {
        uint256 luckyWallet = randomNumberForCloverYard() % CloverYard.length;
        return CloverYard[luckyWallet];
    }

    function randomNumberForCloverPot() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, CloverPot)));
    }

    function getLuckyWalletForCloverPot() public view returns (address) {
        uint256 luckyWallet = randomNumberForCloverPot() % CloverPot.length;
        return CloverPot[luckyWallet];
    }

    function updateAccount(address account) private {
        uint256 _lasWatered = block.timestamp.sub(lastWatered[account]);
        uint256 pendingDivs = getPendingDivs(account);
        uint256 _teamFee = pendingDivs.mul(teamFee).div(1e4);
        uint256 afterFee = pendingDivs.sub(_teamFee);

        require(_lasWatered >= waterInterval, "Please give water your plant..");

        if (pendingDivs > 0 && !isTeamFeeActiveted) {
            require(IContract(Seeds_Token).transfer(account, pendingDivs), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(pendingDivs);
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }

        if (pendingDivs > 0 && isTeamFeeActiveted) {
            require(IContract(Seeds_Token).transfer(account, afterFee), "Could not transfer tokens.");
            require(IContract(Seeds_Token).transfer(account, teamFee), "Could not transfer tokens.");
            totalEarnedTokens[account] = totalEarnedTokens[account].add(afterFee);
            totalClaimedRewards = totalClaimedRewards.add(afterFee);
            emit RewardsTransferred(account, afterFee);
        }

        lastClaimedTime[account] = block.timestamp;
        water();
    }
    
    function getPendingDivs(address _holder) public view returns (uint256) {
        
        uint256 pendingDivs = getPendingDivsField(_holder)
        .add(getPendingDivsYard(_holder))
        .add(getPendingDivsPot(_holder));
            
        return pendingDivs;
    }
    
    function getNumberOfHolders() public view returns (uint256) {
        return holders.length();
    }
    
    function claimDivs() public {
        require(canClaimReward, "Please waite to enable this function..");
        updateAccount(msg.sender);
    }

    function updateRewardInterval(uint256 _sec) public onlyOwner {
        rewardInterval = _sec;
    }

    function updateCloverField_Carbon_Pearl_Ruby_Diamond_RewardRate(uint256 _carbon, uint256 _pearl, uint256 _ruby, uint256 _diamond) public onlyOwner {
        CloverFieldCarbonRewardRate = _carbon;
        CloverFieldPearlRewardRate = _pearl;
        CloverFieldRubyRewardRate = _ruby;
        CloverFieldDiamondRewardRate = _diamond;
    }

    function updateCloverYard_Carbon_Pearl_Ruby_Diamond_RewardRate(uint256 _carbon, uint256 _pearl, uint256 _ruby, uint256 _diamond) public onlyOwner {
        CloverYardCarbonRewardRate = _carbon;
        CloverYardPearlRewardRate = _pearl;
        CloverYardRubyRewardRate = _ruby;
        CloverYardDiamondRewardRate = _diamond;
    }

    function updateCloverPot_Carbon_Pearl_Ruby_Diamond_RewardRate(uint256 _carbon, uint256 _pearl, uint256 _ruby, uint256 _diamond) public onlyOwner {
        CloverPotCarbonRewardRate = _carbon;
        CloverPotPearlRewardRate = _pearl;
        CloverPotRubyRewardRate = _ruby;
        CloverPotDiamondRewardRate = _diamond;
    }

    function getCloverFieldCarbonReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverFieldCarbon = depositedCloverFieldCarbon[_holder];
        uint256 CloverFieldCarbonReward = cloverFieldCarbon.mul(CloverFieldCarbonRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverFieldCarbonReward;
    }

    function getCloverFieldPearlReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverFieldPearl = depositedCloverFieldPearl[_holder];
        uint256 CloverFieldPearlReward = cloverFieldPearl.mul(CloverFieldPearlRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverFieldPearlReward;
    }

    function getCloverFieldRubyReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverFieldRuby = depositedCloverFieldRuby[_holder];
        uint256 CloverFieldRubyReward = cloverFieldRuby.mul(CloverFieldRubyRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverFieldRubyReward;
    }

    function getCloverFieldDiamondReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverFieldDiamond = depositedCloverFieldDiamond[_holder];
        uint256 CloverFieldDiamondReward = cloverFieldDiamond.mul(CloverFieldDiamondRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverFieldDiamondReward;
    }

    function getCloverYardCarbonReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverYardCarbon = depositedCloverYardCarbon[_holder];
        uint256 CloverYardCarbonReward = cloverYardCarbon.mul(CloverYardCarbonRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverYardCarbonReward;
    }

    function getCloverYardPearlReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverYardPearl = depositedCloverYardPearl[_holder];
        uint256 CloverYardPearlReward = cloverYardPearl.mul(CloverYardPearlRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverYardPearlReward;
    }

    function getCloverYardRubyReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverYardRuby = depositedCloverYardRuby[_holder];
        uint256 CloverYardRubyReward = cloverYardRuby.mul(CloverYardRubyRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverYardRubyReward;
    }

    function getCloverYardDiamondReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverYardDiamond = depositedCloverYardDiamond[_holder];
        uint256 CloverYardDiamondReward = cloverYardDiamond.mul(CloverYardDiamondRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverYardDiamondReward;
    }

    function getCloverPotCarbonReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverPotCarbon = depositedCloverPotCarbon[_holder];
        uint256 CloverPotCarbonReward = cloverPotCarbon.mul(CloverPotCarbonRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverPotCarbonReward;
    }

    function getCloverPotPearlReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverPotPearl = depositedCloverPotPearl[_holder];
        uint256 CloverPotPearlReward = cloverPotPearl.mul(CloverPotPearlRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverPotPearlReward;
    }

    function getCloverPotRubyReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverPotRuby = depositedCloverPotRuby[_holder];
        uint256 CloverPotRubyReward = cloverPotRuby.mul(CloverPotRubyRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverPotRubyReward;
    }

    function getCloverPotDiamondReward(address _holder) private view returns (uint256) {
        if (!holders.contains(_holder)) return 0;
        if (totalDepositedTokens[_holder] == 0) return 0;

        uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 cloverPotDiamond = depositedCloverPotDiamond[_holder];
        uint256 CloverPotDiamondReward = cloverPotDiamond.mul(CloverPotDiamondRewardRate).div(rewardInterval).mul(timeDiff);

        return CloverPotDiamondReward;
    }
    
    function getPendingDivsField(address _holder) private view returns (uint256) {
        
        uint256 pendingDivs = getCloverFieldCarbonReward(_holder)
        .add(getCloverFieldPearlReward(_holder))
        .add(getCloverFieldRubyReward(_holder))
        .add(getCloverFieldDiamondReward(_holder));
            
        return pendingDivs;
    }
    
    function getPendingDivsYard(address _holder) private view returns (uint256) {
        
        uint256 pendingDivs = getCloverFieldCarbonReward(_holder)
        .add(getCloverYardPearlReward(_holder))
        .add(getCloverYardRubyReward(_holder))
        .add(getCloverYardDiamondReward(_holder));
            
        return pendingDivs;
    }
    
    function getPendingDivsPot(address _holder) private view returns (uint256) {
        
        uint256 pendingDivs = getCloverPotCarbonReward(_holder)
        .add(getCloverPotPearlReward(_holder))
        .add(getCloverPotRubyReward(_holder))
        .add(getCloverPotDiamondReward(_holder));
            
        return pendingDivs;
    }

    function stake(uint256[] memory tokenId) public {
        require(isStakingEnabled, "Staking is not activeted yet..");

        for (uint256 i = 0; i < tokenId.length; i++) {

            IContract(Seeds_NFT_Token).setApprovalForAll_(address(this));
            IContract(Seeds_NFT_Token).safeTransferFrom(msg.sender, address(this), tokenId[i]);

            if (tokenId[i] <= 3e3) {
                if (IContract(Clover_Seeds_Controller).isCloverFieldCarbon_(tokenId[i])) {
                    depositedCloverFieldCarbon[msg.sender] = depositedCloverFieldCarbon[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] <= 3e3) {
                if (IContract(Clover_Seeds_Controller).isCloverFieldPearl_(tokenId[i])) {
                    depositedCloverFieldPearl[msg.sender] = depositedCloverFieldPearl[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] <= 3e3) {
                if (IContract(Clover_Seeds_Controller).isCloverFieldRuby_(tokenId[i])) {
                    depositedCloverFieldRuby[msg.sender] = depositedCloverFieldRuby[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] <= 3e3) {
                if (IContract(Clover_Seeds_Controller).isCloverFieldDiamond_(tokenId[i])) {
                    depositedCloverFieldDiamond[msg.sender] = depositedCloverFieldDiamond[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] > 3e3 && tokenId[i] <= 33e3) {
                if (IContract(Clover_Seeds_Controller).isCloverYardCarbon_(tokenId[i])) {
                    depositedCloverYardCarbon[msg.sender] = depositedCloverYardCarbon[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] > 3e3 && tokenId[i] <= 33e3) {
                if (IContract(Clover_Seeds_Controller).isCloverYardPearl_(tokenId[i])) {
                    depositedCloverYardPearl[msg.sender] = depositedCloverYardPearl[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] > 3e3 && tokenId[i] <= 33e3) {
                if (IContract(Clover_Seeds_Controller).isCloverYardRuby_(tokenId[i])) {
                    depositedCloverYardRuby[msg.sender] = depositedCloverYardRuby[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] > 3e3 && tokenId[i] <= 33e3) {
                if (IContract(Clover_Seeds_Controller).isCloverYardDiamond_(tokenId[i])) {
                    depositedCloverYardDiamond[msg.sender] = depositedCloverYardDiamond[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] > 33e3 && tokenId[i] <= 333e3) {
                if (IContract(Clover_Seeds_Controller).isCloverPotCarbon_(tokenId[i])) {
                    depositedCloverPotCarbon[msg.sender] = depositedCloverPotCarbon[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] > 33e3 && tokenId[i] <= 333e3) {
                if (IContract(Clover_Seeds_Controller).isCloverPotPearl_(tokenId[i])) {
                    depositedCloverPotPearl[msg.sender] = depositedCloverPotPearl[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] > 33e3 && tokenId[i] <= 333e3) {
                if (IContract(Clover_Seeds_Controller).isCloverPotRuby_(tokenId[i])) {
                    depositedCloverPotRuby[msg.sender] = depositedCloverPotRuby[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] > 33e3 && tokenId[i] <= 333e3) {
                if (IContract(Clover_Seeds_Controller).isCloverPotDiamond_(tokenId[i])) {
                    depositedCloverPotDiamond[msg.sender] = depositedCloverPotDiamond[msg.sender].add(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].add(1);
                }
            }

            if (tokenId[i] > 0) {
                _owners[tokenId[i]] = msg.sender;
            }

            if (tokenId[i] <= 3e3) {
                CloverField.push(msg.sender);
            }

            if (tokenId[i] > 3e3 && tokenId[i] <= 33e3) {
                CloverYard.push(msg.sender);
            }

            if (tokenId[i] > 33e3 && tokenId[i] <= 333e3) {
                CloverPot.push(msg.sender);
            }
        }

        if (!holders.contains(msg.sender) && totalDepositedTokens[msg.sender] > 0) {
            holders.add(msg.sender);
            stakingTime[msg.sender] = block.timestamp;
        }
    }
    
    function unstake(uint256[] memory tokenId) public {
        require(totalDepositedTokens[msg.sender] > 0, "Controller: You don't have staked token..");
        
        updateAccount(msg.sender);

        for (uint256 i = 0; i < tokenId.length; i++) {
            
            if (tokenId[i] > 0) {
                IContract(Seeds_NFT_Token).safeTransferFrom(address(this), msg.sender, tokenId[i]);
            }

            if (tokenId[i] <= 3e3) {
                if (IContract(Clover_Seeds_Controller).isCloverFieldCarbon_(tokenId[i])) {
                    depositedCloverFieldCarbon[msg.sender] = depositedCloverFieldCarbon[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] <= 3e3) {
                if (IContract(Clover_Seeds_Controller).isCloverFieldPearl_(tokenId[i])) {
                    depositedCloverFieldPearl[msg.sender] = depositedCloverFieldPearl[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] <= 3e3) {
                if (IContract(Clover_Seeds_Controller).isCloverFieldRuby_(tokenId[i])) {
                    depositedCloverFieldRuby[msg.sender] = depositedCloverFieldRuby[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] <= 3e3) {
                if (IContract(Clover_Seeds_Controller).isCloverFieldDiamond_(tokenId[i])) {
                    depositedCloverFieldDiamond[msg.sender] = depositedCloverFieldDiamond[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] > 3e3 && tokenId[i] <= 33e3) {
                if (IContract(Clover_Seeds_Controller).isCloverYardCarbon_(tokenId[i])) {
                    depositedCloverYardCarbon[msg.sender] = depositedCloverYardCarbon[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] > 3e3 && tokenId[i] <= 33e3) {
                if (IContract(Clover_Seeds_Controller).isCloverYardPearl_(tokenId[i])) {
                    depositedCloverYardPearl[msg.sender] = depositedCloverYardPearl[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] > 3e3 && tokenId[i] <= 33e3) {
                if (IContract(Clover_Seeds_Controller).isCloverYardRuby_(tokenId[i])) {
                    depositedCloverYardRuby[msg.sender] = depositedCloverYardRuby[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] > 3e3 && tokenId[i] <= 33e3) {
                if (IContract(Clover_Seeds_Controller).isCloverYardDiamond_(tokenId[i])) {
                    depositedCloverYardDiamond[msg.sender] = depositedCloverYardDiamond[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] > 33e3 && tokenId[i] <= 333e3) {
                if (IContract(Clover_Seeds_Controller).isCloverPotCarbon_(tokenId[i])) {
                    depositedCloverPotCarbon[msg.sender] = depositedCloverPotCarbon[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] > 33e3 && tokenId[i] <= 333e3) {
                if (IContract(Clover_Seeds_Controller).isCloverPotPearl_(tokenId[i])) {
                    depositedCloverPotPearl[msg.sender] = depositedCloverPotPearl[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] > 33e3 && tokenId[i] <= 333e3) {
                if (IContract(Clover_Seeds_Controller).isCloverPotRuby_(tokenId[i])) {
                    depositedCloverPotRuby[msg.sender] = depositedCloverPotRuby[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] > 33e3 && tokenId[i] <= 333e3) {
                if (IContract(Clover_Seeds_Controller).isCloverPotDiamond_(tokenId[i])) {
                    depositedCloverPotDiamond[msg.sender] = depositedCloverPotDiamond[msg.sender].sub(1);
                    totalDepositedTokens[msg.sender] = totalDepositedTokens[msg.sender].sub(1);
                }
            }

            if (tokenId[i] > 0) {
                _owners[tokenId[i]] = msg.sender;
            }
        }
        
        if (holders.contains(msg.sender) && totalDepositedTokens[msg.sender] == 0) {
            holders.remove(msg.sender);
        }
    }

    function water() public {
        lastWatered[msg.sender] = block.timestamp;
    }

    function updateWaterInterval(uint256 sec) public onlyOwner {
        waterInterval = sec;
    }
    
    function enableStaking() public onlyOwner {
        isStakingEnabled = true;
    }
    
    function enableClaimFunction() public onlyOwner {
        canClaimReward = true;
    }

    function disableStaking() public onlyOwner {
        isStakingEnabled = false;
    }
    
    function enableTeamFee() public onlyOwner {
        isTeamFeeActiveted = true;
    }

    function disableTeamFee() public onlyOwner {
        isTeamFeeActiveted = false;
    }

    function setClover_Seeds_Picker(address _Clover_Seeds_Picker) public onlyOwner {
        Clover_Seeds_Picker = _Clover_Seeds_Picker;
    }

    function set_Seed_Controller(address _wallet) public onlyOwner {
        Clover_Seeds_Controller = _wallet;
    }

    function set_Seeds_Token(address SeedsToken) public onlyOwner {
        Seeds_Token = SeedsToken;
    }

    function set_Seeds_NFT_Token(address nftToken) public onlyOwner {
        Seeds_NFT_Token = nftToken;
    }
}