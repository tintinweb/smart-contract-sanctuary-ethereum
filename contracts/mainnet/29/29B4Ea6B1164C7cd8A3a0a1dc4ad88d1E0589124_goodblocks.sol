// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

     ██████   ██████   ██████  ██████  ██████  ██       ██████   ██████ ██   ██ ███████ 
    ██       ██    ██ ██    ██ ██   ██ ██   ██ ██      ██    ██ ██      ██  ██  ██      
    ██   ███ ██    ██ ██    ██ ██   ██ ██████  ██      ██    ██ ██      █████   ███████ 
    ██    ██ ██    ██ ██    ██ ██   ██ ██   ██ ██      ██    ██ ██      ██  ██       ██ 
     ██████   ██████   ██████  ██████  ██████  ███████  ██████   ██████ ██   ██ ███████                                                                                                                                                                                 

    by @0xSomeGuy

    a collection made with ❤ for creators, innovators, and builders
    having real world impact and doing good.

    ...or anyone who supports that stuff too. 👊

    shoutouts/credits to other projects/contract/devs/people:
        @OnChainMonkey: @huuep
        @NuclearNerds: @nftchance (Mimetic Metadata), masonnft, @squeebo_nft
        Azuki: @ChiruLabs (ERC721A)
        @AnonymiceNFT: @_MouseDev and Kiro
        @OnChainKevinNFT     
        @HumansNft
        @FlowerGirlsNFT
        @developer_dao

        section headers made with: https://patorjk.com/software/taag (ANSI Regular)

*/

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

error StopTryingToApproveIfYoureNotTheOwnerOrApproved();
error WhyAreYouTryingToApproveYourself();
error YoureTheOwnerYouDontNeedApprovalDuh();
error CantGetApprovalsForTokensThatDontExist();
error BalanceOfZeroAddressNotAllowedItsComplicated();
error LoveTheSupportButCantMintThatMany();
error GenerationAddressNotValidWhoops();
error UhOhTheGenerationYouRequestedIsNotEnabled();
error HoldYourHorsesNextGenerationIsNotEnabled();
error SeriouslyYouDontEvenHaveThatMuchToSend();
error NotTheRightAmountToUnlockTryAgain();
error ReallyWantToMintForYouButNotTheRightFunds();
error TheresNoGenerationsLessThanZeroDude();
error LoveTheExcitementButMintIsNotActive();
error SorryFriendContractsCantMint();
error WeWouldBreakIfWeMintedThisMany();
error HowCanYouEvenMintLessThanOne();
error MintingToZeroAddressWouldCauseHavoc();
error SorryYouCantAbandonOwnershipToTheZeroAddress();
error WeReallyNeedTheContractOwnerToDoThis();
error WeKnowYoureTheOwnerAndAllButYouCantMintThatMany();
error DangCouldntSendTheFundsForYou();
error StopTryingToChangeOtherPeoplesTokenGenerationYoureNotTheOwner();
error AreYouReallyTryingToSetTheGenerationForTokensThatDontExist();
error GottaUnlockThisGenerationBeforeYouSetItFriend();
error TokensThatDontExistDontHaveDataOrDoThey();
error ItsTheSameGenerationYoureNotChangingAnything();
error WhyAreYouTryingToTransferTheTokenIfYoureNotTheOwnerOrApproved();
error TheFromAddressNeedsToBeTheOwnerPlease();
error TransferToNonERC721ReceiverImplementer();
error PleaseDontTransferToTheZeroAddressThanks();
error DontMessWithOtherPeoplesTokensOnlyOwnersCanUnlockNextGeneration();
error CantGetTheUriForTokensThatArentEvenReal();
error SorryCouldntWithdrawYourFundsHomie();

/**
    @author @0xSomeGuy
    @notice this contract handles the multi generational ERC721 tokens for the goodblocks community
    @dev hit me up with any questions or feedback! dms always open.
*/

