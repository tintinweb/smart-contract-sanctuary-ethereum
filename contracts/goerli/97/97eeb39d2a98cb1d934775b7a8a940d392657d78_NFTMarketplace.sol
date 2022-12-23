// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Counter.sol";
import "./ERC721Token.sol";
import "./ERC20Token.sol";

contract NFTMarketplace {
    //get instance of deployed ERC20 and ERC721 token
    ERC20Token private erc20 =
        ERC20Token(0x21b7E543039c7d5eE82816873F8f1CED92a6B36D);
    ERC721Token private nft =
        ERC721Token(0xC77DAabc14A2366326D7Ab16fEcEB6A981046Ca1);

    // Store a mapping of NFT ID to the NFT's metadata
    struct ListedNFT {
        uint nftId;
        uint price;
        string metadata;
    }
    mapping(uint256 => ListedNFT) public nftInfo;

    // Store a list of all NFTs that are for sale
    mapping(uint256 => bool) forSale;

    // Event for when an NFT is listed for sale
    event NFTListed(uint indexed _nftId);

    // Event for when an NFT is purchased
    event NFTPurchased(
        uint indexed _nftId,
        address indexed _buyer,
        uint _price
    );

    // List an NFT for sale
    function listForSale(
        uint _nftId,
        uint _price,
        string memory _metadata
    ) public {
        require(
            nft.holderOf(_nftId) == msg.sender,
            "Only the owner can list an NFT for sale"
        );
        require(_price > 0, "Price must be greater than 0");
        require(bytes(_metadata).length > 0, "Metadata cannot be empty");
        require(forSale[_nftId] == false, "Already listed");

        // Update the NFT's metadata
        nftInfo[_nftId] = ListedNFT(_nftId, _price, _metadata);

        // Add the NFT to the list of those for sale
        forSale[_nftId] = true;

        // Emit the NFTListed event
        emit NFTListed(_nftId);
    }

    // Purchase an NFT
    function purchase(uint _nftId) public {
        require(forSale[_nftId] != false, "NFT is not for sale");
        require(
            nft.holderOf(_nftId) != msg.sender,
            "Cannot purchase your own NFT"
        );

        require(
            erc20.balanceOf(msg.sender) >= nftInfo[_nftId].price,
            "Insufficient balance"
        );
        // Check if the buyer has approved the transfer of the required amount of tokens
        require(
            erc20.allowance(msg.sender, address(this)) >= priceOf(_nftId),
            "Insufficient token allowance"
        );

        // Get the seller's address
        address seller = nft.holderOf(_nftId);

        // Transfer ownership of the NFT to the buyer
        nft.transferFrom(seller, msg.sender, _nftId);

        // Remove the NFT from the list of those for sale
        forSale[_nftId] = false;
        delete nftInfo[_nftId];

        // Transfer the purchase price from the buyer to the seller in the custom ERC20 token
        erc20.transferFrom(msg.sender, seller, priceOf(_nftId));

        // Emit the NFTPurchased event
        emit NFTPurchased(_nftId, msg.sender, priceOf(_nftId));
    }

    // Get the price of an NFT
    function priceOf(uint _nftId) public view returns (uint) {
        return nftInfo[_nftId].price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

//Adapted from Openzeppelin's counter
library Counters {
    struct Counter {
        uint256 _value;
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
pragma solidity ^0.8.2;

import "./Counter.sol";

contract ERC721Token {
    address private owner;
    string private name;
    string private symbol;
    uint private immutable MAX_SUPPLY;
    uint private currentSupply;

    using Counters for Counters.Counter;
    //NFT id counter
    Counters.Counter private _tokenIdCounter;

    // Mapping keeping track of balances of addresses
    mapping(address => uint) private balances;
    // Mapping from token ID to owner address
    mapping(uint256 => address) private holders;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private tokenApprovals;
    // Mapping for token URIs
    mapping(uint256 => string) private tokenURIs;

    // Main events including Mint, Burn, Transfer, Approve
    event tokenMinted(address _to, uint _tokenId);
    event tokenBurned(address _from, uint _tokenId);
    event Transfer(address _from, address _to, uint _tokenId);
    event Approval(address _from, address _to, uint _tokenId);

    /**
     * @dev Modifier restricting access to only owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call method");
        _;
    }

    /**
     * @dev Modifier restricting access to only holder
     */
    modifier onlyHolder(uint _tokenId) {
        require(msg.sender == holders[_tokenId], "Only holder can call method");
        _;
    }

    /**
     * @dev Modifier restricting access to only holder or approved account
     */
    modifier onlyHolderOrApproved(uint _tokenId) {
        require(
            msg.sender == tokenApprovals[_tokenId] ||
                msg.sender == holders[_tokenId],
            "Only holder or approved can call method"
        );
        _;
    }

    constructor(string memory _name, string memory _symbol, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        MAX_SUPPLY = _totalSupply;
    }

    /**
     * @dev Returns the name of the token.
     */
    function getName() public view returns (string memory) {
        return name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function getSymbol() public view returns (string memory) {
        return symbol;
    }

    /**
     * @dev Returns the owner of the token
     */
    function getOwner() public view returns (address) {
        return owner;
    }

    /**
     * @dev Function allows the owner to issue new token to specified address.
     */
    function mintToken(address _to, uint _amount) public onlyOwner {
        require(_amount > 0, "Must mint at least 1 NFT");
        require(_to != address(0), "ERC721: mint to the zero address");
        require(
            _tokenIdCounter.current() + _amount <= MAX_SUPPLY,
            "Cannot mint more than total supply"
        );
        currentSupply += _amount;
        for (uint256 i = 0; i < _amount; i++) {
            _tokenIdCounter.increment();
            uint256 tokenId = _tokenIdCounter.current();
            _mint(_to, tokenId);
            emit tokenMinted(_to, tokenId);
        }
    }

    /**
     * @dev Function allows anyone to burn an amount of their token.
     */
    function burnToken(uint _tokenId) public onlyHolderOrApproved(_tokenId) {
        address holder = holders[_tokenId];

        delete holders[_tokenId];
        unchecked {
            currentSupply -= 1;
            balances[holder] -= 1;
        }
        if (bytes(tokenURIs[_tokenId]).length != 0) {
            delete tokenURIs[_tokenId];
        }
        emit tokenBurned(msg.sender, _tokenId);
    }

    /**
     * @dev Function returning to total supply defined by the owner in constructor.
     */
    function totalSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @dev Function returning to current supply.
     */
    function supply() public view returns (uint256) {
        return currentSupply;
    }

    /**
     * @dev Returns the balance of a specfific user.
     */
    function balanceOf(address _user) public view returns (uint) {
        require(
            _user != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return balances[_user];
    }

    /**
     * @dev Returns the holder of a specific token given token id.
     */
    function holderOf(uint _tokenId) public view returns (address) {
        address holder = holders[_tokenId];
        return holder;
    }

    /**
     * @dev Allows user to transfer a specific token given token id to another address
     */
    function transfer(
        uint _tokenId,
        address _to
    ) public onlyHolder(_tokenId) returns (bool) {
        _transfer(msg.sender, _to, _tokenId);
        return true;
    }

    /**
     * @dev Allows an user to approve spending of a specific token for a spender account.
     */
    function approve(uint _tokenId, address _to) public onlyHolder(_tokenId) {
        tokenApprovals[_tokenId] = _to;
        emit Approval(holderOf(_tokenId), _to, _tokenId);
    }

    /**
     * @dev View approval of a specific token.
     */
    function getApproval(uint _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    /**
     * @dev Allow an user to transfer token in behalf of the owner accounts given approval.
     */
    function transferFrom(
        address _from,
        address _to,
        uint _tokenId
    ) public onlyHolderOrApproved(_tokenId) returns (bool) {
        _transfer(_from, _to, _tokenId);
        return true;
    }

    /**
     * @dev Return the tokenURI of a specific token.
     */
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ERC721: invalid token id");

        string memory _tokenURI = tokenURIs[_tokenId];
        string memory base = "";

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return
            bytes(base).length > 0
                ? string(abi.encodePacked(base, _tokenId))
                : "";
    }

    /**
     * @dev Set tokenURI for a token.
     */
    function _setTokenURI(uint256 _tokenId, string memory _tokenURI) internal {
        require(_exists(_tokenId), "ERC721: URI set of nonexistent token");
        tokenURIs[_tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function mint.
     */
    function _mint(address _to, uint _tokenId) internal {
        require(_to != address(0), "ERC721: mint to the zero address!");
        require(!_exists(_tokenId), "ERC721: token already minted!");
        unchecked {
            balances[_to] += 1;
        }
        holders[_tokenId] = _to;
    }

    /**
     * @dev Internal function transfer.
     */
    function _transfer(address _from, address _to, uint _tokenId) internal {
        require(
            _from == holders[_tokenId],
            "ERC721: transfer from incorrect owner"
        );
        require(_to != address(0), "ERC721: invalid receiver");
        delete tokenApprovals[_tokenId];

        unchecked {
            balances[_from] -= 1;
            balances[_to] += 1;
        }

        holders[_tokenId] = _to;
    }

    /**
     * @dev Check the existence of token with the specified token id
     */
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return holderOf(_tokenId) != address(0);
    }

    /**
     * @dev Check if the address is the holder or is approved for a specific token id.
     */
    function _isHolderOrApproved(
        address _spender,
        uint _tokenId
    ) internal view returns (bool) {
        address holder = ERC721Token.holderOf(_tokenId);
        return (_spender == holder || getApproval(_tokenId) == _spender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ERC20Token {
    address private owner;
    string private name;
    string private symbol;
    uint private immutable MAX_SUPPLY;
    uint currentSupply = 0;

    // Mapping keeping track of balances of addresses
    mapping(address => uint) private balances;

    // Mapping keeping track of allowances of addresses to other spenders
    mapping(address => mapping(address => uint256)) private allowed;

    // Main events including Mint, Burn, Transfer, Approve
    event tokenMinted(address _to, uint _amount);
    event tokenBurned(address _from, uint _amount);
    event Transfer(address _from, address _to, uint _amount);
    event Approval(address _from, address _spender, uint _amount);

    /**
     * @dev Modifier restricting access to only owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call method");
        _;
    }

    /**
     * @dev Modifier requiring sufficient account balance compared to the specified amoount
     */
    modifier insufficientBalance(address _from, uint _amount) {
        require(balances[_from] >= _amount, "Insufficient balance");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        MAX_SUPPLY = _totalSupply;
    }

    /**
     * @dev Returns the name of the token.
     */
    function getName() public view returns (string memory) {
        return name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function getSymbol() public view returns (string memory) {
        return symbol;
    }

    /**
     * @dev Returns the owner of the token
     */
    function getOwner() public view returns (address) {
        return owner;
    }

    /**
     * @dev Function allows the owner to issue new token to specified address.
     */
    function mintToken(address _to, uint _amount) public onlyOwner {
        require(_to != address(0), "ERC20: mint to the zero address");
        require(
            currentSupply + _amount <= MAX_SUPPLY,
            "Cannot mint more than total supply"
        );
        currentSupply += _amount;
        balances[_to] += _amount;
        emit tokenMinted(_to, _amount);
    }

    /**
     * @dev Function allows anyone to burn an amount of their token.
     */
    function burnToken(
        uint _amount
    ) public insufficientBalance(msg.sender, _amount) {
        currentSupply -= _amount;
        balances[msg.sender] -= _amount;
        emit tokenBurned(msg.sender, _amount);
    }

    /**
     * @dev Function returning to total supply defined by the owner in constructor.
     */
    function totalSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    /**
     * @dev Returns the balance of a specfific user.
     */
    function balanceOf(address _user) public view returns (uint) {
        require(
            _user != address(0),
            "ERC20: address zero is not a valid owner"
        );
        return balances[_user];
    }

    /**
     * @dev Returns the allowance of an account for a spender.
     */
    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Allows user to transfer a specific amount of token to another address
     */
    function transfer(
        address _to,
        uint _amount
    ) public insufficientBalance(msg.sender, _amount) returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev Allows an user to approve specific amount of spending for a spender account.
     */
    function approve(
        address _spender,
        uint _oldAmount,
        uint _amount
    ) public returns (bool) {
        require(_spender != address(0), "ERC20: approve to the zero address");
        // Avoid attackers frontrun the transactions and double spend the allowance = oldAmount + amount. Ref: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
        require(
            allowed[msg.sender][_spender] == _oldAmount,
            "Approval has been changed"
        );
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev Allow an user to transfer token in behalf of the owner accounts given approval.
     */
    function transferFrom(
        address _from,
        address _to,
        uint _amount
    ) public insufficientBalance(_from, _amount) returns (bool) {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        require(allowed[_from][msg.sender] >= _amount);

        allowed[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
}