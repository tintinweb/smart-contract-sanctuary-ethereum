// SPDX-License-Identifier: MIT

/**
  Rules:

Parte NFT
  ok - setup - ERC1155 - nao conteḿ NAME e SYMBOL, essas infos foram extraidos para ficar no Metadata JSON
  ok  - customizar URI para atender as necessidades do open sea
  ok - deployer e beneficiary são dois addresses diferentes. Deployer/Owner é repsonsável por fazer deploy e interagir com ERC721 para funções administrativas (owner). Beneficiary é a carateira "business" (idealmente multisig, usando gnosis safe, que receberá os proventos e royalties da coleção)
  ok - withdraw para conta do beneficiario
  pk - beneficiary terá reservado 5 NFT para uso próprio (não disponiveis para MINT público), com MINT FEE ZERO, entre indexes 1 a 5
  ok - fee publico é para 0.003   
  ok - um mesmo comprador (public) pode solicitar no max 3 NFT por mint
  ok - Pausable - permitirá que owner pare as negociações em suspeita de fraude ou condições de mercado
  ok - Configurar BaseTokenURI conforme conteudo publicado no NFT.Storage
   
  ok - Usar lib OpenZeppelin ara push payments

Open Sea
  ok - implementar os metodos de boas praticas definidos para especificação 
   - implementar Meta-transactions e Context Mixing para Polygn / Open Sea  


Parte ERC20
   OK- ao Mint um NFT, recebe como bonus um conjunto de ERC20
    - pode trocar Ether por ERC20
   OK- Editions Especiais podem ser comprados (minted) somente com token ERC20   

Editions
  OK - minted para holder inicial estrategico durante crição???
  OK - podem ser vendidos somente pelo ERC20 do ecossistema
  OK - trades da Coleção "ERC721" acumula "ERC20" que pode ser trocado por editions
  - sortear edtions para Random?

Semi-Fungible
   - converter um conjunto de FT disponíveis em um NFT comemorativo
   - FT são "burned", e no lugar um NFT one-on-one é criado   

Novos
   ok - permitir adicionar novos tipos de tokens para serem gerenciados aos smart contract  
   - Ref: https://github.com/enjin/erc-1155/blob/master/contracts/ERC1155Mintable.sol e https://github.com/ProjectOpenSea/opensea-erc1155/blob/master/contracts/ERC1155Tradable.sol
   OK - Mapping - URI diferente para cada coleção
   - qualquer alteração em URI deve emitir event URI(string value, uint256 indexed id); da IERC1155 
   - usar libs de Roles da OpenZeppelin para criar roles de Creators

Melhorias
   1. REVEAL - contrato iniciará com metadata token URI default, e depois deployer/owner setará endereço correto
   ok 2. ROYALTIES - configuração de royalties por token ids (ERC2898)
   3. Random Index for Mint
   4. Default Function para armazenar eventual transf de fundos direto para contrato (payable, msg.sender)
   5. Transformar em Upgradalbe seguindo boas práticas
   extrair logica economica/matematica para um Smart Contract a parte, que na essência poderia ser Upgradable


      uint256 public constant GOLD = 0;
    uint256 public constant SILVER = 1;
    uint256 public constant THORS_HAMMER = 2;
    uint256 public constant SWORD = 3;
    uint256 public constant SHIELD = 4;

           _mint(msg.sender, GOLD, 10**18, "");
        _mint(msg.sender, SILVER, 10**27, "");
        _mint(msg.sender, THORS_HAMMER, 1, "");
        _mint(msg.sender, SWORD, 10**9, "");
        _mint(msg.sender, SHIELD, 10**9, "");

        -- sequencia para MINT da coleção (param 2- sao IDs dos tokens da coleção, param 2 - "1" signifca que eh um NFT unico daquela imagem - ERC721)
        _mint(msg.sender, 0, 1, "")
        _mint(msg.sender, 1, 1, "")
        _mint(msg.sender, 2, 1, "")


 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/PullPayment.sol";

//import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
//import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";


import "./libs/OpenSeaERC1155.sol";

pragma solidity ^0.8.7;


error CoolDrinkingAlienEcosystem__BeneficiaryOnlyAction();
error CoolDrinkingAlienEcosystem__NoProceedingsToWithdraw();
error CoolDrinkingAlienEcosystem__MintConditionsViolations();
error CoolDrinkingAlienEcosystem__CollectionCreationViolations();
error CoolDrinkingAlienEcosystem__NotEnoughFundsToMintRequiredAmount();
error CoolDrinkingAlienEcosystem__MinterNotEligibleToMintEditions();


contract CoolDrinkingAlienEcosystem is OpenSeaERC1151, ReentrancyGuard, Ownable, PullPayment {

    // libraries
    using Counters for Counters.Counter;

    // constants and init definitions
    uint256 private constant NFT_TYPE = 1;
    uint256 private constant FUNGIBLE_TOKEN = 1;
    uint256 private constant DEFAULT_NFT_FAMILY = 1;
    uint256 private constant DEFAULT_FT_FAMILY = 2;
    uint256 private constant MAX_TOKENS_FOR_CUSTOM_FAMILY = 1000;
    uint256 private constant MULTIPLIER_FEE_CUSTOM_FAMILTY = 2;
   
    // variables e inits
    uint256 public immutable s_publicMintFee;
    uint256 public immutable s_creationFee;
    bool private s_baseExtension_flag = true;

    // beneficiary
    address payable private s_beneficiary;

    // variables - sequence ID minting
    uint256 private _globalIdTracker;

    //URI
    string internal s_base_uri;

    // token types
    enum TokenType {
        UNDEFINED,
        COLLECTABLES,
        EDITIONS,
        FUNGIBLE
    }

    // token types
    struct TokenFamilyInfo {
        uint256 family_id;
        uint256 max_tokens_for_public_mint;
        uint256 max_tokens_per_mint;
        uint256 max_tokens_reserved_for_owners;
        uint256 token_id_tracker;
        uint256 token_id_range_init;
        uint256 token_id_range_end;
        uint256 minted_tokens;
        TokenType token_type;
        uint256 token_mint_fee;
        string token_mint_asset;
        string name;
        string symbol;
        string baseURI;
        address collection_admin;
    }

    // token ecosystem description
    mapping (uint256 => TokenFamilyInfo) private _tokenEcosystem;

    // mapping of tokenID (global) to which famility it belongs
    mapping (uint256 => uint256) private _tokenIdToFamilyId;

     // ecosystem managed token counter
    Counters.Counter private _managedTokensTypeCounter;
   

    // events
    event CollectablesMinted(address s_beneficiary);
    event TokensMinted(address buyer, uint256 [] mintedTokenIds);
 
    // modifier
    modifier isBeneficiary () {
        if ( msg.sender != s_beneficiary ) {
            revert CoolDrinkingAlienEcosystem__BeneficiaryOnlyAction();
        }

        _; 

    }

    // modifier
    modifier isCreator () {
        if ( msg.sender != s_beneficiary ) {
            revert CoolDrinkingAlienEcosystem__BeneficiaryOnlyAction();
        }

        _; 

    }

    constructor (uint256 _publicMintFee,
                 address payable _beneficiary, 
                 uint256 _creationFee, 
                 string memory _contractUri, 
                 string memory _baseUriCollectables,
                 string memory _baseUriEditions,
                 string memory _baseUriFungibles,
                 uint96 _royaltiesBps) OpenSeaERC1151("Alien Ecosystem Tokens", "ALIENTOKENS", _contractUri, _contractUri, _beneficiary, _royaltiesBps) {

        // validate
        require(_beneficiary != address(0), "ERR01");//: Invalid Beneficiary Address - cannot be null
        require(_publicMintFee > 0,"ERR02");//: Public Fee must be above 0");
        require(_creationFee > 0,"ERR03");// Public Fee must be above 0");
        require(bytes(_contractUri).length > 0, "ERR04");// baseURI cannot be empty");  
        require(_royaltiesBps > 0, "ERR05");// royalties must be above 0"); 
        require(bytes(_baseUriCollectables).length > 0, "ERR06");// baseURI cannot be empty"); 
        require(bytes(_baseUriEditions).length > 0, "ERR07");// baseURI cannot be empty"); 
        require(bytes(_baseUriFungibles).length > 0, "ERR08");// baseURI cannot be empty");   

        // init variables
        s_publicMintFee = _publicMintFee;
        s_beneficiary = _beneficiary;
        s_creationFee = _creationFee;
       
        // init collection
        // FAMILY 1
        _addTokenFamily(TokenType.COLLECTABLES, 25, 5, 4, _publicMintFee, "ether", "Cool Drinking Alien", "COOLALIEN", _baseUriCollectables,_msgSender()); //0-30

        // FAMILY 2
        _addTokenFamily(TokenType.FUNGIBLE, ((10**18) - 500), 500, 600, 0, "COOLALIEN", "Cool Alien Coins", "ALCOIN", _baseUriFungibles, _msgSender());// 31

        // FAMILY 3 
        _addTokenFamily(TokenType.EDITIONS, 20, 0, 3, 1000, "ALCOIN", "Special Alien Edition", "SUPERALIEN", _baseUriEditions, _msgSender()); //32

        // grant tokens to owener
        (uint256[] memory ids, uint256[] memory amounts) = _mintDefaultCollectables(
            _tokenEcosystem[DEFAULT_NFT_FAMILY].max_tokens_reserved_for_owners,
            _tokenEcosystem[DEFAULT_FT_FAMILY].max_tokens_reserved_for_owners
        );

        _mintBatch(s_beneficiary, ids, amounts, "");

        emit TokensMinted(_beneficiary,ids);

    }


    /*************************************** */
    /*********CREATOR FUNCTIONS      ******* */
    /*************************************** */ 

    function mint(uint256 _nftAmount) external payable {

        if (_nftAmount < 1 || 
            _nftAmount > _tokenEcosystem[DEFAULT_NFT_FAMILY].max_tokens_per_mint ||
            _nftAmount > getLeftTokensForPublicMintForFamily(DEFAULT_NFT_FAMILY)) {

                revert CoolDrinkingAlienEcosystem__MintConditionsViolations();
        }

        if( msg.value != _nftAmount * _tokenEcosystem[DEFAULT_NFT_FAMILY].token_mint_fee ) {
            revert CoolDrinkingAlienEcosystem__NotEnoughFundsToMintRequiredAmount();
        }

        // TODO check bonus tokens availability
  
        (uint256[] memory ids, uint256[] memory amounts) = _mintDefaultCollectables(_nftAmount, _tokenEcosystem[DEFAULT_FT_FAMILY].max_tokens_per_mint * _nftAmount);

        // charge funds to Escrow
        _asyncTransfer(s_beneficiary, msg.value);

        // batch mint all the stuff 
        _mintBatch(_msgSender(), ids, amounts, "");  

        emit TokensMinted(_msgSender(),ids);
               
    }

    function mintEdition(uint256 _editionId, uint256 _amount) external {

       // require(_tokenEcosystem[_editionId].family_id !=0, "ERR05"); //rror: non-existant family or collection");

        if(_tokenEcosystem[_editionId].family_id == 0) {
            revert CoolDrinkingAlienEcosystem__MintConditionsViolations();
        }

        // elibility - detem ao menos (1) NFT da Main Collection
        // if( balanceOf(_msgSender(),DEFAULT_NFT_FAMILY ) < 1  ) {
        //     revert CoolDrinkingAlienEcosystem__MinterNotEligibleToMintEditions();
        // }

        // quantity
        if (_amount < 1 || 
            _amount > _tokenEcosystem[_editionId].max_tokens_per_mint ||
            _amount > getLeftTokensForPublicMintForFamily(_editionId)) {

                revert CoolDrinkingAlienEcosystem__MintConditionsViolations();
        }

        // check Alien Coins Balance > 0
        if( balanceOf(_msgSender(),DEFAULT_FT_FAMILY ) < _amount * _tokenEcosystem[DEFAULT_FT_FAMILY].token_mint_fee ) {
            revert CoolDrinkingAlienEcosystem__NotEnoughFundsToMintRequiredAmount();
        }
  
        // get id for Bonus Coins
        uint256 l_balance = balanceOf(_msgSender(), _tokenEcosystem[DEFAULT_FT_FAMILY].token_id_range_end);
        uint256 l_edition_mint_fee = _tokenEcosystem[_editionId].token_mint_fee;
        uint256 l_total_cost = l_edition_mint_fee * _amount;
        if (l_balance < l_total_cost) {
            revert CoolDrinkingAlienEcosystem__NotEnoughFundsToMintRequiredAmount();
        }
        
        // burn tokens
        _burn(_msgSender(), _tokenEcosystem[DEFAULT_FT_FAMILY].token_id_range_end, l_total_cost);

        // mint special edition for tokens
        // check if first mint ever
        _tokenIdToFamilyId[_tokenEcosystem[_editionId].token_id_range_end] = _tokenEcosystem[_editionId].family_id;             
       
        _tokenEcosystem[_editionId].token_id_tracker = _tokenEcosystem[_editionId].token_id_range_end;
        _tokenEcosystem[_editionId].minted_tokens += _amount; 

        _mint(_msgSender(), _tokenEcosystem[_editionId].token_id_range_end, _amount, ""); 

    }

    function updateUri (uint256 _familyId, string calldata _newUri) public {


        require(bytes(_newUri).length > 0, "ERR04");// baseURI cannot be empty");  

         // family must exist
        require(_tokenEcosystem[_familyId].family_id !=0, "ERR06");//eRRrror: non-existant family or collection");

        // sender must be admin
        require(_tokenEcosystem[_familyId].collection_admin == _msgSender(), "ERR07");//Error: sender is not creator of collection");

        _tokenEcosystem[_familyId].baseURI = _newUri;

    }

    function updateContractUri(string calldata _newUri) external onlyOwner {
        _updateContractURI(_newUri);

    }

    /*************************************** */
    /*********CREATOR FUNCTIONS      ******* */
    /*************************************** */   

    function createFamily (uint256 _maxTokensPerMint, uint256 _maxTokens, uint256  _tokenMintFee, string memory _tokenName, string memory _tokenSymbol,string memory  _tokenBaseURI) external payable {

         // check value == creation fee
        if( msg.value != s_creationFee ) {
            revert CoolDrinkingAlienEcosystem__NotEnoughFundsToMintRequiredAmount();
        }

        // max token - limitado a 1000
        if(_maxTokens > MAX_TOKENS_FOR_CUSTOM_FAMILY ) {
            revert CoolDrinkingAlienEcosystem__CollectionCreationViolations();
        }
 
        // check Alien - fungible (aditional fee) - == qtd de collectables *2 
        uint256 l_total_cost = _maxTokens * MULTIPLIER_FEE_CUSTOM_FAMILTY;
        if( balanceOf(_msgSender(),_tokenEcosystem[DEFAULT_FT_FAMILY].token_id_range_end ) < l_total_cost ) {
            revert CoolDrinkingAlienEcosystem__CollectionCreationViolations();
        }
           
        // charge funds to Escrow
        // financeiro = transferir esse dinheiro para beneficiary
        _asyncTransfer(s_beneficiary, msg.value);

        // reinjetar token na economia
        // 1. burn tokens existentes, 2. permite mintar novos tokens 
        _burn(_msgSender(), _tokenEcosystem[DEFAULT_FT_FAMILY].token_id_range_end, l_total_cost);
        _tokenEcosystem[DEFAULT_FT_FAMILY].minted_tokens -= l_total_cost;

        _addTokenFamily(TokenType.COLLECTABLES, _maxTokens, 0, _maxTokensPerMint, _tokenMintFee, "ALCOIN",_tokenName,  _tokenSymbol, _tokenBaseURI, _msgSender());

    }

    function airdropMyCollection (uint256 _familyId, uint256 _amount, address _to) external {
   

        // family must exist
        require(_tokenEcosystem[_familyId].family_id !=0, "ERR06");//eRRrror: non-existant family or collection");

        // sender must be admin
        require(_tokenEcosystem[_familyId].collection_admin == _msgSender(), "ERR07");//Error: sender is not creator of collection");

        // quantity check
        if (_amount < 1 || 
            _amount > _tokenEcosystem[_familyId].max_tokens_per_mint ||
            _amount > getLeftTokensForPublicMintForFamily(_familyId)) {

                revert CoolDrinkingAlienEcosystem__MintConditionsViolations();
        }
 
        uint256[] memory ids = new uint256[](_amount);
        uint256[] memory amounts = new uint256[](_amount);

        // OPT-003
        TokenFamilyInfo memory l_token_family;
        l_token_family.token_id_tracker = _tokenEcosystem[_familyId].token_id_tracker;    
        l_token_family.family_id = _tokenEcosystem[_familyId].family_id;

        // PREPARE NFTS                 // OPT-002
        for(uint256 i=0; i < _amount; i = _uinc(i)) {

             // OPT-003
            ++l_token_family.token_id_tracker;// += 1; // first token - starts with 1 OPT-001
            //++l_token_family.minted_tokens;// += 1; // first token - starts with 1 OPT-001
            _tokenIdToFamilyId[l_token_family.token_id_tracker] = l_token_family.family_id;
            ids[i] = l_token_family.token_id_tracker;
            amounts[i] = NFT_TYPE; 
            
            // configure NFT
            // ++_tokenEcosystem[_familyId].token_id_tracker;// += 1; // first token - starts with 1 OPT-001
            // ++_tokenEcosystem[_familyId].minted_tokens;// += 1; // first token - starts with 1 OPT-001
            // _tokenIdToFamilyId[_tokenEcosystem[_familyId].token_id_tracker] = _tokenEcosystem[_familyId].family_id;
            // ids[i] = _tokenEcosystem[_familyId].token_id_tracker;
            // amounts[i] = NFT_TYPE;  

            // OPEN-SEA - freeze metadata
            emit PermanentURI(uri(l_token_family.token_id_tracker), l_token_family.token_id_tracker);
            
        }  

        // OPT-004 - 
        l_token_family.minted_tokens = _tokenEcosystem[_familyId].minted_tokens + _amount;
        
        // OPT-003
        _tokenEcosystem[_familyId].token_id_tracker = l_token_family.token_id_tracker;
        _tokenEcosystem[_familyId].minted_tokens = l_token_family.minted_tokens;

        // batch mint all the stuff 
        _mintBatch(_to, ids, amounts, "");  

        emit TokensMinted(_to,ids);

    }

    // TokenType.EDITIONS, 20, 0, 0, 1000,

    function _addTokenFamily(
        TokenType _tokenType,
        uint256 _maxTokensForPublicMint,
        uint256 _maxTokensReservedForOwners,
        uint256 _maxTokensPerMint,
        uint256 _tokenMintFee,
        string memory _tokenMintAsset,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _tokenBaseURI,
        address _collectionAdmin
    ) private {

        // add acosystem count
        _managedTokensTypeCounter.increment();


        TokenFamilyInfo memory newTokenFamily = TokenFamilyInfo ({
            family_id : _managedTokensTypeCounter.current(),
            token_type : _tokenType,
            max_tokens_for_public_mint : _maxTokensForPublicMint,
            max_tokens_reserved_for_owners : _maxTokensReservedForOwners,
            max_tokens_per_mint : _maxTokensPerMint,
            token_mint_fee: _tokenMintFee,
            token_mint_asset:  _tokenMintAsset,
            token_id_tracker : 0,  // id - FT - mesmo, NFT/EDITIONS - contabiliza
            minted_tokens : 0, // atualizado apos cada mint
            token_id_range_init : _globalIdTracker + 1,
            token_id_range_end : _globalIdTracker + 1,
            name : _tokenName,
            symbol : _tokenSymbol,
            baseURI : _tokenBaseURI,
            collection_admin: _collectionAdmin
         });

         if(_tokenType == TokenType.COLLECTABLES) {
              _globalIdTracker = _globalIdTracker + newTokenFamily.max_tokens_for_public_mint + newTokenFamily.max_tokens_reserved_for_owners;
              newTokenFamily.token_id_range_end = _globalIdTracker;

         } else {
             _globalIdTracker = _globalIdTracker + 1;
         }

        // add ecosystem do mapping 
        _tokenEcosystem[_managedTokensTypeCounter.current()] = newTokenFamily;   

    }


    /*************************************** */
    /*********BENEFICIARY ADMIN      ******* */
    /*************************************** */   

    function _mintDefaultCollectables(uint256 _nftAmount, uint256 _ftAmount) private returns(uint256[] memory, uint256[] memory) {

        // uint256 l_totalTokens = _nftAmount+ FUNGIBLE_TOKEN;

        uint256[] memory ids = new uint256[](_nftAmount+ FUNGIBLE_TOKEN);
        uint256[] memory amounts = new uint256[](_nftAmount+ FUNGIBLE_TOKEN);


        // OPT-003
        TokenFamilyInfo memory l_token_family;
        l_token_family.token_id_tracker = _tokenEcosystem[DEFAULT_NFT_FAMILY].token_id_tracker;
        //l_token_family.minted_tokens = _tokenEcosystem[DEFAULT_NFT_FAMILY].minted_tokens;
        l_token_family.family_id = _tokenEcosystem[DEFAULT_NFT_FAMILY].family_id;

        // PREPARE NFTS                      // OPT-002
        for(uint256 i=0; i < _nftAmount; i = _uinc(i)) {

            //configure NFT
            ++ l_token_family.token_id_tracker;// += 1; // first token - OPT-001 - starts with 1        
            //++ l_token_family.minted_tokens;// += 1; // first token - OPT-001 - starts with 1
            _tokenIdToFamilyId[l_token_family.token_id_tracker] = l_token_family.family_id;
            ids[i] = l_token_family.token_id_tracker;
            amounts[i] = NFT_TYPE;  

            
            // configure NFT
            // ++_tokenEcosystem[DEFAULT_NFT_FAMILY].token_id_tracker;// += 1; // first token - OPT-001 - starts with 1
            // ++_tokenEcosystem[DEFAULT_NFT_FAMILY].minted_tokens;// += 1; // first token - OPT-001 - starts with 1
            // _tokenIdToFamilyId[_tokenEcosystem[DEFAULT_NFT_FAMILY].token_id_tracker] = _tokenEcosystem[DEFAULT_NFT_FAMILY].family_id;
            // ids[i] = _tokenEcosystem[DEFAULT_NFT_FAMILY].token_id_tracker;
            // amounts[i] = NFT_TYPE;  

            // OPEN-SEA - freeze metadata
            emit PermanentURI(uri(l_token_family.token_id_tracker), l_token_family.token_id_tracker);
            
        }  

        // OPT-004 - 
        l_token_family.minted_tokens = _tokenEcosystem[DEFAULT_NFT_FAMILY].minted_tokens + _nftAmount; 

         // OPT-003
        _tokenEcosystem[DEFAULT_NFT_FAMILY].token_id_tracker = l_token_family.token_id_tracker;
        _tokenEcosystem[DEFAULT_NFT_FAMILY].minted_tokens = l_token_family.minted_tokens;

        //_tokenEcosystem[DEFAULT_NFT_FAMILY] = l_token_family;

        // PREPARES FT - COINS
       // uint256 tokenId = _tokenEcosystem[DEFAULT_FT_FAMILY].token_id_range_end;
       
        _tokenIdToFamilyId[_tokenEcosystem[DEFAULT_FT_FAMILY].token_id_range_end] = _tokenEcosystem[DEFAULT_FT_FAMILY].family_id;
           
        ids[_nftAmount] =  _tokenEcosystem[DEFAULT_FT_FAMILY].token_id_range_end;
        amounts[_nftAmount] = _ftAmount;       
       
        _tokenEcosystem[DEFAULT_FT_FAMILY].token_id_tracker = _tokenEcosystem[DEFAULT_FT_FAMILY].token_id_range_end;
        _tokenEcosystem[DEFAULT_FT_FAMILY].minted_tokens += _ftAmount;

        return (ids, amounts);


    } 

    function withdrawBalance() external nonReentrant isBeneficiary  {
   
        if( super.payments(_msgSender()) <= 0 ) {
            revert CoolDrinkingAlienEcosystem__NoProceedingsToWithdraw();
        }

        super.withdrawPayments(payable(_msgSender()));

    }

     function checkBalance() external isBeneficiary view returns (uint256)  {
        return super.payments(_msgSender());
    }

    
    /*************************************** */
    /*********ADMIN FUNCTIONS*************** */
    /*************************************** */
    function pauseContract() external onlyOwner {
        _pause();
    }

    function resumeContract() external onlyOwner {
        _unpause();
    }    

    /*************************************** */
    /*********STATE GETEERS AND SETTER****** */
    /*************************************** */
    // general state getters
     
    /**
      Quantidade atual de tokens Minted de uma determinada familia   
    */
    function getMintedTokensForFamily(uint _familyId) external view returns (uint256) {
        return _tokenEcosystem[_familyId].minted_tokens;
    }

    /**
      Scarcity por familia de tokens - quantidade de tokens restantes para Mint numa dada familia
     */
    function getLeftTokensForPublicMintForFamily(uint _familyId) public view returns (uint256) {
        return _tokenEcosystem[_familyId].max_tokens_for_public_mint + 
                _tokenEcosystem[_familyId].max_tokens_reserved_for_owners - 
                _tokenEcosystem[_familyId].minted_tokens;
    }


    /**
        Multi-token - quantidade de familias de tokens geridos por este contrato
     */
    function getFamilyCount () external view returns (uint256) {
        return _managedTokensTypeCounter.current();
    }

    /**
      Quantidade total de tokens geridos pelo contrato, incluindo todas as familias
     */
    function getGlobalTokensCount() external view returns (uint256) {
        return _globalIdTracker; // current esta sem na proxima pos a ser usada
    }

    function getFamilyDetailsById(uint256 familyId) public view returns (TokenFamilyInfo memory) {
        return _tokenEcosystem[familyId];
    }

    function getFamilyDetailsTokenId(uint256 tokenId) public view returns (TokenFamilyInfo memory) {
        return _tokenEcosystem[_tokenIdToFamilyId[tokenId]];
    }


    function uri(uint256 _tokenId) override public view returns (string memory) {

        // OPENSEA BEST-PRACTICE 01
        require(_tokenId > 0 && _tokenId <= _globalIdTracker, "ERC1155Metadata: URI query for nonexistent token");

        uint256 l_familyId = _tokenIdToFamilyId[_tokenId];
 
        string memory tokenFamilyURI = _tokenEcosystem[l_familyId ].baseURI;

        if(_tokenEcosystem[l_familyId ].token_type == TokenType.COLLECTABLES ) {
                  return string(
                    abi.encodePacked(
                        tokenFamilyURI,
                        Strings.toString(_tokenId),
                        ".json"
        ));

        } else {
            return tokenFamilyURI;
        }

    }



    // OPT-002
    function _uinc(uint x) private pure returns (uint) {
        unchecked { return ++x; }
    }
    

}





