pragma solidity ^0.8.0;

//- В контракте имеется функция вноса любой суммы пожертвования в нативной валюте блокчейна
//- В контракте имеется функция вывода любой суммы на любой адрес, при этом функция может быть вызвана только владельцем контракта
//- В контракте имеется view функция, которая возвращает список всех пользователей когда либо вносивших пожертвование. В списке не должно быть повторяющихся элементов
//- В контракте имеется view функция позволяющая получить общую сумму всех пожертвований для определённого адреса

contract donations {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    mapping(address => uint256) amountOfAddressDonation;
    address[] donationAddreses;

    function donationFund() public payable {
        require(msg.value != 0, "Not less then zero");
        if (amountOfAddressDonation[msg.sender] == 0) {
            donationAddreses.push(msg.sender);
        }
        amountOfAddressDonation[msg.sender] += msg.value;
    }

    function donationWithdraw(address payable _address, uint256 amountInWEI)
        public
        payable
    {
        require(msg.sender == owner, "Not an owner");
        _address.transfer(amountInWEI);
    }

    function allDonationsAddreses() public view returns (address[] memory) {
        return donationAddreses;
    }

    function amountByAddress(address _address) public view returns (uint256) {
        return amountOfAddressDonation[_address];
    }
}