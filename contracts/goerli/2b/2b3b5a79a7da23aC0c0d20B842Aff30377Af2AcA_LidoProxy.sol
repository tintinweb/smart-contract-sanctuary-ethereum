/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

pragma solidity ^0.4.24;

contract LidoProxy {
    address public targetAddress;

    constructor(address _lido) {
        targetAddress = _lido;
    }

    function callTarget(address _referra) external payable {
        bytes memory data = abi.encodeWithSignature('submit(address)', _referra);
        targetAddress.call(data);
    }
}