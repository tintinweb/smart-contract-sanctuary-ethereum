//author @alexbyso SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// interface AggregatorV3Interface {

//   function decimals()
//     external
//     view
//     returns (
//       uint8
//     );

//   function description()
//     external
//     view
//     returns (
//       string memory
//     );

//   function version()
//     external
//     view
//     returns (
//       uint256
//     );

//   // getRoundData and latestRoundData should both raise "No data present"
//   // if they do not have data to report, instead of returning unset values
//   // which could be misinterpreted as actual reported values.
//   function getRoundData(
//     uint80 _roundId
//   )
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );

//   function latestRoundData()
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );

// }

contract MagnetBase{
    // AggregatorV3Interface internal priceFeed;

    struct User {
        address mainAddress; // Основной адрес
        address[2] secondAddresses; // Дополнительныe адресa
        uint8[3] levels; // Уровни в 3х программах
        uint mainReferrer; // Изначальный пригласитель
        mapping (uint8 => uint)[3] referrers; // Пригласители по уровням в трех программах
        uint[16][3] referralsCount; // Количество реферралов в трех программах на каждом уровне
        uint[16][3] reinvestsCount; // Количество реинвествов в трех программах на каждом уровне
        uint[16][3] programId; // Id в каждой программе и на каждом уровне для структурных партнерок
        mapping (uint8 => mapping(uint => ProgramFirstMatrix)) programFirstUser;
        mapping (uint8 => ProgramSecond) programSecondUser;
        mapping (uint8 => ProgramThird) programThirdUser;
        uint[3] balance;
        uint registryTime;
    }

    struct ProgramFirstMatrix {
        uint[3] users;
        uint[3] matrixNumber;
    }

    uint8 P1TreeDepth = 2;

    struct ProgramSecond {
        uint id;
        // address currentReferrer;
        uint currentReferrer;
        // address[] referrals;
        uint[] referrals;
        bool closed;
    }

    struct ProgramThird {
        uint row; //Номер ряда в тринаре
        uint8 id; //Номер в ряду (0-2)
    }

    bool internal locked; //No reentrance
    bool internal canOneButtonClaim;

    mapping (address => uint) public usersIds;
    uint lastId;

    mapping (uint => User) public users;
    uint[][16] public usersProgramSecondIds; //Массивы с адресами по уровням для программы 2 (чтобы следить за последовательностью входов)
    uint[][16][3] public usersProgramsIds; //Массивы с адресами по уровням для программ (чтобы следить за последовательностью входов)
    ProgramThirdStruct[][16] usersProgramThird; //Программа 3
   
    struct ProgramThirdStruct {
        // address[3] addresses;
        uint[3] users;
        bool closed;
    }

    uint[16] public levelsPrice; // Стоимости уровней
    uint[3] public leadersPercent; // Процент Реферрера в каждой программе

    address root; // Команда Magnet
    address owner; // Управляющий смартконтрактом

    address presentsWallet; // Адрес кошелька для розыгрышей
    address nftWallet; // Адрес кошелька или смартконтракта для NFT

    uint8 maxLevel;

    event Register(address indexed addr, uint indexed refferrer, uint indexed uid, uint block_number);

    event BuyLevelProgramFirst(uint indexed addr, uint indexed refferrer, uint indexed profiter, uint8 level, uint value, uint block_number);
    event BuyLevelProgramSecond(uint indexed addr, uint indexed refferrer, uint indexed b_refferrer, uint8 level, uint value, uint block_number);
    event BuyLevelProgramThird(uint indexed addr, uint indexed refferrer, uint row, uint8 id, uint8 level, uint value, uint block_number);

    event ReinvestProgramSecond(uint indexed addr, uint8 level, uint value, uint block_number);
    event ReinvestProgramThird(uint indexed addr, uint8 level, uint value, uint block_number);

    event Transaction(uint indexed from, uint8 indexed prgm, uint8 indexed level, uint to, uint value, uint block_number);


    constructor(address _root, address _presentsWallet) {
        // priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE);

        levelsPrice[1] = 5;
        for (uint8 i = 2; i < 16; i++) {
            levelsPrice[i] = levelsPrice[i - 1] * 2;
        }

        leadersPercent[0] = 700; // Количество процентов умноженное на 10
        leadersPercent[1] = 400; // Количество процентов умноженное на 10
        leadersPercent[2] = 100; // Количество процентов умноженное на 10

        root = _root;
        owner = msg.sender;
        presentsWallet = _presentsWallet;
        lastId++;

        maxLevel = 12;

        usersIds[root] = 1;
        users[1].mainAddress = root;

        users[1].levels[0] = 15;
        users[1].levels[1] = 15;
        users[1].levels[2] = 15;
        users[1].mainReferrer = 0;

        
        for (uint8 i = 1; i < 16; i++){
            //Программа 2
            usersProgramSecondIds[i].push(1);
            ProgramSecond memory _programSecond;
            _programSecond.closed = true;
            users[1].programSecondUser[i] = _programSecond;

            //Программа 3
            ProgramThirdStruct memory _programThirdStruct;
            _programThirdStruct.users[0] = 1;
            _programThirdStruct.users[1] = 1;
            _programThirdStruct.users[2] = 1;
            _programThirdStruct.closed = true;
            usersProgramThird[i].push(_programThirdStruct);

            ProgramThird memory _programThird;
            _programThird.id = 0;
            _programThird.row = 0;

            users[1].programThirdUser[i] = _programThird;
        }
    }

    function _send(address addr, uint256 value, uint8 prgm, uint8 level) internal NoReentrancy() {
        if(addr == address(0)) {
            payable(root).transfer(value);
            emit Transaction(usersIds[msg.sender], prgm, level, 1, value, uint40(block.timestamp));
        }else{
            payable(addr).transfer(value);
            emit Transaction(usersIds[msg.sender], prgm, level, usersIds[addr], value, uint40(block.timestamp));
        }
    }

    function _buyLevelPossibility(uint userId, uint8 prgm, uint8 levelNumber, uint value) internal view {
        require(levelNumber > 0 && levelNumber <= maxLevel, "Invalid level!");
        require(value >= getLevelPrice(levelNumber), "Insufficient funds!");
        require(users[userId].levels[prgm] >= levelNumber - 1, "Need previous level!");
    }

    function _findReferrer(uint referrer, uint8 prgm, uint8 levelNumber) internal view returns(uint){
        uint r = referrer;

        while (users[r].levels[prgm] < levelNumber) {
            r = users[r].mainReferrer;
        }

        return r;
    }

    function _leadersSplitMoney(uint8 prgm, uint referrer, uint8 levelNumber, uint256 value) internal {
        _send(users[referrer].mainAddress, (value * leadersPercent[prgm]) / 1000, prgm, levelNumber);

        uint a=referrer;
        
        for(uint8 i = 0; i<3; i++){
            a = users[a].referrers[prgm][levelNumber];
            if(users[a].mainAddress != address(0)){
                users[a].balance[prgm] += (value * 50) / 1000;
                emit Transaction(usersIds[msg.sender], prgm, levelNumber, a, (value * 50) / 1000, uint40(block.timestamp));
            }else{
                users[1].balance[prgm] += (value * 50) / 1000;
                emit Transaction(usersIds[msg.sender], prgm, levelNumber, 1, (value * 50) / 1000, uint40(block.timestamp));
            }
        }
    }

    function _structureSplitMoney(uint8 prgm, uint8 cnt, uint8 levelNumber, uint referrer, uint value) internal {
        //Выплата cnt людям по 1% зашедшим передо мной и cnt людям зашедшим после меня (структурная партнерка)
        for(uint8 i = 1; i < (cnt + 1); i++) {
            if(referrer > i){
                address _payAddress = users[usersProgramsIds[prgm][levelNumber][referrer - i]].mainAddress;
                
                if(_payAddress != address(0)){
                    users[referrer - i].balance[prgm] +=  (value * 10) / 1000;
                    emit Transaction(usersIds[msg.sender], prgm, levelNumber, referrer - i, (value * 10) / 1000, uint40(block.timestamp));
                }else{
                    users[1].balance[prgm] +=  (value * 10) / 1000;
                    emit Transaction(usersIds[msg.sender], prgm, levelNumber, 1, (value * 10) / 1000, uint40(block.timestamp));
                }
            }else{
                users[1].balance[prgm] +=  (value * 10) / 1000;
                emit Transaction(usersIds[msg.sender], prgm, levelNumber, 1, (value * 10) / 1000, uint40(block.timestamp));
            }

            if(usersProgramsIds[prgm][levelNumber].length > referrer + i){
                address _payAddressUp = users[usersProgramsIds[prgm][levelNumber][referrer + i]].mainAddress;

                if(_payAddressUp != address(0)){
                    users[referrer + i].balance[prgm] +=  (value * 10) / 1000;
                    emit Transaction(usersIds[msg.sender], prgm, levelNumber, referrer + i, (value * 10) / 1000, uint40(block.timestamp));
                }else{
                    users[1].balance[prgm] +=  (value * 10) / 1000;
                    emit Transaction(usersIds[msg.sender], prgm, levelNumber, 1, (value * 10) / 1000, uint40(block.timestamp));
                }
            }else{
                users[1].balance[prgm] +=  (value * 10) / 1000;
                emit Transaction(usersIds[msg.sender], prgm, levelNumber, 1, (value * 10) / 1000, uint40(block.timestamp));
            }
        }
    }

    //-- ВНЕШНИЕ ФУНКЦИИ --
    function getLatestPrice() private view returns (uint) {
        // (
        //     uint80 roundID, 
        //     int price,
        //     uint startedAt,
        //     uint timeStamp,
        //     uint80 answeredInRound
        // ) = priceFeed.latestRoundData();
        // return uint(price);
    }

    function getBNBCostLevel(uint usdCost) pure public returns(uint){
        // return usdCost * 1000;
        return (usdCost * 1e18) / 259;
        // return (usdCost * 1e26) / (getLatestPrice());
    }
   
    function getBallance() view external returns(uint256){
        return address(this).balance;
    }

    function getUserBalance(address addr, uint8 prgm) view external returns(uint) {
        return users[usersIds[addr]].balance[prgm];
    }

    function getUserAllBalance(address addr) view external returns(uint) {
        return users[usersIds[addr]].balance[0] + users[usersIds[addr]].balance[1] + users[usersIds[addr]].balance[2];
    }

    function getLevelPrice(uint8 levelNumber) view public returns(uint) {
        return getBNBCostLevel(levelsPrice[levelNumber]);
    }

    function getUserLevel(address addr, uint8 program) view public withProgram(program) returns(uint8){
        return users[usersIds[addr]].levels[program];
    }

    function getUserLevels(address addr) view public returns(uint8[3] memory) {
        return users[usersIds[addr]].levels;
    }

    function getUserMainReferrer(address addr) view public returns(uint) {
        return users[usersIds[addr]].mainReferrer;
    }

    function getMainReferrerAddressById(uint id) view public returns(address) {
        return users[users[id].mainReferrer].mainAddress;
    }

    function getUserProgramReferrer(address addr, uint8 program, uint8 levelNumber) view public withProgram(program) returns(uint) {
        return users[usersIds[addr]].referrers[program][levelNumber];
    }

    function getUserReferralsCount(address addr, uint8 program) view public withProgram(program) returns(uint[16] memory) {
        return users[usersIds[addr]].referralsCount[program];
    }

    function getReinvestsCount(address addr) view public returns(uint[16][3] memory) {
        return users[usersIds[addr]].reinvestsCount;
    }

    function addSecondWallet(address addr, uint8 id) external {
        require(id >= 0 && id < 2, "Invalid ID!");
        require(usersIds[msg.sender] != 0 && usersIds[addr] == 0, "Invalid address!");

        users[usersIds[msg.sender]].secondAddresses[id] = addr;
    }

    function changeMainWallet(address addr, uint8 id) external {
        require(users[usersIds[addr]].secondAddresses[id] != address(0), "Invalid address!");
        require(users[usersIds[addr]].secondAddresses[0] == msg.sender || users[usersIds[addr]].secondAddresses[1] == msg.sender, "Invalid address!");

        users[usersIds[addr]].mainAddress = users[usersIds[addr]].secondAddresses[id];
        usersIds[users[usersIds[addr]].secondAddresses[id]] = usersIds[addr];
        usersIds[addr] = 0;
    }

    function transferClaimByProgram(uint8 prgm) external payable NoReentrancy {
        require(users[usersIds[msg.sender]].balance[prgm] > 0, "Zero money!");
        if(prgm == 1){
            require(users[usersIds[msg.sender]].registryTime + 7 days < block.timestamp, "Not now!");
        }
        if(prgm == 2){
            require(users[usersIds[msg.sender]].registryTime + 14 days < block.timestamp, "Not now!");
        }

        payable(msg.sender).transfer(users[usersIds[msg.sender]].balance[prgm]);
        users[usersIds[msg.sender]].balance[prgm] = 0;
    }

    function transferClaim() external payable NoReentrancy {
        require(canOneButtonClaim, "Not now!");

        uint b = users[usersIds[msg.sender]].balance[0] + users[usersIds[msg.sender]].balance[1] + users[usersIds[msg.sender]].balance[2];
        payable(msg.sender).transfer(b);
        users[usersIds[msg.sender]].balance[0] = 0;
        users[usersIds[msg.sender]].balance[1] = 0;
        users[usersIds[msg.sender]].balance[2] = 0;

    }

    function getStructureId(uint8 prgm, uint8 levelNumber, uint uid) external view returns(uint){
        return users[uid].programId[prgm][levelNumber];
    }

    function getUserId(address addr) external view returns(uint) {
        return usersIds[addr];
    }

    //--------------------

    //-- СЛУЖЕБНЫЕ ФУНКЦИИ И МОДИФИКАТОРЫ --

    receive() external payable { }

    function transferLostMoney() external payable onlyOwner {
        require(address(this).balance > 0, 'Zero cake');

        _send(root, address(this).balance, 0, 0);
    }

    function changeTransferClaim() external onlyOwner {
        canOneButtonClaim = true;
    }

    function changeMaxLevel(uint8 _maxLevel) external payable onlyOwner {
        require(_maxLevel > maxLevel && _maxLevel < 16, 'Invalid Level!');
        maxLevel = _maxLevel;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Access denied!");
        _;
    }

    modifier NoReentrancy() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    modifier needRegistry(uint8 program) {
         require(users[usersIds[msg.sender]].levels[program] > 0, "User not registered!");
        _;
    }

    modifier needLevel(uint addr, uint8 program, uint8 levelNumber) {
         require(users[addr].levels[program] >= levelNumber, "Level not exists!");
        _;
    }

    modifier withProgram(uint8 program) {
         require(program < 3, "Invalid program!");
        _;
    }

    //--------------------
}

