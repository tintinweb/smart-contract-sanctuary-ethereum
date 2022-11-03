//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../@openzeppelin/contracts/token/ERC20/IERC20.sol";

// сделать единный таймлимит на апрув и для сендера и для экзекутера (переменная timeEnd чтобы была одна)

// переписать структуру RoomNumber так, чтобы структура Taker внутри была сделана как массив, мб газ на этом хорошо сэкономить получится

contract TO_FIAT3 {

    address public admin;
    uint8 public commissions;
    uint256 public comissionSumEth;
    mapping(address => uint256) public comissionSumToken;
    uint256 public minTimeForTakerAndMaker;
    uint256 public maxTimeForTakerAndMaker;
    uint256 public multiplicityOfTime;
    address public TCMultisig;

    // структура описывающая комнату
    struct RoomNumber {

        //адресс покупателя
        address maker;

        // сюда будет записываться время, за которое создателю комнаты позволено давать аппрув того, что taker действительно перевел средства
        uint32 timeForTakerAndMaker;

        // тут у нас маппинг, который исходя из номера отвечает структурой исполнителя
        // типо у нас же одну комнату может несколько человек выполнить, это для этого и сделано
        mapping (uint256 => Taker) taker;

        // этот счетчик нужен чисто для addressOfTaker, чтобы у каждого исполнителя был свой номер
        uint16 counter;

        // обьем комнаты в конечной валюте (endCurrency)
        uint256 volume;

        // курс, по которому будет происходить обмен токена на фиат
        uint32 rate;

        // адресс токена
        address addressOfToken;

        // верхний лимит у исполнителя (как на бинанс лимиты выполнены)
        uint256 maxLimit;

        // нижний лимит у исполнителя (как на бинанс лимиты выполнены)
        uint256 lowLimit;

        // эта переменная отвечает за статус комнаты
        uint8 roomStatus; // 0 - None, 1 - Continue, 2 - Paused, 3 - Stopped

    }

    // это структура, которая хранит в себе всю информацию об одном из исполнителей сделки
    struct Taker {
        // это адресс человека, который выполняет сделку
        address addressOfTaker;

        // обьем, который будет исполнять этот чел
        uint256 volume;

        // timestamp начала выполнения сделки
        uint256 timer;

        // тут в случае, если все был скам со стороны исполнителя, то поле становится true
        bool isScam;

        // тут мы указываем решение о скаме, который принял админ по данному исполнителю
        uint8 moderDecision; // 0 - None, 1 - scamReal, 2 - scamFake, 3 - scamHalf

        // эта переменная отвечает за статус сделки
        uint8 dealStatus; // 0 - None, 1 - Continue, 2 - ApprovedByExecutor, 3 - ApprovedBySender, 4 - Closed

    }

    // маппинг со структурой комнаты
    mapping(uint256 => RoomNumber) roomNumberMap;
    
    // классические модификатор только для админа
    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }
    
    // проверка на модератора (может принимать решение о скаме в сделке)
    modifier onlyModerAddr {
        require(msg.sender == TCMultisig);
        _;
    }

    // модификатор для более красивой проверки статуса комнаты
    modifier roomStatusCheck(bool decision, uint256 _roomNumber, uint8 status) {
        require(decision ? roomNumberMap[_roomNumber].roomStatus == status : roomNumberMap[_roomNumber].roomStatus != status, "RSC");
        _;
    }

    // модификатор для более красивой проверки статуса сделки
    modifier dealStatusCheck(bool decision, uint256 _roomNumber, uint256 _takerNumber, uint8 status) {
        require(decision ? roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus == status : roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus != status, "DSC");
        _;
    }

    // модификатор для более красивой проверки сендера
    modifier isRoomMaker(uint256 _roomNumber, address maker) {
        require(roomNumberMap[_roomNumber].maker == maker, "RM");
        _;
    }

    //--------------------------------------------------------------------------------------------------
    // тут ивенты

    event CreateRoom(
        uint256 roomNumber,
        address maker,
        address addressOfToken,
        uint256 volume
    );

    event JoinRoom(
        uint256 roomNumber,
        uint16 takerNumber,
        address addressOfTaker,
        uint256 takerVolume
    );
    
    event TakerApprove(
        uint256 roomNumber,
        uint256 takerNumber
    );

    event MakerApprove(
        uint256 roomNumber,
        uint256 takerNumber
    );

    event TakerWithdraw(
        uint256 roomNumber,
        uint256 takerNumber,
        address addressOfToken,
        uint256 volume
    );

    event CloseRoom(
        uint256 roomNumber
    );


    //--------------------------------------------------------------------------------------------------
    // тут основная часть контракта (функции)

    // тут мы создаем в комнату в Native токенах сети
    function createRoom(
        uint256 _roomNumber, // номер комнаты
        uint32 _timeForTakerAndMaker, // время, за которое создатель комнаты должен дать аппрув того, что taker действительно перевел средства (в секундах)
        uint256 _maxLimit, // верхний лимит у исполнителя (как на бинанс лимиты выполнены)
        uint256 _lowLimit, // нижний лимит у исполнителя (как на бинанс лимиты выполнены)
        address _addressOfToken, // адресс токена, который будет использован в этой комнате
        uint256 _msgValue, // количество токенов, которые надо будет исполнить в жтой комнате
        uint32 _rate // курс, по которому будет происходить обмен токена на фиат
    ) public payable roomStatusCheck(true, _roomNumber, 0) {
        // тут мы проверяем, что все временные рамки выставленны верно (все в cекундах)
        require(_timeForTakerAndMaker <= maxTimeForTakerAndMaker &&
                _timeForTakerAndMaker >= minTimeForTakerAndMaker &&
                _timeForTakerAndMaker % multiplicityOfTime == 0,
                "Incorrect time");

        if (_addressOfToken == address(0)) {
            require(_maxLimit > _lowLimit && 
                _maxLimit <= (msg.value - (msg.value / 1000 * commissions)),
                "Incorrect limits");

            // монету у нас отправляются в очень мелких величинах (условно 1 udst записыватеся в контракте transferFrom как 1000000)
            // соответсченно подобное деление не будет приводить к неправильным вычислениям
            comissionSumEth += msg.value / 1000 * commissions;
    
            roomNumberMap[_roomNumber].timeForTakerAndMaker = _timeForTakerAndMaker;
            roomNumberMap[_roomNumber].volume = (msg.value - (msg.value / 1000 * commissions));
            roomNumberMap[_roomNumber].addressOfToken = address(0);
            roomNumberMap[_roomNumber].maxLimit = _maxLimit;
            roomNumberMap[_roomNumber].lowLimit = _lowLimit;
            roomNumberMap[_roomNumber].maker = msg.sender;
            roomNumberMap[_roomNumber].rate = _rate;
            roomNumberMap[_roomNumber].roomStatus++;
        } else {
            require(_maxLimit > _lowLimit && 
                _maxLimit <= _msgValue - (_msgValue / 1000 * commissions),
                "Incorrect limits");
        
            // блок с трансферов erc20 токенов для депозита
            require(IERC20(_addressOfToken).allowance(msg.sender, address(this)) >= _msgValue, "Incorrect allowance");
            IERC20(_addressOfToken).transferFrom(msg.sender, address(this), _msgValue);

            // монету у нас отправляются в очень мелких величинах (условно 1 udst записыватеся в контракте transferFrom как 1000000)
            // соответсченно подобное деление не будет приводить к неправильным вычислениям
            comissionSumToken[_addressOfToken] += _msgValue / 1000 * commissions;
    
            roomNumberMap[_roomNumber].timeForTakerAndMaker = _timeForTakerAndMaker;
            roomNumberMap[_roomNumber].volume = (_msgValue - (_msgValue / 1000 * commissions));
            roomNumberMap[_roomNumber].addressOfToken = _addressOfToken;
            roomNumberMap[_roomNumber].maxLimit = _maxLimit;
            roomNumberMap[_roomNumber].lowLimit = _lowLimit;
            roomNumberMap[_roomNumber].maker = msg.sender;
            roomNumberMap[_roomNumber].rate = _rate;
            roomNumberMap[_roomNumber].roomStatus++;
        }

        emit CreateRoom(
            _roomNumber,
            roomNumberMap[_roomNumber].maker,
            roomNumberMap[_roomNumber].addressOfToken,
            roomNumberMap[_roomNumber].volume);
    }

    // тут открывает сделка на исполнение конкретного обьема от комнаты
    function joinRoom (
        uint256 _roomNumber, // номер комнаты
        uint256 _txVolume // какой обьем готовы исполнить в volume (в wei)
    ) public roomStatusCheck(true, _roomNumber, 1) {
        // тут мы проверяем, что обьем сделки исполнителя находится в пределах лимитов
        require(roomNumberMap[_roomNumber].maxLimit > _txVolume && roomNumberMap[_roomNumber].lowLimit < _txVolume, "Your volume is out of limits");

        // создаем структуру чела, который готов исполнить обьем
        roomNumberMap[_roomNumber].taker[roomNumberMap[_roomNumber].counter] = Taker({
            addressOfTaker: msg.sender,
            volume: _txVolume,
            timer: block.timestamp,
            isScam: false,
            moderDecision: 0,
            dealStatus: 1
        });

        // освобождаем обьем комнаты от выполняемой транзакции, чтобы другие ее не могли выполнить
        roomNumberMap[_roomNumber].volume -= _txVolume;

        emit JoinRoom(_roomNumber, roomNumberMap[_roomNumber].counter, msg.sender, _txVolume);

        roomNumberMap[_roomNumber].counter++;

    }

    // тут исполнитель (taker) должен подтвердить свой перевод средств
    function takerApprove(uint256 _roomNumber, uint256 _takerNumber) dealStatusCheck(true, _roomNumber, _takerNumber, 1) external {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker == msg.sender, "You are not taker");
        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus++;
        roomNumberMap[_roomNumber].taker[_takerNumber].timer = block.timestamp + roomNumberMap[_roomNumber].timeForTakerAndMaker;
        emit TakerApprove(_roomNumber, _takerNumber);
    }

    // тут мы получаем подтверждение транзакции покупателя, что исполноитель (struct Taker) все выполнила правильно
    function makerApprove(uint256 _roomNumber, uint256 _takerNumber) external isRoomMaker(_roomNumber, msg.sender) dealStatusCheck(true, _roomNumber, _takerNumber, 2) {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].isScam == false, "There is a scam on this taker");

        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus++;
        emit MakerApprove(_roomNumber, _takerNumber);
    }

    // тут у нас тейкер выводит средства со сделки
    function takerWithdraw(uint256 _roomNumber, uint256 _takerNumber) public dealStatusCheck(true, _roomNumber, _takerNumber, 3) {
        withdraw(_roomNumber, _takerNumber);
        emit TakerWithdraw(_roomNumber, _takerNumber, roomNumberMap[_roomNumber].addressOfToken, roomNumberMap[_roomNumber].taker[_takerNumber].volume);
    }

    // тут у нас исполнитель может вывести деньги, если создатель комнаты дал аппрув
    function withdraw(uint256 _roomNumber, uint256 _takerNumber) internal dealStatusCheck(false, _roomNumber, _takerNumber, 4) {
        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = 4;

        if (roomNumberMap[_roomNumber].addressOfToken == address(0)) {
            payable(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker).transfer(roomNumberMap[_roomNumber].taker[_takerNumber].volume);
        } else {
            IERC20(roomNumberMap[_roomNumber].addressOfToken).transfer(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker, roomNumberMap[_roomNumber].taker[_takerNumber].volume);
        }

    }

    // тут создатель комнаты может ее закрыть, в случае если в ней не осталось исполнителей
    function closeRoom(uint256 _roomNumber) external roomStatusCheck(false, _roomNumber, 3) isRoomMaker(_roomNumber, msg.sender) {

        // тут мы проверяем, чтобы все в комнате было завершено и создатель комнаты не мог просто так взять и закрыть эту комнату
        if (roomNumberMap[_roomNumber].counter > 0) {
            for (uint256 i = 0; i < roomNumberMap[_roomNumber].counter; i++) {
                require(roomNumberMap[_roomNumber].taker[i].dealStatus == 4, "Deal is opened");
            }
        }

        // тут мы выводим остатки средст из комнаты
        if (roomNumberMap[_roomNumber].volume > 0) {
            if (roomNumberMap[_roomNumber].addressOfToken == address(0)) {
                payable(msg.sender).transfer(roomNumberMap[_roomNumber].volume);
            } else {
                IERC20(roomNumberMap[_roomNumber].addressOfToken).transfer(msg.sender, roomNumberMap[_roomNumber].volume);
            }
        }

        roomNumberMap[_roomNumber].roomStatus = 3;
        emit CloseRoom(_roomNumber);
    }

    // в этой функции мы позволяем создателю комнаты запретить создание новых сделок
    function stopRoom(uint256 _roomNumber) external isRoomMaker(_roomNumber, msg.sender) {
        roomNumberMap[_roomNumber].roomStatus = 2;
    }

    // в этой функции мы позволяем создателю комнаты возобновить создание новых сделок
    function continueRoom(uint256 _roomNumber) external isRoomMaker(_roomNumber, msg.sender) {
        roomNumberMap[_roomNumber].roomStatus = 1;
    }

    // тут у нас maker может вернуть деньги в комнату, если taker просрачивает вызов "function dealDone"
    function delayFromTaker(uint256 _roomNumber, uint256 _takerNumber) external dealStatusCheck(true, _roomNumber, _takerNumber, 1) {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].timer <= block.timestamp + roomNumberMap[_roomNumber].timeForTakerAndMaker, "Taker got some time for deal");
        
        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = 4;
        roomNumberMap[_roomNumber].volume += roomNumberMap[_roomNumber].taker[_takerNumber].volume;
    }

    // тут у нас исполнитель может вывести деньги, если создатель просрочил аппрув сделки
    function delayFromMaker(uint256 _roomNumber, uint256 _takerNumber) external dealStatusCheck(true, _roomNumber, _takerNumber, 2) {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].timer <= block.timestamp + roomNumberMap[_roomNumber].timeForTakerAndMaker, "Sender got some time for deal");

        withdraw(_roomNumber, _takerNumber);
    }

    // тут мы узнаем, скаманули ли покупателя (он соответсвенно подтверждает что это скам)
    function scamFromMaker(uint256 _roomNumber, uint256 _takerNumber) external isRoomMaker(_roomNumber, msg.sender) dealStatusCheck(true, _roomNumber, _takerNumber, 2) {
        roomNumberMap[_roomNumber].taker[_takerNumber].isScam = true;
    }

    // данная функция служит для принятия решения админом о скаме
    function moderDecision(uint256 _roomNumber, uint8 _decision, uint256 _takerNumber) external onlyModerAddr {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].isScam == true);
        roomNumberMap[_roomNumber].taker[_takerNumber].moderDecision = _decision;
    }

    // тут если у нас прожимается скам, то админ будет разрешать проблему и делать возврат средств создателю комнаты (типо исполнитель скаманулся)
    function scamReal(uint256 _roomNumber, uint256 _takerNumber) external {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].moderDecision == 1);

        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = 4;
        roomNumberMap[_roomNumber].volume += roomNumberMap[_roomNumber].taker[_takerNumber].volume;
    }

    // тут если у нас прожимается скам, то админ будет разрешать проблему и делать возврат получателю средств
    // (типо покупатель решил скамануть всех, получить товар и при этом деьги вернуть)
    function scamFake(uint256 _roomNumber, uint256 _takerNumber) external {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].moderDecision == 2);

        withdraw(_roomNumber, _takerNumber);
    }

    // в случае этого скама - половина сделки уходит тейкеру, а половина уходит мейкеру
    function scamHalf(uint256 _roomNumber, uint256 _takerNumber) external {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].moderDecision == 3);
        uint256 half = roomNumberMap[_roomNumber].taker[_takerNumber].volume/2;
        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = 4;

        roomNumberMap[_roomNumber].volume += half;

        if (roomNumberMap[_roomNumber].addressOfToken == address(0)) {
            payable(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker).transfer(half);
        } else {
            IERC20(roomNumberMap[_roomNumber].addressOfToken).transfer(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker, half);
        }
    }

    // в случае если тейкер ошибся в своей сделке и хочет из нее выйти, то у него есть время до того момента, как он не подтвердит свой перевод
    function mistakeFromTaker(uint256 _roomNumber, uint256 _takerNumber) external dealStatusCheck(true, _roomNumber, _takerNumber, 1) {
        require(roomNumberMap[_roomNumber].taker[_takerNumber].addressOfTaker == msg.sender, "You are not taker");
        roomNumberMap[_roomNumber].taker[_takerNumber].dealStatus = 4;
        roomNumberMap[_roomNumber].volume += roomNumberMap[_roomNumber].taker[_takerNumber].volume;
    }

    //-----------------------------------------------------------------------------------------------------------
    // Тут несколько вью функций

    // функция, которая возвращает нам одного из исполнителей комнаты
    function getTaker(uint256 _roomNumber, uint256 _takerNumber) public view returns(Taker memory) {
        return(roomNumberMap[_roomNumber].taker[_takerNumber]);
    }

    // функция, которая возвращает нам статические данные о комнате
    function getRoomStatic(uint256 _roomNumber) public view returns(
        address,
        uint32,
        uint256,
        uint256,
        address,
        uint32
        ) {
        return(
            roomNumberMap[_roomNumber].maker,
            roomNumberMap[_roomNumber].timeForTakerAndMaker,
            roomNumberMap[_roomNumber].maxLimit,
            roomNumberMap[_roomNumber].lowLimit,
            roomNumberMap[_roomNumber].addressOfToken,
            roomNumberMap[_roomNumber].rate
        );
    }

    // функция, которая возвращает нам динамические данные о комнате
    function getRoomDynamic(uint256 _roomNumber) public view returns(
        uint16,
        uint256,
        uint8
    ) {
        return(
            roomNumberMap[_roomNumber].counter,
            roomNumberMap[_roomNumber].volume,
            roomNumberMap[_roomNumber].roomStatus
        );
    }

    //-----------------------------------------------------------------------------------------------------------
    // админский функции для глобальных штук

    // функция вывода всех собранных комиссий в эфире
    function withdrawCommissionsEth() external onlyAdmin {
        payable(msg.sender).transfer(comissionSumEth);
        comissionSumEth = 0;
    }

    // функция вывода всех собранных комиссий в токенах
    function withdrawCommissionsToken(address token) external onlyAdmin {
        IERC20(token).transfer(msg.sender, comissionSumToken[token]);
        comissionSumToken[token] = 0;
    }

    // тут админ устанавливает комиссии (исчисление идет в десятых процента, то есть "5" будет соответсвеовать 0,5%)
    function setCommissions(uint8 _commissions) external onlyAdmin {
        commissions = _commissions;
    }

    // устанавливает время в секундах, для лимитов сендера
    function setMaxTimeForTakerAndMaker(uint256 _maxTimeForTakerAndMaker) external onlyAdmin {
        maxTimeForTakerAndMaker = _maxTimeForTakerAndMaker;
    }

    // устанавливает время в секундах, для лимитов сендера
    function setMinTimeForTakerAndMaker(uint256 _minTimeForTakerAndMaker) external onlyAdmin {
        minTimeForTakerAndMaker = _minTimeForTakerAndMaker;
    }

    // устанавливает кратность тайм лимитов
    function setMultiplicityOfTime(uint256 _multiplicityOfTime) external onlyAdmin {
        multiplicityOfTime = _multiplicityOfTime;
    }

    // тут мы можем переназначить главного админа контракта
    function changeAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    // тут мы меняем адрес мультисига
    function setTCMultisig(address _TCMultisig) external onlyAdmin {
        TCMultisig = _TCMultisig;
    }


    //-----------------------------------------------------------------------------------------------------------
    // конструктор

    constructor() {
        admin = msg.sender;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}