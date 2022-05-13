// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "./ERC721A.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";
import "./Counters.sol";

contract Strambolics is Ownable, ERC721A, ReentrancyGuard {
    uint256 public immutable maxPerAddressDuringMint;
    uint256 public immutable amountForDevs;
    uint256 public immutable amountForAuctionAndDev;

    //CREO QUE ESTAS VARIABLES SE PUEDEN MOVER AL PRINCIPIO DEL CONTRATO

    uint256 public constant AUCTION_START_PRICE = 0.00001 ether;
    uint256 public constant AUCTION_END_PRICE = 0.15 ether;
    uint256 public constant AUCTION_PRICE_CURVE_LENGTH = 340 minutes;
    uint256 public constant AUCTION_DROP_INTERVAL = 20 minutes;
    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) /
            (AUCTION_PRICE_CURVE_LENGTH / AUCTION_DROP_INTERVAL);



    struct SaleConfig {
        uint32 auctionSaleStartTime;
        uint32 publicSaleStartTime;
        uint64 mintlistPrice;
        uint64 publicPrice;
        uint32 publicSaleKey;
    }

    SaleConfig public saleConfig;

    mapping(address => uint256) public allowlist;

    //#################### Variables DeadCake

    using Counters for Counters.Counter;
    Counters.Counter private _nftIds;

    // Roles del Contrato  
    mapping(address => bool ) private roles;
    // ID_NFT y su Precio    
    mapping(uint256 => uint256 ) private preciosNFT;
    // Numero total de NFT por tipologia 
    uint256 private numeroTotalDeNFTPorTipo = 10000; 
    // Lista IDs NFT  vs TIPO NFT  
    mapping(uint256 => uint8 ) private listaIdNFTPorTipo;
    // Representa la unica Caja
    struct Caja {
        uint256 nftMinteados;   
        uint256 precio;
        uint256 nftNoMinteados;    
    }
    Caja[4] private cajas;   
 
 
    mapping(uint256 => bool) private idNFTEnVenta;
    event MintNFT(address _minteador,uint256 _idNFT);
    event BuyNFT(address _vendedor, address _comprador, uint256 _idNFT,uint256 _precio);


    //#################### CONSTRUCTOR INIT
    //#################### CONSTRUCTOR INIT

    constructor(
        uint256 collectionSize_,
        uint256 amountForAuctionAndDev_,
        uint256 amountForDevs_,
        uint256 maxBatchSize_
    ) ERC721A("Strambolics token", "STRAMB", maxBatchSize_, collectionSize_) {
        maxPerAddressDuringMint = maxBatchSize_;
        amountForAuctionAndDev = amountForAuctionAndDev_;
        amountForDevs = amountForDevs_;
        require(
            amountForAuctionAndDev_ <= collectionSize_,
            "You need a bigger amount of Strambolics in your collection"
        );
    }

    //#################### CONSTRUCTOR FIN
    //#################### CONSTRUCTOR FIN
    //#################### CONSTRUCTOR FIN

    //####################//####################//#################### ESTA NO SABEMOS SI ES NECESARIA

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Ristricted to users");
        _;
    }

    //####################//####################//#################### ESTA NO SABEMOS SI ES NECESARIA

    // Esta es para hacer whitelist de wallets
    // Función 1. esta función es la de minteo para los programadores. Verifica que no se han minteado aun el maximo permitido y tambien exige que se minten los NFT en grupos de mulitples de maxBatchSize
    function mintInicial(uint256 quantity) external onlyOwner {
        require(
            totalSupply() + quantity <= amountForDevs,
            "too many already minted before dev mint"
        );
        require(
            quantity % maxBatchSize == 0,
            "can only mint a multiple of the maxBatchSize"
        );
        uint256 numChunks = quantity / maxBatchSize;
        for (uint256 i = 0; i < numChunks; i++) {
            _safeMint(msg.sender, maxBatchSize);
        }
    }

    // Función 2a. para mintear duranet la preventa, solo para las carteras whitelist
    function mintPreventa() external payable callerIsUser {
        uint256 price = uint256(saleConfig.mintlistPrice);
        require(price != 0, "Not possible to mint yet. Whitelist sale has not started yet");
        require(allowlist[msg.sender] > 0, "Not possible to mint. You are not part of the Whitelist");
        require(totalSupply() + 1 <= collectionSize, "Not possible to mint. You have reached the maximun amount for mint.");
        allowlist[msg.sender]--;
        _safeMint(msg.sender, 1);
        //refundIfOver(price);
    }

    // Función 2b. para mintear cualquier cartera fuera de whitelist
    function mintNft(uint256 quantity, uint256 callerPublicSaleKey)
        external
        payable
        callerIsUser
    {
        SaleConfig memory config = saleConfig;
        uint256 publicSaleKey = uint256(config.publicSaleKey);
        //uint256 publicPrice = uint256(config.publicPrice);
        //uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
        require(
            publicSaleKey == callerPublicSaleKey,
            "Not possible to mint. The public sale key is wrong"
        );

        /*require(
            isPublicSaleOn(publicPrice, publicSaleKey, publicSaleStartTime),
            "Not possible to mint yet. Public sale has not started yet"
        );*/
        require(
            totalSupply() + quantity <= collectionSize,
            "Not possible to mint anymore. Collection is sold out."
        );
        require(
            numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
            "Not possible to mint. You have reached the maximun amount for mint."
        );
        _safeMint(msg.sender, quantity);
        //refundIfOver(publicPrice * quantity);
    }

    //Kamus: Función 5a. para poner en venta el NFT 
    function venderNft(uint256 _idNFT,bool vender) external returns (bool) {
        //require(msg.sender == NFT.ownerOf(_idNFT),"Only NFT owner can list the it for sale.");
        idNFTEnVenta[_idNFT] = vender;
        return true; 
    }   
  
    //Kamus: Función 5b. para cambiar el precio del NFT para cuando el usuario ponga en venta el mismo
    function cambiarPreciosNFT(uint256 _idNFT,  uint256 precioNFT) external returns (bool) {
       require(msg.sender == ownerOf(_idNFT), "Cambio del precio autorizado solo al Propietario del NFT");
        preciosNFT[_idNFT] = precioNFT;
        return true; 
    }   

    //Kamus: Función 6. Función para comprar un NFT
    function comprarNft(uint256 _idNFT) external returns (bool) {
        require(idNFTEnVenta[_idNFT],"Please least the NFT for sale.");
       // uint256 precioNFT = NFT.precioDelNFTEnMarketPlace(_idNFT);
        //require(tokenBUSD.balanceOf(msg.sender) >= precioNFT, "You dont have enough balance");

        //address propietarioNFT = NFT.ownerOf(_idNFT);

        //tokenBUSD.transferFrom(msg.sender,propietarioNFT,precioNFT);

       // NFT.transferirNFT(propietarioNFT, msg.sender, _idNFT);

        idNFTEnVenta[_idNFT] = false;

       // emit BuyNFT(propietarioNFT, msg.sender, _idNFT, precioNFT);

        return true; 
    }

