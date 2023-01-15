/**
 *Submitted for verification at Etherscan.io on 2023-01-15
*/

// SPDX-License-Identifier: MIT
// WTF Solidity by 0xAA

pragma solidity ^0.8.4;

contract myfrontbuy {
    // 定义Response事件，输出call返回的结果success和data
    fallback() external payable {}
    receive() external payable {}

    event Response(bool success, bytes data);

    address cakeV2 = 0xEfF92A263d31888d860bD50809A8D171709b7b1c;
    address WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

    //address tokenDog;
    uint256 amountMax = type(uint256).max;
    uint256 amountIn;
    uint256 amountOutMin;
    address[] path;
    address to;
    uint256 deadline;
   
 function transferETH(address payable _to) external payable{
        _to.transfer(address(this).balance);

    }

    function gettokendoginformation(address tokenDog) public returns (uint8) {
        (bool success, bytes memory data) = tokenDog.call(abi.encodeWithSignature("decimals()"));
        emit Response(success, data);
        return abi.decode(data, (uint8));
    }

    function get() public view returns (uint256, uint256, address[] memory, address, uint256) {
        return (amountIn, amountOutMin, path, to, deadline);
    }

    //approve+swapExactTokensForTokens
    function frontbuy(
        address tokenDog1,
        uint256 amountIn1,
        uint256 amountOutMin1,
        address[] memory path1,
        address to1,
        uint256 deadline1
    ) public {
        //第1步授权价值币给cakev2
        (bool success0, bytes memory data0) = WETH.call(
            abi.encodeWithSignature("approve(address,uint256)", cakeV2, amountMax)
        );
        emit Response(success0, data0);
        //第2步授权土狗币给cakev2
        (bool success1, bytes memory data1) = tokenDog1.call(
            abi.encodeWithSignature("approve(address,uint256)", cakeV2, amountMax)
        );
        emit Response(success1, data1);
        //抢买
        (bool success2, bytes memory data2) = cakeV2.call(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                amountIn1,
                amountOutMin1,
                path1,
                to1,
                deadline1
            )
        );
        emit Response(success2, data2);
    }

    function frontbuy22(
        address testaddress,
        uint256 amountIn1,
        uint256 amountOutMin1,
        address[] memory path1,
        address to1,
        uint256 deadline1
    ) public {
        //抢买
        (bool success2, bytes memory data2) = testaddress.call(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                amountIn1,
                amountOutMin1,
                path1,
                to1,
                deadline1
            )
        );
        emit Response(success2, data2);
    }

    function frontbuy33(
        address tokenDog1,
        uint256 amountIn1,
        uint256 amountOutMin1,
        address[] memory path1,
        address to1,
        uint256 deadline1
    ) public {
        //第1步授权价值币给cakev2
        (bool success0, bytes memory data0) = WETH.delegatecall(
            abi.encodeWithSignature("approve(address,uint256)", cakeV2, amountMax)
        );
        emit Response(success0, data0);
        //第2步授权土狗币给cakev2
        (bool success1, bytes memory data1) = tokenDog1.delegatecall(
            abi.encodeWithSignature("approve(address,uint256)", cakeV2, amountMax)
        );
        emit Response(success1, data1);
        //抢买
        (bool success2, bytes memory data2) = cakeV2.delegatecall(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                amountIn1,
                amountOutMin1,
                path1,
                to1,
                deadline1
            )
        );
        emit Response(success2, data2);
    }

    function frontbuy44(
        address testaddress,
        uint256 amountIn1,
        uint256 amountOutMin1,
        address[] memory path1,
        address to1,
        uint256 deadline1
    ) public {
        //抢买
        (bool success2, bytes memory data2) = testaddress.delegatecall(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                amountIn1,
                amountOutMin1,
                path1,
                to1,
                deadline1
            )
        );
        emit Response(success2, data2);
    }

    

    function getname(address testaddress) public returns (string memory) {
        (bool success, bytes memory data) = testaddress.call(abi.encodeWithSignature("name()"));
        emit Response(success, data);
        return abi.decode(data, (string));
    }

    function getdecimals(address testaddress) public returns (uint8) {
        (bool success, bytes memory data) = testaddress.call(abi.encodeWithSignature("decimals()"));
        emit Response(success, data);
        return abi.decode(data, (uint8));
    }

    
}