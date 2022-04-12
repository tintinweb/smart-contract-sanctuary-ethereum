/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

pragma solidity>=0.4.16<0.8.0;

contract CarsForBlockChain {    /*  название нашего контракта */
    Car[] public car;           /*  создаём массив, паблик значит что данные общедоступные, и все могут дёргать */
    uint256 public carCount;    /* задаём максимальную длину списка */

    struct Car {                /*  задаём значения в массиве */
      bool bu;
      uint8 doors;
      string marka;
      string colors; 
      uint32 mileage;
      uint32 price; 
    } 

    function add(bool bu, uint8 doors, string memory marka, string memory colors, uint32 mileage, uint32 price ) public {   /*  создаём функцию добавления значений в массив */
      carCount+=1; /*  двигаем список вниз */
      car.push(Car( bu, doors, marka, colors, mileage, price)); /*  добавляем наши значения */

    }

    function show() public view returns(uint256) {   /*  показываем значение определённой строки */
        return carCount;
    }
}