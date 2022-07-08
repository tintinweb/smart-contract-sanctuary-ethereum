/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

// @dev здесь надо описать интерфейс необходимых функций токена ERC20
interface IERC20 {
    function transfer(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function totalSupply() external view returns(uint256);
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
        uint256 unblock_time;
        uint256 value;
        uint256 block_value;
    }

    /// @title Структура голосования
    ///
    /// @dev продумай её сам/сама
    ///
    struct Proposal{
        address contact;
        bytes DATA;
        uint256 agree;
        uint256 disagree;
        uint256 start_time;
        uint256 finish_time;
        bool is_finished;
    }

    /// @dev массив структур Proposal - каждый элемент этого массива - отдельное голосование
    Proposal[] allProposals;

    /// @dev Здесь понадобятся ещё переменные/словари/массивы - придётся самому/самой придумать какие
    mapping(address => mapping(uint256 => bool)) can_you_voite;
    mapping(address => deposit) deposits;

    /// @notice событие испускаемое при создании новго голосования
    event AddProposal(uint256 pId, bytes pCallData, address pCallAddres);
    /// @notice событие испускаемое при завершению голосования
    event FinishProposal(bool quorum, bool result, bool success);

    /// @notice конструктор
    ///
    constructor(uint256 _time, address _TOD){
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
        TOD.transferFrom(msg.sender,address(this), _amount);
        deposits[msg.sender].value += _amount;
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
        require(deposits[msg.sender].value > _amount, "DAO: Not enough coins");
        if (block.timestamp > deposits[msg.sender].unblock_time && deposits[msg.sender].block_value != 0){
            deposits[msg.sender].block_value = 0;
        }
        require(deposits[msg.sender].value - deposits[msg.sender].block_value >= _amount, "DAO: You do not have enough unblocked coins");
        TOD.transfer(msg.sender, _amount);
        deposits[msg.sender].value -= _amount;
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
        require(msg.sender == owner, "DAO: You are not able to do this!");
        Proposal memory proposal;
        proposal.agree = 0;
        proposal.disagree = 0;
        proposal.start_time = block.timestamp;
        proposal.finish_time = block.timestamp + time;
        proposal.is_finished = false;
        proposal.contact = _pCallAddres;
        proposal.DATA = _pCallData;
        allProposals.push(proposal);
        emit AddProposal(allProposals.length, _pCallData, _pCallAddres);
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
        require(block.timestamp < allProposals[_pId-1].finish_time, 
        "DAO: Proposal has been finished");
        require(can_you_voite[msg.sender][_pId - 1] == false, 
        "DAO: You have already voted");
        require(deposits[msg.sender].value > 0, 
        "DAO: Not enough coins to vote");
        if (_choice){
            allProposals[_pId-1].agree += deposits[msg.sender].value;
        } else{
            allProposals[_pId-1].disagree += deposits[msg.sender].value;
        }
        deposits[msg.sender].block_value = deposits[msg.sender].value;
        can_you_voite[msg.sender][_pId - 1] = true;
        if (deposits[msg.sender].unblock_time < allProposals[_pId-1].finish_time){
            deposits[msg.sender].unblock_time = allProposals[_pId-1].finish_time;
        }
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
        require(block.timestamp >= allProposals[_pId-1].finish_time, 
        "DAO: Finish is not available now");
        require(allProposals[_pId-1].is_finished == false, 
        "You can not do it twice");
        allProposals[_pId-1].is_finished = true;
        bool quorum_ = (allProposals[_pId-1].agree + allProposals[_pId-1].disagree) > TOD.totalSupply() / 2;
        bool result_ = false;
        if (quorum_ && allProposals[_pId-1].agree > allProposals[_pId-1].disagree){
            result_ = true;
        }
        bool success_ = false;
        if (quorum_ && allProposals[_pId-1].agree > allProposals[_pId-1].disagree){
            (success_, ) = allProposals[_pId-1].contact.call(allProposals[_pId-1].DATA);
        }
        emit FinishProposal(quorum_, result_, success_);
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
        return allProposals[_pId-1];
    }
}