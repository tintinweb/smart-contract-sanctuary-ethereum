// SPDX-License-Identifier: GPLv3
// Developed by: @joevidev
// v1.0.0

pragma solidity ^0.8.10;

import './ERC721Connector.sol';

contract IzineyNFT is ERC721Connector {

    string[] public IzineyNFTS;

    mapping(string => bool) _izineyNFTExists;

    function mint(string memory _iziney) public {

        require(!_izineyNFTExists[_iziney], 'Error - token already exists');

        IzineyNFTS.push(_iziney);
        uint _id = IzineyNFTS.length -1;

        _mint(msg.sender, _id);

        _izineyNFTExists[_iziney] = true;
    }

    constructor() ERC721Connector('Iziney','IZIN') {}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library SafeMath {
    // sumar: r = x + y
    function add(uint256 x , uint256 y) internal pure returns(uint256) {
        uint256 r = x + y;
        require(r >= x, 'Safemath: addition overflow');
        return r;
    }

    function sub(uint256 x , uint256 y) internal pure returns(uint256) {
        require(y <= x, 'Safemath: subtraction overflow');
        uint256 r = x - y;
        return r;
    }

    // optmimzar uso de gas en multiplicacion
    function mul(uint256 x , uint256 y) internal pure returns(uint256) {
        // gas optimization
        if(x == 0) {
            return 0;
        }

        uint256 r = x * y;
        require(r / x == y, 'SafeMath: multiplication overflow');
        return r;
    }

    function divide(uint256 x, uint256 y) internal pure returns(uint) {
        require(y > 0, 'SafeMath: division by zero');
        uint256 r = x / y;
        return r;  
    }

    //el gasto de gas se mantiene intacto
    function mod(uint256 x, uint256 y) internal pure returns(uint) {
        require(y != 0, 'Safemath: modulo by zero');
        return x % y;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './SafeMath.sol';

library Counters {
    using SafeMath for uint256;

    struct Counter {
        uint256 _value;    
    }

    //definir donde nos encontramos
    function current(Counter storage counter ) internal view returns(uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


interface IERC721Metadata {

    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC721Enumerable {
   
    function totalSupply() external view returns (uint256);

    function tokenByIndex(uint256 _index) external view returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IERC721 {
    event Transfer (
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    function balanceOf(address _owner) external view returns (uint256);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function transferFrom(address _from, address _to, uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './interfaces/IERC721Metadata.sol';
import './ERC165.sol';

contract ERC721Metadata is IERC721Metadata, ERC165 {

    string private _name;
    string private _symbol;

    constructor(string memory named, string memory symbolified) {

        _registerInterface(bytes4(keccak256('name(bytes4)')^
        keccak256('symbol(bytes4)')));

        _name = named;
        _symbol = symbolified;
    }

    function name() external view returns(string memory) {
        return _name;
    }
   
    function symbol() external view returns(string memory) {
        return _symbol;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './ERC721.sol';
import './interfaces/IERC721Enumerable.sol';

contract ERC721Enumerable is IERC721Enumerable,ERC721 {

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(address => uint256[]) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;


    constructor() {
        _registerInterface(bytes4(keccak256('totalSupply(bytes4)')^
        keccak256('tokenByIndex(bytes4)')^keccak256('tokenOfOwnerByIndex(bytes4)')));
    }

    function _mint(address to, uint256 tokenId) internal override(ERC721){
        super._mint(to, tokenId);
        _addTokensToOwnerEnumeration(to, tokenId);
         _addTokensToAllTokenEnumeration(tokenId);
    }

    function _addTokensToAllTokenEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _addTokensToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    function tokenByIndex(uint256 index) public override view returns(uint256) {
        require(index < totalSupply(), 'Global index out of bounds');
        return _allTokens[index];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public override view returns(uint256) {
        require(index < balanceOf(owner), 'Owner index out of bounds');
        return _ownedTokens[owner][index];
    }

    function totalSupply() public override view returns(uint256) {
        return _allTokens.length;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import './ERC721Metadata.sol';
import './ERC721Enumerable.sol';

contract ERC721Connector is ERC721Metadata, ERC721Enumerable {

    constructor(string memory name, string memory symbol) ERC721Metadata(name, symbol){

    }
}

// SPDX-License-Identifier: GPLv3
// Developed by: @joevidev
// v1.0.0

pragma solidity ^0.8.10;

import './ERC165.sol';
import './interfaces/IERC721.sol';
import './libraries/Counters.sol';

contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256; 
    using Counters for Counters.Counter;


    mapping(uint256 => address) private _tokenOwner;

    mapping(address => Counters.Counter) private _ownedTokensCount;

    mapping(uint256 => address) private _tokenApprovals;


    constructor() {
        _registerInterface(bytes4(keccak256('balanceOf(bytes4)')^
        keccak256('ownerOf(bytes4)')^keccak256('transferFrom(bytes4)')));
    }


    function balanceOf(address _owner) public override view returns (uint256){
        require (_owner != address(0), 'Address is zero');
        return _ownedTokensCount[_owner].current();
    }

    function ownerOf(uint256 _tokenId) public override view returns (address){
        address owner = _tokenOwner[_tokenId];
        require (owner != address(0), 'Address is zero');
        return owner;
    }

    function _exists(uint256 tokenId) internal view returns(bool){
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), 'ERC721 minting to zero address');
        require(!_exists(tokenId), 'ERC721 already exists');

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }


    function _transferFrom(address _from, address _to, uint256 _tokenId) internal {
        require(_to != address(0), 'Error - ERC721 Transfer to the zero address');
        require(ownerOf(_tokenId) == _from, 'Trying to transfer a token the address does not own!');

        _ownedTokensCount[_from].decrement();
        _ownedTokensCount[_to].increment();

        _tokenOwner[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }


    function transferFrom(address _from, address _to, uint256 _tokenId) override public {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _transferFrom(_from, _to, _tokenId);
    }


    function approve(address _to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(_to != owner, 'Error - approval to current owner');
        require(msg.sender == owner, 'Current caller must be owner');
        _tokenApprovals[tokenId] = _to;
        emit Approval(owner, _to, tokenId);
    }

    function isApprovedOrOwner(address spender, uint256 tokenId) internal view returns(bool){
        require(_exists(tokenId), 'token does not exist');
        address owner = ownerOf(tokenId);
        return(spender == owner); 
    }
    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import './interfaces/IERC165.sol';

contract ERC165 is IERC165 {

    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        _registerInterface(bytes4(keccak256('supportsInterface(bytes4)')));
    }

    function supportsInterface(bytes4 interfaceID) external view override returns (bool) {
        return _supportedInterfaces[interfaceID];
    }

    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, 'Invalid interface request');
        _supportedInterfaces[interfaceId] = true;
    }

}