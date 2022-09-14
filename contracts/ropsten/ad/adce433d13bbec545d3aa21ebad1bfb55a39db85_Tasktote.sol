/**
 *Submitted for verification at Etherscan.io on 2022-09-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Pausable is Context {
    /**
     * @dev test.
     */
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Tasktote is Pausable, Ownable {
    event hasBeenAdded(
        address sender,
        address recipient,
        string tastBech32,
        uint256 amount,
        address contractAddress
    );

    address public counast;
    address public lukast;

    constructor(address _counast, address _lukast ) {
        counast = _counast;
        lukast = _lukast;
    }

    function deposit(
        uint256 amount,
        string memory target
    ) public whenNotPaused {
        ERC20Token token = ERC20Token(counast);
        require(token.transferFrom(msg.sender, lukast, amount), "ERC20 token transfer was unsuccessful");
        emit hasBeenAdded(msg.sender, lukast, target, amount, counast);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}