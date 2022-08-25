// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
Running 'scripts\deploy.py::main'...
Transaction sent: 0xecbfd277869cb4e7afffe1bc395a5ee4b6f34e1c7cca59bd4ea13091236949b3
  Gas price: 2.500000007 gwei   Gas limit: 1554753   Nonce: 107
  Sale_mult_float.constructor confirmed   Block: 33447625   Gas used: 1413412 (90.91%)
  Sale_mult_float deployed at: 0x0744DC24E8b8f531CFA6F7AD4792f90F8d549730

Waiting for https://api-kovan.etherscan.io/api to process contract...
Verification submitted successfully. Waiting for result...
Verification pending...
Verification complete. Result: Pass - Verified
 */

import "IBEP20.sol";
import "Ownable.sol";

contract Sale_mult_float is Ownable {

    address public USDT; //address of the token which creates the price of the security token
    address public SECURITIES; //address of the security token

    uint256 public basePrice; // price of the secutity token in USD*(10**baseDecimals)
    uint8 public baseDecimals; //decimals of the base price
    address public manager; // manager of the smart contract
    bool public status; // isActive

    struct Order {
        uint256 securities;
        uint256 USDT;
        address token; // address of the token with which security was bought
        string orderId;
        address payer;
    }

    Order[] public orders;    
    uint256 public ordersCount;

    address[] public allowedTokens;
    mapping (address => bool) isTokenAllowed;

    event BuyTokensEvent(address buyer, uint256 amountSecurities, address swapToken);

    constructor(address _USDT, address _securities) {
        USDT = _USDT;
        SECURITIES = _securities;
        manager = _msgSender();
        ordersCount = 0;
        basePrice = 4250; //=42,50 USDT
        baseDecimals = 2;
        status = true;
        allowedTokens.push(_USDT);
        isTokenAllowed[_USDT] = true;
    }

    modifier onlyManager() {
        require(_msgSender() == manager, "Wrong sender");
        _;
    }

    modifier onlyActive() {
        require(status == true, "Sale: not active");
        _;
    }

    modifier onlyAllowedTokens(address _token) {
        require(isTokenAllowed[_token] == true, "Sale: this token is not allowed");
        _;
    }

    function changeManager(address newManager) public onlyOwner {
        manager = newManager;
    }

    function changeStatus(bool _status) public onlyOwner {
        status = _status;
    }
    
    /// @notice price and its decimals of the secutity token in USDT
    /// @param priceInUSDT price of Security in USDT
    /// @param priceDecimals decimals for price in USDT
    function setPrice(uint256 priceInUSDT, uint8 priceDecimals) public onlyManager {
        basePrice = priceInUSDT;
        baseDecimals = priceDecimals;
    }

    /// @notice Add the address of token to allowed tokens.
    /// Only Manager can add new token to allowed.
    /// @param _token Address of token to add to allowed tokens.    
    function addAllowedToken(address _token) public onlyManager returns (bool) {
        require(_token != address(0), "Sale: You try to add zero-address");
        require(isTokenAllowed[_token] == false, "Sale: This token is already allowed");
        allowedTokens.push(_token);
        isTokenAllowed[_token] = true;  
        return true;  
    }

    /// @notice Remove the address of token from the list of allowed tokens.
    /// Only Manager can remove token from allowed.
    /// @param _token Address of token to remove from the list of allowed tokens.    
    function removeTokenFromAllowed(address _token) public onlyManager returns (bool) {
        require(isTokenAllowed[_token] == true, "You try to remove token, which is not allowed");        
        for (uint i = 0; i < allowedTokens.length; i++)
            if (allowedTokens[i] == _token)
                delete allowedTokens[i];        
        isTokenAllowed[_token] = false;
        return true;
    }

    /// @notice swap of the token to security.    
    /// @dev make swap, create and write the order of the operation, emit BuyTokensEvent
    /// @param amountUSDT amount of token to buy securities
    /// @param swapToken address of the token to buy security. 
    /// Token has to be Allowed.
    /// Token has to be equal to the USDT in price, in other way formula doesn't work
    /// @return true if the operation done successfully
    function buyToken(
        uint256 amountUSDT, 
        address swapToken, 
        string memory orderId) 
            public 
            onlyActive 
            onlyAllowedTokens(swapToken) 
            returns(bool) {
        
        uint256 scaledTokenAmount = _scaleAmount(amountUSDT, IBEP20(swapToken).decimals(), baseDecimals);
        uint256 amountSecurities = (scaledTokenAmount / basePrice) * (10 ** (IBEP20(SECURITIES).decimals()));
        Order memory order;
        IBEP20(swapToken).transferFrom(_msgSender(), address(this), amountUSDT);
        require(IBEP20(SECURITIES).transfer(_msgSender(), amountSecurities), "transfer: SEC error");

        order.USDT = amountUSDT;
        order.securities = amountSecurities;
        order.token = swapToken;
        order.orderId = orderId;
        order.payer = _msgSender();
        orders.push(order);
        ordersCount += 1;

        emit BuyTokensEvent(_msgSender(), amountSecurities, swapToken);
        return true;
    }
    
    /// @notice Owner of the contract has an opportunity to send any tokens from the contract to his/her wallet    
    /// @param amount amount of the tokens to send (18 decimals)
    /// @param token address of the tokens to send
    /// @return true if the operation done successfully
    function sendBack(uint256 amount, address token) public onlyOwner returns(bool) {
        require(IBEP20(token).transfer(_msgSender(), amount), "Transfer: error");
        return true;
    }

    /// @notice function count and return the amount of security to be gotten for the proper amount of tokens         
    /// @param amountUSDT amount of token you want to spend
    /// @param swapToken address of token you want to use for buying security
    /// Token has to be Allowed
    /// @return token , securities -  tuple of uintegers - (amount of token to spend, amount of securities to get)    
    function buyTokenView(
        uint256 amountUSDT, 
        address swapToken) 
            public 
            view 
            onlyAllowedTokens(swapToken)
            returns(uint256 token, uint256 securities) {
        uint256 scaledAmountUSDT = _scaleAmount(amountUSDT, IBEP20(swapToken).decimals(), baseDecimals);
        uint256 amountSecurities = (scaledAmountUSDT / basePrice) * (10 ** (IBEP20(SECURITIES).decimals()));
        return (
        amountUSDT, amountSecurities
         );
    }

    /// @notice the function reduces the amount to the required decimals      
    /// @param _amount amount of token you want to reduce
    /// @param _amountDecimals decimals which amount has now
    /// @param _decimals decimals you want to get after scaling
    /// @return uint256 the scaled amount with proper decimals
    function _scaleAmount(uint256 _amount, uint8 _amountDecimals, uint8 _decimals)
        internal
        pure
        returns (uint256)
    {
        if (_amountDecimals < _decimals) {
            return _amount * (10 ** uint256(_decimals - _amountDecimals));
        } else if (_amountDecimals > _decimals) {
            return _amount / (10 ** uint256(_amountDecimals - _decimals));
        }
        return _amount;
    }

}

pragma solidity ^0.8.0;

interface IBEP20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external;
}

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
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

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