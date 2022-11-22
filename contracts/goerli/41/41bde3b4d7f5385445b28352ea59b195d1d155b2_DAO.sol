/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

interface IERC20 {
    function transferFrom (address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function totalSupply () external view returns (uint256);
}

contract DAO {

    IERC20 TOD;         // Интерфейс к токену, которым будут голосовать и ставить депозит
    uint256 duration;   // Время, отводимое для голосования
    address owner;      // Адрес хозяина контракта, который может создавать голосования

    // Структура депозита
    struct deposit {
        uint256 amount;         // всего токенов в депозите
        uint256 frozenAmount;   // количество замороженных токенов (которыми голосуем)
        uint256 unfrozenTime;   // время разморозки
    }
    // Словарь депозитов и их владельцев
    mapping(address => deposit) deposits;

    // Структура голосования
    struct Proposal {
        uint256 id;
        uint256 startTime;
        uint256 countYes;
        uint256 countNo;
        bytes callData;
        address callAddress;
        bool isOver;
    }
    // Список голосований
    Proposal[] allProposals;

    // Адрес >> id голосования >> ставка
    mapping(address => mapping(uint256 => uint256)) activeProposals;

    // Событие, испускаемое при создании нового голосования
    event AddProposal(uint256 id, bytes callData, address callAddress);
    // Событие, испускаемое при завершении голосования
    event FinishProposal(bool quorum, bool result, bool success);

    constructor(uint256 _duration, address _TOD){
        duration = _duration;
        TOD = IERC20(_TOD);
        owner = msg.sender;
    }

    // Добавление депозита
    function addDeposit (uint256 _amount) external {
        TOD.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender].amount += _amount;
    }

    // Вывод депозита
    function withdrawDeposit (uint256 _amount) external {
        require( block.timestamp >= deposits[msg.sender].unfrozenTime, "Freezing time is not expired yet" );
        require( _amount <= deposits[msg.sender].amount, "There is no such amount of tokens in deposit" );

        deposits[msg.sender].frozenAmount = 0;
        TOD.transfer(msg.sender, _amount);
        deposits[msg.sender].amount -= _amount;
    }

    // Добавление нового голосования
    function addProposal (bytes calldata _callData, address _callAddress) external {
        require( msg.sender == owner, "You are not an owner" );
        
        // id, startTime, countYes, countNo, callData, callAddress
        allProposals.push(Proposal(allProposals.length + 1, block.timestamp, 0, 0, _callData, _callAddress, false));
        emit AddProposal(allProposals.length + 1, _callData, _callAddress);
    }

    // Функция голосования
    function vote (uint256 id, bool choice, uint256 _amount) external {
        require(
            deposits[msg.sender].amount - deposits[msg.sender].frozenAmount > 0,
            "You don't have available amount in deposit"
        );
        require(
            _amount <= deposits[msg.sender].amount - deposits[msg.sender].frozenAmount,
            "Not enough amount in deposit"
        );
        require( _amount > 0, "Amount coudn't be zero" );
        require( activeProposals[msg.sender][id] == 0, "You are already participating in this proposal" );
        require( block.timestamp < allProposals[id-1].startTime + duration, "Proposal is over" );

        if ( choice ) {  // yes
            allProposals[id-1].countYes += _amount;
        }
        else {  // no
            allProposals[id-1].countNo += _amount;
        }
        activeProposals[msg.sender][id] = _amount;  // отмечаем, что адрес в голосовании заморозил столько-то токенов
        deposits[msg.sender].frozenAmount += _amount;  // увеличиваем кол-во замороженных токенов

        // если новое голосование закончится позже unfrozenTime в депозите >> увеличиваем unfrozenTime
        if ( deposits[msg.sender].unfrozenTime < allProposals[id-1].startTime + duration ) {
            deposits[msg.sender].unfrozenTime = allProposals[id-1].startTime + duration;
        }
    }

    // Функция окончания голосования
    function finishProposal (uint256 id) external {
        require( block.timestamp >= allProposals[id-1].startTime + duration, "Proposal in progress" );
        require( allProposals[id-1].isOver == false, "Proposal was already finished" );

        allProposals[id-1].isOver = true;

        bool quorum = false;
        bool result = false;
        bool success = false;
        if ( allProposals[id-1].countYes + allProposals[id-1].countNo > TOD.totalSupply() / 2 ) {
            quorum = true;
            if ( allProposals[id-1].countYes > allProposals[id-1].countNo ) {
                result = true;
                (success,) = allProposals[id-1].callAddress.call(allProposals[id-1].callData);
            }
        }
        emit FinishProposal(quorum, result, success);
    }

    // Геттер информации о депозите
    function getDeposit() external view returns (deposit memory) {
        return deposits[msg.sender];
    }

    // Геттер списка всех голосований
    function getAllProposal() external view returns (Proposal[] memory) {
        return allProposals;
    }

    // Геттер информации об одном голосовании по id
    function getProposalByID (uint256 id) external view returns (Proposal memory) {
        require( id != 0 && id <= allProposals.length, "No such proposal id" );
        return allProposals[id-1];
    }

}