/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
} library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
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
} interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
} interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
} interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
} library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
} abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
} abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
} contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function supportsInterface(bytes4 interfaceId)public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        string memory baseURI = _baseURI();
        return
        bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom( address from, address to, uint256 tokenId) internal virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom( address from, address to, uint256 tokenId) internal virtual {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom( address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer( address from, address to, uint256 tokenId, bytes memory _data ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
        isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
        try
        IERC721Receiver(to).onERC721Received(
        _msgSender(),
        from,
        tokenId,
        _data
        )
        returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
        if (reason.length == 0) {
        revert(
        "ERC721: transfer to non ERC721Receiver implementer"
        );
        } else {
        assembly {
        revert(add(32, reason), mload(reason))
        }
        }
        }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
} abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI query for nonexistent token"
        );
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
} abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    constructor() {
        _setOwner(_msgSender());
    }function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
} library Counters {
    struct Counter {
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
} library SafeMath {
    function tryAdd(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
    }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
    require(b <= a, errorMessage);
    return a - b;
    }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
    require(b > 0, errorMessage);
    return a / b;
    }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
    require(b > 0, errorMessage);
    return a % b;
    }
    }
} abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
} contract pizzaNFT is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    Counters.Counter private _nftIds;
    uint256 totalPizzas;
    bool newPizzas = false;

    modifier onlyNFTOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "nown");
        _;
    }

    struct Pizzas {
        address from;
        uint256 _pizzaId;
        uint256 base;
        uint256 sauce;
        uint256 cheese;
        uint256[] meats;
        uint256[] toppings;
        bool isRandom;
        bool unbaked;
        bool calculated;
        uint256 rarity;
    }
    struct PizzasResponse {
        uint256 _pizzaId;
        uint256 base;
        uint256 sauce;
        uint256 cheese;
        uint256[] meats;
        uint256[] toppings;
    }

    mapping(uint256 => Pizzas) pizzasList; // pizzaMintedId => Pizza

    uint256 [] pizzaIds;
    constructor() ERC721("Pizza Bake", "PNFT") {}
   
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    // fn to return total pizzas
    function getTotalPizzas() public view returns(uint256) {
        return totalPizzas;
    }

    // fn to return pizza ids
    function getPizzasIds() public view returns(uint256[] memory){
        return pizzaIds;
    }

    // fn to get pizza details
    function getPizzaDetails(uint256 pizzaId) public view returns(Pizzas memory){
        return pizzasList[pizzaId];
    }

    // fn to update pizza list by id
    function updatePizzaList(uint256 pizzaId, address from, uint256 _pizzaId, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings, bool isRandom, bool unbaked, bool calculated, uint256 rarity) public {
        Pizzas memory pizzaDetails;
        pizzaDetails.from = from;
        pizzaDetails._pizzaId = _pizzaId;
        pizzaDetails.base = base;
        pizzaDetails.sauce = sauce;
        pizzaDetails.cheese = cheese;
        pizzaDetails.meats = meats;
        pizzaDetails.toppings = toppings;
        pizzaDetails.isRandom = isRandom;
        pizzaDetails.unbaked = unbaked;
        pizzaDetails.calculated = calculated;
        pizzaDetails.rarity = rarity;
        pizzasList[pizzaId] = pizzaDetails;
    }

    // fn to  get newPizzas Flag
    function getNewPizzas() public view returns (bool){
        return newPizzas;
    }

    // fn to  Set newPizzas Flag
    function setNewPizzas(bool nP) public {
        newPizzas = nP;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    // main functions
    // random bake pizza and mint
    function randomBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings ) public returns (PizzasResponse memory){
        
        _nftIds.increment();
        uint256 _nftId = _nftIds.current();
        _mint(msg.sender, _nftId);
        _setTokenURI(_nftId, metadata);

        Pizzas memory mintedPizza = Pizzas(
            msg.sender,
            _nftId,
            base,
            sauce,
            cheese,
            meats,
            toppings,
            false,
            false,
            false,
            100
        );

        pizzasList[_nftId] = mintedPizza;

        totalPizzas+=1;
        pizzaIds.push(_nftId);
        newPizzas = true;

        PizzasResponse memory pizzasResponse = PizzasResponse(
            _nftId,
            base,
            sauce,
            cheese,
            meats,
            toppings
        );

        return pizzasResponse;
    }

    // buy & bake pizza and mint
    function buyAndBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings ) public returns(PizzasResponse memory){
        
        _nftIds.increment();
        uint256 _nftId = _nftIds.current();
        _mint(msg.sender, _nftId);
        _setTokenURI(_nftId, metadata);
        
        Pizzas memory mintedPizza = Pizzas(
            msg.sender,
            _nftId,
            base,
            sauce,
            cheese,
            meats,
            toppings,
            false,
            false,
            false,
            100
        );

        pizzasList[_nftId] = mintedPizza;
        totalPizzas+=1;
        pizzaIds.push(_nftId);
        newPizzas = true;

        PizzasResponse memory pizzasResponse = PizzasResponse(
            _nftId,
            base,
            sauce,
            cheese,
            meats,
            toppings
        );
       
        return pizzasResponse;
    }

    // unbake pizza 
    function unbakePizza( uint256 _pizzaId ) public onlyNFTOwner(_pizzaId) {
        Pizzas memory pizzaDetails = pizzasList[_pizzaId];
        if(pizzaDetails._pizzaId > 0) {
           _burn(_pizzaId);

            pizzaDetails.unbaked = true;
            pizzasList[_pizzaId] = pizzaDetails;
            totalPizzas--;
        }
    }

    // rebake pizza
    function rebakePizza( uint256 _pizzaId, string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings ) public onlyNFTOwner(_pizzaId) {
        _setTokenURI(_pizzaId, metadata);
        Pizzas memory mintedPizza = Pizzas(
            msg.sender,
            _pizzaId,
            base,
            sauce,
            cheese,
            meats,
            toppings,
            false,
            false,
            false,
            100
        );
        pizzasList[_pizzaId] = mintedPizza;
        newPizzas = true;
    }
}