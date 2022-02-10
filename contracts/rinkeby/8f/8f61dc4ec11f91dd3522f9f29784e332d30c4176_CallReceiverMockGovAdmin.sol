// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract CallReceiverMockGovAdmin {
    string public sharedAnswer;

    event MockFunctionCalled(address caller, address callee);

    uint256[] private _array;

    address public governorAdmin;

    constructor(address governorAdmin_) {
        governorAdmin = governorAdmin_;
    }

    modifier onlyGovernorAdmin() {
        require(msg.sender == governorAdmin, "msg.sender not governorAdmin");
        _;
    }

    function setGovernorAdmin(address governorAdmin_) external {
        governorAdmin = governorAdmin_;
    }

    function mockFunction() onlyGovernorAdmin public payable returns (string memory) {
        emit MockFunctionCalled(msg.sender, address(this));

        return "0x1234";
    }

    function mockFunctionNonPayable() onlyGovernorAdmin public returns (string memory) {
        emit MockFunctionCalled(msg.sender, address(this));

        return "0x1234";
    }

    function mockStaticFunction() public pure returns (string memory) {
        return "0x1234";
    }

    function mockFunctionRevertsNoReason() onlyGovernorAdmin public payable {
        revert();
    }

    function mockFunctionRevertsReason() onlyGovernorAdmin public payable {
        revert("CallReceiverMock: reverting");
    }

    function mockFunctionThrows() onlyGovernorAdmin public payable {
        assert(false);
    }

    function mockFunctionOutOfGas() onlyGovernorAdmin public payable {
        for (uint256 i = 0; ; ++i) {
            _array.push(i);
        }
    }

    function mockFunctionWritesStorage() onlyGovernorAdmin public returns (string memory) {
        sharedAnswer = "42";
        return "0x1234";
    }
}