// SPDX-License-Identifier: MIT

// Created by HashLips
// The Nerdy Coder Clones

pragma solidity ^0.8.4;

import "./ERC721AQueryable.sol";
import "./Ownable.sol";

contract DoodlesRabbits is ERC721AQueryable, Ownable {
  using Strings for uint256;

  string private baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.04 ether;
  uint256 public maxSupply = 3333;
  uint256 public maxMintAmount = 7;
  bool public paused = false;
  mapping(address => bool) public whitelisted;

  enum  WorkflowStatus {
    PreSale,
    PublicSale,
    Reveal
  }
    
  WorkflowStatus public workflowStatus;

  /** @notice used to listen on workflow status changes
  *   @param _previousStatus the status before 
  *   @param _newStatus the status after */
  event WorkflowStatusChange(WorkflowStatus _previousStatus, WorkflowStatus _newStatus);

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) payable ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);
    whitelisted[msg.sender] = true;
    mint(msg.sender, 1);  
    whitelisted[0x33b1704dc10685AA212ba55497601b6d539BF018] = true;
    whitelisted[0xa9926d10BdDE3cfbe3924bdb29e0AEBdC44D1002] = true;
    whitelisted[0x54C98d7c0FD45A2568DBB8dB49aa7AC2fB1D560e] = true;
    whitelisted[0x6dc22946C6CE08506b8f95d906246Dd61ebF8229] = true;
    whitelisted[0xb9088b32192D8d3B696d07c2100E45AC903B2700] = true;
    whitelisted[0xa4b5F169d47Ec8cDD9d9382e8e6d3f90b1b62Cd6] = true;
    whitelisted[0x9650b865D596d834F984b1ca55927a1423601D10] = true;
    whitelisted[0x6dc22946C6CE08506b8f95d906246Dd61ebF8229] = true;
    whitelisted[0x3C102A95219dc05d4FC211299Ece2cD5b736a0F0] = true;
    whitelisted[0x90f3490B7AbCe5956EbB4B0A375e5A5F17E7Df5e] = true;

    whitelisted[0xd0e6D9dcA395C3E0C87D59c8e0Eb454D059202A7] = true;
    whitelisted[0x4E77cc592cf4d36F8b5cdb17a780d79Ab89fde6E] = true;

    whitelisted[0x462726579936BC84f32c190387A186e4460e9deF] = true;
    whitelisted[0xBBC15B0eF478722a6f0F99617d6aed04f18A3206] = true;
    whitelisted[0x16861e0380C0B5b3BF3d69838d8719A41B612830] = true;
    whitelisted[0x482c2895384f48Cb776d9f7108D3c303291f2EBf] = true;
    whitelisted[0x6dc22946C6CE08506b8f95d906246Dd61ebF8229] = true;
    whitelisted[0xA831Ba9DDB8E552301A8f30437A97AA3d7690E21] = true;
    whitelisted[0xD232C7a4AB5B43c15d2064D35faD61D5897b863F] = true;
    whitelisted[0x0BFBdfCB775CE97C708419F89F68de5621B1A515] = true;
    whitelisted[0x671CD099c370cde378527d00E77d8c7Ecc798f01] = true;
    whitelisted[0x8cAF12984bd88ae0032A864b87F4D6580B101A0a] = true;

    whitelisted[0x8C3D441b5E435115d3D6cCAbE7F4D4b947D47953] = true;
    whitelisted[0x116f01D799D722E3aeA4c701EA3e2DC2409E7A50] = true;
    whitelisted[0xa4b5F169d47Ec8cDD9d9382e8e6d3f90b1b62Cd6] = true;
    whitelisted[0x9aE3856857265B99764934023bb0e29d3f46EAe8] = true;
    whitelisted[0x615aF40045a2A07b413FC3082b969E8CB5A6c157] = true;
    whitelisted[0xC8E9Ba58eC507C6e3d05a06C74436a9693152308] = true;
    whitelisted[0x4d99dD17D82D4a7B7AD6B234419C724Ab1CEc7B2] = true;
    whitelisted[0x09C7533cC31fCB722471D95D646665213D61c8a0] = true;
    whitelisted[0x31d70eE77BFd82DD621afbb9d32F2DC9f99487cA] = true;
    whitelisted[0x8a507b3fe196EF545ae8171F4F5Ed86F0353a777] = true;
    whitelisted[0x3D75e27e9A48ffd0f6e0847158573a9bD2170CAf] = true;
    whitelisted[0xEe84f746d36425b09fcb9d44eA1B5aBD3E159F4f] = true;
    whitelisted[0x3fEF6dcCe6D45c54D4E41B5A79968B3269612645] = true;
    whitelisted[0xc65837DeEd8b5a96A3ae78B4303648250D33F389] = true;
    whitelisted[0x5A437074420882055757F004A965ecfC57bBf89D] = true;
    whitelisted[0x6765CE5b1eBD492f3B50cCa56dD38dE1d3c57389] = true;
    whitelisted[0xBf4b61A8B9974766769Ed7DFD22D1C96647174DC] = true;
    whitelisted[0x5f98A5c6eE6c387692b1aF27Ec3B118053135d81] = true;
    whitelisted[0x000D8202C5bc08085d1cF86E2C24BA84b471860D] = true;
    whitelisted[0xdd0f3BAf1b4Db8052F2D2C3684a816ca1583fB78] = true;
    whitelisted[0x89d833755e3eB949dc105521Ebc376366562609f] = true;
    whitelisted[0x5543FF13829F0D5B9a23A487863623855f7Ee7FE] = true;
    whitelisted[0xcF690F05D9b3E88164371182F2eDa3E3349175D4] = true;
    whitelisted[0xc15e404473B0a411345D85687a9Ee18f92248191] = true;
    whitelisted[0x92BF1F71D8647819474AC6a04A0bD1741FBd6b7C] = true;
    whitelisted[0x0332939ab6Fea4121E221D15FE6ad4C457b7A3A4] = true;
    whitelisted[0x95B9F00646E1018096e6F8D3FeE616730CfaBd0F] = true;
    whitelisted[0x97760A184FC572469d666d47F5432c12bE08d9Ce] = true;
    whitelisted[0x08249B656DaA07DBC37D717cddEFc5e60efee5Bc] = true;
    whitelisted[0xae5c686d145AeA086ee6795662981FCb0D4a142a] = true;
    whitelisted[0x31d70eE77BFd82DD621afbb9d32F2DC9f99487cA] = true;
    whitelisted[0x19a89ee05fFe2818Baee0f59491d184D1348D3A1] = true;
    whitelisted[0x38118e79E96852121Ab4C7d067B648B34E0AAc88] = true;
    whitelisted[0x5fdb15ece12b5e61717643be812100a587AbF8Ef] = true;
    whitelisted[0x19a89ee05fFe2818Baee0f59491d184D1348D3A1] = true;
    whitelisted[0x2Ff8d99087159d9798220932f5a961885A4b8790] = true;
    whitelisted[0xEad598b108E88C14AE28d5B4096a67C639BE0658] = true;
    whitelisted[0xe96ECe2e9D33363cdcD20C495510CDf45bE4DE1a] = true;
    whitelisted[0x54C98d7c0FD45A2568DBB8dB49aa7AC2fB1D560e] = true;
    whitelisted[0x7882c52dae000AacB97BD4e6DdAb3264ffA883f3] = true;
    whitelisted[0x7821B04eB55525ff3fe342bAa1459CF2ced1DB0a] = true;
    whitelisted[0x69e9541Bae37fd07cFfcf4Bb9f1816B0121cdeeC] = true;
    whitelisted[0xd9bE72A803cAA9B2eA0fb20F95eca03Bb2bC16dF] = true;
    whitelisted[0xbE86cb7dcE510cc6694a00658B8A3A977E26a6C3] = true;

    whitelisted[0xb1193Bfd53865a0103B7dd06cD1DDe2BaDC18CEc] = true;
    whitelisted[0xdd0f3BAf1b4Db8052F2D2C3684a816ca1583fB78] = true;
    whitelisted[0x7C734e4c677334a6480c4634bBB1AEbe714dE129] = true;
    whitelisted[0xA3069CFA9C0aA758965E29285b24090e816e2308] = true;
    whitelisted[0xeD1F0B1271688F158aBC4E21884f1CA49495cee0] = true;
  }

  /** @notice next workflowstatus : 1 -> 2 */
  function startReveal() external onlyOwner {
    require(workflowStatus == WorkflowStatus.PublicSale, "DoodlesRabbits: Public sale cant be started now");
    workflowStatus = WorkflowStatus.Reveal;
    
    emit WorkflowStatusChange(WorkflowStatus.PublicSale, WorkflowStatus.Reveal);
  }

  /** @notice next workflowstatus : 0 -> 1 */
  function startPublicSale() external onlyOwner {
    require(workflowStatus == WorkflowStatus.PreSale, "DoodlesRabbits: Reveal cant be started now");
    workflowStatus = WorkflowStatus.PublicSale;
    emit WorkflowStatusChange(WorkflowStatus.PreSale, WorkflowStatus.PublicSale);
  }


  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (workflowStatus == WorkflowStatus.PreSale) {
      require(whitelisted[msg.sender] == true, "DoodlesRabbits: you are not registered");
      require(msg.value >= 0.03 ether * _mintAmount, "DoodlesRabbits: send more money");
    }
    
    if (workflowStatus == WorkflowStatus.PublicSale) {
      require(msg.value >= cost * _mintAmount, unicode"DoodlesRabbits: растению требуется больше воды");
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
  }


function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(workflowStatus == WorkflowStatus.Reveal, "DoodlesRabbits: You're not allow");
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    require(payable(msg.sender).send(address(this).balance));
  }
}