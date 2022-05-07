// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
      _____                   _______                   _____                    _____                    _____                    _____          
     |\    \                 /::\    \                 /\    \                  /\    \                  /\    \                  /\    \         
     |:\____\               /::::\    \               /::\    \                /::\    \                /::\    \                /::\    \        
     |::|   |              /::::::\    \             /::::\    \               \:::\    \              /::::\    \              /::::\    \       
     |::|   |             /::::::::\    \           /::::::\    \               \:::\    \            /::::::\    \            /::::::\    \      
     |::|   |            /:::/~~\:::\    \         /:::/\:::\    \               \:::\    \          /:::/\:::\    \          /:::/\:::\    \     
     |::|   |           /:::/    \:::\    \       /:::/  \:::\    \               \:::\    \        /:::/__\:::\    \        /:::/__\:::\    \    
     |::|   |          /:::/    / \:::\    \     /:::/    \:::\    \              /::::\    \      /::::\   \:::\    \       \:::\   \:::\    \   
     |::|___|______   /:::/____/   \:::\____\   /:::/    / \:::\    \    ____    /::::::\    \    /::::::\   \:::\    \    ___\:::\   \:::\    \  
     /::::::::\    \ |:::|    |     |:::|    | /:::/    /   \:::\ ___\  /\   \  /:::/\:::\    \  /:::/\:::\   \:::\    \  /\   \:::\   \:::\    \ 
    /::::::::::\____\|:::|____|     |:::|    |/:::/____/  ___\:::|    |/::\   \/:::/  \:::\____\/:::/__\:::\   \:::\____\/::\   \:::\   \:::\____\
   /:::/~~~~/~~       \:::\    \   /:::/    / \:::\    \ /\  /:::|____|\:::\  /:::/    \::/    /\:::\   \:::\   \::/    /\:::\   \:::\   \::/    /
  /:::/    /           \:::\    \ /:::/    /   \:::\    /::\ \::/    /  \:::\/:::/    / \/____/  \:::\   \:::\   \/____/  \:::\   \:::\   \/____/ 
 /:::/    /             \:::\    /:::/    /     \:::\   \:::\ \/____/    \::::::/    /            \:::\   \:::\    \       \:::\   \:::\    \     
/:::/    /               \:::\__/:::/    /       \:::\   \:::\____\       \::::/____/              \:::\   \:::\____\       \:::\   \:::\____\    
\::/    /                 \::::::::/    /         \:::\  /:::/    /        \:::\    \               \:::\   \::/    /        \:::\  /:::/    /    
 \/____/                   \::::::/    /           \:::\/:::/    /          \:::\    \               \:::\   \/____/          \:::\/:::/    /     
                            \::::/    /             \::::::/    /            \:::\    \               \:::\    \               \::::::/    /      
                             \::/____/               \::::/    /              \:::\____\               \:::\____\               \::::/    /       
                              ~~                      \::/____/                \::/    /                \::/    /                \::/    /        
                                                                                \/____/                  \/____/                  \/____/                                                                                                                                                                 
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract IYogies {
    function stakeYogie(uint256 yogieId, address sender) external {}
    function unstakeYogie(uint256 yogieId, address sender) external {}

    function vaultStartPoint() external view returns (uint256) {}
    function viyStartPoint() external view returns (uint256) {}

    function freeMint(bytes32[] calldata proof, address caller) external {}
    function nextYogieId() external view returns (uint256) {}
}

abstract contract IYogiesItems is IERC1155 {
    function car() external view returns(uint256) {}
    function house() external view returns (uint256) {}
}

abstract contract IGemies is IERC20 {
    function hasDebt(address user) external view returns (bool) {}
}

