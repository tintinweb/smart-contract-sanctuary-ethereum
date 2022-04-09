// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../../interfaces/IOutputReceiver.sol";
import "../../interfaces/IOutputReceiverV2.sol";
import "../../interfaces/IOutputReceiverV3.sol";
import "../../interfaces/IRevest.sol";
import "../../interfaces/IAddressRegistry.sol";
import "../../interfaces/IRewardsHandler.sol";
import "../../interfaces/IFNFTHandler.sol";
import "../../interfaces/IAddressLock.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

contract Staking is Ownable, IOutputReceiverV3, ERC165, IAddressLock {
    using SafeERC20 for IERC20;

    address private revestAddress;
    address public lpAddress;
    address public rewardsHandlerAddress;
    address public addressRegistry;

    address public oldStakingContract;
    uint public previousStakingIDCutoff;

    bool public additionalEnabled;

    uint private constant ONE_DAY = 86400;

    uint private constant WINDOW_ONE = ONE_DAY;
    uint private constant WINDOW_THREE = ONE_DAY*5;
    uint private constant WINDOW_SIX = ONE_DAY*9;
    uint private constant WINDOW_TWELVE = ONE_DAY*14;
    uint private constant MAX_INT = 2**256 - 1;

    // For tracking if a given contract has approval for token
    mapping (address => mapping (address => bool)) private approvedContracts;

    address internal immutable WETH;

    uint[4] internal interestRates = [4, 13, 27, 56];
    string public customMetadataUrl = "https://revest.mypinata.cloud/ipfs/QmdaJso83dhA5My9gz3ewXBxoWveo95utJJqY99ZSGEpRc";
    string public addressMetadataUrl = "https://revest.mypinata.cloud/ipfs/QmWUyvkGFtFRXWxneojvAfBMy8QpewSvwQMQAkAUV42A91";

    event StakedRevest(uint indexed timePeriod, bool indexed isBasic, uint indexed amount, uint fnftId);

    struct StakingData {
        uint timePeriod;
        uint dateLockedFrom;
        uint amount;
    }

    // fnftId -> timePeriods
    mapping(uint => StakingData) public stakingConfigs;

    constructor(
        address revestAddress_,
        address lpAddress_,
        address rewardsHandlerAddress_,
        address addressRegistry_,
        address wrappedEth_
    ) {
        revestAddress = revestAddress_;
        lpAddress = lpAddress_;
        addressRegistry = addressRegistry_;
        rewardsHandlerAddress = rewardsHandlerAddress_;
        WETH = wrappedEth_;
        previousStakingIDCutoff = IFNFTHandler(IAddressRegistry(addressRegistry).getRevestFNFT()).getNextId() - 1;

        address revest = address(getRevest());
        IERC20(lpAddress).approve(revest, MAX_INT);
        IERC20(revestAddress).approve(revest, MAX_INT);
        approvedContracts[revest][lpAddress] = true;
        approvedContracts[revest][revestAddress] = true;
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC165, IERC165) returns (bool) {
        return (
            interfaceId == type(IOutputReceiver).interfaceId
            || interfaceId == type(IAddressLock).interfaceId
            || interfaceId == type(IOutputReceiverV2).interfaceId
            || interfaceId == type(IOutputReceiverV3).interfaceId
            || super.supportsInterface(interfaceId)
        );
    }

    function stakeBasicTokens(uint amount, uint monthsMaturity) public returns (uint) {
        return _stake(revestAddress, amount, monthsMaturity);
    }

    function stakeLPTokens(uint amount, uint monthsMaturity) public returns (uint) {
        return _stake(lpAddress, amount, monthsMaturity);
    }

    function claimRewards(uint fnftId) external {
        // Check to make sure user owns the fnftId
        require(IFNFTHandler(getRegistry().getRevestFNFT()).getBalance(_msgSender(), fnftId) == 1, 'E061');
        // Receive rewards
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, _msgSender());
    }

    ///
    /// Address Lock Features
    ///

    function updateLock(uint fnftId, uint, bytes memory) external override {
        require(IFNFTHandler(getRegistry().getRevestFNFT()).getBalance(_msgSender(), fnftId) == 1, 'E061');
        // Receive rewards
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, _msgSender());
    }

    // This function not utilized
    function createLock(uint, uint, bytes memory) external pure override {
        return;
    }

    ///
    /// Output Recevier Functions
    ///

    function receiveRevestOutput(
        uint fnftId,
        address asset,
        address payable owner,
        uint quantity
    ) external override {
        address vault = getRegistry().getTokenVault();
        require(_msgSender() == vault, "E016");
        require(quantity == 1, 'ONLY SINGULAR');
        // Strictly limit access
        require(fnftId <= previousStakingIDCutoff || stakingConfigs[fnftId].timePeriod > 0, 'Nonexistent!');

        uint totalQuantity = getValue(fnftId);
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, owner);
        if (asset == revestAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateBasicShares(fnftId, 0);
        } else if (asset == lpAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateLPShares(fnftId, 0);
        } else {
            require(false, "E072");
        }
        IERC20(asset).safeTransfer(owner, totalQuantity);
        emit WithdrawERC20OutputReceiver(_msgSender(), asset, totalQuantity, fnftId, '');
    }

    function handleTimelockExtensions(uint fnftId, uint expiration, address caller) external override {}

    function handleAdditionalDeposit(uint fnftId, uint amountToDeposit, uint quantity, address caller) external override {
        require(_msgSender() == getRegistry().getRevest(), "E016");
        require(quantity == 1);
        require(additionalEnabled, 'Not allowed!');
        _depositAdditionalToStake(fnftId, amountToDeposit, caller);
    }

    function handleSplitOperation(uint fnftId, uint[] memory proportions, uint quantity, address caller) external override {}

    // Future proofing for secondary callbacks during withdrawal
    // Could just use triggerOutputReceiverUpdate and call withdrawal function
    // But deliberately using reentry is poor form and reminds me too much of OAuth 2.0 
    function receiveSecondaryCallback(
        uint fnftId,
        address payable owner,
        uint quantity,
        IRevest.FNFTConfig memory config,
        bytes memory args
    ) external payable override {}

    // Allows for similar function to address lock, updating state while still locked
    // Called by the user directly
    function triggerOutputReceiverUpdate(
        uint fnftId,
        bytes memory args
    ) external override {}

    // This function should only ever be called when a split or additional deposit has occurred 
    function handleFNFTRemaps(uint, uint[] memory, address, bool) external pure override {
        revert();
    }


    function _stake(address stakeToken, uint amount, uint monthsMaturity) private returns (uint){
        require (stakeToken == lpAddress || stakeToken == revestAddress, "E079");
        require(monthsMaturity == 1 || monthsMaturity == 3 || monthsMaturity == 6 || monthsMaturity == 12, 'E055');
        IERC20(stakeToken).safeTransferFrom(msg.sender, address(this), amount);

        IRevest.FNFTConfig memory fnftConfig;
        fnftConfig.asset = stakeToken;
        fnftConfig.depositAmount = amount;
        fnftConfig.isMulti = true;

        fnftConfig.pipeToContract = address(this);

        address[] memory recipients = new address[](1);
        recipients[0] = _msgSender();

        uint[] memory quantities = new uint[](1);
        quantities[0] = 1;

        address revest = getRegistry().getRevest();
        if(!approvedContracts[revest][stakeToken]){
            IERC20(stakeToken).approve(revest, MAX_INT);
            approvedContracts[revest][stakeToken] = true;
        }
        uint fnftId = IRevest(revest).mintAddressLock(address(this), '', recipients, quantities, fnftConfig);

        uint interestRate = getInterestRate(monthsMaturity);
        uint allocPoint = amount * interestRate;

        StakingData memory cfg = StakingData(monthsMaturity, block.timestamp, amount);
        stakingConfigs[fnftId] = cfg;

        if(stakeToken == lpAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateLPShares(fnftId, allocPoint);
        } else if (stakeToken == revestAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateBasicShares(fnftId, allocPoint);
        }
        
        emit StakedRevest(monthsMaturity, stakeToken == revestAddress, amount, fnftId);
        emit DepositERC20OutputReceiver(_msgSender(), stakeToken, amount, fnftId, '');
        return fnftId;
    }

    function _depositAdditionalToStake(uint fnftId, uint amount, address caller) private {
        //Prevent unauthorized access
        require(IFNFTHandler(getRegistry().getRevestFNFT()).getBalance(caller, fnftId) == 1, 'E061');
        require(fnftId > previousStakingIDCutoff, 'E080');
        uint time = stakingConfigs[fnftId].timePeriod;
        require(time > 0, 'E078');
        address asset = ITokenVault(getRegistry().getTokenVault()).getFNFT(fnftId).asset;
        require(asset == revestAddress || asset == lpAddress, 'E079');

        //Claim rewards owed
        IRewardsHandler(rewardsHandlerAddress).claimRewards(fnftId, _msgSender());

        //Write new, extended unlock date
        stakingConfigs[fnftId].dateLockedFrom = block.timestamp;
        stakingConfigs[fnftId].amount = stakingConfigs[fnftId].amount + amount;
        //Retreive current allocation points – WETH and RVST implicitly have identical alloc points
        uint oldAllocPoints = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, asset == revestAddress);
        uint allocPoints = amount * getInterestRate(time) + oldAllocPoints;
        if(asset == revestAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateBasicShares(fnftId, allocPoints);
        } else if (asset == lpAddress) {
            IRewardsHandler(rewardsHandlerAddress).updateLPShares(fnftId, allocPoints);
        }
        emit DepositERC20OutputReceiver(_msgSender(), asset, amount, fnftId, '');
    }


    ///
    /// VIEW FUNCTIONS
    ///

    /// Custom view function

    function getInterestRate(uint months) public view returns (uint) {
        if (months <= 1) {
            return interestRates[0];
        } else if (months <= 3) {
            return interestRates[1];
        } else if (months <= 6) {
            return interestRates[2];
        } else {
            return interestRates[3];
        }
    }

    function getRevest() private view returns (IRevest) {
        return IRevest(getRegistry().getRevest());
    }

    function getRegistry() public view returns (IAddressRegistry) {
        return IAddressRegistry(addressRegistry);
    }

    function getWindow(uint timePeriod) public pure returns (uint window) {
        if(timePeriod == 1) {
            window = WINDOW_ONE;
        }
        if(timePeriod == 3) {
            window = WINDOW_THREE;
        }
        if(timePeriod == 6) {
            window = WINDOW_SIX;
        }
        if(timePeriod == 12) {
            window = WINDOW_TWELVE;
        }
    }

    /// ADDRESS REGISTRY VIEW FUNCTIONS

    /// Does the address lock need an update? 
    function needsUpdate() external pure override returns (bool) {
        return true;
    }

    /// Get the metadata URL for an address lock
    function getMetadata() external view override returns (string memory) {
        return addressMetadataUrl;
    }

    /// Can the stake be unlocked?
    function isUnlockable(uint fnftId, uint) external view override returns (bool) {
        if(fnftId <= previousStakingIDCutoff) {
            return Staking(oldStakingContract).isUnlockable(fnftId, 0);
        }
        uint timePeriod = stakingConfigs[fnftId].timePeriod;
        uint depositTime = stakingConfigs[fnftId].dateLockedFrom;

        uint window = getWindow(timePeriod);
        bool mature = block.timestamp - depositTime > (timePeriod * 30 * ONE_DAY);
        bool window_open = (block.timestamp - depositTime) % (timePeriod * 30 * ONE_DAY) < window;
        return mature && window_open;
    }

    // Retrieve encoded data on the state of the stake for the address lock component
    function getDisplayValues(uint fnftId, uint) external view override returns (bytes memory) {
        if(fnftId <= previousStakingIDCutoff) {
            return IAddressLock(oldStakingContract).getDisplayValues(fnftId, 0);
        }
        uint allocPoints;
        {
            uint revestTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, true);
            uint lpTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, false);
            allocPoints = revestTokenAlloc > 0 ? revestTokenAlloc : lpTokenAlloc;
        }
        uint timePeriod = stakingConfigs[fnftId].timePeriod;
        return abi.encode(allocPoints, timePeriod);
    }

    /// OUTPUT RECEVIER VIEW FUNCTIONS

    function getCustomMetadata(uint fnftId) external view override returns (string memory) {
        if(fnftId <= previousStakingIDCutoff) {
            return Staking(oldStakingContract).getCustomMetadata(fnftId);
        } else {
            return customMetadataUrl;
        }
    }

    function getOutputDisplayValues(uint fnftId) external view override returns (bytes memory) {
        if(fnftId <= previousStakingIDCutoff) {
            return IOutputReceiver(oldStakingContract).getOutputDisplayValues(fnftId);
        }
        bool isRevestToken;
        {
            // Will be zero if this is an LP stake
            uint revestTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, revestAddress, true);
            uint wethTokenAlloc = IRewardsHandler(rewardsHandlerAddress).getAllocPoint(fnftId, WETH, true);
            isRevestToken = revestTokenAlloc > 0 || wethTokenAlloc > 0;
        }
        uint revestRewards = IRewardsHandler(rewardsHandlerAddress).getRewards(fnftId, revestAddress);
        uint wethRewards = IRewardsHandler(rewardsHandlerAddress).getRewards(fnftId, WETH);
        uint timePeriod = stakingConfigs[fnftId].timePeriod;
        uint nextUnlock = block.timestamp + ((timePeriod * 30 days) - ((block.timestamp - stakingConfigs[fnftId].dateLockedFrom)  % (timePeriod * 30 days)));
        //This parameter has been modified for new stakes
        return abi.encode(revestRewards, wethRewards, timePeriod, stakingConfigs[fnftId].dateLockedFrom, isRevestToken ? revestAddress : lpAddress, nextUnlock);
    }

    function getAddressRegistry() external view override returns (address) {
        return addressRegistry;
    }

    function getValue(uint fnftId) public view override returns (uint) {
        if(fnftId <= previousStakingIDCutoff) {
            return ITokenVault(getRegistry().getTokenVault()).getFNFT(fnftId).depositAmount;
        } else {
            return stakingConfigs[fnftId].amount;
        }
    }

    function getAsset(uint fnftId) external view override returns (address) {
        return ITokenVault(getRegistry().getTokenVault()).getFNFT(fnftId).asset;
    }

    ///
    /// ADMIN FUNCTIONS
    ///

    // Allows us to set a new output receiver metadata URL
    function setCustomMetadata(string memory _customMetadataUrl) external onlyOwner {
        customMetadataUrl = _customMetadataUrl;
    }

    function setLPAddress(address lpAddress_) external onlyOwner {
        lpAddress = lpAddress_;
    }

    function setAddressRegistry(address addressRegistry_) external override onlyOwner {
        addressRegistry = addressRegistry_;
    }

    // Set a new metadata url for address lock
    function setMetadata(string memory _addressMetadataUrl) external onlyOwner {
        addressMetadataUrl = _addressMetadataUrl;
    }

    // What contract will handle staking rewards
    function setRewardsHandler(address _handler) external onlyOwner {
        rewardsHandlerAddress = _handler;
    }

    function setCutoff(uint cutoff) external onlyOwner {
        previousStakingIDCutoff = cutoff;
    }

    function setOldStaking(address stake) external onlyOwner {
        oldStakingContract = stake;
    }

    function setAdditionalDepositsEnabled(bool enabled) external onlyOwner {
        additionalEnabled = enabled;
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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRegistryProvider.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';


/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiver is IRegistryProvider, IERC165 {

    function receiveRevestOutput(
        uint fnftId,
        address asset,
        address payable owner,
        uint quantity
    ) external;

    function getCustomMetadata(uint fnftId) external view returns (string memory);

    function getValue(uint fnftId) external view returns (uint);

    function getAsset(uint fnftId) external view returns (address);

    function getOutputDisplayValues(uint fnftId) external view returns (bytes memory);

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IOutputReceiver.sol";
import "./IRevest.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';


/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiverV2 is IOutputReceiver {

    // Future proofing for secondary callbacks during withdrawal
    // Could just use triggerOutputReceiverUpdate and call withdrawal function
    // But deliberately using reentry is poor form and reminds me too much of OAuth 2.0 
    function receiveSecondaryCallback(
        uint fnftId,
        address payable owner,
        uint quantity,
        IRevest.FNFTConfig memory config,
        bytes memory args
    ) external payable;

    // Allows for similar function to address lock, updating state while still locked
    // Called by the user directly
    function triggerOutputReceiverUpdate(
        uint fnftId,
        bytes memory args
    ) external;

    // This function should only ever be called when a split or additional deposit has occurred 
    function handleFNFTRemaps(uint fnftId, uint[] memory newFNFTIds, address caller, bool cleanup) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IOutputReceiverV2.sol";


/**
 * @title Provider interface for Revest FNFTs
 */
interface IOutputReceiverV3 is IOutputReceiverV2 {

    event DepositERC20OutputReceiver(address indexed mintTo, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);

    event DepositERC721OutputReceiver(address indexed mintTo, address indexed token, uint[] tokenIds, uint indexed fnftId, bytes extraData);

    event DepositERC1155OutputReceiver(address indexed mintTo, address indexed token, uint tokenId, uint amountTokens, uint indexed fnftId, bytes extraData);

    event WithdrawERC20OutputReceiver(address indexed caller, address indexed token, uint amountTokens, uint indexed fnftId, bytes extraData);

    event WithdrawERC721OutputReceiver(address indexed caller, address indexed token, uint[] tokenIds, uint indexed fnftId, bytes extraData);

    event WithdrawERC1155OutputReceiver(address indexed caller, address indexed token, uint tokenId, uint amountTokens, uint indexed fnftId, bytes extraData);

    function handleTimelockExtensions(uint fnftId, uint expiration, address caller) external;

    function handleAdditionalDeposit(uint fnftId, uint amountToDeposit, uint quantity, address caller) external;

    function handleSplitOperation(uint fnftId, uint[] memory proportions, uint quantity, address caller) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IRevest {
    event FNFTTimeLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        uint endTime,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTValueLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address compareTo,
        address oracleDispatch,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTAddressLockMinted(
        address indexed asset,
        address indexed from,
        uint indexed fnftId,
        address trigger,
        uint[] quantities,
        FNFTConfig fnftConfig
    );

    event FNFTWithdrawn(
        address indexed from,
        uint indexed fnftId,
        uint indexed quantity
    );

    event FNFTSplit(
        address indexed from,
        uint[] indexed newFNFTId,
        uint[] indexed proportions,
        uint quantity
    );

    event FNFTUnlocked(
        address indexed from,
        uint indexed fnftId
    );

    event FNFTMaturityExtended(
        address indexed from,
        uint indexed fnftId,
        uint indexed newExtendedTime
    );

    event FNFTAddionalDeposited(
        address indexed from,
        uint indexed newFNFTId,
        uint indexed quantity,
        uint amount
    );

    struct FNFTConfig {
        address asset; // The token being stored
        address pipeToContract; // Indicates if FNFT will pipe to another contract
        uint depositAmount; // How many tokens
        uint depositMul; // Deposit multiplier
        uint split; // Number of splits remaining
        uint depositStopTime; //
        bool maturityExtension; // Maturity extensions remaining
        bool isMulti; //
        bool nontransferrable; // False by default (transferrable) //
    }

    // Refers to the global balance for an ERC20, encompassing possibly many FNFTs
    struct TokenTracker {
        uint lastBalance;
        uint lastMul;
    }

    enum LockType {
        DoesNotExist,
        TimeLock,
        ValueLock,
        AddressLock
    }

    struct LockParam {
        address addressLock;
        uint timeLockExpiry;
        LockType lockType;
        ValueLock valueLock;
    }

    struct Lock {
        address addressLock;
        LockType lockType;
        ValueLock valueLock;
        uint timeLockExpiry;
        uint creationTime;
        bool unlocked;
    }

    struct ValueLock {
        address asset;
        address compareTo;
        address oracle;
        uint unlockValue;
        bool unlockRisingEdge;
    }

    function mintTimeLock(
        uint endTime,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintValueLock(
        address primaryAsset,
        address compareTo,
        uint unlockValue,
        bool unlockRisingEdge,
        address oracleDispatch,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function mintAddressLock(
        address trigger,
        bytes memory arguments,
        address[] memory recipients,
        uint[] memory quantities,
        IRevest.FNFTConfig memory fnftConfig
    ) external payable returns (uint);

    function withdrawFNFT(uint tokenUID, uint quantity) external;

    function unlockFNFT(uint tokenUID) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory proportions,
        uint quantity
    ) external returns (uint[] memory newFNFTIds);

    function depositAdditionalToFNFT(
        uint fnftId,
        uint amount,
        uint quantity
    ) external returns (uint);

    function extendFNFTMaturity(
        uint fnftId,
        uint endTime
    ) external returns (uint);

    function setFlatWeiFee(uint wethFee) external;

    function setERC20Fee(uint erc20) external;

    function getFlatWeiFee() external view returns (uint);

    function getERC20Fee() external view returns (uint);


}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

/**
 * @title Provider interface for Revest FNFTs
 * @dev
 *
 */
interface IAddressRegistry {

    function initialize(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external;

    function getAdmin() external view returns (address);

    function setAdmin(address admin) external;

    function getLockManager() external view returns (address);

    function setLockManager(address manager) external;

    function getTokenVault() external view returns (address);

    function setTokenVault(address vault) external;

    function getRevestFNFT() external view returns (address);

    function setRevestFNFT(address fnft) external;

    function getMetadataHandler() external view returns (address);

    function setMetadataHandler(address metadata) external;

    function getRevest() external view returns (address);

    function setRevest(address revest) external;

    function getDEX(uint index) external view returns (address);

    function setDex(address dex) external;

    function getRevestToken() external view returns (address);

    function setRevestToken(address token) external;

    function getRewardsHandler() external view returns(address);

    function setRewardsHandler(address esc) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLPs() external view returns (address);

    function setLPs(address liquidToken) external;

}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

interface IRewardsHandler {

    struct UserBalance {
        uint allocPoint; // Allocation points
        uint lastMul;
    }

    function receiveFee(address token, uint amount) external;

    function updateLPShares(uint fnftId, uint newShares) external;

    function updateBasicShares(uint fnftId, uint newShares) external;

    function getAllocPoint(uint fnftId, address token, bool isBasic) external view returns (uint);

    function claimRewards(uint fnftId, address caller) external returns (uint);

    function setStakingContract(address stake) external;

    function getRewards(uint fnftId, address token) external view returns (uint);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;


interface IFNFTHandler  {
    function mint(address account, uint id, uint amount, bytes memory data) external;

    function mintBatchRec(address[] memory recipients, uint[] memory quantities, uint id, uint newSupply, bytes memory data) external;

    function mintBatch(address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external;

    function setURI(string memory newuri) external;

    function burn(address account, uint id, uint amount) external;

    function burnBatch(address account, uint[] memory ids, uint[] memory amounts) external;

    function getBalance(address tokenHolder, uint id) external view returns (uint);

    function getSupply(uint fnftId) external view returns (uint);

    function getNextId() external view returns (uint);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRegistryProvider.sol";
import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

/**
 * @title Provider interface for Revest FNFTs
 * @dev Address locks MUST be non-upgradeable to be considered for trusted status
 * @author Revest
 */
interface IAddressLock is IRegistryProvider, IERC165{

    /// Creates a lock to the specified lockID
    /// @param fnftId the fnftId to map this lock to. Not recommended for typical locks, as it will break on splitting
    /// @param lockId the lockId to map this lock to. Recommended uint for storing references to lock configurations
    /// @param arguments an abi.encode() bytes array. Allows frontend to encode and pass in an arbitrary set of parameters
    /// @dev creates a lock for the specified lockId. Will be called during the creation process for address locks when the address
    ///      of a contract implementing this interface is passed in as the "trigger" address for minting an address lock. The bytes
    ///      representing any parameters this lock requires are passed through to this method, where abi.decode must be call on them
    function createLock(uint fnftId, uint lockId, bytes memory arguments) external;

    /// Updates a lock at the specified lockId
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @param arguments an abi.encode() bytes array. Allows frontend to encode and pass in an arbitrary set of parameters
    /// @dev updates a lock for the specified lockId. Will be called by the frontend from the information section if an update is requested
    ///      can further accept and decode parameters to use in modifying the lock's config or triggering other actions
    ///      such as triggering an on-chain oracle to update
    function updateLock(uint fnftId, uint lockId, bytes memory arguments) external;

    /// Whether or not the lock can be unlocked
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @dev this method is called during the unlocking and withdrawal processes by the Revest contract - it is also used by the frontend
    ///      if this method is returning true and someone attempts to unlock or withdraw from an FNFT attached to the requested lock, the request will succeed
    /// @return whether or not this lock may be unlocked
    function isUnlockable(uint fnftId, uint lockId) external view returns (bool);

    /// Provides an encoded bytes arary that represents values this lock wants to display on the info screen
    /// Info to decode these values is provided in the metadata file
    /// @param fnftId the fnftId that can map to a lock config stored in implementing contracts. Not recommended, as it will break on splitting
    /// @param lockId the lockId that maps to the lock config which should be updated. Recommended for retrieving references to lock configurations
    /// @dev used by the frontend to fetch on-chain data on the state of any given lock
    /// @return a bytes array that represents the result of calling abi.encode on values which the developer wants to appear on the frontend
    function getDisplayValues(uint fnftId, uint lockId) external view returns (bytes memory);

    /// Maps to a URL, typically IPFS-based, that contains information on how to encode and decode paramters sent to and from this lock
    /// Please see additional documentation for JSON config info
    /// @dev this method will be called by the frontend only but is crucial to properly implement for proper minting and information workflows
    /// @return a URL to the JSON file containing this lock's metadata schema
    function getMetadata() external view returns (string memory);

    /// Whether or not this lock will need updates and should display the option for them
    /// @dev this will be called by the frontend to determine if update inputs and buttons should be displayed
    /// @return whether or not the locks created by this contract will need updates
    function needsUpdate() external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "../interfaces/IAddressRegistry.sol";
import "../interfaces/ITokenVault.sol";
import "../interfaces/ILockManager.sol";

interface IRegistryProvider {
    function setAddressRegistry(address revest) external;

    function getAddressRegistry() external view returns (address);
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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRevest.sol";

interface ITokenVault {

    function createFNFT(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig,
        uint quantity,
        address from
    ) external;

    function withdrawToken(
        uint fnftId,
        uint quantity,
        address user
    ) external;

    function depositToken(
        uint fnftId,
        uint amount,
        uint quantity
    ) external;

    function cloneFNFTConfig(IRevest.FNFTConfig memory old) external returns (IRevest.FNFTConfig memory);

    function mapFNFTToToken(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig
    ) external;

    function handleMultipleDeposits(
        uint fnftId,
        uint newFNFTId,
        uint amount
    ) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory newFNFTIds,
        uint[] memory proportions,
        uint quantity
    ) external;

    function getFNFT(uint fnftId) external view returns (IRevest.FNFTConfig memory);
    function getFNFTCurrentValue(uint fnftId) external view returns (uint);
    function getNontransferable(uint fnftId) external view returns (bool);
    function getSplitsRemaining(uint fnftId) external view returns (uint);
}

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRevest.sol";

interface ILockManager {

    function createLock(uint fnftId, IRevest.LockParam memory lock) external returns (uint);

    function getLock(uint lockId) external view returns (IRevest.Lock memory);

    function fnftIdToLockId(uint fnftId) external view returns (uint);

    function fnftIdToLock(uint fnftId) external view returns (IRevest.Lock memory);

    function pointFNFTToLock(uint fnftId, uint lockId) external;

    function lockTypes(uint tokenId) external view returns (IRevest.LockType);

    function unlockFNFT(uint fnftId, address sender) external returns (bool);

    function getLockMaturity(uint fnftId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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