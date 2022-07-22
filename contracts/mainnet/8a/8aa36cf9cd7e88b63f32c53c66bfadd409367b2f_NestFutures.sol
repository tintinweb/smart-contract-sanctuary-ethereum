/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

// Sources flattened with hardhat v2.5.0 https://hardhat.org

// File contracts/libs/TransferHelper.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value,gas:5000}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// File contracts/interfaces/INestFutures.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for Futures
interface INestFutures {
    
    struct FutureView {
        uint index;
        address tokenAddress;
        uint lever;
        bool orientation;
        
        uint balance;
        // Base price
        uint basePrice;
        // Base block
        uint baseBlock;
    }

    /// @dev New future event
    /// @param tokenAddress Target token address, 0 means eth
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @param index Index of the future
    event New(
        address tokenAddress, 
        uint lever,
        bool orientation,
        uint index
    );

    /// @dev Buy future event
    /// @param index Index of future
    /// @param nestAmount Amount of paid NEST
    event Buy(
        uint index,
        uint nestAmount,
        address owner
    );

    /// @dev Sell future event
    /// @param index Index of future
    /// @param amount Amount to sell
    /// @param owner The owner of future
    /// @param value Amount of NEST obtained
    event Sell(
        uint index,
        uint amount,
        address owner,
        uint value
    );

    /// @dev Settle future event
    /// @param index Index of future
    /// @param addr Target address
    /// @param sender Address of settler
    /// @param reward Liquidation reward
    event Settle(
        uint index,
        address addr,
        address sender,
        uint reward
    );
    
    /// @dev Returns the current value of target address in the specified future
    /// @param index Index of future
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    /// @param addr Target address
    function balanceOf(uint index, uint oraclePrice, address addr) external view returns (uint);

    /// @dev Find the futures of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given owner address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return futureArray Matched futures
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view returns (FutureView[] memory futureArray);

    /// @dev List futures
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return futureArray List of futures
    function list(uint offset, uint count, uint order) external view returns (FutureView[] memory futureArray);

    /// @dev Create future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param levers Levers of future
    /// @param orientation true: call, false: put
    function create(address tokenAddress, uint[] calldata levers, bool orientation) external;

    /// @dev Obtain the number of futures that have been created
    /// @return Number of futures created
    function getFutureCount() external view returns (uint);

    /// @dev Get information of future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @return Information of future
    function getFutureInfo(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view returns (FutureView memory);

    /// @dev Buy future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @param nestAmount Amount of paid NEST
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint nestAmount
    ) external payable;

    /// @dev Buy future direct
    /// @param index Index of future
    /// @param nestAmount Amount of paid NEST
    function buyDirect(uint index, uint nestAmount) external payable;

    /// @dev Sell future
    /// @param index Index of future
    /// @param amount Amount to sell
    function sell(uint index, uint amount) external payable;

    /// @dev Settle future
    /// @param index Index of future
    /// @param addresses Target addresses
    function settle(uint index, address[] calldata addresses) external payable;

    /// @dev K value is calculated by revised volatility
    /// @param sigmaSQ sigmaSQ for token
    /// @param p0 Last price (number of tokens equivalent to 2000 USD)
    /// @param bn0 Block number of the price p0
    /// @param p Latest price (number of tokens equivalent to 2000 USD)
    /// @param bn The block number of the price p
    function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) external view returns (uint k);

    /// @dev Calculate the impact cost
    /// @param vol Trade amount in NEST
    /// @return Impact cost
    function impactCost(uint vol) external pure returns (uint);
}


// File contracts/interfaces/INestVault.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Defines methods for Nest Vault
interface INestVault {

    /// @dev Approve allowance amount to target contract address
    /// @dev target Target contract address
    /// @dev limit Amount limit can transferred once
    function approve(address target, uint limit) external;

    /// @dev Transfer to by allowance
    /// @param to Target receive address
    /// @param amount Transfer amount
    function transferTo(address to, uint amount) external;
}


