/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

pragma solidity ^0.8.11;


contract Rent {
    address payable public admin;
    uint256[7][5] private allReserved;

    struct Client {
        uint256[7][5] reserved;
        uint8 day;
        uint8 room;
    }
    
    mapping(address => Client) private client;

    constructor(address payable _admin) {
        require(_admin != address(0), "Admin address can't be null");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    // 10**16 - цена для добавления бронирования
    function addReservation(uint8 _day, uint8 _room) external payable {
        require(_day <= 6 && _room <= 4, "Unappropriate parametres");
        require(msg.value >= 10**16, "Unappropriate amount of wei");      // 10000000000000000

        client[msg.sender].reserved[_day][_room] += 1;
        allReserved[_day][_room] += 1;
        client[msg.sender].day=_day;
        client[msg.sender].room=_room;
    }

    function resetClientInfo(address wallet) external onlyAdmin {
        delete client[wallet];
    }

    function resetAll() external onlyAdmin {
        delete allReserved;
    }
    
    function getClientReservations(address wallet) public view returns(uint8 _day, uint8 _room, uint256[7][5] memory _allroom) {
        _day = client[wallet].day;
        _room = client[wallet].room;
        _allroom = client[wallet].reserved;
    }
    
    function getAllTable() public view returns(uint256[7][5] memory){
        return allReserved;
    }
    
    // бронь платна, поэтому нужна функция вывода средств с контракта
    function withdraw() external onlyAdmin {
        (bool transferSuccess, ) = admin.call{
                value: address(this).balance
            }("");
        require(transferSuccess, "Transfer to admin failed");
    }
}