/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

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

// Uniswap/v3-periphery/main/contracts/libraries/TransferHelper.sol

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol

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

pragma solidity ^0.8.0;

contract MANCoinCashier is Ownable {
    address public constant MANC = 0x1B8c425d56bCee85ecC6b38f4F03232f4D6Bbba0;

    mapping(address => uint256) private _bonusHistory;
    mapping(address => uint256) private _toCasinoAmount;
    mapping(address => uint256) private _casinoToWalletCredits;
    mapping(address => uint256) private _stakeToWalletCredits;
    mapping(address => uint256) private _stakeToCasinoCredits;

    uint256 public matchingBonus = 1000 ether;
    uint256 public toWalletProcessingFee = 0.005 ether;
    uint256 public toCasinoProcessingFee = 0.004 ether;
    uint256 public exchanged;
    uint256 public exchangeRate = 0.00001 ether;

    constructor() {}

    // public payable
    function swapToWallet() public payable returns (uint256) {
        return swapToWallet(msg.sender);
    }

    function swapToWallet(address user) public payable returns (uint256) {
        require(user != address(0), "user is the zero address");

        if (msg.sender != owner()) {
            require(msg.value > 0, "insufficient funds");
        }

        uint256 swapAmount = getSwapAmount(msg.value);
        uint256 bonusAmount = getBonusAmount(user, swapAmount);

        uint256 amountOut = swapAmount + bonusAmount;
        require(amountOut > 0, "nothing to transfer");

        if (bonusAmount > 0) {
            _bonusHistory[user] += bonusAmount;
        }

        exchanged += amountOut;

        // Transfer the specified amount of MANC to sender.
        TransferHelper.safeTransferFrom(MANC, owner(), user, amountOut);

        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "failed to send funds");

        return amountOut;
    }

    function swapToCasino() public payable returns (uint256) {
        return swapToCasino(msg.sender);
    }

    function swapToCasino(address user) public payable returns (uint256) {
        require(user != address(0), "user is the zero address");

        if (msg.sender != owner()) {
            require(msg.value > 0, "insufficient funds");
        }

        uint256 swapAmount = getSwapAmount(msg.value);
        uint256 bonusAmount = getBonusAmount(user, swapAmount);

        uint256 amountOut = swapAmount + bonusAmount;
        require(amountOut > 0, "nothing to transfer");

        if (bonusAmount > 0) {
            _bonusHistory[user] += bonusAmount;
        }

        exchanged += amountOut;

        // Save amount of MANC to be sent.
        _toCasinoAmount[user] += amountOut;

        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "failed to send funds");

        return amountOut;
    }

    function collectCasinoToWallet() public payable {
        collectCasinoToWallet(msg.sender);
    }

    function collectCasinoToWallet(address user) public payable {
        require(user != address(0), "user is the zero address");

        if (msg.sender != owner() && toWalletProcessingFee > 0) {
            require(msg.value >= toWalletProcessingFee, "insufficient funds");
        }

        _casinoToWalletCredits[user] += 1;

        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "failed to send processing fee");
    }

    function collectStakeToWallet() public payable {
        collectStakeToWallet(msg.sender);
    }

    function collectStakeToWallet(address user) public payable {
        require(user != address(0), "user is the zero address");

        if (msg.sender != owner() && toWalletProcessingFee > 0) {
            require(msg.value >= toWalletProcessingFee, "insufficient funds");
        }

        _stakeToWalletCredits[user] += 1;

        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "failed to send processing fee");
    }

    function collectStakeToCasino() public payable {
        collectStakeToCasino(msg.sender);
    }

    function collectStakeToCasino(address user) public payable {
        require(user != address(0), "user is the zero address");

        if (msg.sender != owner() && toCasinoProcessingFee > 0) {
            require(msg.value >= toCasinoProcessingFee, "insufficient funds");
        }

        _stakeToCasinoCredits[user] += 1;

        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "failed to send processing fee");
    }

    // public view
    function getSwapAmount(uint256 value) public view returns (uint256) {
        return (value / exchangeRate) * 10 ** 18;
    }

    function getBonusAmount(address user, uint256 amount) public view returns (uint256) {
        if (_bonusHistory[user] == 0) {
            return amount > matchingBonus ? matchingBonus : amount;
        }
        return 0;
    }

    function getBonusHistory(address user) public view returns (uint256) {
        return _bonusHistory[user];
    }

    function getToCasinoAmount(address user) public view returns (uint256) {
        return _toCasinoAmount[user];
    }

    function getCasinoToWalletCredits(address user) public view returns (uint256) {
        return _casinoToWalletCredits[user];
    }

    function getStakeToWalletCredits(address user) public view returns (uint256) {
        return _stakeToWalletCredits[user];
    }

    function getStakeToCasinoCredits(address user) public view returns (uint256) {
        return _stakeToCasinoCredits[user];
    }

    // onlyOwner
    function setExchangeRate(uint256 _newExchangeRate) public onlyOwner {
        exchangeRate = _newExchangeRate;
    }

    function setMatchingBonus(uint256 _newMatchingBonus) public onlyOwner {
        matchingBonus = _newMatchingBonus;
    }

    function setToWalletProcessingFee(uint256 _toWalletProcessingFee) public onlyOwner {
        toWalletProcessingFee = _toWalletProcessingFee;
    }

    function setToCasinoProcessingFee(uint256 _toCasinoProcessingFee) public onlyOwner {
        toCasinoProcessingFee = _toCasinoProcessingFee;
    }

    function doCollectCasinoToWallet(address user, uint256 amount) public onlyOwner {
        require(user != address(0), "user is the zero address");
        require(amount > 0, "insufficient MANC");
        require(getCasinoToWalletCredits(user) > 0, "insufficient to wallet credits");

        _casinoToWalletCredits[user] -= 1;

        // Transfer the specified amount of MANC to user.
        TransferHelper.safeTransferFrom(MANC, owner(), user, amount);
    }

    function doCollectStakeToWallet(address user, uint256 amount) public onlyOwner {
        require(user != address(0), "user is the zero address");
        require(amount > 0, "insufficient MANC");
        require(getStakeToWalletCredits(user) > 0, "insufficient stake to wallet credits");

        _stakeToWalletCredits[user] -= 1;

        // Transfer the specified amount of MANC to user.
        TransferHelper.safeTransferFrom(MANC, owner(), user, amount);
    }

    function doCollectStakeToCasino(address user) public onlyOwner {
        require(user != address(0), "user is the zero address");
        require(getStakeToCasinoCredits(user) > 0, "insufficient stake to casino credits");

        _stakeToCasinoCredits[user] -= 1;
    }

    function tokenWithdraw(IERC20 token) public onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        bool success = token.transfer(owner(), amount);
        require(success);
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}