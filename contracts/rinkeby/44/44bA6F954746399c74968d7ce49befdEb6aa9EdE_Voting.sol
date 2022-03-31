/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

contract Voting{

    // Адрес хозяина контракта
    address owner;
    // Комиссия, доступная для вывода
    // комиссия с каждого голосования становится доступна для вывода
    // только после окончания голосования
    uint fee;

    // Структура кандидата
    struct Candidate {
        // id кандидата
        uint cId;
        // количество голосов за кандидата
        uint cVotes;
        // имя кандидата
        string cName;
        // адрес кандидата
        address cAddress;
    } 

    // Структура голосования
    struct Vote{
        // id голосования
        uint vId;
        // время начала голосования
        uint vStartTime;
        // общее количество проголосовавших
        uint vTotal;
        // сумма выигрыша
        uint vWinningAmount;
        // название голосования
        string vName;
        // статус голосования - началось/не началось
        bool vStatusStart;
        // статус голосования - закончилось/не закончилось
        bool vStatusEnd;
        // кандидаты
        Candidate[] vCandidates;
        // id победивших кандидатов 
        uint[] vIdWinners;
        // проголосовавшие
        mapping(address => bool) vVoters;
    }

    // Со структурой Vote удобно работать, но её невозможно вернуть из функции,
    // так как в ней лежит словарь
    // Структура VoteInfo используется для вывода информации о выборах
    // в ней нету словаря, но есть некоторая дополнительная информация
    struct VoteInfo{
        // id голосования
        uint vId;
        // время начала голосования
        uint vStartTime;
        // общее количество проголосовавших
        uint vTotal;
        // количество кандидатов
        uint vCandidateCount;
        // количество выигравших кандидатов
        uint vWinnersCount;
        // выигрыш победившего кандидата/кандидатов
        uint vWinningAmount;
        // название голосования
        string vName;
        // статус голосования - началось/не началось
        bool vStatusStart;
        // статус голосования - закончилось/не закончилось
        bool vStatusEnd;
        // кандидаты
        Candidate[] vCandidates;
        // id победивших кондидатов 
        uint[] vIdWinners;
    }

    // Массив структур Vote - каждый элемент этого массива - отдельное голосование
    Vote[] allVotes;

    modifier onlyOwner(){
        require(msg.sender == owner,
        "Only the host can add, change, delete votes and candidates");
        _;
    }

    // проверка, что голосование не началось
    // нужно для редактирования голосований и списков кандидатов
    // не честно изменять голосование, добавлять/редактировать/убирать
    // кандидатов во время голосования
    modifier voteDontStart(uint _vId){
        require(allVotes[_vId].vStatusStart == false,
        "Voting has begun. You cannot change or delete it");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

// *** ФУНКЦИИ ДОБАВЛЕНИЯ ГОЛОСОВАНИЯ И КАНДИДАДТОВ ***

    // Функция добавления нового голосования
    function addVote(
        string calldata _vName
    )
        external
        onlyOwner
    {
        // добавляем голосование
        allVotes.push();
        // сохраняем индекс для удобства
        uint vIndex = allVotes.length - 1;
        // сохраняем в голосовании его название
        allVotes[vIndex].vName = _vName;
        // сохраняем id голосования
        allVotes[vIndex].vId = vIndex + 1;
    }

    // Функция добавления одного нового кандидата в голосование
    function addCandidateToVote(
        uint _vId,
        string calldata _cName,
        address _cAddress
    )
        external
        onlyOwner
        voteDontStart(--_vId)
    {
        // получаем id кандидата
        uint cId = allVotes[_vId].vCandidates.length + 1;
        // добавляем нового кандидата в список
        allVotes[_vId].vCandidates.push(Candidate(cId, 0, _cName, _cAddress));
    }

    // Функция добавления кандидатов в голосование списком
    function addListCandidatesToVote(
        uint _vId,
        string[] calldata _cNames,
        address[] calldata _cAddresses
    )
        external
        onlyOwner
        voteDontStart(--_vId)
    {
        // получаем id кандидата
        uint cId = allVotes[_vId].vCandidates.length;

        for(uint i = 0; i < _cNames.length; i++){
            // добавляем нового кандидата в список
            allVotes[_vId].vCandidates.push(Candidate(++cId, 0, _cNames[i], _cAddresses[i]));
        }
    }

    // Ультра-функция добавления нового голосования сразу со списком кандидатов
    function addVoteAndListCandidates(
        string calldata _vName, 
        string[] calldata _cNames,
        address[] calldata _cAddresses
    )
        external
        onlyOwner
    {
        // добавляем голосование
        allVotes.push();
        // сохраняем индекс для удобства
        uint vIndex = allVotes.length - 1;
        // сохраняем в голосовании его название
        allVotes[vIndex].vName = _vName;
        // сохраняем id голосования
        allVotes[vIndex].vId = vIndex + 1;
        // id кандидата
        uint cId = 1;
        // добавляем кандидатов
        for(uint i = 0; i < _cNames.length; i++){
            // добавляем нового кандидата в список
            allVotes[vIndex].vCandidates.push(Candidate(cId++, 0, _cNames[i], _cAddresses[i]));
        }
    }

// *** ФУНКЦИИ ДОБАВЛЕНИЯ ГОЛОСОВАНИЯ И КАНДИДАДТОВ ***


// *** ФУНКЦИИ ИЗМЕНЕНИЯ ГОЛОСОВАНИЯ И КАНДИДАДТОВ ***

    // Функция изменения голосования - можно поменять имя
    function changeVote(
        uint _vId,
        string calldata _vName
    )
        external
        onlyOwner
        voteDontStart(--_vId)
    {
        allVotes[_vId].vName = _vName;
    }

    // Функция изменения кандидата - можно поменять имя и/или адрес
    // если меняете что-то одно, то всё равно надо передать два аргумента,
    // но для экономии газа будут перезаписаны только обновляемые значения
    function changeCandidate(
        uint _vId,
        uint _cId,
        string memory _cName,
        address _cAddress
    )
        external
        onlyOwner
        voteDontStart(--_vId)
    { 
        if(keccak256(bytes(allVotes[_vId].vCandidates[--_cId].cName)) != keccak256(bytes(_cName))){
            allVotes[_vId].vCandidates[_cId].cName = _cName;
        }
        if(allVotes[_vId].vCandidates[_cId].cAddress != _cAddress){
            allVotes[_vId].vCandidates[_cId].cAddress = _cAddress;
        }
    }

// *** ФУНКЦИИ ИМЕНЕНИЯ ГОЛОСОВАНИЯ И КАНДИДАДТОВ ***


// *** ФУНКЦИИ УДАЛЕНИЯ ГОЛОСОВАНИЯ И КАНДИДАДТОВ ***

    // Функция удаления голосования
    // исходим из идеи, что индекс и id начавшегося голосования изменятся не должны
    // поэтому голосование можно удлаить при соблюдении двух условий:
    // 1. оно ещё не началось
    // 2. оно является последним в списке или последнее голосование в списке не началось
    function delVote(
        uint _vId
    )
        external
        onlyOwner
        voteDontStart(--_vId)
    {
        require(allVotes[allVotes.length - 1].vStatusStart == false,
        "It is impossible to delete a vote if the last voting in the list has already started");
        // если это последнее голосование в списке - просто удаляем его
        if(_vId == allVotes.length - 1){
            allVotes.pop();
        } else {
            // если не последнее, то перезаписываем в него имя
            allVotes[_vId].vName = allVotes[allVotes.length - 1].vName;
            // и список кандидатов из последнего голосования
            allVotes[_vId].vCandidates = allVotes[allVotes.length - 1].vCandidates;
            // id даже и изменять не надо
            // последнее голосование из списка просто удаляем
            allVotes.pop();
        }
    }

    // Функция удаления одного кандидата из списка
    function delCandidateFromVote(
        uint _vId,
        uint _cId
    )
        external
        onlyOwner
        voteDontStart(--_vId)
    {
        uint lastIndex = allVotes[_vId].vCandidates.length - 1;
        // на позицию удаляемого кандидата записываем данные кандидата из конца списка
        allVotes[_vId].vCandidates[_cId - 1].cName = allVotes[_vId].vCandidates[lastIndex].cName;
        allVotes[_vId].vCandidates[_cId - 1].cAddress = allVotes[_vId].vCandidates[lastIndex].cAddress;
        // удаляем последнего кандидата из списка
        allVotes[_vId].vCandidates.pop();
    }

// *** ФУНКЦИИ УДАЛЕНИЯ ГОЛОСОВАНИЯ И КАНДИДАДТОВ ***


// *** ФУНКЦИИ СТАРТА, ГОЛОСОВАНИЯ И ОКОНЧАНИЯ ***

    // Функция для старта голосования
    function startVote(
        uint _vId
    )
        external
        onlyOwner
        voteDontStart(--_vId)
    {
        // начинаем голосование
        allVotes[_vId].vStatusStart = true;
        // сохраняем время начала голосования
        allVotes[_vId].vStartTime = block.timestamp;
    }

    // Функция голосования
    function vote(
        uint _vId,
        uint _cId
    )
        external
        payable
    {
        // проверки
        // что голосование началось
        require(allVotes[--_vId].vStatusStart == true,
        "Voting has not yet started");
        // что голосование ещё не закончилось - не прошло 3 дня с его старта
        require(block.timestamp < allVotes[_vId].vStartTime + 3 days,
        "Voting time is over");
        // что с этого адреса ещё не голосовали
        require(allVotes[_vId].vVoters[msg.sender] == false,
        "You already voted");
        // что голосующий внёс достаточно средства
        require(msg.value == 10000000000000000,
        "Send 0.01 ETH to vote");
        // увеличиваем количество голосов за конкретного кандидата
        allVotes[_vId].vCandidates[--_cId].cVotes++;
        // увеличиваем общее количество голосов в данном голосовании
        allVotes[_vId].vTotal++;
        // отмечаем адрес как проголосовавший
        allVotes[_vId].vVoters[msg.sender] = true;
    }

    // Функция окончания голосования
    function endVote(
        uint _vId
    )
        external
    {
        // проверки
        // что голосование закончилось - прошло 3 дня с его старта
        require(block.timestamp > allVotes[--_vId].vStartTime + 3 days,
        "You can't finish voting - it hasn't been three days yet");
        // что голосование не было завершено ранее
        require(allVotes[_vId].vStatusEnd == false,
        "Voting is now over");

        // выставляем статус, что голосование завершено
        allVotes[_vId].vStatusEnd = true;

        // находим:
        // максимальное количество голосов за кандидата
        uint maxVote = 0;
        // количество победителей
        uint winnersCount = 0;
        for(uint i = 0; i < allVotes[_vId].vCandidates.length; i++){
            if(allVotes[_vId].vCandidates[i].cVotes > maxVote){
                maxVote = allVotes[_vId].vCandidates[i].cVotes;
                winnersCount = 1;
            }
            else if(allVotes[_vId].vCandidates[i].cVotes == maxVote){
                winnersCount += 1;
            }
        }
        // находим какую сумму выиграл каждый победитель
        allVotes[_vId].vWinningAmount = 9000000000000000 * allVotes[_vId].vTotal / winnersCount;
        // кидаем деньги на счёт каждому победителю
        for(uint i = 0; i < allVotes[_vId].vCandidates.length; i++){
            if(allVotes[_vId].vCandidates[i].cVotes == maxVote){
                // Отправляем средства на адрес победившего кандидата
                payable(allVotes[_vId].vCandidates[i].cAddress).transfer(allVotes[_vId].vWinningAmount);
                // добавляем адрес победителя в список победителей 
                allVotes[_vId].vIdWinners.push(allVotes[_vId].vCandidates[i].cId);
                winnersCount--;
            }
            if(winnersCount == 0){
                break;
            }
        }
        // оставшуюся комиссию теперь можно вывести
        fee += 10000000000000000 * allVotes[_vId].vTotal - allVotes[_vId].vWinningAmount * allVotes[_vId].vIdWinners.length;
    }

// *** ФУНКЦИИ СТАРТА, ГОЛОСОВАНИЯ И ОКОНЧАНИЯ ***


// *** ФУНКЦИИ ПОЛУЧЕНИЯ ИНФОРМАЦИИ О ГОЛОСОВАНИЯХ И КАНДИДАТАХ ***

    // Функция для получения списка вообще всех голосований
    function getallVotes()external view returns(VoteInfo[] memory){
        return getVotes(true, false, false);
    }
    // Функция для получения списка всех идущих голосований
    function getCurrentVoites()external view returns(VoteInfo[] memory){
        return getVotes(false, true, false);
    }
    // Функция для получения списка всех законченных голосований
    function getEndVoites()external view returns(VoteInfo[] memory){
        return getVotes(false, true, true);
    }

    // Функция для получения списка голосований в зависимости от параметров
    function getVotes(
        bool _all,
        bool _start,
        bool _end
    )
        private
        view
        returns(VoteInfo[] memory)
    {
        // сначала необходимо определить сколько голосований подходят под параметры
        uint countVotes = 0;
        for (uint i = 0; i < allVotes.length; i++){
            if(_all || allVotes[i].vStatusStart == _start && allVotes[i].vStatusEnd == _end){
                countVotes++;
            }
        }
        // создаём массив с голосованиями, заполняем его необходимыми данными и возвращаем
        VoteInfo[] memory votes = new VoteInfo[](countVotes);
        uint j = 0;
        for (uint i = 0; i < allVotes.length; i++){
            if(_all || allVotes[i].vStatusStart == _start && allVotes[i].vStatusEnd == _end){
                votes[j].vId = allVotes[i].vId;
                votes[j].vStartTime = allVotes[i].vStartTime;
                votes[j].vTotal = allVotes[i].vTotal;
                votes[j].vCandidateCount = allVotes[i].vCandidates.length;
                votes[j].vWinnersCount = allVotes[i].vIdWinners.length;
                votes[j].vWinningAmount = allVotes[i].vWinningAmount;
                votes[j].vName = allVotes[i].vName;
                votes[j].vStatusStart = allVotes[i].vStatusStart;
                votes[j].vStatusEnd = allVotes[i].vStatusEnd;
                votes[j].vCandidates = allVotes[i].vCandidates;
                votes[j].vIdWinners = allVotes[i].vIdWinners;
                j++;
            }
        }
        return votes;
    }

    // Функция для получения информации об одном голосовании по его id
    function getVoteByID(
        uint _vId
    )
        external
        view
        returns(VoteInfo memory)
    {
        // проверка, что такой id существует
        require(allVotes.length > --_vId, "There is no vote with this id");
        VoteInfo  memory oneVote;
        oneVote.vId = allVotes[_vId].vId;
        oneVote.vStartTime = allVotes[_vId].vStartTime;
        oneVote.vTotal = allVotes[_vId].vTotal;
        oneVote.vCandidateCount = allVotes[_vId].vCandidates.length;
        oneVote.vWinnersCount = allVotes[_vId].vIdWinners.length;
        oneVote.vWinningAmount = allVotes[_vId].vWinningAmount;
        oneVote.vName = allVotes[_vId].vName;
        oneVote.vStatusStart = allVotes[_vId].vStatusStart;
        oneVote.vStatusEnd = allVotes[_vId].vStatusEnd;
        oneVote.vCandidates = allVotes[_vId].vCandidates;
        oneVote.vIdWinners = allVotes[_vId].vIdWinners;
        return oneVote;
    }

    // Функция для получения списка кандидатов из голосования
    function getCandidateByVote(
        uint _vId
    )
        public
        view
        returns(Candidate[] memory)
    {
        // проверка, что в голосовании есть кандидаты
        require(allVotes[--_vId].vCandidates.length > 0, "No candidates here yet");
        // возвращаем список кандидатов
        return allVotes[_vId].vCandidates;
    }

    // Функция для получения списка победителей из голосования
    function getWinnersByVote(
        uint _vId
    )
        public
        view
        returns(Candidate[] memory)
    {
        // проверяем, что голосование завершено
        require(allVotes[--_vId].vStatusEnd == true, "Voting is not over yet");
        // формируем и возвращаем список кандидатов
        Candidate[] memory winnersArray = new Candidate[](allVotes[_vId].vIdWinners.length);
        for(uint i = 0; i < winnersArray.length; i++){
            uint wIndex = allVotes[_vId].vIdWinners[i] - 1;
            winnersArray[i].cId = allVotes[_vId].vCandidates[wIndex].cId;
            winnersArray[i].cVotes = allVotes[_vId].vCandidates[wIndex].cVotes;
            winnersArray[i].cName = allVotes[_vId].vCandidates[wIndex].cName;
            winnersArray[i].cAddress = allVotes[_vId].vCandidates[wIndex].cAddress;
        }
        return winnersArray;
    }

// *** ФУНКЦИИ ПОЛУЧЕНИЯ ИНФОРМАЦИИ О ГОЛОСОВАНИЯХ И КАНДИДАТАХ ***


// *** ФУНКЦИИ ДЛЯ ВЫВОДА КОМИССИИ ***

    // посмотреть сколько средств доступно для вывода
    function getFee()
        external
        view
        onlyOwner
        returns(uint)
    {
        return fee;
    }

    // вывод средств владельцем контракта
    function withDraw()
        external
        onlyOwner
    {
        payable(owner).transfer(fee);
    }
}