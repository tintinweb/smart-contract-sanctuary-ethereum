// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "./dependencies/openzeppelin/IERC20.sol";
import "./library/TransferHelper.sol";
import "./dependencies/openzeppelin/Ownable.sol";
import "./library/Configure.sol";
import "./interface/IAccountManager.sol";
import "./interface/IAuthCenter.sol";
import "./interface/IAccount.sol";
import "./interface/IFundsProvider.sol";
import "./interface/IOpManager.sol";
import "./FundsBasic.sol";

// import "hardhat/console.sol";

contract DexOperator is Ownable, FundsBasic {
    using TransferHelper for address;

    event CreateAccount(string id, address account);
    event DirectlyWithdraw(string id, string uniqueId, address token, uint256 amount);
    event SwapWithdraw(string id, string uniqueId, address srcToken, address dstToken, uint256 srcAmount, uint256 dstAmount);
    event Fee(string uniqueId, address feeTo, address token, uint256 amount);

    event UpdateOneInchRouter(address pre, address oneInchRouter);
    event SetOpManager(address preOpManager, address opManager);
    event SetAccountManager(address preAccountManager, address accountManager);
    event SetAuthCenter(address preAuthCenter, address authCenter);
    event SetFundsProvider(address preFundsProvider, address fundsProvider);
    event SetFeeTo(address preFeeTo, address feeTo);

    event Swap(
        string id,
        string uniqueId,
        uint8 assetFrom,
        uint8 action,
        address srcToken,
        address dstToken,
        address from,
        address to,
        address feeTo,
        uint256 srcTokenAmount,
        uint256 srcFeeAmount,
        uint256 returnAmount
    );

    address public opManager;
    address public accountManager;
    address public authCenter;
    address public fundsProvider;
    address public feeTo;
    address public oneInchRouter;
    // address oneInchRouter = 0x1111111254fb6c44bAC0beD2854e76F90643097d;

    bool flag;

    enum AssetFrom {
        FUNDSPROVIDER,
        ACCOUNT
    }

    enum Action {
        SWAP,
        PRECROSS
    }

    modifier onlyRunning() {
        bool running = IOpManager(opManager).isRunning(address(this));
        require(running, "BYDEFI: op paused!");
        _;
    }

    modifier onlyAccess() {
        IAuthCenter(authCenter).ensureOperatorAccess(_msgSender());
        _;
    }

    function init(
        address _opManager,
        address _accountManager,
        address _authCenter,
        address _fundsProvider,
        address _oneInchRouter,
        address _feeTo
    ) external {
        require(!flag, "BYDEFI: already initialized!");
        super.initialize();
        opManager = _opManager;
        accountManager = _accountManager;
        authCenter = _authCenter;
        fundsProvider = _fundsProvider;
        oneInchRouter = _oneInchRouter;
        feeTo = _feeTo;
        flag = true;
    }

    function doSwap(
        string memory _id,
        string memory _uniqueId,
        uint8 _assetFrom,
        uint8 _action,
        address _srcToken,
        address _dstToken,
        uint256 _srcAmount,
        uint256 _srcFeeAmount,
        bytes calldata _data
    ) external onlyAccess onlyRunning returns (uint256 returnAmount) {
        require(_assetFrom <= 1 && _action <= 1, "BYDEFI: assetFrom or action invalid!");
        require(_srcToken != Configure.ZERO_ADDRESS && _dstToken != Configure.ZERO_ADDRESS, "BYDEFI: invalid token input!");
        require(_srcAmount > 0, "BYDEFI: src amount should gt 0!");
        require(_data.length > 2, "BYDEFI: calldata should not be empty!");

        returnAmount = _swapInternal(_id, _uniqueId, _assetFrom, _action, _srcToken, _dstToken, _srcAmount, _srcFeeAmount, _data);
    }

    struct LocalVars {
        address from;
        address to;
        uint256 amt;
        uint256 value;
        uint256 initalBal;
        uint256 finalBal;
        bool success;
    }

    function _swapInternal(
        string memory _id,
        string memory _uniqueId,
        uint8 _assetFrom,
        uint8 _action,
        address _srcToken,
        address _dstToken,
        uint256 _srcAmount,
        uint256 _srcFeeAmount,
        bytes calldata _data
    ) internal returns (uint256 returnAmount) {
        LocalVars memory vars;
        (vars.from, vars.to) = makeData(_assetFrom, _action, _id, _srcToken, _dstToken);

        vars.amt = IAccount(vars.from).pull(_srcToken, _srcAmount, address(this));
        require(vars.amt == _srcAmount, "BYDEFI: invalid src amount input!");
        vars.initalBal = _getTokenBal(IERC20(_dstToken));

        if (Configure.ETH_ADDRESS == _srcToken) {
            vars.value = _srcAmount;
        } else {
            _srcToken.safeApprove(oneInchRouter, vars.amt);
        }

        (vars.success, ) = oneInchRouter.call{ value: vars.value }(_data);
        if (!vars.success) {
            revert("BYDEFI: 1Inch swap failed");
        }

        vars.finalBal = _getTokenBal(IERC20(_dstToken));

        unchecked {
            returnAmount = vars.finalBal - vars.initalBal;
        }

        // double check, in case dstToken mismatch calldata
        require(returnAmount > 0, "BYDEFI: swap error!");

        if (Configure.ETH_ADDRESS != _dstToken) {
            _dstToken.safeApprove(vars.to, returnAmount);
            IAccount(vars.to).push(_dstToken, returnAmount);
        } else {
            IAccount(vars.to).push{ value: returnAmount }(_dstToken, returnAmount);
        }

        if (_srcFeeAmount > 0 && feeTo != Configure.ZERO_ADDRESS) {
            IAccount(vars.from).pull(_srcToken, _srcFeeAmount, feeTo);
            emit Fee(_uniqueId, feeTo, _srcToken, _srcFeeAmount);
        }

        emit Swap(_id, _uniqueId, _assetFrom, _action, _srcToken, _dstToken, vars.from, vars.to, feeTo, vars.amt, _srcFeeAmount, returnAmount);
    }

    function directlyWithdraw(
        string memory _id,
        string memory _uniqueId,
        address _token,
        uint256 _amount,
        uint256 _feeAmount
    ) external onlyAccess onlyRunning returns (uint256 amt) {
        require(IFundsProvider(fundsProvider).isSupported(_token), "BYDEFI: directlyWithdraw unsupported token!");
        require(_amount > 0, "BYDEFI: withdraw amount should gt 0!");

        address account = _getAccountInternal(_id);
        require(account != Configure.ZERO_ADDRESS, "BYDEFI: invalid id");

        amt = IAccount(account).pull(_token, _amount, fundsProvider);

        if (_feeAmount > 0 && feeTo != Configure.ZERO_ADDRESS) {
            IAccount(account).pull(_token, _feeAmount, feeTo);
        }

        emit DirectlyWithdraw(_id, _uniqueId, _token, amt);
        emit Fee(_uniqueId, feeTo, _token, _feeAmount);
    }

    function swapWithdraw(
        string memory _id,
        string memory _uniqueId,
        address _srcToken,
        address _dstToken,
        uint256 _srcAmount,
        uint256 _srcFeeAmount,
        bytes calldata _data
    ) external onlyAccess onlyRunning returns (uint256 amt) {
        require(_srcToken != Configure.ZERO_ADDRESS && _dstToken != Configure.ZERO_ADDRESS, "BYDEFI: invalid token input!");
        require(_srcAmount > 0, "BYDEFI: src amount should gt 0!");
        require(_data.length != 0, "BYDEFI: calldata should not be empty!");

        amt = _swapInternal(_id, _uniqueId, uint8(AssetFrom.ACCOUNT), uint8(Action.PRECROSS), _srcToken, _dstToken, _srcAmount, _srcFeeAmount, _data);

        emit SwapWithdraw(_id, _uniqueId, _srcToken, _dstToken, _srcAmount, amt);
        emit Fee(_uniqueId, feeTo, _srcToken, _srcFeeAmount);
    }

    function createAccount(string memory _id) external onlyAccess returns (address account) {
        account = IAccountManager(accountManager).createAccount(_id);

        emit CreateAccount(_id, account);
    }

    function getBalanceById(string memory _id, address[] memory _tokens) external view returns (uint256 balance, uint256[] memory amounts) {
        address account = _getAccountInternal(_id);
        require(account != Configure.ZERO_ADDRESS, "BYDEFI: invalid id");
        (balance, amounts) = IAccount(account).getBalance(_tokens);
    }

    function makeData(
        uint8 _assetFrom,
        uint8 _action,
        string memory _id,
        address _srcToken,
        address _dstToken
    ) internal returns (address from, address to) {
        address account = _getAccountInternal(_id);
        if (account == Configure.ZERO_ADDRESS) {
            account = IAccountManager(accountManager).createAccount(_id);
        }

        if (uint8(AssetFrom.FUNDSPROVIDER) == _assetFrom && uint8(Action.SWAP) == _action) {
            // by offchain account, usdt provided by funds provider, swap
            require(IFundsProvider(fundsProvider).isSupported(_srcToken), "BYDEFI: src token not supported by funds provider!");
            from = fundsProvider;
            to = account;
        } else if (uint8(AssetFrom.ACCOUNT) == _assetFrom && uint8(Action.SWAP) == _action) {
            // by onchain account, token provided by sub constract, swap
            from = account;
            to = account;
        } else if (uint8(AssetFrom.ACCOUNT) == _assetFrom && uint8(Action.PRECROSS) == _action) {
            // by onchain account, token provided by sub contract, cross chain
            require(IFundsProvider(fundsProvider).isSupported(_dstToken), "BYDEFI: dst token not supported by funds provider!");
            from = account;
            to = fundsProvider;
        } else {
            revert("BYDEFI: invalid asset from and action combination!");
        }
    }

    function updateOneInchRouter(address _router) external onlyOwner {
        address pre = oneInchRouter;
        oneInchRouter = _router;

        emit UpdateOneInchRouter(pre, oneInchRouter);
    }

    function setOpManager(address _opManager) external onlyOwner {
        address pre = opManager;
        opManager = _opManager;
        emit SetOpManager(pre, _opManager);
    }

    function setAccountManager(address _accManager) external onlyOwner {
        address pre = accountManager;
        accountManager = _accManager;
        emit SetAccountManager(pre, _accManager);
    }

    function setAuthCenter(address _authCenter) external onlyOwner {
        address pre = authCenter;
        authCenter = _authCenter;
        emit SetAuthCenter(pre, _authCenter);
    }

    function setFundsProvider(address _fundsProvider) external onlyOwner {
        address pre = fundsProvider;
        fundsProvider = _fundsProvider;
        emit SetFundsProvider(pre, _fundsProvider);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        address pre = feeTo;
        feeTo = _feeTo;
        emit SetFeeTo(pre, _feeTo);
    }

    function push(address _token, uint256 _amt) external payable override returns (uint256 amt) {
        _token;
        _amt;
        amt;
        revert();
    }

    function pull(
        address _token,
        uint256 _amt,
        address _to
    ) external override returns (uint256 amt) {
        IAuthCenter(authCenter).ensureOperatorPullAccess(_msgSender());
        amt = _pull(_token, _amt, _to);
    }

    function getAccount(string memory _id) external view returns (address account) {
        return _getAccountInternal(_id);
    }

    function _getAccountInternal(string memory _id) internal view returns (address account) {
        account = IAccountManager(accountManager).getAccount(_id);
    }

    function _getTokenBal(IERC20 token) internal view returns (uint256 _amt) {
        _amt = address(token) == Configure.ETH_ADDRESS ? address(this).balance : token.balanceOf(address(this));
    }

    function useless() public pure returns (uint256 a, string memory s) {
        a = 100;
        s = "hello world!";
    }
}

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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";
// import "hardhat/console.sol";

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
    function initialize() internal {
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
        // console.log("owner():", owner());
        // console.log("msgSender:", _msgSender());
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
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }

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
pragma solidity ^0.8.0;

