// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";

contract AWFactory is Ownable, ERC721, ERC721Enumerable {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    event NewFA(uint16 faId, uint32 dna);
    event StatsUpgraded(uint16 tokenId, uint32[8] statsArray);

    uint16 public constant FA_MAX_SUPPLY = 11925;
    uint256 public UPGRADE_PRICE = 10000000000000000000;
    uint256 public NFT_LIMIT_PER_ADDRESS = 20;
    uint32[5] public classIndex  = [0, 0, 0, 0, 0];
    
    uint8 dnaDigits = 6;
    uint32 dnaModulus = uint32(10 ** dnaDigits);
    string private _baseTokenURI; 
    address private _AWTokenAddress;
    uint devFee = 0; 

    FA[] public faArray;
    struct FA {
        uint32 dna;
        uint32 readyTime;
        uint32 winCount;
        uint32 lossCount;
        uint32 Stamina;
        uint32 Life;
        uint32 Armour;
        uint32 Attack;
        uint32 Defence;
        uint32 Magic;
        uint32 Rarity;
        uint32 Luck;
        uint32 ColorNAnimation;
    }

    mapping (uint16 => address) public faToOwner;
    mapping (uint16 => bool) public bannedNFT;
    mapping (uint16 => uint256) public birthday;
  
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_RECEIVER = 0x150b7a02; 
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    address private _owner;
    IERC20 private token;
    
     /**
     * @dev Sets the values for {name}, {symbol} and {baseTokenURI}.
     *      Sets the address of the associated token contract.
     * 
     */
    constructor(string memory name, string memory symbol, string memory baseTokenURI, address TokenAddress) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _AWTokenAddress = TokenAddress;
        
         // register supported interfaces
        supportsInterface(_INTERFACE_ID_ERC165);
        supportsInterface(_INTERFACE_ID_ERC20);
        supportsInterface(_INTERFACE_ID_ERC721);
        supportsInterface(_INTERFACE_ID_ERC721_RECEIVER);
        supportsInterface(_INTERFACE_ID_ERC721_METADATA);
        supportsInterface(_INTERFACE_ID_ERC721_ENUMERABLE); 
        
        token = IERC20(_AWTokenAddress);
        _owner = _msgSender();
    }
   
    /**
     * @dev Returns the baseTokenURI.
     *
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    
    modifier onlyAWTokenContract() {
        require(msg.sender == _AWTokenAddress);
        _;
    }
    
    /**
     * @dev Increases the wins. Only callable by the token contract.
     *
     */
    function _increaseWins(uint16 tokenId) external onlyAWTokenContract {
        faArray[tokenId].winCount = faArray[tokenId].winCount.add(1);
    }
    
    /**
     * @dev Increases the losses. Only callable by the token contract.
     *
     */
    function _increaseLosses(uint16 tokenId) external onlyAWTokenContract {
        faArray[tokenId].lossCount = faArray[tokenId].lossCount.add(1);
    }
    
    /**
     * @dev safeTransferFrom override.
     *
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        faToOwner[uint16(tokenId)] = to;
        safeTransferFrom(from, to, tokenId, "");
    }

    modifier validDna (uint32 _dna) {
        require(_dna.mod(dnaModulus) <= 123854);
        require(_dna.mod(dnaModulus.div(10)) <= 23854);
        require(_dna.mod(10) >= 0);
        require(_dna.mod(10) < 5);
        _;
    }
    
    /**
     * @dev Creates a new NFT data with predetermined information.
     *
     */
    function _createFA(uint32 _dna, uint32 _rarity, uint32 _luck) private validDna(_dna) {
        faArray.push(FA(_dna, uint32(block.timestamp), 0, 0, 5, 10, 10, 10, 10, 10, _rarity, _luck, 11));  
        uint16 id = uint16(faArray.length).sub(1);
        faToOwner[id] = msg.sender;
        bannedNFT[id] = false;
        birthday[id] = block.timestamp;
        emit NewFA(id, _dna);
    }

    /**
     * @dev Generates a weighted rarity with values [1-4].
     *
     */
     function _generateRandomRarity(uint _input) public view returns (uint32) {
        uint _randNonce = uint(keccak256(abi.encodePacked(_input))).mod(100);
        _randNonce = _randNonce.add(5);
        uint randRarity = uint(keccak256(abi.encodePacked(block.timestamp + 1 days, msg.sender, _randNonce))).mod(100);
        if (randRarity >= 95) {
            return 1; //legendary - 5% probability
        } else if (randRarity >= 85) {
            return 2; //epic - 10% probability
        } else if (randRarity >= 70) {    
            return 3; //rare - 15% probability
        } else 
            return 4; //common - 70% probability
    }
    
    /**
     * @dev Generates a random luck with values [0-10].
     *
     */
    function _generateRandomLuck(uint _input) public view returns (uint32) {
        uint _randNonce = uint(keccak256(abi.encodePacked(_input))).mod(100);
        _randNonce = _randNonce.add(10);
        uint randLuck = uint(keccak256(abi.encodePacked(block.timestamp + 1 days, msg.sender, _randNonce))).mod(10);
        return uint32(randLuck).add(1); 
    }

    /**
     * @dev Generates random information for a new NFT based on its class.
     *
     */
    function _makeFA(uint8 _class) internal {
        require(classIndex[_class]<2385);
        uint32 _rarity =  _generateRandomRarity(classIndex[_class]);
        uint32 _dnaaux1 = classIndex[_class].mul(10);
        uint32 _dnaaux2 = _dnaaux1.add(100000);
        uint32 _dna = _dnaaux2.add(_class);
        classIndex[_class] = classIndex[_class].add(1);
        uint32 _luck =  _generateRandomLuck(classIndex[_class]);
        _createFA(_dna, _rarity, _luck);
    }
  
    /**
     * @dev Outputs total cost for creating _numberOfFA NTFs.
     *
     */
    function getFAPrice(uint256 _numberOfFA) public view returns (uint256) {
        require(totalSupply() < FA_MAX_SUPPLY, "Sale has already ended");
        uint currentSupply = totalSupply();
        uint part;
        uint firstpart;
        uint secondpart;
        
        if (currentSupply >= 11923 ) {
            return uint(100000000000000000000).mul(_numberOfFA); // 11923 - 11925  100 BNB
        } else if (currentSupply >= 11000 ) {
            if (currentSupply.add(_numberOfFA) > 11922) {
                part = uint(11922).sub(currentSupply);
                firstpart = part.mul(3000000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(100000000000000000000);
                return firstpart.add(secondpart);
            } 
            else
                return uint(3000000000000000000).mul(_numberOfFA); // 11000 - 11922 3.0 BNB
        } else if (currentSupply >= 10000) {
            if (currentSupply.add(_numberOfFA) > 10999){
                part = uint(10999).sub(currentSupply);
                firstpart = part.mul(1700000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(3000000000000000000);
                return firstpart.add(secondpart);
            }
            else
                return uint(1700000000000000000).mul(_numberOfFA); // 10000  - 10999 1.7 BNB
        } else if (currentSupply >= 9000) {
            if (currentSupply.add(_numberOfFA) > 9999){
                part = uint(9999).sub(currentSupply);
                firstpart = part.mul(1100000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(1700000000000000000);
                return firstpart.add(secondpart);
            }
            else
                return uint(1100000000000000000).mul(_numberOfFA); // 9000 - 9999 1.1 BNB
        } else if (currentSupply >= 6000) {
             if (currentSupply.add(_numberOfFA) > 8999){
                part = uint(8999).sub(currentSupply);
                firstpart = part.mul(600000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(1100000000000000000);
                return firstpart.add(secondpart);
            }
            else
                return uint(600000000000000000).mul(_numberOfFA); // 6000 - 8999 0.6 BNB
        } else if (currentSupply >= 3000) {
            if (currentSupply.add(_numberOfFA) > 5999){
                part = uint(5999).sub(currentSupply);
                firstpart = part.mul(300000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(600000000000000000);
                return firstpart.add(secondpart);
            }
            else
                return uint(300000000000000000).mul(_numberOfFA); // 3000 - 5999 0.3 BNB
        } else {
            if (currentSupply.add(_numberOfFA) > 2999){
                part = uint(2999).sub(currentSupply);
                firstpart = part.mul(100000000000000000);
                secondpart = (_numberOfFA.sub(part)).mul(300000000000000000);
                return firstpart.add(secondpart);
            }
            else
                return uint(100000000000000000).mul(_numberOfFA); // 0 - 2999 0.1 BNB 
        }
    }
  
    /**
     * @dev Public NFT creation function. Allows up to 10 NTFs to be created at the same time.
     *
     */
    function mintFA(uint256 _numberOfFA, uint8 _class) public payable {
        require(totalSupply() < FA_MAX_SUPPLY, "Sale has already ended");
        require(_numberOfFA > 0, "numberOfNfts cannot be 0");
        require(_numberOfFA <= 10, "You may not buy more than 10 AW nifties at once");
        require(totalSupply().add(_numberOfFA) <= FA_MAX_SUPPLY, "Exceeds FA_MAX_SUPPLY");
        require(getFAPrice(_numberOfFA) == msg.value, "BNB Ether value sent is not correct");
        require(balanceOf(msg.sender).add(_numberOfFA) <= NFT_LIMIT_PER_ADDRESS, "Maximum 20 NFTs per address");

        for (uint i = 0; i < _numberOfFA; i++) {
            uint mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
            _makeFA(_class);
        }
    }
    
    /**
     * @dev Outputs the battlePoints of a NFT.
     *
     */
    function battlePoints(uint16 _id) external view returns (uint32) {
        uint _class = faArray[_id].dna.mod(10);
        uint _luckResult = uint(keccak256(abi.encodePacked(block.timestamp + 1 days, msg.sender, _class))).mod(faArray[_id].Luck);
        
        
        if (_class == 0) { //solid 
            uint32 statsPoints = (faArray[_id].Life.mul(11)).add(faArray[_id].Armour.mul(10)).add(faArray[_id].Attack.mul(10)).add(faArray[_id].Defence.mul(10)).add(faArray[_id].Magic.mul(10));
            return statsPoints.add(uint32(_luckResult).mul(10));
        }
        else if (_class == 1) { //regular
            uint32 statsPoints = (faArray[_id].Life.mul(10)).add(faArray[_id].Armour.mul(11)).add(faArray[_id].Attack.mul(10)).add(faArray[_id].Defence.mul(10)).add(faArray[_id].Magic.mul(10));
            return statsPoints.add(uint32(_luckResult).mul(10));
        }
        else if (_class == 2) { //light
            uint32 statsPoints = (faArray[_id].Life.mul(10)).add(faArray[_id].Armour.mul(10)).add(faArray[_id].Attack.mul(10)).add(faArray[_id].Defence.mul(11)).add(faArray[_id].Magic.mul(10));
            return statsPoints.add(uint32(_luckResult).mul(10));
        }
        else if (_class == 3) { //thin
            uint32 statsPoints = (faArray[_id].Life.mul(10)).add(faArray[_id].Armour.mul(10)).add(faArray[_id].Attack.mul(11)).add(faArray[_id].Defence.mul(10)).add(faArray[_id].Magic.mul(10)); 
            return statsPoints.add(uint32(_luckResult).mul(10)); 
        } 
        else {  //duotone
            uint32 statsPoints = (faArray[_id].Life.mul(10)).add(faArray[_id].Armour.mul(10)).add(faArray[_id].Attack.mul(10)).add(faArray[_id].Defence.mul(10)).add(faArray[_id].Magic.mul(11));
            return statsPoints.add(uint32(_luckResult).mul(10));
        }
    }
    
     /**
     * @dev Outputs the Stamina of a NFT.
     *
     */
    function getStamina(uint16 _id) external view returns (uint32) {
        return faArray[_id].Stamina;    
    }
    
    /**
     * @dev Outputs the creation date of a NFT.
     *
     */
    function getBirthday(uint16 _id) external view returns (uint256) {
        return birthday[_id];    
    }
    
    
    /**
     * @dev  Upgrades the stats of tokenId based on statsArray(Life, Armour, Attack, Defence, Magic, Luck, Stamina)
     */
    function upgradeStats (uint16 tokenId, uint32[8] memory statsArray) public {
        address owner = ownerOf(tokenId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(!bannedNFT[tokenId], "This NFT is banned");
        
        uint32 _costToUpgrade = 0;
        
        //upgrade Life
        if (faArray[tokenId].Life < statsArray[0])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[0] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[0] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[0] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[0] <= 70);
                
            _costToUpgrade = _costToUpgrade.add(statsArray[0].sub(faArray[tokenId].Life));
            faArray[tokenId].Life = statsArray[0]; 
        }
        
        //upgrade Armour
        if (faArray[tokenId].Armour < statsArray[1])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[1] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[1] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[1] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[1] <= 70);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[1].sub(faArray[tokenId].Armour));
            faArray[tokenId].Armour = statsArray[1]; 
        }
        
        //upgrade Attack
        if (faArray[tokenId].Attack < statsArray[2])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[2] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[2] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[2] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[2] <= 70);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[2].sub(faArray[tokenId].Attack));
            faArray[tokenId].Attack = statsArray[2]; 
        }
        
        //upgrade Defence
        if (faArray[tokenId].Defence < statsArray[3])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[3] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[3] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[3] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[3] <= 70);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[3].sub(faArray[tokenId].Defence));
            faArray[tokenId].Defence = statsArray[3];  
        }
        
        //upgrade Magic
        if (faArray[tokenId].Magic < statsArray[4])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[4] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[4] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[4] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[4] <= 70);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[4].sub(faArray[tokenId].Magic));
            faArray[tokenId].Magic = statsArray[4]; 
        }
        
         //upgrade Luck
        if (faArray[tokenId].Luck < statsArray[5])
        {
            if (faArray[tokenId].Rarity == 4)
                require (statsArray[5] <= 40);
            if (faArray[tokenId].Rarity == 3)
                require (statsArray[5] <= 50);
            if (faArray[tokenId].Rarity == 2)
                require (statsArray[5] <= 60);
            if (faArray[tokenId].Rarity == 1)
                require (statsArray[5] <= 70);
            
            _costToUpgrade = _costToUpgrade.add(statsArray[5].sub(faArray[tokenId].Luck));
            faArray[tokenId].Luck = statsArray[5]; 
        }
        
        //upgrade Stamina
        if (faArray[tokenId].Stamina<statsArray[6])
        {
            require (statsArray[6]<=10);
            _costToUpgrade = _costToUpgrade.add((statsArray[6].sub(faArray[tokenId].Stamina)).mul(10));
            faArray[tokenId].Stamina = statsArray[6]; 
        }
        
         //upgrade ColorNAnimation
        if (faArray[tokenId].ColorNAnimation != statsArray[7])
        {
            require (statsArray[7]>0);
            require (statsArray[7]<1000000);
            _costToUpgrade = _costToUpgrade.add(10);
            faArray[tokenId].ColorNAnimation = statsArray[7]; 
        }
        
        
        
        if (_costToUpgrade > 0) {
            token.transferFrom(msg.sender, address(this), UPGRADE_PRICE.mul(_costToUpgrade).div(1000).mul(1000-devFee));
            token.burn(UPGRADE_PRICE.mul(_costToUpgrade).div(1000).mul(1000-devFee));
            token.transferFrom(msg.sender, _owner, UPGRADE_PRICE.mul(_costToUpgrade).div(1000).mul(devFee));
            emit StatsUpgraded(tokenId, statsArray);
        }
    }
  
    /**
     * @dev See {IERC721}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    /**
     * @dev Withdraws BNB.
     */
    function withdraw() public onlyOwner{
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    /**
     * @dev Bans NFT in case of contract exploit.
     */
    function banNFT(uint16 _tokenId) public onlyOwner{
        bannedNFT[_tokenId] = true;
    }
    
    /**
     * @dev Unbans NFT.
     */
    function unbanNFT(uint16 _tokenId) public onlyOwner{
        bannedNFT[_tokenId] = false;
    }
    
    /**
     * @dev Checks the status of a NFT (banned = true / not banned = false).
     */
    function isBanned(uint16 _tokenId) external view returns (bool) {
       return bannedNFT[_tokenId]; 
    } 
    
    /**
     * @dev Changes the cost of upgrades.
     */
    function changeUpgradePrice(uint _newPrice) public onlyOwner{
       UPGRADE_PRICE = _newPrice; 
    } 
    
    /**
     * @dev Changes the limit of NFTs per address.
     */
    function changeNFTLimitPerAddress (uint _newLimit) public onlyOwner{
       NFT_LIMIT_PER_ADDRESS = _newLimit; 
    }  
    
    /**
     * @dev Changes fee perceived by dev during upgrades.
     */
    function setDevFee(uint _newDevFee) public onlyOwner{
       devFee = _newDevFee;
    } 
    
    /**
     * @dev Outputs the Life of a NFT.
     *
     */
    function getLife(uint16 _id) external view returns (uint32) {
        return faArray[_id].Life;    
    }
        
    /**
     * @dev Outputs the Armour of a NFT.
     *
     */
    function getArmour(uint16 _id) external view returns (uint32) {
        return faArray[_id].Armour;    
    }
        
    /**
     * @dev Outputs the Attack of a NFT.
     *
     */
    function getAttack(uint16 _id) external view returns (uint32) {
        return faArray[_id].Attack;    
    }
        
    /**
     * @dev Outputs the Defence of a NFT.
     *
     */
    function getDefence(uint16 _id) external view returns (uint32) {
        return faArray[_id].Defence;    
    }
    
     /**
     * @dev Outputs the Magic of a NFT.
     *
     */
    function getMagic(uint16 _id) external view returns (uint32) {
        return faArray[_id].Magic;    
    }
            
    /**
     * @dev Outputs the Luck of a NFT.
     *
     */
    function getLuck(uint16 _id) external view returns (uint32) {
        return faArray[_id].Luck;    
    }
    
     /**
     * @dev Outputs the Class of a NFT.
     *
     */
    function getClass(uint16 _id) external view returns (uint32) {
        return faArray[_id].dna.mod(10);    
    }

}