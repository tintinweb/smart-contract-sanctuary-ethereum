/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity ^0.5.16;

interface IWETH9 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    //receive() external payable;
    function deposit() external payable;
    function withdraw(uint wad) external;
    function totalSupply() external view returns (uint);
    function approve(address guy, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}

contract WETHCaller {
    address public WETHAddress = 0xC7ad2519952c61945c59D11a97121f8DF5957C3E;
    //IWETH9 WETH = IWETH9(WETHAddress);
        //WETH.deposit.value(amount)();
        //require(WETH.deposit.value(amount)(), "WETH deposit failed");
        //WETHAddress.call({value: amount})(abi.encodeWithSignature("deposit()"));
        //require(false, "hello");
        //require(WETH.totalSupply() >= 0, "cant call weth");
        //address payable weth = address(uint160(WETHAddress));
        //weth.transfer(amount);
        //bytes memory data = abi.encodeWithSignature("deposit()");
        //WETHAddress.call.value(amount).gas(27938)(abi.encodeWithSignature("deposit()"));
        //invoke(WETHAddress, data);
    function mintWETH1() external payable {
        (bool success, ) = WETHAddress.call.value(msg.value).gas(27938)(abi.encodeWithSignature("deposit()"));
    }
}