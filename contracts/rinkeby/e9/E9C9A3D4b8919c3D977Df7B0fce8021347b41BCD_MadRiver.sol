/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface ERC20Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MadRiver {
    // ERC20Token public TetherToken;
    // ERC20Token public USDCoin;

    struct Transaction {
        address payable recipient;
        uint amount;
        string coinType;
        address token_address;
    }

    // constructor() {
    //     TetherToken = ERC20Token(0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD);
    //     USDCoin = ERC20Token(0xeb8f08a975Ab53E34D8a0330E0D34de942C95926);
    // }

    function batchTransaction(Transaction[] memory transactions) public payable {
        for(uint i = 0; i < transactions.length; i++) {
            if(keccak256(abi.encodePacked(transactions[i].coinType)) == keccak256(abi.encodePacked("ETH"))) {
                transactions[i].recipient.transfer(transactions[i].amount);
            } else {
                ERC20Token(transactions[i].token_address).transferFrom(msg.sender, transactions[i].recipient, transactions[i].amount);
                // USDCoin.transferFrom(msg.sender, transactions[i].recipient, transactions[i].amount);
            }
        }
    }

}