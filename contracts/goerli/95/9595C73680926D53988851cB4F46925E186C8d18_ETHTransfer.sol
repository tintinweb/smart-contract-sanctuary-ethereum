// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.10;

// import "./IEtherToken.sol";

contract ETHTransfer {
    mapping(uint256 => bool) private record;
    address payable public beneficiary;

    event TransferSuccess(
        address from,
        address to,
        uint256 OrderId,
        uint256 Amount
    );

    constructor(
        address payable reciver
    ){
        beneficiary = reciver;
    }

    function Ordertransfer(uint256 orderid, uint256 amount) external payable {
        beneficiary.transfer(msg.value);
        require(msg.value == amount, "Eth quantity error");
        require(!record[orderid], "OrderId has been used");

        // beneficiary.transfer(msg.value);

        record[orderid] = true;
        emit TransferSuccess(
            msg.sender,
            beneficiary,
            orderid,
            amount
        );
    }
}