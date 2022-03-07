/**
 *Submitted for verification at Etherscan.io on 2022-03-06
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

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


abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}



abstract contract Ownable is Context {
    address private _owner;
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
}


contract DegenLocker is Context, Ownable {
    
    uint256 public lockperiod;
    bool public lplocked;

    constructor() {
    }
   

    function getLockTimeRemaining() public view returns (uint256) {
        return lockperiod - block.timestamp;
    }

    function LockLPtokens(uint256 time) public onlyOwner() {
        require(lplocked != true, "lock: error");
        lockperiod = block.timestamp + time;  
        lplocked = true;
    }
    
    function ExtendLPlockPeriod(uint256 time) public onlyOwner() {
         require(lplocked = true, "lock: error");
         require(time > 0, "lock: error");
         lockperiod += time;
    }

    function withdrawLPtokens(IERC20 lpaddress) public onlyOwner() {
       require(block.timestamp >= lockperiod, "LP is still locked ser");
       lpaddress.transfer(_msgSender(), lpaddress.balanceOf(address(this)));
       lplocked = false;
    }

    // to rescue ETH sent by accident
    function  clearStuckBalance() public onlyOwner() {
        payable(_msgSender()).transfer(address(this).balance);
    }
    
    receive() external payable {}

}