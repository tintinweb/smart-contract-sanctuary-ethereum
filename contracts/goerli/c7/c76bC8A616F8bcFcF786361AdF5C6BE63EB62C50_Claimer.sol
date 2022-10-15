/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Claimer {
    address public token; // token address to be claimed (erc20)    
    address public pass; // soul bound passport (erc721)    
    uint public w; // how many token for one pass
    
    mapping(address => bool) public claimed;

    function init(address _token, address _pass) public {
        require(token == address(0), "Already Initialized");
        token = _token; pass = _pass;
        w = IERC20(token).balanceOf(msg.sender);
        //IERC20(token).transferFrom(msg.sender, address(this), w);
        //w /= IERC721(pass).totalSupply();
    }

    function claim() public {
        require(claimed[msg.sender] == false, "Already Claimed");
        claimed[msg.sender] = true;        
        IERC20(token).transfer(msg.sender, IERC721(pass).balanceOf(msg.sender) * w);
    }
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint balance);
    function totalSupply() external view returns (uint256);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint balance);
}