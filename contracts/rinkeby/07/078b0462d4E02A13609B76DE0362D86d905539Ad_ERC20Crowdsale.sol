// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/TransferHelper.sol";

contract ERC20Crowdsale is Ownable {
    bool public isEnabled = false;

    // ERC20 Token address => price mapping
    mapping(address => uint256) public basePrice;

    uint256 public maxSupply;
    uint256 public totalSupply;

    address public WETH;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    address[] public distWallets;
    mapping(address => uint256) public distPercentile;

    /**
     * @dev Emitted when token is purchased by `buyer` with `token` for `price`.
     */
    event BuyWithERC20Token(
        address indexed buyer,
        address indexed token,
        uint256 totalPrice,
        uint256 indexed amount,
        uint256 orderId
    );

    /**
     * @dev Emitted when token is purchased by `buyer` with `ETH` for `price`.
     */
    event BuyWithETH(
        address indexed buyer,
        uint256 indexed totalPrice,
        uint256 indexed amount,
        uint256 orderId
    );

    /**
     * @dev Emitted when distribution wallet is added.
     */
    event AddDistributionWallet(
        address indexed wallet,
        uint256 indexed percentile
    );

    /**
     * @dev Emitted when distribution wallet is removed.
     */
    event RemoveDistributionWallet(
        address indexed wallet,
        uint256 indexed percentile
    );

    // have to provide WETH token address and price in
    constructor(address wethAddress, uint256 priceInEth) {
        WETH = wethAddress;
        basePrice[WETH] = priceInEth;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    function addERC20Token(address token, uint256 price) external onlyOwner {
        require(token != address(0), "zero address cannot be used");
        basePrice[token] = price;
    }

    function removeERC20Token(address token) external onlyOwner {
        delete basePrice[token];
    }

    /*
     * Pause sale if active, make active if paused
     */
    function setSaleStatus(bool status) public onlyOwner {
        isEnabled = status;
    }

    function addDistributionWallet(address payable wallet, uint256 percentile)
        external
        onlyOwner
    {
        require(wallet != address(0), "zero address cannot be used");
        require(distPercentile[wallet] == 0, "wallet had been already used.");

        require(
            totalDistPercentile() + percentile <= 100,
            "Total percentile of distribution should be less than 100"
        );
        distWallets.push(wallet);
        distPercentile[wallet] = percentile;

        emit AddDistributionWallet(wallet, percentile);
    }

    function removeDistributionWallet(address payable wallet)
        external
        onlyOwner
    {
        require(distPercentile[wallet] > 0, "wallet was not registered");

        for (uint256 i = 0; i < distWallets.length; i++) {
            if (distWallets[i] == wallet) {
                emit RemoveDistributionWallet(wallet, distPercentile[wallet]);
                delete distPercentile[wallet];
                _removeDistWallet(i);
                break;
            }
        }
    }

    function _removeDistWallet(uint256 index) private {
        // require(index < distWallets.length, "index out of bound");

        for (uint256 i = index; i < distWallets.length - 1; i++) {
            distWallets[i] = distWallets[i + 1];
        }
        distWallets.pop();
    }

    function setMaxSupply(uint256 supply) public onlyOwner {
        require(supply > 0, "amount should be greater than 0");
        maxSupply = supply;
        totalSupply = 0;
    }

    function buyWithERC20Token(
        address token,
        uint256 amount,
        uint256 totalPrice,
        uint256 orderId
    ) public {
        require(isEnabled, "Sale is disabled");
        require(amount > 0, "need to buy at least 1 token");
        require(basePrice[token] > 0, "Price in this token was not set");

        uint256 value = amount * basePrice[token];
        require(
            totalPrice >= value,
            "bid price should be greater than base price"
        );

        uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
        require(allowance >= totalPrice, "token allowance is not enough");

        TransferHelper.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            totalPrice
        );

        _balances[msg.sender] += amount;
        totalSupply += amount;
        emit BuyWithERC20Token(msg.sender, token, totalPrice, amount, orderId);
    }

    /**
     * Fallback function is called when msg.data is empty
     */
    receive() external payable {
        _buyWithETH(1, 1);
    }

    function buyWithEth(uint256 orderId, uint256 amount) public payable {
        _buyWithETH(orderId, amount);
    }

    function _buyWithETH(uint256 orderId, uint256 amount) private {
        require(amount > 0, "need to buy at least 1 token");
        require(isEnabled, "Sale is disabled");
        require(totalSupply < maxSupply, "Total Supply is already reached");
        require(msg.value >= basePrice[WETH] * amount, "Not enough ETH sent");

        _balances[msg.sender] += amount;
        totalSupply += amount;

        emit BuyWithETH(msg.sender, msg.value, amount, orderId);
    }

    function totalDistPercentile() public view returns (uint256) {
        uint256 totalPercentile = 0;
        for (uint256 i = 0; i < distWallets.length; i++) {
            totalPercentile += distPercentile[distWallets[i]];
        }

        return totalPercentile;
    }

    function _forwardToken(address token, uint256 amount) private {
        require(amount > 0, "amount should be greater than zero");
        require(
            IERC20(token).balanceOf(address(this)) >= amount,
            "token balance is not enough"
        );

        require(
            totalDistPercentile() == 100,
            "Total percentile of distribution should be 100"
        );

        for (uint256 i = 0; i < distWallets.length; i++) {
            uint256 value = (amount * distPercentile[distWallets[i]]) / 100;
            TransferHelper.safeTransfer(token, distWallets[i], value);
        }
    }

    function _forwardETH(uint256 amount) private {
        require(amount > 0, "balance should be greater than zero");
        require(address(this).balance >= amount, "ETH balance is not enough");

        require(
            totalDistPercentile() == 100,
            "Total percentile of distribution should be 100"
        );

        for (uint256 i = 0; i < distWallets.length; i++) {
            uint256 value = (amount * distPercentile[distWallets[i]]) / 100;
            TransferHelper.safeTransferETH(distWallets[i], value);
        }
    }

    function withdrawEth() external onlyOwner {
        _forwardETH(address(this).balance);
    }

    function withdrawERC20Token(address token) external onlyOwner {
        _forwardToken(token, IERC20(token).balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
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