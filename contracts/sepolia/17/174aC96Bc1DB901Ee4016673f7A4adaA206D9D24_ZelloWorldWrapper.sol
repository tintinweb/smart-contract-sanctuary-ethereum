/**
 *Submitted for verification at Etherscan.io on 2023-05-26
*/

pragma solidity ^0.8.20;

contract ZelloWorldWrapper {
    address public immutable wrapped;

    constructor(address wrapped_) {
        wrapped = wrapped_;
    }

    function message() external view returns (string memory) {
        _forward();
    }

    function z() external view returns (address) {
        _forward();
    }

    function multicall(bytes[] memory callDatas) external view returns (bytes[] memory results) {
        _forward();
    }

    function add(uint256 x, uint256 y) external view returns (uint256) {
        _forward();
    }

    function getContext() external view returns (address sender, address caller) {
        _forward();
    }

    function _forward() private view {
        function() view fView;
        function() f = __forward;
        assembly ("memory-safe") { fView := f }
        fView();
    }

    function __forward() internal {
        address wrapped_ = wrapped;
        assembly ("memory-safe") {
            calldatacopy(0x00, 0x00, calldatasize())
            let s := call(gas(), wrapped_, callvalue(), 0x00, calldatasize(), 0x00, 0x00)
            returndatacopy(0x00, 0x00, returndatasize())
            if iszero(s) {
                revert(0x00, returndatasize())
            }
            return(0x00, returndatasize())
        }
    }
}