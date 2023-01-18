/**
 *Submitted for verification at Etherscan.io on 2023-01-18
*/

// File: contracts/test.sol



pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount ) external returns (bool);
}

contract BulkTransfer2 {
    constructor () {}

    function execute(IERC20 _token, address[] memory _recipients, uint256[] memory _amounts) external {
        uint256 total = 0;
        for (uint256 i = 0; i < _amounts.length; i++) {
            total += _amounts[i];
        }
        _token.transferFrom(msg.sender, address(this), total);
        require(_recipients.length == _amounts.length, "Invalid recipient and amount arrays");
        for (uint256 i = 0; i < _recipients.length; i++) {
            _token.transfer(_recipients[i], _amounts[i]);
        }
    }

    function execute2(IERC20 _token, address[] memory _recipients, uint256[] memory _amounts) external {
        require(_recipients.length == _amounts.length, "Invalid recipient and amount arrays");
        for (uint256 i = 0; i < _recipients.length; i++) {
            _token.transferFrom(msg.sender, _recipients[i], _amounts[i]);
        }
    }
}