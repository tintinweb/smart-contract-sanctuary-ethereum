pragma solidity >=0.7.3;

contract CIPAY {
    

    uint public sender_id;
    uint public receiver_id;
    uint public betrag_EUR;
    string public date_time;

    constructor (uint _sender_id, uint _receiver_id, uint _betrag_EUR, string memory _date_time) public {
        sender_id = _sender_id;
        receiver_id = _receiver_id;
        betrag_EUR = _betrag_EUR;
        date_time = _date_time;
    }

    function getData() public view returns(uint, uint, uint, string memory) {
        return(sender_id, receiver_id, betrag_EUR, date_time);
    }
    function setData (uint _sender_id, uint _receiver_id, uint _betrag_EUR, string memory _date_time) public {
        sender_id = _sender_id;
        receiver_id = _receiver_id;
        betrag_EUR = _betrag_EUR;
        date_time = _date_time;
    }


}

//1, 2, 1250, "29.09.2022 23:20"
//Contract deployed to address: 0xb443F331e7Da201fcf336D874e3819e983524CF1
//npx hardhat verify --network goerli 0xb443F331e7Da201fcf336D874e3819e983524CF1 1, 2, 1250, "29.09.2022 23:20"