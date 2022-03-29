/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract KiwiToken {
    function lockToken(address user, uint256 amount, uint256 unlockTime) external virtual;
}

contract KIWI is Ownable {
    address public tokenAddress = 0x42C9A3e29a0382b17F290966f402D38725771D2d;
	address public baseToken = 0x42C9A3e29a0382b17F290966f402D38725771D2d;
	
	struct User {
	   uint256 investment;
	   uint256 token;
    }
	mapping (address => User) public users;
	
    uint256 public SalePrice = 120;
	uint256 public BuyPrice  = 120;
	uint256 public baseRate  = 1 * 10**6;
	uint256 public unlockTimeStamp = block.timestamp;
	
    bool public buyEnable = false;
	bool public saleEnable = false;
	bool public buyTokenLocked = true;
	
	KiwiToken public immutable KTOKEN = KiwiToken(tokenAddress);
	
    event TokensBuy(address indexed buyer, uint256 amount);
	event TokensSell(address indexed seller, uint256 amount);
    
    function buy(uint256 amount) external returns (bool) {
	    address buyer = msg.sender;
		uint256 spendToken = (amount/BuyPrice)*(baseRate);
        require(
		   buyEnable,
		   'Buy is not started yet'
		);
        require(
           IBEP20(tokenAddress).balanceOf(owner()) >= amount,
           "Owner does not have sufficient token balance"
        );
		
		IBEP20(baseToken).transferFrom(buyer, owner(), spendToken);
		IBEP20(tokenAddress).transferFrom(owner(), buyer, amount);
		
		users[buyer].investment += spendToken;
		users[buyer].token += amount;
		
		if(buyTokenLocked)
		{
		   KTOKEN.lockToken(buyer, amount, unlockTimeStamp);
		}
		
        emit TokensBuy(buyer, amount);
        return true;
    }
	
	function sell(uint256 amount) external returns (bool) {
	    address seller = msg.sender;
		uint256 getToken = (amount*SalePrice)/(baseRate);
        require(
		   saleEnable,
		   'Sale is not started yet'
		);
        require(
           IBEP20(baseToken).balanceOf(owner()) >= amount,
           "Owner does not have sufficient token balance"
        );
		
		IBEP20(baseToken).transferFrom(owner(), seller, getToken);
		IBEP20(tokenAddress).transferFrom(seller, owner(), amount);
		
        emit TokensSell(seller, amount);
        return true;
    }
	
    function setSaleStatus(bool status) public onlyOwner {
	   require(saleEnable != status);
       saleEnable = status;
    }
	
	function setBuyStatus(bool status) public onlyOwner {
	   require(buyEnable != status);
       buyEnable = status;
    }
	
	function setBuyTokenLockedStatus(bool status) public onlyOwner {
	   require(buyTokenLocked != status);
       buyTokenLocked = status;
    }
	
	function setUnlockTimeStamp(uint256 newTime) external onlyOwner{
        unlockTimeStamp = newTime;
    }
	
	function setSalePrice(uint256 newPrice) external onlyOwner{
        SalePrice = newPrice;
    }
	
	function setBuyPrice(uint256 newPrice) external onlyOwner{
        BuyPrice = newPrice;
    }
	
	function setBaseRate(uint256 newRate) external onlyOwner{
        baseRate = newRate;
    }
	
    function setTokenAddress(address newAddress) external onlyOwner{
        tokenAddress = newAddress;
    }
	
	function setBaseToken(address newToken) external onlyOwner{
        baseToken = newToken;
    }
	
    function withdrawToken(address token) external onlyOwner {
       require( IBEP20(token).balanceOf(address(this)) > 0, "Insufficient token balance");
       IBEP20(token).transfer(msg.sender, IBEP20(token).balanceOf(address(this)));
    }
	
	function migrateBNB(address payable recipient) public onlyOwner {
        recipient.transfer(address(this).balance);
    }
}