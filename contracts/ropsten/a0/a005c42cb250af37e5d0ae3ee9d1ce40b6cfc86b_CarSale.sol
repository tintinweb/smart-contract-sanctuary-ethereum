/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity ^0.5.17;

contract CarSale {
    uint256 carPrice = 0.1 ether;
    address owner;
    mapping(address => uint256) public carHolders;

    constructor() public {
        owner = msg.sender;
    }

    function getCarPrice() public view returns (uint256 retVal) {
        return carPrice;
    }
    function buyCar(address _user, uint256 _amount) payable public {
        require(msg.value >= carPrice * _amount);
        bookCar(_user, _amount);
    }

    function bookCar(address _user, uint256 _amount) internal {
        owner = _user;
        carHolders[_user] = carHolders[_user] + _amount;
    }

    function withdraw() view public {
        require(msg.sender == owner, "you are not the owner");
        //(bool success, ) = payable(owner).call{value: address(this).balance}("");
        //require(success);
    }

}