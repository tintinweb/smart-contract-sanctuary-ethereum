/**
 *Submitted for verification at Etherscan.io on 2022-07-06
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
    function burn(uint amount) external;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Contract {

    address public manager;
    address public admin;
    IERC20 public tokenEof;
    IERC20 public tokenUsdt;

    struct Record { uint256 orderId; uint256 eof; uint256 usdt; uint times; }
    mapping (address => Record[]) _records;
    mapping (address => Record[]) _pledges;
    
    constructor(address _admin, IERC20 _rof, IERC20 _usdt) {
        admin = _admin;
        tokenEof = IERC20(_rof);
        tokenUsdt = IERC20(_usdt);
        manager = msg.sender;
    }

    /*
     * buy
     */
    function buy(uint256 _orderId, uint256 _eofAmount, uint256 _usdtAmount) public {
        require(tokenEof.balanceOf(msg.sender) >= _eofAmount, "EOF: the balanceOf address is not enough !!");
        require(tokenEof.allowance(msg.sender, address(this)) >= _eofAmount, "EOF: the allowance is not enough !!");
        require(tokenUsdt.balanceOf(msg.sender) >= _usdtAmount, "USDT: the balanceOf address is not enough !!");
        require(tokenUsdt.allowance(msg.sender, address(this)) >= _usdtAmount, "USDT: the allowance is not enough !!");

        tokenEof.transferFrom(msg.sender, address(this), _eofAmount);
        tokenUsdt.transferFrom(msg.sender, address(this), _usdtAmount);

        _records[msg.sender].push(Record(_orderId, _eofAmount, _usdtAmount, block.timestamp));
    }

    /*
     * records of buy
     */
    function getBuyRecords(address _addr) external view returns (Record[] memory) {
        return _records[_addr];
    }

    // ----------------------------------------------------------------------------------------------------

    /*
     * pledge
     */
    function pledge(uint256 _orderId, uint256 _eofAmount, uint256 _usdtAmount) public {
        require(tokenEof.balanceOf(msg.sender) >= _eofAmount, "EOF: the balanceOf address is not enough !!");
        require(tokenEof.allowance(msg.sender, address(this)) >= _eofAmount, "EOF: the allowance is not enough !!");
        require(tokenUsdt.balanceOf(msg.sender) >= _usdtAmount, "USDT: the balanceOf address is not enough !!");
        require(tokenUsdt.allowance(msg.sender, address(this)) >= _usdtAmount, "USDT: the allowance is not enough !!");

        tokenEof.transferFrom(msg.sender, address(this), _eofAmount);
        tokenUsdt.transferFrom(msg.sender, address(this), _usdtAmount);

        _pledges[msg.sender].push(Record(_orderId, _eofAmount, _usdtAmount, block.timestamp));
    }

    /*
     * records of pledge
     */
    function getPledgeRecords(address _addr) external view returns (Record[] memory) {
        return _pledges[_addr];
    }

    // ----------------------------------------------------------------------------------------------------

    /*
     * withdraw eof
     */
    function withdrawEof(address _to, uint256 _amount) public onlyManager {
        require(tokenEof.balanceOf(address(this)) >= _amount, "the balanceOf contract is not enough !!");
        tokenEof.transfer(_to, _amount);
    }

    /*
     * withdraw usdt
     */
    function withdrawUsdt(address _to, uint256 _amount) public onlyManager {
        require(tokenUsdt.balanceOf(address(this)) >= _amount, "the balanceOf contract is not enough !!");
        tokenUsdt.transfer(_to, _amount);
    }

    // ----------------------------------------------------------------------------------------------------

    /*
     * set admin
     */
    function setAdmin(address _admin) external onlyManager {
        admin = _admin;
    }

    /*
     * reward
     */
    function reward(uint256 _total, address[] memory _tos, uint256[] memory _amounts) public onlyManager {
        require(tokenEof.balanceOf(admin) >= _total, "EOF: the balanceOf admin is not enough !!");
        require(tokenEof.allowance(admin, address(this)) >= _total, "EOF: the allowance contract is not enough !!");
        require(_tos.length == _amounts.length, "EOF: data exception !!");
        for (uint i = 0; i < _tos.length; i++) {
            tokenEof.transferFrom(admin, _tos[i], _amounts[i]);
        }
    }

    /*
     * burn
     */
    function burn(uint256 _amount) public onlyManager {
        require(tokenEof.balanceOf(address(this)) >= _amount, "the balanceOf contract is not enough !!");
        tokenEof.burn(_amount);
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