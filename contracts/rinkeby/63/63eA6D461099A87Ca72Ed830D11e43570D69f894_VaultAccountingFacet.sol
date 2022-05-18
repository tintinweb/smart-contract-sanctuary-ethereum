// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IVaultAccounting } from "../interfaces/facets/IVaultAccounting.sol";
import { IVault } from "../interfaces/IVault.sol";
import { LibStorage, VaultStorage, DepositsRewardsStorage, TokenAddressStorage } from "../libraries/LibStorage.sol";
import { LibVaultUtils } from "../libraries/LibVaultUtils.sol";
import { LibDiamond } from "../vendor/libraries/LibDiamond.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultAccountingFacet is IVaultAccounting {
    /**
     * @notice Enforces only diamond owner can call function
     */
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    /**
     * @notice Updates the rewards
     */
    modifier updateReward(bytes12 vaultName, address account) {
        VaultStorage storage vs = LibStorage.vaultStorage();
        DepositsRewardsStorage storage drs = LibStorage.depositsRewardsStorage();

        address vaultAddress = vs.vaultAddresses[vaultName];
        require(vaultAddress != address(0), "Vault does not exist");

        drs.rewardPerTokenStored[vaultName] = rewardPerToken(vaultName);
        drs.lastUpdateTime[vaultName] = lastTimeRewardApplicable(vaultName);

        if (account != address(0)) {
            drs.rewards[vaultName][account] = earned(vaultName, account);
            drs.userRewardPerTokenPaid[vaultName][account] = drs.rewardPerTokenStored[vaultName];
        }

        _;
    }

    /**
     * @notice Deposits ETH into vault
     * @dev Main point of entry into the marketplace
     *
     * @param vaultName The name of the vault as registered in the registry
     */
    function deposit(bytes12 vaultName) external payable override updateReward(vaultName, msg.sender) {
        VaultStorage storage vs = LibStorage.vaultStorage();

        address vaultAddress = vs.vaultAddresses[vaultName];

        // deposit into vault on behalf of sender
        uint256 lpTokensAmount = IVault(vaultAddress).deposit{ value: msg.value }();
        vs.userVaultBalances[msg.sender][vaultName] += lpTokensAmount;

        emit DepositEth(msg.sender, vaultName, msg.value, lpTokensAmount);
    }

    /**
     * @notice Deposits LP tokens directly into vault
     * @dev Main point of entry into the marketplace
     *
     * @param vaultName The name of the vault as registered in the registry
     * @param amount The amount of LP tokens to deposit
     */
    function depositLpToken(bytes12 vaultName, uint256 amount) external override updateReward(vaultName, msg.sender) {
        VaultStorage storage vs = LibStorage.vaultStorage();

        address vaultAddress = vs.vaultAddresses[vaultName];

        // deposit into vault on behalf of sender
        IVault(vaultAddress).depositLpToken(amount);
        vs.userVaultBalances[msg.sender][vaultName] += amount;

        emit DepositLpToken(msg.sender, vaultName, amount);
    }

    /**
     * @notice Withdraw ETH from the user's lp token in vault
     *
     * @param lpTokenAmount The amount to withdraw
     * @param vaultName The vault to withdraw from
     */
    function withdraw(uint256 lpTokenAmount, bytes12 vaultName) external override updateReward(vaultName, msg.sender) {
        VaultStorage storage vs = LibStorage.vaultStorage();

        address vaultAddress = vs.vaultAddresses[vaultName];

        // verify the user deposit information
        require(lpTokenAmount <= vs.userVaultBalances[msg.sender][vaultName], "Insufficient token balance");

        // update user balance
        vs.userVaultBalances[msg.sender][vaultName] -= lpTokenAmount;
        // withdraw from vault and send to recipient
        uint256 amountWithdrawn = IVault(vaultAddress).withdraw(lpTokenAmount, payable(msg.sender));

        emit Withdraw(msg.sender, vaultName, amountWithdrawn, lpTokenAmount);
    }

    /**
     * @notice Withdraw user's LP tokens from the vault
     *
     * @param lpTokenAmount The amount of LP tokens to withdraw
     * @param vaultName The vault to withdraw from
     */
    function withdrawLpToken(uint256 lpTokenAmount, bytes12 vaultName)
        external
        override
        updateReward(vaultName, msg.sender)
    {
        VaultStorage storage vs = LibStorage.vaultStorage();

        address vaultAddress = vs.vaultAddresses[vaultName];

        // verify the user deposit information
        require(lpTokenAmount <= vs.userVaultBalances[msg.sender][vaultName], "Insufficient token balance");

        // update user balance
        vs.userVaultBalances[msg.sender][vaultName] -= lpTokenAmount;
        // withdraw from vault and send to recipient
        IVault(vaultAddress).withdrawLpToken(lpTokenAmount, payable(msg.sender));

        emit WithdrawLpToken(msg.sender, vaultName, lpTokenAmount);
    }

    /**
     * @notice Claim the rewards owed for a vault
     *
     * @param vaultName The vault name
     */
    function getReward(bytes12 vaultName) external override updateReward(vaultName, msg.sender) {
        DepositsRewardsStorage storage drs = LibStorage.depositsRewardsStorage();
        TokenAddressStorage storage tas = LibStorage.tokenAddressStorage();

        uint256 reward = drs.rewards[vaultName][msg.sender];

        if (reward > 0) {
            drs.rewards[vaultName][msg.sender] = 0;
            IERC20(tas.fukuToken).transfer(msg.sender, reward);
            emit RewardPaid(vaultName, msg.sender, reward);
        }
    }

    /**
     * @notice Notify the reward amount
     *
     * @param vaultName The vault name
     * @param reward The reward amount
     */
    function notifyRewardAmount(bytes12 vaultName, uint256 reward)
        external
        override
        onlyOwner
        updateReward(vaultName, address(0))
    {
        DepositsRewardsStorage storage drs = LibStorage.depositsRewardsStorage();
        TokenAddressStorage storage tas = LibStorage.tokenAddressStorage();

        // transfer in reward amount
        // todo: state variable to keep track of how much is allocated?
        IERC20(tas.fukuToken).transferFrom(msg.sender, address(this), reward);

        if (block.timestamp >= drs.periodFinish[vaultName]) {
            drs.rewardRate[vaultName] = reward / drs.rewardsDuration[vaultName];
        } else {
            uint256 remaining = drs.periodFinish[vaultName] - block.timestamp;
            uint256 leftover = remaining * drs.rewardRate[vaultName];
            drs.rewardRate[vaultName] = reward + leftover / drs.rewardsDuration[vaultName];
        }

        drs.lastUpdateTime[vaultName] = block.timestamp;
        drs.periodFinish[vaultName] = block.timestamp + drs.rewardsDuration[vaultName];

        emit RewardAdded(vaultName, reward);
    }

    /**
     * @notice Sets the rewards duration
     *
     * @param vaultName The vault name
     * @param duration The duration
     */
    function setRewardsDuration(bytes12 vaultName, uint256 duration) external override onlyOwner {
        DepositsRewardsStorage storage drs = LibStorage.depositsRewardsStorage();

        require(block.timestamp > drs.periodFinish[vaultName], "Previous rewards period not ended");
        drs.rewardsDuration[vaultName] = duration;

        emit RewardsDurationUpdated(vaultName, duration);
    }

    /**
     * @notice Queries the user's lp token balance for a vault
     *
     * @param user The user to query for
     * @param vaultName The vault to query for
     */
    function userLPTokenBalance(address user, bytes12 vaultName) external view override returns (uint256) {
        return LibVaultUtils.getUserLpTokenBalance(user, vaultName);
    }

    /**
     * @notice Queries the user's eth balance for a vault
     *
     * @param user The user to query for
     * @param vaultName The vault to query for
     */
    function userETHBalance(address user, bytes12 vaultName) external view override returns (uint256) {
        return LibVaultUtils.getUserEthBalance(user, vaultName);
    }

    /**
     * @notice Queries the user's earned rewards for a vault
     *
     * @param vaultName The vault name
     * @param account The user's address
     */
    function earned(bytes12 vaultName, address account) public view override returns (uint256) {
        VaultStorage storage vs = LibStorage.vaultStorage();
        DepositsRewardsStorage storage drs = LibStorage.depositsRewardsStorage();

        return
            (vs.userVaultBalances[account][vaultName] *
                (rewardPerToken(vaultName) - drs.userRewardPerTokenPaid[vaultName][account])) /
            1e18 +
            drs.rewards[vaultName][account];
    }

    /**
     * @notice Calculates the reward per token
     *
     * @param vaultName The vault name
     */
    function rewardPerToken(bytes12 vaultName) public view override returns (uint256) {
        DepositsRewardsStorage storage drs = LibStorage.depositsRewardsStorage();

        uint256 totalSupply = LibVaultUtils.getTotalVaultHoldings(vaultName);

        if (totalSupply == 0) {
            return drs.rewardPerTokenStored[vaultName];
        }

        return
            drs.rewardPerTokenStored[vaultName] +
            (
                ((((lastTimeRewardApplicable(vaultName) - drs.lastUpdateTime[vaultName]) * drs.rewardRate[vaultName]) *
                    1e18) / totalSupply)
            );
    }

    /**
     * @notice Calculates the last time reward applicable
     *
     * @param vaultName The vault name
     */
    function lastTimeRewardApplicable(bytes12 vaultName) public view override returns (uint256) {
        DepositsRewardsStorage storage drs = LibStorage.depositsRewardsStorage();

        return block.timestamp < drs.periodFinish[vaultName] ? block.timestamp : drs.periodFinish[vaultName];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVaultAccounting {
    event DepositEth(address indexed user, bytes12 indexed vaultName, uint256 amountEth, uint256 amountLp);

    event DepositLpToken(address indexed user, bytes12 indexed vaultName, uint256 amountLp);

    event Withdraw(address indexed user, bytes12 indexed vaultName, uint256 amountEth, uint256 amountLp);

    event WithdrawLpToken(address indexed user, bytes12 indexed vaultName, uint256 amountLp);

    event RewardAdded(bytes12 vaultName, uint256 reward);

    event RewardPaid(bytes12 vaultName, address indexed user, uint256 reward);

    event RewardsDurationUpdated(bytes12 vaultName, uint256 newDuration);

    function deposit(bytes12 vaultName) external payable;

    function depositLpToken(bytes12 vaultName, uint256 amount) external;

    function withdraw(uint256 lpTokenAmount, bytes12 vaultName) external;

    function withdrawLpToken(uint256 lpTokenAmount, bytes12 vault) external;

    function getReward(bytes12 vaultName) external;

    function notifyRewardAmount(bytes12 vaultName, uint256 reward) external;

    function setRewardsDuration(bytes12 vaultName, uint256 duration) external;

    function userLPTokenBalance(address user, bytes12 vaultName) external view returns (uint256);

    function userETHBalance(address user, bytes12 vaultName) external view returns (uint256);

    function earned(bytes12 vaultName, address account) external view returns (uint256);

    function rewardPerToken(bytes12 vaultName) external view returns (uint256);

    function lastTimeRewardApplicable(bytes12 vaultName) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IVault {
    /**
     * @dev Deposits ETH and converts to vault's LP token
     *
     * @return The amount of LP tokens received from ETH deposit
     */
    function deposit() external payable returns (uint256);

    /**
     * @dev Deposits LP token directly into vault
     *
     * @param amount The amount of LP tokens to deposit
     */
    function depositLpToken(uint256 amount) external;

    /**
     * @dev Converts LP token and withdraws as ETH
     *
     * @param lpTokenAmount The amount of LP tokens to withdraw before converting
     * @param recipient The recipient of the converted ETH
     * @return The amount of ETH withdrawn
     */
    function withdraw(uint256 lpTokenAmount, address payable recipient) external returns (uint256);

    /**
     * @dev Withdraws LP token directly from vault
     *
     * @param lpTokenAmount The amount of LP tokens to withdraw
     * @param recipient The recipient of the LP tokens
     */
    function withdrawLpToken(uint256 lpTokenAmount, address recipient) external;

    /**
     * @dev Transfers LP tokens to new vault
     *
     * @param newVaultAddress The new vault which will receive the LP tokens
     */
    function transferFunds(address payable newVaultAddress) external;

    /**
     * @dev Gets the conversion from LP token to ETH
     *
     * @param lpTokenAmount The LP token amount
     */
    function getAmountETH(uint256 lpTokenAmount) external view returns (uint256);

    /**
     * @dev Gets the conversion from ETH to LP token
     *
     * @param ethAmount The ETH amount
     */
    function getAmountLpTokens(uint256 ethAmount) external view returns (uint256);

    /**
     * @dev Get the LP token address of the vault
     */
    function getLpToken() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { BidInfo, OptionInfo, AcceptedOption } from "../FukuTypes.sol";

struct BidMarketStorage {
    uint256 nextBidId;
    mapping(uint256 => BidInfo) bids;
}

struct OptionMarketStorage {
    uint256 nextOptionId;
    mapping(uint256 => OptionInfo) options;
    mapping(uint256 => AcceptedOption) acceptedOptions;
}

struct VaultStorage {
    mapping(bytes12 => address) vaultAddresses;
    mapping(address => mapping(bytes12 => uint256)) userVaultBalances;
}

struct TokenAddressStorage {
    address punkToken;
    address fukuToken;
}

struct AirdropClaimStorage {
    bytes32 merkleRoot;
    uint256 totalAmount; // todo: unused
    uint256 initialUnlockBps; // todo: unused
    mapping(address => uint256) claimed;
}

struct RewardsManagementStorage {
    uint256 nextEpochId;
    uint256 epochDuration;
    uint256 sellerShareBp;
    mapping(uint256 => uint256) epochEndings;
    mapping(uint256 => uint256) depositsAllocation; // todo: remove?
    mapping(uint256 => uint256) salesAllocation;
    mapping(uint256 => mapping(address => uint256)) collectionAllocation;
    mapping(uint256 => mapping(address => uint256)) floorPrices;
    mapping(uint256 => address[]) rewardedCollections;
}

struct BidRewardsStorage {
    mapping(uint256 => mapping(address => uint256)) totalCollectionBids;
    mapping(uint256 => mapping(address => mapping(address => uint256))) competitiveBids;
}

struct DepositsRewardsStorage {
    mapping(bytes12 => uint256) periodFinish;
    mapping(bytes12 => uint256) rewardRate;
    mapping(bytes12 => uint256) rewardsDuration;
    mapping(bytes12 => uint256) lastUpdateTime;
    mapping(bytes12 => uint256) rewardPerTokenStored;
    mapping(bytes12 => uint256) totalSupply;
    mapping(bytes12 => mapping(address => uint256)) userRewardPerTokenPaid;
    mapping(bytes12 => mapping(address => uint256)) rewards;
}

struct SalesRewardsStorage {
    mapping(uint256 => uint256) totalSales;
    mapping(uint256 => mapping(address => uint256)) sales;
}

library LibStorage {
    bytes32 constant BID_MARKET_STORAGE_POSITION = keccak256("fuku.storage.market.bid");
    bytes32 constant OPTION_MARKET_STORAGE_POSTION = keccak256("fuku.storage.market.option");
    bytes32 constant VAULT_STORAGE_POSITION = keccak256("fuku.storage.vault");
    bytes32 constant TOKEN_ADDRESS_STORAGE_POSITION = keccak256("fuku.storage.token.address");
    bytes32 constant AIRDROP_CLAIM_STORAGE_POSITION = keccak256("fuku.storage.airdrop.claim");
    bytes32 constant REWARDS_MANAGEMENT_STORAGE_POSITION = keccak256("fuku.storage.rewards.management");
    bytes32 constant BIDS_REWARDS_STORAGE_POSITION = keccak256("fuku.storage.bids.rewards");
    bytes32 constant DEPOSITS_REWARDS_STORAGE_POSITION = keccak256("fuku.storage.deposits.rewards");
    bytes32 constant SALES_REWARDS_STORAGE_POSITION = keccak256("fuku.storage.sales.rewards");

    function bidMarketStorage() internal pure returns (BidMarketStorage storage bms) {
        bytes32 position = BID_MARKET_STORAGE_POSITION;
        assembly {
            bms.slot := position
        }
    }

    function optionMarketStorage() internal pure returns (OptionMarketStorage storage oms) {
        bytes32 position = OPTION_MARKET_STORAGE_POSTION;
        assembly {
            oms.slot := position
        }
    }

    function vaultStorage() internal pure returns (VaultStorage storage vs) {
        bytes32 position = VAULT_STORAGE_POSITION;
        assembly {
            vs.slot := position
        }
    }

    function tokenAddressStorage() internal pure returns (TokenAddressStorage storage tas) {
        bytes32 position = TOKEN_ADDRESS_STORAGE_POSITION;
        assembly {
            tas.slot := position
        }
    }

    function airdropClaimStorage() internal pure returns (AirdropClaimStorage storage acs) {
        bytes32 position = AIRDROP_CLAIM_STORAGE_POSITION;
        assembly {
            acs.slot := position
        }
    }

    function rewardsManagementStorage() internal pure returns (RewardsManagementStorage storage rms) {
        bytes32 position = REWARDS_MANAGEMENT_STORAGE_POSITION;
        assembly {
            rms.slot := position
        }
    }

    function bidRewardsStorage() internal pure returns (BidRewardsStorage storage brs) {
        bytes32 position = BIDS_REWARDS_STORAGE_POSITION;
        assembly {
            brs.slot := position
        }
    }

    function depositsRewardsStorage() internal pure returns (DepositsRewardsStorage storage drs) {
        bytes32 position = DEPOSITS_REWARDS_STORAGE_POSITION;
        assembly {
            drs.slot := position
        }
    }

    function salesRewardsStorage() internal pure returns (SalesRewardsStorage storage srs) {
        bytes32 position = SALES_REWARDS_STORAGE_POSITION;
        assembly {
            srs.slot := position
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { LibStorage, VaultStorage } from "./LibStorage.sol";
import { IVault } from "../interfaces/IVault.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibVaultUtils {
    function getUserLpTokenBalance(address user, bytes12 vaultName) internal view returns (uint256) {
        VaultStorage storage vs = LibStorage.vaultStorage();

        return vs.userVaultBalances[user][vaultName];
    }

    function getUserEthBalance(address user, bytes12 vaultName) internal view returns (uint256) {
        VaultStorage storage vs = LibStorage.vaultStorage();

        return IVault(vs.vaultAddresses[vaultName]).getAmountETH(vs.userVaultBalances[user][vaultName]);
    }

    function getTotalVaultHoldings(bytes12 vaultName) internal view returns (uint256) {
        VaultStorage storage vs = LibStorage.vaultStorage();

        address vault = vs.vaultAddresses[vaultName];
        address vaultLpToken = IVault(vault).getLpToken();
        if (vaultLpToken == address(0)) {
            return vault.balance;
        } else {
            return IERC20(vaultLpToken).balanceOf(vault);
        }
    }
}

// SPDX-License-Identifier: MIT
/**
 * Vendored on March 15, 2022 from:
 * https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/libraries/LibDiamond.sol
 */
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

enum OptionDuration {
    ThirtyDays,
    NinetyDays
}

struct BidInputParams {
    bytes12 vault; // the vault from where the funds for the bid originate
    address nft; // the address of the nft collection
    uint256 nftIndex; // the index of the nft in the collection
    uint256 amount; // the bid amount
}

struct BidInfo {
    BidInputParams bidInput; // the input params used to create bid
    address bidder; // the address of the bidder
}

struct OptionInputParams {
    BidInputParams bidInput;
    uint256 premium;
    OptionDuration duration;
}

struct OptionInfo {
    OptionInputParams optionInput; // the input params used to create base part of bid
    bool exercisable; // true if option can be exercised, false otherwise
    address bidder; // the bidder (buyer)
}

struct AcceptedOption {
    uint256 expiry;
    address seller;
}

struct AirdropInit {
    bytes32 merkleRoot;
    address token;
    uint256 totalAmount;
    uint256 initialUnlockBps;
}

// SPDX-License-Identifier: MIT
/**
 * Vendored on March 15, 2022 from:
 * https://github.com/mudgen/diamond-3-hardhat/blob/main/contracts/interfaces/IDiamondCut.sol
 */
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}