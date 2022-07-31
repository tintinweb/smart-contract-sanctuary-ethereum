// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Strings.sol";
import "./Base64.sol";
import "./Counters.sol";

contract CryptoMarmutContract is Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;

    Counters.Counter private currentTokenId;
    uint256 internal _gen0Counter;
    //uint256 public constant CREATION_LIMIT_GEN0 = 10000;
    string private _currentBaseURI;

    struct Marmut {
        string genes;
        uint32 idDad;
        uint32 idMom;
        uint32 generation;
        uint64 birthDateTime;
        uint16 gender;
        uint64 breedCount;
        uint64 maxBreedCount;
        string jsonData;
    }

    mapping(uint256 => Marmut) id_to_marmut;

    constructor() ERC721("CryptoMarmut - NFT", "Xor Pointer") {
        /*
        01    02     03     08      01   01       1    05        03  08
        Tail Mouth  Accent wings   Env  EyeShape Body Eyecolor  Base horn     
        */
        // setBaseURI(
        //     "https://cryptomarmut-api-hqn4ypf4ia-uc.a.run.app/api/token/"
        // );
        //mint("0301010000011011500", 0, 0, 0, 0, 1000);
        //mint("1501020000061060100", 0, 0, 0, 1, 1000);
    }

    // function setBaseURI(string memory baseURI) public onlyOwner {
    //     _currentBaseURI = baseURI;
    // }

    // function _baseURI() internal view virtual override returns (string memory) {
    //     return _currentBaseURI;
    // }

    function getMarmut(uint256 _idMarmut)
        external
        view
        returns (
            uint256 idMarmut,
            string memory genes,
            uint32 idDad,
            uint32 idMom,
            uint32 generation,
            uint64 birthDateTime,
            uint16 gender,
            uint64 breedCount,
            uint64 maxBreedCount,
            address owner,
            string memory jsonData
        )
    {
        require(_exists(_idMarmut), "Token not found");
        Marmut storage marmut = id_to_marmut[_idMarmut];

        idMarmut = _idMarmut;
        genes = marmut.genes;
        idDad = marmut.idDad;
        idMom = marmut.idMom;
        generation = marmut.generation;
        birthDateTime = marmut.birthDateTime;
        gender = marmut.gender;
        breedCount = marmut.breedCount;
        maxBreedCount = marmut.maxBreedCount;
        jsonData = marmut.jsonData;
        owner = ownerOf(_idMarmut);
    }

    function getMarmutsOf(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        // get the number of marmuts owned by _owner
        uint256 ownerCount = balanceOf(_owner);
        if (ownerCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory ids = new uint256[](ownerCount);
        uint256 i = 1;
        uint256 count = 0;
        while (count < ownerCount || i < totalSupply()) {
            if (ownerOf(i) == _owner) {
                ids[count] = i;
                count += 1;
            }
            i += 1;
        }

        return ids;
    }

    function getMarmutsForSale() public view returns (uint256[] memory) {
        uint256 ownerCount = balanceOf(owner());
        if (ownerCount == 0) {
            return new uint256[](0);
        }

        uint256[] memory ids = new uint256[](ownerCount);
        uint256 i = 1;
        uint256 count = 0;
        while (count < ownerCount || i < totalSupply()) {
            if (ownerOf(i) == owner()) {
                ids[count] = i;
                count += 1;
            }
            i += 1;
        }

        return ids;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token not found");
        Marmut storage marmut = id_to_marmut[tokenId];
        string memory json = Base64.encode(
            bytes(string(abi.encodePacked(marmut.jsonData)))
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    event GenerateMarmutEvent(
        uint256 idMarmut,
        uint256 idDad,
        uint256 idMom,
        string genes,
        uint256 _gender,
        uint256 breedCount,
        uint256 maxBreedCount,
        address owner
    );

    function createMarmutGen0(
        string memory _genes,
        uint256 _gender,
        uint256 _maxBreed,
        string memory _jsonData,
        uint256 _nextId
    ) public onlyOwner returns (uint256) {
        require(_exists(_nextId) == false, "Token is already taken");

        _gen0Counter += 1;
        uint256 numToken = currentTokenId.current();

        mint(_genes, 0, 0, 0, uint16(_gender), _maxBreed, _jsonData);
        return numToken + 1;
    }

    function getGen0Count() public view returns (uint256) {
        return _gen0Counter;
    }

    function _createMarmut(
        uint256 _idDad,
        uint256 _idMom,
        uint256 _generation,
        string memory _genes,
        uint256 _gender,
        uint256 _maxBreedCount,
        address _owner,
        string memory _jsonData
    ) internal returns (uint256) {
        Marmut memory marmut = Marmut({
            genes: _genes,
            idDad: uint32(_idDad),
            idMom: uint32(_idMom),
            generation: uint32(_generation),
            birthDateTime: uint64(block.timestamp),
            gender: uint16(_gender),
            breedCount: 0,
            maxBreedCount: uint64(_maxBreedCount),
            jsonData: _jsonData
        });

        currentTokenId.increment();
        uint256 newMarmutId = currentTokenId.current();
        id_to_marmut[newMarmutId] = marmut;

        emit GenerateMarmutEvent(
            newMarmutId,
            _idDad,
            _idMom,
            _genes,
            _gender,
            0,
            _maxBreedCount,
            _owner
        );

        _safeMint(_owner, newMarmutId);

        return newMarmutId;
    }

    function mint(
        string memory _genes,
        uint256 _idDad,
        uint256 _idMom,
        uint256 _generation,
        uint256 _gender,
        uint256 _maxBreedCount,
        string memory _jsonData
    ) internal {
        Marmut memory marmut = Marmut({
            genes: _genes,
            idDad: uint32(_idDad),
            idMom: uint32(_idMom),
            generation: uint32(_generation),
            birthDateTime: uint64(block.timestamp),
            gender: uint16(_gender),
            breedCount: uint64(0),
            maxBreedCount: uint64(_maxBreedCount),
            jsonData: _jsonData
        });

        currentTokenId.increment();
        uint256 newMarmutId = currentTokenId.current();
        id_to_marmut[newMarmutId] = marmut;

        _safeMint(msg.sender, newMarmutId);
    }

    function breed(
        uint256 _idDad,
        uint256 _idMom,
        string memory _childGenes,
        uint256 _gender,
        uint256 _maxBreedCount,
        string memory _jsonData,
        uint256 _nextId
    ) external payable returns (uint256) {
        require(msg.value == 0.01 ether, "Breeding costs 10 finney");
        Marmut storage dad = id_to_marmut[_idDad];
        Marmut storage mom = id_to_marmut[_idMom];

        require(_exists(_nextId) == false, "Token is already taken");
        //require(_eligibleToBreed(dad, mom), "the token not eligible");

        dad.breedCount += 1;
        mom.breedCount += 1;

        uint256 childId = _createMarmut(
            _idDad,
            _idMom,
            dad.generation + 1,
            _childGenes,
            _gender,
            _maxBreedCount,
            msg.sender,
            _jsonData
        );

        if (childId > 0) {
            payable(owner()).transfer(0.01 ether);
        }

        return childId;
    }

    function isMarmutOwner(uint256 tokenId) public view returns (bool) {
        return msg.sender == ownerOf(tokenId);
    }

    function getCurrentId() public view returns (uint256) {
        return currentTokenId.current();
    }

    function getNextId() public view returns (uint256) {
        return currentTokenId.current() + 1;
    }
}