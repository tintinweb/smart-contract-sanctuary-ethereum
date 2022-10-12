/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// Sources flattened with hardhat v2.6.5 https://hardhat.org

// File contracts/interfaces/INestBatchPriceView.sol

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This contract implemented the mining logic of nest
interface INestBatchPriceView {
    
    /// @dev Get the full information of latest trigger price
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(uint channelId, uint pairIndex) external view returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    );

    /// @dev Find the price at block number
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        uint channelId, 
        uint pairIndex,
        uint height
    ) external view returns (uint blockNumber, uint price);

    /// @dev Get the last (num) effective price
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber|price
    function lastPriceList(uint channelId, uint pairIndex, uint count) external view returns (uint[] memory);
}


// File contracts/interfaces/INestBatchPrice2.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This contract implemented the mining logic of nest
interface INestBatchPrice2 {

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
}


// File contracts/libs/TransferHelper.sol

// GPL-3.0-or-later

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


// File contracts/interfaces/INestBatchMining.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev This interface defines the mining methods for nest
interface INestBatchMining {
    
    /// @dev PriceChannel open event
    /// @param channelId Target channelId
    /// @param token0 Address of token0, use to mensuration, 0 means eth
    /// @param unit Unit of token0
    /// @param reward Reward token address
    event Open(uint channelId, address token0, uint unit, address reward);

    /// @dev Post event
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @param miner Address of miner
    /// @param index Index of the price sheet
    /// @param scale Scale of this post. (Which times of unit)
    event Post(uint channelId, uint pairIndex, address miner, uint index, uint scale, uint price);

    /* ========== Structures ========== */
    
    /// @dev Nest mining configuration structure
    struct Config {
        
        // -- Public configuration
        // The number of times the sheet assets have doubled. 4
        uint8 maxBiteNestedLevel;
        
        // Price effective block interval. 20
        uint16 priceEffectSpan;

        // The amount of nest to pledge for each post (Unit: 1000). 100
        uint16 pledgeNest;
    }

    /// @dev PriceSheetView structure
    struct PriceSheetView {
        
        // Index of the price sheet
        uint32 index;

        // Address of miner
        address miner;

        // The block number of this price sheet packaged
        uint32 height;

        // The remained scales of this sheet, this value reduced by take
        uint32 remainScales;

        // The scales of token0 left in this sheet
        uint32 token0Scales;

        // The scales of token1 left in this sheet
        uint32 token1Scales;

        // The pledged number of nest in this sheet. (Unit: 1000nest)
        uint24 nestNum1k;

        // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
        uint8 level;

        // Post fee shares, if there are many sheets in one block, this value is used to divide up mining value
        uint8 shares;

        // The token price. (1eth equivalent to (price) token)
        uint152 price;
    }

    // Price channel configuration
    struct ChannelConfig {

        // Reward per block standard
        uint96 rewardPerBlock;

        // Post fee(0.0001eth, DIMI_ETHER). 1000
        uint16 postFeeUnit;

        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;

        // Reduction rate(10000 based). 8000
        uint16 reductionRate;
    }

    /// @dev PricePair view
    struct PairView {
        // Target token address
        address target;
        // Count of price sheets
        uint96 sheetCount;
    }

    /// @dev Price channel view
    struct PriceChannelView {
        
        uint channelId;

        // Address of token0, use to mensuration, 0 means eth
        address token0;
        // Unit of token0
        uint96 unit;

        // Reward token address
        address reward;
        // Reward per block standard
        uint96 rewardPerBlock;

        // Reward total
        uint128 vault;
        // The information of mining fee
        uint96 rewards;
        // Post fee(0.0001eth, DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // Count of price pairs in this channel
        uint16 count;

        // Address of opener
        address opener;
        // Genesis block of this channel
        uint32 genesisBlock;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // Reduction rate(10000 based). 8000
        uint16 reductionRate;
        
        // Price pair array
        PairView[] pairs;
    }

