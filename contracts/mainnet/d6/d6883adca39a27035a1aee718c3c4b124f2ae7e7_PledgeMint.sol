/**
 *Submitted for verification at Etherscan.io on 2022-08-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC721Pledge {
    function pledgeMint(address to, uint256 quantity)
        external;
    
    function amountForPledgeMint() external view returns (uint256);
}

contract PledgeMint is Ownable, ReentrancyGuard {

    uint256 public totalMinted = 0;

    IERC721Pledge public nftContract;
    uint256 public mintPrice = 0.01 ether;
    uint256 public maxPerWallet = 10;
    bool public pledgesLocked = false;
    bool public open = true;

    address[] public pledgers;
    mapping(address => bool) public allowlists;
    mapping(address => uint256) public pledgesAmount;
    mapping(address => uint256) public depositAmount;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _; 
    }

    constructor() {}

    function setNftContract(address contractAdd) public onlyOwner {
        require(address(nftContract) == address(0), "Nft contract was setup");
        nftContract = IERC721Pledge(contractAdd);
    }

    function setupPledgePhase(uint256 _mintPrice, uint256 _maxPerWallet) external onlyOwner {
        mintPrice = _mintPrice;
        maxPerWallet = _maxPerWallet;
    }

    function allowAddresses(bool isAdding, address[] calldata _allowlist) external onlyOwner {
        for (uint i=0; i < _allowlist.length; i++) {
            allowlists[_allowlist[i]] = isAdding;
        }
    }

    function pledge(uint256 number) external payable callerIsUser {
        if(open == false){
            require(allowlists[msg.sender], "Not in whitelist");
        }
        require((totalMinted + number) <= nftContract.amountForPledgeMint(), "Cannot buy that many NFTs");
        require(pledgesAmount[msg.sender] + number <= maxPerWallet, "Cannot buy that many NFTs");
        require(number > 0, "Need to buy at least one");
        require(msg.value >= mintPrice * number, "Amount mismatch");
        pledgers.push(msg.sender);
        pledgesAmount[msg.sender] += number;
        depositAmount[msg.sender] += msg.value;

        totalMinted +=  number;
    }

    function unpledge() external nonReentrant callerIsUser {
        require(pledgesLocked == false, "Pledges are locked");
        require(pledgesAmount[msg.sender] > 0, "Nothing pledged");

        (bool success, ) = msg.sender.call{value: depositAmount[msg.sender]}("");
        require(success, "Address: unable to send value, recipient may have reverted");

        totalMinted = totalMinted - pledgesAmount[msg.sender];
        depositAmount[msg.sender] = 0;
        pledgesAmount[msg.sender] = 0;
    }

    function lockPledgePhase() external onlyOwner {
        pledgesLocked = true;
    }

    function unlockPledgePhase() external onlyOwner {
        pledgesLocked = false;
    }


    function openPledgePublicly(bool isOpen) external onlyOwner {
        open = isOpen;
    }

    // withdraw
    function withdrawFund(uint256 amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
    }

    // mint for all participants
    function mintPledgeForAll() external onlyOwner {
        _mintPledge(pledgers, 0, pledgers.length);
    }

    // mint for all participants, paginated
    function mintPledgeByIndex(uint startIdx, uint length) external onlyOwner {
        _mintPledge(pledgers, startIdx, length);
    }

    // mint for select participants
    // internal function checks eligibility and pledged number.
    function mintPledgeForAddresses(address[] calldata selectPledgers) external onlyOwner {
        _mintPledge(selectPledgers, 0, selectPledgers.length);
    }

    function _mintPledge(address[] memory addresses, uint startIdx, uint count) internal {
        for (uint i = startIdx; i < count; i++) {
            address pledger = addresses[i];
            uint256 quantity = pledgesAmount[pledger];

            if (quantity > 0) {
                pledgesAmount[pledger] = 0;
                depositAmount[pledger] = 0;
                nftContract.pledgeMint(pledger, quantity);
            }
        }
    }

    function refundToPledger(address pledger) external onlyOwner nonReentrant {
        (bool success, ) = pledger.call{value: depositAmount[pledger]}("");
        require(success, "Address: unable to send value, recipient may have reverted");
        totalMinted = totalMinted - pledgesAmount[msg.sender];
        depositAmount[msg.sender] = 0;
        pledgesAmount[msg.sender] = 0;
    }

    function refundAll() public onlyOwner {
        for (uint256 i = 0; i < pledgers.length; i++) {
            address pledger = pledgers[i];

            if(depositAmount[pledger] > 0){
                (bool success, ) = pledger.call{value: depositAmount[pledger]}("");
                require(success, "Address: unable to send value, recipient may have reverted");
                totalMinted = totalMinted - pledgesAmount[pledger];
                depositAmount[pledger] = 0;
                pledgesAmount[pledger] = 0;
            }
        }
    }

    function refundToPledgersByIndex(uint startIdx, uint count) external onlyOwner {
        for (uint i = startIdx; i < count; i++) {
            address pledger = pledgers[i];
            if(depositAmount[pledger] > 0){
                (bool success, ) = pledger.call{value: depositAmount[pledger]}("");
                require(success, "Address: unable to send value, recipient may have reverted");
                totalMinted = totalMinted - pledgesAmount[pledger];
                depositAmount[pledger] = 0;
                pledgesAmount[pledger] = 0;
            }
        }
    }

    function getAmountForPledgeMint() public view returns(uint256){
        if(address(nftContract) == address(0))
            return 0;
        else
            return nftContract.amountForPledgeMint();
    }

    function totalPledgers() public view returns(uint256){
        return pledgers.length;
    }
}