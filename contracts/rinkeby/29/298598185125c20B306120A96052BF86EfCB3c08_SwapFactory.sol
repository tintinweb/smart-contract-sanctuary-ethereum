// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >0.4.23 <0.9.0;
import "./swap/Swap.sol";
import "./swap/ChainlinkSwap.sol";
import "./utils/TransferHelper.sol";

contract SwapFactory {
    using ChainlinkLib for *;

    address[] private chainlinkWithApiFeedSwaps;
    address[] private chainlinkFeedSwaps;

    address factoryAdmin;

    event LinkFeedWithApiSwapCreated(
        address indexed sender,
        address swapAddress
    );
    event LinkFeedSwapCreated(address indexed sender, address swapAddress);

    modifier onlyFactoryAdmin() {
        _onlyFactoryAdmin();
        _;
    }

    function _onlyFactoryAdmin() internal view {
        require(msg.sender == factoryAdmin, "Not Admin");
    }

    constructor(address _factoryAdmin) {
        require(_factoryAdmin != address(0), "Invalid admin");
        factoryAdmin = _factoryAdmin;
    }

    function createLinkFeedWithApiSwap(
        address _tokenA,
        address _tokenB,
        SwapLib.DexSetting calldata _dexSettings,
        ChainlinkLib.ChainlinkInfo calldata _chainlinkInfo,
        uint256 _chainlinkDepositAmount,
        ChainlinkLib.ApiInfo calldata _apiInfo
    ) external onlyFactoryAdmin {
        require(
            _tokenA != address(0) && _tokenB != address(0),
            "invalid token"
        );
        require(
            _dexSettings.rateTimeOut >= 120 && _dexSettings.rateTimeOut <= 300,
            "wrong Duration!"
        );
        require(chainlinkWithApiFeedSwaps.length < 1000, "over limit");
        require(
            _dexSettings.tradeFee >= 0 && _dexSettings.tradeFee < 10**8,
            "wrong fee"
        );

        Swap swap = new Swap(_tokenA, _tokenB, _dexSettings, _apiInfo);

        emit LinkFeedWithApiSwapCreated(msg.sender, address(swap));
        TransferHelper.safeTransferFrom(
            _chainlinkInfo.chainlinkToken,
            msg.sender,
            address(swap),
            _chainlinkDepositAmount
        );
        swap.initChainlinkAndPrieInfo(_chainlinkInfo);
        //Depositing chainlink tokens to swap contract

        swap.transferOwnership(msg.sender);

        chainlinkWithApiFeedSwaps.push(address(swap));
    }

    function createLinkFeedSwap(
        address _tokenA,
        address _tokenB,
        string memory _commDexName,
        uint256 _tradeFee,
        address _commodityChainlinkAddress,
        address _dexAdmin
    ) external onlyFactoryAdmin {
        require(
            _tokenA != address(0) && _tokenB != address(0),
            "Invalid address"
        );
        require(_tradeFee >= 0 && _tradeFee < 10**8, "wrong fee amount");
        require(chainlinkFeedSwaps.length < 1000, "You reached out limitation");

        ChainlinkSwap _clSwap = new ChainlinkSwap(
            _tokenA,
            _tokenB,
            _commDexName,
            _tradeFee,
            _commodityChainlinkAddress,
            _dexAdmin
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./BaseSwap.sol";
import "../interfaces/ISwapExtras.sol";
import "../utils/TransferHelper.sol";
import {PriceLib, ChainlinkLib} from "../lib/Lib.sol";

contract Swap is ChainlinkClient, BaseSwap, ISwapExtras {
    using ChainlinkLib for *;
    using SwapLib for *;
    using PriceLib for *;
   //chainlink appi request
    using Chainlink for Chainlink.Request;
  
    //check for price redirection
    bool public chainlinkFeedEnabled;
    //contrains API call info
    ChainlinkLib.ApiInfo private apiInfo;
    //Current Price and timeout info
    PriceLib.PriceInfo private priceInfo;
   //fee in terms on LINK tokenns
    uint256 private chainlinkTokenFee;
    //Chainlink Job Id
    bytes32 private jobId;

    constructor(
        //dex tokens
        address _tokenA,
        address _tokenB,
        //dex params
        SwapLib.DexSetting memory _dexSettings,
        //endpoint params
        ChainlinkLib.ApiInfo memory _apiData
    ) {
        require(
            _dexSettings.dexAdmin != address(0),
            "Invalid address"
        );

        dexData.tokenA = _tokenA;
        dexData.tokenB = _tokenB;
        dexSettings.comdexName = _dexSettings.comdexName;
        dexSettings.tradeFee = _dexSettings.tradeFee;
        dexSettings.rateTimeOut = _dexSettings.rateTimeOut;
        dexSettings.dexAdmin = _dexSettings.dexAdmin;
        
        apiInfo = _apiData;
    }

    function initChainlinkAndPrieInfo(
        ChainlinkLib.ChainlinkInfo memory _chainlinkInfo
    ) external onlyOwner {
        if (_chainlinkInfo.chainlinkFeedEnabled) {
            chainlinkFeedEnabled = true;
            priceFeed = AggregatorV3Interface(
                _chainlinkInfo.chianlinkPriceFeed
            );
        }
        setChainlinkToken(_chainlinkInfo.chainlinkToken);
        setChainlinkOracle(_chainlinkInfo.chainlinkOracle);

        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        chainlinkTokenFee = (1 * LINK_DIVISIBILITY) / 10; // 0.1 LINK Token as fee for each request

        priceInfo.rates = new uint256[](2);
        priceInfo.chainlinkRequestId = new bytes32[](2);
        priceInfo.lastTimeStamp = new uint256[](2);
        priceInfo.lastPriceFeed = new uint256[](2);

        //Load both buy and sell rate
        setPriceFeed(SwapLib.BUY_INDEX);
        setPriceFeed(SwapLib.SELL_INDEX);
    }

    function swap(
        uint256 _amountIn,
        address _from,
        address _to
    ) external virtual whenNotPaused{
        require(_amountIn > 0, "wrong amount");
        require(
            (_from == dexData.tokenA && _to == dexData.tokenB) ||
                (_to == dexData.tokenA && _from == dexData.tokenB),
            "wrong pair"
        );

        uint256 amountFee = (_amountIn * dexSettings.tradeFee) / (10**8);

        if (_from == dexData.tokenA) {
            if (!chainlinkFeedEnabled) {
                //reqiest a fresh price from API
                setPriceFeed(SwapLib.SELL_INDEX);
                //revert for outdated price
                require(!isRateTimeout(SwapLib.SELL_INDEX), "rate timeout");
            }

            uint256 amountA = _amountIn - amountFee;
            uint256 amountB = fetchPrice(SwapLib.SELL_INDEX, amountA);

            if (dexData.reserveB < amountB)
                emit LowTokenBalance(dexData.tokenB, dexData.reserveB);
            require(dexData.reserveB >= amountB, "not enough balance");

            TransferHelper.safeTransferFrom(
                dexData.tokenA,
                msg.sender,
                address(this),
                _amountIn
            );
            TransferHelper.safeTransfer(dexData.tokenB, msg.sender, amountB);

            dexData.reserveA = dexData.reserveA + amountA;
            dexData.reserveB = dexData.reserveB - amountB;
            dexData.feeA_Storage = dexData.feeA_Storage + amountFee;
            emit Swapped(msg.sender, _amountIn, amountB, SwapLib.SELL_INDEX);
        } else {
            if (!chainlinkFeedEnabled) {
                //reqiest a fresh price from API
                setPriceFeed(SwapLib.BUY_INDEX);
                //revert for outdated price
                require(!isRateTimeout(SwapLib.BUY_INDEX), "rate timeout");
            }
            uint256 amountB = _amountIn - amountFee;
            uint256 amountA = fetchPrice(SwapLib.BUY_INDEX, amountB);

            if (dexData.reserveA < amountA)
                emit LowTokenBalance(dexData.tokenA, dexData.reserveA);
            require(dexData.reserveA >= amountA, "not enough balance");

            TransferHelper.safeTransferFrom(
                dexData.tokenB,
                msg.sender,
                address(this),
                _amountIn
            );
            TransferHelper.safeTransfer(dexData.tokenA, msg.sender, amountA);

            dexData.reserveA = dexData.reserveA - amountA;
            dexData.reserveB = dexData.reserveB + amountB;
            dexData.feeB_Storage = dexData.feeB_Storage + amountFee;
            emit Swapped(msg.sender, _amountIn, amountA, SwapLib.BUY_INDEX);
        }
    }

    function getChainLinkFeedPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        require(price >= 0, "ChainLink price error");
        return uint256(price);
    }

    function convertPrice(
        uint256 _index,
        uint256 _amount,
        uint256 price
    ) internal pure returns (uint256) {
        if (_index == SwapLib.SELL_INDEX) return (_amount * price) / (10**8);
        else return (_amount * (10**8)) / price;
    }

    function fetchPrice(uint256 _index, uint256 _amount)
        internal
        view
        returns (uint256)
    {
        // fetch from chainLink when feed enabled
        if (chainlinkFeedEnabled)
            return convertPrice(_index, _amount, getChainLinkFeedPrice());
        // when chainLinkPriceFeed is disabled
        else
            return
                convertPrice(_index, _amount, priceInfo.lastPriceFeed[_index]);
    }

    function setPriceFeed(uint256 _isSale) internal {
        if (priceInfo.rates[_isSale] != 0) {
            priceInfo.lastTimeStamp[_isSale] = block.timestamp;
            priceInfo.lastPriceFeed[_isSale] = priceInfo.rates[_isSale];
        }
        priceInfo.chainlinkRequestId[_isSale] = requestVolumeData(_isSale);
    }

    function isRateTimeout(uint256 _isSale) internal view returns (bool) {
        if (priceInfo.lastTimeStamp[_isSale] == 0) return true;
        if (
            block.timestamp - priceInfo.lastTimeStamp[_isSale] >
            dexSettings.rateTimeOut
        ) return true;
        // yes the price feed is expired
        else return false; // no the price feed is not expired
    }

    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(
            fetchPrice(SwapLib.SELL_INDEX, amountA) == amountB,
            "amounts should be equal"
        );
        super._addLiquidity(amountA, amountB);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB)
        external
        onlyOwner
    {
        require(
            fetchPrice(SwapLib.SELL_INDEX, amountA) == amountB,
            "amounts should be equal"
        );
        super._removeLiquidity(amountA, amountB);
    }

    function requestVolumeData(uint256 flag)
        internal
        returns (bytes32 requestRate)
    {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        // Set the URL to perform the GET request on
        req.add("get", apiInfo._apiUrl);
        req.add("path", apiInfo._chainlinkRequestPath[flag]); // Chainlink nodes 1.0.0 and later support this format

        // Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10**8;
        req.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequest(req, chainlinkTokenFee);
    }

    // rate between token A and token B * (10**8)

    function fulfill(bytes32 _requestId, uint256 _rate)
        external
        recordChainlinkFulfillment(_requestId)
    {
        uint256 index = (_requestId ==
            priceInfo.chainlinkRequestId[SwapLib.BUY_INDEX])
            ? SwapLib.BUY_INDEX
            : SwapLib.SELL_INDEX;
        priceInfo.rates[index] = _rate;
        if (priceInfo.lastPriceFeed[index] == 0)
            // first time priceInfo.lastPriceFeed will be same
            priceInfo.lastPriceFeed[index] = _rate;
        emit RequestRateFulfilled(_requestId, _rate);
    }

    function setChainlinkFeedEnable(bool _flag) external onlyOwner {
        require(_flag != chainlinkFeedEnabled, "Already Enabled or Disabled");
        chainlinkFeedEnabled = _flag;

        emit ChainlinkFeedEnabled(_flag);
    }

    function setApiUrl(string memory _newUrl) external onlyOwner {
        apiInfo._apiUrl = _newUrl;
        emit ApiUrlChanged(_newUrl);
    }

    function setBuyPath(string memory _newBuyPath) external onlyOwner {
        apiInfo._chainlinkRequestPath[SwapLib.BUY_INDEX] = _newBuyPath;
        emit ApiBuyPathChanged(_newBuyPath);
    }

    function setSellPath(string memory _newSellPath) external onlyOwner {
        apiInfo._chainlinkRequestPath[SwapLib.SELL_INDEX] = _newSellPath;
        emit ApiSellPathChanged(_newSellPath);
    }

    // CommDEX admin functions
    function setChainlinkTokenddress(address _newChainlinkAddr)
        external
        onlyComdexAdmin
    {
        setChainlinkToken(_newChainlinkAddr);
        emit ChainlinkTokenAddressChanged(_newChainlinkAddr);
    }

    function setChainlinkOracleAddress(address _newChainlinkOracleAddr)
        external
        onlyComdexAdmin
    {
        setChainlinkOracle(_newChainlinkOracleAddr);

        emit ChainlinkOracleAddressChanged(_newChainlinkOracleAddr);
    }

    function setRateTimeOut(uint256 _newDuration) external onlyComdexAdmin {
        require(_newDuration >= 120 && _newDuration <= 300, "Wrong Duration!");
        dexSettings.rateTimeOut = _newDuration;
        emit RateTimeoutChanged(_newDuration);
    }

    /// @dev Get buy or sell rate
    /// @param _rateIndex 0 for buy 1 for sell
    /// @return Either buy rate or sell rate depending on index
    function getRate(uint256 _rateIndex) external view returns (uint256) {
        return priceInfo.rates[_rateIndex];
    }

    /// @dev Get buy or sell priceInfo.lastPriceFeed
    /// @param _flag 0 for buy 1 for sell
    /// @return Either buy  or sell priceInfo.lastPriceFeed
    function getlastPriceFeed(uint256 _flag) external view returns (uint256) {
        return priceInfo.lastPriceFeed[_flag];
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() external onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;
import "./BaseSwap.sol";

contract ChainlinkSwap is BaseSwap {
    constructor(
        address _tokenA,
        address _tokenB,
        string memory _commdexName,
        uint256 _tradeFee,
        address _commodityChainlinkAddress,
        address _dexAdmin
    ) {
        require(
            _dexAdmin != address(0),
            "Invalid address"
        );
        dexData.tokenA = _tokenA;
        dexData.tokenB = _tokenB;
        dexSettings.comdexName = _commdexName;
        dexSettings.tradeFee = _tradeFee;
        dexSettings.dexAdmin = _dexAdmin;

        priceFeed = AggregatorV3Interface(_commodityChainlinkAddress);
    }

    function swap(
        uint256 _amountIn,
        address _from,
        address _to
    ) external virtual whenNotPaused {
        require(_amountIn > 0, "Invalid amount");
        require(
            (_from == dexData.tokenA && _to == dexData.tokenB) ||
                (_to == dexData.tokenA && _from == dexData.tokenB),
            "wrong pair"
        );

        uint256 amountFee = (_amountIn * dexSettings.tradeFee) / (10**8);

        if (_from == dexData.tokenA) {
            uint256 amountA = _amountIn - amountFee;
            uint256 amountB = (amountA * getChainLinkFeedPrice()) / (10**8);

            if (dexData.reserveB < amountB)
                emit LowTokenBalance(dexData.tokenB, dexData.reserveB);
            require(dexData.reserveB >= amountB, "not enough balance");

            TransferHelper.safeTransferFrom(
                dexData.tokenA,
                msg.sender,
                address(this),
                _amountIn
            );
            TransferHelper.safeTransfer(dexData.tokenB, msg.sender, amountB);

            dexData.reserveA = dexData.reserveA + amountA;
            dexData.reserveB = dexData.reserveB - amountB;
            dexData.feeA_Storage = dexData.feeA_Storage + amountFee;
            emit Swapped(msg.sender, _amountIn, amountB, SwapLib.SELL_INDEX);
        } else {
            uint256 amountB = _amountIn - amountFee;
            uint256 amountA = (amountB * (10**8)) / getChainLinkFeedPrice();

            if (dexData.reserveA < amountA)
                emit LowTokenBalance(dexData.tokenA, dexData.reserveA);
            require(dexData.reserveA >= amountA, "not enough balance");

            TransferHelper.safeTransferFrom(
                dexData.tokenB,
                msg.sender,
                address(this),
                _amountIn
            );
            TransferHelper.safeTransfer(dexData.tokenA, msg.sender, amountA);

            dexData.reserveA = dexData.reserveA - amountA;
            dexData.reserveB = dexData.reserveB + amountB;
            dexData.feeB_Storage = dexData.feeB_Storage + amountFee;
            emit Swapped(msg.sender, _amountIn, amountA, SwapLib.BUY_INDEX);
        }
    }

    function getChainLinkFeedPrice() public view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        require(price >= 0, "ChainLink price error");
        return uint256(price);
    }

    function addLiquidity(uint256 amountA, uint256 amountB)
        external
        virtual
        onlyOwner
    {
        require(
            (amountA * getChainLinkFeedPrice()) / (10**8)  == amountB,
            "amounts should be equal"
        );
        super._addLiquidity(amountA, amountB);
        emit LiquidityAdded(_msgSender(), amountA, amountB);
    }

    function removeLiquidity(uint256 amountA, uint256 amountB)
        external
        virtual
        onlyOwner
    {
        require(
            (amountA * getChainLinkFeedPrice()) / (10**8) == amountB,
            "amountA should be equal"
        );
        super._removeLiquidity(amountA, amountB);
        emit LiquidityRemoved(_msgSender(), amountA, amountB);
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
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../utils/TransferHelper.sol";
import "../interfaces/ISwap.sol";
import "./../utils/Pausable.sol";

import {SwapLib} from "../lib/Lib.sol";

abstract contract BaseSwap is Ownable, ISwap, Pausable {
    using SwapLib for *;

    SwapLib.DexData public dexData;
    SwapLib.DexSetting public dexSettings;
    AggregatorV3Interface internal priceFeed;

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

    function _addLiquidity(uint256 amountA, uint256 amountB) internal {
        TransferHelper.safeTransferFrom(
            dexData.tokenA,
            msg.sender,
            address(this),
            amountA
        );
        TransferHelper.safeTransferFrom(
            dexData.tokenB,
            msg.sender,
            address(this),
            amountB
        );
        dexData.reserveA = dexData.reserveA + amountA;
        dexData.reserveB = dexData.reserveB + amountB;
        emit LiquidityAdded(_msgSender(), amountA, amountB);
    }

    function _removeLiquidity(uint256 amountA, uint256 amountB) internal {
        TransferHelper.safeTransfer(dexData.tokenA, _msgSender(), amountA);
        TransferHelper.safeTransfer(dexData.tokenB, _msgSender(), amountB);
        dexData.reserveA = dexData.reserveA - amountA;
        dexData.reserveB = dexData.reserveB - amountB;
        emit LiquidityRemoved(_msgSender(), amountA, amountB);
    }

    // rate between token A and token B * (10**8)

    function setTradeFee(uint256 _newTradeFee) external onlyComdexAdmin {
        require(_newTradeFee >= 0 && _newTradeFee < 10**8, "Wrong Fee!");
        dexSettings.tradeFee = _newTradeFee;
        emit TradeFeeChanged(_newTradeFee);
    }

    function withdrawFee() external onlyComdexAdmin {
        TransferHelper.safeTransfer(
            dexData.tokenA,
            msg.sender,
            dexData.feeA_Storage
        );
        TransferHelper.safeTransfer(
            dexData.tokenB,
            msg.sender,
            dexData.feeB_Storage
        );

        emit FeeWithdraw(
            msg.sender,
            dexData.feeA_Storage,
            dexData.feeB_Storage
        );

        dexData.feeA_Storage = 0;
        dexData.feeB_Storage = 0;
    }

    function setChainlinkFeedAddress(address _chainlinkPriceFeed)
        external
        onlyComdexAdmin
    {
        priceFeed = AggregatorV3Interface(_chainlinkPriceFeed);
        emit ChainlinkFeedAddressChanged(_chainlinkPriceFeed);
    }

    function setCommdexAdmin(address _updatedAdmin) external onlyComdexAdmin {
        require(
            _updatedAdmin != address(0) &&
                _updatedAdmin != dexSettings.dexAdmin,
            "Invalid Address"
        );
        dexSettings.dexAdmin = _updatedAdmin;
        emit ComDexAdminChanged(_updatedAdmin);
    }

    function emergencyWithdraw() external onlyOwner {
        TransferHelper.safeTransfer(
            dexData.tokenA,
            msg.sender,
            dexData.reserveA
        );
        TransferHelper.safeTransfer(
            dexData.tokenB,
            msg.sender,
            dexData.reserveB
        );

        emit EmergencyWithdrawComplete(
            msg.sender,
            dexData.reserveA,
            dexData.reserveB
        );

        dexData.reserveA = 0;
        dexData.reserveB = 0;
    }

    function withDrawAndDestory() external onlyComdexAdmin {
        // withdraw the reserves
        TransferHelper.safeTransfer(
            dexData.tokenA,
            msg.sender,
            dexData.reserveA
        );
        TransferHelper.safeTransfer(
            dexData.tokenB,
            msg.sender,
            dexData.reserveB
        );
        // withdraw fees
        TransferHelper.safeTransfer(
            dexData.tokenA,
            dexSettings.dexAdmin,
            dexData.feeA_Storage
        );
        TransferHelper.safeTransfer(
            dexData.tokenB,
            dexSettings.dexAdmin,
            dexData.feeB_Storage
        );
        emit withDrawAndDestroyed(
            msg.sender,
            dexData.reserveA,
            dexData.reserveB,
            dexData.feeA_Storage,
            dexData.feeB_Storage
        );
        dexData.reserveA = 0;
        dexData.reserveB = 0;
        dexData.feeA_Storage = 0;
        dexData.feeB_Storage = 0;
    }

    function unpause() external onlyComdexAdmin {
        _unpause();
    }

    function pause() external onlyComdexAdmin{
        _pause();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

interface ISwapExtras {
    event ChainlinkFeedAddrChanged(address newFeedAddress);
    event RequestRateFulfilled(bytes32 indexed requestRate, uint256 rate);
    event ChainlinkFeedEnabled(bool flag);
    event ApiUrlChanged(string newUrl);
    event ApiBuyPathChanged(string newBuyPath);
    event ApiSellPathChanged(string newSellPath);
    event ChainlinkTokenAddressChanged(address newTokenAddress);
    event ChainlinkOracleAddressChanged(address newOracleAddress);
    event RateTimeoutChanged(uint256 newDuration);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

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
    uint256 constant BUY_INDEX = 0;
    uint256 constant SELL_INDEX = 1;
    struct DexSetting {
        string comdexName;
        uint256 tradeFee;
        address dexAdmin;
        uint256 rateTimeOut;
    }

    struct DexData {
        uint256 reserveA;
        uint256 reserveB;
        uint256 feeA_Storage; // storage that the fee of token A can be stored
        uint256 feeB_Storage; // storage that the fee of token B can be stored
        address tokenA;
        address tokenB;
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

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.15;

interface ISwap {
    event LowTokenBalance(address Token, uint256 balanceLeft);
    event Swapped(
        address indexed sender,
        uint256 amountIn,
        uint256 amountOut,
        uint256 isSale
    );
    event LiquidityAdded(
        address indexed sender,
        uint256 amountA,
        uint256 amountB
    );
    event LiquidityRemoved(
        address indexed sender,
        uint256 amountA,
        uint256 amountB
    );
    event TradeFeeChanged(uint256 newTradeFee);
    event ComDexAdminChanged(address newAdmin);
    event EmergencyWithdrawComplete(
        address indexed sender,
        uint256 amountA,
        uint256 amountB
    );
    event FeeWithdraw(address indexed sender, uint256 amountA, uint256 amountB);
    event ChainlinkFeedAddressChanged(address newFeedAddress);
    event withDrawAndDestroyed(
        address indexed sender,
        uint256 reserveA,
        uint256 reserveB,
        uint256 feeA,
        uint256 feeB
    );
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