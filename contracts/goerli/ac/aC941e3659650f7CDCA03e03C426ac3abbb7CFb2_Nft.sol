//SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "LinkTokenInterface.sol";

//Adresses
//Mainnet - 0x514910771AF9Ca656af840dff83E8264EcF986CA
//Kovan - 0xa36085F69e2889c224210F603D836748e7dC0088
//Rinkeby - 0x01BE23585060835E02B77ef475b0Cc51aA1e0709
//Goerli - 0x326C977E6efc84E512bB9C30f76E30c160eD06FB

contract Nft {

    address payable public owner;
    address[] public allowedNetworks =[0x514910771AF9Ca656af840dff83E8264EcF986CA, 0x01BE23585060835E02B77ef475b0Cc51aA1e0709,
        0xa36085F69e2889c224210F603D836748e7dC0088,0x326C977E6efc84E512bB9C30f76E30c160eD06FB];

    constructor() payable public {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only allowed to the contract owner");
        _;
    }

    modifier onlyAllowedAddress(address linkContractAddress) {
        require(linkContractAddress==allowedNetworks[0]||linkContractAddress==allowedNetworks[1]||
        linkContractAddress==allowedNetworks[2]||linkContractAddress==allowedNetworks[3],"Only allowed Link contract address");
        _;
    }

    function getBalanceContract(address _addr) public view onlyOwner onlyAllowedAddress(_addr) returns (uint) {
        return LinkTokenInterface(_addr).balanceOf(address(this));
    }

    function transferFundsLink(address _addr) public payable onlyOwner onlyAllowedAddress(_addr) returns (bool){
        return LinkTokenInterface(_addr).transfer(owner,getBalanceContract(_addr));
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}