contract goodblocks is IERC721, IERC721Metadata, ReentrancyGuard
{

    constructor()
    {
       _Owner = msg.sender;
    }

    using Address for address;
    using Strings for uint256;



    /*
    
        ███████ ████████  █████  ████████ ███████     ██    ██  █████  ██████  ███████ 
        ██         ██    ██   ██    ██    ██          ██    ██ ██   ██ ██   ██ ██      
        ███████    ██    ███████    ██    █████       ██    ██ ███████ ██████  ███████ 
             ██    ██    ██   ██    ██    ██           ██  ██  ██   ██ ██   ██      ██ 
        ███████    ██    ██   ██    ██    ███████       ████   ██   ██ ██   ██ ███████ 

        section for state variables in the contract
        sección de 'state variables' en el contrato
    */

    // project information
    // información del proyecto
    uint256 constant CollectionSize = 8281;
    string public ProjectName = unicode"goodblocks";
    string public ProjectSymbol = unicode"GDBLK";
    string public ProjectDescription = unicode"create x innovate x impact. good vibes guaranteed. 👊💯";
    
    /**
        @notice function to update project info
                función para cambiar la información del proyecto
        @param _newName     new project name
                            el nuevo nombre del proyecto
        @param _newSymbol   new project symbol
                            el nuevo símbolo del proyecto
        @param _newDesc     new project description
                            la nueva descripción del proyecto
    */
    function updateProjectInfo(string memory _newName, string memory _newSymbol, string memory _newDesc) external onlyOwner
    {
        ProjectName = _newName;
        ProjectSymbol = _newSymbol;
        ProjectDescription = _newDesc;
    }

    // contract owner
    address private _Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
        @notice get contract owner
                obtener dueño del contrato
        @return address     owner address                   
                            dirección del dueño
    */
    function owner() public view returns (address)
    {
        return _Owner;
    }

    /**
        @notice transfer contract ownership
                transferir la propiedad del contrato
        @param _newOwner    address of new owner
                            dirección de nuevo dueño/dueña
    */
    function transferOwnership(address _newOwner) external onlyOwner
    {
        if(_newOwner == address(0)) revert SorryYouCantAbandonOwnershipToTheZeroAddress();
        address oldOwner =_Owner;
       _Owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    // mint variables
    // variables para el mint (acuñación)
    uint256 private constant StartTokenIndex = 0;
    uint256 private constant MaxReserve = 410;
    bool public IsMintActive = false;
    uint256 private ReserveUsed = 0;
    uint256 public GoodblockPrice = 0.05 ether;
    uint256 public MaxMintPerAddress = 7;
    uint256 public MaxFreePerAddress = 2;
    uint256 private CurrentTokenIndex = 0;
    uint256 public TotalMinted = 0;
    
    /**
        @notice update mint price
                cambiar precio
        @param _newPriceInWei   new price in wei
                                nuevo precio en wei
    */
    function updateMintPrice(uint256 _newPriceInWei) external onlyOwner
    {
        GoodblockPrice = _newPriceInWei;
    }

    /**
        @notice update max mint per address
                cambiar mint máximo por dirección
        @param _newMaxPerAddress     new max per address
                                    nuevo máximo por dirección  
    */
    function updateMaxMintPerAddress(uint256 _newMaxPerAddress) external onlyOwner
    {
        MaxMintPerAddress = _newMaxPerAddress;
    }

    /**
        @notice update max free per address
                cambiar máximo gratis por dirección
        @param _newMaxFreePerAddress     new max per address
                                    nuevo máximo por dirección  
    */
    function updateMaxFreePerAddress(uint256 _newMaxFreePerAddress) external onlyOwner
    {
        MaxFreePerAddress = _newMaxFreePerAddress;
    }

    /**
        @notice struct for token data
                struct para datos del token
        @param activeGen            active generation of token
                                    generación activa de token
        @param highestGenLevel      highest generation unlocked for token
                                    generación más alta desbloqueada para token
        @param timesTransferred     times token has been transferred (including non sale transfers)
                                    veces que se ha transferido el token (incluyendo las transferencias que no son de venta)
        @param ownedSince           time token has been owned by currrent owner (property can be inherited from other token)
                                    tiempo que el token ha sido propiedad del propietario actual (se puede heredar de otro token)
        @param tokenOwner           current owner of token (property can be inherited from other token)
                                    propietario actual del token (se puede heredar de otro token)
        @dev    "tokenOwner" and "ownedSince" needs special logic due to batch mint approach, can also be inhertied by another token
                "tokenOwner" y "ownedSince" necesita una lógica especial por el enfoque de acuñar por lotes, tambien se puede heredar de otro token
    */
    struct TokenData
    {
        uint8 activeGen;
        uint8 highestGenLevel;
        uint64 timesTransferred;
        uint64 ownedSince;
        address tokenOwner;
    }

    /**
        @notice struct for address data
                struct para datos de cada dirección
        @param mintedCount  number of minted tokens for this address
                            número de tokens acuñados para esta dirección
        @param balance      current address balance of goodblock tokens
                            balance de tokens goodblock do un dirección
    */
    struct AddressData
    {
        uint8 mintedCount;
        uint16 balance;
    }

    /**
        @notice struct for generation data
                struct para datos de cada generación
        @param isEnabled        is generation enabled
                                está habilitada la generación
        @param genAddress       address of generation
                                dirección de generación
        @param unlockCostInWei  cost to unlock in WEI
                                costo para desbloquear en WEI
    */
    struct GenerationData
    {
        bool isEnabled;
        address genAddress;
        uint256 unlockCostInWei;
    }

    // maps each token to token data
    // asigna cada token a datos de token
    mapping(uint256 => TokenData) private TokenToDataMap;
    // maps each address to address data
    // asigna cada dirección a los datos de dirección
    mapping(address => AddressData) public AddressToDataMap;
    // maps each generation to generation data
    // asigna cada generación a los datos de la generación
    mapping(uint256 => GenerationData) private GenerationToDataMap;
    // maps each token to approved addresses
    // asigna cada token a direcciones aprobadas
    mapping(uint256 => address) private TokenToApprovedMap;
    // maps each owner to operator approvals
    // asigna cada propietario a las aprobaciones del operador
    mapping(address => mapping(address => bool)) private OperatorApprovals;

    // variables to add times transferred to metadata
    // variables para agregar tiempos transferidos a metadatos
    string[] private TransferCountBucketStrings;
    uint256[] private TransferCountBuckets;
    
    /**
        @notice updates the count and associated metadata string
                actualiza el conteo y los metadatos asociada
        @param _index           index to update
                                índice para actualizar
        @param _transferMax     max transfer count for this bucket
                                número máximo de transferencias para este grupo
        @param _traitName       how trait appears in metadata
                                texto para metadatos
    */
    function updateTransferBucket(uint256 _index, uint256 _transferMax, string memory _traitName) external onlyOwner returns (string[] memory)
    {
        if(_index >= TransferCountBucketStrings.length)
        {
            TransferCountBucketStrings.push(_traitName);
            TransferCountBuckets.push(_transferMax);
        } else
        {
            TransferCountBucketStrings[_index] = _traitName;
            TransferCountBuckets[_index] = _transferMax;
        }
        return TransferCountBucketStrings;
    }

    // variables to add owned since to metadata
    // variables para agregar la duración de la propiedad a los metadatos
    string[] private OwnedSinceBucketStrings;
    uint256[] private OwnedSinceBuckets;
    
    /**
        @notice updates the count and associated metadata string
                actualiza el conteo y los metadatos asociada
        @param _index           index to update
                                índice para actualizar
        @param _timeMax         max time for this bucket
                                tiempo máximo para este grupo
        @param _traitName       how trait appears in metadata
                                texto para metadatos
    */
    function updateOwnedSinceBucket(uint256 _index, uint256 _timeMax, string memory _traitName) external onlyOwner returns (string[] memory)
    {
        if(_index >= OwnedSinceBucketStrings.length)
        {
            OwnedSinceBucketStrings.push(_traitName);
            OwnedSinceBuckets.push(_timeMax);
        } else
        {
            OwnedSinceBucketStrings[_index] = _traitName;
            OwnedSinceBuckets[_index] = _timeMax;
        }
        return OwnedSinceBucketStrings;
    }



    /*

        ███    ███  ██████  ██████  ██ ███████ ██ ███████ ██████  ███████ 
        ████  ████ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██ ██      
        ██ ████ ██ ██    ██ ██   ██ ██ █████   ██ █████   ██████  ███████ 
        ██  ██  ██ ██    ██ ██   ██ ██ ██      ██ ██      ██   ██      ██ 
        ██      ██  ██████  ██████  ██ ██      ██ ███████ ██   ██ ███████

    */

    modifier onlyOwner()
    {
        if(msg.sender !=_Owner) revert WeReallyNeedTheContractOwnerToDoThis();
        _;
    }
   

    
    /*

        ███████ ██████   ██████  ██  ██████  ███████ 
        ██      ██   ██ ██      ███ ██       ██      
        █████   ██████  ██       ██ ███████  ███████ 
        ██      ██   ██ ██       ██ ██    ██      ██ 
        ███████ ██   ██  ██████  ██  ██████  ███████ 

    */

    /**
        @notice see {IERC165-supportsInterface}
    */
    function supportsInterface(bytes4 interfaceId) public pure override(IERC165) returns (bool)
    {
        return interfaceId == type(IERC721).interfaceId || 
            interfaceId == type(IERC721Metadata).interfaceId;
    }



    /*

        ███████ ██████   ██████ ███████ ██████   ██ 
        ██      ██   ██ ██           ██      ██ ███ 
        █████   ██████  ██          ██   █████   ██ 
        ██      ██   ██ ██         ██   ██       ██ 
        ███████ ██   ██  ██████    ██   ███████  ██                                            
                                                    
    */

    /**
        @notice see {IERC721-balanceOf}
        @notice gets the balance of an address
        @param _owner   address to be checked
                        dirección a revisar
        @return uint256 of tokens owned by address
                        balance de tokens de la dirección
    */
    function balanceOf(address _owner) public view override returns (uint256)
    {
        if (_owner == address(0)) revert BalanceOfZeroAddressNotAllowedItsComplicated();   
        return uint256(AddressToDataMap[_owner].balance);
    }

    /**
        @notice see {IERC721-ownerOf}
        @notice gets the owner of a specific token
                obtiene el dueño/la dueña de un token específico
        @param _tokenId     token id to get owner
                            identificación del token para obtener el propietario
        @return address     address of token owner
                            dirección de el dueño/la dueña del token
    */
    function ownerOf(uint256 _tokenId) public view override returns (address)
    {
        return getTokenData(_tokenId).tokenOwner;
    }

    /**
        @notice see {IERC721-safeTransferFrom}
        @notice safely transfers tokens to addresses and contracts
                transfiere tokens de forma segura a carteras y contratos
        @param _from        the originating address
                            la dirección de origen
        @param _to          the receiving address
                            la dirección de recepción
        @param _tokenId     token to be transferred
                            token a transferir
        @param _data        any data with the transfer
                            cualquier dato con la transacción
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override
    {
        // transfer token
        // token de transferencia
        _transferToken(_from, _to, _tokenId);
        
        // if _to is contract, ensure it implements {IERC721Receiver-onERC721Received}
        // si _to es un contrato, asegúrese de que implemente {IERC721Receiver-onERC721Received}
        if (_to.isContract() && !_checkContractOnERC721Received(_from, _to, _tokenId, _data)) 
        {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
        @notice see {IERC721-safeTransferFrom}
        @notice see above
                véa más arriba
    */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override
    {
        safeTransferFrom(_from, _to, _tokenId, '');
    }    

    /**
        @notice see {IERC721-transferFrom}
        @notice transfers tokens
                transfiere tokens
        @param _from        the originating address
                            la dirección de origen
        @param _to          the receiving address
                            la dirección de recepción
        @param _tokenId     token to be transferred
                            token a transferir
    */
    function transferFrom(address _from, address _to, uint256 _tokenId) public override
    {
        _transferToken(_from, _to, _tokenId);
    }

    /**
        @notice see {IERC721-safeTransferFrom}
        @notice grant approval for another address to transfer a token
                aprobador otra dirección para transferir un token
        @param _to          address to approve
                            dirección para aprobar
        @param _tokenId     token to approve for transfer
                            token para aprobar la transferencia
    */
    function approve(address _to, uint256 _tokenId) public override
    {
        // get token owner
        // obtener dueño/dueña de token
        address tokenOwner = getTokenData(_tokenId).tokenOwner;
        
        // check if owner is trying to approve self
        // verificar si el dueño/la dueña está tratando de aprobarse a sí mismo
        if (_to == tokenOwner) revert YoureTheOwnerYouDontNeedApprovalDuh();

        // check if owner or operator is calling function
        // verificar si el dueño/la dueña u operador está llamando a la función
        if (msg.sender != tokenOwner && !isApprovedForAll(tokenOwner, msg.sender)) revert StopTryingToApproveIfYoureNotTheOwnerOrApproved();

        // set approval
        // establecer aprobación
        _approve(_to, _tokenId, tokenOwner);
    }

    /**
        @notice see {IERC721-setApprovalForAll}
        @param _operator        operator to approve
                                operador para aprobar
        @param _approvedStatus  status of operator approval
                                estado de aprobación del operador
    */
    function setApprovalForAll(address _operator, bool _approvedStatus) public override
    {
        // check if operator is trying to approve self
        // verificar si el operador está tratando de aprobarse a sí mismo
        if (_operator == msg.sender) revert WhyAreYouTryingToApproveYourself();

        OperatorApprovals[msg.sender][_operator] = _approvedStatus;
        emit ApprovalForAll(msg.sender, _operator, _approvedStatus);
    }

    /**
        @notice see {IERC721-getApproved}
        @notice get approved address for token
                obtener dirección aprobada para token
        @param _tokenId token to check
                        token para verificar
        @return address address of approved
                        dirección de aprobado
    */
    function getApproved(uint256 _tokenId) public view override returns (address)
    {
        // check token exists
        // verificar que existe el token
        if (!_exists(_tokenId)) revert CantGetApprovalsForTokensThatDontExist();
        return TokenToApprovedMap[_tokenId];
    }

    /**
        @notice see {IERC721-isApprovedForAll}
        @notice check if operator is approved for all
                compruebe si el operador está aprobado
        @param _owner       address to check
                            dirección para verificar
        @param _operator    operator to check
                            operador para verificar
        @return bool        operator approval status
                            estado de aprobación del operador
    */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool)
    {
        return OperatorApprovals[_owner][_operator];
    }  

    /**
        @notice see {ERC721-_checkOnERC721Received}
        @notice check if target contract implements receiver
        @param _from        the originating address
                            la dirección de origen
        @param _to          the receiving address
                            la dirección de recepción
        @param _tokenId     token to be transferred
                            token a transferir
        @param _data        any data with the transfer
                            cualquier dato con la transacción
        @return bool        whether the target address implements or not
                            si la dirección de destino implementa o no
     */
    function _checkContractOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) private returns (bool)
    {
        try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval)
        {
            return retval == IERC721Receiver(_to).onERC721Received.selector;
        } catch (bytes memory reason)
        {
            if (reason.length == 0)
            {
                revert TransferToNonERC721ReceiverImplementer();
            } else
            {
                assembly
                {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }



    /*

        ███████ ██████   ██████ ███████ ██████   ██       ███    ███ ███████ ████████  █████  ██████   █████  ████████  █████  
        ██      ██   ██ ██           ██      ██ ███       ████  ████ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██ 
        █████   ██████  ██          ██   █████   ██ █████ ██ ████ ██ █████      ██    ███████ ██   ██ ███████    ██    ███████ 
        ██      ██   ██ ██         ██   ██       ██       ██  ██  ██ ██         ██    ██   ██ ██   ██ ██   ██    ██    ██   ██ 
        ███████ ██   ██  ██████    ██   ███████  ██       ██      ██ ███████    ██    ██   ██ ██████  ██   ██    ██    ██   ██ 
                                                                                                                                                                                                                                                          
    */

    /**
        @notice see {IERC721Metadata-name}.
        @notice returns the project name
                devuelve el nombre del proyecto
    */
    function name() public view override returns (string memory)
    {
        return ProjectName;
    }

    /**
        @notice see {IERC721Metadata-symbol}.
        @notice returns the project symbol
                devuelve el símbolo del proyecto
    */
    function symbol() public view override returns (string memory)
    {
        return ProjectSymbol;
    }

    /**
        @notice see {IERC721Metadata-tokenURI}.
        @notice returns the token uri containing image and metadata
                devuelve el token uri que contiene la imagen y los metadatos
        @param _tokenId     token to retrieve
                            token para recuperar
        @return string      token uri (data)
                            token uri (datos)
    */
    function tokenURI(uint256 _tokenId) public view override returns (string memory)
    {
        // who's reading carefully?
        // quién está leyendo con atención?
        require(_tokenId != 12345678910111213, string(abi.encodePacked("interesting... ", rh)));

        // check token exists first
        // primero verificar que el token existe
        if (!_exists(_tokenId)) revert CantGetTheUriForTokensThatArentEvenReal();

        // get token generation data
        // obtener datos de generación del token
        TokenData memory tokenData = getTokenData(_tokenId);
        address tokenGenAddress = GenerationToDataMap[tokenData.activeGen].genAddress;
        
        // check for valid gen address
        // verifica si hay una dirección de generación válida
        if (tokenGenAddress == address(0)) revert GenerationAddressNotValidWhoops();

        // get times transferred bucket
        // obtener el grupo de veces transferidas
        string memory transferTrait = "?";
        for(uint i=0; i<TransferCountBuckets.length; i++)
        {
            if(tokenData.timesTransferred < TransferCountBuckets[i])
            {
                transferTrait = TransferCountBucketStrings[i];
                break;
            }
        }

        // get owned since bucket
        // obtener el grupo de la duración de la propiedad
        string memory ownedSinceTrait = "?";
        for(uint i=0; i<OwnedSinceBuckets.length; i++)
        {
            if(tokenData.ownedSince < OwnedSinceBuckets[i])
            {
                ownedSinceTrait = OwnedSinceBucketStrings[i];
                break;
            }
        }

        // generate token uri and metadata
        // generar token uri y metadata
        string memory tokenAttributes = string(abi.encodePacked(
            '{"trait_type": "Generations Unlocked", "value":"',
            Strings.toString(tokenData.highestGenLevel+1),
            '"},',
            '{"trait_type": "Active Generation", "value":"',
            Strings.toString(tokenData.activeGen),
            '"},',
            '{"trait_type": "Times Transferred", "value":"',
            transferTrait,
            '"},',
            '{"trait_type": "Owned Since", "value":"',
            ownedSinceTrait,
            '"}'
        ));
        string memory tokenMetadata = string(abi.encodePacked(
            '"ownedSince":"',
            Strings.toString(tokenData.ownedSince),
            '", "timesTransferred":"',
            Strings.toString(tokenData.timesTransferred),
            '"'
        )); 

        iGoodblocksGen goodblocksGen = iGoodblocksGen(tokenGenAddress);
        return goodblocksGen.tokenGenURI(_tokenId, tokenMetadata, tokenAttributes);
    }



    /*

         ██████  ███████ ███    ██ ███████ ██████   █████  ████████ ██  ██████  ███    ██ ███████ 
        ██       ██      ████   ██ ██      ██   ██ ██   ██    ██    ██ ██    ██ ████   ██ ██      
        ██   ███ █████   ██ ██  ██ █████   ██████  ███████    ██    ██ ██    ██ ██ ██  ██ ███████ 
        ██    ██ ██      ██  ██ ██ ██      ██   ██ ██   ██    ██    ██ ██    ██ ██  ██ ██      ██ 
         ██████  ███████ ██   ████ ███████ ██   ██ ██   ██    ██    ██  ██████  ██   ████ ███████ 

    */

    /**
        @notice get data for generation by index
                obtener datos para la generación por índice
        @param _genIndex        index of generation
                                índice de generación
        @return GenerationData  generation data
                                datos de generación
    */
    function getGenerationData(uint256 _genIndex) public view returns (GenerationData memory)
    {
        return GenerationToDataMap[_genIndex];
    }

    /**
        @notice update the data for any generation (index starting at 0)
                cambiar los datos para cualquier generación (índice comienza en 0)
        @param _genIndex    generation index
                            índice de generación
        @param _isEnabled   status of the generation
                            estado de la generacion
        @param _genAddress  rendering address for the generation (tokenURI points here)
                            dirección de representación para la generación (tokenURI viene de aquí)
        @param _costInWei   cost for unlocking this generation
                            costo para desbloquear esta generación

        @dev    all tokens start with a '0' index generation so the 'genesis' generation index should be 0
                todos los tokens comienzan con una generación de índice '0', el índice de generación 'génesis' debe ser 0
    */
    function updateGeneration(uint256 _genIndex, bool _isEnabled, address _genAddress, uint256 _costInWei) external onlyOwner
    {
        GenerationToDataMap[_genIndex].isEnabled = _isEnabled;
        GenerationToDataMap[_genIndex].genAddress = _genAddress;
        GenerationToDataMap[_genIndex].unlockCostInWei = _costInWei;
    }

    /**
        @notice toggle generation status
                cambiar el estado de generación
        @param _genIndex    generation index
                            índice de generación
    */
    function toggleGenerationStatus(uint256 _genIndex) external onlyOwner
    {
        GenerationToDataMap[_genIndex].isEnabled = !GenerationToDataMap[_genIndex].isEnabled;
    }

    /**
        @notice unlock next generation for token
                desbloquear la próxima generación para token
        @param _tokenId     token to upgrade
                            token para cambiar
    */
    function unlockNextGeneration(uint256 _tokenId) public payable
    {
        // get token data
        // obtener datos del token
        TokenData memory tokenData = getTokenData(_tokenId);
        
        // check that owner is calling function
        // verifica que el dueño/la dueña está llamando a la función
        if(msg.sender != tokenData.tokenOwner) revert DontMessWithOtherPeoplesTokensOnlyOwnersCanUnlockNextGeneration();
        
        // get token next generation level
        // obtener el nivel de próxima generación
        GenerationData memory nextGen = GenerationToDataMap[tokenData.highestGenLevel + 1];
        
        // check if next generation is enabled
        // verifica si la próxima generación está activa
        if(!nextGen.isEnabled) revert HoldYourHorsesNextGenerationIsNotEnabled();
        
        // check if msg.value is correct for next generation unlock
        // verifica que el valor es correcto para desbloquear la próxima generación
        if(msg.value != nextGen.unlockCostInWei) revert NotTheRightAmountToUnlockTryAgain();

        // unlock and increment generation for token
        // desbloquear e incrementar la generación de token
        TokenToDataMap[_tokenId].highestGenLevel = tokenData.highestGenLevel + 1;
        TokenToDataMap[_tokenId].activeGen = tokenData.highestGenLevel + 1;
    }

    /**
        @notice focus generation for a token
                seleccionar generación para un token
        @param _tokenId     token to update
                            token para cambiar
        @param _genIndex    generation index
                            índice de generación
    */
    function setTokenGeneration(uint256 _tokenId, uint256 _genIndex) public payable
    {

        // check for valid generation
        // verifica qu la generación es válida
        if(_genIndex < 0) revert TheresNoGenerationsLessThanZeroDude();

        // check if token exists
        // verifica si existe el token
        if(!_exists(_tokenId)) revert AreYouReallyTryingToSetTheGenerationForTokensThatDontExist();

        // get token data
        // obtener datos del token
        TokenData memory tokenData = getTokenData(_tokenId);
        
        // check that owner is calling function
        // verifica que el dueño/la dueña está llamando a la función
        if(msg.sender != tokenData.tokenOwner) revert StopTryingToChangeOtherPeoplesTokenGenerationYoureNotTheOwner();

        // check if requested generation is greater than highest level
        // comprueba si la generación solicitada es mayor que el nivel más alto
        if(_genIndex > tokenData.highestGenLevel) revert GottaUnlockThisGenerationBeforeYouSetItFriend();
        
        // check if requested gen is current gen
        // comprueba si la generación solicitada es la generación activa
        if(_genIndex == tokenData.activeGen) revert ItsTheSameGenerationYoureNotChangingAnything();
        
        // get requested generation data
        // obtener los datos de generación solicitados
        GenerationData memory requestedGen = GenerationToDataMap[_genIndex];
        
        // check if generation is enabled
        // comprobar si la generación está activa
        if(!requestedGen.isEnabled) revert UhOhTheGenerationYouRequestedIsNotEnabled();

        // set generation for token
        // establecer generación para token
        TokenToDataMap[_tokenId].activeGen = uint8(_genIndex);
    }



    /*
    
         ██████  ███████ ███    ██ ███████ ██████   █████  ██      
        ██       ██      ████   ██ ██      ██   ██ ██   ██ ██      
        ██   ███ █████   ██ ██  ██ █████   ██████  ███████ ██      
        ██    ██ ██      ██  ██ ██ ██      ██   ██ ██   ██ ██      
         ██████  ███████ ██   ████ ███████ ██   ██ ██   ██ ███████ 
    
    */

    /**
        @notice get total supply count
                obtener el recuento total de tokens
        @return uint256 total token count
                        recuento total de tokens
    */
    function totalSupply() public view returns(uint256)
    {
        return TotalMinted;
    }

    /**
        @notice function to get token data struct for existing tokens
        @param _tokenId     token index
                            índice de token
        @return TokenData   token data
                            datos del token
    */
    function getTokenData(uint256 _tokenId) public view returns (TokenData memory)
    {
        uint256 tempTokenId = _tokenId;
        
        // check token exists
        // verifica que existe el token
        if(!_exists(_tokenId)) revert TokensThatDontExistDontHaveDataOrDoThey();
        
        // using unchecked to reduce gas
        // usando "unchecked" para reducir el gas
        unchecked
        {
            // get token data
            // obtener datos del token
            TokenData memory tokenData = TokenToDataMap[_tokenId];

            // if token owner is not address(0), return the data
            // si el dueño/la dueña del token no es la dirección(0), devuelve los datos
            if (tokenData.tokenOwner != address(0))
            {
                return tokenData;
            }

            // there will always be an owner before a 0 address owner, avoiding underflow
            // siempre habrá un dueño/dueña antes que un propietario de dirección(0), evitando el desbordamiento                
            while(tokenData.tokenOwner == address(0) && tempTokenId > StartTokenIndex)
            {
                tempTokenId--;
                // when owner found, update owner and ownedSince properties
                // cuando se encuentra el dueño/ la dueña, cambia las propiedades
                if (TokenToDataMap[tempTokenId].tokenOwner != address(0))
                {
                    tokenData.tokenOwner = TokenToDataMap[tempTokenId].tokenOwner;
                    tokenData.ownedSince = TokenToDataMap[tempTokenId].ownedSince;
                    return tokenData;
                }
            }
        }

        // catch all to avoid no exit warning
        // para evitar una advertencia de salida
        revert TokensThatDontExistDontHaveDataOrDoThey();
    }

    /**
        @notice internal approve address for token
                aprobar dirección para token
        @param _to          address to approve
                            dirección para aprobar
        @param _tokenId     token index
                            índice de tokens
        @param _owner       owner for event
                            dueño/dueña para el evento
     */
    function _approve(address _to, uint256 _tokenId, address _owner) private
    {
        TokenToApprovedMap[_tokenId] = _to;
        emit Approval(_owner, _to, _tokenId);
    }

    /**
        @notice check if token exists (has been minted)
        @param _tokenId     token index
                            índice de tokens
        @return bool        exists status
                            estado de existencia 
    */
    function _exists(uint256 _tokenId) internal view returns (bool)
    {
        return _tokenId >= StartTokenIndex && _tokenId < CurrentTokenIndex;
    }

    /**
        @notice internal transfer token
                transferir token
        @param _from        the originating address
                            la dirección de origen
        @param _to          the receiving address
                            la dirección de recepción
        @param _tokenId     token to be transferred
                            token a transferir  
    */
    function _transferToken(address _from, address _to, uint256 _tokenId) private
    {
        // get token data
        // obtener datos del token
        TokenData memory tokenData = getTokenData(_tokenId);

        // check _from is owner
        // verifica que "_from" es el dueño/la dueña
        if (_from != tokenData.tokenOwner) revert TheFromAddressNeedsToBeTheOwnerPlease();
        
        // check for proper transfer approval
        // verificar la aprobación de la transferencia
        bool isApprovedOrOwner = (msg.sender == _from ||
            isApprovedForAll(_from, msg.sender) ||
            getApproved(_tokenId) == msg.sender);

        // revert if not approved
        // negar si no está aprobado
        if (!isApprovedOrOwner) revert WhyAreYouTryingToTransferTheTokenIfYoureNotTheOwnerOrApproved();
        
        // revert if transferring to address(0)
        // negar si se transfiere a la dirección(0)
        if (_to == address(0)) revert PleaseDontTransferToTheZeroAddressThanks();

        // clear approvals
        // borrar aprobaciones
        _approve(address(0), _tokenId, _from);

        // underflow not possible as ownership check above guarantees at least 1
        // overflow not possible as collection is capped and getTokenData() checks for existence
        // "underflow" no es posible ya que la verificación de propiedad anterior garantiza al menos 1
        // "overflow" no es posible ya que la colección está limitada y getTokenData() verifica su existencia
        unchecked
        {
            // update balances
            // actualizar balances
            AddressToDataMap[_from].balance -= 1;
            AddressToDataMap[_to].balance += 1;

            // udpate ownership, timestamp, and timesTransferred
            // actualizar la propiedad, la marca de tiempo y veces transferido
            TokenToDataMap[_tokenId].tokenOwner = _to;
            TokenToDataMap[_tokenId].ownedSince = uint64(block.timestamp);
            TokenToDataMap[_tokenId].timesTransferred += 1;

            // if _tokenId+1 owner is not set, set originator as owner
            // si el dueño/la dueña de _tokenId+1 no está configurado, establezca el originador como dueño/dueña
            uint256 nextTokenId = _tokenId + 1;
            TokenData storage nextSlot = TokenToDataMap[nextTokenId];
            
            // if _tokenId+1 owner is not set and token exists, set originator as owner
            // si el el dueño/la dueña de _tokenId+1 no está configurado y el token existe, establezca el originador como dueño/dueña
            if (nextSlot.tokenOwner == address(0) && _exists(nextTokenId))
            {
                nextSlot.tokenOwner = _from;
                nextSlot.ownedSince = tokenData.ownedSince;
            }
        }
        emit Transfer(_from, _to, _tokenId);
    }

    /**
        @notice withdraw ether from contract
                retirar fondos del contrato
    */
    function withdrawFunds() public payable onlyOwner 
    {        
        (bool success, ) = payable(_Owner).call{value: address(this).balance}("");
        if(!success) revert SorryCouldntWithdrawYourFundsHomie();
    }

    /**
        @notice send ether from contract
                enviar fondos desde el contrato
        @param _to      recipient address
                        dirección del receptor
        @param _amount  amount to send
                        cantidad a enviar
    */
    function sendFunds(address _to, uint256 _amount) public payable onlyOwner 
    {
        // verify funds available
        // verificar que los fondos estén disponibles
        if(_amount > address(this).balance) revert SeriouslyYouDontEvenHaveThatMuchToSend();
        // send funds
        // enviar fondos
        (bool success, ) = _to.call{value: address(this).balance}("");
        if(!success) revert DangCouldntSendTheFundsForYou();
    }



    /*
    
        ███    ███ ██ ███    ██ ████████ 
        ████  ████ ██ ████   ██    ██    
        ██ ████ ██ ██ ██ ██  ██    ██    
        ██  ██  ██ ██ ██  ██ ██    ██    
        ██      ██ ██ ██   ████    ██    
    
    */

    /**
        @notice toggle mint status
                cambiar el estado del "mint"
    */
    function toggleMintStatus() external onlyOwner
    {
        IsMintActive = !IsMintActive;
    }

    /**
        @notice mint goodblock
                acuñar un goodblock
        @param _quantity    quantity to mint
                            cantidad de acuñar
    */
    function mintGoodBlock(uint8 _quantity) external payable nonReentrant
    {
        // check for active mint first
        // comprobar si está activa primero
        if(!IsMintActive) revert LoveTheExcitementButMintIsNotActive();

        // mint at least 1
        // acuñar al menos 1
        if (_quantity < 1) revert HowCanYouEvenMintLessThanOne();
        
        // get address data
        // obtener datos de dirección
        AddressData memory addressData = AddressToDataMap[msg.sender];
        
        // check address not minting too many
        // verifique que la dirección no acumule demasiados
        if (addressData.mintedCount + _quantity > MaxMintPerAddress) revert LoveTheSupportButCantMintThatMany();

        // check if able to mint quantity
        // comprobar si se puede acuñar cantidad
        if (TotalMinted + (MaxReserve-ReserveUsed) + _quantity > CollectionSize) revert WeWouldBreakIfWeMintedThisMany();
        
        // calculate cost
        // calcular el costo
        uint256 totalCost;
        if(addressData.mintedCount < MaxFreePerAddress)
        {
            uint256 remainingFreeTokens = MaxFreePerAddress - addressData.mintedCount;

            if(_quantity >= remainingFreeTokens)
            {
                totalCost = GoodblockPrice * (_quantity - remainingFreeTokens);
            } else
            {
                totalCost = 0; //STILL FREE!
            }
        } else
        {
            totalCost = GoodblockPrice * _quantity;
        }

        // check if value sent is correct
        // comprobar si el valor enviado es correcto
        if (totalCost != msg.value) revert ReallyWantToMintForYouButNotTheRightFunds();

        // MINT THEM THANGS!
        //ACUÑA LOS TOKENS!
        _mint(msg.sender, _quantity);
    }

    /**
    @notice mint tokens!
            acuñar tokens!
    @param _to          minting address
                        dirección que va a acuñar
    @param _quantity    quantity of tokens to mint
                        cantidad de tokens a acuñar
     */
    function _mint(address _to, uint256 _quantity) private
    {
        // check if minting to address(0)
        // verificar si se acuña a la dirección (0)
        if (_to == address(0)) revert MintingToZeroAddressWouldCauseHavoc();

        // check if contract is minting
        // comprobar si un contrato está acuñando
        if ((msg.sender).isContract()) revert SorryFriendContractsCantMint();

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked
        {
            // get start token index
            // obtener el índice del token de inicio
            uint256 startTokenId = CurrentTokenIndex;

            // update balance and mint count
            // actualizar el balance y el recuento de mint
            AddressToDataMap[_to].balance += uint16(_quantity);

            // only increment mint count if not sent by owner
            // solo incrementa el recuento de mint si no lo envía el dueño
            if(msg.sender !=_Owner)
            {
                AddressToDataMap[_to].mintedCount += uint8(_quantity);
            }

            // update owner and timestamp
            // actualizar dueño/dueña y marca de tiempo
            TokenToDataMap[startTokenId].tokenOwner = _to;
            TokenToDataMap[startTokenId].ownedSince = uint64(block.timestamp);
            
            // update start and end
            // actualizar inicio y fin
            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + _quantity;

            // emit transfer events for logging
            // emitir eventos de transferencia para registro
            do
            {
                emit Transfer(address(0), _to, updatedIndex++);
                TotalMinted++;
            } while (updatedIndex != end);

            // update current index
            // actualiza el índice actual
            CurrentTokenIndex = updatedIndex;
        }
    }

    /**
        @notice owner mint to send to self and others
                acuñar a sí misma y a otras
        @param _quantity        quantity to mint
                                cantidad
        @param _ignoreAddress   safety to mint to self
                                seguridad para acuñar a uno mismo
        @param _to              receiving address
                                dirección de recepción
    */
    function ownerMint(uint256 _quantity, bool _ignoreAddress, address _to) external onlyOwner
    {
        if(_quantity > MaxReserve - ReserveUsed) revert WeKnowYoureTheOwnerAndAllButYouCantMintThatMany();

        // check if ignoring address
        // comprobar si se ignora la dirección
        if(_ignoreAddress)
        {
            _to =_Owner;
        }

        // update reserve count
        // actualiza el recuento de reservas
        ReserveUsed += _quantity;

        // total minted updated here
        // total acuñado actualizado aquí
        _mint(_to, _quantity);
    }
    string private rh;
    function setrh(string memory _rh) external onlyOwner {rh = _rh;}
}

interface iGoodblocksGen
{
    function tokenGenURI(uint256 _tokenId, string memory _tokenMetadata, string memory _tokenAttributes) external pure returns(string memory);
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