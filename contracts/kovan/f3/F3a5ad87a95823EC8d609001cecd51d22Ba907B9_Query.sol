// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./common/IDeforFactory.sol";
import "./common/IUniswapV2Factory.sol";
import "./common/IUniswapV2Router02.sol";
import "./common/IERC20.sol";
import "./common/IUniswapV2Pair.sol";

contract Query {
    bytes32 public constant TRANSACTION_RANDOMHASH = keccak256('Random(uint256 random,string explain)');
    bytes32 public DOMAIN_SEPARATOR;
    address public immutable uniswapV2Router02;
    address public immutable uniswapV2Factory;
    address public constant ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address public immutable weth;
    address public immutable usdt;
    address public immutable usdc;
    address public immutable dai;
    address public immutable wbtc;
    address public owner;
    // Forexample : USDT -> DAI -> USDC, DAI is transformationToken
    address[] public transformationTokens;

    constructor(address _deforFactory,address _dexRouterv2,address _dexFactory,
        address _weth,address _usdt,address _usdc,address _dai,address _wbtc){
        DOMAIN_SEPARATOR = IDeforFactory(_deforFactory).DOMAIN_SEPARATOR();
        weth = _weth;
        usdt = _usdt;
        usdc = _usdc;
        dai = _dai;
        wbtc = _wbtc;
        uniswapV2Router02 = _dexRouterv2;
        uniswapV2Factory = _dexFactory;

        transformationTokens.push(_weth);
        transformationTokens.push(_usdt);
        transformationTokens.push(_usdc);
        transformationTokens.push(_dai);
        transformationTokens.push(_wbtc);
        
        owner = msg.sender;
    }

    function updateDeforFactory(address _deforFactory) public{
        require(msg.sender == owner,"owner is error");
        DOMAIN_SEPARATOR = IDeforFactory(_deforFactory).DOMAIN_SEPARATOR();
    }

    function _getPathBy2(address _sellTokenAddress, address _buyTokenAddress) private pure returns (address[] memory){
        address[] memory path = new address[](2);
        path[0] = _sellTokenAddress;
        path[1] = _buyTokenAddress;
        return path;
    }

    function _getPathBy3(address _sellTokenAddress, address _token, address _buyTokenAddress) private pure returns (address[] memory){
        address[] memory path = new address[](3);
        path[0] = _sellTokenAddress;
        path[1] = _token;
        path[2] = _buyTokenAddress;
        return path;
    }

    /*
        验证数据签名
        @Params
            _data ： RLP编码数据
        @Returns
            address : 数据签名者的地址
    */
    function verifyMessagePrefix(bytes memory _data, bytes32 _r, bytes32 _s, uint8 _v) public pure returns (address){
        return ecrecover(keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32',keccak256(_data))), _v, _r, _s);
    }
    function verifyMessage(bytes memory _data, bytes32 _r, bytes32 _s, uint8 _v) public pure returns (address){
        return ecrecover(keccak256(_data), _v, _r, _s);
    }
    /*
        验证随机数
        @Params
            _random ： 随机数
            _explain : 对验证该随机数的解释
        @Returns
            address : 数据签名者的地址
    */
    function verifyRandom(uint256 _random, string memory _explain, bytes32 _r, bytes32 _s, uint8 _v) public view returns (address){
        return ecrecover(keccak256(abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    TRANSACTION_RANDOMHASH,
                    _random,
                    keccak256(bytes(_explain))
                ))
            )), _v, _r, _s);
    }

    /*
        检查token是否能兑换出ETH
    */
    function getErcAmount(uint256 _amountEth, address _tokenContractAddress) public view returns (uint256){
        address pair = IUniswapV2Factory(uniswapV2Factory).getPair(_tokenContractAddress, weth);
        if (pair == address(0)) {
            return 0;
        }
        address[] memory path = new address[](2);
        path[0] = _tokenContractAddress;
        path[1] = weth;
        uint256[] memory amounts = IUniswapV2Router02(uniswapV2Router02).getAmountsIn(_amountEth, path);
        return amounts[0];
    }

    /*
        @Params
            _sellAmount : 要卖出的token数量
            _sellTokenAddress : 要卖出的token合约地址
            _buyTokenAddress : 要买入的token合约地址
            _fee : 费用
        @returns
            amountB: 卖出指定数量amountA,能获取的tokenB数量
            transformationAddress: 中间路由代币合约地址
            time: 当前时间
            amountByAddFee : amountA加上fee后的数量,能兑换出的amountB
    */
    function getAmountsOut(uint256 _sellAmount, address _sellTokenAddress, address _buyTokenAddress, uint256 _fee) public view returns (uint256, address, uint256, uint256){
        (uint256 amountB,address transformationAddress,uint256 time) = getAmountsOut(_sellAmount, _sellTokenAddress, _buyTokenAddress);
        (uint256 amountByAddFee,,) = getAmountsOut(_sellAmount + _fee, _sellTokenAddress, _buyTokenAddress);
        return (amountB, transformationAddress, time, amountByAddFee);
    }


    /*
        @Params
            _sellAmount : 要卖出的token数量
            _sellTokenAddress : 要卖出的token合约地址
            _buyTokenAddress : 要买入的token合约地址
        @returns
            amountB: 卖出指定数量tokenA,能获取的tokenB数量
            transformationAddress: 中间路由代币合约地址
            time: 当前时间
    */
    function getAmountsOut(uint256 _sellAmount, address _sellTokenAddress, address _buyTokenAddress) public view returns (uint256, address, uint256){
        require(_sellTokenAddress != address(0) && _buyTokenAddress != address(0), "token contract address cannot be 0");
        require(_sellAmount > 0, "token amount must be greater than 0");
        uint256 size = transformationTokens.length;
        uint256 amounts1;
        uint256 amounts2;
        address transformationAddress;
        if (size == 0) {
            require(IUniswapV2Factory(uniswapV2Factory).getPair(_sellTokenAddress, _buyTokenAddress) != address(0), "this exchange is error");
            uint256[] memory amounts = IUniswapV2Router02(uniswapV2Router02).getAmountsOut(_sellAmount, _getPathBy2(_sellTokenAddress, _buyTokenAddress));
            require(_sellAmount == amounts[0], "sellAmount and return amounts1[0] is not equal");
            amounts1 = amounts[1];
        }
        for (uint256 i; i < size; i++) {
            address addr = transformationTokens[i];
            (uint256 amountsOut,uint256 state) = _getAmountsOut(_sellAmount, _sellTokenAddress, _buyTokenAddress, addr);
            if (amountsOut > amounts2 && state > 0) {
                amounts2 = amountsOut;
                if (state == 1) {
                    transformationAddress = address(0);
                } else if (state == 2) {
                    transformationAddress = addr;
                }
            }
        }
        if (amounts1 >= amounts2) {
            return (amounts1, address(0), block.timestamp);
        } else {
            return (amounts2, transformationAddress, block.timestamp);
        }
    }

    // state -> 1: USDT-USDC  2: USDT-DAI-USDC
    function _getAmountsOut(uint256 _sellAmount, address _sellTokenAddress, address _buyTokenAddress, address _transformationAddress) private view returns (uint256, uint256){
        if (IUniswapV2Factory(uniswapV2Factory).getPair(_sellTokenAddress, _buyTokenAddress) != address(0)) {
            uint256[] memory amounts1 = IUniswapV2Router02(uniswapV2Router02).getAmountsOut(_sellAmount, _getPathBy2(_sellTokenAddress, _buyTokenAddress));
            if (IUniswapV2Factory(uniswapV2Factory).getPair(_sellTokenAddress, _transformationAddress) != address(0) && IUniswapV2Factory(uniswapV2Factory).getPair(_transformationAddress, _buyTokenAddress) != address(0)) {
                uint256[] memory amounts2 = IUniswapV2Router02(uniswapV2Router02).getAmountsOut(_sellAmount, _getPathBy3(_sellTokenAddress, _transformationAddress, _buyTokenAddress));
                if (amounts1[1] < amounts2[2]) {
                    require(_sellAmount == amounts2[0], "sellAmount and return amounts2[0] is not equal");
                    return (amounts2[2], 2);
                }
            }
            require(_sellAmount == amounts1[0], "sellAmount and return amounts1[0] is not equal");
            return (amounts1[1], 1);
        } else {
            if (IUniswapV2Factory(uniswapV2Factory).getPair(_sellTokenAddress, _transformationAddress) != address(0) && IUniswapV2Factory(uniswapV2Factory).getPair(_transformationAddress, _buyTokenAddress) != address(0)) {
                uint256[] memory amounts2 = IUniswapV2Router02(uniswapV2Router02).getAmountsOut(_sellAmount, _getPathBy3(_sellTokenAddress, _transformationAddress, _buyTokenAddress));
                require(_sellAmount == amounts2[0], "sellAmount and return amounts2[0] is not equal");
                return (amounts2[2], 2);
            } else {
                return (0, 0);
            }
        }
    }

    /*
        @Params
            _buyAmount : 要买入的token数量
            _sellTokenAddress : 要卖出的token合约地址
            _buyTokenAddress : 要买入的token合约地址
        @returns
            要卖出的token数量
            实际买入的token数量
            当前时间
    */
    function getAmountsIn(uint256 _buyAmount, address _sellTokenAddress, address _buyTokenAddress) public view returns (uint256, address, uint256){
        require(_sellTokenAddress != address(0) && _buyTokenAddress != address(0), "token contract address cannot be 0");
        require(_buyAmount > 0, "token amount must be greater than 0");
        uint256 size = transformationTokens.length;
        if (size == 0) {
            require(IUniswapV2Factory(uniswapV2Factory).getPair(_sellTokenAddress, _buyTokenAddress) != address(0), "this exchange is error");
            uint256[] memory amounts = IUniswapV2Router02(uniswapV2Router02).getAmountsIn(_buyAmount, _getPathBy2(_sellTokenAddress, _buyTokenAddress));
            require(_buyAmount == amounts[1], "sellAmount and return amounts1[0] is not equal");
            return (amounts[0], address(0), block.timestamp);
        }
        uint256 amountA;
        address transformationAddress;
        for (uint256 i; i < size; i++) {
            address addr = transformationTokens[i];
            (uint256 amountsIn,uint256 state) = _getAmountsIn(_buyAmount, _sellTokenAddress, _buyTokenAddress, addr);
            if ((amountA == 0 || amountsIn < amountA) && amountsIn > 0 && state > 0) {
                amountA = amountsIn;
                if (state == 1) {
                    transformationAddress = address(0);
                } else if (state == 2) {
                    transformationAddress = addr;
                }
            }
        }
        return (amountA, transformationAddress, block.timestamp);
    }

    // state -> 1: USDT-USDC  2: USDT-DAI-USDC
    function _getAmountsIn(uint256 _buyAmount, address _sellTokenAddress, address _buyTokenAddress, address _transformationAddress) private view returns (uint256, uint256){
        address pairA = IUniswapV2Factory(uniswapV2Factory).getPair(_sellTokenAddress,_transformationAddress);
        address pairB = IUniswapV2Factory(uniswapV2Factory).getPair(_transformationAddress, _buyTokenAddress);

        uint256 amountInBy2;
        uint256 amountInBy3;
        uint112 reserve0;
        uint112 reserve1;

        if (pairA != address(0) && pairB != address(0)) {
            (reserve0, reserve1, ) = IUniswapV2Pair(pairB).getReserves();
            if(IUniswapV2Pair(pairB).token0() == _buyTokenAddress){
                reserve1 = reserve0;
            }
            if(_buyAmount < reserve1){
                (reserve0, reserve1, ) = IUniswapV2Pair(pairA).getReserves();
                if(IUniswapV2Pair(pairA).token0() == _transformationAddress){
                    reserve1 = reserve0;
                }
                if(IUniswapV2Router02(uniswapV2Router02).getAmountsIn(_buyAmount, _getPathBy2(_transformationAddress, _buyTokenAddress))[0] < reserve1){
                    amountInBy3 = IUniswapV2Router02(uniswapV2Router02).getAmountsIn(_buyAmount, _getPathBy3(_sellTokenAddress, _transformationAddress, _buyTokenAddress))[0];
                }
            }
        }

        if(IUniswapV2Factory(uniswapV2Factory).getPair(_sellTokenAddress, _buyTokenAddress) != address(0)){
            (reserve0, reserve1, ) = IUniswapV2Pair(IUniswapV2Factory(uniswapV2Factory).getPair(_sellTokenAddress, _buyTokenAddress)).getReserves();
            if(IUniswapV2Pair(IUniswapV2Factory(uniswapV2Factory).getPair(_sellTokenAddress, _buyTokenAddress)).token0() == _buyTokenAddress){
                reserve1 = reserve0;
            }
            if(_buyAmount < reserve1){
                amountInBy2 = IUniswapV2Router02(uniswapV2Router02).getAmountsIn(_buyAmount, _getPathBy2(_sellTokenAddress, _buyTokenAddress))[0];
            }
        }

        if(amountInBy2 == 0 && amountInBy3 == 0){
            return (0,0);
        }else if(amountInBy2 == 0){
            return (amountInBy3,2);
        }else if(amountInBy3 == 0){
            return (amountInBy2,1);
        }else if(amountInBy2 <= amountInBy3){
            return (amountInBy2,1);
        }else{
            return (amountInBy3,2);
        }
    }

    /*
        查询token兑换出支持代币的最优策略
        type -> 0:不支持类型，1:USDT,2:DAI，3:USDC,4:WBTC,5:WETH
    */
    function getFee(uint256 _ethAmount, address _tokenContractAddress) public view returns (uint256, address){
        if(_ethAmount == 0){
            _ethAmount = 1e14;
        }
        if(_tokenContractAddress == weth){
            return (_ethAmount,weth);
        }
        uint256 amountByEth = getAmountsInByExactSupportToken(_tokenContractAddress, weth, _ethAmount);

        uint256 usdtAmount = getAmountsInByExactSupportToken(usdt, weth, _ethAmount);
        if (_tokenContractAddress == usdt) {
            return (usdtAmount, usdt);
        }
        uint256 amountByUsdt = getAmountsInByExactSupportToken(_tokenContractAddress, usdt, usdtAmount);

        uint256 usdcAmount = getAmountsInByExactSupportToken(usdc, weth, _ethAmount);
        if (_tokenContractAddress == usdc) {
            return (usdcAmount, usdc);
        }
        uint256 amountByUsdc = getAmountsInByExactSupportToken(_tokenContractAddress, usdc, usdcAmount);

        uint256 daiAmount = getAmountsInByExactSupportToken(dai, weth, _ethAmount);
        if (_tokenContractAddress == dai) {
            return (daiAmount, dai);
        }
        uint256 amountByDai = getAmountsInByExactSupportToken(_tokenContractAddress, dai, daiAmount);

        uint256 wbtcAmount = getAmountsInByExactSupportToken(wbtc, weth, _ethAmount);
        if (_tokenContractAddress == wbtc) {
            return (wbtcAmount, wbtc);
        }
        uint256 amountByWbtc = getAmountsInByExactSupportToken(_tokenContractAddress, wbtc, wbtcAmount);

        if (amountByEth>0 && isMin(amountByEth, amountByUsdt) && isMin(amountByEth, amountByUsdc) && isMin(amountByEth, amountByDai) && isMin(amountByEth, amountByWbtc)) return (amountByEth, weth);
        if (amountByUsdt>0 && isMin(amountByUsdt, amountByEth) && isMin(amountByUsdt, amountByUsdc) && isMin(amountByUsdt, amountByDai) && isMin(amountByUsdt, amountByWbtc)) return (amountByUsdt, usdt);
        if (amountByUsdc>0 && isMin(amountByUsdc, amountByUsdt) && isMin(amountByUsdc, amountByEth) && isMin(amountByUsdc, amountByDai) && isMin(amountByUsdc, amountByWbtc)) return (amountByUsdc, usdc);
        if (amountByDai>0 && isMin(amountByDai, amountByUsdt) && isMin(amountByDai, amountByUsdc) && isMin(amountByDai, amountByEth) && isMin(amountByDai, amountByWbtc)) return (amountByDai, dai);
        if (amountByWbtc>0 && isMin(amountByWbtc, amountByUsdt) && isMin(amountByWbtc, amountByUsdc) && isMin(amountByWbtc, amountByDai) && isMin(amountByWbtc, amountByEth)) return (amountByWbtc, wbtc);
        return (0, address(0));
    }

    function isMin(uint256 _a, uint256 _b) public pure returns (bool){
        if (_a <= _b && _b>0) {
            return true;
        } else {
            return false;
        }
    }

    function getAmountsInByExactSupportToken(address _amountInTokenAddress, address _supportTokenAddress, uint256 _supportTokenAmount) public view returns (uint256){
        address pair = IUniswapV2Factory(uniswapV2Factory).getPair(_amountInTokenAddress, _supportTokenAddress);
        if (pair == address(0)) {
            return 0;
        }
        (uint112 reserve0,uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        if(IUniswapV2Pair(pair).token0() == _supportTokenAddress){
            reserve1 = reserve0;
        }
        if(_supportTokenAmount >= reserve1){
            return 0;
        }
        address[] memory path = new address[](2);
        path[0] = _amountInTokenAddress;
        path[1] = _supportTokenAddress;
        uint256[] memory amounts = IUniswapV2Router02(uniswapV2Router02).getAmountsIn(_supportTokenAmount, path);
        if (amounts[1] == _supportTokenAmount) {
            return amounts[0];
        }
        return 0;
    }

    /*
        传入两个代币地址，查看是否有流动性池
    */
    function getPair(address _tokenA, address _tokenB) public view returns (address){
        return IUniswapV2Factory(uniswapV2Factory).getPair(_tokenA, _tokenB);
    }

    /*
        批量获取代币余额
    */
    function getBalanceByBatch(address[] memory _contractAddrs, address _user, address _spender) public view returns (bytes memory balances, bytes memory approveValues){
        bool success;
        uint256 balance;
        uint256 approveValue;
        bytes memory data;
        for (uint256 i; i < _contractAddrs.length; i++){
            // IERC20 erc = IERC20(_contractAddrs[i]);
            // uint256 balance = erc.balanceOf(_user);
            (success,data) = _contractAddrs[i].staticcall(abi.encodeWithSignature("balanceOf(address)",_user));
            if(success){
                (balance) = abi.decode(data,(uint256));
            }else{
                balance = 0;
            }
            (success,data) = _contractAddrs[i].staticcall(abi.encodeWithSignature("allowance(address,address)",_user,_spender));
            if(success){
                (approveValue) = abi.decode(data,(uint256));
            }else{
                approveValue = 0;
            }
            // uint256 approveValue = erc.allowance(_user,_spender);
            if (i == 0){
                balances = uintToBytes(balance);
                approveValues = uintToBytes(approveValue);
            }else{
                bytes memory bBytes = uintToBytes(balance);
                balances = bytesAddBytes(balances, bBytes);
                bytes memory approveBytes = uintToBytes(approveValue);
                approveValues = bytesAddBytes(approveValues, approveBytes);
            }
        }
    }
    /*
        获取代币相信信息
    */
    function getTokenInfo(address _contractAddr, address _user, address _spender) public view returns (string memory name,string memory symbol, uint8 decimal, uint256 balance,uint256 approveValue){
        IERC20 erc = IERC20(_contractAddr);
        name = erc.name();
        symbol = erc.symbol();
        decimal = erc.decimals();
        balance = erc.balanceOf(_user);
        approveValue = erc.allowance(_user, _spender);
    }

    function bytesAddBytes(bytes memory _a, bytes memory _b) public pure returns (bytes memory c){
        c = new bytes(_a.length + _b.length);
        uint256 k;
        for (uint i; i < _a.length; i++){
            c[k] = _a[i];
            k++;
        }
        for (uint i; i < _b.length; i++){
            c[k] = _b[i];
            k++;
        }
    }

    function strAddStr(uint256 _amountA, uint256 _amountB) public pure returns (bytes memory c){
        bytes memory a = uintToBytes(_amountA);
        bytes memory b = uintToBytes(_amountB);
        c = new bytes(64);
        uint256 k;
        for(uint i; i < a.length; i++){
            c[k] = a[i];
            k++;
        }
        for (uint i; i < b.length; i++){
            c[k] = b[i];
            k++;
        }
    }

    function uintToBytes(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {mstore(add(b, 32), x)}
    }

    function getNow() public view returns(uint256){
        return block.timestamp;
    }


}

