//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract OTC_01 {
    
    bool public isPayed = false;
    bool public senderApprove = false;
    bool public recipientApprove = false;
    mapping(uint256 => address) public roomNumberRecipient;
    mapping(uint256 => address) public roomNumberSender;
    mapping(uint256 => bool) public roomNumberSenderApprove;
    mapping(uint256 => bool) public roomNumberRecipientApprove;
    mapping(uint256 => uint256) public roomNumberValue;
    mapping(uint256 => bool) public roomNumberIsPayed;
    address public recipient;
    address public sender;
    uint256 public value;
    address public admin;


    // модификатор для только продавца
    modifier onlyRecepient {
        require(msg.sender == recipient);
        _;
    }

    // модификатор для только покупателя
    modifier onlySender {
        require(msg.sender == sender);
        _;
    }

    // проверяет, пришли ли деньги на контракт (скинул ли покупатель деньги)
    modifier ModifierIsPayed {
        require(isPayed == true);
        _;
    }

    // сделал ли финальное подтвержддение продавец
    modifier ModifierSenderApprove {
        require(senderApprove == true);
        _;
    }

    // сделал ли финальное подтвержддение покупатель
    modifier ModifierRecipientApprove {
        require(recipientApprove == true);
        _;
    }





    // тут от покупателя деньги получаем на контракт
    function storeETH(address _recipient, uint256 _roomNumber) payable public {
        require(roomNumberSender[_roomNumber] == 0x0000000000000000000000000000000000000000, "there is a deal");
        require(roomNumberRecipient[_roomNumber] == 0x0000000000000000000000000000000000000000, "there is a deal");
        require(roomNumberIsPayed[_roomNumber] == false, "there is a deal");
        require(roomNumberValue[_roomNumber]== 0, "there is a deal");

        roomNumberIsPayed[_roomNumber] = true;
        roomNumberValue[_roomNumber] = msg.value;
        roomNumberRecipient[_roomNumber] = _recipient;
        roomNumberSender[_roomNumber] = msg.sender;
    }

    // тут мы получаем подтверждение транзакции покупателя
    function approveFromSender(uint256 _roomNumber) external{
        require(roomNumberSender[_roomNumber] == msg.sender);
        roomNumberSenderApprove[_roomNumber] = true;
    }

    // тут мы получаем подтверждение транзакции от продавца
    function approveFromRecepient(uint256 _roomNumber) external{
        require(roomNumberRecipient[_roomNumber] == msg.sender);
        roomNumberRecipientApprove[_roomNumber] = true;
    }

    // тут продавец деньги выводит
    function withdraw(uint256 _roomNumber) external {
        require(msg.sender == roomNumberRecipient[_roomNumber]);
        address payable to = payable(msg.sender);
        to.transfer(roomNumberValue[_roomNumber]);

        roomNumberValue[_roomNumber] = 0;
        roomNumberRecipient[_roomNumber] = 0x0000000000000000000000000000000000000000;
        roomNumberSender[_roomNumber] = 0x0000000000000000000000000000000000000000;
        roomNumberRecipientApprove[_roomNumber] = false;
        roomNumberSenderApprove[_roomNumber] = false;
        roomNumberIsPayed[_roomNumber] = false;
    } 


    constructor() {
        admin = msg.sender;
    }

}