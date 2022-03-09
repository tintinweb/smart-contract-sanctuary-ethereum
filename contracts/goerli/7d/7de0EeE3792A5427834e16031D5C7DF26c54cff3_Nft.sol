//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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

    mapping( uint => address) public tokenToBuyer;
    uint public tokenCounter;
    uint[] public priceBox;

    enum BoxType {
        Common,
        Epic,
        Legendary
    }

    event BoxPurchase(string boxType);
    event NftPurchase(uint token_0, uint token_1, uint token_2, address buyer);

    constructor() payable {
        owner = payable(msg.sender);
        tokenCounter =0;
        priceBox = [ 1 wei, 10 wei, 100 wei];
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

    modifier boxCost(BoxType boxType){
        require(msg.value >= priceBox[uint(boxType)], appendStrings("Insufficient funds to buy the box. Deposit",
         appendStrings(uint2str(priceBox[uint(boxType)]),"wei")) );
        _;
    }

    function getBalanceContract(address _addr) public view onlyOwner onlyAllowedAddress(_addr) returns (uint) {
        return LinkTokenInterface(_addr).balanceOf(address(this));
    }

    function transferFundsLink(address _addr) public payable onlyOwner onlyAllowedAddress(_addr) returns (bool){
        return LinkTokenInterface(_addr).transfer(owner,getBalanceContract(_addr));
    }

    function buyBox(BoxType boxType) external payable boxCost(boxType) returns (uint[3] memory acquiredTokens ) { 
        require(uint8(boxType) <= 2);
        emit BoxPurchase(convertBoxTypeToString(boxType));
        
        acquiredTokens = [tokenCounter, tokenCounter+1, tokenCounter +2];

        for(uint i = 0; i < 3;i++){
            tokenToBuyer[tokenCounter + i] = msg.sender;            
        }

        emit NftPurchase(acquiredTokens[0], acquiredTokens[1], acquiredTokens[2], msg.sender);
        tokenCounter+=3;
        
        return (acquiredTokens);
    }

    function convertBoxTypeToString(BoxType boxType) internal pure returns(string memory){
        
        // Error handling for input
        require(uint8(boxType) <= 2);

        if(boxType == BoxType.Common)
            return "Common";
        else if(boxType == BoxType.Epic)
            return "Epic";
        else
            return "Legendary";
    }


    function appendStrings(string memory a, string memory b) internal pure returns (string memory) {
        string memory space =  "\u0020";
    return string(abi.encodePacked(a,space,b));
    }

    function uint2str(uint _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}