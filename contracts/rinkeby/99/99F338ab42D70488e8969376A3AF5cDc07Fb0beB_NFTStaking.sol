// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}


interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
 

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];

            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = valueIndex;
            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

contract NFTStaking is Ownable{
    using EnumerableSet for EnumerableSet.UintSet;

    uint public REWARD_AMOUNT = 1440 * 1e18;
    uint256 public LOCK_TIME = 21 days;
    IERC721Enumerable public NFT;
    IBEP20 public token;

    mapping(address => EnumerableSet.UintSet) stakedNFTs;
    mapping(uint => uint256) timestampOfNFTs;
    mapping(address => uint256) rewards;
    uint public TotalShares;

    bool locked;
    modifier lock {
        require(!locked);
        locked=true;
        _;
        locked=false;
    }

    constructor(address _NFT, address _token) {
        token = IBEP20(_token);
        NFT = IERC721Enumerable(_NFT);
    }

    function setTokenAddress(address _token) external onlyOwner {
        token=IBEP20(_token);
    }

    function setNFTAddress(address _NFT) external onlyOwner {
        NFT = IERC721Enumerable(_NFT);
    }

    function setLockTime(uint256 _locktime) external onlyOwner {
        LOCK_TIME = _locktime;
    }

    function DepositAll() external{
        while(NFT.balanceOf(msg.sender)>0)
            Deposit(NFT.tokenOfOwnerByIndex(msg.sender,0));
    }

    function Deposit(uint tokenID) public lock {
        NFT.transferFrom(msg.sender,address(this),tokenID);
        stakedNFTs[msg.sender].add(tokenID);
        timestampOfNFTs[tokenID] = block.timestamp;
        TotalShares += 1;
    } 

    function WithdrawAll() external {
       while(stakedNFTs[msg.sender].length() > 0) {
           uint ID = stakedNFTs[msg.sender].length() - 1;
           WithdrawNFT(stakedNFTs[msg.sender].at(ID));
       }
    }

    function WithdrawNFT(uint tokenId) public lock {
        require(stakedNFTs[msg.sender].contains(tokenId), "NFT not staked by Account");
        require(block.timestamp - timestampOfNFTs[tokenId] > LOCK_TIME, "NFT can't be unstaked now.");
        
        stakedNFTs[msg.sender].remove(tokenId);
        timestampOfNFTs[tokenId] = 0;
        TotalShares -= 1;
        NFT.transferFrom(address(this), msg.sender, tokenId);
    }

    function getLengthOfStakedNFTs(address _addr) external view returns (uint256) {
        return stakedNFTs[_addr].length();
    }
    
    function getStakedNFTByIndex(address _addr, uint256 id) external view returns (uint256) {
        uint256 length = stakedNFTs[_addr].length();
        require(length > id, "");

        return stakedNFTs[_addr].at(id);
    }

    function WithdrawDividents() external lock {
        _withdrawDividents(msg.sender);
    }

    function _withdrawDividents(address recipient) private {
        uint amount = getDividents(recipient);
        
        uint256 length = stakedNFTs[recipient].length();
        for(uint256 i = 0; i < length; i ++) {
            uint256 tokenId = stakedNFTs[recipient].at(i);
            timestampOfNFTs[tokenId] = block.timestamp;
        }

        if(amount == 0) return;
        token.transfer(recipient, amount);
    }

    function getDividents(address recipient) public view returns (uint dividents) {
        dividents = 0;
        uint256 length = stakedNFTs[recipient].length();
        for(uint256 i = 0; i < length; i ++) {
            uint256 tokenId = stakedNFTs[recipient].at(i);
            if(timestampOfNFTs[tokenId] > 0) {
                uint256 diff = block.timestamp - timestampOfNFTs[tokenId];
                dividents += diff * REWARD_AMOUNT / (1 days);
            }
        }
    }
}