contract YogiesStaking is OwnableUpgradeable {
    
    /** === Yogies contracts === */

    IYogies public yogies;
    IYogies public gYogies;
    IGemies public gemies;

    /** === Staking core === */

    /// @dev Stores last action timestamp, reward per day, yogies staked and accumulated reward in single uint256
    /// - first 32 bits: last action timestamp
    /// - second 16 bits: total yogies staked
    /// - third 104 bits: total rewards per day the user earns
    /// - remaining 104 bits: accumulated gemies reward
    mapping(address => uint256) public yogiesStakeData;

    uint256 public yogieBaseType;
    uint256 public vaultYogieType;
    uint256 public viyYogieType;
    uint256 public gYogieType;

    mapping(uint256 => uint256) public yogieTypeToYield;

    mapping(uint256 => uint256) public carBonus; // maps car amount to bonus. Base 100
    uint256 public carBonusCap; // max car amount where bonus increase stops

    constructor(
        address _yogies,
        address _gYogies
        //address _gemies
    ) {}

    function initialize(
        address _yogies,
        address _gYogies
       // address _gemies
    ) public initializer {
        __Ownable_init();

        yogies = IYogies(_yogies);
        gYogies = IYogies(_gYogies);
        //gemies = IGemies(_gemies);

        carBonus[1] = 20;
        carBonus[2] = 35;
        carBonus[3] = 50;

        yogieTypeToYield[0] = 10 ether; // normal yogie
        yogieTypeToYield[1] = 15 ether; // vault yogie
        yogieTypeToYield[2] = 30 ether; // viy yogie
        yogieTypeToYield[3] = 45 ether; // genesis yogie

        yogieBaseType = 0;
        vaultYogieType = 1;
        viyYogieType = 2;
        gYogieType = 3;

        carBonusCap = 3;
    }


    /** === Stake helpers === */
    function _validateVaultYogies(uint256 yogieId) internal view returns (bool) {
        uint256 vaultStartPoint = yogies.vaultStartPoint();
        uint256 viyStartPoint = yogies.viyStartPoint();
        return vaultStartPoint != 0 && yogieId >= vaultStartPoint && yogieId < viyStartPoint;
    }

    function _validateVIY(uint256 yogieId) internal view returns (bool) {
        uint256 viyStartPoint = yogies.viyStartPoint();
        return yogieId >= viyStartPoint;
    }

    function _validateStakeAmount(address user, uint256 newStakeTotal) internal view returns (bool) {
        //uint256 houseBalance = yogiesItems.balanceOf(user, yogiesItems.house());
//
        //if (houseBalance == 0) {
        //    return newStakeTotal == 1;
        //} else {
        //    return newStakeTotal <= houseBalance * 10;
        //}
        return newStakeTotal == 1;
    }

    function _getUnrealizedReward(address user, uint256 lastAction, uint256 dailyReward) internal view returns (uint256) {
        uint256 nakedReward = (block.timestamp - lastAction) * dailyReward / 1 days;

        //uint256 carBalance = yogiesItems.balanceOf(user, yogiesItems.car());
        //uint256 carBonusPercentage = carBalance > carBonusCap ? carBonus[carBonusCap] : carBonus[carBalance];
//
        //if (carBonusPercentage == 0) {
        //    return nakedReward;
        //} else {
        //    uint256 carBonusReceived = nakedReward * carBonusPercentage / 100;
        //    return nakedReward + carBonusReceived;
        //}

        return nakedReward;
    }

    /** === Stake functions === */
    function _stakeSingleYogie(uint256 yogieId, uint256 yogieType) internal {
        require(yogieType >= yogieBaseType && yogieType <= gYogieType, "Incorrect yogie type");

        if (_validateVaultYogies(yogieId)) {
            require(yogieType == vaultYogieType, "Yogie type of vault yogie incorrect");
        } else {
            require(yogieType != vaultYogieType, "Yogie type of vault yogie incorrect");
        }

        if (_validateVIY(yogieId)) {
            require(yogieType == viyYogieType, "Yogie type of viy yogie incorrect");
        } else {
            require(yogieType != viyYogieType, "Yogie type of viy yogie incorrect");
        }
        
        if (yogieType == gYogieType) {
            gYogies.stakeYogie(yogieId, msg.sender);
        } else {
            yogies.stakeYogie(yogieId, msg.sender);
        }
        
        uint256 yogieStakeData = yogiesStakeData[msg.sender];

        uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
        uint256 dailyReward = _getDailyReward(yogieStakeData);
        uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
        uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);

        uint256 earnedRewardSinceLastAction = totalStaked == 0 ? 0 : _getUnrealizedReward(msg.sender, lastAction, dailyReward);        
        uint256 newDailyReward = dailyReward + yogieTypeToYield[yogieType];
        uint256 newTotal = totalStaked + 1;
        uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;
        
        require(_validateStakeAmount(msg.sender, newTotal), "Not enough houses supporting stake amount");

        yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, newDailyReward, newTotal, newAccumulatedReward);
    }

    function stakeSingleYogie(uint256 yogieId, uint256 yogieType) external {
        _stakeSingleYogie(yogieId, yogieType);
    }

    function unStakeSingleYogie(uint256 yogieId, uint256 yogieType) external {
        require(yogieType >= yogieBaseType && yogieType <= gYogieType, "Incorrect yogie type");
        //require(!gemies.hasDebt(msg.sender), "Sender account frozen");

        if (_validateVaultYogies(yogieId)) {
            require(yogieType == vaultYogieType, "Yogie type of vault yogie incorrect");
        } else {
            require(yogieType != vaultYogieType, "Yogie type of vault yogie incorrect");
        }

        if (_validateVIY(yogieId)) {
            require(yogieType == viyYogieType, "Yogie type of viy yogie incorrect");
        } else {
            require(yogieType != viyYogieType, "Yogie type of viy yogie incorrect");
        }
        
        if (yogieType == gYogieType) {
            gYogies.unstakeYogie(yogieId, msg.sender);
        } else {
            yogies.unstakeYogie(yogieId, msg.sender);
        }
        
        uint256 yogieStakeData = yogiesStakeData[msg.sender];

        uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
        uint256 dailyReward = _getDailyReward(yogieStakeData);
        uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
        uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);

        uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
        uint256 newDailyReward = dailyReward - yogieTypeToYield[yogieType];
        uint256 newTotal = totalStaked - 1;
        uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;

        yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, newDailyReward, newTotal, newAccumulatedReward);
    }

    //function stakeManyYogies(uint256[] calldata yogieIds, uint256[] calldata yogieTypes) external {
    //    require(yogieIds.length > 0, "Cannot stake 0 yogies");
    //    require(yogieIds.length == yogieTypes.length, "ids and types mismatch");
