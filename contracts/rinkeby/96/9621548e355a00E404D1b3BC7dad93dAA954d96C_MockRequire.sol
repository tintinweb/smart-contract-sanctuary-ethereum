//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

contract MockRequire {
    uint8 private _mockUint8 = 8;
    uint256 private _mockUint256 = 188;
    uint8 private _mockCall = 8;
    bool private _mockBool = true;
    bytes32 private _mockBytes32 = "";
    address private _mockAddress;
    bytes private _mockBytes;

    function mockView() external view returns (uint8) {
        return _mockUint8;
    }

    function mockView(uint8 a) external view returns (uint8) {
        return _mockUint8 + a;
    }

    function mockView(bool a) external view returns (bool) {
        return a || _mockBool;
    }

    function mockTwoView() external view returns (uint8, uint256) {
        return (_mockUint8, _mockUint256);
    }

    function mockTwoView(uint8 a) external view returns (uint8, uint256) {
        return (_mockUint8 + a, _mockUint256 + a);
    }

    function mockView(address a) external view returns (address) {
        if (a != msg.sender) {
            return a;
        }
        return _mockAddress;
    }

    function mockView(bytes32 a) external view returns (bytes32) {
        if (a != _mockBytes32) {
            return a;
        }
        return _mockBytes32;
    }

    function mockView(bytes memory a) external view returns (bytes memory) {
        if (a.length != _mockBytes.length) {
            return a;
        }
        return _mockBytes;
    }

    function mockView(uint256 a) external view returns (uint256) {
        return a + _mockUint256;
    }

    function mockTwoView(bytes32 a, uint256 b) external view returns (bytes32, uint256) {
        if (b != _mockUint256) {
            return (a, b);
        }

        return (_mockBytes32, _mockUint256);
    }

    function mockPure() external pure returns (uint8) {
        return 1;
    }

    function mockPure(uint8 a) external pure returns (uint8) {
        return a;
    }

    function mockPure(address a) external pure returns (address) {
        return a;
    }

    function mockPureWithReturnB32(bytes32 a) external pure returns (bytes32) {
        return a;
    }

     function mockPure(bytes32 a) external pure returns (bytes32) {
        return a;
    }

    function mockPure(bytes memory a) external pure returns (bytes memory) {
        return a;
    }

    function mockPure(uint256 a) external pure returns (uint256) {
        return a;
    }

    function mockPure(bool a) external pure returns (bool) {
        return a;
    }

    function mockTwoPure(bytes32 a, uint256 b) external pure returns (bytes32, uint256) {
        return (a, b);
    }

    function mockCall() external {
        _mockCall = 0;
    }

    function mockCall(uint8 amount) external {
        _mockCall = amount;
    }

    function mockCall(bool a) external {
        _mockBool = a;
    }

    function mockCall(uint8 amount1, uint256 amount2) external {
        _mockUint8 = amount1;
        _mockUint256 = amount2;
    }

    function mockCallWithReturn() external returns (uint256 a) {
        _mockCall = 0;
        return _mockUint256;
    }

    function mockCallWithReturn(uint8 amount) external returns (uint256 a) {
        _mockCall = amount;
        return _mockUint256;
    }

    function mockCallWithReturnBytes32(bytes32 amount1, uint256 amount) external returns (bytes32 a) {
        _mockUint256 = amount;
        return amount1;
    }

    function mockCallWithReturnUint(uint256 amount) external returns (uint256 a) {
        _mockUint256 = amount;
        return _mockUint256;
    }

    function revertInt8(uint8 amount) external returns (uint8) {
        _mockCall = amount;
        revert("Int8");
    }

    function revertInt256(uint256 amount2) external returns (uint256) {
        _mockUint256 = amount2;
        revert("Int256");
    }

    function revertBytes32(bytes32 mockBytes32) external returns (bytes32) {
        _mockBytes32 = mockBytes32;
        revert("bytes32");
    }

    function revertAccount(address account) external returns (address) {
        _mockAddress = account;
        revert("account");
    }

    function revertBool(bool isSucess) external returns (bool) {
        _mockBool = isSucess;
        revert("Bool");
    }
}