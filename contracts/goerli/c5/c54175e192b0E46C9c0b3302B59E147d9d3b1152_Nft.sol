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

    uint[4] public ratioCommonBoxAddon = [99,159,179,193];
    uint[4] public ratioEpicBoxAddon = [79,139,169,189];  
    uint[4] public ratioLegendaryBoxAddon = [39,79,119,159];

    enum BoxType {
        Common,
        Epic,
        Legendary
    }

    enum NumberAddons{
        Zero,
        One,
        Two,
        Three,
        Four
    }

    event BoxPurchase(string boxType);
    event NftPurchase(uint token_0, uint token_1, uint token_2, address buyer);
    event ChangedProbabilityBox(uint box, uint[4] probability);

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


    function generateRandomNumber() internal view returns (uint256 ramdomNumber){
        return uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.difficulty,
                    block.timestamp
                )
            )
        );
    }


    function generateThreeRandomNumbers() internal view returns (uint256[3] memory randomNumbers){
        randomNumbers[0] = generateRandomNumber();

        randomNumbers[1] = uint256(
            keccak256(
                abi.encodePacked(
                    randomNumbers[0],
                    tokenCounter
                )
            )
        );

        randomNumbers[2] = uint256(
            keccak256(
                abi.encodePacked(
                    randomNumbers[1],
                    owner
                )
            )
        );
        
        return (randomNumbers);
    }


    function generateAddons(BoxType box) internal view returns (uint addon0, uint addon1, uint addon2){
        uint[3] memory randomNumbers = generateThreeRandomNumbers();

        for(uint i=0; i<3; i++){
            randomNumbers[i] %= 200;
        }

        uint[4] memory probability = boxToProbabilityArray(box); 

        for(uint i=0; i<3; i++){
            randomNumbers[i] = numberToAddon(randomNumbers[i], probability);
        }

        return (randomNumbers[0],randomNumbers[1],randomNumbers[2]);
    }


    function boxToProbabilityArray(BoxType box) public view returns(uint[4] memory probabilityArray){
        require(uint8(box) <= 2);

        if(box == BoxType.Common)
            return ratioCommonBoxAddon;
        else if(box == BoxType.Epic)
            return ratioEpicBoxAddon;
        else
            return ratioLegendaryBoxAddon;
    }


    function numberToAddon(uint randomNumber, uint[4] memory probabilityArray) internal pure returns (uint value){
        
        if(randomNumber>=0 && randomNumber<= probabilityArray[0])
            return 0;
        else if(randomNumber>probabilityArray[0] && randomNumber<=probabilityArray[1])
            return 1;
        else if(randomNumber>probabilityArray[1] && randomNumber<=probabilityArray[2])
            return 2;
        else if(randomNumber>probabilityArray[2] && randomNumber<=probabilityArray[3])
            return 3;
        else
            return 4;
    }

    
    function setProbabilityArray(uint probabilityArray ,uint[4] memory newProbabilityArray) external onlyOwner {
        
        require((newProbabilityArray[0]>0 && newProbabilityArray[0]<199)&&
            (newProbabilityArray[1]>0 && newProbabilityArray[1]<199)&&
            (newProbabilityArray[2]>0 && newProbabilityArray[2]<199)&&
            (newProbabilityArray[3]>0 && newProbabilityArray[3]<199),"Out of range [1-198]");

        require((newProbabilityArray[0]<newProbabilityArray[1])&&
            (newProbabilityArray[1]<newProbabilityArray[2])&&
            (newProbabilityArray[2]<newProbabilityArray[3]),"Must be in Ascending Order - Not Repeated");

        if(probabilityArray == 0)
            ratioCommonBoxAddon = newProbabilityArray;
        else if(probabilityArray == 1)
            ratioEpicBoxAddon = newProbabilityArray;
        else if(probabilityArray == 2)
            ratioLegendaryBoxAddon = newProbabilityArray;

        emit ChangedProbabilityBox(probabilityArray, newProbabilityArray);
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