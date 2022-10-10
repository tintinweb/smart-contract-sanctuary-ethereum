/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

pragma solidity >0.8.6 <0.8.8;

contract SimpleStorage {
    // string public name;
    uint256 public number ;

    //struct
    struct Person {
        string name;
        uint256 number;
    }
    // array of struct
    Person[] public person ;

    //mapping
    mapping(string => uint256) public nameToFavNum;

    function addPerson(string memory _name, uint256 _number) external {
        
        Person memory newPerson = Person({name:_name, number:_number});
        person.push(newPerson);

        /*********
            else u can add person by 
        ->     person.push(Person(_name, _number));
        *********/

        //adding to the mapping 
        nameToFavNum[_name] = _number;

    }

    function store(uint256 _number) external virtual{
        number = _number;
    }

    function retrieve() public view returns (uint256){
        return number;
    }


}