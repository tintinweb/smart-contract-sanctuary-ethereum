/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// This is a special "passive" migration contract of MTM. 
// Every single method is modified and has custom "passive" migration proxy logic.

abstract contract Ownable {
    address public owner;
    constructor() { owner = msg.sender; }
    modifier onlyOwner { require(owner == msg.sender, "Ownable: NO"); _; }
    function transferOwnership(address newOwner_) public virtual onlyOwner {
        owner = newOwner_; 
    }
}

interface iCM {
    // Views
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId_) external view returns (address);
    function balanceOf(address address_) external view returns (uint256);
    function getApproved(uint256 tokenId_) external view returns (address);
    function isApprovedForAll(address owner_, address operator_) external view returns (bool);
}

// ERC721I Functions, but we modified it for passive migration method
// ERC721IMigrator uses local state storage for gas savings.
// It is like ERC721IStorage and ERC721IOperator combined into one.
contract ERC721IMigrator is Ownable {

    // Interface the MTM Characters Main V1
    iCM public CM;
    function setCM(address address_) external onlyOwner {
        CM = iCM(address_);
    }

    // Name and Symbol Stuff
    string public name; string public symbol;
    constructor(string memory name_, string memory symbol_) {
        name = name_; symbol = symbol_;
    }

    // We turned these to _ prefix so we can use a override function
    // To display custom proxy and passive migration logic
    uint256 public totalSupply;
    mapping(uint256 => address) public _ownerOf;
    mapping(address => uint256) public _balanceOf;

    // Here we have to keep track of a initialized balanceOf to prevent any view issues
    mapping(address => bool) public _balanceOfInitialized;

    
    // We disregard the previous contract's approvals
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    // // TotalSupply Setter
    // Here, we set the totalSupply to equal the previous
    function setTotalSupply(uint256 totalSupply_) external onlyOwner {
        totalSupply = totalSupply_; 
    }

    // // Initializer
    // This is a custom Transfer emitter for the initialize of this contract only
    function initialize(uint256[] calldata tokenIds_, address[] calldata owners_) external onlyOwner {
        require(tokenIds_.length == owners_.length,
            "initialize(): array length mismatch!");
        
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            emit Transfer(address(0x0), owners_[i], tokenIds_[i]);
        }
    }

    // OwnerOf (Proxy View)
    function ownerOf(uint256 tokenId_) public view returns (address) {
        // Find out of the _ownerOf slot has been initialized.
        // We hardcode the tokenId_ to save gas.
        if (tokenId_ <= 3259 && _ownerOf[tokenId_] == address(0x0)) {
            // _ownerOf[tokenId_] is not initialized yet, so return the CM V1 value.
            return CM.ownerOf(tokenId_);
        } else {
            // If it is already initialized, or is higher than migration Id
            // return local state storage instead.
            return _ownerOf[tokenId_];
        }
    }

    // BalanceOf (Proxy View)
    function balanceOf(address address_) public view returns (uint256) {
        // Proxy the balance function
        // We have a tracker of initialization of _balanceOf to track the differences
        // If initialized, we use the state storage. Otherwise, we use CM V1 storage.
        if (_balanceOfInitialized[address_]) {
            return _balanceOf[address_]; 
        } else {
            return CM.balanceOf(address_);
        }
    }

    // Events! L[o_o]⅃ 
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Mint(address indexed to, uint256 tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Functions
    function _mint(address to_, uint256 tokenId_) internal virtual {
        require(to_ != address(0x0), "ERC721IMigrator: _mint() Mint to Zero Address!");
        require(ownerOf(tokenId_) == address(0x0), "ERC721IMigrator: _mint() Token already Exists!");

        // // ERC721I Logic

        // We set _ownerOf in a normal way
        _ownerOf[tokenId_] = to_;

        // We rebalance the _balanceOf on initialization, otherwise follow normal ERC721I logic
        if (_balanceOfInitialized[to_]) {
            // If we are already initialized
            _balanceOf[to_]++;
        } else {
            _balanceOf[to_] = (CM.balanceOf(to_) + 1);
            _balanceOfInitialized[to_] = true;
        }

        // Increment TotalSupply as normal
        totalSupply++;

        // // ERC721I Logic End

        // Emit Events
        emit Transfer(address(0x0), to_, tokenId_);
        emit Mint(to_, tokenId_);
    }

    function _transfer(address from_, address to_, uint256 tokenId_) internal virtual {
        require(from_ == ownerOf(tokenId_), "ERC721IMigrator: _transfer() Transfer from_ != ownerOf(tokenId_)");
        require(to_ != address(0x0), "ERC721IMigrator: _transfer() Transfer to Zero Address!");

        // // ERC721I Transfer Logic

        // If token has an approval
        if (getApproved[tokenId_] != address(0x0)) {
            // Remove the outstanding approval
            getApproved[tokenId_] = address(0x0);
        }

        // Set the _ownerOf to the receiver
        _ownerOf[tokenId_] = to_;

        // // Initialize and Rebalance _balanceOf 
        if (_balanceOfInitialized[from_]) {
            // If from_ is initialized, do normal balance change
            _balanceOf[from_]--;
        } else {
            // If from_ is NOT initialized, follow rebalance flow
            _balanceOf[from_] = (CM.balanceOf(from_) - 1);
            // Set from_ as initialized
            _balanceOfInitialized[from_] = true;
        }

        if (_balanceOfInitialized[to_]) {
            // If to_ is initialized, do normal balance change
            _balanceOf[to_]++;
        } else {
            // If to_ is NOT initialized, follow rebalance flow
            _balanceOf[to_] = (CM.balanceOf(to_) + 1);
            // Set to_ as initialized;
            _balanceOfInitialized[to_] = true;
        }

        // // ERC721I Transfer Logic End

        emit Transfer(from_, to_, tokenId_);
    }

    // Approvals
    function _approve(address to_, uint256 tokenId_) internal virtual {
        if (getApproved[tokenId_] != to_) {
            getApproved[tokenId_] = to_;
            emit Approval(ownerOf(tokenId_), to_, tokenId_);
        }
    }
    function _setApprovalForAll(address owner_, address operator_, bool approved_) internal virtual {
        require(owner_ != operator_, "ERC721IMigrator: _setApprovalForAll() Owner must not be the Operator!");
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    // // Functional Internal Views
    function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view returns (bool) {
        address _owner = ownerOf(tokenId_);
        require(_owner != address(0x0), "ERC721IMigrator: _isApprovedOrOwner() Owner is Zero Address!");
        return (spender_ == _owner // is the owner OR
            || spender_ == getApproved[tokenId_] // is approved for token OR
            || isApprovedForAll[_owner][spender_] // isApprovedForAll spender 
        );
    }

    // Exists
    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        // We hardcode tokenId_ for gas savings
        if (tokenId_ <= 3259) { return true; }
        return _ownerOf[tokenId_] != address(0x0);
    }

    // Public Write Functions 
    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(to_ != _owner, "ERC721IMigrator: approve() cannot approve owner!");
        require(msg.sender == _owner // sender is the owner of the token
            || isApprovedForAll[_owner][msg.sender], // or isApprovedForAll for the owner
            "ERC721IMigrator: approve() Caller is not owner of isApprovedForAll!");
        _approve(to_, tokenId_);
    }
    // SetApprovalForAll - the msg.sender is always the subject of approval
    function setApprovalForAll(address operator_, bool approved_) public virtual {
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    // Transfers
    function transferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        require(_isApprovedOrOwner(msg.sender, tokenId_), 
            "ERC721IMigrator: transferFrom() _isApprovedOrOwner = false!");
        _transfer(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory data_) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.staticcall(abi.encodeWithSelector(0x150b7a02, msg.sender, from_, tokenId_, data_));
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(_selector == 0x150b7a02, "ERC721IMigrator: safeTransferFrom() to_ not ERC721Receivable!");
        }
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    // Native Multi-Transfers by 0xInuarashi
    function multiTransferFrom(address from_, address to_, uint256[] memory tokenIds_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            transferFrom(from_, to_, tokenIds_[i]);
        }
    }
    function multiSafeTransferFrom(address from_, address to_, uint256[] memory tokenIds_, bytes memory data_) public virtual {
        for (uint256 i = 0; i < tokenIds_.length; i++ ){
            safeTransferFrom(from_, to_, tokenIds_[i], data_);
        }
    }

    // OZ Standard Stuff
    function supportsInterface(bytes4 interfaceId_) public pure returns (bool) {
        return (interfaceId_ == 0x80ac58cd || interfaceId_ == 0x5b5e139f);
    }

    // High Gas Loop View Functions
    function walletOfOwner(address address_) public virtual view returns (uint256[] memory) {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _index;
        uint256 _loopThrough = totalSupply;
        for (uint256 i = 0; i < _loopThrough; i++) {
            // Add another loop through for each 0x0 until array is filled
            if (ownerOf(i) == address(0x0) && _tokens[_balance - 1] == 0) {
                _loopThrough++;
            }
            // Fill the array on each token found
            if (ownerOf(i) == address_) {
                // Record the ID in the index 
                _tokens[_index] = i;
                // Increment the index
                _index++;
            }
        }
        return _tokens;
    }

    // TokenURIs Functions Omitted //

}

