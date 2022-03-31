// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155URIStorage.sol";

interface IERC1155  {
  
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);  
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) external;
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external;
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);
    function setApprovalForAll(address _operator, bool _approved) external;
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


contract MultiToke is IERC1155, ERC1155URIStorage {
    
    mapping(uint256 =>  mapping(address => uint256)) private balances;

    mapping(address => mapping(address => bool)) private operatorApprovals;


    constructor () {

    }


    function balanceOf(address owner,uint256 id) public view virtual override returns(uint256) {
        require(owner != address(0),"ERC1155: Owner address belongs to zero address");
        return balances[id][owner];
    }
    
    function balanceOfBatch(address[] calldata owners,uint256[] calldata ids) public view virtual override returns (uint256[] memory){
        require(owners.length == ids.length, "ERC1155: accounts and id's length not matched");
        uint256[] memory accountsBalance = new uint256[](owners.length);

        for(uint256 i = 0; i<owners.length ; i++){
            accountsBalance[i]=balanceOf(owners[i], ids[i]);
        }

        return accountsBalance;
    }

    function isApprovedForAll(address owner,address operator) public view virtual override returns (bool) {
        return operatorApprovals[owner][operator];
    }

    function setApprovalForAll(address operator,bool approved) public override {
        require(operator != msg.sender, "ERC1155: No need of approval for own self");
        require(operator != address(0), "ERC1155: Approval for zero address");

        operatorApprovals[msg.sender][operator]= approved;
    }


    function _safeTransferFrom(address from, address to, uint256 id, uint256 value) internal virtual{
        require(to != address(0), "ERC1155: Transfring to zero address");

        require(balanceOf(from, id) >= value, "ERC1155:  insufficient balance for transfer");

        unchecked {
            balances[id][from] -= value;
        }
        balances[id][to] += value;

        emit TransferSingle(msg.sender, from, to, id, value);
    }



    function safeTransferFrom(address from,address to,uint256 id,uint256 value) public virtual override {
        require((msg.sender == from || isApprovedForAll(from, msg.sender)), "ERC1155: You're not allowed to transfer tokens");

        _safeTransferFrom(from, to, id, value);
    }

    function safeBatchTransferFrom(address from,address to,uint256[] calldata ids,uint256[] calldata values) public override{
        require(ids.length == values.length, "ERC1155: Values and Id's length don't matched!");
        require(to != address(0), "ERC1155: Transfring to zero address");

        require((msg.sender == from || isApprovedForAll(from, msg.sender)), "ERC1155: You're not allowed to transfer tokens");

        for(uint256 i = 0; i < ids.length; i++){
            _safeTransferFrom(from, to, ids[i], values[i]);
        }
        
        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    function mint(address to, uint256 id, uint256 tokens, string memory uri) public virtual {
        require(address(0) != to, "ERC1155: Minting to zero address");
    
        balances[id][to] += tokens;

        if(bytes(uri).length > 0){
            setTokenURI(id, uri);
        }

        emit TransferSingle(msg.sender, address(0), to, id, tokens);
    }

    function burn(address from, uint256 id, uint256 tokens) public virtual {
        require(address(0) != from, "ERC1155: Minting to zero address");
    
        uint256 fromBalance = balances[id][from];
        require(fromBalance >= tokens, "ERC1155: burn amount exceeds balance");
        unchecked {
            balances[id][from] = fromBalance - tokens;
        }
       
       emit TransferSingle(msg.sender,from ,address(0), id, tokens);
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata tokens) public virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == tokens.length, "ERC1155: ids and amounts length mismatch");


        for (uint256 i = 0; i < ids.length; i++) {
            balances[ids[i]][to] += tokens[i];
        }

        emit TransferBatch(msg.sender, address(0), to, ids, tokens);
    }

    function burnBatch(address from, uint256[] calldata ids, uint256[] calldata tokens) public virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == tokens.length, "ERC1155: ids and amounts length mismatch");

         for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = tokens[i];

            uint256 fromBalance = balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, tokens);

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155URIStorage {
    function setBaseURI(string memory tokenBaseURI) external;
    function getBaseURI() external view returns (string memory);
    
    function getTokenURI(uint256 tokenId) external view returns (string memory);
    function setTokenURI(uint256 tokenId, string memory tokenURI) external;
}

abstract contract ERC1155URIStorage is IERC1155URIStorage{
    string  private  baseURI = "";

    mapping (uint256 => string) tokenURIs;

    function setBaseURI(string memory tokenBaseURI) public virtual override {
        require(bytes(tokenBaseURI).length > 0, "ERC1155: You're not allowed to set empty data as base URI");
        baseURI = tokenBaseURI;
    }

    function getBaseURI() public view virtual override returns (string memory){
        return baseURI;
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public virtual override{
        require(bytes(tokenURI).length > 0, "ERC1155: You're not allowed to set empty data as base URI");
        tokenURIs[tokenId] = tokenURI;
    }

    function getTokenURI(uint256 tokenId) public view virtual override returns(string memory){
        require(bytes(tokenURIs[tokenId]).length > 0, "ERC1155: No token's URI found");
        return tokenURIs[tokenId];
    }

}