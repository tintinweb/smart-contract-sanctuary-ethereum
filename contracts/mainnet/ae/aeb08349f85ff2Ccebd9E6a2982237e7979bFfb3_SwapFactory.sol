// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import "./swap/ChainlinkSwap.sol";
import "./utils/TransferHelper.sol";
import "./interfaces/ISwapFactoryExtended.sol";
import "./interfaces/ISwapExtras.sol";

contract SwapFactory {
    using ChainlinkLib for *;

    address[] private chainlinkWithApiFeedSwaps;
    address[] private chainlinkFeedSwaps;

    address factoryAdmin;
    //created sub-factiory for reducing code size abd renaub under limit
    ISwapFactoryExtended subFactory;

    mapping(address=> bool) private whitelistedPartners;

    // events

    event LinkFeedWithApiSwapCreated(
        address indexed sender,
        address swapAddress
    );
    event LinkFeedSwapCreated(address indexed sender, address swapAddress);
    event PartnerWhitlisted(address indexed partner, bool value);

    // modifiers
    modifier onlyFactoryAdminOrPartner() {
        _onlyFactoryAdminOrPartner();
        _;
    }
    
    modifier onlyFactoryAdmin(){
        _onlyFactoryAdmin();
        _;
    }


    constructor(address _factoryAdmin) {
        require(_factoryAdmin != address(0), "Invalid admin");
        factoryAdmin = _factoryAdmin;
    }

    function createLinkFeedWithApiSwap(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting calldata _dexSettings,
        ChainlinkLib.ChainlinkInfo calldata _chainlinkInfo,
        uint256 _chainlinkDepositAmount,
        ChainlinkLib.ApiInfo calldata _apiInfo
    ) external onlyFactoryAdminOrPartner {
       SwapLib.checkcommodityTokenddress(_commodityToken, _stableToken);
        require(
            _dexSettings.rateTimeOut >= 120 && _dexSettings.rateTimeOut <= 300,
            "wrong Duration!"
        );
        require(chainlinkWithApiFeedSwaps.length < 1000, "over limit");
        SwapLib.checkFee(_dexSettings.tradeFee);
        address swap = subFactory.createLinkFeedWithApiSwap(_commodityToken, _stableToken, _dexSettings, _apiInfo);
        ISwapExtras swapExtras = ISwapExtras(swap);
        //Swap swap = new Swap(_commodityToken, _stableToken, _dexSettings, _apiInfo);

        emit LinkFeedWithApiSwapCreated(msg.sender, address(swap));
        TransferHelper.safeTransferFrom(
            _chainlinkInfo.chainlinkToken,
            msg.sender,
            address(swap),
            _chainlinkDepositAmount
        );
        swapExtras.initChainlinkAndPriceInfo(_chainlinkInfo);
        //Depositing chainlink tokens to swap contract

        Ownable(swap).transferOwnership(msg.sender);

        chainlinkWithApiFeedSwaps.push(address(swap));
    }

    function createLinkFeedSwap(
        address _commodityToken,
        address _stableToken,
        string calldata _commDexName,
        uint256 _tradeFee,
        address _commodityChainlinkAddress,
        address _dexAdmin,
        uint256 _unitMultiplier,
        address _stableToUSDPriceFeed
    ) external onlyFactoryAdminOrPartner {
        SwapLib.checkcommodityTokenddress(_commodityToken, _stableToken);
        SwapLib.checkFee(_tradeFee);
        require(chainlinkFeedSwaps.length < 1000, "You reached out limitation");

        ChainlinkSwap _clSwap = new ChainlinkSwap(
            _commodityToken,
            _stableToken,
            _commDexName,
            _tradeFee,
            _commodityChainlinkAddress,
            _dexAdmin,
            _unitMultiplier,
            _stableToUSDPriceFeed
        );
        emit LinkFeedSwapCreated(msg.sender, address(_clSwap));

        _clSwap.transferOwnership(msg.sender);
        chainlinkFeedSwaps.push(address(_clSwap));
    }

    function changeFactoryAdmin(address _newAdmin) external onlyFactoryAdmin {
        require(
            _newAdmin != factoryAdmin && _newAdmin != address(0),
            "invalid admin"
        );
        factoryAdmin = _newAdmin;
    }

    function getChainlinkWithApiFeedSwaps()
        external
        view
        returns (address[] memory)
    {
        return chainlinkWithApiFeedSwaps;
    }

    function getChainlinkFeedSwaps() external view returns (address[] memory) {
        return chainlinkFeedSwaps;
    }

    function setWhiteListPartner (address _partner, bool _value) 
        external
        onlyFactoryAdmin
    {
        require(whitelistedPartners[_partner]!=_value, "already true/false");
        whitelistedPartners[_partner] = _value;
        emit PartnerWhitlisted(_partner,_value);
    }

    function isWhiteListedPartner(address _partner)
        external
        view 
        returns(bool)
    {
        return whitelistedPartners[_partner];
    }

    function setSubFactory(address _subFactory) external onlyFactoryAdmin {
        require(_subFactory != address(0x00),"wrong address");
        subFactory = ISwapFactoryExtended(_subFactory);
    }

    // internal functions 

    function _onlyFactoryAdmin() internal view{
        require(msg.sender == factoryAdmin, "Not admin");
    }
    
    function _onlyFactoryAdminOrPartner() internal view {
        require(msg.sender == factoryAdmin || whitelistedPartners[msg.sender], "Not Admin/Partner");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

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
import {SwapLib, ChainlinkLib} from "../lib/Lib.sol";

interface ISwapFactoryExtended {
    function createLinkFeedWithApiSwap(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting calldata _dexSettings,
        ChainlinkLib.ApiInfo calldata _apiInfo
    ) external returns(address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import { ChainlinkLib} from "../lib/Lib.sol";

interface ISwapExtras {
    event ChainlinkFeedAddrChanged(address newFeedAddress);
    event RequestRateFulfilled(bytes32 indexed requestRate, uint256 rate);
    event ChainlinkFeedEnabled(bool flag);
    event ApiUrlChanged(string newUrl);
    event ApiBuyPathChanged(string newBuyPath);
    event ApiSellPathChanged(string newSellPath);
    event ChainlinkcommodityTokenddressChanged(address newcommodityTokenddress);
    event ChainlinkOracleAddressChanged(address newOracleAddress);
    event RateTimeoutChanged(uint256 newDuration);
    function initChainlinkAndPriceInfo(
        ChainlinkLib.ChainlinkInfo calldata _chainlinkInfo
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import "./BaseSwap.sol";

contract ChainlinkSwap is BaseSwap {

    /// @param _commodityToken the commodity token
    /// @param _stableToken the stable token
    /// @param _commdexName Name for the dex
    /// @param _tradeFee Fee per swap
    /// @param _commodityChainlinkAddress chainlink price feed address for commodity
    /// @param _dexAdmin Comm-dex admin 
    constructor(
        address _commodityToken,
        address _stableToken,
        string memory _commdexName,
        uint256 _tradeFee,
        address _commodityChainlinkAddress,
        address _dexAdmin,
        uint256 _unitMultiplier,
        address _stableToUSDPriceFeed
    ) {
        require(
            _dexAdmin != address(0),
            "Invalid address"
        );
        require(_unitMultiplier > 0, "Invalid _unitMultiplier");
        dexData.commodityToken = _commodityToken;
        dexData.stableToken = _stableToken;
        dexSettings.comdexName = _commdexName;
        dexSettings.tradeFee = _tradeFee;
        dexSettings.dexAdmin = _dexAdmin;
        dexSettings.unitMultiplier = _unitMultiplier; 
        dexSettings.stableToUSDPriceFeed = _stableToUSDPriceFeed;

        priceFeed = AggregatorV3Interface(_commodityChainlinkAddress);
        stableTokenPriceFeed = AggregatorV3Interface(_stableToUSDPriceFeed);
    }

    /// @notice Allows Swaps from commodity token to another token and vice versa,
    /// @param _amountIn Amount of tokens user want to give for swap (in decimals of _from token)
    /// @param _from token that user wants to spend
    /// @param _to token that user wants in result of swap

    function swap(
        uint256 _amountIn,
        address _from,
        address _to
    ) external virtual whenNotPaused {
        require(_amountIn > 0, "wrong amount");
        require(
            (_from == dexData.commodityToken && _to == dexData.stableToken) ||
                (_to == dexData.commodityToken && _from == dexData.stableToken),
            "wrong pair"
        );

        uint256 amountFee = (_amountIn * dexSettings.tradeFee) / (10**10); // 8 decimals for fee, 100 for percentage

        if (_from == dexData.commodityToken) {
            uint256 commodityAmount = _amountIn - amountFee;
            uint256 stableAmount = (commodityAmount * getChainLinkFeedPrice()) / (10**8);
            stableAmount = convertUSDToStable(stableAmount);
            stableAmount = SwapLib.normalizeAmount(stableAmount, _from, _to);

            if (dexData.reserveStable < stableAmount)
                emit LowstableTokenalance(dexData.stableToken, dexData.reserveStable);
            require(dexData.reserveStable >= stableAmount, "not enough liquidity");
            
            TransferHelper.safeTransferFrom(
                dexData.commodityToken,
                msg.sender,
                address(this),
                _amountIn
            );
            TransferHelper.safeTransfer(dexData.stableToken, msg.sender, stableAmount);

            dexData.reserveCommodity = dexData.reserveCommodity + commodityAmount;
            dexData.reserveStable = dexData.reserveStable - stableAmount;
            dexData.totalFeeCommodity = dexData.totalFeeCommodity + amountFee;
            emit Swapped(msg.sender, _amountIn, stableAmount, SwapLib.SELL_INDEX);
        } else {
            uint256 stableAmount = _amountIn - amountFee;
            uint commodityUnitPrice = convertUSDToStable(getChainLinkFeedPrice());
            uint256 commodityAmount = (stableAmount * (10**8)) / commodityUnitPrice;
            commodityAmount = SwapLib.normalizeAmount(commodityAmount, _from, _to);

            if (dexData.reserveCommodity < commodityAmount)
                emit LowstableTokenalance(dexData.commodityToken, dexData.reserveCommodity);
            require(dexData.reserveCommodity >= commodityAmount, "not enough liquidity");

            TransferHelper.safeTransferFrom(
                dexData.stableToken,
                msg.sender,
                address(this),
                _amountIn
            );
            TransferHelper.safeTransfer(dexData.commodityToken, msg.sender, commodityAmount);

            dexData.reserveCommodity = dexData.reserveCommodity - commodityAmount;
            dexData.reserveStable = dexData.reserveStable + stableAmount;
            dexData.totalFeeStable = dexData.totalFeeStable + amountFee;
            emit Swapped(msg.sender, _amountIn, commodityAmount, SwapLib.BUY_INDEX);
        }
    }


    /// @notice adds liquidity for both assets
    /// @dev stableAmount should be = commodityAmount * price
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset

    function addLiquidity(uint256 commodityAmount, uint256 stableAmount)
        external
        virtual
        onlyOwner
    {
        uint amount = (commodityAmount * convertUSDToStable(getChainLinkFeedPrice())) / (10**8);
        require(
            SwapLib.normalizeAmount(amount,dexData.commodityToken, dexData.stableToken) == stableAmount,
            "amounts should be equal"
        );
        super._addLiquidity(commodityAmount, stableAmount);
    }

    /// @notice removes liquidity for both assets
    /// @dev stableAmount should be = commodityAmount * price
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset

    function removeLiquidity(uint256 commodityAmount, uint256 stableAmount)
        external
        virtual
        onlyOwner
    {
        uint amount = (commodityAmount * convertUSDToStable(getChainLinkFeedPrice())) / (10**8);
        require(
            SwapLib.normalizeAmount(amount, dexData.commodityToken, dexData.stableToken) == stableAmount,
            "commodityAmount should be equal"
        );
        super._removeLiquidity(commodityAmount, stableAmount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "./../interfaces/IERC20.sol";
library ChainlinkLib {
    struct ApiInfo {
        string _apiUrl;
        string[2] _chainlinkRequestPath; //0 index contains buy and 1 contains sell
    }
    struct ChainlinkInfo {
        address chainlinkToken;
        address chainlinkOracle;
        address chianlinkPriceFeed;
        bool chainlinkFeedEnabled;
    }
}

library SwapLib {
    uint256 constant BUY_INDEX = 0; //index used to indicate a BUY trx
    uint256 constant SELL_INDEX = 1; //index used to indicate a SELL trx
    struct DexSetting {
        string comdexName;//name of the dex-pool
        uint256 tradeFee;//percentage fee deducted on each swap in 10**8 decimals
        address dexAdmin;//address responsible for certain admin functions e.g. addLiquidity
        uint256 rateTimeOut;//if expires swap will be paused 
        uint256 unitMultiplier;//to convert feed price units to commodity token units
        address stableToUSDPriceFeed; //chainlink feed for stable/usd conversion
    }

    struct DexData {
        uint256 reserveCommodity;
        uint256 reserveStable;
        uint256 totalFeeCommodity; // storage that the fee of token A can be stored
        uint256 totalFeeStable; // storage that the fee of token B can be stored
        address commodityToken;
        address stableToken;
    }

    function normalizeAmount(uint _amountIn, address _from, address _to) internal view returns(uint256){
        uint fromDecimals = IERC20(_from).decimals();
        uint toDecimals = IERC20(_to).decimals();
        if(fromDecimals == toDecimals) return _amountIn;
        return fromDecimals > toDecimals ? _amountIn / (10**(fromDecimals-toDecimals)) : _amountIn * (10**(toDecimals - fromDecimals));
    }

    function checkFee(uint _fee) internal pure{
        require(_fee <10**8, "wrong fee amount");
    }

    function checkcommodityTokenddress(address _commodityToken, address _stableToken) internal pure{
        require(_commodityToken != address(0) && _stableToken != address(0),"invalid token");
    }
}

library PriceLib {
    struct PriceInfo {
        uint256[] rates; //= new uint256[](2);//0 index contains buy and 1 contains sell
        bytes32[] chainlinkRequestId; // = new bytes32[](2);//0 index contains buy and 1 contains sell
        uint256[] lastTimeStamp; //= new uint256[](2);//0 index contains buy and 1 contains sell
        uint256[] lastPriceFeed; //= new uint256[](2);//0 index contains buy and 1 contains sell
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface IERC20{
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../utils/TransferHelper.sol";
import "../interfaces/ISwap.sol";
import "./../utils/Pausable.sol";
import "./../interfaces/IERC20.sol";

import {SwapLib} from "../lib/Lib.sol";

abstract contract BaseSwap is Ownable, ISwap, Pausable {
    using SwapLib for *;

    SwapLib.DexData public dexData;
    SwapLib.DexSetting public dexSettings;
    AggregatorV3Interface internal priceFeed;
    AggregatorV3Interface internal stableTokenPriceFeed;
    // uint256 public unitMultiplier; // will be used to convert feed price units to token price units

    modifier onlyComdexAdmin() {
        _onlyCommdexOwner();
        _;
    }

    function _onlyCommdexOwner() internal view{
       require(
            msg.sender == dexSettings.dexAdmin,
            "Caller is not comm-dex owner"
        );
    }

    /// @notice Adds liquidity for both assets
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset

    function _addLiquidity(uint256 commodityAmount, uint256 stableAmount) internal {
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
        dexData.reserveCommodity = dexData.reserveCommodity + commodityAmount;
        dexData.reserveStable = dexData.reserveStable + stableAmount;
        emit LiquidityAdded(_msgSender(), commodityAmount, stableAmount);
    }

    /// @notice Removes liquidity for both assets
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset

    function _removeLiquidity(uint256 commodityAmount, uint256 stableAmount) internal {
        TransferHelper.safeTransfer(dexData.commodityToken, _msgSender(), commodityAmount);
        TransferHelper.safeTransfer(dexData.stableToken, _msgSender(), stableAmount);
        dexData.reserveCommodity = dexData.reserveCommodity - commodityAmount;
        dexData.reserveStable = dexData.reserveStable - stableAmount;
        emit LiquidityRemoved(_msgSender(), commodityAmount, stableAmount);
    }

    /// @notice Allows to set trade fee for swap
    /// @param _newTradeFee updated trade fee, should be < 10 ** 8


    function setTradeFee(uint256 _newTradeFee) external onlyComdexAdmin {
        require(_newTradeFee < 10**8, "Wrong Fee!");
        dexSettings.tradeFee = _newTradeFee;
        emit TradeFeeChanged(_newTradeFee);
    }

    /// @notice Allows comm-dex admin to withdraw fee

    function withdrawFee() external onlyComdexAdmin {

        withdrawFeeHelper();

        emit FeeWithdraw(
            msg.sender,
            dexData.totalFeeCommodity,
            dexData.totalFeeStable
        );

        resetFees();
    }

    /// @notice Allows to set Chainlink feed address
    /// @param _chainlinkPriceFeed the updated chainlink price feed address

    function setChainlinkFeedAddress(address _chainlinkPriceFeed)
        external
        onlyComdexAdmin
    {
        priceFeed = AggregatorV3Interface(_chainlinkPriceFeed);
        emit ChainlinkFeedAddressChanged(_chainlinkPriceFeed);
    }

    /// @notice Allows to set comm-dex admin
    /// @param _updatedAdmin the new admin

    function setCommdexAdmin(address _updatedAdmin) external onlyComdexAdmin {
        require(
            _updatedAdmin != address(0) &&
                _updatedAdmin != dexSettings.dexAdmin,
            "Invalid Address"
        );
        dexSettings.dexAdmin = _updatedAdmin;
        emit ComDexAdminChanged(_updatedAdmin);
    }

    /// @notice allows Swap admin to withdraw reserves in case of emergency

    function emergencyWithdraw() external onlyOwner {

        withDrawReserveHelper();

        emit EmergencyWithdrawComplete(
            msg.sender,
            dexData.reserveCommodity,
            dexData.reserveStable
        );

        resetReserves();
    }

    /// @notice Allows comm-dex admin to empty dex, sends reserves to comm-dex admin and fee to comm-dex admin

    function withDrawAndDestory(address _to) external onlyComdexAdmin {

        // withdraw the reserves
        withDrawReserveHelper();
        // withdraw fees
        withdrawFeeHelper();

        emit withDrawAndDestroyed(
            msg.sender,
            dexData.reserveCommodity,
            dexData.reserveStable,
            dexData.totalFeeCommodity,
            dexData.totalFeeStable
        );

        selfdestruct(payable(_to));
    }

    function getChainLinkFeedPrice() internal view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        require(price >= 0, "ChainLink price error");

        return (uint256(price) * dexSettings.unitMultiplier) / (10**18); // converting feed price unit into token commodity units e.g 1 gram = 1000mg
    }

    function convertUSDToStable(uint _amount) internal view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = stableTokenPriceFeed.latestRoundData();
        require(price >= 0, "ChainLink price error");

        return ((_amount * (1* (10**(8+5)) / uint256(price))))/ (10**5) ; // supporting 5 decimals on USD values
    }

    function withdrawFeeHelper() internal{
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

    function withDrawReserveHelper() internal {
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

    function resetReserves() internal{
        dexData.reserveCommodity = 0;
        dexData.reserveStable = 0;
    }

    function resetFees() internal {
        dexData.totalFeeCommodity = 0;
        dexData.totalFeeStable = 0;
    }

    /// @notice pauses the Swap function

    function unpause() external onlyComdexAdmin {
        _unpause();
    }

    /// @notice unpause the Swap function

    function pause() external onlyComdexAdmin{
        _pause();
    }

    function updateUnitMultiplier(uint _unitMultiplier) external onlyOwner{
        require(_unitMultiplier > 0 , "Invalid  _unitMultiplier");
        dexSettings.unitMultiplier = _unitMultiplier;
        emit UnitMultiplierUpdated(_unitMultiplier);
    }    
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

interface ISwap {
    event LowstableTokenalance(address Token, uint256 balanceLeft);
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
    event EmergencyWithdrawComplete(
        address indexed sender,
        uint256 commodityAmount,
        uint256 stableAmount
    );
    event FeeWithdraw(address indexed sender, uint256 commodityAmount, uint256 stableAmount);
    event ChainlinkFeedAddressChanged(address newFeedAddress);
    event withDrawAndDestroyed(
        address indexed sender,
        uint256 reserveCommodity,
        uint256 reserveStable,
        uint256 feeA,
        uint256 feeB
    );

    event UnitMultiplierUpdated(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


abstract contract Pausable {
  
    event Paused(address account);


    event Unpaused(address account);

    bool private _paused;

 
    constructor() {
        _paused = false;
    }


    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }


    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }


    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }


    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

  
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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