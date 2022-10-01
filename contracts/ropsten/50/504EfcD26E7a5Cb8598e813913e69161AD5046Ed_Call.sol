// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICallMe {
    function get() external view returns(uint256);
    function change(address _CallAddress, uint256 _value) external;
}

contract Call {

    address public CallAddress;
    address public CallMeAddress;
    uint256 public storedValue;

    function setCallAddress(address _CallAddress) public {
        CallAddress = _CallAddress;
    }

    function setCallMeAddress(address _CallMeAddress) public {
        CallMeAddress = _CallMeAddress;
    }

    function writeContract(uint256 _value) public {
        ICallMe(CallMeAddress).change(CallAddress, _value);
    }

    function readContract() public view returns(uint256) {
        uint256 _value;
        _value = ICallMe(CallMeAddress).get();
        return _value;
    }

    function storeValue() public {
        storedValue = ICallMe(CallMeAddress).get();
    }

}