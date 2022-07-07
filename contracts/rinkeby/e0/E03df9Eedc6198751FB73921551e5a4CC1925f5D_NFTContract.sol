/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/**
 * @dev Based on OpenZeppelin Ownable's (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol), with reduced operations
 */
contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}

interface IERC721Receiver {
    function onERC721Received(address _from, uint256 _tokenId)
        external
        returns (bytes4);
}

interface IERC721 {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function totalSupply() external returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function ownerOf(uint256 _tokenId) external view returns (address);

    function safeTransfer(address _to, uint256 _tokenId) external;

    function safeMint(
        string calldata _name,
        string calldata _description,
        string calldata _imageURI
    ) external payable returns(uint256);

    function setPrice(uint256 _price) external;

    function getPrice() external view returns (uint256);

    function getMetadata(uint256 _tokenId)
        external
        view
        returns (
            string memory _name,
            string memory _description,
            string memory _imageURI
        );
}


contract NFTContract is Ownable, IERC721 {
    string public name = 'SantiagoSofiaEstebanItay';
    string public symbol = 'SSEI';
    uint256 public totalSupply;
    uint256 private price;
    uint256 public tokenId = 1;
    uint256 public VERSION = 101;

    struct SSEIToken {
        string name;
        string description;
        string imageURI;
    }

    SSEIToken[] private allTokens;

    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    mapping(string => bool) private _registedNFTs;

    /**
     * @dev Initializes the contract, prevent tokenId 0.
     */
    constructor() Ownable() {
        allTokens.push();
        price = 1;
    }

    /**
     * @dev Get balance of tokens of someone
     */
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), 'Invalid owner address');
        return _balances[_owner];
    }

    /**
     * @dev Get the URI of some token by tokenId
     */
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        require(_tokenId != 0 && _tokenId < tokenId, "Token doesn't exist");
        SSEIToken memory token = allTokens[_tokenId];
        return token.imageURI;
    }

    /**
     * @dev Get the owner of some token by tokenId
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address _owner = _owners[_tokenId];
        require(_owner != address(0), 'Invalid owner');
        return _owner;
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address
     * Notes: Throws if `msg.sender` is not the current owner of this NFT.
     * Throws if `_to` is the zero address. When transfer is complete, this function
     * checks if `_to` is a smart contract (code size > 0). If so, it calls
     * `onERC721Received` on `_to` and throws if the return value is not
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` or
     *  onERC721Received.selector.
     */
    function safeTransfer(address _to, uint256 _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, 'Invalid token owner');
        require(_to != address(0), 'Invalid receiver token address');

        _balances[msg.sender]--;
        _balances[_to]++;
        _owners[_tokenId] = _to;
        require(
            _checkOnERC721Received(_to, _tokenId),
            'Transfer to non ERC721Receiver'
        );
    }

    function _checkOnERC721Received(address _to, uint256 _tokenId)
        internal
        returns (bool)
    {
        if (_isContract(_to)) {
            try
                IERC721Receiver(_to).onERC721Received(msg.sender, _tokenId)
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch {
                revert('Transfer to non ERC721Receiver');
            }
        } else {
            return true;
        }
    }

    function _isContract(address _address) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }

    /**
     * @dev Creates a new Token
     */
    function safeMint(
        string calldata _name,
        string calldata _description,
        string calldata _imageURI
    ) external payable returns(uint256) {
        //Validate enough money && token name uniqueness
        require(msg.value >= price, 'Not enough funds to create.');
        require(!_registedNFTs[_name], 'Token already exists');

        //Create token object
        allTokens.push(SSEIToken(_name, _description, _imageURI));

        //Set the created token to msg.sender
        _balances[msg.sender] += 1;
        _owners[tokenId] = msg.sender;

        _registedNFTs[_name] = true;
        tokenId++;
        require(
            _checkOnERC721Received(msg.sender, tokenId),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
        emit Mint(tokenId - 1, msg.sender);
        return tokenId - 1;
    }

    function setPrice(uint256 _price) onlyOwner external {
        require(_price > 0, 'Price can not be 0');
        price = _price;
    }

    function getPrice() external view returns (uint256) {
        return price;
    }

    function getMetadata(uint256 _tokenId)
        external
        view
        returns (
            string memory _name,
            string memory _description,
            string memory _imageURI
        )
    {
        require(_tokenId != 0 && _tokenId < tokenId, "Token doesn't exist");

        SSEIToken memory token = allTokens[_tokenId];
        _name = token.name;
        _description = token.description;
        _imageURI = token.imageURI;
    }

    event Mint(uint256 indexed tokenId, address indexed owner);
}