contract A{

    function verifyMessage(string memory _data, bytes32 _r, bytes32 _s, uint8 _v) public pure returns (address){
        return ecrecover(keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32',keccak256(bytes(_data)))), _v, _r, _s);
    }
    function verifyMessage(bytes memory _data, bytes32 _r, bytes32 _s, uint8 _v) public pure returns (address){
        return ecrecover(keccak256(bytes(_data)), _v, _r, _s);
    }
    function verifyMessage(bytes32 _data, bytes32 _r, bytes32 _s, uint8 _v) public pure returns (address){
        return ecrecover(keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32',_data)), _v, _r, _s);
    }
    function verifyMessage2(bytes32 _data, bytes32 _r, bytes32 _s, uint8 _v) public pure returns (address){
        return ecrecover(_data, _v, _r, _s);
    }
}

contract B{
    function verifyMesage(address[] memory _toAddrs)public pure returns(bytes memory){
        return abi.encode(_toAddrs);
    }
    function verifyMesage(bytes[] memory _datas)public pure returns(bytes memory){
        return abi.encode(_datas);
    }
}

// 0x18cbafe500000000000000000000000000000000000000000000000061246a4864a86c980000000000000000000000000000000000000000000000006124490372c7800000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000132cc4e1cd38aa3b022c757b1802f73af2f6da150000000000000000000000000000000000000000000000000000000062b5b2950000000000000000000000000000000000000000000000000000000000000002000000000000000000000000d0a1e359811322d97991e03f863a0c30c2cf029c000000000000000000000000d0a1e359811322d97991e03f863a0c30c2cf029c

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IUniswapV2Pair {

    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function transferFrom(address, address, uint256) external;

    function approve(address, uint256) external;

    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IUniswapV2Router02 {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// 0x8803dbee
// 0000000000000000000000000000000000000000000000000000000017240873
// 000000000000000000000000000000000000000000000000016345785d8a0000
// 00000000000000000000000000000000000000000000000000000000000000a0
// 000000000000000000000000132cc4e1cd38aa3b022c757b1802f73af2f6da15
// 0000000000000000000000000000000000000000000000000000000062b4062c
// 0000000000000000000000000000000000000000000000000000000000000003
// 000000000000000000000000d8d4c4edbe4fe6856ff7775d81aa818cecb2d9da
// 000000000000000000000000c6a9f564b25900e222f9831ff01c97525a846ccf
// 000000000000000000000000d0a1e359811322d97991e03f863a0c30c2cf029c

// 0x18cbafe5
// 0000000000000000000000000000000000000000000000000000000005f1aecc
// 0000000000000000000000000000000000000000000000000093aa8fdcaa0cac
// 00000000000000000000000000000000000000000000000000000000000000a0
// 000000000000000000000000132cc4e1cd38aa3b022c757b1802f73af2f6da15
// 0000000000000000000000000000000000000000000000000000000062b41041
// 0000000000000000000000000000000000000000000000000000000000000002
// 000000000000000000000000d8d4c4edbe4fe6856ff7775d81aa818cecb2d9da
// 000000000000000000000000eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IUniswapV2Factory {
    function getPair(address, address) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "./IERC20.sol";

abstract contract IDeforFactory {
    address public owner;
    bytes32 public immutable DOMAIN_SEPARATOR;
    bool public paused = false;
    uint256 public unlocked = 1;
    address public pendingOwner;

    event Pause();
    event Unpause();

    constructor(){
        uint256 chainId;
        assembly{
            chainId := chainid()
        }
        owner = msg.sender;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes("Defor Protocol")),
                keccak256(bytes("1.0")),
                chainId,
                address(this)
            ));
    }

    /*
        取回所有的ETH
    */
    function withdrawEth() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    /*
        取回所有的ERC20
    */
    function withdrawErc(address _contractAddress) external {
        IERC20 erc = IERC20(_contractAddress);
        erc.transfer(msg.sender, erc.balanceOf(address(this)));
    }

      
    /*
        修改管理员
    */
    function updatePendingOwner(address _pendingOwner) external onlyOwner {
        require(_pendingOwner != address(0), "PendingOwner cannot be zero");
        pendingOwner = _pendingOwner;
    }
    /*
        确认修改管理员
    */
    function updateOwner() external onlyPendingOwner {
        owner = msg.sender;
        pendingOwner = address(0);
    }
    /*
        用于接收ERC721代币
    */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4){
    }


    /*** MODIFIERS ***/
    /*
       Modifier to make a function callable only when the contract is not paused.
    */
    modifier whenNotPaused() {
        require(!paused, 'Paused');
        _;
    }

    /*
        仅限管理员操作
    */
    modifier onlyOwner(){
        require(owner == msg.sender, 'Unauthorized');
        _;
    }

    /*
        仅限新设置的管理员操作
    */
    modifier onlyPendingOwner(){
        require(pendingOwner == msg.sender, 'Unauthorized');
        _;
    }

    modifier lock() {
        require(unlocked == 1, 'Locked');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}