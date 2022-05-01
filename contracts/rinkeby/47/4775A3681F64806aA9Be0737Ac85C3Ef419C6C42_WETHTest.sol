// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
}
*/

contract WETHTest {

//    IWETH internal immutable WETH;
    address public WETHAddress = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    bytes public data;
    uint256 balance;

    receive() external payable {
        
    }

    function withdraw(address to) public {
        
        (bool success, bytes memory _data) = WETHAddress.call(abi.encodeWithSignature("balanceOf(address)", address(this)));
        require(success, "Call failed");
        data = _data;
        balance = abi.decode(data, (uint256));
        (bool success2,) = WETHAddress.call(abi.encodeWithSignature("transfer(address,uint256)", to, balance));
        require(success2, "Call failed");
    }
    
}