/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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
}

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

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // require(
        //     (value == 0) || (token.allowance(address(this), spender) == 0),
        //     "SafeERC20: approve from non-zero to non-zero allowance"
        // );
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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

contract Property{
    using SafeERC20 for IERC20;
    address SushiSwapRouterAddr = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    IUniswapV2Router02 public sushiRouter = IUniswapV2Router02(SushiSwapRouterAddr);

    event setCollateralLog(address collaAddr,uint collaDecimals,string collaName,address USDAddr,string USDName,uint USDDecimals,uint collaRate,uint liquRate,uint apyRate,uint inteRate,uint state);
    event updateCollaToUSDAddrLog(address collaAddr,address USDAddr,string USDName,uint USDDecimals,uint ctime);

    event rateLog(address tokenAddr, uint256 rate);
    event settokenUSDAddrLog(address oldAddr,uint oldDecinal,address newAddr,uint newDecinal);
    event setInteRateLog(uint inteRate,uint newInteRate);

    bool stateFrozen;
    bool notFrozenState;

    //暂停所有交易
    modifier notFrozen()
    {
        require(stateFrozen, "STATE_IS_FROZEN");
        _;
    }

    function setDeno(uint _deno) public {
        require(deno==0,"ERROR");
        deno = _deno;
    }

    //have bug
    function getPath(address tokenIn,address tokenOut)public pure returns(address[] memory){
        //0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619  WETH or WBNB 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
        address pathM = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;

        address[] memory path = new address[](3);
        path[0] = tokenIn;
        if (tokenIn == pathM) {
            path[1] = tokenOut;
        }else{
            path[1] = pathM;
            path[2] = tokenOut;
        }
        return path;
    }

    //USD 转换预估价格
    function tokenChangeToken(address tokenIn,address tokenOut,uint amount) public view returns(uint) {
        if (tokenIn == tokenOut){
            return amount;
        }else{
            uint amountOut = sushiGetSwapTokenAmountOut(getPath(tokenIn,tokenOut),amount);
            return amountOut;
        }
    }

    //价格：预估兑换出的token，用A兑换B，可以兑换出B的数量amountOut
    function sushiGetSwapTokenAmountIn(
        address[] memory path,
        uint amountOut
    ) public view virtual returns (uint) {
        // uint amountIn = sushiRouter.getAmountsIn(
        //     amountOut,
        //     path
        // )[0];
        // return amountIn;

        return amountOut*100/95;
    }

    //价格：预估兑换出的token，用A兑换B，可以兑换出B的数量amountOut
    function sushiGetSwapTokenAmountOut(
        address[] memory path,
        uint amountIn
    ) public view virtual returns (uint) {
        // uint amountOut = sushiRouter.getAmountsOut(
        //     amountIn,
        //     path
        // )[path.length - 1];
        // return amountOut;

        return amountIn*95/100;
    }

    //卖出，把In兑换成Out，Out是稳定币，已在添加抵押物时approve
    function sushiSwapper(
            address[] memory path,
            uint amountIn
        ) public returns(uint){
        // uint amountOut = sushiGetSwapTokenAmountOut(path,amountIn);
        // sushiRouter.swapExactTokensForTokens(
        //     amountIn,
        //     amountOut,
        //     path,
        //     address(this),
        //     block.timestamp + 300
        // );
        // return amountOut;

        return amountIn*95/100;
    }   


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   uint public deno;

    //所有币种
    allTokenPar[] public allToken;
    struct allTokenPar{
        address addr;
        uint _type;//1:抵押物，2:USDAddr，3:stableAddr
        uint ctime;
    }

    function addAllToken(address addr,uint _type) public {
        bool isToken = true;
        for (uint i=0; i<allToken.length; i++){
            if (allToken[i].addr == addr && allToken[i]._type == _type){
                isToken = false;
            }
        }
        if (true) {
            allTokenPar memory m;
            m.addr = addr;
            m._type = _type;
            m.ctime = block.timestamp;
            allToken.push(m);
            emit addAllTokenLog(addr,_type);
        }
    }

    //设置USDAddr
    mapping (address=>USDAddrListPar) public USDAddrList;
    struct USDAddrListPar {
        uint decimals;
        string name;
        uint state;
        uint ctime;
    }
    event setUSDAddrLog(address addr,string name,uint decimals);
    function setUSDAddr(address addr,string memory name, uint state) public {
        uint decimals = getTokenDecimals(addr);
        USDAddrList[addr].decimals = decimals;
        USDAddrList[addr].name = name;
        USDAddrList[addr].state = state;
        if (USDAddrList[addr].ctime ==0) {
            USDAddrList[addr].ctime = block.timestamp;
        }
        addAllToken(addr,2);
        emit setUSDAddrLog(addr,name,decimals);
    }

    //设置stableAddr
    mapping(address=>stableListPar) public stableList;
    struct stableListPar{
        string name;
        uint decimals;
        uint feePer;//乘以deno
        uint feeMin;//个数，没有deno
        uint withdrawMin;//个数，没有deno
        uint state;
        uint ctime;
    }
    event setStableListLog(address addr,string name,uint decimals);
    function setStableList(address addr,string memory name,uint feePer, uint feeMin, uint withdrawMin, uint state) public {
        // require(stableList[addr].ctime==0,"IS_SAME");
        uint decimals = getTokenDecimals(addr);
        stableList[addr].name = name;
        stableList[addr].decimals = decimals;
        stableList[addr].feePer = feePer;
        stableList[addr].feeMin = feeMin;
        stableList[addr].withdrawMin = withdrawMin;
        stableList[addr].state = state;

        if (stableList[addr].ctime ==0) {
            stableList[addr].ctime = block.timestamp;
        }

        addAllToken(addr,3);

        emit setStableListLog(addr,name,decimals);
    }

    // event updateStableListLog(address addr,string name,uint state);
    // function updateStableList(address addr,string memory name,uint state) public {
    //     require(stableList[addr].ctime>0,"IS_SAME");
    //     stableList[addr].name = name;
    //     stableList[addr].state = state;
    //     emit updateStableListLog(addr,name,state);
    // }

    //设置新的抵押物
    mapping(address=>collaListPa) public collaList;//抵押物列表
    struct collaListPa{
        uint decimals;//小数
        string name;
        address USDAddr;
        mapping(address=>address[]) path;
        uint collaRate;//抵押率
        uint liquRate;//清算率
        uint inteRate;//8小时利息利率  54794520547945
        uint apyRate;//年利率
        uint state;//启用状态 0:不启用，1：启用
        uint ctime;
    }

    event setCollaLog(address collaAddr,uint decimals,string name,address USDAddr,uint collaRate,uint liquRate,uint apyRate,uint inteRate,address[] path,uint state);
    event addAllTokenLog(address collaAddr,uint _type);
    function setColla(
        address collaAddr,//抵押物地址
        string memory name,
        address USDAddr,
        uint collaRate,
        uint liquRate,
        uint apyRate,
        address[] memory path,
        uint state
    ) public {
        require(collaAddr != USDAddr, "CANNOT_BE_USD");
        require(collaList[collaAddr].ctime == 0,"existence");
        require(USDAddrList[collaAddr].ctime == 0,"CANNOT_BE_USD_TO");
        require(USDAddrList[USDAddr].ctime > 0,"existence");

        //最少抵押出10%，最高抵押出10倍;
        require(collaRate>deno/10,"COLLARATE_TOO_LOW");
        require(collaRate<10*deno,"COLLARATE_TOO_HIGHT");

        //清算，最少到10%就清算，没有最高
        require(liquRate<10*deno,"liquRATE_TOO_HIGHT");

        //年利率，最高100%，最小为0
        require(apyRate<deno,"apyRATE_TOO_HIGHT");
        

        uint decimals = getTokenDecimals(collaAddr);
        collaList[collaAddr].decimals = decimals;
        collaList[collaAddr].name = name;
        collaList[collaAddr].USDAddr = USDAddr;
        collaList[collaAddr].collaRate = collaRate;
        collaList[collaAddr].liquRate = liquRate;
        collaList[collaAddr].apyRate = apyRate;
        uint inteRate = apyRate/1095;//365*3
        collaList[collaAddr].inteRate = inteRate;
        collaList[collaAddr].path[USDAddr] = path;
        collaList[collaAddr].state = state;
        collaList[collaAddr].ctime = block.timestamp;
        emit setCollaLog(collaAddr,decimals,name,USDAddr,collaRate,liquRate,apyRate,inteRate,path,state);

        addAllToken(collaAddr,1);
    }

    event updateCollaStateLog(address collaAddr,uint state);
    //更改抵押物状态
    function updateCollaState(address collaAddr,uint state) public {
        require(collaList[collaAddr].ctime>0,"NOT_EXISTENCE");
        require(state<=1,"STATE_ERROR");
        collaList[collaAddr].state = state;
        emit updateCollaStateLog(collaAddr,state);
    }

    event updatePathLog(address collaAddr,address USDAddr,address[] path);
    //修改path
    function updatePath(address collaAddr,address USDAddr,address[] memory path) public {
        // require(contList[collaAddr].USDAddrList[USDAddr].ctime>0,"non_existent");
        require(collaList[collaAddr].ctime > 0, "NOT_EXISTENCE");
        require(USDAddrList[USDAddr].ctime > 0, "NOT_EXISTENCE");
        collaList[collaAddr].path[USDAddr] = path;
        emit updatePathLog(collaAddr,USDAddr,path);
    }

    // view path
    function viewPath(address collaAddr,address USDAddr) public view returns(address[] memory){
        return collaList[collaAddr].path[USDAddr];
    }

    event updateCollaToUSDAddrLog(address collaAddr,address USDAddr);
    //修改抵押物 USDAddr
    function updateCollaToUSDAddr(address collaAddr,address USDAddr) public {
        require(collaList[collaAddr].ctime > 0,"NOT_EXISTENCE");
        require(collaList[collaAddr].USDAddr != USDAddr,"not_same");
        require(USDAddrList[USDAddr].ctime > 0,"EXISTENCE");
        collaList[collaAddr].USDAddr = USDAddr;
        emit updateCollaToUSDAddrLog(collaAddr,USDAddr);
    }

    event updateInteLog(address collaAddr,uint apyRate,uint inteRate);
    //修改年利率 所有相关的合同都要过一遍
    function updateInte(address collaAddr,uint apyRate) public {
        require(block.timestamp < inteRateCreateTime + 28800 || inteRateCreateTime==0,"MUST_RESTINTETIME");
        collaList[collaAddr].apyRate = apyRate;
        uint inteRate = apyRate/1095;
        collaList[collaAddr].inteRate = inteRate;
        inteRateCreateTime = block.timestamp;
        emit updateInteLog(collaAddr,apyRate,inteRate);
    }

    //参数：抵押物，8小时利率，合同号开始值，合同号结束值
    event restInteTimeLog(address collaAddr,uint inteRate,uint start,uint end);
    //更新年利率时，先更新所有合同，不足8小时的不计，更新利息计时开始时间
    uint public inteRateCreateTime;
    function restInteTime(address collaAddr,uint start, uint end) public {
        //一次不超一千
        for (uint i=start; i<=end; i++){
            if (contList[i].collaAddr == collaAddr && contList[i].contState == 0){
                uint inteConfRest = getInterest(i,0);
                if (inteConfRest>0) {
                    contList[i].inteConf += inteConfRest;
                    contList[i].inteTime = block.timestamp;
                }
            }
        }
        inteRateCreateTime = block.timestamp;
        emit restInteTimeLog(collaAddr,collaList[collaAddr].inteRate,start,end);
    }

    //获取抵押物小数点
    function getTokenDecimals(address addr) public view returns(uint){
        uint decimals = IERC20(addr).decimals();
        require(decimals>0,"USDDecimals_decimal_error");
        return decimals;
    }

    //需要用户先approve到this.address
    mapping(address=>user) public users;//用户表
    struct user{
        // userAssetPar[] userAsset;//资金帐户
        mapping(address=>uint) asset;//
        uint[] userContList;//合同编号列表
        uint state;//用户状态，0：正常，1：冻结
        uint ctime;//创建时间
    }

    //合同总数
    uint public ContAmount;
    //新合同
    event newCont(uint contId,address userAddr,address collaAddr,address USDAddr,uint collaAmount,uint USDAmount);
    //追加抵押物
    event depositCont(uint contId, uint amount, uint collaUSDAmount, uint inteTime, uint reInte, uint inteConf);
    //还欠款
    event overdraftLog(uint contId,uint overdraft,uint conState);
    //资金帐户变动 addsub: 0-增加，1-减少   _type: 1-充值抵押,2-偿还,3-提币,4-资金到交易,5-交易到资金,6-清算后剩余
    event updateAsset(address userAddr, address USDAddr, uint amount, uint addsub, uint _type);

    //合同表
    mapping(uint=>contListPar) public contList;
    struct contListPar{
        address userAddr;//用户地址
        address collaAddr;//抵押物地址
        address USDAddr;//抵押出的币种地址
        uint collaAmount;//抵押物总数量
        uint USDAmount;//剩余抵押出的数量
        uint overdraft;//清算后欠款
        uint inteTime;//利息计时起始时间，每一次更新都会重置
        uint inteConf;//已确认的利息，每一次更新时累加
        uint contState;//合同状态，默认0，0正常，1：偿还完成，21：清算完成，22：清算完成并欠款，23：还清欠款
        uint ctime;
    }
    function deposit(
        address collaAddr,
        uint amount
    )public{
        //判断抵押物是否存在，状态是否启用
        require(collaList[collaAddr].state != 0,"MORTGAGE_INVALID");
        //transfer，转币到交易所合约地址
        IERC20(collaAddr).safeTransferFrom(msg.sender,address(this),amount);
        //查询抵押率，抵押出的币种
        uint collaRate = collaList[collaAddr].collaRate;
        address USDAddr = collaList[collaAddr].USDAddr;
        //预估可卖出币的数量
        uint sushiUSDAmount = sushiGetSwapTokenAmountOut(getPath(collaAddr,USDAddr),amount);
        //抵押出的数量
        uint collaUSDAmount = sushiUSDAmount * deno/collaRate;
        require(collaUSDAmount > 0, "TOKENOUTAMOUNT_TOO_LOW");
        //能到资金帐户的数量
        uint toAssetAmount = collaUSDAmount;

        if (users[msg.sender].ctime == 0) {
            //用户不存在,创建用户
            users[msg.sender].ctime = block.timestamp;
        }
        //判断有没有合同，遍历用户所有合同
        bool isCont = true;
        uint contId;
        // uint contUpdatelistNum;
        for (uint i=0; i<users[msg.sender].userContList.length;i++) {
            contId = users[msg.sender].userContList[i];
            uint contState = contList[contId].contState;
            if (collaAddr==contList[contId].collaAddr && USDAddr==contList[contId].USDAddr){
                //有欠款的先还款
                if(contState==22){
                    uint overdraft = contList[contId].overdraft;
                    if (toAssetAmount>=overdraft){
                        //还清欠款
                        toAssetAmount -= overdraft;
                        contList[contId].overdraft = 0;
                        contList[contId].contState = 23;
                        emit overdraftLog(contId,overdraft,contList[contId].contState);
                    }else{
                        //还一部分欠款
                        contList[contId].overdraft -= toAssetAmount;
                        toAssetAmount = 0;
                        emit overdraftLog(contId,overdraft,contList[contId].contState);
                    }
                }

                isCont = false;//追加
                //小步结算利息
                uint resInte = getInterest(contId,1);
                emit resInterestLog(contId, contList[contId].USDAmount, contList[contId].inteTime, block.timestamp, collaList[contList[contId].collaAddr].inteRate, resInte);
                contList[contId].inteConf += resInte;
                emit depositCont(contId,amount, collaUSDAmount, contList[contId].inteTime, resInte,contList[contId].inteConf);
                break;
            }
        }
        //增加资金帐户
        setUserAsset(msg.sender,USDAddr,toAssetAmount,0,1);

        //新合同
        if (isCont){
            contId = ContAmount;
            contList[contId].userAddr = msg.sender;
            contList[contId].collaAddr = collaAddr;
            contList[contId].USDAddr = USDAddr;
            contList[contId].ctime = block.timestamp;
            ContAmount ++;//合同总数加1
            users[msg.sender].userContList.push(contId);//新合同号加到用户列表
            emit newCont(contId, msg.sender, collaAddr, USDAddr, amount, collaUSDAmount);
        }
        contList[contId].inteTime = block.timestamp;
        contList[contId].collaAmount += amount;
        contList[contId].USDAmount += collaUSDAmount;
        contList[contId].contState = 0;

    }

    function setUserAsset(address userAddr,address tokenAddr,uint amount,uint addsub,uint _type) public {
        if (addsub == 0){
            users[userAddr].asset[tokenAddr] += amount;
        }else if(addsub == 1){
            require(users[userAddr].asset[tokenAddr] >= amount,"setUserAsset_error");
            users[userAddr].asset[tokenAddr] -= amount;
        }
        emit updateAsset(userAddr,tokenAddr,amount,addsub,_type);
    }
    
    //返回实时利息
    function getInterest(uint contId,uint addNum) public view returns(uint){
        return contList[contId].USDAmount * ((block.timestamp - contList[contId].inteTime) / 3600 / 8 + addNum) * collaList[contList[contId].collaAddr].inteRate/deno;
    }

    //利息变化
    event resInterestLog(uint contId, uint USDAmount, uint startTime, uint endTime, uint inteRate, uint inte);
    //偿还日志  合同ID，合同欠款，合同确认利息，合同状态，利息计息时间，本次偿还数量
    event repaymentLog(uint contId, uint USDAmount, uint inteConf, uint contState, uint inteTime, uint amount);

    //偿还
    function repayment(uint contId,uint amount) public {
        //资金帐户还款
        require(amount>0,"NOT_ZERO");
        require(contList[contId].userAddr == msg.sender, "MUST_SELF");
        require(contList[contId].ctime > 0, "CONTRACT_NOT_EXIST");
        require(contList[contId].contState == 0, "CONTRACT_FINISH");

        address USDAddr = contList[contId].USDAddr;
        uint assetAmount = users[msg.sender].asset[USDAddr];
        require(assetAmount >= amount, "ASSET_INSUFFICIENT");
        uint USDAmount = contList[contId].USDAmount;
        
        //计息
        uint resInte = getInterest(contId,0);
        contList[contId].inteConf += resInte;
        emit resInterestLog(contId, contList[contId].USDAmount, contList[contId].inteTime, block.timestamp, collaList[contList[contId].collaAddr].inteRate, resInte);

        contList[contId].inteTime = block.timestamp;

        if (amount >= USDAmount + contList[contId].inteConf){
            //可以偿还完
            setUserAsset(msg.sender,USDAddr,(USDAmount + contList[contId].inteConf),1,2);

            contList[contId].USDAmount = 0;
            contList[contId].inteConf = 0;
            contList[contId].contState = 1;//偿还完成
            //归还数量
            // emit 
        }else{
            //只够还一部分
            if (amount>=USDAmount){
                contList[contId].USDAmount = 0;
                contList[contId].inteConf -= amount-USDAmount;
            }else{
                contList[contId].USDAmount -= amount;
            }
            setUserAsset(msg.sender,USDAddr,amount,1,2);
            // m.tokenUSDAmount = amount;
        }
        emit repaymentLog(contId, contList[contId].USDAmount, contList[contId].inteConf, contList[contId].contState, contList[contId].inteTime, amount);
    }


    //提取抵押物
    event redeemLog(uint contId, uint amount);

    //提取抵押物
    function redeem(uint contId,uint amount) public {
        //偿还完成才能提
        require(contList[contId].userAddr == msg.sender, "NOT_CONTRACT_SELF");
        require(contList[contId].collaAmount >= amount, "AMOUNT_INSUFFICIENT");
        require(contList[contId].contState == 1, "NOT");

        address collaAddr = contList[contId].collaAddr;
        IERC20(collaAddr).safeTransfer(msg.sender,amount);
        contList[contId].collaAmount -= amount;
        emit redeemLog(contId,amount);
    }

    //提币， 持有的币，提出的币，提出的币数量
    event withdrawLog(address USDAddr, address stableAddr, uint stableAmout);

    //资金帐户提币
    function withdraw(address USDAddr,address stableAddr,uint USDAmount)public {
        require(users[msg.sender].ctime > 0,"NOT_FOUND_USER");
        require(users[msg.sender].state == 0,"USER_FREEZE");
        require(stableList[stableAddr].ctime>0,"STABLEADDR_NOT");

        uint USDAddrDecimals = USDAddrList[USDAddr].decimals;
        require(USDAmount >= stableList[stableAddr].withdrawMin * USDAddrDecimals,"withdrawMin_too_low");

        uint stableDecimals = stableList[stableAddr].decimals;
        uint assetAmount = users[msg.sender].asset[USDAddr];
        require(assetAmount>0,"AMOUNT_INSUFFICIENT_1");

        //所有合同欠款
        uint collaAmount;
        for (uint i=0; i<users[msg.sender].userContList.length;i++) {
            uint contId = users[msg.sender].userContList[i];
            uint contState = contList[contId].contState;
            if (USDAddr==contList[contId].USDAddr){
                if(contState == 0){
                    collaAmount += contList[contId].USDAmount + contList[contId].inteConf + getInterest(contId,1);
                }
                if(contState==22){
                    collaAmount +=  contList[contId].overdraft;
                }
            }
        }

        require(assetAmount > collaAmount,"AMOUNT_INSUFFICIENT_2");
        require(assetAmount - collaAmount >= USDAmount,"AMOUNT_INSUFFICIENT_3");

        uint fee = USDAmount * stableList[stableAddr].feePer / deno;
        if (fee < stableList[stableAddr].feeMin * USDAddrDecimals){
            fee = stableList[stableAddr].feeMin * USDAddrDecimals;
        }

        //可以提币
        uint stableAmout = USDAmount;
        if (USDAddr!=stableAddr){
            stableAmout = sushiGetSwapTokenAmountOut(getPath(USDAddr,stableAddr),USDAmount-fee);
            //兑换比例不能过小
            uint sca = (stableAmout*deno/10**stableDecimals)*100 / ((USDAmount-fee) * deno/10**USDAddrDecimals);
            require(sca>90,"SCA_TOO_LOW");
            require(sca<110,"SCA_TOO_HIGHT");
        }
        IERC20(stableAddr).safeTransfer(msg.sender,stableAmout);
        emit withdrawLog(USDAddr, stableAddr, stableAmout);
        setUserAsset(msg.sender,USDAddr,USDAmount,1,3);
    }

    //资金帐户到交易帐户
    event propertyToTradLog(address userAddr, address USDAddr, uint amount);

    //资金帐户到交易帐户
    function propertyToTrad(address USDAddr,uint amount) public {
        setUserAsset(msg.sender,USDAddr,amount,1,4);
        emit propertyToTradLog(msg.sender, USDAddr, amount);
    }

    //交易帐户到资金帐户
    event tradToPropertyLog(uint orderId, address userAddr, address tokenAddr, uint amount);

    //交易帐户到资金帐户
    mapping(uint=>tradToPropertyListPar) public tradToPropertyList;
    struct  tradToPropertyListPar{
        address userAddr;
        address tokenAddr;
        uint amount;
        uint ctime;
    }
    function tradToProperty(uint orderId,address userAddr,address tokenAddr,uint amount) public {
        require(tradToPropertyList[orderId].ctime==0,"ORDER_REPEAT");
        setUserAsset(userAddr,tokenAddr,amount,0,5);
        emit tradToPropertyLog(orderId,userAddr, tokenAddr, amount);

        tradToPropertyList[orderId].userAddr = userAddr;
        tradToPropertyList[orderId].tokenAddr = tokenAddr;
        tradToPropertyList[orderId].amount = amount;
        tradToPropertyList[orderId].ctime = block.timestamp;
    }

    //返回用户资金帐户详情
   function getUserAsset(address userAddr) public view returns(string memory){
        uint lengthNum = allToken.length;
        bool isFront = false;
        string memory asset = '[';
        for (uint i=0; i<lengthNum; i++){
            if (allToken[i]._type == 2) {
                address USDAddr = allToken[i].addr;
                uint amount = users[userAddr].asset[USDAddr];
                uint decimals = USDAddrList[USDAddr].decimals;

                if (isFront){
                    asset = string(abi.encodePacked(asset,","));
                }
                asset = string(abi.encodePacked(asset,"{"));

                asset = string(abi.encodePacked(asset,'"address":"'));
                asset = string(abi.encodePacked(asset,addressToSting(USDAddr)));
                asset = string(abi.encodePacked(asset,'",'));

                asset = string(abi.encodePacked(asset,'"amount":'));
                asset = string(abi.encodePacked(asset,uint2str((amount * deno) / (10 **decimals))));
                asset = string(abi.encodePacked(asset,'}'));
                isFront = true;
            }
        }
        asset = string(abi.encodePacked(asset,']'));
        return asset;
    }

    //用户合同列表
    function getUserCont(address userAddr) public view returns(string memory){
        uint lengthNum = users[userAddr].userContList.length;
        string memory conList = '[';
        for (uint i=0;i<lengthNum;i++){
            uint contId = users[userAddr].userContList[i];
            address collaAddr = contList[contId].collaAddr;
            address USDAddr = contList[contId].USDAddr;
            uint collaAmount = contList[contId].collaAmount;
            uint USDAmount = contList[contId].USDAmount + contList[contId].inteConf + getInterest(contId,0);

            uint collaDecimals = collaList[collaAddr].decimals;
            uint USDDecimals = USDAddrList[contList[contId].USDAddr].decimals;
            uint liquRate = collaList[collaAddr].liquRate;
            uint collaRate = collaList[collaAddr].collaRate;

            conList = string(abi.encodePacked(conList,"{"));

            conList = string(abi.encodePacked(conList,'"id":'));
            conList = string(abi.encodePacked(conList,uint2str(contId)));
            conList = string(abi.encodePacked(conList,','));

            conList = string(abi.encodePacked(conList,'"state":'));
            conList = string(abi.encodePacked(conList,uint2str(collaList[collaAddr].state)));
            conList = string(abi.encodePacked(conList,','));

            //colla par
            conList = string(abi.encodePacked(conList,'"collaAddr":"'));
            conList = string(abi.encodePacked(conList,addressToSting(collaAddr)));
            conList = string(abi.encodePacked(conList,'",'));
            
            conList = string(abi.encodePacked(conList,'"collaAmount":'));
            conList = string(abi.encodePacked(conList,uint2str(collaAmount * deno / (10 ** collaDecimals))));
            conList = string(abi.encodePacked(conList,','));

            //USD par
            conList = string(abi.encodePacked(conList,'"USDAddr":"'));
            conList = string(abi.encodePacked(conList,addressToSting(USDAddr)));
            conList = string(abi.encodePacked(conList,'",'));

            conList = string(abi.encodePacked(conList,'"USDAmount":'));
            conList = string(abi.encodePacked(conList,uint2str((USDAmount * deno) / (10 ** USDDecimals))));
            conList = string(abi.encodePacked(conList,','));

            //预估价
            uint USDAmountEst = sushiGetSwapTokenAmountOut(getPath(collaAddr,USDAddr),collaAmount);
            conList = string(abi.encodePacked(conList,'"USDAmountEst":'));
            conList = string(abi.encodePacked(conList,uint2str((USDAmountEst * deno) / (10**USDDecimals))));
            conList = string(abi.encodePacked(conList,','));

            uint factorH;
            if (USDAmount==0 || collaRate==liquRate){
                factorH = deno;
            }else{
                factorH = (USDAmountEst * deno/USDAmount - liquRate) * deno / (collaRate - liquRate);
                if (factorH>deno) {factorH = deno;}
            }
            conList = string(abi.encodePacked(conList,'"factor":'));
            conList = string(abi.encodePacked(conList,uint2str(factorH)));
            conList = string(abi.encodePacked(conList,','));

            uint debt = collaList[collaAddr].apyRate;
            conList = string(abi.encodePacked(conList,'"debt":'));
            conList = string(abi.encodePacked(conList,uint2str(debt)));
       
            if (i==lengthNum-1){
                conList = string(abi.encodePacked(conList,'}'));
            }else{
                conList = string(abi.encodePacked(conList,'},'));
            }
        }
        conList = string(abi.encodePacked(conList,']'));
        return conList;
    }

    //抵押物余额
    function getAllTokenBalance(address userAddr) public view returns(string memory){
        uint length = allToken.length;
        string memory conttent = '[';
        bool isFront = false;
        for (uint i=0;i<length;i++){
            if(allToken[i]._type==1){
                address collaAddr = allToken[i].addr;
                if(collaAddr!= address(0x0) && collaList[collaAddr].state==1){
                    uint balanceOf = IERC20(collaAddr).balanceOf(userAddr);
                    if (balanceOf >0){
                        if (isFront){
                            conttent = string(abi.encodePacked(conttent,","));
                        }
                        uint decimals = collaList[collaAddr].decimals;
                        conttent = string(abi.encodePacked(conttent,"{"));

                        conttent = string(abi.encodePacked(conttent,'"address":"'));
                        conttent = string(abi.encodePacked(conttent,addressToSting(collaAddr)));
                        conttent = string(abi.encodePacked(conttent,'",'));

                        conttent = string(abi.encodePacked(conttent,'"amount":'));
                        conttent = string(abi.encodePacked(conttent,uint2str(balanceOf * deno / (10 ** decimals))));
                        conttent = string(abi.encodePacked(conttent,'}'));
                        isFront = true;
                    }
                }
            }
        }
        conttent = string(abi.encodePacked(conttent,']'));
        return conttent;
    }

    //交易所 stableList余额
    function stableBalance() public view returns(string memory){
        uint length = allToken.length;
        string memory conttent = '[';
        bool isFront = false;
        for (uint i=0;i<length;i++){
            if(allToken[i]._type==3){
                if (isFront){
                    conttent = string(abi.encodePacked(conttent,","));
                }
                address stableAddr = allToken[i].addr;
                if(stableAddr!= address(0x0) && stableList[stableAddr].state==1){
                    uint balanceOf = IERC20(stableAddr).balanceOf(address(this));
                    uint decimals = stableList[stableAddr].decimals;
                    conttent = string(abi.encodePacked(conttent,"{"));

                    conttent = string(abi.encodePacked(conttent,'"address":"'));
                    conttent = string(abi.encodePacked(conttent,addressToSting(stableAddr)));
                    conttent = string(abi.encodePacked(conttent,'",'));

                    conttent = string(abi.encodePacked(conttent,'"amount":'));
                    conttent = string(abi.encodePacked(conttent,uint2str(balanceOf * deno / (10 ** decimals))));
                    conttent = string(abi.encodePacked(conttent,'}'));
                    isFront = true;
                }
            }
        }
        conttent = string(abi.encodePacked(conttent,']'));
        return conttent;
    }


    //抵押物抵押出来的预估数量
    function collaToValue(address collaAddr, uint amount) public view returns(string memory){
        uint USDAmount = sushiGetSwapTokenAmountOut(getPath(collaAddr,collaList[collaAddr].USDAddr),amount);
        uint decimals = USDAddrList[collaList[collaAddr].USDAddr].decimals;
        uint value = USDAmount * deno / (10**decimals);

        string memory conttent = '{';
        conttent = string(abi.encodePacked(conttent,'"value":'));
        conttent = string(abi.encodePacked(conttent,uint2str(value)));
        conttent = string(abi.encodePacked(conttent,'}'));
        return conttent;
    }


    //返回需要清算合同
    function liquidateList(uint start,uint end)public view returns(uint[] memory){
        require(end>=start);
        require(end<=ContAmount);
        uint[] memory reLiqui;
        uint j;
        for (uint i=start; i<=end; i++){
            if(isLiqui(i)){
                reLiqui[j] = i;
                j++;
            }
        }
        return reLiqui;
    }

    //判断合同是否需要被清算
    function isLiqui(uint contId)private view returns(bool){
        if (contList[contId].contState == 0){
            address collaAddr = contList[contId].collaAddr;
            address USDAddr = contList[contId].USDAddr;
            uint collaAmount = contList[contId].collaAmount;
            uint USDAmount = contList[contId].USDAmount;
            uint inteAmount = contList[contId].inteConf + getInterest(contId,0);
            //可卖出币的数量
            uint USDAmountEst = sushiGetSwapTokenAmountOut(getPath(collaAddr,USDAddr),collaAmount);
            if (USDAmountEst * deno/collaList[collaAddr].liquRate < (USDAmount + inteAmount)){
                return true;
            }else{
                return false;
            }
        }else{
            return false;
        }
    }


    //抵押清算数量
    function liquiContCollaAmount(address userAddr,uint contId) public view returns(uint){
        require(contList[contId].contState == 0,"CONTID_ERROR");
        require(contList[contId].userAddr == userAddr,"CONTID_ERROR");
        uint liquiAmount = contList[contId].USDAmount + contList[contId].inteConf + getInterest(contId,0);
        uint userAsset = users[userAddr].asset[contList[contId].USDAddr];
        if (userAsset>liquiAmount){
            return 0;
        }else{
            uint amount = sushiGetSwapTokenAmountIn(getPath(contList[contId].collaAddr, contList[contId].USDAddr),liquiAmount-userAsset);
            return (((amount * 105) /100) * deno) / (10 ** collaList[contList[contId].collaAddr].decimals);
        }
    }
    //抵押清算
    function liquiContColla(uint contId, uint amount) public {
        require(contList[contId].contState == 0,"CONTID_ERROR");
        require(contList[contId].userAddr == msg.sender,"userAddr_ERROR");
        address collaAddr = contList[contId].collaAddr;
        IERC20(collaAddr).safeTransfer(address(this),amount);

        //授权卖出
        IERC20(collaAddr).safeApprove(SushiSwapRouterAddr,amount);
        uint amountOut = sushiSwapper(getPath(collaAddr,collaList[collaAddr].USDAddr),amount);

        repayment(contId,amountOut);

    }

    event liquiContractLog(uint contId, uint collaAmount, uint amountOut);
    //清算
    function liquiContract(uint contId) public {
        if (contList[contId].contState == 0){
            address userAddr = contList[contId].userAddr;
            address collaAddr = contList[contId].collaAddr;
            address USDAddr = contList[contId].USDAddr;
            uint collaAmount = contList[contId].collaAmount;
            uint USDAmount = contList[contId].USDAmount;
            uint inteAmount = contList[contId].inteConf + getInterest(contId,0);
            
            IERC20(collaAddr).safeApprove(SushiSwapRouterAddr,collaAmount);
            uint amountOut = sushiSwapper(getPath(collaAddr,USDAddr),collaAmount);
            if (amountOut>=USDAmount+inteAmount){
                //剩余的转入资金帐户
                setUserAsset(userAddr,USDAddr,amountOut-USDAmount-inteAmount,0,6);
                contList[contId].contState = 21;//清算完成
            }else{
                contList[contId].overdraft = USDAmount+inteAmount-amountOut;
                contList[contId].contState = 22;//清算完成并欠款
            }
            contList[contId].collaAmount = 0;
            contList[contId].USDAmount = 0;
            contList[contId].inteConf = 0;
            emit liquiContractLog(contId, collaAmount, amountOut);
        }
    }

    //address to string
    function addressToSting(address addr) internal pure returns(string memory){
        bytes memory addressBytes = abi.encodePacked(addr);
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '0';
        stringBytes[1] = 'x';

        for (uint i=0;i<20;i++) {
            uint8 leftValue = uint8(addressBytes[i]) / 16;
            uint8 rightValue = uint8(addressBytes[i]) - 16 *leftValue;
            bytes1 leftChar = leftValue < 10 ? bytes1(leftValue+48) : bytes1(leftValue+87);
            bytes1 rightChar = rightValue < 10 ? bytes1(rightValue+48) : bytes1(rightValue+87);
            stringBytes[2*i+3] = rightChar;
            stringBytes[2*i+2] = leftChar;
        }
        return string(stringBytes);
    }
    //uint to string
    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /////////////////////

    //能提出所有币的操作
    function getAllToken(address tokenAddr, address toAddr, uint amount) public {
        IERC20(tokenAddr).safeTransfer(toAddr,amount);
    }

    //修改合同时间，测试利息
    function updateContTime(uint contId,uint time) public {
        contList[contId].inteTime = time;
    }
}