library Configure {
    address public constant ZERO_ADDRESS = address(0);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccountManager {
    function createAccount(string memory id) external returns (address _account);

    function getAccount(string memory id) external view returns (address _account);

    function isAccount(address _address) external view returns (bool, string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAuthCenter {
    function ensureAccountAccess(address _caller) external view;
    function ensureFundsProviderPullAccess(address _caller) external view;
    function ensureFundsProviderRebalanceAccess(address _caller) external view;
    function ensureOperatorAccess(address _caller) external view;
    function ensureOperatorPullAccess(address _caller) external view;
    function ensureAccountManagerAccess(address _caller) external view;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAccount {
    function init(address _authCenter) external;
    
    function getBalance(address[] memory _tokens) external view returns (uint256, uint256[] memory);

    function pull(
        address token,
        uint256 amt,
        address to
    ) external returns (uint256 _amt);

    function push(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFundsProvider {
    function init(address _authCenter) external;

    function getBalance(address[] memory _tokens)
        external
        view
        returns (uint256, uint256[] memory);

    function pull(
        address token,
        uint256 amt,
        address to
    ) external returns (uint256 _amt);

    function push(address token, uint256 amt)
        external
        payable
        returns (uint256 _amt);

    function isSupported(address _token) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOpManager {
    function isRunning(address _op) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { IERC20 } from "./dependencies/openzeppelin/IERC20.sol";
import "./library/Configure.sol";
import "./library/TransferHelper.sol";

abstract contract FundsBasic {
    using TransferHelper for address;
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    event Push(address token, uint256 amt);
    event Pull(address token, uint256 amt, address to);

    function push(address _token, uint256 _amt) external payable virtual returns (uint256 amt) {
        amt = _amt;

        if (_token != Configure.ETH_ADDRESS) {
            _token.safeTransferFrom(msg.sender, address(this), _amt);
        } else {
            require(msg.value == _amt, "BYDEFI: Invalid Ether Amount");
        }
        emit Push(_token, _amt);
    }

    function pull(
        address _token,
        uint256 _amt,
        address _to
    ) external virtual returns (uint256 amt);

    function _pull(
        address _token,
        uint256 _amt,
        address _to
    ) internal noReentrant returns (uint256 amt) {
        amt = _amt;
        if (_token == Configure.ETH_ADDRESS) {
            (bool retCall, ) = _to.call{ value: _amt }("");
            require(retCall != false, "BYDEFI: pull ETH from account fail");
        } else {
            _token.safeTransfer(_to, _amt);
        }
        emit Pull(_token, _amt, _to);
    }

    function getBalance(IERC20[] memory _tokens) external view returns (uint256, uint256[] memory) {
        uint256[] memory array = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            array[i] = _tokens[i].balanceOf(address(this));
        }
        return (address(this).balance, array);
    }

    receive() external payable {}
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