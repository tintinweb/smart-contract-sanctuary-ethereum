/**
 *Submitted for verification at Etherscan.io on 2022-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
// ----------------------------------------------------------------------------
// ArtWorks Sale contract for theArtClub.io
// (c) by Mario Brandinu, Santa Cruz - España.
// ----------------------------------------------------------------------------
// ----------------------------------------------------------------------------
//0xe0d189176c68f2fc55be8fef32e9883b287f739a
//nft sale 0xeaf6cd9141e9d5a91ffe7bb8b118738c69eb48b5
contract Ownable
{

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

abstract contract NFTInterface {
    function mint(address _to,uint256 _tokenId,string calldata _uri)  virtual external ;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) virtual external;
    
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    
    function ownerOf(uint __artId) virtual public view returns ( address artOwner);
    
    function safeTransferFrom( address _from, address _to, uint256 _tokenId) virtual public;
    
    function tokenURI(uint256 _tokenId) virtual external returns (string memory);
     
    function approveResaleNFT( uint256 _tokenId ) virtual public;
    function approveAuctionNFT( uint256 _tokenId ) virtual public;
    
    function addNftPurchaser(uint __artId,uint __tokenId, address  __buyer) public virtual ;//, uint prezzo, string memory __email
    function deleteNftPurchaser(uint __artId, address  seller  )virtual public ;
    function deleteArtworkPurchased(uint __tokenId, address  exOwner  ) virtual public ;
    
    function getArtIdOwners(uint __artId) virtual public view returns (address [] memory);
    
    function getArtworksOwnedBy(address __buyer) virtual public view returns (uint [] memory);
    
    function getNftTokenIds(uint __artId) virtual public view returns (uint [] memory);
 }
 
contract NFTsaleRio is  Ownable{ 
    
    address nftAddress = 0xe0d189176C68F2fc55BE8FeF32E9883b287f739a ;// da NFTTokenMetadata 
    NFTInterface public tokenNFT = NFTInterface(nftAddress);
    
    bool isActive;
    
    mapping(uint => address payable) public artistAddress;
    mapping(uint => uint) public feeArtclub;
    mapping(uint => uint) priceNFT;
    mapping(uint => bool) public isNftForSale;

    event ArtPurchasingDetail(
           string indexed __uri
        );
    constructor()
  {
     owner = msg.sender;
     isActive = true;
  }
    
    function setArtNFTContract( address  _contract)  public  returns (bool success) {
        require(msg.sender == owner,"Only theArtClub can add NFTs");
        nftAddress = _contract ; 
        tokenNFT = NFTInterface(nftAddress);
        return true;
    }
    function setArtNFT(uint256[] memory __artId , address[] memory  __artist, uint[] memory __price, uint[] memory __fee) public {
        require(msg.sender == owner,"Only theArtClub can add NFTs");
        for(uint8 i = 0; i < __artId.length; i++) {
            priceNFT[__artId[i]] = __price[i];
            artistAddress[__artId[i]] = payable(__artist[i]);
            feeArtclub[__artId[i]] = __fee[i];

        }
    }
    function buyArtIdNFT (uint __artId, uint __tokenId, string calldata __uri)  external payable returns (bool success) {//override
        require(isActive,"Contract has to be active");//, string memory __email
        require(artistAddress[__artId]!=address(0),"ADDRESS artist unknown");
        //the artClub prende il 20% di default ma lo settiamo nella creazione artId
        uint vendita = priceNFT[__artId];
        if(msg.value>priceNFT[__artId]){ vendita = msg.value; }//considero ipotesi che alzo il prezzo}
        uint commissione = vendita * feeArtclub[__artId] / 100;
        uint quotaArtista = vendita - commissione ;
        
        payable(address(uint160(owner))).transfer(commissione);
       
            artistAddress[__artId].transfer(quotaArtista);

            tokenNFT.mint(msg.sender,__tokenId,__uri);
       
            tokenNFT.addNftPurchaser(__artId,__tokenId,msg.sender);//, vendita
            priceNFT[__tokenId] = vendita;
        
            emit ArtPurchasingDetail( __uri );//__artId,
        
        return true;
    }
    
     function resaleNFT (uint256 _tokenId,uint __price) external returns (bool success){
        require(msg.sender == tokenNFT.ownerOf(_tokenId),"Only NFT owner can act here");
        priceNFT[_tokenId]=__price;
        tokenNFT.approveResaleNFT( _tokenId);
        isNftForSale[_tokenId]=true;
     return true;
    }
     
    function buyResaleNFT (uint __artId, uint __tokenId)  external payable returns (bool success) {//override
        require(isActive,"Contract has to be active");//, string memory __email
        address proprietario = tokenNFT.ownerOf(__tokenId);
        //the artClub prende il 10% ma lo settiamo -artista 10% - il resto il proprietario
        uint vendita = priceNFT[__tokenId]; //il prezzo va  messo nella transazione
        uint commissione = vendita * 10 /100;
        uint quotaArtista = vendita * 10 /100;
        uint quotaProprietario = vendita - commissione - quotaArtista;
        
        payable(address(uint160(proprietario))).transfer(quotaProprietario);
        
        payable(address(uint160(owner))).transfer(commissione);
       
        artistAddress[__artId].transfer(quotaArtista);

        tokenNFT.safeTransferFrom(proprietario, msg.sender, __tokenId);
       
            isNftForSale[__tokenId] = false;
            
            tokenNFT.addNftPurchaser(__artId,__tokenId,msg.sender);//, vendita

            tokenNFT.deleteNftPurchaser(__artId,proprietario);
            
            tokenNFT.deleteArtworkPurchased(__tokenId,proprietario);
            
        return true;
    }
    /* BUY WITH ARTCOIN 
    function buyNftWithArtcoin(uint __artId, uint __tokenId, string calldata __uri) external  returns (bool success) {//override
        address payable buyer = payable(msg.sender) ;//,string memory __email
        uint256 buyerBalance = tokenArtclub.balanceOf(buyer);
        //controlla che abbia artcoin nel wallet
        uint256 artCoin = priceNFT[__artId] * (10 ** uint256(10)) / tokenArtclub.getTokenPrice(); //va espresso in token e si aggiungono i decimali
        require(artCoin <= buyerBalance, "Not enough ArtCoin Available in the Buyer balance");
        require(isActive,"Contract has to be active");
        require(artistAddress[__artId]!=address(0),"ADDRESS artist unknown");
        
        tokenArtclub.transferFrom(buyer, owner, artCoin * feeArtclub[__artId] / 100);//commissione TAC
        tokenArtclub.transferFrom(buyer, artistAddress[__artId], artCoin * (100-feeArtclub[__artId]) / 100);//
        
        tokenNFT.mint(msg.sender,__tokenId,__uri);
            
            tokenNFT.addNftPurchaser(__artId,__tokenId,msg.sender);//, priceNFT[__artId]
            priceNFT[__tokenId] = priceNFT[__artId];

            emit ArtPurchasingDetail( __uri );//__artId,
            
        return true;
    }
    function buyResaledNFTwithArtcoin (uint __artId, uint __tokenId)  external returns (bool success) {//override
        address payable buyer = payable(msg.sender) ;//, string memory __email
        uint256 buyerBalance = tokenArtclub.balanceOf(buyer);
        //controlla che abbia artcoin nel wallet
        uint256 artCoin = priceNFT[__tokenId] * (10 ** uint256(10)) / tokenArtclub.getTokenPrice(); //va espresso in token e si aggiungono i decimali
        require(artCoin <= buyerBalance, "Not enough ArtCoin Available in the Buyer balance");
        require(isActive,"Contract has to be active");
        require(artistAddress[__artId]!=address(0),"ADDRESS artist unknown");
        
        address proprietario = tokenNFT.ownerOf(__tokenId);
        //the artClub prende il 10% ma lo settiamo -artista 10% - il resto il proprietario
        uint commissione = artCoin * 10 /100;
        uint quotaArtista = artCoin * 10 /100;
        uint quotaProprietario = artCoin - commissione - quotaArtista;
        
        
        tokenArtclub.transferFrom(buyer, owner, commissione);//commissione TAC
        tokenArtclub.transferFrom(buyer, artistAddress[__artId], quotaArtista);//
        tokenArtclub.transferFrom(buyer, proprietario, quotaProprietario);//

        tokenNFT.safeTransferFrom(proprietario, msg.sender, __tokenId);
       
            isNftForSale[__tokenId] = false;
            
            tokenNFT.addNftPurchaser(__artId,__tokenId,msg.sender);
            
            
            tokenNFT.deleteNftPurchaser(__artId,proprietario);
            
            tokenNFT.deleteArtworkPurchased(__tokenId,proprietario);
            
        return true;
    }
    */
    
    function changeStato(bool stato) public {
        require(msg.sender == owner,"Solo TheArtClub puo disattivare il contratto");
        isActive = stato;
    }
    

   function getArtIdOwners(uint __artId) public view returns (address [] memory) {
  		return tokenNFT.getArtIdOwners(__artId);
	}
    
    function getArtworksOwnedBy(address __buyer) public view returns (uint [] memory) {
  		return tokenNFT.getArtworksOwnedBy(__buyer);
	}
    function getNftTokenIds(uint __artId) public view returns (uint [] memory) {
  		return tokenNFT.getNftTokenIds(__artId);
	}
    function getOwnerOf(uint __artId) public view returns (address) {
  		return tokenNFT.ownerOf(__artId);
	}
    function getPriceNFT(uint __artId) public view  returns (uint){
  		return priceNFT[__artId];
	}
	/*function getAmountPurchased(uint __tokenId) external view returns (uint){
  		return priceNFT[__tokenId];
	}*/

    receive () payable  external {
        revert();//evita di ricevere pagamenti fuori dal processo
    }
}