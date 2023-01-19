// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "./DefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./LuckyGnomes.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract GnomesCollective is Ownable, DefaultOperatorFilterer, ERC721Enumerable, Addresses {
  using Strings for uint256;
  
  address LuckyGnomes; 
  uint256 public cost = 0.01888 ether;
  uint256 public publicPrice = 0.00888 ether;
  uint256 public maxSupply = 1888;
  uint256 public maxMintAmount = 1;
  bytes32 public root;
  bool public publicMint = false;
  bool public paused = false;
  bool public revealed = false;
  string public notRevealedUri="ipfs://QmWw33TuFSVAPHeuamMpqmR4ATr8159kEWghaDTaBj2ZuA/";
  mapping(address => bool) public whitelisted;
  mapping(uint256 => address) private requestToSender;
  mapping(uint256 => string) private _tokenURIs;
  mapping(address => uint256) private walletMints;

  constructor(
    bytes32 _root,
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) { 
    root = _root;
    mint(10);
    initWL();
  }

  function mint(uint256 _mintAmount) public payable {
    if(msg.sender != owner()){                                                 // @dev Constructor call for Treasure
    require(!paused, 'Minting is paused');
    require(walletMints[msg.sender] < maxMintAmount + 1, 'Exceed max wallet'); //@dev Whitelist can mint again after Free mint and before public
    }
    require(_mintAmount > 0, 'Amount has to be > 0');
    require(totalSupply() + _mintAmount <= maxSupply, 'SOLD OUT');

    if(whitelisted[msg.sender] != true) {
        if(msg.sender != owner()){
          require(publicMint, 'Public _state=false');
          require(_mintAmount <= maxMintAmount, 'Amount is > max');
          require(msg.value >= (cost + publicPrice), 'Not enough ETH');
          walletMints[msg.sender]=2;
          }
          for (uint256 i=0; i<(_mintAmount); i++){
        requestToSender[totalSupply() + 1] = msg.sender;
        _safeMint(msg.sender, totalSupply() + 1);
          }
    }
    if (whitelisted[msg.sender] == true) {
      require(_mintAmount <= (maxMintAmount + 1 - walletMints[msg.sender]), 'Amount is > max');
      if (_mintAmount == 2 || walletMints[msg.sender] == 1) {
        if (publicMint){
        require(msg.value >= cost + publicPrice, 'Not enough ETH');}
        else {
          require(msg.value >= cost, 'Not enough ETH');
        }
      }
      for (uint256 i=0; i<(_mintAmount); i++){
        requestToSender[totalSupply() + 1] = msg.sender;
        _safeMint(msg.sender, totalSupply() + 1);
        walletMints[msg.sender]++;
      }
      }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
  
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override(ERC721)
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    return tokenURI(tokenId);
  }

  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
         require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function _publicMint(bool _state) public onlyOwner {
    publicMint = _state;
  }

 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os,'not os');
  }

  function setWalletMints (address _user, uint256 _state) public onlyOwner {
    walletMints[_user] = _state;
  }

  function getWalletMints(address _user) view public returns (uint256 WalletMints) {
    return walletMints[_user];
  }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
) public override(ERC721, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
}

