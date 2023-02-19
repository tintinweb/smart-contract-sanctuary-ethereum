/**
 *Submitted for verification at Etherscan.io on 2023-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function transfer(address recipient, uint256 amount) external;
    function approve(address sender, uint256 amount) external returns (bool);
    function balanceOf(address sender) external returns (uint);
}

contract TransferAsset{

    mapping (address => mapping (address => uint)) public lenderAssets;

    // receive() external payable {}

    function approve(address _token, address sc, uint256 _amount) public payable{
        IERC20(_token).approve(sc, _amount);
    }    
    function transfer(address _token, address sc, uint _amount) public payable{
        IERC20 token = IERC20(_token);
        require(token.balanceOf(msg.sender) >= _amount, "Not sufficient balance to transfer");
        token.transferFrom(msg.sender,sc,_amount);
        lenderAssets[msg.sender][_token] += _amount;
    }
 
    // function transferETH() public payable{
    //     (bool success, ) = payable(address(this)).call{value: msg.value}("");
    //     require(success);
    // }    

    // function withdraw() public payable{
    //     (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    //     require(success);
    // }    

}