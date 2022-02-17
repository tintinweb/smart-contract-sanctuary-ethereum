//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "IERC20.sol";
import "UniswapInterfaces.sol";
import "ITrainSpotting.sol";
import "StructsDataType.sol";

contract TrainSpotting {
    mapping(address => stationData) public lastStation;

    address globalToken;
    address centralStation;
    IUniswapV2Router02 solidRouter;

    constructor(address _denominator, address _router) {
        solidRouter = IUniswapV2Router02(_router);
        globalToken = _denominator;
    }

    function _setCentralStation(address _centralStation)
        external
        returns (address, address)
    {
        require(centralStation == address(0));
        centralStation = _centralStation;
        return (address(solidRouter), globalToken);
    }

    function _spottingParams(
        address _denominator,
        address _centralStation,
        address _reRouter
    ) external returns (address, address) {
        require(msg.sender == centralStation || centralStation == address(0));
        globalToken = _denominator;
        centralStation = _centralStation;
        if (_reRouter != address(0))
            solidRouter = IUniswapV2Router02(_reRouter);

        IERC20(globalToken).approve(
            address(solidRouter),
            type(uint128).max - 1
        );

        emit SpottingParamsUpdated(globalToken, centralStation);

        return (address(solidRouter), globalToken);
    }

    event TrainInStation(address indexed _trainAddress, uint256 _nrstation);
    event TrainStarted(address indexed _trainAddress, stationData _station);
    event TrainConductorWithdrawal(
        address indexed buybackToken,
        address indexed trainAddress,
        address who,
        uint256 quantity
    );
    event TrainStarted(address indexed _trainAddress, Train _train);
    event SpottingParamsUpdated(
        address _denominator,
        address indexed _centralStation
    );

    function _trainStation(
        address[2] memory addresses,
        uint256[5] memory context
    ) external returns (bool) {
        require(msg.sender == centralStation);

        lastStation[addresses[0]].at = block.number;

        if (lastStation[addresses[0]].lastGas == 0) {
            lastStation[addresses[0]].price =
                context[0] /
                (10**(18 - context[3]));

            lastStation[addresses[0]].lastGas = context[1] - gasleft();

            // solidRouter.addLiquidity(
            //     addresses[1],
            //     globalToken,
            //     IERC20(addresses[1]).balanceOf(address(this)),
            //     IERC20(globalToken).balanceOf(address(this)),
            //     0,
            //     0,
            //     centralStation,
            //     block.timestamp
            // );

            return true;
        }

        // uint256 remaining = IERC20(addresses[1]).balanceOf(address(this));

        uint256 card = context[2];
        uint64 percentage = uint64(context[4]);
        if (context[2] > 0)
            context[2] = context[2] - ((percentage * context[2]) / 100);

        card = card - context[2];
        uint256 price2 = IUniswapV2Pair(addresses[0]).price0CumulativeLast();
        card = card / price2;
        lastStation[addresses[0]].ownedQty += card;
        if (context[0] > 1) {
            solidRouter.addLiquidity(
                addresses[1],
                globalToken,
                IERC20(addresses[1]).balanceOf(address(this)),
                IERC20(globalToken).balanceOf(address(this)),
                0,
                0,
                centralStation,
                block.timestamp
            );
        }

        emit TrainInStation(addresses[0], block.number);

        lastStation[addresses[0]].lastGas = (context[1] -
            (context[1] - gasleft()));
        lastStation[addresses[0]].price = context[0];

        (bool s, ) = tx.origin.call{
            value: lastStation[addresses[0]].lastGas * 2
        }("gas money");

        return s;
    }

    function _offBoard(
        uint256[6] memory params, ///[t.destination, t.departure, t.bagSize, t.perUnit, inCustody, yieldSharesTotal]
        address[3] memory addresses ///toWho, trainAddress, bToken
    ) external returns (bool success) {
        require(msg.sender == centralStation);

        uint256 shares;
        //@dev sharevalue degradation incentivises predictability
        uint256 pYield = (IERC20(addresses[2]).balanceOf(centralStation) -
            params[4] -
            lastStation[addresses[2]].ownedQty) / params[5];

        if (params[0] < block.number) {
            shares = (params[0] - params[1]) * params[2];
            success = IERC20(addresses[2]).transfer(
                addresses[0],
                (pYield * shares + params[2])
            );
        } else {
            shares = (block.number - params[1]) * params[2];
            success = IERC20(globalToken).transfer(
                addresses[0],
                ((pYield * shares + params[2]) * params[3])
            );
        }
        return success;
    }

    function _withdrawBuybackToken(address[3] memory addresses)
        external
        returns (bool success)
    {
        IERC20 token = IERC20(addresses[1]);
        uint256 q = lastStation[addresses[0]].ownedQty;
        if (q > 0) {
            success = token.transfer(addresses[2], q);
        }
        if (success)
            emit TrainConductorWithdrawal(
                addresses[1],
                addresses[0],
                addresses[2],
                q
            );
    }

    function _addLiquidity(
        address _bToken,
        uint256 _bAmout,
        uint256 _dAmout
    ) external returns (bool) {
        require(msg.sender == centralStation);

        (, , uint256 liq) = solidRouter.addLiquidity(
            _bToken,
            globalToken,
            _bAmout,
            _dAmout,
            0,
            0,
            centralStation,
            block.timestamp
        );
        if (liq > 1) return true;
    }

    function _removeLiquidity(
        address _bToken,
        uint256 _bAmount,
        uint256 _dAmount,
        uint256 _lAmount
    ) public returns (bool) {
        require(msg.sender == centralStation);

        (, uint256 liq) = solidRouter.removeLiquidity(
            _bToken,
            globalToken,
            _lAmount,
            _bAmount,
            _dAmount,
            address(this),
            block.timestamp
        );
        if (liq > 1) return true;
    }

    function _removeAllLiquidity(address _bToken, address _poolAddress)
        external
        returns (bool)
    {
        require(msg.sender == centralStation);
        uint256 l = IERC20(_poolAddress).balanceOf(address(this));
        if (l > 100) {
            (uint256 a, uint256 b) = solidRouter.removeLiquidity(
                _bToken,
                globalToken,
                l - 99,
                0,
                0,
                address(this),
                block.timestamp
            );
            if (a + b > 2) return true;
        }
    }

    function _tokenOut(
        uint256 _amount,
        uint256 _inCustody,
        address _poolAddress,
        address _bToken,
        address _toWho
    ) external returns (bool success) {
        require(msg.sender == centralStation);

        IERC20 token = IERC20(_bToken);
        uint256 prev = token.balanceOf(address(this));
        if (prev >= _amount) success = token.transfer(_toWho, _amount);
        if (!success) {
            uint256 _toBurn = IERC20(_poolAddress).balanceOf(address(this)) /
                (_inCustody / _amount);
            _removeLiquidity(_bToken, _amount, 0, _toBurn);
            success = token.transfer(_toWho, _amount);
        }
    }

    function _approveToken(address _bToken, address _uniPool)
        external
        returns (bool success)
    {
        require(msg.sender == centralStation);

        success =
            IERC20(_bToken).approve(
                address(solidRouter),
                type(uint128).max - 1
            ) &&
            IERC20(_uniPool).approve(
                address(solidRouter),
                type(uint128).max - 1
            );
    }

    function _willTransferFrom(
        address _from,
        address _to,
        address _token,
        uint256 _amount
    ) external returns (bool success) {
        require(msg.sender == centralStation);
        success = IERC20(_token).transferFrom(_from, _to, _amount);
    }

    function _setStartStation(address _trainAddress) external returns (bool) {
        require(msg.sender == centralStation);
        lastStation[_trainAddress].at = block.number;
        return true;
    }

    function _getLastStation(address _train)
        external
        view
        returns (uint256[4] memory stationD)
    {
        stationD = [
            lastStation[_train].at,
            lastStation[_train].price,
            lastStation[_train].ownedQty,
            lastStation[_train].lastGas
        ];
    }

    function _isInStation(uint256 _cycleZero, address _trackAddr)
        external
        view
        returns (bool)
    {
        if (_cycleZero + lastStation[_trackAddr].at == block.number)
            return true;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

///SPDX-License-Identifier: GNU-2.0

pragma solidity 0.8.4;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

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
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2ERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

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
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.4;

interface ITrainSpotting {
    function _spottingParams(
        address baseToken,
        address bossContract,
        address uniRouter
    ) external returns (address, address);

    function _trainStation(
        address[2] memory addresses,
        uint256[5] memory context
    ) external returns (bool);

    function _offBoard(uint256[6] memory params, address[3] memory addresses)
        external
        returns (bool);

    /// [ trainAddress, bToken, tOwner ]
    function _withdrawBuybackToken(address[3] memory addresses)
        external
        returns (bool);

    function _addLiquidity(
        address bToken,
        uint256 bAmout,
        uint256 dAmout
    ) external returns (bool);

    function _removeLiquidity(
        address bToken,
        uint256 bAmount,
        uint256 dAmount,
        uint256 lAmount
    ) external returns (bool);

    function _removeAllLiquidity(address bToken, address poolAddress)
        external
        returns (bool);

    function _isInStation(uint256, address) external view returns (bool);

    function _tokenOut(
        uint256 amountOut,
        uint256 inCustody,
        address poolAddr,
        address bToken,
        address toWho
    ) external returns (bool);

    function _approveToken(address bToken, address pool)
        external
        returns (bool);

    function _willTransferFrom(
        address from,
        address to,
        address token,
        uint256 value
    ) external returns (bool);

    function _setCentralStation(address centralStation)
        external
        returns (address, address);

    function _getLastStation(address train)
        external
        view
        returns (uint256[4] memory stationD);

    function _setStartStation(address _trainAddress) external returns (bool);
}

//SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.4;

struct stationData {
    uint256 at; //last station ocurred at block
    uint256 price; //price at last station
    uint256 ownedQty; //owned quantity (withdrawable by conductor / ! inCustody)
    uint256 lastGas; //last gas for station execution cycle (informative)
}

struct operators {
    address buybackToken; //buyback token contract address
    address uniPool; //address of the uniswap pair contract
}

struct configdata {
    uint64[4] cycleParams; //[cycleFreq(distance between stations), minDistance(min nr of stations for ticket), budgetSlicer(chunk to spend on token buyback each station), perDecimalDepth(market price< loop limiter for buyout)]
    uint256 minBagSize; //min bag size (min stake for ticket)
    bool controlledSpeed; //if true, facilitate speed management (can cycle params be changed?)
}

struct Train {
    operators meta;
    uint256 yieldSharesTotal; //total quantity of pool shares
    uint256 budget; //total budget for buybacks
    uint256 inCustody; //total token in custody (! separate from stationData.ownedQty)
    uint64 passengers; //number of active tickets/passangers
    configdata config; //configdata
}

struct Ticket {
    uint256 destination; //promises to travel to block
    uint256 departure; //created on block
    uint256 bagSize; //amount token
    uint256 perUnit; //buyout price
    address trainAddress; //train ID (pair pool)
    uint256 nftid; //nft id
}