    /* ========== Configuration ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external;

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Open price channel
    /// @param token0 Address of token0, use to mensuration, 0 means eth
    /// @param unit Unit of token0
    /// @param reward Reward token address
    /// @param tokens Target tokens
    /// @param config Channel configuration
    function open(
        address token0, 
        uint96 unit, 
        address reward, 
        address[] calldata tokens,
        ChannelConfig calldata config
    ) external;

    /// @dev Modify channel configuration
    /// @param channelId Target channelId
    /// @param config Channel configuration
    function modify(uint channelId, ChannelConfig calldata config) external;

    /// @dev Increase vault to channel
    /// @param channelId Target channelId
    /// @param vault Total to increase
    function increase(uint channelId, uint128 vault) external payable;

    /// @dev Decrease vault from channel
    /// @param channelId Target channelId
    /// @param vault Total to decrease
    function decrease(uint channelId, uint128 vault) external;

    /// @dev Get channel information
    /// @param channelId Target channelId
    /// @return Information of channel
    function getChannelInfo(uint channelId) external view returns (PriceChannelView memory);

    /// @dev Post price
    /// @param channelId Target channelId
    /// @param scale Scale of this post. (Which times of unit)
    /// @param equivalents Price array, one to one with pairs
    function post(uint channelId, uint scale, uint[] calldata equivalents) external payable;

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+ethNumBal, -tokenNumBal)
    /// @param channelId Target price channelId
    /// @param pairIndex Target pairIndex. When take token0, use pairIndex direct, or add 65536 conversely
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newEquivalent The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function take(uint channelId, uint pairIndex, uint index, uint takeNum, uint newEquivalent) external payable;

    /// @dev List sheets by page
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(
        uint channelId, 
        uint pairIndex, 
        uint offset, 
        uint count, 
        uint order
    ) external view returns (PriceSheetView[] memory);

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param channelId Target channelId
    /// @param indices Two-dimensional array of sheet indices, first means pair indices, seconds means sheet indices
    function close(uint channelId, uint[][] calldata indices) external;

    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) external view returns (uint);

    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    function withdraw(address tokenAddress, uint value) external;

    /// @dev Estimated mining amount
    /// @param channelId Target channelId
    /// @return Estimated mining amount
    function estimate(uint channelId) external view returns (uint);

    /// @dev Query the quantity of the target quotation
    /// @param channelId Target channelId
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(
        uint channelId,
        uint index
    ) external view returns (uint minedBlocks, uint totalShares);

    /// @dev Pay
    /// @param channelId Target channelId
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(uint channelId, address to, uint value) external;
}


// File contracts/custom/ChainConfig.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;

/// @dev Specific data for target chain
contract ChainConfig {

    // ******** Ethereum ******** //

    // Ethereum average block time interval, 12090 milliseconds
    uint constant ETHEREUM_BLOCK_TIMESPAN = 12090;

    // Nest ore drawing attenuation interval. 2600000 blocks, about one year
    uint constant NEST_REDUCTION_SPAN = 2600000;
    // The decay limit of nest ore drawing becomes stable after exceeding this interval. 
    // 24 million blocks, about 10 years
    uint constant NEST_REDUCTION_LIMIT = 26000000; //NEST_REDUCTION_SPAN * 10;
    // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    //uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;

    // ******** BSC ******** //
    
    // // Ethereum average block time interval, 3000 milliseconds
    // uint constant ETHEREUM_BLOCK_TIMESPAN = 3000;

    // // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    // uint constant NEST_REDUCTION_SPAN = 10000000;
    // // The decay limit of nest ore drawing becomes stable after exceeding this interval. 
    // // 24 million blocks, about 10 years
    // uint constant NEST_REDUCTION_LIMIT = 100000000; //NEST_REDUCTION_SPAN * 10;
    // // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    // uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;

    // ******** Ploygon ******** //

    // // Ethereum average block time interval, 2200 milliseconds
    // uint constant ETHEREUM_BLOCK_TIMESPAN = 2200;

    // // Nest ore drawing attenuation interval. 2400000 blocks, about one year
    // uint constant NEST_REDUCTION_SPAN = 15000000;
    // // The decay limit of nest ore drawing becomes stable after exceeding this interval. 
    // // 24 million blocks, about 10 years
    // uint constant NEST_REDUCTION_LIMIT = 150000000; //NEST_REDUCTION_SPAN * 10;
    // // Attenuation gradient array, each attenuation step value occupies 16 bits. The attenuation value is an integer
    // uint constant NEST_REDUCTION_STEPS = 0x280035004300530068008300A300CC010001400190;
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

    // Address of nest token contract
    address constant NEST_TOKEN_ADDRESS = 0x04abEdA201850aC0124161F037Efd70c74ddC74C;

    // Genesis block number of nest
    // NEST token contract is created at block height 6913517. However, because the mining algorithm of nest1.0
    // is different from that at present, a new mining algorithm is adopted from nest2.0. The new algorithm
    // includes the attenuation logic according to the block. Therefore, it is necessary to trace the block
    // where the nest begins to decay. According to the circulation when nest2.0 is online, the new mining
    // algorithm is used to deduce and convert the nest, and the new algorithm is used to mine the nest2.0
    // on-line flow, the actual block is 5120000
    //uint constant NEST_GENESIS_BLOCK = 0;

    // /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    // ///      super.update(newGovernance) when overriding, and override method without onlyGovernance
    // /// @param newGovernance IHedgeGovernance implementation contract address
    // function update(address newGovernance) public virtual override {
    //     super.update(newGovernance);
    //     NEST_TOKEN_ADDRESS = INestGovernance(newGovernance).getNestTokenAddress();
    // }
}


// File contracts/NestBatchMining.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This contract implemented the mining logic of nest4
contract NestBatchMining is ChainConfig, NestFrequentlyUsed, INestBatchMining {

    /// @dev To support open-zeppelin/upgrades
    /// @param governance INestGovernance implementation contract address
    function initialize(address governance) public override {
        super.initialize(governance);
        // Placeholder in _accounts, the index of a real account must greater than 0
        _accounts.push();
    }

    /// @dev Definitions for the price sheet, include the full information. 
    /// (use 256-bits, a storage unit in ethereum evm)
    struct PriceSheet {
        
        // Index of miner account in _accounts. for this way, mapping an address(which need 160-bits) to a 32-bits 
        // integer, support 4 billion accounts
        uint32 miner;

        // The block number of this price sheet packaged
        uint32 height;

        // The remained scales of this sheet, this value reduced by take
        uint32 remainScales;

        // The scales of token0 left in this sheet
        uint32 token0Scales;

        // The scales of token1 left in this sheet
        uint32 token1Scales;

        // The pledged number of nest in this sheet. (Unit: 1000nest)
        uint24 nestNum1k;

        // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses bite price sheet
        uint8 level;

        // Post fee shares, if there are many sheets in one block, this value is used to divide up mining value
        uint8 shares;

        // Represent price as this way, may lose precision, the error less than 1/10^14
        // price = priceFraction * 16 ^ priceExponent
        uint56 priceFloat;
    }

    /// @dev Definitions for the price information
    struct PriceInfo {

        // Record the index of price sheet, for update price information from price sheet next time.
        uint32 index;

        // The block number of this price
        uint32 height;

        // The remain number of this price sheet
        uint32 remainScales;

        // Price, represent as float
        // Represent price as this way, may lose precision, the error less than 1/10^14
        uint56 priceFloat;

        // Avg Price, represent as float
        // Represent price as this way, may lose precision, the error less than 1/10^14
        uint56 avgFloat;

        // Square of price volatility, need divide by 2^48
        uint48 sigmaSQ;
    }

    // Price pair structure
    struct PricePair {
        address target;
        PriceInfo price;
        PriceSheet[] sheets;    
    }

    /// @dev Price channel
    struct PriceChannel {

        // Address of token0, use to mensuration, 0 means eth
        address token0;
        // Unit of token0
        uint96 unit;

        // Reward token address
        address reward;        
        // Reward per block standard
        uint96 rewardPerBlock;

        // Reward total
        uint128 vault;        
        // The information of mining fee
        uint96 rewards;
        // Post fee(0.0001eth, DIMI_ETHER). 1000
        uint16 postFeeUnit;
        // Count of price pairs in this channel
        uint16 count;

        // Address of opener
        address opener;
        // Genesis block of this channel
        uint32 genesisBlock;
        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;
        // Reduction rate(10000 based). 8000
        uint16 reductionRate;
        
        // Price pair array
        PricePair[0xFFFF] pairs;
    }

    /// @dev Structure is used to represent a storage location. Storage variable can be used to avoid indexing 
    /// from mapping many times
    struct UINT {
        uint value;
    }

    /// @dev Account information
    struct Account {
        
        // Address of account
        address addr;

        // Balances of mining account
        // tokenAddress=>balance
        mapping(address=>UINT) balances;
    }

    // Configuration
    Config _config;

    // Registered account information
    Account[] _accounts;

    // Mapping from address to index of account. address=>accountIndex
    mapping(address=>uint) _accountMapping;

    // Price channels
    PriceChannel[] _channels;

    // Unit of post fee. 0.0001 ether
    uint constant DIMI_ETHER = 0.0001 ether;

    /* ========== Governance ========== */

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external override onlyGovernance {
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    /// @dev Open price channel
    /// @param token0 Address of token0, use to mensuration, 0 means eth
    /// @param unit Unit of token0
    /// @param reward Reward token address
    /// @param tokens Target tokens
    /// @param config Channel configuration
    function open(
        address token0, 
        uint96 unit, 
        address reward, 
        address[] calldata tokens,
        ChannelConfig calldata config
    ) external override {

        require(uint(unit) > 0, "NOM:unit must > 0");

        // Emit open event
        emit Open(_channels.length, token0, unit, reward);
        
        PriceChannel storage channel = _channels.push();

        // Address of token0
        channel.token0 = token0;
        // Unit of token0
        channel.unit = unit;

        // Address of reward
        channel.reward = reward;

        channel.vault = uint128(0);
        channel.rewards = uint96(0);
        channel.count = uint16(tokens.length);
        
        // Address of opener
        channel.opener = msg.sender;
        // Genesis block of this channel
        channel.genesisBlock = uint32(block.number);

        // Create price pairs
        for (uint i = 0; i < tokens.length; ++i) {
            require(token0 != tokens[i], "NOM:token can't equal token0");
            for (uint j = 0; j < i; ++j) {
                require(tokens[i] != tokens[j], "NOM:token reiterated");
            }
            channel.pairs[i].target = tokens[i];
        }

        _modify(channel, config);
    }

    /// @dev Modify channel configuration
    /// @param channelId Target channelId
    /// @param config Channel configuration
    function modify(uint channelId, ChannelConfig calldata config) external override {
        PriceChannel storage channel = _channels[channelId];
        require(channel.opener == msg.sender, "NOM:not opener");
        _modify(channel, config);
    }

    /// @dev Modify channel configuration
    /// @param channel Target channel
    /// @param config Channel configuration
    function _modify(PriceChannel storage channel, ChannelConfig calldata config) private {
        // Reward per block standard
        channel.rewardPerBlock = config.rewardPerBlock;

        // Post fee(0.0001eth, DIMI_ETHER). 1000
        channel.postFeeUnit = config.postFeeUnit;

        // Single query fee (0.0001 ether, DIMI_ETHER). 100
        channel.singleFee = config.singleFee;
        // Reduction rate(10000 based). 8000
        channel.reductionRate = config.reductionRate;
    }

    /// @dev Add price token, make a pair with token0. (Not support remove, be careful!)
    /// @param channelId Target channelId
    /// @param target Target token address
    function addPair(uint channelId, address target) external {
        PriceChannel storage channel = _channels[channelId];
        require(channel.opener == msg.sender, "NOM:not opener");
        require(channel.token0 != target, "NOM:token can't equal token0");
        uint count = uint(channel.count);
        for (uint j = 0; j < count; ++j) {
            require(channel.pairs[j].target != target, "NOM:token reiterated");
        }
        channel.pairs[count].target = target;
        ++channel.count;
    }

    /// @dev Modify token Address
    /// @param channelId Target channelId
    /// @param tokenIndex Which token to be update, 65536 means token0, 65537 means reward, else means pairs[tokenIndex]
    /// @param tokenAddress New token address
    function modifyToken(
        uint channelId, 
        uint tokenIndex,
        address tokenAddress
    ) external onlyGovernance {
        PriceChannel storage channel = _channels[channelId];
        if (tokenIndex == 65536) {
            channel.token0 = tokenAddress;
        } else if (tokenIndex == 65537) {
            channel.reward = tokenAddress;
        } else {
            channel.pairs[tokenIndex].target = tokenAddress;
        }
    }

    /// @dev Increase vault to channel
    /// @param channelId Target channelId
    /// @param vault Total to increase
    function increase(uint channelId, uint128 vault) external payable override {
        PriceChannel storage channel = _channels[channelId];
        address reward = channel.reward;
        if (reward == address(0)) {
            require(msg.value == uint(vault), "NOM:vault error");
        } else {
            TransferHelper.safeTransferFrom(reward, msg.sender, address(this), uint(vault));
        }
        channel.vault += vault;
    }

    /// @dev Decrease vault from channel
    /// @param channelId Target channelId
    /// @param vault Total to decrease
    function decrease(uint channelId, uint128 vault) external override {
        PriceChannel storage channel = _channels[channelId];
        require(channel.opener == msg.sender, "NOM:not opener");
        address reward = channel.reward;
        channel.vault -= vault;
        if (reward == address(0)) {
            payable(msg.sender).transfer(uint(vault));
        } else {
            TransferHelper.safeTransfer(reward, msg.sender, uint(vault));
        }
    }

    /// @dev Change opener
    /// @param channelId Target channelId
    /// @param newOpener New opener address
    function changeOpener(uint channelId, address newOpener) external {
        PriceChannel storage channel = _channels[channelId];
        require(channel.opener == msg.sender, "NOM:not opener");
        channel.opener = newOpener;
    }

    /// @dev Get channel information
    /// @param channelId Target channelId
    /// @return Information of channel
    function getChannelInfo(uint channelId) external view override returns (PriceChannelView memory) {
        PriceChannel storage channel = _channels[channelId];

        uint count = uint(channel.count);
        PairView[] memory pairs = new PairView[](count);
        for (uint i = 0; i < count; ++i) {
            PricePair storage pair = channel.pairs[i];
            pairs[i] = PairView(pair.target, uint96(pair.sheets.length));
        }

        return PriceChannelView (
            channelId,

            // Address of token0, use to mensuration, 0 means eth
            channel.token0,
            // Unit of token0
            channel.unit,

            // Reward token address
            channel.reward,
            // Reward per block standard
            channel.rewardPerBlock,

            // Reward total
            channel.vault,
            // The information of mining fee
            channel.rewards,
            // Post fee(0.0001eth, DIMI_ETHER). 1000
            channel.postFeeUnit,
            // Count of price pairs in this channel
            channel.count,

            // Address of opener
            channel.opener,
            // Genesis block of this channel
            channel.genesisBlock,
            // Single query fee (0.0001 ether, DIMI_ETHER). 100
            channel.singleFee,
            // Reduction rate(10000 based). 8000
            channel.reductionRate,

            pairs
        );
    }

    /* ========== Mining ========== */

    /// @dev Post price
    /// @param channelId Target channelId
    /// @param scale Scale of this post. (Which times of unit)
    /// @param equivalents Price array, one to one with pairs
    function post(uint channelId, uint scale, uint[] calldata equivalents) external payable override {

        // 0. Load config
        Config memory config = _config;

        // 1. Check arguments
        require(scale == 1, "NOM:!scale");

        // 2. Load price channel
        PriceChannel storage channel = _channels[channelId];

        // 3. Freeze assets
        uint accountIndex = _addressIndex(msg.sender);

        // Freeze token and nest
        // Because of the use of floating-point representation(fraction * 16 ^ exponent), it may bring some precision 
        // loss After assets are frozen according to equivalent * scale, the part with poor accuracy may be 
        // lost when the assets are returned, It should be frozen according to decodeFloat(fraction, exponent) * scale
        // However, considering that the loss is less than 1 / 10 ^ 14, the loss here is ignored, and the part of
        // precision loss can be transferred out as system income in the future
        mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;

        uint cn = uint(channel.count);
        uint fee = msg.value;

        // Freeze nest
        fee = _freeze(balances, NEST_TOKEN_ADDRESS, cn * uint(config.pledgeNest) * 1000 ether, fee);
    
        // Freeze token0
        fee = _freeze(balances, channel.token0, cn * uint(channel.unit), fee);

        // Freeze token1
        while (cn > 0) {
            PricePair storage pair = channel.pairs[--cn];
            uint equivalent = equivalents[cn];
            require(equivalent > 0, "NOM:!equivalent");
            fee = _freeze(balances, pair.target, equivalent, fee);

            // Calculate the price
            // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price
            // is placed before the sheet is added, which can reduce unnecessary traversal
            _stat(config, pair);
            
            // 6. Create token price sheet
            emit Post(channelId, cn, msg.sender, pair.sheets.length, 1, equivalent);
            // Only pairIndex 0 has reward
            _create(pair.sheets, accountIndex, uint32(1), uint(config.pledgeNest), cn == 0 ? 1 : 0, equivalent);
        }

        // Remove post fee logic, and reserve postFeeUnit field
        // // 4. Deposit fee
        // // Only postFeeUnit > 0 need fee
        // uint postFeeUnit = uint(channel.postFeeUnit);
        // if (postFeeUnit > 0) {
        //     require(fee >= postFeeUnit * DIMI_ETHER + tx.gasprice * 400000, "NM:!fee");
        // }
        // if (fee > 0) {
        //     channel.rewards += _toUInt96(fee);
        // }
    }

    /// @notice Call the function to buy TOKEN/NTOKEN from a posted price sheet
    /// @dev bite TOKEN(NTOKEN) by ETH,  (+token0Scales, -token1Scales)
    /// @param channelId Target price channelId
    /// @param pairIndex Target pairIndex. When take token0, use pairIndex direct, or add 65536 conversely
    /// @param index The position of the sheet in priceSheetList[token]
    /// @param takeNum The amount of biting (in the unit of ETH), realAmount = takeNum * newTokenAmountPerEth
    /// @param newEquivalent The new price of token (1 ETH : some TOKEN), here some means newTokenAmountPerEth
    function take(
        uint channelId, 
        uint pairIndex, 
        uint index, 
        uint takeNum, 
        uint newEquivalent
    ) external payable override {

        Config memory config = _config;

        // 1. Check arguments
        require(takeNum > 0, "NM:!takeNum");
        require(newEquivalent > 0, "NM:!price");

        // 2. Load price sheet
        PriceChannel storage channel = _channels[channelId];
        PricePair storage pair = channel.pairs[pairIndex < 0x10000 ? pairIndex : pairIndex - 0x10000];
        PriceSheet memory sheet = pair.sheets[index];

        // 3. Check state
        require(uint(sheet.height) + uint(config.priceEffectSpan) >= block.number, "NM:!state");
        sheet.remainScales = uint32(uint(sheet.remainScales) - takeNum);

        uint accountIndex = _addressIndex(msg.sender);
        // Number of nest to be pledged
        // sheet.token0Scales + sheet.token1Scales is always two times to sheet.scale (a virtual variable)
        uint needNest1k = (takeNum << 2) * uint(sheet.nestNum1k) / (uint(sheet.token0Scales) + uint(sheet.token1Scales));

        // 4. Calculate the number of eth, token and nest needed, and freeze them
        uint needEthNum = takeNum;
        uint level = uint(sheet.level);
        if (level < 255) {
            if (level < uint(config.maxBiteNestedLevel)) {
                // Double scale sheet
                needEthNum <<= 1;
            }
            ++level;
        }

        {
            // Freeze nest and token
            // Freeze assets: token0, token1, nest
            mapping(address=>UINT) storage balances = _accounts[accountIndex].balances;
            uint fee = msg.value;

            // Target pairIndex. When take token0, use pairIndex direct, or add 65536 conversely
            // pairIndex < 0x10000 means take token0
            if (pairIndex < 0x10000) {
                // Update the bitten sheet
                sheet.token0Scales = uint32(uint(sheet.token0Scales) - takeNum);
                sheet.token1Scales = uint32(uint(sheet.token1Scales) + takeNum);
                pair.sheets[index] = sheet;

                // Freeze token0
                fee = _freeze(balances, channel.token0, (needEthNum - takeNum) * uint(channel.unit), fee);
                // Freeze token1
                fee = _freeze(
                    balances, 
                    pair.target, 
                    needEthNum * newEquivalent + _decodeFloat(sheet.priceFloat) * takeNum, 
                    fee
                );
            } 
            // pairIndex >= 0x10000 means take target token1
            else {
                pairIndex -= 0x10000;
                // Update the bitten sheet
                sheet.token0Scales = uint32(uint(sheet.token0Scales) + takeNum);
                sheet.token1Scales = uint32(uint(sheet.token1Scales) - takeNum);
                pair.sheets[index] = sheet;

                // Freeze token0
                fee = _freeze(balances, channel.token0, (needEthNum + takeNum) * uint(channel.unit), fee);
                // Freeze token1
                uint backTokenValue = _decodeFloat(sheet.priceFloat) * takeNum;
                if (needEthNum * newEquivalent > backTokenValue) {
                    fee = _freeze(balances, pair.target, needEthNum * newEquivalent - backTokenValue, fee);
                } else {
                    _unfreeze(balances, pair.target, backTokenValue - needEthNum * newEquivalent, accountIndex);
                }
            }
                
            // Freeze nest
            fee = _freeze(balances, NEST_TOKEN_ADDRESS, needNest1k * 1000 ether, fee);

            require(fee == 0, "NOM:!fee");
        }
            
        // 5. Calculate the price
        // According to the current mechanism, the newly added sheet cannot take effect, so the calculated price
        // is placed before the sheet is added, which can reduce unnecessary traversal
        _stat(config, pair);

        // 6. Create price sheet
        emit Post(channelId, pairIndex, msg.sender, pair.sheets.length, needEthNum, newEquivalent);
        _create(pair.sheets, accountIndex, uint32(needEthNum), needNest1k, level << 8, newEquivalent);
    }

    /// @dev List sheets by page
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @param offset Skip previous (offset) records
    /// @param count Return (count) records
    /// @param order Order. 0 reverse order, non-0 positive order
    /// @return List of price sheets
    function list(
        uint channelId,
        uint pairIndex,
        uint offset,
        uint count,
        uint order
    ) external view override noContract returns (PriceSheetView[] memory) {

        PriceSheet[] storage sheets = _channels[channelId].pairs[pairIndex].sheets;
        PriceSheetView[] memory result = new PriceSheetView[](count);
        uint length = sheets.length;
        uint i = 0;

        // Reverse order
        if (order == 0) {

            uint index = length - offset;
            uint end = index > count ? index - count : 0;
            while (index > end) {
                --index;
                result[i++] = _toPriceSheetView(sheets[index], index);
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
                result[i++] = _toPriceSheetView(sheets[index], index);
                ++index;
            }
        }
        return result;
    }

    /// @notice Close a batch of price sheets passed VERIFICATION-PHASE
    /// @dev Empty sheets but in VERIFICATION-PHASE aren't allowed
    /// @param channelId Target channelId
    /// @param indices Two-dimensional array of sheet indices, first means pair indices, seconds means sheet indices
    function close(uint channelId, uint[][] calldata indices) external override {
        
        Config memory config = _config;
        PriceChannel storage channel = _channels[channelId];
        
        uint accountIndex = 0;
        uint reward = 0;
        uint nestNum1k = 0;
        uint token0Scales = 0;

        // storage variable must given a value at declaring, this is useless
        mapping(address=>UINT) storage balances = _accounts[0/*accountIndex*/].balances;
        uint[3] memory vars = [
            uint(channel.rewardPerBlock), 
            uint(channel.genesisBlock), 
            uint(channel.reductionRate)
        ];

        for (uint j = indices.length; j > 0;) {
            PricePair storage pair = channel.pairs[--j];

            ///////////////////////////////////////////////////////////////////////////////////////
            uint tokenValue = 0;

            // 1. Traverse sheets
            for (uint i = indices[j].length; i > 0;) {

                // ---------------------------------------------------------------------------------
                uint index = indices[j][--i];
                PriceSheet memory sheet = pair.sheets[index];
                
                // Batch closing quotation can only close sheet of the same user
                if (accountIndex == 0) {
                    // accountIndex == 0 means the first sheet, and the number of this sheet is taken
                    accountIndex = uint(sheet.miner);
                    balances = _accounts[accountIndex].balances;
                } else {
                    // accountIndex != 0 means that it is a follow-up sheet, and the miner number must be 
                    // consistent with the previous record
                    require(accountIndex == uint(sheet.miner), "NM:!miner");
                }

                // Check the status of the price sheet to see if it has reached the effective block interval 
                // or has been finished
                if (accountIndex > 0 && (uint(sheet.height) + uint(config.priceEffectSpan) < block.number)) {

                    // Only pairIndex 0 has reward
                    if (j == 0) {
                        uint shares = uint(sheet.shares);
                        // Mining logic
                        // The price sheet which shares is zero doesn't mining
                        if (shares > 0) {

                            // Currently, mined represents the number of blocks has mined
                            (uint mined, uint totalShares) = _calcMinedBlocks(pair.sheets, index, sheet);
                            
                            reward += (
                                mined
                                * shares
                                * _reduction(uint(sheet.height) - vars[1], vars[2])
                                * vars[0]
                                / totalShares / 400
                            );
                        }
                    }

                    nestNum1k += uint(sheet.nestNum1k);
                    token0Scales += uint(sheet.token0Scales);
                    tokenValue += _decodeFloat(sheet.priceFloat) * uint(sheet.token1Scales);

                    // Set sheet.miner to 0, express the sheet is closed
                    sheet.miner = uint32(0);
                    sheet.token0Scales = uint32(0);
                    sheet.token1Scales = uint32(0);
                    pair.sheets[index] = sheet;
                }

                // ---------------------------------------------------------------------------------
            }

            _stat(config, pair);
            ///////////////////////////////////////////////////////////////////////////////////////

            // Unfreeze token1
            _unfreeze(balances, pair.target, tokenValue, accountIndex);
        }

        // Unfreeze token0
        _unfreeze(balances, channel.token0, token0Scales * uint(channel.unit), accountIndex);
        
        // Unfreeze nest
        _unfreeze(balances, NEST_TOKEN_ADDRESS, nestNum1k * 1000 ether, accountIndex);

        uint vault = uint(channel.vault);
        if (reward > vault) {
            reward = vault;
        }
        // Record the vault for each channel to prevent the opener use the funds in this contract without increase
        channel.vault = uint128(vault - reward);
        
        // Record reward
        _unfreeze(balances, channel.reward, reward, accountIndex);
    }

    /// @dev View the number of assets specified by the user
    /// @param tokenAddress Destination token address
    /// @param addr Destination address
    /// @return Number of assets
    function balanceOf(address tokenAddress, address addr) external view override returns (uint) {
        return _accounts[_accountMapping[addr]].balances[tokenAddress].value;
    }

    /// @dev Withdraw assets
    /// @param tokenAddress Destination token address
    /// @param value The value to withdraw
    function withdraw(address tokenAddress, uint value) external override {

        // The user's locked nest and the mining pool's nest are stored together. When the nest is mined over,
        // the problem of taking the locked nest as the ore drawing will appear
        // As it will take a long time for nest to finish mining, this problem will not be considered for the time being
        UINT storage balance = _accounts[_accountMapping[msg.sender]].balances[tokenAddress];
        balance.value -= value;
        TransferHelper.safeTransfer(tokenAddress, msg.sender, value);
    }

    /// @dev Estimated mining amount
    /// @param channelId Target channelId
    /// @return Estimated mining amount
    function estimate(uint channelId) external view override returns (uint) {

        PriceChannel storage channel = _channels[channelId];
        PriceSheet[] storage sheets = channel.pairs[0].sheets;
        uint index = sheets.length;
        uint blocks = 10;
        while (index > 0) {

            PriceSheet memory sheet = sheets[--index];
            if (uint(sheet.shares) > 0) {
                blocks = block.number - uint(sheet.height);
                break;
            }
        }

        return 
            blocks
            * uint(channel.rewardPerBlock) 
            * _reduction(block.number - uint(channel.genesisBlock), uint(channel.reductionRate))
            / 400;
    }

    /// @dev Query the quantity of the target quotation
    /// @param channelId Target channelId
    /// @param index The index of the sheet
    /// @return minedBlocks Mined block period from previous block
    /// @return totalShares Total shares of sheets in the block
    function getMinedBlocks(
        uint channelId,
        uint index
    ) external view override returns (uint minedBlocks, uint totalShares) {
        PriceSheet[] storage sheets = _channels[channelId].pairs[0].sheets;
        return _calcMinedBlocks(sheets, index, sheets[index]);
    }

    /// @dev Pay
    /// @param channelId Target channelId
    /// @param to Address to receive
    /// @param value Amount to receive
    function pay(uint channelId, address to, uint value) external override {

        PriceChannel storage channel = _channels[channelId];
        require(channel.opener == msg.sender, "NOM:!opener");
        channel.rewards -= _toUInt96(value);
        // pay
        payable(to).transfer(value);
    }

    /// @dev Gets the address corresponding to the given index number
    /// @param index The index number of the specified address
    /// @return The address corresponding to the given index number
    function indexAddress(uint index) public view returns (address) {
        return _accounts[index].addr;
    }

    /// @dev Gets the registration index number of the specified address
    /// @param addr Destination address
    /// @return 0 means nonexistent, non-0 means index number
    function getAccountIndex(address addr) external view returns (uint) {
        return _accountMapping[addr];
    }

    /// @dev Get the length of registered account array
    /// @return The length of registered account array
    function getAccountCount() external view returns (uint) {
        return _accounts.length;
    }

    // Convert PriceSheet to PriceSheetView
    function _toPriceSheetView(PriceSheet memory sheet, uint index) private view returns (PriceSheetView memory) {

        return PriceSheetView(
            // Index number
            uint32(index),
            // Miner address
            indexAddress(sheet.miner),
            // The block number of this price sheet packaged
            sheet.height,
            // The remain number of this price sheet
            sheet.remainScales,
            // The eth number which miner will got
            sheet.token0Scales,
            // The eth number which equivalent to token's value which miner will got
            sheet.token1Scales,
            // The pledged number of nest in this sheet. (Unit: 1000nest)
            sheet.nestNum1k,
            // The level of this sheet. 0 expresses initial price sheet, a value greater than 0 expresses 
            // bite price sheet
            sheet.level,
            // Post fee shares
            sheet.shares,
            // Price
            uint152(_decodeFloat(sheet.priceFloat))
        );
    }

    // Create price sheet
    function _create(
        PriceSheet[] storage sheets,
        uint accountIndex,
        uint32 scale,
        uint nestNum1k,
        uint level_shares,
        uint equivalent
    ) private {
        sheets.push(PriceSheet(
            uint32(accountIndex),                       // uint32 miner;
            uint32(block.number),                       // uint32 height;
            scale,                                      // uint32 remainScales;
            scale,                                      // uint32 token0Scales;
            scale,                                      // uint32 token1Scales;
            uint24(nestNum1k),                          // uint32 nestNum1k;
            uint8(level_shares >> 8),                   // uint8 level;
            uint8(level_shares & 0xFF),
            _encodeFloat(equivalent)
        ));
    }

    // Calculate price, average price and volatility
    function _stat(Config memory config, PricePair storage pair) private {
        
        PriceSheet[] storage sheets = pair.sheets;
        // Load token price information
        PriceInfo memory p0 = pair.price;

        // Length of sheets
        uint length = sheets.length;
        // The index of the sheet to be processed in the sheet array
        uint index = uint(p0.index);
        // The latest block number for which the price has been calculated
        uint prev = uint(p0.height);
        // It's not necessary to load the price information in p0
        // Eth count variable used to calculate price
        uint totalToken0Scales = 0; 
        // Token count variable for price calculation
        uint totalToken1Value = 0; 
        // Block number of current sheet
        uint height = 0;

        // Traverse the sheets to find the effective price
        //uint effectBlock = block.number - uint(config.priceEffectSpan);
        PriceSheet memory sheet;
        for (; ; ++index) {

            // Gas attack analysis, each post transaction, calculated according to post, needs to write
            // at least one sheet and freeze two kinds of assets, which needs to consume at least 30000 gas,
            // In addition to the basic cost of the transaction, at least 50000 gas is required.
            // In addition, there are other reading and calculation operations. The gas consumed by each
            // transaction is impossible less than 70000 gas, The attacker can accumulate up to 20 blocks
            // of sheets to be generated. To ensure that the calculation can be completed in one block,
            // it is necessary to ensure that the consumption of each price does not exceed 70000 / 20 = 3500 gas,
            // According to the current logic, each calculation of a price needs to read a storage unit (800)
            // and calculate the consumption, which can not reach the dangerous value of 3500, so the gas attack
            // is not considered

            // Traverse the sheets that has reached the effective interval from the current position
            bool flag = index >= length
                || (height = uint((sheet = sheets[index]).height)) + uint(config.priceEffectSpan) >= block.number;

            // Not the same block (or flag is true), calculate the price and update it
            if (flag || prev != height) {

                // totalToken0Scales > 0 Can calculate the price
                if (totalToken0Scales > 0) {

                    // Calculate average price and Volatility
                    // Calculation method of volatility of follow-up price
                    uint tmp = _decodeFloat(p0.priceFloat);
                    // New price
                    uint price = totalToken1Value / totalToken0Scales;
                    // Update price
                    p0.remainScales = uint32(totalToken0Scales);
                    p0.priceFloat = _encodeFloat(price);
                    // Clear cumulative values
                    totalToken0Scales = 0;
                    totalToken1Value = 0;

                    if (tmp > 0) {
                        // Calculate average price
                        // avgPrice[i + 1] = avgPrice[i] * 90% + price[i] * 10%
                        p0.avgFloat = _encodeFloat((_decodeFloat(p0.avgFloat) * 9 + price) / 10);

                        // When the accuracy of the token is very high or the value of the token relative to
                        // eth is very low, the price may be very large, and there may be overflow problem,
                        // it is not considered for the moment
                        tmp = (price << 48) / tmp;
                        if (tmp > 0x1000000000000) {
                            tmp = tmp - 0x1000000000000;
                        } else {
                            tmp = 0x1000000000000 - tmp;
                        }

                        // earn = price[i] / price[i - 1] - 1;
                        // seconds = time[i] - time[i - 1];
                        // sigmaSQ[i + 1] = sigmaSQ[i] * 90% + (earn ^ 2 / seconds) * 10%
                        tmp = (
                            uint(p0.sigmaSQ) * 9 + 
                            // It is inevitable that prev greater than p0.height
                            ((tmp * tmp * 1000 / ETHEREUM_BLOCK_TIMESPAN / (prev - uint(p0.height))) >> 48)
                        ) / 10;

                        // The current implementation assumes that the volatility cannot exceed 1, and
                        // corresponding to this, when the calculated value exceeds 1, expressed as 0xFFFFFFFFFFFF
                        if (tmp > 0xFFFFFFFFFFFF) {
                            tmp = 0xFFFFFFFFFFFF;
                        }
                        p0.sigmaSQ = uint48(tmp);
                    }
                    // The calculation methods of average price and volatility are different for first price
                    else {
                        // The average price is equal to the price
                        //p0.avgTokenAmount = uint64(price);
                        p0.avgFloat = p0.priceFloat;

                        // The volatility is 0
                        p0.sigmaSQ = uint48(0);
                    }

                    // Update price block number
                    p0.height = uint32(prev);
                }

                // Move to new block number
                prev = height;
            }

            if (flag) {
                break;
            }

            // Cumulative price information
            totalToken0Scales += uint(sheet.remainScales);
            totalToken1Value += _decodeFloat(sheet.priceFloat) * uint(sheet.remainScales);
        }

        // Update price information
        if (index > uint(p0.index)) {
            p0.index = uint32(index);
            pair.price = p0;
        }
    }

    // Calculation number of blocks which mined
    function _calcMinedBlocks(
        PriceSheet[] storage sheets,
        uint index,
        PriceSheet memory sheet
    ) private view returns (uint minedBlocks, uint totalShares) {

        uint length = sheets.length;
        uint height = uint(sheet.height);
        totalShares = uint(sheet.shares);

        // Backward looking for sheets in the same block
        for (uint i = index; ++i < length && uint(sheets[i].height) == height;) {
            
            // Multiple sheets in the same block is a small probability event at present, so it can be ignored
            // to read more than once, if there are always multiple sheets in the same block, it means that the
            // sheets are very intensive, and the gas consumed here does not have a great impact
            totalShares += uint(sheets[i].shares);
        }

        // Find sheets in the same block forward
        uint prev = height;
        while (index > 0 && uint(prev = sheets[--index].height) == height) {

            // Multiple sheets in the same block is a small probability event at present, so it can be ignored 
            // to read more than once, if there are always multiple sheets in the same block, it means that the
            // sheets are very intensive, and the gas consumed here does not have a great impact
            totalShares += uint(sheets[index].shares);
        }

        if (index > 0 || height > prev) {
            minedBlocks = height - prev;
        } else {
            minedBlocks = 10;
        }
    }

    /// @dev freeze token
    /// @param balances Balances ledger
    /// @param tokenAddress Destination token address
    /// @param tokenValue token amount
    /// @param value The remain value
    function _freeze(
        mapping(address=>UINT) storage balances, 
        address tokenAddress, 
        uint tokenValue,
        uint value
    ) private returns (uint) {
        if (tokenAddress == address(0)) {
            return value - tokenValue;
        } else {
            // Unfreeze nest
            UINT storage balance = balances[tokenAddress];
            uint balanceValue = balance.value;
            if (balanceValue < tokenValue) {
                balance.value = 0;
                TransferHelper.safeTransferFrom(tokenAddress, msg.sender, address(this), tokenValue - balanceValue);
            } else {
                balance.value = balanceValue - tokenValue;
            }
            return value;
        }
    }

    /// @dev unfreeze token
    /// @param balances Balances ledger
    /// @param tokenAddress Destination token address
    /// @param tokenValue token amount
    /// @param accountIndex target accountIndex
    function _unfreeze(
        mapping(address=>UINT) storage balances, 
        address tokenAddress, 
        uint tokenValue,
        uint accountIndex
    ) private {
        if (tokenValue > 0) {
            if (tokenAddress == address(0)) {
                payable(indexAddress(accountIndex)).transfer(tokenValue);
            } else {
                balances[tokenAddress].value += tokenValue;
            }
        }
    }

    /// @dev Gets the index number of the specified address. If it does not exist, register
    /// @param addr Destination address
    /// @return The index number of the specified address
    function _addressIndex(address addr) private returns (uint) {

        uint index = _accountMapping[addr];
        if (index == 0) {
            // If it exceeds the maximum number that 32 bits can store, you can't continue to register a new account.
            // If you need to support a new account, you need to update the contract
            require((_accountMapping[addr] = index = _accounts.length) < 0x100000000, "NM:!accounts");
            _accounts.push().addr = addr;
        }

        return index;
    }

    function _reduction(uint delta, uint reductionRate) private pure returns (uint) {
        if (delta < NEST_REDUCTION_LIMIT) {
            uint n = delta / NEST_REDUCTION_SPAN;
            return 400 * reductionRate ** n / 10000 ** n;
        }
        return 400 * reductionRate ** 10 / 10000 ** 10;
    }

    /* ========== Tools and methods ========== */

    /// @dev Encode the uint value as a floating-point representation in the form of fraction * 16 ^ exponent
    /// @param value Destination uint value
    /// @return float format
    function _encodeFloat(uint value) private pure returns (uint56) {

        uint exponent = 0; 
        while (value > 0x3FFFFFFFFFFFF) {
            value >>= 4;
            ++exponent;
        }
        return uint56((value << 6) | exponent);
    }

    /// @dev Decode the floating-point representation of fraction * 16 ^ exponent to uint
    /// @param floatValue fraction value
    /// @return decode format
    function _decodeFloat(uint56 floatValue) private pure returns (uint) {
        return (uint(floatValue) >> 6) << ((uint(floatValue) & 0x3F) << 2);
    }

    // Convert uint to uint96
    function _toUInt96(uint value) internal pure returns (uint96) {
        require(value < 0x1000000000000000000000000, "NBM:can't convert to uint96");
        return uint96(value);
    }

    /* ========== Price Query ========== */
    
    /// @dev Get the full information of latest trigger price
    /// @param pair Target price pair
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function _triggeredPriceInfo(PricePair storage pair) internal view returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    ) {

        PriceInfo memory priceInfo = pair.price;

        if (uint(priceInfo.remainScales) > 0) {
            return (
                uint(priceInfo.height) + uint(_config.priceEffectSpan),
                _decodeFloat(priceInfo.priceFloat),
                _decodeFloat(priceInfo.avgFloat),
                (uint(priceInfo.sigmaSQ) * 1 ether) >> 48
            );
        }

        return (0, 0, 0, 0);
    }

