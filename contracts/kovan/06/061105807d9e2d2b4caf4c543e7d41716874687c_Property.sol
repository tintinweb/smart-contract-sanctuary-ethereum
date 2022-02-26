/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

//import "hardhat/console.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
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
    event rateLog(address tokenAddr, uint256 rate);
    // event mortAmount(address recipient, address tokenAddr, uint256 rate);

    event setCollateralListLog(address tokenAddr,uint decimal,uint mortRate,uint liquRate,uint state);
    event settokenUSDAddrLog(address oldAddr,uint oldDecinal,address newAddr,uint newDecinal);
    event setInteRateLog(uint inteRate,uint newInteRate);

    bool stateFrozen;
    bool notFrozenState;
    //冻结
    modifier notFrozen()
    {
        require(notFrozenState, "STATE_IS_FROZEN");
        _;
    }

    //预估需要的token，想兑换出数量amountOut, 那需要数量amountIn
    function sushiGetSwapTokenAmountIn(
        address tokenA,
        address tokenB,
        uint amountOut
    ) public view virtual returns (uint) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        uint amountIn = sushiRouter.getAmountsIn(
            amountOut,
            path
        )[0];
        return amountIn;
    }

    //价格：预估兑换出的token，用A兑换B，可以兑换出B的数量amountOut
    function sushiGetSwapTokenAmountOut_re(
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) public view virtual returns (uint) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint amountOut = sushiRouter.getAmountsOut(
            amountIn,
            path
        )[0];
        return amountOut;
    }

    function sushiGetSwapTokenAmountOut(
        address tokenIn,
        address tokenOut,
        uint amountIn
    ) public view virtual returns (uint) {
        uint price_dmg = 14800000;
        return price_dmg*amountIn;
    }

    //开始兑换，把In兑换成Out，Out是稳定币，已在添加抵押物时approve
    function sushiSwapper(address tokenIn, address tokenOut,uint amountIn) private returns(uint){
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256 exchangeBalanceBeforeIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 exchangeBalanceBeforeOut = IERC20(tokenOut).balanceOf(address(this));
        
        uint amountOut = sushiGetSwapTokenAmountOut(tokenIn,tokenOut,amountIn);
        sushiRouter.swapExactTokensForTokens(
            amountIn,
            amountOut,
            path,
            address(this),
            block.timestamp + 300
        );

        uint256 exchangeBalanceAfterIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 exchangeBalanceAfterOut = IERC20(tokenOut).balanceOf(address(this));

        require(exchangeBalanceAfterIn >= exchangeBalanceBeforeIn, "OVERFLOW");
        require(exchangeBalanceAfterOut >= exchangeBalanceBeforeOut, "OVERFLOW");
        require(exchangeBalanceAfterIn == exchangeBalanceBeforeIn + amountIn,"INCORRECT_AMOUNT_TRANSFERRED");
        require(exchangeBalanceAfterOut == exchangeBalanceBeforeOut + amountOut,"INCORRECT_AMOUNT_TRANSFERRED");
        return amountOut;
    }

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//设置新的抵押物
    mapping(address=>collaListPa) public collaList;//抵押物列表
    struct collaListPa{
        uint decimal;//小数
        uint mortRate;//抵押率
        uint liquRate;//清算率
        uint state;//启用状态 0:不启用，1：启用
    }
    function setCollateralList(
        address tokenAddr,//抵押物地址
        uint decimal,
        uint mortRate,
        uint liquRate,
        uint state
    )public {
        if (collaList[tokenAddr].mortRate == 0){
            //需要approve，this.address approve tokenA to sushiswap，清算时需要，否则无法清算卖出该币种
            // IERC20 token = IERC20(tokenAddr);
            // token.approve(sushiswapAddr,2**256-1);
            IERC20(tokenAddr).safeApprove(SushiSwapRouterAddr,2**256-1);
        }
        collaList[tokenAddr].decimal = decimal;
        collaList[tokenAddr].mortRate = mortRate;
        collaList[tokenAddr].liquRate = liquRate;
        collaList[tokenAddr].state = state;
        emit setCollateralListLog(tokenAddr,decimal,mortRate,liquRate,state);
    }

