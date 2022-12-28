/**
 *Submitted for verification at Etherscan.io on 2022-12-27
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

// File: ido.sol




pragma solidity ^0.8.0;


interface IERC20 {
    function decimals() external view returns (uint8);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom( address from,address to, uint256 amount) external returns (bool);
}

contract ICO_launchpad is Ownable {

    uint private fee = 500;
    uint private division = 10000;
    uint private contractFee;

    struct ICO {
        address owner; //owner of ICO
        uint priceForToken; //price for 1 token
        uint bnb; //raised funds
        uint rest; //rest of token
    }

    mapping(address => ICO) private ico; //token address => ico struct

    function createICO(address token, uint price, uint amount) external {
        uint rest;
        if (ico[token].owner != address(0)) {
            require(msg.sender == ico[token].owner, "Not an owner of ICO");
            rest = ico[token].rest;
            _createICO(token, price, amount, rest);
        } else {
            _createICO(token, price, amount, rest);
        }
    }

    function _createICO(address token, uint price, uint amount, uint rest) internal {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (rest > 0) {
            ico[token].rest = amount + rest;
        } else {
            ico[token].owner = msg.sender;
            ico[token].rest = amount;
        }
        if (ico[token].priceForToken != price) {
            ico[token].priceForToken = price;
        }
    }


    function buyTokens(address token, uint amountToBuy) external payable {
        require(msg.value * 10 ** IERC20(token).decimals() >= amountToBuy * ico[token].priceForToken, "Incorrect payment amount");
        require(ico[token].rest >= amountToBuy, "amount exceeds rest of token");
        uint valueWithFee = msg.value - (msg.value * fee/division);
        ico[token].bnb += valueWithFee;
        ico[token].rest -= amountToBuy;
        contractFee += msg.value - valueWithFee;
        IERC20(token).transfer(msg.sender, amountToBuy);
    }

    //=====================================ICO owner's functions=====================================

    function addLiquidity(address token, uint amount) external {
        require(ico[token].owner == msg.sender, "Only ICO owner can add liquidity");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        ico[token].rest += amount;
    }

    function withdraw_BNB_by_ICO_owner(address token) external {
        require(ico[token].owner == msg.sender, "Only ICO owner can withdraw");
        uint amount = ico[token].bnb;
        ico[token].bnb = 0;
        payable(msg.sender).transfer(amount);
    }

    function changePrice(address token, uint _price) external {
        require(ico[token].owner == msg.sender, "Only ICO owner can change price");
        ico[token].priceForToken = _price;
    }

    function withdrawTokenFromICO(address token, uint amount) external {
        require(ico[token].owner == msg.sender, "Only ICO owner can change price");
        require(ico[token].rest >= amount, "amount exceeds rest of token");
        ico[token].rest -= amount;
        IERC20(token).transfer(msg.sender, amount);
    }

    //=====================================Veiw's functions=====================================

    function getEarnedFee() external view returns(uint) {
        return contractFee;
    }

    function getFee() external view returns(uint) {
        return fee;
    }

    function getPriceForToken(address token) external view returns(uint) {
        return ico[token].priceForToken;
    }

    function getRaisedFunds(address token) external view returns(uint) {
        return ico[token].bnb;
    }

    function getRest(address token) external view returns(uint) {
        return ico[token].rest;
    }

    //=====================================Admin's functions====================================

    function changeFee(uint _newFee) external onlyOwner {
        fee = _newFee;
    }

    function withdrawFee(address payable _to) external onlyOwner {
        _to.transfer(contractFee);
    }

}