    /// @dev Find the price at block number
    /// @param pair Target price pair
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function _findPrice(
        PricePair storage pair,
        uint height
    ) internal view returns (uint blockNumber, uint price) {

        PriceSheet[] storage sheets = pair.sheets;
        uint priceEffectSpan = uint(_config.priceEffectSpan);

        uint length = sheets.length;
        uint index = 0;
        uint sheetHeight;
        height -= priceEffectSpan;
        {
            // If there is no sheet in this channel, length is 0, length - 1 will overflow,
            uint right = length - 1;
            uint left = 0;
            // Find the index use Binary Search
            while (left < right) {

                index = (left + right) >> 1;
                sheetHeight = uint(sheets[index].height);
                if (height > sheetHeight) {
                    left = ++index;
                } else if (height < sheetHeight) {
                    // When index = 0, this statement will have an underflow exception, which usually 
                    // indicates that the effective block height passed during the call is lower than 
                    // the block height of the first quotation
                    right = --index;
                } else {
                    break;
                }
            }
        }

        // Calculate price
        uint totalToken0Scales = 0;
        uint totalToken1Value = 0;
        uint h = 0;
        uint remainScales;
        PriceSheet memory sheet;

        // Find sheets forward
        for (uint i = index; i < length;) {

            sheet = sheets[i++];
            sheetHeight = uint(sheet.height);
            if (height < sheetHeight) {
                break;
            }
            remainScales = uint(sheet.remainScales);
            if (remainScales > 0) {
                if (h == 0) {
                    h = sheetHeight;
                } else if (h != sheetHeight) {
                    break;
                }
                totalToken0Scales += remainScales;
                totalToken1Value += _decodeFloat(sheet.priceFloat) * remainScales;
            }
        }

        // Find sheets backward
        while (index > 0) {

            sheet = sheets[--index];
            remainScales = uint(sheet.remainScales);
            if (remainScales > 0) {
                sheetHeight = uint(sheet.height);
                if (h == 0) {
                    h = sheetHeight;
                } else if (h != sheetHeight) {
                    break;
                }
                totalToken0Scales += remainScales;
                totalToken1Value += _decodeFloat(sheet.priceFloat) * remainScales;
            }
        }

        if (totalToken0Scales > 0) {
            return (h + priceEffectSpan, totalToken1Value / totalToken0Scales);
        }
        return (0, 0);
    }

