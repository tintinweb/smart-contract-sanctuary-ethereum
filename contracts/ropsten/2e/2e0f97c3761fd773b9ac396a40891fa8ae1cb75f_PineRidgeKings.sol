pragma solidity ^0.4.24;


contract PineRidgeKings {
    
    string public constant king1 = 'HENDRICKS';
    string public constant king2 = 'BEN';
    string public constant king3 = 'MATT';
    string public constant king4 = 'VICTA';
    string public constant king5 = 'ZACH';
    string public constant king6 = 'H4XW3LL';
    
    address private mastermind;
    
    string[] public kingsList;
    
    constructor(PineRidgeKings) public {
        mastermind = msg.sender;
    }
    

    
    function ctrlZee() public {
        require(msg.sender == mastermind);
        selfdestruct(msg.sender);
    }
    
    
}