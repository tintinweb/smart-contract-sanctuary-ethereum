// SPDX-License-Identifier: MIT

// ██████╗  █████╗ ██╗    ██╗██████╗  ██████╗ ████████╗███████╗
// ██╔══██╗██╔══██╗██║    ██║██╔══██╗██╔═████╗╚══██╔══╝██╔════╝
// ██████╔╝███████║██║ █╗ ██║██████╔╝██║██╔██║   ██║   ███████╗
// ██╔══██╗██╔══██║██║███╗██║██╔══██╗████╔╝██║   ██║   ╚════██║
// ██║  ██║██║  ██║╚███╔███╔╝██████╔╝╚██████╔╝   ██║   ███████║
// ╚═╝  ╚═╝╚═╝  ╚═╝ ╚══╝╚══╝ ╚═════╝  ╚═════╝    ╚═╝   ╚══════╝
// A 0xWARLABS Project

pragma solidity ^0.8.0;

import "./interfaces/IPlaToken.sol";
import "./GenCounter.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Rawb0ts is ERC721Enumerable, Ownable, GenCounter {
    using SafeMath for uint256;

    struct MissionData {
        uint256 missionStart;
        uint256 recoveryStart;
        uint256[] components;
    }

    IPlaToken public PlaToken;

    uint256 private constant MAX_PRESALE_MINT = 1;
    uint256 private constant MAX_SALE_MINT = 2;    
    uint256 private constant MAX_TOT_PRESALE_MINT = 666;
    uint256 private constant MAX_MISSION_COMPONENTS = 3;
    uint256 private constant MISSION_TIME  = 43200;
    uint256 private constant RECOVERY_TIME = 43200;

    string private baseURI;

    bool public airdropActive;
    bool public presaleActive;
    bool public saleActive;
    bool public breedActive;
    bool public missionActive;
    bool public claimMissionActive;
    bool public inkExternalActive;

    uint256 public presalePrice = 0.000045 ether; //0.045 ether;
    uint256 public salePrice = 0.00009 ether; //0.09 ether
    uint256 public missionPrice; //? ether

    uint256 public breedPlaPrice = 666 ether;
    uint256 public inkTime = 86400;

    mapping(uint256 => MissionData) public missionData;

    mapping (uint256 => uint256) public inkLastUpdate;
    mapping(address => bool) public inkAllowedAddresses;

    mapping (address => uint256) public presaleWhitelist;

    mapping (uint256 => uint256) public tokensMinted;

    address private safeDevAddress;

    event breeding(uint256 parent1, uint256 parent2, uint256 child);
    event missionStarted(bool);
    event missionEnded(bool);

    modifier airdropIsActive() {
        require(airdropActive, "Airdrop is not active");
        _;
    }

    modifier presaleIsActive() {
        require(presaleActive, "Presale is not active");
        _;
    }

    modifier saleIsActive() {
        require(saleActive, "Sale is not active");
        _;
    }

    modifier breedIsActive() {
        require(breedActive, "Breed is not active");
        _;
    }
    
    modifier missionIsActive() {
        require(missionActive, "Mission is not active");
        _;
    }

    modifier inkExternalIsActive() {
        require(inkExternalActive, "Ink external interaction is not active");
        _;
    }

    modifier rawb0tOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Invalid owner");
        _;
    }

    constructor(string memory name, string memory symbol) ERC721(name, symbol) GenCounter() { }

    function airdrop(address[] calldata _airdropAddresses, uint256[] calldata _airdropTokens) external onlyOwner airdropIsActive {
        for (uint256 i; i < _airdropAddresses.length ; i++) {
            uint256 tokenId = _airdropTokens[i];
            bytes2 gen = getCounterGen(tokenId);
            require(tokenCount(gen).add(1) <= getMaxSupply(gen), "Max supply of Rawb0ts exceeded");
            require(getMatrixValue(gen, tokenId) == 0, "Token id already minted");
            setDefinedMatrixValue(gen, tokenId);
            _safeMint(_airdropAddresses[i], tokenId);
            tokensMinted[totalSupply()] = tokenId; 
            PlaToken.updateRewardAfterMint(msg.sender);
            inkLastUpdate[tokenId] = block.timestamp;
        }
    }

    function mintPresale(uint256 _rawb0tsToMint) external payable presaleIsActive { //returns (uint256[] memory) {
        require(msg.sender == tx.origin, "Cannot mint from a contract");
        uint256 amount = presaleWhitelist[msg.sender];
        require(amount > 0, "No tokens available for this address");
        require(_rawb0tsToMint > 0 && _rawb0tsToMint <= amount && _rawb0tsToMint <= MAX_PRESALE_MINT, "Invalid purchase amount");
        require(tokenCount(GEN0).add(_rawb0tsToMint) <= MAX_TOT_PRESALE_MINT, "Presale Sold-out");
        require(tokenCount(GEN0).add(_rawb0tsToMint) <= getMaxSupply(GEN0), "Max supply of Rawb0ts exceeded");
        require(presalePrice.mul(_rawb0tsToMint) == msg.value, "Invalid purchase price");
        presaleWhitelist[msg.sender] = amount - _rawb0tsToMint;
        //uint256[] memory rawb0tsMinted = new uint256[](_rawb0tsToMint);
        for(uint256 i; i < _rawb0tsToMint; i++){
            //rawb0tsMinted[mint(GEN0)];
            mint(GEN0);
        }
        //return rawb0tsMinted;
    }

    function mintSale(uint256 _rawb0tsToMint) external payable saleIsActive { //returns (uint256[] memory) {
        require(msg.sender == tx.origin, "Cannot mint from a contract");
        require(_rawb0tsToMint > 0 && _rawb0tsToMint <= MAX_SALE_MINT, "Invalid purchase amount");
        require(tokenCount(GEN0).add(_rawb0tsToMint) <= getMaxSupply(GEN0), "Max supply of Rawb0ts exceeded");
        require(salePrice.mul(_rawb0tsToMint) == msg.value, "Invalid purchase price");
        //uint256[] memory rawb0tsMinted = new uint256[](_rawb0tsToMint);
        for(uint256 i; i < _rawb0tsToMint; i++) {
            //rawb0tsMinted[mint(GEN0)];
            mint(GEN0);
        }
        //return rawb0tsMinted;
    }

    function mint(bytes2 _gen) private returns (uint256) {      
        uint256 tokenId = nextToken(_gen);
        _safeMint(msg.sender, tokenId);
        tokensMinted[totalSupply()] = tokenId; 
        PlaToken.updateRewardAfterMint(msg.sender);
        inkLastUpdate[tokenId] = block.timestamp;
        return tokenId;      
    }

    function breed(uint256 _parent1, uint256 _parent2) external breedIsActive rawb0tOwner(_parent1) rawb0tOwner(_parent2) {        
        require(missionData[_parent1].missionStart == 0, "Rawbot on a mission");
        require(block.timestamp - missionData[_parent1].recoveryStart >= RECOVERY_TIME, "Waiting for recovery");
        require(missionData[_parent2].missionStart == 0, "Rawbot on a mission");
        require(block.timestamp - missionData[_parent2].recoveryStart >= RECOVERY_TIME, "Waiting for recovery");
        require(getGen(_parent1) == getGen(_parent2), "Parents Gen must be equal");
        require(getPendingInk(_parent1) == 100 && getPendingInk(_parent2) == 100 , "Ink missing");
        bytes2 genParent1 = getParentGen(_parent1);
        bytes2 genParent2 = getParentGen(_parent2);
        require(genParent1 != genParent2, "Parents colors must differ");
        bytes2 genChild = getChildGen(genParent1, genParent2);
        require(tokenCount(genChild).add(1) <= getMaxSupply(genChild), "No more children available");

        PlaToken.burn(msg.sender, breedPlaPrice);

        uint256 childId = mint(genChild);
        inkLastUpdate[_parent1] = block.timestamp; 
        inkLastUpdate[_parent2] = block.timestamp; 

        emit breeding(_parent1, _parent2, childId);
    }

    function startMission(uint256[] calldata _rawb0tsId) external missionIsActive {
         require(_rawb0tsId.length > 0 && _rawb0tsId.length <= MAX_MISSION_COMPONENTS, "Wrong number of mission components");
         for (uint256 i; i < _rawb0tsId.length; i++) {
             require(ownerOf(_rawb0tsId[i]) == msg.sender, "Not the owner of the mission component");
             require(missionData[_rawb0tsId[i]].missionStart == 0, "Mission already started");
             require(block.timestamp - missionData[_rawb0tsId[i]].recoveryStart >= RECOVERY_TIME, "Waiting for recovery");
             missionData[_rawb0tsId[i]].missionStart = block.timestamp;
             missionData[_rawb0tsId[i]].recoveryStart = 0;
             missionData[_rawb0tsId[i]].components = _rawb0tsId;
         }

         emit missionStarted(true);
     }

     function endMission(uint256[] calldata _rawb0tsId) external payable missionIsActive {
         require(_rawb0tsId.length > 0 && _rawb0tsId.length <= MAX_MISSION_COMPONENTS, "Wrong number of components");
         for (uint256 i; i < _rawb0tsId.length; i++) {
             require(ownerOf(_rawb0tsId[i]) == msg.sender, "Not the owner of the mission component");
             require(missionData[_rawb0tsId[i]].missionStart > 0, "Mission never started");
             require(block.timestamp - missionData[_rawb0tsId[i]].missionStart >= MISSION_TIME, "Mission not ended yet");
             require(missionData[_rawb0tsId[i]].components.length == _rawb0tsId.length 
                && missionData[_rawb0tsId[i]].components[i] == _rawb0tsId[i], "Wrong mission components");
             missionData[_rawb0tsId[i]].missionStart = 0;
             missionData[_rawb0tsId[i]].recoveryStart = block.timestamp;
             missionData[_rawb0tsId[i]].components[i] = 0;
         }
         if (claimMissionActive) {
            require(missionPrice == msg.value, "Invalid mission price");
            PlaToken.claimMissionPla(msg.sender, _rawb0tsId.length);
         }

         emit missionEnded(true);
     }

    function getPendingInk(uint256 _id) public view rawb0tOwner(_id) returns (uint256) {
        uint256 inkPercentage = (block.timestamp - inkLastUpdate[_id]) * 100 / inkTime;
        inkPercentage = inkPercentage > 100 ? 100 : inkPercentage;
        return inkPercentage;
    }  

    function emptyInk(uint256 _tokenId) external inkExternalIsActive {
        require(inkAllowedAddresses[msg.sender], "Address does not have permission to interact with Ink");
        inkLastUpdate[_tokenId] = block.timestamp; 
    }

    function setInkAllowedAddresses(address _address, bool _access) external onlyOwner {
        inkAllowedAddresses[_address] = _access;
    }

    function getGen(uint256 _tokenId) internal pure returns (bytes2) {
        require(_tokenId >= START_GEN0_ID && _tokenId <= MAX_GEN2_ID, "Invalid Gen");
        bytes2 gen;
        if (_tokenId >= START_GEN0_ID && _tokenId <= MAX_GEN0_ID) {
            gen = GEN0;
        } else if (_tokenId >= START_GEN1_ID && _tokenId <= MAX_GEN1_ID) {
            gen = GEN1;
        } else if (_tokenId >= START_GEN2_ID && _tokenId <= MAX_GEN2_ID) {
            gen = GEN2;
        }
        return gen;
    }      

    function getParentGen(uint256 _tokenId) private pure returns (bytes2) {
        require(_tokenId >= START_GEN0_ID && _tokenId <= MAX_GEN1_ID, "Invalid Gen for breeding");
        bytes2 gen;
        if (_tokenId >= START_GEN01_ID && _tokenId <= MAX_GEN01_ID) {
            gen = GEN01;
        } else if (_tokenId >= START_GEN02_ID && _tokenId <= MAX_GEN02_ID) {
            gen = GEN02;
        } else if (_tokenId >= START_GEN03_ID && _tokenId <= MAX_GEN03_ID) {
            gen = GEN03;
        } else if (_tokenId >= START_GEN11_ID && _tokenId <= MAX_GEN11_ID) {
            gen = GEN11;
        } else if (_tokenId >= START_GEN12_ID && _tokenId <= MAX_GEN12_ID) {
            gen = GEN12;
        } else if (_tokenId >= START_GEN13_ID && _tokenId <= MAX_GEN13_ID) {
            gen = GEN13;
        }
        return gen;
    }   

    function getChildGen(bytes2 _genParent1, bytes2 _genParent2) private pure returns (bytes2) {
        bytes2 gen;
        if (_genParent1 == GEN01 && _genParent2 == GEN02
            || _genParent1 == GEN02 && _genParent2 == GEN01) {
            gen = GEN11;
        } else if (_genParent1 == GEN01 && _genParent2 == GEN03
            || _genParent1 == GEN03 && _genParent2 == GEN01) {
            gen = GEN12;
        } else if (_genParent1 == GEN02 && _genParent2 == GEN03
            || _genParent1 == GEN03 && _genParent2 == GEN02) {
            gen = GEN13;
        } else if (_genParent1 == GEN11 && _genParent2 == GEN12
            || _genParent1 == GEN12 && _genParent2 == GEN11) {
            gen = GEN21;
        } else if (_genParent1 == GEN11 && _genParent2 == GEN13
            || _genParent1 == GEN13 && _genParent2 == GEN11) {
            gen = GEN22;
        } else if (_genParent1 == GEN12 && _genParent2 == GEN13
            || _genParent1 == GEN13 && _genParent2 == GEN12) {
            gen = GEN23;
        } 
        return gen;
    }

    function getCounterGen(uint256 _tokenId) private pure returns (bytes2) {
        bytes2 gen;
        if (_tokenId >= START_GEN0_ID && _tokenId <= MAX_GEN0_ID) {
            gen = GEN0;
        } else if (_tokenId >= START_GEN11_ID && _tokenId <= MAX_GEN11_ID) {
            gen = GEN11;
        } else if (_tokenId >= START_GEN12_ID && _tokenId <= MAX_GEN12_ID) {
            gen = GEN12;
        } else if (_tokenId >= START_GEN13_ID && _tokenId <= MAX_GEN13_ID) {
            gen = GEN13;
        } else if (_tokenId >= START_GEN21_ID && _tokenId <= MAX_GEN21_ID) {
            gen = GEN21;
        } else if (_tokenId >= START_GEN22_ID && _tokenId <= MAX_GEN22_ID) {
            gen = GEN22;
        } else if (_tokenId >= START_GEN23_ID && _tokenId <= MAX_GEN23_ID) {
            gen = GEN23;
        }
        return gen;
    }  

    function getRawb0tsOwned(address _owner) public view returns(uint256[] memory) {
        uint256 rawb0tsBalance = balanceOf(_owner);
        uint256[] memory rawb0tsOwned = new uint256[](rawb0tsBalance);
        for(uint256 i; i < rawb0tsBalance; i++){
            rawb0tsOwned[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return rawb0tsOwned;
    }

    function toggleAirdropActive() external onlyOwner {
        airdropActive = !airdropActive;
    }

    function togglePresaleActive() external onlyOwner {
        presaleActive = !presaleActive;
    }

    function toggleSaleActive() external onlyOwner {
        saleActive = !saleActive;
    }
    
    function toggleBreedActive() external onlyOwner {
        breedActive = !breedActive;
    }

    function toggleMissionActive() external onlyOwner {
        missionActive = !missionActive;
    }

    function toggleClaimMission() external onlyOwner {
        claimMissionActive = !claimMissionActive;
    }

    function toggleInkExternalActive() external onlyOwner {
        inkExternalActive = !inkExternalActive;
    }

    function changePresalePrice(uint256 _price) public onlyOwner {
        presalePrice = _price;
    }

    function changeSalePrice(uint256 _price) public onlyOwner {
        salePrice = _price;
    }

    function changeMissionPrice(uint256 _price) public onlyOwner {
        missionPrice = _price;
    }

    function changeInkTime(uint256 _inkTime) public onlyOwner {
        inkTime = _inkTime;
    }

    function setPresaleWhitelist(address[] calldata _presaleAddresses, uint256[] calldata _amount) external onlyOwner {
        for(uint256 i; i < _presaleAddresses.length; i++){
            presaleWhitelist[_presaleAddresses[i]] = _amount[i];
        }
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setPlaToken(address _plaTokenAddress) external onlyOwner {
        PlaToken = IPlaToken(_plaTokenAddress);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        PlaToken.updateReward(_from, _to);
        inkLastUpdate[_tokenId] = block.timestamp;
        delete missionData[_tokenId];
        missionData[_tokenId].recoveryStart = block.timestamp;
        ERC721.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
        PlaToken.updateReward(_from, _to);
        inkLastUpdate[_tokenId] = block.timestamp;
        delete missionData[_tokenId];
        missionData[_tokenId].recoveryStart = block.timestamp;
        ERC721.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function changeSafeDevAddress(address _newAddress) public onlyOwner {
        safeDevAddress = _newAddress;
    }

    function withdraw() public onlyOwner {
        require(safeDevAddress != address(0));
        uint256 balance = address(this).balance;
        payable(safeDevAddress).transfer(balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPlaToken {
    function burn(address _from, uint256 _amount) external;

    function updateReward(address _from, address _to) external;

    function updateRewardAfterMint(address _owner) external;

    function claimMissionPla(address _sender, uint256 _reward) external;
}

// SPDX-License-Identifier: MIT
// Inspired by https://github.com/1001-digital/erc721-extensions/blob/main/LICENSE
pragma solidity ^0.8.0;

import "./GenSupply.sol";

abstract contract GenCounter is GenSupply {
    // Used for random index assignment
    mapping(uint256 => uint256) private gen0TokenMatrix;
    mapping(uint256 => uint256) private gen11TokenMatrix;
    mapping(uint256 => uint256) private gen12TokenMatrix;
    mapping(uint256 => uint256) private gen13TokenMatrix;
    mapping(uint256 => uint256) private gen21TokenMatrix;
    mapping(uint256 => uint256) private gen22TokenMatrix;
    mapping(uint256 => uint256) private gen23TokenMatrix;

    /// Instanciate the contract
    constructor() GenSupply() {}

    /// Get the next token ID
    /// @dev Randomly gets a new token ID and keeps track of the ones that are still available.
    /// @return the next token ID
    function nextToken(bytes2 _gen)
        internal
        override
        ensureAvailability(_gen)
        returns (uint256)
    {
        uint256 maxIndex = getMaxSupply(_gen) - tokenCount(_gen);
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    block.coinbase,
                    block.difficulty,
                    block.gaslimit,
                    block.timestamp
                )
            )
        ) % maxIndex;

        uint256 value = 0;
        uint256 startFrom = getStartFrom(_gen);
        uint256 matrixValue = getMatrixValue(_gen, random);

        if (matrixValue == 0) {
            // If this matrix position is empty, set the value to the generated random number.
            value = random;
        } else {
            // Otherwise, use the previously stored number from the matrix.
            value = matrixValue;
        }

        matrixValue = getMatrixValue(_gen, maxIndex - 1);
        // If the last available tokenID is still unused...
        if (matrixValue == 0) {
            // ...store that ID in the current matrix position.
            setMatrixValue(_gen, random, maxIndex - 1);
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            setMatrixValue(_gen, random, matrixValue);
        }

        // Increment counts
        super.nextToken(_gen);

        return value + startFrom;
    }

    function getStartFrom(bytes2 _gen) private pure returns (uint256) {
        uint256 startFrom = 0;
        if (_gen == GEN0) {
            startFrom = START_GEN0_ID;
        } else if (_gen == GEN11) {
            startFrom = START_GEN11_ID;
        } else if (_gen == GEN12) {
            startFrom = START_GEN12_ID;
        } else if (_gen == GEN13) {
            startFrom = START_GEN13_ID;
        } else if (_gen == GEN21) {
            startFrom = START_GEN21_ID;
        } else if (_gen == GEN22) {
            startFrom = START_GEN22_ID;
        } else if (_gen == GEN23) {
            startFrom = START_GEN23_ID;
        }
        return startFrom;
    }

    function getMatrixValue(bytes2 _gen, uint256 _index)
        internal
        view
        returns (uint256)
    {
        if (_gen == GEN0) {
            return gen0TokenMatrix[_index];
        } else if (_gen == GEN11) {
            return gen11TokenMatrix[_index];
        } else if (_gen == GEN12) {
            return gen12TokenMatrix[_index];
        } else if (_gen == GEN13) {
            return gen13TokenMatrix[_index];
        } else if (_gen == GEN21) {
            return gen21TokenMatrix[_index];
        } else if (_gen == GEN22) {
            return gen22TokenMatrix[_index];
        } else if (_gen == GEN23) {
            return gen23TokenMatrix[_index];
        } else {
            return 0;
        }
    }

    function setMatrixValue(
        bytes2 _gen,
        uint256 _index,
        uint256 _value
    ) private {
        if (_gen == GEN0) {
            gen0TokenMatrix[_index] = _value;
        } else if (_gen == GEN11) {
            gen11TokenMatrix[_index] = _value;
        } else if (_gen == GEN12) {
            gen12TokenMatrix[_index] = _value;
        } else if (_gen == GEN13) {
            gen13TokenMatrix[_index] = _value;
        } else if (_gen == GEN21) {
            gen21TokenMatrix[_index] = _value;
        } else if (_gen == GEN22) {
            gen22TokenMatrix[_index] = _value;
        } else if (_gen == GEN23) {
            gen23TokenMatrix[_index] = _value;
        }
    }

    function setDefinedMatrixValue(bytes2 _gen, uint256 _value) internal {
        uint256 maxIndex = getMaxSupply(_gen) - tokenCount(_gen);
        uint256 matrixValue = getMatrixValue(_gen, maxIndex - 1);
        // If the last available tokenID is still unused...
        if (matrixValue == 0) {
            // ...store that ID in the current matrix position.
            setMatrixValue(_gen, _value, maxIndex - 1);
        } else {
            // ...otherwise copy over the stored number to the current matrix position.
            setMatrixValue(_gen, _value, matrixValue);
        }
        // Increment counts
        super.nextToken(_gen);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

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
     * by default, can be overriden in child contracts.
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
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

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
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
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

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// Inspired by https://github.com/1001-digital/erc721-extensions/blob/main/LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

abstract contract GenSupply {
    using Counters for Counters.Counter;

    bytes2 internal constant GEN0  = "0";
    bytes2 internal constant GEN01 = "01";
    bytes2 internal constant GEN02 = "02";
    bytes2 internal constant GEN03 = "03";
    bytes2 internal constant GEN1  = "1";
    bytes2 internal constant GEN11 = "11";
    bytes2 internal constant GEN12 = "12";
    bytes2 internal constant GEN13 = "13";
    bytes2 internal constant GEN2  = "2";
    bytes2 internal constant GEN21 = "21";
    bytes2 internal constant GEN22 = "22";
    bytes2 internal constant GEN23 = "23";

    uint256 internal constant START_GEN0_ID  = 1;
    uint256 internal constant MAX_GEN0_ID    = 6666;
    uint256 internal constant START_GEN01_ID = 1;
    uint256 internal constant MAX_GEN01_ID   = 2222;
    uint256 internal constant START_GEN02_ID = 2223;
    uint256 internal constant MAX_GEN02_ID   = 4444;
    uint256 internal constant START_GEN03_ID = 4445;
    uint256 internal constant MAX_GEN03_ID   = 6666;

    uint256 internal constant START_GEN1_ID  = 6667;
    uint256 internal constant MAX_GEN1_ID    = 13332;
    uint256 internal constant START_GEN11_ID = 6667;
    uint256 internal constant MAX_GEN11_ID   = 8888;
    uint256 internal constant START_GEN12_ID = 8889;
    uint256 internal constant MAX_GEN12_ID   = 11110;
    uint256 internal constant START_GEN13_ID = 11111;
    uint256 internal constant MAX_GEN13_ID   = 13332;

    uint256 internal constant START_GEN2_ID  = 13333;
    uint256 internal constant MAX_GEN2_ID    = 19998;
    uint256 internal constant START_GEN21_ID = 13333;
    uint256 internal constant MAX_GEN21_ID   = 15554;
    uint256 internal constant START_GEN22_ID = 15555;
    uint256 internal constant MAX_GEN22_ID   = 17776;
    uint256 internal constant START_GEN23_ID = 17777;
    uint256 internal constant MAX_GEN23_ID   = 19998;

    uint256 private constant SUP_GEN0_ID  = 6666;
    uint256 private constant SUP_GEN11_ID = 2222;
    uint256 private constant SUP_GEN12_ID = 2222;
    uint256 private constant SUP_GEN13_ID = 2222;
    uint256 private constant SUP_GEN21_ID = 2222;
    uint256 private constant SUP_GEN22_ID = 2222;
    uint256 private constant SUP_GEN23_ID = 2222;

    /// @dev Emitted when the supply of this collection changes
    event SupplyChanged(bytes2 indexed gen, uint256 indexed supply);

    // Keeps track of how many we have minted
    Counters.Counter private _gen0TokenCount;
    Counters.Counter private _gen11TokenCount;
    Counters.Counter private _gen12TokenCount;
    Counters.Counter private _gen13TokenCount;
    Counters.Counter private _gen21TokenCount;
    Counters.Counter private _gen22TokenCount;
    Counters.Counter private _gen23TokenCount;

    /// @dev The maximum count of tokens this token tracker will hold.
    uint256 private _gen0MaxSupply;
    uint256 private _gen11MaxSupply;
    uint256 private _gen12MaxSupply;
    uint256 private _gen13MaxSupply;
    uint256 private _gen21MaxSupply;
    uint256 private _gen22MaxSupply;
    uint256 private _gen23MaxSupply;

    /// Instanciate the contract
    constructor () {
        _gen0MaxSupply = SUP_GEN0_ID;
        _gen11MaxSupply = SUP_GEN11_ID;
        _gen12MaxSupply = SUP_GEN12_ID;
        _gen13MaxSupply = SUP_GEN13_ID;
        _gen21MaxSupply = SUP_GEN21_ID;
        _gen22MaxSupply = SUP_GEN22_ID;
        _gen23MaxSupply = SUP_GEN23_ID;
    }

    /// @dev Get the max Supply
    /// @return the maximum token count
    function getMaxSupply(bytes2 _gen) public view returns (uint256) {
        if (_gen == GEN0) {
            return _gen0MaxSupply;
        } else if (_gen == GEN11) {
            return _gen11MaxSupply;
        } else if (_gen == GEN12) {
            return _gen12MaxSupply;
        } else if (_gen == GEN13) {
            return _gen13MaxSupply;
        } else if (_gen == GEN21) {
            return _gen21MaxSupply;
        } else if (_gen == GEN22) {
            return _gen22MaxSupply;
        }else if (_gen == GEN23) {
            return _gen23MaxSupply;
        } else {
            return 0;
        }       
    }

    /// @dev Get the current token count
    /// @return the created token count
    function tokenCount(bytes2 _gen) public view returns (uint256) {
        if (_gen == GEN0) {
            return _gen0TokenCount.current();
        } else if (_gen == GEN11) {
            return _gen11TokenCount.current();
        } else if (_gen == GEN12) {
            return _gen12TokenCount.current();
        } else if (_gen == GEN13) {
            return _gen13TokenCount.current();
        } else if (_gen == GEN21) {
            return _gen21TokenCount.current();
        } else if (_gen == GEN22) {
            return _gen22TokenCount.current();
        }else if (_gen == GEN23) {
            return _gen23TokenCount.current();
        } else {
            return 0;
        }
    }

    /// @dev Check whether tokens are still available
    /// @return the available token count
    function availableTokenCount(bytes2 _gen) public view returns (uint256) {
        return getMaxSupply(_gen) - tokenCount(_gen);
    }

    /// @dev Increment the token count and fetch the latest count
    /// @return the next token id
    function nextToken(bytes2 _gen) internal virtual returns (uint256) {
        uint256 token = 0;
        if (_gen == GEN0) {
            token = _gen0TokenCount.current();
            _gen0TokenCount.increment();
        } else if (_gen == GEN11) {
            token = _gen11TokenCount.current();
            _gen11TokenCount.increment();
        } else if (_gen == GEN12) {
            token = _gen12TokenCount.current();
            _gen12TokenCount.increment();
        } else if (_gen == GEN13) {
            token = _gen13TokenCount.current();
            _gen13TokenCount.increment();
        } else if (_gen == GEN21) {
            token = _gen21TokenCount.current();
            _gen21TokenCount.increment();
        } else if (_gen == GEN22) {
            token = _gen22TokenCount.current();
            _gen22TokenCount.increment();
        } else if (_gen == GEN23) {
            token = _gen23TokenCount.current();
            _gen23TokenCount.increment();
        } 
        return token;
    }

    /// @dev Check whether another token is still available
    modifier ensureAvailability(bytes2 _gen) {
        require(availableTokenCount(_gen) > 0, "No more tokens available");
        _;
    }

    /// @param _amount Check whether number of tokens are still available
    /// @dev Check whether tokens are still available
    modifier ensureAvailabilityFor(uint256 _amount, bytes2 _gen) {
        require(availableTokenCount(_gen) >= _amount, "Requested number of tokens not available");
        _;
    }

    /// Update the supply for the collection
    /// @param _supply the new token supply.
    /// @dev create additional token supply for this collection.
    function _setSupply(uint256 _supply, bytes2 _gen) private {
        require(_supply > tokenCount(_gen), "Can't set the supply to less than the current token count");
        if (_gen == GEN0) {
            _gen0MaxSupply = _supply;
        } else if (_gen == GEN11) {
            _gen11MaxSupply = _supply;
        } else if (_gen == GEN12) {
            _gen12MaxSupply = _supply;
        } else if (_gen == GEN13) {
            _gen13MaxSupply = _supply;
        } else if (_gen == GEN21) {
            _gen21MaxSupply = _supply;
        } else if (_gen == GEN22) {
            _gen22MaxSupply = _supply;
        } else if (_gen == GEN23) {
            _gen23MaxSupply = _supply;
        } 

        emit SupplyChanged(_gen, getMaxSupply(_gen));
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}