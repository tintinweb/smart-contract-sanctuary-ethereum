pragma solidity ^0.4.24;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}


contract EventsDatabase is Ownable {

    //структура для хранения события
    struct EventStruct {
      uint64 eventID;    
      uint eventDate;
      uint8 result; // 0 - отрицательный, 1 - положительный, 2 - не выставлен
      bool isSet;
    }
    
    //Событие. Записываем лог
    event createEventLog(string _description, uint _eventDate,  uint32 _eventID );
    event setEventResultLog(string _description,  uint32 _eventID, uint8 _result );

    //адресс с которого разрешено заносить события в базу
    address manager;
    
    //Сама база данных ID события => структура
    mapping (uint64 => EventStruct) eventDatabase;
    
    //конструктор. Вызывается 1 раз при деплое контракта
    constructor() public {
        manager = msg.sender;
    }

    //Модификатор проверяющий, является ли вызвавший метод владельцем контракта или менеджером
    modifier onlyOwnerOrManager() {
        require((msg.sender == owner)||(msg.sender == manager));
        _;
    }

    //Смена менеджера. Может быть вызвана только владельцем
    function setManager(address _manager) public onlyOwner {
        manager = _manager;
    }
    
    //Заносим событие в базу данных
    function createEvent(string _description, uint _eventDate, uint32 _eventID ) public onlyOwnerOrManager {
        //Проверяем - существует ли событие с таким ID
        if(eventDatabase[_eventID].isSet){
            revert();
        }
        EventStruct memory eventStruct = EventStruct({eventID:_eventID, eventDate:_eventDate, result:2,  isSet:true });
        
        eventDatabase[_eventID] = eventStruct;
        emit createEventLog(_description,  _eventDate,   _eventID);
    }
    
    function setEventResult(string _description, uint32 _eventID, uint8 _result  ) public onlyOwnerOrManager {
        //Проверяем - существует ли событие с таким ID
        if(!eventDatabase[_eventID].isSet){
            revert();
        }
        //проверяем - наступилали дата события
        if(now < eventDatabase[_eventID].eventDate){
            revert();
        }
        
        
        eventDatabase[_eventID].result = _result;
        emit setEventResultLog(_description,  _eventID,   _result);
    }
    
    function getEventResult( uint32 _eventID ) public constant returns(uint8) {
        //Проверяем - существует ли событие с таким ID
        if(!eventDatabase[_eventID].isSet){
            revert();
        }
        
        return eventDatabase[_eventID].result;
    }
    
    
}