function initWL() public onlyOwner {
  for(uint256 i=0;i<_whitelists.length;i++){
  whitelisted[_whitelists[i]]=true;
  }
}

 function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
  return MerkleProof.verify(proof, root, leaf);
 }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Addresses {

constructor() {}
     address[] public _whitelists= [
0x86a1d85Aa48343527D659A5682102D585a4B6fef,
0x27f59BCA189B61E8E1037AB79e1638C3c53C4976,
0x35a214b13c9E223B8D511f343aC8Fa94293233a1,
0xb9CF71AAD861e7226Ef2C07fCd2feED6d0f9A643,
0xAB7ea27D810E5Bd751A4a035B940e66E757c2F74,
0x29eB182B934780bB25C4656268Df4C919225E707,
0xe58e9D6244d9D206c2c9BC0Ea36b2aEA974B7D2A,
0x347125aB96E098a9ff7e26405A75Aa227E119c15,
0xe9a158488A060a5673cC42bd2dc38283bbB00a30,
0x1A5585c834F5a179f6c62e18D17E265B0e971A84,
0xB1c025B75Ba1CBcaDb5b3A8B0D9fe9B8B8939be9,
0x1e15B51616213E06aC509261aAa84466646b9084,
0x221e438E4A8Fc6569457bAe62CbCcDb8b5b02a93,
0x86cA24024779A431176844D43c73699A7327a7be,
0x286DC89a62468f464ccb532000ef0b1197462B04,
0x0Aff1e0F3D0F11c21c5976F1f68179D2eDfAc6fC,
0x7263F3E47c77fa68fDB02eAA572768bC90Fd9298,
0x74715e12d34706Dc93DF96D2D8e813fb06Af146A,
0xeaE9870e408327733aACBa4BdC33FC14822a48Da,
0x6f4E8096e4fa46AF0534db16708910008040e566,
0x1cA49623b5d5d78Caa6ccbB8E828aaDAC990DA0A,
0xd8FBb54edF49ed0783d5c79440a168c353780753,
0x90C676fBe75df48b83aB596364646588Ae535385,
0x2f0df65c444B35b3CbCE0EFAeCD9C9750612e136,
0x6d0Dc2CA7467F5b38E9b4506C344B99996b5cd0c,
0x2838032d8FbE767f86c3C5a300e2B379917A3476,
0x0dE365d28e92213b35c1c0B066331ed6BE0Bd5E6,
0xC6d4c47aD61607e3BC80b0e85CC5B3DD93CE8F5d,
0xE31BB9D024A823d03e98E158e81c87Db7A3454e2,
0xA54d14640a7E874B85D76041b4791E646728B325,
0xa17F11B182fc1Ea02dBff64A2c814Df5eE5495e7,
0xF7Eb1c7f8b750840Fd38A298CfcDF83F56e70884,
0xaE5faD3ba62a70b34A17005cE2cB465B2Ee2430e,
0xdCcf21d69267C9435FE2b4BcE17985b6698e163A,
0xF60eD9B7FeFB29Cd2a79b737D4e4eD28180972f8,
0x026d3bD0F6aD3977EC3F2E5d9ff0667634b6DC70,
0x47C152A5a60c6cac213D7B6cCf8784032B110A2A,
0xe455423d2d9133bA3Ef1121D58Bd7aAB73077491,
0x033fb4a29E8641500710C77037dd40Dd84E40b19,
0x29A3c67f2a4a50250342d23748beEd0c19349605,
0xe09136166C1B56FA3ef732872673ec3092031332,
0x1192FBc30f019eBA6b81588ac2341FE1216AdF93,
0x9775268fc9CAc77697D3211b7e547026c628eD76,
0xdA38AFF9D34fF382F12a1De111A10491566B9876,
0xF43E00E64574596b43f48a34CA84956Ab527FD72,
0x714e075198636956785B4cC08Be1C70d9361C445,
0x6140aa690a41e907d74F844d722c237D9796C1AC,
0xDad32Fc8B47190eb3CB2d3AD9512f894E1762a2C,
0x8129035991f8D9D7CE2787E9591800e38303Cc8a,
0x8afeA3F31828F1E70c2c0CacF38F874Fc3a4C4c6,
0x3cD3F81e1F7A2D11bbAd593821a52184294768a7,
0x6140aa690a41e907d74F844d722c237D9796C1AC,
0x0f54143169170BdB8064A9E32EA6CBc32E490fE6,
0xa2fF79431f7fC4d1f1Db88B94C9C6a0FE92376Ac,
0x61C46B6b1f4Fc59dcBc7a8676f0432b66f61Cc73,
0x0AF009194CabF04876B3F0D3a64ef2Ce48df7569,
0x3cE735F6cFAD70D8A689774E69695A98fb12920b,
0x0f54143169170BdB8064A9E32EA6CBc32E490fE6,
0xce3b5695deE26dfcBfa0b4E217c43638A7457C14,
0x3a80E195e707b4983c4AfF876B8A7cBB1444E905,
0xd74AAFB161ABf14bd86c29e3CA0a2EEFa2b54B79,
0x312026648c69DD893797fa0b2eC9f5a99f9332E2,
0x105de362AB1C4B20EeDc1528335cf3878CC6c0cd,
0x2838032d8FbE767f86c3C5a300e2B379917A3476,
0xe455423d2d9133bA3Ef1121D58Bd7aAB73077491,
0x6f4E8096e4fa46AF0534db16708910008040e566,
0x83622e062142c6D297f9B8f7a0e6537eE2Db3e43,
0xE9e969207C02533e24783E397106BB6D2e47c00E,
0xE221b7f3E5D9a3484ba8a799AE7F813820860C57,
0x25FdB5688d697eDe28A35B5057f1A3daf7c3647a,
0xc908eBd8D0C40546E8E3ca3f3a80dbc1e8Fa01E5,
0x5dC70D8Be1c4bDDb76C65120De9b64198590CC6D,
0x50aCf361E07ED95DF690C780a0793e44b4a20192,
0x9E1C0BedbcBE78F2C6d1335D976E4EaBF84264d9,
0x47C152A5a60c6cac213D7B6cCf8784032B110A2A,
0x35a214b13c9E223B8D511f343aC8Fa94293233a1,
0x128c64963F518E9A2C72F6c0B5f5AC26d506aC4d,
0xD2615a44fa8346D8630d9B3e24146b844c8Db507,
0xB9cF5601dCF561d544a82578759304338F280c3B,
0x0575cf9Ec75e96932BfddCC442cEe6690F621C9a,
0xC39b2e5dCC628df722191e808505f276A217c5b4,
0xDad32Fc8B47190eb3CB2d3AD9512f894E1762a2C,
0x09a22A6e37167FC1951e783d2dE7B9861c41f71b,
0x5565d845372964b3B5cA0fF38cA88fEC1Bae4851,
0x2586b8Bc2B92FeDaCEC05Eb5b2c06289BDcB9758,
0x9B2DD174210eC09e51b83189A9258c20Db252631,
0x62A82c99c6AEddBB2C4429118f8281bc7820e741,
0x9384Df9cFdeF8773E1aAb32fDCC8E9bb7Ed0EA2f,
0x07422ceF7d14556db51DcC429ae9CB5A88cACed0,
0x57FEbDf01bf66B92C8a0107DEA832673aeF6381a,
0x2F24710750D8944B7F8cCa2643F09bB3FA842faa,
0x900Cc280Ece775c5426ce874D5beA66b17277aE2,
0x170d54cC598CF3875Af833bfd1e0Dd2Dd58F4B0d,
0xC931baaa62BFDf09beDDE1ebd3de16C05AbB33e6,
0xBd25f53D1e49358CAc7E5061f6aDBEdEf3979D98,
0x972fB92aF6462FfF526f719FDA4281145F2bcd15,
0xeA5743D7f04653fFA5099c8B916B3E416d19bd21,
0xb6CC2F281e1656175B3Ee89d296363CD60CB960f,
0x4C68f3639c1bA805E52986349d35c499592D406e,
0x99152812192C474C50d6f36324D9e7772a777913,
0x617d63bF8aB327fd6Ed9b89a5F17ee823961044F,
0x787d92ad51E3467cF3F66D814c1e0dd0c0D9BB85,
0x1416e20d666aE4aB9a8cF3FF05a77c054f700F30,
0x4975a608E4EDCC38f2c3435Ca63327BB2c6c8A25,
0x08aF359f2492fd70D3E4A117B0eCbf8Fb8557c3F,
0x252a0f3ed636BCC8c10183Dc4C722c8DE024Bebb,
0x894648F4797Ff67d1861A71F0B77ABF5D35b9760,
0x4f8C19ae8aA24b98Ffd9c8B88b6FD75cfcB63b0d,
0x2a3234Bb2Ada7efF7D8f5Fe6fABf0eAd110D9AC0,
0xa41d7cca4F220c286cF1B6D408882ACA4dd3130d,
0x8C28989D99059960223Bd600Cd7451d707b294F6,
0x40282fb345bCFc7579d02AB5fcD50503f6114cB5,
0xD938722718F97F717297eFc904232FFB9dF919B4,
0x5bD1bD69eC0e87639a9b657A838A3Ce26d281CaD,
0x4A346b08A5f939a1c707F0e40b2f8a6b59D26a20,
0xd74Baa483da05E195804F6A8f6636C9f0C7aCFC2,
0xd32F0E6Dde11E95E26497a79a31554B19C464997,
0x3c011FD929500B9e504D2Cb50F265595a8e7CC5D,
0x46a0907595a0Da3F45b8ac70a4e563593a0b3379,
0x3F3Bd4457e80868f563Bf60671C1A79bc1a14b8A,
0x5499931aA515CED9D4946cC1590439268c3Db8F8,
0x154D9d4c92fCFa1C461f6946e2F287365eD3CA09,
0x30ecE5B508e58deb520cf71ba8F69CDA3472fDf3,
0xfa2236A34042bc622C44d031328b465973c3d140,
0xA39405206CcD73778Fe677BB7f8eAf0404eD4C22,
0x63fddce2718C655aAd16166BC696dA1a111e254b,
0xD0476bE41995B8dE49ab5Df7Bb3e930B42261Ad4,
0x3aAAE5C3c0f1F3b239cb6a5F02e105674De13bB2,
0xEC491B54C54Ad53aDe796464d7Bf33fC7a51129B,
0x058df57e7CCD5480C250b56B4024B0Fc61657cD3,
0x754C00d07fEe18905D8B27F3EC890b93846a5312,
0x4F03d95aF246C7cbbc9E4fC1859974945ef418a1,
0x3E1f996345BF39aBb45E493E7b2f49e36e32504f,
0x70e3cc5EAb809984a92a141BE800098dA1d85a78,
0x8eAb27eBA895CE5471E92069c78a61c7Cabe8299,
0x90FF3ACa423150Fc69703A6d8320e93A6624c74D,
0x5794C30A3Bc498928170B0d65A10893e2cC4BcBB,
0x232AAEe8F202A48EAC9c8F2f04074DF8dd2f5F71,
0x70a29b1BCeD6453A68Bb6B25a48993Cf565312aa,
0x28FfE7F5ae14E2222e857460814BfA1Ad60Fe67f,
0xF785334f4f68340f48CeC24A9bE8ecAE5dC027B4,
0xb90335e55ea544676C27ecf450d520c935270e4E,
0x9b2E28cF818d1D3369AC1572D9f1698328f4F00f,
0xa9EA7a50BFd7a254Bf92A7457fEbc935c5c61F94,
0xC33964f4EeC0aed852aae04b5e3Fec8a7617200e,
0xf6f78af747971352f5Cda9669E4EbA572bF839D7,
0x973d44Ec1f4a23B29f07E435a09B5E2eE3400A92,
0xcd07c39832191431C4Cd8b44a33af355711edDaF,
0xC05F16b106C4092672219e7C5503BA1704995AF7,
0x9a5cc0560c4ED2ebD5fa2dB646D8AC7E4820f80e,
0x2f6C73FD2605c15D0580357AeDbeF131F4a8A8a1,
0x7B2c1C3B0C00739199D3E9576A7e469eCf0782EA,
0xDb2308EAaEe35deb05082B5AB3e87f0dA05A4279,
0xd84e99c6e6B92C8652acABE92115f5d54A5713C5,
0xdC084a84944939e25Dc0b13F3eaAe0726921B2D5,
0x15e40210c549EF7F352893d27aC82eaDA8027cE2,
0xd68d52D216a6423fbCB3Fce43BA6719adA0c6EaE,
0xE0E5E0389D1A9DcFBc4BEc918C7b49cfe8C1b4C2,
0x71725c908FFdb6F4c89AC418D39404E574d24945,
0x0317B899d2886d515718495c3317e25B3134D55D,
0x0A3152882AA0B0949Aee58ee708eB6941e25E3b7,
0x47C152A5a60c6cac213D7B6cCf8784032B110A2A,
0xC25d4DE6C695b43bC52Aa50915bFEE08e0467206,
0x00101a08f44B9DA944D09c4F1fbCAd9C8FDf0412,
0xF78EA7Dd78e3236Bd1007F399eB01c6BD2D02005,
0xFeD07C07ca5Ab8B5487eCC2e13be2B89BC6336B1,
0x3c9290e5985614Bc724ddc72011c54F4446b6Ef2,
0x1747a687Ab4d1b7a739b07e261930eF8014878a6,
0x82e23103Ebf463ECB9C58985294006939A1467cB,
0x2Bb77e7B7e8f104b4C584021B3BA4276faE1F840,
0xbBfd7A1F37a84bD75ec8557B464DDC9B70Af4852,
0xfB4cD1bc8B7498fbfA29a910dF11369A381Ac10a,
0x2b35B48EF2BB3f1BC27e00b1580a4D7501e53874,
0x41ec094daA32423a183a3fd2a5422Dfb2cAf6E53,
0x77Fc4eA0e4bdf14C5c6b85F7ca7E5B217Dcc72F3,
0xAf9420eC811ca8033a22922e26d614792538d53a,
0xDe68a3155D64B5F6B8fAd0e4e5CF4fC17cE5346d,
0x9CEdfE562541e3CAA9F88fE259955AA52e07Cf5E,
0x9B520CC47332ED0f7e49B95Acd5383E8615ae164,
0x7217c31D8Cf12657e2Cc6a1c54E9FBf991A28561,
0x2b010915dd4490D4D8D7A535CEd0C32071cA172c,
0x68e1b05B2AE98e1aE174E5C6640dfC0231dD6A4c,
0x01Df47e31b9bb354D1841798908Ce3848CbDBE45,
0x3a80E195e707b4983c4AfF876B8A7cBB1444E905,
0xd47C113f9172170baAe62a7eBea629a079bc2114,
0xe549e4Fae5599943B57F8A2FD556b0B42331BAC3,
0x9224060CdfF5191507365CD7838e52dA9f6b7179,
0x61d5f686847a9C8542b0E02cF16f101135106709,
0x9953b7723EEc584Eb8A4599d8492a13A65F99A0f,
0x0E204E46A52f1C701E54eFD525062A4da96f2b59,
0x18929e2357EcC852d6064DdC67648F00eC0699ae,
0x922e025792E9Fb8CdbbE2b077045fAe71c82128f,
0xeea2eE6895Cb5a37B435a20bAA5d96b4544184fA,
0x2e8cCE5295fB4e303d75cA130E7284C97f5Ad8f5,
0x4C9DCeF5FF128c97184AcDf6f284BBb1703A227b,
0xEa388cFDd9a846f459Cb130f15A80CBF80f27c54,
0x1617b0b344D09aEEb0b2E573ccdc9b071f06c278,
0x74356542fcA8F2b11C8D34a3C65042851b30Fa92,
0xA8eed2635d40EBe072540e8f43369035480F877C,
0xfb8739dA95d824d1303599642aAb975FB073F622,
0xB9cF5601dCF561d544a82578759304338F280c3B,
0x6d0Dc2CA7467F5b38E9b4506C344B99996b5cd0c,
0xC39b2e5dCC628df722191e808505f276A217c5b4,
0xca229e409a7353F19587faaeF8fDAd052431B279,
0x143A78B670A1618A4984deb4F450c67aCBd6EF68,
0x9cc05c7174d0E2ad859e215301dfB43A4baA8C72,
0xfC108AEA78345451656A35A25BdF16d57adFBe01,
0x5C202A6D33492B2fAC0c0B8BD139606C9e8D1a5f,
0x60B338691ca75Ac668DbB1C426E220f7b628C800,
0xbB65f0941dD4837FE922b27c9d38D7b3c9E944a5,
0x2Cc5143bFa8b8b381121f63D2FB2eB1fFe116429,
0x5f54D6DD3F35A4f5f40FB6E901F58cDb11c25E6C,
0x407e7e826613e72c2226493c7019c2B4aa31D5b8,
0x0fcf53C6fE2c21904FF6c651b1fDDFDed642277B,
0xC650B904c6d55bD4f09Cf8bDBB8F0a71A46429B3,
0x4425e36E96ef4A47bFA39C65174ac4Cc93dB6829,
0xe455423d2d9133bA3Ef1121D58Bd7aAB73077491,
0x1f75Ff538349269b10D7c7681cd1FFa62cABAB74,
0x6645B730Cf6077720D541cDF2316Ba676D255EFc,
0x12b076563894D00633064BA943094D47CCE758e0,
0x03698aa6df9d604D51469738BE5f00F258660Cff,
0xD295dc147C902D631ef679Badaa6706Ca3a80751,
0xEFF72fa850dDC0CeE566504F08c1661da5ed53e5,
0x6681922c02730Eb6F01ea6C6f7b0d56bB7f549B1,
0x5dC70D8Be1c4bDDb76C65120De9b64198590CC6D,
0x1cF9fDD6023A908a98C4Ff58Cd2d752197124393,
0xDF3b1A47393d2fB4080f6083c05EBBB454f58Bf5,
0xd91ad3ae3931f87E77aDd853571C70F9EA5d634F,
0x3Fc70e0b22a2979c650dc0Ff835aE42A68755166,
0xC42F1cfE61c242F3AFEf6e7ed68Ba979E9f0749E,
0x243ABC822a0D47d20aF03031207724bFa2357EB0,
0x51646CE1fa528297f95859b61C957d419eDF09F6,
0x470e3C8eb305c021b8b7e5C873a01528eC93f2B4,
0x08B07bc6BADF2cc56e0dda9e77b25a91D3b71B66,
0x250104be9c39ff2F71540Cf3545C072dDbB56498,
0x90EC73F9f1A4021055B0E7BdE3568701BB3dC632,
0x3d9D5e2996292A5ddBE975Ed217aFD8B8344d839,
0x056D0F48E1FA94333A09B2215ea9aA6D2b78E470,
0x5565d845372964b3B5cA0fF38cA88fEC1Bae4851,
0x5c368C03637625C3A1DCa9eA24fde9530Da80FE1,
0x2586b8Bc2B92FeDaCEC05Eb5b2c06289BDcB9758,
0x506B7c9692117DdEbB14D19d3C7cE1e998DBA11a,
0xd324163e52d312184f9e95f31D35475b59ab8919,
0xca06fBDE588a97C4E16A844494D387087337147F,
0xBA8e38e7Ff9F2b175880C53A432151Ae84A4Ad1C,
0x6BC43546f2FCF0bFD40D0FFB025899134F5Aa895,
0x69286756bb947aeFF60696519E496127f9cF654f,
0x9B2DD174210eC09e51b83189A9258c20Db252631,
0x4871990d43c0Cf15408A22ded2dAc082CAF90Ce0,
0xEE7094B0D871b9c86d6205A560E6b7f7F3934EaE,
0x11Df643Cb599E409228cB36e5081fB39E4fBd029,
0xB3689e2aee1B147C7A229587778E1BcCafE3Be58,
0xaE6D28aA68096CFD12a71beCbBEb9B0e56c873E6,
0xD0253dc692a18c3633d0d64C99c45815d432Ab89,
0xb428B59800C6077aCbEA49FeBCCA6B558b635361,
0x1f75Ff538349269b10D7c7681cd1FFa62cABAB74,
0xcd07c39832191431C4Cd8b44a33af355711edDaF,
0x87e12A599B49303B575a372329987488Db530433,
0x67d93f436CEF45cd3AA2Ea6A1518dc181c5fc17A,
0xC13d78cd06807fD5366C62DE833E3d5E88A65FE3,
0x35CeB51E04Bb46a8712A5822a3e50BE5499F6762,
0x6C03aC14B7cf131fE837A1Eb0Ba46216B2d47d79,
0x253a9A47792b168208b1fF37DA898EFb445c6878,
0x4Dd2EC52F8026551A3E90531A8B17B08e985C289,
0x6E7970763D0d1B77CFA3E6471D158E7D75C95499,
0x39ee20451b86143B0eC8C647c9d0b316b3B514CE,
0x316B4E1f6150F7FC8F665c03f3b09818D15cF027,
0xcDf3B9D5F41ba95E8fA576937afEfb66d0fFc9B1,
0xa0751827DA7a5cE235D85694164382Ee8920648D,
0x4cC2eC05f374a9171C23b1E435392297ab73F0a2,
0xF67CF7333b259cf2100b877a5B55562CB53C4B3D,
0x41705c9c36829cA76902f5F353bdA9F907772336,
0x1d405c7837E9568Ceabc59F767be3daBcde7d876,
0x41de3fD88ADD510cE4e1D3a14c147B3Cea450a08,
0x71cD836B8ab475f38e777Dc1c7a6aA03bB422Afc,
0x52Eff600E9a0317981C1E3EE882c4b6d6E053f5D,
0xc7899A2205515a346DEBe510Ce848cc66cD11Ace,
0xA602a1bc54344da90a61654cB64e34913907b0a2,
0xa65289A4148aC0Dc36B4E1e7fC18E188d9e06848,
0xC652af2F515b671c4a89e60C97360e71ae535978,
0x8DeA21d8765901F33c1425e78e1261C2fA06b647,
0x8a87149072817293ACc15478D0fd8a64248974b3,
0x5d7b573bBFdF243B711c6B53124f92861342175E,
0x77C03887aAEC0079C0F9e8Ab472e42c06519Ea5e,
0xF6Eadd921353D6a755144105930C0791f1804013,
0x613d74ed2B6317b97D6D4B7f37F5c6F6f410835D,
0x50513814D3b307C2B06192ab06d4a2Dd1d5D2782,
0x76DF767ba7576ECA390b80804e2d3fEDECE7C3A9,
0x6BCaAEa0F3be2bBFf1a7dCCA7386b3646B87d8e4,
0xea69ee73DE48fD53C50Eba7eDfD09ABab3f86775,
0x7C56c531A76dCbA4B5DEC7379b44Cd31236A8373,
0xeA190fd3b642e24Ec290050c548e222F407ee28d,
0x32Fc02ab9FD278F71c1C9593679C1E16372C4687,
0x6E5d886072aEcf2E2C615A8f7703995Be36C7fa2,
0xC41310CF9FD5904cBb21a3771f8dA7274e7fcf7a,
0xf04683631f47B3e2C2493Af4c1B44dd3196fBb5C,
0x3d8f02628508E0576dF63F1b7F4E9E367cc67400,
0xa2Bb4BB00fA841B5691B8E39B30514b674102807,
0x3D0D45d07ab880477Fe8a83fa647c6b4a33cFc89,
0xe7f3Bb066e3585c4b7e4a7D72a26014FEA9a7B93,
0x1734D6D1713C170d835237809196E5Beed96c7fB,
0x8a288D0Da29f5f362261Fcd8BAcd242D3B581C56,
0x41820b093214C882E1c1F4f2D2FC31E12454d7D9,
0x8D726C1BeF58fD405700E9839423d5dE0E7c81aA,
0x6409dcD8B6518f9109044A51B69Be05b3Ce07305,
0x9F9c2d62B52800F5403C105658d2B4b6f88425E2,
0x995d155F9fB74053d032cBFc4516944450EE8943,
0x3068B0041d5634A7C1cF84274F261671BD343C63,
0x54cC37D004bD21A2134b3264a1C769110728d84c,
0xb9CF71AAD861e7226Ef2C07fCd2feED6d0f9A643,
0x161E2Fa8C84fCE6ac41531e567DC1d46A827A970,
0x26843798C486499aCFD64d6D3489437555c30B7f,
0x525cb402192D65339c0491ddE9a66FdC64e07586,
0xf10a780C7fa1A63419ce96f9bA5FDC439b1a3852,
0xD2665A310C38324635A4B7Cf8ED20215E39082F2,
0x8fDed530e4698634a2A6E23d206F2A7Cd2241c7a,
0x4C667769cfb14DC6186F8E2e29d550c3E538D89b,
0xA39405206CcD73778Fe677BB7f8eAf0404eD4C22,
0x692a2CcF3d9f82d1Db4fDEe66DE6c66fcc5c0985,
0xf9946523c93D277Fd64f98cDba1aD344177C6467,
0x09053693d3E8dEA1C45f72140fE57b00A2921d5d,
0x469d56cD21807916809893C3728271f571be88Ff,
0xD06A6028464C543933933F49a417611499eeBBaB,
0xfa1E22E39459B7c15475D78e214A6c1706478499,
0x5819034f26Dc83073B827d1AE5Cec3FaC425Cd0A,
0x8F6F61dC51A120b83a058384FE031E25b1C2B37a,
0x14987A5620430cB74506034F47662D9ED6E17C6f,
0xc4f775c7Dd8bCf9Fd77aeE79c25aD734Cc0DF576,
0xFD7C4a6ff5513491F7DB5F71C1A16F71EC59fF9E,
0x202A5cEdb74bb2690B7B122e9f3203867BD4D569,
0xfa957EB2BD179fcD562472cf45d47bdbBdC55F2A,
0x3933Da0C6beD62028EE126f24AE9e43063ecEb17,
0x2b09558cD638893fd312e9F5d3a541f10B77f900,
0xb788eCD1855BFe21a74659eE92614b0df8979239,
0xCFafb58fE229Ab2b56424668281dA8B6eF4D2353,
0x143A78B670A1618A4984deb4F450c67aCBd6EF68,
0x84ea0b8D5B920e6A10043AB9C6F7500bCb2C9D25,
0x1fA0c3437651F6f2c2cA34508Dcf01f3473f0778,
0x80592d00Ff937D3C1F181Ba036F0e748Ee97f619,
0x2e63A76A0025BF1D92CECdA73c5Efd342849fd0d,
0x525cb402192D65339c0491ddE9a66FdC64e07586,
0xb31aa41590EEaD169599E5E0D1d27eB7f822D0F5,
0x3bb8BF82794A51F690FB6aE0aa40EAB0232996F0,
0x243807F518800299CbE9727Ed3c6ca6f73aa808E,
0x38F80163Ad1C8930C921B58317df5bB43CD1Bfc3,
0xEfb8943F1A0092C14B3C0Ab4d6f6fEFDfB8487d6,
0xCdC21aC88873f5DeC862756C515957C9c993caD2,
0xB6b363cE425Cf83E9f10217d45915e168b5868a3,
0x2Cb1034524c1633A8588c7d9C9Bcf6FD966eDb32,
0x265674Fe56AEa269Fd7f5F13b941E88BeCB26577,
0x2D42Ec4F2a6B633AD65aC76f277F15ac3AA09631,
0xEEC22c815c10De9353a2EB89D99c671ab6e18863,
0x058df57e7CCD5480C250b56B4024B0Fc61657cD3,
0x56b22221303fe4660F09f94F6196D9F06c29a088,
0xD8d678CD79b68ecEb86133A9A09EB082F2d471f7,
0x88A0429f1eaF787EC9C808cF6A40f0f2bB97c4Ba,
0xa7c066385d322AC5Fccb1CF5a751eeBB8B739550,
0xbb150D0358c85eFAF0Dd302156C6520454Aae4e7,
0xea105F6f810DBCbe8d34418c3Dc0Dfb755Dec35d,
0x0D1EFcE1729F2Ddd4BFA4dfb2B1e3E43a131EC30,
0xE2945BA4126582C0548759F880d1951559513B0A,
0xFED2368773b4F0D819c70BE8162E3d2f6ad35Dc1,
0xCC7a406eaE38740c39148A7ab4860C4be1D22eC2,
0xf432675d1933c3877edca37E354e953B1798F0a6,
0xFB4fA74cAcE15b5D2415cBf13bff341372bF47d9,
0x7929e94e18f09E32562BA504cA7434c79debB2d6,
0x8331aeD8563BC6336C79c3E763B6c8D23eA43bdc,
0x7F8F5Da84114F09b0777035d7fD5642Fad07c1f3,
0x52B90F065B0216B94E15ff1708ED156C9e5B06e7,
0x6669047bD1cC51745aF11FBbC344B28B896Bd4E6,
0x13704f3675feF45846d04cD1FC2D12784a567197,
0xc1Bf92D8Ca7e4DA04a8BE7ef1031789F8533B64f,
0x892185f3a2BEd64b2F2e386B8feB2F1A4E8cB90E,
0x443541B93ba2513A26CDF5bDF5Da7E2ace11A031,
0x4C8455351ABC38391fB9D06CeCca87E429E81F86,
0xD52ec343dd85c891Ed12c5Af72643AC115a953F8,
0x869B85df33EC98F957D2CCb9CEddb26D92dFb610,
0x4cFD50f62Df880CCCD5e6d489e9ea3039819aAd1,
0x2f902C2664adB96256249f3716405F68788a2775,
0x8a5e251778e660b72A7FDDf1F5dcd551851cff73,
0x17C014D17317eBa95Be79d7e4A85296A883395df,
0xd8A252d1F3ecE3a496f16df1BA2Bfb1Cd59CfcB5,
0xD154b29aEB90dD858853da94E447b6538199B0C3,
0x47229128d78B40B4dE902Fd777d88593ef7AB5BB,
0x55FD4E5278e60bC06d5cA1090A048e0A7EF2382C,
0x3d47B440D8Ead4e7220B12B2b0c227c155c7E233,
0x6F1A18E399F8Da8B4019c24fbE755f0C96af61fB,
0xFcDF08a64bDc016732B75506FfD933EBE95a082c,
0x854D33F336157ccF5d05B6cAfB034D76e435ed04,
0xc1aa76389F5DD58690f8b009575d629B8501c787,
0x580D71e75E9ff44A9FF32DFa7f821aac9EEDBe52,
0xc37e2A54A76e6781E23ebE9430843874252e2fC9,
0xfE3219C3fBB10C6c2F8b4248968A1AEC70492CE2,
0xd95cF88D71FC6F4b99113C444AcE56Ee0195C4dD,
0x3c9290e5985614Bc724ddc72011c54F4446b6Ef2,
0xC2757DEd2cAa504baF40898733b187649E5DDD9C,
0x0E393311BeabFfeF428D5014277610d6ea94e3e1,
0xb63eb639374bD3B9C01ff1a728BE2865347F4263,
0x42108AAf4c14D5A82F162BeDC6D67068a26b43B5,
0x426fE88132Efed988A8a31B8012fdeA4e351D00D,
0xa1dfA761e139362Af058aAF8aacc545d90cCe30f,
0x63D70Fca42a11B71e2A905464DfAF030C0b0F4cc,
0xC45Ea56d4809feDC05347474c28A8cae237B6610,
0xe75Ca03c9edA5E6e3B01a9Ec3B3265B7EfB75Ff0,
0x8d74a0De22CE1810a56f8afAA25F20Aa90543bb6,
0xD71829c6695464D6539CeA8aCEeF1Cc21fd8C57F,
0xb9deb5c1A1822ab906015965c4249C57d6197049,
0xC41D5Ed0CD6FA6e4b169A2415805cab4612a043B,
0x9B2d608A546702af05876c88CA3A64a7806007b7,
0x20b06e1106b0D7ebCaefcfb4e8ed39B43ED762f1,
0xEE2190D17cd2Bc75a7af9c589834fC4f4B6CC003,
0x70536539a605d58Fae0712640c6892580B0C05ae,
0x579Fd812f65f0612dcF5d893F29D59442d68D1cB,
0x843e26137023Bb2E9801527597653292047B143C,
0x48cd55147D8b1aD727Aa102d8670b1D296a6e295,
0xB6de61396E901733BF32aC526df88a0D919F9BA7,
0x60392D3C1e0691eA6AF4DEf442E81BE92C20FAd9,
0xbde578eEb92e1A3b418253be4a86c3343707c960,
0x5b6B825C052286C184bac20CD7473410Ea511848,
0xE740482c55FC2afEE1C3E78BBb29B62eDabB3454,
0xa3263776a2361102449CC2b89632D53E0b14547d,
0x2Eec9b14D977270B965545216FB5B29FB74E9b29,
0x3b70802F1d8726DD61ad06d39D5902D7b22Ba230,
0xbd96161578a6e92a3A606dD7c133A1E8cE390E6e,
0x60270f6962cc1E9De63e8E41673876f92171d433,
0xBBBE561c853B3b47A2BF31D669D98a20502ca7df,
0x66f68251abb4A0844578145f667D01651f7A0AFD
];  

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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