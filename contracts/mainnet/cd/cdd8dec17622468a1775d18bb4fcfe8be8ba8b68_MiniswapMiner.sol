// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

import './interfaces/IMiniswapMiner.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IMiniswapPair.sol';
import './libraries/MiniswapLibrary.sol';
import './interfaces/IERC20.sol';
import './libraries/SafeMath.sol';
import './interfaces/IMini.sol';

contract MiniswapMiner is IMiniswapMiner{
    using SafeMath for uint;
    
    address public override owner;
    address public override feeder;

    mapping(address=>bool) public override whitelistMap;
    mapping(uint256=>uint256) public override mineInfo; // day=>issueAmount
    mapping(address=>uint256) private balances;
    
    uint256 public override minFee;

    uint256 firstTxHeight;
    address MINI;
    address USDT;
    mapping (uint=>mapping(address=>bool)) rewardMap;
    mapping (uint=>uint) rewardAmountByRoundMap;

    constructor(uint256 _minFee,address _mini,address _usdt,address _feeder) public {
        owner = msg.sender;
        minFee = _minFee;
        MINI = _mini;
        USDT = _usdt;
        feeder = _feeder;
        firstTxHeight = block.number;
    }

    modifier isOwner(){
        require(msg.sender == owner,"forbidden:owner");
        _;
    }

    modifier isWhiteAddress(){
        require(whitelistMap[msg.sender] == true,"forbidden:whitelist");
        _;
    }

    function getToken(address token,address to) public isOwner() {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(to,balance);
    }

    function changeMinFee(uint256 _minFee) override public isOwner() {
        minFee = _minFee;
    }

    function addWhitelist(address pair) override public isOwner() {
        whitelistMap[pair] = true;
    }

    function addWhitelistByTokens(address factory ,address token0,address token1) override public isOwner() {
        address pair = MiniswapLibrary.pairFor(factory, token0, token1);
        addWhitelist(pair);
    }

    function removeWhitelist(address pair) override public isOwner() {
        whitelistMap[pair] = false;
    }

    function removeWhitelistByTokens(address factory ,address token0,address token1) override public isOwner() {
        address pair = MiniswapLibrary.pairFor(factory, token0, token1);
        removeWhitelist(pair);
    }

    function mining(address factory,address feeTemp,address originSender,address token,uint amount) override public isWhiteAddress(){
        TransferHelper.safeTransferFrom(token,msg.sender,address(this),amount);
        uint issueAmount;
        uint miniAmount;
        if (token == MINI){
            //send half of increment to address0,the other send to feeder
            issueAmount = amount;
            miniAmount = amount;
        } else if (token == USDT) {
            //get price from token-USDT-MINI
            address[] memory path = new address[](2);
            path[0] = token;
            path[1] = MINI;
            uint256[] memory amountsOut = MiniswapLibrary.getAmountsOut(factory,amount,path); //[USDTAmountOut,MINIAmountOut]
            issueAmount = amountsOut[1];
            //only mine when usdtout more than minFee
            if(issueAmount<= minFee)
                return;
            miniAmount = swapMini(factory,USDT,issueAmount,amountsOut[0]); //usdt-->mini
        } else {
         //get price from token-USDT-MINI
            address[] memory path = new address[](3);
            path[0] = token;
            path[1] = USDT;
            path[2] = MINI;
            uint256[] memory amountsOut = MiniswapLibrary.getAmountsOut(factory,amount,path); //[tokenAmountOut,USDTAmountOut,MINIAmountOut]
            issueAmount = amountsOut[2];
            //only mine when usdtout more than minFee
            if(issueAmount<= minFee)
                return;
            uint usdtAmount = swapUsdt(factory,token,amountsOut[1],amount); //token-->usdt
            miniAmount = swapMini(factory,USDT,issueAmount,usdtAmount); //usdt-->mini
        }
        //send half of increment to address0,the other half send to feeder
        TransferHelper.safeTransfer(MINI,address(0x1111111111111111111111111111111111111111), miniAmount.div(2));
        TransferHelper.safeTransfer(MINI,feeder, miniAmount.div(2));
        issueMini(issueAmount,feeTemp,originSender);
    }

    function swapUsdt(address factory, address token,uint usdtAmount,uint amount) internal returns(uint){
        uint256 balance0 = IERC20(USDT).balanceOf(address(this));
        (address token0,address token1) = MiniswapLibrary.sortTokens(token,USDT);
        address pair_token_usdt = MiniswapLibrary.pairFor(factory,token0,token1);
        (uint amount0Out ,uint amount1Out) = token0==token ? (uint(0),usdtAmount):(usdtAmount,uint(0));
        TransferHelper.safeTransfer(token,pair_token_usdt,amount); //send token to pair
        IMiniswapPair(pair_token_usdt).swap(
                amount0Out, amount1Out, address(this), address(this),new bytes(0)
            );
        return IERC20(USDT).balanceOf(address(this)).sub(balance0);
    }

    function swapMini(address factory, address token,uint issueAmount,uint amount) internal returns(uint){
        uint256 balance0 = IERC20(MINI).balanceOf(address(this));
        (address token0,address token1) = MiniswapLibrary.sortTokens(token,MINI);
        address pair_token_mini = MiniswapLibrary.pairFor(factory,token0,token1);
        (uint amount0Out ,uint amount1Out) = token0==token ? (uint(0),issueAmount):(issueAmount,uint(0));
        TransferHelper.safeTransfer(token,pair_token_mini,amount); //send token to pair
        IMiniswapPair(pair_token_mini).swap(
                amount0Out, amount1Out, address(this),address(this),new bytes(0)
            );
        return IERC20(MINI).balanceOf(address(this)).sub(balance0);
    }

    function issueMini(uint256 issueAmount,address feeTemp,address originSender) internal {
        ///////The 6000 block height is one day, 30 day is one month
        uint durationDay = (block.number.sub(firstTxHeight)).div(6000);
        uint256 issueAmountLimit = MiniswapLibrary.getIssueAmountLimit(durationDay);
        //issue mini to liquilidity && user
        if( mineInfo[durationDay].add(issueAmount).add(issueAmount) > issueAmountLimit){
            issueAmount = issueAmountLimit.sub( mineInfo[durationDay]).div(2);
        }
        if(issueAmount > 0){
            IMini(MINI).issueTo(originSender,issueAmount);
            IMini(MINI).issueTo(feeTemp,issueAmount);
            mineInfo[durationDay] = mineInfo[durationDay].add(issueAmount).add(issueAmount);
        }
    }
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

interface IMini {
    function k() external view returns(uint256);
    function kTotals(uint256) external view returns(uint256);
    function issueTo(address to, uint256 amount) external;
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

interface IMiniswapMiner {
    event AddWhitelist(address);
    event RemoveWhitelist(address);

    function owner() external view returns(address);
    function feeder() external view returns(address);

    function whitelistMap(address) external view returns(bool);
    function mineInfo(uint256) external view returns(uint256);
    function minFee() external view returns(uint256);

    function changeMinFee(uint256) external;
    function addWhitelist(address) external;
    function addWhitelistByTokens(address,address,address) external;
    function removeWhitelist(address) external;
    function removeWhitelistByTokens(address,address,address) external;

    function mining(address,address,address,address,uint) external;//factory receiver token amount
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

interface IMiniswapPair {
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1,uint amountMINI, address indexed to);
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
    function miner() external view returns(address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function MINI() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function feeTemp() external view returns(address);
    function userInFeeAmount(address) external returns(uint);
    function totalFeeAmount() external returns(uint);
    function getMineFeeAmount(address) external view returns(uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1,uint amountmini);
    function swap(uint amount0Out, uint amount1Out, address to,address originSender, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address,address,address, address) external;
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

import '../interfaces/IMiniswapPair.sol';

import "./SafeMath.sol";

library MiniswapLibrary {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'MiniswapLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'MiniswapLibrary: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'c452e099acab13324eff6921de6a25e75eb481f814af7406d7f296af8ddb7dbd' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IMiniswapPair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'MiniswapLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'MiniswapVLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'MiniswapLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'MiniswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'MiniswapLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'MiniswapLibrary: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'MiniswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'MiniswapLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }

    function getIssueAmountLimit(uint256 durationDay) internal pure returns(uint256 amount){
        ///////The 6000 block height is one day, 30 day is one month
        uint durationMonth = durationDay.div(30);
        amount = 18000 * (10**18);
        if (durationMonth < 10) {
            amount =  uint(500000 * (10**18)).mul(7**durationMonth).div(10**durationMonth);
        }
    }
}

// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-License-Identifier: SimPL-2.0
pragma solidity=0.6.9;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}