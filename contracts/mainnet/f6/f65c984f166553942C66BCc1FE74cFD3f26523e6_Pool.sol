// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "./LPToken.sol";
import "../libs/MathUtils.sol";
import "../access/Ownable.sol";
import "./interfaces/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Pool is IPool, Ownable {
    using SafeERC20 for IERC20;
    using MathUtils for uint256;


    uint256 public initialA;
    uint256 public futureA;
    uint256 public initialATime;
    uint256 public futureATime;

    uint256 public swapFee;
    uint256 public adminFee;

    LPToken public lpToken;

    IERC20[] public coins;
    mapping(address => uint8) private coinIndexes;
    uint256[] tokenPrecisionMultipliers;

    uint256[] public balances;


    event TokenSwap(
        address indexed buyer,
        uint256 tokensSold,
        uint256 tokensBought,
        uint128 soldId,
        uint128 boughtId
    );

    event AddLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );

    event RemoveLiquidity(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256 lpTokenSupply
    );

    event RemoveLiquidityOne(
        address indexed provider,
        uint256 lpTokenAmount,
        uint256 lpTokenSupply,
        uint256 boughtId,
        uint256 tokensBought
    );

    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[] tokenAmounts,
        uint256[] fees,
        uint256 invariant,
        uint256 lpTokenSupply
    );

    event NewSwapFee(uint256 newSwapFee);
    event NewAdminFee(uint256 newAdminFee);

    event RampA(uint256 oldA, uint256 newA, uint256 initialTime, uint256 futureTime);
    event StopRampA(uint256 currentA, uint256 time);


    struct CalculateWithdrawOneTokenDYInfo {
        uint256 d0;
        uint256 d1;
        uint256 newY;
        uint256 feePerToken;
        uint256 preciseA;
    }

    struct AddLiquidityInfo {
        uint256 d0;
        uint256 d1;
        uint256 d2;
        uint256 preciseA;
    }

    struct RemoveLiquidityImbalanceInfo {
        uint256 d0;
        uint256 d1;
        uint256 d2;
        uint256 preciseA;
    }

    uint256 private constant FEE_DENOMINATOR = 10**10;

    // feeAmount = amount * fee / FEE_DENOMINATOR, 1% max.
    uint256 private constant MAX_SWAP_FEE = 10**8;

    // Percentage of swap fee. E.g. 5*1e9 = 50%
    uint256 public constant MAX_ADMIN_FEE = 10**10;

    uint256 private constant MAX_LOOP_LIMIT = 256;

    uint256 public constant A_PRECISION = 100;
    uint256 public constant MAX_A = 10**6;
    uint256 private constant MAX_A_CHANGE = 10;
    uint256 private constant MIN_RAMP_TIME = 1 days;

    constructor(
        IERC20[] memory _coins,
        uint8[] memory decimals,
        string memory lpTokenName,
        string memory lpTokenSymbol,
        uint256 _a,
        uint256 _swapFee,
        uint256 _adminFee
    ) {
        require(_coins.length >= 2, "O3SwapPool: coins.length out of range(<2)");
        require(_coins.length <= 8, "O3SwapPool: coins.length out of range(>8");
        require(_coins.length == decimals.length, "O3SwapPool: invalid decimals length");

        uint256[] memory precisionMultipliers = new uint256[](decimals.length);

        for (uint8 i = 0; i < _coins.length; i++) {
            require(address(_coins[i]) != address(0), "O3SwapPool: token address cannot be zero");
            require(decimals[i] <= 18, "O3SwapPool: token decimal exceeds maximum");

            if (i > 0) {
                require(coinIndexes[address(_coins[i])] == 0 && _coins[0] != _coins[i], "O3SwapPool: duplicated token pooled");
            }

            precisionMultipliers[i] = 10 ** (18 - uint256(decimals[i]));
            coinIndexes[address(_coins[i])] = i;
        }

        require(_a < MAX_A, "O3SwapPool: _a exceeds maximum");
        require(_swapFee <= MAX_SWAP_FEE, "O3SwapPool: _swapFee exceeds maximum");
        require(_adminFee <= MAX_ADMIN_FEE, "O3SwapPool: _adminFee exceeds maximum");

        coins = _coins;
        lpToken = new LPToken(lpTokenName, lpTokenSymbol);
        tokenPrecisionMultipliers = precisionMultipliers;
        balances = new uint256[](_coins.length);
        initialA = _a * A_PRECISION;
        futureA = _a * A_PRECISION;
        initialATime = 0;
        futureATime = 0;
        swapFee = _swapFee;
        adminFee = _adminFee;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'O3SwapPool: EXPIRED');
        _;
    }

    function getTokenIndex(address token) external view returns (uint8) {
        uint8 index = coinIndexes[token];
        require(address(coins[index]) == token, "O3SwapPool: TOKEN_NOT_POOLED");
        return index;
    }

    function getA() external view returns (uint256) {
        return _getA();
    }

    function _getA() internal view returns (uint256) {
        return _getAPrecise() / A_PRECISION;
    }

    function _getAPrecise() internal view returns (uint256) {
        uint256 t1 = futureATime;
        uint256 a1 = futureA;

        if (block.timestamp < t1) {
            uint256 a0 = initialA;
            uint256 t0 = initialATime;
            if (a1 > a0) {
                return a0 + (a1 - a0) * (block.timestamp - t0) / (t1 - t0);
            } else {
                return a0 - (a0 - a1) * (block.timestamp - t0) / (t1 - t0);
            }
        } else {
            return a1;
        }
    }

    function getVirtualPrice() external view returns (uint256) {
        uint256 d = _getD(_xp(), _getAPrecise());
        uint256 totalSupply = lpToken.totalSupply();

        if (totalSupply == 0) {
            return 0;
        }

        return d * 10**18 / totalSupply;
    }

    function calculateWithdrawOneToken(uint256 tokenAmount, uint8 tokenIndex) external view returns (uint256 amount) {
        (amount, ) = _calculateWithdrawOneToken(tokenAmount, tokenIndex);
    }

    function _calculateWithdrawOneToken(uint256 tokenAmount, uint8 tokenIndex) internal view returns (uint256, uint256) {
        uint256 dy;
        uint256 newY;

        (dy, newY) = _calculateWithdrawOneTokenDY(tokenIndex, tokenAmount);
        uint256 dySwapFee = (_xp()[tokenIndex] - newY) / tokenPrecisionMultipliers[tokenIndex] - dy;

        return (dy, dySwapFee);
    }

    function _calculateWithdrawOneTokenDY(uint8 tokenIndex, uint256 tokenAmount) internal view returns (uint256, uint256) {
        require(tokenIndex < coins.length, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");

        CalculateWithdrawOneTokenDYInfo memory v = CalculateWithdrawOneTokenDYInfo(0, 0, 0, 0, 0);
        v.preciseA = _getAPrecise();
        v.feePerToken = _feePerToken();
        uint256[] memory xp = _xp();
        v.d0 = _getD(xp, v.preciseA);
        v.d1 = v.d0 - tokenAmount * v.d0 / lpToken.totalSupply();

        require(tokenAmount <= xp[tokenIndex], "O3SwapPool: WITHDRAW_AMOUNT_EXCEEDS_AVAILABLE");

        v.newY = _getYD(v.preciseA, tokenIndex, xp, v.d1);

        uint256[] memory xpReduced = new uint256[](xp.length);

        for (uint256 i = 0; i < coins.length; i++) {
            uint256 xpi = xp[i];

            xpReduced[i] = xpi - (
                ((i == tokenIndex) ? xpi * v.d1 / v.d0 - v.newY : xpi - xpi * v.d1 / v.d0)
                * v.feePerToken / FEE_DENOMINATOR
            );
        }

        uint256 dy = xpReduced[tokenIndex] - _getYD(v.preciseA, tokenIndex, xpReduced, v.d1);
        dy = (dy - 1) / tokenPrecisionMultipliers[tokenIndex];

        return (dy, v.newY);
    }

    function _getYD(uint256 a, uint8 tokenIndex, uint256[] memory xp, uint256 d) internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        require(tokenIndex < numTokens, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");

        uint256 c = d;
        uint256 s;
        uint256 nA = a * numTokens;

        for (uint256 i = 0; i < numTokens; i++) {
            if (i != tokenIndex) {
                s = s + xp[i];
                c = c * d / (xp[i] * numTokens);
            }
        }

        c = c * d * A_PRECISION / (nA * numTokens);

        uint256 b = s + d * A_PRECISION / nA;
        uint256 yPrev;
        uint256 y = d;
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = (y*y + c) / (2 * y + b - d);
            if (y.within1(yPrev)) {
                return y;
            }
        }

        revert("Approximation did not converge");
    }

    function _getD(uint256[] memory xp, uint256 a) internal pure returns (uint256) {
        uint256 numTokens = xp.length;
        uint256 s;

        for (uint256 i = 0; i < numTokens; i++) {
            s = s + xp[i];
        }

        if (s == 0) {
            return 0;
        }

        uint256 prevD;
        uint256 d = s;
        uint256 nA = a * numTokens;

        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            uint256 dP = d;
            for (uint256 j = 0; j < numTokens; j++) {
                dP = dP * d / (xp[j] * numTokens);
            }
            prevD = d;
            d = (nA * s / A_PRECISION + dP * numTokens) * d / ((nA - A_PRECISION) * d / A_PRECISION + (numTokens + 1) * dP);
            if (d.within1(prevD)) {
                return d;
            }
        }

        revert("D did not converge");
    }

    function _getD() internal view returns (uint256) {
        return _getD(_xp(), _getAPrecise());
    }

    function _xp(uint256[] memory _balances, uint256[] memory _precisionMultipliers) internal pure returns (uint256[] memory) {
        uint256 numTokens = _balances.length;
        require(numTokens == _precisionMultipliers.length, "O3SwapPool: BALANCES_MULTIPLIERS_LENGTH_MISMATCH");

        uint256[] memory xp = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            xp[i] = _balances[i] * _precisionMultipliers[i];
        }

        return xp;
    }

    function _xp(uint256[] memory _balances) internal view returns (uint256[] memory) {
        return _xp(_balances, tokenPrecisionMultipliers);
    }

    function _xp() internal view returns (uint256[] memory) {
        return _xp(balances, tokenPrecisionMultipliers);
    }

    function _getY(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 x, uint256[] memory xp) internal view returns (uint256) {
        uint256 numTokens = coins.length;

        require(tokenIndexFrom != tokenIndexTo, "O3SwapPool: DUPLICATED_TOKEN_INDEX");
        require(tokenIndexFrom < numTokens && tokenIndexTo < numTokens, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");

        uint256 a = _getAPrecise();
        uint256 d = _getD(xp, a);
        uint256 nA = numTokens * a;
        uint256 c = d;
        uint256 s;
        uint256 _x;

        for (uint256 i = 0; i < numTokens; i++) {
            if (i == tokenIndexFrom) {
                _x = x;
            } else if (i != tokenIndexTo) {
                _x = xp[i];
            } else {
                continue;
            }
            s += _x;
            c = c * d  / (_x * numTokens);
        }

        c = c * d * A_PRECISION / (nA * numTokens);
        uint256 b = s + d * A_PRECISION / nA;
        uint256 yPrev;
        uint256 y = d;

        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = (y * y + c) / (2 * y + b - d);
            if (y.within1(yPrev)) {
                return y;
            }
        }

        revert("Approximation did not converge");
    }

    function calculateSwap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx) external view returns (uint256 dy) {
        (dy, ) = _calculateSwap(tokenIndexFrom, tokenIndexTo, dx);
    }

    function _calculateSwap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx) internal view returns (uint256 dy, uint256 dyFee) {
        uint256[] memory xp = _xp();
        require(tokenIndexFrom < xp.length && tokenIndexTo < xp.length, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");

        uint256 x = xp[tokenIndexFrom] + dx * tokenPrecisionMultipliers[tokenIndexFrom];
        uint256 y = _getY(tokenIndexFrom, tokenIndexTo, x, xp);
        dy = xp[tokenIndexTo] - y - 1;
        dyFee = dy * swapFee / FEE_DENOMINATOR;
        dy = (dy - dyFee) / tokenPrecisionMultipliers[tokenIndexTo];
    }

    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory) {
        return _calculateRemoveLiquidity(amount);
    }

    function _calculateRemoveLiquidity(uint256 amount) internal view returns (uint256[] memory) {
        uint256 totalSupply = lpToken.totalSupply();
        require(amount <= totalSupply, "O3SwapPool: WITHDRAW_AMOUNT_EXCEEDS_AVAILABLE");

        uint256 numTokens = coins.length;
        uint256[] memory amounts = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; i++) {
            amounts[i] = balances[i] * amount / totalSupply;
        }

        return amounts;
    }

    function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256) {
        uint256 numTokens = coins.length;
        uint256 a = _getAPrecise();
        uint256[] memory _balances = balances;
        uint256 d0 = _getD(_xp(balances), a);

        for (uint256 i = 0; i < numTokens; i++) {
            if (deposit) {
                _balances[i] += amounts[i];
            } else {
                _balances[i] -= amounts[i];
            }
        }

        uint256 d1 = _getD(_xp(_balances), a);
        uint256 totalSupply = lpToken.totalSupply();

        if (deposit) {
            return (d1 - d0) * totalSupply / d0;
        } else {
            return (d0 - d1) * totalSupply / d0;
        }
    }

    function getAdminBalance(uint256 index) external view returns (uint256) {
        require(index < coins.length, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");
        return coins[index].balanceOf(address(this)) - balances[index];
    }

    function _feePerToken() internal view returns (uint256) {
        return swapFee * coins.length / (4 * (coins.length - 1));
    }

    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline) external ensure(deadline) returns (uint256) {
        require(dx <= coins[tokenIndexFrom].balanceOf(msg.sender), "O3SwapPool: INSUFFICIENT_BALANCE");

        uint256 balanceBefore = coins[tokenIndexFrom].balanceOf(address(this));
        coins[tokenIndexFrom].safeTransferFrom(msg.sender, address(this), dx);
        uint256 transferredDx = coins[tokenIndexFrom].balanceOf(address(this)) - balanceBefore;

        (uint256 dy, uint256 dyFee) = _calculateSwap(tokenIndexFrom, tokenIndexTo, transferredDx);
        require(dy >= minDy, "O3SwapPool: INSUFFICIENT_OUTPUT_AMOUNT");

        uint256 dyAdminFee = dyFee * adminFee / FEE_DENOMINATOR / tokenPrecisionMultipliers[tokenIndexTo];

        balances[tokenIndexFrom] += transferredDx;
        balances[tokenIndexTo] -= dy + dyAdminFee;

        coins[tokenIndexTo].safeTransfer(msg.sender, dy);

        emit TokenSwap(msg.sender, transferredDx, dy, tokenIndexFrom, tokenIndexTo);

        return dy;
    }

    function addLiquidity(uint256[] memory amounts, uint256 minToMint, uint256 deadline) external ensure(deadline) returns (uint256) {
        require(amounts.length == coins.length, "O3SwapPool: AMOUNTS_COINS_LENGTH_MISMATCH");

        uint256[] memory fees = new uint256[](coins.length);

        AddLiquidityInfo memory v = AddLiquidityInfo(0, 0, 0, 0);
        uint256 totalSupply = lpToken.totalSupply();

        if (totalSupply != 0) {
            v.d0 = _getD();
        }
        uint256[] memory newBalances = balances;

        for (uint256 i = 0; i < coins.length; i++) {
            // Initial deposit requires all coins
            require(totalSupply != 0 || amounts[i] > 0, "O3SwapPool: ALL_TOKENS_REQUIRED_IN_INITIAL_DEPOSIT");

            // Transfer tokens first to see if a fee was charged on transfer
            if (amounts[i] != 0) {
                uint256 beforeBalance = coins[i].balanceOf(address(this));
                coins[i].safeTransferFrom(msg.sender, address(this), amounts[i]);
                amounts[i] = coins[i].balanceOf(address(this)) - beforeBalance;
            }

            newBalances[i] = balances[i] + amounts[i];
        }

        v.preciseA = _getAPrecise();
        v.d1 = _getD(_xp(newBalances), v.preciseA);
        require(v.d1 > v.d0, "O3SwapPool: INVALID_OPERATION_D_MUST_INCREASE");

        // updated to reflect fees and calculate the user's LP tokens
        v.d2 = v.d1;
        if (totalSupply != 0) {
            uint256 feePerToken = _feePerToken();
            for (uint256 i = 0; i < coins.length; i++) {
                uint256 idealBalance = v.d1 * balances[i] / v.d0;
                fees[i] = feePerToken * idealBalance.difference(newBalances[i]) / FEE_DENOMINATOR;
                balances[i] = newBalances[i] - (fees[i] * adminFee / FEE_DENOMINATOR);
                newBalances[i] -= fees[i];
            }
            v.d2 = _getD(_xp(newBalances), v.preciseA);
        } else {
            balances = newBalances;
        }

        uint256 toMint;
        if (totalSupply == 0) {
            toMint = v.d1;
        } else {
            toMint = (v.d2 - v.d0) * totalSupply / v.d0;
        }

        require(toMint >= minToMint, "O3SwapPool: INSUFFICIENT_MINT_AMOUNT");

        lpToken.mint(msg.sender, toMint);

        emit AddLiquidity(msg.sender, amounts, fees, v.d1, totalSupply + toMint);

        return toMint;
    }

    function removeLiquidity(uint256 amount, uint256[] calldata minAmounts, uint256 deadline) external ensure(deadline) returns (uint256[] memory) {
        require(amount <= lpToken.balanceOf(msg.sender), "O3SwapPool: INSUFFICIENT_LP_AMOUNT");
        require(minAmounts.length == coins.length, "O3SwapPool: AMOUNTS_COINS_LENGTH_MISMATCH");

        uint256[] memory amounts = _calculateRemoveLiquidity(amount);

        for (uint256 i = 0; i < amounts.length; i++) {
            require(amounts[i] >= minAmounts[i], "O3SwapPool: INSUFFICIENT_OUTPUT_AMOUNT");
            balances[i] -= amounts[i];
            coins[i].safeTransfer(msg.sender, amounts[i]);
        }

        lpToken.burnFrom(msg.sender, amount);

        emit RemoveLiquidity(msg.sender, amounts, lpToken.totalSupply());

        return amounts;
    }

    function removeLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex, uint256 minAmount, uint256 deadline) external ensure(deadline) returns (uint256) {
        uint256 numTokens = coins.length;

        require(tokenAmount <= lpToken.balanceOf(msg.sender), "O3SwapPool: INSUFFICIENT_LP_AMOUNT");
        require(tokenIndex < numTokens, "O3SwapPool: TOKEN_INDEX_OUT_OF_RANGE");

        uint256 dyFee;
        uint256 dy;

        (dy, dyFee) = _calculateWithdrawOneToken(tokenAmount, tokenIndex);

        require(dy >= minAmount, "O3SwapPool: INSUFFICIENT_OUTPUT_AMOUNT");

        balances[tokenIndex] -= dy + dyFee * adminFee / FEE_DENOMINATOR;
        lpToken.burnFrom(msg.sender, tokenAmount);
        coins[tokenIndex].safeTransfer(msg.sender, dy);

        emit RemoveLiquidityOne(msg.sender, tokenAmount, lpToken.totalSupply(), tokenIndex, dy);

        return dy;
    }

    function removeLiquidityImbalance(uint256[] calldata amounts, uint256 maxBurnAmount, uint256 deadline) external ensure(deadline) returns (uint256) {
        require(amounts.length == coins.length, "O3SwapPool: AMOUNTS_COINS_LENGTH_MISMATCH");
        require(maxBurnAmount <= lpToken.balanceOf(msg.sender) && maxBurnAmount != 0, "O3SwapPool: INSUFFICIENT_LP_AMOUNT");

        RemoveLiquidityImbalanceInfo memory v = RemoveLiquidityImbalanceInfo(0, 0, 0, 0);

        uint256 tokenSupply = lpToken.totalSupply();
        uint256 feePerToken = _feePerToken();
        v.preciseA = _getAPrecise();
        v.d0 = _getD(_xp(), v.preciseA);

        uint256[] memory newBalances = balances;

        for (uint256 i = 0; i < coins.length; i++) {
            newBalances[i] -= amounts[i];
        }

        v.d1 = _getD(_xp(newBalances), v.preciseA);

        uint256[] memory fees = new uint256[](coins.length);

        for (uint256 i = 0; i < coins.length; i++) {
            uint256 idealBalance = v.d1 * balances[i] / v.d0;
            uint256 difference = idealBalance.difference(newBalances[i]);
            fees[i] = feePerToken * difference / FEE_DENOMINATOR;
            balances[i] = newBalances[i] - (fees[i] * adminFee / FEE_DENOMINATOR);
            newBalances[i] -= fees[i];
        }

        v.d2 = _getD(_xp(newBalances), v.preciseA);

        uint256 tokenAmount = (v.d0 - v.d2) * tokenSupply / v.d0;
        require(tokenAmount != 0, "O3SwapPool: BURNT_LP_AMOUNT_CANNOT_BE_ZERO");
        tokenAmount += 1;

        require(tokenAmount <= maxBurnAmount, "O3SwapPool: BURNT_LP_AMOUNT_EXCEEDS_LIMITATION");

        lpToken.burnFrom(msg.sender, tokenAmount);

        for (uint256 i = 0; i < coins.length; i++) {
            coins[i].safeTransfer(msg.sender, amounts[i]);
        }

        emit RemoveLiquidityImbalance(msg.sender, amounts, fees, v.d1, tokenSupply - tokenAmount);

        return tokenAmount;
    }

    function applySwapFee(uint256 newSwapFee) external onlyOwner {
        require(newSwapFee <= MAX_SWAP_FEE, "O3SwapPool: swap fee exceeds maximum");
        swapFee = newSwapFee;

        emit NewSwapFee(newSwapFee);
    }

    function applyAdminFee(uint256 newAdminFee) external onlyOwner {
        require(newAdminFee <= MAX_ADMIN_FEE, "O3SwapPool: admin fee exceeds maximum");
        adminFee = newAdminFee;

        emit NewAdminFee(newAdminFee);
    }

    function withdrawAdminFee(address receiver) external onlyOwner {
        for (uint256 i = 0; i < coins.length; i++) {
            IERC20 token = coins[i];
            uint256 balance = token.balanceOf(address(this)) - balances[i];
            if (balance > 0) {
                token.safeTransfer(receiver, balance);
            }
        }
    }

    function rampA(uint256 _futureA, uint256 _futureTime) external onlyOwner {
        require(block.timestamp >= initialATime + MIN_RAMP_TIME, "O3SwapPool: at least 1 day before new ramp");
        require(_futureTime >= block.timestamp + MIN_RAMP_TIME, "O3SwapPool: insufficient ramp time");
        require(_futureA > 0 && _futureA < MAX_A, "O3SwapPool: futureA must in range (0, MAX_A)");

        uint256 initialAPrecise = _getAPrecise();
        uint256 futureAPrecise = _futureA * A_PRECISION;

        if (futureAPrecise < initialAPrecise) {
            require(futureAPrecise * MAX_A_CHANGE >= initialAPrecise, "O3SwapPool: futureA too small");
        } else {
            require(futureAPrecise <= initialAPrecise * MAX_A_CHANGE, "O3SwapPool: futureA too large");
        }

        initialA = initialAPrecise;
        futureA = futureAPrecise;
        initialATime = block.timestamp;
        futureATime = _futureTime;

        emit RampA(initialAPrecise, futureAPrecise, block.timestamp, _futureTime);
    }

    function stopRampA() external onlyOwner {
        require(futureATime > block.timestamp, "O3SwapPool: ramp already stopped");

        uint256 currentA = _getAPrecise();

        initialA = currentA;
        futureA = currentA;
        initialATime = block.timestamp;
        futureATime = block.timestamp;

        emit StopRampA(currentA, block.timestamp);
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function coins(uint256 index) external view returns(IERC20);
    function getA() external view returns (uint256);
    function getTokenIndex(address token) external view returns (uint8);

    function getVirtualPrice() external view returns (uint256);

    function calculateSwap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx) external view returns (uint256 dy);
    function calculateRemoveLiquidity(uint256 amount) external view returns (uint256[] memory);
    function calculateTokenAmount(uint256[] calldata amounts, bool deposit) external view returns (uint256);
    function calculateWithdrawOneToken(uint256 tokenAmount, uint8 tokenIndex) external view returns (uint256 amount);

    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline) external returns (uint256);
    function addLiquidity(uint256[] memory amounts, uint256 minToMint, uint256 deadline) external returns (uint256);
    function removeLiquidity(uint256 amount, uint256[] calldata minAmounts, uint256 deadline) external returns (uint256[] memory);
    function removeLiquidityOneToken(uint256 tokenAmount, uint8 tokenIndex, uint256 minAmount, uint256 deadline) external returns (uint256);
    function removeLiquidityImbalance(uint256[] calldata amounts, uint256 maxBurnAmount, uint256 deadline) external returns (uint256);

    function applySwapFee(uint256 newSwapFee) external;
    function applyAdminFee(uint256 newAdminFee) external;
    function getAdminBalance(uint256 index) external view returns (uint256);
    function withdrawAdminFee(address receiver) external;
    function rampA(uint256 _futureA, uint256 _futureTime) external;
    function stopRampA() external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "../access/Ownable.sol";
import "./interfaces/IPool.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract LPToken is ERC20Burnable, Ownable {

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address account, uint256 amount) external onlyOwner {
        require(amount != 0, "ERC20: zero mint amount");
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title MathUtils library
 * @notice A library to be used in conjunction with SafeMath. Contains functions for calculating
 * differences between two uint256.
 */
library MathUtils {
    /**
     * @notice Compares a and b and returns true if the difference between a and b
     *         is less than 1 or equal to each other.
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return True if the difference between a and b is less than 1 or equal,
     *         otherwise return false
     */
    function within1(uint256 a, uint256 b) internal pure returns (bool) {
        return (_difference(a, b) <= 1);
    }

    /**
     * @notice Calculates absolute difference between a and b
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return Difference between a and b
     */
    function difference(uint256 a, uint256 b) internal pure returns (uint256) {
        return _difference(a, b);
    }

    /**
     * @notice Calculates absolute difference between a and b
     * @param a uint256 to compare with
     * @param b uint256 to compare with
     * @return Difference between a and b
     */
    function _difference(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a - b;
        }
        return b - a;
    }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}