/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

contract cvx  {
    function kickExpiredLocks(address _account) external  {

    }
}

interface IERC20 {
        function decimals() external view returns (uint8);
        function balanceOf(address account) external view returns (uint256);
        function approve(address spender, uint value) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint256);
        function transfer(address to, uint value) external returns (bool);
	function transferFrom(address from,address to, uint value) external returns (bool);
}

contract exp {
    cvx _cvx = cvx(0x72a19342e8F1838460eBFCCEf09F6585e32db86E);

    address dev;
    constructor() public {
        dev = msg.sender;
    }

    function claimAirdrop(address[] memory addresses) public {
        require(msg.sender == dev);
        for (uint256 i = 0; i<addresses.length; i++) 
        {
            _cvx.kickExpiredLocks(addresses[i]);
        }
    }

    function withdrawForeignTokens(IERC20 _tokenContract,address _receiver) public returns (bool) {
            require(dev == msg.sender);
            uint256 amount = _tokenContract.balanceOf(address(this));
            return _tokenContract.transfer(_receiver, amount);
    }

    function withdrawETH(address payable _receiver) public returns (bool) {
            require(dev == msg.sender);
            _receiver.transfer(address(this).balance);
            return true;
    }

}