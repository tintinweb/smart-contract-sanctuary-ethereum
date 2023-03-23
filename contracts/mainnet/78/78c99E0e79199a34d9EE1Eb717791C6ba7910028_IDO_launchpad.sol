/**
 *Submitted for verification at Etherscan.io on 2023-03-22
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

// SPDX-License-Identifier: MIT
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

// File: contracts/ido.sol




pragma solidity ^0.8.0;


interface IERC20 {
    function decimals() external view returns (uint8);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom( address from,address to, uint256 amount) external returns (bool);
}

contract IDO_launchpad is Ownable {


    uint private contractFee;

    struct IDO {
        address owner; //owner of IDO
        uint priceForToken; //price for 1 token
        uint bnb; //raised funds
        uint rest; //rest of token
    }

    mapping(address => IDO) private ido; //token address => ico struct

    function createIDO(address token, uint price, uint amount) external {
        uint rest;
        if (ido[token].owner != address(0)) {
            require(msg.sender == ido[token].owner, "Not an owner of ICO");
            rest = ido[token].rest;
            _createIDO(token, price, amount, rest);
        } else {
            _createIDO(token, price, amount, rest);
        }
    }

    function _createIDO(address token, uint price, uint amount, uint rest) internal {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        if (rest > 0) {
            ido[token].rest = amount + rest;
        } else {
            ido[token].owner = msg.sender;
            ido[token].rest = amount;
        }
        if (ido[token].priceForToken != price) {
            ido[token].priceForToken = price;
        }
    }


    function buyTokens(address token, uint amountToBuy) external payable {
        require(msg.value * 10 ** IERC20(token).decimals() >= amountToBuy * ido[token].priceForToken, "Incorrect payment amount");
        require(ido[token].rest >= amountToBuy, "amount exceeds rest of token");
        uint valueWithFee = msg.value - (msg.value * 1/100);
        ido[token].bnb += valueWithFee;
        ido[token].rest -= amountToBuy;
        contractFee += msg.value - valueWithFee;
        IERC20(token).transfer(msg.sender, amountToBuy);
    }

    //=====================================ICO owner's functions=====================================

    function addLiquidity(address token, uint amount) external {
        require(ido[token].owner == msg.sender, "Only IDO owner can add liquidity");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        ido[token].rest += amount;
    }

    function withdraw_BNB_by_ICO_owner(address token) external {
        require(ido[token].owner == msg.sender, "Only IDO owner can withdraw");
        uint amount = ido[token].bnb;
        ido[token].bnb = 0;
        payable(msg.sender).transfer(amount);
    }

    function changePrice(address token, uint _price) external {
        require(ido[token].owner == msg.sender, "Only IDO owner can change price");
        ido[token].priceForToken = _price;
    }

    function withdrawTokenFromIDO(address token, uint amount) external {
        require(ido[token].owner == msg.sender, "Only IDO owner can withdraw");
        require(ido[token].rest >= amount, "amount exceeds rest of token");
        ido[token].rest -= amount;
        IERC20(token).transfer(msg.sender, amount);
    }

    //=====================================Veiw's functions=====================================

    function getEarnedFee() external view returns(uint) {
        return contractFee;
    }

    function getPriceForToken(address token) external view returns(uint) {
        return ido[token].priceForToken;
    }

    function getRaisedFunds(address token) external view returns(uint) {
        return ido[token].bnb;
    }

    function getRest(address token) external view returns(uint) {
        return ido[token].rest;
    }

    //=====================================Admin's functions====================================

    function withdrawFee(address payable _to) external onlyOwner {
        _to.transfer(contractFee);
    }
    function returnBnb() external payable onlyOwner {
    require(msg.value > 0, "No bnb sent");
    payable(msg.sender).transfer(msg.value);
    }
}