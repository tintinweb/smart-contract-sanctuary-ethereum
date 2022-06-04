// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "./IMyERC20.sol";
import "./Istaking.sol";

contract DAO{

    /// @dev интерфейс к токену дающему право голоса
    IMyERC20 TOK;
    /// @dev интерфейс к стейку, дающему право голоса
    Istaking staking;
    /// @dev время, которое будет отводится для голосования
    uint256 time;
    /// @dev Адрес хозяина контракта, который может создавать голосования
    address chairman;


    /// @title Структура депозита
    ///
    /// @dev allTokens - количество токенов, внесённых на депозит
    /// @dev frozenToken - замороженные токены, то есть те, которые участвуют в голосовании
    /// @dev unFrozentime - время, когда токены будут разморожены
    ///
    struct deposit{
        uint256 frozenToken;
        uint256 unFrozentime;
    }

    /// @title Структура голосования
    ///
    /// @dev pId - id голосования
    /// @dev pEndTime - время окончания голосования
    /// @dev pTokenYes - количество токенов, котороыми проголосовали За
    /// @dev pTokenNo - количество токенов, котороыми проголосовали Против
    /// @dev pDescription - описание голосования
    /// @dev pAbiArguments - аби и аргументы вызываемой функции - любой может получить их проверить, что валидность pCalldata
    /// @dev pCallData - закодированные сигнатура функции и аргументы
    /// @dev pCallAddres - адрес вызываемого контракта
    /// @dev pStatusEnd - статус голосования - закончилось/не закончилось
    ///
    struct Proposal{
        uint256 pId;
        uint256 pEndTime;
        uint256 pTokenYes;
        uint256 pTokenNo;
        string pDescription;
        string pAbiArguments;
        bytes pCallData;
        address pCallAddres;
        bool pStatusEnd;
    }

    /// @dev массив структур Proposal - каждый элемент этого массива - отдельное голосование
    Proposal[] allProposals;

    /// @dev Словарь с избирателями
    /// @dev (id голосования => (адрес избирателя => проголосовал или нет))
    mapping(uint => mapping(address => bool)) voters;

    /// @dev внесённые депозиты избирателей
    mapping(address => deposit) deposits;

    /// @notice событие испускающееся при объявлении новго голосования
    event AddProposal(uint256 pId, string _pDescription, string _pAbiArguments, bytes _pCallData, address _pCallAddres);
    /// @notice событие испускающееся при завершению голосования
    event FinishProposal(string description, bool quorum, bool result, bool success);

    /// @dev конструктор
    ///
    /// @param _tokenAddress - адрес токена, которы можно голосовать
    /// @param _time - продолжительность голосования в секундах
    ///
    /// @dev также в конструкторе инициализируется адрес аккаунта, который может создавать голосования - chairman
    ///
    constructor(address _tokenAddress, uint256 _time){
        TOK = IMyERC20(_tokenAddress);
        time = _time;
        chairman = msg.sender;
    }

    /// @notice функция для получения информации о депозите
    ///
    /// @return возвращает структуру deposit с информацией о депозите аккаунта, вызвавшего функцию
    ///
    function getDeposit(address _adr) external view returns(deposit memory){
        return deposits[_adr];
    }

    /// @notice функция добавления нового голосования
    ///
    /// @param _pDescription - описание голосования
    /// @param _pAbiArguments - аби и аргументы вызываемой функции
    /// @param _pCallData - закодированные сигнатура функции и аргументы
    /// @param _pCallAddres - адрес вызываемого контракта
    ///
    /// @dev вызывает revert если голосование старается создать не chairman
    ///
    /// @dev добавляет новую структуру голосования Proposal в массив allProposals
    /// @dev вызывает событие AddProposal
    ///
    function addProposal(
        string calldata _pDescription, 
        string calldata _pAbiArguments,
        bytes calldata _pCallData,
        address _pCallAddres
    )
        external
    {
        require(msg.sender == chairman, "You do not have permission to add proposal");

        allProposals.push(Proposal(
            allProposals.length + 1,
            block.timestamp + time,
            0,
            0,
            _pDescription,
            _pAbiArguments,
            _pCallData,
            _pCallAddres,
            false
        ));

        emit AddProposal(allProposals.length, _pDescription, _pAbiArguments, _pCallData, _pCallAddres);
    }

    /// @notice Функция голосования
    ///
    /// @param _pId - id голосования
    /// @param _choice - голос за или против
    ///
    /// @dev вызывает revert если голосующий не внёс депозит
    /// @dev вызывает revert при попытке повторного голосования с одного адреса
    /// @dev вызывает revert если время голосования истекло
    ///
    /// @dev увеличиваем количество токенов за выбор голосующего
    /// @dev отмечаем адрес как проголосовавший
    /// @dev обновляем количество токенов, замороженных на депозите и время заморозки
    ///
    function vote(
        uint _pId,
        bool _choice
    )
        external
    {
        StakeStruct memory stake = staking.getStakes(msg.sender);
        require(stake.tokenAmount > 0,
            "You did not make a deposit");
        require(voters[_pId][msg.sender] == false,
            "You already voted");
        require(block.timestamp < allProposals[--_pId].pEndTime,
            "Voting time is over");

        if(_choice){
            allProposals[_pId].pTokenYes += stake.tokenAmount;
        } else {
            allProposals[_pId].pTokenNo += stake.tokenAmount;
        }

        voters[_pId][msg.sender] = true;
        deposits[msg.sender].frozenToken = stake.tokenAmount;
        deposits[msg.sender].unFrozentime = allProposals[_pId].pEndTime;
    }

    /// @notice Функция окончания голосования
    ///
    /// @param _pId - id голосования
    ///
    /// @dev вызывает revert если время голосования не истекло
    /// @dev вызывает revert если голосование уже было завершено ранее
    ///
    /// @dev выставляет статус, что голосование завершено
    /// @dev проверяет, что набрался кворум
    /// @dev если набрался кворум количество токенов ЗА больше, количество токнов ПРОТИВ, вызывается функция
    /// @dev вызывает событие FinishProposal
    ///
    function finishProposal(
        uint _pId
    )
        external
    {
        require(block.timestamp > allProposals[--_pId].pEndTime,
        "Voting time is not over yet");
        require(allProposals[_pId].pStatusEnd == false,
        "Voting is now over");

        bool quorum = false;
        bool result = false;
        bool success = false;

        allProposals[_pId].pStatusEnd = true;

        if(allProposals[_pId].pTokenYes + allProposals[_pId].pTokenNo > TOK.totalSupply() / 2){
            quorum = true;
            if(allProposals[_pId].pTokenYes > allProposals[_pId].pTokenNo){
                result = true;
                (success, ) = allProposals[_pId].pCallAddres.call(allProposals[_pId].pCallData);
            }
        }

        emit FinishProposal(allProposals[_pId].pDescription, quorum, result, success);
    }

    /// @notice Функция для получения списка всех голосований
    ///
    /// @dev возвращает массив allProposals со всеми голосованиями
    ///
    function getAllProposal()
        external
        view
        returns(Proposal[] memory)
    {
        return allProposals;
    }

    /// @notice Функция для получения информации об одном голосовании по его id
    ///
    /// @param _pId - id голосования
    ///
    /// @dev вызывает revert, если такого id не существует
    ///
    /// @return возвращает одно голосование - структуру Proposal
    ///
    function getProposalByID(
        uint _pId
    )
        external
        view
        returns(Proposal memory)
    {
        require(allProposals.length > --_pId, "There is no vote with this id");
        return allProposals[_pId];
    }

    // изначально установить контракт стейка может только хозяин контракта
    // в дельнейшем изменить адрес стейка можно только голосованием
    function setStake(address _stakeAddress) public {
        require(msg.sender == chairman && address(staking) == address(0) || msg.sender == address(this),
                "You do not have access rights");
        staking = Istaking(_stakeAddress);
    }

    function getStakeAddress() public view returns(address){
        return address(staking);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMyERC20 {
    function name() external view returns(string memory);
    function totalSupply() external view returns(uint256);
    function decimals() external view returns(uint8);
    function balanceOf(address) external view returns(uint256);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function transfer(address, uint256) external returns(bool);
    function transferFrom(address, address, uint256) external returns(bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;

struct StakeStruct{
    uint256 tokenAmount;
    uint256 timeStamp;
    uint256 rewardPaid;
}

interface Istaking {

    function setfreezingTime(uint256) external;    
    function getStakes(address) external view returns(StakeStruct memory);
}