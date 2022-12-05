// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./lib/TransferHelper.sol";
import "./FundsBasic.sol";
// import "hardhat/console.sol";

contract Operator is Ownable, FundsBasic {
    using TransferHelper for address;

    event FlipRunning(bool _prev, bool _curr);
    event SwapFeeTo(address _prev, address _curr);
    event GasFeeTo(address _prev, address _curr);
    event SetWhitelist(address _addr, bool _isWhitelist);
    event FundsProvider(address _prev, address _curr);

    event Swap(
        bytes id,
        bytes uniqueId,
        ACTION action,
        address srcToken,
        address dstToken,
        address tokenFrom,
        address tokenTo,
        uint256 retAmt,
        uint256 srcAmt,
        uint256 feeAmt
    );

    // 1inch router address: 0x1111111254fb6c44bAC0beD2854e76F90643097d
    address public immutable oneInchRouter;

    // USDT intermediate token
    address public immutable imToken;

    // swap fee will tranfer to this address, provided by Finance Team
    address public swapFeeTo;

    // used for cross swap, provided by Finance Team
    address public gasFeeTo;

    // used for cross swap, this is a usdt vault
    address public getFundsProvider;

    // running or pause, false by default
    bool public isRunning;

    // used for cross swap, provided by Wallet Team
    mapping(address => bool) public whitelist;

    // used for emit event
    enum ACTION {
        // swap in a specific blockchain
        INNER_SWAP,
        // swap for cross chain scenario, this is the first step, transfer token from EOA to FundsProvider
        CROSS_FIRST,
        // swap for cross chain scenario, this is the second step, transfer token from FundsProvider to EOA
        CROSS_SECOND
    }

    // ACCESS CONTROL
    modifier onlyRunning() {
        require(isRunning, "not running!");
        _;
    }

    modifier onlyEOA() {
        require(_msgSender() == tx.origin, "not an eoa!");
        _;
    }

    modifier onlyWhitelist() {
        require(whitelist[_msgSender()], "not in whitelist!");
        _;
    }

    // @notice this is the function we call 1inch
    // function swap( IAggregationExecutor caller, SwapDescription calldata desc, bytes calldata data ) external payable returns ( uint256 returnAmount, uint256 spentAmount, uint256 gasLeft )
    // ONEINCH_SELECTOR = bytes4(keccak256(bytes("swap(address,(address,address,address,address,uint256,uint256,uint256,bytes),bytes)")));
    bytes4 private constant ONEINCH_SELECTOR = 0x7c025200;

    constructor(
        address _oneInchRouter,
        address _imToken,
        address _fundsProvider,
        address payable _swapFeeTo,
        address payable _gasFeeTo
    ) {
        oneInchRouter = _oneInchRouter;
        imToken = _imToken;
        getFundsProvider = _fundsProvider;
        swapFeeTo = _swapFeeTo;
        gasFeeTo = _gasFeeTo;

        emit FundsProvider(address(0), getFundsProvider);
        emit SwapFeeTo(address(0), swapFeeTo);
        emit GasFeeTo(address(0), gasFeeTo);
    }

    /**
     * @notice swap for inner swap, will be called by user EOA, no access limitation
     * @param _id id
     * @param _uniqueId used for cross chain
     * @param _swapFeeAmt fee changed by us
     * @param _data data provided by 1inch api
     */
    function doSwap(
        bytes memory _id,
        bytes memory _uniqueId,
        uint256 _swapFeeAmt,
        bytes calldata _data
    ) external payable onlyRunning onlyEOA {
        _swap(_id, _uniqueId, _msgSender(), swapFeeTo, _swapFeeAmt, _data);
    }

    /**
     * @notice when usdt as src token to do cross swap
     * @param _id id
     * @param _uniqueId used for cross chain
     * @param _amt swap amount
     * @param _swapFeeAmt fee changed by us
     */
    function fromUCross(
        bytes memory _id,
        bytes memory _uniqueId,
        uint256 _amt,
        uint256 _swapFeeAmt
    ) external onlyRunning onlyEOA {
        require(_amt > 0, "invalid amt!");
        address(imToken).safeTransferFrom(_msgSender(), getFundsProvider, _amt);

        if (_swapFeeAmt > 0) {
            address(imToken).safeTransferFrom(
                _msgSender(),
                swapFeeTo,
                _swapFeeAmt
            );
        }

        emit Swap(
            _id,
            _uniqueId,
            ACTION.CROSS_FIRST,
            address(imToken),
            address(imToken),
            _msgSender(),
            getFundsProvider,
            _amt,
            _amt,
            _swapFeeAmt
        );
    }

    /**
     * @notice for cross chain swap, can only be called by bybit special EOA
     * @param _id id
     * @param _uniqueId used for cross chain
     * @param _gasFeeAmt usdt fee changed by us
     * @param _data data provided by 1inch api
     */
    function crossSwap(
        bytes memory _id,
        bytes memory _uniqueId,
        uint256 _gasFeeAmt,
        bytes calldata _data
    ) external onlyRunning onlyWhitelist {
        _swap(_id, _uniqueId, getFundsProvider, gasFeeTo, _gasFeeAmt, _data);
    }

    /**
     * @notice when usdt as dst token to do cross swap
     * @param _id id
     * @param _uniqueId used for cross chain
     * @param _amt usdt amount that will send to user EOA directly
     * @param _gasFeeAmt usdt fee changed by us
     */
    function toUCross(
        bytes memory _id,
        bytes memory _uniqueId,
        uint256 _amt,
        uint256 _gasFeeAmt,
        address _to
    ) external onlyRunning onlyWhitelist {
        require(_amt > 0, "invalid amt!");
        address(imToken).safeTransferFrom(getFundsProvider, _to, _amt);

        if (_gasFeeAmt > 0) {
            address(imToken).safeTransferFrom(
                getFundsProvider,
                gasFeeTo,
                _gasFeeAmt
            );
        }
        emit Swap(
            _id,
            _uniqueId,
            ACTION.CROSS_SECOND,
            address(imToken),
            address(imToken),
            _msgSender(),
            getFundsProvider,
            _amt,
            _amt,
            _gasFeeAmt
        );
    }

    struct LocalVars {
        uint256 value;
        bool success;
        bytes retData;
        uint256 retAmt;
    }

    // 1inch Data Struct
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver; // don't use
        address payable dstReceiver;
        uint256 amount;
        uint256 minretAmt;
        uint256 flags;
        bytes permit;
    }

    /**
     * @notice internal swap function, will call 1inch
     * @param _id id
     * @param _uniqueId used for cross chain
     * @param _payer could be EOA or funds provider
     * @param _feeTo _feeTo can either be swapFee or gasFee
     * @param _feeAmt _feeAmt
     * @param _data data provided by 1inch api
     */
    function _swap(
        bytes memory _id,
        bytes memory _uniqueId,
        address _payer,
        address _feeTo,
        uint256 _feeAmt,
        bytes calldata _data
    ) internal {
        LocalVars memory vars;
        require(
            _data.length > 4 && bytes4(_data[0:4]) == ONEINCH_SELECTOR,
            "invalid selector!"
        );

        SwapDescription memory desc;
        (, desc, ) = abi.decode(_data[4:], (address, SwapDescription, bytes));

        require(
            address(desc.srcToken) != address(0) &&
                address(desc.dstToken) != address(0) &&
                desc.amount != 0 &&
                desc.dstReceiver != address(0),
            "invalid calldata!"
        );

        // default: INNER_SWAP
        ACTION action;

        if (desc.dstReceiver == getFundsProvider) {
            // receiver is fundsProvider means this is the first step for cross swap
            action = ACTION.CROSS_FIRST;
        } else if (_payer == getFundsProvider) {
            // when fundsProvider provide usdt means this is the second step for cross swap
            action = ACTION.CROSS_SECOND;
        } else {
            // means this is a inner swap, thus the payer should be equal to the receiver
            require(_payer == desc.dstReceiver, "fromAddr should be eaqul to toAddr!");
        }

        // From EOA NATIVE_TOKEN
        if (address(desc.srcToken) == NATIVE_TOKEN) {
            require(
                msg.value == desc.amount + _feeAmt,
                "msg.value should eaqul to amount set in api"
            );

            // transfer fee to 'feeTo'
            if (_feeAmt > 0) {
                address(_feeTo).safeTransferETH(_feeAmt);
            }

            // will pass to 1inch
            vars.value = desc.amount;
        } else {
            // From EOA ERC20 Token
            require(msg.value == 0, "msg.value should be 0");

            // fetch token that will be used for swapping
            // need funds provider Approve to OP first
            address(desc.srcToken).safeTransferFrom(
                _payer,
                address(this),
                desc.amount
            );

            if (_feeAmt > 0) {
                // transfer fee to '_feeTo'
                address(desc.srcToken).safeTransferFrom(
                    _payer,
                    _feeTo,
                    _feeAmt
                );
            }

            // approve uint256 max to 1inch for erc20
            // op will not keep money, so it would be safe
            if (
                desc.srcToken.allowance(address(this), oneInchRouter) <
                desc.amount
            ) {
                address(desc.srcToken).safeApprove(
                    oneInchRouter,
                    type(uint256).max
                );
            }
        }

        // call swap
        (vars.success, vars.retData) = oneInchRouter.call{value: vars.value}(
            _data
        );
        if (!vars.success) revert("1inch swap failed");

        // function swap( IAggregationExecutor caller, SwapDescription calldata desc, bytes calldata data )
        // external
        // payable
        // returns ( uint256 returnAmount, uint256 spentAmount, uint256 gasLeft )

        vars.retAmt = abi.decode(vars.retData, (uint256));
        require(vars.retAmt > 0, "swap retAmt should not be 0!");

        emit Swap(
            _id,
            _uniqueId,
            action,
            address(desc.srcToken),
            address(desc.dstToken),
            _payer,
            desc.dstReceiver,
            vars.retAmt,
            desc.amount,
            _feeAmt
        );
    }

    /**
     * @notice start or stop this operator
     */
    function flipRunning() external onlyOwner {
        isRunning = !isRunning;
        emit FlipRunning(!isRunning, isRunning);
    }

    /**
     * @notice set new swapFeeTo
     * @param _newSwapFeeTo new address
     */
    function setSwapFeeTo(address _newSwapFeeTo) external onlyOwner {
        emit SwapFeeTo(swapFeeTo, _newSwapFeeTo);
        swapFeeTo = _newSwapFeeTo;
    }

    /**
     * @notice set new gasFeeTo
     * @param _newGasFeeTo new address
     */
    function setGasFeeTo(address _newGasFeeTo) external onlyOwner {
        emit GasFeeTo(gasFeeTo, _newGasFeeTo);
        gasFeeTo = _newGasFeeTo;
    }

    /**
     * @notice set special caller whitelist
     * @param _addrArr new address array
     * @param _flags new state array for addresses
     */
    function setWhitelist(address[] calldata _addrArr, bool[] calldata _flags)
        external
        onlyOwner
    {
        require(_addrArr.length == _flags.length, "input length mismatch!");
        for (uint256 i; i < _addrArr.length; i++) {
            whitelist[_addrArr[i]] = _flags[i];
            emit SetWhitelist(_addrArr[i], _flags[i]);
        }
    }

    /**
     * @notice set new funds provider
     * @param _newFundsProvider new address
     */
    function setFundsProvider(address _newFundsProvider) external onlyOwner {
        emit FundsProvider(getFundsProvider, _newFundsProvider);
        getFundsProvider = _newFundsProvider;
    }

    function pull(
        address _token,
        uint256 _amt,
        address _to
    ) external override onlyOwner returns (uint256 amt) {
        amt = _pull(_token, _amt, _to);
    }

    // will delete later
    function useless() external pure returns (uint256) {
        return 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./lib/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract FundsBasic {
    address internal constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    using TransferHelper for address;
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    // EVENTS
    // event Push(address token, uint256 amt);
    event Pull(address token, uint256 amt, address to);

    /**
     * @notice deposit token into contract
     * @param _token token address
     * @param _amt amount in decimals
     * @return amt actual amount
     */
    // function push(address _token, uint256 _amt)
    //     external
    //     payable
    //     virtual
    //     returns (uint256 amt);

    /**
     * @notice withdraw token from this contract
     * @param _token token address
     * @param _amt amount in decimals
     * @return amt actual amount
     */
    function pull(
        address _token,
        uint256 _amt,
        address _to
    ) external virtual returns (uint256 amt);

    // INTERNAL FUNCTION
    // function _push(address _token, uint256 _amt)
    //     internal
    //     virtual
    //     returns (uint256 amt)
    // {
    //     amt = _amt;

    //     if (_token != NATIVE_TOKEN) {
    //         require(msg.value == 0, "Invalid msg.value");
    //         _token.safeTransferFrom(msg.sender, address(this), _amt);
    //     } else {
    //         require(msg.value == _amt, "Invalid Amount");
    //     }
    //     emit Push(_token, _amt);
    // }

    function _pull(
        address _token,
        uint256 _amt,
        address _to
    ) internal noReentrant returns (uint256 amt) {
        amt = _amt;
        if (_token == NATIVE_TOKEN) {
            _to.safeTransferETH(_amt);
        } else {
            _token.safeTransfer(_to, _amt);
        }
        emit Pull(_token, _amt, _to);
    }

    /**
     * @notice get balances of the given tokens
     * @param _tokens array of token addresses, support NATIVE TOKEN
     * @return balances balance array
     */
    function getBalance(address[] memory _tokens)
        external
        view
        returns (uint256[] memory balances)
    {
        balances = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == NATIVE_TOKEN) {
                balances[i] = address(this).balance;
            } else {
                balances[i] = IERC20(_tokens[i]).balanceOf(address(this));
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper:safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper:safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper:transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper:safeTransferETH: ETH transfer failed");
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