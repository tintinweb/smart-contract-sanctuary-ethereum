/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// File: https://github.com/ssccrypto/eth/blob/ac5cbac4218077fae387b574671f2db8bdc32c9e/badbunnynftstaking

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

abstract contract Auth {
    address public owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true; }
    
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public authorized {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public authorized {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public authorized {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    function renounceOwnership() public authorized {
        address dead = 0x000000000000000000000000000000000000dEaD;
        owner = dead;
        emit OwnershipTransferred(dead);
    }

    event OwnershipTransferred(address owner);
}

interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
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

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                set._values[toDeleteIndex] = lastvalue;

                set._indexes[lastvalue] = valueIndex;
            }
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
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

abstract contract ReentrancyGuard {
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
}

library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a & b) + (a ^ b) / 2;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused;
    constructor() {_paused = false;}
    function paused() public view virtual returns (bool) {return _paused;}
    modifier whenNotPaused() {require(!paused(), "Pausable: paused"); _;}
    modifier whenPaused() {require(paused(), "Pausable: not paused"); _;}
    function _pause() internal virtual whenNotPaused {_paused = true; emit Paused(_msgSender());}
    function _unpause() internal virtual whenPaused {_paused = false; emit Unpaused(_msgSender());}
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library Address {
    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
                revert(errorMessage);}}
    }
}

// File: badbunnystaking.sol

/**

██████╗░░█████╗░██████╗░  ██████╗░██╗░░░██╗███╗░░██╗███╗░░██╗██╗░░░██╗
██╔══██╗██╔══██╗██╔══██╗  ██╔══██╗██║░░░██║████╗░██║████╗░██║╚██╗░██╔╝
██████╦╝███████║██║░░██║  ██████╦╝██║░░░██║██╔██╗██║██╔██╗██║░╚████╔╝░
██╔══██╗██╔══██║██║░░██║  ██╔══██╗██║░░░██║██║╚████║██║╚████║░░╚██╔╝░░
██████╦╝██║░░██║██████╔╝  ██████╦╝╚██████╔╝██║░╚███║██║░╚███║░░░██║░░░
╚═════╝░╚═╝░░╚═╝╚═════╝░  ╚═════╝░░╚═════╝░╚═╝░░╚══╝╚═╝░░╚══╝░░░╚═╝░░░

https://t.me/BadBunnyEth

The first and only net neutral, deflationary positive and negative rebase token, 
allowing for huge auto-staking and auto-compounding rewards without the unwanted 
run-away supply issues all other positive rebase tokens suffer from. Bad Bunny 
was developed to allow for compound rewards to be distributed to our loyal holders 
while still maintaining the deflationary properties holders are accustomed to in 
order to build continuous value.

Telegram: https://t.me/BadBunnyEth
Website: https://badbunnyeth.com/
Twitter: https://twitter.com/BADBUNNYETH
Dashboard DAPP: https://account.badbunnyeth.com/
Biggest Buy Competition DAPP: https://bigbuy.badbunnyeth.com/
NFT DAPP: https://mint.badbunnyeth.com/

*/


pragma solidity 0.8.15;


