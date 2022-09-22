// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract Speed is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Speed", "SPE") {}

    struct Car{
        address owner;
        uint token;         
        uint carType;     
        uint engine;        
        uint os;            
        uint driverOS;      
        string modelUri;    
        uint[] technology;    
        uint[] extereior;   
    }

    mapping(address=>Car[])  ownerCars;
    Car[] cars;

    function _baseURI() internal pure override returns (string memory) {
        return "https://speedfi.oss-cn-shenzhen.aliyuncs.com/";
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    event CreateCarLog(address,uint256);
    function CreateCar(address _to,string memory _uri,uint _carType,uint _engine,uint[] calldata _technology,uint[] calldata _exterior,uint _os,uint _driverOs,string memory _modelUri)  public onlyOwner returns (uint256){
        Car memory c;
        c.carType = _carType;
        c.engine = _engine;
        c.os = _os;
        c.driverOS = _driverOs;
        c.technology = _technology;
        c.extereior = _exterior;
        _tokenIdCounter.increment();
        uint256 _tokenId = _tokenIdCounter.current();
        c.token = _tokenId;
        c.owner = _to;
        c.modelUri = _modelUri;
        ownerCars[_to].push(c);
        cars.push(c);
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
        emit CreateCarLog(_to,_tokenId);
        return (_tokenId);
    }

    

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function getByOwner(address _owner) external view returns(uint[] memory) {
        uint[] memory result = new uint[](balanceOf(_owner));
        uint counter = 0;
        for (uint i = 1; i <= _tokenIdCounter.current(); i++) {
            if (ownerOf(i) == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function getCar(address _owener,uint nftId ) external view returns (uint256 token ,uint256 carType,uint256 engine,uint256 os,uint256 driverOS,string memory uri,string memory modelUri ,uint[] memory  technology,uint[] memory extereior){
        Car[] memory  cs = ownerCars[_owener];
        require(cs.length > 0, "Did not own cars");
        uri = tokenURI(nftId);
        for (uint i=0;i<cs.length;i++){
            Car memory tmpCar = cars[i];
            if (tmpCar.token == nftId){    
                 string memory base = _baseURI();
                 tmpCar.modelUri = string(abi.encodePacked(base, tmpCar.modelUri));
                return (tmpCar.token,tmpCar.carType,tmpCar.engine,tmpCar.os,tmpCar.driverOS,uri,tmpCar.modelUri,tmpCar.technology,tmpCar.extereior);
            }
        }
        revert("Did not own cars!");
    }
   
}