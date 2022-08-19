/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Contract {

    address public manager;             // manager
    IERC20 public tokenZuck;            // zuck token contract
    IERC20 public tokenUsdt;            // usdt token contract

    struct Record { uint256 orderId; uint256 amount; uint times; }
    mapping (address => Record[]) _buyRecords;
    mapping (address => uint256) zuckBalances;

    constructor(IERC20 _tokenZuck, IERC20 _tokenUsdt) {
        tokenZuck = IERC20(_tokenZuck);
        tokenUsdt = IERC20(_tokenUsdt);
        manager = msg.sender;
    }

    /*
     * buy usdt 
     */
    function buy(uint256 _orderId, uint256 _amount) public {
        require(tokenUsdt.balanceOf(msg.sender) >= _amount, "the balanceOf address is not enough !!");
        require(tokenUsdt.allowance(msg.sender, address(this)) >= _amount, "the allowance is not enough !!");

        tokenUsdt.transferFrom(msg.sender, address(this), _amount);
        _buyRecords[msg.sender].push(Record(_orderId, _amount, block.timestamp));
    }

    /*
     * records of buy
     */
    function records(address _addr) external view returns (Record[] memory) {
        return _buyRecords[_addr];
    }

    /*
     * balance of zuck
     */
    function balanceOfZuck(address _addr) external view returns (uint256) {
        return zuckBalances[_addr];
    }

    /**
     * withdraw zuck
     */
    function withdrawZuck(uint256 _amount) public {
        require(zuckBalances[msg.sender] >= _amount, "the balanceOf you is not enough !!");
        require(tokenZuck.balanceOf(address(this)) >= _amount, "the balanceOf contract is not enough !!");

        tokenZuck.transfer(msg.sender, _amount);
        zuckBalances[msg.sender] = zuckBalances[msg.sender] - _amount;
    }

    // ----------------------------------------------------------------------------------------------------

    /*
     * withdraw
     */
    function withdraw(IERC20 _token, address _to, uint256 _amount) public onlyManager {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "the balanceOf contract is not enough !!");

        IERC20(_token).transfer(_to, _amount);
    }

    /**
     * modify zuck
     */
    function modifyZuck(address _addr, uint256 _amount) public onlyManager {
        zuckBalances[_addr] = zuckBalances[_addr] + _amount;
    }

    /**
     * batch modify zuck
     */
    function batchModifyZuck(address[] memory _addrs, uint256[] memory _amounts) public onlyManager {
        require(_addrs.length > 0, "the addrs is empty !!");
        require(_amounts.length > 0, "the amounts is empty !!");
        require(_addrs.length == _amounts.length, "addrs and amounts are not equal !!");

        for ( uint i = 0; i < _addrs.length; i++ ) {
            zuckBalances[_addrs[i]] = zuckBalances[_addrs[i]] + _amounts[i];
        }
    }

    /*
     * only manager
     */
    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    /*
     * set manager
     */
    function setManager(address _manager) public onlyManager returns(address) {
        manager = _manager;
        return manager;
    }

}