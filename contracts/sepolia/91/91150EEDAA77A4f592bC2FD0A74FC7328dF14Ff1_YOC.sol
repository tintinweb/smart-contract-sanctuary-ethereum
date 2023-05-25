// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// https://eips.ethereum.org/EIPS/eip-20

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
//
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(
        address tokenOwner
    ) external view returns (uint256 balance);

    function allowance(
        address tokenOwner,
        address spender
    ) external view returns (uint256 remaining);

    function transfer(
        address to,
        uint256 tokens
    ) external returns (bool success);

    function approve(
        address spender,
        uint256 tokens
    ) external returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract YOC is IERC20, SafeMath, Ownable {
    // name, symbol, decimals are a part of ERC20 standard, and are OPTIONAL
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;

    uint256 public constant MINT_INTERVAL = 1; // minting interval in seconds
    uint256 public constant MINT_AMOUNT_PER = 100;
    uint256 public lastMintTime;
    address public MasterChef;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event UpdateMasterChef(address masterChefAddress);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        lastMintTime = block.timestamp;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return balances[account];
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[_msgSender()][spender] += amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool success) {
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balances[msg.sender] = safeSub(balances[msg.sender], amount);
        balances[recipient] = safeAdd(balances[recipient], amount);

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool success) {
        // I, who allowed the Swap/Dex (msg.sender) to do transaction on my behalf, allow them to
        // deduct the amount
        allowances[sender][msg.sender] = safeSub(
            allowances[sender][msg.sender],
            amount
        );

        // Subtract amount from "sender" address
        balances[sender] = safeSub(balances[sender], amount);
        // Add amount to "to" address
        balances[recipient] = safeAdd(balances[recipient], amount);

        // Emit the event, it'll be visible in logs
        emit Transfer(sender, recipient, amount);

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            balances[account] += amount;
        }

        emit Transfer(address(0), account, amount);
    }

    function setMasterChef(
        address masterChefAddress
    ) external onlyOwner returns (bool success) {
        MasterChef = masterChefAddress;
        emit UpdateMasterChef(masterChefAddress);
        return true;
    }

    function mint() public returns (bool success) {
        uint256 timeElapsed = block.timestamp - lastMintTime;
        uint256 tokensToMint = (timeElapsed / MINT_INTERVAL) * MINT_AMOUNT_PER;
        if (tokensToMint > 0) {
            _mint(address(this), tokensToMint * 10 ** decimals);
            lastMintTime += (timeElapsed / MINT_INTERVAL) * MINT_INTERVAL;
        }
        return success;
    }

    function mintToMasterChef(
        address recipient,
        uint256 amount
    ) external returns (bool success) {
        require(
            MasterChef == msg.sender,
            "This fuction is able to call by the MasterChef"
        );

        mint();

        allowances[address(this)][msg.sender] = amount;

        transferFrom(address(this), recipient, amount);

        emit Transfer(address(this), recipient, amount);

        return true;
    }
}