interface IERC721 {
    function ownerOf(uint256 tokenId_) external view returns (address);
    function transferFrom(address from_, address to_, uint256 tokenId_) external;
}

interface iCS {
    struct Character {
        uint8  race_;
        uint8  renderType_;
        uint16 transponderId_;
        uint16 spaceCapsuleId_;
        uint8  augments_;
        uint16 basePoints_;
        uint16 totalEquipmentBonus_;
    }
    struct Stats {
        uint8 strength_; 
        uint8 agility_; 
        uint8 constitution_; 
        uint8 intelligence_; 
        uint8 spirit_; 
    }
    struct Equipment {
        uint8 weaponUpgrades_;
        uint8 chestUpgrades_;
        uint8 headUpgrades_;
        uint8 legsUpgrades_;
        uint8 vehicleUpgrades_;
        uint8 armsUpgrades_;
        uint8 artifactUpgrades_;
        uint8 ringUpgrades_;
    }

    // Create Character
    function createCharacter(uint tokenId_, Character memory Character_) external;
    // Characters
    function setName(uint256 tokenId_, string memory name_) external;
    function setRace(uint256 tokenId_, string memory race_) external;
    function setRenderType(uint256 tokenId_, uint8 renderType_) external;
    function setTransponderId(uint256 tokenId_, uint16 transponderId_) external;
    function setSpaceCapsuleId(uint256 tokenId_, uint16 spaceCapsuleId_) external;
    function setAugments(uint256 tokenId_, uint8 augments_) external;
    function setBasePoints(uint256 tokenId_, uint16 basePoints_) external;
    function setBaseEquipmentBonus(uint256 tokenId_, uint16 baseEquipmentBonus_) external;
    function setTotalEquipmentBonus(uint256 tokenId_, uint16 totalEquipmentBonus) external;
    // Stats
    function setStrength(uint256 tokenId_, uint8 strength_) external;
    function setAgility(uint256 tokenId_, uint8 agility_) external;
    function setConstitution(uint256 tokenId_, uint8 constitution_) external;
    function setIntelligence(uint256 tokenId_, uint8 intelligence_) external;
    function setSpirit(uint256 tokenId_, uint8 spirit_) external;
    // Equipment
    function setWeaponUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setChestUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setHeadUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setLegsUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setVehicleUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setArmsUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setArtifactUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    function setRingUpgrades(uint256 tokenId_, uint8 upgrade_) external;
    // Structs and Mappings
    function names(uint256 tokenId_) external view returns (string memory);
    function characters(uint256 tokenId_) external view returns (Character memory);
    function stats(uint256 tokenId_) external view returns (Stats memory);
    function equipments(uint256 tokenId_) external view returns (Equipment memory);
    function contractToRace(address contractAddress_) external view returns (uint8);
}