//抵押出的币种
    address public tokenUSDAddrOut;
    uint public tokenUSDAddrOutDecimal;
    mapping(address=>uint) public tokenUSDList;

    struct currencyAllPar{
        address tokenAddr;
        uint tranType;//1：抵押出，2：抵押进
        uint state;//启用状态 0：正常，1：禁用
    }
    currencyAllPar[] public currencyAll;//所有币种
    
    // struct tokenUSDListPar{
    //     address tokenUSDAddrOut;
    //     uint tokenUSDAddrOutDecimal;
    // }
    function settokenUSDAddr(address newtokenUSDAddr,uint newtokenUSDAddrOutDecimal) public{
        emit settokenUSDAddrLog(tokenUSDAddrOut,tokenUSDAddrOutDecimal,newtokenUSDAddr,newtokenUSDAddrOutDecimal);
        tokenUSDAddrOut = newtokenUSDAddr;
        tokenUSDAddrOutDecimal = newtokenUSDAddrOutDecimal;
        tokenUSDList[newtokenUSDAddr] = newtokenUSDAddrOutDecimal;
        for (uint i=0;i<currencyAll.length;i++){
            
        }

    }



//年利率更改
    uint public inteRate;//5479452054794520
    uint public inteRateDeno = 100000000000000000000;
    uint public inteRateCreateTime;
    function setInteRate(uint newInteRate) public {
        //更新所有合同，不足8小时的不计，更新利息计时开始时间
        //先执行restInteTime，8小时内有效  28800
        require(block.timestamp < inteRateCreateTime + 28800 || inteRateCreateTime==0,"MUST_RESTINTETIME");
        //更改利率
        emit setInteRateLog(inteRate,newInteRate);
        inteRate = newInteRate;
        inteRateCreateTime = block.timestamp;
    }

    //更新年利率时，先更新所有合同，不足8小时的不计，更新利息计时开始时间
    function restInteTime(uint start, uint end) public {
        //一次不超一千
        for (uint i=start; i<=end; i++){
            if (contList[i].state == 0){
                uint interestConfirmRest = getInterest(i,0);
                if (interestConfirmRest>0) {
                    contList[i].interestConfirm += interestConfirmRest;
                    contList[i].interestTime = block.timestamp;
                }
            }
        }
        inteRateCreateTime = block.timestamp;
    }

    //内部交易
    function transferToExchange(address tokenAddr,uint256 amount)public returns (bool){
        IERC20 token = IERC20(tokenAddr);
        uint256 exchangeBalanceBefore = token.balanceOf(address(this));
        // bytes memory callData = abi.encodeWithSelector(
        //     token.transferFrom.selector,
        //     msg.sender,
        //     address(this),
        //     amount
        // );
        // (bool success,) = tokenAddr.call(callData);
        // require(success,"TRANSFER_ERROR");
        token.safeTransferFrom(msg.sender,address(this),amount);

        uint256 exchangeBalanceAfter = token.balanceOf(address(this));
        require(exchangeBalanceAfter >= exchangeBalanceBefore, "OVERFLOW");
        require(exchangeBalanceAfter == exchangeBalanceBefore + amount,"INCORRECT_AMOUNT_TRANSFERRED");
        return true;
    }

