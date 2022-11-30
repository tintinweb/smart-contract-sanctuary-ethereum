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
        require(msg.value == amount, "Eth quantity error");
        require(!record[orderid], "OrderId has been used");
        beneficiary.transfer(msg.value);
       
        // IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6).deposit{
        //     value: msg.value
        // }();
        // bool result = IERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6)
        //     .transfer(0x419062fe412AAfE50D96A83d6a401313F0a15Fbe, amount);

        // if (!result) {
        //     revert("transfer failed");
        // }
        record[orderid] = true;
        emit TransferSuccess(
            msg.sender,
            beneficiary,
            orderid,
            amount
        );
    }
}