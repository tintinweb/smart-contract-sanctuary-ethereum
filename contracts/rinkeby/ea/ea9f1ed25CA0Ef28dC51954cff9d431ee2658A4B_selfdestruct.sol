pragma solidity 0.8.4;

contract selfdestruct {
    event Log(uint256);
    uint256 myNumber = 1;

    function suicide() public {
        selfdestruct(payable(0x8136618BC694C2f3062b449de00394ca8b9a517C));
    }

    function getMyNumber() public returns (uint256) {
        emit Log(myNumber);
        return myNumber;
    }

    function setMyNumber(uint256 newNumber) public {
        myNumber = newNumber;
        emit Log(myNumber);
    }
}