//抵押物进来直接兑换，需要用户先approve到this.address
    //用户表
    mapping(address=>user) public users;
    struct user{
        mapping(address => uint) userAsset;//资金帐户
        // mapping(string=>contPar) userContList;//用户所有合同
        uint[] userContList;//合同编号列表
        // uint32 contNum;//合同总数
        uint userCreateTime;//创建时间
    }

    // struct contPar{
    //     address tokenUSD;
    //     uint createTime;
    //     uint state;
    // }

    //合同总数
    uint public loanContractAmount;

    //合同表
    mapping(uint=>contListPar) public contList;
    struct contListPar{
        address userAddr;//用户地址
        address mortAddr;//抵押物地址
        address tokenUSDAddr;//抵押出的币种地址
        uint mortAmount;//抵押物总数量
        uint tokenUSDAmount;//剩余抵押出的数量
        uint interestTime;//利息计时起始时间，每一次更新都会重置
        uint interestConfirm;//已确认的利息，每一次更新时累加
        contUpdateListPar[] contUpdateList;//合同更新
        uint state;//合同状态，默认0，0正常，1：结算完成等待提出抵押物，2：抵押物已被提走，3：已被清算
        uint createTime;
    }
    struct contUpdateListPar{
        uint updateType;//更新类型，默认0，0：新开合同，1：追加，2：归还，3：抵押物提走，4：清算
        uint mortAmount;//抵押物数量
        uint tokenUSDAmount;//抵押出的数量
        uint mortRate;//抵押率
        // uint interestConfirm;//结算利息
        uint createTime;
    }

    function depositToken(
        address tokenAddr,
        uint amount
        // uint tranType
    )public{
        //console.log("start ",tokenAddr);
        //判断抵押物是否存在，状态是否启用
        require(collaList[tokenAddr].state != 0,"MORTGAGE_INVALID");
        //console.log("collaList[tokenAddr].state is  ",collaList[tokenAddr].state);
        //transfer，转币到交易所合约地址
        IERC20(tokenAddr).safeTransferFrom(msg.sender,address(this),amount);
        //console.log("transferFrom end ",tokenAddr);
        //查询抵押率，抵押出的币种
        uint mortRate = collaList[tokenAddr].mortRate;
        //console.log("mortRate is ",mortRate);
        //可卖出币的数量
        uint tokenOutAmount = sushiGetSwapTokenAmountOut(tokenAddr,tokenUSDAddrOut,amount);
        //console.log("tokenOutAmount is ",tokenOutAmount);
        //抵押出的数量
        uint tokenCollateraAmount = tokenOutAmount * mortRate/100;
        //console.log("tokenCollateraAmount is ",tokenCollateraAmount);
        require(tokenCollateraAmount!=0,"TOKENOUTAMOUNT_TOO_LOW");

        uint isUser = users[msg.sender].userCreateTime;
        //console.log("isUser is ",isUser);
        if (isUser==0) {//用户不存在
            users[msg.sender].userCreateTime = block.timestamp;
            // users[msg.sender].contNum = 1;
            // users[msg.sender].contList[newContId].tokenUSD = tokenUSDAddr;
            // users[msg.sender].contList[newContId].createTime = block.timestamp;
            // users[msg.sender].contList[newContId].state = tranType;

        }
        //console.log("users[msg.sender].userCreateTime is ",users[msg.sender].userCreateTime);
        
        //资金帐户
        users[msg.sender].userAsset[tokenUSDAddrOut] += tokenCollateraAmount;
        //console.log("users[msg.sender].userAsset[tokenUSDAddrOut] is ",users[msg.sender].userAsset[tokenUSDAddrOut]);
        //判断有没有合同，遍历所有合同
        bool contStateTemp = true;
        //合同编号
        //string memory newContId = string(string(abi.encodePacked(addressToSting(msg.sender),uint2str(idNum))));
        uint contId;
        uint contUpdatelistNum;
        //console.log("users[msg.sender].userContList.length is ",users[msg.sender].userContList.length);
        for (uint i=0; i<users[msg.sender].userContList.length;i++) {
            //console.log("i is ",i);
            contId = users[msg.sender].userContList[i];
            //console.log("contId is ",contId);
            address mortAddr = contList[contId].mortAddr;
            //console.log("mortAddr is ",mortAddr);
            address tokenUSDAddr = contList[contId].tokenUSDAddr;
            //console.log("tokenUSDAddr is ",tokenUSDAddr);
            uint stateTemp = contList[contId].state;
            //console.log("stateTemp is ",stateTemp);
            if (mortAddr==tokenAddr && tokenUSDAddr==tokenUSDAddrOut && stateTemp==0){
                //console.log("contStateTemp is ",contStateTemp);
                //追加
                contStateTemp = false;
                // contUpdatelistNum = contList[contId].contUpdatelistNum + 1;
                // contList[contId].contUpdatelistNum = contUpdatelistNum;
                contList[contId].contUpdateList[contUpdatelistNum].updateType = 1;
                //console.log("contList[contId].contUpdateList[contUpdatelistNum].updateType is ",contList[contId].contUpdateList[contUpdatelistNum].updateType);
                //小步结算利息 年利息为0.06时 rate=54794520547  94520,20个零 100000000000000000000
                contList[contId].interestConfirm = getInterest(contId,1);
                //console.log("contList[contId].interestConfirm is ",contList[contId].interestConfirm);

                break;
            }
        }
        //新合同
        if (contStateTemp){
            //console.log("contStateTemp is ",contStateTemp);
            contId = loanContractAmount;
            //console.log("contId is ",contId);
            contList[contId].userAddr = msg.sender;
            //console.log("contList[contId].userAddr is ",contList[contId].userAddr);
            contList[contId].mortAddr = tokenAddr;
            //console.log("contList[contId].mortAddr is ",contList[contId].mortAddr);
            contList[contId].tokenUSDAddr = tokenUSDAddrOut;
            //console.log("contList[contId].tokenUSDAddr is ",contList[contId].tokenUSDAddr);
            contList[contId].createTime = block.timestamp;
            //console.log("contList[contId].createTime is ",contList[contId].createTime);
            loanContractAmount ++;//合同总数加1
            //console.log("loanContractAmount is ",loanContractAmount);
            users[msg.sender].userContList.push(contId);//新合同号加到用户列表
            //console.log("users[msg.sender].userContList is ",users[msg.sender].userContList.length);
        }
        contList[contId].interestTime = block.timestamp;
        contList[contId].mortAmount += tokenCollateraAmount;
        contList[contId].tokenUSDAmount += tokenCollateraAmount;

        contUpdateListPar memory m;
        m.mortAmount = amount;
        m.tokenUSDAmount = tokenCollateraAmount;
        m.mortRate = mortRate;
        m.createTime = block.timestamp;
        contList[contId].contUpdateList.push(m);
        
        //写入日志，抵押出的量，交易所查询上帐用
        // emit depositTokenLog(msg.sender,contId,contStateTemp,tokenAddr,amount,);
    }

    //链的主币充值，如eth,matic

    //归还
    function repayment(uint contId,uint amount) public {
        //资金帐户还款
        require(contList[contId].createTime != 0, "CONTRACT_NOT_EXIST");
        require(contList[contId].state == 0, "CONTRACT_FINISH");
        address tokenAddr = contList[contId].tokenUSDAddr;
        require(users[msg.sender].userAsset[tokenAddr] >= amount, "ASSET_INSUFFICIENT");
        uint tokenUSDAmount = contList[contId].tokenUSDAmount;
        // uint interestAmount = contList[contId].interestConfirm + getInterest(contId);
        contList[contId].interestConfirm += getInterest(contId,0);
        contList[contId].interestTime = block.timestamp;

        contUpdateListPar memory m;
        m.updateType = 2;
        m.createTime = block.timestamp;

        if (amount >= tokenUSDAmount + contList[contId].interestConfirm){
            //可以清算
            users[msg.sender].userAsset[tokenAddr] -= (tokenUSDAmount + contList[contId].interestConfirm);
            contList[contId].tokenUSDAmount = 0;
            contList[contId].interestConfirm = 0;
            contList[contId].state = 1;//结算完成，等待抵押物被提走
            //归还数量
            m.tokenUSDAmount = (tokenUSDAmount + contList[contId].interestConfirm);
        }else{
            //只够还一部分
            if (amount>=tokenUSDAmount){
                contList[contId].tokenUSDAmount = 0;
                contList[contId].interestConfirm -= amount-tokenUSDAmount;
            }else{
                contList[contId].tokenUSDAmount -= amount;
            }
            users[msg.sender].userAsset[tokenAddr] -= amount;
            m.tokenUSDAmount = amount;
        }
        contList[contId].contUpdateList.push(m);
    }

    //返回实时利息
    function getInterest(uint contId,uint addNum) public view returns(uint){
        return contList[contId].tokenUSDAmount * ((block.timestamp - contList[contId].interestTime) / 3600 / 8 + addNum) * inteRate/inteRateDeno;
    }

    //返回需要清算合同
    function liquidateList(uint start,uint end)public view returns(uint[] memory){
        require(end>=start);
        require(end<=loanContractAmount);
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
        if (contList[contId].state == 0){
            address mortAddr = contList[contId].mortAddr;
            address tokenUSDAddr = contList[contId].tokenUSDAddr;
            uint mortAmount = contList[contId].mortAmount;
            uint tokenUSDAmount = contList[contId].tokenUSDAmount;
            uint interAmount = contList[contId].interestConfirm + getInterest(contId,0);
            //可卖出币的数量
            uint tokenOutAmount = sushiGetSwapTokenAmountOut(mortAddr,tokenUSDAddr,mortAmount);
            if (tokenOutAmount * collaList[mortAddr].liquRate/100 < tokenUSDAmount + interAmount){
                return true;
            }else{
                return false;
            }
        }else{
            return false;
        }
    }

    //清算
    function liquiContract(uint contId) public {
        if (contList[contId].state == 0){
            address userAddr = contList[contId].userAddr;
            address mortAddr = contList[contId].mortAddr;
            address tokenUSDAddr = contList[contId].tokenUSDAddr;
            uint mortAmount = contList[contId].mortAmount;
            uint tokenUSDAmount = contList[contId].tokenUSDAmount;
            uint interAmount = contList[contId].interestConfirm + getInterest(contId,0);
            
            uint amountOut = sushiSwapper(mortAddr,tokenUSDAddr,mortAmount);
            if (amountOut>=tokenUSDAmount+interAmount){
                //剩余的转入资金帐户
                users[userAddr].userAsset[tokenUSDAddr] += amountOut-tokenUSDAmount-interAmount;
            }else{
                //清算完不够还抵押

            }
            //清算完成
            contList[contId].state = 3;//已被清算
            contList[contId].mortAmount = 0;
            contList[contId].tokenUSDAmount = 0;
            contList[contId].interestConfirm = 0;
        }
    }
    //address to string
    function addressToSting(address addr) internal pure returns(string memory){
        bytes memory addressBytes = abi.encodePacked(addr);
        bytes memory stringBytes = new bytes(42);

        stringBytes[0] = '';
        stringBytes[0] = '';

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
}