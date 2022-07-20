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

// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Safe Relayer - A relayer for Safe multisig wallet
/// @author Uxío Fuentefría - <[email protected]>
/// @custom:experimental This is an experimental contract.
contract Relayer is Ownable {
    IERC20 public token;
    uint256 public maxPriorityFee;
    uint256 public relayerFee;
    bytes4 public method;

    /// @dev Init contract
    /// @param _token Token for paying refunds. Should be the wrapped version of the base currency (e.g. WETH for mainnet)
    /// @param _maxPriorityFee MaxPriorityFee clients will be paying, so relayer cannot be abused to drain user funds
    /// @param _relayerFee Relayer fee that will be added to the gasPrice when calculating refunds
    /// @param _method Method id that will be called on the Safe
    constructor(
        IERC20 _token,
        uint256 _maxPriorityFee,
        uint256 _relayerFee,
        bytes4 _method
    ) {
        require(address(_token) != address(0), "Token cannot be empty");

        require(_maxPriorityFee > 0, "MaxPriorityFee must be higher than 0");

        token = _token;
        maxPriorityFee = _maxPriorityFee;
        relayerFee = _relayerFee;
        method = _method;
        // Prevent issues with deterministic deployment
        // solhint-disable-next-line avoid-tx-origin
        transferOwnership(tx.origin);
    }

    /// @param _token New token for paying refunds
    function changeToken(IERC20 _token) public onlyOwner {
        token = _token;
    }

    /// @param _maxPriorityFee New MaxPriorityFee clients will be paying
    function changeMaxPriorityFee(uint256 _maxPriorityFee) public onlyOwner {
        maxPriorityFee = _maxPriorityFee;
    }

    /// @param _relayerFee New Relayer fee
    function changeRelayerFee(uint256 _relayerFee) public onlyOwner {
        relayerFee = _relayerFee;
    }

    /// @notice Recover tokens sent by mistake to this contract
    /// @dev Ether recovery is not implemented as contract is not payable
    /// @param withdrawToken token to recover
    /// @param target destination for the funds
    function recoverFunds(IERC20 withdrawToken, address target)
        public
        onlyOwner
    {
        withdrawToken.transfer(target, withdrawToken.balanceOf(address(this)));
    }

    /// @notice Relay a transaction and get refunded
    /// @dev It's responsability of the sender to check if the Safe has enough funds to pay
    /// @param target Safe to call
    /// @param functionData ABI encoded Safe `execTransaction` without the method selector
    /// @param target destination for the refund
    function relay(
        address target,
        bytes calldata functionData,
        address refundAccount
    ) external {
        // 9k are for the token transfers + 21k base + data (8 bytes method + 32 bytes address + data)
        // We will use 14 as the gas price per data byte, to avoid overcharging too much
        uint256 gas = gasleft();
        uint256 txMaxPriorityFee = tx.gasprice - block.basefee;
        require(
            txMaxPriorityFee <= maxPriorityFee,
            "maxPriorityFee is higher than expected"
        );

        uint256 additionalGas = 30000 + (40 + functionData.length) * 14;
        uint256 gasPrice = tx.gasprice + relayerFee;

        // The method id is appended by the contract to avoid that another method is called
        bytes memory data = abi.encodePacked(method, functionData);
        bool success;
        // Assembly reduced the costs by 400 gas
        // solhint-disable-next-line no-inline-assembly
        assembly {
            success := call(
                sub(gas(), 12000),
                target,
                0,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
        require(success, "Could not successfully call target");

        // It's responsability of the sender to check if the Safe has enough funds to pay
        address refundTarget = refundAccount == address(0)
            ? msg.sender
            : refundAccount;
        require(
            token.transferFrom(
                target,
                refundTarget,
                (gas - gasleft() + additionalGas) * gasPrice
            ),
            "Could not refund sender"
        );
    }
}