    /// @dev Get the last (num) effective price
    /// @param pair Target price pair
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber|price
    function _lastPriceList(PricePair storage pair, uint count) internal view returns (uint[] memory) {

        PriceSheet[] storage sheets = pair.sheets;
        PriceSheet memory sheet;
        uint[] memory array = new uint[](count <<= 1);

        uint priceEffectSpan = uint(_config.priceEffectSpan);
        uint index = sheets.length;
        uint totalToken0Scales = 0;
        uint totalToken1Value = 0;
        uint height = 0;

        for (uint i = 0; i < count;) {

            bool flag = index == 0;
            if (flag || height != uint((sheet = sheets[--index]).height)) {
                if (totalToken0Scales > 0 && height + priceEffectSpan < block.number) {
                    array[i++] = height + priceEffectSpan;
                    array[i++] = totalToken1Value / totalToken0Scales;
                }
                if (flag) {
                    break;
                }
                totalToken0Scales = 0;
                totalToken1Value = 0;
                height = uint(sheet.height);
            }

            uint remainScales = uint(sheet.remainScales);
            totalToken0Scales += remainScales;
            totalToken1Value += _decodeFloat(sheet.priceFloat) * remainScales;
        }

        return array;
    }
}


// File contracts/NestBatchPlatform2.sol