//author @alexbyso SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;

import "./MagnetBase.sol";
import "./MagnetProgram1.sol";
import "./MagnetProgram2.sol";
import "./MagnetProgram3.sol";

contract MagnetContract is MagnetProgram1, MagnetProgram2, MagnetProgram3{
    constructor(address _root, address _presentsWallet) MagnetBase(_root, _presentsWallet) {}

    function _register(address addr, uint referrerId, uint256 value) private {
        require(users[usersIds[addr]].levels[0] == 0 && users[usersIds[addr]].levels[1] == 0 && users[usersIds[addr]].levels[2] == 0, "User arleady register!");
        require(users[referrerId].levels[0] > 0 && users[referrerId].levels[1] > 0 && users[referrerId].levels[2] > 0, "Upline not register!");
        require(value >= getBNBCostLevel(levelsPrice[1]) * 3, "Insufficient funds!");

        lastId++;
        users[lastId].mainReferrer = referrerId;
        usersIds[addr] = lastId;

        users[lastId].registryTime = block.timestamp;

        emit Register(addr, referrerId, lastId, uint(block.number));

        _buyLevelProgramFirst(lastId, 1, value / 3);
        _buyLevelProgramSecond(lastId, 1, value / 3);
        _buyLevelProgramThird(lastId, 1, value / 3);
    }
    
    function register(uint referrerId) external payable {
        _register(msg.sender, referrerId, msg.value);
    }

    function buyProgramFirst(uint8 levelNumber) external payable needRegistry(0) {
        _buyLevelProgramFirst(usersIds[msg.sender], levelNumber, msg.value);
    }

    function buyProgramSecond(uint8 levelNumber) external payable needRegistry(1) {
        _buyLevelProgramSecond(usersIds[msg.sender], levelNumber, msg.value);
    }

    function buyProgramThird(uint8 levelNumber) external payable needRegistry(2) {
        _buyLevelProgramThird(usersIds[msg.sender], levelNumber, msg.value);
    }

    function reinvestProgramSecond(uint8 levelNumber) external payable needRegistry(1) {
        _reinvestProgramSecond(usersIds[msg.sender], levelNumber, msg.value);
    }

    function reinvestProgramThird(uint8 levelNumber) external payable needRegistry(2) {
        _reinvestProgramThird(usersIds[msg.sender], levelNumber, msg.value);
    }

    function leadersInception(address[] calldata arrAccounts) external onlyOwner {
        require(arrAccounts.length > 0, "Zero Array");

        for (uint256 i = 0; i < arrAccounts.length; i++) {
            require(arrAccounts[i] != address(0), "Zero address");
            require(users[usersIds[arrAccounts[i]]].levels[0] == 0, "Invalid user");

            lastId++;
            users[lastId].mainReferrer = 1;
            users[lastId].mainAddress = arrAccounts[i];
            usersIds[arrAccounts[i]] = lastId;

            for(uint8 j = 0; j < 3; j++){
                users[lastId].levels[j] = 15;
                for(uint8 k = 1; k < 16; k++) {
                    users[lastId].referrers[j][k] = 1;
                    users[1].referralsCount[j][k]++;
                }
            }

            //Бинар второй программы и тринар третей программы
            for(uint8 k = 1; k < 16; k++) {
                _setLevelsProgramSecond(lastId, 1, k);
                _setLevelProgramThird(lastId, k);
            }            
        }
    }
}

