// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./BasicSTIStrategyTest.sol";
import "../../bni/constant/EthConstantTest.sol";
import "../../../interfaces/IStVault.sol";
import "../../../libs/Const.sol";

contract EthSTIStrategyTest is BasicSTIStrategyTest {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IStVault public ETHVault;
    IStVault public MATICVault;

    function initialize1(
        address _admin,
        address _priceOracle,
        IStVault _ETHVault, IStVault _MATICVault
    ) public initializer {
        super.initialize(
            _admin,
            _priceOracle,
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, // Uniswap2
            EthConstantTest.WETH,
            EthConstantTest.USDT,
            Const.NATIVE_ASSET
        );

        tokens.push(EthConstantTest.MATIC);
        updatePid();

        ETHVault = _ETHVault;
        MATICVault = _MATICVault;

        // IERC20Upgradeable(EthConstantTest.MATIC).safeApprove(address(MATICVault), type(uint).max);
        // IERC20Upgradeable(EthConstantTest.MATIC).safeApprove(address(router), type(uint).max);
    }

    function setStVault(IStVault _ETHVault, IStVault _MATICVault) external onlyOwner {
        ETHVault = _ETHVault;
        MATICVault = _MATICVault;

        // if (IERC20Upgradeable(EthConstantTest.MATIC).allowance(address(this), address(MATICVault)) == 0) {
        //     IERC20Upgradeable(EthConstantTest.MATIC).safeApprove(address(MATICVault), type(uint).max);
        // }
    }

    function getStVault(address _token) internal view override returns (IStVault stVault) {
        if (_token == Const.NATIVE_ASSET) {
            stVault = ETHVault;
        } else if (_token == EthConstantTest.MATIC) {
            stVault = MATICVault;
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../../bni/priceOracle/IPriceOracle.sol";
import "../../../interfaces/IERC20UpgradeableExt.sol";
import "../../../interfaces/IUniRouter.sol";
import "../../../interfaces/IStVault.sol";
import "../../../libs/Const.sol";
import "../../../libs/Token.sol";

contract BasicSTIStrategyTest is PausableUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20UpgradeableExt;

    IUniRouter public router;
    IERC20UpgradeableExt public SWAP_BASE_TOKEN; // It has same role with WETH on Ethereum Swaps. Most of tokens have been paired with this token.
    IERC20UpgradeableExt public USDT;
    uint8 usdtDecimals;

    address public admin;
    address public vault;
    IPriceOracle public priceOracle;

    address[] public tokens;
    mapping(address => uint) public pid; // Pool indices in tokens array

    // maps the address to array of the owned tokens, the first key is token address.
    mapping(address => mapping(address => uint[])) public claimer2ReqIds;
    // reqId can be owned by only one address at the time, therefore reqId is present in only one of those arrays in the mapping
    // this mapping stores the index of the reqId in one of those arrays, the first key is token address.
    mapping(address => mapping(uint => uint)) public reqId2Index;

    event AddToken(address token, uint pid);
    event RemoveToken(address token, uint pid);
    event Withdraw(uint sharePerc, uint USDTAmt);
    event Claim(address claimer, address token, uint tokenAmt, uint USDTAmt);
    event EmergencyWithdraw(uint USDTAmt);
    event SetTreasuryWallet(address oldTreasuryWallet, address newTreasuryWallet);
    event SetAdminWallet(address oldAdmin, address newAdmin);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize(
        address _admin,
        address _priceOracle,
        address _router, address _SWAP_BASE_TOKEN,
        address _USDT, address _token0
    ) public virtual initializer {
        require(_router != address(0), "Invalid router");
        require(_SWAP_BASE_TOKEN != address(0), "Invalid SWAP_BASE_TOKEN");
        require(_USDT != address(0), "Invalid USDT");
        require(_token0 != address(0), "Invalid token0");
        __Ownable_init();

        admin = _admin;
        priceOracle = IPriceOracle(_priceOracle);
        router = IUniRouter(_router);
        SWAP_BASE_TOKEN = IERC20UpgradeableExt(_SWAP_BASE_TOKEN);

        USDT = IERC20UpgradeableExt(_USDT);
        usdtDecimals = USDT.decimals();
        require(usdtDecimals >= 6, "USDT decimals must >= 6");

        tokens.push(_token0);
        updatePid();

        // USDT.safeApprove(address(router), type(uint).max);
        // if (_token0 != Const.NATIVE_ASSET) {
        //     IERC20UpgradeableExt(_token0).safeApprove(address(router), type(uint).max);
        // }
    }

    function updatePid() internal {
        address[] memory _tokens = tokens;

        uint tokenCnt = _tokens.length;
        for (uint i = 0; i < tokenCnt; i ++) {
            pid[_tokens[i]] = i;
        }
    }

    function getPoolCount() public view returns (uint) {
        return tokens.length;
    }

    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function addToken(address _token) external onlyOwner {
        uint _pid = pid[_token];
        require ((_pid == 0 && _token != tokens[0]), "Already added");

        tokens.push(_token);
        _pid = tokens.length-1;
        pid[_token] = _pid;

        // if (_token != Const.NATIVE_ASSET && IERC20UpgradeableExt(_token).allowance(address(this), address(router)) == 0) {
        //     IERC20UpgradeableExt(_token).safeApprove(address(router), type(uint).max);
        // }
        emit AddToken(_token, _pid);
    }

    function removeToken(uint _pid) external onlyOwner {
        uint tokenCnt = tokens.length;
        require(_pid < tokenCnt, "Invalid pid");
        uint pool = _getPoolInUSD(_pid);
        require(pool == 0, "Pool is not empty");

        address _token = tokens[_pid];
        tokens[_pid] = tokens[tokenCnt-1];
        tokens.pop();

        pid[_token] = 0;
        updatePid();

        emit RemoveToken(_token, _pid);
    }

    /// @param _USDTAmts amounts of USDT should be deposited to each pools. They have been denominated in USDT decimals
    function invest(address[] memory _tokens, uint[] memory _USDTAmts) external onlyVault {
        _investInternal(_tokens, _USDTAmts);
    }

    function _investInternal(address[] memory _tokens, uint[] memory _USDTAmts) internal {
        uint poolCnt = _tokens.length;
        uint USDTAmt;
        uint[] memory USDTAmts = new uint[](tokens.length);
        for (uint i = 0; i < poolCnt; i ++) {
            uint amount = _USDTAmts[i];
            USDTAmt += amount;
            uint _pid = pid[_tokens[i]];
            USDTAmts[_pid] += amount;
        }
        USDT.safeTransferFrom(vault, address(this), USDTAmt);

        // _invest(USDTAmts);
    }

    function _invest(uint[] memory _USDTAmts) internal virtual {
        uint poolCnt = _USDTAmts.length;
        for (uint _pid = 0; _pid < poolCnt; _pid ++) {
            uint USDTAmt = _USDTAmts[_pid];
            if (USDTAmt == 0) continue;

            address token = tokens[_pid];
            uint tokenAmt;
            if (token != address(USDT)) {
                (uint USDTPriceInUSD, uint8 USDTPriceDecimals) = getUSDTPriceInUSD();
                (uint TOKENPriceInUSD, uint8 TOKENPriceDecimals) = priceOracle.getAssetPrice(token);
                uint8 tokenDecimals = _assetDecimals(token);
                uint numerator = USDTPriceInUSD * (10 ** (TOKENPriceDecimals + tokenDecimals));
                uint denominator = TOKENPriceInUSD * (10 ** (USDTPriceDecimals + usdtDecimals));
                uint amountOutMin = USDTAmt * numerator * 85 / (denominator * 100);

                if (token == Const.NATIVE_ASSET) {
                    tokenAmt = _swapForETH(address(USDT), USDTAmt, amountOutMin);
                } else if (token == address(SWAP_BASE_TOKEN)) {
                    tokenAmt = _swap(address(USDT), token, USDTAmt, amountOutMin);
                } else {
                    tokenAmt = _swap2(address(USDT), token, USDTAmt, amountOutMin);
                }
            } else {
                tokenAmt = USDTAmt;
            }

            IStVault stVault = getStVault(token);
            if (address(stVault) != address(0)) {
                if (token == Const.NATIVE_ASSET) {
                    stVault.depositETH{value: tokenAmt}();
                } else {
                    stVault.deposit(tokenAmt);
                }
            }
        }
    }

    function withdrawPerc(address _claimer, uint _sharePerc) external onlyVault returns (uint USDTAmt) {
        require(_sharePerc <= 1e18, "Over 100%");
        USDTAmt = _withdraw(_claimer, _sharePerc);
        if (USDTAmt > 0) {
            USDT.safeTransfer(vault, USDTAmt);
        }
        emit Withdraw(_sharePerc, USDTAmt);
    }

    function _withdraw(address _claimer, uint _sharePerc) internal virtual returns (uint USDTAmt) {
        USDTAmt = USDT.balanceOf(address(this)) * _sharePerc / 1e18;
        // uint poolCnt = tokens.length;
        // for (uint i = 0; i < poolCnt; i ++) {
        //     USDTAmt += _withdrawFromPool(_claimer, i, _sharePerc);
        // }
    }

    function _withdrawFromPool(address _claimer, uint _pid, uint _sharePerc) internal virtual returns (uint USDTAmt) {
        address token = tokens[_pid];
        IStVault stVault = getStVault(token);
        if (address(stVault) != address(0)) {
            uint reqId;
            (USDTAmt, reqId) = _withdrawStVault(stVault, _sharePerc);
            if (reqId > 0) {
                addReqId(tokens[_pid], _claimer, reqId);
            }
        } else {
            uint amount = _balanceOf(token, address(this)) * _sharePerc / 1e18;
            if (0 < amount) {
                if (token == address(USDT)) {
                    USDTAmt = amount;
                } else {
                    USDTAmt = _swapForUSDT(token, amount);
                }
            }
        }
    }

    function _withdrawStVault(IStVault _stVault, uint _sharePerc) private returns (uint USDTAmt, uint reqId) {
        uint amount = _stVault.balanceOf(address(this)) * _sharePerc / 1e18;
        if (0 < amount) {
            (uint tokenAmt, uint _reqId) = _stVault.withdraw(amount);
            if (tokenAmt > 0) {
                USDTAmt = _swapForUSDT(address(_stVault.token()), tokenAmt);
            }
            reqId = _reqId;
        }
    }

    function _swapForUSDT(address token, uint amount) internal returns (uint USDTAmt) {
        (uint USDTPriceInUSD, uint8 USDTPriceDecimals) = getUSDTPriceInUSD();
        (uint TOKENPriceInUSD, uint8 TOKENPriceDecimals) = priceOracle.getAssetPrice(address(token));
        uint8 tokenDecimals = _assetDecimals(token);
        uint numerator = TOKENPriceInUSD * (10 ** (USDTPriceDecimals + usdtDecimals));
        uint denominator = USDTPriceInUSD * (10 ** (TOKENPriceDecimals + tokenDecimals));
        uint amountOutMin = amount * numerator * 85 / (denominator * 100);

        if (address(token) == address(Const.NATIVE_ASSET)) {
            USDTAmt = _swapETH(address(USDT), amount, amountOutMin);
        } else if (address(token) == address(SWAP_BASE_TOKEN)) {
            USDTAmt = _swap(address(token), address(USDT), amount, amountOutMin);
        } else{
            USDTAmt = _swap2(address(token), address(USDT), amount, amountOutMin);
        }
    }

    function _swap(address _tokenA, address _tokenB, uint _amt, uint _minAmount) private returns (uint) {
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;
        return (router.swapExactTokensForTokens(_amt, _minAmount, path, address(this), block.timestamp))[1];
    }

    function _swap2(address _tokenA, address _tokenB, uint _amt, uint _minAmount) private returns (uint) {
        address[] memory path = new address[](3);
        path[0] = _tokenA;
        path[1] = address(SWAP_BASE_TOKEN);
        path[2] = _tokenB;
        return (router.swapExactTokensForTokens(_amt, _minAmount, path, address(this), block.timestamp))[2];
    }

    function _swapETH(address _tokenB, uint _amt, uint _minAmount) internal virtual returns (uint) {
        address[] memory path = new address[](2);
        path[0] = address(SWAP_BASE_TOKEN);
        path[1] = _tokenB;
        return (router.swapExactETHForTokens{value: _amt}(_minAmount, path, address(this), block.timestamp))[1];
    }

    function _swapForETH(address _tokenA, uint _amt, uint _minAmount) internal virtual returns (uint) {
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = address(SWAP_BASE_TOKEN);
        return (router.swapExactTokensForETH(_amt, _minAmount, path, address(this), block.timestamp))[1];
    }

    function emergencyWithdraw() external onlyVault {
        _pause();
        // 1e18 == 100% of share
        uint USDTAmt = _withdraw(address(this), 1e18);
        if (USDTAmt > 0) {
            USDT.safeTransfer(vault, USDTAmt);
        }
        emit EmergencyWithdraw(USDTAmt);
    }

    function claimEmergencyWithdrawal() external onlyVault {
        _claimAllAndTransfer(address(this));
    }

    function getEmergencyWithdrawalUnbonded() public view returns (
        uint waitingInUSD, uint unbondedInUSD, uint waitForTs
    ) {
        return _getAllUnbonded(address(this));
    }

    /// @param _USDTAmts amounts of USDT should be deposited to each pools. They have been denominated in USDT decimals
    function reinvest(address[] memory _tokens, uint[] memory _USDTAmts) external onlyVault {
        _unpause();
        _investInternal(_tokens, _USDTAmts);
    }

    function addReqId(address _token, address _claimer, uint _reqId) internal {
        uint[] storage reqIds = claimer2ReqIds[_token][_claimer];

        reqIds.push(_reqId);
        reqId2Index[_token][_reqId] = reqIds.length - 1;
    }

    function removeReqId(address _token, address _claimer, uint _reqId) internal {
        uint[] storage reqIds = claimer2ReqIds[_token][_claimer];
        uint length = reqIds.length;
        uint reqIdIndex = reqId2Index[_token][_reqId];

        if (reqIdIndex != length-1) {
            uint256 lastReqId = reqIds[length - 1];
            reqIds[reqIdIndex] = lastReqId;
            reqId2Index[_token][lastReqId] = reqIdIndex;
        }

        reqIds.pop();
        delete reqId2Index[_token][_reqId];
    }

    function removeReqIds(address _token, address _claimer, uint[] memory _reqIds) internal {
        uint[] storage reqIds = claimer2ReqIds[_token][_claimer];
        uint length = reqIds.length;

        for (uint i = 0; i < _reqIds.length; i++) {
            uint reqId = _reqIds[i];
            uint reqIdIndex = reqId2Index[_token][reqId];

            if (reqIdIndex != length-1) {
                uint256 lastReqId = reqIds[length - 1];
                reqIds[reqIdIndex] = lastReqId;
                reqId2Index[_token][lastReqId] = reqIdIndex;
            }

            reqIds.pop();
            length --;
            delete reqId2Index[_token][reqId];
        }
    }

    function getStVault(address _token) internal view virtual returns (IStVault stVault) {
    }

    ///@return waiting is token amount that is not unbonded.
    ///@return waitingInUSD is USD value of token amount that is not unbonded.
    ///@return unbonded is token amount that is unbonded.
    ///@return unbondedInUSD is USD value of token amount that is unbonded.
    ///@return waitForTs is timestamp to wait to the next claim.
    function getPoolUnbonded(address _claimer, uint _pid) public view returns (
        uint waiting, uint waitingInUSD,
        uint unbonded, uint unbondedInUSD,
        uint waitForTs
    ) {
        if (_pid < tokens.length) {
            address token = tokens[_pid];
            IStVault stVault = getStVault(token);
            if (address(stVault) != address(0)) {
                uint[] memory reqIds = claimer2ReqIds[token][_claimer];

                for (uint i = 0; i < reqIds.length; i ++) {
                    uint reqId = reqIds[i];
                    (bool _claimable, uint _tokenAmt,,, uint _waitForTs) = stVault.getWithdrawRequest(reqId);

                    if (_claimable) {
                        unbonded += _tokenAmt;
                    } else {
                        waiting += _tokenAmt;
                        if (waitForTs == 0 || waitForTs > _waitForTs) waitForTs = _waitForTs;
                    }
                }

                if (waiting > 0) waitingInUSD = getValueInUSD(token, waiting);
                if (unbonded > 0) unbondedInUSD = getValueInUSD(token, unbonded);
            }
        }
    }

    function getPoolsUnbonded(address _claimer) external view returns (
        address[] memory,
        uint[] memory waitings,
        uint[] memory waitingInUSDs,
        uint[] memory unbondeds,
        uint[] memory unbondedInUSDs,
        uint[] memory waitForTses
    ) {
        uint poolCnt = tokens.length;
        waitings = new uint[](poolCnt);
        waitingInUSDs = new uint[](poolCnt);
        unbondeds = new uint[](poolCnt);
        unbondedInUSDs = new uint[](poolCnt);
        waitForTses = new uint[](poolCnt);

        for (uint _pid = 0; _pid < poolCnt; _pid++) {
            (uint _waiting, uint _waitingInUSD, uint _unbonded, uint _unbondedInUSD, uint _waitForTs) = getPoolUnbonded(_claimer, _pid);
            waitings[_pid] = _waiting;
            waitingInUSDs[_pid] = _waitingInUSD;
            unbondeds[_pid] = _unbonded;
            unbondedInUSDs[_pid] = _unbondedInUSD;
            waitForTses[_pid] = _waitForTs;
        }
        return (tokens, waitings, waitingInUSDs, unbondeds, unbondedInUSDs, waitForTses);
    }

    function _getAllUnbonded(address _claimer) internal view returns (
        uint waitingInUSD, uint unbondedInUSD, uint waitForTs
    ) {
        uint poolCnt = tokens.length;
        for (uint _pid = 0; _pid < poolCnt; _pid ++) {
            (, uint _waitingInUSD,, uint _unbondedInUSD, uint _waitForTs) = getPoolUnbonded(_claimer, _pid);
            waitingInUSD += _waitingInUSD;
            unbondedInUSD += _unbondedInUSD;
            if (waitingInUSD > 0) {
                if (waitForTs == 0 || waitForTs > _waitForTs) {
                    waitForTs = _waitForTs;
                }
            }
        }
    }

    function getAllUnbonded(address _claimer) external view returns (
        uint waitingInUSD, uint unbondedInUSD, uint waitForTs
    ) {
        return _getAllUnbonded(_claimer);
    }

    function claim(address _claimer) external onlyVault returns (uint USDTAmt) {
        USDTAmt = _claimAllAndTransfer(_claimer);
    }

    function _claimAllAndTransfer(address _claimer) internal returns (uint USDTAmt) {
        // uint poolCnt = tokens.length;
        // for (uint _pid = 0; _pid < poolCnt; _pid ++) {
        //     USDTAmt += _claim(_claimer, _pid);
        // }
        // if (USDTAmt > 0) {
        //     USDT.safeTransfer(vault, USDTAmt);
        // }
    }

    function _claim(address _claimer, uint _pid) internal returns (uint USDTAmt) {
        address token = tokens[_pid];
        IStVault stVault = getStVault(token);
        if (address(stVault) != address(0)) {
            uint[] memory reqIds = claimer2ReqIds[token][_claimer];

            (uint amount, uint claimedCount, bool[] memory claimed) = stVault.claimMulti(reqIds);
            if (amount > 0) {
                uint[] memory claimedReqIds = new uint[](claimedCount);
                uint index;
                for (uint i = 0; i < reqIds.length; i ++) {
                    if (claimed[i]) {
                        claimedReqIds[index++] = reqIds[i];
                    }
                }
                removeReqIds(token, _claimer, claimedReqIds);

                USDTAmt = _swapForUSDT(address(token), amount);
                emit Claim(_claimer, token, amount, USDTAmt);
            }
        }
    }

    function _balanceOf(address _token, address _account) internal view returns (uint) {
        return (_token != Const.NATIVE_ASSET)
            ? IERC20Upgradeable(_token).balanceOf(_account)
            : _account.balance;
    }

    function _assetDecimals(address _asset) internal view returns (uint8 _decimals) {
        _decimals = (_asset == Const.NATIVE_ASSET) ? 18 : IERC20UpgradeableExt(_asset).decimals();
    }

    function setAdmin(address _admin) external onlyOwner {
        address oldAdmin = admin;
        admin = _admin;
        emit SetAdminWallet(oldAdmin, _admin);
    }

    function setVault(address _vault) external onlyOwner {
        require(vault == address(0), "Vault set");
        vault = _vault;
    }

    /// @return the price of USDT in USD.
    function getUSDTPriceInUSD() public view returns(uint, uint8) {
        return priceOracle.getAssetPrice(address(USDT));
    }

    function getEachPoolInUSD() public view returns (address[] memory, uint[] memory pools) {
        return (tokens, _getEachPoolInUSD());
    }

    function _getEachPoolInUSD() private view returns (uint[] memory pools) {
        uint poolCnt = tokens.length;
        pools = new uint[](poolCnt);
        for (uint i = 0; i < poolCnt; i ++) {
            pools[i] = _getPoolInUSD(i);
        }
    }

    function _getPoolInUSD(uint _pid) internal view virtual returns (uint pool) {
        pool = getValueInUSD(address(USDT), USDT.balanceOf(address(this)) / tokens.length);
        // address token = tokens[_pid];
        // IStVault stVault = getStVault(token);
        // if (address(stVault) != address(0)) {
        //     pool = getStVaultPoolInUSD(stVault);
        // } else {
        //     uint amount = _balanceOf(token, address(this));
        //     if (0 < amount) {
        //         pool = getValueInUSD(token, amount);
        //     }
        // }
    }

    function getStVaultPoolInUSD(IStVault _stVault) internal view returns (uint) {
        uint stVaultTotalSupply = _stVault.totalSupply();
        return stVaultTotalSupply == 0 ? 0 : _stVault.getAllPoolInUSD() * _stVault.balanceOf(address(this)) / stVaultTotalSupply;
    }

    ///@return the value in USD. it's scaled by 1e18;
    function getValueInUSD(address _asset, uint _amount) internal view returns (uint) {
        (uint priceInUSD, uint8 priceDecimals) = priceOracle.getAssetPrice(_asset);
        uint8 _decimals = _assetDecimals(_asset);
        return Token.changeDecimals(_amount, _decimals, 18) * priceInUSD / (10 ** (priceDecimals));
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint[] memory pools = _getEachPoolInUSD();
        uint poolCnt = pools.length;
        uint allPool;
        for (uint i = 0; i < poolCnt; i ++) {
            allPool += pools[i];
        }

        if (paused()) {
            (uint waitingInUSD, uint unbondedInUSD,) = getEmergencyWithdrawalUnbonded();
            allPool += (waitingInUSD + unbondedInUSD);
        }
        return allPool;
    }

    function getCurrentTokenCompositionPerc() public view returns (address[] memory, uint[] memory percentages) {
        uint[] memory pools = _getEachPoolInUSD();
        uint poolCnt = pools.length;
        uint allPool;
        for (uint i = 0; i < poolCnt; i ++) {
            allPool += pools[i];
        }

        uint defaultTargetPerc = poolCnt == 0 ? 0 : Const.DENOMINATOR / poolCnt;
        percentages = new uint[](poolCnt);
        for (uint i = 0; i < poolCnt; i ++) {
            percentages[i] = allPool == 0 ? defaultTargetPerc : pools[i] * Const.DENOMINATOR / allPool;
        }
        return (tokens, percentages);
    }

    function getAPR() public view virtual returns (uint) {
        (address[] memory _tokens, uint[] memory perc) = getCurrentTokenCompositionPerc();
        uint allApr;
        uint poolCnt = _tokens.length;
        for (uint _pid = 0; _pid < poolCnt; _pid ++) {
            IStVault stVault = getStVault(tokens[_pid]);
            if (address(stVault) != address(0)) {
                allApr += stVault.getAPR() * perc[_pid];
            }
        }
        return (allApr / Const.DENOMINATOR);
    }

    receive() external payable {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[39] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

library EthConstantTest {
    uint internal constant CHAINID = 4;

    address internal constant MATIC = 0x7D1AfA7B718fb893dB30A3aBc0Cfc608AaCfeBB0; // Should be replaced with testnet address
    address internal constant stETH = 0xF4242f9d78DB7218Ad72Ee3aE14469DBDE8731eD;
    address internal constant stMATIC = 0x9ee91F9f426fA633d227f7a9b000E28b9dfd8599; // Should be replaced with testnet address
    address internal constant USDC = 0xDf5324ebe6F6b852Ff5cBf73627eE137e9075276;
    address internal constant USDT = 0x21e48034753E490ff04f2f75f7CAEdF081B320d5;
    address internal constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IStVault is IERC20Upgradeable {

    struct WithdrawRequest {
        uint tokenAmt;
        uint stTokenAmt;
        uint requestTs;
    }

    // fee percentage that treasury takes from rewards.
    function yieldFee() external view returns(uint);
    // treasury wallet address.
    function treasuryWallet() external view returns(address);
    // administrator address.
    function admin() external view returns(address);

    // underlying token such as ETH, WMATIC, and so on.
    function token() external view returns(IERC20Upgradeable);
    // staked token such as stETH, stMATIC, and so on.
    function stToken() external view returns(IERC20Upgradeable);

    // the buffered deposit token amount that is not yet staked into the staking pool.
    function bufferedDeposits() external view returns(uint);
    // On some staking pools, the rewards are accumulated until unbonded even though redeem is requested. This function considers it.
    function getBufferedDeposits() external view returns(uint);
    // the buffered withdrawal token amount that is unstaked from the staking pool but not yet withdrawn from the user.
    function bufferedWithdrawals() external view returns(uint);
    // the token amount that shares is already burnt but not withdrawn.
    function pendingWithdrawals() external view returns(uint);
    // the total amount of withdrawal stToken that is not yet requested to the staking pool.
    function pendingRedeems() external view returns(uint);
    // the amount of stToken that is emergency unbonding, and shares according to them are not burnt yet.
    function getEmergencyUnbondings() external view returns(uint);
    // the amount of stToken that has invested into L2 vaults to get extra benefit.
    function getInvestedStTokens() external view returns(uint);
    
    // the seconds to wait for unbonded since withdarwal requested. For example, 30 days in case of unstaking stDOT to get xcDOT
    function unbondingPeriod() external view returns(uint);
    // the minimum amount of token to invest.
    function minInvestAmount() external view returns(uint);
    // the minimum amount of stToken to redeem.
    function minRedeemAmount() external view returns(uint);

    // the timestamp that the last investment was executed on.
    function lastInvestTs() external view returns(uint);
    // minimum seconds to wait before next investment. For example, MetaPool's stNEAR buffer is replenished every 5 minutes.
    function investInterval() external view returns(uint);
    // the timestamp that the last redeem was requested on.
    function lastRedeemTs() external view returns(uint);
    // minimum seconds to wait before next redeem. For example, Lido have up to 20 redeem requests to stDOT in parallel. Therefore, the next redeem should be requested after about 1 day.
    function redeemInterval() external view returns(uint);
    // the timestamp that the profit last collected on.
    function lastCollectProfitTs() external view returns(uint);
    // the timestamp of one epoch. Each epoch, the stToken price or balance will increase as staking-rewards are added to the pool.
    function oneEpoch() external view returns(uint);

    ///@return the total amount of tokens in the vault.
    function getAllPool() external view returns (uint);
    ///@return the amount of shares that corresponds to `_amount` of token.
    function getSharesByPool(uint _amount) external view returns (uint);
    ///@return the amount of token that corresponds to `_shares` of shares.
    function getPoolByShares(uint _shares) external view returns (uint);
    ///@return the total USD value of tokens in the vault.
    function getAllPoolInUSD() external view returns (uint);
    ///@return the USD value of rewards that is avilable to claim. It's scaled by 1e18.
    function getPendingRewards() external view returns (uint);
    ///@return the APR in the vault. It's scaled by 1e18.
    function getAPR() external view returns (uint);
    ///@return _claimable specifys whether user can claim tokens for it.
    ///@return _tokenAmt is amount of token to claim.
    ///@return _stTokenAmt is amount of stToken to redeem.
    ///@return _requestTs is timestmap when withdrawal requested.
    ///@return _waitForTs is timestamp to wait for.
    function getWithdrawRequest(uint _reqId) external view returns (
        bool _claimable,
        uint _tokenAmt, uint _stTokenAmt,
        uint _requestTs, uint _waitForTs
    );
    ///@return the unbonded token amount that is claimable from the staking pool.
    function getTokenUnbonded() external view returns (uint);

    ///@dev deposit `_amount` of token.
    function deposit(uint _amount) external;
    ///@dev deposit the native asset.
    function depositETH() external payable;
    ///@dev request a withdrawal that corresponds to `_shares` of shares.
    ///@return _amount is the amount of withdrawn token.
    ///@return _reqId is the NFT token id indicating the request for rest of withdrawal. 0 if no request is made.
    function withdraw(uint _shares) external returns (uint _amount, uint _reqId);
    ///@dev claim token with NFT token
    ///@return _amount is the amount of claimed token.
    function claim(uint _reqId) external returns (uint _amount);
    ///@dev claim token with NFT tokens
    ///@return _amount is the amount of claimed token.
    ///@return _claimedCount is the count of reqIds that are claimed.
    ///@return _claimed is the flag indicating whether the token is claimed.
    function claimMulti(uint[] memory _reqIds) external returns (uint _amount, uint _claimedCount, bool[] memory _claimed);
    ///@dev stake the buffered deposits into the staking pool. It's called by admin.
    function invest() external;
    ///@dev redeem the requested withdrawals from the staking pool. It's called by admin.
    function redeem() external;
    ///@dev claim the unbonded tokens from the staking pool. It's called by admin.
    function claimUnbonded() external;
    ///@dev request a withdrawal for all staked tokens. It's called by admin.
    function emergencyWithdraw() external;
    ///@dev the total amount of emergency withdrawal stToken that is not yet requested to the staking pool.
    function emergencyPendingRedeems() external view returns (uint _redeems);
    ///@dev In emergency mode, redeem the rest of stTokens. Especially it's needed for stNEAR because the MetaPool has a buffer limit.
    function emergencyRedeem() external;
    ///@dev reinvest the tokens, and set the vault status as normal. It's called by admin.
    function reinvest() external;
    ///@dev take rewards and reinvest them. It's called by admin.
    function yield() external;
    ///@dev collect profit and update the watermark
    function collectProfitAndUpdateWatermark() external;
    ///@dev transfer out fees.
    function withdrawFees() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Const {

    uint internal constant DENOMINATOR = 10000;

    uint internal constant APR_SCALE = 1e18;
    
    uint internal constant YEAR_IN_SEC = 365 days;

    address internal constant NATIVE_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

interface IPriceOracle {

    /**
     * @notice Sets or replaces price sources of assets
     * @param assets The addresses of the assets
     * @param sources The addresses of the price sources
     */
    function setAssetSources(address[] memory assets, address[] memory sources) external;

    /**
     * @notice Returns the address of the source for an asset address
     * @param asset The address of the asset
     * @return The address of the source
     */
    function getSourceOfAsset(address asset) external view returns (address);

    /**
     * @notice Returns a list of prices from a list of assets addresses
     * @param assets The list of assets addresses
     * @return prices The prices of the given assets
     */
    function getAssetsPrices(address[] memory assets) external view returns (uint[] memory prices, uint8[] memory decimalsArray);

    /**
     * @notice Returns a list of prices from a list of assets addresses
     * @param asset The asset address
     * @return price The prices of the given assets
     */
    function getAssetPrice(address asset) external view returns (uint price, uint8 decimals);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20UpgradeableExt is IERC20Upgradeable {
    function decimals() external view returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

interface IUniRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity) ;

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Token {
    function changeDecimals(uint amount, uint curDecimals, uint newDecimals) internal pure returns(uint) {
        if (curDecimals == newDecimals) {
            return amount;
        } else if (curDecimals < newDecimals) {
            return amount * (10 ** (newDecimals - curDecimals));
        } else {
            return amount / (10 ** (curDecimals - newDecimals));
        }
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}