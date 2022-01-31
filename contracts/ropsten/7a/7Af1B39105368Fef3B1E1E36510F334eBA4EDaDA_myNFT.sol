//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract myNFT is Ownable{

    using Counters for Counters.Counter;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    Counters.Counter private _tokenID;

    mapping(uint256 => string) private _tokenURIs;
    string internal baseURI;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) _tokenApprovals;

    function init(string memory Name,string memory Symbol) public{
        _name = Name;
        _symbol =Symbol;
        initializeOwner(msg.sender);
    }
    function name() public view returns(string memory){
        return _name;
    }

    function symbol() public view returns(string memory){
        return _symbol;
    }

  function balanceOf(address owner) public view  returns (uint256) {
        require(owner != address(0), "Balance query for the zero address");
        return _balances[owner];
    }

/*Sets TokenURI */
    function _setTokenURI(uint256 tokenID, string memory toknURI) internal {
        require(_exists(tokenID), "Can not add URI to non existent token");

        _tokenURIs[tokenID] = toknURI; 
    }
/*Returns Base URI */
    function _baseURI() internal view returns(string memory){
        return baseURI;
    }
/*this function setBaseURI  only owner can change the base URI*/
    function setBaseURI(string memory base) public onlyOwner{
        baseURI = base;
    }

    function tokenURI(uint256 tokenID) public view returns(string memory){
        require(_exists(tokenID)," Query for non existent token");

        string memory _tokenURI = _tokenURIs[tokenID];
        string memory base = _baseURI();


        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return bytes(base).length>0 ? string(abi.encodePacked(base, tokenID.toString())) : "" ;
    }

/**Mints single token */
    function mint(address to, string memory uri) public onlyOwner {
        require(to != address(0), "Cannot mint to address(0)");
        
        _tokenID.increment();
        uint256 tokenID = _tokenID.current();
        _mint(to, tokenID);
        _setTokenURI(tokenID, uri);
    }

    function _exists(uint256 tokenID) internal view returns(bool){
        return _owners[tokenID] != address(0);
    }

/**Mint tokens in Batch with giving URI as an array */
    function mintBatch(address to, string[] memory batch) public{
        for(uint256 i = 0; i < batch.length; i++){
            _tokenID.increment();
            uint256 tokenID = _tokenID.current();
            _mint(to,tokenID);
            _setTokenURI(tokenID, batch[i]);
        }
    }

    function _mint(address to, uint256 tokenID) internal virtual {
        require(to != address(0), "Cannot mint to address(0)");
        require(!_exists(tokenID), "tokenId already exists");
        
        _balances[to] += 1;
        _owners[tokenID] = to;

        //emit Transfer(address(0), to, tokenID);
    }

    function ownerOf(uint256 tokenId) public view  returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "owner query for nonexistent token");
        return owner;
    }


    function burn(uint256 tokenID) public onlyOwner{
        _burn(tokenID);
    }

    function _burn(uint256 tokenID) internal {
        
        address _owner = ownerOf(tokenID);
        _balances[_owner] -= 1;
        delete _owners[tokenID];

        //emit Transfer(owner,address(0),tokenID);
    }

    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "approval to current owner");
        require( msg.sender == owner,  "approve caller is not owner");

        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        //emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function transferFrom(address from, address to,  uint256 tokenId) public {
       
        require(getApproved(tokenId) == msg.sender || ownerOf(tokenId) == msg.sender, "transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function transferFrom( address to,  uint256 tokenId) public {
       
        require(ownerOf(tokenId) == msg.sender, "transfer caller is not owner ");

        _transfer(msg.sender, to, tokenId);
    }

      function _transfer(address from,address to,uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "transfer from incorrect owner");
        require(to != address(0), "transfer to the zero address");

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        //emit Transfer(from, to, tokenId);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

contract Ownable{
    address internal owner;


    function initializeOwner(address _owner) internal{
        owner = _owner;
    }

    event ownerTransferred(address _oldOwner,address _newOwner);

    modifier onlyOwner(){
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner !=  address(0), "Cannot make address(0) a owner");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner ) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit ownerTransferred(oldOwner, newOwner);
    }

    function getOwner() public view returns(address) {
        return owner;
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