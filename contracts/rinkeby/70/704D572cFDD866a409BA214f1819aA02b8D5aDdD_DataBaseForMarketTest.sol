//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract DataBaseForMarketTest {

    struct advertisments {
        string header; // тут название обьявления
        string description; // тут описание
        uint256 price; // цена тут
        string typeOfDeal; // wtb / wts
        uint256 timestamp; // время создания обьявления
    }

    mapping(address => advertisments[]) public numberOfAdvertismentsOfUser;


    // тут вы узнаем сколько обьявлений было создано конкретным кошельком
    function getNumberOfAdvertismets(address _address) public view returns(uint256) {
        return (numberOfAdvertismentsOfUser[_address].length);
    }


    // тут мы делаем пост (состоит он изх того, что задано в структуре)
    function zapis(string memory _head, string memory _description, string memory _typeOfDeal, uint256 _price) external {
        advertisments[] storage listOfAdvertisments = numberOfAdvertismentsOfUser[msg.sender];
        listOfAdvertisments.push(advertisments(_head, _description, _price, _typeOfDeal, block.timestamp));
    }

    // тут мы забираем пост по адрессату, который им владеет и номеру самого поста
    function getZapis(address _address, uint256 numberOfAdvertisment) public view returns(advertisments memory){  
        return(numberOfAdvertismentsOfUser[_address][numberOfAdvertisment]);
    }

    // тут мы удаляем обьвяление, по которому была выполнена сделка и его надо исключить
    function removeZapis(address _address, uint256 numberOfAdvertisment) public{
        advertisments[] storage listOfAdvertisments = numberOfAdvertismentsOfUser[_address];
        listOfAdvertisments[numberOfAdvertisment] = listOfAdvertisments[listOfAdvertisments.length - 1];
        listOfAdvertisments.pop();
    }


    // тут будет функция, которая очищает все старые обьявления
    // на вход подаются все аддрема, которые мы хотим проверит, по ним пробегаемся по их обьявлениям, и те которые
    // слишком старые - удаляютсяъ

    // проверить на комиссию, мб очень дорого выйдет так делать и надо будет придумать
    // другую механику
    function refresher(address[] memory _addresses) external {
        uint256 addresses = _addresses.length;
        uint advert;
        for(uint256 i=0; i<addresses; i++){
            advert = getNumberOfAdvertismets(_addresses[i]);
            for(uint256 j=0; j<advert; j++){
                if(getZapis(_addresses[i], j).timestamp + 1000 <= block.timestamp){
                    removeZapis(_addresses[i], j);
                }
            }
        }
    }



    constructor() {}
}