/**
  Open Sea Subst

    function uri(
    uint256 _id
  ) public view returns (string memory) {
    require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
    return Strings.strConcat(
      baseMetadataURI,
      Strings.uint2str(_id)
      .json
    );
  }


 */

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.7;

// // OPENSEA  - ERC2981 - Royalty Metadata COnfiguration
contract OpenSeaERC1151 is ERC1155Pausable, ERC2981 {

    string private constant baseExtension = ".json";

    // OPENSEA expects public property called NAME (Anton:ERC1155 - multi-token violation)
    string public name;
    string public symbol;
    string public s_contractURI;

    // OPENSEA indicates frozen metadata NAME 
    event PermanentURI(string _value, uint256 indexed _id);


    constructor (
        string memory _name, 
        string memory _symbol, 
        string memory _baseURI, 
        string memory _contractURI,
        address _beneficiary,
        uint96 _royaltiesBips) ERC1155(_baseURI) {

        name = _name;
        symbol = _symbol;
        s_contractURI = _contractURI;

        _setDefaultRoyalty(_beneficiary,_royaltiesBips);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC1155) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }


    // OPENSEA gloabl collection metadata NAME 
    function contractURI() public view returns (string memory) {
        return s_contractURI;
    }

    function _updateContractURI(string calldata _newContractUri) internal {
        s_contractURI = _newContractUri;
    }

    // function formatUri(string calldata _customURI) internal returns (string memory formattedUri) {

    //     if (bytes(_customURI) < 0) 

    // }


    /**
      Token metadata URI override
     */
    // function uri(uint256 tokenId) override  public view returns (string memory) {

       
    //     string memory originaltokenURI = super.uri(tokenId);
        
    //     return string(
    //                 abi.encodePacked(
    //                     originaltokenURI,
    //                     Strings.toString(tokenId),
    //                     baseExtension
    //     ));

    // }

    /**
        Override de multipla herança
    */

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155URIStorage.sol)

