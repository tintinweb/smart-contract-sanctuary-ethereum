// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILGGNFT {
    function safeMintBlindBox(address to) external;
}

contract IdoNftNew is Ownable {

    bool public open;
    bool public done;
    bool public publicSell;
    mapping (address => bool) public whitelist;
    mapping (address => bool) public doneAddress;
    uint256 public sellcount = 388;
    uint256 public sales;
    uint256 public boxTokenPrices = 8 * 10 ** 16;
    ILGGNFT public token;
    address public beneficiary = address(0xB02ae6be01E1920798561C21eb26952Af7549e69);
    uint256 public whitelistCount = 200;
    uint256 public whitelistSales;

    constructor(ILGGNFT _token){
        token = _token;
    }

    function buyBox() external payable {
        uint256 _boxesLength = 1;
        require(publicSell, "No launch");
        require(!done, "Finish");
        require(_boxesLength > 0, "Boxes length must > 0");
        address sender = msg.sender;
        require(!doneAddress[sender], "Purchase only once");
        uint256 price = _boxesLength * boxTokenPrices;
        uint256 amount = msg.value;
        require(amount >= price, "Transfer amount error");
        doneAddress[sender] = true;
        
        for (uint256 i = 0; i < _boxesLength; i++) {
            require(sales < sellcount, "Sell out");
            sales += 1;
            if(sales >= sellcount){
                done = true;
            }
            token.safeMintBlindBox(sender);
        }
            
        payable(beneficiary).transfer(price);  
        emit Buy(sender, beneficiary, price);
    }

    function whitelistBuy() external payable {
        require(whitelistSales < whitelistCount, "Sell out...");
        require(open, "No launch");
        address sender = msg.sender;
        uint256 price = boxTokenPrices;
        uint256 amount = msg.value;
        require(amount >= price, "Transfer amount error");
        require(whitelist[sender], "Account is not already whitelist");
        whitelist[sender] = false;
        whitelistSales += 1;
        token.safeMintBlindBox(sender);
        payable(beneficiary).transfer(price);
    }

    function setWhitelist(address[] memory _accounts) public onlyOwner {
        for (uint i = 0; i < _accounts.length; i+=1) {
            whitelist[_accounts[i]] = true;
        }
    }
    function delWhitelist(address[] memory _accounts) public onlyOwner {
        for (uint i = 0; i < _accounts.length; i+=1) {
            whitelist[_accounts[i]] = false;
        }
    }

    function setSellcount(uint256 _count) public onlyOwner {
        sellcount = _count;
    }

    function setWhitelistCount(uint256 _whitelistCount) public onlyOwner {
        whitelistCount = _whitelistCount;
    }

    function setBoxTokenPrices(uint256 _boxTokenPrices) public onlyOwner {
        boxTokenPrices = _boxTokenPrices;
    }

    function setOpen(bool _open) public onlyOwner {
        open = _open;
    }

    function setDone(bool _done) public onlyOwner {
        done = _done;
    }

    function setPublicSell(bool _publicSell) public onlyOwner {
        publicSell = _publicSell;
    }

    function setToken(ILGGNFT _token) public onlyOwner {
        token = _token;
    }

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    receive() external payable {}
    fallback() external payable {}

    /* ========== EMERGENCY ========== */
    /*
        Users make mistake by transferring usdt/busd ... to contract address.
        This function allows contract owner to withdraw those tokens and send back to users.
    */
    function rescueStuckToken(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner(), amount);
    }

    function refund(address _addr, uint256 _amount) external onlyOwner {
        payable(_addr).transfer(_amount);
    }

    /* ========== EVENTS ========== */
    event Buy(address indexed user, address indexed beneficiary, uint256 amount);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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