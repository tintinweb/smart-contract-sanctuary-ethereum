// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import "./swap/PoolChainlink.sol";
import "./utils/TransferHelper.sol";
import "./interfaces/IPoolFactoryExtended.sol";
import "./interfaces/IPoolExtras.sol";

contract PoolFactory {
    address[] private chainlinkWithApiFeedSwaps;
    address[] private chainlinkFeedSwaps;

    address public factoryAdmin;
    address public dexAdmin;

    //created sub-factiory for reducing code size and remain under limit
    IPoolFactoryExtended public subFactory;
    // mapping to track whitelisted partners
    mapping(address => bool) private whitelistedPartners;

    // events

    event LinkFeedWithApiSwapCreated(
        address indexed sender,
        address swapAddress
    );
    event LinkFeedSwapCreated(address indexed sender, address swapAddress);
    event PartnerWhitelisted(address indexed partner, bool value);
    event DexAdminChanged(address indexed newAdmin);
    // modifiers
    modifier onlyFactoryAdminOrPartner() {
        _onlyFactoryAdminOrPartner();
        _;
    }

    modifier onlyFactoryAdmin() {
        _onlyFactoryAdmin();
        _;
    }

    constructor(address _factoryAdmin, address _dexAdmin) {
        require(_factoryAdmin != address(0), "PF: invalid admin");
        require(_dexAdmin != address(0), "PF: invalid dex admin");

        factoryAdmin = _factoryAdmin;
        dexAdmin = _dexAdmin;
    }

    /// @notice Allows Factory admin or whitlisted partner to create Pool with API and chainlink support
    /// @param _commodityToken commodity token address
    /// @param _stableToken stable token address
    /// @param _dexSettings check ./lib/Lib.sol
    /// @param _stableFeedInfo check ./lib/Lib.sol feed and heartbeat of stable token of pool
    /// @param _chainlinkInfo check ./lib/Lib.sol
    /// @param _chainlinkDepositAmount amount of link tokens that will be used to pay as fee to make request to API
    /// @param _apiInfo check ./lib/Lib.sol
    function createLinkFeedWithApiPool(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting memory _dexSettings,
        SwapLib.FeedInfo calldata _stableFeedInfo,
        ChainlinkLib.ChainlinkApiInfo calldata _chainlinkInfo,
        uint256 _chainlinkDepositAmount,
        ChainlinkLib.ApiInfo calldata _apiInfo
    ) external onlyFactoryAdminOrPartner {
        require(chainlinkWithApiFeedSwaps.length < 1000, "PF: out of limit");
        //overwritting dex admin just in case sent address was invalid admin
        //suggested by hacken
        _dexSettings.dexAdmin = dexAdmin;
        address swap = subFactory.createLinkFeedWithApiPool(
            _commodityToken,
            _stableToken,
            _dexSettings,
            _stableFeedInfo
        );

        IPoolExtras swapExtras = IPoolExtras(swap);
        emit LinkFeedWithApiSwapCreated(msg.sender, address(swap));

        //Depositing chainlink tokens to swap contract
        TransferHelper.safeTransferFrom(
            _chainlinkInfo.chainlinkToken,
            msg.sender,
            address(swap),
            _chainlinkDepositAmount
        );

        //set chainlink related information
        swapExtras.initChainlinkAndPriceInfo(_chainlinkInfo, _apiInfo);

        //transfer ownership of pool to creator
        Ownable(swap).transferOwnership(msg.sender);

        chainlinkWithApiFeedSwaps.push(address(swap));
    }

    /// @notice Allows Factory admin or whitlisted partner to create PoolChainlink
    /// @param _commodityToken commodity token address
    /// @param _stableToken stable token address
    /// @param _dexSettings check ./lib/Lib.sol
    /// @param _commodityFeedInfo check ./lib/Lib.sol feed and heartbeat of commodity token of pool
    /// @param _stableFeedInfo check ./lib/Lib.sol feed and heartbeat of stable token of pool
    function createChainlinkPool(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting memory _dexSettings,
        SwapLib.FeedInfo calldata _commodityFeedInfo,
        SwapLib.FeedInfo calldata _stableFeedInfo
    ) external onlyFactoryAdminOrPartner {
        require(chainlinkFeedSwaps.length < 1000, "PF: out of limit");
        //overwritting dex admin just in case sent address was invalid admin
        //suggested by hacken
        _dexSettings.dexAdmin = dexAdmin;
        PoolChainlink _clSwap = new PoolChainlink(
            _commodityToken,
            _stableToken,
            _dexSettings,
            _commodityFeedInfo,
            _stableFeedInfo
        );
        emit LinkFeedSwapCreated(msg.sender, address(_clSwap));

        _clSwap.transferOwnership(msg.sender);
        chainlinkFeedSwaps.push(address(_clSwap));
    }
    
    /// @notice Allows Factory Admin to set new dexAdmin 
    /// @param _newAdmin new factory admin
    function changeDexAdmin(address _newAdmin) external onlyFactoryAdmin {
        require(
            _newAdmin != dexAdmin && _newAdmin != address(0),
            "PF: invalid admin"
        );
        dexAdmin = _newAdmin;
        emit DexAdminChanged(_newAdmin);
    }

    /// @notice Allows Factory Admin to set new Factory Admin
    /// @param _newAdmin new factory admin
    function changeFactoryAdmin(address _newAdmin) external onlyFactoryAdmin {
        require(
            _newAdmin != factoryAdmin && _newAdmin != address(0),
            "PF: invalid admin"
        );
        factoryAdmin = _newAdmin;
    }

    /// @return returns addresses of Pools with API + Chainlink price feed support
    function getChainlinkWithApiFeedSwaps()
        external
        view
        returns (address[] memory)
    {
        return chainlinkWithApiFeedSwaps;
    }

    /// @return returns addresses of Pools with Chainlink price feed support only
    function getChainlinkFeedSwaps() external view returns (address[] memory) {
        return chainlinkFeedSwaps;
    }

    /// @notice Allows Factory admin to add or remove a partner from whitelist
    /// @param _partner partner address to be whitelisted
    /// @param _value true: add to whitelist, false: remove from whitelist
    function setWhiteListPartner(address _partner, bool _value)
        external
        onlyFactoryAdmin
    {
        require(whitelistedPartners[_partner] != _value, "PF: no change");
        whitelistedPartners[_partner] = _value;
        emit PartnerWhitelisted(_partner, _value);
    }

    /// @param _partner address to check if whitelisted
    /// @return true: whitelisted, false:not-whitelisted
    function isWhiteListedPartner(address _partner)
        external
        view
        returns (bool)
    {
        return whitelistedPartners[_partner];
    }

    /// @notice Allows Factory admin to set SubFactory address(that helps in deploying pool with API+ chainlink support)
    /// @param _subFactory new SubFactory address
    function setSubFactory(address _subFactory) external onlyFactoryAdmin {
        require(_subFactory != address(0x00), "PF: invalid address");
        subFactory = IPoolFactoryExtended(_subFactory);
    }

    // internal functions

    function _onlyFactoryAdmin() internal view {
        require(msg.sender == factoryAdmin, "PF: not admin");
    }

    function _onlyFactoryAdminOrPartner() internal view {
        require(
            msg.sender == factoryAdmin || whitelistedPartners[msg.sender],
            "PF: not admin/partner"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import "./BasePool.sol";

contract PoolChainlink is BasePool {
    SwapLib.FeedInfo public commodityFeedInfo;

    /// @param _commodityToken the commodity token
    /// @param _stableToken the stable token
    /// @param _dexSettings dexsettings
    /// @param _stableFeedInfo chainlink price feed address and heartbeats
    /// @param _commodityFeedInfo chainlink price feed address and heartbeats
    constructor(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting memory _dexSettings,
        SwapLib.FeedInfo memory _commodityFeedInfo,
        SwapLib.FeedInfo memory _stableFeedInfo
    ) BasePool(_commodityToken, _stableToken, _dexSettings) {
        //set price feeds
        _setFeedSetting(_commodityFeedInfo, _stableFeedInfo);
    }

    /// @notice Allows Swaps from commodity token to another token and vice versa,
    /// @param _amountIn Amount of tokens user want to give for swap (in decimals of _from token)
    /// @param _expectedAmountOut expected amount of output tokens at the time of quote
    /// @param _slippage slippage tolerance in percentage (2 decimals)
    /// @param _from token that user wants to spend
    /// @param _to token that user wants in result of swap
    function swap(
        uint256 _amountIn,
        uint256 _expectedAmountOut,
        uint256 _slippage,
        address _from,
        address _to
    ) external virtual whenNotPaused {
        //invalid amount check
        require(_amountIn > 0, "PC: wrong amount");
        //tokens check
        require(
            (_from == dexData.commodityToken && _to == dexData.stableToken) ||
                (_to == dexData.commodityToken && _from == dexData.stableToken),
            "PC: wrong pair"
        );
        //calculating fee as percentage of amount passed
        uint256 amountFee = (_amountIn * dexSettings.tradeFee) / (10**10); // 8 decimals for fee, 100 for percentage

        //start sell case
        if (_from == dexData.commodityToken) {
            //commodity -> stable conversion
            //deducting fee
            uint256 commodityAmount = _amountIn - amountFee;
            //getting latest price for given amount
            //false indicates commodity being sold
            uint256 stableAmount = getAmountOut(
                commodityAmount,
                SwapLib.SELL_INDEX
            );

            //cant go ahead if no liquidity
            require(
                dexData.reserveStable >= stableAmount,
                "PC: not enough liquidity"
            );
            //verify slippage stableAmount > minimumAmountOut &&  stableAmount < maximumAmountOut
            verifySlippageTolerance(
                _expectedAmountOut,
                _slippage,
                stableAmount
            );

            //increase commodity reserve
            dexData.reserveCommodity =
                dexData.reserveCommodity +
                commodityAmount;
            //decrease stable reserve
            dexData.reserveStable = dexData.reserveStable - stableAmount;
            //add fee
            dexData.totalFeeCommodity = dexData.totalFeeCommodity + amountFee;
            //emit swap event
            emit Swapped(
                msg.sender,
                _amountIn,
                stableAmount,
                SwapLib.SELL_INDEX
            );

            // All state updates for swap should come before calling the
            // See: https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern

            //transfer the commodity tokens to the contract
            TransferHelper.safeTransferFrom(
                dexData.commodityToken,
                msg.sender,
                address(this),
                _amountIn
            );
            //transfer the stable amount to the user
            TransferHelper.safeTransfer(
                dexData.stableToken,
                msg.sender,
                stableAmount
            );
        } else {
            //deduct calculated fee
            uint256 stableAmount = _amountIn - amountFee;
            //get number of commodity tokens to buy against stable amount passed
            uint256 commodityAmount = getAmountOut(
                stableAmount,
                SwapLib.BUY_INDEX
            );
            //revert on low reserves
            require(
                dexData.reserveCommodity >= commodityAmount,
                "PC: not enough liquidity"
            );

            //verify slippage commodityAmount > minimumAmountOut &&  stableAmount < maximumAmountOut
            verifySlippageTolerance(
                _expectedAmountOut,
                _slippage,
                commodityAmount
            );

            //decrease commodity reserve
            dexData.reserveCommodity =
                dexData.reserveCommodity -
                commodityAmount;
            //increase stable reserve
            dexData.reserveStable = dexData.reserveStable + stableAmount;
            //add stable fee
            dexData.totalFeeStable = dexData.totalFeeStable + amountFee;
            //emit swap event
            emit Swapped(
                msg.sender,
                _amountIn,
                commodityAmount,
                SwapLib.BUY_INDEX
            );
            // All state updates for swap should come before calling the
            // See: https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern

            //transfer stale amountt from user to contract
            TransferHelper.safeTransferFrom(
                dexData.stableToken,
                msg.sender,
                address(this),
                _amountIn
            );
            //transfer commodity amount from contract to user
            TransferHelper.safeTransfer(
                dexData.commodityToken,
                msg.sender,
                commodityAmount
            );
        }
    }

    /// @notice Allows pool owner to add liquidity for both assets
    /// @param _commodityAmount amount of tokens for commodity asset
    /// @param _stableAmount amount of tokens for stable asset
    /// @param _slippage slippage tolerance in percentage (2 decimals)
    function addLiquidity(
        uint256 _commodityAmount,
        uint256 _stableAmount,
        uint256 _slippage
    ) external virtual onlyOwner {
        //calculating amount of stable against commodity amount
        uint256 amount = getAmountOut(_commodityAmount, SwapLib.SELL_INDEX); //deliberate use of false flag to get sell price
        //verify slippage amount > minimumAmountOut &&  amount < maximumAmountOut
        verifySlippageTolerance(_stableAmount, _slippage, amount);
        super._addLiquidity(_commodityAmount, amount);
    }

    /// @notice Allows pool owner to remove liquidity for both assets
    /// @param _commodityAmount amount of tokens for commodity asset
    /// @param _stableAmount amount of tokens for stable asset
    /// @param _slippage slippage tolerance in percentage (2 decimals)
    function removeLiquidity(
        uint256 _commodityAmount,
        uint256 _stableAmount,
        uint256 _slippage
    ) external virtual onlyOwner {
        //calculating amount of stable against commodity amount
        uint256 amount = getAmountOut(_commodityAmount, SwapLib.SELL_INDEX); //deliberate use of false flag to get sell price
        //verify slippage amount > minimumAmountOut &&  amount < maximumAmountOut &&
        verifySlippageTolerance(_stableAmount, _slippage, amount);
        super._removeLiquidity(_commodityAmount, amount);
    }

    ///@dev returns the amonutOut for given amount in if true flag
    ///@param _amountIn the amount of tokens to exchange
    ///@param _index 0 = buy price returns amount commodity for stable _amountIn,
    ///              1 = for sell price
    function getAmountOut(uint256 _amountIn, uint256 _index)
        public
        view
        returns (uint256)
    {
        //calculating commodity amount against stable tokens passed
        //1 Commodity Token = ? Stable tokens
        uint256 commodityUnitPriceUsd = getCommodityPrice();//price returned as USD is converted into respective stable token amount
        uint256 commodityUnitPriceStable = _convertUSDToStable(commodityUnitPriceUsd);

        if (_index == SwapLib.BUY_INDEX) {

            //adding spot price difference to unit price in terms of percentage of the unit price itself
            //e.g. buySpotDifference = 110 = 1.1% and commodityUnitPrice = 50 StableTokens
            //result will be 50+(1.1% of 50) = 50.55
            commodityUnitPriceStable =
                commodityUnitPriceStable +
                ((commodityUnitPriceStable * dexSettings.buySpotDifference) / 10000); // adding % from spot price

            // commodityAmount = amount of stable tokens / commodity unit price in stable
            uint256 commodityAmount = (_amountIn *
                (10**commodityFeedInfo.priceFeed.decimals())) /
                commodityUnitPriceStable;

            //convert to commodity decimals as amount is in stable decimals
            return
                SwapLib._normalizeAmount(
                    commodityAmount,
                    dexData.stableToken,
                    dexData.commodityToken
                );
        } else {
            // calculating stable amount against commodity tokens passed
            // getCommodityPrice returns 1 commodity in USD / its decimals
            // _convertUSDToStable converts dollar value to stable token amount
            // total stable amount  = amount of commodity tokens * 1 commodity price in stable token
            uint256 stableAmount = (_amountIn *
                commodityUnitPriceStable) /
                10**stableFeedInfo.priceFeed.decimals();

            //subtracting sell spot difference
            //e.g. sellSpotDifference = 110 = 1.1% and commodityUnitPrice = 50 StableTokens
            //result will be 50-(1.1% of 50) = 49.45
            stableAmount =
                stableAmount -
                ((stableAmount * dexSettings.sellSpotDifference) / (10000)); // deducting 1.04% out of spot price
            //convert to stable decimal as amount is in commodity decimals
            return
                SwapLib._normalizeAmount(
                    stableAmount,
                    dexData.commodityToken,
                    dexData.stableToken
                );
        }
    }

    /// @notice Allows to set Chainlink feed address
    /// @param _stableFeedInfo chainlink price feed addresses and heartbeats
    /// @param _commodityFeedInfo chainlink price feed addresses and heartbeats
    function setFeedSetting(
        SwapLib.FeedInfo memory _commodityFeedInfo,
        SwapLib.FeedInfo memory _stableFeedInfo
    ) external onlyComdexAdmin {
        _setFeedSetting(_commodityFeedInfo, _stableFeedInfo);
    }

    /// @dev internal function to set chainlink feed settings
    function _setFeedSetting(
        SwapLib.FeedInfo memory _commodityFeedInfo,
        SwapLib.FeedInfo memory _stableFeedInfo
    ) internal {
        require(
            _commodityFeedInfo.heartbeat > 10 &&
                _commodityFeedInfo.heartbeat <= 86400, // 10 seconds to 24 hrs
            "PC: invalid heartbeat commodity"
        );
        require(
            _stableFeedInfo.heartbeat > 10 &&
                _stableFeedInfo.heartbeat <= 86400, // 10 seconds to 24 hrs
            "PC: invalid heartbeat stable"
        );

        commodityFeedInfo = _commodityFeedInfo;
        //try to hit price to check if commodity feed is valid
        uint256 commodityUnitPrice = getCommodityPrice();

        stableFeedInfo = _stableFeedInfo;
        //try to hit price FOR ARBITRARY VALUE to check if stable feed is valid
        _convertUSDToStable(commodityUnitPrice);

        emit FeedAddressesChanged(
            address(_commodityFeedInfo.priceFeed),
            address(_stableFeedInfo.priceFeed)
        );
    }

    ///@dev returns the price of 1 unit of commodity from chainlink feed configured
    function getCommodityPrice() internal view returns (uint256) {
        (
            ,
            // uint80 roundID
            int256 price, // uint answer // startedAt
            ,
            uint256 updatedAt, // updatedAt

        ) = commodityFeedInfo.priceFeed.latestRoundData();
        require(price > 0, "BP: chainLink price error");
        require(
            !_isCommodityFeedTimeout(updatedAt),
            "BP: commodity price expired"
        );
        return (uint256(price) * dexSettings.unitMultiplier) / (10**18); // converting feed price unit into token commodity units e.g 1 gram = 1000mg
    }

    ///@dev returns true if the commodity feed updated price is over heartbeat value
    function _isCommodityFeedTimeout(uint256 _updatedAt)
        internal
        view
        returns (bool)
    {
        //under heartbeat is not a timeout
        if (block.timestamp - _updatedAt < commodityFeedInfo.heartbeat)
            return false;
        else return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import {ChainlinkLib} from "../lib/Lib.sol";

interface IPoolExtras {
    event RequestRateFulfilled(bytes32 indexed requestRate, uint256 rate);
    event ApiInfoChanged(string newUrl, string newBuyPath, string newSellPath);
    event ChainlinkTokenddressChanged(address newcommodityTokenddress);
    event ChainlinkOracleAddressChanged(address newOracleAddress);
    event RateTimeoutChanged(uint256 newDuration);
    event ChainlinkReqFeeUpdated(uint256 newFees);
    event OracleJobIdUpdated(bytes32);
    event FeedAddressChanged(address);
    event LinkRequestDelayChanged(uint256);
    function initChainlinkAndPriceInfo(
        ChainlinkLib.ChainlinkApiInfo calldata _chainlinkInfo,
        ChainlinkLib.ApiInfo calldata _apiInfo
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import {SwapLib, ChainlinkLib} from "../lib/Lib.sol";

interface IPoolFactoryExtended {
    function createLinkFeedWithApiPool(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting calldata _dexSettings,
        SwapLib.FeedInfo calldata _stableFeedInfo
    ) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransferFrom: transferFrom failed"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../utils/TransferHelper.sol";
import "../interfaces/IPool.sol";
import "./../interfaces/IERC20.sol";

import {SwapLib} from "../lib/Lib.sol";

abstract contract BasePool is Ownable, IPool, Pausable {
    //state variable for dex data reserves, tokens etc check ../lib/Lib.sol
    SwapLib.DexData public dexData;

    //name, fee, timeout etc check ../lib/Lib.sol
    SwapLib.DexSetting public dexSettings;

    //to convert USD value to stable token amount
    SwapLib.FeedInfo public stableFeedInfo;

    modifier onlyComdexAdmin() {
        _onlyCommdexAdmin();
        _;
    }

    function _onlyCommdexAdmin() internal view {
        require(
            msg.sender == dexSettings.dexAdmin,
            "BP: caller not pool admin"
        );
    }

    constructor(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting memory _dexSettings
    ) {
        //note: no hard cap on upper limit because units can be any generic conversion
        require(_dexSettings.unitMultiplier > 0, "BP: Invalid _unitMultiplier");
        SwapLib._checkNullAddress(_dexSettings.dexAdmin);
        SwapLib._checkFee(_dexSettings.tradeFee);
        SwapLib._checkNullAddress(_commodityToken);
        SwapLib._checkNullAddress(_stableToken);
        SwapLib._checkRateTimeout(_dexSettings.rateTimeOut);
        dexData.commodityToken = _commodityToken;
        dexData.stableToken = _stableToken;
        //maximum allowed value for difference is 10% could be as low as 0 (1000 = 10.00 %)
        require(
            _dexSettings.sellSpotDifference <= 1000 &&
                _dexSettings.buySpotDifference <= 1000,
            "BP: invalid spot difference"
        );
        dexSettings = _dexSettings;
    }

    /// @notice Adds liquidity for both assets
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset
    function _addLiquidity(uint256 commodityAmount, uint256 stableAmount)
        internal
    {
        dexData.reserveCommodity = dexData.reserveCommodity + commodityAmount;
        dexData.reserveStable = dexData.reserveStable + stableAmount;
        emit LiquidityAdded(_msgSender(), commodityAmount, stableAmount);
        TransferHelper.safeTransferFrom(
            dexData.commodityToken,
            msg.sender,
            address(this),
            commodityAmount
        );
        TransferHelper.safeTransferFrom(
            dexData.stableToken,
            msg.sender,
            address(this),
            stableAmount
        );
    }

    /// @notice Removes liquidity for both assets
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset
    function _removeLiquidity(uint256 commodityAmount, uint256 stableAmount)
        internal
    {
        dexData.reserveCommodity = dexData.reserveCommodity - commodityAmount;
        dexData.reserveStable = dexData.reserveStable - stableAmount;
        emit LiquidityRemoved(_msgSender(), commodityAmount, stableAmount);
        TransferHelper.safeTransfer(
            dexData.commodityToken,
            _msgSender(),
            commodityAmount
        );
        TransferHelper.safeTransfer(
            dexData.stableToken,
            _msgSender(),
            stableAmount
        );
    }

    /// @notice Allows to set trade fee for swap
    /// @param _newTradeFee updated trade fee should be <= 10 ** 8
    function setTradeFee(uint256 _newTradeFee) external onlyComdexAdmin {
        SwapLib._checkFee(_newTradeFee);
        dexSettings.tradeFee = _newTradeFee;
        emit TradeFeeChanged(_newTradeFee);
    }

    /// @dev Allows comm-dex admin to withdraw fee
    function withdrawFee() external onlyComdexAdmin {
        //transfer fee to dexAdmin
        _withdrawFee();
        //reset states
        _resetFees();
        //emit event
        emit FeeWithdraw(
            msg.sender,
            dexData.totalFeeCommodity,
            dexData.totalFeeStable
        );
    }

    /// @notice Allows comm-dex admin to set new comm-dex admin
    /// @param _updatedAdmin the new admin
    function setCommdexAdmin(address _updatedAdmin) external onlyComdexAdmin {
        require(
            _updatedAdmin != address(0) &&
                _updatedAdmin != dexSettings.dexAdmin,
            "BP: invalid address"
        );
        dexSettings.dexAdmin = _updatedAdmin;
        emit ComDexAdminChanged(_updatedAdmin);
    }

    /// @notice allows owner to withdraw reserves in case of emergency
    function emergencyWithdraw() external onlyOwner {
        //transfe the
        _withDrawReserve();
        _resetReserves();
        emit EmergencyWithdraw(
            msg.sender,
            dexData.reserveCommodity,
            dexData.reserveStable
        );
    }

    /// @notice Allows comm-dex admin to self-destruct pool, sends reserves to pool owner and fee to comm-dex admin
    function withDrawAndDestory(address _to) external onlyComdexAdmin {
        SwapLib._checkNullAddress(_to);
        // send reserves to pool owner
        _withDrawReserve();
        // send fee to admin fees
        _withdrawFee();
        emit withDrawAndDestroyed(
            msg.sender,
            dexData.reserveCommodity,
            dexData.reserveStable,
            dexData.totalFeeCommodity,
            dexData.totalFeeStable
        );

        selfdestruct(payable(_to));
    }

    ///@dev pass a usd value to convert it to number of stable tokens against it
    function _convertUSDToStable(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        (
            ,
            // uint80 roundID
            int256 price, // uint answer // startedAt
            ,
            uint256 updatedAt, // updatedAt

        ) = stableFeedInfo.priceFeed.latestRoundData();
        require(price > 0, "BP: stable price error");
        //check if updated rate is expired
        require(!_isStableFeedTimeout(updatedAt), "BP: stable price expired");
        // e.g.
        // price USD = 1 USDT
        // 1 USD = (1 USDT / price USD)USDT
        // (amount  * priceFeed.decimals() / price USD) USDT = amount USDT
        return
            (_amount * 10**stableFeedInfo.priceFeed.decimals()) /
            uint256(price);
    }

    ///@dev returns true if the stable feed updated price is over its heartbeat
    function _isStableFeedTimeout(uint256 _updatedAt)
        internal
        view
        returns (bool)
    {
        if (block.timestamp - _updatedAt < stableFeedInfo.heartbeat)
            return false;
        //under 3 minutes is not a timeout
        else return true;
    }

    function _withdrawFee() internal {
        address dexAdmin = dexSettings.dexAdmin;

        TransferHelper.safeTransfer(
            dexData.commodityToken,
            dexAdmin,
            dexData.totalFeeCommodity
        );
        TransferHelper.safeTransfer(
            dexData.stableToken,
            dexAdmin,
            dexData.totalFeeStable
        );
    }

    function _withDrawReserve() internal {
        address dexOwner = owner();
        TransferHelper.safeTransfer(
            dexData.commodityToken,
            dexOwner,
            dexData.reserveCommodity
        );
        TransferHelper.safeTransfer(
            dexData.stableToken,
            dexOwner,
            dexData.reserveStable
        );
    }

    function _resetReserves() internal {
        dexData.reserveCommodity = 0;
        dexData.reserveStable = 0;
    }

    function _resetFees() internal {
        dexData.totalFeeCommodity = 0;
        dexData.totalFeeStable = 0;
    }

    /// @notice Allows comm-dex-admin to pause the Swap function

    function unpause() external onlyComdexAdmin {
        _unpause();
    }

    /// @notice Allows comm-dex-admin to un-pause the Swap function

    function pause() external onlyComdexAdmin {
        _pause();
    }

    /// @notice Allows pool owner to update unitMultiplier
    /// @param _unitMultiplier new unitMultiplier
    function updateUnitMultiplier(uint256 _unitMultiplier) external onlyOwner {
        require(_unitMultiplier > 0, "BP: Invalid _unitMultiplier");
        dexSettings.unitMultiplier = _unitMultiplier;
        emit UnitMultiplierUpdated(_unitMultiplier);
    }

    /// @notice Allows comm-dex-admin to update buySpotDifference
    /// @param _newDifference new buySpotDifference
    function updateBuySpotDifference(uint256 _newDifference)
        external
        onlyComdexAdmin
    {
        //maximum allowed value for difference is 10% could be as low as 0 (1000 = 10.00 %)
        require(
            _newDifference <= 1000,
            "BP: invalid spot difference"
        );
        dexSettings.buySpotDifference = _newDifference;
        emit BuySpotDifferenceUpdated(_newDifference);
    }

    /// @notice Allows comm-dex-admin to update sellSpotDifference
    /// @param _newDifference new sellSpotDifference
    function updateSellSpotDifference(uint256 _newDifference)
        external
        onlyComdexAdmin
    {

        //maximum allowed value for difference is 10% could be as low as 0 (1000 = 10.00 %)
        require(
            _newDifference <= 1000,
            "BP: invalid spot difference"
        );
        dexSettings.sellSpotDifference = _newDifference;
        emit SellSpotDifferenceUpdated(_newDifference);
    }

    /// @dev get maximum allowed amount out and minimum allowed amount out for given expected amount out and slippage values
    /// @param _expectedAmountOut expected amount of output tokens at the time of quote
    /// @param _slippage slippage tolerance in percentage 0.00 % - 5.00 %
    /// @param _amountOut calculated amountOut in this tx
    function verifySlippageTolerance(
        uint256 _expectedAmountOut,
        uint256 _slippage,
        uint256 _amountOut
    ) public pure {
        //slippage value max 5% = 0 -> 500
        require(_slippage <= 500, "BP: invalid slippage");
        require(_expectedAmountOut > 0, "BP: invalid expected amount");
        //allowed minimum amount out for this tx
        uint256 minAmountOut = _expectedAmountOut -
            ((_expectedAmountOut * _slippage) / 10000); // 2 slippage decimals
        //allowed maximum amount out for this tx
        uint256 maxAmountOut = _expectedAmountOut +
            ((_expectedAmountOut * _slippage) / 10000); // 2 slippage decimals
        //verify slippage _amountOut > minimumAmountOut &&  _amountOut < maximumAmountOut &&
        require(
            _amountOut >= minAmountOut && _amountOut <= maxAmountOut,
            "BP: slippage high"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "./../interfaces/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library ChainlinkLib {
    struct ApiInfo {
        string apiUrl;
        string[2] chainlinkRequestPath; //0 index contains buy and 1 contains sell
    }

    struct ChainlinkApiInfo {
        address chainlinkToken;
        address chainlinkOracle;
        bytes32 jobId;
        uint256 singleRequestFee;
    }
}

library SwapLib {
    uint256 constant BUY_INDEX = 0; //index used to indicate a BUY trx
    uint256 constant SELL_INDEX = 1; //index used to indicate a SELL trx
    uint256 constant SUPPORTED_DECIMALS = 8; //chainlink request and support contract decimals

    struct DexSetting {
        string comdexName; //name of the dex-pool
        uint256 tradeFee; //percentage fee deducted on each swap in 10**8 decimals
        address dexAdmin; //address responsible for certain admin functions e.g. addLiquidity
        uint256 rateTimeOut; //if expires swap will be paused
        uint256 unitMultiplier; //to convert feed price units to commodity token units
        uint256 buySpotDifference; // % difference in buy spot price e.g 112 means 1.12%
        uint256 sellSpotDifference; // % difference in sell spot price e.g 104 means 1.04%
    }

    struct DexData {
        uint256 reserveCommodity; //total commodity reserves
        uint256 reserveStable; //total stable reserves
        uint256 totalFeeCommodity; // storage that the fee of token A can be stored
        uint256 totalFeeStable; // storage that the fee of token B can be stored
        address commodityToken;
        address stableToken;
    }
    struct FeedInfo {
        //chainlink data feed reference
        AggregatorV3Interface priceFeed;
        uint256 heartbeat;
    }

    function _normalizeAmount(
        uint256 _amountIn,
        address _from,
        address _to
    ) internal view returns (uint256) {
        uint256 fromDecimals = IERC20(_from).decimals();
        uint256 toDecimals = IERC20(_to).decimals();
        if (fromDecimals == toDecimals) return _amountIn;
        return
            fromDecimals > toDecimals
                ? _amountIn / (10**(fromDecimals - toDecimals))
                : _amountIn * (10**(toDecimals - fromDecimals));
    }

    function _checkFee(uint256 _fee) internal pure {
        require(_fee <= 10**8, "Lib: wrong fee amount");
    }

    function _checkRateTimeout(uint256 _newDuration) internal pure {
        require(
            _newDuration > 60 && _newDuration <= 300,//changed to minutes after delay implementation
            "Lib: invalid timeout"
        );
    }

    function _checkNullAddress(address _address) internal pure {
        require(_address != address(0), "Lib: invalid address");
    }
}

library PriceLib {
    struct PriceInfo {
        bytes32[] chainlinkRequestId; // = new bytes32[](2);//0 index contains buy and 1 contains sell
        uint256[] lastTimeStamp; // price time 0 index contains buy and 1 contains sell
        uint256[] lastPriceFeed; // price 0 index contains buy and 1 contains sell
        uint256[] lastRequestTime; // time of last request 0 index contains buy and 1 contains sell
        uint256[] cachedRequestTimeStamp; // request start time 0 index contains buy and 1 contains sell
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IPool {
    event Swapped(
        address indexed sender,
        uint256 amountIn,
        uint256 amountOut,
        uint256 isSale
    );
    event LiquidityAdded(
        address indexed sender,
        uint256 commodityAmount,
        uint256 stableAmount
    );
    event LiquidityRemoved(
        address indexed sender,
        uint256 commodityAmount,
        uint256 stableAmount
    );
    event TradeFeeChanged(uint256 newTradeFee);
    event ComDexAdminChanged(address newAdmin);
    event EmergencyWithdraw(
        address indexed sender,
        uint256 commodityAmount,
        uint256 stableAmount
    );
    event FeeWithdraw(
        address indexed sender,
        uint256 commodityAmount,
        uint256 stableAmount
    );
    event FeedAddressesChanged(address newCommodityFeed, address newStableFeed);
    event withDrawAndDestroyed(
        address indexed sender,
        uint256 reserveCommodity,
        uint256 reserveStable,
        uint256 feeA,
        uint256 feeB
    );

    event UnitMultiplierUpdated(uint256);
    event BuySpotDifferenceUpdated(uint256);
    event SellSpotDifferenceUpdated(uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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