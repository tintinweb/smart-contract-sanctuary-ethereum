pragma solidity 0.8.9;

contract Storage {

    string[] public names;

    constructor(string memory _name){
       names.push(_name);
    }

    function setName(string memory name) public {
       names.push(name);
    }

    function getName() public view returns(string[] memory) {
        return names;
    }
}