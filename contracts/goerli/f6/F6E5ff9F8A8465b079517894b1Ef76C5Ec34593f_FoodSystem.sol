// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./slimFactory.sol";

contract FoodSystem is SlimFactory {
    struct food {
        string name;
        uint price;
        uint exp;
    }

    food[] foods;

    // ["apple", "banana", "orange"]
    constructor(string[] memory InitialFoods) {
        uint index;
        for (index = 0; index < InitialFoods.length; index++) {
            foodIndex[index] = InitialFoods[index];
            foods.push(food(InitialFoods[index], 10**16, 10)); //0.01 ether
            priceOfFood[InitialFoods[index]] = foods[index].price;
            expOfFood[InitialFoods[index]] = foods[index].exp;
        }
    }

    mapping(uint => string) foodIndex;
    mapping(string => uint) priceOfFood;
    mapping(string => uint) expOfFood;

    // Mod Function OnlyOwner
    function addNewFood(
        string memory _name,
        uint _price,
        uint _exp
    ) public onlyOwner returns (uint Index) {
        uint index = foods.length;
        foods.push(food(_name, _price, _exp));
        foodIndex[index] = _name;
        priceOfFood[_name] = _price;
        return index;
    }

    function setNewPrice(uint _index, uint _price) public onlyOwner {
        foods[_index].price = _price;
    }

    // Internal Function

    // Public Function
    function foodSearching(uint _id)
        public
        view
        returns (
            string memory name,
            uint price,
            uint exp
        )
    {
        require(_id < foods.length, "ID not in the data !");
        food memory Food = foods[_id];
        return (Food.name, Food.price, Food.exp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SlimFactory {
    uint dnaDigit = 10**12;
    address owner;

    struct slim {
        string name;
        string sex;
        uint dna;
        uint level;
    }

    slim[] slims;

    event newSlimCreate(string _message);

    mapping(address => uint) ownerSlimId;
    mapping(address => bool) isCreated;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {}

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    //Mod Function OnlyOwner

    //Internal Function
    function _generateRandomDna(string memory _name)
        internal
        view
        returns (uint)
    {
        uint dna = uint(
            keccak256(abi.encodePacked(_name, msg.sender, block.timestamp))
        ) % dnaDigit;
        return dna;
    }

    function _generateRandomSexual(string memory _name)
        internal
        view
        returns (string memory)
    {
        string memory sex;
        if (_generateRandomDna(_name) % 2 == 0) {
            sex = "Male";
        } else {
            sex = "Female";
        }
        return sex;
    }

    function _createSlim(string memory _name) internal {
        slims.push(
            slim(
                _name,
                _generateRandomSexual(_name),
                _generateRandomDna(_name),
                1
            )
        );
        ownerSlimId[msg.sender] = slims.length - 1;
    }

    //Public Function
    function slimsCreator(string memory _name) public payable {
        require(isCreated[msg.sender] == false, "Created already !");
        _createSlim(_name);
        emit newSlimCreate("New Slim Come to The World!");
        isCreated[msg.sender] = false;
    }

    function mySlimState()
        public
        view
        returns (
            string memory name,
            string memory sex,
            uint dna,
            uint level
        )
    {
        return (
            slims[ownerSlimId[msg.sender]].name,
            slims[ownerSlimId[msg.sender]].sex,
            slims[ownerSlimId[msg.sender]].dna,
            slims[ownerSlimId[msg.sender]].level
        );
    }
}