/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

pragma solidity ^0.8.13;

contract First{

    mapping(uint => cars) public car;

    bool G1;
    bool R1;
    uint8 carcount;
    struct person{
        string _firstname;
        string _secondname;
        uint8 _age;
    }
    struct cars{
        string _color;
        string _vendor;
        bool _fuel;
        uint8 _power;
    }
    person[] public people;

    enum Svetofor {Green, Yellow, Red}
    Svetofor public svetofor;

    constructor() public{
        svetofor = Svetofor.Green;
        G1 = true;
        R1 = false;
        
    }

    function Yellow() public {
        svetofor = Svetofor.Yellow;
        R1 = false;
        G1 = false;
        
    }

    function Red() public {
        svetofor = Svetofor.Red;
        R1 = true;
        G1 = false;
    }

    function Green() public {
        svetofor = Svetofor.Green;
         G1 = true;
         R1 = false;
    }
    function addcars(
            string memory _color,
            string memory _vendor,
            bool _fuel,
            uint8 _power
            ) public {
                if (R1 == false) {
                    return ;
                }
                carcount += 1;
                car[carcount] = cars(_color, _vendor, _fuel, _power);
                
    }
            
    function addperson(
                string memory _firstname,
                string memory _secondname,
                uint8 _age
            ) public {
                if (G1 == true) {
                    people.push(person(_firstname, _secondname, _age));
                }
                else {
                    return ;
                }
                
            }
}