interface iCC {
    function queryCharacterYieldRate(uint8 augments_, uint16 basePoints_, uint16 totalEquipmentBonus_) external view returns (uint256);
    function getEquipmentBaseBonus(uint16 spaceCapsuleId_) external view returns (uint16); 
}

interface iMES {
    // View Functions
    function balanceOf(address address_) external view returns (uint256);
    function pendingRewards(address address_) external view returns (uint256); 
    // Administration
    function setYieldRate(address address_, uint256 yieldRate_) external;
    function addYieldRate(address address_, uint256 yieldRateAdd_) external;
    function subYieldRate(address address_, uint256 yieldRateSub_) external;
    // Credits System
    function deductCredits(address address_, uint256 amount_) external;
    function addCredits(address address_, uint256 amount_) external;
    // Claiming
    function updateReward(address address_) external;
    function burn(address from, uint256 amount_) external;
}

interface iMetadata {
    function renderMetadata(uint256 tokenId_) external view returns (string memory);
}

contract MTMCharacters is ERC721IMigrator {
    constructor() ERC721IMigrator("MTM Characters", "CHARACTERS") {}

    // Interfaces
    iCS public CS; iCC public CC; iMES public MES; iMetadata public Metadata;
    IERC721 public TP; IERC721 public SC;
    function setContracts(address metadata_, address cc_, address cs_, address mes_, address tp_, address sc_) external onlyOwner {
        CS = iCS(cs_); CC = iCC(cc_); MES = iMES(mes_); Metadata = iMetadata(metadata_);
        TP = IERC721(tp_); SC = IERC721(sc_);
    }

    // Mappings
    mapping(address => mapping(uint256 => bool)) public contractAddressToTokenUploaded;

    // Internal Write Functions
    function __yieldMintHook(address to_, uint256 tokenId_) internal {
        // First, we update the reward. 
        MES.updateReward(to_);

        // Then, we query the token yield rate.
        iCS.Character memory _Character = CS.characters(tokenId_);
        uint256 _tokenYieldRate = CC.queryCharacterYieldRate(_Character.augments_, _Character.basePoints_, _Character.totalEquipmentBonus_);

        // Lastly, we adjust the yield rate of the address.
        MES.addYieldRate(to_, _tokenYieldRate);
    }
    function __yieldTransferHook(address from_, address to_, uint256 tokenId_) internal {
        // First, we update the reward. 
        MES.updateReward(from_); MES.updateReward(to_);

        // Then, we query the token yield rate.
        iCS.Character memory _Character = CS.characters(tokenId_);
        uint256 _tokenYieldRate = CC.queryCharacterYieldRate(_Character.augments_, _Character.basePoints_, _Character.totalEquipmentBonus_);

        // Lastly, we adjust the yield rate of the addresses.
        MES.subYieldRate(from_, _tokenYieldRate); MES.addYieldRate(to_, _tokenYieldRate);
    }

    // Public Write Functions
    mapping(uint8 => bool) public renderTypeAllowed;
    function setRenderTypeAllowed(uint8 renderType_, bool bool_) external onlyOwner {
        renderTypeAllowed[renderType_] = bool_;
    }

    function beamCharacter(uint256 transponderId_, uint256 spaceCapsuleId_, uint8 renderType_) public {
        require(msg.sender == TP.ownerOf(transponderId_) && msg.sender == SC.ownerOf(spaceCapsuleId_), "Unowned pair!");
        require(renderTypeAllowed[renderType_], "This render type is not allowed!");

        // Burn the Transponder and Space Capsule.
        TP.transferFrom(msg.sender, address(this), transponderId_);
        SC.transferFrom(msg.sender, address(this), spaceCapsuleId_);

        uint8 _race = uint8( (uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty, transponderId_, spaceCapsuleId_))) % 10) + 1 ); // RNG (1-10) 
        uint16 _equipmentBonus = CC.getEquipmentBaseBonus((uint16(spaceCapsuleId_)));

        iCS.Character memory _Character = iCS.Character(
            _race,
            renderType_,
            uint16(transponderId_),
            uint16(spaceCapsuleId_),
            0,
            0,
            _equipmentBonus
        );

        CS.createCharacter(totalSupply, _Character);
        
        __yieldMintHook(msg.sender, totalSupply);
        _mint(msg.sender, totalSupply);
    }
    function uploadCharacter(uint256 transponderId_, uint256 spaceCapsuleId_, uint8 renderType_, address contractAddress_, uint256 uploadId_) public {
        require(msg.sender == TP.ownerOf(transponderId_) && msg.sender == SC.ownerOf(spaceCapsuleId_), "Unowned pair!");
        require(msg.sender == IERC721(contractAddress_).ownerOf(uploadId_), "You don't own this character!");
        require(!contractAddressToTokenUploaded[contractAddress_][uploadId_], "This character has already been uploaded!");
        require(renderTypeAllowed[renderType_], "This render type is not allowed!");

        // Burn the Transponder and Space Capsule. Then, set the character as uploaded.
        TP.transferFrom(msg.sender, address(this), transponderId_);
        SC.transferFrom(msg.sender, address(this), spaceCapsuleId_);
        contractAddressToTokenUploaded[contractAddress_][uploadId_] = true;

        uint8 _race = CS.contractToRace(contractAddress_);
        uint16 _equipmentBonus = CC.getEquipmentBaseBonus((uint16(spaceCapsuleId_)));
        
        iCS.Character memory _Character = iCS.Character(
            _race,
            renderType_,
            uint16(transponderId_),
            uint16(spaceCapsuleId_),
            0,
            0,
            _equipmentBonus
        );

        CS.createCharacter(totalSupply, _Character); 

        __yieldMintHook(msg.sender, totalSupply);
        _mint(msg.sender, totalSupply); 
    }

    // Public Write Multi-Functions
    function multiBeamCharacter(uint256[] memory transponderIds_, uint256[] memory spaceCapsuleIds_, uint8[] memory renderTypes_) public {
        require(transponderIds_.length == spaceCapsuleIds_.length, "Missing pairs!");
        require(transponderIds_.length == renderTypes_.length, "Missing render type!");
        for (uint256 i = 0; i < transponderIds_.length; i++) {
            beamCharacter(transponderIds_[i], spaceCapsuleIds_[i], renderTypes_[i]);
        }
    }
    function multiUploadCharacter(uint256[] memory transponderIds_, uint256[] memory spaceCapsuleIds_, uint8[] memory renderTypes_, address contractAddress_, uint256[] memory uploadIds_) public {
        require(transponderIds_.length == spaceCapsuleIds_.length, "Missing pairs!");
        require(transponderIds_.length == renderTypes_.length, "Missing render type!");
        require(transponderIds_.length == uploadIds_.length, "Upload IDs mismatched length!");
        for (uint256 i = 0; i < transponderIds_.length; i++) {
            uploadCharacter(transponderIds_[i], spaceCapsuleIds_[i], renderTypes_[i], contractAddress_, uploadIds_[i]);
        }
    }

    // Transfer Hooks
    function transferFrom(address from_, address to_, uint256 tokenId_) public override {
        __yieldTransferHook(from_, to_, tokenId_);
        ERC721IMigrator.transferFrom(from_, to_, tokenId_);
    }
    function safeTransferFrom(address from_, address to_, uint256 tokenId_, bytes memory bytes_) public override {
        __yieldTransferHook(from_, to_, tokenId_);
        ERC721IMigrator.safeTransferFrom(from_, to_, tokenId_, bytes_);
    }

    // Public View Functions
    function tokenURI(uint256 tokenId_) public view returns (string memory) {
        require(_exists(tokenId_), "Character does not exist!");
        return Metadata.renderMetadata(tokenId_);
    }
}