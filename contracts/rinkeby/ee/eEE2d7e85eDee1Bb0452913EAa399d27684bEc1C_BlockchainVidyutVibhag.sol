// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract BlockchainVidyutVibhag{
    // 2611769     
    address private admin;
   uint public constant timePeriod = 2611769;
   uint public paneltyAmount=1000000000000000000;

    struct User{
        address userAddress;
        string add;
        uint current_time;
        bool isActive;
        uint units;
        uint payableAmount;
        uint dueTime ;
        
    }
    // mapping..
    mapping(address=>User)public userMap;
    mapping(address=>bool)private operator;

    // events..
    event registredUserEvent(
        address indexed userAddress,
        bool status
        
    );
    event paidBillEvents(
        address indexed _from,
        uint _value
    );

    //constructor to initialize deployed address.
    constructor(){
        admin = msg.sender;
    }

    // modifiers for onlyAdmin and onlyOperator..
    modifier onlyAdmin {
      require(msg.sender == admin,"Only Admin Can Access");
      _;
    }
    modifier onlyOperator {
      require(operator[msg.sender]);
       _;  
    }

    
    function createOperator(address adsOfOperator)external onlyAdmin {
      operator[adsOfOperator] = true; 
    }
    function removeOperators(address operatorAds)external onlyAdmin{
        operator[operatorAds] = false;

    } 
    function userRegisteration(address userAddress,string memory _add,bool isActive)public onlyAdmin {
        require(userMap[userAddress].isActive==false,"Already Registered");
        userMap[userAddress]=User(userAddress,_add,0,true,0,0,0);

        emit registredUserEvent(userAddress,true);
    }
    function removeUser(address adsOfUser)external onlyAdmin returns(bool){
        userMap[adsOfUser].isActive = false;

    }

    // Generate bill for users and store their current and duetime.
    function generateBill(address ads,uint _units)external onlyOperator{
        require(userMap[ads].isActive==true,"Invalid user address");
        userMap[ads].units= _units;
        userMap[ads].payableAmount = 8*_units;
        
        // store current time and duetime of user in struct
        userMap[ads].current_time=block.timestamp;
        userMap[ads].dueTime=block.timestamp+timePeriod;

                
    }
    function billPay() external payable{
        // add panelty to user after due time
        _paneltyToUser();
        require(userMap[msg.sender].isActive==true,"Inavlid user address,Unble to pay");
        require(userMap[msg.sender].units>0,"Already paid");
        require(msg.value/10^18>=userMap[msg.sender].payableAmount,"Insufficient amount to paid");
        // require(userMap[msg.sender].current_time<=userMap[msg.sender].dewTime,"Time Limit exceed");

        address payable _to=payable(address(this));
        bool sent = _to.send(msg.value/10^18);

        userMap[msg.sender].units = 0;
        userMap[msg.sender].payableAmount = 0;

        emit paidBillEvents(msg.sender,msg.value);

    
    }
    function _paneltyToUser()internal view{
        if(block.timestamp>=userMap[msg.sender].dueTime){
            userMap[msg.sender].payableAmount+paneltyAmount;
        }
        

    }

}