// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./IERC20.sol";
import "./IFA.sol"; 

contract AWAddons is Ownable, ERC721, ERC721Enumerable {
    using SafeMath for uint256;
    using SafeMath32 for uint32;
    using SafeMath16 for uint16;

    string private _baseTokenURI; 
    address private _AWTokenAddress;
    
    uint16 public constant PREMIUM_ADDON_SUPPLY = 1000;
    uint16 public constant STANDARD_ADDON_SUPPLY = 6000;
    
    uint256 public NFT_ADDON_LIMIT_PER_ADDRESS = 20;
    uint256 public PREMIUM_ADDON_PRICE = 500000000000000000;
    uint256 public STANDARD_ADDON_PRICE = 20000000000000000000;
    uint256 public UPGRADE_PRICE = 10000000000000000000;
    
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_RECEIVER = 0x150b7a02; 
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    address private _owner;
    address private _nftAddress;
    
    FAAD[] public faAddonArray;
    
    event NewFAAD(uint16 _typeId);
    event AddonUpgraded(uint16 addonId, uint32 level); 
    
    struct FAAD {
        uint16 typeId; // 1-6 (standard addons); 7-12 (premium addons);
        uint32 level;  // for standard addons, max 40
    }
    
    struct Stats {
            uint32 life;
            uint32 armour;
            uint32 attack;
            uint32 defence;
            uint32 magic;
            uint32 luck;
        }
    
    uint32[2] public AddonsIndex  = [0, 0]; //Standard and Premium
    uint devFee = 0; 
    
    mapping (uint16 => uint16) public nftToAddonStandard;
    mapping (uint16 => uint16) public addonToNFTStandard;
    
    mapping (uint16 => uint16) public nftToAddonPremium;
    mapping (uint16 => uint16) public addonToNFTPremium;
    
    mapping (uint16 => bool) public bannedAddon;

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
    

    /**
     * @dev safeTransferFrom override.
     *
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
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
    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    /**
     * @dev Only callable once, right after deployment.
     */
    function setNFTContractAddress(address nftAddress) public {
        require(_nftAddress == address(0), "Already set");
        
        _nftAddress = nftAddress;
    }
    
    /**
     * @dev Public NFT Addons creation function. Costs AW (standard addons) or BNB (premium addons)
     *
     */
    function mintFAAddons(uint16 _typeId) public payable {
        uint16 TOTAL_SUPPLY = PREMIUM_ADDON_SUPPLY + STANDARD_ADDON_SUPPLY;
        require(totalSupply() < TOTAL_SUPPLY, "Sale has already ended");
        require(balanceOf(msg.sender) <= NFT_ADDON_LIMIT_PER_ADDRESS, "Maximum 20 NFT Addons per address");
        
        uint16 mintIndex = uint16(totalSupply()); 
        
        if (_typeId>6)
        {
            require(PREMIUM_ADDON_PRICE == msg.value, "BNB Ether value sent is not correct");
            require(AddonsIndex[1] < PREMIUM_ADDON_SUPPLY, "Premium addons sold out");
            AddonsIndex[1] = AddonsIndex[1].add(1);
            
            nftToAddonPremium[15000] = mintIndex;
            addonToNFTPremium[mintIndex] = 15000;
        }
        
        else 
        {
            require(AddonsIndex[0] < STANDARD_ADDON_SUPPLY, "Premium addons sold out");
            AddonsIndex[0] = AddonsIndex[0].add(1);
            nftToAddonStandard[15000] = mintIndex;
            addonToNFTStandard[mintIndex] = 15000;
            
            token.transferFrom(msg.sender, address(this), STANDARD_ADDON_PRICE);
            token.burn(STANDARD_ADDON_PRICE);
        }
        
        _safeMint(msg.sender, mintIndex);
        faAddonArray.push(FAAD(_typeId,1));
        bannedAddon[mintIndex] = false; 
        
        emit NewFAAD(_typeId);
    }
    
    /**
     * @dev Public Assign Addon to a NFT. 
     *
     */
    function assignAddon(uint16 _addonId, uint16 _nftId) public  {
        address owner = ownerOf(_addonId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require(!bannedAddon[_addonId], "This NFT is banned");
        uint16 auxNFT;
        uint16 auxAddon;
        
        if (faAddonArray[_addonId].typeId > 6)
        {
            auxNFT = addonToNFTPremium[_addonId];
            auxAddon = nftToAddonPremium[_nftId];
            
            nftToAddonPremium[auxNFT] = 0;
            addonToNFTPremium[auxAddon] = 0;
            
            nftToAddonPremium[_nftId] = _addonId;
            addonToNFTPremium[_addonId] = _nftId;
        }
        else 
        {    
            auxNFT = addonToNFTStandard[_addonId];
            auxAddon = nftToAddonStandard[_nftId];
            
            nftToAddonStandard[auxNFT] = 0;
            addonToNFTStandard[auxAddon] = 0; 
             
            nftToAddonStandard[_nftId] = _addonId;
            addonToNFTStandard[_addonId] = _nftId;
        }
    }
    
     /**
     * @dev  Upgrades the level of an addon. Costs AW
     */
    function upgradeLevel (uint16 addonId, uint32 level) public {
        address owner = ownerOf(addonId);
        require(_msgSender() == owner, "ERC721: caller is not the owner");
        require (level <= 40);
        require (level > faAddonArray[addonId].level,"Upgrade to a higher level");
        require(!bannedAddon[addonId], "This NFT is banned");
        
        uint32 _costToUpgrade = level.sub(faAddonArray[addonId].level); 
        faAddonArray[addonId].level = level;
        
        token.transferFrom(msg.sender, address(this), UPGRADE_PRICE.mul(_costToUpgrade).div(1000).mul(1000-devFee));
        token.burn(UPGRADE_PRICE.mul(_costToUpgrade).div(1000).mul(1000-devFee));
        token.transferFrom(msg.sender, _owner, UPGRADE_PRICE.mul(_costToUpgrade).div(1000).mul(devFee));
        emit AddonUpgraded(addonId, level); 
    }
    
    /**
     * @dev Outputs the battlePoints of a NFT computed with addons.
     *
     */
    function newBattlePoints(uint16 _fromId, uint16 _toId) external view returns (uint32) {
       
        Stats memory fromStats; 
        Stats memory toStats; 
        
        uint16 fromStandardAddonId = nftToAddonStandard[_fromId];
        uint16 toStandardAddonId = nftToAddonStandard[_toId]; 
        
        uint16 fromPremiumAddonId = nftToAddonPremium[_fromId];
        uint16 toPremiumAddonId = nftToAddonPremium[_toId];
        
        uint32 _fromClass = IFA(_nftAddress).getClass(_fromId);
        uint32 _toClass = IFA(_nftAddress).getClass(_toId);
       
        fromStats.life = IFA(_nftAddress).getLife(_fromId);
        fromStats.armour = IFA(_nftAddress).getArmour(_fromId);
        fromStats.attack = IFA(_nftAddress).getAttack(_fromId);
        fromStats.defence = IFA(_nftAddress).getDefence(_fromId);
        fromStats.magic = IFA(_nftAddress).getMagic(_fromId);
        fromStats.luck = IFA(_nftAddress).getLuck(_fromId);
        
        toStats.life = IFA(_nftAddress).getLife(_toId);
        toStats.attack = IFA(_nftAddress).getAttack(_toId);
        toStats.defence = IFA(_nftAddress).getDefence(_toId);
        toStats.magic = IFA(_nftAddress).getMagic(_toId);
        toStats.luck = IFA(_nftAddress).getLuck(_toId);
        
        if ((faAddonArray.length>0) && (fromStandardAddonId>0))
        {
            if (faAddonArray[fromStandardAddonId].typeId==1)
                fromStats.life += faAddonArray[fromStandardAddonId].level;
            if (faAddonArray[fromStandardAddonId].typeId==2)
                fromStats.armour += faAddonArray[fromStandardAddonId].level;
            if (faAddonArray[fromStandardAddonId].typeId==3)
                fromStats.attack += faAddonArray[fromStandardAddonId].level;
            if (faAddonArray[fromStandardAddonId].typeId==4)
                fromStats.defence += faAddonArray[fromStandardAddonId].level;
            if (faAddonArray[fromStandardAddonId].typeId==5)
                fromStats.magic += faAddonArray[fromStandardAddonId].level;
            if (faAddonArray[fromStandardAddonId].typeId==6)
                fromStats.luck += faAddonArray[fromStandardAddonId].level;
        }
        
        if ((faAddonArray.length>0) && (toStandardAddonId>0))
        {   
            if (faAddonArray[toStandardAddonId].typeId==1)
                toStats.life += faAddonArray[toStandardAddonId].level;
            if (faAddonArray[toStandardAddonId].typeId==2)
                toStats.armour += faAddonArray[toStandardAddonId].level;
            if (faAddonArray[toStandardAddonId].typeId==3)
                toStats.attack += faAddonArray[toStandardAddonId].level;
            if (faAddonArray[toStandardAddonId].typeId==4)
                toStats.defence += faAddonArray[toStandardAddonId].level;
            if (faAddonArray[toStandardAddonId].typeId==5)
                toStats.magic += faAddonArray[toStandardAddonId].level;
            if (faAddonArray[toStandardAddonId].typeId==6)
                toStats.luck += faAddonArray[toStandardAddonId].level;
        }
        
        uint randomLuck = uint256(keccak256(abi.encodePacked(block.timestamp+1 days, msg.sender, _fromId, _toId)));
        uint _luckResult = (randomLuck.mod(fromStats.luck)).mul(10);
        uint _toLuckResult = (randomLuck.mod(toStats.luck)).mul(10);
         
        if ((fromPremiumAddonId>0) || (toPremiumAddonId>0))
        {
            if ((faAddonArray[fromPremiumAddonId].typeId==7) || (faAddonArray[toPremiumAddonId].typeId==7)) // Only Luck
            {
                return uint32(_luckResult);
            }
            else if ((faAddonArray[fromPremiumAddonId].typeId==8) || (faAddonArray[toPremiumAddonId].typeId==8)) //Only Primary
            {
                if (_fromClass == 0) //solid 
                    return fromStats.life.mul(11);
                else if (_fromClass == 1) //regular 
                    return fromStats.armour.mul(11);
                else if (_fromClass == 2) //light 
                    return fromStats.defence.mul(11);
                else if (_fromClass == 3) //thin 
                    return fromStats.attack.mul(11);
                else  //duotone 
                    return fromStats.magic.mul(11);
            }
            else if ((faAddonArray[fromPremiumAddonId].typeId==9) || (faAddonArray[toPremiumAddonId].typeId==9)) //Deny Luck
            {
                if (_fromClass == 0) { //solid
                    fromStats.life = fromStats.life.mul(11);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_fromClass == 1) { //regular 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(11);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_fromClass == 2) { //light 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(11);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_fromClass == 3) { //thin 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(11);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else { //duotone 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(11); 
                }
                
                uint32 statsPoints = fromStats.life + fromStats.armour + fromStats.attack + fromStats.defence + fromStats.magic;
                return statsPoints;
            }
            else if ((faAddonArray[fromPremiumAddonId].typeId==10) || (faAddonArray[toPremiumAddonId].typeId==10)) //Deny Primary bonus
            {
                fromStats.life = fromStats.life.mul(10);
                fromStats.armour = fromStats.armour.mul(10);
                fromStats.attack = fromStats.attack.mul(10);
                fromStats.defence = fromStats.defence.mul(10);
                fromStats.magic = fromStats.magic.mul(10); 
                
                uint32 statsPoints = fromStats.life + fromStats.armour + fromStats.attack + fromStats.defence + fromStats.magic;
                statsPoints += uint32(_luckResult);
                return statsPoints;
            }
            else if ((faAddonArray[fromPremiumAddonId].typeId==11) || (faAddonArray[toPremiumAddonId].typeId==11)) //Switch Luck
            {
                if (_fromClass == 0) { //solid
                    fromStats.life = fromStats.life.mul(11);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_fromClass == 1) { //regular 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(11);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_fromClass == 2) { //light 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(11);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_fromClass == 3) { //thin 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(11);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else { //duotone 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(11); 
                }
                
                uint32 statsPoints = fromStats.life + fromStats.armour + fromStats.attack + fromStats.defence + fromStats.magic;
                statsPoints += uint32(_toLuckResult);
                return statsPoints;
            }
            else if ((faAddonArray[fromPremiumAddonId].typeId==12) || (faAddonArray[toPremiumAddonId].typeId==12)) //Switch Primary
            {
                if (_toClass == 0) { //solid
                    fromStats.life = toStats.life.mul(11);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_toClass == 1) { //regular 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = toStats.armour.mul(11);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_toClass == 2) { //light 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = toStats.defence.mul(11);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_toClass == 3) { //thin 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = toStats.attack.mul(11);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else { //duotone 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = toStats.magic.mul(11); 
                }
                
                uint32 statsPoints = fromStats.life + fromStats.armour + fromStats.attack + fromStats.defence + fromStats.magic;
                statsPoints += uint32(_luckResult);
                return statsPoints;
            }
            else { //normal play with standard addons
                if (_fromClass == 0) { //solid
                    fromStats.life = fromStats.life.mul(11);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_fromClass == 1) { //regular 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(11);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_fromClass == 2) { //light 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(11);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else if (_fromClass == 3) { //thin 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(11);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(10);
                }
                else { //duotone 
                    fromStats.life = fromStats.life.mul(10);
                    fromStats.armour = fromStats.armour.mul(10);
                    fromStats.attack = fromStats.attack.mul(10);
                    fromStats.defence = fromStats.defence.mul(10);
                    fromStats.magic = fromStats.magic.mul(11); 
                }
                
                uint32 statsPoints = fromStats.life + fromStats.armour + fromStats.attack + fromStats.defence + fromStats.magic;
                statsPoints += uint32(_luckResult);
                return statsPoints;
            }
        }
        else { //normal play with standard addons
            if (_fromClass == 0) { //solid
                fromStats.life = fromStats.life.mul(11);
                fromStats.armour = fromStats.armour.mul(10);
                fromStats.attack = fromStats.attack.mul(10);
                fromStats.defence = fromStats.defence.mul(10);
                fromStats.magic = fromStats.magic.mul(10);
            }
            else if (_fromClass == 1) { //regular 
                fromStats.life = fromStats.life.mul(10);
                fromStats.armour = fromStats.armour.mul(11);
                fromStats.attack = fromStats.attack.mul(10);
                fromStats.defence = fromStats.defence.mul(10);
                fromStats.magic = fromStats.magic.mul(10);
            }
            else if (_fromClass == 2) { //light 
                fromStats.life = fromStats.life.mul(10);
                fromStats.armour = fromStats.armour.mul(10);
                fromStats.attack = fromStats.attack.mul(10);
                fromStats.defence = fromStats.defence.mul(11);
                fromStats.magic = fromStats.magic.mul(10);
            }
            else if (_fromClass == 3) { //thin 
                fromStats.life = fromStats.life.mul(10);
                fromStats.armour = fromStats.armour.mul(10);
                fromStats.attack = fromStats.attack.mul(11);
                fromStats.defence = fromStats.defence.mul(10);
                fromStats.magic = fromStats.magic.mul(10);
            }
            else { //duotone 
                fromStats.life = fromStats.life.mul(10);
                fromStats.armour = fromStats.armour.mul(10);
                fromStats.attack = fromStats.attack.mul(10);
                fromStats.defence = fromStats.defence.mul(10);
                fromStats.magic = fromStats.magic.mul(11); 
            }
            
            uint32 statsPoints = fromStats.life + fromStats.armour + fromStats.attack + fromStats.defence + fromStats.magic;
            statsPoints += uint32(_luckResult);
            return statsPoints;
        }
    }
    
    /**
     * @dev Modifies premium addon price (in BNB)
     */
    function modifyPremiumAddonPrice(uint _newprice) public onlyOwner {
        PREMIUM_ADDON_PRICE = _newprice;
    }
    
     /**
     * @dev Modifies standard addon price (in AW)
     */
    function modifyStandardAddonPrice(uint _newprice) public onlyOwner {
        STANDARD_ADDON_PRICE = _newprice;
    }
    
     /**
     * @dev Changes the cost of upgrades.
     */
    function changeUpgradePrice(uint _newPrice) public onlyOwner{
       UPGRADE_PRICE = _newPrice;
    } 
    
     /**
     * @dev Changes the limit of NFT addons per address.
     */
    function changeNFTAddonLimitPerAddress (uint _newLimit) public onlyOwner{
       NFT_ADDON_LIMIT_PER_ADDRESS = _newLimit; 
    }   
    
    /**
     * @dev Changes fee perceived by dev during upgrades.
     */
    function setDevFee(uint _newDevFee) public onlyOwner{
       devFee = _newDevFee;
    } 
    
    /**
     * @dev Bans NFT in case of contract exploit.
     */
    function banAddon(uint16 _AddonId) public onlyOwner{
        bannedAddon[_AddonId] = true;
    }
    
    /**
     * @dev Unbans NFT.
     */
    function unbanAddon(uint16 _AddonId) public onlyOwner{
        bannedAddon[_AddonId] = false;
    }
    
    /**
     * @dev Checks the status of a NFT (banned = true / not banned = false).
     */
    function isBannedAddon(uint16 _AddonId) external view returns (bool) {
       return bannedAddon[_AddonId]; 
    } 
    
}