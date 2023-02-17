/**
 *Submitted for verification at Etherscan.io on 2023-02-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

// @dev здесь надо описать интерфейс необходимых функций токена ERC20
interface IERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function totalSupply() external view returns (uint256);
}

contract DAO {
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
    struct Deposit {
        uint tokenAll;
        uint tokenFreeze;
        uint timeUnfreeze;
    }

    /// @title Структура голосования
    ///
    /// @dev продумай её сам/сама
    ///
    struct Proposal {
        uint id;
        uint endTime;
        uint tokenYes;
        uint tokenNo;
        bool finish;
        address callAddress;
        bytes callData;
    }

    /// @dev массив структур Proposal - каждый элемент этого массива - отдельное голосование
    Proposal[] allProposals;

    /// @dev Здесь понадобятся ещё переменные/словари/массивы - придётся самому/самой придумать какие
    mapping(address => mapping(uint => bool)) voted;
    mapping(address => Deposit) deposits;
    mapping(address => bool) coowner;

    /// @notice событие испускаемое при создании новго голосования
    event AddProposal(uint256 pId, bytes pCallData, address pCallAddres);
    /// @notice событие испускаемое при завершению голосования
    event FinishProposal(bool quorum, bool result, bool success);

    /// @notice конструктор
    ///
    constructor(uint256 _time, address _TOD) {
        owner = msg.sender;
        time = _time;
        TOD = IERC20(_TOD);
    }

    /// @notice функция добавления депозита
    ///
    /// @dev вызывается функция transferFrom() на токене TOD
    /// @dev изменяется значение депозита для пользователя, вызвавшего функцию
    ///
    function addDeposit(uint256 _amount) external {
        require(TOD.transferFrom(msg.sender, address(this), _amount));
        deposits[msg.sender].tokenAll += _amount;
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
        Deposit memory deposit = deposits[msg.sender];
        if (block.timestamp > deposit.timeUnfreeze && deposit.tokenFreeze > 0) {
            deposit.tokenFreeze = 0;
        }
        require(deposit.tokenAll - deposit.tokenFreeze > _amount);
        deposit.tokenAll -= _amount;
        deposits[msg.sender] = deposit;
        require(TOD.transfer(msg.sender, _amount));
    }

    /// @notice функция добавления нового голосования
    ///
    /// @param _pCallData - закодированные сигнатура функции и аргументы
    /// @param _pCallAddres - адрес вызываемого контракта
    ///
    /// @dev только owner может создавать новое голосование
    /// @dev добавляет новую структуру голосования Proposal в массив allProposals
    /// @dev не забудьте об ограничении по времени!
    /// @dev вызывает событие AddProposal
    ///
    function addProposal(bytes calldata _pCallData, address _pCallAddres) external {
        require(msg.sender == owner || coowner[msg.sender]);
        allProposals.push(Proposal(
            allProposals.length,
            block.timestamp,
            0, 0, false,
            _pCallAddres, _pCallData
        ));
        emit AddProposal(allProposals.length - 1, _pCallData, _pCallAddres);
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
    function vote(uint256 _pId, bool _choice) external {
        Deposit memory deposit = deposits[msg.sender];
        require(deposit.tokenAll > 0);
        require(!voted[msg.sender][_pId]);
        require(block.timestamp > allProposals[_pId].endTime);

        voted[msg.sender][_pId] = true;
        if (_choice) allProposals[_pId].tokenYes += deposit.tokenAll;
        else allProposals[_pId].tokenNo += deposit.tokenAll;
        deposits[msg.sender].tokenFreeze = deposit.tokenAll;

        if (allProposals[_pId].endTime > deposit.timeUnfreeze)
            deposits[msg.sender].timeUnfreeze = allProposals[_pId].endTime;
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
    function finishProposal(uint256 _pId) external {
        require(block.timestamp < allProposals[_pId].endTime);
        require(!allProposals[_pId].finish);

        allProposals[_pId].finish = true;

        bool quorum = (allProposals[_pId].tokenYes + allProposals[_pId].tokenNo > TOD.totalSupply() / 2);
        bool result = (allProposals[_pId].tokenYes > allProposals[_pId].tokenNo);
        bool success = false;
        if (quorum && result) {
            (success, ) = allProposals[_pId].callAddress.call(allProposals[_pId].callData);
            require(success);
        }

        emit FinishProposal(quorum, result, success);
    }

    /// @notice функция для получения информации о депозите
    ///
    /// @return возвращает структуру deposit с информацией о депозите пользователя, вызвавшего функцию
    ///
    function getDeposit() external view returns(Deposit memory) {
        return deposits[msg.sender];
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
    function getProposalByID(uint256 _pId) external view returns(Proposal memory) {
        return allProposals[_pId];
    }
}