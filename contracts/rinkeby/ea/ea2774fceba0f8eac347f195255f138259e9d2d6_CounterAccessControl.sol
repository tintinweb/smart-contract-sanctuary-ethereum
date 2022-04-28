/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

pragma solidity 0.8.13;

contract CounterAccessControl {

        address private _module = address(0);

        constructor(address payable safe_module) {
            require(safe_module!= address(0), "invalid module address");
            _module = safe_module;
        }

        function module() public view virtual returns (address) {
            return _module;
        }

        modifier onlyModule() {
            require(module() == msg.sender, "Caller is not the module");
            _;
        }


        function increment_0xd09de08a(bytes32 role) external view onlyModule returns (bool) {
            return false;
        }

}