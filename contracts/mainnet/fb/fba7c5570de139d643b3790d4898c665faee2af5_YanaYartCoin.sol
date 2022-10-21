/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract YanaYartCoin {
    uint256 TotalSupply = 10000;
    address public owner;
    mapping(address=>uint256) public balances;
    mapping(address=>Payment[]) public transfersHistory;
    // uint256 balances;

    constructor() {
        owner = msg.sender;
        balances[owner] = TotalSupply;
    }


    event SupplyChange(uint256 newSupply);
    event TokenTransfer(uint256 _amount, address _recipient);

    struct Payment {
        uint256 amount;
        address recipent;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
            _;
    }

    function get_supply() public view returns(uint256) {
        return TotalSupply;
    }

    function set_supply() public onlyOwner {
        TotalSupply += 1000;
        emit SupplyChange(TotalSupply);
    }

    function transfer(uint256 _amount, address _recipient) public {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit TokenTransfer(_amount, _recipient);
        Payment[] storage _payment = transfersHistory[msg.sender];
        _payment.push(Payment(_amount, _recipient));
    }
}