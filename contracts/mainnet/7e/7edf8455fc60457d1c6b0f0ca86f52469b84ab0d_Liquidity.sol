// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./IERC20.sol";
import "./IUniswapV2Router.sol";
import "./IUniswapV2Pair.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./OwnedInitializable.sol";
import "./IWETH.sol";

struct Deposit {
    uint256 balance;
    uint256 withdrawnBalance;
    uint48 timestamp;
    bool locked;
}

contract Liquidity is OwnedInitializable, ReentrancyGuardUpgradeable {
    IUniswapV2Router private constant router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    IUniswapV2Pair public uniswapPair;
    IERC20 public token;
    address private _WETH;
    address private _token0;
    address private _token1;

    mapping(address => uint256) public nonces;
    mapping(address => mapping(uint256 => Deposit)) public deposits;

    uint256 public lockPeriod;
    uint256 public vestingPeriod;

    event ProvidedLiquidity(address indexed user, bool indexed locked, uint256 tokenId, uint256 amountLiquidity);
    event Withdraw(address indexed user, bool indexed locked, uint256 tokenId, uint256 amountLiquidity);
    event LockPeriodUpdated(uint256 oldValue, uint256 newValue);
    event VestingPeriodUpdated(uint256 oldValue, uint256 newValue);

    function initialize(address _token, address _uniswapPair) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        token = IERC20(_token);
        uniswapPair = IUniswapV2Pair(_uniswapPair);
        _WETH = router.WETH();
        (_token0, _token1) = (_WETH < _token ? (_WETH, _token) : (_token, _WETH));
        lockPeriod = 26 weeks;
        vestingPeriod = lockPeriod * 2;
    }

    /// @notice provides liquidity with uniswap
    /// @dev    ETH half is provided by user, token half is provided by the smart contract
    /// @dev    each deposit is stored with new id
    /// @param  _lock if true, lock total token amount for `lockPeriod` amount of time, else linearly vest amount for `vestingPeriod` amount of time
    function provideLiquidity(bool _lock) external payable nonReentrant {
        uint256 amountETH = msg.value;
        uint256 nonce = nonces[_msgSender()];
        nonces[_msgSender()]++;
        uint256 liquidityMinted = _provideLiquidity(amountETH);
        Deposit memory newDeposit = Deposit({
            balance: liquidityMinted,
            withdrawnBalance: 0,
            timestamp: uint48(block.timestamp),
            locked: _lock
        });
        deposits[_msgSender()][nonce] = newDeposit;
        emit ProvidedLiquidity(_msgSender(), _lock, nonce, liquidityMinted);
    }

    /// @notice allows to withdraw unlocked tokens
    /// @dev    for locked tokens allows full withdrawal after lock period is over
    /// @dev    for vested tokens allows to withdraw partial unlocked amount
    /// @param  _id deposit id to withdraw
    function withdraw(uint256 _id) external nonReentrant {
        Deposit storage deposit = deposits[_msgSender()][_id];
        require(nonces[_msgSender()] > _id, "Liquidity: No deposit found for provided id");
        uint256 tokensToWithdraw = _withdrawableBalance(deposit);
        require(tokensToWithdraw > 0, "Liquidity: No unlocked tokens to withdraw for provided id");
        deposit.withdrawnBalance += tokensToWithdraw;
        assert(uniswapPair.transfer(_msgSender(), tokensToWithdraw));
        emit Withdraw(_msgSender(), deposit.locked, _id, tokensToWithdraw);
    }

    /// @notice sets new duration of lock period
    /// @dev only callable by owner
    /// @param _newPeriod new period duration in seconds
    function setLockPeriod(uint256 _newPeriod) external onlyOwner {
        emit LockPeriodUpdated(lockPeriod, _newPeriod);
        lockPeriod = _newPeriod;
    }

    /// @notice sets new duration of vesting period
    /// @dev only callable by owner
    /// @param _newPeriod new period duration in seconds
    function setVestingPeriod(uint256 _newPeriod) external onlyOwner {
        emit VestingPeriodUpdated(vestingPeriod, _newPeriod);
        vestingPeriod = _newPeriod;
    }

    /// @dev returns deposited balance for a specific account and token id
    function depositedBalance(address _account, uint256 _id) external view returns (uint256) {
        if (_id >= nonces[_account]) {
            return 0;
        }
        return deposits[_account][_id].balance;
    }

    /// @dev returns withdrawable balance for a specific account and token id
    function withdrawableBalance(address _account, uint256 _id) external view returns (uint256) {
        Deposit memory deposit = deposits[_account][_id];
        return _withdrawableBalance(deposit);
    }

    function _provideLiquidity(uint256 _amountETH) private returns (uint256 liquidityMinted) {
        require(_amountETH > 0, "Liquidity: No ETH provided");
        (uint256 reserve0, uint256 reserve1, ) = uniswapPair.getReserves();
        assert(reserve0 > 0 && reserve1 > 0);
        (uint256 reserveA, uint256 reserveB) = address(token) == _token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 amountToken = (_amountETH * (reserveA)) / reserveB;
        require(amountToken <= token.balanceOf(address(this)), "Liquidity: Insufficient token amount in contract");
        assert(token.transfer(address(uniswapPair), amountToken));
        IWETH weth = IWETH(_WETH);
        weth.deposit{value: _amountETH}();
        assert(weth.transfer(address(uniswapPair), _amountETH));
        liquidityMinted = uniswapPair.mint(address(this));
    }

    function _withdrawableBalance(Deposit memory _deposit) private view returns (uint256) {
        if (_deposit.locked) {
            return
                _deposit.timestamp + lockPeriod <= block.timestamp ? _deposit.balance - _deposit.withdrawnBalance : 0;
        } else {
            uint256 amountTokensLocked = 0;
            if (_deposit.timestamp + vestingPeriod > block.timestamp) {
                amountTokensLocked =
                    _deposit.balance -
                    ((_deposit.balance * (block.timestamp - _deposit.timestamp)) / vestingPeriod);
            }
            return _deposit.balance - amountTokensLocked - _deposit.withdrawnBalance;
        }
    }
}