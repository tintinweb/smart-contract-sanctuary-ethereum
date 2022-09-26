/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint256 my_number;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event ValueChanged(uint256 oldvalue, uint256 newvalue);

    address private owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    function store(uint256 new_number) public {
        my_number = new_number;
        emit ValueChanged(my_number, new_number);
    }

    function retrieve() public view returns (uint256){
        return my_number;
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner,newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address){
        return owner;
    }

    function amIOwner() public view returns (bool) {
        return msg.sender==owner;
    }
}