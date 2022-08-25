//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract SolidityDevs{
    mapping(address => bool) internal owner;
    struct Dev{
        string name;
        uint256 score;
        address wallet;
        uint256[] ratings;
        bool active;
    }
    mapping(string => Dev) public devs;
    address fundManager;


    event DevCreated(string indexed name, address owner);
    event DevDeleted(string indexed name, address owner);
    event DevRated(string indexed name, address owner, uint256 rating);
    event Donated(address donator, uint256 amount);

    constructor(){
        owner[msg.sender] = true;
        fundManager = msg.sender;
    }

    function addOwner(address _address)  external{
        require(owner[msg.sender], "Only owner can call");
        owner[_address] = true;
    }

    function createDev(string memory _name, address _address) external {  
        require(owner[msg.sender], "Only owner can call");   
        uint256[] memory arr = new uint256[](0);
        devs[_name] = Dev(_name, 0, _address, arr, true);
        emit DevCreated(_name, msg.sender);
    }

    function viewDev(string memory _name) public view returns(Dev memory){
        return devs[_name];
    }

    function viewRatings(string memory _name) public view returns(uint256[] memory){
        Dev storage dev = devs[_name];
        return dev.ratings;
    }

    function rateDev(string memory _name, uint256 _rating) external {
        require(owner[msg.sender], "Only owner can call"); 
        Dev storage dev = devs[_name];
        require(dev.active, "This dev is not active");
        require(_rating > 0 && _rating <=10, "Must be a rating between 1-10");
        dev.ratings.push(_rating);
        uint256 average = 0;
        for(uint256 i = 0; i <dev.ratings.length; i++){
            average += dev.ratings[i];
        }
        dev.score = average *100 / dev.ratings.length;

        emit DevRated(_name, msg.sender, _rating);
    }

    function deleteDev(string memory _name) external{
        require(owner[msg.sender], "Only owner can call"); 
        Dev storage dev = devs[_name];
        require(dev.active, "This dev is not active");
        dev.active = !dev.active;
        emit DevDeleted(_name, msg.sender);
    }

     receive() external payable{
         emit Donated(msg.sender, msg.value);
     }

    function withdraw() external{
        require(msg.sender == fundManager, "You cannot withdraw");
        payable(fundManager).transfer(address(this).balance);
    }

}