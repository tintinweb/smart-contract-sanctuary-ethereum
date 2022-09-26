/**
 *Submitted for verification at Etherscan.io on 2022-09-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface INFTFeeClaim {
    function batchDeposit(uint256[] memory ids, address _nft, address _token, uint256 _amount) external returns (bool _success);
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

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IRewardsNFT {
    function totalSupply() external view returns (uint256);
    function remainingItems() external view returns (uint256);
}

interface ITokensRecoverable {
    function recoverTokens(IERC20 token) external;
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'no whitelist');
        _;
    }

    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
        return success;
    }

    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
        return success;
    }

    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
        return success;
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

abstract contract TokensRecoverable is Whitelist, ITokensRecoverable {
    using SafeERC20 for IERC20;

    function recoverTokens(IERC20 token) public override onlyWhitelisted() {
        require (canRecoverTokens(token));
        token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    function canRecoverTokens(IERC20 token) public virtual view returns (bool) { 
        return address(token) != address(this); 
    }
}

contract RewardsDistributorV2 is INFTFeeClaim, Whitelist, ReentrancyGuard, TokensRecoverable {
    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct TokenStats {
        uint256 deposited;
        uint256 claimed;
    }

    struct UserStats {
        bool blocked;
        
        string name;

        mapping(address => TokenStats) tokens;
    }

    address public developer;

    //////////////
    // MAPPINGS //
    //////////////

    mapping(address => mapping(address => uint256)) private _claimableOf;
    mapping(address => TokenStats) private _tokenStats;
    mapping(address => UserStats) private _userStats;

    ////////////
    // EVENTS //
    ////////////

    event payment(address indexed caller, address indexed nft, address token, uint256 amount, uint256 timestamp);

    event rewardsDeposited(address indexed caller, address indexed nft, address token, uint256 amount, uint256 timestamp);
    event rewardsClaimed(address indexed caller, address indexed token, uint256 amount, uint256 timestamp);

    event nameSetForAddress(address indexed caller, string name, uint256 timestamp);

    event setUserBlocked(address indexed caller, bool blocked, uint256 timestamp);

    event setDeveloper(address indexed devAddress, uint256 timestamp);


    ////////////////////////////
    // CONSTRUCTOR & FALLBACK //
    ////////////////////////////

    constructor(address _developer) {
        developer = _developer;
    }

    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////

    // Deposit tokens to a single user by NFT and ID
    function deposit(address _token, address _nft, uint256 _itemId, uint256 _amount) external nonReentrant returns (bool _success) {

        // Get the tokens from the depositor
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // Find the owner of an item
        address user = getOwnerOf(_nft, _itemId);
        
        // Add deposit to recipient's claimables
        _claimableOf[user][_token] += _amount;

        // Tell the network, successful function!
        emit payment(msg.sender, _nft, _token, _amount, block.timestamp);
        return true;
    }

    // Deposit rewards in any token to any set of NFTs
    function batchDeposit(uint256[] memory ids, address _nft, address _token, uint256 _amount) override external nonReentrant returns (bool _success) {
        
        // Get the tokens from the depositor
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
    
        // Establish the sender
        address sender = msg.sender;

        // Find the total items being split between
        uint256 totalItems = ids.length;

        // Find amount of tokens per item
        uint256 amountPerItem = (_amount / totalItems);

        // For each item, until i = totalItems...
        for (uint i = 1; i <= totalItems; i++) {

            // Find the owner of the item,
            address user = getOwnerOf(_nft, i);

            // If the holder is blocked, 
            if (isBlocked(user)) {

                // redirect payment to the developer of this contract
                user = developer;
            }
            
            // Then credit them the amountPerItem of tokens
            _claimableOf[user][_token] += amountPerItem;
        }

        // Update Stats
        _tokenStats[_token].deposited += _amount;
        _userStats[sender].tokens[_token].deposited += _amount;

        // Tell the network, successful function!
        emit rewardsDeposited(msg.sender, _nft, _token, _amount, block.timestamp);
        return true;
    }

    // Claim any entitlements by token address
    function claimPayout(address _token) external nonReentrant returns (bool _success) {
        
        // Make sure user is not blocked
        address user = msg.sender;
        require(!isBlocked(user), "RECIPIENT_BANNED");

        // Make sure there's something to claim
        uint256 amount = claimableOf(user, _token);
        require (amount > 0, "No payout available");
        
        // Zero the account
        _claimableOf[user][_token] = 0;
        
        // Dispense tokens
        IERC20(_token).safeTransfer(user, amount);

        // Update stats
        _tokenStats[_token].claimed += amount;
        _userStats[user].tokens[_token].claimed += amount;

        // Tell the network, successful function!
        emit rewardsClaimed(user, _token, amount, block.timestamp);
        return true;
    }

    // Set name for address
    function setName(string memory _name) external nonReentrant returns (bool _success) {
        address user = msg.sender;

        _userStats[user].name = _name;

        emit nameSetForAddress(user, _name, block.timestamp);
        return true;
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    // Get the nametag of an address
    function getNameOf(address _user) public view returns (string memory _name) {
        return (_userStats[_user].name);
    }

    // Get stats of user by token
    function getStatsOfUser(address _token, address _user) public view returns (uint256 deposited, uint256 claimed) {
        return (
            _userStats[_user].tokens[_token].deposited,
            _userStats[_user].tokens[_token].claimed
        );
    }

    // Get stats of token by address
    function getStatsOfToken(address _token) public view returns (uint256 deposited, uint256 claimed) {
        return (
            _tokenStats[_token].deposited,
            _tokenStats[_token].claimed
        );
    }

    // Get owner of an NFT item by id
    function getOwnerOf(address _nft, uint256 _id) public view returns (address) {
        return IERC721(_nft).ownerOf(_id);
    }

    // Get if user is blocked or not
    function isBlocked(address _user) public view returns (bool) {
        return (_userStats[_user].blocked);
    }

    // Get claimable balance of a holder by token address
    function claimableOf(address _user, address _token) public view returns (uint256) {
        return _claimableOf[_user][_token];
    }

    // Can governance recover tokens?
    function canRecoverTokens(IERC20 _token) public override view returns (bool) {
        return address(_token) != address(this); 
    }

    //////////////////////////
    // OWNER-ONLY FUNCTIONS //
    //////////////////////////

    // Set name for address
    function setNameFor(address _addr, string memory _name) external nonReentrant onlyWhitelisted() returns (bool _success) {
        _userStats[_addr].name = _name;

        emit nameSetForAddress(_addr, _name, block.timestamp);
        return true;
    }

    // Block or Unblock a recipient by address
    function setBlocked(address _addr, bool _blocked) external nonReentrant onlyWhitelisted() returns (bool _success) {
        _userStats[_addr].blocked = _blocked;

        emit setUserBlocked(_addr, _blocked, block.timestamp);
        return true;
    }

    // Set Developer Address
    function setDevAddress(address _dev) external onlyOwner() returns (bool _success) {
        developer = _dev;

        emit setDeveloper(_dev, block.timestamp);
        return true;
    }
}