//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./libs/IBEP20.sol";
import "./libs/Safemath.sol";
import "./libs/IUniswapV2Router.sol";
import "./libs/IUniswapV2Factory.sol";

contract Coin2 is IBEP20 {
    using SafeMath for uint256;
   
    string private name_;
    string private symbol_;
    uint256 private  totalSupply_ = 100000000 * (10 ** 6);
    uint8 private decimals_;
    address private owner;

  mapping(address => uint256) public _balances;
  mapping(address => mapping(address => uint256)) public _allowances;

  IUniswapV2Router swapRouter;
  address public nativeTokenPair;
  address reflectorToken = 0x32541f3C4d5EA7a8b5C07a16E74a2615247c8858;
  address public WFTM = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  address public routerAddress =  0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address DEAD = 0x000000000000000000000000000000000000dEaD;
  address ZERO = 0x0000000000000000000000000000000000000000;
  address DEAD_NON_CHECKSUM = 0x000000000000000000000000000000000000dEaD;

  bool isSwapEnabled = false;
  bool isInSwap;

  uint256 public swapThreshold = totalSupply_/1000;

  uint256 targetLiquidity = 10;
  uint256 targetLiquidityDenominator = 100;

   uint256 liquidityFee = 500;
    uint256 buybackFee = 0;
    uint256 reflectionFee = 500;
    uint256 marketingFee = 200;
    uint256 TCHSavings = 300;
    uint256 totalFee = 1500;
    uint256 feeDenominator = 10000;

     address public autoLiquidityReceiver=0x7Fe040190Cae8dcd6Dc6EB3Aa857e07C5ab09DeB; //liq address
    address public marketingFeeReceiver=0xFF341d69619FAeE2F07C018Ce2B3b8501f31636D; // marketing address


  modifier swapping(){
      isInSwap = true;
      _;
      isInSwap = false;
  }

  constructor() {
     name_ = "Coin2";
     symbol_ = "CN2";
     decimals_ = 6;
     _balances[msg.sender] = totalSupply_;

     owner = msg.sender;
     swapRouter = IUniswapV2Router(routerAddress);
     nativeTokenPair = IUniswapV2Factory(swapRouter.factory()).createPair(WFTM,address(this));
     _allowances[address(this)][address(swapRouter)] = totalSupply_;
    
     approve(routerAddress, totalSupply_);
     approve(address(nativeTokenPair), totalSupply_);
  }

  function name()external view override returns(string memory) {
     return name_;
  }

  function symbol()external view override returns(string memory){
     return symbol_;
  }

  function totalSupply()external view override returns(uint256){
      return totalSupply_;
  }

  function decimals()external view override returns(uint8){
      return decimals_;
  }

  function getOwner()external view override returns(address){
      return owner;
  }

  function balanceOf(address _address)public view override returns(uint256){
      return _balances[_address];
  }

  function allowance(address _owner, address _spender)external view override returns(uint256){
      return _allowances[_owner][_spender];
  }

  function approve(address spender_, uint256 amount)public override returns (bool) {
       require(_balances[msg.sender]>=amount,"Insufficient balance");
       _allowances[msg.sender][spender_] = amount;
       return true;
  }

  function transfer(address recipient, uint256 amount)external override returns(bool) {
    return _transfer(msg.sender,recipient,amount);
  }

  function transferFrom(address sender_, address recipient_, uint256 amount)external override returns(bool){
  require(_allowances[sender_][msg.sender]>=amount,"Exceeded allowance");
    return _transfer(sender_,recipient_,amount);
  }

  function _transfer(address sender_, address recipient, uint256 amount)internal returns(bool){
      require(_balances[sender_]>=amount,"Insufficient balance");
      bool isSelling = recipient == nativeTokenPair || recipient == routerAddress;

    bool shouldSwap = shouldSwapTokens();
      if(isSelling){
          if(shouldSwap){
           swapBack();
          }
      }
      _balances[sender_] = _balances[sender_] - amount;
      _balances[recipient] = _balances[recipient] + amount;
      emit Transfer(sender_,recipient,amount);
      emit logSwapBack(shouldSwap,isSelling);
      return true;
  }

   function shouldSwapTokens() internal view returns (bool) {
        return msg.sender != nativeTokenPair
        && !isInSwap
        && isSwapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function getDynamicLiquidityFee(uint256 _targetLiquidity, uint256 _targetLiquidityDenominator)external view returns(uint256){
        uint256 dynamicLiquidityFee = isOverLiquified(_targetLiquidity, _targetLiquidityDenominator) ? 0 : liquidityFee;
        return dynamicLiquidityFee;
    }

  function getAmountToLiquify(uint256 _targetLiquidity_, uint256 _targetLiquidityDenominator_)external view returns(uint256){
        uint256 dynamicLiquidityFee = isOverLiquified(_targetLiquidity_, _targetLiquidityDenominator_) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        return amountToLiquify;
    }

    function getAmountSwap(uint256 targetLiquidity_, uint256 targetLiquidityDenominator_)external view returns(uint256){

       uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity_, targetLiquidityDenominator_) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        return amountToSwap;

    }

      function swapBack() public swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WFTM;
        uint256 balanceBefore = address(this).balance;
     
        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            100000000000,
            0,
            path,
            address(this),
            block.timestamp
        );
   /*
        uint256 amountFTM = address(this).balance.sub(balanceBefore);

        uint256 totalFTMFee = totalFee.sub(dynamicLiquidityFee.div(2));

        uint256 amountFTMLiquidity = amountFTM.mul(dynamicLiquidityFee).div(totalFTMFee).div(2);
        uint256 amountFTMReflection = amountFTM.mul(reflectionFee).div(totalFTMFee);
        uint256 amountFTMMarketing = amountFTM.mul(marketingFee).div(totalFTMFee);

        //try distributor.deposit{value: amountFTMReflection}() {} catch {}
        payable(marketingFeeReceiver).transfer(amountFTMMarketing);
            
        if(amountToLiquify > 0){
            swapRouter.addLiquidityETH{value: amountFTMLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountFTMLiquidity, amountToLiquify);
        }
        */
    }

     function getCirculatingSupply() public view returns (uint256) {
        return totalSupply_.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

      function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(nativeTokenPair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function setSwapStatus()external {
        if(isSwapEnabled==true){
            isSwapEnabled = false;
        }else {
            isSwapEnabled = true;
        }
    }

    function getSwapStatus()external view returns(bool){
        return isSwapEnabled;
    }

     function setSwapBackSettings(bool _enabled, uint256 _amount) external {
        isSwapEnabled = _enabled;
        swapThreshold = _amount;
    }

    event logSwapBack(bool shouldSwapBack,bool isSelling);
    event logSwapBack1(bool isOverLiquified,uint256 dynamicLiquidityFee, uint256 amountToLiquify,uint256 amountToSwap, uint256 totalFee);
    event AutoLiquify(uint256 amountFTM, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);

}

pragma solidity 0.8.7;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

pragma solidity 0.8.7;

interface IUniswapV2Router {
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

pragma solidity 0.8.7;

/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}