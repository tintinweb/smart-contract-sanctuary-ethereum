// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISplit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Split is Ownable, ISplit {
    address public override walletA;
    uint16 public override portionA;

    address public override walletB;
    uint16 public override portionB;

    address[] public override tokens;

    struct Withdrawals {
        uint256 walletAWithdrawals;
        uint256 walletBWithdrawals;
        uint256 totalWithdrawals;
    }

    mapping(address => Withdrawals) public override tokenWithdrawals;

    Withdrawals public override baseWithdrawals;

    constructor(
        address _walletA,
        uint16 _portionA,
        address _walletB,
        uint16 _portionB
    ) {
        require(
            _walletA != address(0) && _walletB != address(0),
            "Invalid wallets"
        );

        require(_portionA + _portionB == 10000, "Invalid portion");

        walletA = _walletA;
        portionA = _portionA;

        walletB = _walletB;
        portionB = _portionB;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function updateTokens(address[] memory _newTokens)
        external
        override
        onlyOwner
    {
        tokens = _newTokens;
        emit TokensUpdated(_newTokens);
    }

    function updateWallets(address _newWalletA, address _newWalletB)
        external
        override
        onlyOwner
    {
        require(
            _newWalletA != address(0) && _newWalletB != address(0),
            "Invalid wallets"
        );
        walletA = _newWalletA;
        walletB = _newWalletB;

        emit WalletsUpdated(_newWalletA, _newWalletB);
    }

    function updatePortions(uint16 _newPortionA, uint16 _newPortionB)
        external
        override
        onlyOwner
    {
        require(_newPortionA + _newPortionB == 10000, "Invalid portion");

        _autoWithdrawCoinBalance();
        _autoWithdrawTokenBalance();
        portionA = _newPortionA;
        portionB = _newPortionB;

        emit PortionsUpdated(_newPortionA, _newPortionB);
    }

    function withdrawTokenBalance(address _token) external override {
        require(msg.sender == walletA || msg.sender == walletB);

        Withdrawals memory _tokenWithdrawals = tokenWithdrawals[_token];

        IERC20 token = IERC20(_token);

        uint256 totalBalances = token.balanceOf(address(this)) +
            _tokenWithdrawals.totalWithdrawals;

        if (msg.sender == walletA) {
            uint256 walletAToWithdraw = ((totalBalances * portionA) / 10000) -
                _tokenWithdrawals.walletAWithdrawals;

            if (walletAToWithdraw > 0) {
                tokenWithdrawals[_token].totalWithdrawals += walletAToWithdraw;
                tokenWithdrawals[_token]
                    .walletAWithdrawals += walletAToWithdraw;

                bool success = token.transfer(walletA, walletAToWithdraw);
                require(success, "unsuccessfull transfer to wallet A");

                emit TokenWithdraw(_token, walletA, walletAToWithdraw);
            }
        } else {
            uint256 walletBToWithdraw = ((totalBalances * portionB) / 10000) -
                _tokenWithdrawals.walletBWithdrawals;

            if (walletBToWithdraw > 0) {
                tokenWithdrawals[_token].totalWithdrawals += walletBToWithdraw;
                tokenWithdrawals[_token]
                    .walletBWithdrawals += walletBToWithdraw;

                bool success = token.transfer(walletB, walletBToWithdraw);
                require(success, "unsuccessfull transfer to wallet B");

                emit TokenWithdraw(_token, walletB, walletBToWithdraw);
            }
        }
    }

    function withdrawCoinBalance() external override {
        require(msg.sender == walletA || msg.sender == walletB);

        uint256 totalBalances = address(this).balance +
            baseWithdrawals.totalWithdrawals;

        if (msg.sender == walletA) {
            uint256 walletAToWithdraw = ((totalBalances * portionA) / 10000) -
                baseWithdrawals.walletAWithdrawals;

            if (walletAToWithdraw > 0) {
                baseWithdrawals.totalWithdrawals += walletAToWithdraw;
                baseWithdrawals.walletAWithdrawals += walletAToWithdraw;

                payable(walletA).transfer(walletAToWithdraw);

                emit CoinWithdraw(walletA, walletAToWithdraw);
            }
        } else {
            uint256 walletBToWithdraw = ((totalBalances * portionB) / 10000) -
                baseWithdrawals.walletBWithdrawals;

            if (walletBToWithdraw > 0) {
                baseWithdrawals.totalWithdrawals += walletBToWithdraw;
                baseWithdrawals.walletBWithdrawals += walletBToWithdraw;
                payable(walletB).transfer(walletBToWithdraw);
                emit CoinWithdraw(walletB, walletBToWithdraw);
            }
        }
    }

    function _autoWithdrawCoinBalance() private {
        uint256 totalBalances = address(this).balance +
            baseWithdrawals.totalWithdrawals;

        uint256 walletAToWithdraw = ((totalBalances * portionA) / 10000) -
            baseWithdrawals.walletAWithdrawals;

        uint256 walletBToWithdraw = ((totalBalances * portionB) / 10000) -
            baseWithdrawals.walletBWithdrawals;

        delete baseWithdrawals;

        if (walletAToWithdraw > 0) {
            payable(walletA).transfer(walletAToWithdraw);

            emit CoinWithdraw(walletA, walletAToWithdraw);
        }

        if (walletBToWithdraw > 0) {
            payable(walletB).transfer(walletBToWithdraw);
            emit CoinWithdraw(walletB, walletBToWithdraw);
        }
    }

    function _autoWithdrawTokenBalance() private {
        for (uint256 i = 0; i < tokens.length; i++) {
            Withdrawals memory _tokenWithdrawals = tokenWithdrawals[tokens[i]];

            delete tokenWithdrawals[tokens[i]];

            IERC20 token = IERC20(tokens[i]);

            uint256 totalBalances = token.balanceOf(address(this)) +
                _tokenWithdrawals.totalWithdrawals;

            uint256 walletAToWithdraw = ((totalBalances * portionA) / 10000) -
                _tokenWithdrawals.walletAWithdrawals;

            uint256 walletBToWithdraw = ((totalBalances * portionB) / 10000) -
                _tokenWithdrawals.walletBWithdrawals;

            if (walletAToWithdraw > 0) {
                bool success = token.transfer(walletA, walletAToWithdraw);
                require(success, "unsuccessfull transfer to wallet A");

                emit TokenWithdraw(address(token), walletA, walletAToWithdraw);
            }

            if (walletBToWithdraw > 0) {
                bool success = token.transfer(walletB, walletBToWithdraw);
                require(success, "unsuccessfull transfer to wallet B");

                emit TokenWithdraw(address(token), walletB, walletBToWithdraw);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface ISplit {
    event TokensUpdated(address[] tokens);
    event WalletsUpdated(address walletA, address walletB);
    event PortionsUpdated(uint16 portionA, uint16 portionB);
    event TokenWithdraw(address tokenAddress, address wallet, uint256 amount);

    event CoinWithdraw(address wallet, uint256 amount);

    event Received(address, uint256);

    function walletA() external view returns (address);

    function portionA() external view returns (uint16);

    function walletB() external view returns (address);

    function portionB() external view returns (uint16);

    function tokens(uint256 index) external view returns (address);

    function tokenWithdrawals(address _address)
        external
        view
        returns (
            uint256 walletAWithdrawals,
            uint256 walletBWithdrawals,
            uint256 totalWithdrawals
        );

    function baseWithdrawals()
        external
        view
        returns (
            uint256 walletAWithdrawals,
            uint256 walletBWithdrawals,
            uint256 totalWithdrawals
        );

    function updateTokens(address[] memory _newTokens) external;

    function updateWallets(address _newWalletA, address _newWalletB) external;

    function updatePortions(uint16 _newPortionA, uint16 _newPortionB) external;

    function withdrawTokenBalance(address _token) external;

    function withdrawCoinBalance() external;
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