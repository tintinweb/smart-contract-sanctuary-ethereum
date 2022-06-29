// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IToken.sol";

/// @title ETH-Pegged Token.
/// @notice ERC20 Token can be purchased with ETH.
contract Token is IToken, Ownable, ReentrancyGuard {
    /// STORAGE ///

    /// @notice Name of token.
    string public name;
    /// @notice Symbol of token.
    string public symbol;
    /// @notice Decimals of token.
    uint256 public decimals;
    /// @notice Purchase rate of token.
    uint256 public rate = 2;
    /// @notice Total supply of token.
    uint256 public totalSupply;
    /// @notice Balances of each holder.
    mapping(address => uint256) public balanceOf;
    /// @notice Allowances for each spender.
    mapping(address => mapping(address => uint256)) public allowance;

    /// EVENTS ///

    /// @notice Emitted when approve function is called.
    /// @param owner Owner address.
    /// @param spender Spender address.
    /// @param amount Approve amount of token.
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /// @notice Emitted when transfer token.
    /// @param from Sender address.
    /// @param to Receiver address.
    /// @param amount Transfer amount of token.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice Emitted when token is minted.
    /// @param to Minter address.
    /// @param amount Mint amount.
    /// @param totalSupply Total supply of token.
    event TokensMinted(
        address indexed to,
        uint256 amount,
        uint256 totalSupply
    );

    /// @notice Emitted when token is burned.
    /// @param from Burner address.
    /// @param amount Burn amount.
    /// @param totalSupply Total supply of token.
    event TokensBurned(
        address indexed from,
        uint256 amount,
        uint256 totalSupply
    );

    /// ERRORS ///

    error Token__NameIsEmpty();
    error Token__SymbolIsEmpty();
    error Token__AddressIsZeroAddress();
    error Token__AmountIsZero();
    error Token__AmountExceedBalance(
        address holder,
        uint256 balance,
        uint256 amount
    );
    error Token__AmountExceedAllowance(
        address owner,
        address spender,
        uint256 allowance,
        uint256 amount
    );

    /// @notice Initialize the contract.
    /// @param _name Name of token.
    /// @param _symbol Symbol of token.
    /// @param _decimals Decimals of token.
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _decimals
    ) {
        if (bytes(_name).length == 0) {
            revert Token__NameIsEmpty();
        }
        if (bytes(_symbol).length == 0) {
            revert Token__SymbolIsEmpty();
        }

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /// @notice Approve a user to spend tokens.
    /// @param spender Spender address.
    /// @param amount Amount of token to approve.
    function approve(address spender, uint256 amount)
        external
        override
        nonReentrant
        returns (bool)
    {
        if (spender == address(0)) {
            revert Token__AddressIsZeroAddress();
        }
        if (amount == 0) {
            revert Token__AmountIsZero();
        }
        if (amount > balanceOf[msg.sender]) {
            revert Token__AmountExceedBalance(
                msg.sender,
                balanceOf[msg.sender],
                amount
            );
        }

        allowance[msg.sender][spender] = amount;

        return true;
    }

    /// @notice Buy tokens with ether, mint and allocate new tokens to the purchaser.
    function buy() external payable override nonReentrant returns (bool) {
        if (msg.value == 0) {
            revert Token__AmountIsZero();
        }

        uint256 tokenAmount = (msg.value * rate * (10**decimals)) / 1e18;

        totalSupply += tokenAmount;
        balanceOf[msg.sender] += tokenAmount;

        emit TokensMinted(msg.sender, tokenAmount, totalSupply);
        emit Transfer(address(0), msg.sender, tokenAmount);

        return true;
    }

    /// @notice Transfer value to another address.
    /// @param to Receiver address.
    /// @param amount Amount of token to send.
    function transfer(address to, uint256 amount)
        external
        override
        nonReentrant
        returns (bool)
    {
        if (balanceOf[msg.sender] < amount) {
            revert Token__AmountExceedBalance(
                msg.sender,
                balanceOf[msg.sender],
                amount
            );
        }

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /// @notice Tranfer on behalf of a user, from one address to another.
    /// @param from Holder address.
    /// @param to Receiver address.
    /// @param amount Amount of token to transfer.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override nonReentrant returns (bool) {
        if (amount == 0) {
            revert Token__AmountIsZero();
        }
        if (balanceOf[from] < amount) {
            revert Token__AmountExceedBalance(from, balanceOf[from], amount);
        }
        if (allowance[from][msg.sender] < amount) {
            revert Token__AmountExceedAllowance(
                from,
                msg.sender,
                allowance[from][msg.sender],
                amount
            );
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount;

        allowance[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);

        return true;
    }

    /// @notice Withdraw the ETH held by this contract
    /// @param amount Amount of ETH to withdraw.
    function withdraw(uint256 amount)
        external
        override
        nonReentrant
        returns (bool)
    {
        if (amount == 0) {
            revert Token__AmountIsZero();
        }
        uint256 tokenAmount = amount * rate;
        if (balanceOf[msg.sender] < tokenAmount) {
            revert Token__AmountExceedBalance(
                msg.sender,
                balanceOf[msg.sender],
                tokenAmount
            );
        }

        (bool success, ) = msg.sender.call{ value: amount }("");
        if (!success) {
            return false;
        }

        totalSupply -= tokenAmount;
        balanceOf[msg.sender] -= tokenAmount;

        emit TokensBurned(msg.sender, tokenAmount, totalSupply);
        emit Transfer(msg.sender, address(0), tokenAmount);

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IToken {
    /// @notice Approve a user to spend tokens.
    /// @param spender Spender address.
    /// @param amount Amount of token to approve.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Buy tokens with ether, mint and allocate new tokens to the purchaser.
    function buy() external payable returns (bool);

    /// @notice Transfer value to another address.
    /// @param to Receiver address.
    /// @param amount Amount of token to send.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Tranfer on behalf of a user, from one address to another.
    /// @param from Holder address.
    /// @param to Receiver address.
    /// @param amount Amount of token to transfer.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /// @notice Withdraw the ETH held by this contract
    /// @param amount Amount of ETH to withdraw.
    function withdraw(uint256 amount) external returns (bool);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @dev Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @dev Returns the remaining number of tokens that `spender` will be
    ///      allowed to spend on behalf of `owner` through {transferFrom}.
    ///      This is zero by default.
    ///      This value changes when {approve} or {transferFrom} are called.
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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