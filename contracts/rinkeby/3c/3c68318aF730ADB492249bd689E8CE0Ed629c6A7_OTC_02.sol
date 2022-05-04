//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;



contract OTC_02 {
    
    mapping(uint256 => address) public roomNumberRecipient;
    mapping(uint256 => address) public roomNumberSender;
    mapping(uint256 => bool) public roomNumberSenderApprove;
    mapping(uint256 => uint256) public roomNumberValue;
    mapping(uint256 => bool) public roomNumberIsPayed;
    mapping(uint256 => bool) public roomNumberIsScam;
    mapping(uint256 => uint256) public roomNumberBlockNumber;
    address public admin;
    uint256 public commissions;

    // классические модификатор только для админа
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    // чтобы только юзер мог вызывать, а не другой контракт
    modifier callerIsUser {
        require(tx.origin != msg.sender);
        _;
    }

    // просто функция обнуления всех переменных комнаты, выполняется после полного
    // окончания сделки любым из способов
    function zeroing(uint256 _roomNumber) internal {
        roomNumberValue[_roomNumber] = 0;
        roomNumberRecipient[_roomNumber] = 0x0000000000000000000000000000000000000000;
        roomNumberSender[_roomNumber] = 0x0000000000000000000000000000000000000000;
        roomNumberSenderApprove[_roomNumber] = false;
        roomNumberIsPayed[_roomNumber] = false;
        roomNumberIsScam[_roomNumber] = false;
        roomNumberBlockNumber[_roomNumber] = 0;
    }


//--------------------------------------------------------------------------------------------------
// часть контракта с мнгновенными сделками


    // тут от покупателя деньги получаем на контракт (мы сразу себе забираем комиссию 0,5%)
    function storeETH(address _recipient, uint256 _roomNumber) payable public callerIsUser {
        require(roomNumberSender[_roomNumber] == 0x0000000000000000000000000000000000000000, "there is a deal");
        require(roomNumberRecipient[_roomNumber] == 0x0000000000000000000000000000000000000000, "there is a deal");
        require(roomNumberIsPayed[_roomNumber] == false, "there is a deal");
        require(roomNumberValue[_roomNumber]== 0, "there is a deal");

        commissions = commissions + ((msg.value/1000)*5);

        roomNumberIsPayed[_roomNumber] = true;
        roomNumberValue[_roomNumber] = (msg.value - commissions);
        roomNumberRecipient[_roomNumber] = _recipient;
        roomNumberSender[_roomNumber] = msg.sender;
        roomNumberBlockNumber[_roomNumber] = block.number;
    }

    // тут мы получаем подтверждение транзакции покупателя
    function approveFromSender(uint256 _roomNumber) external{
        require(roomNumberSender[_roomNumber] == msg.sender);
        require(roomNumberSenderApprove[_roomNumber] == false);
        require(roomNumberIsScam[_roomNumber] == false);
        roomNumberSenderApprove[_roomNumber] = true;
    }

    // тут мы узнаем, скаманули ли покупателя (он соответсвенно подтверждает что это скам)
    function ScamFromSender(uint256 _roomNumber) external{
        require(roomNumberSender[_roomNumber] == msg.sender);
        require(roomNumberSenderApprove[_roomNumber] == false);
        require(roomNumberIsScam[_roomNumber] == false);
        roomNumberIsScam[_roomNumber] = true;
    }


    // тут продавец деньги выводит
    function withdraw(uint256 _roomNumber) external {
        require(msg.sender == roomNumberRecipient[_roomNumber]);
        require(roomNumberSenderApprove[_roomNumber] == true);
        require(roomNumberIsScam[_roomNumber] == false);
        require(msg.sender == tx.origin);
        address payable to = payable(msg.sender);
        to.transfer(roomNumberValue[_roomNumber]);

        zeroing(_roomNumber);
    } 


    // тут если у нас прожимается скам, то админ будет разрешать проблему и делать возврат отправителю средств (типо продавец скаманулся)
    function scamReal(uint256 _roomNumber) external onlyAdmin {
        require(roomNumberIsScam[_roomNumber] == true);
        address payable to = payable(roomNumberSender[_roomNumber]);
        to.transfer(roomNumberValue[_roomNumber]);
    }

    // тут если у нас прожимается скам, то админ будет разрешать проблему и делать возврат получателю средств
    // (типо покупатель решил скамануть всех, получить товар и при этом деьги вернуть)
    function scamFake(uint256 _roomNumber) external onlyAdmin {
        require(roomNumberIsScam[_roomNumber] == true);
        address payable to = payable(roomNumberRecipient[_roomNumber]);
        to.transfer(roomNumberValue[_roomNumber]);
    }

    // Если ситуация спорная (например при передаче сам по себе заблокировался аккаунт дискорд),
    // то возврат происходит 50/50
    function scamHalf(uint256 _roomNumber) external onlyAdmin {
        require(roomNumberIsScam[_roomNumber] == true);
        address payable to = payable(roomNumberRecipient[_roomNumber]);
        to.transfer(roomNumberValue[_roomNumber]/2);
        to = payable(roomNumberSender[_roomNumber]);
        to.transfer(roomNumberValue[_roomNumber]/2);
    }


    // тут надо допилить тему, мол если отправитель не нажал ни на одну, ни на вторую кнопку, то типо по истечению некоторого временеи
    // получатель может отправить транзу на запрос бабок
    function delayFromSender(uint256 _roomNumber) external {
        require(msg.sender == roomNumberRecipient[_roomNumber]);
        require(roomNumberBlockNumber[_roomNumber] + 20 >=block.number);
        address payable to = payable(roomNumberRecipient[_roomNumber]);
        to.transfer(roomNumberValue[_roomNumber]);

        zeroing(_roomNumber);
    }


    // это такая импровезированная система возврата (но ее еще надо додумать)
    // типо если чел неправильный адресс получателя ввел, или неправильную сумму и тд
    function refund(uint256 _roomNumber) external onlyAdmin {
        require(roomNumberIsScam[_roomNumber] == false);


        // это тестовая строка, которая должна компенсировать комиссию админу от возврата средств по сделке
        roomNumberValue[_roomNumber] = roomNumberValue[_roomNumber] - gasleft();

        address payable to = payable(roomNumberSender[_roomNumber]);
        to.transfer(roomNumberValue[_roomNumber]);

        zeroing(_roomNumber);
    }

    // добавить функцию вывода всех собранных комиссий админом
    function withdrawCommissions() external onlyAdmin {
        address payable to = payable(msg.sender);
        to.transfer(commissions);
    }






//-----------------------------------------------------------------------------------------------------------
// часть контракта со сделками с удержанием средств


    uint256 public timeForDeplay;

    function YstoreETH(address _recipient, uint256 _roomNumber, uint256 _timeForDeplay) payable public callerIsUser {
        require(roomNumberSender[_roomNumber] == 0x0000000000000000000000000000000000000000, "there is a deal");
        require(roomNumberRecipient[_roomNumber] == 0x0000000000000000000000000000000000000000, "there is a deal");
        require(roomNumberIsPayed[_roomNumber] == false, "there is a deal");
        require(roomNumberValue[_roomNumber]== 0, "there is a deal");

        timeForDeplay = _timeForDeplay;

        commissions = commissions + ((msg.value/1000)*5);

        roomNumberIsPayed[_roomNumber] = true;
        roomNumberValue[_roomNumber] = (msg.value - commissions);
        roomNumberRecipient[_roomNumber] = _recipient;
        roomNumberSender[_roomNumber] = msg.sender;
        roomNumberBlockNumber[_roomNumber] = block.number;
    }

    uint256 public test;
    function testTimeStamp() external {
        test = block.timestamp;
    }








    constructor() {
        admin = msg.sender;
        commissions = 0;
    }

}