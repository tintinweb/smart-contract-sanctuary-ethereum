// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

interface ILANDXNFT{
    function landArea(uint256 id) external view returns (uint256);

    function rent(uint256 id) external view returns (uint256);

    function crop(uint256 id) external view returns (string memory);
}

interface IXTOKENROUTER{
        function getXToken(string memory _name) external view returns(address);
        function getCToken(string memory _name) external view returns(address);
    } 

interface IGRAINPRICES {
	    function prices(string memory grain) external pure returns(uint256);
    }

interface ICrop {
        function crop() external pure returns(string memory);
    }

contract RentFoundation is 
    Context,
    Ownable
{
    IERC20 public usdc;

    ILANDXNFT public landXNFT; //address of landXNFT

    IGRAINPRICES public grainPrices;
    
    IXTOKENROUTER public xTokenRouter; // address of xTokenRouter

    event rentPaid(uint256 tokenID, uint256 amount);
    event initialRentPaid(uint256 tokenID, uint256 amount);

    struct deposit {
        uint256 timestamp;
        uint256 amount; // in kg
        int256 depositBalance; //in kg
    }

    mapping (uint256 => deposit) public deposits;

    mapping(uint256 => bool) public initialRentApplied;

    constructor(address _usdc)
    {
		usdc = IERC20(_usdc);
	}

    // deposit rent for token ID, in USDC
    function payRent(uint256 tokenID, uint256 amount) public {
        require(initialRentApplied[tokenID], "Initial rent was not applied");
        require(usdc.transferFrom(msg.sender, address(this), amount), "transfer failed");
        uint256 grainAmount = amount / grainPrices.prices(landXNFT.crop(tokenID));
        deposits[tokenID].amount += grainAmount;
        emit rentPaid(tokenID, grainAmount);
    }

    // prepay initial rent after sharding in kg
   function payInitialRent(uint256 tokenID, uint256 amount) external {
        string memory crop = ICrop(msg.sender).crop();
        require(!initialRentApplied[tokenID], "Initial Paymant already applied");
        require(xTokenRouter.getXToken(crop) == msg.sender, "not initial payer");
        deposits[tokenID].timestamp = block.timestamp;
        deposits[tokenID].amount = amount;
        initialRentApplied[tokenID] = true;
        emit initialRentPaid(tokenID, amount);
    }

    function getDepositBalance(uint256 tokenID) public view returns(int256) {
        uint256 elapsedSeconds = block.timestamp - deposits[tokenID].timestamp;
        uint256 delimeter = 365 * 1 days;
        uint256 rentPerSecond = landXNFT.rent(tokenID) * landXNFT.landArea(tokenID) / (10000 * delimeter);
        return int256(deposits[tokenID].amount) - int256(rentPerSecond * elapsedSeconds);
    }
    
    function sellCToken(address account, uint256 amount) public {
        string memory crop = ICrop(msg.sender).crop();
        require(xTokenRouter.getCToken(crop) == msg.sender, "no valid cToken");
        usdc.transfer(account, amount * grainPrices.prices(crop) / (10 ** 6));
    }

    function setXTokenRouter(address _router) public onlyOwner {
        xTokenRouter = IXTOKENROUTER(_router);
    }

    function setGrainPrices(address _grainPrices) public onlyOwner {
        grainPrices = IGRAINPRICES(_grainPrices);
    }
    
    // change the address of landxNFT.
    function changeLandXNFTAddress(address _newAddress) public onlyOwner {
        landXNFT = ILANDXNFT(_newAddress);
    }
    
    //owner can withdraw any token sent here. should be used with care
	function reclaimToken(IERC20 token, uint256 _amount) external onlyOwner {
		require(address(token) != address(0), "no 0 address");
		uint256 balance = token.balanceOf(address(this));
		require(_amount <= balance, "you can't withdraw more than you have");
		token.transfer(msg.sender, _amount);
	}

    //owner can withdraw any ETH sent here
	function withdraw() external onlyOwner {
		uint256 balance = address(this).balance;
		payable(msg.sender).transfer(balance);
	}
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}