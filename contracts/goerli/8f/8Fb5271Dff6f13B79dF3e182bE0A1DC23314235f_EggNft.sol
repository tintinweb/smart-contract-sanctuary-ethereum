// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Address.sol";
import "./ERC721.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract EggNft is ERC721, Ownable {
    event Received(address, uint256);
    event Fallback(address, uint256);

    event SetTotalSupply(address addr, uint256 _totalSupply);
    event SetOgPrice(address addr, uint256 _price);
    event SetWlPrice(address addr, uint256 _price);
    event SetPlPrice(address addr, uint256 _price);

    event SetOgLimit(address addr, uint256 _count);
    event SetWlLimit(address addr, uint256 _count);
    event SetPlLimit(address addr, uint256 _count);

    event WithdrawAll(address addr, uint256 cro);

    event SetBaseURI(string baseURI);
    event SetGoldenList(address _user);
    event SetOgList(address _user);
    event SetWlList(address _user);
    event EggType(string _eggtype, address addr);
    event SetPlList(address _user);

    using Strings for uint256;

    uint256 private MAX_SUPPLY = 7799;

    uint256 private MAX_MINT_AMOUNT = 20;

    uint256 private MAX_GOLDEN_COUNT = 7;
    uint256 private MAX_GOOD_OR_EVIL_COUNT = 4500;

    uint256 private ogPrice = 0.001 * 10**18;
    uint256 private wlPrice = 0.002 * 10**18;
    uint256 private plPrice = 0.003 * 10**18;

    uint256 private ogLimit = 100;
    uint256 private wlLimit = 200;
    uint256 private plLimit = 700;

    uint256 private _nftMintedCount;
    uint256 private _goldenNftMintedCount;
    uint256 private _goodNftMintedCount;
    uint256 private _evilNftMintedCount;
    uint256 private mintType = 0;
    string private _baseURIExtended;
    string private _baseExtension;
    bool private revealed;
    string private notRevealedUri;
    bool private paused;

    // mapping(address => bool) _goldenList;
    // mapping(address => bool) _ogList;
    // mapping(address => bool) _wlList;
    // mapping(address => bool) _plList;

    mapping(address => uint256) _ogMintedCountList;
    mapping(address => uint256) _wlMintedCountList;
    mapping(address => uint256) _plMintedCountList;

    mapping(uint256 => uint256) _uriToTokenId;

    // mapping(address => bool) wlListClaimed;
    // mapping(address => bool) ogListClaimed;

    bytes32 public merkleOgListRoot = 0x441e9a093d15a285456b05fae796239465b0a00c138dfde451ea541e55ea1856;
    bytes32 public merkleWlListRoot = 0x441e9a093d15a285456b05fae796239465b0a00c138dfde451ea541e55ea1856;
    

    constructor() ERC721("Egg NFT", "Egg") {
        _baseURIExtended = "https://ipfs.infura.io/";
        _baseExtension = ".json";
        _nftMintedCount = 0;
        _goldenNftMintedCount = 0;
        _goodNftMintedCount = 0;
        _evilNftMintedCount = 0;
        paused = true;
    }

    function isWlUser(bytes32[] calldata _merkleProof) public returns (bool) {
        // require (!wlListClaimed[msg.sender], "Address has already claimed.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleWlListRoot, leaf);
        // require (!MerkleProof.verify(_merkleProof, merkleWlListRoot, leaf), "Invalid Roof.");
        // wlListClaimed[msg.sender] = true;

    }

    function isOgUser(bytes32[] calldata _merkleProof) public returns (bool){
        // require (!ogListClaimed[msg.sender], "Address has already claimed.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, merkleOgListRoot, leaf);
        // require (!MerkleProof.verify(_merkleProof, merkleOgListRoot, leaf), "Invalid Roof.");
        // ogListClaimed[msg.sender] = true;
    }

    //only owner
    function reveal() external onlyOwner {
        revealed = true;
    }

    function setNotRevealedURI(string memory _notRevealedURI)
        external
        onlyOwner
    {
        notRevealedUri = _notRevealedURI;
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        emit Fallback(msg.sender, msg.value);
    }

    function setMintType(uint256 nftMintType) external onlyOwner {
        mintType = nftMintType;
    }

    function getNftMintPrice(uint256 amount) external view returns (uint256) {
        if (mintType == 0) {
            return amount * ogPrice;
        } else if (mintType == 1) {
            return amount * wlPrice;
        } else {
            return amount * plPrice;
        }
    }

    function getUserWhiteListed(bytes32[] calldata _merkleProof) external view returns (uint256) { 
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        uint256 value;
        if (mintType == 0) {
            require(MerkleProof.verify(_merkleProof, merkleOgListRoot, leaf) == true, "Not registry");
            value = 1;
        } else if (mintType == 1) {
            require(MerkleProof.verify(_merkleProof, merkleWlListRoot, leaf) == true, "Not registry");
            value = 2;
        } else {
            value = 3;
        }
        return value;
    }

    // function setGoldenList(address _user) external onlyOwner {
    //     _goldenList[_user] = true;
    //     emit SetGoldenList(_user);
    // }

    // function setOgList(address[] memory _user) external onlyOwner {
    //     for (uint256 i = 0; i < _user.length; i++) {
    //         _ogList[_user[i]] = true;
    //         emit SetOgList(_user[i]);
    //     }
    // }

    // function setWlList(address[] memory _user) external onlyOwner {
    //     for (uint256 i = 0; i < _user.length; i++) {
    //         _wlList[_user[i]] = true;
    //         emit SetWlList(_user[i]);
    //     }
    // }

    // function setPlList(address[] memory _user) external onlyOwner {
    //     for (uint256 i = 0; i < _user.length; i++) {
    //         _plList[_user[i]] = true;
    //         emit SetPlList(_user[i]);
    //     }
    // }

    // function removeOgList(address[] memory _user) external onlyOwner {
    //     for (uint256 i = 0; i < _user.length; i++) {
    //         delete _ogList[_user[i]];
    //     }
    // }

    // function removeWlList(address[] memory _user) external onlyOwner {
    //     for (uint256 i = 0; i < _user.length; i++) {
    //         delete _wlList[_user[i]];
    //     }
    // }

    // function removePlList(address[] memory _user) external onlyOwner {
    //     for (uint256 i = 0; i < _user.length; i++) {
    //         delete _plList[_user[i]];
    //     }
    // }

    //Set, Get Price Func
    function setOgLimit(uint256 _count) external onlyOwner {
        ogLimit = _count;
        emit SetOgLimit(msg.sender, _count);
    }

    function getMintType() external view returns (uint256) {
        return mintType;
    }

    function getOgLimit() external view returns (uint256) {
        return ogLimit;
    }

    function setOgPrice(uint256 _price) external onlyOwner {
        ogPrice = _price;
        emit SetOgPrice(msg.sender, _price);
    }

    function getOgPrice() external view returns (uint256) {
        return ogPrice;
    }

    function setWlLimit(uint256 _count) external onlyOwner {
        wlLimit = _count;
        emit SetWlLimit(msg.sender, _count);
    }

    function getWlLimit() external view returns (uint256) {
        return wlLimit;
    }

    function getOgMintedCountList() external view returns (uint256) {
        return _ogMintedCountList[msg.sender];
    }

    function getWlMintedCountList() external view returns (uint256) {
        return _wlMintedCountList[msg.sender];
    }

    function getPlMintedCountList() external view returns (uint256) {
        return _plMintedCountList[msg.sender];
    }

    function setWlPrice(uint256 _price) external onlyOwner {
        wlPrice = _price;
        emit SetWlPrice(msg.sender, _price);
    }

    function getWlPrice() external view returns (uint256) {
        return wlPrice;
    }

    function setPlPrice(uint256 _price) external onlyOwner {
        plPrice = _price;
        emit SetPlPrice(msg.sender, _price);
    }

    function getPlPrice() external view returns (uint256) {
        return plPrice;
    }

    function setPlLimit(uint256 _count) external onlyOwner {
        wlLimit = _count;
        emit SetPlLimit(msg.sender, _count);
    }

    function getPlLimit() external view returns (uint256) {
        return plLimit;
    }

    function setTotalSupply(uint256 _totalSupply) external onlyOwner {
        MAX_SUPPLY = _totalSupply;
        emit SetTotalSupply(msg.sender, _totalSupply);
    }

    function totalSupply() external view returns (uint256) {
        return MAX_SUPPLY;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseURIExtended = baseURI;
        emit SetBaseURI(baseURI);
    }

    function getBaseURI() external view returns (string memory) {
        return _baseURIExtended;
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIExtended;
    }

    function random(uint num) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, 
        msg.sender))) % num;
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

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _uriToTokenId[tokenId].toString(),
                        _baseExtension
                    )
                )
                : "";
    }

    function withdrawAll() external onlyOwner {
        address payable mine = payable(msg.sender);
        uint256 balance = address(this).balance;

        if (balance > 0) {
            mine.transfer(address(this).balance);
        }

        emit WithdrawAll(msg.sender, balance);
    }

    /**
     * @dev Mint NFT by customer
     */
    function mint(uint256 _mintAmount, bytes32[] calldata _merkleProof) external payable {
        require(!paused, "The contract is paused");

        uint256 currentPrice;
        uint256 _nftType = 0;

        require(
            _nftMintedCount + _mintAmount <= MAX_SUPPLY,
            "Already Finished Minting"
        );
        require(_mintAmount > 0, "mintAmount must be bigger than 0");
        if(msg.sender != owner())
        require(_mintAmount <= MAX_MINT_AMOUNT, "Can't mint over 20 at once");

        // require(
        //     _goldenList[msg.sender] == true ||
        //         owner() == msg.sender ||
        //         _ogList[msg.sender] == true ||
        //         _wlList[msg.sender] == true ||
        //         _plList[msg.sender] == true,
        //     "Invalid user"
        // );

        if(_nftMintedCount / 1111 > _goldenNftMintedCount){
            _nftType = 0;
        }

        if(random(10) > 5 ){
            _nftType = 0;
        }
        else{
            if(random(3) == 1){
                _nftType = 1;
            }
            else{
                _nftType = 2;
            }
        }
        

        if (_nftType == 0) {
            // golden egg
            // require(
            //     _goldenList[msg.sender] == true || owner() == msg.sender,
            //     "Only Golden Users can mint"
            // );
            require(
                _goldenNftMintedCount + _mintAmount <= MAX_GOLDEN_COUNT,
                "Overflow of golden eggs"
            );
            
            emit EggType("GoldenEgg", msg.sender);
        } else {
            require(
                _goodNftMintedCount + _evilNftMintedCount + _mintAmount <=
                    (MAX_SUPPLY - MAX_GOLDEN_COUNT),
                "Overflow of total of the golden or evil eggs"
            );


            if (_nftType == 1) {
                // good egg
                require(
                    _goodNftMintedCount + _mintAmount <=
                        MAX_GOOD_OR_EVIL_COUNT ||
                        _evilNftMintedCount <= MAX_GOOD_OR_EVIL_COUNT,
                    "Overflow of 4500 good eggs"
                );
                
                emit EggType("GoodEgg", msg.sender);
            } else {
                // evil egg
                require(
                    _evilNftMintedCount + _mintAmount <=
                        MAX_GOOD_OR_EVIL_COUNT ||
                        _goodNftMintedCount <= MAX_GOOD_OR_EVIL_COUNT,
                    "Overflow of 4500 good eggs"
                );
                 emit EggType("EvilEgg", msg.sender);
                
            }
        }

        //calculate minted count
        if (mintType == 0) {
            require(isOgUser(_merkleProof) == true, "Not registry at OG list");
            require(
                _ogMintedCountList[msg.sender] + _mintAmount <= ogLimit,
                "Overflow of your eggs"
            );
            currentPrice = ogPrice;
            _ogMintedCountList[msg.sender] += _mintAmount;
        } else if (mintType == 1) {
            require(isWlUser(_merkleProof) == true, "Not registry at WL list");
            require(
                _wlMintedCountList[msg.sender] + _mintAmount <= wlLimit,
                "Overflow of your eggs"
            );
            currentPrice = wlPrice;
            _wlMintedCountList[msg.sender] += _mintAmount;
        } else {
            require(
                _plMintedCountList[msg.sender] + _mintAmount <= plLimit,
                "Overflow of your eggs"
            );
            currentPrice = plPrice;
            _plMintedCountList[msg.sender] += _mintAmount;
        }

        currentPrice = currentPrice * _mintAmount;

        require(msg.value >= currentPrice, "Not Enough Money");

        uint256 idx;

        for (idx = 0; idx < _mintAmount; idx++) {
            if(_nftType == 0){
                _uriToTokenId[_nftMintedCount+1+idx] = _goldenNftMintedCount + idx;
            }
            else if(_nftType == 1){
                _uriToTokenId[_nftMintedCount+1+idx] = 7 + _goodNftMintedCount + idx;
            }
            else{
                _uriToTokenId[_nftMintedCount+1+idx] = 4500 + _evilNftMintedCount + idx;
            }
            _safeMint(msg.sender, _nftMintedCount);
            // _nftMintedCount++;
        }
        _nftMintedCount = _nftMintedCount + _mintAmount;
        if(_nftType == 0){
            _goldenNftMintedCount += _mintAmount;
        }
        else if (_nftType == 1){
            _goodNftMintedCount += _mintAmount;
        }
        else{
            _evilNftMintedCount += _mintAmount;
        }
    }

    function getMintedCount() external view returns (uint256) {
        return _nftMintedCount;
    }

    function getGoodMintedCount() external view returns (uint256) {
        return _goodNftMintedCount;
    }

    function getEvilMintedCount() external view returns (uint256) {
        return _evilNftMintedCount;
    }

    // function getPrice() external view returns (uint256) {
    //     uint256 currentPrice = 0;
    //     if (_ogList[msg.sender] == true) {
    //         currentPrice = ogPrice;
    //     } else if (_wlList[msg.sender] == true) {
    //         currentPrice = wlPrice;
    //     } else {
    //         currentPrice = plPrice;
    //     }
    //     return currentPrice;
    // }
}