// File contracts/custom/ChainParameter.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Specific parameters for target chain
contract ChainParameter {
    
    // ETH:
    // Block average time in milliseconds. ethereum 14 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    uint constant BLOCK_TIME = 14000;
    // Minimal exercise block period. 180000
    uint constant MIN_PERIOD = 180000;
    // Minimal exercise block period for NestLPGuarantee. 180000
    uint constant MIN_EXERCISE_BLOCK = 180000;

    // // BSC:
    // // Block average time in milliseconds. ethereum 14 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    // uint constant BLOCK_TIME = 3000;
    // // Minimal exercise block period. 840000
    // uint constant MIN_PERIOD = 840000;
    // // Minimal exercise block period for NestLPGuarantee. 840000
    // uint constant MIN_EXERCISE_BLOCK = 840000;

    // // Polygon:
    // // Block average time in milliseconds. ethereum 14 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    // uint constant BLOCK_TIME = 2200;
    // // Minimal exercise block period. 1200000
    // uint constant MIN_PERIOD = 1200000;
    // // Minimal exercise block period for NestLPGuarantee. 1200000
    // uint constant MIN_EXERCISE_BLOCK = 1200000;

    // // KCC:
    // // Block average time in milliseconds. ethereum 14 seconds, BSC 3 seconds, polygon 2.2 seconds, KCC 3 seconds
    // uint constant BLOCK_TIME = 3000;
    // // Minimal exercise block period. 840000
    // uint constant MIN_PERIOD = 840000;
    // // Minimal exercise block period for NestLPGuarantee. 840000
    // uint constant MIN_EXERCISE_BLOCK = 840000;
}


// File contracts/interfaces/INestMapping.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev The interface defines methods for nest builtin contract address mapping
interface INestMapping {

    /// @dev Set the built-in contract address of the system
    /// @param nestTokenAddress Address of nest token contract
    /// @param nestNodeAddress Address of nest node contract
    /// @param nestLedgerAddress INestLedger implementation contract address
    /// @param nestMiningAddress INestMining implementation contract address for nest
    /// @param ntokenMiningAddress INestMining implementation contract address for ntoken
    /// @param nestPriceFacadeAddress INestPriceFacade implementation contract address
    /// @param nestVoteAddress INestVote implementation contract address
    /// @param nestQueryAddress INestQuery implementation contract address
    /// @param nnIncomeAddress NNIncome contract address
    /// @param nTokenControllerAddress INTokenController implementation contract address
    function setBuiltinAddress(
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    ) external;

    /// @dev Get the built-in contract address of the system
    /// @return nestTokenAddress Address of nest token contract
    /// @return nestNodeAddress Address of nest node contract
    /// @return nestLedgerAddress INestLedger implementation contract address
    /// @return nestMiningAddress INestMining implementation contract address for nest
    /// @return ntokenMiningAddress INestMining implementation contract address for ntoken
    /// @return nestPriceFacadeAddress INestPriceFacade implementation contract address
    /// @return nestVoteAddress INestVote implementation contract address
    /// @return nestQueryAddress INestQuery implementation contract address
    /// @return nnIncomeAddress NNIncome contract address
    /// @return nTokenControllerAddress INTokenController implementation contract address
    function getBuiltinAddress() external view returns (
        address nestTokenAddress,
        address nestNodeAddress,
        address nestLedgerAddress,
        address nestMiningAddress,
        address ntokenMiningAddress,
        address nestPriceFacadeAddress,
        address nestVoteAddress,
        address nestQueryAddress,
        address nnIncomeAddress,
        address nTokenControllerAddress
    );

    /// @dev Get address of nest token contract
    /// @return Address of nest token contract
    function getNestTokenAddress() external view returns (address);

    /// @dev Get address of nest node contract
    /// @return Address of nest node contract
    function getNestNodeAddress() external view returns (address);

    /// @dev Get INestLedger implementation contract address
    /// @return INestLedger implementation contract address
    function getNestLedgerAddress() external view returns (address);

    /// @dev Get INestMining implementation contract address for nest
    /// @return INestMining implementation contract address for nest
    function getNestMiningAddress() external view returns (address);

    /// @dev Get INestMining implementation contract address for ntoken
    /// @return INestMining implementation contract address for ntoken
    function getNTokenMiningAddress() external view returns (address);

    /// @dev Get INestPriceFacade implementation contract address
    /// @return INestPriceFacade implementation contract address
    function getNestPriceFacadeAddress() external view returns (address);

    /// @dev Get INestVote implementation contract address
    /// @return INestVote implementation contract address
    function getNestVoteAddress() external view returns (address);

    /// @dev Get INestQuery implementation contract address
    /// @return INestQuery implementation contract address
    function getNestQueryAddress() external view returns (address);

