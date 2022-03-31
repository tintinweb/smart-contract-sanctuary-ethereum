// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

//Utilities
import "./interfaces/IUnipilotFarm.sol";
import "./helper/ReentrancyGuard.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

// openzeppelin helpers
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/// @title Unipilot Farm
/// @author @UnipilotDev
/// @notice Contract for staking Unipilot v2 lp's in farm and earn rewards

contract UnipilotFarm is IUnipilotFarm, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address private immutable pilot;

    address public governance;
    uint256 public rewardPerBlock;
    uint256 private totalVaults;
    uint256 public farmingGrowthBlockLimit;

    mapping(uint256 => address) private vaults;

    /// @notice contains the vault data for each vault being operated in the farm
    mapping(address => VaultInfo) public vaultInfo;

    /// @notice contains the vault alt data for each vault being operated in the farm
    mapping(address => AltInfo) public vaultAltInfo;

    /// @notice contains the data for each user who are involved in the vaults farm
    mapping(address => mapping(address => UserInfo)) public userInfo;

    /// @notice contains the vaults which are active(whitelist == true)
    mapping(address => bool) public vaultWhitelist;

    constructor(
        address _governance,
        address _pilot,
        uint256 _rewardPerBlock
    ) {
        require(_governance != address(0) && _pilot != address(0), "ZA");
        require(_rewardPerBlock > 0, "IV");
        governance = _governance;
        pilot = _pilot;
        rewardPerBlock = _rewardPerBlock;
    }

    receive() external payable {}

    fallback() external payable {}

    modifier onlyGovernance() {
        require(msg.sender == governance, "NA");
        _;
    }

    /// @notice use to whitelist the vault. If the vault is being
    /// added for the first time it is added to the vault mapping
    /// @dev only called by governance
    /// @param _vault list of vaults to be add in farm
    /// @param _multiplier multiplier w.r.t vault index
    function initializer(
        address[] calldata _vault,
        uint256[] calldata _multiplier,
        RewardType[] calldata _rewardType,
        address[] calldata _rewardToken
    ) external override onlyGovernance {
        require(
            _vault.length == _multiplier.length &&
                _vault.length == _rewardType.length &&
                _vault.length == _rewardToken.length,
            "LNS"
        );

        uint256 blockNum = block.number;
        for (uint256 i = 0; i < _vault.length; i++) {
            require(
                _vault[i] != address(0) &&
                    _rewardToken[i] != address(0) &&
                    _multiplier[i] > 0,
                "IV"
            );
            require(
                IERC20(_rewardToken[i]).balanceOf(address(this)) > 0,
                "NEB"
            );

            VaultInfo storage vaultState = vaultInfo[_vault[i]];
            AltInfo storage vaultAltState = vaultAltInfo[_vault[i]];

            if (!vaultWhitelist[_vault[i]] && vaultState.totalLpLocked == 0) {
                if (
                    _rewardType[i] == RewardType.Alt ||
                    _rewardType[i] == RewardType.Dual
                ) {
                    vaultAltState.multiplier = _multiplier[i];
                    vaultAltState.startBlock = blockNum;
                    vaultAltState.lastRewardBlock = blockNum;
                    vaultAltState.rewardToken = _rewardToken[i];
                }
                insertVault(_vault[i], _multiplier[i], _rewardType[i]);
                emit Vault(
                    _vault[i],
                    rewardPerBlock,
                    _multiplier[i],
                    blockNum,
                    _rewardType[i],
                    _rewardToken[i]
                );
            } else {
                require(!vaultWhitelist[_vault[i]], "AI");
                if (vaultState.reward == RewardType.Dual) {
                    vaultState.lastRewardBlock = blockNum;
                    vaultAltState.lastRewardBlock = blockNum;
                    vaultAltState.multiplier = _multiplier[i];
                    vaultState.multiplier = _multiplier[i];
                } else if (vaultState.reward == RewardType.Alt) {
                    vaultAltState.lastRewardBlock = blockNum;
                    vaultAltState.multiplier = _multiplier[i];
                } else {
                    vaultState.lastRewardBlock = blockNum;
                    vaultState.multiplier = _multiplier[i];
                }
            }
            vaultWhitelist[_vault[i]] = true;
            emit VaultWhitelistStatus(_vault[i], true);
        }
    }

    /// @notice Deposit your lp for the specified vaults in the Unipilot farm
    /// @param _vault vault address on which you want to farm
    /// @param _amount the amount of tokens you want to deposit
    function stakeLp(address _vault, uint256 _amount)
        external
        override
        nonReentrant
    {
        require(_vault != address(0) && _amount > 0, "IV");
        require(farmingGrowthBlockLimit == 0, "LA");
        require(vaultWhitelist[_vault], "TNL");
        address caller = msg.sender;
        require(IERC20(_vault).balanceOf(caller) >= _amount, "NEB");
        uint256 blockNum = block.number;
        bool flag;
        VaultInfo storage vaultState = vaultInfo[_vault];
        AltInfo storage vaultAltState = vaultAltInfo[_vault];
        UserInfo storage userState = userInfo[_vault][caller];

        (uint256 reward, uint256 altReward, , ) = currentReward(_vault, caller);
        if (reward > 0 || altReward > 0) {
            claimReward(_vault);
            flag = true;
        }
        if (!flag) {
            if (vaultState.lastRewardBlock != vaultState.startBlock) {
                uint256 blockDiff = blockNum.sub(vaultState.lastRewardBlock);
                vaultState.globalReward = getGlobalReward(
                    _vault,
                    blockDiff,
                    vaultState.multiplier,
                    vaultState.globalReward,
                    0
                );
            }
        }

        if (
            vaultState.reward == RewardType.Dual ||
            vaultState.reward == RewardType.Alt
        ) {
            updateAltState(_vault);
            vaultAltState.lastRewardBlock = blockNum;
        }

        vaultState.totalLpLocked = vaultState.totalLpLocked.add(_amount);

        userInfo[_vault][caller] = UserInfo({
            reward: vaultState.globalReward,
            altReward: vaultAltState.globalReward,
            lpLiquidity: userState.lpLiquidity.add(_amount),
            vault: _vault
        });

        IERC20(vaultState.stakingToken).safeTransferFrom(
            caller,
            address(this),
            _amount
        );

        if (
            vaultState.reward == RewardType.Dual ||
            vaultState.reward == RewardType.Pilot
        ) {
            vaultState.lastRewardBlock = blockNum;
        }
        emit Deposit(caller, _vault, _amount, vaultState.totalLpLocked);
    }

    /// @notice Withdraw your lp as well as the accumulated reward if
    /// any from the farm.
    /// @param _vault vault where to earn reward
    /// @param _amount the amount of tokens want to withdraw
    function unstakeLp(address _vault, uint256 _amount)
        external
        override
        nonReentrant
    {
        require(_vault != address(0) && _amount > 0, "IA");
        address caller = msg.sender;
        VaultInfo storage vaultState = vaultInfo[_vault];
        UserInfo storage userState = userInfo[_vault][caller];
        require(
            userState.lpLiquidity >= _amount &&
                vaultState.totalLpLocked >= _amount,
            "AGTL"
        );

        claimReward(_vault);

        vaultState.totalLpLocked = vaultState.totalLpLocked.sub(_amount);
        userState.lpLiquidity = userState.lpLiquidity.sub(_amount);

        IERC20(_vault).safeTransfer(caller, _amount);

        emit Withdraw(caller, _vault, _amount);

        if (vaultState.totalLpLocked == 0) {
            if (vaultState.reward == RewardType.Dual) {
                vaultState.startBlock = block.number;
                vaultState.lastRewardBlock = block.number;
                vaultState.globalReward = 0;

                AltInfo storage altState = vaultAltInfo[_vault];
                altState.startBlock = block.number;
                altState.lastRewardBlock = block.number;
                altState.globalReward = 0;
            } else if (vaultState.reward == RewardType.Alt) {
                AltInfo storage altState = vaultAltInfo[_vault];
                altState.startBlock = block.number;
                altState.lastRewardBlock = block.number;
                altState.globalReward = 0;
            } else {
                vaultState.startBlock = block.number;
                vaultState.lastRewardBlock = block.number;
                vaultState.globalReward = 0;
            }
        }

        if (userState.lpLiquidity == 0) {
            delete userInfo[_vault][caller];
        }
    }

    /// @notice Withdraw your accumulated rewards without withdrawing lp.
    /// @param _vault vault address from which you intend to claim the
    /// accumulated reward from
    /// @return reward of pilot for a particular user that was accumulated
    /// @return altReward of altToken for a particular user that was accumulated
    /// @return gr global reward
    /// @return altGr alt global reward
    function claimReward(address _vault)
        public
        returns (
            uint256 reward,
            uint256 altReward,
            uint256 gr,
            uint256 altGr
        )
    {
        require(_vault != address(0), "ZA");
        address caller = msg.sender;
        uint256 blocknum = block.number;
        VaultInfo storage vaultState = vaultInfo[_vault];
        AltInfo storage vaultAltState = vaultAltInfo[_vault];
        UserInfo storage userState = userInfo[_vault][caller];

        (reward, altReward, gr, altGr) = currentReward(_vault, caller);

        require(reward > 0 || altReward > 0, "RZ");
        if (vaultState.reward == RewardType.Dual) {
            if (altReward > 0) {
                userState.altReward = altGr;
                vaultAltState.globalReward = altGr;
                vaultAltState.lastRewardBlock = blocknum;
            }
            if (reward > 0) {
                userState.reward = gr;
                vaultState.globalReward = gr;
                vaultState.lastRewardBlock = blocknum;
            }
        } else if (vaultState.reward == RewardType.Alt) {
            if (altReward > 0) {
                userState.altReward = altGr;
                vaultAltState.globalReward = altGr;
                vaultAltState.lastRewardBlock = blocknum;
            }
            if (reward > 0) {
                userState.reward = vaultState.globalReward;
            }
        } else {
            if (reward > 0) {
                userState.reward = gr;
                vaultState.globalReward = gr;
                vaultState.lastRewardBlock = blocknum;
            }

            if (altReward > 0) {
                userState.altReward = vaultAltState.globalReward;
            }
        }
        if (altReward > 0) {
            emit Reward(vaultAltState.rewardToken, caller, _vault, altReward);
            IERC20(vaultAltState.rewardToken).safeTransfer(caller, altReward);
        }
        if (reward > 0) {
            emit Reward(pilot, caller, _vault, reward);
            IERC20(pilot).safeTransfer(caller, reward);
        }
    }

    /// @notice Blacklist the vaults which are already whitelisted.
    /// No famring allowed on blacklisted vaults
    /// @dev only called by governance
    /// @param _vaults list of vaults
    function blacklistVaults(address[] calldata _vaults)
        external
        override
        onlyGovernance
    {
        for (uint256 i = 0; i < _vaults.length; i++) {
            if (vaultInfo[_vaults[i]].reward == RewardType.Dual) {
                updateVaultState(_vaults[i]);
                updateAltState(_vaults[i]);
            } else if (vaultInfo[_vaults[i]].reward == RewardType.Alt) {
                updateAltState(_vaults[i]);
            } else {
                updateVaultState(_vaults[i]);
            }
            vaultWhitelist[_vaults[i]] = false;
            emit VaultWhitelistStatus(_vaults[i], false);
        }
    }

    /// @notice update the reward per block of the vaults
    /// @dev only called by governance
    /// @param _value of the reward to be set
    function updateRewardPerBlock(uint256 _value)
        external
        override
        onlyGovernance
    {
        require(_value > 0, "IV");
        address[] memory vaults = vaultListed();
        for (uint256 i = 0; i < vaults.length; i++) {
            if (vaultWhitelist[vaults[i]]) {
                if (vaultInfo[vaults[i]].totalLpLocked != 0) {
                    if (vaultInfo[vaults[i]].reward == RewardType.Dual) {
                        updateVaultState(vaults[i]);
                        updateAltState(vaults[i]);
                    } else if (vaultInfo[vaults[i]].reward == RewardType.Alt) {
                        updateAltState(vaults[i]);
                    } else {
                        updateVaultState(vaults[i]);
                    }
                }
            }
        }
        emit RewardPerBlock(rewardPerBlock, rewardPerBlock = _value);
    }

    /// @notice update multiplier of a particular vault
    /// @dev only called by governance
    /// @param _vault vault address for which you want to update multiplier
    /// @param _value value of multiplier
    function updateMultiplier(address _vault, uint256 _value)
        external
        override
        onlyGovernance
    {
        require(_vault != address(0) && _value > 0, "IV");
        require(
            vaultInfo[_vault].reward == RewardType.Pilot ||
                vaultInfo[_vault].reward == RewardType.Dual,
            "WM"
        );
        updateVaultState(_vault);
        emit Multiplier(
            _vault,
            pilot,
            vaultInfo[_vault].multiplier,
            vaultInfo[_vault].multiplier = _value
        );
    }

    /// @notice update alt multiplier of a particular vault
    /// @dev only called by governance
    /// @param _vault vault address for which you want to update multiplier
    /// @param _value value of multiplier
    function updateAltMultiplier(address _vault, uint256 _value)
        external
        override
        onlyGovernance
    {
        require(_vault != address(0) && _value > 0, "IV");
        require(
            vaultInfo[_vault].reward == RewardType.Alt ||
                vaultInfo[_vault].reward == RewardType.Dual,
            "WM"
        );
        updateAltState(_vault);
        emit Multiplier(
            _vault,
            vaultAltInfo[_vault].rewardToken,
            vaultAltInfo[_vault].multiplier,
            vaultAltInfo[_vault].multiplier = _value
        );
    }

    /// @notice update governance to a new address
    /// @dev only called by governance
    /// @param _newGovernance new address of governance
    function updateGovernance(address _newGovernance)
        external
        override
        onlyGovernance
    {
        require(_newGovernance != address(0), "IA");

        emit GovernanceUpdated(governance, governance = _newGovernance);
    }

    /// @notice loops through the vaults mapping and returns a formulated array of vaults
    /// @dev only called by governance
    function vaultListed() public view returns (address[] memory) {
        uint256 vaultsLength = totalVaults;
        require(vaultsLength > 0, "NPE");
        address[] memory vaultList = new address[](vaultsLength);
        for (uint256 i = 0; i < vaultsLength; i++) {
            vaultList[i] = vaults[i + 1];
        }
        return vaultList;
    }

    /// @notice update reward type of the vault to either PILOT | ALT | DUAL
    /// @dev only called by governance
    /// @param _vault vault address for which you want to update reward type
    /// @param _rewardType type to which you want to change the reward to
    /// @param _altToken token address in which you want to give alt rewards
    function updateRewardType(
        address _vault,
        RewardType _rewardType,
        address _altToken
    ) external override onlyGovernance {
        require(_vault != address(0) && _altToken != address(0), "NAZ");
        AltInfo storage altState = vaultAltInfo[_vault];
        VaultInfo storage vaultState = vaultInfo[_vault];
        uint256 blockNumber = block.number;

        if (RewardType.Alt == _rewardType || RewardType.Dual == _rewardType) {
            require(IERC20(_altToken).balanceOf(address(this)) > 0, "NEB");
            altState.rewardToken = _altToken;
        }

        if (vaultInfo[_vault].reward == RewardType.Alt) {
            vaultState.lastRewardBlock = blockNumber;
            if (_rewardType == RewardType.Pilot) {
                altState.startBlock = blockNumber;
                updateAltState(_vault);
            }
        } else if (vaultInfo[_vault].reward == RewardType.Dual) {
            if (_rewardType == RewardType.Alt) {
                if (vaultState.totalLpLocked > 0) {
                    vaultState.startBlock = blockNumber;
                }
                updateVaultState(_vault);
            } else {
                altState.startBlock = blockNumber;
                updateAltState(_vault);
            }
        } else {
            altState.lastRewardBlock = blockNumber;
            if (_rewardType == RewardType.Alt) {
                if (vaultState.totalLpLocked > 0) {
                    vaultState.startBlock = blockNumber;
                }
                updateVaultState(_vault);
            }
        }
        emit RewardStatus(
            _vault,
            vaultInfo[_vault].reward,
            vaultInfo[_vault].reward = _rewardType,
            _altToken
        );
    }

    /// @notice Migrate funds to Governance address or in new Contract
    /// @dev only governance can call this
    /// @param _receiver address of new contract or wallet address
    /// @param _tokenAddress address of token which want to migrate
    /// @param _amount withdraw that amount which are required
    function migrateFunds(
        address _receiver,
        address _tokenAddress,
        uint256 _amount
    ) external override onlyGovernance {
        require(_receiver != address(0) && _tokenAddress != address(0), "NAZ");
        require(_amount > 0, "IV");
        IERC20(_tokenAddress).safeTransfer(_receiver, _amount);
        emit MigrateFunds(_receiver, _tokenAddress, _amount);
    }

    /// @notice Used to stop staking Lps in contract after block limit
    function updateFarmingLimit(uint256 _blockNumber)
        external
        override
        onlyGovernance
    {
        require(_blockNumber == 0 || _blockNumber > block.number, "BSG");
        emit UpdateFarmingLimit(
            farmingGrowthBlockLimit,
            farmingGrowthBlockLimit = _blockNumber
        );
        updateLastBlock(_blockNumber);
    }

    /// @notice Withdraw your lp
    /// @param _vault vault from where lp's will be unstaked without reward
    function emergencyUnstakeLp(address _vault) external override nonReentrant {
        require(_vault != address(0), "IA");
        address caller = msg.sender;
        VaultInfo storage vaultState = vaultInfo[_vault];
        UserInfo memory userState = userInfo[_vault][caller];
        require(
            userState.lpLiquidity > 0 && vaultState.totalLpLocked > 0,
            "AGTL"
        );
        IERC20(_vault).safeTransfer(caller, userState.lpLiquidity);
        vaultState.totalLpLocked = vaultState.totalLpLocked.sub(
            userState.lpLiquidity
        );
        if (vaultState.totalLpLocked == 0) {
            if (vaultState.reward == RewardType.Dual) {
                vaultState.startBlock = block.number;
                vaultState.lastRewardBlock = block.number;
                vaultState.globalReward = 0;

                AltInfo storage altState = vaultAltInfo[_vault];
                altState.startBlock = block.number;
                altState.lastRewardBlock = block.number;
                altState.globalReward = 0;
            } else if (vaultState.reward == RewardType.Alt) {
                AltInfo storage altState = vaultAltInfo[_vault];
                altState.startBlock = block.number;
                altState.lastRewardBlock = block.number;
                altState.globalReward = 0;
            } else {
                vaultState.startBlock = block.number;
                vaultState.lastRewardBlock = block.number;
                vaultState.globalReward = 0;
            }
        }
        delete userInfo[_vault][caller];
    }

    ///@notice use to fetch reward of particular user in a vault
    ///@param _vault address of vault to query for
    ///@param _user address of user to query for
    function currentReward(address _vault, address _user)
        public
        view
        override
        returns (
            uint256 reward,
            uint256 altReward,
            uint256 gr,
            uint256 altGr
        )
    {
        //gas optimisation using store for 1 SLOAD rather then n number
        //of SLOADS per each struct value count
        VaultInfo storage vaultState = vaultInfo[_vault];
        UserInfo storage userState = userInfo[_vault][_user];

        if (vaultState.reward == RewardType.Dual) {
            gr = verifyLimit(_vault, Direction.Pilot);
            reward = gr.sub(userState.reward);
            reward = FullMath.mulDiv(reward, userState.lpLiquidity, 1e18);
            altGr = verifyLimit(_vault, Direction.Alt);
            altReward = altGr.sub(userState.altReward);
            altReward = FullMath.mulDiv(altReward, userState.lpLiquidity, 1e18);
        } else if (vaultState.reward == RewardType.Alt) {
            altGr = verifyLimit(_vault, Direction.Alt);
            altReward = altGr.sub(userState.altReward);
            altReward = FullMath.mulDiv(altReward, userState.lpLiquidity, 1e18);

            if (userState.reward < vaultState.globalReward) {
                reward = vaultState.globalReward.sub(userState.reward);
                reward = FullMath.mulDiv(reward, userState.lpLiquidity, 1e18);
            }
        } else {
            gr = verifyLimit(_vault, Direction.Pilot);
            reward = gr.sub(userState.reward);
            reward = FullMath.mulDiv(reward, userState.lpLiquidity, 1e18);

            if (userState.altReward < vaultAltInfo[_vault].globalReward) {
                AltInfo memory vaultAltState = vaultAltInfo[_vault];
                altReward = vaultAltState.globalReward.sub(userState.altReward);
                altReward = FullMath.mulDiv(
                    altReward,
                    userState.lpLiquidity,
                    1e18
                );
            }
        }
    }

    /// @notice update PoolInfo and AltInfo global rewards and lastRewardBlock
    /// @dev only called by governance
    function updateLastBlock(uint256 _blockNumber) private {
        address[] memory vaults = vaultListed();
        for (uint256 i = 0; i < totalVaults; i++) {
            if (vaultInfo[vaults[i]].reward == RewardType.Dual) {
                if (_blockNumber > 0) {
                    updateVaultState(vaults[i]);
                    updateAltState(vaults[i]);
                } else {
                    vaultInfo[vaults[i]].lastRewardBlock = block.number;
                    vaultAltInfo[vaults[i]].lastRewardBlock = block.number;
                }
            } else if (vaultInfo[vaults[i]].reward == RewardType.Alt) {
                if (_blockNumber > 0) {
                    updateAltState(vaults[i]);
                } else {
                    vaultAltInfo[vaults[i]].lastRewardBlock = block.number;
                }
            } else {
                if (_blockNumber > 0) {
                    updateVaultState(vaults[i]);
                } else {
                    vaultInfo[vaults[i]].lastRewardBlock = block.number;
                }
            }
        }
    }

    ///@notice use for reading global reward of Unipilot farm
    ///@param _vault address of vault
    ///@param _blockDiff difference of the blocks for which you want the global reward
    ///@param _multiplier multiplier of the vaults
    ///@param _lastGlobalReward last global reward that was calculated
    function getGlobalReward(
        address _vault,
        uint256 _blockDiff,
        uint256 _multiplier,
        uint256 _lastGlobalReward,
        uint24 _direction
    ) private view returns (uint256 _globalReward) {
        _globalReward = _direction == 0
            ? vaultInfo[_vault].globalReward
            : vaultAltInfo[_vault].globalReward;

        if (vaultWhitelist[_vault]) {
            if (vaultInfo[_vault].totalLpLocked > 0) {
                _globalReward = FullMath.mulDiv(
                    rewardPerBlock,
                    _multiplier,
                    1e18
                );

                _globalReward = FullMath
                    .mulDiv(
                        _blockDiff.mul(_globalReward),
                        1e18,
                        vaultInfo[_vault].totalLpLocked
                    )
                    .add(_lastGlobalReward);
            }
        }
    }

    ///@notice used to update vault states, call where required
    ///@param _vault address of the vault for which you want to update the state
    function updateVaultState(address _vault) private {
        VaultInfo storage vaultState = vaultInfo[_vault];
        if (vaultState.totalLpLocked > 0) {
            uint256 blockDiff = (block.number).sub(vaultState.lastRewardBlock);
            vaultState.globalReward = getGlobalReward(
                _vault,
                blockDiff,
                vaultState.multiplier,
                vaultState.globalReward,
                0
            );
            vaultState.lastRewardBlock = block.number;
        }
    }

    ///@notice update vault alt states, call where required
    ///@param _vault address of the vault for which you want to update the state
    function updateAltState(address _vault) private {
        AltInfo storage altState = vaultAltInfo[_vault];

        if (altState.lastRewardBlock != altState.startBlock) {
            uint256 blockDiff = (block.number).sub(altState.lastRewardBlock);
            altState.globalReward = getGlobalReward(
                _vault,
                blockDiff,
                altState.multiplier,
                altState.globalReward,
                1
            );
            altState.lastRewardBlock = block.number;
        }
    }

    ///@notice Add vault in Unipilot Farm called inside initializer
    ///@param _vault address of vault to add
    ///@param _multiplier value of multiplier to set for particular vault
    function insertVault(
        address _vault,
        uint256 _multiplier,
        RewardType _rewardType
    ) private {
        if (vaultInfo[_vault].startBlock == 0) {
            totalVaults++;
        }
        vaults[totalVaults] = _vault;
        vaultInfo[_vault] = VaultInfo({
            startBlock: block.number,
            globalReward: 0,
            lastRewardBlock: block.number,
            totalLpLocked: 0,
            multiplier: _multiplier,
            stakingToken: _vault,
            reward: _rewardType
        });
    }

    ///@notice check the limit to see if the farmingGrowthBlockLimit was crossed or not
    ///@param _vault address of vault
    ///@param _check enum value to check whether we want to verify Limit for Pilot or Alt
    function verifyLimit(address _vault, Direction _check)
        private
        view
        returns (uint256 globalReward)
    {
        Cache memory state;

        if (_check == Direction.Pilot) {
            VaultInfo storage vaultState = vaultInfo[_vault];
            state = Cache({
                globalReward: vaultState.globalReward,
                lastRewardBlock: vaultState.lastRewardBlock,
                multiplier: vaultState.multiplier,
                direction: 0
            });
        } else if (_check == Direction.Alt) {
            AltInfo storage vaultAltInfo = vaultAltInfo[_vault];
            state = Cache({
                globalReward: vaultAltInfo.globalReward,
                lastRewardBlock: vaultAltInfo.lastRewardBlock,
                multiplier: vaultAltInfo.multiplier,
                direction: 1
            });
        }

        if (
            state.lastRewardBlock < farmingGrowthBlockLimit &&
            block.number >= farmingGrowthBlockLimit
        ) {
            globalReward = getGlobalReward(
                _vault,
                farmingGrowthBlockLimit.sub(state.lastRewardBlock),
                state.multiplier,
                state.globalReward,
                state.direction
            );
        } else if (
            state.lastRewardBlock > farmingGrowthBlockLimit &&
            farmingGrowthBlockLimit > 0
        ) {
            globalReward = state.globalReward;
        } else {
            uint256 blockDifference = (block.number).sub(state.lastRewardBlock);
            globalReward = getGlobalReward(
                _vault,
                blockDifference,
                state.multiplier,
                state.globalReward,
                state.direction
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IUnipilotFarm {
    struct UserInfo {
        uint256 reward;
        uint256 altReward;
        uint256 lpLiquidity;
        address vault;
    }

    struct VaultInfo {
        uint256 startBlock;
        uint256 lastRewardBlock;
        uint256 globalReward;
        uint256 totalLpLocked;
        uint256 multiplier;
        address stakingToken;
        RewardType reward;
    }

    struct AltInfo {
        address rewardToken;
        uint256 startBlock;
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 multiplier;
    }

    struct Cache {
        uint256 globalReward;
        uint256 lastRewardBlock;
        uint256 multiplier;
        uint24 direction;
    }

    event Vault(
        address vault,
        uint256 rewardPerBlock,
        uint256 multiplier,
        uint256 lastRewardBlock,
        RewardType rewardType,
        address rewardToken
    );

    event RewardStatus(
        address vault,
        RewardType old,
        RewardType updated,
        address altToken
    );

    enum Direction {
        Pilot,
        Alt
    }

    enum RewardType {
        Pilot,
        Alt,
        Dual
    }

    event Deposit(
        address user,
        address vault,
        uint256 amount,
        uint256 totalLpLocked
    );

    event Withdraw(address user, address vault, uint256 amount);

    event Reward(address token, address user, address vault, uint256 reward);

    event Multiplier(
        address vault,
        address token,
        uint256 old,
        uint256 updated
    );

    event RewardPerBlock(uint256 old, uint256 updated);

    event VaultWhitelistStatus(address indexed _vault, bool status);

    event FarmingStatus(bool old, bool updated);

    event GovernanceUpdated(address old, address updated);

    event MigrateFunds(
        address newContract,
        address _tokenAddress,
        uint256 _amount
    );

    event UpdateFarmingLimit(uint256 old, uint256 updated);

    function initializer(
        address[] calldata _vault,
        uint256[] calldata _multiplier,
        RewardType[] calldata _rewardType,
        address[] calldata _rewardToken
    ) external;

    function blacklistVaults(address[] calldata _vault) external;

    function stakeLp(address vault, uint256 amount) external;

    function unstakeLp(address vault, uint256 amount) external;

    function emergencyUnstakeLp(address vault) external;

    function updateRewardPerBlock(uint256 value) external;

    function updateMultiplier(address vault, uint256 value) external;

    function updateAltMultiplier(address vault, uint256 value) external;

    function currentReward(address vault, address user)
        external
        view
        returns (
            uint256 reward,
            uint256 altReward,
            uint256 gr,
            uint256 altGr
        );

    function updateGovernance(address newGovernance) external;

    function updateRewardType(
        address _vault,
        RewardType _rewardType,
        address _altToken
    ) external;

    function migrateFunds(
        address _receiver,
        address _tokenAddress,
        uint256 _amount
    ) external;

    function updateFarmingLimit(uint256 _blockNumber) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract ReentrancyGuard {
    uint8 private _unlocked = 1;

    modifier nonReentrant() {
        require(_unlocked == 1, "ReentrancyGuard: reentrant call");
        _unlocked = 0;
        _;
        _unlocked = 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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