// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ISeasideNFT.sol";
import "./libraries/Splitter.sol";

// enum for coin
enum Coin { USDC, USDT, BUSD }

contract PrivateSales is Ownable {

    uint256 public constant priceDecimal = 1000;

    // price limit restriction
    uint256 public priceLimit = 500 * 10**18;

    // seaside coin
    IERC20 public immutable seasideCoin;

    // USDC coin
    IERC20 public immutable USDC;

    // USDT coin
    IERC20 public immutable USDT;
    
    // BUSD coin
    IERC20 public immutable BUSD;

    // seaside nft
    ISeasideNFT public immutable seasideNFT;

    // coin price
    uint256 public constant coinPriceUSD = 1 * priceDecimal;

    // private sale enable flags
    bool public privateSalesEnabled;

    // mapping for allowed addresses
    mapping(address=>bool) public isAllowed;
    
    // threashold on split count
    uint256 public constant threashold = 1000000 * 10**18;

    // initial max count
    uint256 public constant initialMaxCount = 100;

    // percentage of reward after buying
    uint256 public constant rewardPercentage = 10;

    constructor(
        address seasideCoin_,
        address seasideNFT_,
        address addressUSDC_,
        address addressUSDT_,
        address addressBUSD_
    )  {
        seasideCoin = IERC20(seasideCoin_);
        USDC = IERC20(addressUSDC_);
        USDT = IERC20(addressUSDT_);
        BUSD = IERC20(addressBUSD_);
        seasideNFT = ISeasideNFT(seasideNFT_);
    }

    /** 
     * @dev setting privateSalesEnabled variable
     * @param enabled boolean True if enables, False otherwise
    */

    function setPrivateSalesEnabled(bool enabled) external onlyOwner {
        privateSalesEnabled = enabled;
    }

    /** 
     * @dev setting allowed addresses
     * @param allowed boolean True if enables, False otherwise
    */

    function setAllowed(address[] calldata addresses, bool allowed) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; ++i) {
            isAllowed[addresses[i]] = allowed;
        }
    }

    /** 
     * @dev setting priceLimit variable
     * @param priceLimit_ new value
    */

    function setPriceLimit(uint256 priceLimit_) external onlyOwner {
        priceLimit = priceLimit_;
    }

    /**
     * @dev modifier to detect if address is allowed for buying coins
    */
    modifier whenAllowed() {
        require(isAllowed[msg.sender], "PrivateSales: address is not allowed to call this function");
        _;
    }

    /**
     * @dev get the max split count on amount
     * @param amount of coins
    */

    function getMaxSplitCount(uint256 amount) public pure returns(uint256) {
        return Splitter.getMaxSplitCount(threashold, initialMaxCount, amount);
    }


    /**
     * @dev Buy the coins in private Coins supply with USDC coin
     * @param amount USDC coins to be transferred
     * @param splitNFTCount nft count
     * @param coinType type of coin: USDC, USDT, BUSD
    */

    function buy(uint256 amount, uint256 splitNFTCount, Coin coinType) external whenAllowed {
        require(privateSalesEnabled, "PrivateSales: sale is not enabled");
        require(splitNFTCount <= getMaxSplitCount(amount), "PrivateSales: split count exceed it's limit");
        require(amount >= priceLimit, "PrivateSales: amount should be greater than price limit ");

        address paidCoinAddress;
        if (coinType == Coin.USDC) {
            USDC.transferFrom(msg.sender, address(this), amount);
            paidCoinAddress = address(USDC);
        }
        else if (coinType == Coin.USDT) {
            USDT.transferFrom(msg.sender, address(this), amount);
            paidCoinAddress = address(USDT);
        }
        else {
            BUSD.transferFrom(msg.sender, address(this), amount);
            paidCoinAddress = address(BUSD);
        }

        uint256 seasideCoins = priceDecimal * amount / coinPriceUSD;
        seasideCoin.transfer(address(seasideNFT), seasideCoins);

        seasideNFT.mint(
            msg.sender, 
            seasideCoins, 
            splitNFTCount, 
            block.timestamp, 
            20 minutes,
            paidCoinAddress,
            rewardPercentage * amount / 100
        );
    }

    /**
     * @dev airdrop the coins from private Coins supply, with USDC/USDT/BUSD coin
     * @param amount USDC coins to be transferred
     * @param splitNFTCount nft count
     * @param coinType type of coin: USDC, USDT, BUSD
    */

    function airdrop(address to, uint256 amount, uint256 splitNFTCount, Coin coinType) external onlyOwner {
        require(privateSalesEnabled, "PrivateSales: sale is not enabled");
        require(splitNFTCount <= getMaxSplitCount(amount), "PrivateSales: split count exceed it's limit");
        require(amount >= priceLimit, "PrivateSales: amount should be greater than price limit ");

        address paidCoinAddress;
        if (coinType == Coin.USDC) {
            paidCoinAddress = address(USDC);
        }
        else if (coinType == Coin.USDT) {
            paidCoinAddress = address(USDT);
        }
        else {
            paidCoinAddress = address(BUSD);
        }

        uint256 seasideCoins = priceDecimal * amount / coinPriceUSD;
        seasideCoin.transfer(address(seasideNFT), seasideCoins);

        seasideNFT.mint(
            to, 
            seasideCoins, 
            splitNFTCount, 
            block.timestamp, 
            20 minutes,
            paidCoinAddress,
            rewardPercentage * amount / 100
        );
    }

    /**
     * @dev withdraw USDC from contract address
     * @param receiver the receiver of the USDC
     * @param coinAddress the coin address: USDC, USDT, BUSD
    */

    function withdraw(address receiver, address coinAddress) external onlyOwner {
        IERC20 coin = IERC20(coinAddress);
        coin.transfer(receiver, coin.balanceOf(address(this)));
    }

    /**
     * @dev withdraw Seaside Coins from contract address and transfers to SeasideCoin contract address
    */

    function withdrawSeasideCoins() external onlyOwner {
        seasideCoin.transfer(address(seasideCoin), seasideCoin.balanceOf(address(this)));
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface ISeasideNFT {

    /**
     * @dev minting the token on certain address
     * @param account the account of owner nft
     * @param nftCount the split nft token count
     * @param start start durataion of vesting
     * @param duration duration of vesting
     * @param tokenAddress address of paid token
     * @param rewardAmount amount of reward in paid token
    */

    function mint(
        address account, 
        uint256 amount, 
        uint256 nftCount, 
        uint256 start, 
        uint64 duration, 
        address tokenAddress, 
        uint256 rewardAmount
    ) external;

    /**
     * @dev gets the ownerOf certain tokenId
     * @param tokenId id of token
    */
    function ownerOf(uint256 tokenId) external view returns(address);

    /**
     * @dev updating nft coins amount regarding released money
     * @param tokenId id of nft token
    */

    function updateNFTCoins(uint256 tokenId) external;
    
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library Splitter {

    /**
     @dev calculates the max nft split count based on theashold amount and initialMaxCount
     @param threashold the theashold amount after nft split count increases
     @param initialMaxCount initial max split nft count
     @param amount amount of coin
    */

    function getMaxSplitCount(uint256 threashold, uint256 initialMaxCount, uint256 amount) internal pure returns (uint256) {
        if (amount < threashold) {
            return initialMaxCount;
        } 

        return initialMaxCount * (amount / threashold + 1);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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