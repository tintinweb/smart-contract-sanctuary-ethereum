// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WETHCaller {
    address public WETHAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public WETHTest = 0x4775A3681F64806aA9Be0737Ac85C3Ef419C6C42;
    bytes data;

    receive() external payable {
        
    }

    function WETHCallerTest1() public {
        // payable(WETHAddress).transfer(200000000000000000);
        (bool success, bytes memory _data)= WETHAddress.call{value: 100}(abi.encodeWithSignature("deposit()"));
        data = _data;
        require(success, "weth transfer 1 failed");
    }

    function WETHCallerTest2() public {
        payable(WETHAddress).transfer(200000000000000000);

        (bool success, bytes memory _data) = WETHAddress.call(abi.encodeWithSignature("transfer(address,uint256)", WETHTest, 200000000000000000));
        data = _data;
        require(success, "weth transfer 1 failed");
    }

    function WETHCallerTest3() public {
        payable(WETHAddress).transfer(200000000000000000);

        (bool success, bytes memory _data) = WETHAddress.call(abi.encodeWithSignature("transfer(address,uint256)", WETHTest, 200000000000000000));
        data = _data;
        require(success, "weth transfer 1 failed");

        (bool success2, bytes memory _data2) = WETHTest.call(abi.encodeWithSignature("withdraw(address)", address(this)));
        data = _data2;
        require(success2, "weth transfer 2 failed");

    }

    function WETHCallerTest4() public {
        payable(WETHAddress).transfer(200000000000000000);

        (bool success, bytes memory _data) = WETHAddress.call(abi.encodeWithSignature("transfer(address,uint256)", WETHTest, 200000000000000000));
        data = _data;
        require(success, "weth transfer 1 failed");

        (bool success2, bytes memory _data2) = WETHTest.call(abi.encodeWithSignature("withdraw(address)", address(this)));
        data = _data2;
        require(success2, "weth transfer 2 failed");

        (bool success3, bytes memory _data3) = WETHAddress.call(abi.encodeWithSignature("withdraw(uint256)", 200000000000000000));
        data = _data3;
        require(success3, "weth transfer 3 failed");
    }
}