//
    //    uint256 totalRewardAdded;
    //    for (uint256 i = 0; i < yogieIds.length; i++) {
    //        uint256 yogieId = yogieIds[i];
    //        uint256 yogieType = yogieTypes[i];
//
    //        require(yogieType >= yogieBaseType && yogieType <= gYogieType, "Incorrect yogie type");
//
    //        if (_validateVaultYogies(yogieId)) {
    //            require(yogieType == vaultYogieType, "Yogie type of vault yogie incorrect");
    //        } else {
    //            require(yogieType != vaultYogieType, "Yogie type of vault yogie incorrect");
    //        }
//
    //        if (_validateVIY(yogieId)) {
    //            require(yogieType == viyYogieType, "Yogie type of viy yogie incorrect");
    //        } else {
    //            require(yogieType != viyYogieType, "Yogie type of viy yogie incorrect");
    //        }
    //        
    //        if (yogieType == gYogieType) {
    //            gYogies.stakeYogie(yogieId, msg.sender);
    //        } else {
    //            yogies.stakeYogie(yogieId, msg.sender);
    //        }
//
    //        totalRewardAdded += yogieTypeToYield[yogieType];
    //    }        
    //    
    //    uint256 yogieStakeData = yogiesStakeData[msg.sender];
//
    //    uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
    //    uint256 dailyReward = _getDailyReward(yogieStakeData);
    //    uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
    //    uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);
//
    //    if (totalStaked == 0) {
    //        require(_validateStakeAmount(msg.sender, yogieIds.length), "Not enough houses supporting stake amount");
    //        yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, totalRewardAdded, yogieIds.length, accumulatedReward);
    //    } else {
    //        uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
    //        uint256 newDailyReward = dailyReward + totalRewardAdded;
    //        uint256 newTotal = totalStaked + yogieIds.length;
    //        uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;
//
    //        require(_validateStakeAmount(msg.sender, newTotal), "Not enough houses supporting stake amount");
//
    //        yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, newDailyReward, newTotal, newAccumulatedReward);
    //    }
    //}
//
    //function unStakeManyYogies(uint256[] calldata yogieIds, uint256[] calldata yogieTypes) external {
    //    require(yogieIds.length > 0, "Cannot stake 0 yogies");
    //    require(yogieIds.length == yogieTypes.length, "ids and types mismatch");
    //    //require(!gemies.hasDebt(msg.sender), "Sender account frozen");
//
    //    uint256 totalRewardLost;
    //    for (uint256 i = 0; i < yogieIds.length; i++) {
    //        uint256 yogieId = yogieIds[i];
    //        uint256 yogieType = yogieTypes[i];
//
    //        require(yogieType >= yogieBaseType && yogieType <= gYogieType, "Incorrect yogie type");