//author @alexbyso SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;

import "./MagnetBase.sol";

abstract contract MagnetProgram1 is MagnetBase{
    function _buyLevelProgramFirst(uint userId, uint8 levelNumber, uint value) internal {
        _buyLevelPossibility(userId, 0, levelNumber, value);
        require(users[userId].levels[0] < levelNumber, "Level exists!");
        
        users[userId].levels[0]++;

        uint upline = _findReferrer(users[userId].mainReferrer, 0, levelNumber);

        uint profiter = _findProgramFirstProfiter(upline, userId, levelNumber, 0, false); //Профитер - тот у кого не закрыта матрица или команда Магнет
        users[userId].referrers[0][levelNumber] = upline;

        usersProgramsIds[0][levelNumber].push(userId);
        users[userId].programId[0][levelNumber] = usersProgramsIds[0][levelNumber].length;

        emit BuyLevelProgramFirst(userId, upline, profiter, levelNumber, value, uint40(block.timestamp));

        _programFirstSplitMoney(profiter, levelNumber, value);
    }

    function _addToMatrixProgramFirst(uint uid, uint referral, uint8 levelNumber, uint refMatrix) private {
        uint matrixNumber = users[uid].referralsCount[0][levelNumber] / 3;
        uint8 numberCol = uint8(users[uid].referralsCount[0][levelNumber] % 3);

        //Запись матрицы реферреру
        users[uid].programFirstUser[levelNumber][matrixNumber].users[numberCol] = referral;
        users[uid].programFirstUser[levelNumber][matrixNumber].matrixNumber[numberCol] = refMatrix;
    }

    function _findProgramFirstProfiter(uint uid, uint referral, uint8 levelNumber, uint refMatrixNumber, bool addReinvest) private returns(uint) {
        _addToMatrixProgramFirst(uid, referral, levelNumber, refMatrixNumber);
        users[uid].referralsCount[0][levelNumber]++;
        
        //Если сюда попали путем реинвеста - добавляем +1 к реинвестам (т.к. в этой программе считаем реинвесты под нами, свои просто считаются из количества реферралов)
        if(addReinvest) users[uid].reinvestsCount[0][levelNumber]++;

        if(users[uid].referralsCount[0][levelNumber] % 3 == 0 && users[uid].mainReferrer != 0) {
            uint matrixNumber = users[uid].referralsCount[0][levelNumber] / 3;
            return _findProgramFirstProfiter(users[uid].mainReferrer, uid, levelNumber, matrixNumber, true);
        }else{
            return uid;
        }
    }

    function _programFirstSplitMoney(uint referrer, uint8 levelNumber, uint256 value) private {
        _send(root, (value * 200) / 1000, 0, levelNumber); // 20% - на команду Magnet

        uint256 v = value - (value * 200) / 1000; // Вычитаем отправленную сумму на команду
        _leadersSplitMoney(0, referrer, levelNumber, v); // 85% из оставшихся отправляем лидерский бонус и поколения команд
        _structureSplitMoney(0, 5, levelNumber, referrer, v); // 10% - структурная партнерка

        _send(presentsWallet, (v * 50) / 1000, 0, levelNumber); // 5% Отправить на призовой фонд деньги
    }

    function getUserP1MatrixCount(uint uid, uint8 levelNumber) external view returns (uint){
        return (users[uid].referralsCount[0][levelNumber] / 3) + 1;
    }

    function _getP1Matrix(uint uid, uint8 levelNumber, uint matrixId) public view returns (ProgramFirstMatrix memory) {
        return users[uid].programFirstUser[levelNumber][matrixId];
    }

    function _getP1Structure(ProgramFirstMatrix[] memory matrixes, uint8 levelNumber, uint8 d) private view returns (ProgramFirstMatrix[] memory){
        uint countOut = 0;
        for(uint i = d; i <= P1TreeDepth; i++) {
            countOut += 3 ** i;
        }

        ProgramFirstMatrix[] memory outMatrixes = new ProgramFirstMatrix[](countOut);
        ProgramFirstMatrix[] memory newMatrixes = new ProgramFirstMatrix[](matrixes.length * 3);

        //Цикл по всем переданным (адрес и ссылка на матрицу)
        for(uint i = 0; i < matrixes.length; i++) {
            outMatrixes[i] = matrixes[i];
            //Цикл по адресам тринара
            for(uint8 j = 0; j < 3; j++){
                newMatrixes[i*3 + j] = _getP1Matrix(matrixes[i].users[j], levelNumber, matrixes[i].matrixNumber[j]);
                if(d + 1 >= P1TreeDepth) {
                    outMatrixes[matrixes.length + i*3 + j] = newMatrixes[i*3 + j];
                }
            }
        }

        if(d + 1 < P1TreeDepth) {
            ProgramFirstMatrix[] memory innerMatrixes = _getP1Structure(newMatrixes, levelNumber, d + 1);
            for(uint i = 0; i < innerMatrixes.length; i++) {
                outMatrixes[i + matrixes.length] = innerMatrixes[i];
            }
        }

        return outMatrixes;
    }

    function _getAddressesFromMatrixes(ProgramFirstMatrix[] memory matrixes) private pure returns (uint[] memory) {
        uint[] memory out = new uint[](matrixes.length * 3);

        for(uint i = 0; i < matrixes.length; i++) {
            for(uint j = 0; j < 3; j++) {
                out[i*3 + j] = matrixes[i].users[j];
            }
        }

        return out;
    }

    function _checkAddressInStructure(uint uid, uint mainAddress, uint8 levelNumber) private view returns (bool) {
        if(users[uid].referrers[0][levelNumber] == mainAddress) return true;
        if(users[uid].referrers[0][levelNumber] == 0) return false;
        return _checkAddressInStructure(users[uid].referrers[0][levelNumber], mainAddress, levelNumber);
    }

    function getP1Structure(uint uid, uint8 levelNumber, uint matrix) external view returns (uint[] memory){
        require(usersIds[msg.sender] == uid || msg.sender == owner || _checkAddressInStructure(uid, usersIds[msg.sender], levelNumber), 'Not your structure!');
        ProgramFirstMatrix[] memory tree = new ProgramFirstMatrix[](1);
        tree[0] = _getP1Matrix(uid, levelNumber, matrix);

        ProgramFirstMatrix[] memory outMatrix = _getP1Structure(tree, levelNumber, 0);
        uint[] memory out = _getAddressesFromMatrixes(outMatrix);

        return out;
    }
}

