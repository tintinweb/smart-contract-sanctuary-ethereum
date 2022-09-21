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
    uint256 public constant MAX_TOKENS = 2929;
    string private _externalUrl = "https://cryptomarmut.app/token/";
    string private _imageUrl =
        "https://firebasestorage.googleapis.com/v0/b/cryptomarmut.appspot.com/o/";

    struct Marmut {
        string genes;
        uint32 idDad;
        uint32 idMom;
        uint32 generation;
        uint64 birthDateTime;
        uint16 gender;
        uint64 breedCount;
        uint64 maxBreedCount;
        string attributes;
    }

    mapping(uint256 => Marmut) id_to_marmut;

    constructor() ERC721("CryptoMarmut - Official", "Xor Pointer") {}

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
            string memory attributes
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
        attributes = marmut.attributes;
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
        string[6] memory parts;
        string memory id = Strings.toString(tokenId);

        parts[0] = string(abi.encodePacked('{"name":"', "Marmut #", id, '",'));
        parts[
            1
        ] = '"description":"Cute little animal that can breed and made into adorable collections. Visit https://cryptomarmut.app",';
        parts[2] = string(
            abi.encodePacked('"external_url":"', _externalUrl, id, '",')
        );
        parts[3] = string(
            abi.encodePacked(
                '"image":"',
                _imageUrl,
                marmut.genes,
                '.png?alt=media",'
            )
        );

        parts[4] = marmut.attributes;
        parts[5] = "}";

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        parts[0],
                        parts[1],
                        parts[2],
                        parts[3],
                        parts[4],
                        parts[5]
                    )
                )
            )
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
        string memory _attributes
    ) public onlyOwner returns (uint256) {
        require(totalSupply() < MAX_TOKENS, "Limit exceeded");

        _gen0Counter += 1;
        uint256 numToken = currentTokenId.current();

        mint(_genes, 0, 0, 0, uint16(_gender), _maxBreed, _attributes);
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
        string memory _attributes
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
            attributes: _attributes
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
        string memory _attributes
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
            attributes: _attributes
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
        string memory _attributes
    ) external payable returns (uint256) {
        require(totalSupply() < MAX_TOKENS, "Limit exceeded");
        require(msg.value == 0.01 ether, "Mint costs 10 finney");

        Marmut storage dad = id_to_marmut[_idDad];
        Marmut storage mom = id_to_marmut[_idMom];

        dad.breedCount += 1;
        mom.breedCount += 1;

        uint256 _generation = _idDad == 0 ? 0 : dad.generation + 1;

        uint256 marmutId = _createMarmut(
            _idDad,
            _idMom,
            _generation,
            _childGenes,
            _gender,
            _maxBreedCount,
            msg.sender,
            _attributes
        );

        if (marmutId > 0) {
            payable(owner()).transfer(0.01 ether);
        }

        return marmutId;
    }

    function setExternalUrl(string memory externalUrl) public onlyOwner {
        _externalUrl = externalUrl;
    }

    function setImageUrl(string memory imageUrl) public onlyOwner {
        _imageUrl = imageUrl;
    }

    function isMarmutOwner(uint256 tokenId) public view returns (bool) {
        return msg.sender == ownerOf(tokenId);
    }

    function getCurrentId() public view returns (uint256) {
        return currentTokenId.current();
    }
}