// GPL-3.0-or-later

pragma solidity ^0.8.6;
/// @dev This contract implemented the query logic of nest
contract NestBatchPlatform2 is NestBatchMining, INestBatchPriceView, INestBatchPrice2 {

    /* ========== INestBatchPriceView ========== */

    /// @dev Get the full information of latest trigger price
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(uint channelId, uint pairIndex) external view override noContract returns (
        uint blockNumber,
        uint price,
        uint avgPrice,
        uint sigmaSQ
    ) {
        return _triggeredPriceInfo(_channels[channelId].pairs[pairIndex]);
    }

    /// @dev Find the price at block number
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        uint channelId,
        uint pairIndex,
        uint height
    ) external view override noContract returns (uint blockNumber, uint price) {
        return _findPrice(_channels[channelId].pairs[pairIndex], height);
    }

    /// @dev Get the last (num) effective price
    /// @param channelId Target channelId
    /// @param pairIndex Target pairIndex
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber|price
    function lastPriceList(uint channelId, uint pairIndex, uint count) external view override noContract returns (uint[] memory) {
        return _lastPriceList(_channels[channelId].pairs[pairIndex], count);
    } 

    /* ========== INestBatchPrice ========== */

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
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint n = pairIndices.length << 2;
        prices = new uint[](n);
        while (n > 0) {
            n -= 4;
            (prices[n], prices[n + 1], prices[n + 2], prices[n + 3]) = _triggeredPriceInfo(pairs[pairIndices[n >> 2]]);
        }
    }

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
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint n = pairIndices.length << 1;
        prices = new uint[](n);
        while (n > 0) {
            n -= 2;
            (prices[n], prices[n + 1]) = _findPrice(pairs[pairIndices[n >> 1]], height);
        }
    }

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
    ) external payable override returns (uint[] memory prices) {
        PricePair[0xFFFF] storage pairs = _pay(channelId, payback).pairs;

        uint row = count << 1;
        uint n = pairIndices.length * row;
        prices = new uint[](n);
        while (n > 0) {
            n -= row;
            uint[] memory pi = _lastPriceList(pairs[pairIndices[n / row]], count);
            for (uint i = 0; i < row; ++i) {
                prices[n + i] = pi[i];
            }
        }
    }

    // Payment of transfer fee
    function _pay(uint channelId, address payback) private returns (PriceChannel storage channel) {
        channel = _channels[channelId];
        if (msg.value > 0) {
            payable(payback).transfer(msg.value);
            // BSC adopts the old gas calculation strategy. Direct transfer may lead to the excess of gas 
            // in the agency contract. The following methods should be used for transfer
            //TransferHelper.safeTransferETH(payback, msg.value - fee);
        }
    }
}