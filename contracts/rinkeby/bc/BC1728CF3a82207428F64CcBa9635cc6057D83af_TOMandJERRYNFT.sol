pragma solidity ^0.8.2;

contract TOMandJERRYNFT{
    string public name;
    string public symbol;

    uint256 public _tokenId;
    mapping(uint256 => address) private _owner;
    mapping(uint256 => string) private _tokenURI;
    mapping(address => uint256) private _balances;

    event Transfer(address _from, address _to, uint256 _tokenId);

    constructor(string memory _name, string memory _symbol){
        name = _name;
        symbol = _symbol;
    }

    // return URI point to metadata
    function tokenURI(uint256 tokenId) public view returns(string memory){
        require(_owner[tokenId] != address(0), "No one own this token, token does not have URI");
        return _tokenURI[tokenId];
    }  

    // function mint(address to, string memory token_URI) public {
    //     _tokenId += 1;
    //     _balances[to] += 1;
    //     _owner[_tokenId] = to;
    //     _tokenURI[_tokenId] = token_URI;

    //     emit Transfer(address(0), to, _tokenId);
    // }

    function mint( string memory token_URI) public {
        _tokenId += 1;
        _balances[msg.sender] += 1;
        _owner[_tokenId] = msg.sender;
        _tokenURI[_tokenId] = token_URI;

        emit Transfer(address(0), msg.sender, _tokenId);
    }

    function burn(uint256 tokenId)public{
        address owner = _owner[tokenId];
        require(msg.sender == owner, "Caller is not owner of the token" );
        //clear approval
        _balances[owner] -= 1;
        delete _owner[tokenId];

        emit Transfer(owner, address(0), tokenId);

    }
    function supportsInterface(bytes4 interfaceId) public pure returns (bool){
        return interfaceId == 0x80ac58cd;
    }

}