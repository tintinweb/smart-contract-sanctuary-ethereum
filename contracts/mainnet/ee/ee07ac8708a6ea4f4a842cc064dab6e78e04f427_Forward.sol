/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ERC20 {
    function totalSupply() external view returns (uint);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function owner() external view returns (address owner_address);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value)  external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender  , uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Forward is ERC20 {

    address public forwarded;
    ERC20 token;

    address public f_owner;

    modifier onlyAuth () {
        require(msg.sender == f_owner);
        _;
    }

    constructor(address forw) {
        f_owner = msg.sender;
        forwarded = forw;
        token = ERC20(forwarded);
    }

    function set_forwarded(address addy) public onlyAuth {
        forwarded = addy;
        token = ERC20(forwarded);
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        token.transfer(_to, _value);
        return true;
    }

    function totalSupply() public view override returns (uint) {
        return token.totalSupply();
    }

    function owner() public view override returns (address _owner) {
        return token.owner();
    }

    function name() public view override returns (string memory) {
        return token.name();
    }

    function decimals() public view override returns (uint8) {
        return token.decimals();
    }

    function symbol() public view override returns (string memory) {
        return token.symbol();
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        token.transferFrom(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return token.balanceOf(_owner);
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        token.approve(_spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return token.allowance(_owner, _spender);
    }
}