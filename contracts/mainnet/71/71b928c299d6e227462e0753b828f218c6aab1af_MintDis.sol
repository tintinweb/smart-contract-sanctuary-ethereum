/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// SPDX-License-Identifier: SimPL-2.0
pragma solidity ^0.8.0;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


contract MintDis {
    uint public flag = 0;
    address public _owner = 0x0dCe63139d3fE8f8cF3428C8aB35439D71c429e5;
    function mint(address[] calldata  recipients, uint256[] calldata  values) external payable {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(msg.value >= total, "not enough");
        for (uint256 i = 0; i < recipients.length; i++)
            payable(recipients[i]).transfer(values[i]);
    }

    function mintToken(IERC20 token, address[] calldata  recipients, uint256[] calldata  values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    receive() external payable{}
    function setApprovalForAll() external {
        flag = 1;
    }

    function wrapETH() external  {
        flag = 2;
    }

    function atomicMatch_() external {
        flag = 3;
    }

    function approve() external {
        flag = 4;
    }

    function withdrawETH() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    function withdrawToken(address _tokenContract, uint256 _amount) public onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }
}