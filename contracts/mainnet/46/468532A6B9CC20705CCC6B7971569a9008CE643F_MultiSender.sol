pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MultiSender is Ownable {
    mapping(address => bool) public allowList;

    modifier onlyAllowList() {
        require(allowList[msg.sender], "You do not have execute permission");
        _;
    }

    constructor () {
    }

    receive() external payable {}

    function addAllowList(address[] calldata _account) external onlyOwner {
        for (uint256 i = 0; i < _account.length; i++) {
            allowList[_account[i]] = true;
        }
    }

    function _withdrawERC20(address _token) private {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        TransferHelper.safeTransfer(_token, msg.sender, balance);
    }

    function _withdrawETH() private {
        payable(msg.sender).transfer(address(this).balance);
    }

    function MultiSendETH(address[] calldata _account, uint256 _quantity) external payable onlyAllowList {
        require(_quantity != 0 && _account.length != 0, 'err1');
        require(address(this).balance >= _quantity * _account.length, 'err2');

        for (uint256 i = 0; i < _account.length; i++) {
            payable(_account[i]).transfer(_quantity);
        }
        if (address(this).balance != 0) {
            _withdrawETH();
        }
    }

    function BulkSendETH(address[] calldata _account, uint256[] calldata _quantity) external payable onlyAllowList {
        require(address(this).balance != 0 && _quantity.length != 0 && _account.length != 0, 'err1');
        require(_quantity.length == _account.length, 'err2');

        for (uint256 i = 0; i < _account.length; i++) {
            payable(_account[i]).transfer(_quantity[i]);
        }
        if (address(this).balance != 0) {
            _withdrawETH();
        }
    }
    
    function MultiSendToken(address[] calldata _account, uint256 _quantity, address _tokenAddress) external onlyAllowList {
        require(IERC20(_tokenAddress).balanceOf(msg.sender) != 0 && _quantity != 0 && _account.length != 0, 'err1');

        TransferHelper.safeTransferFrom(_tokenAddress, msg.sender, address(this), _quantity * _account.length);
        for (uint256 i = 0; i < _account.length; i++) {
            TransferHelper.safeTransfer(_tokenAddress, _account[i], _quantity);
        }
        if (IERC20(_tokenAddress).balanceOf(address(this)) != 0) {
            _withdrawERC20(_tokenAddress);
        }
    }

    function BulkSendToken(address[] calldata _account, uint256[] calldata _quantity, address _tokenAddress) external onlyAllowList {
        require(IERC20(_tokenAddress).balanceOf(msg.sender) != 0 && _quantity.length != 0 && _account.length != 0, 'err1');
        require(_quantity.length == _account.length, 'err2');

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _quantity.length; i++) {
            totalAmount += _quantity[i];
        }

        TransferHelper.safeTransferFrom(_tokenAddress, msg.sender, address(this), totalAmount);
        for (uint256 i = 0; i < _account.length; i++) {
            TransferHelper.safeTransfer(_tokenAddress, _account[i], _quantity[i]);
        }
        if (IERC20(_tokenAddress).balanceOf(address(this)) != 0) {
            _withdrawERC20(_tokenAddress);
        }
    }
    

}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
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