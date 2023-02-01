/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);}

interface DAPP {
    function distributeTokenPercent(address token, address receiver, uint256 amount) external;
    function distributeTokenAmount(address token, address receiver, uint256 amount) external;
    function distributeStaking(uint256 totalPercentage, uint256 stakePercentageLP) external;
    function setParameters(address liquidity, address token, address core) external;
    function rescueETH(uint256 amountPercentage) external;
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

contract StakingDistribution is DAPP, Auth {
    address tokenStaking;
    address liquidityStaking;
    address coreToken;
    constructor() Auth(msg.sender) {}
    receive() external payable {}

    function setParameters(address liquidity, address token, address core) external override authorized {
        liquidityStaking = liquidity; tokenStaking = token; coreToken = core;
    }

    function distributeStaking(uint256 totalPercentage, uint256 stakeLPPercentage) external override authorized {
        uint256 tokenAmt = (IERC20(coreToken).balanceOf(address(this)) * totalPercentage) / uint256(100);
        uint256 LPStakingAmt = (tokenAmt * stakeLPPercentage) / uint256(100);
        uint256 TokenStakingAmt = tokenAmt - LPStakingAmt;
        IERC20(coreToken).transfer(liquidityStaking, LPStakingAmt);
        IERC20(coreToken).transfer(tokenStaking, TokenStakingAmt);
    }
    
    function distributeTokenPercent(address token, address receiver, uint256 amount) external override authorized {
        uint256 tokenAmt = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(receiver, (tokenAmt * amount / 100));
    }

    function distributeTokenAmount(address token, address receiver, uint256 amount) external override authorized {
        IERC20(token).transfer(receiver, amount);
    }

    function rescueETH(uint256 amountPercentage) external override authorized {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }
}