/*
    // Función 8. para obtener el precio del NFT mas caro vendido hasta el momento
    // Creo que esta funcion ya estara includia pro defecto en el ERC721a, ya que sale en el contrato de Azuki, pero no se ve en ninguna parte del codigo 
    function getNftTopPrice () {
        // Falta el codigo
    }

    // Función 9. 	Obtener el precio al que se ha vendido el NFT más caro de la colección
    // Creo que esta funcion ya estara includia pro defecto en el ERC721a, ya que sale en el contrato de Azuki, pero no se ve en ninguna parte del codigo 
    function getNftPerWaller () {
        // Falta el codigo
    }

    // Función 10. Obtener el NFT correspondiente a un id dado.
    function getCaracteristicasNft () {
        // Falta el codigo
    }

    // Función 11. Publicar los nfts en Opensea. (esto en principio, se realiza mediante el script de publicación.
    function publicarNft() {
        // Falta el codigo
    }
*/

    // Función 12. Transferir el nft de una wallet a otra (aquí hay que pensar si se cobra porcentaje por transferir de una a otra, ya que si la gente transfiere puede estar vendiendo sin hacerlo a través del contrato)
    // Creo que esta funcion ya estara includia pro defecto en el ERC721a, ya que sale en el contrato de Azuki, pero no se ve en ninguna parte del codigo 
    /*function transferirNFT(address account, address comprador, uint256 _idNFT) external onlyWhitelisted {
        require(account == ownerOf(_idNFT), "Solo puede vender el Propietario del NFT");
        _transfer(account, comprador, _idNFT);
    }*/

    // Funcion 13. Genera un listado de Wallets que tienen acceso al MINTEO en la fase de preventa.
    //#################### 13 ####################
    //Kamus: Función auxiliar para restringir a solo whitelisted wallets. En Deadecake se onlyUser
    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "Restricted to whitelisted wallets.");
        _;
    }

    //Kamus: Función para anadir una wallet a Whitelist.. En Deadecake se llama agregarUser. 
    // Hay que crear la variable para los roles del contrato - mapping(address => bool ) private roles;
    function whitelistWallet (address account) public onlyWhitelisted {
        roles[account] = true;  
    }

    //Kamus: Función para borrar una wallet de la Whitelist. En Deadecake se llama borrarUser
    function borrarWhitelistWallet (address account) public onlyWhitelisted {
        roles[account] = false; 
    }

    //Kamus: Función que devuelve si una cartera en particular esta en la whitelist. En Deadecake se llama isUser
   function isWhitelisted(address account)  public view returns (bool) {
        require(roles[account] == true, "Restricted to whitelisted wallets.");
        return true;
    }
    //#################### 13 ####################


    // // metadata URI
    string private _baseTokenURI;


    // Función 15. Función que etira el dinero que el contrato tiene hacia fuera "Solo el dueno del contrato puede hacerlo"
    function retirarFondos() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // Función 16. Define cuando empieza la la subasta publica. Supongo que es cuando los token se listan en opensea
    function setAuctionSaleStartTime(uint32 timestamp) external onlyOwner {
        saleConfig.auctionSaleStartTime = timestamp;
    }

    ///Funciones de sporte que no habiamos declarado

    // En esta función, se le introduce el id de un NFT y esta devuelve la cartera que lo posee
    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    // Esta función eveuleve el numero de tokens minteados de una cartera en especifico
    function numberMinted(address owner) public view returns (uint256) {
        return _numberMinted(owner);
    }
}