/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// Sources flattened with hardhat v2.9.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File contracts/interface/ICheckPermission.sol

pragma solidity =0.8.10;

interface ICheckPermission {
    function operator() external view returns (address);

    function owner() external view returns (address);

    function check(address _target) external view returns (bool);
}

// File contracts/tools/Operatable.sol

pragma solidity =0.8.10;

// seperate owner and operator, operator is for daily devops, only owner can update operator
contract Operatable is Ownable {
    event SetOperator(address indexed oldOperator, address indexed newOperator);

    address public operator;

    mapping(address => bool) public contractWhiteList;

    constructor() {
        operator = msg.sender;
        emit SetOperator(address(0), operator);
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "not operator");
        _;
    }

    function setOperator(address newOperator) public onlyOwner {
        require(newOperator != address(0), "bad new operator");
        address oldOperator = operator;
        operator = newOperator;
        emit SetOperator(oldOperator, newOperator);
    }

    // File: @openzeppelin/contracts/utils/Address.sol
    function isContract(address account) public view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }

    function addContract(address _target) public onlyOperator {
        contractWhiteList[_target] = true;
    }

    function removeContract(address _target) public onlyOperator {
        contractWhiteList[_target] = false;
    }

    //Do not ban access to the user, need to be in the whitelist contract address to be able to access
    function check(address _target) public view returns (bool) {
        if (isContract(_target)) {
            return contractWhiteList[_target];
        }
        return true;
    }
}

// File contracts/tools/CheckPermission.sol

pragma solidity =0.8.10;

// seperate owner and operator, operator is for daily devops, only owner can update operator
contract CheckPermission is ICheckPermission {
    Operatable public operatable;

    event SetOperatorContract(address indexed oldOperator, address indexed newOperator);

    constructor(address _oper) {
        operatable = Operatable(_oper);
        emit SetOperatorContract(address(0), _oper);
    }

    modifier onlyOwner() {
        require(operatable.owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOperator() {
        require(operatable.operator() == msg.sender, "not operator");
        _;
    }

    modifier onlyAEOWhiteList() {
        require(check(msg.sender), "aeo or whitelist");
        _;
    }

    function operator() public view override returns (address) {
        return operatable.operator();
    }

    function owner() public view override returns (address) {
        return operatable.owner();
    }

    function setOperContract(address _oper) public onlyOwner {
        require(_oper != address(0), "bad new operator");
        address oldOperator = address(operatable);
        operatable = Operatable(_oper);
        emit SetOperatorContract(oldOperator, _oper);
    }

    function check(address _target) public view override returns (bool) {
        return operatable.check(_target);
    }
}

// File contracts/tools/TransferHelper.sol

pragma solidity 0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

// File contracts/interface/IStablePool.sol

pragma solidity =0.8.10;

interface IStablePool {
    function n_coins() external view returns (int128);

    function coins(uint256) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function base_coins(uint256) external view returns (address);

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // bUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        address receiver
    ) external returns (uint256);

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        bool use_eth,
        address receiver
    ) external payable returns (uint256);

    function exchange_underlying(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        address receiver
    ) external returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool isDeposit) external returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool isDeposit) external returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts, bool isDeposit) external returns (uint256);
}

// File contracts/interface/curve/IZapDepositor5pool.sol

pragma solidity >=0.8.0;

interface IZapDepositor5pool {
    function calc_token_amount(uint256[5] calldata amounts, bool _is_deposit) external returns (uint256);

    function n_coins() external view returns (int128);

    function underlying_coins(uint256 i) external view returns (address);

    function exchange_underlying(
        uint256 _i,
        uint256 _j,
        uint256 _dx,
        uint256 _min_dy,
        address receiver
    ) external;
}

// File contracts/interface/curve/IZapDepositor4pool.sol

pragma solidity >=0.8.0;

interface IZapDepositor4pool {
    function calc_token_amount(uint256[4] calldata amounts, bool _is_deposit) external returns (uint256);

