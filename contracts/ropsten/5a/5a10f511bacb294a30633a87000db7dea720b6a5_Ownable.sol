/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-22
*/

// SPDX-License-Identifier: Unlicensed

// Smart Contract Code Developed BY: ISAIAH FADAK

//         🅳🅴🆅🅴🅻🅾🅿🅴🅳  🅱🆈

//       🅸🆂🅰🅸🅰🅷         🅵🅰🅳🅰🅺
// Telegram Group: https://t.me/safu_trendz
// Telegram Channel: https://t.me/safu_trendzans
// Twitter: https://twitter.com/safu_trendz
// website: www.safutrendz.com

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}