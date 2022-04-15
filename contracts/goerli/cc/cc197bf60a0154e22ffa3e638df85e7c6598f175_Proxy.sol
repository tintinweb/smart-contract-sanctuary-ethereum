/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

pragma solidity ^0.4.24;

contract Proxy {
address public owner;
    event Upgraded(address indexed implementation);
    address internal _implementation;

    constructor() public {
      owner = msg.sender;
}

    modifier onlyOwner() {
 require(msg.sender == owner, "Not owner");
 _;
}
    function implementation() public view returns (address) {
        return _implementation;
}

    function upgradeTo(address impl) public onlyOwner {
        require(impl != address(0), "Cannot upgrade to invalid address");
        require(impl != _implementation, "Cannot upgrade to the same implementation");
        _implementation = impl;
        emit Upgraded(impl);
}

    function () external payable {
        address _impl = _implementation;
        require(_impl != address(0), "implementation contract not set");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}