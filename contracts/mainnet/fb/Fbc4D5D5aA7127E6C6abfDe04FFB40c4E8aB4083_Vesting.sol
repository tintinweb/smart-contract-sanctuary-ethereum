/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

//SPDX-License-Identifier: MIT Licensed
pragma solidity ^0.8.6;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Vesting {
    IERC20 public GaddaFi = IERC20(0x657857f50A6855d6Cf2d9d3F7D62C7b11550E696);
    address public owner = 0x25Ec5bbDFD7f0dD2bb7f172883675C2eDf6Fc81F;

    uint256 public LockedToken;
    uint256 public UnlockTime;
    uint256 public unLockedToken;

    modifier onlyOwner() {
        require(msg.sender == owner, "PRESALE: Not an owner");
        _;
    }

    event LockToken(uint256 indexed _amount);
    event UnLockToken(uint256 indexed _amount);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {}

    // to Lock Tokens

    function LockGaddaFi(uint256 _amount) public {
        GaddaFi.transferFrom(msg.sender, address(this), _amount);
        LockedToken += _amount;
        UnlockTime = block.timestamp + 180 days;
    }

    // to UnLock Tokens
    function UnLockGaddaFi(uint256 _amount) public onlyOwner {
        require(block.timestamp >= UnlockTime, "Time not reached yet");
        GaddaFi.transfer(owner, _amount);
        LockedToken -= _amount;
        unLockedToken += _amount;
    }

    //to change  time
    function changeTime(uint256 _UnlockTime) public onlyOwner {
        UnlockTime = _UnlockTime;
    }

    // transfer ownership
    function changeOwner(address payable _newOwner) external onlyOwner {
        require(
            _newOwner != address(0),
            "_newOwner wallet cannot be address zero"
        );
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }   
}