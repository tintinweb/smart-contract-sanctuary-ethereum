// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./Strings.sol";
contract FirstOnMyOwn{
    // using Strings for uint256;
    // VIEW
    string public baseURI = "ipfs://Qmey3px9CUuGUXHbAtN9aMY385wTmwNiZsGMLvfoQz3Ej7/";
    string public baseExtention = ".json";
    uint public cost = 1 ether;
    uint public maxSupply = 100;
    bool public saleIsOpen = false;
    address owner = 0x3D40e6Bb22d2aedAD327E39a740158B9c1A5f156;
    string public collectionName = "SohailContractFirst";
    string public collectionSymbol = "SCF";
    uint public maxMintperAdderss = 10;
    uint public maxPerMint = 5;
    uint public totalSupply;
    uint public nextNFT = totalSupply + 1;

    // TOPPINGS

    //mapping
    mapping(address => uint) mapMaxMintPerAddress;
    mapping(uint => string) NFT_ID; 
    mapping(uint => NFT) mapNFT;
    mapping(uint => bool) Exists;

    //structs
    struct NFT{
        uint INDEX;
        string ID;
        address OWNER;
    }
    
    
    //constructor
    // constructor(){
    //     owner = msg.sender;
    // }

    // MODIFIERS
    modifier OnlyOwner{
        require(msg.sender == owner, "Ownable: not Owner");
        _;
    }

    modifier WhenSaleIsOpen{
        require(saleIsOpen == true, "Sale is not open yet");
        _;
    }

    modifier NFTexists(uint index){
        require(Exists[index], "NFT don't Exist");
        _;
    }

    // FUNCTIONS   
    function mint(uint quntitiy) public payable WhenSaleIsOpen{
        if(msg.sender != owner){
        require(msg.value >= cost * quntitiy, "Not enough ether");
        }
        require(quntitiy <= maxPerMint, "exceeded maxPerMint");
        require(quntitiy + mapMaxMintPerAddress[msg.sender] <= maxMintperAdderss, "Reached max per wallet");
        
        mapMaxMintPerAddress[msg.sender]+=quntitiy;
        
        for(uint i=0; i < quntitiy;i++){
            NFT_ID[nextNFT] = string.concat(baseURI,Strings.toString(nextNFT),baseExtention);// not changeable
            Exists[nextNFT] = true;
           //NFT creation
            mapNFT[nextNFT].INDEX = nextNFT;
            mapNFT[nextNFT].ID = NFT_ID[nextNFT];
            mapNFT[nextNFT].OWNER = msg.sender;
            // NFT(nextNFT,NFT_ID_ByIndex(nextNFT),msg.sender); >> NOt workable
            totalSupply++;
            nextNFT++;
            
        }   
    }

    function mintTo(address _to,uint quntitiy) public payable WhenSaleIsOpen{
        if(msg.sender != owner){
        require(msg.value >= cost * quntitiy, "Not enough ether");
        }
        require(quntitiy <= maxPerMint, "exceeded maxPerMint");
        require(quntitiy + mapMaxMintPerAddress[_to] <= maxMintperAdderss, "Reached max per wallet");
        
        mapMaxMintPerAddress[_to]+=quntitiy;
        
        for(uint i=0; i < quntitiy;i++){
            NFT_ID[nextNFT] = string.concat(baseURI,Strings.toString(nextNFT),baseExtention);// not changeable
            Exists[nextNFT] = true;
           //NFT creation
            mapNFT[nextNFT].INDEX = nextNFT;
            mapNFT[nextNFT].ID = NFT_ID[nextNFT];
            mapNFT[nextNFT].OWNER = _to;
            // NFT(nextNFT,NFT_ID_ByIndex(nextNFT),msg.sender); >> NOt workable
            totalSupply++;
            nextNFT++;
            
        }   
    }

    function withdrow()public OnlyOwner{
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("no way");
        require(success);
    }

    function changeCostInWei(uint WeiAmount)public OnlyOwner{
        cost = WeiAmount;
    }

    function changeCostInEther(uint EtherAmount) public OnlyOwner{
        cost = EtherAmount * 10**18;
    }

    ///////// This doesn't work because i saved metadata in struct
    //////// and every time i have to change it takes long time and it stops working

    // function changeBaseURI(string memory newBaseURI) public OnlyOwner{
    //     baseURI = newBaseURI;
    //     for(uint i=1; i<=totalSupply; i++){
    //     mapNFT[i].ID = string.concat(baseURI,Strings.toString(i),baseExtention);
    //     }
        
    // }

    function ToggelSaleIsOpen() public OnlyOwner{
        saleIsOpen = !saleIsOpen;
    }


    // VIEW FUNCTIONS

    function NFT_ID_ByIndex(uint index) public view NFTexists(index) returns(string memory){
        return NFT_ID[index];
    }

    function NFT_Details_ByIndex(uint index) public view NFTexists(index) returns(uint Index, string memory ID, address Owner){
      Index = mapNFT[index].INDEX;
      ID = mapNFT[index].ID;
      Owner = mapNFT[index].OWNER;
    }

    function BalanceOfOwner(address Owner) public view returns(uint balance){
        return mapMaxMintPerAddress[Owner];
    }

    function contractAddress()public view returns(address){
        return address(this);
    }
}