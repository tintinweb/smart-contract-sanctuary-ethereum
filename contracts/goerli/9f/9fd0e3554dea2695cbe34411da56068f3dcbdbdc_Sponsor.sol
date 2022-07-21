// SPDX-License-Identifier: GPL-3.0

import "./owner.sol";

interface Ioutbox {

        function executeTransaction(
        bytes32[] calldata proof,
        uint256 index,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data
    ) external;
}
pragma solidity ^0.8.0;

/**
 * @title Sponsor
 * @dev User pay the cost of L1 execution to the sponsor and get back the remained fund
 */
contract Sponsor is Ownable {

    address payable public currentSponsor;
    address public outbox;

    constructor(address _outbox) Ownable() {
        require(_outbox != address(0),"Set a non-zero address");
        outbox = _outbox;
   }

    function setOutbox(address _outbox) external onlyOwner {
        require(_outbox != address(0),"Set a non-zero address");
        outbox = _outbox;
    }

    function execute(
        bytes32[] calldata proof,
        uint256 index,
        address l2Sender,
        address to,
        uint256 l2Block,
        uint256 l1Block,
        uint256 l2Timestamp,
        uint256 value,
        bytes calldata data 
        ) external {

        Ioutbox(outbox).executeTransaction(proof, index, l2Sender, to, l2Block, l1Block, l2Timestamp, value, data);
        currentSponsor = payable(msg.sender);
    }

    /**
     * @dev pays the cost to the sponsor and the remained ETH sent to the contrct to the user 
     * @param _gasAmount amount of gas that sponsor will need for executing the transaction 
     */
    function payToSponsor(uint256 _gasAmount) external payable{
        uint256 cost = _gasAmount * block.basefee;
        require(msg.value >= cost, "the fund is not enough");
        (bool success1, ) = currentSponsor.call{value:cost}("");
        require(success1, "Ether not transferred to Sponsor");
        unchecked{
            (bool success2, ) = payable(msg.sender).call{value:msg.value - cost}("");
            require(success2, "Ether not transferred to the User");
        }
    }
}