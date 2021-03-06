/**
 *Submitted for verification at Etherscan.io on 2021-12-20
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
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getOnwer(uint256 tokenId) external view returns (address owner);
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
    // function sendValue(address payable recipient, uint256 amount) internal {
    //     require(
    //         address(this).balance >= amount,
    //         "Address: insufficient balance"
    //     );
    //     (bool success,) = recipient.call{value : amount}("");
    //     require(
    //         success,
    //         "Address: unable to send value, recipient may have reverted"
    //     );
    // }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall( address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue( address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return
        functionCallWithValue(
            target,
            data,
            value,
            "Address: low-level call with value failed"
        );
    }
    function functionCallWithValue( address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require( address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value : value}(
        data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view
    returns (bytes memory)
    {
        return
        functionStaticCall(
            target,
            data,
            "Address: low-level static call failed"
        );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
        return
        functionDelegateCall(
            target,
            data,
            "Address: low-level delegate call failed"
        );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }
    function getOnwer(uint256 tokenId) public view virtual override returns (address) {
        return _owners[tokenId];
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

    function trySub(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
    if (b > a) return (false, 0);
    return (true, a - b);
    }
    }

    function tryMul(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
    }
    }

    function tryDiv(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
    if (b == 0) return (false, 0);
    return (true, a / b);
    }
    }
    function tryMod(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
    if (b == 0) return (false, 0);
    return (true, a % b);
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
    uint ARTIST_SHARE = 10;
    uint RARITY_REWARD_SHARE = 1;
    Counters.Counter private _IngredientIds;
    Counters.Counter private _buyPizzaIds;
    Counters.Counter private _nftIds;
    uint256 public randomBakeStartTime;
    uint256 public randomBakeEndTime;
    uint256 public totalPizzas;
    uint256 public totalIngredients;
    uint256 public meatIngredientsCount;
    uint256 public toppingIngredientsCount;
    uint256 hundered = 100;
    uint256 totalClaimable = 0;
    uint256 totalRarityRewards = 0;
    bool newPizzas = false;
    uint256 public rarestPizzaId = 0;
    event createIngredientEvent( 
        uint256 indexed _ingredientId,
        string ingredientTokenURI, 
        uint256 price, 
        address artist, 
        uint256 ingType);

    event mintIngredient( uint256 indexed _nftId);
    event mintIngredients( uint[] mintedIds);
    // event mintPizza( address from, uint256 indexed _nftId, string metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] meats, uint256[] toppings);
    event mintPizza( uint256 indexed _nftId);
    event mintRandomPizza( uint256 indexed _nftId, PizzasResponse);
    event setTime( address _owner, uint256 randomBakeStartTime, uint256 randomBakeEndTime);
    event rarityClaim( uint256 nftId, uint256 claimableAmount);

    modifier onlyNFTOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "Ownable: caller is not the owner of the NFT");
        _;
    }
    modifier isRandomBakePizzaMint() {
        require(block.timestamp >= randomBakeStartTime, "Random bake is not started yet");
        require(block.timestamp <= randomBakeEndTime, "Random bake is ended now");
        _;
    }
    struct UserIngredients {
        uint256 _ingredientId;
        uint256 _nftId;
        address user;
        bool isUsed;
    }
    struct Ingredients {
        string name;
        uint256 _ingredientId;
        string metadata;
        uint256 price;
        uint256 created;
        address artist;
        uint256 ingType;
        uint256 totalCount;
    }
    struct IngredientResponse {
        string name;
        uint256 rarity;
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
    struct RarityReward {
        address wallet;
        bool claimed;
        uint256 rewardPrice;
        uint256 nftId;
        uint256 rarityScore;
    }
    struct IngredientCountResponse {
        uint256 total;
        uint256 minted;
    }
    mapping(address => uint256) claimableList;
    mapping(uint256 => Ingredients) public ingredientsList;
    mapping(uint256 => UserIngredients) public userIngredientsList;
    mapping(uint256 => uint256) public ingredientTypes;
    mapping(uint256 => Pizzas) public pizzasList;
    mapping(uint256 => uint256) public mintIngredientTypes;
    mapping(uint256 => uint256) public userIngToIngIds;
    mapping(uint256 => uint256) public ingredientUsedCount;
    mapping(uint256 => uint256) public ingredientRarityPercent;
    mapping(address => RarityReward) public rarityRewardsList;
    mapping(uint256 => address) public rarityRewardsAddresses;
    mapping(address => uint256) public rarityRewardsClaimableList;
    mapping(uint256 => uint256) public ingredientMintCount;
    mapping(uint256 => uint256) public ingredientTotalCount;
    uint256 [] meatIngredients;
    uint256 [] toppingIngredients;
    uint256 [] pizzaIds;
    constructor() ERC721("Pizza Bake", "PNFT") {}
    function getTotalRarityRewards() public view returns(uint256) {
        return totalRarityRewards;
    }
    function getRarityRewardOwner(uint256 index) public view returns(address) {
        return rarityRewardsAddresses[index];
    }
    function getRarityRewardPizza(address owner) public view returns(RarityReward memory) {
        RarityReward memory rarityReward = rarityRewardsList[owner];
        return rarityReward;
    }
    function traitRarity() internal {
        if(totalPizzas > 0) {
            uint256 sauceUsed = 0;
            uint256 cheeseUsed = 0;
            for(uint256 i = 1; i <= totalIngredients; i++) {
                Ingredients memory ingredientDetail = ingredientsList[i];
                uint256 ingredientId = ingredientDetail._ingredientId;
                uint256 count = ingredientUsedCount[ingredientId];
                if(ingredientDetail.ingType == 2 && count > 0) {
                    sauceUsed++;
                }
                if(ingredientDetail.ingType == 3 && count > 0) {
                    cheeseUsed++;
                }
                if(count > 0) {
                    ingredientRarityPercent[ingredientDetail._ingredientId] = ingredientUsedCount[ingredientId].mul(100).div(totalPizzas);
                }
            }
            if(sauceUsed> 0) {
                ingredientRarityPercent[5000] = hundered.sub(sauceUsed.mul(100).div(totalPizzas)); // percentage for sauce not used
            }
            if(cheeseUsed > 0) {
                ingredientRarityPercent[5001] = hundered.sub(cheeseUsed.mul(100).div(totalPizzas)); // percentage for cheese not used
            }
        }
        else {
            for(uint256 i = 1; i <= totalIngredients; i++) {
                Ingredients memory ingredientDetail = ingredientsList[i];
                uint256 ingredientId = ingredientDetail._ingredientId;
                ingredientRarityPercent[ingredientId] = 0;
            }
            ingredientRarityPercent[5000] = 0;
            ingredientRarityPercent[5001] = 0;
        }
    }
    function calculateRarity() internal {
        Pizzas memory pizzaDetails;
        uint256 lowestRarity = 100;
        uint256 lowestRarityId = 0;
        uint256 rarityTotal = 0;
        uint256 pizzaId;
        address pizzaOwner;
        uint256 ingId;
        uint256[] memory meats;
        uint256[] memory toppings;
        bool ingAvailable = false;
        uint256 totalIngredientsNow = 3;
        for(uint256 i = 0; i < totalPizzas; i++) {
            pizzaId = pizzaIds[i];
            pizzaDetails = pizzasList[pizzaId];
            // if(!pizzaDetails.calculated && !pizzaDetails.unbaked) {
            if(!pizzaDetails.unbaked) {
                if(pizzaDetails.base > 0) {
                    ingId = userIngToIngIds[pizzaDetails.base];
                    rarityTotal = rarityTotal+ ingredientRarityPercent[ingId];
                }
                if(pizzaDetails.sauce > 0) {
                    ingId = userIngToIngIds[pizzaDetails.sauce];
                    rarityTotal = rarityTotal + ingredientRarityPercent[ingId];
                }
                else {
                    rarityTotal = rarityTotal + ingredientRarityPercent[5000];
                }
                if(pizzaDetails.cheese > 0) {
                    ingId = userIngToIngIds[pizzaDetails.cheese];
                    rarityTotal = rarityTotal + ingredientRarityPercent[ingId];
                }
                else {
                    rarityTotal = rarityTotal + ingredientRarityPercent[5001];
                }
                for(uint256 x = 0; x < meatIngredients.length; x++) {
                    totalIngredientsNow++;
                    ingAvailable = false;
                    meats = pizzaDetails.meats;
                    for(uint256 y=0; y < meats.length; y++) {
                        ingId = userIngToIngIds[meats[y]];
                        if(ingId == meatIngredients[x]) {
                            ingAvailable = true;
                        }
                    }
                    if(ingAvailable) {
                        rarityTotal = rarityTotal + ingredientRarityPercent[meatIngredients[x]];
                    }
                    else {
                        rarityTotal = rarityTotal + hundered.sub(ingredientRarityPercent[meatIngredients[x]]); 
                    }
                }
                for(uint256 x = 0; x < toppingIngredients.length; x++) {
                    totalIngredientsNow++;
                    ingAvailable = false;
                    toppings = pizzaDetails.toppings;
                    for(uint256 y=0; y < toppings.length; y++) {
                        ingId = userIngToIngIds[toppings[y]];
                        if(ingId == toppingIngredients[x]) {
                            ingAvailable = true;
                        }
                    }
                    if(ingAvailable) {
                        rarityTotal = rarityTotal + ingredientRarityPercent[toppingIngredients[x]];
                    }
                    else {
                        rarityTotal = rarityTotal + hundered.sub(ingredientRarityPercent[toppingIngredients[x]]); 
                    }
                }
                rarityTotal = rarityTotal.div(totalIngredientsNow);
                if(rarityTotal < lowestRarity) {
                    lowestRarity = rarityTotal;
                    lowestRarityId = pizzaId;
                    pizzaOwner = pizzaDetails.from;
                }
                pizzaDetails.calculated = true;
                pizzaDetails.rarity;
                pizzasList[pizzaId] = pizzaDetails;
            }
        }
        if(pizzaOwner != address(0)) {
            uint256 totalContractBalance = address(this).balance;
            uint256 availableContractBalance = totalContractBalance-totalClaimable;            
            uint256 rarityRewardShare = availableContractBalance * RARITY_REWARD_SHARE / 100;

            totalClaimable+=rarityRewardShare;
            RarityReward memory rarityReward = RarityReward(
                pizzaOwner,
                false,
                rarityRewardShare,
                lowestRarityId,
                lowestRarity
            );
            rarityRewardsList[pizzaOwner] = rarityReward;
            rarityRewardsAddresses[totalRarityRewards] = pizzaOwner;
            totalRarityRewards+=1;
            rarestPizzaId = lowestRarityId;
        }
    }
    function rarityRewardsCalculation() public {
        if(newPizzas && totalPizzas > 0) {
            traitRarity();
            calculateRarity();
            newPizzas = false;
        }
    }
    function checkMints(uint256 ingredientId) public view returns (IngredientCountResponse memory) {
        uint256 mintCount = ingredientMintCount[ingredientId];
        uint256 totalCount = ingredientTotalCount[ingredientId];
        IngredientCountResponse memory ingredientCount = IngredientCountResponse(
            totalCount,
            mintCount
        );
        return ingredientCount;
    }
    function getIngredientRarity(uint256 ingredientId) public view returns(IngredientResponse memory) {
        uint256 rarity = ingredientRarityPercent[ingredientId];
        Ingredients memory ingredientDetails = ingredientsList[ingredientId];
        IngredientResponse memory ingredientResponse = IngredientResponse(
            ingredientDetails.name,
            rarity
        );
        return (ingredientResponse);
    }
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    function updateArtistShare( uint feePercent) public onlyOwner {
        ARTIST_SHARE = feePercent;
    }
    function checkclaimableReward(address userAddress) public view returns(uint256) {
        uint256 claimableAmount = claimableList[userAddress];
        uint256 nftId = 0;
        RarityReward memory rarityReward = rarityRewardsList[userAddress];
        if(rarityReward.rewardPrice > 0 && !rarityReward.claimed) {
            nftId = rarityReward.nftId;
            claimableAmount+=rarityReward.rewardPrice;
        }
        return claimableAmount;
    }
    function claimReward() public payable {
        uint256 claimableAmount = claimableList[msg.sender];
        uint256 nftId = 0;
        RarityReward memory rarityReward = rarityRewardsList[msg.sender];
        if(rarityReward.rewardPrice > 0 && !rarityReward.claimed) {
            nftId = rarityReward.nftId;
            claimableAmount+=rarityReward.rewardPrice;
        }
        require( claimableAmount > 0, "You are not eligible to claim any reward.");
        payable(msg.sender).transfer(claimableAmount);
        claimableList[msg.sender] = 0;
        rarityReward.rewardPrice = 0;
        rarityReward.claimed = true;
        totalClaimable -= claimableAmount;
        rarityRewardsList[msg.sender] = rarityReward;
        emit rarityClaim(nftId, claimableAmount);
    }
    function createIngredient( string memory ingredientTokenURI, uint256 price, address artist, uint256 ingType, uint256 totalCount, string memory name) public {
        _IngredientIds.increment();
        uint256 _ingredientId = _IngredientIds.current();
        Ingredients memory ingredientDetail = Ingredients(
            name,
            _ingredientId,
            ingredientTokenURI,
            price,
            1,
            artist,
            ingType,
            totalCount
        );
        ingredientTotalCount[_ingredientId] = totalCount;
        ingredientsList[_ingredientId] = ingredientDetail;
        ingredientTypes[_ingredientId] = ingType;
        totalIngredients+=1;
        if(ingType == 4) {
            meatIngredients.push(_ingredientId);
        }
        if(ingType == 5) {
            toppingIngredients.push(_ingredientId);
        }
        emit createIngredientEvent(_ingredientId, ingredientTokenURI, price, artist, ingType);
    }
    function purchaseAndMintIngretient( uint256 _ingredientId) public payable {
        Ingredients memory ingredientDetail = ingredientsList[_ingredientId];
        require(ingredientDetail.created > 0, "Invalid ingredient");
        require(msg.value >= ingredientDetail.price, "Price is not valid");
        uint256 currentMintCount = ingredientMintCount[_ingredientId];
        uint256 totalCount = ingredientTotalCount[_ingredientId];
        require(currentMintCount < totalCount, "This ingredient is already sold out");
        address payable artist = payable(ingredientDetail.artist);
        _nftIds.increment();
        uint256 _nftId = _nftIds.current();
        _mint(msg.sender, _nftId);
        _setTokenURI(_nftId, ingredientDetail.metadata);
        if(artist != address(0)) {
            uint256 currentClaimable = claimableList[ingredientDetail.artist];
            currentClaimable += (msg.value * ARTIST_SHARE / 100);
            claimableList[ingredientDetail.artist] = currentClaimable;
            totalClaimable += currentClaimable;
        }
        
        // ingredientMintCount[_ingredientId] = currentMintCount+1;
        mintIngredientTypes[_nftId] = ingredientDetail.ingType;
        UserIngredients memory userIngredientDetails = UserIngredients(
            _ingredientId,
            _nftId,
            msg.sender,
            false
        );
        userIngredientsList[_nftId] = userIngredientDetails;
        userIngToIngIds[_nftId] = ingredientDetail._ingredientId;
        ingredientMintCount[_ingredientId] = currentMintCount + 1;
        emit mintIngredient(_nftId);
    }
    function purchaseAndMintIngredients( uint256[] memory _ingredientIds) public payable { // 3
        Ingredients memory ingredientDetail;
        uint256 totalPrice = 0;
        for(uint256 i = 0; i < _ingredientIds.length; i++) {
            ingredientDetail = ingredientsList[_ingredientIds[i]];
            require(ingredientDetail.created > 0, "Invalid ingredient");
            totalPrice+=ingredientDetail.price;
        }
        require(msg.value >= totalPrice, "Price is not valid");
        uint[] memory mintedIds = new uint[](_ingredientIds.length);

        for(uint256 i = 0; i < _ingredientIds.length; i++) {
            ingredientDetail = ingredientsList[_ingredientIds[i]];
            address payable artist = payable(ingredientDetail.artist);
            uint256 currentMintCount = ingredientMintCount[_ingredientIds[i]];
            uint256 totalCount = ingredientTotalCount[_ingredientIds[i]];
            require(currentMintCount < totalCount, "This ingredient is already sold out");
            _nftIds.increment();
            uint256 _nftId = _nftIds.current();
            _mint(msg.sender, _nftId);
            _setTokenURI(_nftId, ingredientDetail.metadata);
            if(artist != address(0)) {
                uint256 currentClaimable = claimableList[ingredientDetail.artist];
                currentClaimable += (msg.value * ARTIST_SHARE / 100);
                claimableList[ingredientDetail.artist] = currentClaimable;
                totalClaimable += currentClaimable;
            }
            mintIngredientTypes[_nftId] = ingredientDetail.ingType;
            UserIngredients memory userIngredientDetails = UserIngredients(
                _ingredientIds[i],
                _nftId,
                msg.sender,
                false
            );
            userIngredientsList[_nftId] = userIngredientDetails;
            mintedIds[i] = _nftId;
            userIngToIngIds[_nftId] = ingredientDetail._ingredientId;
            ingredientMintCount[_ingredientIds[i]] = currentMintCount + 1;
        }
        
        emit mintIngredients(mintedIds);
    }
    //called on bake
    function bakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings) public payable {
        // verifyUserIngredientTypes(base, sauce, cheese, meats, toppings, true);
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
        if(base > 0) {
            changeIngredientUsedStatus(base, true);
            increaseUsedCountByUserIngredient(base);
        }
        if(sauce > 0) {
            changeIngredientUsedStatus(sauce, true);
            increaseUsedCountByUserIngredient(sauce);
        }
        if(cheese > 0) {
            changeIngredientUsedStatus(cheese, true);
            increaseUsedCountByUserIngredient(cheese);
        }
        for(uint256 x = 0; x < meats.length; x++) {
            if(meats[x] > 0) {
                changeIngredientUsedStatus(meats[x], true);
                increaseUsedCountByUserIngredient(meats[x]);
            }
        }
        for(uint256 x = 0; x < toppings.length; x++) {
            if(toppings[x] > 0) {
                changeIngredientUsedStatus(toppings[x], true);
                increaseUsedCountByUserIngredient(toppings[x]);
            }
        }
        totalPizzas+=1;
        pizzaIds.push(_nftId);
        newPizzas = true;
        traitRarity();
        emit mintPizza(_nftId);
    }
    //called on rebake
    function rebakePizza( uint256 _pizzaId, string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings, uint256[] memory oldIngs ) public payable onlyNFTOwner(_pizzaId) {
        // verifyUserIngredientTypes(base, sauce, cheese, meats, toppings, true);
        for(uint256 a = 0; a < oldIngs.length; a++) {
            changeIngredientUsedStatus(oldIngs[a], false);
            decreaseUsedCountByUserIngredient(oldIngs[a]);
        }
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
        if(base > 0) {
            changeIngredientUsedStatus(base, true);
            increaseUsedCountByUserIngredient(base);
        }
        if(sauce > 0) {
            changeIngredientUsedStatus(sauce, true);
            increaseUsedCountByUserIngredient(sauce);
        }
        if(cheese > 0) {
            changeIngredientUsedStatus(cheese, true);
            increaseUsedCountByUserIngredient(cheese);
        }
        for(uint256 x = 0; x < meats.length; x++) {
            if(meats[x] > 0) {
                changeIngredientUsedStatus(meats[x], true);
                increaseUsedCountByUserIngredient(meats[x]);
            }
        }
        for(uint256 x = 0; x < toppings.length; x++) {
            if(toppings[x] > 0) {
                changeIngredientUsedStatus(toppings[x], true);
                increaseUsedCountByUserIngredient(toppings[x]);
            }
        }
        newPizzas = true;
        traitRarity();
    }
    //called on random bake
    function randomBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings ) public payable 
        isRandomBakePizzaMint() {
        // verifyUserIngredientTypes(base, sauce, cheese, meats, toppings, false);
        uint256[] memory tops;
        uint256[] memory mets;
        PizzasResponse memory pizzasResponse = PizzasResponse(
            0,
            0,
            0,
            0,
            tops,
            mets);
        uint256 userIngId = 0;
        if(base > 0) {
            userIngId = createUserIngredient(base);
            pizzasResponse.base = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        if(sauce > 0) {
            userIngId = createUserIngredient(sauce);
            pizzasResponse.sauce = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        if(cheese > 0) {
            userIngId = createUserIngredient(cheese);
            pizzasResponse.cheese = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        // uint256[] memory metasIngs;
        uint256[] memory metasIngs = new uint256[](meats.length);
        for(uint256 x = 0; x < meats.length; x++) {
            if(meats[x] > 0) {
                userIngId = createUserIngredient(meats[x]);
                increaseUsedCountByUserIngredient(userIngId);
                metasIngs[x] = userIngId;
            }
        }
        if(metasIngs.length > 0) {
            pizzasResponse.meats = metasIngs;
        }

        // uint256[] memory topsIngs;
        uint256[] memory topsIngs = new uint256[](toppings.length);
        for(uint256 z = 0; z < toppings.length; z++) {
            if(toppings[z] > 0) {
                userIngId = createUserIngredient(toppings[z]);
                increaseUsedCountByUserIngredient(userIngId);
                topsIngs[z] = userIngId;
            }
        }
        if(topsIngs.length > 0) {
            pizzasResponse.toppings = topsIngs;
        }

        _nftIds.increment();
        uint256 _nftId = _nftIds.current();
        _mint(msg.sender, _nftId);
        _setTokenURI(_nftId, metadata);
        Pizzas memory mintedPizza = Pizzas(
            msg.sender,
            _nftId,
            pizzasResponse.base,
            pizzasResponse.sauce,
            pizzasResponse.cheese,
            pizzasResponse.meats,
            pizzasResponse.toppings,
            false,
            false,
            false,
            100
        );
        pizzasList[_nftId] = mintedPizza;
        if(base > 0) {
            changeIngredientUsedStatus(pizzasResponse.base, true);
        }
        if(sauce > 0) {
            changeIngredientUsedStatus(pizzasResponse.sauce, true);
        }
        if(cheese > 0) {
            changeIngredientUsedStatus(pizzasResponse.cheese, true);
        }
        for(uint256 x = 0; x < pizzasResponse.meats.length; x++) {
            if(meats[x] > 0) {
                changeIngredientUsedStatus(pizzasResponse.meats[x], true);
            }
        }
        for(uint256 x = 0; x < pizzasResponse.toppings.length; x++) {
            if(toppings[x] > 0) {
                changeIngredientUsedStatus(pizzasResponse.toppings[x], true);
            }
        }
        totalPizzas+=1;
        pizzaIds.push(_nftId);
        newPizzas = true;
        traitRarity();
        emit mintRandomPizza(_nftId, pizzasResponse);
    }
    //called on random bake
    function buyAndBakePizzaAndMint(string memory metadata, uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings ) public payable {
        // verifyUserIngredientTypes(base, sauce, cheese, meats, toppings, false);
        uint256[] memory tops;
        uint256[] memory mets;
        PizzasResponse memory pizzasResponse = PizzasResponse(
            0,
            0,
            0,
            0,
            tops,
            mets);
        uint256 userIngId = 0;
        if(base > 0) {
            userIngId = createUserIngredient(base);
            pizzasResponse.base = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        if(sauce > 0) {
            userIngId = createUserIngredient(sauce);
            pizzasResponse.sauce = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        if(cheese > 0) {
            userIngId = createUserIngredient(cheese);
            pizzasResponse.cheese = userIngId;
            increaseUsedCountByUserIngredient(userIngId);
        }
        // uint256[] memory metasIngs;
        uint256[] memory metasIngs = new uint256[](meats.length);
        for(uint256 x = 0; x < meats.length; x++) {
            if(meats[x] > 0) {
                userIngId = createUserIngredient(meats[x]);
                increaseUsedCountByUserIngredient(userIngId);
                metasIngs[x] = userIngId;
            }
        }
        if(metasIngs.length > 0) {
            pizzasResponse.meats = metasIngs;
        }

        // uint256[] memory topsIngs;
        uint256[] memory topsIngs = new uint256[](toppings.length);
        for(uint256 x = 0; x < toppings.length; x++) {
            if(toppings[x] > 0) {
                userIngId = createUserIngredient(toppings[x]);
                increaseUsedCountByUserIngredient(userIngId);
                topsIngs[x] = userIngId;
            }
        }
        if(topsIngs.length > 0) {
            pizzasResponse.toppings = topsIngs;
        }

        _nftIds.increment();
        uint256 _nftId = _nftIds.current();
        _mint(msg.sender, _nftId);
        _setTokenURI(_nftId, metadata);
        Pizzas memory mintedPizza = Pizzas(
            msg.sender,
        _nftId,
        pizzasResponse.base,
        pizzasResponse.sauce,
        pizzasResponse.cheese,
        pizzasResponse.meats,
        pizzasResponse.toppings,
        false,
        false,
        false,
        100
        );
        pizzasList[_nftId] = mintedPizza;
        if(base > 0) {
            changeIngredientUsedStatus(pizzasResponse.base, true);
        }
        if(sauce > 0) {
            changeIngredientUsedStatus(pizzasResponse.sauce, true);
        }
        if(cheese > 0) {
            changeIngredientUsedStatus(pizzasResponse.cheese, true);
        }
        for(uint256 x = 0; x < pizzasResponse.meats.length; x++) {
            if(meats[x] > 0) {
                changeIngredientUsedStatus(pizzasResponse.meats[x], true);
            }
        }
        for(uint256 x = 0; x < pizzasResponse.toppings.length; x++) {
            if(toppings[x] > 0) {
                changeIngredientUsedStatus(pizzasResponse.toppings[x], true);
            }
        }
        totalPizzas+=1;
        pizzaIds.push(_nftId);
        newPizzas = true;
        traitRarity();
        emit mintRandomPizza(_nftId, pizzasResponse);
    }
    function verifyIngredientType(uint256 ingredientId, uint256 requiredType) internal {
        uint256 ingType = ingredientsList[ingredientId].ingType;
        require(ingType == requiredType || ingredientId == 0, "Invalid ingredient type");
    }
    function verifyUserIngredientType(uint256 ingredientId, uint256 requiredType) internal {
        uint256 ingType = mintIngredientTypes[ingredientId];
        require(ingType == requiredType || ingredientId == 0, "Invalid ingredient type");
    }
    function createUserIngredient(uint256 _ingredientId) internal returns(uint256) {
        Ingredients memory ingredientDetail = ingredientsList[_ingredientId];
        address payable artist = payable(ingredientDetail.artist);
        _nftIds.increment();
        uint256 _nftId = _nftIds.current();

        uint256 currentMintCount = ingredientMintCount[_ingredientId];
        uint256 totalCount = ingredientTotalCount[_ingredientId];
        require(currentMintCount < totalCount, "This ingredient is already sold out");
        
        _mint(msg.sender, _nftId);
        _setTokenURI(_nftId, ingredientDetail.metadata);
        if(artist != address(0)) {
            uint256 currentClaimable = claimableList[ingredientDetail.artist];
            currentClaimable += (ingredientDetail.price * ARTIST_SHARE / 100);
            claimableList[ingredientDetail.artist] = currentClaimable;
            totalClaimable += currentClaimable;
        }
        mintIngredientTypes[_nftId] = ingredientDetail.ingType;
        UserIngredients memory userIngredientDetails = UserIngredients(
            _ingredientId,
            _nftId,
            msg.sender,
            false
        );
        userIngredientsList[_nftId] = userIngredientDetails;
        userIngToIngIds[_nftId] = ingredientDetail._ingredientId;
        ingredientMintCount[_ingredientId] = currentMintCount + 1;
        return _nftId;
    }
    function withdrawContractCommission(address payable _address) external payable onlyOwner {
        uint256 totalContractBalance = address(this).balance;
        uint256 availableContractBalance = totalContractBalance-totalClaimable; 
        _address.transfer(availableContractBalance);
    }
    function unbakePizza( uint256 _pizzaId, uint256[] memory ingredientIds) public payable onlyNFTOwner(_pizzaId) {
        Pizzas memory pizzaDetails = pizzasList[_pizzaId];
        if(pizzaDetails._pizzaId > 0) {
           _burn(_pizzaId);
            for(uint8 i=0; i<ingredientIds.length; i++) {
                changeIngredientUsedStatus(ingredientIds[i], false);
                decreaseUsedCountByUserIngredient(ingredientIds[i]);
            }
            pizzaDetails.unbaked = true;
            pizzasList[_pizzaId] = pizzaDetails;
            totalPizzas--;
            traitRarity();
        }
    }
    function setRandomBakeDateTime(uint256 _randomBakeStartTime, uint256 _randomBakeEndTime) public returns(bool) {
        require(_randomBakeStartTime < _randomBakeEndTime, "StartTime must be less then endTime");
        randomBakeStartTime = _randomBakeStartTime;
        randomBakeEndTime = _randomBakeEndTime;
        emit setTime(msg.sender,randomBakeStartTime,randomBakeEndTime);
        return true;
    }
    function increaseUsedCountByUserIngredient(uint256 ingredientId) internal {
        uint256 ing = userIngToIngIds[ingredientId];
        uint256 ingCountUsed = ingredientUsedCount[ing]+1;
        ingredientUsedCount[ing] = ingCountUsed;
    }
    function verifyUserIngredientTypes(uint256 base, uint256 sauce, uint256 cheese, uint256[] memory meats, uint256[] memory toppings, bool checkOwner) internal {
        verifyUserIngredientType(base, 1);
        if(checkOwner)
            require(getOnwer(base) == msg.sender || base == 0, "You are not owner of base you selected");     
        
        verifyUserIngredientType(sauce, 2);
            require(getOnwer(sauce) == msg.sender || sauce == 0, "You are not owner of sauce you selected");
        
        verifyUserIngredientType(cheese, 3);
        if(checkOwner)
            require(getOnwer(cheese) == msg.sender || cheese == 0, "You are not owner of cheese you selected");
        for(uint256 x = 0; x < meats.length; x++) {
            verifyUserIngredientType(meats[x], 4);
            if(checkOwner)
                require(getOnwer(meats[x]) == msg.sender || meats[x] == 0, "You are not owner of meat you selected");
        }
        for(uint256 x = 0; x < toppings.length; x++) {
            verifyUserIngredientType(toppings[x], 5);
            if(checkOwner)
                require(getOnwer(toppings[x]) == msg.sender || toppings[x] == 0, "You are not owner of toppings you selected");
        }
    }
    function decreaseUsedCountByUserIngredient(uint256 ingredientId) internal {
        uint256 ing = userIngToIngIds[ingredientId];
        if(ingredientUsedCount[ing] > 0) {
            uint256 ingCountUsed = ingredientUsedCount[ing]-1;
            ingredientUsedCount[ing] = ingCountUsed;
        }
    }
    function changeIngredientUsedStatus(uint256 ingredientId, bool status) internal {
        UserIngredients memory userIngredientDetails = userIngredientsList[ingredientId];
        userIngredientDetails.isUsed = status;
        userIngredientsList[ingredientId] = userIngredientDetails;
    }
    //get data calls
    // function getIngredientById(uint256 ingrId) public view returns( Ingredients memory ) {
    //     return ingredientsList[ingrId];
    // }
    // function getUserIngredientById(uint256 nftId) public view returns( UserIngredients memory ) {
    //     return userIngredientsList[nftId];
    // }
    // function getPizzaById(uint256 pizzaId) public view returns( Pizzas memory ) {
    //     return pizzasList[pizzaId];
    // }
}