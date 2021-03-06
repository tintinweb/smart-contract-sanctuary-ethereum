pragma solidity ^0.4.24;

interface Token {
    function transfer(address _to, uint256 _value) external;
}

contract Crowdsale {
    
    Token public tokenReward;
    address public owner;
    
    event FundTransfer(address backer, uint amount);

    constructor() public {
        owner = msg.sender;
        tokenReward = Token(0xE80450753db8bBF37B2a4AB0E4952F0D9FebBfA1);
    }

    function () payable public {
        require(msg.value > 0);
        tokenReward.transfer(msg.sender, msg.value);
        emit FundTransfer(msg.sender, msg.value);
        owner.transfer(msg.value);
    }
}