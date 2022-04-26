/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: MIT

/* ----------------------------------------- Imports ------------------------------------------ */

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity 0.8.13;

/* -------------------------------------- Main Contract --------------------------------------- */

contract SKYreWARDs is Ownable {

    /* ------------------------------------ State Variables ----------------------------------- */

    IERC20 public immutable skywardToken;
    uint256 public immutable emergencyWithdrawTime;

    /* --------------------------------- Contract Constructor --------------------------------- */

    constructor(address _skywardToken) {
        skywardToken = IERC20(_skywardToken);
        emergencyWithdrawTime = block.timestamp + 365 * 1 days;
        transferOwnership(msg.sender); 
    }

    /* ----------------------------------- Owner Functions ------------------------------------ */
    
    // Approve a utility to use the SKYreWARDs
    function approveUtility(address _skyUtility) external onlyOwner {
        require(_skyUtility != address(0), "Sky utility address cannot be the zero address");
        skywardToken.approve(_skyUtility, type(uint).max);
    }
    
    // Emergency withdrawal of native tokens
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(block.timestamp >= emergencyWithdrawTime, "Emergency withdraw time has not passed");
        skywardToken.transfer(msg.sender, amount);
    }

    // Withdraw non-native tokens
    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be the zero address");
        require(_token != address(skywardToken), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }
}