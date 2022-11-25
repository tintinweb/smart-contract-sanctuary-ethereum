/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/FeeManager.sol

pragma solidity ^0.8.0;

contract FeeManager is Ownable {
    struct FeeRecipients {
        address receiver;
        uint256 feeBips;
    }

    struct User {
        uint256 profitTotal;
        uint256 claimed;
        uint256 balance;
    }

    mapping(address => User) public users;
    mapping(address => uint256) public referralFeeBips;
    mapping(address => mapping(uint256 => FeeRecipients[])) public creatorFeeInfo;
    mapping(address => mapping(uint256 => FeeRecipients[])) public appliedCreatorFeeInfo;
    mapping(address => mapping(uint256 => uint256)) public unverifiedProfit;
    mapping(address => bool) public operators;

    bool isInitialized;
    address payable public platformFeeAddress;
    uint256 constant public MAX_BIPS = 10000;
    uint256 public PLATFORM_FEE;
    uint256 public MAX_CREATOR_FEE;
    uint256 public BASIC_REFERRAL_FEE;
    uint256 public UNVERIFIED_CREATOR_FEE;


    event NftRegistrationApproved(address indexed tokenAddress, uint256 indexed tokenId, address indexed receiver, uint256 feeBips);
    event NftRegistrationApplied(address indexed tokenAddress, uint256 indexed tokenId);
    event SetCreatorFee(address indexed tokenAddress, uint256 indexed tokenId, address indexed receiver, uint256 feeBips);
    event FeeProfitClaimed(address indexed user, uint256 amount);
    event CreatorProfitMade(address indexed tokenAddress, uint256 indexed tokenId, address indexed user, uint256 amount);
    event PlatformProfitMade(address indexed tokenAddress, uint256 indexed tokenId, uint256 amount);
    event ReferralProfitMade(address indexed tokenAddress, uint256 indexed tokenId, address indexed user, uint256 amount);

    modifier onlyOperator() {
        require(operators[msg.sender] == true, "Operator account only");
        _;
    }

    receive() external payable {}
    fallback() external payable {}

    function init(
        address payable _platformFeeAddress
    ) external {
        require(!isInitialized, "Already initialized");
        platformFeeAddress = _platformFeeAddress;

        PLATFORM_FEE = 250;
        MAX_CREATOR_FEE = 3000;
        BASIC_REFERRAL_FEE = 0;
        UNVERIFIED_CREATOR_FEE = 500;

        _transferOwnership(msg.sender);
    }

    /** Called by users **/

    function withdrawBalance(address _user) external {
        User memory user = users[_user];
        require(user.balance > 0, "No balance to withdraw");
        user.claimed += user.balance;
        address payable receiver = payable(_user);
        receiver.transfer(user.balance);
        emit FeeProfitClaimed(_user, user.balance);
        user.balance = 0;
    }

    function setCreatorFee(FeeRecipients[] memory _splitInfo, address _tokenAddress, uint256 _tokenId) public {
        if (creatorFeeInfo[_tokenAddress][_tokenId].length == 0 &&
            isCreator(msg.sender, _tokenAddress, _tokenId) == false && 
            operators[msg.sender] == false) {
            _applyNftRegistration(_splitInfo, _tokenAddress, _tokenId);
            return;
        }

        uint256 feeSum = 0;
        uint i;
        for (i = 0; i < _splitInfo.length; i++) {
            feeSum += _splitInfo[i].feeBips;
            if (i < creatorFeeInfo[_tokenAddress][_tokenId].length) {
                creatorFeeInfo[_tokenAddress][_tokenId][i].receiver = _splitInfo[i].receiver;
                creatorFeeInfo[_tokenAddress][_tokenId][i].feeBips = _splitInfo[i].feeBips;
            } else {
                creatorFeeInfo[_tokenAddress][_tokenId].push(_splitInfo[i]);
            }
            emit SetCreatorFee(_tokenAddress, _tokenId, _splitInfo[i].receiver, _splitInfo[i].feeBips);
        }
        for (; i < creatorFeeInfo[_tokenAddress][_tokenId].length;) {
            creatorFeeInfo[_tokenAddress][_tokenId].pop();
        }
        require(feeSum <= MAX_CREATOR_FEE, "The creator fee must be same to or smaller than 30%");
    }

    function setCreatorFees(FeeRecipients[] memory _splitInfo, address _tokenAddress, uint256[] memory _tokenIds) external {
        for (uint i = 0; i < _tokenIds.length; i++)
            setCreatorFee(_splitInfo, _tokenAddress, _tokenIds[i]);
    }

    /** Called by Marketplace **/
    
    function settleTradeFee(address _tokenAddress, uint256 _tokenId, address _referral) payable external {
        uint256 totalFeeBips = getTradeFeeBips(_tokenAddress, _tokenId);
        uint256 totalFee = msg.value;
        uint256 tradePrice = totalFee * MAX_BIPS / totalFeeBips;

        // settle referral
        uint256 referralFee = 0;
        if (_referral != address(0)) {
            if (referralFeeBips[_referral] > 0) {
                referralFee = totalFee * PLATFORM_FEE / totalFeeBips * referralFeeBips[_referral] / MAX_BIPS;
            } else {
                referralFee = totalFee * PLATFORM_FEE / totalFeeBips * BASIC_REFERRAL_FEE / MAX_BIPS;
            }
            users[_referral].profitTotal += referralFee;
            users[_referral].balance += referralFee;
            emit ReferralProfitMade(_tokenAddress, _tokenId, _referral, referralFee);
        }
        
        // settle platform
        uint256 platformFee = totalFee * PLATFORM_FEE / totalFeeBips - referralFee;
        users[platformFeeAddress].profitTotal += platformFee;
        users[platformFeeAddress].balance += platformFee;
        emit PlatformProfitMade(_tokenAddress, _tokenId, platformFee);

        // settle creators
        FeeRecipients[] memory recipients;
        if (creatorFeeInfo[_tokenAddress][_tokenId].length > 0) {
            recipients = creatorFeeInfo[_tokenAddress][_tokenId];
            for (uint i = 0; i < recipients.length; i++) {
                uint256 fee = tradePrice * recipients[i].feeBips / MAX_BIPS;
                users[recipients[i].receiver].profitTotal += fee;
                users[recipients[i].receiver].balance += fee;

                emit CreatorProfitMade(_tokenAddress, _tokenId, recipients[i].receiver, fee);
            }
        // } else if (appliedCreatorFeeInfo[_tokenAddress][_tokenId].length > 0) {
        //     recipients = appliedCreatorFeeInfo[_tokenAddress][_tokenId];
        //     uint256 feeBips;
        //     for (uint i = 0; i < recipients.length; i++) {
        //         feeBips += recipients[i].feeBips;
        //     }
        //     unverifiedProfit[_tokenAddress][_tokenId] += tradePrice * feeBips / MAX_BIPS;
        } else {
            unverifiedProfit[_tokenAddress][_tokenId] += tradePrice * UNVERIFIED_CREATOR_FEE / MAX_BIPS;
        }
    }
 
    /** Called by Admin **/
    function approveNftRegistration(address _tokenAddress, uint256 _tokenId) external onlyOperator {
        uint256 feeBipsSum;
        FeeRecipients[] memory feeInfo = appliedCreatorFeeInfo[_tokenAddress][_tokenId];
        for (uint i = feeInfo.length - 1; i >= 0; i--) {
            feeBipsSum += feeInfo[i].feeBips;
        }
        for (uint i = feeInfo.length - 1; i >= 0; i--) {
            creatorFeeInfo[_tokenAddress][_tokenId].push( feeInfo[i] );
            uint256 fee = unverifiedProfit[_tokenAddress][_tokenId] * feeInfo[i].feeBips / feeBipsSum;
            users[feeInfo[i].receiver].profitTotal += fee;
            users[feeInfo[i].receiver].balance += fee;
            appliedCreatorFeeInfo[_tokenAddress][_tokenId].pop();
            emit NftRegistrationApproved(_tokenAddress, _tokenId, feeInfo[i].receiver, feeInfo[i].feeBips);
        }

    }

    // Rate in Platform Fee
    function setReferralFeeBips(address _referral, uint256 _feeBips) external onlyOwner {
        require(_feeBips <= MAX_BIPS, "_feeBips cannot be bigger than 10000. 10000 means 100%");
        referralFeeBips[_referral] = _feeBips;
    }

    function setPlatformFeeBips(uint256 _feeBips) external onlyOwner {
        require(_feeBips <= MAX_BIPS, "_feeBips cannot be bigger than 10000. 10000 means 100%");
        PLATFORM_FEE = _feeBips;
    }

    function setMaxCreatorFeeBips(uint256 _feeBips) external onlyOwner {
        require(_feeBips <= MAX_BIPS, "_feeBips cannot be bigger than 10000. 10000 means 100%");
        MAX_CREATOR_FEE = _feeBips;
    }

    function setBasicReferralFeeBips(uint256 _feeBips) external onlyOwner {
        require(_feeBips <= MAX_BIPS, "_feeBips cannot be bigger than 10000. 10000 means 100%");
        BASIC_REFERRAL_FEE = _feeBips;
    }

    function setUnverifiedCreatorFeeBips(uint256 _feeBips) external onlyOwner {
        require(_feeBips <= MAX_BIPS, "_feeBips cannot be bigger than 10000. 10000 means 100%");
        UNVERIFIED_CREATOR_FEE = _feeBips;
    }

    function setPlatformFeeAddress(address payable _platformFeeAddress) external onlyOwner {
        platformFeeAddress = _platformFeeAddress;
    }

    function setOperator(address _address, bool _isOperator) external onlyOwner {
        operators[_address] = _isOperator;
    }

    /** Internals **/

    function _applyNftRegistration(FeeRecipients[] memory _splitInfo, address _tokenAddress, uint256 _tokenId) internal {
        for (uint i = 0; i < _splitInfo.length; i++) {
            appliedCreatorFeeInfo[_tokenAddress][_tokenId].push( _splitInfo[i] );
        }

        emit NftRegistrationApplied(_tokenAddress, _tokenId);
    }

    /** Views **/

    function getCreatorFee(address _tokenAddress, uint256 _tokenId) view public returns (FeeRecipients[] memory) {
        return creatorFeeInfo[_tokenAddress][_tokenId];
    }

    function isCreator(address _creator, address _tokenAddress, uint256 _tokenId) view public returns (bool) {
        if (Ownable(_tokenAddress).owner() == _creator)
            return true;
        FeeRecipients[] memory info = getCreatorFee(_tokenAddress, _tokenId);
        for (uint i = 0; i < info.length; i++) {
            if (info[i].receiver == _creator)
                return true;
        }
        return false;
    }
 
    function getTradeFeeBips(address _tokenAddress, uint256 _tokenId) view public returns (uint256) {
        FeeRecipients[] memory recipients;
        uint256 sum = PLATFORM_FEE;

        if (creatorFeeInfo[_tokenAddress][_tokenId].length > 0)
            recipients = creatorFeeInfo[_tokenAddress][_tokenId];
        // else if (appliedCreatorFeeInfo[_tokenAddress][_tokenId].length > 0)
        //     recipients = appliedCreatorFeeInfo[_tokenAddress][_tokenId];
        else
            sum += UNVERIFIED_CREATOR_FEE;

        for (uint i = 0; i < recipients.length; i++) {
            sum += recipients[i].feeBips;
        }
        return sum;
    }
}