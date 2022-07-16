pragma solidity ^0.5.2;

contract IStateSender {
    function syncState(address receiver, bytes calldata data) external;
    function register(address sender, address receiver) public;
}

contract sender {
    address public stateSenderContract = 0xEAa852323826C71cd7920C3b4c007184234c3945;
    address public receiver = 0x67bccfE281bca7615F5cAbD9b1cF46ab622A9F15;

    uint public states = 0;

    function sendState(bytes calldata data) external {
        states = states + 1 ;
        IStateSender(stateSenderContract).syncState(receiver, data);
    }

}