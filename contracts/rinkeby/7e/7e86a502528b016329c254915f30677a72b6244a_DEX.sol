/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/IERC20.sol



pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function cap() external view returns (uint256);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
    function burn(address from, uint256 amount) external returns (bool);
}
// File: contracts/DEX.sol



pragma solidity ^0.8.0;

// import "./RMDSEth.sol";




contract DEX is Ownable, ReentrancyGuard {

    // RMDSEthToken public token;
    IERC20 public token;
    uint256 public price;
    address public RMDS_ADDRESS;
    address public ETH_ADDRESS=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public USDC_ADDRESS;//=0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public USDT_ADDRESS;//=0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public DAI_ADDRESS;//=0x6B175474E89094C44Da98b954EedeAC495271d0F;

    event Bought(address account, uint256 amount, uint256 timestamp);
    event Sold(address account, uint256 amount, uint256 timestamp);
    event PriceUpdated(uint256 price, uint256 timestamp);

    constructor(address tokenAddress, address USDCTokenAddress, address USDTTokenAddress, address DAITokenAddress, uint256 tokenPrice) {
        // token = RMDSEthToken(tokenAddress);
        RMDS_ADDRESS = tokenAddress;
        USDC_ADDRESS = USDCTokenAddress;
        USDT_ADDRESS = USDTTokenAddress;
        DAI_ADDRESS = DAITokenAddress;
        token = IERC20(tokenAddress);
        price = tokenPrice;
    }

    function swapEthToToken(address to, uint256 amount) private {
        require(msg.value >= amount*price/10**18, "Amount is low");
        uint256 balance = token.balanceOf(address(this));
        if (amount > balance) {
            token.mint(address(this), amount - balance);
        }
        token.transfer(to, amount);
        emit Bought(to, amount, block.timestamp);
    }

    function getTokenAmount(address token0Address, address token1Address, IERC20 token0, IERC20 token1, uint256 amount) private view returns (uint256, uint256) {
        uint256 token0Decimals = token0.decimals();
        uint256 token1Decimals = token1.decimals();
        uint256 amount0;
        uint256 amount1;
        if (token0Address == RMDS_ADDRESS) {
            amount0 = amount; 
            amount1 = (amount*(10**token1Decimals))/(10*(10**token0Decimals));
        }
        if (token1Address == RMDS_ADDRESS) {
            amount0 = (amount*(10**token0Decimals))/(10*(10**token1Decimals));
            amount1 = amount;
        }
        return (amount0, amount1);
    }

    function swapTokenToToken(address token0Address, address token1Address, address accountAddress, uint256 amount) private {
        IERC20 token0 = IERC20(token0Address);
        IERC20 token1 = IERC20(token1Address);
        uint256 token0Balance = token0.balanceOf(accountAddress);
        ( uint256 token0Amount, uint256 token1Amount) = getTokenAmount(token0Address, token1Address, token0, token1, amount);
        require(token0Balance >= token0Amount, "Amount is low");
        uint256 balance = token1.balanceOf(address(this));
        token0.transferFrom(accountAddress, address(this), token0Amount);
        if (token1Address == RMDS_ADDRESS && token1Amount > balance) {
            token1.mint(address(this), token1Amount - balance);
        }
        token1.transfer(accountAddress, token1Amount);
        emit Bought(accountAddress, amount, block.timestamp);
    }

    function swapTokenToEth(address from, uint256 amount) private {
        require(amount*price/10**18 <= address(this).balance, "Funds not available at this moment! Please try again later.");
        token.transferFrom(from, address(this), amount);
        payable(from).transfer(amount*price/10**18);
        emit Sold(from, amount, block.timestamp);
    }

    function buy(address tokenAddress, uint256 amountTobuy) external payable {
        require(amountTobuy > 0, "You need to buy some tokens");
        require(tokenAddress == ETH_ADDRESS || tokenAddress == USDC_ADDRESS || tokenAddress == USDT_ADDRESS || tokenAddress == DAI_ADDRESS || tokenAddress == address(0), "token swapping not available for the provided token address");
        if (tokenAddress == ETH_ADDRESS || tokenAddress == address(0)) {
            swapEthToToken(msg.sender, amountTobuy);
        } else {
            swapTokenToToken(tokenAddress, RMDS_ADDRESS, msg.sender, amountTobuy);
        }
    }

    function sell(address tokenAddress, uint256 amountToSell) external nonReentrant {
        require(amountToSell > 0, "You need to sell at least some tokens");
        require(amountToSell <= token.balanceOf(msg.sender), "Not enough tokens available on your account!");
        require(tokenAddress == ETH_ADDRESS || tokenAddress == USDC_ADDRESS || tokenAddress == USDT_ADDRESS || tokenAddress == DAI_ADDRESS || tokenAddress == address(0), "token swapping not available for the provided token address");
        if (tokenAddress == ETH_ADDRESS || tokenAddress == address(0)) {
            swapTokenToEth(msg.sender, amountToSell);
        } else {
            swapTokenToToken(RMDS_ADDRESS, tokenAddress, msg.sender, amountToSell);
        }
    }

    function updatePrice(uint256 newPrice) external onlyOwner {
        price = newPrice;
        emit PriceUpdated(newPrice, block.timestamp);
    }
}