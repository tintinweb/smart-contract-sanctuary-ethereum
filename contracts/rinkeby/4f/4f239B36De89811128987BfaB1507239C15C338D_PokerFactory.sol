// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PokerTable.sol";

contract PokerFactory is Ownable {

    PokerTable[] public tables;
    address PKX;

    constructor(address _PKX) {
        PKX = _PKX;
    }

    function createTable(string memory name, string memory image) external onlyOwner {
        PokerTable table = new PokerTable(msg.sender, name, image, PKX);
        tables.push(table);
    }

    function getTables() external view returns (PokerTable[] memory result) {
        result = tables;
    }

    function sendChips(address user) external onlyOwner {
        IERC20(PKX).transfer(user, 1000 * 10 ** 18);
        payable(user).transfer(0.1 ether);
    }

    receive() external payable {}
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
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PokerTable {
    IERC20 public PKX;
    address public owner;
    string public name;
    string public banner;

    mapping(address => uint256) public balances;
    bool[7] public seats;

    uint256 public minAmount = 50 * 10 ** 18;

    // struct RoundEvents {
    //     string name;
    //     address user;
    //     uint256 amount;
    //     uint pos;
    //     uint256 pot;
    // }

    struct UserData {
        address user;
        uint256 balance;
    }

    event PlayerJoin(address indexed, uint, uint256);
    event PlayerLeave(address indexed, uint);
    event PlayerAddChip(address indexed, uint256);
    event PlayerClaimChip(address indexed, uint256);
    // event RoundEnded(RoundEvents[]);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    constructor(address _owner, string memory _name, string memory _banner, address _PKX) {
        owner = _owner;
        name = _name;
        banner = _banner;
        PKX = IERC20(_PKX);
    }

    function setName(string memory _name) external onlyOwner {
        name = _name;
    }

    function setBanner(string memory _banner) external onlyOwner {
        banner = _banner;
    }    

    function changeMinAmount(uint256 amount) external onlyOwner {
        minAmount = amount;
    }

    function resetSitting() external onlyOwner {
        for (uint i = 0; i < 7; i ++) {
            seats[i] = false;
        }
    }

    function updateSitting(uint num, bool sitting) external onlyOwner {
        seats[num] = sitting;
    }

    function freeSeats() external view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < 7; i ++) {
            if (seats[i] == false) {
                count ++;
            }
        }
        return count;
    }

    function join(uint num, uint256 amount) external {
        address account = msg.sender;
        // require(!seats[num], "Not able to join");
        require(balances[account] + amount >= minAmount, "Deposit at least min amount");
        
        PKX.transferFrom(account, address(this), amount);
        balances[account] += amount;
        seats[num] = true;
        emit PlayerJoin(account, num, amount);
    }

    function leave(address account, uint num) external onlyOwner {
        PKX.transfer(account, balances[account]);
        balances[account] = 0;
        seats[num] = false;
        emit PlayerLeave(account, num);
    }

    function addChips(uint256 amount) external {
        address account = msg.sender;
        PKX.transferFrom(account, address(this), amount);
        balances[account] += amount;
        emit PlayerAddChip(account, amount);
    }

    function claimChips() external {
        address account = msg.sender;
        uint256 amount = balances[account];
        PKX.transfer(account, amount);
        balances[account] = 0;
        emit PlayerClaimChip(account, amount);
    }

    function endRound(UserData[] memory users) external onlyOwner {
        // emit RoundEnded(events);

        for (uint i = 0; i < users.length; i ++) {
            balances[users[i].user] = users[i].balance;
        }
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