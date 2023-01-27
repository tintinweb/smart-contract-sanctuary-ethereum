/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


error TransferFailed();

interface WETH {
    function withdraw(uint wad) external;
    function transferFrom(address src, address dst, uint wad) external returns(bool);
} 

contract BinanceTransfer {
    address constant internal WETHADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    WETH constant internal weth = WETH(WETHADDRESS);

    address private binance;
    address immutable private owner;
    address private sender;

    constructor(address _binance, address _sender){
        binance = _binance;
        sender = _sender;
        owner = msg.sender;
    }

    function transferToBinance(uint amount) external payable{
        require(msg.sender == sender);

        weth.transferFrom(owner, address(this), amount);
        weth.withdraw(amount);


        (bool success, ) = payable(binance).call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    function setBinance(address _binance) external {
        require(msg.sender == owner);
        binance = _binance;
    }

    function setSender(address _sender) external {
        require(msg.sender == owner);
        sender = _sender;
    }


}