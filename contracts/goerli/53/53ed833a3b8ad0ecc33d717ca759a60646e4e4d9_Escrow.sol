/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Escrow {

    struct escrow {
        uint amount;
        address buyer;
        address seller;
        address agent;
        bool goodsDelivered;
    }

    constructor() {
    }

    uint nonce;

    mapping (bytes32 => escrow) public escrowRegistry;

    function openEscrow(address _seller, address _agent) external payable returns (bytes32 _escrowId) {
        address _buyer = msg.sender;
        uint _amount = msg.value;
        _escrowId = keccak256(abi.encodePacked(_buyer, nonce));
        escrowRegistry[_escrowId].amount = _amount;
        escrowRegistry[_escrowId].buyer = _buyer;
        escrowRegistry[_escrowId].seller = _seller;
        escrowRegistry[_escrowId].agent = _agent;
        nonce += 1;
    }

    function withdrawAmount(bytes32 _escrowId) external payable returns (bool){
        require((escrowRegistry[_escrowId].goodsDelivered == true && msg.sender == escrowRegistry[_escrowId].seller)
            || (escrowRegistry[_escrowId].goodsDelivered == false && msg.sender == escrowRegistry[_escrowId].buyer));
        payable(msg.sender).transfer(escrowRegistry[_escrowId].amount);
        return (true);
    }

    function goodsDelivered(bytes32 _escrowId, bool _goodsDelivered) external returns (bool){
        require(msg.sender == escrowRegistry[_escrowId].agent);
        escrowRegistry[_escrowId].goodsDelivered = _goodsDelivered;
    }
}