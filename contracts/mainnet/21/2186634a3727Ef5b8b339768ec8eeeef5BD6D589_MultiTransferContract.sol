/**
 *Submitted for verification at Etherscan.io on 2023-02-18
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

interface IERC20 {
    function decimals() external view returns (uint8);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

abstract contract Ownable {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender) , "!Owner"); _;
    }

    function isOwner(address account) private view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

contract MultiTransferContract is Ownable(msg.sender) {

    constructor() {}

    function transfer(IERC20 token, address[] calldata addresses, uint256[] calldata amounts) external onlyOwner {
        uint256 decimalScalingFactor = 10**token.decimals();
        uint256 amount;
        address airdropee;
        for(uint i = 0;i<addresses.length;i++){
            amount = amounts[i]*decimalScalingFactor;
            airdropee = addresses[i];
            token.transfer(airdropee, amount);
        }
    }
}