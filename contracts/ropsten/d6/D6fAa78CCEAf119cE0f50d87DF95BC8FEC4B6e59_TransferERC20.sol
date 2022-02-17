/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract TransferERC20 {
    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));


    function balanceOf(address token) public view returns (uint) {
        return IERC20(token).balanceOf(address(this));
    }

    function transferUsingSelector( address token, address receiver, uint256 amount) public returns (bool) {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, receiver, amount));
        return success;
    }

    function transferUsingInterface( address token, address receiver, uint256 amount) public returns (bool) {
        return IERC20(token).transfer(receiver, amount);
    }

}