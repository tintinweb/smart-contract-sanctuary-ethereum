// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface CErc20 { 
    function mint(uint) external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
}

contract compound_supply {

    address public owner;
    IERC20 public erc20Token;
    CErc20 public cErc20Token;
    constructor(address _erc20, address _cErc20) {
        owner = msg.sender;
        erc20Token = IERC20(_erc20);
        cErc20Token = CErc20(_cErc20);
    }

    event tokensupplied(uint suppliedResponse);
    
    function supplytocompound(uint256 _numoftokens) external {
        erc20Token.transferFrom(msg.sender, address(this), _numoftokens);
        erc20Token.approve(address(cErc20Token), _numoftokens);
        uint supplied = cErc20Token.mint(_numoftokens);
        emit tokensupplied(supplied);
    }

    function getBalancecErc20() public view returns (uint) {
        return cErc20Token.balanceOf(address(this));
    }

    function getBalanceErc20() public view returns (uint256) {
        return erc20Token.balanceOf(address(this));
    }

    function getUnderlyingBalance() external returns (uint) {
        return cErc20Token.balanceOfUnderlying(address(this));
    }
}