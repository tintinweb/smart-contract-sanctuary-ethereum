/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/Grace_NFTs/GraceOptimizer.sol


pragma solidity ^0.8.9;



interface IGraceCars {
    function buyCarOnChain(string memory _carName, address _buyer, uint256 _price) external;
}

interface IGraceArts {
    function buyArtOnChain(string memory _artName, address _buyer, uint256 _price) external;
}

contract GraceOptimizer is Ownable {
    
    IGraceCars public graceCars;
    IGraceArts public graceArts;
    address public USDC_Token;
    address private balanceReceiver;
    
    event NewBalanceReceiver(address newReceiver);
    event NewOwner(address newOwner);
    event NewCarsAddress(address newAddress);
    event NewArtsAddress(address newAddress);

    constructor(address _graceCars, address _graceArts, address _usdcToken, address _balanceReceiver) {
        graceCars = IGraceCars(_graceCars);
        graceArts = IGraceArts(_graceArts);
        USDC_Token = _usdcToken;
        balanceReceiver = _balanceReceiver;
    }

    /**
    * @dev Allows a user to buy one or multiple cars and pieces of art, also receives extra USDCs for merchandising.
    * 
    * @param carNames An array of strings representing the names of the cars to be bought.
    * @param carPrices An array of uint256 representing the prices of the cars to be bought. 
    * The number of items in carNames and carPrices must be the same.
    * @param artNames An array of strings representing the names of the pieces of art to be bought.
    * @param artPrices An array of uint256 representing the prices of the pieces of art to be bought. 
    * The number of items in artNames and artPrices must be the same.
    * @param merchPrice The total price of any additional items in the purchase.
    * 
    * The total number of cars and pieces of art to be bought must be less than or equal to 10.
    * The user must have enough USDC tokens approved for transfer.
    * 
    * The function will transfer USDC tokens from the user to the balanceReceiver address.
    */
    function buy(string[] memory carNames, uint256[] memory carPrices, string[] memory artNames, uint256[] memory artPrices, uint256 merchPrice) public {
        require(carNames.length == carPrices.length, "Car names and prices must be equal amount");
        require(artNames.length == artPrices.length, "Art names and prices must be equal amount");
        require(carPrices.length <= 10 && artPrices.length <= 10, "You can buy up to 10 items at a time");
        uint256 carsAmount = carNames.length;
        uint256 artsAmount = artNames.length;
        uint256 amount;
        if(carsAmount > 0) {
            for(uint i=0;i<carsAmount;i++){
                graceCars.buyCarOnChain(carNames[i], msg.sender, carPrices[i]);
                amount += carPrices[i];
            }
        }
        if(artsAmount > 0) {
            for(uint i=0;i<artsAmount;i++){
                graceArts.buyArtOnChain(artNames[i], msg.sender, artPrices[i]);
                amount += artPrices[i];
            }   
        }
        if(merchPrice > 0) {
            amount += merchPrice;
        }
        IERC20(USDC_Token).transferFrom(msg.sender, balanceReceiver, amount);
    }

    function setReceiver(address _newReceiver) public onlyOwner {
        balanceReceiver = _newReceiver;
        emit NewBalanceReceiver(_newReceiver);
    }

    function setCarsAddress(address _newAddress) public onlyOwner {
        graceCars = IGraceCars(_newAddress);
        emit NewCarsAddress(_newAddress);
    }

    function setArtsAddress(address _newAddress) public onlyOwner {
        graceArts = IGraceArts(_newAddress);
        emit NewArtsAddress(_newAddress);
    }
}