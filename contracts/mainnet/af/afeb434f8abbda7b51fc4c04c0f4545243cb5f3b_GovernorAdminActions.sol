/**
 *Submitted for verification at Etherscan.io on 2022-08-02
*/

pragma solidity 0.6.7;

abstract contract GovernorLike {
    function timelock() external virtual view returns (address);
    function _setTimelock(address) external virtual;

}

contract GovernorAdminActions {
    function _setTimelock(address target, address val) external {
        GovernorLike(target)._setTimelock(val);
    }
}