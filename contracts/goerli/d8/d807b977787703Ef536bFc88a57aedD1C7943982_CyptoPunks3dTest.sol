// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

interface ERC1155NFT {
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);
}

library Counters {
    struct Counter {
        uint256 _value; 
    }

    //  CHANGE THE VALUE TO 500 where round 1 starts
    function current(Counter storage counter) internal view returns (uint256) {
        return (counter._value +10);
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

interface ERC20{
    function transferFrom( address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address owner) external returns(uint256);
    function decimals() external returns (uint8);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract CyptoPunks3dTest is ERC721, Pausable, ERC721Burnable {
    using Counters for Counters.Counter;  
    address public burnAddress = 0xd0691889BAE9dc81436C0baE01239aa5Ec266029;  // Amulay sir's wallet
    address[4] public CryptoCurrencies; 

    bool[5] public paymentPermitted =[true,true,true,true,true];

    address public ExistingERC1155;
    
    Counters.Counter private _gloablId;       

    uint256 public EtherPrice;                                  
    mapping(address =>bool) public validators;              
    uint public Discount;  // upto one decimals 50 % -> 500
    uint public whitelistTimeBound;                         
    address public owner;     
    event Testing(uint discount, uint amount,uint timestamp);                              

    uint256[][] public priceCardInDollar = 
    [
        // amountInEthers[0][x] should not be used
        [ 
            100,
            100,
            100,
            100,
            100,
            100
        ], 
        [
            140,
            133,
            126,
            119,
            112,
            98 
        ],
        [
            147,
            140,
            133,
            125,
            118,
            103 
        ],
        [
            155,
            147,
            139,
            132,
            124,
            109 
        ],
        [
            163,
            154,
            145,
            138,
            130,
            114 
        ],
        [
            171,
            162,
            153,
            145,
            137,
            120  
        ],
        [
            179,
            170,
            160,
            152,
            143,
            126 
        ],
        [
            188,
            189,
            169,
            160,
            151,
            132 
        ],
        [
            197,
            188,
            178,
            168,
            158, 	
            138 
        ],
        [
            207,
            197,
            187,
            176,
            166,
            145 
        ],
        [
            218,
            207,
            196,
            185,
            174,
            153 
        ]
    ];

    uint256[11] public roundCap = [ 10,  20,  30,  40,  50,  60,  70,  80,   90,  100, 110];
    //          ends                t0   t1   t2   t3   t4   t5   t6   t7    t8   t9   t10
    uint256[11] public unpauseTimeStamp;
    bool[11] public roundReveal = [ 
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false
    ];                                          

    string public baseURI = "https://crypt3dpunk.herokuapp.com/api/";
    
    mapping(uint256 => bool) public stopTransfer;
    mapping(uint =>address[]) public whiteListedAddress;

   constructor() ERC721("CyptoPunks3d", "CP3d") {                       
        ExistingERC1155 = 0xe8470ae2E17afa6892ed3494edBA0DBf064A4098;
        CryptoCurrencies[0]=0xE7DC78a7542Dc829fd4d84F96BfC971f3D82e051;
        CryptoCurrencies[1]=0x77c6f11c4f04C1Fd9b84A76DfE42a4FE293cA6d1;
        CryptoCurrencies[2]=0x9f5d82f9eCDC2110840EAA22a8189b834f53fa64; 
        CryptoCurrencies[3]=0x85B72D80db6408D588f815C5a9839b18c3AecB73;
        validators[msg.sender]=true;               
        owner =msg.sender;                  
        EtherPrice= 5000000; // current price of ethereum upto 2 decimals.
        unpauseTimeStamp[1]=block.timestamp;                            
        Discount=50;                                                    
        whitelistTimeBound = 72000; // 60*60*20  - 20 minutes
    }   

    uint256 public Round = 1;

    enum CurrentState {
        round0,
        round1,
        round2,
        round3,
        round4,
        round5,
        round6,
        round7,
        round8,
        round9,
        round10,
        pause,
        completed
    }

    CurrentState public currentState = CurrentState.round1; 

    modifier onlyValidator() {
        require(validators[msg.sender],"Only a validator can call this function");
        _;
    }

    function updateEtherPrice(uint price) public onlyValidator {
        EtherPrice=price;
    }

    function batchSwapExistingUsers(uint256[] memory nftIds) public {
        require(
            (_gloablId.current() + nftIds.length) <= roundCap[Round],
            "quantity exceeded the limit for this round"
        );
        for (uint256 i = 0; i < nftIds.length; i++) {
            require(
                ERC1155NFT(ExistingERC1155).balanceOf(msg.sender, nftIds[i]) >=
                    1,
                "You don't own this nftId"
            );
            ERC1155NFT(ExistingERC1155).safeTransferFrom(
                msg.sender,
                burnAddress,
                nftIds[i],
                1,
                "0x00"
            );
            _safeMint(msg.sender, nftIds[i]);
            uint256 tokenId = _gloablId.current();
            _gloablId.increment();
            _safeMint(msg.sender, tokenId);
            if (_gloablId.current() == roundCap[Round]) {
                currentState = CurrentState.pause;
                _pause();
            }
        }
    }   

    function pauseUnpauseNFTsTransfer(uint256 _round, bool flip) public onlyValidator{
        require(_round >= 0 && _round <= 10);
        stopTransfer[_round] = flip;
    }       

    // updatedValues are in dollars
    function updatePriceCard(uint256 round, uint256[] memory updatedValues) public onlyValidator {
        require(round >= 1 && round <= 10);
        require(updatedValues.length==6,"Invalid updatedValues array size");
        for(uint i=0; i<updatedValues.length; i++){
            priceCardInDollar[round][i] = updatedValues[i];
        }
    }   

    // Token value 0 - USDT     
    // Token value 1 - USDC     
    // Token value 2 - DAI      
    // Token value 3 - BUSD      
    // Token value 4 - Ethers   

    function AlterPayment(uint256 token)  public onlyValidator{
        paymentPermitted[token] = !paymentPermitted[token];
    }

    function addwhiteListBatch(uint _round, address[] memory _addresses) public onlyValidator{
        require(_round >= 1 && _round <= 10);
        whiteListedAddress[_round] =_addresses;
    }

    function addwhiteListAddress(uint _round, address _address) public onlyValidator{
        require(_round >= 1 && _round <= 10);
        whiteListedAddress[_round].push(_address);
    }

    function removeWhiteListAddress(uint _round, address _address) public onlyValidator {
        require(presentInWhitelist(_round, _address),"Not a whitelisted address");
        deleteFromWhiteList(_round, _address);
    }

    function batchMint(uint256 _quantity, address _to) public payable whenNotPaused{
        // require(currentState!=CurrentState.completed,"All NFTs are minted");
        require(uint256(currentState) == Round, "Please enter correct round");
        require(paymentPermitted[4],"Payment Stopped for ethers");
        require(
            (_gloablId.current() + _quantity) <= roundCap[Round],
            "quantity exceeded the limit for this round"
        );  
        require(
            _quantity == 1 ||
                _quantity == 2 ||
                _quantity == 3 ||
                _quantity == 4 ||
                _quantity == 5 ||
                _quantity == 10,
            "Invalid input : quantity"
        );
        uint NotlocalDiscount=1000;
        uint amount;
        // NOTE: EtherPrice is stored upto two decimals i.e. 137890 

        if (!validators[msg.sender]) {
            if(presentInWhitelist(Round,msg.sender) && (block.timestamp<=unpauseTimeStamp[Round]+whitelistTimeBound)){
                NotlocalDiscount =1000-Discount;
                deleteFromWhiteList(Round,msg.sender);
            }                         
            if(_quantity!=10){
                uint temp =_quantity-1;
                amount =((priceCardInDollar[Round][temp]*(10**20)*NotlocalDiscount)*_quantity)/(EtherPrice*1000);
            }else{  
                amount =((priceCardInDollar[Round][5]*(10**20)*NotlocalDiscount)*_quantity)/(EtherPrice*1000);
            }        
            require(msg.value >=amount , "Not enough ethers");
            // if (_quantity == 1) {
            // } else if (_quantity == 2) {
            //     require(msg.value >= ((priceCardInDollar[Round][1]*(10**20)*NotlocalDiscount)*_quantity)/(EtherPrice*1000), "Not enough ethers");
            // } else if (_quantity == 3) {
            //     require(msg.value >= ((priceCardInDollar[Round][2]*(10**20)*NotlocalDiscount)*_quantity)/(EtherPrice*1000), "Not enough ethers");
            // } else if (_quantity == 4) {
            //     require(msg.value >= ((priceCardInDollar[Round][3]*(10**20)*NotlocalDiscount)*_quantity)/(EtherPrice*1000), "Not enough ethers");
            // } else if (_quantity == 5) {
            //     require(msg.value >= ((priceCardInDollar[Round][4]*(10**20)*NotlocalDiscount)*_quantity)/(EtherPrice*1000), "Not enough ethers");
            // } else if (_quantity == 10) {
            //     require(msg.value >= ((priceCardInDollar[Round][5]*(10**20)*NotlocalDiscount)*_quantity)/(EtherPrice*1000), "Not enough ethers");
            // }
        }   
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = _gloablId.current();
            _gloablId.increment();
            _safeMint(_to, tokenId);
            if (_gloablId.current() == roundCap[Round]) {
                currentState = CurrentState.pause;
                _pause();
            }
        }
        emit Testing(NotlocalDiscount,amount,block.timestamp);
    }

    // NOTE :This function return the priceCard for a round PER NFT 
    // if you want the price in wei pass isEther true, for any other cryptocurrency pass isEther false
    // for USDT and USDC pass decimal-6, for dai and BUSD pass decimal-18

    function getPriceForARound(bool isEther,uint decimal,uint round) public view returns (uint[] memory){
        uint[] memory prices= new uint256[](6); 
        for(uint i=0; i<6; i++){
            if(isEther){
                uint256 amountinWei =(priceCardInDollar[round][i]*(10**20))/EtherPrice;
                prices[i]=amountinWei;
            }else{
                uint256 amount =(priceCardInDollar[round][i]*(10**decimal));
                prices[i]=amount;
            }
        }
        return prices;
    }

    // Token value 0 - USDT
    // Token value 1 - USDC
    // Token value 2 - DAI 
    // Token value 3 - BUSD 
    function batchMintUsingCryptoCurrency(uint8 token, uint256 _quantity, address _to) public payable whenNotPaused{
        // require(currentState!=CurrentState.completed,"All NFTs are minted");
        require(uint256(currentState) == Round, "Please enter correct round");
        require(paymentPermitted[token],"Payment Stopped for this crypto currency");
        require(
            (_gloablId.current() + _quantity) <= roundCap[Round],
            "quantity exceeded the limit for this round"
        );
        require(    
            _quantity == 1 ||
                _quantity == 2 ||
                _quantity == 3 ||
                _quantity == 4 ||
                _quantity == 5 ||
                _quantity == 10,
            "Invalid input : quantity"
        );
        uint8 decimal = ERC20(CryptoCurrencies[token]).decimals();
        if (!validators[msg.sender]) {
            if (_quantity == 1) {
                uint256 amount =(priceCardInDollar[Round][0]*(10**decimal))*_quantity;
                require(ERC20(CryptoCurrencies[token]).balanceOf(msg.sender) >= amount, "Not enough Tokens");
                ERC20(CryptoCurrencies[token]).transferFrom(msg.sender, address(this),amount);
            } else if (_quantity == 2) {
                uint256 amount =(priceCardInDollar[Round][1]*(10**decimal))*_quantity;
                require(ERC20(CryptoCurrencies[token]).balanceOf(msg.sender) >= amount, "Not enough Tokens");
                ERC20(CryptoCurrencies[token]).transferFrom(msg.sender,  address(this),amount);
            } else if (_quantity == 3) {
                uint256 amount =(priceCardInDollar[Round][2]*(10**decimal))*_quantity;
                require(ERC20(CryptoCurrencies[token]).balanceOf(msg.sender) >= amount, "Not enough Tokens");
                ERC20(CryptoCurrencies[token]).transferFrom(msg.sender,  address(this),amount);
            } else if (_quantity == 4) {
                uint256 amount =(priceCardInDollar[Round][3]*(10**decimal))*_quantity;
                require(ERC20(CryptoCurrencies[token]).balanceOf(msg.sender) >= amount, "Not enough Tokens");
                ERC20(CryptoCurrencies[token]).transferFrom(msg.sender,  address(this),amount);
            } else if (_quantity == 5) {
                uint256 amount =(priceCardInDollar[Round][4]*(10**decimal))*_quantity;
                require(ERC20(CryptoCurrencies[token]).balanceOf(msg.sender) >= amount, "Not enough Tokens");
                ERC20(CryptoCurrencies[token]).transferFrom(msg.sender,  address(this),amount);
            } else if (_quantity == 10) {
                uint256 amount =(priceCardInDollar[Round][5]*(10**decimal))*_quantity;
                require(ERC20(CryptoCurrencies[token]).balanceOf(msg.sender) >= amount, "Not enough Tokens");
                ERC20(CryptoCurrencies[token]).transferFrom(msg.sender,  address(this),amount);
            }
        }   
        for (uint256 i = 0; i < _quantity; i++) {
            uint256 tokenId = _gloablId.current();
            _gloablId.increment();
            _safeMint(_to, tokenId);
            if (_gloablId.current() == roundCap[Round]) {
                currentState = CurrentState.pause;
                _pause();
            }
        }
    }

    function reveal(uint256 _round) public onlyValidator {
        roundReveal[_round] = true;
    }

    function pause() public onlyValidator {
        _pause();
    }

    // _discount value should be one Decimal place  50 % -> 500, hence can't be more that 1000
    // _EtherPrice value is up to two decimal 1300

    function unpause(bool newRound, uint _EtherPrice, uint _discountPercentage, uint _whitelistTimeBound) public onlyValidator {
        require(_discountPercentage<=1000,"Discount can not be more than 100%");
        if (_gloablId.current() == roundCap[1]) {
            currentState = CurrentState.round2;
            Round = 2;
            unpauseTimeStamp[2]=block.timestamp;
        } else if (_gloablId.current() == roundCap[2]) {
            currentState = CurrentState.round3;
            Round = 3;
            unpauseTimeStamp[3]=block.timestamp;
        } else if (_gloablId.current() == roundCap[3]) {
            currentState = CurrentState.round4;
            Round = 4;
            unpauseTimeStamp[4]=block.timestamp;
        } else if (_gloablId.current() == roundCap[4]) {
            currentState = CurrentState.round5;
            Round = 5;
            unpauseTimeStamp[5]=block.timestamp;
        } else if (_gloablId.current() == roundCap[5]) {
            currentState = CurrentState.round6;
            Round = 6;
            unpauseTimeStamp[6]=block.timestamp;
        } else if (_gloablId.current() == roundCap[6]) {
            currentState = CurrentState.round7;
            Round = 7;
            unpauseTimeStamp[7]=block.timestamp;
        } else if (_gloablId.current() == roundCap[7]) {
            currentState = CurrentState.round8;
            Round = 8;
            unpauseTimeStamp[8]=block.timestamp;
        } else if (_gloablId.current() == roundCap[8]) {
            currentState = CurrentState.round9;
            Round = 9;
            unpauseTimeStamp[9]=block.timestamp;
        } else if (_gloablId.current() == roundCap[9]) {
            currentState = CurrentState.round10;
            Round = 10;
            unpauseTimeStamp[10]=block.timestamp;
        } else if (_gloablId.current() == roundCap[10]) {
            currentState = CurrentState.completed;
            Round = 10;
        }
        if(newRound){
            EtherPrice =_EtherPrice;
            Discount=_discountPercentage;    
            whitelistTimeBound =_whitelistTimeBound;
        }
        _unpause();
    }

    function getNextTokenId() public view returns (uint256) {
        return _gloablId.current();
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    //  Withdraw ethers from this contract
    function withdrawEthers(address to,uint amount) public onlyValidator {
        (bool success, ) = (to).call{value: amount}("");
        require(success, "Failed to send ethers");
    }
    
    //  Withdraw cryptocurrencies from this contract
    function withdrawTokens(uint token, address to, uint amount) public onlyValidator {
        ERC20(CryptoCurrencies[token]).transfer(to,amount);
    }

    function _beforeTokenTransfer( address from, address to, uint256 tokenId  ) internal override {
        if (
            from != address(0) &&
            !stopTransfer[0] &&
            (tokenId >= 0 && tokenId <= 9)
        ) {
            revert("Owner has paused the trasfer of nfts for this round");
        }
        if (
            from != address(0) &&
            !stopTransfer[1] &&
            (tokenId >= 10 && tokenId <= 19)
        ) {
            revert("Owner has paused the trasfer of nfts for this round");
        }
        if (
            from != address(0) &&
            !stopTransfer[2] &&
            (tokenId >= 20 && tokenId <= 29)
        ) {
            revert("Owner has paused the trasfer of nfts for this round");
        }
        if (
            from != address(0) &&
            !stopTransfer[3] &&
            (tokenId >= 30 && tokenId <= 39)
        ) {
            revert("Owner has paused the trasfer of nfts for this round");
        }
        if (
            from != address(0) &&
            !stopTransfer[4] &&
            (tokenId >= 2100 && tokenId <= 2999)
        ) {
            revert("Owner has paused the trasfer of nfts for this round");
        }
        if (
            from != address(0) &&
            !stopTransfer[5] &&
            (tokenId >= 3000 && tokenId <= 3999)
        ) {
            revert("Owner has paused the trasfer of nfts for this round");
        }
        if (
            from != address(0) &&
            !stopTransfer[6] &&
            (tokenId >= 4000 && tokenId <= 4999)
        ) {
            revert("Owner has paused the trasfer of nfts for this round");
        }
        if (
            from != address(0) &&
            !stopTransfer[7] &&
            (tokenId >= 5000 && tokenId <= 5999)
        ) {
            revert("Owner has paused the trasfer of nfts for this round");
        }
        if (
            from != address(0) &&
            !stopTransfer[8] &&
            (tokenId >= 6000 && tokenId <= 6999)
        ) {
            revert("Owner has paused the trasfer of nfts for this round");
        }
        if (
            from != address(0) &&
            !stopTransfer[9] &&
            (tokenId >= 7000 && tokenId <= 7999)
        ) {
            revert("Owner has paused the trasfer of nfts for this round");
        }
        if (
            from != address(0) &&
            !stopTransfer[10] &&
            (tokenId >= 8000 && tokenId <= 8999)
        ) {
            revert("Owner has paused the trasfer of nfts for this round");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function updateBaseUri(string memory _newbaseURI) onlyValidator public {
        baseURI = _newbaseURI;
    }

    function addValidator(address validator) public onlyValidator{
        validators[validator]=true;
    }

    function removeValidator(address validator) public onlyValidator{
        require(owner!=validator,"Can not remove the owner");
        validators[validator]=false;
    }

    function presentInWhitelist(uint _round,address _address) internal view returns(bool){
        address[] memory a =whiteListedAddress[_round];
        for(uint i=0; i<a.length; i++){
            if(a[i]==_address) return true;
        }
        return false;
    }

    function deleteFromWhiteList(uint _round,address _address) internal {
        uint index;
        address[] memory a =whiteListedAddress[_round];
        for(uint i=0; i<a.length; i++){
            if(a[i]==_address) index=i;
        }
        delete whiteListedAddress[_round][index];
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721) returns (bool){
        return interfaceId == 0x2a55205a || super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        address owner = _owners[tokenId];
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
            "ERC721: approve caller is not token owner nor approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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