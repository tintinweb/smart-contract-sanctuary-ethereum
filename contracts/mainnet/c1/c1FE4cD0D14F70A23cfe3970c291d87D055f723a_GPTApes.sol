/*        
              GPTA:                       
             ?P~5GG5?~                    
             !J^~JG5?^                    
               .Y&&#Y                     
                7Y55J                     
             ...:..!J?.                   
           .:.::...:!:                    
          ....:......                     
        .::...:::...                      
        .^::!BJ!~::::                     
         .:~B&G55J5~^~.                   
           :P#P??!77BB5                   
          .^~~~::^^^~:.                   
          .^^:  ..::^.                    
          ...       .:.                   
       .:.           .                    
   ~P~ ..            .:.                  
   .PP57              ::^^?J:             
    .:!J~             :JB5^7^             
                      :?:                 
*/
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "Ownable.sol";
import "ECDSA.sol";
import "ERC721A.sol";

interface INft is IERC721A {
    error InvalidSaleState();
    error NonEOA();
    error WithdrawFailedVault();
}

contract GPTApes is INft, Ownable, ERC721A {
    using ECDSA for bytes32;
    enum SaleStates {CLOSED, PUBLIC}
    SaleStates public saleState;
    uint256 public maxSupply = 10000;
    uint256 public publicPrice = 0.005 ether;
    uint256 public GiveawayPrice = 0 ether;
    uint64 public WALLET_MAX = 100;
    uint256 public maxFreeMint = 1;
    uint256 public maxGiveawayMint = 3;
    string private _baseTokenURI = "";
    string private baseExtension = ".json";
    bool public pausedGiveaway = false;
    string private seed = '7168484740775753454372592524734663322';
    string private phrase = '';
    event Minted(address indexed receiver, uint256 quantity);
    event SaleStateChanged(SaleStates saleState);
    mapping(address => uint256) private _freeMintedCount; 

    constructor() ERC721A("GPT-Apes", "GPTA") {}

    /// @notice Function used during the public mint
    /// @param quantity Amount to mint.
    /// @dev checkState to check sale state.
    function Mint(uint64 quantity) external payable checkState(SaleStates.PUBLIC){
    uint256 price = publicPrice;
    uint256 freeMintCount = _freeMintedCount[msg.sender];
    require(quantity<=(maxFreeMint-freeMintCount), "Invalid amount of free mint");
    if(quantity<=(maxFreeMint-freeMintCount)){
        price=0;
        _freeMintedCount[msg.sender] += quantity;
    }
    require(msg.value >= quantity * price, "Invalid ether amount");
    require((_numberMinted(msg.sender) - _getAux(msg.sender)) + quantity <= WALLET_MAX, "Wallet limit exceeded");
    require(_totalMinted() + quantity <= maxSupply, "Supply exceeded");

    _mint(msg.sender, quantity);
    emit Minted(msg.sender, quantity);
}


    /// @notice Function used for the giveaway mint
    /// @param quantity Amount to mint.
function GiveawayMint(uint64 quantity, string calldata sign) external payable checkState(SaleStates.PUBLIC){
    require(!pausedGiveaway, "Giveaway Paused");
    require(keccak256(bytes(sign)) == keccak256(abi.encodePacked(seed,phrase)), "Invalid Signature");
    uint256 freeMintCount = _freeMintedCount[msg.sender];
    require((_numberMinted(msg.sender) - _getAux(msg.sender)) + quantity <= WALLET_MAX, "Wallet limit exceeded");
    require((_totalMinted() + quantity) <= maxSupply, "Supply Exceeded");
    require((quantity + freeMintCount) <= maxGiveawayMint, "Giveaway Limit Exceeded");
    require(msg.value >= quantity * GiveawayPrice, "Invalid Ether Amount");
    _freeMintedCount[msg.sender] = freeMintCount + quantity;
    _mint(msg.sender, quantity);
    emit Minted(msg.sender, quantity);
}

    
    /// @notice Fail-safe withdraw function, incase withdraw() causes any issue.
    /// @param receiver address to withdraw to.
    function withdrawTo(address receiver) public onlyOwner {        
        (bool withdrawalSuccess, ) = payable(receiver).call{value: address(this).balance}("");
        if (!withdrawalSuccess) revert WithdrawFailedVault();
    }


    /// @notice Function used to change mint public price.
    /// @param newPublicPrice Newly intended `publicPrice` value.
    /// @dev Price can never exceed the initially set mint public price (0.069E), and can never be increased over it's current value.

    function setRound(uint256 _maxFreeMint, uint256 _maxGiveawayMint, uint64 newMaxWallet, uint256 newPublicPrice, uint256 newGiveawayPrice) external onlyOwner {
      maxFreeMint = _maxFreeMint;
      maxGiveawayMint = _maxGiveawayMint;
      WALLET_MAX = newMaxWallet;
      publicPrice = newPublicPrice;
      GiveawayPrice = newGiveawayPrice;
    }

    function setGiveawayState(bool _state) external onlyOwner {
        pausedGiveaway = _state;
    }


    /// @notice Function used to check the number of tokens `account` has minted.
    /// @param account Account to check balance for.
    function balance(address account) external view returns (uint256) {
        return _numberMinted(account);
    }


    /// @notice Function used to view the current `_baseTokenURI` value.
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /// @notice Sets base token metadata URI.
    /// @param baseURI New base token URI.
    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }


    /// @notice Function used to change the current `saleState` value.
    /// @param newSaleState The new `saleState` value.
    /// @dev 0 = CLOSED, 1 = PUBLIC
    function setSaleState(uint256 newSaleState) external onlyOwner {
    require(newSaleState <= uint256(SaleStates.PUBLIC), "Invalid sale state");
    saleState = SaleStates(newSaleState);
    emit SaleStateChanged(saleState);
    }



    /// @notice Verifies the current state.
    /// @param saleState_ Sale state to verify. 
    modifier checkState(SaleStates saleState_) {
        if (msg.sender != tx.origin) revert NonEOA();
        if (saleState != saleState_) revert InvalidSaleState();
        _;
    }

    function setPhrase(string calldata _phrase) external onlyOwner {
      phrase = _phrase;
    }

    function freeMintedCount(address owner) external view returns (uint256) {
    return _freeMintedCount[owner];
  }
    
 

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
            string memory baseURI = _baseURI();
            return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId),baseExtension)) : ''; 
    }
}