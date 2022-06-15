//SPDX-License-Identifier: MIT

//Author: @hodl_pcc << twitter

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./registration-rules.sol";
import "./interfaces/IERC2981.sol";
import "./interfaces/IENSToken.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IMetadata.sol";
import "./interfaces/IRegister.sol";
import "./interfaces/IENSAdmin.sol";
import "./interfaces/IReverseResolver.sol";
import "./interfaces/ICCIPResolver.sol";
import "./metadata-provider.sol";
import "./ENSEnumerable.sol";
import "./EnsTldWrapper.sol";

pragma solidity ^0.8.13;


struct EnsInfo {
    uint256 id;
    string domain;
    uint256 royalty;
    address owner;
    bool locked;
    uint256 price;
    string image;
    bytes32 domainHash;
    address currentLocation;
    uint256 expiry;

}

contract SubdomainFactory is  IManager, IERC721Receiver, Ownable, ERC165, ERC721, IERC2981, ENSEnumerable {

    using SafeMath for uint256;
    using Strings for uint256;

    event DepositEns(address indexed _from, uint256 indexed _id, string _domainLabel);
    event TransferEnsOwnership(address indexed _from, address indexed _to, uint256 indexed _id);
    event WithdrawEns(address indexed _to, uint256 indexed _id);
    event WithdrawFunds(address indexed _addr, uint256 _funds);
    event UpdateDomainDefaultImage(address indexed _addr, uint256 indexed _id, string _image);
    event UpdateDomainDefaultMintPrice(address indexed _addr, uint256 indexed _id, uint256 _defaultPriceInWei);
    event UpdateDomainRoyaltyPercentage(address indexed _addr, uint256 indexed _id, uint256 _percentage);
    event UpdateDomainRegistrationRules(address indexed _addr, uint256 indexed _id, address indexed _registrationStrategy);
    event LockEnsDomain(address indexed _addr, uint256 indexed _id);
    event SubdomainRegistered(address indexed _addr, uint256 indexed _id, uint256 indexed _subdomainId, string _subDomain);
    event SetSubdomainRedirect(address indexed _from, address indexed _to, uint256 indexed _subdomainId);

    address constant ENS_ADDRESS = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    address constant PUBLIC_RESOLVER_ADDRESS = 0xf6305c19e814d2a75429Fd637d01F7ee0E77d615;
    address constant REVERSE_RESOLVER_ADDRESS = 0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c;
    address constant ENS_TOKEN_ADDRESS = 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85;

    IReverseResolver public ReverseResolver = IReverseResolver(REVERSE_RESOLVER_ADDRESS);
    IENSAdmin public PublicResolver = IENSAdmin(PUBLIC_RESOLVER_ADDRESS);
    IENSToken public EnsToken = IENSToken(ENS_TOKEN_ADDRESS);
    ENS private ens = ENS(ENS_ADDRESS); 

    EnsTldWrapper public EnsWrapper;
    IRegister public DefaultRegister;
    ICCIPResolver public CCIPResolver;
    bool public CCIPResolverLocked;   
    IMetadata public MetaData;
    uint256 private currentId; 
    uint256 public ContractOwnerPrimaryRoyalties = 2;
    uint256 public MinDomainExpiry = 90 days;
    mapping(uint256 => address) public TokenOwnerMap;
    mapping(uint256 => bool) public TokenLocked;
    mapping(bytes32 => uint256) public HashToIdMap;
    mapping(uint256 => bytes32) public IdToHashMap;
    mapping(uint256 => uint256) public IdToOwnerId;
    mapping(uint256 => string) public IdToLabelMap;
    mapping(uint256 => IRegister) public IdToRegisterMap;
    mapping(uint256 => bool) public IdToUseCCIPMap;
    mapping(address => mapping(uint256 => address)) public RedirectAddress;
    mapping(bytes32 => mapping(string => string)) public texts;
    mapping(uint256 => string) public IdToDomain;
    mapping(uint256 => uint256) public IdRoyaltyMap;
    mapping(uint256 => string) public IdImageMap;
    mapping(uint256 => uint256) public DefaultMintPrice;
    mapping(address => uint256) public OwnerFunds;

    uint256 public ContractOwnerFunds;

    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    uint256 public DepositCost = 0.01 ether;

    constructor() ERC721("ENS sub-domains", "ESF"){
         MetaData = new MetadataProviderV1(this);
         DefaultRegister = new RegistrationRulesV1(this);
         EnsWrapper = new EnsTldWrapper(this);
         EnsWrapper.transferOwnership(msg.sender); //just so can update metadata link
    }

    function onERC721Received(
        address operator,
        address from,   
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        require(address(this) == operator, "only transfer from contract address");
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }


    fallback() payable external {
        ContractOwnerFunds += msg.value;
    }

    receive() payable external {
        ContractOwnerFunds += msg.value;
    }

    function withdrawEns(uint256 _id) external tokenOwner(_id) {

        require(!TokenLocked[_id], "token is locked");
        EnsToken.safeTransferFrom(address(this), msg.sender, _id);
        EnsWrapper.burn(_id);
        _beforeTLDTransfer(msg.sender, address(0), _id);

        emit WithdrawEns(msg.sender, _id);
    }


function depositEns(string calldata _label, uint256 _royalty, uint256 _mintPrice, string calldata _defaultImageUri) payable external {
    depositEns(_label, _royalty, _mintPrice, _defaultImageUri, DefaultRegister, false);
}

    //only pay for the first deposit of a token.
    function getDepositCost(uint256 _id) public view returns(uint256) {
        return TokenOwnerMap[_id] == address(0) ? DepositCost : 0;
    }

    function getSubdomainCost(uint256 _tokenId, string calldata _label, address _addr, bytes32[] calldata _proofs) external view returns (uint256){
        require(EnsToken.ownerOf(_tokenId) == address(this), "token not in contract");
        return IdToRegisterMap[_tokenId].mintPrice(_tokenId, _label, _addr, _proofs);
    }
    ///Deposit the ENS token and register it for sub-domain creation
    ///This costs the fixed amount that is set by the contract owner
    ///@param _label label of the .eth domain that is being deposited
    // the id is worked out from the text
    ///@param _royalty Royalty % should be integer 0 - 10
    ///@param _mintPrice should be more than 0.01 ether
    function depositEns(string calldata _label, uint256 _royalty, uint256 _mintPrice, string calldata _defaultImageUri, IRegister _registrationStrategy, bool _useCCIP) payable public {
        uint256 id = getIdFromLabel(_label);
        require(msg.value == getDepositCost(id), "incorrect ether");             
        require(EnsToken.nameExpires(id) > (block.timestamp.add(MinDomainExpiry)), "domain expires too early");

        EnsToken.reclaim(id, address(this));
        bytes32 domainHash = getDomainHash(_label);

        if (ens.resolver(domainHash) != address(PublicResolver) 
            && (!_useCCIP || address(CCIPResolver) == address(0))){

                ens.setResolver(domainHash, address(PublicResolver));
        }

        //if resolver is already set to public and _useCCIP is false then do nothing

        if (_useCCIP && address(CCIPResolver) != address(0)){
            ens.setResolver(domainHash, address(this));
            IdToUseCCIPMap[id] = true;
        }

        EnsToken.safeTransferFrom(msg.sender, address(this), id);
        TokenOwnerMap[id] = msg.sender;
        IdToDomain[id] = _label;

        IdToRegisterMap[id] = _registrationStrategy;

        ContractOwnerFunds = ContractOwnerFunds.add(msg.value);

        if(_royalty > 0){
            setRoyaltyPercent(id, _royalty);            
        }

        if(_mintPrice > 0){
            setMintPrice(id, _mintPrice);                      
        }

        if(bytes(_defaultImageUri).length > 0){
            setSubdomainImageUri(id, _defaultImageUri);           
        }

        IdToRegisterMap[id] = _registrationStrategy;

        emit UpdateDomainRegistrationRules(msg.sender, id, address(_registrationStrategy));
        emit DepositEns(msg.sender, id, _label);

        //if the token has expired then it may be redeposited
        if(EnsWrapper.exists(id)){
            EnsWrapper.burn(id);
            TokenLocked[id] = false;
            _beforeTLDTransfer(msg.sender, address(0), id);
        }

            EnsWrapper.mint(msg.sender, id);
            _beforeTLDTransfer(address(0), msg.sender, id);                 
    }

    ///helper method for getting ens id from the domain label
    function getIdFromLabel(string calldata _label) public pure returns(uint256 id) {
        bytes32 labelHash = keccak256(abi.encodePacked(_label));
        id = uint256(labelHash);
    }

    ///function to register sub-domain
    ///@param _id token id of the parent ens domain
    ///@param _label label for the subdomain, should be lower-case, numeric not uppercase
    function registerSubdomain(uint256 _id, string calldata _label, bytes32[] calldata _proofs) payable public {
        address owner = TokenOwnerMap[_id];
        //owner can always mint sub-domains of their TLD
        if (msg.sender != owner){
            //use ID specific registration strategy    
            //can be used for whitelist minting / payment strategy / label exclusion etc        
            require(IdToRegisterMap[_id].canRegister(_id, _label, msg.sender, msg.value, _proofs));
        }

        uint256 ownerCut;

        if (msg.value > 0){
            //owner primary cut is maximum 5% (set at 2% for contract deployment, unlikely to change)
            ownerCut = (msg.value / 100) * ContractOwnerPrimaryRoyalties;
            ContractOwnerFunds = ContractOwnerFunds.add(ownerCut);
            OwnerFunds[owner] = OwnerFunds[owner].add(msg.value - ownerCut);
        }

        register(_id, _label, msg.sender);       
    }

    function register(uint256 _tokenId, string memory _label, address _addr) private {
        bytes32 encoded_label = keccak256(abi.encodePacked(_label));
        bytes32 domainHash = getDomainHash(IdToDomain[_tokenId]);
        bytes32 hashed = keccak256(abi.encodePacked(domainHash, encoded_label));

        //we only check this contract for minted sub-domains. If you wish to protect sub-domains
        //registered externally then these will require specifying in some custom registration rules
        require(HashToIdMap[hashed] == 0, "sub-domain already exists");

        //start from ID 1, this is because of the above check ^^
        uint256 id = ++currentId;

        IdToHashMap[id] = hashed;
        HashToIdMap[hashed] = id;
        _safeMint(_addr, id);
        IdToOwnerId[id] = _tokenId; //_tokenId is the parent ens id
        IdToLabelMap[id] = _label;
        ens.setSubnodeRecord(domainHash, encoded_label, address(this), address(this), 0);

        emit SubdomainRegistered(_addr, _tokenId, id, name(hashed));
    }


    ///@param node nodes representaion of the full domain
    ///@param key key of the key:value pair to return
    ///@return value of the key. avatar is default but it can be overridden
    function rawText(bytes32 node, string calldata key) public view returns (string memory) {
        string memory value = texts[node][key];
        
        if(keccak256(abi.encodePacked(key)) == keccak256("avatar") && bytes(value).length == 0){
            uint256 id = HashToIdMap[node];
            uint256 owner = IdToOwnerId[id];
            value = IdImageMap[owner];
        }

        return value;
    }


    ///interface method
    ///@param node nodes representaion of the full domain
    ///@param key key of the key:value pair to return
    ///@return value of the key. avatar is default but it can be overridden
    function text(bytes32 node, string calldata key) external view returns (string memory) {
        uint256 id = HashToIdMap[node];
        //added ccip proxy resolver to "future proof"
        if (shouldUseCcipResolver(IdToOwnerId[id])) {
            return CCIPResolver.text(node, key);
        }
        else {
            return rawText(node, key);
        }
    }

    //standard interface method
    function addr(bytes32 nodeID) public view returns (address) {
        uint256 id = HashToIdMap[nodeID];

        //added in ccip resolver to "future proof"
        if (shouldUseCcipResolver(IdToOwnerId[id])) {
            return CCIPResolver.addr(nodeID);
        }
        else {
            address owner = ownerOf(id);
            address redirect = RedirectAddress[owner][id];
            return (redirect == address(0)) ? owner : redirect;
        }
    }

    function shouldUseCcipResolver(uint256 _id) private view returns(bool){
        //0 for wildcard entries.. will need to add extra logic inside of registration
        //rules to stop off-chain sub-domains being reregistered
        return (IdToUseCCIPMap[_id] || _id == 0) 
                && address(CCIPResolver) != address(0);
    }


    function name(bytes32 node) view public returns (string memory){
        uint256 id = HashToIdMap[node];
        uint256 owner = IdToOwnerId[id];

        //added in ccip resolver to "future proof"
        if (shouldUseCcipResolver(owner)) {
            return CCIPResolver.name(node);
        }
        else {

            string memory domain = IdToDomain[owner];
            string memory label = IdToLabelMap[id];
            return string(abi.encodePacked(label,".",domain,".eth"));
        }
    }

    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC165, ERC721) returns(bool){
        return super.supportsInterface(interfaceId) 
        || interfaceId == 0x3b3b57de //addr
        || interfaceId == 0x59d1d43c //text
        || interfaceId == 0x691f3431 //name
        || interfaceId == 0x2a55205a //royalties
        || interfaceId == 0x01ffc9a7; //supportsInterface << [inception];
    }
    ///this is the correct method for creating a 2 level ENS namehash
    function getDomainHash(string memory _domain) public pure returns (bytes32 namehash) {
            namehash = 0x0;
            namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked('eth'))));
            namehash = keccak256(abi.encodePacked(namehash, keccak256(abi.encodePacked(_domain))));
    }

    function tokenURI(uint256 tokenId) public view  override(ERC721) returns(string memory){
        require(_exists(tokenId), "token does not exist");

        return MetaData.tokenURI(tokenId);
    }

    //user can set an address redirect for any delegated address. The redirect is only active
    //whilst the NFT is in the wallet that set it. Set to `0x0000000000000000000000000000000000000000`
    //to remove redirect
    function setRedirect(uint256 _id, address _to) external {
        //token checked if it exists in _isApprovedOrOwner method
        require(_isApprovedOrOwner(msg.sender, _id), "not approved");

        RedirectAddress[ownerOf(_id)][_id] = _to;
        emit SetSubdomainRedirect(msg.sender, _to, _id);
    }

    function setText(bytes32 node, string calldata key, string calldata value) external {
        uint256 token_id = HashToIdMap[node];
        require(_exists(token_id), "token does not exist");
        require(_isApprovedOrOwner(msg.sender, token_id), "not approved");
        
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

///token owner functions

    ///This is the royalty percentage for secondary sales. It's set per sub-domain
    ///owner of the TLD can set this 0-10%, this works on all marketplaces that support 
    ///on-chain royalties :-)
    function setRoyaltyPercent(uint256 _id, uint256 _percent) public tokenOwner(_id) {
        require(_percent <= 10, "max 10 percent");

        IdRoyaltyMap[_id] = _percent;
        emit UpdateDomainRoyaltyPercentage(msg.sender, _id, _percent);
    }

    ///token owner can set mint price. 0 mint price means that it is not for minting by
    ///anyone apart from the token owner. Additional logic for mint price can be applied 
    ///in custom registration-rules that can be applied to any ENS domain. eg. you want to charge
    ///more for shorter labels / give certain wallets reduced price, many other ideas
    function setMintPrice(uint256 _id, uint256 _price) public tokenOwner(_id) {

        require(_price >= 0.01 ether || _price == 0, "min 0.01 ether");
        DefaultMintPrice[_id] = _price;
        emit UpdateDomainDefaultMintPrice(msg.sender, _id, _price); 
    }

    ///this is the default image that will display when users mint a sub-domain. This can be overridden
    ///by the user setting a value for the 'avatar' key in their text mappings
    function setSubdomainImageUri(uint256 _id, string calldata _uri) tokenOwner(_id) public {
        
        IdImageMap[_id] = _uri;
        emit UpdateDomainDefaultImage(msg.sender, _id, _uri);
    }

    ///proxy method so that the TLD owner can still manage various public resolver
    ///functions for their token despite it being contained in this contract
    function setTldAddr(uint256 _id, uint256 coinType, bytes  memory a) tokenOwner(_id) public {
        bytes32 node = getDomainHash(IdToDomain[_id]);
        PublicResolver.setAddr(node, coinType, a);
    }

    function setTldAddr(uint256 _id, address a) tokenOwner(_id) public {
        bytes32 node = getDomainHash(IdToDomain[_id]);
        PublicResolver.setAddr(node, a);
    }

    function setTldDNSRecords(uint256 _id, bytes memory data) tokenOwner(_id) public {
        bytes32 node = getDomainHash(IdToDomain[_id]);
        PublicResolver.setDNSRecords(node, data);
    }

    function setTldText(uint256 _id, string memory key, string memory value) tokenOwner(_id) public {
        bytes32 node = getDomainHash(IdToDomain[_id]);
        PublicResolver.setText(node, key, value);
    }


    ///use this method to update the registration stategy for any ENS domains. Can only be called by the 
    ///account that owns the tokens. Can update multiple at the same time.
    function updateRegistrationStrategy(uint256[] calldata _ids, IRegister _registrationStrategy) public {
        for(uint256 i; i < _ids.length;){
            require(TokenOwnerMap[_ids[i]] == msg.sender, "not owner");

            IdToRegisterMap[_ids[i]] = _registrationStrategy;

            emit UpdateDomainRegistrationRules(msg.sender, _ids[i], address(_registrationStrategy));

            //we do this because it's the most gas efficient way of doing the loop          
            unchecked { ++i; }
        }
    }

    ///I don't really like ccip, but need to make sure we provide a way of updating this in the future if it
    ///matures to a usable state.
    function updateUseCCIPResolver(uint256[] calldata _ids, bool _shouldUse) public {
        require(address(CCIPResolver) != address(0), "ccip resolver not set");
        for(uint256 i; i < _ids.length;){
            require(TokenOwnerMap[_ids[i]] == msg.sender, "not owner");

            IdToUseCCIPMap[_ids[i]] = _shouldUse;
            
            ens.setResolver(getDomainHash(IdToDomain[_ids[i]])
                            , _shouldUse ? address(this) : address(PublicResolver)
                            );

            //we do this because it's the most gas efficient way of doing the loop
            unchecked { ++i; }
        }        
    }

    ///this action cannot be undone. locked domain will remain permenantly locked in the contract unless
    ///it expires (remember that anyone can renew a domain, so it is our intention that project funds could be 
    ///redirected to fund renewals for popular domains)
    function lockDomain(uint256 _id) tokenOwner(_id) public {
        require(EnsToken.ownerOf(_id) == address(this), "token not in contract");
        require(!TokenLocked[_id], "token already locked");
        TokenLocked[_id] = true;

        emit LockEnsDomain(msg.sender, _id);
    }

///end token owner functions
//
// ------------------------------------

    ///if the "wrapped" ens domain is transferred then this method is called which will change the ownership
    ///of the domain for admin and payout purposes. We can't just link to the owner of this token because
    ///it is burned when the ENS is withdrawn.
    function transferDomainOwnership(uint256 _id, address _newOwner) external {       
        require(address(EnsWrapper) == msg.sender, "only through EnsWrapper transfer");
        address currentOwner = TokenOwnerMap[_id];
        TokenOwnerMap[_id] = _newOwner;
       
        _beforeTLDTransfer(currentOwner, _newOwner, _id);
        emit TransferEnsOwnership(currentOwner, _newOwner, _id);
    }

    ///this is for the ENS owners to withdraw primary sales. It's collected by wallet not by ID
    ///so that only 1 withdrawal is required and if a domain is sold then previous sales can still be
    ///claimed by the original owner.
    function withdrawPrimarySalesFunds() external  {        
        require(OwnerFunds[msg.sender] > 0, "no funds to claim");
        
        //we do this like this to prevent re-entrency
        uint256 balance = OwnerFunds[msg.sender];
        OwnerFunds[msg.sender] = 0;
        payable(msg.sender).transfer(balance);

        emit WithdrawFunds(msg.sender, balance);
    }

///contract owner functions

    ///contract owner to set default registration strategy. This will not alter any exsting domains that 
    ///are using the current default strategy only future registered ones. currently the default
    ///registration strategy is quite basic so there is lots of room to be able to improve this in the future
    function updateDefaultRegister(IRegister _registrationStrategy) external onlyOwner {
        DefaultRegister = _registrationStrategy;
    }

    ///contract owner withdraw for any primary sale commission / 
    function contractOwnerWithdrawFunds() external onlyOwner {        
        require(ContractOwnerFunds > 0, "no funds to claim");
        
        //we do this like this to prevent re-entrency
        uint256 balance = ContractOwnerFunds;
        ContractOwnerFunds = 0;
        payable(msg.sender).transfer(balance);
    }

    function setCCIPResolver(ICCIPResolver _ccip) onlyOwner external {
        require(!CCIPResolverLocked, "resolver already locked");
        CCIPResolver = _ccip;
    }

    function setCCIPLocked() onlyOwner external {
        require(!CCIPResolverLocked, "resolver already locked");
        CCIPResolverLocked = true;
    }

    function setMetadataContract(IMetadata _metadata) onlyOwner external {
        MetaData = _metadata;
    }

    function setDepositCost(uint256 _priceInWei) onlyOwner external {
        DepositCost = _priceInWei;
    }

    ///contract owner percentage for primary sales. this cannot be set to higher than 5%
    ///probably set to 2% when the contract is initially deployed
    function setContractOwnerPrimaryRoyalty(uint256 _percent) onlyOwner external {
        require(_percent <= 5, "max 5 percent");
        ContractOwnerPrimaryRoyalties = _percent;
    }

    //set the minimum requirement for a deposited domain to expire. 30 days seems low, default is 90 days
    function setMinDomainExpiryForDeposit(uint256 _minNumberOfDays) onlyOwner external {
        MinDomainExpiry = (_minNumberOfDays * 1 days);
        require(MinDomainExpiry >= 30 days, "must be minimum of 30 days");
    }

    ///underutilised ENS functionality. Naming a contract using the reverse registrar
    function setContractName(string calldata _name) onlyOwner external {
        ReverseResolver.setName(_name);
    }

/// <end> contract owner functions
//
// ------------------------------------

    ///IERC2981 interface method for on-chain royalty. This is so we can charge different royalty %
    ///per ENS domain and also pay out to the contract owner. This standard is only supported by good reputable
    ///ethereum marketplaces
    function royaltyInfo( 
    uint256 _tokenId,
    uint256 _salePrice
        ) external view returns (
            address receiver,
            uint256 royaltyAmount
        ){
            uint256 parentId = IdToOwnerId[_tokenId];
            address owner = TokenOwnerMap[parentId];
            uint256 percent = IdRoyaltyMap[parentId];
            uint256 royalty = _salePrice.div(100).mul(percent);

            return (owner, royalty);
        }

   ///read method to get some information for the UI
    function getTokenInfo(uint256[] calldata _ids) external view returns(EnsInfo[] memory){
        EnsInfo[] memory infos = new EnsInfo[](_ids.length);

        for(uint256 i; i < _ids.length;){
            infos[i] = getInfo(_ids[i]);
            unchecked { ++i; }
        }

        return infos;
    }

    function getInfo(uint256 _id) private view returns(EnsInfo memory){
        EnsInfo memory info;

        info.id = _id;
        info.domain = IdToDomain[_id];
        info.royalty = IdRoyaltyMap[_id];
        info.owner = TokenOwnerMap[_id];
        info.locked = TokenLocked[_id];
        info.price = DefaultMintPrice[_id];
        info.image = IdImageMap[_id];
        info.domainHash = getDomainHash(info.domain);
        info.currentLocation = EnsToken.ownerOf(_id);
        info.expiry = EnsToken.nameExpires(_id);
    
        return info;
    }

        function tldBalanceOf(address _addr) public view returns(uint256){
            return TLDBalances[_addr];
        }

        function totalSupply() public view returns(uint256){
            return currentId;
        }

   modifier tokenOwner(uint256 _id) {
        require(TokenOwnerMap[_id] == msg.sender, "is not owner");
      _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

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
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

pragma solidity >=0.8.4;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external virtual;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external virtual returns(bytes32);
    function setResolver(bytes32 node, address resolver) external virtual;
    function setOwner(bytes32 node, address owner) external virtual;
    function setTTL(bytes32 node, uint64 ttl) external virtual;
    function setApprovalForAll(address operator, bool approved) external virtual;
    function owner(bytes32 node) external virtual view returns (address);
    function resolver(bytes32 node) external virtual view returns (address);
    function ttl(bytes32 node) external virtual view returns (uint64);
    function recordExists(bytes32 node) external virtual view returns (bool);
    function isApprovedForAll(address owner, address operator) external virtual view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

import "./interfaces/IManager.sol";
import "./interfaces/IRegister.sol";


pragma solidity ^0.8.13;

contract RegistrationRulesV1 is IRegister {

    IManager public DomainManager;
    constructor(IManager _manager){
        DomainManager = _manager;
    }

    function canRegister(uint256 _tokenId, string calldata _label, address _addr, uint256 _priceInWei, bytes32[] calldata _proofs) external view returns(bool){
        uint256 price = DomainManager.DefaultMintPrice(_tokenId);
        require(price == _priceInWei, "incorrect ether");
        require(price != 0, "not for primary sale");
        return true;
    }

    function mintPrice(uint256 _tokenId, string calldata _label, address _addr, bytes32[] calldata _proofs) external view returns(uint256){
        uint256 price = DomainManager.DefaultMintPrice(_tokenId);
        address owner = DomainManager.TokenOwnerMap(_tokenId);
        return owner == _addr ? 0 : price;
    }
 
}

//SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

pragma solidity ^0.8.13;

interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (
        address receiver,
        uint256 royaltyAmount
    );
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


interface IENSToken {
    function nameExpires(uint256 id) external view returns(uint256);
    function reclaim(uint256 id, address addr) external;
    function setResolver(address _resolverAddress) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.13;

interface IManager {

function IdToLabelMap( uint256 _tokenId) external view returns (string memory label);
function IdToOwnerId( uint256 _tokenId) external view returns (uint256 ownerId);
function IdToDomain( uint256 _tokenId) external view returns (string memory domain);
function TokenLocked( uint256 _tokenId) external view returns (bool locked);
function IdImageMap( uint256 _tokenId) external view returns (string memory image);
function IdToHashMap(uint256 _tokenId) external view returns (bytes32 _hash);
function text(bytes32 node, string calldata key) external view returns (string memory _value);
function DefaultMintPrice(uint256 _tokenId) external view returns (uint256 _priceInWei);
function transferDomainOwnership(uint256 _id, address _newOwner) external;
function TokenOwnerMap(uint256 _id) external view returns(address); 
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IMetadata {
    function tokenURI(uint256 tokenId) external view returns(string memory);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRegister {
    function canRegister(uint256 _tokenId, string memory _label, address _addr, uint256 _priceInWei, bytes32[] calldata _proofs) external view returns(bool);
    function mintPrice(uint256 _tokenId, string calldata _label, address _addr, bytes32[] calldata _proofs) external view returns(uint256);
    
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


interface IENSAdmin {
    function setAddr(bytes32 node, uint256 coinType, bytes  memory a) external;
    function setAddr(bytes32 node, address a) external;
    function setDNSRecords(bytes32 node, bytes memory data) external;
    function setText(bytes32 node, string memory key, string memory value) external;

}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IReverseResolver {
    function setName(string memory name) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


interface ICCIPResolver {
    function text(bytes32 _node, string calldata _key) external view returns(string memory _value);
    function addr(bytes32 _node) external view returns(address _addr);
    function name(bytes32 node) external view returns (string memory);
}

//SPDX-License-Identifier: MIT


import "@ensdomains/ens-contracts/contracts/registry/ENS.sol";
import "./interfaces/IENSToken.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IMetadata.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.13;

contract MetadataProviderV1 is IMetadata {

    using Strings for uint256;

    IManager public Manager;
    ENS private ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e); 
    IENSToken public ensToken = IENSToken(0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85);
    string public DefaultImage = 'ipfs://QmYWSU93qnqDvAwHGEpJbEEghGa7w7RbsYo9mYYroQnr1D'; //QmaTFCsJ9jsPEQq9zgJt9F38TJ5Ys3KwVML3mN1sZLZbxE

    constructor(IManager _manager){
        Manager = _manager;
    }

   function tokenURI(uint256 tokenId) public view returns(string memory){
        
        string memory label = Manager.IdToLabelMap(tokenId);

        uint256 ownerId = Manager.IdToOwnerId(tokenId);
        string memory parentName = Manager.IdToDomain(ownerId);
        string memory ensName = string(abi.encodePacked(label, ".", parentName, ".eth"));
        string memory locked = (ensToken.ownerOf(ownerId) == address(Manager)) && (Manager.TokenLocked(ownerId)) ? "True" : "False";
        string memory image = Manager.IdImageMap(ownerId);

        bytes32 hashed = Manager.IdToHashMap(tokenId);
        string memory avatar = Manager.text(hashed, "avatar");
        address resolver = ens.resolver(hashed);
        string memory active = resolver == address(Manager) ? "True" : "False";

        uint256 expiry = ensToken.nameExpires(ownerId);
        
        return string(  
            abi.encodePacked(
                'data:application/json;utf8,{"name": "'
                , ensName
                , '","description": "Transferable '
                , parentName
                , '.eth sub-domain","image":"'
                , bytes(avatar).length == 0 ? 
                    (bytes(image).length == 0 ? DefaultImage : image)
                    : avatar
                , '","attributes":[{"trait_type" : "parent name", "value" : "'
                , parentName
                , '.eth"},{"trait_type" : "parent locked", "value" : "'
                , locked
                , '"},{"trait_type" : "active", "value" : "'
                , active
                , '" },{"trait_type" : "parent expiry", "display_type": "date","value": ', expiry.toString(), '}]}'
                        )
                            );               
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


/**
 * @dev Adapted this from the ERC721Enumerable extension
 */
abstract contract ENSEnumerable  {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(address => uint256) public TLDBalances;

    /**
     * @dev 
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < TLDBalances[owner], "ENSEnumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev 
     */
    function totalTLDCount() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev 
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalTLDCount(), "ENSEnumerable: global index out of bounds");
        return _allTokens[index];
    }


    /**
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTLDTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        

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
        uint256 length = TLDBalances[to];
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
        ++TLDBalances[to];
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


        uint256 lastTokenIndex = TLDBalances[from] - 1;
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

        --TLDBalances[from];
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

    function getTokenOwnerArray(address _addr, uint256 _start, uint256 _count) view external returns(uint256[] memory){
        uint256 balance = TLDBalances[_addr];

        uint256 num = (_count + _start) > (balance - _start) ? (balance - _start) : _count;
        uint256[] memory arr = new uint256[](num);

        for(uint256 i; i < num;){
            arr[i] = _ownedTokens[_addr][_start + i];

            unchecked { ++i; }
        }

        return arr;
    }
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IENSToken.sol";
import "./interfaces/IManager.sol";

pragma solidity ^0.8.13;

contract EnsTldWrapper is ERC721, Ownable {
    address constant ENS_TOKEN_ADDRESS = 0x57f1887a8BF19b14fC0dF6Fd9B2acc9Af147eA85;
    IENSToken public EnsToken = IENSToken(ENS_TOKEN_ADDRESS);
    IManager public DomainManager;
    string public BaseUri = 'https://metadata.ens.domains/mainnet/0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85/';
    uint256 public totalSupply;

    constructor(IManager _manager) ERC721("Wrapped ENS", "WENS"){
        DomainManager = _manager;
    }

    function mint(address _addr, uint256 _tokenId) public isDomainManager {
        _safeMint(_addr, _tokenId);
        unchecked { ++totalSupply; }
    }

    function burn(uint256 _tokenId) public isDomainManager {
        _burn(_tokenId);
        unchecked { --totalSupply; } //this is only used for display generally.
    }

    function exists(uint256 _tokenId) public view returns(bool) {
        return _exists(_tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (from != address(0) && to != address(0)){
            //the token could expire and then this token would not be bound to it and could be sold independently.
            //this should stop that from happening. 
          require(EnsToken.ownerOf(tokenId) == address(DomainManager) 
                    && EnsToken.nameExpires(tokenId) > block.timestamp
          , "cannot transfer if expired or not in contract"); 
          
            DomainManager.transferDomainOwnership(tokenId, to); 
        
        }
    }

    function setBaseUri(string calldata _uri) public onlyOwner {
        BaseUri = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return BaseUri;
    }

   modifier isDomainManager() {
        require(address(DomainManager) == msg.sender, "is not domain manager");
      _;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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