//author @alexbyso SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;

import "./MagnetBase.sol";

abstract contract MagnetProgram2 is MagnetBase{

    function _setLevelsProgramSecond(uint addr, uint referrer, uint8 levelNumber) internal {
        uint[] memory _binarPopentialReferrers = new uint[](1);
        _binarPopentialReferrers[0] = referrer;
        
        uint binarReferrer = _findNewProgramSecondReferrer(_binarPopentialReferrers, levelNumber);

        // users[addr].programSecondUser[levelNumber].id = usersProgramSecondIds[levelNumber].length; //ID в программе 2
        // usersProgramSecondIds[levelNumber].push(addr);

        usersProgramsIds[1][levelNumber].push(addr);
        users[addr].programId[1][levelNumber] = usersProgramsIds[1][levelNumber].length;

        users[addr].programSecondUser[levelNumber].currentReferrer = binarReferrer;
        users[binarReferrer].programSecondUser[levelNumber].referrals.push(addr);
    }

    function _buyLevelProgramSecond(uint addr, uint8 levelNumber, uint value) internal {
        _buyLevelPossibility(addr, 1, levelNumber, value);
        require(users[addr].levels[1] < levelNumber, "Level exists!");
        
        uint referrer = _findReferrer(users[addr].mainReferrer, 1, levelNumber);
        
        users[addr].referrers[1][levelNumber] = referrer;
        users[referrer].referralsCount[1][levelNumber]++;
        
        _setLevelsProgramSecond(addr, referrer, levelNumber);
        users[addr].levels[1]++;

        emit BuyLevelProgramSecond(addr, referrer, users[addr].programSecondUser[levelNumber].currentReferrer, levelNumber, value, uint40(block.timestamp));
        _programSecondSplitMoney(addr, referrer, levelNumber, value);
    }

    function _findNewProgramSecondReferrer (uint[] memory _binarReferrers, uint8 levelNumber) view internal returns(uint){
        uint findedReferrer;
        uint newBinarSublineLength = 0;

        for (uint i = 0; i < _binarReferrers.length || findedReferrer != 0; i++){
            if(!_existsBinarPlace(_binarReferrers[i], levelNumber)){
                newBinarSublineLength += users[_binarReferrers[i]].programSecondUser[levelNumber].referrals.length;
           }else{
               findedReferrer = _binarReferrers[i];
               break;
           }
        }

        if(findedReferrer == 0){
            uint[] memory _newBinarSubLine = new uint[](newBinarSublineLength);
            uint j = 0;
            
            for (uint i = 0; i < _binarReferrers.length || findedReferrer != 0; i++){
                uint bLength = users[_binarReferrers[i]].programSecondUser[levelNumber].referrals.length;
                for (uint a = 0; a < bLength; a++){
                    _newBinarSubLine[j] = users[_binarReferrers[i]].programSecondUser[levelNumber].referrals[a];
                    j++;
                }
            }
            
            findedReferrer = _findNewProgramSecondReferrer(_newBinarSubLine, levelNumber);
        }
        
        return findedReferrer;
    }

    function _existsBinarPlace (uint addr, uint8 levelNumber) view internal returns(bool) {
        return _getBinarRefferralsCount(addr,levelNumber) < 2 ? true : false;
    }

    function _getBinarRefferralsCount (uint addr, uint8 levelNumber) view internal returns(uint256) {
        return users[addr].programSecondUser[levelNumber].referrals.length;
    }

    function _programSecondSplitMoney(uint addr, uint referrer, uint8 levelNumber, uint256 value) internal {
        _send(root, (value * 200) / 1000, 1, levelNumber); // 20% - на команду Magnet

        uint256 v = value - (value * 200) / 1000; // Вычитаем отправленную сумму на команду
        _leadersSplitMoney(1, referrer, levelNumber, v); // 55% из оставшихся отправляем лидерский бонус и поколения команд

        _send(presentsWallet, (v * 50) / 1000, 1, levelNumber); // 5% Отправить на призовой фонд деньги
        
        // 30% рефферальная программа
        uint a=addr;
        for(uint8 i = 0; i<10; i++){
            a = users[a].programSecondUser[levelNumber].currentReferrer;
            if(a != 0){
                users[a].balance[1] += (v * 30) / 1000;
                emit Transaction(usersIds[msg.sender], 1, levelNumber, a, (v * 30) / 1000, uint40(block.timestamp));
            }else{
                users[1].balance[1] +=  (v * 30) / 1000;
                emit Transaction(usersIds[msg.sender], 1, levelNumber, 1, (v * 30) / 1000, uint40(block.timestamp));
            }
        }

         _structureSplitMoney(1, 5, levelNumber, referrer, v); // 10% - структурная партнерка
    }

    function _reinvestProgramSecond(uint addr, uint8 levelNumber, uint value) internal needLevel(addr, 1, levelNumber){
        _buyLevelPossibility(addr, 1, levelNumber, value);        
        _programSecondSplitMoney(addr, users[addr].referrers[1][levelNumber], levelNumber, value);
        users[addr].reinvestsCount[1][levelNumber]++;
        emit ReinvestProgramSecond(addr, levelNumber, value, uint40(block.timestamp));
    }

    //==================================================

    function getUserProgramSecondUser(uint addr, uint8 levelNumber) view public returns(ProgramSecond memory) {
        return users[addr].programSecondUser[levelNumber];
    }

    function getUserProgramSecondId(uint addr, uint8 levelNumber) view public returns(uint) {
        return users[addr].programSecondUser[levelNumber].id;
    }

    function getPSBinarReferrer(uint addr, uint8 levelNumber) view public returns(uint) {
        return users[addr].programSecondUser[levelNumber].currentReferrer;
    }
    
}

