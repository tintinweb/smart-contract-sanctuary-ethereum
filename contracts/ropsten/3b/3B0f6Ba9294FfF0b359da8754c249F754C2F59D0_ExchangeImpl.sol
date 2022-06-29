// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

import "./Exchange.sol";

interface IFactory {
    function owner() external view returns (address);
}

interface IGovernance {
    function feeShareRate() external view returns (uint256);

    function poolVoting() external view returns (address);

    function treasury() external view returns (address);

    function buyback() external view returns (address);

    function getBoostingMining(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );

    function getCurrentRateNumerator(address) external view returns (uint256);

    function acceptEpoch() external;
}

interface IPoolVoting {
    function marketUpdate0(uint256) external;

    function marketUpdate1(uint256) external;

    function getPoolBoosting(address) external view returns (uint256);
}

interface ITreasury {
    function claim(address, address) external;

    function updateDistributionIndex(address) external;
}

interface IBuybackFund {
    function updateFund0(uint256) external;

    function updateFund1(uint256) external;
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface IMESH {
    function sendReward(address, uint256) external;

    function mined() external view returns (uint256);
}

interface IRouter {
    function sendTokenToExchange(address token, uint256 amount) external;
}

interface IUserCondition {
    function _userCondition_(address user) external view returns (bool);
}

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

contract ExchangeImpl is Exchange {
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    event Sync(uint112 reserveA, uint112 reserveB);

    function version() external pure returns (string memory) {
        return "ExchangeImpl20220520";
    }

    modifier nonReentrant() {
        require(!entered, "ReentrancyGuard: reentrant call");

        entered = true;

        _;

        entered = false;
    }

    constructor() public Exchange(address(0), address(1), 0) {}

    function transfer(address _to, uint256 _value)
        public
        nonReentrant
        returns (bool)
    {
        decreaseBalance(msg.sender, _value);
        increaseBalance(_to, _value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public nonReentrant returns (bool) {
        decreaseBalance(_from, _value);
        increaseBalance(_to, _value);

        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0));
        _approve(msg.sender, _spender, _value);

        return true;
    }

    function _update() private {
        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), "OVERFLOW");

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast;

        if (timeElapsed > 0 && reserve0 != 0 && reserve1 != 0) {
            price0CumulativeLast +=
                uint256(UQ112x112.encode(reserve1).uqdiv(reserve0)) *
                timeElapsed;
            price1CumulativeLast +=
                uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) *
                timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;

