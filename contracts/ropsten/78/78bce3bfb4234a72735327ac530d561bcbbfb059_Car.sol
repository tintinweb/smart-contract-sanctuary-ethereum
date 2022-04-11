/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

/*
Условия задания:
Состряпать структуру (6 значений):
1. Логическая (БУ - Тру, Новая - Фолс)
2. uint4 (Кол-во дверей)
3. Симв. марка
4. Симв. цвет
5. uint (пробег)
6. int (цена)

add
show
*/
//Компилятор
pragma solidity >=0.4.16 < 0.8.0;
//Создания блока контракта
contract Car{
//Структура нашего контракта
    struct Car{
        bool status;
        uint8 doors;
        string model;
        string color;
        uint road;
        int price;
    }
//В маппине описываем, что ключ string будет связан с нашей структурой машины
    mapping (string => Car) cars;
//Описываем массив id для каждой машины
    string[] public carsId;
//Описываем функцию для добавления параметров для каждой новой машины исходя из ТЗ
     function addCar(
        string _address,
        bool _status,
        uint8 _doors,
        string _model,
        string _color,
        uint _road,
        int _price) public {
        var car = cars[_address];

        car.status = _status;
        car.doors = _doors;
        car.model = _model;
        car.color = _color;
        car.road = _road;
        car.price = _price;
        //+1 для соблюдения порядкового номера(id) последующих автомобилей
        carsId.push(_address) + 1;

    }
    //Функция для возврата значений при вводе того номера машины, который был обозначен
     function showCar(string idCar) view public returns (bool, uint8, string, string, uint, int) {
        return (cars[idCar].status, cars[idCar].doors, cars[idCar].model, cars[idCar].color, cars[idCar].road, cars[idCar].price);
    }
}