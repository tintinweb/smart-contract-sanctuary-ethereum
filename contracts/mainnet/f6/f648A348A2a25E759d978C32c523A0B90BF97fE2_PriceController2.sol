/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// File: iface/IERC20.sol

pragma solidity ^0.8.4;

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

// File: iface/IPriceController.sol


pragma solidity ^0.8.4;

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
// File: iface/INestPriceFacadeForNest4.sol


pragma solidity ^0.8.4;

interface INestPriceFacadeForNest4 {
    function triggeredPriceInfo(
        uint channelId, 
        uint[] calldata pairIndices,
        address payback
    ) external payable returns (uint[] memory prices);
}
// File: PriceController2.sol


pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;




contract PriceController2 is IPriceController {

    // Nest price
    INestPriceFacadeForNest4 _nestBatchPlatform;
    // usdt address
    address constant USDT_ADDRESS = address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    // usdt base amount
    uint256 constant BASE_USDT_AMOUNT = 2000 ether;
    // Channel id
    uint256 constant CHANNELID = 0;
    // pair index
    mapping(address => uint256) addressToPriceIndex;

    /// @dev Initialization method
    /// @param nestBatchPlatform Nest price contract
	constructor (address nestBatchPlatform) {
		_nestBatchPlatform = INestPriceFacadeForNest4(nestBatchPlatform);
        addressToPriceIndex[address(0x0316EB71485b0Ab14103307bf65a021042c6d380)] = 0;
        addressToPriceIndex[address(0x0)] = 1;
        addressToPriceIndex[address(0x04abEdA201850aC0124161F037Efd70c74ddC74C)] = 2;
    }

    function getAddressToPriceIndex(
        address tokenAddress
    ) public view returns(uint256) {
        return addressToPriceIndex[tokenAddress];
    }

    /// @dev Get price
    /// @param token mortgage asset address
    /// @param uToken underlying asset address
    /// @param payback return address of excess fee
    /// @return tokenPrice Mortgage asset price(2000U = ? token)
    /// @return pTokenPrice PToken price(2000U = ? pToken)
    function getPriceForPToken(
        address token, 
        address uToken,
        address payback
    ) public payable override returns (
        uint256 tokenPrice,
        uint256 pTokenPrice
    ) {
        if(uToken == address(USDT_ADDRESS)) {
            uint256[] memory pricesIndex = new uint256[](1);
            pricesIndex[0] = addressToPriceIndex[token];
            uint256[] memory prices = _nestBatchPlatform.triggeredPriceInfo{value:msg.value}(CHANNELID, pricesIndex, payback);
            require(prices[2] > 0, "Log:PriceController:!avg");
            return(prices[2], BASE_USDT_AMOUNT);
        } else {
            uint256[] memory pricesIndex = new uint256[](2);
            pricesIndex[0] = addressToPriceIndex[token];
            pricesIndex[1] = addressToPriceIndex[uToken];
            uint256[] memory prices = _nestBatchPlatform.triggeredPriceInfo{value:msg.value}(CHANNELID, pricesIndex, payback);
            require(prices[2] > 0 && prices[6] > 0, "Log:PriceController:!avg");
            return(prices[2], prices[6]);
        }
    }
}