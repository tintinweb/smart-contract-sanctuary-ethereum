// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IUTILITYTOKENERC20.sol"; 
import "../interfaces/IPRESALE.sol"; 

contract Presale is IPRESALE, Ownable {  

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////////////////////////////////////////

    address public s_utilityTokenAddress;

    uint256 private s_priceToken;
    uint256 private s_tokenAmountToSell;
    uint256 private s_tokenAmountSold;

    //////////////////////////////////////////////////////////////////////////////////////////////////
    // Public functions
    ////////////////////////////////////////////////////////////////////////////////////////////////// 

    // => View functions

    function priceOneToken() public view override returns(uint256) {
        return s_priceToken;
    }

    function priceAmountToken(uint256 p_amountTokenBuy) public view override returns(uint256) {
        uint256 amountBuy = p_amountTokenBuy * (s_priceToken / 10000000000000);
        return amountBuy / (1 ether / 10000000000000);
    }

    function tokenAmountToSell() public view override returns(uint256) {
        return s_tokenAmountToSell;
    }

    function tokenAmountSold() public view override returns(uint256) {
        return s_tokenAmountSold;
    }

    function tokenAmountToSellNow() public view override returns(uint256) {
        if (s_tokenAmountToSell == 0) { return 0; }
        
        return s_tokenAmountToSell - s_tokenAmountSold; 
    }

    function balanceTokenContract() public view override returns(uint256) { 
        return IERC20(s_utilityTokenAddress).balanceOf(address(this));
    }

    // => Set functions

    function setUtilityTokenAddress(address p_utilityTokenAddress) public onlyOwner override { 
        require(s_utilityTokenAddress == address(0), "Error Utility token address");

        s_utilityTokenAddress = p_utilityTokenAddress;
    }

    function buy(uint256 p_amountToken) public payable override {
        require(s_priceToken > 0, "Error price");

        uint256 amountBuy = p_amountToken * (s_priceToken / 10000000000000);
        amountBuy = amountBuy / (1 ether / 10000000000000);
        require(msg.value == amountBuy, "Error value ETH");

        require(s_tokenAmountSold + p_amountToken <= s_tokenAmountToSell, "Full sale");
        s_tokenAmountSold += p_amountToken;

        payable(owner()).transfer(msg.value);
        require(IERC20(s_utilityTokenAddress).transfer(msg.sender, p_amountToken), "Error transfer token");

        emit Sale(msg.sender, p_amountToken);
    }

    function sell(uint256 p_tokenAmount, uint256 p_price) public onlyOwner override {
        require(
            IUTILITYTOKENERC20(s_utilityTokenAddress).freeBalanceOf(address(this)) >= p_tokenAmount,
            "Insufficient balance"
        );
        require(p_price >= 10000000000000, "Insufficient price");

        s_tokenAmountToSell = p_tokenAmount;
        s_priceToken = p_price;

        delete s_tokenAmountSold;

        emit toSell(p_tokenAmount, p_price);
    }

    function deleteSell() public onlyOwner override { 
        delete s_tokenAmountToSell;
        delete s_priceToken;
        delete s_tokenAmountSold;
    }   

    function finalize() public onlyOwner override {
        uint256 balance = IUTILITYTOKENERC20(s_utilityTokenAddress).freeBalanceOf(address(this));

        if (balance > 0) {
            IERC20(s_utilityTokenAddress).transfer(msg.sender, balance);
        }

        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUTILITYTOKENERC20 {
    // EVENTS

    event FreeMint(address indexed e_owner, uint256 e_amount);
    
    // PUBLIC FUNCTIONS

        // View functions

        function costMint(uint128 p_amount) external view returns(uint256);
        function ethToTokens(uint256 p_amount) external view returns(uint256);
        function maxMint() external view returns(uint256);
        function freeBalanceOf(address p_from) external view returns(uint256);
        function monthlyUnlock(address p_owner) external view returns(uint256);
        function poolUniswapV3() external view returns(address);

        // Set functions

        function setAddressStocksNFTs(address p_addressStocksNFTs) external;
        function setAddressCardsNFTs(address p_addressCardsNFTs) external;
        function setAddressBuy(address p_buyAddress) external;
        function setPause(bool p_pause) external;
        function freeMint(address p_owner, uint256 p_amount) external;
        function mint() external payable;
        function burn(address p_address, uint256 p_amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPRESALE {
    // EVENTS

    event Sale(address indexed e_client, uint256 e_amount);
    event toSell(uint256 e_tokenAmount, uint256 e_price);
    
    // PUBLIC FUNCTIONS

        // View functions

        function priceOneToken() external view returns(uint256);
        function priceAmountToken(uint256 p_amountTokenBuy) external view returns(uint256);
        function tokenAmountToSell() external view returns(uint256);
        function tokenAmountSold() external view returns(uint256);
        function tokenAmountToSellNow() external view returns(uint256);
        function balanceTokenContract() external view returns(uint256);

        // Set functions

        function setUtilityTokenAddress(address p_utilityTokenAddress) external;
        function buy(uint256 p_amountToken) external payable;
        function sell(uint256 p_tokenAmount, uint256 p_price) external;
        function deleteSell() external;
        function finalize() external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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