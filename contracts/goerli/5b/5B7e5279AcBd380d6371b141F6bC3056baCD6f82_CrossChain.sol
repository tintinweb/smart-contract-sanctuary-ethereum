// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./UniswapInterface.sol";
import "./SafeMath.sol";

/**
 ________      ___    ___ ________   ________  _____ ______   ___  ________     
|\   ___ \    |\  \  /  /|\   ___  \|\   __  \|\   _ \  _   \|\  \|\   ____\    
\ \  \_|\ \   \ \  \/  / | \  \\ \  \ \  \|\  \ \  \\\__\ \  \ \  \ \  \___|    
 \ \  \ \\ \   \ \    / / \ \  \\ \  \ \   __  \ \  \\|__| \  \ \  \ \  \       
  \ \  \_\\ \   \/  /  /   \ \  \\ \  \ \  \ \  \ \  \    \ \  \ \  \ \  \____  
   \ \_______\__/  / /      \ \__\\ \__\ \__\ \__\ \__\    \ \__\ \__\ \_______\
    \|_______|\___/ /        \|__| \|__|\|__|\|__|\|__|     \|__|\|__|\|_______|
             \|___|/                                                            
 */

contract CrossChain is Ownable {
    // variables and mappings
    using SafeMath for uint256;
    uint256 constant divider = 10000;
    uint256 constant swapTimeout = 900;
    uint256 public fee;
    address public router; // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    address public WETH;
    mapping(address => bool) public zeroFee;

    // structs and events
    event SwapForToken(
        address receiver,
        address tokenTo,
        uint256 amount,
        uint256 chainId
    );

    constructor(
        // address _cbridgeAddress,
        uint256 _fee,
        address _router,
        address _weth
    ) {
        // cbridgeAddress = _cbridgeAddress;
        router = _router;
        fee = _fee;
        WETH = _weth;
    }

    function updateFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function setFreeFee(address _target, bool _isFreeFee) public onlyOwner {
        zeroFee[_target] = _isFreeFee;
    }

    function swap(
        address _receiver,
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn,
        uint256 _percentSlippage,
        uint64 _dstChainId // uint64 _nonce, // uint32 _maxSlippage
    ) external payable {
        if (_dstChainId == 97) {
            swapSameChain(
                _receiver,
                _tokenFrom,
                _tokenTo,
                _amountIn,
                _percentSlippage
            );
            return;
        }

        uint256 amountOut = 0;
        uint256 remainingAmount = _amountIn;
        if (msg.value > 0) {
            require(msg.value == _amountIn, "Invalid input");
            if (!zeroFee[msg.sender] && fee > 0) {
                uint256 totalFee = (fee * _amountIn) / divider;
                remainingAmount = remainingAmount.sub(totalFee);
            }
            if (_tokenFrom == _tokenTo) {
                emit SwapForToken(
                    _receiver,
                    _tokenTo,
                    remainingAmount,
                    _dstChainId
                );
                return;
            }
            appove(router, _tokenFrom, remainingAmount);
            address[] memory path;
            path = new address[](2);
            path[0] = WETH;
            path[1] = _tokenTo;
            uint256[] memory amt = IUniswapV2Router(router).getAmountsOut(
                remainingAmount,
                path
            );
            require(amt[amt.length - 1] > 0, "Invalid param");
            uint256 amountOutMin = (amt[amt.length - 1] *
                (100 - _percentSlippage)) / 100;

            uint256[] memory amounts = IUniswapV2Router(router)
                .swapExactETHForTokens{value: remainingAmount}(
                amountOutMin,
                path,
                address(this),
                block.timestamp + swapTimeout
            );
            amountOut = amounts[amounts.length - 1];
        } else {
            bool result = IERC20(_tokenFrom).transferFrom(
                msg.sender,
                address(this),
                _amountIn
            );
            require(result, "[DYNA]: Token transfer fail");
            if (!zeroFee[msg.sender] && fee > 0 && _dstChainId != 97) {
                uint256 totalFee = (fee * _amountIn) / divider;
                remainingAmount = remainingAmount.sub(totalFee);
            }
            if (_tokenFrom == _tokenTo) {
                emit SwapForToken(
                    _receiver,
                    _tokenTo,
                    remainingAmount,
                    _dstChainId
                );
                return;
            }
            appove(router, _tokenFrom, remainingAmount);
            if (_tokenFrom != _tokenTo) {
                address[] memory path;
                if (_tokenFrom == WETH || _tokenTo == WETH) {
                    path = new address[](2);
                    path[0] = _tokenFrom;
                    path[1] = _tokenTo;
                } else {
                    path = new address[](3);
                    path[0] = _tokenFrom;
                    path[1] = WETH;
                    path[2] = _tokenTo;
                }

                uint256[] memory amt = IUniswapV2Router(router).getAmountsOut(
                    remainingAmount,
                    path
                );
                require(amt[amt.length - 1] > 0, "Invalid param");
                uint256 amountOutMin = (amt[amt.length - 1] *
                    (100 - _percentSlippage)) / 100;

                uint256[] memory amounts = IUniswapV2Router(router)
                    .swapExactTokensForTokens(
                        remainingAmount,
                        amountOutMin,
                        path,
                        address(this),
                        block.timestamp + swapTimeout
                    );
                amountOut = amounts[amounts.length - 1];
            }
        }

        emit SwapForToken(_receiver, _tokenTo, amountOut, _dstChainId);
    }

    function swapSameChain(
        address _receiver,
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountIn,
        uint256 _percentSlippage
    ) internal {
        if (msg.value > 0) {
            address[] memory path;
            path = new address[](2);
            path[0] = WETH;
            path[1] = _tokenTo;
            uint256[] memory amt = IUniswapV2Router(router).getAmountsOut(
                _amountIn,
                path
            );

            require(amt[amt.length - 1] > 0, "Invalid param");
            uint256 amountOutMin = (amt[amt.length - 1] *
                (100 - _percentSlippage)) / 100;

            IUniswapV2Router(router).swapExactETHForTokens{value: msg.value}(
                amountOutMin,
                path,
                _receiver,
                block.timestamp + swapTimeout
            );
            return;
        } else {
            bool result = IERC20(_tokenFrom).transferFrom(
                msg.sender,
                address(this),
                _amountIn
            );
            require(result, "[DYNA]: Token transfer fail");
            appove(router, _tokenFrom, _amountIn);
            address[] memory path;
            if (_tokenFrom == WETH || _tokenTo == WETH) {
                path = new address[](2);
                path[0] = _tokenFrom;
                path[1] = _tokenTo;
            } else {
                path = new address[](3);
                path[0] = _tokenFrom;
                path[1] = WETH;
                path[2] = _tokenTo;
            }

            uint256[] memory amt = IUniswapV2Router(router).getAmountsOut(
                _amountIn,
                path
            );
            require(amt[amt.length - 1] > 0, "Invalid param");
            uint256 amountOutMin = (amt[amt.length - 1] *
                (100 - _percentSlippage)) / 100;
            IUniswapV2Router(router).swapExactTokensForTokens(
                _amountIn,
                amountOutMin,
                path,
                _receiver,
                block.timestamp + swapTimeout
            );
        }
    }

    function appove(
        address spener,
        address token,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), spener) < amount) {
            IERC20(token).approve(spener, amount);
        }
    }

    function withdraw(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(_msgSender(), _amount);
    }

    function withdrawETH(uint256 _amount) public payable onlyOwner {
        (bool success, ) = _msgSender().call{value: _amount}("");
        require(success, "Transfer ETH failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
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