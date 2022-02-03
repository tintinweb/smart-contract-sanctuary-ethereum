//SPDX-License-Identifier: Unlicense
pragma solidity  >=0.7.0 <0.9.0;

contract Owner {
     address private owner;
     event _changeOwner(address _oldOwner, address _newOwner);
    constructor() {
          owner = msg.sender;
           emit _changeOwner(address(0), owner);
    }
    modifier isOwner{
        require(msg.sender == owner, "message");
        _;
    }
    function changeOwner(address _newOwner) public isOwner{
      owner=_newOwner;
      emit _changeOwner(owner, _newOwner);
    }
    function getOwner() public view returns (address ) {
        return  owner;
    }
}