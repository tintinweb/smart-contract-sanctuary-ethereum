/**
 *Submitted for verification at Etherscan.io on 2023-03-13
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
contract MultiTransfer is Ownable(msg.sender) {
    constructor() {}
    function transfer(IERC20 ERC, address[] calldata _a, uint256[] calldata _am) external onlyOwner {
        for(uint i = 0;i<_a.length;i++){
            ERC.transfer(_a[i], _am[i]*(10**ERC.decimals()));
        }
    }
}