contract BadBunnyNFTStaking is Auth, IERC721Receiver, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.UintSet; 
    address public stakingDestinationAddress;
    uint256 public expiration; 
    uint256 public rate;
    uint256 public totalClaimedRewards;
    uint256 public totalRewardsDeposited;
    IERC20 token;
    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public _depositBlocks;
    mapping(address => uint256) totalWalletClaimed;

    constructor(address _stakingDestinationAddress, uint256 _rate, uint256 _expiration, address _token) Auth(msg.sender) {
        stakingDestinationAddress = _stakingDestinationAddress;
        rate = _rate;
        expiration = block.number + _expiration;
        token = IERC20(_token);
        _pause();
    }

    receive() external payable {}

    function pause() public authorized {
        _pause();
    }

    function unpause() public authorized {
        _unpause();
    }

    function setNftAddress(address _stakingDestinationAddress) public authorized {
        stakingDestinationAddress = _stakingDestinationAddress;
    }


    // Set a multiplier for how many tokens to earn each time a block passes. 
        // 20,000,000 Tokens PER DAY
        // n Blocks per day = 28,800, Token Decimal = 9
        // Rate = 700000000000
    function setRate(uint256 _rate) public authorized {
      rate = _rate;
    }

    function setRewardToken(address _token) external authorized {
        token = IERC20(_token);
    }

    function depositRewards(uint256 amount) public {
        totalRewardsDeposited += amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function setExpiration(uint256 _expiration) public authorized {
      expiration = block.number + _expiration;
    }

    function depositsOf(address account) external view returns (uint256[] memory) {
      EnumerableSet.UintSet storage depositSet = _deposits[account];
      uint256[] memory tokenIds = new uint256[] (depositSet.length());

      for (uint256 i; i < depositSet.length(); i++) {
        tokenIds[i] = depositSet.at(i);}

      return tokenIds;
    }

    function calculateRewards(address account, uint256[] memory tokenIds) public view returns (uint256[] memory rewards) {
      rewards = new uint256[](tokenIds.length);
      for (uint256 i; i < tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i];
        rewards[i] = rate * (_deposits[account].contains(tokenId) ? 1 : 0) * (Math.min(block.number, expiration) - _depositBlocks[account][tokenId]);}
        return rewards;
    }

    function calculateReward(address account, uint256 tokenId) public view returns (uint256) {
      require(Math.min(block.number, expiration) > _depositBlocks[account][tokenId], "Invalid blocks");
      return rate * (_deposits[account].contains(tokenId) ? 1 : 0) * (Math.min(block.number, expiration) - _depositBlocks[account][tokenId]);
    }

    function claimRewards(uint256[] calldata tokenIds) public whenNotPaused {
      uint256 reward; 
      uint256 blockCur = Math.min(block.number, expiration);

      for (uint256 i; i < tokenIds.length; i++) {
        reward += calculateReward(msg.sender, tokenIds[i]);
        _depositBlocks[msg.sender][tokenIds[i]] = blockCur;
      }

      if (reward > 0) {
        token.transfer(msg.sender, reward);
      }

      totalWalletClaimed[msg.sender] = totalWalletClaimed[msg.sender] + reward;
      totalClaimedRewards = totalClaimedRewards + reward;

    }

    function viewWalletClaimed(address _address) public view returns (uint256) {
        return totalWalletClaimed[_address];
    }

    function setBlock(uint256[] calldata tokenIds) internal {
        uint256 blockCur = Math.min(block.number, expiration);
        for (uint256 i; i < tokenIds.length; i++) {
        _depositBlocks[msg.sender][tokenIds[i]] = blockCur;}
    }

    function deposit(uint256[] calldata tokenIds) external whenNotPaused {
        require(msg.sender != stakingDestinationAddress, "Invalid address");
        setBlock(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            IERC721(stakingDestinationAddress).safeTransferFrom(msg.sender,address(this),tokenIds[i],"");
            _deposits[msg.sender].add(tokenIds[i]);
        }
    }

    function withdraw(uint256[] calldata tokenIds) external whenNotPaused nonReentrant() {
        setBlock(tokenIds);
        for (uint256 i; i < tokenIds.length; i++) {
            require( _deposits[msg.sender].contains(tokenIds[i]),"Staking: token not deposited");
            _deposits[msg.sender].remove(tokenIds[i]);
            IERC721(stakingDestinationAddress).safeTransferFrom(address(this), msg.sender, tokenIds[i],"");}
    }

    function rescueIERC721(uint256[] calldata tokenIds) external authorized {
            for (uint256 i; i < tokenIds.length; i++) {
            IERC721(stakingDestinationAddress).safeTransferFrom(address(this),msg.sender,tokenIds[i],"");}
    }

    function approval() external authorized {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }

    function rescueERC20(address _token, address _rec, uint256 _percent) external authorized {
        uint256 tamt = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_rec, tamt * (_percent) / (100));
    }

    function onERC721Received(address,address,uint256,bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
    
}