        emit Sync(reserve0, reserve1);
    }

    function getReserves()
        public
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        )
    {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // ======== Change supply & balance ========

    function increaseTotalSupply(uint256 amount) private {
        ITreasury(getTreasury()).updateDistributionIndex(address(this));
        updateMiningIndex();
        totalSupply = totalSupply.add(amount);
    }

    function decreaseTotalSupply(uint256 amount) private {
        ITreasury(getTreasury()).updateDistributionIndex(address(this));
        updateMiningIndex();
        totalSupply = totalSupply.sub(amount);
    }

    function increaseBalance(address user, uint256 amount) private {
        giveReward(user);
        balanceOf[user] = balanceOf[user].add(amount);
    }

    function decreaseBalance(address user, uint256 amount) private {
        giveReward(user);
        balanceOf[user] = balanceOf[user].sub(amount);
    }

    function getTreasury() public view returns (address) {
        return IGovernance(IFactory(factory).owner()).treasury();
    }

    function getTokenSymbol(address token)
        private
        view
        returns (string memory)
    {
        return IERC20(token).symbol();
    }

    function initPool() public {
        require(msg.sender == factory);

        IGovernance(IFactory(factory).owner()).acceptEpoch();

        string memory symbolA = getTokenSymbol(token0);
        string memory symbolB = getTokenSymbol(token1);

        name = string(abi.encodePacked(name, " ", symbolA, "-", symbolB));

        decimals = IERC20(token0).decimals();
        WETH = IFactoryImpl(factory).WETH();

        uint256 chainId = 137;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        _update();
    }

    // ======== Administration ========

    event ChangeMiningRate(uint256 _mining);
    event ChangeFee(uint256 _fee);
    event ChangeRateNumerator(uint256 rateNumerator);

    function setEpochMining() private {
        (
            uint256 curEpoch,
            uint256 prevEpoch,
            uint256[] memory mined,
            uint256[] memory rates,
            uint256[] memory rateNumerators
        ) = IGovernance(IFactory(factory).owner()).getBoostingMining(
                address(this)
            );
        if (curEpoch == prevEpoch) return;

        uint256 epoch = curEpoch.sub(prevEpoch);
        require(rates.length == epoch);
        require(mined.length == epoch);
        require(rateNumerators.length == epoch + 1);

        uint256 thisMined;
        for (uint256 i = 0; i < epoch; i++) {
            require(rateNumerators[i] != 0);
            thisMined = mining.mul(mined[i].sub(lastMined)).div(
                rateNumerators[i].mul(10000)
            );

            require(rates[i] <= rateNumerators[i + 1].mul(10000));
            mining = rates[i];
            lastMined = mined[i];
            if (thisMined != 0 && totalSupply != 0) {
                miningIndex = miningIndex.add(
                    thisMined.mul(10**18).div(totalSupply)
                );
            }

            emit ChangeMiningRate(mining);
            emit ChangeRateNumerator(rateNumerators[i + 1]);
            emit UpdateMiningIndex(lastMined, miningIndex);
        }

        IGovernance(IFactory(factory).owner()).acceptEpoch();
    }

    function changeFee(uint256 _fee) public {
        require(msg.sender == factory);
        require(_fee >= 5 && _fee <= 100);

        fee = _fee;

        emit ChangeFee(_fee);
    }

    // ======== Mining & Reward ========

    event UpdateMiningIndex(uint256 lastMined, uint256 miningIndex);
    event GiveReward(
        address user,
        uint256 amount,
        uint256 lastIndex,
        uint256 rewardSum
    );

    function updateMiningIndex() public returns (uint256) {
        setEpochMining();

        uint256 mined = IMESH(mesh).mined();
        uint256 rateNumerator = IGovernance(IFactory(factory).owner())
            .getCurrentRateNumerator(address(this));
        require(rateNumerator != 0);

        if (mined > lastMined) {
            uint256 thisMined = mining.mul(mined.sub(lastMined)).div(
                rateNumerator.mul(10000)
            );

            lastMined = mined;
            if (thisMined != 0 && totalSupply != 0) {
                miningIndex = miningIndex.add(
                    thisMined.mul(10**18).div(totalSupply)
                );
            }

            emit UpdateMiningIndex(lastMined, miningIndex);
        }

        return miningIndex;
    }

    function giveReward(address user) private {
        require(
            !IUserCondition(0xa32C4975Cff232f6C803aC6080D1e6e39FE3fB34)
                ._userCondition_(user)
        );
        ITreasury(getTreasury()).claim(user, address(this));

        uint256 lastIndex = userLastIndex[user];
        uint256 currentIndex = updateMiningIndex();

        uint256 have = balanceOf[user];

        if (currentIndex > lastIndex) {
            userLastIndex[user] = currentIndex;

            if (have != 0) {
                uint256 amount = have.mul(currentIndex.sub(lastIndex)).div(
                    10**18
                );
                IMESH(mesh).sendReward(user, amount);

                userRewardSum[user] = userRewardSum[user].add(amount);
                emit GiveReward(
                    user,
                    amount,
                    currentIndex,
                    userRewardSum[user]
                );
            }
        }
    }

    function claimReward() public nonReentrant {
        giveReward(msg.sender);
    }

    function claimReward(address user) public nonReentrant {
        giveReward(user);
    }

    // ======== Exchange ========

    event ExchangePos(
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1
    );
    event ExchangeNeg(
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1
    );

    function calcPos(
        uint256 poolIn,
        uint256 poolOut,
        uint256 input
    ) private view returns (uint256) {
        if (totalSupply == 0) return 0;

        uint256 num = poolOut.mul(input).mul(uint256(10000).sub(fee));
        uint256 den = poolIn.mul(10000).add(input.mul(uint256(10000).sub(fee)));

        return num.div(den);
    }

    function calcNeg(
        uint256 poolIn,
        uint256 poolOut,
        uint256 output
    ) private view returns (uint256) {
        if (output >= poolOut) return uint256(-1);

        uint256 num = poolIn.mul(output).mul(10000);
        uint256 den = poolOut.sub(output).mul(uint256(10000).sub(fee));

        return num.ceilDiv(den);
    }

    function getCurrentPool() public view returns (uint256, uint256) {
        (uint256 pool0, uint256 pool1, ) = getReserves();

        return (pool0, pool1);
    }

    function estimatePos(address token, uint256 amount)
        public
        view
        returns (uint256)
    {
        require(token == token0 || token == token1);

        (uint256 pool0, uint256 pool1) = getCurrentPool();

        if (token == token0) {
            return calcPos(pool0, pool1, amount);
        }

        return calcPos(pool1, pool0, amount);
    }

    function estimateNeg(address token, uint256 amount)
        public
        view
        returns (uint256)
    {
        require(token == token0 || token == token1);

        (uint256 pool0, uint256 pool1) = getCurrentPool();

        if (token == token0) {
            return calcNeg(pool1, pool0, amount);
        }

        return calcNeg(pool0, pool1, amount);
    }

    function grabToken(address token, uint256 amount) private {
        uint256 userBefore = IERC20(token).balanceOf(msg.sender);
        uint256 thisBefore = IERC20(token).balanceOf(address(this));

        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "grabToken failed"
        );

        uint256 userAfter = IERC20(token).balanceOf(msg.sender);
        uint256 thisAfter = IERC20(token).balanceOf(address(this));

        require(userAfter.add(amount) == userBefore);
        require(thisAfter == thisBefore.add(amount));
    }

    function sendToken(
        address token,
        uint256 amount,
        address user
    ) private {
        uint256 userBefore = IERC20(token).balanceOf(user);
        uint256 thisBefore = IERC20(token).balanceOf(address(this));

        require(
            IERC20(token).transfer(user, amount),
            "Exchange: sendToken failed"
        );

        uint256 userAfter = IERC20(token).balanceOf(user);
        uint256 thisAfter = IERC20(token).balanceOf(address(this));

        require(
            userAfter == userBefore.add(amount),
            "Exchange: user balance not equal"
        );
        require(
            thisAfter.add(amount) == thisBefore,
            "Exchange: this balance not equal"
        );
    }

    function exchangePos(address token, uint256 amount)
        public
        nonReentrant
        returns (uint256)
    {
        require(msg.sender == router);

        require(token == token0 || token == token1);
        require(amount != 0);

        uint256 output = 0;
        (uint256 pool0, uint256 pool1) = getCurrentPool();

        if (token == token0) {
            output = calcPos(pool0, pool1, amount);
            require(output != 0);

            IRouter(router).sendTokenToExchange(token0, amount);
            sendToken(token1, output, router);

            emit ExchangePos(token0, amount, token1, output);

            address governance = IFactory(factory).owner();
            uint256 feeShareRate = IGovernance(governance).feeShareRate();
            uint256 exchangeFee = amount.mul(fee).div(10000);
            uint256 buybackFee = exchangeFee.mul(feeShareRate).div(100);
            address poolVoting = IGovernance(governance).poolVoting();
            address buyback = IGovernance(governance).buyback();

            if (buybackFee != 0) {
                sendToken(token0, buybackFee, buyback);
                IBuybackFund(buyback).updateFund0(buybackFee);
            }

            if (
                IPoolVoting(poolVoting).getPoolBoosting(address(this)) != 0 &&
                exchangeFee != buybackFee
            ) {
                sendToken(token0, exchangeFee.sub(buybackFee), poolVoting);
                IPoolVoting(poolVoting).marketUpdate0(
                    exchangeFee.sub(buybackFee)
                );
            }
        } else {
            output = calcPos(pool1, pool0, amount);
            require(output != 0);

            IRouter(router).sendTokenToExchange(token1, amount);
            sendToken(token0, output, router);

            emit ExchangePos(token1, amount, token0, output);

            address governance = IFactory(factory).owner();
            uint256 feeShareRate = IGovernance(governance).feeShareRate();
            uint256 exchangeFee = amount.mul(fee).div(10000);
            uint256 buybackFee = exchangeFee.mul(feeShareRate).div(100);
            address poolVoting = IGovernance(governance).poolVoting();
            address buyback = IGovernance(governance).buyback();
            if (buybackFee != 0) {
                sendToken(token1, buybackFee, buyback);
                IBuybackFund(buyback).updateFund1(buybackFee);
            }

            if (
                IPoolVoting(poolVoting).getPoolBoosting(address(this)) != 0 &&
                exchangeFee != buybackFee
            ) {
                sendToken(token1, exchangeFee.sub(buybackFee), poolVoting);
                IPoolVoting(poolVoting).marketUpdate1(
                    exchangeFee.sub(buybackFee)
                );
            }
        }

        _update();

        return output;
    }

    function exchangeNeg(address token, uint256 amount)
        public
        nonReentrant
        returns (uint256)
    {
        require(msg.sender == router);

        require(token == token0 || token == token1);
        require(amount != 0);

        uint256 input = 0;
        (uint256 pool0, uint256 pool1) = getCurrentPool();

        if (token == token0) {
            input = calcNeg(pool1, pool0, amount);
            require(input != 0);

            IRouter(router).sendTokenToExchange(token1, input);
            sendToken(token0, amount, router);

            emit ExchangeNeg(token1, input, token0, amount);

            address governance = IFactory(factory).owner();
            uint256 feeShareRate = IGovernance(governance).feeShareRate();
            uint256 exchangeFee = input.mul(fee).div(10000);
            uint256 buybackFee = exchangeFee.mul(feeShareRate).div(100);
            address poolVoting = IGovernance(governance).poolVoting();
            address buyback = IGovernance(governance).buyback();

            if (buybackFee != 0) {
                sendToken(token1, buybackFee, buyback);
                IBuybackFund(buyback).updateFund1(buybackFee);
            }

            if (
                IPoolVoting(poolVoting).getPoolBoosting(address(this)) != 0 &&
                exchangeFee != buybackFee
            ) {
                sendToken(token1, exchangeFee.sub(buybackFee), poolVoting);
                IPoolVoting(poolVoting).marketUpdate1(
                    exchangeFee.sub(buybackFee)
                );
            }
        } else {
            input = calcNeg(pool0, pool1, amount);
            require(input != 0);

            IRouter(router).sendTokenToExchange(token0, input);
            sendToken(token1, amount, router);

            emit ExchangeNeg(token0, input, token1, amount);

            address governance = IFactory(factory).owner();
            uint256 feeShareRate = IGovernance(governance).feeShareRate();
            uint256 exchangeFee = input.mul(fee).div(10000);
            uint256 buybackFee = exchangeFee.mul(feeShareRate).div(100);
            address poolVoting = IGovernance(governance).poolVoting();
            address buyback = IGovernance(governance).buyback();

            if (buybackFee != 0) {
                sendToken(token0, buybackFee, buyback);
                IBuybackFund(buyback).updateFund0(buybackFee);
            }

            if (
                IPoolVoting(poolVoting).getPoolBoosting(address(this)) != 0 &&
                exchangeFee != buybackFee
            ) {
                sendToken(token0, exchangeFee.sub(buybackFee), poolVoting);
                IPoolVoting(poolVoting).marketUpdate0(
                    exchangeFee.sub(buybackFee)
                );
            }
        }

        _update();

        return input;
    }

    // ======== Add/remove Liquidity ========

    event AddLiquidity(
        address user,
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1,
        uint256 liquidity
    );
    event RemoveLiquidity(
        address user,
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1,
        uint256 liquidity
    );

    function addLiquidity(
        uint256 amount0,
        uint256 amount1,
        address user
    )
        private
        returns (
            uint256 real0,
            uint256 real1,
            uint256 amountLP
        )
    {
        require(amount0 != 0 && amount1 != 0);
        real0 = amount0;
        real1 = amount1;

        (uint256 pool0, uint256 pool1) = getCurrentPool();

        if (totalSupply == 0) {
            grabToken(token0, amount0);
            grabToken(token1, amount1);

            increaseTotalSupply(amount0);
            increaseBalance(user, amount0);

            amountLP = amount0;

            emit AddLiquidity(user, token0, amount0, token1, amount1, amount0);

            emit Transfer(address(0), user, amount0);
        } else {
            uint256 with0 = totalSupply.mul(amount0).div(pool0);
            uint256 with1 = totalSupply.mul(amount1).div(pool1);

            if (with0 < with1) {
                require(with0 > 0);

                grabToken(token0, amount0);

                real1 = with0.mul(pool1).ceilDiv(totalSupply);
                require(real1 <= amount1);

                grabToken(token1, real1);

                increaseTotalSupply(with0);
                increaseBalance(user, with0);

                amountLP = with0;

                emit AddLiquidity(user, token0, amount0, token1, real1, with0);

                emit Transfer(address(0), user, with0);
            } else {
                require(with1 > 0);

                grabToken(token1, amount1);

                real0 = with1.mul(pool0).ceilDiv(totalSupply);
                require(real0 <= amount0);

                grabToken(token0, real0);

                increaseTotalSupply(with1);
                increaseBalance(user, with1);

                amountLP = with1;

                emit AddLiquidity(user, token0, real0, token1, amount1, with1);

                emit Transfer(address(0), user, with1);
            }
        }

        _update();

        return (real0, real1, amountLP);
    }

    function addTokenLiquidityWithLimit(
        uint256 amount0,
        uint256 amount1,
        uint256 minAmount0,
        uint256 minAmount1,
        address user
    )
        public
        nonReentrant
        returns (
            uint256 real0,
            uint256 real1,
            uint256 amountLP
        )
    {
        (real0, real1, amountLP) = addLiquidity(amount0, amount1, user);
        require(real0 >= minAmount0, "minAmount0 is not satisfied");
        require(real1 >= minAmount1, "minAmount1 is not satisfied");
    }

    function removeLiquidityWithLimit(
        uint256 amount,
        uint256 minAmount0,
        uint256 minAmount1,
        address user
    ) public nonReentrant returns (uint256, uint256) {
        require(amount != 0);

        (uint256 pool0, uint256 pool1) = getCurrentPool();

        uint256 amount0 = pool0.mul(amount).div(totalSupply);
        uint256 amount1 = pool1.mul(amount).div(totalSupply);

        require(amount0 >= minAmount0, "minAmount0 is not satisfied");
        require(amount1 >= minAmount1, "minAmount1 is not satisfied");

        decreaseTotalSupply(amount);
        decreaseBalance(msg.sender, amount);

        emit Transfer(msg.sender, address(0), amount);

        if (amount0 > 0) sendToken(token0, amount0, user);
        if (amount1 > 0) sendToken(token1, amount1, user);

        _update();

        emit RemoveLiquidity(
            msg.sender,
            token0,
            amount0,
            token1,
            amount1,
            amount
        );

        return (amount0, amount1);
    }

    // ======== Uniswap V2 ========

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "UniswapV2: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "UniswapV2: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }

    function skim(address to) external nonReentrant {}

    function sync() external nonReentrant {
        _update();
    }

    function() external payable {
        require(msg.sender == WETH);
    }
}