    function n_coins() external view returns (int128);

    function underlying_coins(uint256 i) external view returns (address);

    function exchange_underlying(
        uint256 _i,
        uint256 _j,
        uint256 _dx,
        uint256 _min_dy,
        address receiver
    ) external;
}

// File contracts/interface/ICryptoPool.sol

pragma solidity =0.8.10;

interface ICryptoPool {
    function n_coins() external view returns (uint256);

    function coins(uint256) external view returns (address);

    function get_virtual_price() external view returns (uint256);

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function add_liquidity(
        // bUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts) external;

    function exchange(
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        bool use_eth,
        address receiver
    ) external payable returns (uint256);

    function exchange(
        uint256 from,
        uint256 to,
        uint256 _from_amount,
        uint256 _min_to_amount,
        bool use_eth
    ) external payable;

    //    function calc_token_amount(uint256[2] calldata amounts) external returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts) external returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit) external returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts) external returns (uint256);
}

// File contracts/interface/ISwapMining.sol

pragma solidity =0.8.10;

interface ISwapMining {
    function swap(
        address account,
        address pair,
        uint256 quantity
    ) external returns (bool);

    function getRewardAll() external;

    function getReward(uint256 pid) external;
}

// File contracts/swap/SwapRouter.sol

pragma solidity =0.8.10;

contract SwapRouter is CheckPermission {
    event ChangeSwapMining(address indexed oldSwapMining, address indexed newSwapMining);

    address public weth;

    address public swapMining;

    constructor(address _operatorMsg, address _weth) CheckPermission(_operatorMsg) {
        weth = _weth;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    // address(0) means no swap mining
    function setSwapMining(address addr) public onlyOperator {
        address oldSwapMining = swapMining;
        swapMining = addr;
        emit ChangeSwapMining(oldSwapMining, swapMining);
    }

    function _callStableSwapMining(
        address account,
        address pair,
        uint256 i,
        uint256 amount
    ) private {
        if (swapMining != address(0)) {
            int128 n = IStablePool(pair).n_coins();
            uint256 quantity;
            if (n == 2) {
                uint256[2] memory amounts;
                amounts[i] = amount;
                quantity = IStablePool(pair).calc_token_amount(amounts, false);
            } else if (n == 3) {
                uint256[3] memory amounts;
                amounts[i] = amount;
                quantity = IStablePool(pair).calc_token_amount(amounts, false);
            } else {
                uint256[4] memory amounts;
                amounts[i] = amount;
                quantity = IStablePool(pair).calc_token_amount(amounts, false);
            }
            ISwapMining(swapMining).swap(account, pair, quantity);
        }
    }

    function _callCryptoSwapMining(
        address account,
        address pair,
        uint256 i,
        uint256 amount
    ) private {
        if (swapMining != address(0)) {
            uint256 n = ICryptoPool(pair).n_coins();
            uint256 quantity;
            if (n == 2) {
                uint256[2] memory amounts;
                amounts[i] = amount;
                quantity = ICryptoPool(pair).calc_token_amount(amounts, false);
            } else {
                uint256[3] memory amounts;
                amounts[i] = amount;
                quantity = ICryptoPool(pair).calc_token_amount(amounts, false);
            }
            ISwapMining(swapMining).swap(account, pair, quantity);
        }
    }

    function _callCryptoTokenSwapMining(
        address account,
        address pair,
        uint256 i,
        uint256 amount
    ) private {
        if (swapMining != address(0)) {
            uint256 quantity;
            int128 n = IZapDepositor5pool(pair).n_coins();
            if (n == 2) {
                uint256[4] memory amounts;
                amounts[i] = amount;
                quantity = IZapDepositor4pool(pair).calc_token_amount(amounts, false);
                ISwapMining(swapMining).swap(account, pair, quantity);
            } else if (n == 3) {
                uint256[5] memory amounts;
                amounts[i] = amount;
                quantity = IZapDepositor5pool(pair).calc_token_amount(amounts, false);
                ISwapMining(swapMining).swap(account, pair, quantity);
            }
        }
    }

    function swapStable(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external ensure(deadline) {
        int128 fromInt = int128(uint128(from));
        int128 toInt = int128(uint128(to));
        address fromToken = IStablePool(pool).coins(from);
        //        address toToken = IStablePool(pool).coins(to);
        if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
            TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
        }
        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        IStablePool(pool).exchange(fromInt, toInt, fromAmount, minToAmount, receiver);
        _callStableSwapMining(receiver, pool, from, fromAmount);
    }

    function swapMeta(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external ensure(deadline) {
        int128 fromInt = int128(uint128(from));
        int128 toInt = int128(uint128(to));
        address fromToken;
        uint256 callStable = 0;
        if (from == 0) {
            fromToken = IStablePool(pool).coins(from);
        } else {
            fromToken = IStablePool(pool).base_coins(from - 1);
            callStable = 1;
        }

        if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
            TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
        }

        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        IStablePool(pool).exchange_underlying(fromInt, toInt, fromAmount, minToAmount, receiver);
        _callStableSwapMining(receiver, pool, callStable, fromAmount);
    }

    function swapToken(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external ensure(deadline) {
        address fromToken = IStablePool(pool).coins(from);
        //        address toToken = IStablePool(pool).coins(to);
        if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
            TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
        }
        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        ICryptoPool(pool).exchange(from, to, fromAmount, minToAmount, false, receiver);
        _callCryptoSwapMining(receiver, pool, from, fromAmount);
    }

    function swapToken3(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external ensure(deadline) {
        address fromToken = ICryptoPool(pool).coins(from);
        if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
            TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
        }
        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        ICryptoPool(pool).exchange(from, to, fromAmount, minToAmount, false);
        _callCryptoSwapMining(receiver, pool, from, fromAmount);
    }

    function swapCryptoToken(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external ensure(deadline) {
        address fromToken = IZapDepositor5pool(pool).underlying_coins(from);
        if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
            TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
        }
        TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        IZapDepositor5pool(pool).exchange_underlying(from, to, fromAmount, minToAmount, receiver);
        _callCryptoTokenSwapMining(receiver, pool, from, fromAmount);
    }

    function swapEthForToken(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        address receiver,
        uint256 deadline
    ) external payable ensure(deadline) {
        uint256 bal = msg.value;
        address fromToken = IStablePool(pool).coins(from);
        if (fromToken != weth) {
            if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
                TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
            }

            TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        }

        if (fromToken == weth) {
            ICryptoPool(pool).exchange{value: bal}(from, to, fromAmount, minToAmount, true, receiver);
        } else {
            ICryptoPool(pool).exchange(from, to, fromAmount, minToAmount, true, receiver);
        }
        _callCryptoSwapMining(receiver, pool, from, fromAmount);
    }

    function swapETHStable(
        address pool,
        uint256 from,
        uint256 to,
        uint256 fromAmount,
        uint256 minToAmount,
        bool useEth,
        address receiver,
        uint256 deadline
    ) external payable ensure(deadline) {
        int128 fromInt = int128(uint128(from));
        int128 toInt = int128(uint128(to));
        address fromToken = IStablePool(pool).coins(from);
        if (!useEth) {
            if (IERC20(fromToken).allowance(address(this), pool) < fromAmount) {
                TransferHelper.safeApprove(fromToken, pool, type(uint256).max);
            }
            TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), fromAmount);
        }

        if (useEth) {
            IStablePool(pool).exchange{value: msg.value}(fromInt, toInt, fromAmount, minToAmount, true, receiver);
        } else {
            IStablePool(pool).exchange(fromInt, toInt, fromAmount, minToAmount, true, receiver);
        }

        _callStableSwapMining(receiver, pool, from, fromAmount);
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external onlyOperator {
        TransferHelper.safeTransfer(_tokenAddress, owner(), _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    event Recovered(address _token, uint256 _amount);
}