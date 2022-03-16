/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface INestPriceFacadeForNest4 {
    function triggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        address payback
    ) external payable returns (uint[] memory prices);
}

interface INestPriceFacade {
	/// @dev Price call entry configuration structure
    struct Config {

        // Single query fee（0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;

        // Double query fee（0.0001 ether, DIMI_ETHER). 100
        uint16 doubleFee;

        // The normal state flag of the call address. 0
        uint8 normalFlag;
    }
    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view returns (Config memory);

    /// @dev Get the full information of latest trigger price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447, 
    ///         it means that the volatility has exceeded the range that can be expressed
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    /// @return ntokenAvgPrice Average price of ntoken
    /// @return ntokenSigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo2(address tokenAddress, address paybackAddress) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ, uint ntokenBlockNumber, uint ntokenPrice, uint ntokenAvgPrice, uint ntokenSigmaSQ);

    /// @dev Get the full information of latest trigger price
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(address tokenAddress, address paybackAddress) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ);
}

interface IPriceController {
    /// @dev Get price
    /// @param token mortgage asset address
    /// @param uToken underlying asset address
    /// @param payback return address of excess fee
    /// @return tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @return pTokenPrice PToken price(1 ETH = ? pToken)
    function getPriceForPToken(
    	address token, 
        address uToken,
        address payback
	) external payable returns (uint256 tokenPrice, uint256 pTokenPrice);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

contract PriceController3 is IPriceController {
    // Nest price contract
    INestPriceFacadeForNest4 immutable _nestBatchPlatform;
    INestPriceFacade immutable _nestPriceFacade;
    // usdt address
    address constant USDT_ADDRESS =
        address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    // nest address
    address constant NEST_ADDRESS =
        address(0x04abEdA201850aC0124161F037Efd70c74ddC74C);
    // HBTC address
    address constant HBTC_ADDRESS =
        address(0x0316EB71485b0Ab14103307bf65a021042c6d380);
    // nest4 base usdt amount
    uint256 constant BASE_USDT_AMOUNT = 2000 ether;
    // nest4 channel id
    uint256 constant CHANNELID = 0;
    // asset token address => price index
    mapping(address => uint256) addressToPriceIndex;
    // price fee
    uint256 public nest3Fee = 0.001 ether;
    // owner address
    address public owner;

    /// @dev Initialization method
    /// @param nestBatchPlatform Nest price contract
    /// @param nestPriceFacade Nest price contract
    constructor(address nestBatchPlatform, address nestPriceFacade) {
        _nestBatchPlatform = INestPriceFacadeForNest4(nestBatchPlatform);
        _nestPriceFacade = INestPriceFacade(nestPriceFacade);

        addressToPriceIndex[HBTC_ADDRESS] = 0;
        owner = msg.sender;
    }

    /// @dev Uniform accuracy
    /// @param inputToken Initial token
    /// @param inputTokenAmount Amount of token
    /// @param outputToken Converted token
    /// @return stability Amount of outputToken
    function getDecimalConversion(
        address inputToken,
        uint256 inputTokenAmount,
        address outputToken
    ) public view returns (uint256) {
        uint256 inputTokenDec = 18;
        uint256 outputTokenDec = 18;
        if (inputToken != address(0x0)) {
            inputTokenDec = IERC20(inputToken).decimals();
        }
        if (outputToken != address(0x0)) {
            outputTokenDec = IERC20(outputToken).decimals();
        }
        return (inputTokenAmount * (10**outputTokenDec)) / (10**inputTokenDec);
    }

    function checkAddressToPriceIndex(address tokenAddress)
        public
        view
        returns (uint256)
    {
        return addressToPriceIndex[tokenAddress];
    }

    function setNest3Fee(uint256 num) external {
        require(msg.sender == owner, "Log:PriceController:!owner");
        nest3Fee = num;
    }

    /// @dev Get price
    /// @param token mortgage asset address
    /// @param uToken underlying asset address
    /// @param payback return address of excess fee
    /// @return tokenPrice Mortgage asset price(1 ETH = ? token)
    /// @return pTokenPrice PToken price(1 ETH = ? pToken)
    function getPriceForPToken(
        address token,
        address uToken,
        address payback
    )
        public
        payable
        override
        returns (uint256 tokenPrice, uint256 pTokenPrice)
    {
        require(uToken == HBTC_ADDRESS, "Log:PriceController:!uToken");
        if (token == address(0x0)) {
            // The mortgage asset is ETH，get USDT-ETH price
            (, , uint256 avg, ) = _nestPriceFacade.triggeredPriceInfo{
                value: nest3Fee
            }(USDT_ADDRESS, payback);
            require(avg > 0, "Log:PriceController:!avg nest3");

            uint256[] memory pricesIndex = new uint256[](1);
            pricesIndex[0] = addressToPriceIndex[token];
            // get HBTC-USDT price
            uint256[] memory prices = _nestBatchPlatform.triggeredPriceInfo{
                value: msg.value - nest3Fee
            }(CHANNELID, pricesIndex, payback);
            require(prices[2] > 0, "Log:PriceController:!avg nest4");
            uint256 priceETH = (getDecimalConversion(
                USDT_ADDRESS,
                avg,
                address(0x0)
            ) * prices[2]) / BASE_USDT_AMOUNT;
            return (1 ether, priceETH);
        } else if (token == NEST_ADDRESS) {
            // The mortgage asset is nest，get USDT-NEST price
            (, , uint256 avg1, , , , uint256 avg2, ) = _nestPriceFacade
                .triggeredPriceInfo2{value: nest3Fee}(USDT_ADDRESS, payback);
            require(avg1 > 0 && avg2 > 0, "Log:PriceController:!avg nest3");

            uint256[] memory pricesIndex = new uint256[](1);
            pricesIndex[0] = addressToPriceIndex[token];
            // get HBTC-USDT price
            uint256[] memory prices = _nestBatchPlatform.triggeredPriceInfo{
                value: msg.value - nest3Fee
            }(CHANNELID, pricesIndex, payback);
            require(prices[2] > 0, "Log:PriceController:!avg nest4");
            uint256 priceETH = (getDecimalConversion(
                USDT_ADDRESS,
                avg1,
                address(0x0)
            ) * prices[2]) / BASE_USDT_AMOUNT;
            return (avg2, priceETH);
        } else {
            revert("Log:PriceController:no token");
        }
    }
}