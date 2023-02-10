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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./uni/interfaces/IDEXCallee.sol";
import "./uni/interfaces/IDEXPair.sol";
import "./uni/interfaces/IDEXFactory.sol";

contract CompoundLiquidationFlashSwap is IDEXCallee, Ownable {
    address wETHAddress;
    address cETHAddress;
    address uniFactory;
    mapping(address => bool) public whitelist;

    event CallResponse(bool indexed success, bytes indexed data);
    event ETHReceive(uint amount, address sender);

    constructor(address _uniFactory, address[] memory _whitelist, address _wETHAddress, address _cETHAddress) {
        uniFactory = _uniFactory;
        wETHAddress = _wETHAddress;
        cETHAddress = _cETHAddress;
        for (uint i = 0; i < _whitelist.length; i++) {
            whitelist[_whitelist[i]] = true;
        }
    }

    receive() external payable {
        emit ETHReceive(msg.value, msg.sender);
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, "flashSwap: locked");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function addWhitelist(address _whitelist) external onlyOwner {
        whitelist[_whitelist] = true;
    }

    function withdrawalEth(address payable _to, uint256 amount) external payable onlyOwner {
        _to.transfer(amount);
    }

    function withdrawalErc20(address token, address _to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(_to, amount);
    }

    function callUpdate(address callee, bytes memory data, uint256 _value) internal returns (bytes memory) {
        bool success;
        bytes memory returnData;
        if (_value != 0) {
            (success, returnData) = callee.call{ value: _value }(data);
        } else {
            (success, returnData) = callee.call(data);
        }
        emit CallResponse(success, returnData);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    function callView(address callee, bytes memory data) internal view returns (bytes memory) {
        bool success;
        bytes memory returnData;
        (success, returnData) = callee.staticcall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    // TODO need to handle the case when repayToken is not seize token
    function dexCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external lock {
        require(whitelist[sender], "flashSwap: invalid sender");
        require(amount0 > 0 || amount1 > 0, "flashSwap: invalid amount");
        address token0 = IDEXPair(msg.sender).token0();
        address token1 = IDEXPair(msg.sender).token1();

        uint256 repayAmountForComp = amount0 == 0 ? amount1 : amount0;
        uint256 repayAmountForUni = (repayAmountForComp * 1000) / 997 + 1;
        address repayToken = amount0 == 0 ? token1 : token0;

        address pair = IDEXFactory(uniFactory).getPair(token0, token1);
        require(pair == msg.sender, "flashSwap: invalid pair");

        (address cToken, bytes memory callData) = abi.decode(data, (address, bytes));

        if (repayToken == wETHAddress || cToken == cETHAddress) {
            // convert weth to eth
            callUpdate(wETHAddress, abi.encodeWithSignature("withdraw(uint256)", repayAmountForComp), 0);
            require(address(this).balance >= repayAmountForComp, "flashSwap: insufficient balance");
            // liquidate eth
            callUpdate(cToken, callData, repayAmountForComp);
            // check cToken balance
            uint256 cTokenBalance = abi.decode(
                callView(cToken, abi.encodeWithSignature("balanceOf(address)", address(this))),
                (uint256)
            );
            // redeem cToken to underlying token
            uint errorCode = abi.decode(
                callUpdate(cToken, abi.encodeWithSignature("redeem(uint256)", cTokenBalance), 0),
                (uint)
            );
            require(errorCode == 0, "flashSwap: failed redeem eth");
            // deposit eth to weth
            callUpdate(wETHAddress, abi.encodeWithSignature("deposit()"), repayAmountForUni);
            // transfer weth back to uniswap
            callUpdate(wETHAddress, abi.encodeWithSignature("transfer(address,uint256)", pair, repayAmountForUni), 0);
        } else {
            // approve erc20 to ctoken
            IERC20(repayToken).approve(cToken, repayAmountForComp);
            // liquidate erc20
            uint errorCode = abi.decode(callUpdate(cToken, callData, 0), (uint));
            require(errorCode == 0, "flashSwap: failed liquidation erc20");
            // check cToken balance
            bytes memory balanceRes = callView(cToken, abi.encodeWithSignature("balanceOf(address)", address(this)));
            uint256 cTokenBalance = abi.decode(balanceRes, (uint256));
            // redeem cToken to underlying token
            errorCode = abi.decode(
                callUpdate(cToken, abi.encodeWithSignature("redeem(uint256)", cTokenBalance), 0),
                (uint)
            );
            require(errorCode == 0, "flashSwap: failed redeem erc20");
            // transfer erc20 back to uniswap
            IERC20(repayToken).transfer(pair, repayAmountForUni);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IDEXCallee {
    function dexCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IDEXFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

interface IDEXPair {
    // erc20 already with the functions below
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    // below are properties but defined as function in interface
    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}