    /// @dev Get NNIncome contract address
    /// @return NNIncome contract address
    function getNnIncomeAddress() external view returns (address);

    /// @dev Get INTokenController implementation contract address
    /// @return INTokenController implementation contract address
    function getNTokenControllerAddress() external view returns (address);

    /// @dev Registered address. The address registered here is the address accepted by nest system
    /// @param key The key
    /// @param addr Destination address. 0 means to delete the registration information
    function registerAddress(string memory key, address addr) external;

    /// @dev Get registered address
    /// @param key The key
    /// @return Destination address. 0 means empty
    function checkAddress(string memory key) external view returns (address);
}


// File contracts/interfaces/INestGovernance.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This interface defines the governance methods
interface INestGovernance is INestMapping {

    /// @dev Set governance authority
    /// @param addr Destination address
    /// @param flag Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function setGovernance(address addr, uint flag) external;

    /// @dev Get governance rights
    /// @param addr Destination address
    /// @return Weight. 0 means to delete the governance permission of the target address. Weight is not 
    ///        implemented in the current system, only the difference between authorized and unauthorized. 
    ///        Here, a uint96 is used to represent the weight, which is only reserved for expansion
    function getGovernance(address addr) external view returns (uint);

    /// @dev Check whether the target address has governance rights for the given target
    /// @param addr Destination address
    /// @param flag Permission weight. The permission of the target address must be greater than this weight 
    /// to pass the check
    /// @return True indicates permission
    function checkGovernance(address addr, uint flag) external view returns (bool);
}


