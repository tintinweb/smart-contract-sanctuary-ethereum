//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// сделать единный таймлимит на апрув и для сендера и для экзекутера (переменная timeEnd чтобы была одна)

// переписать структуру RoomNumber так, чтобы структура Executor внутри была сделана как массив, мб газ на этом хорошо сэкономить получится

contract ETH_TO_FIAT3 {

    address public admin;
    uint256 public commissions;
    uint256 public comissionSum;
    uint256 public minTimeForApproveFromSender;
    uint256 public maxTimeForApproveFromSender;
    uint256 public maxTimeForExecutor;
    uint256 public minTimeForExecutor;
    uint256 public multiplicityOfTime;

    // перечисление, которое отвечает за состояние скама в комнате (нет скама/настоящий скам/фэйк скам)
    enum AdminDecision {
        None,
        scamReal,
        scamFake
    }

    // перечисление, которое отвечает за состояние комнаты (работает/на паузе/остановлена)
    enum RoomStatus {
        None,
        Continue,
        Paused,
        Stopped
    }

    // перечисление, которое отвечает за состояние сделки (работает/на паузе/остановлена)
    enum DealStatus {
        None,
        Continue,
        ApprovedByExecutor,
        ApprovedBySender,
        Closed
    }

    // структура описывающая комнату
    struct RoomNumber {

        //адресс покупателя
        address sender;

        //покупатель подтверждает что с товаром все хорошо и дает разреншение на вывод средств
        bool senderApprove;

        //случился ли скам
        bool isScam;

        //время блока, в котором была создана комната
        uint256 timestamp;

        // проверяет, подтвердил ли сделку продавец
        bool isLive;

        // Эту штука свидетельствует о решении админа о скаме
        AdminDecision adminDecision;

        // сюда будет записываться время, за которое создателю комнаты позволено давать аппрув того, что executor действительно перевел средства
        uint32 timeForApproveFromSender;

        // тут у нас маппинг, который исходя из номера отвечает структурой исполнителя
        // типо у нас же одну комнату может несколько человек выполнить, это для этого и сделано
        Executor[] executor;

        // этот счетчик нужен чисто для addressOfExecutor, чтобы у каждого исполнителя был свой номер
        uint16 counter;

        // обьем комнаты в конечной валюте (endCurrency)
        uint256 volume;

        // тут у нас указываестя курс, по которому будут менять один актив на второй
        uint256 rate;

        // верхний лимит у исполнителя (как на бинанс лимиты выполнены)
        uint256 maxLimit;

        // нижний лимит у исполнителя (как на бинанс лимиты выполнены)
        uint256 lowLimit;

        // время, которое дается на выполнение сделки
        uint32 timeForExecutor;

        // эта переменная отвечает за статус комнаты
        RoomStatus roomStatus;

    }

    // это структура, которая хранит в себе всю информацию об одном из исполнителей сделки
    struct Executor {
        // это адресс человека, который выполняет сделку
        address addressOfExecutor;

        // обьем, который будет исполнять этот чел
        uint256 volume;

        // timestamp начала выполнения сделки
        uint256 timeStart;

        // timestamp окончания выполнения сделки
        uint256 timeEnd;

        // тут в случае, если все был скам со стороны исполнителя, то поле становится true
        bool isScam;

        // тут мы указываем решение о скаме, который принял админ по данному исполнителю
        AdminDecision adminDecision;

        // эта переменная отвечает за статус сделки
        DealStatus dealStatus;

    }

    // маппинг со структурой комнаты
    mapping (uint256 => RoomNumber) roomNumberMap;

    
    // классические модификатор только для админа
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    //--------------------------------------------------------------------------------------------------
    // тут основная часть контракта (функции)

    Executor internal buf = Executor(
        address(0), 0, 0, 0, false, AdminDecision.None, DealStatus.None
    );

    // тут мы создаем в комнату в Native токенах сети
    function makeRoomEth(
        uint256 _roomNumber, // номер комнаты
        uint32 _timeForApproveFromSender, // время, за которое создатель комнаты должен дать аппрув того, что executor действительно перевел средства (в секундах)
        uint32 _timeForExecutor, // тут мы устанавливаем время, за которое должна быть выполнена сделка исполнителем (Executor) (в секундах)
        uint256 _rate, // курс, по которому хотят быть обменяны эфиры на _endCurrency (всегда к доллару)
        uint256 _maxLimit, // верхний лимит у исполнителя (как на бинанс лимиты выполнены)
        uint256 _lowLimit // нижний лимит у исполнителя (как на бинанс лимиты выполнены)
    ) public payable {
        require(roomNumberMap[_roomNumber].roomStatus == RoomStatus.None, "Active room");

        // тут мы проверяем, что все временные рамки выставленны верно (все в cекундах)
        require(_timeForApproveFromSender <= maxTimeForApproveFromSender && _timeForApproveFromSender >= minTimeForApproveFromSender && _timeForApproveFromSender % multiplicityOfTime == 0, "Incorrect time A");
        require(_timeForExecutor <= maxTimeForExecutor && _timeForExecutor >= minTimeForExecutor && _timeForExecutor % multiplicityOfTime == 0, "Incorrect time E");
        require(_maxLimit > _lowLimit && (msg.value * _rate) > _maxLimit, "Incorrect limits");

        // монету у нас отправляются в очень мелких величинах (условно 1 udst записыватеся в контракте transferFrom как 1000000)
        // соответсченно подобное деление не будет приводить к неправильным вычислениям
        // comissionSum += (msg.value / 1000 * commissions);
        //
        //

        // roomNumberMap[_roomNumber] = RoomNumber({
        //     sender: msg.sender,
        //     senderApprove:false,
        //     isScam: false,
        //     timestamp: block.timestamp,
        //     isLive: false,
        //     adminDecision: AdminDecision.None,
        //     timeForApproveFromSender: _timeForApproveFromSender,
        //     executor: new Executor[buf](1),
        //     counter: 0,
        //     volume: (msg.value * _rate),
        //     rate: _rate,
        //     maxLimit: _maxLimit,
        //     lowLimit: _lowLimit,
        //     timeForExecutor: _timeForExecutor,
        //     roomStatus: RoomStatus.Continue
        // });
  
        roomNumberMap[_roomNumber].timeForApproveFromSender = _timeForApproveFromSender;
        roomNumberMap[_roomNumber].timeForExecutor = _timeForExecutor;
        roomNumberMap[_roomNumber].volume = (msg.value * _rate);
        roomNumberMap[_roomNumber].rate = _rate;
        roomNumberMap[_roomNumber].maxLimit = _maxLimit;
        roomNumberMap[_roomNumber].lowLimit = _lowLimit;
        roomNumberMap[_roomNumber].sender = msg.sender;
        roomNumberMap[_roomNumber].timestamp = block.timestamp;

        //roomNumberMap[_roomNumber].value = msg.value; // (msg.value - (msg.value / 1000 * commissions));

        roomNumberMap[_roomNumber].roomStatus = RoomStatus.Continue;
    }

    // тут открывает сделка на исполнение конкретного обьема от комнаты
    function completeDeal (
        uint256 _roomNumber, // номер комнаты
        uint256 _txVolume // какой обьем готовы исполнить в volume (в эфире)
    ) public {
        // тут проверяем, чтобы чел не пытался выполнить сделки больше, чем заявлена
        // вот это проверку потенциально можно будет удалить, ее проверка следующая заменяет
        // require(_txVolume <= roomNumberMap[_roomNumber].volume, "you trying to overflow deal");
        require(roomNumberMap[_roomNumber].roomStatus == RoomStatus.Continue, "The room is stoped");
        // тут мы проверяем, что обьем сделки исполнителя находится в пределах лимитов
        require(roomNumberMap[_roomNumber].maxLimit > _txVolume && roomNumberMap[_roomNumber].lowLimit < _txVolume, "Your volume is out of limits");

        // тут мы записываем, кто является исполнителем этого обьема
        roomNumberMap[_roomNumber].counter += 1;

        // создаем структуру чела, который готов исполнить обьем
        roomNumberMap[_roomNumber].executor[roomNumberMap[_roomNumber].counter] = Executor({
            addressOfExecutor: msg.sender,
            volume: _txVolume,
            timeStart: block.timestamp,
            timeEnd: (block.timestamp + roomNumberMap[_roomNumber].timeForExecutor),
            isScam: false,
            adminDecision: AdminDecision.None,
            dealStatus: DealStatus.Continue
        });

        // освобождаем обьем комнаты от выполняемой транзакции, чтобы другие ее не могли выполнить
        roomNumberMap[_roomNumber].volume -= _txVolume;

    }

    // тут исполнитель (executor) должен подтвердить свой перевод средств
    function dealDone(uint256 _roomNumber, uint256 _counter) external {
        require(roomNumberMap[_roomNumber].executor[_counter].addressOfExecutor == msg.sender, "You are not executor");
        roomNumberMap[_roomNumber].executor[_counter].dealStatus = DealStatus.ApprovedByExecutor;
        roomNumberMap[_roomNumber].executor[_counter].timeEnd = block.timestamp + roomNumberMap[_roomNumber].timeForApproveFromSender;
    }

    // тут мы получаем подтверждение транзакции покупателя, что исполноитель (struct Executor) все выполнила правильно
    function approveFromSender(uint256 _roomNumber, uint256 _counter) external {
        require(roomNumberMap[_roomNumber].executor[_counter].isScam == false, "There is a scam on this executor");
        require(roomNumberMap[_roomNumber].sender == msg.sender);
        require(roomNumberMap[_roomNumber].executor[_counter].dealStatus == DealStatus.ApprovedByExecutor, "Executor dont give his approve");

        roomNumberMap[_roomNumber].executor[_counter].dealStatus = DealStatus.ApprovedBySender;
    }

    function finalWithdraw(uint256 _roomNumber, uint256 _counter) public {
        require(roomNumberMap[_roomNumber].executor[_counter].dealStatus == DealStatus.ApprovedBySender, "Sender dont give approve");
        withdraw(_roomNumber, _counter);
    }

    // тут у нас исполнитель может вывести деньги, если создатель комнаты дал аппрув
    function withdraw(uint256 _roomNumber, uint256 _counter) internal {
        require(roomNumberMap[_roomNumber].executor[_counter].dealStatus != DealStatus.Closed, "Deal is closed");

        roomNumberMap[_roomNumber].executor[_counter].dealStatus = DealStatus.Closed;

        payable(roomNumberMap[_roomNumber].executor[_counter].addressOfExecutor).transfer(roomNumberMap[_roomNumber].executor[_counter].volume/roomNumberMap[_roomNumber].rate);
    }

    // тут создатель комнаты может ее закрыть, в случае если в ней не осталось исполнителей
    function closeRoom(uint256 _roomNumber) external {
        require(roomNumberMap[_roomNumber].sender == msg.sender, "You are not sender");
        require(roomNumberMap[_roomNumber].roomStatus != RoomStatus.Stopped, "Room already closed");

        // тут мы проверяем, чтобы все в комнате было завершено и создатель комнаты не мог просто так взять и закрыть эту комнату
        if (roomNumberMap[_roomNumber].counter > 0) {
            for (uint256 i = 1; i <= roomNumberMap[_roomNumber].counter; i++) {
                require(roomNumberMap[_roomNumber].executor[i].dealStatus == DealStatus.Closed, "Deal is opened");
            }
        }

        // тут мы выводим остатки средст из комнаты
        if (roomNumberMap[_roomNumber].volume > 0) {
            payable(msg.sender).transfer(roomNumberMap[_roomNumber].volume/roomNumberMap[_roomNumber].rate);
        }

        roomNumberMap[_roomNumber].roomStatus = RoomStatus.Stopped;

    }

    // в этой функции мы позволяем создателю комнаты запретить создание новых сделок
    function stopRoom(uint256 _roomNumber) external {
        require(roomNumberMap[_roomNumber].sender == msg.sender);
        roomNumberMap[_roomNumber].roomStatus = RoomStatus.Paused;
    }

    // в этой функции мы позволяем создателю комнаты возобновить создание новых сделок
    function continueRoom(uint256 _roomNumber) external {
        require(roomNumberMap[_roomNumber].sender == msg.sender);
        roomNumberMap[_roomNumber].roomStatus = RoomStatus.Continue;
    }

    // тут у нас sender может вернуть деньги в комнату, если экзекутор просрачивает вызов "function dealDone"
    function delayFromExecutor(uint256 _roomNumber, uint256 _counter) external {
        require(roomNumberMap[_roomNumber].executor[_counter].dealStatus == DealStatus.Continue, "Deal is done");
        require(roomNumberMap[_roomNumber].executor[_counter].timeEnd <= block.timestamp, "Executor got some time for deal");
        
        roomNumberMap[_roomNumber].executor[_counter].dealStatus = DealStatus.Closed;
        roomNumberMap[_roomNumber].volume += roomNumberMap[_roomNumber].executor[_counter].volume;
    }

    // тут у нас исполнитель может вывести деньги, если создатель просрочил аппрув сделки
    function delayFromSender(uint256 _roomNumber, uint256 _counter) external {
        require(roomNumberMap[_roomNumber].executor[_counter].timeEnd <= block.timestamp, "Sender got some time for deal");
        require(roomNumberMap[_roomNumber].executor[_counter].dealStatus == DealStatus.ApprovedByExecutor, "Deal is not done");

        withdraw(_roomNumber, _counter);
    }

    // тут мы узнаем, скаманули ли покупателя (он соответсвенно подтверждает что это скам)
    function scamFromSender(uint256 _roomNumber, uint256 _counter) external{
        require(roomNumberMap[_roomNumber].sender == msg.sender);
        require(roomNumberMap[_roomNumber].executor[_counter].dealStatus == DealStatus.ApprovedByExecutor);
        
        roomNumberMap[_roomNumber].executor[_counter].isScam = true;
    }

    // данная функция служит для принятия решения админом о скаме
    function adminDecision(uint256 _roomNumber, AdminDecision _decision, uint256 _counter) external onlyAdmin {
        require(roomNumberMap[_roomNumber].executor[_counter].isScam == true);
        roomNumberMap[_roomNumber].executor[_counter].adminDecision = _decision;
    }

    // тут если у нас прожимается скам, то админ будет разрешать проблему и делать возврат средств создателю комнаты (типо исполнитель скаманулся)
    function scamReal(uint256 _roomNumber, uint256 _counter) external {
        require(roomNumberMap[_roomNumber].executor[_counter].adminDecision == AdminDecision.scamReal);

        roomNumberMap[_roomNumber].volume += roomNumberMap[_roomNumber].executor[_counter].volume;
    }

    // тут если у нас прожимается скам, то админ будет разрешать проблему и делать возврат получателю средств
    // (типо покупатель решил скамануть всех, получить товар и при этом деьги вернуть)
    function scamFake(uint256 _roomNumber, uint256 _counter) external {
        require(roomNumberMap[_roomNumber].executor[_counter].adminDecision == AdminDecision.scamFake);

        withdraw(_roomNumber, _counter);
    }

    //-----------------------------------------------------------------------------------------------------------
    // Тут несколько вью функций

    // функция, которая возвращает нам одного из исполнителей комнаты
    function getExecutor(uint256 _roomNumber, uint256 _counter) public view returns(Executor memory) {
        return(roomNumberMap[_roomNumber].executor[_counter]);
    }

    // функция, которая возвращает нам статические данные о комнате
    function getRoomStatic(uint256 _roomNumber) public view returns(
        address,
        uint256,
        uint64,
        uint256,
        uint256,
        uint256,
        uint256
        ) {
        return(
            roomNumberMap[_roomNumber].sender,
            roomNumberMap[_roomNumber].timestamp,
            roomNumberMap[_roomNumber].timeForApproveFromSender,
            roomNumberMap[_roomNumber].rate,
            roomNumberMap[_roomNumber].maxLimit,
            roomNumberMap[_roomNumber].lowLimit,
            roomNumberMap[_roomNumber].timeForExecutor
        );
    }

    // функция, которая возвращает нам динамические данные о комнате
    function getRoomDynamic(uint256 _roomNumber) public view returns(
        bool,
        bool,
        bool,
        AdminDecision,
        uint256,
        uint256,
        RoomStatus
    ) {
        return(
            roomNumberMap[_roomNumber].senderApprove,
            roomNumberMap[_roomNumber].isScam,
            roomNumberMap[_roomNumber].isLive,
            roomNumberMap[_roomNumber].adminDecision,
            roomNumberMap[_roomNumber].counter,
            roomNumberMap[_roomNumber].volume,
            roomNumberMap[_roomNumber].roomStatus
        );
    }


    //-----------------------------------------------------------------------------------------------------------
    // админский функции для глобальных штук

    // функция вывода всех собранных комиссий
    function withdrawCommissions() external onlyAdmin {
        payable(msg.sender).transfer(comissionSum);
        comissionSum = 0;
    }

    // тут админ устанавливает комиссии (исчисление идет в десятых процента, то есть "5" будет соответсвеовать 0,5%)
    function setCommissions(uint256 _commissions) external onlyAdmin {
        commissions = _commissions;
    }

    // устанавливает время в секундах, для лимитов сендера
    function setMaxTimeForApproveFromSender(uint256 _maxTimeForApproveFromSender) external onlyAdmin {
        maxTimeForApproveFromSender = _maxTimeForApproveFromSender;
    }

    // устанавливает время в секундах, для лимитов сендера
    function setMinTimeForApproveFromSender(uint256 _minTimeForApproveFromSender) external onlyAdmin {
        minTimeForApproveFromSender = _minTimeForApproveFromSender;
    }

    // устанавливает время в секундах, для лимитов экзекутера
    function setMaxTimeForExecutor(uint256 _maxTimeForExecutor) external onlyAdmin {
        maxTimeForExecutor = _maxTimeForExecutor;
    }

    // устанавливает время в секундах, для лимитов экзекутера
    function setMinTimeForExecutor(uint256 _minTimeForExecutor) external onlyAdmin {
        minTimeForExecutor = _minTimeForExecutor;
    }

    // устанавливает кратность тайм лимитов
    function setMultiplicityOfTime(uint256 _multiplicityOfTime) external onlyAdmin {
        multiplicityOfTime = _multiplicityOfTime;
    }

    // тут мы можем переназначить главного админа контракта
    function changeAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }


    //-----------------------------------------------------------------------------------------------------------
    // конструктор

    constructor() {
        admin = msg.sender;
    }

}