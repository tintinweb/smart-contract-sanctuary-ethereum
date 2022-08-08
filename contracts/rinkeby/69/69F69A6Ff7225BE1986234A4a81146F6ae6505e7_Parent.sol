// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
import "./sonCon.sol";
contract Parent {
    sonCon public sonAddress;
    constructor(){}
    
    function deployNewInstance(string memory _nameParent, uint256 _ageParent)public{
        sonAddress = new sonCon(_nameParent, _ageParent);   
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
contract sonCon {
    string public name;
    uint256 public age;
    address public owner;
    constructor(string memory _name, uint256 _age){
        name = _name;
        age = _age;
    }

    function register() public {
        owner = msg.sender;
    }
}