/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Qualification {

    address public manager;     // manager
    IERC20 public token;        // token contract

    struct Record { uint256 orderId; uint256 amount; uint times; }
    mapping (address => Record[]) _records;

    constructor(IERC20 _token) {
        token = IERC20(_token);
        manager = msg.sender;
    }

    /*
     * buy
     */
    function buy(uint256 _orderId, uint256 _amount) public {
        require(token.balanceOf(msg.sender) >= _amount, "the balanceOf address is not enough !!");
        require(token.allowance(msg.sender, address(this)) >= _amount, "the allowance is not enough !!");

        token.transferFrom(msg.sender, address(this), _amount);
        _records[msg.sender].push(Record(_orderId, _amount, block.timestamp));
    }

    /*
     * records
     */
    function records(address _addr) external view returns (Record[] memory) {
        return _records[_addr];
    }

    /*
     * withdraw
     */
    function withdraw(address _to, uint256 _amount) public onlyManager {
        require(token.balanceOf(address(this)) >= _amount, "the balanceOf contract is not enough !!");

        token.transfer(_to, _amount);
    }

    // ----------------------------------------------------------------------------------------------------

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