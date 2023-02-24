/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: contracts/TokenExchange.sol



pragma solidity >=0.7.0 <0.9.0;


contract TokenExchange {
    
    struct OTC {
        address buyer;
        address seller;
        address tokenAddressIn;
        address tokenAddressOut;
        uint256 tokenAmountIn;
        uint256 tokenAmountOut;
        bool buyerExecuted;
        bool sellerExecuted;
    }
    
    mapping(bytes32 => OTC) public otcList;

    event OTCOpened(bytes32 otcID, address buyer, address seller, address tokenAddressIn, address tokenAddressOut, uint256 tokenAmountIn, uint256 tokenAmountOut);
    event OTCExecuted(bytes32 otcID);
    
    function OpenOTC(address _buyer, address _seller, address _tokenAddressIn, address _tokenAddressOut, uint256 _tokenAmountIn, uint256 _tokenAmountOut) public {
        bytes32 otcID = keccak256(abi.encodePacked(_buyer, _seller, _tokenAddressIn, _tokenAddressOut, _tokenAmountIn, _tokenAmountOut));
        require(otcList[otcID].buyer == address(0), "OTC already exists");
        otcList[otcID] = OTC(_buyer, _seller, _tokenAddressIn, _tokenAddressOut, _tokenAmountIn, _tokenAmountOut, false, false);
        emit OTCOpened(otcID, _buyer, _seller, _tokenAddressIn, _tokenAddressOut, _tokenAmountIn, _tokenAmountOut);
    }
    
    function ExecP2P(address _buyer, address _seller, address _tokenAddressIn, address _tokenAddressOut, uint256 _tokenAmountIn, uint256 _tokenAmountOut) public {
        bytes32 otcID = keccak256(abi.encodePacked(_buyer, _seller, _tokenAddressIn, _tokenAddressOut, _tokenAmountIn, _tokenAmountOut));
        OTC storage otc = otcList[otcID];
        require(otc.buyer == _buyer && otc.seller == _seller && otc.tokenAddressIn == _tokenAddressIn && otc.tokenAddressOut == _tokenAddressOut && otc.tokenAmountIn == _tokenAmountIn && otc.tokenAmountOut == _tokenAmountOut, "Invalid OTC");
        if (msg.sender == otc.buyer) {
            require(!otc.buyerExecuted, "OTC already executed by buyer");
            otc.buyerExecuted = true;
        } else if (msg.sender == otc.seller) {
            require(!otc.sellerExecuted, "OTC already executed by seller");
            otc.sellerExecuted = true;
        } else {
            revert("Unauthorized");
        }
        if (otc.buyerExecuted && otc.sellerExecuted) {
            require(IERC20(otc.tokenAddressIn).transferFrom(otc.buyer, otc.seller, otc.tokenAmountIn), "Token transfer failed");
            require(IERC20(otc.tokenAddressOut).transferFrom(otc.seller, otc.buyer, otc.tokenAmountOut), "Token transfer failed");
            emit OTCExecuted(otcID);
        }
    }
}