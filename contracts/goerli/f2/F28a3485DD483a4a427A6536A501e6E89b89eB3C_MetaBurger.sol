/**
 *Submitted for verification at Etherscan.io on 2022-10-07
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

contract MetaBurger {
    

    address public owner;
    address public god;
    uint256 public price;
    string public messageForOwner;

    constructor(uint256 _price,string memory _messageForOwner) {
        owner = msg.sender;
        god = msg.sender;
        price = _price;        
        messageForOwner=_messageForOwner;
    }

    modifier onlyGod {

        require(msg.sender==god);
        _;
        
    }

    modifier onlyOwner {

        require(msg.sender==owner);
        _;
        
    }


    modifier notAnOwner {

        require(msg.sender!=owner);
        _;
        
    }
    
    function changePrice(uint256 _newPrice)external onlyOwner returns (bool) {

        price=_newPrice;
        return true;

    }

    receive() external payable notAnOwner{

        require(msg.value==price);
        owner = msg.sender;

    }

    function getMyMoney() external onlyGod{        

        payable(god).transfer(address(this).balance);

    }

}