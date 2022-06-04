/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;


contract Ownable {
    address public owner;

    /**
      * The Ownable constructor sets the original `owner` of the contract to the sender
      * account.
      */
    constructor() public {
        owner = msg.sender;
    }

    /**
      * Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}



contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}



contract VesselIdentifier is Ownable {

    string public ImoCode = "10534567";
    
    string public Flag = "Flag not set yet";
    
    function ChangeFlag(string memory _flag) public {
        Flag = _flag;
    }
    
    string public CallSign = "Call Sign not set yet";
    
    function ChangeCallSign(string memory _CallSign) public {
        CallSign = _CallSign;
    }

    address public VesselDetailsContract = 0x0000000000000000000000000000000000000000;
    
    function ChangeVesselDetailsContract(address _VesselDetailsContract) public {
    VesselDetailsContract = _VesselDetailsContract;
    }





    
}