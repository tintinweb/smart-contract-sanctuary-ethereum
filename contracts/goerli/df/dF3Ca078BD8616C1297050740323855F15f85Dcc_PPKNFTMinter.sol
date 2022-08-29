// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// ORIGINALLY: pragma solidity ^0.8.4;

import "hardhat/console.sol";


import "./ERC721A.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";




// interface TheCIGsContract {
//    // Standard ERC20 Functions:
//    function totalSupply() external view returns (uint256);
//    function balanceOf(address account) external view returns (uint256);
//    function transfer(address recipient, uint256 amount) external returns (bool);
//    //  function allowance(address owner, address spender) external view returns (uint256);
//     function approve(address spender, uint256 amount) external returns (bool);
//    //  function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
//    //  event Transfer(address indexed from, address indexed to, uint256 value);
//    //  event Approval(address indexed owner, address indexed spender, uint256 value);
      
//    // Specific CIGs-Contract Functions:
//    function getStats(address _user) external view returns(uint256[] memory, address, bytes32, uint112[] memory);
//    // REMINDER 1: string public constant name = "Cigarette Token";
//    function name() external view returns (string calldata);
//    // REMINDER 2: string public constant symbol = "CIG";
//    function symbol() external view returns (string calldata);
// }




contract PPKNFTMinter is ERC721A, Pausable, Ownable, ReentrancyGuard {
   // Lets me:
   // 1. mass-mint PK's NFTs to all the Gold Mint-Pass (and Silver Pass?) Holders
   // 2. Also let's regular "Public-Sale" type Minter buy PK NFTs

   // Code comes from the original AZUKI Contract....

   // uint256 public immutable maxPerAddressDuringMint;
   // uint256 public immutable amountForDevs;
   // uint256 public immutable amountForAuctionAndDev;


   ///////////////////////////////////////////////////////////
   //
   // CIGs CONTRACT STUFF:
   //
   // Create a reference to the CIGs contract:
   // TheCIGsContract public CIGsContractInstance; 


   // struct SaleConfigStruct {
   //    uint32 auctionSaleStartTime;
   //    uint32 publicSaleStartTime;
   //    uint64 mintlistPrice;
   //    uint64 publicPrice;
   //    uint32 publicSaleKey;
   // }

   // Need a DutchAuctionStartTime
   // Need an Interval after which Price goes down by INCREMENT AMOUNT
   // Need to be able to reset all those variables
   // 

   // SaleConfigStruct public saleConfig;

   using Strings for uint256;
   // Counters.Counter private _tokenIdCounter;


   // This is it baby!!!
   mapping(address => uint256) public goldMPHoldersDictionary;


   address[] public goldMPHolderAddressesArray;

   // Base URI:
   string private baseMetadataURI;

   // Price in ETH: 0.25 ETH
   uint256 public PPKETHPrice = 0.01 ether;
   // Price in CIGs: 0.25 ETH
   uint256 public PPKCIGsPrice = 0.01 ether;   // <<--------- CIGs not ETH!!!


   // EVENTS:
   event BaseURIUpdated(string newlyUpdatedURI);
   event MintPassHoldersArrayUploaded(address[] goldMPHolderAddressesArray);
   event ProductPriceSet(uint newProductPrice);




   constructor() ERC721A("PProduct NFT", "PRDKT", 11, 4595) {
      console.log("\n\n>In the 'PPKNFTMinter' constructor()!!!");

      // CIGsContractInstance = TheCIGsContract(0xCB56b52316041A62B6b5D0583DcE4A8AE7a3C629);
      // Let's now call a function from that Contract:
      // string memory contractName = CIGsContractInstance.name();
      // console.log("\n\n===>>1. contractName = %s", contractName);
      // string memory contractSymbol = CIGsContractInstance.symbol();
      // console.log("===>>2. contractSymbol = %s", contractSymbol);
      // uint256 coinSupply = CIGsContractInstance.totalSupply();
      // console.log("===>>3. coinSupply = %s", coinSupply);


      // amountForAuctionAndDev = amountForAuctionAndDev_;
      // amountForDevs = amountForDevs_;
      // require(amountForAuctionAndDev_ <= collectionSize, "larger collection size needed");
      // require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
      


      baseMetadataURI = "https://fractionalownership.io/Products/JSON/product";
      console.log("\n\n>'baseMetadataURI()' = %s", baseMetadataURI);

      // goldMPHolderAddressesArray = mintPassers;


      console.log("\n\n>NOW LOADING UP THE ARRAY...!");

      // 0-9:
      goldMPHolderAddressesArray.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
      goldMPHolderAddressesArray.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);

      goldMPHolderAddressesArray.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
      goldMPHolderAddressesArray.push(0x90F79bf6EB2c4f870365E785982E1f101E93b906);

      goldMPHolderAddressesArray.push(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
      goldMPHolderAddressesArray.push(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);

      goldMPHolderAddressesArray.push(0x976EA74026E726554dB657fA54763abd0C3a0aa9);
      goldMPHolderAddressesArray.push(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);

      goldMPHolderAddressesArray.push(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
      goldMPHolderAddressesArray.push(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
      
      // console.log("\n\n>'goldMPHolderAddressesArray[0]' = %s", goldMPHolderAddressesArray[4]);

      // 10-19:
      goldMPHolderAddressesArray.push(0xBcd4042DE499D14e55001CcbB24a551F3b954096);
      goldMPHolderAddressesArray.push(0x71bE63f3384f5fb98995898A86B02Fb2426c5788);
      goldMPHolderAddressesArray.push(0xFABB0ac9d68B0B445fB7357272Ff202C5651694a);
      goldMPHolderAddressesArray.push(0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec);
      goldMPHolderAddressesArray.push(0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097);
      goldMPHolderAddressesArray.push(0xcd3B766CCDd6AE721141F452C550Ca635964ce71);
      goldMPHolderAddressesArray.push(0x2546BcD3c84621e976D8185a91A922aE77ECEc30);
      goldMPHolderAddressesArray.push(0xbDA5747bFD65F08deb54cb465eB87D40e51B197E);
      goldMPHolderAddressesArray.push(0xdD2FD4581271e230360230F9337D5c0430Bf44C0);
      goldMPHolderAddressesArray.push(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199);

      // 20-29:
      goldMPHolderAddressesArray.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
      goldMPHolderAddressesArray.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
      goldMPHolderAddressesArray.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
      goldMPHolderAddressesArray.push(0x90F79bf6EB2c4f870365E785982E1f101E93b906);
      goldMPHolderAddressesArray.push(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
      goldMPHolderAddressesArray.push(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
      goldMPHolderAddressesArray.push(0x976EA74026E726554dB657fA54763abd0C3a0aa9);
      goldMPHolderAddressesArray.push(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
      goldMPHolderAddressesArray.push(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
      goldMPHolderAddressesArray.push(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);

      // 30-39:
      goldMPHolderAddressesArray.push(0xBcd4042DE499D14e55001CcbB24a551F3b954096);
      goldMPHolderAddressesArray.push(0x71bE63f3384f5fb98995898A86B02Fb2426c5788);
      goldMPHolderAddressesArray.push(0xFABB0ac9d68B0B445fB7357272Ff202C5651694a);
      goldMPHolderAddressesArray.push(0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec);
      goldMPHolderAddressesArray.push(0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097);
      goldMPHolderAddressesArray.push(0xcd3B766CCDd6AE721141F452C550Ca635964ce71);
      goldMPHolderAddressesArray.push(0x2546BcD3c84621e976D8185a91A922aE77ECEc30);
      goldMPHolderAddressesArray.push(0xbDA5747bFD65F08deb54cb465eB87D40e51B197E);
      goldMPHolderAddressesArray.push(0xdD2FD4581271e230360230F9337D5c0430Bf44C0);
      goldMPHolderAddressesArray.push(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199);

      // 40-49
      goldMPHolderAddressesArray.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
      goldMPHolderAddressesArray.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
      goldMPHolderAddressesArray.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
      goldMPHolderAddressesArray.push(0x90F79bf6EB2c4f870365E785982E1f101E93b906);
      goldMPHolderAddressesArray.push(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
      goldMPHolderAddressesArray.push(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
      goldMPHolderAddressesArray.push(0x976EA74026E726554dB657fA54763abd0C3a0aa9);
      goldMPHolderAddressesArray.push(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
      goldMPHolderAddressesArray.push(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
      goldMPHolderAddressesArray.push(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
      
      // 50-59:
      goldMPHolderAddressesArray.push(0xBcd4042DE499D14e55001CcbB24a551F3b954096);
      goldMPHolderAddressesArray.push(0x71bE63f3384f5fb98995898A86B02Fb2426c5788);
      goldMPHolderAddressesArray.push(0xFABB0ac9d68B0B445fB7357272Ff202C5651694a);
      goldMPHolderAddressesArray.push(0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec);
      goldMPHolderAddressesArray.push(0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097);
      goldMPHolderAddressesArray.push(0xcd3B766CCDd6AE721141F452C550Ca635964ce71);
      goldMPHolderAddressesArray.push(0x2546BcD3c84621e976D8185a91A922aE77ECEc30);
      goldMPHolderAddressesArray.push(0xbDA5747bFD65F08deb54cb465eB87D40e51B197E);
      goldMPHolderAddressesArray.push(0xdD2FD4581271e230360230F9337D5c0430Bf44C0);
      goldMPHolderAddressesArray.push(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199);

      // 60-69:
      goldMPHolderAddressesArray.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
      goldMPHolderAddressesArray.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
      goldMPHolderAddressesArray.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
      goldMPHolderAddressesArray.push(0x90F79bf6EB2c4f870365E785982E1f101E93b906);
      goldMPHolderAddressesArray.push(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
      goldMPHolderAddressesArray.push(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
      goldMPHolderAddressesArray.push(0x976EA74026E726554dB657fA54763abd0C3a0aa9);
      goldMPHolderAddressesArray.push(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
      goldMPHolderAddressesArray.push(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
      goldMPHolderAddressesArray.push(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
      
      // 70-79:
      goldMPHolderAddressesArray.push(0xBcd4042DE499D14e55001CcbB24a551F3b954096);
      goldMPHolderAddressesArray.push(0x71bE63f3384f5fb98995898A86B02Fb2426c5788);
      goldMPHolderAddressesArray.push(0xFABB0ac9d68B0B445fB7357272Ff202C5651694a);
      goldMPHolderAddressesArray.push(0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec);
      goldMPHolderAddressesArray.push(0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097);
      goldMPHolderAddressesArray.push(0xcd3B766CCDd6AE721141F452C550Ca635964ce71);
      goldMPHolderAddressesArray.push(0x2546BcD3c84621e976D8185a91A922aE77ECEc30);
      goldMPHolderAddressesArray.push(0xbDA5747bFD65F08deb54cb465eB87D40e51B197E);
      goldMPHolderAddressesArray.push(0xdD2FD4581271e230360230F9337D5c0430Bf44C0);
      goldMPHolderAddressesArray.push(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199);

      // 80-89:
      goldMPHolderAddressesArray.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
      goldMPHolderAddressesArray.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
      goldMPHolderAddressesArray.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
      goldMPHolderAddressesArray.push(0x90F79bf6EB2c4f870365E785982E1f101E93b906);
      goldMPHolderAddressesArray.push(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
      goldMPHolderAddressesArray.push(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
      goldMPHolderAddressesArray.push(0x976EA74026E726554dB657fA54763abd0C3a0aa9);
      goldMPHolderAddressesArray.push(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
      goldMPHolderAddressesArray.push(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
      goldMPHolderAddressesArray.push(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
      
      // 90-99:
      goldMPHolderAddressesArray.push(0xBcd4042DE499D14e55001CcbB24a551F3b954096);
      goldMPHolderAddressesArray.push(0x71bE63f3384f5fb98995898A86B02Fb2426c5788);
      goldMPHolderAddressesArray.push(0xFABB0ac9d68B0B445fB7357272Ff202C5651694a);
      goldMPHolderAddressesArray.push(0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec);
      goldMPHolderAddressesArray.push(0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097);
      goldMPHolderAddressesArray.push(0xcd3B766CCDd6AE721141F452C550Ca635964ce71);
      goldMPHolderAddressesArray.push(0x2546BcD3c84621e976D8185a91A922aE77ECEc30);
      goldMPHolderAddressesArray.push(0xbDA5747bFD65F08deb54cb465eB87D40e51B197E);
      goldMPHolderAddressesArray.push(0xdD2FD4581271e230360230F9337D5c0430Bf44C0);
      goldMPHolderAddressesArray.push(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199);

      // 100-109:
      goldMPHolderAddressesArray.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
      goldMPHolderAddressesArray.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
      goldMPHolderAddressesArray.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
      goldMPHolderAddressesArray.push(0x90F79bf6EB2c4f870365E785982E1f101E93b906);
      goldMPHolderAddressesArray.push(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
      goldMPHolderAddressesArray.push(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
      goldMPHolderAddressesArray.push(0x976EA74026E726554dB657fA54763abd0C3a0aa9);
      goldMPHolderAddressesArray.push(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
      goldMPHolderAddressesArray.push(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
      goldMPHolderAddressesArray.push(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);

      // 110-119:
      goldMPHolderAddressesArray.push(0xBcd4042DE499D14e55001CcbB24a551F3b954096);
      goldMPHolderAddressesArray.push(0x71bE63f3384f5fb98995898A86B02Fb2426c5788);
      goldMPHolderAddressesArray.push(0xFABB0ac9d68B0B445fB7357272Ff202C5651694a);
      goldMPHolderAddressesArray.push(0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec);
      goldMPHolderAddressesArray.push(0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097);
      goldMPHolderAddressesArray.push(0xcd3B766CCDd6AE721141F452C550Ca635964ce71);
      goldMPHolderAddressesArray.push(0x2546BcD3c84621e976D8185a91A922aE77ECEc30);
      goldMPHolderAddressesArray.push(0xbDA5747bFD65F08deb54cb465eB87D40e51B197E);
      goldMPHolderAddressesArray.push(0xdD2FD4581271e230360230F9337D5c0430Bf44C0);
      goldMPHolderAddressesArray.push(0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199);

      // 120-129:
      goldMPHolderAddressesArray.push(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
      goldMPHolderAddressesArray.push(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
      goldMPHolderAddressesArray.push(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);
      goldMPHolderAddressesArray.push(0x90F79bf6EB2c4f870365E785982E1f101E93b906);
      goldMPHolderAddressesArray.push(0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65);
      goldMPHolderAddressesArray.push(0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc);
      goldMPHolderAddressesArray.push(0x976EA74026E726554dB657fA54763abd0C3a0aa9);
      goldMPHolderAddressesArray.push(0x14dC79964da2C08b23698B3D3cc7Ca32193d9955);
      goldMPHolderAddressesArray.push(0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f);
      goldMPHolderAddressesArray.push(0xa0Ee7A142d267C1f36714E4a8F75612F20a79720);
      
      // 130-134:
      goldMPHolderAddressesArray.push(0xBcd4042DE499D14e55001CcbB24a551F3b954096);
      goldMPHolderAddressesArray.push(0x71bE63f3384f5fb98995898A86B02Fb2426c5788);
      goldMPHolderAddressesArray.push(0xFABB0ac9d68B0B445fB7357272Ff202C5651694a);
      goldMPHolderAddressesArray.push(0x1CBd3b2770909D4e10f157cABC84C7264073C9Ec);
      goldMPHolderAddressesArray.push(0xdF3e18d64BC6A983f673Ab319CCaE4f1a57C7097);
      

      // With 135 GOLD MintPasses - I have to mint 1,485 NFTs
      //
      // 
      // 110 NFTs  --> 10 x 11 = 110
      // ===>>>BATCH Mint 11 NFTs to the first TEN (50) "MintPassHolder" Accounts: 
      // ===>>>CREATE / POPULATE THE "goldMPHoldersDictionary" MAPPING of WINNING GOLD-MINT-PASS BIDDERS/MINTERS:
      // REMINDER: 
      // mapping(address => uint256) public goldMPHoldersDictionary;
    
      for (uint256 i; i < goldMPHolderAddressesArray.length; i++) {
         console.log("\n>CONSTRUCTOR FOR LOOP \n >ADDING Address to 'goldMPHoldersDictionary' MAPPING \n >MINTING to ETH Account # %s, which is: %s \n", i, goldMPHolderAddressesArray[i]);
         // Add address and it's ranking to my MAPPING:
         goldMPHoldersDictionary[goldMPHolderAddressesArray[i]] = i;
         console.log("   >Address # %s is: %s", i, goldMPHolderAddressesArray[i]);
    
         // _safeMint(goldMPHolderAddressesArray[i], 11);
         _safeDeploymentMint(goldMPHolderAddressesArray[i], 11, "");
      }


   }   // END constructor




   // MIGHT STILL NEED THIS HERE BELOW!!!!!
   // 
   //    A function to upload the MintPassHolders ARRAY!!!
   // 

   // function uploadMintpassHolderAddresses(address[] memory mintPassHoldersArray) public onlyOwner() {
   //    console.log("\nIn 'uploadMintpassHolderAddresses()'!!!");

   //    // require(msg.sender == contractOwner, "'uploadSortedBidsIndex()' --> ONLY OWNER ALLOWED TO EXECUTE!");

   //    console.log("\nHere's the array that I uploaded: ");
   //    for(uint counter; counter < mintPassHoldersArray.length; counter++) {
   //       console.log("-Address # %s is: %s", counter, mintPassHoldersArray[counter]);
   //    }

   //    goldMPHolderAddressesArray = mintPassHoldersArray;

   //    console.log("\nAnd for VERIFICATION, here's the 'goldMPHolderAddressesArray' to which I assigned the Array I uploaded: ");
   //    for(uint counter; counter < goldMPHolderAddressesArray.length; counter++) {
   //       console.log("-Address # %s is: %s", counter, goldMPHolderAddressesArray[counter]);
   //    }

   //    emit MintPassHoldersArrayUploaded(goldMPHolderAddressesArray);
   // }



   /*

   During DEPLOYMENT, there's no telling:
   1. How many MintPass-Holder-Addresses I'll be able to pass-in with my Array-Argument
   2. How many NFTs I'll then be able to mint - and to how many of those MintPass-Holder Addresses I'll be able to mint them

   Therefore, I'll need a stand-alone FUNCTION that'll let me
   1. mint an X number of NFTs
   2. to a specific number of those MintPass-Holder Addresses
   3. Will need an INDEX NUMBER for the STARTING ETH-ADDRESS
   4. Will need a specific number of NFTs to mint to each address?
      -OR do I just mint 11 NFTs right off the bat, wherein I know that only 5 will point to
       actual finished Products and the other 6 will point to empty "dummy" JSON's and JPEGs?

   */



   // // OPTIONAL method - for ME, the Contract-Owner
   // // Let's me mint 11 Product NFTs to a series of ETH Addresse - meaning another group of Gold Mint-Pass Holders
   // function mintToMintPassHolders(uint startingETHAddressIndexNum) public onlyOwner() { 
   //    console.log("In 'mintToMintPassHolders()'");

   //    require(goldMPHolderAddressesArray.length > 0, "==>'mintToMintPassHolders()' ERROR! 'goldMPHolderAddressesArray' is EMPTY!");

   //    // My array of MintPassHolders - containing the winning bids from the Auction - will have 135 ETH addresses in it.
   //    // During DEPLOYMENT, if I'm able to mint 11 NFTs to SAY the first 35 ETH Addresses from that Array, it'll
   //    // mean there'll still be 100 other ETH Addresses that will need to have 11 NFTs minted to them.
   //    // -So, I'll need to pass in the INDEX number of the ETH Address from which I want to "pick-up where I left off" - and start
   //    // Minting 11 NFTs to this address - and all subsequent addresses after it, until I reach the end of the Array of MintPass-Holders

   //    // address startingETHAddress = goldMPHolderAddressesArray[startingETHAddressIndexNum];


   //    // Loop through the Array of Gold Mint-Pass Holders, *STARTING AT A SPECIFIC INDEX
   //    // NUMBER* - and  Mint 11 NFTs to each one of them:
   //    for(uint256 ETHAddressCounter = startingETHAddressIndexNum; ETHAddressCounter < goldMPHolderAddressesArray.length; ETHAddressCounter++) {
   //       console.log("\n>OUTER FOR LOOP, minting to ETH Account # %s", ETHAddressCounter);
   //       console.log(">And that ETH address is: %s \n", goldMPHolderAddressesArray[ETHAddressCounter]);
   //       _safeMint(goldMPHolderAddressesArray[startingETHAddressIndexNum], 11);
   //    }

   // }




   // For the PUBLIC SALE: Lets anyone buy ONE NFT in the "regular" way:
   // (had "callerIsUser"...)
   function regularMint() external payable whenNotPaused() {
      console.log("\n>In 'regularMint()'");
   
      require(msg.value >= PPKETHPrice, "'regularMint()' ERROR! Insufficient funds!");

      // WHAT AM I DOING ABOUT COLLECTION-SIZE????  <-------------------------------------------------------------------
      require(totalSupply() + 1 <= collectionSize, "'regularMint()' ERROR! Reached max supply");

      // // SHOULD BE ABLE TO MINT ONLY ONE?????
      // require(numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint, "can not mint this many");
      
      _safeMint(msg.sender, 1);

      // refundIfOver(publicPrice * quantity);
   }


 

   // Actual PERSON as opposed to CONTRACT:
   modifier callerIsUser() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
   }





 
   // function refundIfOver(uint256 price) private {
   //    require(msg.value >= price, "Need to send more ETH.");
   //    if (msg.value > price) {
   //       payable(msg.sender).transfer(msg.value - price);
   //    }
   // }





   // // FREE MINTING - meaning no ETH is required to be sent to this function by the caller. Cause this function is *NOT* "payable"
   // // This LETS ME - the CONTRACT-OWNER (and thus ONLY ME) - MINT AN NFT *WITHOUT PAYING FOR IT*
   // // -This can be used IN THE CONSTRUCTOR, AS A WAY OF QUICKLY MINTING AND ALLOCATING A NUMBER OF NFTS TO A SPECIFIC ADDRESS OR SET OF ADDRESSES.
   // function safeFREEMint(address to) public payable onlyOwner() {
   //    console.log("In 'safeFREEMint()'");

   //    uint256 tokenId = _tokenIdCounter.current(); //  <<====  I could add 500 to this value right here!!!

   //    _tokenIdCounter.increment();
   //    _safeMint(to, tokenId);

   //    // console.log("\n-->Hey World!");
   //    console.log("Minted token# %s to address: %s", tokenId, to);
      
   //    _setTokenURI(tokenId, "");
   // }


   // // FREE MINTING. LETS ME MINT AN NFT WITHOUT PAYING FOR IT.
   // // TO BE USED IN THE CONSTRUCTOR, AS A WAY OF QUICKLY MINTING AND ALLOCATING A NUMBER OF NFTS TO A SPECIFIC ADDRESS OR SET OF ADDRESSES.
   // function safeFREEMint(address to, string memory uri) public payable onlyOwner() {
   //    console.log("In 'safeFREEMint()'");
   
   //    // require(apePrice.mul(numberOfTokens) <= msg.value, "Ether value sent is not correct");

   //    uint256 tokenId = _tokenIdCounter.current();
   //    _tokenIdCounter.increment();
   //    _safeMint(to, tokenId);

   //    // console.log("Changing owner from %s to %s", currentOwner, newOwner)
   //    console.log("\n-->Hey World!");
   //    console.log("Minted token# %s to address: %s", tokenId, to);
   //    console.log("Here is that Token's URI: %s", uri);
   //    // console.log("Minted token#", tokenId, ", to address: ", to, ", and here's the URI: ", uri);

   //    // NO NEED FOR BASE-URI here - because it'll automatically get APPENDED to any token's URI 
   //    // any time the "tokenURI()" method is called!!!
   //    // Take the baseURI and APPEND to it the 'tokenID' - as set 3 lines above:
   //    _setTokenURI(tokenId, uri);
   // }




   function setProductPrice(uint incomingPrice) public onlyOwner() {
      // console.log("In 'setProductPrice()'");
      // console.log("Incoming Price =  %s", incomingPrice);

      PPKETHPrice = incomingPrice * 1 ether;

      emit ProductPriceSet(PPKETHPrice);
   }



   ///////////////////////////////////////////////////////////////////////////////
   //
   //     ===>>TOKEN URI STUFF
   // 
   // 
   function setBaseURI(string memory newBaseURI_) external onlyOwner() {
      baseMetadataURI = newBaseURI_;

      emit BaseURIUpdated(baseMetadataURI);
   }


   // Here I'm OVERRIDING the standard "_baseURI()" function that comes in "ERC721.sol" and making it return the 
   // value of "baseMetadataURI" - otherwise, it would just return "" - which is what it's written to do out of the box:
   function _baseURI() internal view virtual override returns (string memory) {
      return baseMetadataURI;
   }


  
   function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
      console.log("In 'tokenURI()', inquiring about 'tokenId' = %s", tokenId);

      // But here's code I'm copy-pasting from the "parent" ERC721.sol Contract:
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      // If "baseURI" is EMPTY, return "", otherwise, concatenate ("") the "baseURI" with the "tokenId":
      return bytes(baseMetadataURI).length > 0 ? string(abi.encodePacked(baseMetadataURI, tokenId.toString(), ".json")) : "";
   }




   // // (MINE!) DIRECT, REGULAR, PAID-FOR MINTING:
   // function safeMint(address to) public payable {
   //    console.log("In 'safeMint()'");
   //    console.log("msg.value = %s", msg.value);
   //    console.log("Current 'PPKPrice' = %s", PPKPrice);
      
   //    require(msg.value >= PPKPrice, "ETH value not enough!");

   //    uint256 tokenId = _tokenIdCounter.current();
   //    _tokenIdCounter.increment();
   //    _safeMint(to, tokenId);

   //    console.log("\n-->Hey World!");
   //    console.log("Minted token# %s to address: %s", tokenId, to);
   //    // console.log("Here is that Token's URI: %s", uri);
   //    // console.log("Minted token#", tokenId, ", to address: ", to, ", and here's the URI: ", uri);

   //    // NO NEED FOR BASE-URI here - because it'll automatically get APPENDED to any token's URI 
   //    // when the "tokenURI()" method is called!!!
   //    // Take the baseURI and APPEND to it the 'tokenID' - as set 3 lines above:
   //    _setTokenURI(tokenId, "");
   // }



   // function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal whenNotPaused override(ERC721A, ERC721Enumerable) {
   //    super._beforeTokenTransfer(from, to, tokenId);
   // }



   // // The following functions are overrides required by Solidity:
   // function _burn(uint256 tokenId) internal override(ERC721A, ERC721URIStorage) {
   //    super._burn(tokenId);
   // }



   // function getAllTokensOfUser(address user) public view returns (uint256[] memory) {
   //    // Get/Find out how many Tokens this User owns:
   //    // uint256 numTokensOwned = balanceOf(user);

   //    // Make sure the User owns at least one PPass:
   //    require(balanceOf(user) > 0, "ADDRESS DOESN'T OWN ANY PUNKPASSES!");

   //    // Next, declare an Integer-Array to hold all the Token-ID's held by the User in quest:
   //    uint[] memory _tokensOfOwner = new uint[](balanceOf(user));
   //    // uint[] memory _tokensOfOwner = new uint[](ERC721.balanceOf(user));

   //    uint tokenCounter;
   //    for(tokenCounter = 0; tokenCounter < balanceOf(user); tokenCounter++){
   //       _tokensOfOwner[tokenCounter] = tokenOfOwnerByIndex(user, tokenCounter);
   //       // _tokensOfOwner[tokenCounter] = ERC721Enumerable.tokenOfOwnerByIndex(user, tokenCounter);
   //    }
   //    return (_tokensOfOwner);
      
   // }


   // function withdrawFundsFromContract(uint256 amount) public onlyOwner() {
   //    console.log("\n\n>In 'withdraw()'");
   //    console.log(">Amount to be withdrawn = %s", amount);

   //    require(amount <= address(this).balance,"'withdrawFundsFromContract()' ERROR!!! Insufficient funds to withdraw");	

   //    console.log(">'address(this).balance()' = %s", address(this).balance);

   //    // address payable theOwner = payable(owner());
   //    payable(owner()).transfer(amount);
   //  }
    



   // function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
   //    return super.supportsInterface(interfaceId);
   // }



   function cashOut() external onlyOwner nonReentrant {
      (bool success, ) = msg.sender.call{ value: address(this).balance }("");
      require(success, "Transfer failed.");
   }



   function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
      _setOwnersExplicit(quantity);
   }



   function numberMinted(address owner) public view returns (uint256) {
      return _numberMinted(owner);
   }


   function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
      return ownershipOf(tokenId);
   }




   // // PAUSING and UN-PAUSING:
   // function pause() public onlyOwner() {
   //    _pause();
   // }


   // function unpause() public onlyOwner() {
   //    _unpause();
   // }


   function pauser(bool pState) public onlyOwner() {
      if(pState == false) {
         _unpause();
      }
      else{
         _pause();
      }
   }




}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; // √√√

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at 0 (e.g. 0, 1, 2, 3..).
 *
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
   using Address for address;
   using Strings for uint256;

   struct TokenOwnership {
      address addr;
      uint64 startTimestamp;
   }

   struct AddressData {
      uint128 balance;       // How many they minted THEMSELVES + BOUGHT later on Secondary afterwards?
      uint128 numberMinted;  // How many they minted THEMSELVES
   }

   uint256 private currentIndex = 0;

   uint256 internal immutable collectionSize;  //  =  10,000
   uint256 internal immutable maxBatchSize;    //  =  5

   // Token name:
   string private _name;

   // Token symbol:
   string private _symbol;

   // Mapping from token ID to ownership details:
   // An empty struct value does not necessarily mean the token is unowned. See "ownershipOf" implementation 
   // for details.
   mapping(uint256 => TokenOwnership) private _ownerships;

   // Mapping owner address to address data:
   mapping(address => AddressData) private _addressData;

   // Mapping from token ID to approved address:
   mapping(uint256 => address) private _tokenApprovals;

   // Mapping from owner to operator approvals:
   mapping(address => mapping(address => bool)) private _operatorApprovals;



   /**
   * @dev
   * `maxBatchSize` refers to how much a minter can mint at a time.
   * `collectionSize_` refers to how many tokens are in the collection.
   */
   constructor(string memory name_, string memory symbol_, uint256 maxBatchSize_, uint256 collectionSize_) {
      require(collectionSize_ > 0, "ERC721A: collection must have a nonzero supply");
      require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
      _name = name_;
      _symbol = symbol_;
      collectionSize = collectionSize_;    //  =  10,000
      maxBatchSize = maxBatchSize_;        //  =  5
   }



   /**
   * @dev See {IERC165-supportsInterface}.
   */
   function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
      return
         interfaceId == type(IERC721).interfaceId ||
         interfaceId == type(IERC721Metadata).interfaceId ||
         interfaceId == type(IERC721Enumerable).interfaceId ||
         super.supportsInterface(interfaceId);
   }




   /**
   * @dev See {IERC721-balanceOf}.
   */
   function balanceOf(address owner) public view override returns (uint256) {
      require(owner != address(0), "ERC721A: balance query for the zero address");
      return uint256(_addressData[owner].balance);
   }




   /**
   * @dev See {IERC721-ownerOf}.
   */
   function ownerOf(uint256 tokenId) public view override returns (address) {
      return ownershipOf(tokenId).addr;
   }



   /**
   * @dev See {IERC721Metadata-name}.
   */
   function name() public view virtual override returns (string memory) {
      return _name;
   }



   /**
   * @dev See {IERC721Metadata-symbol}.
   */
   function symbol() public view virtual override returns (string memory) {
      return _symbol;
   }



   /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
      require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

      string memory baseURI = _baseURI();

      return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
   }




   /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overriden in child contracts.
   */
   function _baseURI() internal view virtual returns (string memory) {
      return "";
   }



   /**
   * @dev See {IERC721-approve}.
   */
   function approve(address to, uint256 tokenId) public override {
      address owner = ERC721A.ownerOf(tokenId);
      require(to != owner, "ERC721A: approval to current owner");

      require(
         _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
         "ERC721A: approve caller is not owner nor approved for all"
      );

      _approve(to, tokenId, owner);
   }



   /**
   * @dev See {IERC721-getApproved}.
   */
   function getApproved(uint256 tokenId) public view override returns (address) {
      require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

      return _tokenApprovals[tokenId];
   }




   /**
   * @dev See {IERC721-setApprovalForAll}.
   */
   function setApprovalForAll(address operator, bool approved) public override {
      require(operator != _msgSender(), "ERC721A: approve to caller");

      _operatorApprovals[_msgSender()][operator] = approved;
      emit ApprovalForAll(_msgSender(), operator, approved);
   }




   /**
   * @dev See {IERC721-isApprovedForAll}.
   */
   function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
      return _operatorApprovals[owner][operator];
   }




   /**
   * @dev See {IERC721-transferFrom}.
   */
   function transferFrom(address from, address to, uint256 tokenId) public override {
      _transfer(from, to, tokenId);
   }





   /**
   * @dev See {IERC721-safeTransferFrom}.
   */
   function safeTransferFrom(address from, address to, uint256 tokenId) public override {
      safeTransferFrom(from, to, tokenId, "");
   }




   /**
   * @dev See {IERC721-safeTransferFrom}.
   */
   function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
      _transfer(from, to, tokenId);
      require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721A: transfer to non ERC721Receiver implementer");
   }





   /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
   function _transfer(address from, address to, uint256 tokenId) private {
      TokenOwnership memory prevOwnership = ownershipOf(tokenId);

      bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
         getApproved(tokenId) == _msgSender() ||
         isApprovedForAll(prevOwnership.addr, _msgSender()));

      require(isApprovedOrOwner, "ERC721A: transfer caller is not owner nor approved");
      require(prevOwnership.addr == from, "ERC721A: transfer from incorrect owner");
      require(to != address(0), "ERC721A: transfer to the zero address");

      _beforeTokenTransfers(from, to, tokenId, 1);

      // Clear approvals from the previous owner
      _approve(address(0), tokenId, prevOwnership.addr);

      _addressData[from].balance -= 1;
      _addressData[to].balance += 1;
      _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

      // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
      // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
      uint256 nextTokenId = tokenId + 1;
      if (_ownerships[nextTokenId].addr == address(0)) {
         if (_exists(nextTokenId)) {
            _ownerships[nextTokenId] = TokenOwnership(prevOwnership.addr, prevOwnership.startTimestamp);
         }
      }

      emit Transfer(from, to, tokenId);
      _afterTokenTransfers(from, to, tokenId, 1);
   }





   function ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
      console.log("\n>In 'ownershipOf()'!!!");
      console.log("Inquiring about 'tokenId' # %s", tokenId);

      require(_exists(tokenId), "ERC721A 'ownershipOf()' ERROR!: owner query for nonexistent token");

      uint256 lowestTokenToCheck;

      if(tokenId >= maxBatchSize) {
         lowestTokenToCheck = tokenId - maxBatchSize + 1;
      }

      console.log("\n>'lowestTokenToCheck' = %s \n", lowestTokenToCheck);


      for(uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
         console.log(">FOR LOOP: 'curr' = %s", curr);
         TokenOwnership memory ownership = _ownerships[curr];
         if(ownership.addr != address(0)) {
            console.log(">OWNER FOUND!");
            return ownership;
         }
      }

      revert("ERC721A: unable to determine the owner of token");
   }






   /**
      * @dev See {IERC721Enumerable-totalSupply}.
      */
   function totalSupply() public view override returns (uint256) {
      return currentIndex;
   }



   /**
      * @dev See {IERC721Enumerable-tokenByIndex}.
      */
   function tokenByIndex(uint256 index) public view override returns (uint256) {
      require(index < totalSupply(), "ERC721A: global index out of bounds");
      return index;
   }



   /**
      * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
      * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
      * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
      */
   function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
      require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
      uint256 numMintedSoFar = totalSupply();
      uint256 tokenIdsIdx = 0;
      address currOwnershipAddr = address(0);
      for (uint256 i = 0; i < numMintedSoFar; i++) {
         TokenOwnership memory ownership = _ownerships[i];
         if (ownership.addr != address(0)) {
            currOwnershipAddr = ownership.addr;
         }
         if (currOwnershipAddr == owner) {
            if (tokenIdsIdx == index) {
               return i;
            }
            tokenIdsIdx++;
         }
      }
      revert("ERC721A: unable to get token of owner by index");
   }







   function _numberMinted(address owner) internal view returns (uint256) {
      require(owner != address(0), "ERC721A: number minted query for the zero address");
      return uint256(_addressData[owner].numberMinted);
   }





   /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   */
   function _exists(uint256 tokenId) internal view returns (bool) {
      return tokenId < currentIndex;
   }




   function _safeMint(address to, uint256 quantity) internal {
      _safeMint(to, quantity, "");
   }




   /**
   * @dev Mints `quantity` tokens and transfers them to `to`.
   *
   * Requirements:
   *
   * - there must be `quantity` tokens remaining unminted in the total collection.
   * - `to` cannot be the zero address.
   * - `quantity` cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
   function _safeMint(address to, uint256 quantity, bytes memory _data) internal {
      console.log("_safeMint()!!! -- DEEP in ERC721A...");

      console.log(">currentIndex = %s", currentIndex);
      uint256 startTokenId = currentIndex;
      require(to != address(0), "ERC721A: mint to the zero address");

      // We know if the first token in the batch doesn't exist, the other ones don't as well, because of 
      // serial ordering.
      require(!_exists(startTokenId), "ERC721A: token already minted");

      // I'm commenting out this line, which WAS IN the original Azuki 721A Contract:
      // require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

      // Instead, I'm doing this:
      // if()

      _beforeTokenTransfers(address(0), to, startTokenId, quantity);

      AddressData memory addressData = _addressData[to];

      _addressData[to] = AddressData(addressData.balance + uint128(quantity), addressData.numberMinted + uint128(quantity));
      _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

      uint256 updatedIndex = startTokenId;

      for (uint256 i = 0; i < quantity; i++) {
         console.log("  >In '_safeMint()' -- Minting NFT # %s to account %s", i, to);
         emit Transfer(address(0), to, updatedIndex);
         require(_checkOnERC721Received(address(0), to, updatedIndex, _data), "ERC721A: transfer to non ERC721Receiver implementer");
         updatedIndex++;
      }

      currentIndex = updatedIndex;
      _afterTokenTransfers(address(0), to, startTokenId, quantity);
   }





   function _safeDeploymentMint(address to, uint256 quantity, bytes memory _data) internal {
      console.log(" \nDEEP in ERC721A --> '_safeDeploymentMint()'!!! ");

      console.log(">currentIndex = %s", currentIndex);
      uint256 startTokenId = currentIndex;
      require(to != address(0), "ERC721A: mint to the zero address");

      // We know if the first token in the batch doesn't exist, the other ones don't as well, because of 
      // serial ordering.
      require(!_exists(startTokenId), "ERC721A: token already minted");

      // I'm commenting out this line, which WAS IN the original Azuki 721A Contract:
      // require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

      // Instead, I'm doing this:
      // if()

      _beforeTokenTransfers(address(0), to, startTokenId, quantity);

      AddressData memory addressData = _addressData[to];

      _addressData[to] = AddressData(addressData.balance + uint128(quantity), addressData.numberMinted + uint128(quantity));
      _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

      uint256 updatedIndex = startTokenId;

      for (uint256 i = 0; i < quantity; i++) {
         console.log("  >In '_safeDeploymentMint()' -- Minting NFT # %s (%s) to account %s", i, currentIndex+i, to);
         // emit Transfer(address(0), to, updatedIndex);
         require(_checkOnERC721Received(address(0), to, updatedIndex, _data), "ERC721A: transfer to non ERC721Receiver implementer");
         updatedIndex++;
      }

      currentIndex = updatedIndex;
      _afterTokenTransfers(address(0), to, startTokenId, quantity);
   }


   




   /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits a {Approval} event.
   */
   function _approve(address to, uint256 tokenId, address owner) private {
      _tokenApprovals[tokenId] = to;
      emit Approval(owner, to, tokenId);
   }




   uint256 public nextOwnerToExplicitlySet = 0;


   /**
   * @dev Explicitly set `owners` to eliminate loops in future calls of ownerOf().
   */
   function _setOwnersExplicit(uint256 quantity) internal {
      uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
      require(quantity > 0, "quantity must be nonzero");
      
      uint256 endIndex = oldNextOwnerToSet + quantity - 1;
      
      if (endIndex > collectionSize - 1) {
         endIndex = collectionSize - 1;
      }

      // We know if the last one in the group exists, all in the group exist, due to serial ordering.
      require(_exists(endIndex), "not enough minted yet for this cleanup");
      
      for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
         if (_ownerships[i].addr == address(0)) {
            TokenOwnership memory ownership = ownershipOf(i);
            _ownerships[i] = TokenOwnership(ownership.addr, ownership.startTimestamp);
         }
      }
      nextOwnerToExplicitlySet = endIndex + 1;
   }




   /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
   function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
      if (to.isContract()) {
         try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
         } 
         catch (bytes memory reason) {
            if (reason.length == 0) {
               revert("ERC721A: transfer to non ERC721Receiver implementer");
            } 
            else {
               assembly {
                  revert(add(32, reason), mload(reason))
               }
            }
         }
      } 
      else {
         return true;
      }
   }




  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   */
   function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual {}



   /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when `from` and `to` are both non-zero.
   * - `from` and `to` are never both zero.
   */
   function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal virtual { }



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
   /**
   * @dev Emitted when the pause is triggered by `account`.
   */
   event Paused(address account);

   /**
   * @dev Emitted when the pause is lifted by `account`.
   */
   event Unpaused(address account);

   bool private _paused;

   /**
   * @dev Initializes the contract in unpaused state.
   */
   constructor() {
      _paused = false;
   }

   /**
   * @dev Returns true if the contract is paused, and false otherwise.
   */
   function paused() public view virtual returns (bool) {
      return _paused;
   }

   /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
   modifier whenNotPaused() {
      require(!paused(), "Pausable: paused");
      _;
   }

   /**
   * @dev Modifier to make a function callable only when the contract is paused.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
   modifier whenPaused() {
      require(paused(), "Pausable: not paused");
      _;
   }

   /**
   * @dev Triggers stopped state.
   *
   * Requirements:
   *
   * - The contract must not be paused.
   */
   function _pause() internal virtual whenNotPaused {
      _paused = true;
      emit Paused(_msgSender());
   }

   /**
   * @dev Returns to normal state.
   *
   * Requirements:
   *
   * - The contract must be paused.
   */
   function _unpause() internal virtual whenPaused {
      _paused = false;
      emit Unpaused(_msgSender());
   }
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    
   address private _owner;

   event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
   constructor() {
      _transferOwnership(_msgSender());
   }

   /**
   * @dev Returns the address of the current owner.
   */
   function owner() public view virtual returns (address) {
      return _owner;
   }

   /**
   * @dev Throws if called by any account other than the owner.
   */
   modifier onlyOwner() {
      require(owner() == _msgSender(), "Ownable: caller is not the owner");
      _;
   }

   /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
   function renounceOwnership() public virtual onlyOwner {
      _transferOwnership(address(0));
   }

   /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
   function transferOwnership(address newOwner) public virtual onlyOwner {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      _transferOwnership(newOwner);
   }

   /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Internal function without access restriction.
   */
   function _transferOwnership(address newOwner) internal virtual {
      address oldOwner = _owner;
      _owner = newOwner;
      emit OwnershipTransferred(oldOwner, newOwner);
   }

   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0; // √√√

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0; // √√√

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;  // √√√

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;  // √√√

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;  // √√√

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.0;
// ORIGINALLY: pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;  // √√√

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;  // √√√

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}