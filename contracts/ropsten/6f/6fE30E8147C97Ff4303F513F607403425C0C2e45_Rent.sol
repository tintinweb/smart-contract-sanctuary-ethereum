/**
 *Submitted for verification at Etherscan.io on 2022-01-31
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
        require(msg.sender == admin, "User is not an admin");
        _;
    }
    
    // 10**14 - цена для добавления бронирования
    function addReservation(uint8 _day, uint8 _room, address wallet) external payable {
        require(_day <= 6 && _room <= 4, "Unappropriate parametres");
        require(msg.value >= 10**14, "Unappropriate amount of wei");      // 100000000000000 wei

        client[wallet].reserved[_day][_room] += 1;
        allReserved[_day][_room] += 1;
        client[wallet].day=_day;
        client[wallet].room=_room;
    }

    function resetClientInfo(address wallet) external onlyAdmin {
        delete client[wallet];
    }

    function resetAll() external onlyAdmin {
        delete allReserved;
    }
    
    function getClientReservations(address wallet) external view returns(uint8 _day, uint8 _room, uint256[7][5] memory _allroom) {
        if(msg.sender!=wallet){
            if(msg.sender!=admin)
            revert("User is not an admin");
        }
        _day = client[wallet].day;
        _room = client[wallet].room;
        _allroom = client[wallet].reserved;
    }

    function getAllTable() external view onlyAdmin returns(uint256[7][5] memory){
        return allReserved;
    }
    
    function getBalance() external view onlyAdmin returns (uint) {
        return address(this).balance;
    }
    function withdraw() external onlyAdmin {
        admin.transfer(address(this).balance);
    }
}