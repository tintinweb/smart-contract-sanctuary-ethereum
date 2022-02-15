/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

pragma solidity 0.8.4;

contract Challenge {
    // Private number, will not be public at all ;)
    uint8 private constant answer = 42;

    constructor() payable {}

    function guess(uint8 n) external payable {
        require(msg.value == 100 wei);

        if (n == answer) {
            (bool success, ) = msg.sender.delegatecall('');
            require(success, 'send fail');
        }
    }
}