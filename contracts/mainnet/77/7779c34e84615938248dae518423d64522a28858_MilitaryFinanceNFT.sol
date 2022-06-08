//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract MilitaryFinanceNFT is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string public baseURI = "ipfs://QmTCbup7X7G9jKUnay1odzVTyM3gndgApgapuySywHYpAg/mil.json";
    bool public isMintActive = false;

    mapping(address=>bool) private hasMinted;
    mapping(address=>uint256) public nftPerAddress;

    constructor() ERC721("Military Finance", "MF") {
        setBaseURI(baseURI);
        assignNFT([0x0F02c84F0f4dde605B8F79A0f906189Fe3D6563b,0x4cf8b424df061DebF876a4B930D83A1c6999e41F,0xd5a5E3e8d783198E296418a0c372B6840a1d7908,0xCb7c988DCf1bd9798adad8C1f0fde85E301884BA,0x7b8575a65320fC220D75290123f13906B512B2B3,0x74D6400F9480df5e5ffc76283147836bcE8D3c95,0x42480b336ad6246Cfde0ADc3b5C0F987621301bF,0x04cD0F07C5dfB0Fd97E2D6D4dCF51Fc4bf6902b8,0x2515388f9135c6e554950a13f27A2D311a695005,0xdB379e9D031b31A339e1FA38ac14859987379f85,0x49410e0986Bf3DAe2099f6CF159c3a428775BaCD,0xE6ac31c0eBFBdC40C0d37F00b22D7798810CA534,0xfC283d4DB5FcbC9C1f121E6F7aE98279d2DCE7dd,0x4E5D191DFFb8d3DFe7790F91ACe6f9B80F04Ef0f,0x3cbF94db8624F711e43429bb35eac970fd787cF7,0x6aE85Eaade22A37bD8f82755946307C869300317,0xC83DCD8509559A81250A62Ab5bfA02fC377E0472,0xd73f155CbdE8904E378f23b7cF03e85422045fCe,0x89147c5005230ef53629C9C6B1EA98994E626Eb2,0xa665daa4CF74F388b5BA71921B399Ad8d6c246e8,0x18Ec26AB28fE3f01675da12D6bD9AE9BcE560cEb,0xa69EeE71308C9Ae74eBA62c369ee77E306906c0f,0x38EEad1e98dfB2FD75fA6D10FE9b6fAB59f5893E,0x4aa0e35DC8A91193BE87592e19a84Bd7051D4ce6,0x45Aa70E782Aa969AEacB0Bc0570D014ccC66b588,0xC27be6F5e9640cEF25F98217Ca10f3FD51CE8277,0xB7A7c45562Cef752cB695DbB37F721ac82589bfe,0x8419b7BFF5F0a028062812993b77CA1b4fa5D05F,0x1dde6B5963536D241Fd50afD28c062cE0C94Bb36,0xd4E17a7851EC93DE08eCb25638a9E09D457f93Cb,0xF21d95281337D1D7d6086bb03ddA4699d36B8568,0xe8e3451b15EB5e6d4c4092Ff7d4e6a328b8B1C49,0xcf9B51D3E910E3910e29eD54480dC4308F69096E,0xDa6db76eAed161d422D8BEB670d7056Ec75b7914,0xD3041A2d0A087818CbF164EfBC0C481bBA0Fba52,0xb8343637ddEEBA2b30a57e486390645960299A65,0x458BE92AdceaAA7ef850B9feB8DBAB7D59435831,0x5743Ce317A6f7155D5681701F935082c04255c97,0x8C3c67f6e2E4FBD181F9c0fE4030aFbeE732C864,0x25585f2c5E89BF0C0A6E56e13Cb4Db35Aa36450e,0x70887FC71a498A983A3d0dE9D0b1dD8fF3414515,0xe10fd8f09A586d3740ace93d2BB44018fbBe1E78,0x7c727fCaFC90D47AD11f4bf5f47a8f116eC1b697,0x2f365624c31cDb9aEc9ACC6B395deB155601BfeE,0x6EF959D111b62F0e830eFc471D01D47BA77984CC,0xeFC8C6986fA3a8A6E6bc4bFc1Cb42985B1d1E576,0xC501A034678F7a0ba939d02C4fA5F7F138565561,0x77Df96e69aD2Aaf27766B72FE9b15Fe17Be7F9Fa,0x3A93E420f88776eD82890735b1CF0362cFb4524b,0x297557bf0aEc3EEb9Da85c72d59bfe5D8f7C4C48,0x492D24C7C5370f55aB667605DEEeFAC0962DB69A,0x03f44A591DE8Db070Ab2Ba753fab753b5142d54c,0x713f78655336b56E88B71d18D6deC48Eb141fBD4,0x396162B335BFeAf590c548162aC844aD670BFe93,0xe8F7dA81CA885f1F97bcD129bd8d240cA7063e7A,0x4F051a38BF4795677bcfBb3b02f3C65580C4F920,0x5f0Ba33ad38EcB093A8F3aB08C8B5dA55Ca33947,0x9F56A5b7236c2F2440aD5a4C201938C1780176C0,0xcd15DBA1E6E6C7ad6477C253627Aad3F6397366a,0x849DFB80c24E83a623889426e17D3a452012b3e8,0x3967610e525aB2c2D19D7B6a896A9ab81E90d031,0x7ed63716911c13a56c55D43E1079679461BC929c,0x1DD9438351562A095e8c8A76EAb11F8321AbB3d9,0xa9EB742D925B248d3EaF6a8d57Fb1e9de9fe2952,0xcA0cdD507C949AE0c8575238DC16da1dd876b621,0x2083AfCce65cb7B90bB5F674ebbb6d3DD6faE530,0xd8d415806d20a7D1d28758C6BD73285ef2657888,0x6851ea3FB6abaEDBAA46eD92dd437173972b9E74,0x71D744165eC5f61598D192728E23A71D5D4983c8,0xe8A35d12B2Eb667A40063A048F143d61696c6BDd,0xe7EAc73B3076b3ce4889Ff294d736A0B03733cD0,0x8d1360FC5d845CfB438023bA89b4F30C66cfFDEf,0x68517c3aC4e9836605CEf894c2ee54D34084385c,0x2728BD850d20e0d588A7b0d51b9fD4d82f98D94A,0x97d8f0450352e366e96f7F76c290324C2b3627CE,0xb0c3930Ab043540A61E11B080EF9B076d86e760D,0xccf4Ed95207b4be79BE5494Df0d95eb7168E83Ad,0x62706e185595dBd747EAC3A0046b166d7EAa334c,0xbac0Ab0cFB622aBBEe48907bFa21Ba5aBe4deDaE,0x185F0b084cf273535F09a1d9b0b7534F16773d3C,0x1358a36E4f231FFee9be67A6d544e79129eA34F2,0x529BdDE496249E5b3462092Ef84b84315CD3e368],[2,2,1,1,1,2,20,20,2,4,10,21,4,10,1,1,2,2,2,4,4,5,10,10,10,10,10,10,10,10,10,10,10,15,20,20,20,50,50,100,1,8,1,8,1,2,2,10,10,24,1,1,4,4,20,2,2,4,4,8,10,16,4,1,2,10,4,10,13,1,5,120,1,50,1,18,1,2,5,2,1,100]);
    }

    function assignNFT(address[82] memory _addresses, uint8[82] memory _amountOfNFT) public onlyOwner {
        require(_addresses.length == _amountOfNFT.length, "No. of Addresses not equal to No. of NFTs!");
        for(uint i = 0; i < _addresses.length; i++) {
            nftPerAddress[_addresses[i]] = _amountOfNFT[i];
        }
    }

    function setPerAddressNFT(address _address, uint256 _amountOfNFT) public onlyOwner{
        nftPerAddress[_address] = _amountOfNFT;
    }

    function mint(uint256 _mintAmount) public {
        require(isMintActive, "Minting not started yet!");
        require(hasMinted[msg.sender] == false, "You've already minted!");
        require(_mintAmount == nftPerAddress[msg.sender], "You're Not authorized to mint!");
        _mintLoop(msg.sender, _mintAmount);   
        hasMinted[msg.sender] = true;
        nftPerAddress[msg.sender] = 0;
    }

    function setMintStatus(bool _status) public onlyOwner{
        isMintActive = _status;
    }

    function walletOfOwner(address _owner) public view returns (uint[] memory) { 
        uint[] memory _tokensOfOwner = new uint[](balanceOf(_owner)); 

        for (uint i=0; i < balanceOf(_owner);i++){
            _tokensOfOwner[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return (_tokensOfOwner);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        return baseURI;
    }
    
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
    
    function withdraw() public onlyOwner {
        require(address(this).balance >= 0, "contract has no ethers!");
        payable(owner()).transfer(address(this).balance);
    }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
      uint supply = totalSupply();
    for (uint8 i = 0; i < _mintAmount; i++) {
      _safeMint(_receiver, supply+i+1);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}