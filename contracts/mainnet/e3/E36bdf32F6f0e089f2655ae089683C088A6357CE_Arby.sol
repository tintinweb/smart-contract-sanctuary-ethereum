// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Ownable.sol";

interface ERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function factory() external view returns (address);

    function swap(
        uint256 amount0,
        uint256 amount1,
        address sender,
        bytes calldata data
    ) external;
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

address constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

contract Arby is Ownable {
    event ValueReceived(address user, uint256 amount);
    event Withdrawal(address token, uint256 amount);
    event ConstructorDeposit(address token, uint256 amount);
    event PayloadData(Payload payload);

    struct Payload {
        address target;
        bytes data;
        uint256 value;
    }

    mapping(address => bool) public factoryAddresses;
    ERC20 weth;

    constructor() payable {
        factoryAddresses[0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f] = true;
        factoryAddresses[0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac] = true;

        weth = ERC20(WETH_ADDR);
        if (msg.value > 0) {
            emit ConstructorDeposit(msg.sender, msg.value);
            weth.deposit{value: msg.value}();
        }
    }

    function drainERC20Account(address tokenAddress) public onlyOwner {
        if (IERC20(tokenAddress).balanceOf(address(this)) > 1) {
            emit Withdrawal(
                tokenAddress,
                IERC20(tokenAddress).balanceOf(address(this)) - 1
            );

            IERC20(tokenAddress).transfer(
                owner(),
                IERC20(tokenAddress).balanceOf(address(this)) - 1
            );
        }
    }

    function withdrawETH(uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance);
        payable(msg.sender).transfer(_amount);
        emit Withdrawal(msg.sender, _amount);
    }

    function setFactoryFlag(address _factoryAddress, bool _flag)
        external
        onlyOwner
    {
        factoryAddresses[_factoryAddress] = _flag;
    }

    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }

    fallback() external {
        bytes4 func_selector = bytes4(msg.data[0:4]);
        bool executeAllPayloads = false;
        bool returnOnFirstFailure = false;

        if (
            func_selector ==
            bytes4(
                abi.encodeWithSignature(
                    "uniswapV2Call(address,uint256,uint256,bytes)"
                )
            )
        ) {
            address lp_factory = IUniswapV2Pair(msg.sender).factory();

            require(factoryAddresses[lp_factory] == true, "Unapproved factory");

            address token0_address = IUniswapV2Pair(msg.sender).token0();
            address token1_address = IUniswapV2Pair(msg.sender).token1();

            address lp_address = IUniswapV2Factory(lp_factory).getPair(
                token0_address,
                token1_address
            );

            require(msg.sender == lp_address, "Unauthorized LP");

            address sender;
            uint256 amount0Out = 0;
            uint256 amount1Out = 0;
            bytes memory payloadBytes;
            Payload[] memory payloads;

            (sender, amount0Out, amount1Out, payloadBytes) = abi.decode(
                msg.data[4:],
                (address, uint256, uint256, bytes)
            );

            require(sender == address(this), "Must me owner!");

            (payloads) = abi.decode(payloadBytes, (Payload[]));

            this._deliverPayloads(
                payloads,
                returnOnFirstFailure,
                executeAllPayloads
            );
        } else {
            revert();
        }
    }

    function _deliverPayloads(
        Payload[] memory _payloads,
        bool _returnOnFirstFailure,
        bool _executeAllPayloads
    ) external payable {
        if (_returnOnFirstFailure) {
            require(!_executeAllPayloads, "Conflicting revert options");
        }

        if (_executeAllPayloads) {
            require(!_returnOnFirstFailure, "Conflicting revert options");
        }

        uint256 totalValue = 0;

        for (uint256 i = 0; i < _payloads.length; i++) {
            totalValue += _payloads[i].value;
        }
        require(
            totalValue <= msg.value + address(this).balance,
            "Insufficient value"
        );

        if ((!_executeAllPayloads) && (!_returnOnFirstFailure)) {
            for (uint256 i = 0; i < _payloads.length; i++) {
                emit PayloadData(_payloads[i]);
                (bool success, bytes memory data) = _payloads[i].target.call(
                    _payloads[i].data
                );
            }
        } else if (_returnOnFirstFailure) {
            for (uint256 i = 0; i < _payloads.length; i++) {
                (bool success, bytes memory data) = _payloads[i].target.call(
                    _payloads[i].data
                );

                if (!success) break;
            }
        } else if (_executeAllPayloads) {
            for (uint256 i = 0; i < _payloads.length; i++) {
                (bool success, bytes memory data) = _payloads[i].target.call(
                    _payloads[i].data
                );
            }
        }
    }

    function _payBribe(uint256 _amount) internal {
        uint256 wethBalance;
        if (address(this).balance >= _amount) {
            (bool sent, bytes memory data) = (block.coinbase).call{
                value: _amount
            }("");
        } else {
            wethBalance = IERC20(WETH_ADDR).balanceOf(address(this));
            require(
                _amount <= address(this).balance + wethBalance,
                "Bribe exceeds balance"
            );

            weth.withdraw(_amount - address(this).balance);
            (bool sent, bytes memory data) = (block.coinbase).call{
                value: _amount
            }("");
        }
    }

    function executePackedPayload(
        address _target,
        bytes memory _payload,
        uint256 _bribeAmount
    ) external onlyOwner {
        _target.call(_payload);
        if (_bribeAmount > 0) {
            _payBribe(_bribeAmount);
        }
    }

    function executePayloads(
        Payload[] memory _payloads,
        uint256 _bribeAmount,
        bool _returnOnFirstFailure,
        bool _executeAllPayloads
    ) external onlyOwner {
        this._deliverPayloads(
            _payloads,
            _returnOnFirstFailure,
            _executeAllPayloads
        );

        if (_bribeAmount > 0) _payBribe(_bribeAmount);
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

import "Context.sol";

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