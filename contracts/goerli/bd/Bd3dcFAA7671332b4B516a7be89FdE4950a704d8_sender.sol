pragma solidity ^0.8.0;

interface IStateSender {
    function syncState(address receiver, bytes calldata data) external;
}

contract sender {
    address public stateSenderContract = 0x67bccfE281bca7615F5cAbD9b1cF46ab622A9F15;
    address public receiver = 0x5ff5FE1B503de5D6E1110676bA587D346daB51e4;

    uint public states = 0;

    function sendState(bytes calldata data) external {
        states = states + 1 ;
        IStateSender(stateSenderContract).syncState(receiver, data);
    }

}