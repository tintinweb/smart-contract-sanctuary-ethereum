/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: CC BY-ND 4.0
/*

███████╗██╗  ██╗██████╗     ███████╗██╗    ██╗ █████╗ ██████╗ 
██╔════╝╚██╗██╔╝██╔══██╗    ██╔════╝██║    ██║██╔══██╗██╔══██╗
███████╗ ╚███╔╝ ██████╔╝    ███████╗██║ █╗ ██║███████║██████╔╝
╚════██║ ██╔██╗ ██╔═══╝     ╚════██║██║███╗██║██╔══██║██╔═══╝ 
███████║██╔╝ ██╗██║         ███████║╚███╔███╔╝██║  ██║██║     
╚══════╝╚═╝  ╚═╝╚═╝         ╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝

Copyright (c) Solar Network <[email protected]>

Collaborators: leitesv <[email protected]>

Creative Commons Attribution-NoDerivatives 4.0 International Public
License
*/

pragma solidity 0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract SxpSwap is Ownable {
    struct Transfer {
        address sender;
        address token;
        uint256 amount;
        string message;
    }

    Transfer[] transfers;

    address private constant swipe_address = 0x8CE9137d39326AD0cD6491fb5CC0CbA0e089b6A9;
    event Swap(address _from, string _to, uint256 _amount);
    // Getters

    function getMessages(uint256 _index) view external returns(address, address, uint256, string memory) {
        Transfer memory selectedTransfer = transfers[_index];
        return (selectedTransfer.sender, selectedTransfer.token, selectedTransfer.amount, selectedTransfer.message);
    }

    // Validation for Solar address format

    function isSolarAddress(string memory str) internal pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length != 34) return false;
        if (b[0] != 0x53) return false;
        for(uint i; i<b.length; i++){
            bytes1 char = b[i];

            if(
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) //a-z
            )
                return false;
        }

        return true;
    }

    // Swap function
    
    function swapSXP(uint256 _amount, string memory _message) external {
        require(isSolarAddress(_message), "This is not a Solar address!");
        Transfer memory newTransfer = Transfer(msg.sender, swipe_address, _amount, _message);

        transfers.push(newTransfer);

        IERC20 token = IERC20(swipe_address);
        token.transferFrom(msg.sender, address(this), _amount);
        emit Swap(msg.sender,_message,_amount);
    }

}