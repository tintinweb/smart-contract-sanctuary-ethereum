/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: OpenZeppelin/[email protected]/Context

/*
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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: ImAsset

interface ImAsset is IERC20 {

    function decimals() external view returns (uint8);
    function getPriceFeedAddress() external view returns (address);
    function updatePriceFeedAddress(address newPriceFeedAddress) external;
    function DEX() external view returns (address);
    function updateDEX(address newDEX) external;
    function transfer(address _to, uint256 _value) external override returns (bool);
    function transferFrom(address from, address to, uint256 amount) external override returns (bool);
    function allowance(address owner, address spender) external view override returns (uint256);
    function approve(address spender, uint256 amount) external override returns (bool);
    function getLatestPrice() external view returns (int);
}

// Part: OpenZeppelin/[email protected]/Ownable

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// Part: ImUSD

interface ImUSD is ImAsset{
    function claim(address newInvestor) external;
}

// File: DEX.sol

contract DEX is Ownable {
        
    ImUSD public usd;
    ImAsset public TSLA;
    
    //when deploying pass in owner 1 and owner 2
    
    constructor() {}
    
    function buy(uint256 quantity, ImAsset asset) public virtual {
        uint256 amount = uint256(asset.getLatestPrice()) * quantity;
        require(usd.balanceOf(_msgSender())  >= amount, "mUSD: transfer amount exceeds balance");
        require(usd.allowance(_msgSender(), address(this)) >= amount, "mUSD: insufficient allowance");
        //token1, owner1, amount 1 -> owner2
        _safeTransferFrom(usd, _msgSender(), address(this), amount);
        //token2, owner2, amount 2 -> owner1
        _safeTransferFrom(asset, address(this), _msgSender(), quantity * 10 ** asset.decimals());
    }
    
    function sell(uint256 quantity, ImAsset asset) public virtual {
        uint256 amount = uint256(asset.getLatestPrice()) * quantity;
        uint256 formated_quantity = quantity * 10 ** asset.decimals();
        require(asset.balanceOf(_msgSender())  >= formated_quantity, "mAsset: quantity exceeds balance");
        require(asset.allowance(_msgSender(), address(this)) >= formated_quantity, "mUSD: insufficient allowance");
        //token1, owner1, amount 1 -> owner2.  needs to be in same order as function
        _safeTransferFrom(asset, _msgSender(), address(this), formated_quantity);
        //token2, owner2, amount 2 -> owner1.  needs to be in same order as function
        _safeTransferFrom(usd, address(this), _msgSender(), amount);
    }

    //*** Important ***
    //this contract needs an allowance to send tokens at token 1 and token 2 that is owned by owner 1 and owner 2
    
    function _swap(IERC20 token1, address owner1, uint256 amount1, 
                   IERC20 token2, address owner2, uint256 amount2) internal virtual {
        //TokenSwap
        //token1, owner1, amount 1 -> owner2.  needs to be in same order as function
        _safeTransferFrom(token1, owner1, owner2, amount1);
        //token2, owner2, amount 2 -> owner1.  needs to be in same order as function
        _safeTransferFrom(token2, owner2, owner1, amount2);
        
        
    }
    //This is a private function that the function above is going to call
    //the result of this transaction(bool) is assigned in a variable called sent
    //then we require the transfer to be successful
    function _safeTransferFrom(IERC20 token, address sender, address recipient, uint amount) internal {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "DEX: Token transfer failed");
    }
}