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
import "@openzeppelin/contracts/access/Ownable.sol";

contract IYogies {
    function stakeYogie(uint256 yogieId, address sender) external {}
    function unstakeYogie(uint256 yogieId, address sender) external {}

    function vaultStartPoint() external view returns (uint256) {}
    function viyStartPoint() external view returns (uint256) {}

    function freeMint(bytes32[] calldata proof) external {}
    function nextYogieId() external view returns (uint256) {}
}

abstract contract IYogiesItems is IERC1155 {
    function car() external view returns(uint256) {}
    function house() external view returns (uint256) {}
}

abstract contract IGemmies is IERC20 {
    function hasDebt(address user) external view returns (bool) {}
}

contract YogiesStaking is Ownable {
    
    /** === Yogies contracts === */

    IYogies public yogies;
    IYogies public gYogies;
    IYogiesItems public yogiesItems;
    IGemmies public gemmies;

    /** === Staking core === */

    /// @dev Stores last action timestamp, reward per day, yogies staked and accumulated reward in single uint256
    /// - first 40 bits: last action timestamp
    /// - second 32 bits: total rewards per day the user earns
    /// - third 16 bits: total yogies staked
    /// - remaining 168 bits: accumulated gemmies reward
    mapping(address => uint256) public yogiesStakeData;

    uint256 public yogieBaseType = 0;
    uint256 public vaultYogieType = 1;
    uint256 public viyYogieType = 2;
    uint256 public gYogieType = 3;

    mapping(uint256 => uint256) public yogieTypeToYield;

    mapping(uint256 => uint256) public carBonus; // maps car amount to bonus. Base 100
    uint256 public carBonusCap = 3; // max car amount where bonus increase stops

    constructor(
        address _yogies,
        address _gYogies,
        address _yogiesItems,
        address _gemmies
    ) {
        yogies = IYogies(_yogies);
        gYogies = IYogies(_gYogies);
        yogiesItems = IYogiesItems(_yogiesItems);
        gemmies = IGemmies(_gemmies);

        carBonus[1] = 20;
        carBonus[2] = 35;
        carBonus[3] = 50;

        yogieTypeToYield[0] = 10 ether; // normal yogie
        yogieTypeToYield[1] = 15 ether; // vault yogie
        yogieTypeToYield[2] = 30 ether; // viy yogie
        yogieTypeToYield[3] = 50 ether; // genesis yogie
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
        uint256 houseBalance = yogiesItems.balanceOf(user, yogiesItems.house());

        if (houseBalance == 0) {
            return newStakeTotal == 1;
        } else {
            return newStakeTotal <= houseBalance * 10;
        }
    }

    function _getUnrealizedReward(address user, uint256 lastAction, uint256 dailyReward) internal view returns (uint256) {
        uint256 nakedReward = (block.timestamp - lastAction) * dailyReward / 1 days;

        uint256 carBalance = yogiesItems.balanceOf(user, yogiesItems.car());
        uint256 carBonusPercentage = carBalance > carBonusCap ? carBonus[carBonusCap] : carBonus[carBalance];

        if (carBonusPercentage == 0) {
            return nakedReward;
        } else {
            uint256 carBonus = nakedReward * carBonusPercentage / 100;
            return nakedReward + carBonus;
        }

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

        if (totalStaked == 0) {
            yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, yogieTypeToYield[yogieType], 1, accumulatedReward);
        } else {
            uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
            uint256 newDailyReward = dailyReward + yogieTypeToYield[yogieType];
            uint256 newTotal = totalStaked + 1;
            uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;
            
            require(_validateStakeAmount(msg.sender, newTotal), "Not enough houses supporting stake amount");

            yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, newDailyReward, newTotal, newAccumulatedReward);
        }
    }

    function stakeSingleYogie(uint256 yogieId, uint256 yogieType) external {
        _stakeSingleYogie(yogieId, yogieType);
    }

    function unStakeSingleYogie(uint256 yogieId, uint256 yogieType) external {
        require(yogieType >= yogieBaseType && yogieType <= gYogieType, "Incorrect yogie type");
        require(!gemmies.hasDebt(msg.sender), "Sender account frozen");

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

    function stakeManyYogies(uint256[] calldata yogieIds, uint256[] calldata yogieTypes) external {
        require(yogieIds.length > 0, "Cannot stake 0 yogies");
        require(yogieIds.length == yogieTypes.length, "ids and types mismatch");

        uint256 totalRewardAdded;
        for (uint256 i = 0; i < yogieIds.length; i++) {
            uint256 yogieId = yogieIds[i];
            uint256 yogieType = yogieTypes[i];

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

            totalRewardAdded += yogieTypeToYield[yogieType];
        }        
        
        uint256 yogieStakeData = yogiesStakeData[msg.sender];

        uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
        uint256 dailyReward = _getDailyReward(yogieStakeData);
        uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
        uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);

        if (totalStaked == 0) {
            require(_validateStakeAmount(msg.sender, yogieIds.length), "Not enough houses supporting stake amount");
            yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, totalRewardAdded, yogieIds.length, accumulatedReward);
        } else {
            uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
            uint256 newDailyReward = dailyReward + totalRewardAdded;
            uint256 newTotal = totalStaked + yogieIds.length;
            uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;

            require(_validateStakeAmount(msg.sender, newTotal), "Not enough houses supporting stake amount");

            yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, newDailyReward, newTotal, newAccumulatedReward);
        }
    }

    function unStakeManyYogies(uint256[] calldata yogieIds, uint256[] calldata yogieTypes) external {
        require(yogieIds.length > 0, "Cannot stake 0 yogies");
        require(yogieIds.length == yogieTypes.length, "ids and types mismatch");
        require(!gemmies.hasDebt(msg.sender), "Sender account frozen");

        uint256 totalRewardLost;
        for (uint256 i = 0; i < yogieIds.length; i++) {
            uint256 yogieId = yogieIds[i];
            uint256 yogieType = yogieTypes[i];

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
                gYogies.unstakeYogie(yogieId, msg.sender);
            } else {
                yogies.unstakeYogie(yogieId, msg.sender);
            }

            totalRewardLost += yogieTypeToYield[yogieType];
        }        
        
        uint256 yogieStakeData = yogiesStakeData[msg.sender];

        uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
        uint256 dailyReward = _getDailyReward(yogieStakeData);
        uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
        uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);

        uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
        uint256 newDailyReward = dailyReward - totalRewardLost;
        uint256 newTotal = totalStaked - yogieIds.length;
        uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;

        yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, newDailyReward, newTotal, newAccumulatedReward);
    }

    function updateAccumulatedReward(address user) external {
        uint256 yogieStakeData = yogiesStakeData[user];

        uint256 lastAction = _getLastActionTimeStamp(yogieStakeData);
        uint256 dailyReward = _getDailyReward(yogieStakeData);
        uint256 totalStaked = _getTotalStakedYogies(yogieStakeData);
        uint256 accumulatedReward = _getAccumulatedReward(yogieStakeData);

        if (totalStaked > 0) {
            uint256 earnedRewardSinceLastAction = _getUnrealizedReward(msg.sender, lastAction, dailyReward);
            uint256 newAccumulatedReward = accumulatedReward + earnedRewardSinceLastAction;
            yogiesStakeData[msg.sender] = _getUpdatedYogieStakeData(block.timestamp, dailyReward, totalStaked, newAccumulatedReward);
        }
    }

    /** === Mint Yogies === */
    function mintYogies(bytes32[] calldata proof, bool mintAndStake) external {
        uint256 nextYogie = yogies.nextYogieId();
        yogies.freeMint(proof);
        
        if (mintAndStake) {
            _stakeSingleYogie(nextYogie, yogieBaseType);
        }
    }

    /** === Getters === */
    function _getLastActionTimeStamp(uint256 yogieStakeData) internal pure returns(uint256) {
        return uint256(uint40(yogieStakeData));   
    }

    function _getDailyReward(uint256 yogieStakeData) internal pure returns (uint256) {
        return uint256(uint32(yogieStakeData >> 40));
    }

    function _getTotalStakedYogies(uint256 yogieStakeData) internal pure returns (uint256) {
        return uint256(uint16(yogieStakeData >> 72));
    }

    function _getAccumulatedReward(uint256 yogieStakeData) internal pure returns (uint256) {
        return uint256(uint168(yogieStakeData >> 88));
    }

    function _getUpdatedYogieStakeData(uint256 timestamp, uint256 daily, uint256 total, uint256 pending) internal pure returns (uint256) {
        uint256 newData = timestamp;
        newData |= daily << 40;
        newData |= total << 72;
        newData |= pending << 88;
        return newData;
    }

    /** === View === */
    function getLastActionTimeStamp(address user) external view returns(uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint40(yogieStakeData));   
    }

    function getDailyReward(address user) external view returns (uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint32(yogieStakeData >> 40));
    }

    function getTotalStakedYogies(address user) external view returns (uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint16(yogieStakeData >> 72));
    }

    function getAccumulatedReward(address user) external view returns (uint256) {
        uint256 yogieStakeData = yogiesStakeData[user];
        return uint256(uint168(yogieStakeData >> 88));
    }

    function getAccumulatedGemmies(address user) external view returns (uint256) {
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

    function setYogiesItems(address _yogiesItems) external onlyOwner {
        yogiesItems = IYogiesItems(_yogiesItems);
    }

    function setGemmies(address _gemmies) external onlyOwner {
        gemmies = IGemmies(_gemmies);
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