// File contracts/NestBase.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Base contract of nest
contract NestBase {

    /// @dev INestGovernance implementation contract address
    address public _governance;

    /// @dev To support open-zeppelin/upgrades
    /// @param governance INestGovernance implementation contract address
    function initialize(address governance) public virtual {
        require(_governance == address(0), "NEST:!initialize");
        _governance = governance;
    }

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    /// @param newGovernance INestGovernance implementation contract address
    function update(address newGovernance) public virtual {

        address governance = _governance;
        require(governance == msg.sender || INestGovernance(governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _governance = newGovernance;
    }

    //---------modifier------------

    modifier onlyGovernance() {
        require(INestGovernance(_governance).checkGovernance(msg.sender, 0), "NEST:!gov");
        _;
    }

    modifier noContract() {
        require(msg.sender == tx.origin, "NEST:!contract");
        _;
    }
}


// File contracts/custom/NestFrequentlyUsed.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This contract include frequently used data
contract NestFrequentlyUsed is NestBase {

    // ETH:
    // Address of nest token
    address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;
    // Address of NestOpenPrice contract
    address constant NEST_OPEN_PRICE = 0xE544cF993C7d477C7ef8E91D28aCA250D135aa03;
    // Address of nest vault
    address constant NEST_VAULT_ADDRESS = 0x12858F7f24AA830EeAdab2437480277E92B0723a;

    // // BSC:
    // // Address of nest token
    // address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;
    // // Address of NestOpenPrice contract
    // address constant NEST_OPEN_PRICE = 0x09CE0e021195BA2c1CDE62A8B187abf810951540;
    // // Address of nest vault
    // address constant NEST_VAULT_ADDRESS = 0x65e7506244CDdeFc56cD43dC711470F8B0C43beE;

    // // Polygon:
    // // Address of nest token
    // address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;
    // // Address of NestOpenPrice contract
    // address constant NEST_OPEN_PRICE = 0x09CE0e021195BA2c1CDE62A8B187abf810951540;
    // // Address of nest vault
    // address constant NEST_VAULT_ADDRESS;

    // // KCC:
    // // Address of nest token
    // address constant NEST_TOKEN_ADDRESS = 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7;
    // // Address of NestOpenPrice contract
    // address constant NEST_OPEN_PRICE = 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6;
    // // Address of nest vault
    // address constant NEST_VAULT_ADDRESS;

    // USDT base
    uint constant USDT_BASE = 1 ether;
}


// File contracts/interfaces/INestBatchPrice2.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This contract implemented the mining logic of nest
interface INestBatchPrice2 {

    /// @dev Get the latest trigger price
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param payback Address to receive refund
    /// @return prices Price array, i * 2 is the block where the ith price is located, and i * 2 + 1 is the ith price
    function triggeredPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Get the full information of latest trigger price
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param payback Address to receive refund
    /// @return prices Price array, i * 4 is the block where the ith price is located, i * 4 + 1 is the ith price,
    /// i * 4 + 2 is the ith average price and i * 4 + 3 is the ith volatility
    function triggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Find the price at block number
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param height Destination block number
    /// @param payback Address to receive refund
    /// @return prices Price array, i * 2 is the block where the ith price is located, and i * 2 + 1 is the ith price
    function findPrice(
        uint channelId,
        uint[] calldata pairIndices, 
        uint height, 
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Get the last (num) effective price
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param count The number of prices that want to return
    /// @param payback Address to receive refund
    /// @return prices Result array, i * count * 2 to (i + 1) * count * 2 - 1 are 
    /// the price results of group i quotation pairs
    function lastPriceList(
        uint channelId, 
        uint[] calldata pairIndices, 
        uint count, 
        address payback
    ) external payable returns (uint[] memory prices);

    /// @dev Returns lastPriceList and triggered price info
    /// @param channelId Target channelId
    /// @param pairIndices Array of pair indices
    /// @param count The number of prices that want to return
    /// @param payback Address to receive refund
    /// @return prices result of group i quotation pair. Among them, the first two count * are the latest prices, 
    /// and the last four are: trigger price block number, trigger price, average price and volatility
    function lastPriceListAndTriggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        uint count, 
        address payback
    ) external payable returns (uint[] memory prices);
}


// File contracts/custom/NestPriceAdapter.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev PriceAdapter from INestBatchPrice2
contract NestPriceAdapter is NestFrequentlyUsed {
    
    // Token configuration
    struct TokenConfig {
        // The channelId for call nest price
        uint16 channelId;
        // The pairIndex for call nest price
        uint16 pairIndex;

        // SigmaSQ for token
        uint64 sigmaSQ;
        // MIU_LONG for token
        uint64 miuLong;
        // MIU_SHORT for token
        uint64 miuShort;
    }

    // Post unit: 2000usd
    uint constant POST_UNIT = 2000 * USDT_BASE;

    function _pairIndices(uint pairIndex) private pure returns (uint[] memory pairIndices) {
        pairIndices = new uint[](1);
        pairIndices[0] = pairIndex;
    }

    // Query latest 2 price
    function _lastPriceList(
        TokenConfig memory tokenConfig, 
        uint fee, 
        address payback
    ) internal returns (uint[] memory prices) {
        prices = INestBatchPrice2(NEST_OPEN_PRICE).lastPriceList {
            value: fee
        } (uint(tokenConfig.channelId), _pairIndices(uint(tokenConfig.pairIndex)), 2, payback);

        prices[1] = _toUSDTPrice(prices[1]);
        prices[3] = _toUSDTPrice(prices[3]);
    }

    // Query latest price
    function _latestPrice(
        TokenConfig memory tokenConfig, 
        uint fee, 
        address payback
    ) internal returns (uint oraclePrice) {
        uint[] memory prices = INestBatchPrice2(NEST_OPEN_PRICE).lastPriceList {
            value: fee
        } (uint(tokenConfig.channelId), _pairIndices(uint(tokenConfig.pairIndex)), 1, payback);

        oraclePrice = _toUSDTPrice(prices[1]);
    }

    // Find price by blockNumber
    function _findPrice(
        TokenConfig memory tokenConfig, 
        uint blockNumber, 
        uint fee, 
        address payback
    ) internal returns (uint oraclePrice) {
        uint[] memory prices = INestBatchPrice2(NEST_OPEN_PRICE).findPrice {
            value: fee
        } (uint(tokenConfig.channelId), _pairIndices(uint(tokenConfig.pairIndex)), blockNumber, payback);

        oraclePrice = _toUSDTPrice(prices[1]);
    }

    // Convert to usdt based price
    function _toUSDTPrice(uint rawPrice) internal pure returns (uint) {
        return POST_UNIT * 1 ether / rawPrice;
    }
}


// File contracts/NestFutures.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev Futures
contract NestFutures is ChainParameter, NestFrequentlyUsed, NestPriceAdapter, INestFutures {

    /// @dev Account information
    struct Account {
        // Amount of margin
        uint128 balance;
        // Base price
        uint64 basePrice;
        // Base block
        uint32 baseBlock;
    }

    /// @dev Future information
    struct FutureInfo {
        // Target token address
        address tokenAddress; 
        // Lever of future
        uint32 lever;
        // true: call, false: put
        bool orientation;

        // Token index in _tokenConfigs
        uint16 tokenIndex;
        
        // Account mapping
        mapping(address=>Account) accounts;
    }

    // Minimum balance quantity. If the balance is less than this value, it will be liquidated
    uint constant MIN_VALUE = 10 ether;

    // Mapping from composite key to future index
    mapping(uint=>uint) _futureMapping;

    // Future array, element of 0 is place holder
    FutureInfo[] _futures;

    // token to index mapping, address=>tokenConfigIndex + 1
    mapping(address=>uint) _tokenMapping;

    // Token configs
    TokenConfig[] _tokenConfigs;

    constructor() {
    }

    /// @dev To support open-zeppelin/upgrades
    /// @param governance INestGovernance implementation contract address
    function initialize(address governance) public override {
        super.initialize(governance);
        _futures.push();
    }

    /// @dev Register token configuration
    /// @param tokenAddress Target token address, 0 means eth
    /// @param tokenConfig token configuration
    function register(address tokenAddress, TokenConfig calldata tokenConfig) external onlyGovernance {
        // Get registered tokenIndex by tokenAddress
        uint index = _tokenMapping[tokenAddress];
        
        // index == 0 means token not registered, add
        if (index == 0) {
            // Add tokenConfig to array
            _tokenConfigs.push(tokenConfig);
            // Record index + 1
            index = _tokenConfigs.length;
            require(index < 0x10000, "NF:too much tokenConfigs");
            _tokenMapping[tokenAddress] = index;
        } else {
            // Update tokenConfig
            _tokenConfigs[index - 1] = tokenConfig;
        }
    }

    /// @dev Returns the current value of target address in the specified future
    /// @param index Index of future
    /// @param oraclePrice Current price from oracle, usd based, 18 decimals
    /// @param addr Target address
    function balanceOf(uint index, uint oraclePrice, address addr) external view override returns (uint) {
        FutureInfo storage fi = _futures[index];
        Account memory account = fi.accounts[addr];
        return _balanceOf(
            _tokenConfigs[fi.tokenIndex],
            uint(account.balance), 
            _decodeFloat(account.basePrice), 
            uint(account.baseBlock),
            oraclePrice, 
            fi.orientation, 
            uint(fi.lever)
        );
    }

    /// @dev Find the futures of the target address (in reverse order)
    /// @param start Find forward from the index corresponding to the given owner address 
    /// (excluding the record corresponding to start)
    /// @param count Maximum number of records returned
    /// @param maxFindCount Find records at most
    /// @param owner Target address
    /// @return futureArray Matched futures
    function find(
        uint start, 
        uint count, 
        uint maxFindCount, 
        address owner
    ) external view override returns (FutureView[] memory futureArray) {
        futureArray = new FutureView[](count);
        // Calculate search region
        FutureInfo[] storage futures = _futures;

        // Loop from start to end
        uint end = 0;
        // start is 0 means Loop from the last item
        if (start == 0) {
            start = futures.length;
        }
        // start > maxFindCount, so end is not 0
        if (start > maxFindCount) {
            end = start - maxFindCount;
        }
        
        // Loop lookup to write qualified records to the buffer
        for (uint index = 0; index < count && start > end;) {
            FutureInfo storage fi = futures[--start];
            if (uint(fi.accounts[owner].balance) > 0) {
                futureArray[index++] = _toFutureView(fi, start, owner);
            }
        }
    }

    /// @dev List futures
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return futureArray List of futures
    function list(
        uint offset, 
        uint count, 
        uint order
    ) external view override returns (FutureView[] memory futureArray) {
        // Load futures
        FutureInfo[] storage futures = _futures;
        // Create result array
        futureArray = new FutureView[](count);
        uint length = futures.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {
            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                FutureInfo storage fi = futures[--index];
                futureArray[i++] = _toFutureView(fi, index, msg.sender);
            }
        } 
        // Positive order
        else {
            uint index = offset;
            uint end = index + count;
            if (end > length) {
                end = length;
            }
            while (index < end) {
                futureArray[i++] = _toFutureView(futures[index], index, msg.sender);
                ++index;
            }
        }
    }

    /// @dev Create future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param levers Levers of future
    /// @param orientation true: call, false: put
    function create(address tokenAddress, uint[] calldata levers, bool orientation) external override onlyGovernance {

        // Get registered tokenIndex by tokenAddress
        // _tokenMapping[tokenAddress] is less than 0x10000, so it can convert to uint16
        // If tokenAddress not registered, _tokenMapping[tokenAddress] is 0, subtract by 1 will failed
        // This make sure tokenAddress must registered
        uint16 tokenIndex = uint16(_tokenMapping[tokenAddress] - 1);

        // Create futures
        for (uint i = 0; i < levers.length; ++i) {
            uint lever = levers[i];

            // Check if the future exists
            uint key = _getKey(tokenAddress, lever, orientation);
            uint index = _futureMapping[key];
            require(index == 0, "NF:exists");

            // Create future
            index = _futures.length;
            FutureInfo storage fi = _futures.push();
            fi.tokenAddress = tokenAddress;
            fi.lever = uint32(lever);
            fi.orientation = orientation;
            fi.tokenIndex = tokenIndex;

            _futureMapping[key] = index;

            // emit New event
            emit New(tokenAddress, lever, orientation, index);
        }
    }

    /// @dev Obtain the number of futures that have been created
    /// @return Number of futures created
    function getFutureCount() external view override returns (uint) {
        return _futures.length;
    }

    /// @dev Get information of future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @return Information of future
    function getFutureInfo(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) external view override returns (FutureView memory) {
        uint index = _futureMapping[_getKey(tokenAddress, lever, orientation)];
        return _toFutureView(_futures[index], index, msg.sender);
    }

    /// @dev Buy future
    /// @param tokenAddress Target token address, 0 means eth
    /// @param lever Lever of future
    /// @param orientation true: call, false: put
    /// @param nestAmount Amount of paid NEST
    function buy(
        address tokenAddress,
        uint lever,
        bool orientation,
        uint nestAmount
    ) external payable override {
        return buyDirect(_futureMapping[_getKey(tokenAddress, lever, orientation)], nestAmount);
    }

    /// @dev Buy future direct
    /// @param index Index of future
    /// @param nestAmount Amount of paid NEST
    function buyDirect(uint index, uint nestAmount) public payable override {

        require(index != 0, "NF:not exist");
        require(nestAmount >= 50 ether, "NF:at least 50 NEST");

        // 1. Transfer NEST from user
        //DCU(DCU_TOKEN_ADDRESS).burn(msg.sender, nestAmount);
        TransferHelper.safeTransferFrom(NEST_TOKEN_ADDRESS, msg.sender, NEST_VAULT_ADDRESS, nestAmount);

        FutureInfo storage fi = _futures[index];
        bool orientation = fi.orientation;
        
        // 2. Query oracle price
        // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
        // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
        // When merger, s0 use recorded price, s1 use corrected by k
        TokenConfig memory tokenConfig = _tokenConfigs[uint(fi.tokenIndex)];
        uint oraclePrice = _queryPrice(nestAmount, tokenConfig, orientation, msg.sender);

        // 3. Merger price
        Account memory account = fi.accounts[msg.sender];
        uint basePrice = _decodeFloat(account.basePrice);
        uint balance = uint(account.balance);
        uint newPrice = oraclePrice;
        if (uint(account.baseBlock) > 0) {
            newPrice = (balance + nestAmount) * oraclePrice * basePrice / (
                basePrice * nestAmount + (balance << 64) * oraclePrice / _expMiuT(
                    uint(orientation ? tokenConfig.miuLong : tokenConfig.miuShort), 
                    uint(account.baseBlock)
                )
            );
        }
        
        // 4. Update account
        account.balance = _toUInt128(balance + nestAmount);
        account.basePrice = _encodeFloat(newPrice);
        account.baseBlock = uint32(block.number);
        fi.accounts[msg.sender] = account;

        // emit Buy event
        emit Buy(index, nestAmount, msg.sender);
    }

    /// @dev Sell future
    /// @param index Index of future
    /// @param amount Amount to sell
    function sell(uint index, uint amount) external payable override {

        require(index != 0, "NF:not exist");
        
        // 1. Load the future
        FutureInfo storage fi = _futures[index];
        bool orientation = fi.orientation;

        // 2. Query oracle price
        // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
        // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
        // When merger, s0 use recorded price, s1 use corrected by k
        TokenConfig memory tokenConfig = _tokenConfigs[uint(fi.tokenIndex)];
        uint oraclePrice = _queryPrice(0, tokenConfig, !orientation, msg.sender);

        // 3. Update account
        Account memory account = fi.accounts[msg.sender];
        account.balance -= _toUInt128(amount);
        fi.accounts[msg.sender] = account;

        // 4. Transfer NEST to user
        uint value = _balanceOf(
            tokenConfig,
            amount, 
            _decodeFloat(account.basePrice), 
            uint(account.baseBlock),
            oraclePrice, 
            orientation, 
            uint(fi.lever)
        );
        //DCU(DCU_TOKEN_ADDRESS).mint(msg.sender, value);
        INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, value);

        // emit Sell event
        emit Sell(index, amount, msg.sender, value);
    }

    /// @dev Settle future
    /// @param index Index of future
    /// @param addresses Target addresses
    function settle(uint index, address[] calldata addresses) external payable override {

        require(index != 0, "NF:not exist");

        // 1. Load the future
        FutureInfo storage fi = _futures[index];
        uint lever = uint(fi.lever);
        require(lever > 1, "NF:lever must greater than 1");

        bool orientation = fi.orientation;
            
        // 2. Query oracle price
        // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
        // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
        // When merger, s0 use recorded price, s1 use corrected by k
        TokenConfig memory tokenConfig = _tokenConfigs[uint(fi.tokenIndex)];
        uint oraclePrice = _queryPrice(0, tokenConfig, !orientation, msg.sender);

        // 3. Loop and settle
        uint reward = 0;
        for (uint i = addresses.length; i > 0;) {
            address acc = addresses[--i];

            // 4. Update account
            Account memory account = fi.accounts[acc];
            uint balance = _balanceOf(
                tokenConfig,
                uint(account.balance), 
                _decodeFloat(account.basePrice), 
                uint(account.baseBlock),
                oraclePrice, 
                orientation, 
                lever
            );

            // 5. Settle logic
            // lever is great than 1, and balance less than a regular value, can be liquidated
            // the regular value is: Max(balance * lever * 2%, MIN_VALUE)
            uint minValue = uint(account.balance) * lever / 50;
            if (balance < (minValue < MIN_VALUE ? MIN_VALUE : minValue)) {
                fi.accounts[acc] = Account(uint128(0), uint64(0), uint32(0));
                reward += balance;
                emit Settle(index, acc, msg.sender, balance);
            }
        }

        // 6. Transfer NEST to user
        if (reward > 0) {
            //DCU(DCU_TOKEN_ADDRESS).mint(msg.sender, reward);
            INestVault(NEST_VAULT_ADDRESS).transferTo(msg.sender, reward);
        }
    }

    // Compose key by tokenAddress, lever and orientation
    function _getKey(
        address tokenAddress, 
        uint lever,
        bool orientation
    ) private pure returns (uint) {
        //return keccak256(abi.encodePacked(tokenAddress, lever, orientation));
        require(lever < 0x100000000, "NF:lever too large");
        return (uint(uint160(tokenAddress)) << 96) | (lever << 8) | (orientation ? 1 : 0);
    }

    // Query price
    function _queryPrice(
        uint nestAmount, 
        TokenConfig memory tokenConfig, 
        bool enlarge, 
        address payback
    ) private returns (uint oraclePrice) {

        // Query price from oracle
        uint[] memory prices = _lastPriceList(tokenConfig, msg.value, payback);
        
        // Convert to usdt based price
        oraclePrice = prices[1];
        uint k = calcRevisedK(uint(tokenConfig.sigmaSQ), prices[3], prices[2], oraclePrice, prices[0]);

        // When call, the base price multiply (1 + k), and the sell price divide (1 + k)
        // When put, the base price divide (1 + k), and the sell price multiply (1 + k)
        // When merger, s0 use recorded price, s1 use corrected by k
        if (enlarge) {
            oraclePrice = oraclePrice * (1 ether + k + impactCost(nestAmount)) / 1 ether;
        } else {
            oraclePrice = oraclePrice * 1 ether / (1 ether + k + impactCost(nestAmount));
        }
    }

    /// @dev Calculate the impact cost
    /// @param vol Trade amount in NEST
    /// @return Impact cost
    function impactCost(uint vol) public pure override returns (uint) {
        //impactCost = vol / 10000 / 1000;
        return vol / 10000000;
    }

    /// @dev K value is calculated by revised volatility
    /// @param sigmaSQ sigmaSQ for token
    /// @param p0 Last price (number of tokens equivalent to 2000 USD)
    /// @param bn0 Block number of the price p0
    /// @param p Latest price (number of tokens equivalent to 2000 USD)
    /// @param bn The block number of the price p
    function calcRevisedK(uint sigmaSQ, uint p0, uint bn0, uint p, uint bn) public view override returns (uint k) {
        uint sigmaISQ = p * 1 ether / p0;
        if (sigmaISQ > 1 ether) {
            sigmaISQ -= 1 ether;
        } else {
            sigmaISQ = 1 ether - sigmaISQ;
        }

        // The left part change to: Max((p2 - p1) / p1, 0.002)
        if (sigmaISQ > 0.002 ether) {
            k = sigmaISQ;
        } else {
            k = 0.002 ether;
        }

        sigmaISQ = sigmaISQ * sigmaISQ / (bn - bn0);
        // sigmaSQ = sigmaSQ * BLOCK_TIME * 1e18 / 1000;
        sigmaSQ = sigmaSQ * BLOCK_TIME * 1e15;
        k += _sqrt((sigmaSQ > sigmaISQ ? sigmaSQ : sigmaISQ) * (block.number - bn));
    }

    function _sqrt(uint256 x) private pure returns (uint256) {
        unchecked {
            if (x == 0) return 0;
            else {
                uint256 xx = x;
                uint256 r = 1;
                if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
                if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
                if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
                if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
                if (xx >= 0x100) { xx >>= 8; r <<= 4; }
                if (xx >= 0x10) { xx >>= 4; r <<= 2; }
                if (xx >= 0x8) { r <<= 1; }
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1;
                r = (r + x / r) >> 1; // Seven iterations should be enough
                uint256 r1 = x / r;
                return (r < r1 ? r : r1);
            }
        }
    }

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) private pure returns (uint64) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint64((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint64 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }

    // Convert uint to uint128
    function _toUInt128(uint value) private pure returns (uint128) {
        require(value < 0x100000000000000000000000000000000, "NF:can't convert to uint128");
        return uint128(value);
    }

    // Convert uint to int128
    function _toInt128(uint v) private pure returns (int128) {
        require(v < 0x80000000000000000000000000000000, "NF:can't convert to int128");
        return int128(int(v));
    }

    // Convert int128 to uint
    function _toUInt(int128 v) private pure returns (uint) {
        require(v >= 0, "NF:can't convert to uint");
        return uint(int(v));
    }
    
    // Calculate net worth
    function _balanceOf(
        TokenConfig memory tokenConfig,
        uint balance,
        uint basePrice,
        uint baseBlock,
        uint oraclePrice, 
        bool ORIENTATION, 
        uint LEVER
    ) private view returns (uint) {

        if (balance > 0) {
            uint left;
            uint right;
            // Call
            if (ORIENTATION) {
                left = balance + (LEVER << 64) * balance * oraclePrice / basePrice
                        / _expMiuT(uint(tokenConfig.miuLong), baseBlock);
                right = balance * LEVER;
            } 
            // Put
            else {
                left = balance * (1 + LEVER);
                right = (LEVER << 64) * balance * oraclePrice / basePrice 
                        / _expMiuT(uint(tokenConfig.miuShort), baseBlock);
            }

            if (left > right) {
                balance = left - right;
            } else {
                balance = 0;
            }
        }

        return balance;
    }

    // Calculate e^μT
    function _expMiuT(uint miu, uint baseBlock) private view returns (uint) {
        // return _toUInt(ABDKMath64x64.exp(
        //     _toInt128((orientation ? MIU_LONG : MIU_SHORT) * (block.number - baseBlock) * BLOCK_TIME)
        // ));

        // Using approximate algorithm: x*(1+rt)
        return miu * (block.number - baseBlock) * BLOCK_TIME / 1000 + 0x10000000000000000;
    }

    // Convert FutureInfo to FutureView
    function _toFutureView(FutureInfo storage fi, uint index, address owner) private view returns (FutureView memory) {
        Account memory account = fi.accounts[owner];
        return FutureView(
            index,
            fi.tokenAddress,
            uint(fi.lever),
            fi.orientation,
            uint(account.balance),
            _decodeFloat(account.basePrice),
            uint(account.baseBlock)
        );
    }
}