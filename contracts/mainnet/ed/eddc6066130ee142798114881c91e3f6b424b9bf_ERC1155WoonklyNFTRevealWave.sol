// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./ERC1155Base.sol";

contract ERC1155WoonklyNFTRevealWave is ERC1155Base {
    using SafeMathUpgradeable for uint256;

 
    mapping(uint256 => uint256) public tokens; //tokenId to WaveId
    mapping(uint256 => RevealWave) public waves; //waveId -> RevealWave details

    struct RevealWave {
        bool isRevealed;
        string name;
        string hiddenBaseURI;
        bool addTokenURIToHiddenBaseURI;
        string revealBaseURI;
    }
      /// @dev true if collection is private, false if public
    bool isPrivate;

    event CreateERC1155WoonklyNFT(address owner, string name, string symbol);
    event CreateERC1155WoonklyNFTUser(address owner, string name, string symbol);

    function __ERC1155WoonklyNFTUser_init(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address[] memory operators, address transferProxy, address lazyTransferProxy) external initializer {
        __ERC1155WoonklyNFT_init_unchained(_name, _symbol, baseURI, contractURI, transferProxy, lazyTransferProxy);
        for(uint i = 0; i < operators.length; i++) {
            setApprovalForAll(operators[i], true);
        }

        isPrivate = true;
        emit CreateERC1155WoonklyNFTUser(_msgSender(), _name, _symbol);
    }
    
    function __ERC1155WoonklyNFT_init(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address transferProxy, address lazyTransferProxy) external initializer {
        __ERC1155WoonklyNFT_init_unchained(_name, _symbol, baseURI, contractURI, transferProxy, lazyTransferProxy);

        isPrivate = false;
        emit CreateERC1155WoonklyNFT(_msgSender(), _name, _symbol);
    }

    function __ERC1155WoonklyNFT_init_unchained(string memory _name, string memory _symbol, string memory baseURI, string memory contractURI, address transferProxy, address lazyTransferProxy) internal {
        __Ownable_init_unchained();
        __ERC1155Lazy_init_unchained();
        __ERC165_init_unchained();
        __Context_init_unchained();
        __Mint1155Validator_init_unchained();
        __ERC1155_init_unchained("");
        __HasContractURI_init_unchained(contractURI);
        __ERC1155Burnable_init_unchained();
        __RoyaltiesV2Upgradeable_init_unchained();
        __ERC1155Base_init_unchained(_name, _symbol);
        _setBaseURI("");

        //setting default approver for transferProxies
        _setDefaultApproval(transferProxy, true);
        _setDefaultApproval(lazyTransferProxy, true);
    }

  

    function getRevealWaveIdByTokenId(uint _tokenId) public view returns (uint)
    {
        uint revealWaveId=tokens[_tokenId];
        return revealWaveId;
    }

    function setRevealWave(
        uint _waveId,
        string memory _name,
        string memory _hiddenBaseURI,
        bool _addTokenURIToHiddenBaseURI
    ) public onlyOwner {
        require(bytes(_name).length > 0 && bytes(_hiddenBaseURI).length > 0,"Error: Input parameters can not be empty (string) or equal to 0 (uint)");
        RevealWave storage revealWave = waves[_waveId];
        revealWave.name = _name;
        revealWave.hiddenBaseURI = _hiddenBaseURI;
        revealWave.addTokenURIToHiddenBaseURI = _addTokenURIToHiddenBaseURI;    
    }

    function changeHiddenBaseURI(
        uint _waveId,
        string memory _baseURI
    ) public onlyOwner {
        require(bytes(_baseURI).length > 0,"Error: Input parameters can not be empty (string)");
        RevealWave storage revealWave = waves[_waveId];
        revealWave.hiddenBaseURI = _baseURI;   
    }

    function changeAddTokenURIToHiddenBaseURI(
        uint _waveId,
        bool _addTokenURIToHiddenBaseURI
    ) public onlyOwner {
         RevealWave storage revealWave = waves[_waveId];
        revealWave.addTokenURIToHiddenBaseURI = _addTokenURIToHiddenBaseURI;   
    }

    function changeRevealBaseURI(
        uint _waveId,
        string memory _revealBaseURI
    ) public onlyOwner {
        require(bytes(_revealBaseURI).length > 0,"Error: Input parameters can not be empty (string)");
        RevealWave storage revealWave = waves[_waveId];
        revealWave.isRevealed = true;   
        revealWave.revealBaseURI = _revealBaseURI;
   
    }


    function resetIsRevealedAndRevealURI(
        uint _waveId
    ) public onlyOwner {
         RevealWave storage revealWave = waves[_waveId];
        revealWave.revealBaseURI = "";
        revealWave.isRevealed = false;   
    }


     function changeName(
        uint _waveId,
        string memory _name
    ) public onlyOwner {
        require(bytes(_name).length > 0,"Error: Input parameters can not be empty (string)");
        RevealWave storage revealWave = waves[_waveId];
        revealWave.name = _name;   
    }

 
    function assignRevealWaveIdToTokenId(uint _tokenId, uint _waveId) public onlyOwner
    {
        tokens[_tokenId] = _waveId;
    }

    function _tokenURI(uint256 _tokenId) internal view virtual override returns (string memory)
    {

        uint waveId = getRevealWaveIdByTokenId(_tokenId);
        RevealWave memory revealWave = waves[waveId];

        string memory _tokenURI;
        string memory _baseURI;

        if(revealWave.isRevealed == true || revealWave.addTokenURIToHiddenBaseURI == true)
        {
            _tokenURI = super._tokenURI(_tokenId);
        }

        _baseURI = revealWave.isRevealed == false ? revealWave.hiddenBaseURI : revealWave.revealBaseURI;
 
        if (bytes(_baseURI).length == 0) {
            return _tokenURI;
        }

        return string(abi.encodePacked(_baseURI,_tokenURI));
         
    }

     function uri(uint id) external view override virtual returns (string memory) {
        return _tokenURI(id);
    }

      function mintAndTransfer(LibERC1155LazyMint.Mint1155Data memory data, address to, uint256 _amount) public override {
        if (isPrivate){
          require(owner() == data.creators[0].account, "minter is not the owner");
        }
        super.mintAndTransfer(data, to, _amount);
    }

     
    function mintAndTransferReveal(
        LibERC1155LazyMint.Mint1155Data memory data,
        address to,
        uint256 _amount,
        uint _waveId
    ) public onlyOwner{

        assignRevealWaveIdToTokenId(data.tokenId,_waveId);
        
        mintAndTransfer(data, to,_amount);
    }  
    

    uint256[49] private __gap;
}