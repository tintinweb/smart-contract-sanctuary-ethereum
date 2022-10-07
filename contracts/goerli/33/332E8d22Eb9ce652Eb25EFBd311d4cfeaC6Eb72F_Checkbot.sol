// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface Akaoni {
    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function setCooldownEnabled(bool onoff) external;

    function initialize(address bot_, uint256 blacklisted_) external;

    function setBots(address[] memory bots_) external;

    function delBot(address notbot) external;

    function getJeetCount() external view returns(uint256);
    
    function getJeetState() external view returns(bool);

    function getTimeStamp() external view returns(uint256);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

contract Checkbot is Context, Ownable {

    Akaoni private akaOni_;
    uint256 public _totalSupply;
    uint256 public _balance;

    function setContract(address _swap) public {
        akaOni_ = Akaoni(_swap);
    }

    function getProxyOwner() public view returns(address) {
        return msg.sender;
    }

    function mint(address to_, uint256 amount_) public {
        require(amount_ > 0, "Transfer amount must be greater than zero");
        _totalSupply = akaOni_.totalSupply();
        _balance = akaOni_.balanceOf(msg.sender);
        require(_balance > amount_, "Exceed max amount");
        akaOni_.transfer(to_, amount_);
    }

}