pragma solidity ^0.8.0;

import "../../../utils/Strings.sol";
import "../ERC1155.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 * Inspired by the ERC721URIStorage extension
 *
 * _Available since v4.6._
 */
abstract contract ERC1155URIStorage is ERC1155 {
    using Strings for uint256;

    // Optional base URI
    string private _baseURI = "";

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the concatenation of the `_baseURI`
     * and the token-specific uri if the latter is set
     *
     * This enables the following behaviors:
     *
     * - if `_tokenURIs[tokenId]` is set, then the result is the concatenation
     *   of `_baseURI` and `_tokenURIs[tokenId]` (keep in mind that `_baseURI`
     *   is empty per default);
     *
     * - if `_tokenURIs[tokenId]` is NOT set then we fallback to `super.uri()`
     *   which in most cases will contain `ERC1155._uri`;
     *
     * - if `_tokenURIs[tokenId]` is NOT set, and if the parents do not have a
     *   uri value set, then the result is empty.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenURI)) : super.uri(tokenId);
    }

    /**
     * @dev Sets `tokenURI` as the tokenURI of `tokenId`.
     */
    function _setURI(uint256 tokenId, string memory tokenURI) internal virtual {
        _tokenURIs[tokenId] = tokenURI;
        emit URI(uri(tokenId), tokenId);
    }

    /**
     * @dev Sets `baseURI` as the `_baseURI` for all tokens
     */
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseURI = baseURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}