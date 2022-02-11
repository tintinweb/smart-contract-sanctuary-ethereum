/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

pragma solidity ^0.8.0;

interface IOwnable {
    function transferOwnership(address newOwner) external;
}

contract Factory {
    event Deployed(address addr, uint256 salt);

    function deploy(bytes memory code, uint256 salt) public {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        IOwnable(addr).transferOwnership(msg.sender);
        emit Deployed(addr, salt);
    }
}