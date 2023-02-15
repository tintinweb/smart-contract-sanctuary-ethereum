/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// contracts/WiproTokon.sol
// SPDX-License-Identifier: UNLICENSED

pragma solidity  ^0.8.17;

contract TradeRoute {
    mapping (address => bool) tradeStatus;
    enum tradeStatuType {SUBMITTED, SETTLED}
    uint uniqueKey = 0;

    event AdditionInfo(address indexed _receiver, uint256 indexed _id);
    
    struct trade {
        address to;
        address from;
        uint256 id;
        uint256 amount;
        tradeStatuType status; 
    }

    mapping (address => mapping(uint => trade)) public repogistry;

    function registerTrade(address _receiver, uint256 _amount) public returns (bool) {
        uint256 _tradeId = random(1000, _receiver);
        repogistry[msg.sender][_tradeId].to = _receiver;
        repogistry[msg.sender][_tradeId].from = msg.sender;
        repogistry[msg.sender][_tradeId].id = _tradeId;
        repogistry[msg.sender][_tradeId].amount = _amount;
        repogistry[msg.sender][_tradeId].status = tradeStatuType.SUBMITTED;

        emit AdditionInfo(_receiver, _tradeId);
        
        return true;
    }

    function random(uint256 number, address _receiver) public returns(uint256) {
        uniqueKey = uniqueKey + 45;
        return uint256(keccak256(abi.encodePacked(msg.sender, _receiver, uniqueKey))) % number;
    }


    function settledTrade(uint256 _tradeid, address _senderAddress) public returns (bool) {
        // settle trade
        address receiver = repogistry[_senderAddress][_tradeid].to;
        require(receiver == msg.sender, "Only the reciept can settle.");
        repogistry[_senderAddress][_tradeid].status = tradeStatuType.SETTLED;
        return true;
    }

    function getTradeStatus(uint256 _tradeid, address _senderAddress) public view returns (tradeStatuType) {
        return  repogistry[_senderAddress][_tradeid].status;
    }

}