//
    //        if (_validateVaultYogies(yogieId)) {
    //            require(yogieType == vaultYogieType, "Yogie type of vault yogie incorrect");
    //        } else {
    //            require(yogieType != vaultYogieType, "Yogie type of vault yogie incorrect");
    //        }
//
    //        if (_validateVIY(yogieId)) {
    //            require(yogieType == viyYogieType, "Yogie type of viy yogie incorrect");
    //        } else {
    //            require(yogieType != viyYogieType, "Yogie type of viy yogie incorrect");
    //        }
    //        
    //        if (yogieType == gYogieType) {
    //            gYogies.unstakeYogie(yogieId, msg.sender);
    //        } else {
    //            yogies.unstakeYogie(yogieId, msg.sender);
    //        }
//
    //        totalRewardLost += yogieTypeToYield[yogieType];
    //    }        
    //    
    //    uint256 yogieStakeData = yogiesStakeData[msg.sender];
//
    //    uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
    //    uint256 dailyReward = _getDailyReward(yogieStakeData);
    //    uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
    //    uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);
//
    //    uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
    //    uint256 newDailyReward = dailyReward - totalRewardLost;
    //    uint256 newTotal = totalStaked - yogieIds.length;
    //    uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;
//
    //    yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, newDailyReward, newTotal, newAccumulatedReward);
    //}

    //function updateAccumulatedReward(address user) external {
    //    uint256 yogieStakeData = yogiesStakeData[user];
//
    //    uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
    //    uint256 dailyReward = _getDailyReward(yogieStakeData);
    //    uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
    //    uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);
//
    //    if (totalStaked > 0) {
    //        uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
    //        uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;
    //        yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, dailyReward, totalStaked, newAccumulatedReward);
    //    }
    //}

    /** === Mint Yogies === */
    function mintYogies(bytes32[] calldata proof, bool mintAndStake) external {
        uint256 nextYogie = yogies.nextYogieId();
        yogies.freeMint(proof, msg.sender);
        
        if (mintAndStake) {
            _stakeSingleYogie(nextYogie, yogieBaseType);
        }
    }

    /** === Getters === */
    function _getLastActionTimeStamp(uint256 yogieStakeData) internal pure returns(uint256) {
        return uint256(uint32(yogieStakeData));   
    }

    function _getTotalStakedYogies(uint256 yogieStakeData) internal pure returns (uint256) {
        return uint256(uint16(yogieStakeData >> 32));
    }

    function _getDailyReward(uint256 yogieStakeData) internal pure returns (uint256) {
        return uint256(uint104(yogieStakeData >> 48));
    }

    function _getAccumulatedReward(uint256 yogieStakeData) internal pure returns (uint256) {
        return uint256(uint104(yogieStakeData >> 152));
    }

    function _getUpdatedYogieStakeData(uint256 timestamp, uint256 daily, uint256 total, uint256 pending) internal pure returns (uint256) {
        uint256 newData = timestamp;
        newData |= total << 32;
        newData |= daily << 48;
        newData |= pending << 152;
        return newData;
    }

    /** === View === */
    function getLastActionTimeStamp(address user) external view returns(uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint32(yogieStakeData));   
    }

    function getTotalStakedYogies(address user) external view returns (uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint16(yogieStakeData >> 32));
    }

    function getDailyReward(address user) external view returns (uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint104(yogieStakeData >> 48));
    }

    function getAccumulatedReward(address user) external view returns (uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint104(yogieStakeData >> 152));
    }

    function getAccumulatedGemies(address user) external view returns (uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];

        uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
        uint256 dailyReward = _getDailyReward(yogieStakeData);
        uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);

        uint256 unrealizedReward = _getUnrealizedReward(user, lastAction, dailyReward);
        uint256 totalReward = accumulatedReward + unrealizedReward;

        return totalReward;
    }

    /** === Setter === */
    function setYogies(address _yogies) external onlyOwner {
        yogies = IYogies(_yogies);
    }

    function setGYogies(address _gYogies) external onlyOwner {
        gYogies = IYogies(_gYogies);
    }
    
    function setGemies(address _gemies) external onlyOwner {
        gemies = IGemies(_gemies);
    }

    function setYogieTypeToYield(uint256 yogieType, uint256 yield) external onlyOwner {
        yogieTypeToYield[yogieType] = yield;
    }

    function setCarBonus(uint256 amount, uint256 bonus) external onlyOwner {
        carBonus[amount] = bonus;
    }

    function setCarBonusCap(uint256 newCap) external onlyOwner {
        carBonusCap = newCap;
    }
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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