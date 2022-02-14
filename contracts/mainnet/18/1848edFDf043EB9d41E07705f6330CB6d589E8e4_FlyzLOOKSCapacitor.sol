// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './interfaces/IFlyzTreasury.sol';

import './types/Ownable.sol';
import './interfaces/IERC20.sol';

import './libraries/SafeMath.sol';
import './libraries/SafeERC20.sol';

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface ILooksStaking {
    function userInfo(address user) external view returns (uint256, uint256, uint256);
    function deposit(uint256 amount, bool claimRewardToken) external;
    function withdraw(uint256 shares, bool claimRewardToken) external;
    function withdrawAll(bool claimRewardToken) external;
    function harvest() external;
}

interface IFlyzWrappedLOOKS is IERC20 {
    function mintTo(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

contract FlyzLOOKSCapacitor is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bool public autoStake;
    bool public autoHarvest;

    address public immutable flyz;
    address public immutable flyzLP;
    address public immutable weth;
    address public immutable looks;
    address public immutable looksLP;
    address public immutable looksStaking;
    address public immutable wrappedLooks;
    address public immutable treasury;
    address public immutable swapRouter;

    mapping(address => bool) private _depositors;

    event DepositorAdded(address indexed depositor);
    event DepositorRemoved(address indexed depositor);

    modifier onlyOnwerOrDepositor() {
        require(msg.sender == owner() || _depositors[msg.sender], "Capacitor: Not owner or depositor");
        _;
    }

    constructor(
        address _flyz,
        address _looks,
        address _looksStaking,
        address _wrappedLooks,
        address _treasury,
        address _router
    ) {
        flyz = _flyz;
        looks = _looks;
        wrappedLooks = _wrappedLooks;
        looksStaking = _looksStaking;
        treasury = _treasury;
        autoStake = true;

        IUniswapV2Router02 _swapRouter = IUniswapV2Router02(_router);
        IUniswapV2Factory _factory = IUniswapV2Factory(_swapRouter.factory());
        address _weth = _swapRouter.WETH();
        address _flyzLP = _factory.getPair(_flyz, _weth);
        address _looksLP = _factory.getPair(_looks, _weth);

        swapRouter = _router;
        weth = _weth;
        flyzLP = _flyzLP;
        looksLP = _looksLP;

        IERC20(_looks).approve(_looksStaking,  uint256(-1));
        IERC20(_looks).approve(_router,  uint256(-1));
        IERC20(_flyz).approve(_router,  uint256(-1));
        IERC20(_weth).approve(_router,  uint256(-1));
        IERC20(_flyz).approve(_treasury,  uint256(-1));
        IERC20(_flyzLP).approve(_treasury,  uint256(-1));
        IERC20(_looks).approve(_treasury,  uint256(-1));
        IERC20(_wrappedLooks).approve(_treasury,  uint256(-1));
    }

    /**
     * @notice returns the pending rewards in LOOKS staking contract
     */
    function getStakingInfos() public view returns (uint256 shares, uint256 userRewardPerTokenPaid, uint256 rewards) {
        (shares, userRewardPerTokenPaid, rewards) = ILooksStaking(looksStaking).userInfo(address(this));
    }

    /**
     * @notice Stake LOOKS tokens (and collect reward tokens if requested)
     * @param amount amount of LOOKS to stake
     * @param claimRewardToken whether to claim reward tokens
     */
    function _stake(uint256 amount, bool claimRewardToken) internal {
        require(amount <= IERC20(looks).balanceOf(address(this)), "Capacitor: over balance");
        ILooksStaking(looksStaking).deposit(amount, claimRewardToken);
    }

    /**
     * @notice Stake LOOKS tokens (and collect reward tokens if requested)
     * @param amount amount of LOOKS to stake
     * @param claimRewardToken whether to claim reward tokens
     */
    function stake(uint256 amount, bool claimRewardToken) external onlyOnwerOrDepositor {
        _stake(amount, claimRewardToken);
    }

    /**
     * @notice Stake all LOOKS tokens (and collect reward tokens if requested)
     * @param claimRewardToken whether to claim reward tokens
     */
    function stakeAll(bool claimRewardToken) external onlyOnwerOrDepositor {
        _stake(IERC20(looks).balanceOf(address(this)), claimRewardToken);
    }

    /**
     * @notice Unstake LOOKS tokens (and collect reward tokens if requested)
     * @param shares shares to withdraw
     * @param claimRewardToken whether to claim reward tokens
     */
    function unstake(uint256 shares, bool claimRewardToken) external onlyOnwerOrDepositor {
        require(shares > 0, "Capacitor: Invalid shares");
        ILooksStaking(looksStaking).withdraw(shares, claimRewardToken);
    }

    /**
     * @notice Unstake all LOOKS tokens (and collect reward tokens if requested)
     * @param claimRewardToken whether to claim reward tokens
     */
    function unstakeAll(bool claimRewardToken) external onlyOnwerOrDepositor {
        ILooksStaking(looksStaking).withdrawAll(claimRewardToken);
    }

    /**
     * @notice Harvest current pending rewards
     */
    function _harvest() internal {
        (, , uint256 rewards) = getStakingInfos();
        if (rewards > 0) {
            ILooksStaking(looksStaking).harvest();
        }
    }

    /**
     * @notice Harvest current pending rewards
     */
    function harvest() external onlyOnwerOrDepositor {
        _harvest();
    }

    /**
     * @notice Deposit LOOKS and send a receipt token to the treasury
     */
    function deposit(uint256 amount) external onlyOnwerOrDepositor {
        IERC20(looks).safeTransferFrom(msg.sender, address(this), amount);
        IFlyzWrappedLOOKS(wrappedLooks).mintTo(treasury, amount);

        if (autoStake) {
            _stake(amount, autoHarvest);
        }
        else if (autoHarvest) {
            _harvest();
        }
    }

    /**
     * @notice send a receipt token to the treasury (LOOKS are transfered first by the caller to the contract)
     * used by BondDepository to save gas
     */
    function depositReceipt(uint256 amount) external onlyOnwerOrDepositor {
        require(amount <= IERC20(looks).balanceOf(address(this)), "Capacitor: over balance");
        IFlyzWrappedLOOKS(wrappedLooks).mintTo(treasury, amount);

        if (autoStake) {
            _stake(amount, autoHarvest);
        }
        else if (autoHarvest) {
            _harvest();
        }
    }

    /**
     * @dev Swap helper function
     */
    function _swap(address pair, address token, uint256 amount, address to) internal returns (uint256) {
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        address otherToken = token0 == token ? token1 : token0;

        address[] memory path = new address[](2);
        path[0] = token0 == token ? token0 : token1;
        path[1] = otherToken;

        uint256 balance = IERC20(otherToken).balanceOf(address(this));
        IUniswapV2Router02(swapRouter).swapExactTokensForTokens(amount, 0, path, to, block.timestamp);
        uint256 newBalance = IERC20(otherToken).balanceOf(address(this));

        return newBalance - balance;
    }

    /**
     * @notice Swap LOOKS to WETH, swap WETH to FLYZ, add liquidity to FLYZ/WETH LP and send LP to treasury with 100% profit
     */
    function swapAndSendFlyzLPToTreasury(uint256 looksAmount) external onlyOnwerOrDepositor {
        // swap looks to weth
        if (looksAmount > 0) {
            require(looksAmount <= IERC20(looks).balanceOf(address(this)), "Capacitor: over LOOKS balance");
            _swap(looksLP, looks, looksAmount, address(this));
        }

        // buy back flyz
        uint256 wethAmount = IERC20(weth).balanceOf(address(this)).div(2);
        require(wethAmount > 0, "Capacitor: WETH balance is 0");
        uint256 flyzReceived = _swap(flyzLP, weth, wethAmount, address(this));

        // add liquidity to flyz LP
        IUniswapV2Router02(swapRouter).addLiquidity(flyz, weth, flyzReceived, wethAmount, 0, 0, address(this), block.timestamp);

        // add to the treasury with 100% profit
        uint256 lpAmount = IERC20(flyzLP).balanceOf(address(this));
        uint256 profit = IFlyzTreasury(treasury).valueOfToken(flyzLP, lpAmount);
        IFlyzTreasury(treasury).deposit(lpAmount, flyzLP, profit);
    }

    /**
     * @notice Withdraw LOOKS from treasury to this contract and replace with WRAPPED LOOKS
     */
    function receiveLooksFromTreasury(uint256 amount) external onlyOnwerOrDepositor {
        require(amount <= IERC20(looks).balanceOf(treasury), "Capacitor: over balance");

        // mint wrapped looks receipt
        IFlyzWrappedLOOKS(wrappedLooks).mintTo(address(this), amount);   
        // deposit wrapped looks receipt to treasury
        IFlyzTreasury(treasury).deposit(amount, wrappedLooks, 0);
        // withdraw looks from treasury
        IFlyzTreasury(treasury).withdraw(amount, looks);
    }

    /**
     * @notice Withdraw WRAPPED LOOKS from the treasury to this contract and replace with LOOKS
     * WRAPPED LOOKS are burned
     */
    function sendLooksToTreasury(uint256 amount) external onlyOnwerOrDepositor {
        require(amount <= IERC20(looks).balanceOf(address(this)), "Capacitor: over balance");
     
        // deposit looks to treasury
        IFlyzTreasury(treasury).deposit(amount, looks, 0);
        // withdraw wrapped looks from treasury
        IFlyzTreasury(treasury).withdraw(amount, wrappedLooks);
        // burn wrapped looks receipt
        IFlyzWrappedLOOKS(wrappedLooks).burn(amount);
    }

    /**
     * @notice Auto stake LOOKS on deposits
     */
    function setAutoStake(bool enable) external onlyOwner {
        autoStake = enable;
    }

    /**
     * @notice Auto harvest rewards on deposits
     */
    function setAutoHarvest(bool enable) external onlyOwner {
        autoHarvest = enable;
    }

    /**
     * @notice Returns `true` if `account` is a member of deposit group
     */
    function isDepositor(address account) public view returns(bool) {
        return _depositors[account];
    }

    /**
     * @notice Add `depositor` to the list of addresses allowed to call `deposit()`  
     */
    function addDepositor(address depositor) external onlyOwner {
        require(depositor != address(0), "Capacitor: invalid address(0)");
        require(!_depositors[depositor], "Capacitor: already depositor");
        _depositors[depositor] = true;
        emit DepositorAdded(depositor);
    }

    /**
     * @notice Remove `depositor` from the list of addresses allowed to call `deposit()`  
     */
    function removeDepositor(address depositor) external onlyOwner {
        require(_depositors[depositor], "Capacitor: not depositor");
        _depositors[depositor] = false;
        emit DepositorRemoved(depositor);
    }

    /**
     * @notice Recover tokens sent to this contract by mistake
     */
    function recoverLostToken(address _token, uint256 amount) external onlyOwner returns (bool) {
        require(amount <= IERC20(_token).balanceOf(address(this)), "Capacitor: over token balance");
        IERC20(_token).safeTransfer(
            msg.sender,
            amount
        );
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IFlyzTreasury {
    function excessReserves() external view returns (uint256);

    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256 sent_);

    function valueOfToken(address _token, uint256 _amount)
        external
        view
        returns (uint256 value_);

    function mintRewards(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function withdraw(uint256 _amount, address _token) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
    function owner() external view returns (address);

    function renounceManagement() external;

    function pushManagement(address newOwner_) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OwnershipPulled(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipPushed(address(0), _owner);
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function renounceManagement() public virtual override onlyOwner {
        emit OwnershipPushed(_owner, address(0));
        _owner = address(0);
    }

    function pushManagement(address newOwner_)
        public
        virtual
        override
        onlyOwner
    {
        require(
            newOwner_ != address(0),
            'Ownable: new owner is the zero address'
        );
        emit OwnershipPushed(_owner, newOwner_);
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require(msg.sender == _newOwner, 'Ownable: must be new owner to pull');
        emit OwnershipPulled(_owner, _newOwner);
        _owner = _newOwner;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

interface IERC20Mintable {
    function mint(uint256 amount_) external;

    function mint(address account_, uint256 ammount_) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
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
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '../interfaces/IERC20.sol';

import './SafeMath.sol';
import './Counters.sol';
import './Address.sol';

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeERC20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeERC20: decreased allowance below zero'
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            'SafeERC20: low-level call failed'
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                'SafeERC20: ERC20 operation did not succeed'
            );
        }
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './SafeMath.sol';

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            'Address: insufficient balance'
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(
            success,
            'Address: unable to send value, recipient may have reverted'
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'Address: low-level call with value failed'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'Address: insufficient balance for call'
        );
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                'Address: low-level static call failed'
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), 'Address: static call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                'Address: low-level delegate call failed'
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), 'Address: delegate call to non-contract');

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function addressToString(address _address)
        internal
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = '0123456789abcdef';
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}