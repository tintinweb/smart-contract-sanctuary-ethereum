// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "Ownable.sol";
import "IGeminonOracle.sol";
import "IGenesisLiquidityPool.sol";
import "ISCMinter.sol";
import "TimeLocks.sol";


/**
* @title GeminonOracle
* @author Geminon Protocol
* @notice Protocol oracle. Performs both information
* functions, coordination functions and safety functions.
*/
contract GeminonOracle is IGeminonOracle, Ownable, TimeLocks {
    
    bool public isAnyPoolMigrating;
    bool public isAnyPoolRemoving;

    address public scMinter;
    address public treasuryLender;
    address public feesCollector;
    address[] public pools;

    uint64 public ageSCMinter;
    uint64 public ageTreasuryLender;
    uint64 public ageFeesCollector;

    bool public isMigratingMinter;
    address public newMinter;

    mapping(address => bool) public isPool;
    mapping(address => bool) public isMigratingPool;
    mapping(address => bool) public isRemovingPool;
    mapping(address => uint64) public poolAge;


    modifier onlyPool {
        require(isPool[msg.sender]);
        _;
    }

    modifier onlyMinter {
        require(msg.sender == scMinter);
        _;
    }


    constructor(address[] memory _pools) {
        for (uint16 i=0; i<_pools.length; i++) {
            _addPool(_pools[i]);
            poolAge[_pools[i]] = uint64(block.timestamp);
        }

        ageSCMinter = type(uint64).max;
        ageTreasuryLender = type(uint64).max;
        ageFeesCollector = type(uint64).max;
    }


    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                          INITIALIZATION                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @notice Initializes the address of the stablecoin minter
    /// @dev this function can only be used once as it requires that the
    /// address hasn't been already initialized. To update the address 
    /// use the requestAddressChange() and applyMinterChange() functions.
    function setSCMinter(address scMinter_) external onlyOwner {
        require(scMinter == address(0));
        require(scMinter_ != address(0));

        scMinter = scMinter_;
        ageSCMinter = uint64(block.timestamp);
    }

    /// @notice Initializes the address of the treasury lender.
    /// @dev this function can only be used once as it requires that the
    /// address hasn't been already initialized. To update the address 
    /// use the requestAddressChange() and applyLenderChange() functions.
    function setTreasuryLender(address lender) external onlyOwner {
        require(treasuryLender == address(0));
        require(lender != address(0));
        
        treasuryLender = lender;
        ageTreasuryLender = uint64(block.timestamp);
    }

    /// @dev Set the address of the fees collector contract.
    /// This function can be used anytime as it has no impact on the
    /// pool or the users. Can be reset to 0.
    function setCollector(address feesCollector_) external onlyOwner {
        feesCollector = feesCollector_;
        ageFeesCollector = uint64(block.timestamp);
    }

    
    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                         POOLS MIGRATION                            +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @dev Adds a new liquitidty pool to the oracle. Timelock 7 days.
    function addPool(address newPool) external onlyOwner {
        require(changeRequests[address(0)].changeRequested); // dev: Not requested
        require(changeRequests[address(0)].timestampRequest != 0); // dev: Timestamp request zero
        require(block.timestamp - changeRequests[address(0)].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[address(0)].newAddressRequested != address(0)); // dev: Address zero
        require(changeRequests[address(0)].newAddressRequested == newPool); // dev: Address not requested

        changeRequests[address(0)].changeRequested = false;
        changeRequests[address(0)].newAddressRequested = address(0);
        changeRequests[address(0)].timestampRequest = type(uint64).max;

        _addPool(newPool);
    }

    /// @notice Remove a liquitidty pool from the oracle. Timelock 7 days.
    function removePool(address pool) external onlyOwner {
        require(changeRequests[pool].changeRequested); // dev: Not requested
        require(changeRequests[pool].timestampRequest != 0); // dev: Timestamp request zero
        require(block.timestamp - changeRequests[pool].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[pool].newAddressRequested == address(0)); // dev: New address not zero

        changeRequests[pool].changeRequested = false;
        changeRequests[pool].newAddressRequested = pool;
        changeRequests[pool].timestampRequest = type(uint64).max;

        _removePool(pool);
    }


    /// @dev Register a request to migrate a pool. The owner must
    /// register a changeAddress request 7 days prior to execute
    /// the migration request.
    /// This function can only be called from a valid pool
    /// contract. It is called from the requestMigration()
    /// function. 
    function requestMigratePool(address newPool) external onlyPool {
        require(!isAnyPoolMigrating);
        require(!isMigratingPool[msg.sender]);
        require(isPool[newPool]);
        require(changeRequests[msg.sender].changeRequested); // dev: Not requested
        require(changeRequests[msg.sender].timestampRequest != 0); // dev: Timestamp request zero
        require(block.timestamp - changeRequests[msg.sender].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[msg.sender].newAddressRequested != msg.sender); // dev: Same address
        require(changeRequests[msg.sender].newAddressRequested == newPool); // dev: Address not requested

        changeRequests[msg.sender].changeRequested = false;
        changeRequests[msg.sender].newAddressRequested = msg.sender;
        changeRequests[msg.sender].timestampRequest = type(uint64).max;

        isAnyPoolMigrating = true;
        isMigratingPool[msg.sender] = true;
    }

    /// @dev Notifies the oracle that the pool migration
    /// has been done and removes the pool from the list of pools.
    function setMigrationDone() external onlyPool {
        require(isAnyPoolMigrating, "Not any pool migrating");
        require(isMigratingPool[msg.sender], "Pool is not migrating");

        isAnyPoolMigrating = false;
        isMigratingPool[msg.sender] = false;
        _removePool(msg.sender);
    }

    /// @dev Cancels a requested pool migration
    function cancelMigration() external onlyPool {
        isAnyPoolMigrating = false;
        isMigratingPool[msg.sender] = false;
    }


    /// @dev Register a request to remove a pool.
    /// This function can only be called from a valid pool
    /// contract. It is called from the requestRemove()
    /// function. 
    function requestRemovePool() external onlyPool {
        require(!isAnyPoolRemoving);
        require(!isRemovingPool[msg.sender]);
        require(changeRequests[msg.sender].changeRequested); // dev: Not requested
        require(changeRequests[msg.sender].timestampRequest != 0); // dev: Timestamp request zero
        require(block.timestamp - changeRequests[msg.sender].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[msg.sender].newAddressRequested != msg.sender); // dev: Same address
        require(changeRequests[msg.sender].newAddressRequested == address(0)); // dev: Address not requested

        changeRequests[msg.sender].changeRequested = false;
        changeRequests[msg.sender].newAddressRequested = msg.sender;
        changeRequests[msg.sender].timestampRequest = type(uint64).max;

        isAnyPoolRemoving = true;
        isRemovingPool[msg.sender] = true;
    }

    /// @notice Notifies the oracle that the pool removal
    /// has been done and removes the pool from the list of pools.
    function setRemoveDone() external onlyPool {
        require(isAnyPoolRemoving);
        require(isRemovingPool[msg.sender]);

        isAnyPoolRemoving = false;
        isRemovingPool[msg.sender] = false;
        _removePool(msg.sender);
    }

    /// @notice Cancels a requested pool migration
    function cancelRemove() external onlyPool {
        isAnyPoolRemoving = false;
        isRemovingPool[msg.sender] = false;
    }


    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                         MINTER MIGRATION                           +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    function requestMigrateMinter(address newMinter_) external onlyMinter {
        require(!isMigratingMinter);
        require(changeRequests[scMinter].changeRequested); // dev: Not requested
        require(changeRequests[scMinter].timestampRequest != 0); // dev: Timestamp request zero
        require(block.timestamp - changeRequests[scMinter].timestampRequest > 7 days); // dev: Time elapsed
        require(changeRequests[scMinter].newAddressRequested != scMinter); // dev: Same address
        require(changeRequests[scMinter].newAddressRequested == newMinter_); // dev: Address not requested

        changeRequests[scMinter].changeRequested = false;
        changeRequests[scMinter].newAddressRequested = scMinter;
        changeRequests[scMinter].timestampRequest = type(uint64).max;

        isMigratingMinter = true;
        newMinter = newMinter_;
    }

    function setMinterMigrationDone() external onlyMinter {
        require(isMigratingMinter);

        scMinter = newMinter;
        ageSCMinter = uint64(block.timestamp);
        isMigratingMinter = false;
    }

    function cancelMinterMigration() external onlyMinter {
        isMigratingMinter = false;
        newMinter = address(0);
    }


    
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                     INFORMATIVE FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    
    /// @dev All pools must be initialized or this function will revert
    function getTotalCollatValue() public view returns(uint256 totalValue) {
        for (uint16 i=0; i<pools.length; i++)
            totalValue += IGenesisLiquidityPool(pools[i]).getCollateralValue();
        return totalValue;
    }

    /// @dev All pools must be initialized or this function will revert. Uses 18 decimals.
    function getPoolCollatWeight(address pool) public view returns(uint256 weight) {
        require(isPool[pool]); // dev: address is not pool
        
        uint256 totalValue = getTotalCollatValue();
        if (totalValue == 0)
            weight = IGenesisLiquidityPool(pool).poolWeight();
        else
            weight = (IGenesisLiquidityPool(pool).getCollateralValue() *1e18) / totalValue;
        
        return weight;
    }
    

    /// @dev All pools must be initialized or this function will revert
    function getSafePrice() public view returns(uint256) {
        uint256 wprice;
        uint256 weight;
        for (uint16 i=0; i<pools.length; i++) {
            weight = getPoolCollatWeight(pools[i]);
            wprice += (IGenesisLiquidityPool(pools[i]).meanPrice() * weight)/1e18;
        }
        return wprice;
    }

    function getLastPrice() public view returns(uint256) {
        uint256 price;
        for (uint16 i=0; i<pools.length; i++) 
            price += IGenesisLiquidityPool(pools[i]).lastPrice();
        
        return price / pools.length;
    }

    function getMeanVolume() public view returns(uint256) {
        uint256 volume;
        for (uint16 i=0; i<pools.length; i++) 
            volume += IGenesisLiquidityPool(pools[i]).meanVolume();
        
        return volume / pools.length;
    }

    function getLastVolume() public view returns(uint256) {
        uint256 volume;
        for (uint16 i=0; i<pools.length; i++) 
            volume += IGenesisLiquidityPool(pools[i]).lastVolume();
        
        return volume / pools.length;
    }
    
    function getTotalMintedGEX() public view returns(uint256) {
        int256 totalSupply;
        for (uint16 i=0; i<pools.length; i++)
            totalSupply += IGenesisLiquidityPool(pools[i]).mintedGEX();
        
        if (totalSupply < 0) totalSupply = 0;
        return uint256(totalSupply);
    }

    function getLockedAmountGEX() public view returns(uint256) {
        require(isPool[msg.sender] || msg.sender == owner()); // dev: invalid caller
        require(scMinter != address(0)); // dev: scMinter not set
        return ISCMinter(scMinter).getBalanceGEX();
    }

    function getHighestGEXPool() public view returns(address maxAddress) {
        uint256 balance;
        uint256 maxBalance;
        for (uint16 i=0; i<pools.length; i++) {
            balance = IGenesisLiquidityPool(pools[i]).balanceGEX();
            if (balance > maxBalance) {
                maxBalance = balance;
                maxAddress = address(pools[i]);
            }
        }
        return maxAddress;
    }


    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    // +                        INTERNAL FUNCTIONS                          +
    // ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    /// @notice Adds a new liquitidty pool to the oracle
    function _addPool(address newPool) private {
        require(newPool != address(0));
        pools.push(newPool);
        isPool[newPool] = true;
        poolAge[newPool] = uint64(block.timestamp);
    }

    /// @notice Remove a liquitidty pool from the oracle
    function _removePool(address pool) private {
        require(isPool[pool], "Is not pool");
        uint16 numPools = uint16(pools.length);
        
        for (uint16 i; i < numPools; i++) {
            if (pools[i] == pool) {
                pools[i] = pools[numPools - 1];
                pools.pop();
                break;
            }
        }
        isPool[pool] = false;
        poolAge[pool] = type(uint64).max;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
pragma solidity ^0.8.0;


interface IGeminonOracle {

    // +++++++++++++++++++  PUBLIC STATE VARIABLES  +++++++++++++++++++++++++

    function isAnyPoolMigrating() external view returns(bool);
    
    function isAnyPoolRemoving() external view returns(bool);

    function scMinter() external view returns(address);

    function treasuryLender() external view returns(address);
    
    function feesCollector() external view returns(address);

    function ageSCMinter() external view returns(uint64);

    function ageTreasuryLender() external view returns(uint64);
    
    function ageFeesCollector() external view returns(uint64);
    
    function isMigratingPool(address) external view returns(bool);
    
    function isRemovingPool(address) external view returns(bool);

    function isMigratingMinter() external view returns(bool);

    function isPool(address) external view returns(bool);

    function poolAge(address) external view returns(uint64);


    // ++++++++++++++++++++++++++  MIGRATIONS  ++++++++++++++++++++++++++++++

    function requestMigratePool(address newPool) external;

    function setMigrationDone() external;

    function cancelMigration() external;

    function requestRemovePool() external;

    function setRemoveDone() external;

    function cancelRemove() external;

    
    function requestMigrateMinter(address newMinter) external;

    function setMinterMigrationDone() external;

    function cancelMinterMigration() external;


    // ++++++++++++++++++++  INFORMATIVE FUNCTIONS  +++++++++++++++++++++++++

    function getSafePrice() external view returns(uint256);
    
    function getLastPrice() external view returns(uint256);

    function getMeanVolume() external view returns(uint256);

    function getLastVolume() external view returns(uint256);

    function getLockedAmountGEX() external view returns(uint256);

    function getTotalMintedGEX() external view returns(uint256);

    function getTotalCollatValue() external view returns(uint256);

    function getPoolCollatWeight(address pool) external view returns(uint256);

    function getHighestGEXPool() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ICollectible.sol";


interface IGenesisLiquidityPool is ICollectible {

    // +++++++++++++++++++  PUBLIC STATE VARIABLES  +++++++++++++++++++++++++

    function poolWeight() external view returns(uint16);
    
    function balanceCollateral() external view returns(uint256);

    function balanceGEX() external view returns(uint256);

    function mintedGEX() external view returns(int256);

    function meanPrice() external view returns(uint256);
    
    function lastPrice() external view returns(uint256);
    
    function meanVolume() external view returns(uint256);
    
    function lastVolume() external view returns(uint256);

    function isMigrationRequested() external view returns(bool);
    
    function isRemoveRequested() external view returns(bool);    
    

    // ++++++++++++++++++++++++++  MIGRATION  +++++++++++++++++++++++++++++++

    function receiveMigration(uint256 amountGEX, uint256 amountCollateral, uint256 initMintedAmount) external;

    function bailoutMinter() external returns(uint256);

    function lendCollateral(uint256 amount) external returns(uint256);

    function repayCollateral(uint256 amount) external returns(uint256);

    
    // ++++++++++++++++++++++++  USE FUNCTIONS  +++++++++++++++++++++++++++++
    
    function mintSwap(uint256 inCollatAmount, uint256 minOutGEXAmount) external;

    function redeemSwap(uint256 inGEXAmount, uint256 minOutCollatAmount) external;
    
    
    // ++++++++++++++++++++  INFORMATIVE FUNCTIONS  +++++++++++++++++++++++++

    function collateralPrice() external view returns(uint256);

    function collateralQuote() external view returns(uint256);

    function getCollateralValue() external view returns(uint256);

    function GEXPrice() external view returns(uint256);

    function GEXQuote() external view returns(uint256);

    function amountFeeMint(uint256 amountGEX) external view returns(uint256);

    function amountFeeRedeem(uint256 amountGEX) external view returns(uint256);

    function getMintInfo(uint256 inCollatAmount) external view returns(
        uint256 collateralPriceUSD, 
        uint256 gexPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outGEXAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    );

    function getRedeemInfo(uint256 inGEXAmount) external view returns(
        uint256 collateralPriceUSD, 
        uint256 gexPriceUSD,
        uint256 collatQuote,
        uint256 gexQuote,
        uint256 fee,
        uint256 feeAmount,
        uint256 outCollatAmount,
        uint256 finalGEXPriceUSD,
        uint256 priceImpact
    );

    function amountOutGEX(uint256 inCollatAmount) external view returns(uint256);

    function amountOutCollateral(uint256 inGEXAmount) external view returns(uint256);

    function variableFee(uint256 amountGEX, uint256 baseFee) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
* @title ICollectible
* @author Geminon Protocol
* @notice Interface for smart contracts whose fees have
* to be collected by the FeeCollector contract.
*/
interface ICollectible {
    function collectFees() external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ICollectible.sol";


interface ISCMinter is ICollectible {
    
    function receiveMigration(uint256 amountGEX) external;


    function mintStablecoin(address stablecoin, uint256 inAmountGEX) external ;

    function redeemStablecoin(address stablecoin, uint256 inAmountStablecoin) external;


    function getBalanceGEX() external view returns(uint256);

    function mintAmount(address stablecoin, uint256 amountGEX) external; 

    function redeemAmount(address stablecoin, uint256 amountStablecoin) external;

    function getSafeMintRatio(address stablecoin) external;

    function getSafeRedeemRatio(address stablecoin) external;
    

    function amountFeeMint(uint256 amountGEX) external view returns(uint256);

    function amountFeeRedeem(uint256 amountGEX) external view returns(uint256);

    function variableFee(uint256 amountGEX, uint256 baseFee) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";


/**
* @title TimeLocks
* @author Geminon Protocol
* @dev Utility to protect smart contracts against instant changes
* on critical infrastructure. Sets a two step procedure to change
* the address of a smart contract that is used by another contract.
*/
contract TimeLocks is Ownable {

    struct ContractChangeRequest {
        bool changeRequested;
        uint64 timestampRequest;
        address newAddressRequested;
    }

    mapping(address => ContractChangeRequest) public changeRequests;

    
    /// @dev Creates a request to change the address of a smart contract.
    function requestAddressChange(address actualContract, address newContract) 
        external 
        onlyOwner 
    {
        require(newContract != address(0)); // dev: address 0
        
        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: newContract
            });
        
        changeRequests[actualContract] = changeRequest;
    }

    /// @dev Creates a request to add a new address of a smart contract.
    function requestAddAddress(address newContract) external onlyOwner {
        require(newContract != address(0)); // dev: address 0

        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: newContract
            });
        
        changeRequests[address(0)] = changeRequest;
    }

    /// @dev Creates a request to remove the address of a smart contract.
    function requestRemoveAddress(address oldContract) external onlyOwner {
        require(oldContract != address(0)); // dev: address zero
        
        ContractChangeRequest memory changeRequest = 
            ContractChangeRequest({
                changeRequested: true, 
                timestampRequest: uint64(block.timestamp), 
                newAddressRequested: address(0)
            });
        
        changeRequests[oldContract] = changeRequest;
    }
}