//author @alexbyso SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 < 0.9.0;

import "./MagnetBase.sol";

abstract contract MagnetProgram3 is MagnetBase{
    function _setLevelProgramThird(uint addr, uint8 levelNumber) internal {
        //Проверяем закрыт ли ряд тринара
        uint row = usersProgramThird[levelNumber].length - 1;
        if(!usersProgramThird[levelNumber][row].closed){
            if(usersProgramThird[levelNumber][row].users[1] == 0){
                usersProgramThird[levelNumber][row].users[1] = addr;
                users[addr].programThirdUser[levelNumber].id = 1;
            }else{
                usersProgramThird[levelNumber][row].users[2] = addr;
                users[addr].programThirdUser[levelNumber].id = 2;
                usersProgramThird[levelNumber][row].closed = true;
            }
        }else{
            row++;
            ProgramThirdStruct memory newRow;
            newRow.users[0] = addr;
            usersProgramThird[levelNumber].push(newRow);

            users[addr].programThirdUser[levelNumber].id = 0;
        }

        users[addr].programThirdUser[levelNumber].row = row;

        usersProgramsIds[2][levelNumber].push(addr);
        users[addr].programId[2][levelNumber] = usersProgramsIds[2][levelNumber].length;
    }

    function _buyLevelProgramThird(uint addr, uint8 levelNumber, uint value) internal {
        _buyLevelPossibility(addr, 2, levelNumber, value);
        require(users[addr].levels[2] < levelNumber, "Level exists!");
        
        uint referrer = _findReferrer(users[addr].mainReferrer, 2, levelNumber);
        
        users[addr].referrers[2][levelNumber] = referrer;
        users[addr].levels[2]++;
        users[referrer].referralsCount[2][levelNumber]++;
        
        _setLevelProgramThird(addr, levelNumber);

        ProgramThird memory p = users[addr].programThirdUser[levelNumber];

        emit BuyLevelProgramThird(addr, referrer, p.row, p.id, levelNumber, value, uint40(block.timestamp));
        _programThirdSplitMoney(referrer, levelNumber, value, p.row);
    }

    function _programThirdSplitMoney(uint referrer, uint8 levelNumber, uint256 value, uint row) internal {
        _send(root, (value * 200) / 1000, 2, levelNumber); // 20% - на команду Magnet

        uint256 v = value - (value * 200) / 1000; // Вычитаем отправленную сумму на команду
        _leadersSplitMoney(2, referrer, levelNumber, v); // 25% из оставшихся отправляем лидерский бонус и поколения команд

        _send(presentsWallet, (v * 50) / 1000, 2, levelNumber); // 5% Отправить на призовой фонд деньги

        _splitRowsUp(row, levelNumber, v, 10); // 30% Выплата по реферральной программе (посылаем цифру - как 100% для удобства подсчета)

        _structureSplitMoney(2, 20, levelNumber, referrer, v); // 10% - структурная партнерка
    }

    function _splitRowsUp(uint row, uint8 levelNumber, uint256 value, uint8 iterations) internal {
        uint r = row;

        for(uint8 i = 0; i < iterations; i++){
            if(r != 0){
                r--;
                for(uint8 j = 0; j < 3; j++){
                    // _send(usersProgramThird[levelNumber][r].addresses[j], (value * 10) / 1000, 2, levelNumber);
                    if(usersProgramThird[levelNumber][r].users[j] != 0){
                        users[usersProgramThird[levelNumber][r].users[j]].balance[2] += (value * 10) / 1000;
                        emit Transaction(usersIds[msg.sender], 2, levelNumber, usersProgramThird[levelNumber][r].users[j], (value * 10) / 1000, uint40(block.timestamp));
                    }else{
                        users[1].balance[2] +=  (value * 10) / 1000;
                        emit Transaction(usersIds[msg.sender], 2, levelNumber, 1, (value * 10) / 1000, uint40(block.timestamp));
                    }
                }
            }else{
                for(uint8 j = 0; j < 3; j++){
                    // _send(root, (value * 10) / 1000, 2, levelNumber);
                    users[1].balance[2] +=  (value * 10) / 1000;
                    emit Transaction(usersIds[msg.sender], 2, levelNumber, 1, (value * 10) / 1000, uint40(block.timestamp));
                }
            }
        }
    }

    function _reinvestProgramThird(uint addr, uint8 levelNumber, uint value) internal needLevel(addr, 2, levelNumber){
        _buyLevelPossibility(addr, 2, levelNumber, value);        
        _programThirdSplitMoney(users[addr].referrers[2][levelNumber], levelNumber, value, users[addr].programThirdUser[levelNumber].row);
        users[addr].reinvestsCount[2][levelNumber]++;
        emit ReinvestProgramThird(addr, levelNumber, value, uint40(block.timestamp));
    }
}