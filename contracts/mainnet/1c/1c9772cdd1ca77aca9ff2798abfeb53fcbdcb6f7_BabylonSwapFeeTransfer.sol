/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

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


// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathBabylonSwap {
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}



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



interface IBank {
    function addReward(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) external;

    function addrewardtoken(address token, uint256 amount) external;
}

interface IFarm {
    function addLPInfo(
        IERC20 _lpToken,
        IERC20 _rewardToken0,
        IERC20 _rewardToken1
    ) external;

    function addReward(
        address _lp,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1
    ) external;

    function addrewardtoken(
        address _lp,
        address token,
        uint256 amount
    ) external;
}



interface IBabylonSwapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeToSetter(address) external;
    function PERCENT100() external view returns (uint256);
    function DEADADDRESS() external view returns (address);
    
    function lockFee() external view returns (uint256);
    // function sLockFee() external view returns (uint256);
    function pause() external view returns (bool);
    function setRouter(address _router) external ;
    function feeTransfer() external view returns (address);

    function setFeeTransfer(address)external ;
    
}

contract BabylonSwapFeeTransfer {
    using SafeMathBabylonSwap for uint256;

    uint256 public constant PERCENT100 = 1000000;

    // fee addresses
    address public farm;
    address public miningBank;
    address public xbtBank;

    // Swap fees
    uint256 public miningbankFee = 300;
    uint256 public farmFee = 1000;
    uint256 public xbtbankFee = 200;

    constructor(address _farm, address _miningBank, address _xbtBank) public {
        farm = _farm;
        miningBank = _miningBank;
        xbtBank = _xbtBank;
    }

    function takeSwapFee(address lp, address token) public returns (uint256) {
        uint256 amount = IERC20(token).balanceOf(address(this));
        uint256[10] memory fees;

        fees[0] = amount.mul(miningbankFee).div(swaptotalFee()); //miningbankFee
        fees[1] = amount.mul(farmFee).div(swaptotalFee()); //farmFee
        fees[2] = amount.mul(xbtbankFee).div(swaptotalFee()); //xbtbankFee

        _approvetokens(token, miningBank, amount);
        IBank(miningBank).addrewardtoken(token, fees[0]);
 
        _approvetokens(token, farm, amount);
        IFarm(farm).addrewardtoken(lp, token, fees[1]);

        _approvetokens(token, xbtBank, amount);
        IFarm(xbtBank).addrewardtoken(lp, token, fees[2]);
    }

    function swaptotalFee() public view returns (uint256) {
        return miningbankFee + farmFee + xbtbankFee;
    }

    function _approvetokens(
        address _token,
        address _receiver,
        uint256 _amount
    ) private {
        if (
            _token != address(0x000) ||
            IERC20(_token).allowance(address(this), _receiver) < _amount
        ) {
            IERC20(_token).approve(_receiver, _amount);
        }
    }

}