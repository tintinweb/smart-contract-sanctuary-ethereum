// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
import "../IUniswapV2Pair.sol";
// import "./IDMMPool.sol";

import "../IUniswapV3Pool.sol";
import "../pool/IUniswapV3SwapCallback.sol";
import "../TransferHelper.sol";

import "../IUniswapV3FlashCallback.sol";
import "../IUniswapV2Callee.sol";
import "../IBancorExchange.sol";
import "../IWETH9.sol";
import "../IConverter.sol"; 
import "../IConverterAnchor.sol"; 

//主网地址：0xaeAAE13E98e1252411b0b6aa9f509830d626b5f4 
////////////////////////////////////////////////////////////////////////需要更改地址
contract V2V3FalshV2V3loan_Bancor is IUniswapV3SwapCallback, IUniswapV3FlashCallback,
    IUniswapV2Callee 
{
    bool private trig = false;
    address constant ethBancor=0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; 
    mapping(address => bool) LegalUsers; 

    //goerli
    address constant weth  =0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;  
    IBancorExchange private BancorExchange= IBancorExchange(payable(0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0));  
    address public constant owner = payable(0xC35602711F647B8c88016cAf1212861bb07e5a50);       
    //Mainnet
    // address constant weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;  
    // IBancorExchange private BancorExchange = IBancorExchange(payable(0x2F9EC37d6CcFFf1caB21733BdaDEdE11c823cCB0)); 
    // address public constant owner = payable(0x1dD215B383595b55159f62e965A055A26f90e906);   
    
    modifier onlyAdmin {
        require(
            msg.sender == owner  ,
            "Only owner can call this function."
        );
        _;
    } 
    
    receive() external payable {}
    
    function setUsers(address[] memory _addrsAdd,address[] memory _addrskill) public onlyAdmin{
        // Update the value at this address
        if(_addrsAdd.length>0){ 
            for (uint256 i = 0; i <= _addrsAdd.length - 1; i++) {
                LegalUsers[_addrsAdd[i]] =true;
            }
        }
        if(_addrskill.length>0){ 
            for (uint256 i = 0; i <= _addrskill.length - 1; i++) {
                delete LegalUsers[_addrskill[i]];
            }
        }
    }
    
    function getUsers(address _addr) public view returns (bool) {
        // Mapping always returns a value.
        // If the value was never set, it will return the default value.
        return LegalUsers[_addr];
    }

    modifier onlyOwner {
        require(
            LegalUsers[msg.sender] || msg.sender == owner,
            "Only User can call this function."
        );
        _;
    }

    function setBancor(address newBancorRouter) public onlyAdmin  {
        BancorExchange = IBancorExchange(payable(newBancorRouter));
    }


/*  // modifier unlockCallback {
    //     trig=true;
    //     _;
    //     trig=false;
    // }
*/
    function gettrig() public view onlyOwner returns (bool trig0 , IBancorExchange BancorExchange0) {
        trig0=trig;
        BancorExchange0=BancorExchange;
    }

    function puttrig() public onlyOwner returns (bool) {
        trig = false;
        return trig;
    }

    function DrawBack(
        address token,
        uint256 amount,
        uint256 amoutETH
    ) public payable onlyOwner {
        if (amoutETH > 0) TransferHelper.safeTransferETH(owner, amoutETH);
        if (amount > 0) TransferHelper.safeTransfer(token, owner, amount);
    }

    function uniSwapByOut(
        uint256 trueAmountOut,
        address tokenOut,
        address poolAdd,
        address to
    ) private {
        IUniswapV2Pair pair = IUniswapV2Pair(poolAdd);
        address token1 = pair.token1();
        uint256 amount0Out = 0;
        uint256 amount1Out = 0;
        if (tokenOut < token1) amount0Out = trueAmountOut;
        else amount1Out = trueAmountOut;
        pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }

    function getAmountOut0(
        uint256 amountIn,
        address tokenIn,
        address poolAdd
    ) public view returns (uint256 amountOut, address tokenOut) {
        IUniswapV2Pair pair = IUniswapV2Pair(poolAdd);
        address token0 = pair.token0();
        uint256 reserveOut;
        uint256 reserveIn;
        if (tokenIn == token0) {
            (reserveIn, reserveOut, ) = pair.getReserves();
            tokenOut = pair.token1();
        } else {
            (reserveOut, reserveIn, ) = pair.getReserves();
            tokenOut = token0;
        }
        uint256 amountInWithFee = amountIn * (997);
        uint256 numerator = amountInWithFee * (reserveOut);
        uint256 denominator = reserveIn * (1000) + (amountInWithFee);
        amountOut = numerator / denominator;
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn,
        address pair
    ) public view returns (uint256 amountOut, address tokenOut) {
        assembly { 
            let ptr := mload(0x40)
            // token0()
            mstore(ptr, 0x0dfe168100000000000000000000000000000000000000000000000000000000) 
            let res1 := staticcall(gas(), pair, ptr, 4, add(ptr, 4), 32)
            if eq(res1, 0){ revert(0, 0) }
            let token0 := mload(add(ptr, 4))

            let reserveOut
            let reserveIn
            // getReserves()
            mstore(ptr, 0x0902f1ac00000000000000000000000000000000000000000000000000000000) 
            res1 := staticcall(gas(), pair, ptr, 4, add(ptr, 4), 64)
            if eq(res1, 0) { revert(0, 0) }
            let ifeq := eq(tokenIn, token0)
            switch ifeq
            case 1 {
                reserveIn := mload(add(ptr, 4))
                reserveOut := mload(add(ptr, 36)) 
                // token1()
                ptr := mload(0x40)
                mstore(ptr, 0xd21220a700000000000000000000000000000000000000000000000000000000) 
                res1 := staticcall(gas(), pair, ptr, 4, add(ptr, 4), 32)
                if eq(res1, 0) { revert(0, 0) } 
                tokenOut := mload(add(ptr, 4))
            } 
            default {
                reserveOut := mload(add(ptr, 4))
                reserveIn := mload(add(ptr, 36)) 
                tokenOut := token0
            }

            let amountInWithFee := mul(amountIn , 997)
            let numerator := mul(amountInWithFee , reserveOut)
            let denominator := add(mul(reserveIn , 1000), amountInWithFee)
            amountOut := div(numerator, denominator)    
        }
    }



    function getBancorOuttoken(
        address sourceToken,   //输入输出都是weth
        address ankor 
    )public view returns (address targetToken) { 
        IConverterAnchor anchor = IConverterAnchor(ankor); 
        IConverter _converter = IConverter(payable(anchor.owner()));
        targetToken = address(_converter.connectorTokens(0));
        if(sourceToken==weth)sourceToken=ethBancor;
        if(sourceToken==targetToken)
            targetToken = address(_converter.connectorTokens(1));            
        if(targetToken==ethBancor)targetToken=weth; 
    } 

    function ensureAllowance(address _token, address _spender, uint256 _value) private {
        uint256 allowance = IERC20(_token).allowance(address(this), _spender);
        if (allowance < _value) {
            if (allowance > 0)
                TransferHelper.safeApprove(_token, _spender, 0);
            TransferHelper.safeApprove(_token, _spender, _value);
        }
    }

    function TradeBancor(
        uint256 amountIn,
        address[] memory BancPath,
        address to
    )public payable onlyOwner returns (uint256 amountOut) {
        if(BancPath[0]==weth){  //如果输入是weth需要转化为eth才能交易
            BancPath[0]=ethBancor;
            IWETH9(weth).withdraw(amountIn);
        }else{                  //如果输入不是weth需要授权
            ensureAllowance( BancPath[0], address(BancorExchange),  amountIn); 
        }

        uint LastInd=BancPath.length-1;
        if(BancPath[LastInd]==weth)BancPath[LastInd]=ethBancor; 

        if(BancPath[0]==ethBancor) 
            amountOut=BancorExchange.convertFor{value: amountIn}(BancPath, amountIn, 1,to );
        else if (BancPath[LastInd]==ethBancor) {    
            amountOut=BancorExchange.convertFor(BancPath,amountIn,1,address(this));
            IWETH9(weth).deposit{value: amountOut}(); //eth转换为weth
            if(to!=address(this))TransferHelper.safeTransfer(weth, to, amountOut);
        }else amountOut=BancorExchange.convertFor(BancPath,amountIn,1,to);        
    }  

    function TradeBancor3jump(
        uint256 amountIn,
        address tokenIn,
        address ankor,
        address to
    )public payable onlyOwner returns (uint256 amountOut, address tokenOut) {
        tokenOut=getBancorOuttoken(tokenIn,ankor);
        address[] memory BancPath = new address[](3);
        BancPath[0]=tokenIn;
        BancPath[1]=ankor;
        BancPath[2]=tokenOut;
        //https://docs.soliditylang.org/en/develop/types.html?highlight=array#members 
        amountOut = TradeBancor(amountIn,BancPath,to);
    }

    function UniV3Swap(
        uint256 amountIn,
        address tokenIn,
        address poolAdd,
        address recipient,
        bytes memory data
    ) private returns (uint256 amountOut, address tokenOut) {
        // uint160 MIN_SQRT_RATIO = 4295128739;
        // uint160 MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
        address token0 = IUniswapV3Pool(poolAdd).token0();
        if (tokenIn == token0) tokenOut = IUniswapV3Pool(poolAdd).token1();
        else tokenOut = token0;
        bool zeroForOne = tokenIn < tokenOut;
        (int256 amount0, int256 amount1) = IUniswapV3Pool(poolAdd).swap(
            recipient,
            zeroForOne,
            int256(amountIn),
            zeroForOne
                ? 4295128740
                : 1461446703485210103287273052203988822378723970341,
            data
        );
        amountOut = uint256(-(zeroForOne ? amount1 : amount0));
    }



    /// @inheritdoc IUniswapV3SwapCallback
    //在SwapCallback中，address(this)是该合约, msg.sender是pool
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        if (!trig) revert("trig");
        (
            uint8 exchange,
            address tokenOut,
            address poolAdd,
            bytes memory data2Dec
        ) = abi.decode(_data, (uint8, address, address, bytes)); //为了减少一次encode decode
        // 这个V3需要打入的量amountIn和换出的量amountOut
        uint256 amountIn2payback = amount0Delta > 0
            ? uint256(amount0Delta)
            : uint256(amount1Delta);
        if (exchange <= 2) {
            // uniSwapV2
            uniSwapByOut(amountIn2payback, tokenOut, poolAdd, msg.sender);
        } else if (exchange == 255) {
            //从address(this)打给V3
            TransferHelper.safeTransfer(tokenOut, msg.sender, amountIn2payback);
        } else if (exchange == 254) {
            //flashswapV3
            uint256 amountOut2Trade = amount0Delta < 0
                ? uint256(-amount0Delta)
                : uint256(-amount1Delta);

            address tokenIn0 = poolAdd;
            (
                uint8 judge,
                uint256 tokenUsed_AsGas,
                uint8[] memory exchanges,
                address[] memory pools
            ) = abi.decode(data2Dec, (uint8, uint256, uint8[], address[]));

            (amountOut2Trade, tokenOut) = TradeFrom2(
                amountOut2Trade,
                tokenOut,
                exchanges,
                pools
            );
            if (judge > 1)
                require(
                    amountOut2Trade >
                        tokenUsed_AsGas + amountIn2payback &&
                        tokenOut == tokenIn0,
                    "0000000no profit: profit<Gascost"
                );
            TransferHelper.safeTransfer(tokenOut, msg.sender, amountIn2payback);
        }
    }

    function noFlashTrade1026994(
        uint8 judge,
        address tokenIn0,
        uint256 tokenUsed_AsGas,
        uint256 amountIn,
        uint8[] memory exchanges,
        address[] memory pools,
        bytes32 expectedParentHash
    ) public payable onlyOwner {         
        if(judge>=3)require(blockhash(block.number - 1) == expectedParentHash, "block was uncled");
        trig = true;
        if (exchanges[0] <= 2) IERC20(tokenIn0).transfer(pools[0], amountIn); //第一次从钱包转账到pool
        (uint256 amountOut, address tokenOut) = TradeFrom2(
            amountIn,
            tokenIn0,
            exchanges,
            pools
        );
        if (judge >= 1)
            require(amountOut >= amountIn, "000no profit: amountOut<amountIn");
        if (judge > 1)
            require( amountOut >tokenUsed_AsGas + amountIn, "0000000no profit: profit<Gascost" );
        trig = false;
    }

    function FlashTrade545355(
        uint8 extype0,
        address pool0,
        uint8 judge,
        address tokenIn0,
        uint256 tokenUsed_AsGas,
        uint256 amountIn,
        uint8[] memory exchanges,
        address[] memory pools,
        bytes32 expectedParentHash
    ) public payable onlyOwner {         
        if(judge>=3)require(blockhash(block.number - 1) == expectedParentHash, "block was uncled");
        trig = true;
        if (extype0 <= 1) {
            (uint256 amountOut, address tokenOut) = getAmountOut(
                amountIn,
                tokenIn0,
                pool0
            ); //dmm的flashswap不通用
            bytes memory data = abi.encode(
                judge,
                tokenIn0,
                tokenUsed_AsGas,
                amountIn,
                tokenOut,
                exchanges,
                pools
            );

            IUniswapV2Pair pair = IUniswapV2Pair(pool0);
            address token1 = pair.token1();
            uint256 amount0Out = 0;
            uint256 amount1Out = 0;
            if (tokenOut < token1) amount0Out = amountOut;
            else amount1Out = amountOut;
            pair.swap(
                amount0Out,
                amount1Out,
                address(this), //直接打给下个V2pool会失败。
                data
            );
        } else if (extype0 == 203) {
            //触发Callback中的flashswapV3
            IUniswapV3Pool ipoolv3 = IUniswapV3Pool(pool0);
            address tokenOut = ipoolv3.token0();
            if (tokenIn0 == tokenOut) tokenOut = ipoolv3.token1();

            // exchange = 254,进入v3swapcallback中的254分支
            bytes memory data = abi.encode(
                254,
                tokenOut,
                tokenIn0,
                abi.encode(judge, tokenUsed_AsGas, exchanges, pools)
            );

            //如果下个是v2的话，可以直接打过去
            bool zeroForOne = tokenIn0 < tokenOut;
            address to = exchanges[0] <= 2 ? pools[0] : address(this);
            IUniswapV3Pool(pool0).swap(
                to, //address(this),//
                zeroForOne,
                int256(amountIn),
                zeroForOne
                    ? 4295128740
                    : 1461446703485210103287273052203988822378723970341,
                data
            );
        } else if (extype0 == 204) {
            //触发的V3flashLoan
            bytes memory data = abi.encode(
                judge,
                tokenIn0,
                tokenUsed_AsGas,
                amountIn,
                exchanges,
                pools
            );
            IUniswapV3Pool ipoolv3 = IUniswapV3Pool(pool0);
            (uint256 amount0, uint256 amount1) = tokenIn0 == ipoolv3.token0()
                ? (amountIn, uint256(0))
                : (uint256(0), amountIn);
            address to = exchanges[0] <= 2 ? pools[0] : address(this);
            ipoolv3.flash(to, amount0, amount1, data);
        }
        trig = false;
    }

    function uniswapV3FlashCallback(
        //在这里还钱
        uint256 fee0, //这个是要给的token0费用
        uint256 fee1, //这个是要给的token1费用
        bytes calldata data
    ) external override {
        if (!trig) revert("trig");
        (
            uint8 judge,
            address tokenIn0,
            uint256 tokenUsed_AsGas,
            uint256 amountIn,
            uint8[] memory exchanges,
            address[] memory pools
        ) = abi.decode(
                data,
                (uint8, address, uint256, uint256, uint8[], address[])
            );
        (uint256 amountOut, address tokenOut) = TradeFrom2(
            amountIn,
            tokenIn0,
            exchanges,
            pools
        );
        if (judge > 1)
            require(
                amountOut >
                    tokenUsed_AsGas + amountIn &&
                    tokenOut == tokenIn0,
                "0000000no profit: profit<Gascost"
            );
        amountIn = amountIn + fee0 + fee1;
        IERC20(tokenIn0).transfer(msg.sender, amountIn);
    }

    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external override {
        if (!trig) revert("trig");
        (
            uint8 judge,
            address tokenIn0,
            uint256 tokenUsed_AsGas,
            uint256 amountBack,
            address tokenOut,
            uint8[] memory exchanges,
            address[] memory pools
        ) = abi.decode(
                _data,
                (uint8, address, uint256, uint256, address, uint8[], address[])
            );
        uint256 amountOut = _amount0 > 0 ? _amount0 : _amount1;

        if (exchanges[0] <= 2) IERC20(tokenOut).transfer(pools[0], amountOut);
        (amountOut, tokenOut) = TradeFrom2(
            amountOut,
            tokenOut,
            exchanges,
            pools
        );
        if (judge > 1)
            require(
                amountOut >
                    tokenUsed_AsGas + amountBack &&
                    tokenOut == tokenIn0,
                "0000000no profit: profit<Gascost"
            );
        IERC20(tokenIn0).transfer(msg.sender, amountBack);
    }

    function TradeFrom2(
        uint256 amountIn,
        address tokenIn,
        uint8[] memory exchanges,
        address[] memory pools
    ) private returns (uint256 amountOut, address tokenOut) {
        amountOut = amountIn;
        bytes memory data;
        uint256 poolLen = pools.length;
        uint8 exchange;
        for (uint256 i = 0; i <= poolLen - 1; i++) {
            exchange = exchanges[i];
            address thisPool = pools[i];
            if (i == 0) {   //first round
                // if exchange<=2 已经把钱打给了pool
                if (exchange == 203) {
                    //从钱包打给V3
                    data = abi.encode(255, tokenIn, address(0), abi.encode(0));
                }
            } else tokenIn = tokenOut; //other rounds

            if (i + 1 <= poolLen - 1) {
                //下一个swap的情况
                address nextPool = pools[i + 1];
                if (exchanges[i + 1] <= 2) {
                    //如果下一个所是V2类型的,直接打进去
                    if (exchange <= 2) {
                        (amountOut, tokenOut) = getAmountOut( 
                            amountOut,
                            tokenIn,
                            thisPool
                        );
                        uniSwapByOut(amountOut, tokenOut, thisPool, nextPool);
                    }
                    if (exchange == 203)
                        (amountOut, tokenOut) = UniV3Swap(
                            amountOut,
                            tokenIn,
                            thisPool,
                            nextPool,
                            data
                        );
                    if(exchange == 82)//82=bancor
                        (amountOut, tokenOut) =TradeBancor3jump(amountOut,tokenIn,thisPool,nextPool);
                } else if (exchanges[i + 1] == 203) {
                    //如果下一个所是V3类型的
                    if (exchange <= 2) {
                        // only query, no V2swap. V2swap execute in callback of NextUniv3
                        (amountOut, tokenOut) = getAmountOut( 
                            amountOut,
                            tokenIn,
                            thisPool
                        ); //amountOut as nextV3 input
                        // 从V2打给V3
                        data = abi.encode(
                            exchange,
                            tokenOut,
                            thisPool,
                            abi.encode(0)
                        );
                    }
                    if (exchange == 203) {
                        // ThisV3 to address(this)
                        (amountOut, tokenOut) = UniV3Swap(
                            amountOut,
                            tokenIn,
                            thisPool,
                            address(this),
                            data
                        );
                        // address(this) to nextV3, will execute in callback of NextUniv3
                        data = abi.encode(
                            255,
                            tokenOut,
                            address(0),
                            abi.encode(0)
                        );
                    }
                    if(exchange == 82){//82=bancor
                        //如果想直接打给V3，那么需要计算quoteBancor，作为V3输入。耗费更多
                        (amountOut, tokenOut) =TradeBancor3jump(amountOut,tokenIn,thisPool,address(this));
                        data = abi.encode(255,tokenOut,address(0),abi.encode(0));
                    }
                    
                }
            } else if (i + 1 == poolLen) {
                //最后一步给回钱包
                if (exchange <= 2) {
                    (amountOut, tokenOut) = getAmountOut( 
                        amountOut,
                        tokenIn,
                        thisPool
                    );
                    uniSwapByOut(amountOut, tokenOut, thisPool, address(this));
                }
                if (exchange == 203)
                    (amountOut, tokenOut) = UniV3Swap(
                        amountOut,
                        tokenIn,
                        thisPool,
                        address(this),
                        data
                    );
                if(exchange == 82)  //82=bancor
                    (amountOut, tokenOut) =TradeBancor3jump(amountOut,tokenIn,thisPool,address(this));                       
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;   

interface IConverterAnchor {
    function owner() external pure returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;  
import "./IOwned.sol"; 
import "./IConverterAnchor.sol"; 
import './IERC20.sol';
// import "./IOwned.sol"; 
import "./IWhitelist.sol"; 

interface IConverter  { //is IOwned
    function converterType() external pure returns (uint16);
    function anchor() external view returns (IConverterAnchor);
    function isActive() external view returns (bool);

    function targetAmountAndFee(IERC20 _sourceToken, IERC20 _targetToken, uint256 _amount) external view returns (uint256, uint256);
    function convert(IERC20 _sourceToken,
                     IERC20 _targetToken,
                     uint256 _amount,
                     address _trader,
                     address payable _beneficiary) external payable returns (uint256);

    function conversionWhitelist() external view returns (IWhitelist);
    function conversionFee() external view returns (uint32);
    function maxConversionFee() external view returns (uint32);
    function reserveBalance(IERC20 _reserveToken) external view returns (uint256);
    receive() external payable;

    function transferAnchorOwnership(address _newOwner) external;
    function acceptAnchorOwnership() external;
    function setConversionFee(uint32 _conversionFee) external;
    function setConversionWhitelist(IWhitelist _whitelist) external;
    function withdrawTokens(IERC20 _token, address _to, uint256 _amount) external;
    function withdrawETH(address payable _to) external;
    function addReserve(IERC20 _token, uint32 _ratio) external;

    // deprecated, backward compatibility
    function token() external view returns (IConverterAnchor);
    function transferTokenOwnership(address _newOwner) external;
    function acceptTokenOwnership() external;
    function connectors(IERC20 _address) external view returns (uint256, uint32, bool, bool, bool);
    function getConnectorBalance(IERC20 _connectorToken) external view returns (uint256);
    function connectorTokens(uint256 _index) external view returns (IERC20);
    function connectorTokenCount() external view returns (uint16);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

import './IERC20.sol'; 

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6; 
 
interface IBancorExchange { 
    // function conversionPath(address _sourceToken,address _targetToken) external view returns (address[]);
 
    function conversionPath(address _sourceToken,address _targetToken) 
        external view returns (address[] memory);

    function rateByPath(address[] memory _path, uint256 _amount) 
        external view returns (uint256);
    
    function convertFor(address[] memory _path, uint256 _amount, uint256 _minReturn,address _beneficiary) 
        external payable returns (uint256); 
    
        function convertByPath(address[] memory _path, uint256 _amount, uint256 _minReturn,address _beneficiary,address _affiliateAccount,uint _affiliateFee) 
        external payable returns (uint256);  
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#flash
/// @notice Any contract that calls IUniswapV3PoolActions#flash must implement this interface
interface IUniswapV3FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IUniswapV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#flash call
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;
 
import './IERC20.sol';

/// @title TransferHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Calls transfer on token contract, errors with TF if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
    
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';


/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0; 
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;
 
 
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */ 
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6; 
 
interface IWhitelist {
    function isWhitelisted(address _address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;  

interface IOwned {
    // this function isn't since the compiler emits automatically generated getter functions as external
    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
    function acceptOwnership() external;
}