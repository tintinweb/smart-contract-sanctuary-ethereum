/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

// @dev здесь надо описать интерфейс необходимых функций токена ERC20
interface IERC20 {
    function getSupply() external view returns(uint256);

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns(bool);
    
    function transferFrom(address, address, uint256) external returns(bool);
}

contract DAO{
    /// @dev интерфейс к токену управления право голоса
    IERC20 TOD;
    /// @dev время, отводимое для голосования
    uint256 time;
    /// @dev Адрес хозяина контракта, который может создавать голосования
    address owner;
    /// @title Структура депозита
    ///
    /// @dev продумай её сам/сама
    ///
    struct deposit{
        uint amount;
        uint time;
    }

    /// @title Структура голосования
    ///
    /// @dev продумай её сам/сама
    ///
    struct Proposal{
        bytes proposalArguments;
        address proposalContract;
        uint tokenYes;
        uint tokenNo;
        bool Finished;
        uint256 time;
    }

    /// @dev массив структур Proposal - каждый элемент этого массива - отдельное голосование
    Proposal[] allProposals;


    /// @dev Здесь понадобятся ещё переменные/словари/массивы - придётся самому/самой придумать какие
    mapping(address => deposit) deposits;
    mapping(address => mapping(uint => bool)) voters;

    /// @notice событие испускаемое при создании нового голосования
    event AddProposal(uint256 pId, bytes pCallData, address pCallAddres);
    /// @notice событие испускаемое при завершению голосования
    event FinishProposal(bool quorum, bool result, bool success);

    /// @notice конструктор
    ///
    constructor(uint _time, address _TOD){
        owner = msg.sender;
        time = _time;
        TOD = IERC20(_TOD);
    }

    /// @notice функция добавления депозита
    ///
    /// @dev вызывается функция transferFrom() на токене TOD
    /// @dev изменяется значение депозита для пользователя, вызвавшего функцию
    ///
    function addDeposit(uint _amount) external {
        TOD.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender].amount += _amount;
    }

    /// @notice функция для получения информации о депозите
    ///
    /// @return возвращает структуру deposit с информацией о депозите пользователя, вызвавшего функцию
    ///
    function getDeposit() external view returns(deposit memory){
        return deposits[msg.sender];
    }

    /// @notice функция вывода депозита
    ///
    /// @param _amount - количество токенов, выводимых из депозита
    ///
    /// @dev нельзя вывести депозит, пока не закончены все голосования, в которых он участвует
    /// @dev нельзя вывести из депозита больше токенов, чем в нём есть
    /// @dev не забудьте изменить размер депозита пользователя
    ///
    function withdrawDeposit(uint256 _amount) external {
        require(block.timestamp > deposits[msg.sender].time, "Deposits time has not yet finished");
        require(_amount <= deposits[msg.sender].amount, "Error: Sender cannot withdraw more tokens than he has");
        TOD.transfer(msg.sender, _amount);
        deposits[msg.sender].amount -= _amount;
    }

    /// @notice функция добавления нового голосования
    ///
    /// @param _pCallData - закодированные сигнатура функции и аргументы
    /// @param _pCallAddress - адрес вызываемого контракта
    ///
    /// @dev только owner может создавать новое голосование
    /// @dev добавляет новую структуру голосования Proposal в массив allProposals
    /// @dev не забудьте об ограничении по времени!
    /// @dev вызывает событие AddProposal
    ///
    function addProposal(bytes calldata _pCallData, address _pCallAddress) external {
        require(msg.sender == owner, "Error: you are not an owner");
        Proposal memory newProposal;
        newProposal.proposalArguments = _pCallData;
        newProposal.proposalContract = _pCallAddress;
        newProposal.time = block.timestamp + time;
        newProposal.Finished = false;
        allProposals.push(newProposal);
        emit AddProposal(allProposals.length, _pCallData, _pCallAddress);
    }

    /// @notice Функция голосования
    ///
    /// @param _pId - id голосования
    /// @param _choice - голос за или против
    ///
    /// @dev вызывает прерывание если голосующий не внёс депозит
    /// @dev вызывает прерывание при попытке повторного голосования с одного адреса
    /// @dev вызывает прерывание если время голосования истекло
    ///
    /// @dev увеличиваем количество токенов за выбор голосующего
    /// @dev отмечаем адрес как проголосовавший
    /// @dev обновляем количество токенов, замороженных на депозите и время заморозки
    ///
    function vote(uint _pId, bool _choice) external {
        require(deposits[msg.sender].amount != 0, "Error: This address did not make a deposit");
        require(block.timestamp < (allProposals[_pId].time), "Error: Proposals time has finished");
        require(!voters[msg.sender][_pId], "Error: This address has already voted");
        if (allProposals[_pId].time > deposits[msg.sender].time) {
            deposits[msg.sender].time = allProposals[_pId].time;
        }
        if (_choice)
            allProposals[_pId].tokenYes += deposits[msg.sender].amount;
        else
            allProposals[_pId].tokenNo += deposits[msg.sender].amount;
        voters[msg.sender][_pId] = true;
    }

    /// @notice Функция окончания голосования
    ///
    /// @param _pId - id голосования
    ///
    /// @dev вызывает прерывание если время голосования не истекло
    /// @dev вызывает прерывание если голосование уже было завершено ранее
    ///
    /// @dev выставляет статус, что голосование завершено
    /// @dev проверяет, что набрался кворум
    /// @dev если набрался кворум количество токенов ЗА больше, количество токнов ПРОТИВ, вызывается функция
    /// @dev вызывает событие FinishProposal
    ///
    function finishProposal(uint _pId) external {
        Proposal memory proposal = allProposals[_pId];
        require(block.timestamp >= (proposal.time), "Error: Proposals time has not yet finished");
        require(!proposal.Finished, "Error: Proposal is already finished");
        allProposals[_pId].Finished = true;
        bool quorum = (proposal.tokenYes + proposal.tokenNo) >= (TOD.getSupply() / 2);
        bool result = false;
        bool success = false;
        if (quorum && (proposal.tokenYes > proposal.tokenNo)){
            result = true;
            (success, ) = proposal.proposalContract.call(proposal.proposalArguments);
            require(success);
        }
        emit FinishProposal(quorum, true, success);
    }

    /// @notice Функция для получения списка всех голосований
    ///
    /// @dev возвращает массив allProposals со всеми голосованиями
    ///
    function getAllProposal() external view returns(Proposal[] memory) {
        return allProposals;
    }

    /// @notice Функция для получения информации об одном голосовании по его id
    ///
    /// @param _pId - id голосования
    ///
    /// @dev вызывает прерывание, если такого id не существует
    ///
    /// @return возвращает одно голосование - структуру Proposal
    ///
    function getProposalByID(uint _pId) external view returns(Proposal memory){
        return allProposals[_pId];
    }
}