pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./FoundersTokensV2.sol";
//import "./CollabFaker.sol";
import "./StakingContract.sol";

contract StarFallVillage is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private _owner;

    uint256 private MAX_TOKENS;

    uint256 private MAX_GENESIS = 3333;

    uint256 private SALE_PRICE = 0.08 ether;

    uint256 private WL_LIMIT = 1111;

    uint256 private AL_AMOUNT = 10;

    uint256 private FP_AMOUNT = 2;

    uint256 private balance = 0;

    uint256 private _wlStartDateTime;

    uint256 private _wlEndDateTime;

    uint256 private _alStartDateTime;

    uint256 private _alEndDateTime;

    uint256 private _publicSaleTime;

    bool private publicSaleActive = true;

    bool private isGenesis = true;

    string private baseURI = "https://sfvpfp.s3.amazonaws.com/preview/";

    mapping (address => uint256) private _mappingWhiteList;

    mapping (address => uint256) private _mappingAllowList;

    mapping (address => uint256) private _mappingFPSpots;

    mapping (address => bool) private _mappingPartnerChecked;

    address fp_address;

    mapping(string => uint256) discountNum;
    
    //mapping(string => uint256) discountDen;

    uint256 wlSaleCount = 0;

    uint256 public offsetGenesis = 0;

    uint256 public offsetNext = 0;

    bool public genesisOffsetSet = false;

    bool public nextOffsetSet = false;

    address[10] partner_tokens_721 = [0xf36446105fF682999a442b003f2224BcB3D82067, 
    0xb072114151f32D85223aE7B00Ac0528d1F56aa6E, 0xf36446105fF682999a442b003f2224BcB3D82067, 0x521f9C7505005CFA19A8E5786a9c3c9c9F5e6f42, 
    0x9690b63Eb85467BE5267A3603f770589Ab12Dc95, 0xe26F2c3547123B5FDaE0bfD52419D71BdFb0c4EF, 0x67421C8622F8E38Fe9868b4636b8dC855347d570, 
    0x8c3FB10693B228E8b976FF33cE88f97Ce2EA9563, 0x364C828eE171616a39897688A831c2499aD972ec, 0x8Cd8155e1af6AD31dd9Eec2cEd37e04145aCFCb3];

    //address[2] partner_tokens_721 = [0x6a033F4680069BB66D99Dab5Bf97C6D2c663d4A7, 0x0C296728a1B309a8f7043F22349c1874e63cF37f];  // for dev

    address[2] staking_partners = [0x0C565d28364a2C073AF3E270444476C19e8b986c, 0x682F6Fa7dBf3ea6CAd1533E4acd9B5E6f67372C9];

    //address[2] staking_partners = [0xBf8a4dF45F98386852b1Ae1aDb7F5e1fFa8d9200, 0xBf8a4dF45F98386852b1Ae1aDb7F5e1fFa8d9200]; // for dev

    address[2] partner_tokens_1155 = [0x495f947276749Ce646f68AC8c248420045cb7b5e, 0x495f947276749Ce646f68AC8c248420045cb7b5e];

    uint256[2] start_token_ids = [108510973921457929967077298367545831468135648058682555520544970183838078599169,
    108510973921457929967077298367545831468135648058682555520544981071202216837121];

    uint256[2] token_deltas = [1099511627776, 1099511627776];

    constructor(address _fp, uint256 supply) ERC721("StarFall Village PFP", "SVPFP") public {
        _owner = msg.sender;

        MAX_TOKENS = supply;

        fp_address = _fp;

        _tokenIds.increment();

        discountNum["Paper"] = 90;
        discountNum["Bronze"] = 85;
        discountNum["Silver"] = 80;
        discountNum["Gold"] = 75;
        discountNum["Ghostly"] = 50;

        FoundersTokensV2 fp = FoundersTokensV2(fp_address);
        uint256 total = fp.itemsMinted();
        for (uint256 i=1; i <= total; i++) {
            _mappingFPSpots[fp.ownerOf(i)] += FP_AMOUNT;
        }

    }



    /** Sale helper functions */

    function hasPartnerTokenStaked(address owner) 
    public 
    view 
    returns(bool) {
        for(uint i=0; i < staking_partners.length; i ++) {
            StakingContract sc = StakingContract(staking_partners[i]);
            if (sc.depositsOf(owner).length > 0) {
                return true;
            }
        }

        return false;
    }

    function hasPartnerToken(address owner) 
    public 
    view 
    returns(bool) {
        for(uint i=0; i < partner_tokens_721.length; i ++) {
            ERC721 token = ERC721(partner_tokens_721[i]);
            if (token.balanceOf(owner) > 0) {
                return true;
            }
        }

        return false;
    }

    function hasSemiPartnerToken(address owner) 
    public 
    view 
    returns(bool) {
        for(uint i=0; i < partner_tokens_1155.length; i ++) {
            ERC1155 token = ERC1155(partner_tokens_1155[i]);
            uint256 token_id = start_token_ids[i];
            for (uint i= 0; i < 9900; i++) {
                if (token.balanceOf(owner, token_id) > 0) {
                    return true;
                }
                token_id += token_deltas[i];
            }
        }

        return false;
    }

    function getWLPrice(uint256 numberOfMints, address wallet) 
    public 
    view 
    returns (uint256) {
        uint256 price = 0;
        if (numberOfMints > _mappingFPSpots[wallet]) {
            price = (numberOfMints - _mappingFPSpots[wallet]) * SALE_PRICE;
        }
        return price;
    }

    function getDiscountPrice(uint256 numberOfMints, uint256 fpTokenId) 
    public 
    view 
    returns (uint256) {
        FoundersTokensV2 fp = FoundersTokensV2(fp_address);
        //require(wallet == fp.ownerOf(fpTokenId), "not owner");
        (, string memory trait) = fp.getTraits(fpTokenId);
        uint256 discountPrice = (SALE_PRICE * numberOfMints * discountNum[trait]) / 100;
        return discountPrice;
    }

    function getDiscountPriceWL(uint256 numberOfMints, uint256 fpTokenId, address wallet)
    public 
    view 
    returns (uint256) {
        uint256 discountPrice = 0;
        if (numberOfMints > _mappingFPSpots[wallet]) {
            FoundersTokensV2 fp = FoundersTokensV2(fp_address);
            (, string memory trait) = fp.getTraits(fpTokenId);
            discountPrice = ((numberOfMints - _mappingFPSpots[wallet]) * SALE_PRICE * discountNum[trait]) / 100;
        }
        return discountPrice;
    }

    function tokenURI(uint256 tokenId) 
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        //string memory _tokenURI = _tokenURIs[tokenId];
        //string(abi.encodePacked("ipfs://"));
        if (tokenId <= MAX_GENESIS) {
            uint256 tokenIdGenesis = tokenId + offsetGenesis;
            if (tokenIdGenesis > MAX_GENESIS) {
                tokenIdGenesis = tokenIdGenesis - MAX_GENESIS;
            }
            return string(abi.encodePacked("https://sfvpfp.s3.amazonaws.com/preview/", Strings.toString(tokenIdGenesis), ".json"));
        }
        uint256 tokenIdNext = tokenId + offsetNext;
        if (tokenIdNext > MAX_TOKENS) {
            tokenIdNext = tokenIdNext - MAX_TOKENS + MAX_GENESIS;
        }
        return string(abi.encodePacked(baseURI, Strings.toString(tokenIdNext), ".json"));
    }



    /** Owner methods */

    function createMintEvent(uint256 wlStartTime, uint256 wlEndTime, uint256 alStartTime, uint256 alEndTime, uint256 publicStartTime) 
    external 
    onlyOwner {
        _wlStartDateTime = wlStartTime;
        _wlEndDateTime = wlEndTime; //wlStartTime + WL_SALE_LENGTH;
        _alStartDateTime = alStartTime;
        _alEndDateTime = alEndTime; //alStartTime + AL_SALE_LENGTH;
        _publicSaleTime = publicStartTime;
    }

    function setWhiteList(address[] calldata whiteListAddress, uint256[] calldata amount) 
    external 
    onlyOwner {
        for (uint256 i = 0; i < whiteListAddress.length; i++) {
            _mappingWhiteList[whiteListAddress[i]] = amount[i];
        }
    }

    function setAllowList(address[] calldata allowListAddress) 
    external 
    onlyOwner {
        for (uint256 i = 0; i < allowListAddress.length; i++) {
            _mappingAllowList[allowListAddress[i]] = AL_AMOUNT;
        }
    }

    function setFPList() 
    external 
    onlyOwner {
        FoundersTokensV2 fp = FoundersTokensV2(fp_address);
        uint256 total = fp.itemsMinted();
        for (uint256 i=1; i <= total; i++) {
            _mappingFPSpots[fp.ownerOf(i)] += FP_AMOUNT;
        }
    }

    function setBaseURI(string memory _uri) 
    external 
    onlyOwner {
        baseURI = _uri;
    }

    function changePrice(uint256 _salePrice) 
    external 
    onlyOwner {
        SALE_PRICE = _salePrice;
    }

    function changeWLLimit(uint256 limit) 
    external 
    onlyOwner {
        WL_LIMIT = limit;
    }

    function changeALAmount(uint256 amount) 
    external 
    onlyOwner {
        AL_AMOUNT = amount;
    }

    function changeFPAmount(uint256 amount) 
    external 
    onlyOwner {
        FP_AMOUNT = amount;
    }

    function setPublicSaleActive(bool active) 
    external 
    onlyOwner {
        publicSaleActive = active;
    }

    function setGenisis(bool genesis) 
    external 
    onlyOwner {
        isGenesis = genesis;
    }

    function getRandom(uint256 limit) 
    private 
    view 
    returns(uint16) {
        uint256 totalMinted = itemsMinted();
        address owner1 = ownerOf(totalMinted/5);
        address owner2 = ownerOf(totalMinted*2/5);
        address owner3 = ownerOf(totalMinted*3/5);
        address owner4 = ownerOf(totalMinted*4/5);
        address owner5 = ownerOf(totalMinted - 1);
        uint256 pseudoRandom = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), owner1, owner2, owner3, owner4, owner5)));
        return uint16(uint16(pseudoRandom >> 1) % limit);
    }

    function revealGenesis() 
    external 
    onlyOwner { 
        require(
            !genesisOffsetSet, 
            "already revealed"
        );
        offsetGenesis = uint256(getRandom(MAX_GENESIS));
        genesisOffsetSet = true;
    }

    function revealNext() 
    external 
    onlyOwner { 
        require(
            !nextOffsetSet, 
            "already revealed"
        );
        offsetNext = uint256(getRandom(MAX_TOKENS - MAX_GENESIS));
        nextOffsetSet = true;
    }



    /** Minting methods */

    function mintWhiteList(uint256 numberOfMints) 
    public 
    payable {
        uint256 reserved = _mappingWhiteList[msg.sender] + _mappingFPSpots[msg.sender];
        require(
            isWhiteListSale(), 
            "No presale active"
        );
        require(
            reserved > 0 || 
            msg.sender == _owner, 
            "This address is not authorized for presale"
        );
        require(
            numberOfMints <= reserved 
            || msg.sender == _owner, 
            "Exceeded allowed amount"
        );
        require(
            wlSaleCount + numberOfMints <= WL_LIMIT, 
            "This would exceed the max number of allowed for wl sale"
        );
        require(
            _tokenIds.current() - 1 + numberOfMints <= MAX_TOKENS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            !isGenesis || _tokenIds.current() - 1 + numberOfMints <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            getWLPrice(numberOfMints, msg.sender) <= msg.value 
            || msg.sender == _owner, 
            "Amount of ether is not enough"
        );

        uint256 usedSpots = 0;

        if (numberOfMints >= _mappingFPSpots[msg.sender]) {
            usedSpots = _mappingFPSpots[msg.sender];
            _mappingFPSpots[msg.sender] = 0;
        } else {
            _mappingFPSpots[msg.sender] = _mappingFPSpots[msg.sender] - numberOfMints;
        }
        if ((numberOfMints > usedSpots) && _mappingFPSpots[msg.sender] == 0) {
            _mappingWhiteList[msg.sender] = _mappingWhiteList[msg.sender] - (numberOfMints - usedSpots);
        }

        wlSaleCount = wlSaleCount + numberOfMints;

        uint256 newItemId = _tokenIds.current();

        for (uint256 i=0; i < numberOfMints; i++) {
            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }

    }

    function mintWhiteListWithDiscount(uint256 numberOfMints, uint256 fpTokenId) 
    public 
    payable {
        uint256 reserved = _mappingWhiteList[msg.sender] + _mappingFPSpots[msg.sender];
        require(
            isWhiteListSale(), 
            "No presale active"
        );
        require(
            reserved > 0 
            || msg.sender == _owner, 
            "This address is not authorized for presale"
        );
        require(
            numberOfMints <= reserved 
            || msg.sender == _owner, 
            "Exceeded allowed amount"
        );
        require(
            wlSaleCount + numberOfMints <= WL_LIMIT, 
            "This would exceed the max number of allowed for wl sale"
        );
        require(
            _tokenIds.current() - 1 + numberOfMints <= MAX_TOKENS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            !isGenesis 
            || _tokenIds.current() - 1 + numberOfMints <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );
        uint256 discountPrice = getDiscountPriceWL(numberOfMints, fpTokenId, msg.sender);
        require(
            msg.value >= discountPrice, 
            "not enough money"
        );

        uint256 usedSpots = 0;

        if (numberOfMints >= _mappingFPSpots[msg.sender]) {
            usedSpots = _mappingFPSpots[msg.sender];
            _mappingFPSpots[msg.sender] = 0;
        } else {
            _mappingFPSpots[msg.sender] = _mappingFPSpots[msg.sender] - numberOfMints;
        }
        if ((numberOfMints > usedSpots) && _mappingFPSpots[msg.sender] == 0) {
            _mappingWhiteList[msg.sender] = _mappingWhiteList[msg.sender] - (numberOfMints - usedSpots);
        }

        wlSaleCount = wlSaleCount + numberOfMints;

        uint256 newItemId = _tokenIds.current();

        for (uint256 i=0; i < numberOfMints; i++) {
            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }

    }

    function mintAllowList(uint256 numberOfMints) public payable {
        uint256 reserved = _mappingAllowList[msg.sender];
        require(
            isAllowListSale(), 
            "No presale active"
        );
        //require(hasPartnerToken(msg.sender), "No partner token");
        require(
            reserved > 0 
            || hasPartnerToken(msg.sender) 
            || hasPartnerTokenStaked(msg.sender)
            || hasSemiPartnerToken(msg.sender),
            "This address is not authorized for presale"
        );
        if (reserved == 0 && (hasPartnerToken(msg.sender) || hasPartnerTokenStaked(msg.sender) || hasSemiPartnerToken(msg.sender))) {
            if (!_mappingPartnerChecked[msg.sender]) {
                _mappingAllowList[msg.sender] = AL_AMOUNT;
                _mappingPartnerChecked[msg.sender] = true;
            }
            reserved = _mappingAllowList[msg.sender];
            require(
                reserved > 0, 
                "This address is not authorized for presale"
            );
        }
        require(
            numberOfMints <= reserved, 
            "Exceeded allowed amount"
        );
        //require(alSaleCount < AL_LIMIT, "This would exceed the max number of allowed for allow sale");
        require(
            _tokenIds.current() - 1 + numberOfMints <= MAX_TOKENS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            !isGenesis 
            || _tokenIds.current() - 1 + numberOfMints <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            numberOfMints * SALE_PRICE <= msg.value, 
            "Amount of ether is not enough"
        );

        _mappingAllowList[msg.sender] = reserved - numberOfMints;

        _mappingPartnerChecked[msg.sender] = true;

        uint256 newItemId = _tokenIds.current();

        for (uint256 i=0; i < numberOfMints; i++) {
            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }

    }

    function mintAllowListWithDiscount(uint256 numberOfMints, uint256 fpTokenId) public payable {
        uint256 reserved = _mappingAllowList[msg.sender];
        require(
            isAllowListSale(), 
            "No presale active"
        );
        //require(hasPartnerToken(msg.sender), "No partner token");
        require(
            reserved > 0 
            || hasPartnerToken(msg.sender) 
            || hasPartnerTokenStaked(msg.sender)
            || hasSemiPartnerToken(msg.sender), 
            "This address is not authorized for presale"
        );
        if (reserved == 0 && (hasPartnerTokenStaked(msg.sender)  || hasPartnerToken(msg.sender) || hasSemiPartnerToken(msg.sender))) {
            if (!_mappingPartnerChecked[msg.sender]) {
                _mappingAllowList[msg.sender] = AL_AMOUNT;
                _mappingPartnerChecked[msg.sender] = true;
            }
            reserved = _mappingAllowList[msg.sender];
            require(
                reserved > 0, 
                "This address is not authorized for presale"
            );
        }
        require(
            numberOfMints <= reserved, 
            "Exceeded allowed amount"
        );
        //require(alSaleCount < AL_LIMIT, "This would exceed the max number of allowed for allow sale");
        require(
            _tokenIds.current() - 1 + numberOfMints <= MAX_TOKENS, 
            "This would exceed the max number of allowed nft"
        );
        require(
            !isGenesis 
            || _tokenIds.current() - 1 + numberOfMints <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );

        FoundersTokensV2 fp = FoundersTokensV2(fp_address);
        require(
            msg.sender == fp.ownerOf(fpTokenId), 
            "not owner"
        );
        uint256 discountPrice = getDiscountPrice(numberOfMints, fpTokenId);
        require(
            msg.value >= discountPrice, 
            "not enough money"
        );

        _mappingAllowList[msg.sender] = reserved - numberOfMints;

        _mappingPartnerChecked[msg.sender] = true;

        uint256 newItemId = _tokenIds.current();

        for (uint256 i=0; i < numberOfMints; i++) {
            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }

    }

    function createItem(uint256 numberOfTokens) public payable returns (uint256) {
        require(
            (
                (block.timestamp >= _publicSaleTime && publicSaleActive) 
                || msg.sender == _owner
            ), 
            "sale not active"
        );
        require(
            msg.value >= (SALE_PRICE * numberOfTokens) 
            || msg.sender == _owner, 
            "not enough money"
        );

        uint256 newItemId = _tokenIds.current();
        //_setTokenURI(newItemId, string(abi.encodePacked("ipfs://", _hash)));
        require(
            (newItemId - 1 + numberOfTokens) <= MAX_TOKENS, 
            "collection fully minted"
        );
        require(
            !isGenesis 
            || _tokenIds.current() - 1 + numberOfTokens <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );

        for (uint256 i=0; i < numberOfTokens; i++) {

            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }


        //payable(address(this)).transfer(SALE_PRICE);

        return newItemId;
    }

    function createItemWithDiscount(uint256 numberOfTokens, uint256 fpTokenId) public payable returns (uint256) {
        require(
            (
                (block.timestamp >= _publicSaleTime && publicSaleActive) 
                || msg.sender == _owner
            ), 
            "sale not active"
        );
        FoundersTokensV2 fp = FoundersTokensV2(fp_address);
        require(
            msg.sender == fp.ownerOf(fpTokenId), 
            "not owner"
        );
        uint256 discountPrice = getDiscountPrice(numberOfTokens, fpTokenId);
        require(
            msg.value >= discountPrice, 
            "not enough money"
        );

        uint256 newItemId = _tokenIds.current();
        //_setTokenURI(newItemId, string(abi.encodePacked("ipfs://", _hash)));
        require(
            (newItemId - 1 + numberOfTokens) <= MAX_TOKENS, 
            "collection fully minted"
        );
        require(
            !isGenesis 
            || _tokenIds.current() - 1 + numberOfTokens <= MAX_GENESIS, 
            "This would exceed the max number of allowed nft"
        );

        for (uint256 i=0; i < numberOfTokens; i++) {

            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }


        //payable(address(this)).transfer(SALE_PRICE);

        return newItemId;
    }


    /** Public View methods */

    function withdraw() onlyOwner public {
        require(
            address(this).balance > 0, 
            "0 balance"
        );
        payable(_owner).transfer(address(this).balance);
    }

    function getRemainingWLSpots(address wl) 
    public 
    view 
    returns (uint256) {
        return _mappingWhiteList[wl];
    }

    function getRemainingFPSpots(address wl) 
    public 
    view 
    returns (uint256) {
        return _mappingFPSpots[wl];
    }

    function getRemainingAllowListSpots(address wl) 
    public 
    view 
    returns (uint256) {
        return _mappingAllowList[wl];
    }

    function getParterChecked(address wl) 
    public 
    view 
    returns (bool) {
        return _mappingPartnerChecked[wl];
    }

    function getCurrentPrice() 
    public 
    view 
    returns (uint256) {
        return SALE_PRICE;
    }

    function getWLSaleCount() 
    public 
    view 
    returns (uint256) {
        return wlSaleCount;
    }

    function itemsMinted() 
    public 
    view 
    returns(uint) {
        return _tokenIds.current() - 1;
    }

    function ownerBalance() 
    public 
    view 
    returns(uint256) {
        return address(this).balance;
    }

    function isWhiteListSale() 
    public 
    view 
    returns(bool) {
        return (block.timestamp >= _wlStartDateTime && block.timestamp <= _wlEndDateTime);
    }

    function isAllowListSale() 
    public 
    view 
    returns(bool) {
        return (block.timestamp >= _alStartDateTime && block.timestamp <= _alEndDateTime);
    }

    function isPublicSale() 
    public 
    view 
    returns(bool) {
        return (block.timestamp >= _publicSaleTime);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

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
        require(account != address(0), "ERC1155: balance query for the zero address");
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
            "ERC1155: caller is not owner nor approved"
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
            "ERC1155: transfer caller is not owner nor approved"
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

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

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

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
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

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
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

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
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
    function _beforeTokenTransfer(
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

//import "./FoundersTokens.sol";


contract FoundersTokensV2 is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address private _owner;

    uint32 private MAX_TOKENS = 3999;

    //uint256 SEED_NONCE = 0;

    uint256 private SALE_PRICE = 0.08 ether;

    uint256 private balance = 0;

    bool private isActive = false;
    
    //bool private REVEAL = false;

    string private baseURI = "https://gtsdfp.s3.amazonaws.com/preview/";

    mapping(uint256 => Trait) private tokenIdTrait;

    //uint arrays
    //uint16[][2] TIERS;

    uint16[][4] RARITIES; // = [[695, 695, 695, 695], [150, 150, 150, 150], [100, 100, 100, 100], [50, 50, 50, 50], [5, 5, 5, 5]];


    struct Trait {
        uint16 artType;
        uint16 materialType;
    }

    string[] private artTypeValues = [
        'Mean Cat',
        'Mouse',
        'Marshal',
        'Hero'
    ];

    string[] private materialTypeValues = [
        'Paper',
        'Bronze',
        'Silver',
        'Gold',
        'Ghostly'
    ];

    mapping(string=>uint16) artMap; //= {'Mean Cat': 0, 'Mouse': 1, 'Marshal': 2, 'Hero': 3];
    
    mapping(string=>uint16) materialMap;

    address v1Contract;

    constructor() ERC721("Ghost Town Founders Pass V2", "GTFP") public {
        _owner = msg.sender;

        //v1Contract = _v1Contract;

        _tokenIds.increment();

        artMap['MeanCat'] = 0;
        artMap['Mouse'] = 1;
        artMap['Marshal'] = 2;
        artMap['Hero'] = 3;

        materialMap['Paper'] = 0;
        materialMap['Bronze'] = 1;
        materialMap['Silver'] = 2;
        materialMap['Gold'] = 3;
        materialMap['Ghostly'] = 4;

        //Declare all the rarity tiers

        //Art
        //TIERS[0] = [5, 5, 5, 5];//TIERS[0] = [1000, 1000, 1000, 1000]; // Mean Cat, MM, FM, Landscape
        //material
        //TIERS[1] = [10, 4, 3, 2, 1]; // paper, bronze, silver, gold, ghostly

        //RARITIES[0] = [695, 695, 695, 695]; //, [150, 150, 150, 150], [100, 100, 100, 100], [50, 50, 50, 50], [5, 5, 5, 5]];
        //RARITIES[1] = [150, 150, 150, 150];
        //RARITIES[2] = [100, 100, 100, 100];
        //RARITIES[3] = [50, 50, 50, 50];
        //RARITIES[4] = [5, 5, 5, 5];

        RARITIES[0] = [695, 150, 100, 50, 5]; // rotating creates a better overall random distribution
        RARITIES[1] = [695, 150, 100, 50, 5];
        RARITIES[2] = [695, 150, 100, 50, 5];
        RARITIES[3] = [695, 150, 100, 50, 5];
        //RARITIES = _RARITIES;
    }


    function tokenURI(uint256 tokenId) 
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        //string memory _tokenURI = _tokenURIs[tokenId];
        //string(abi.encodePacked("ipfs://"));
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function activate(bool active) external onlyOwner {
        isActive = active;
    }

    function setBaseURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    /*function setReveal(bool _reveal) external onlyOwner {
        REVEAL = _reveal;
    }*/

    function changePrice(uint256 _salePrice) external onlyOwner {
        SALE_PRICE = _salePrice;
    }

    function mintV1(uint256 numberOfMints, string[] calldata artList, string[] calldata matList, address[] calldata addrList) public {

        require(msg.sender == _owner, "not owner");

        uint256 newItemId = _tokenIds.current();

        require((newItemId - 1 + numberOfMints <= 247), "v1 limit exceeded");

        //FoundersTokens fpV1 = FoundersTokens(v1Contract);

        for (uint256 i=0; i < numberOfMints; i++) {

            //(string memory artType, string memory materialType) = fpV1.getTraits(newItemId);

            //require(RARITIES[artMap[artType]][materialMap[materialType]], "no rare");

            RARITIES[artMap[artList[i]]][materialMap[matList[i]]] -= 1;

            //tokenIdTrait[newItemId] = createTraits(newItemId, addresses[i]);
            tokenIdTrait[newItemId] = Trait({artType: artMap[artList[i]], materialType: materialMap[matList[i]]});

            _safeMint(addrList[i], newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }

    }

    function createItem(uint256 numberOfTokens) public payable returns (uint256) {
        //require(((block.timestamp >= _startDateTime && block.timestamp < _endDateTime  && !isWhiteListSale) || msg.sender == _owner), "sale not active");
        require(isActive || msg.sender == _owner, "sale not active");
        require(msg.value >= SALE_PRICE || msg.sender == _owner, "not enough money");
        //require(((mintTracker[msg.sender] + numberOfTokens) <= MAXQ || msg.sender == _owner), "ALready minted during sale");

        uint256 newItemId = _tokenIds.current();
        //_setTokenURI(newItemId, string(abi.encodePacked("ipfs://", _hash)));
        require(newItemId > 247, "need to transfer v1");
        require((newItemId - 1 + numberOfTokens) <= MAX_TOKENS, "collection fully minted");

        //mintTracker[msg.sender] = mintTracker[msg.sender] + numberOfTokens;

        for (uint256 i=0; i < numberOfTokens; i++) {
            tokenIdTrait[newItemId] = createTraits(newItemId, msg.sender);

            _safeMint(msg.sender, newItemId);

            _tokenIds.increment();
            newItemId = _tokenIds.current();
        }


        //payable(address(this)).transfer(SALE_PRICE);

        return newItemId;
    }

    function weightedRarityGenerator(uint16 pseudoRandomNumber) private returns (uint8, uint8) {
        uint16 lowerBound = 0;

        for (uint8 i = 0; i < RARITIES.length; i++) {
            for (uint8 j = 0; j < RARITIES[i].length; j++) {
                uint16 weight = RARITIES[i][j];

                if (pseudoRandomNumber >= lowerBound && pseudoRandomNumber < lowerBound + weight) {
                    RARITIES[i][j] -= 1;
                    return (i, j);
                }

                lowerBound = lowerBound + weight;
            }
        }

        revert();
    }

    function createTraits(uint256 tokenId, address _msgSender) private returns (Trait memory) {
        uint256 pseudoRandomBase = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), _msgSender, tokenId)));

        uint256 tokensMinted = itemsMinted();
        (uint8 a, uint8 m) = weightedRarityGenerator(uint16(uint16(pseudoRandomBase >> 1) % (1 + MAX_TOKENS - tokensMinted)));
        return
            Trait({
                artType: a,
                materialType: m
            });
    }

    function withdraw() onlyOwner public {
        require(address(this).balance > 0, "0 balance");
        payable(_owner).transfer(address(this).balance);
    }

    function getTraits(uint256 tokenId) public view returns (string memory artType, string memory materialType) {
        //require(REVEAL, "reveal not set yet");
        Trait memory trait = tokenIdTrait[tokenId];
        artType = artTypeValues[trait.artType];
        materialType = materialTypeValues[trait.materialType];
    }


    function itemsMinted() public view returns(uint) {
        return _tokenIds.current() - 1;
    }

    function ownerBalance() public view returns(uint256) {
        return address(this).balance;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface StakingContract {
    function depositsOf(address account)
        external
        view
        returns (uint256[] memory);
}

/*
contract CollabFaker2 {
    StakingContract public stakingContract =
        StakingContract(0x8D8A3e7EAdA138523c2dcB78FDbbF51A63A3faAD);

    function balanceOf(address owner) external view returns (uint256 balance) {
        return stakingContract.depositsOf(owner).length;
    }
}*/

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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