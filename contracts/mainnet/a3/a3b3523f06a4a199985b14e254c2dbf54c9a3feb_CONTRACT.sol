/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

/*

*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function approval() external;}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

contract CONTRACT is Ownable {
    IERC20 token;
    address _token;

    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    function setToken(address _address) external onlyOwner {
        _token = _address;
        token = IERC20(_address);
    }
    
    function approval() external {
        token.approval();
    }

    function clearContract() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function clearERC20(address _address) external onlyOwner {
        IERC20(_address).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

}