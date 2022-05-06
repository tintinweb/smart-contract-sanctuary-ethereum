//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract DataBaseForMarketTest {

    struct advertisments {
        string header; // тут название обьявления
        string description; // тут описание
        uint256 price; // цена тут
        string typeOfDeal; // wtb / wts
    }

    mapping(address => advertisments[]) public numberOfAdvertismentsOfUser;



    function getNumberOfAdvertismets(address _address) external view returns(uint256) {
        return (numberOfAdvertismentsOfUser[_address].length);
    }


    // тут мы делаем пост (состоит он изх того, что задано в структуре)
    function zapis(string memory _head, string memory _description, string memory _typeOfDeal, uint256 _price) external {
        advertisments[] storage listOfAdvertisments = numberOfAdvertismentsOfUser[msg.sender];
        listOfAdvertisments.push(advertisments(_head, _description, _price, _typeOfDeal));
    }

    // тут мы забираем пост по адрессату, который им владеет и номеру самого поста
    function getZapis(address _address, uint256 numberOfAdvertisment) external view returns(advertisments memory){  
        return(numberOfAdvertismentsOfUser[_address][numberOfAdvertisment]);
    }

    // тут мы удаляем обьвяление, по которому была выполнена сделка и его надо исключить
    function removeZapis(address _address, uint256 numberOfAdvertisment) external{
        advertisments[] storage listOfAdvertisments = numberOfAdvertismentsOfUser[_address];
        listOfAdvertisments[numberOfAdvertisment] = listOfAdvertisments[listOfAdvertisments.length - 1];
        listOfAdvertisments.pop();
    }

    // function remove(uint index) public{
    //     firstArray[index] = firstArray[firstArray.length - 1];
    //     firstArray.pop();
    // }


    constructor() {}
}