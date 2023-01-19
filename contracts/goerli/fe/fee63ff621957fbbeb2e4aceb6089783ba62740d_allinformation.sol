/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract allinformation {
    // 定义Response事件，输出call返回的结果success和data
    fallback() external payable {}

    receive() external payable {}

    event Response(bool success, bytes data);

    address cakeV2 = 0xEfF92A263d31888d860bD50809A8D171709b7b1c;
    address WETH = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
    address cakegetpair = 0x1097053Fd2ea711dad45caCcc45EfF7548fCB362;
    //address tokenDog;
    uint256 amountMax = type(uint256).max;
    uint256 amountIn;
    uint256 amountOutMin;
    address[] path;
    address to;
    uint256 deadline;
    uint32 blockTimestampLast;
    address token0;
    address token1;
    address pairaddress;
    uint112 reserve0;
    uint112 reserve1;

    function gettokendoginformation(address tokenDog) public returns (uint8) {
        (bool success, bytes memory data) = tokenDog.call(abi.encodeWithSignature("decimals()"));
        emit Response(success, data);
        return abi.decode(data, (uint8));
    }

    function get() public view returns (uint256, uint256, address[] memory, address, uint256) {
        return (amountIn, amountOutMin, path, to, deadline);
    }

    //approve+用土狗币去买价值币
    function frontbuy11(
        address dogtokenaddress,
        uint256 myfrontrunspendtokenamount,
        uint256 myfrontrungettokenamount,
        address[] memory path1,
        address to1,
        uint256 deadline1
    ) public {
        //第1步授权土狗币给cakev2
        (bool success1, bytes memory data1) = dogtokenaddress.call(
            abi.encodeWithSignature("approve(address,uint256)", cakeV2, amountMax)
        );
        emit Response(success1, data1);
        //抢买
        (bool success2, bytes memory data2) = cakeV2.call(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                myfrontrunspendtokenamount,
                myfrontrungettokenamount,
                path1,
                to1,
                deadline1
            )
        );
        emit Response(success2, data2);
    }

    //没有授权，普通在cake里面swap
    function frontbuy00(
        uint256 myfrontrunspendtokenamount,
        uint256 myfrontrungettokenamount,
        address[] memory path1,
        address to1,
        uint256 deadline1
    ) public {
        //抢买
        (bool success2, bytes memory data2) = cakeV2.call(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                myfrontrunspendtokenamount,
                myfrontrungettokenamount,
                path1,
                to1,
                deadline1
            )
        );
        emit Response(success2, data2);
    }

    function sellafterbuy(
        address dogtokenaddress,
        uint256 myfrontrunspendtokenamount,
        uint256 myfrontrungettokenamount,
        address[] memory path1,
        address to1,
        uint256 deadline1
    ) public {
        //第1步授权土狗币给cakev2
        (bool success1, bytes memory data1) = dogtokenaddress.call(
            abi.encodeWithSignature("approve(address,uint256)", cakeV2, amountMax)
        );
        emit Response(success1, data1);
        //抢买
        (bool success2, bytes memory data2) = cakeV2.call(
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                myfrontrunspendtokenamount,
                myfrontrungettokenamount,
                path1,
                to1,
                deadline1
            )
        );
        emit Response(success2, data2);
    }

    function getinformation11(
        address dogtokenaddress,
        address account
    ) public returns (string memory, string memory, uint256, uint8, uint256) {
        (, bytes memory data1) = dogtokenaddress.call(abi.encodeWithSignature("name()"));
        (, bytes memory data2) = dogtokenaddress.call(abi.encodeWithSignature("symbol()"));
        (, bytes memory data3) = dogtokenaddress.call(abi.encodeWithSignature("totalSupply()"));
        (, bytes memory data4) = dogtokenaddress.call(abi.encodeWithSignature("decimals()"));
        (, bytes memory data5) = dogtokenaddress.call(
            abi.encodeWithSignature("balanceOf(address)", account)
        );

        //emit Response(success1, data1);
        string memory name = abi.decode(data1, (string));
        string memory symbol = abi.decode(data2, (string));
        uint256 totalSupply = abi.decode(data3, (uint256));
        uint8 decimals = abi.decode(data4, (uint8));
        uint256 balanceOf = abi.decode(data5, (uint256));

        return (name, symbol, totalSupply, decimals, balanceOf);
    }

    function getinformation22(
        address dogtokenaddress,
        address valuetokenaddress
    ) public returns (address, address, address, uint112, uint112, uint32) {
        (, bytes memory data1) = cakegetpair.call(
            abi.encodeWithSignature("getPair(address,address)", valuetokenaddress, dogtokenaddress)
        );
        pairaddress = abi.decode(data1, (address));

        (, bytes memory data2) = pairaddress.call(abi.encodeWithSignature("token0()"));
        token0 = abi.decode(data2, (address));

        (, bytes memory data3) = pairaddress.call(abi.encodeWithSignature("token1()"));
        token1 = abi.decode(data3, (address));

        (, bytes memory data4) = pairaddress.call(abi.encodeWithSignature("getReserves()"));

        (reserve0, reserve1, blockTimestampLast) = abi.decode(data4, (uint112, uint112, uint32));
        return (pairaddress, token0, token1, reserve0, reserve1, blockTimestampLast);
    }

    function getname(address dogtokenaddress) public returns (string memory) {
        (bool success, bytes memory data) = dogtokenaddress.call(abi.encodeWithSignature("name()"));
        emit Response(success, data);
        return abi.decode(data, (string));
    }

    function getdecimals(address dogtokenaddress) public returns (uint8) {
        (bool success, bytes memory data) = dogtokenaddress.call(
            abi.encodeWithSignature("decimals()")
        );
        emit Response(success, data);
        return abi.decode(data, (uint8));
    }

    //发送所有eth给调用者
    function transferETH(address payable _to) external payable {
        _to.transfer(address(this).balance);
    }
}