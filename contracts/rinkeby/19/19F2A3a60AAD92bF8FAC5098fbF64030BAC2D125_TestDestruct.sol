pragma solidity 0.8.13;

contract TestDestruct {
    uint public a;
    string public name;
    constructor(uint _a, string memory _name) payable {
        a = _a;
        name = _name;
    }

    function destruct() external {
        selfdestruct(payable(msg.sender));
    }

    function balance() external view returns (uint) {
        return address(this).balance;
    }
}