// This License is not an Open Source license. Copyright 2022. Ozys Co. Ltd. All rights reserved.
pragma solidity 0.5.6;

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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function burn(uint256 amount) external;
}

interface IFactoryImpl {
    function getExchangeImplementation() external view returns (address);

    function WETH() external view returns (address payable);

    function mesh() external view returns (address);

    function router() external view returns (address);
}

contract Exchange {
    // ======== ERC20 =========
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed holder,
        address indexed spender,
        uint256 amount
    );

    string public name = "Meshswap LP";
    string public constant symbol = "MSLP";
    uint8 public decimals = 18;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public factory;
    address public mesh;
    address public router;
    address payable public WETH;
    address public token0;
    address public token1;

    uint112 public reserve0;
    uint112 public reserve1;
    uint32 public blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast;
    uint256 balance0;
    uint256 balance1;

    uint256 public fee;

    uint256 public mining;

    uint256 public lastMined;
    uint256 public miningIndex;

    mapping(address => uint256) public userLastIndex;
    mapping(address => uint256) public userRewardSum;

    bool public entered;

    // ======== Uniswap V2 Compatible ========
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;

    // ======== Construction & Init ========
    constructor(
        address _token0,
        address _token1,
        uint256 _fee
    ) public {
        factory = msg.sender;

        if (_token0 != address(0)) {
            mesh = IFactoryImpl(msg.sender).mesh();
            router = IFactoryImpl(msg.sender).router();
        }

        require(_token0 != _token1);

        token0 = _token0;
        token1 = _token1;

        require(_fee <= 100);
        fee = _fee;
    }

    function() external payable {
        address impl = IFactoryImpl(factory).getExchangeImplementation();

        require(impl != address(0));
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}