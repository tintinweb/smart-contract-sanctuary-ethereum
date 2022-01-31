/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

pragma solidity ^0.8.11;


contract Rent {
    address payable public admin;
    address payable public admin2;
    uint256[7][5] private allReserved;

    struct Client {
        uint256[7][5] reserved;
    }
    
    mapping(address => Client) private client;

    constructor(address payable _admin) {
        require(_admin != address(0), "Admin address can't be null");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin ||
        (msg.sender == admin2 && admin2 != address(0)));
        _;
    }
    
    // 10**16 - цена для добавления бронирования
    function addReservation(uint256 _day, uint256 _room) external payable {
        require(_day <= 6 && _room <= 4, "Unappropriate parametres");
        require(msg.value == 10**16, "Unappropriate amount of wei");      // 10000000000000000

        client[msg.sender].reserved[_day][_room] += 1;
        allReserved[_day][_room] += 1;
    }

    function resetClientInfo(address wallet) external onlyAdmin {
        delete client[wallet];
    }

    function resetAll() external onlyAdmin {
        delete allReserved;
    }
    
    function getClientReservations(address wallet) public view returns(uint256[7][5] memory) {
        return client[wallet].reserved;
    }
    
    function getAllTable() public view returns(uint256[7][5] memory){
        return allReserved;
    }

    function setAdmin2(address _admin) external onlyAdmin {
        admin2 = payable(_admin);
    }
    
    // бронь платна, поэтому нужна функция вывода средств с контракта
    function withdraw() external onlyAdmin {
        (bool transferSuccess, ) = admin.call{
                value: address(this).balance
            }("");
        require(transferSuccess, "Transfer to admin failed");
    }
}