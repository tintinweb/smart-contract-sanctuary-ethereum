//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Lottery{
    uint public minFee;
    address private owner;
    address[] public players;
    mapping(address =>uint) public playerBalances;
    event newPlayer(
        address indexed player,
        uint fee
    );

    constructor(uint _minFee){
        minFee = _minFee;
        owner = msg.sender;
    }

    function play()public payable{
        require(msg.value >= minFee, "Tiene que pagar mas");
        players.push(msg.sender);
        playerBalances[msg.sender] += msg.value;
        emit newPlayer(msg.sender, msg.value);
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function getRandomNumber() public view returns(uint){
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function pickWinner() public onlyOwner{
        uint index = getRandomNumber() % players.length;
        (bool sucess,) = players[index].call{value:getBalance()}("");
        require(sucess, "Pago fallo");
        players = new address [](0); 
    } 

    function changeOwner(address adrressNewOwner) public onlyOwner{
        owner = adrressNewOwner;
    }

    function getOwner() public view returns(address){
        return owner;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

}