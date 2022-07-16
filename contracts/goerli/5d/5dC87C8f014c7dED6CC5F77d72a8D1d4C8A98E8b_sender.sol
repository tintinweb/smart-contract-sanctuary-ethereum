pragma solidity ^0.5.2;

contract IStateSender {
    function syncState(address receiver, bytes calldata data) external;
    function register(address sender, address receiver) public;
}

contract sender {
    address public stateSenderContract = 0x9C5f2aDD39224DF9CfdE92AA293235eB443086E3;
    address public receiver = 0xBd3dcFAA7671332b4B516a7be89FdE4950a704d8;

    uint public states = 0;

    function sendState(bytes calldata data) external {
        states = states + 1 ;
        IStateSender(stateSenderContract).syncState(receiver, data);
    }

}