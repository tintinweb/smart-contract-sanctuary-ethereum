// SPDX-License-Identifier: Apache-2.0

pragma solidity^0.8.7;

import "./IERC20.sol";
contract ERC20 is IERC20{
    string ercName;
    string ercSymbol;
    uint8 ercDecimal;
    uint256 ercTotalSupply;
    address public owner;
    mapping(address=>uint256) ercBalances;
    mapping(address=>mapping(address=>uint256)) ercAlllwance;
    constructor(){
        ercName="maomi";
        ercSymbol="mi";
        ercDecimal=18;
        owner=msg.sender;
        mint(msg.sender,1000000000*(10**uint256(ercDecimal)));

    }

    //返回令牌的名称
    function name() override external view returns (string memory){
        return ercName;

    }
    //返回令牌的符号。例如“HIX”
    function symbol() override external view returns (string memory){
        return ercSymbol;

    }
    //返回令牌使用的小数位数 - 例如8，表示将令牌数量除以100000000以获得其用户表示
    function decimals() override external view returns (uint8){
        return ercDecimal;

    }
    //总供应
    function totalSupply() override external view returns (uint256){
        return ercTotalSupply;

    }
    //返回另一个具有 address 的帐户的帐户余额
    function balanceOf(address _owner) override external view returns (uint256 balance){
        return ercBalances[_owner];

    }
    //_value将代币数量转移到地址，_to并且必须触发Transfer事件
    function transfer(address _to, uint256 _value) override external returns (bool success){
        require(_value>0,"_value must >0");
        require(address(0)!=_to,"to address is zero");
        require(ercBalances[msg.sender]>=_value,"user` balance not enouth");
        ercBalances[msg.sender]-=_value;
        ercBalances[_to]+=_value;
        emit Transfer(msg.sender,_to,_value);
        return true;


    }
    //将_value一定数量的代币从地址转移_from到地址_to，并且必须触发该Transfer事件
    function transferFrom(address _from, address _to, uint256 _value) override external returns (bool success){
        require(ercBalances[_from]>=_value,"user`s balance not enough");
        require(ercAlllwance[_from][msg.sender]>=_value,"approve`s balance not enough");
        require(_value>0,"value must >0");
        require(address(0)!=_to,"_ti is a zero address");
        ercBalances[_from]-=_value;
        ercBalances[_to]+=_value;
        ercAlllwance[_from][msg.sender]-=_value;
        emit Transfer(_from,_to,_value);
        return true;

    }
    //允许_spender多次从您的帐户中提款，最高_value金额。如果再次调用此函数，它会用 覆盖当前容差_value
    function approve(address _spender, uint256 _value) override external returns (bool success){
        //允许委托0，就是取消委托
        //require(_value>0,"value must > 0");
        require(address(0)!=_spender,"_spender is a zero address");
        require(ercBalances[msg.sender]>=_value,"user`s balance not enough");
        //我委托给谁，多少钱
        ercAlllwance[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;

    }
    //_spender返回仍然允许提取的金额_owner
    function allowance(address _owner, address _spender) override external view returns (uint256 remaining){
        remaining=ercAlllwance[_owner][_spender];

    }

    function mint(address _to,uint256 _value )public {
        require(msg.sender==owner,"only owner can do");
        require(address(0)!=_to,"to is a zero address");
        require(_value>0,"value must >0");
        ercBalances[_to]+=_value;
        ercTotalSupply+=_value;
        emit Transfer(address(0),_to,_value);
    }
   
   
}