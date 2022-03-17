/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/Context.sol


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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/BeastReroll.sol



pragma solidity ^0.8.0;



interface MAMMOTH {
    function burn(address _from, uint256 _amount) external;
    function mintMammoth(address _to, uint256 _amount) external;
    }

interface RWASTE {
    function transferFrom(address sender, address recipient, uint256 amount) external;
    }

interface DMT {
    function transferFrom(address sender, address recipient, uint256 amount) external;
    }

interface PrimalBeasts {
    function ownerOf(uint256 tokenIDofBeast) external returns (address);
    function setReward(address ownerAddress, uint256 newReward) external;
    function calcNewReward(address from) external view returns(uint256);
    function claimableReward(address from) external view returns (uint256);

    }

contract mammothReroll is Ownable, ReentrancyGuard {
    
    RWASTE public rwasteHandler = RWASTE(0x5cd2FAc9702D68dde5a94B1af95962bCFb80fC7d);
    DMT public dmtHandler = DMT(0x5b1D655C93185b06B00f7925791106132Cb3ad75);
    MAMMOTH public mammothHandler = MAMMOTH(0xa95ECa953CcF7eBF1a17018db14356DA5Ff92803);
    PrimalBeasts public primalHandler = PrimalBeasts(0xE3c47892E6c71E881eaFF077664E3055A48F8E27);
    
    constructor(){}
    mapping(address => uint256) public claimedReward;
    mapping(address => bool) public approvedAddress;
    bool public mammothEnabled = true;

    function setReward(address ownerAddress, uint256 newReward) public {
      require(approvedAddress[msg.sender], "Only controllers can set reward");
      claimedReward[ownerAddress] = newReward;
    }

    function spendMammoth(address ownerAddress, uint256 newReward) public {
      require(approvedAddress[msg.sender], "Only controllers can set reward");
      claimedReward[ownerAddress] += newReward;
    }

    function activateMammoth(bool mammothGo) external onlyOwner{
        mammothEnabled = mammothGo;
    }

    function addController(address owner, bool access) external onlyOwner {
        approvedAddress[owner] = access;
    }

    function claimRewards(address claimer) public nonReentrant{
        require(mammothEnabled, "Mammoth is paused.");
        require(claimer == msg.sender || approvedAddress[msg.sender], "Can't claim for others");
        uint256 total = ((primalHandler.calcNewReward(claimer) + primalHandler.claimableReward(claimer) - claimedReward[claimer]));
        if (total > 0) {
            mammothHandler.mintMammoth(claimer, total);
        }
        claimedReward[claimer] += (primalHandler.calcNewReward(claimer) + primalHandler.claimableReward(claimer));
    }


    function getOldReward(address claimer) public view returns (uint256){
        return (primalHandler.claimableReward(claimer) + primalHandler.calcNewReward(claimer));
    }

    function getFinalReward(address claimer) public view returns (uint256){
        return (primalHandler.claimableReward(claimer) + primalHandler.calcNewReward(claimer) - claimedReward[claimer]);
    }

    function setRWaste(address rWasted) external onlyOwner {
        rwasteHandler = RWASTE(rWasted);
    } 

    function setDMT(address DMTer) external onlyOwner {
        dmtHandler = DMT(DMTer);
    } 

    function setMammoth(address mammothAdder) external onlyOwner {
        mammothHandler = MAMMOTH(mammothAdder);
    }

    function setPB(address PBAddy) external onlyOwner {
        primalHandler = PrimalBeasts(PBAddy);
    } 

    event mammothRerollEmit(uint256 beast);
    event rwasteRerollEmit(uint256 beast);
    event dmtRerollEmit(uint256 beast);
    uint256 public rerollCost = 100 ether;
    uint256 public rerollDMTCost = 50 ether;
    uint256 public rerollRWASTECost = 20 ether;

    function changeDMTCost(uint256 newCostDMT) public onlyOwner{
        rerollDMTCost = newCostDMT;
    }
    function changeCost(uint256 newCost) public onlyOwner{
        rerollCost = newCost;
    }
    function changeRWASTECost(uint256 newCostRWASTE) public onlyOwner{
        rerollRWASTECost = newCostRWASTE;
    }

    address burnWalletDMT = 0xEaf13874Cf4408C71B78c7854Ab9A20ED5Af507d;
    address burnWalletRWASTE = 0xEaf13874Cf4408C71B78c7854Ab9A20ED5Af507d;
    address burnWallet = 0xEaf13874Cf4408C71B78c7854Ab9A20ED5Af507d;

    function newBurnWallet(address newBurner) public onlyOwner{
        burnWallet = newBurner;
    }
    function newBurnWalletDMT(address newBurner) public onlyOwner{
        burnWalletDMT = newBurner;
    }
    function newBurnWalletRWASTE(address newBurner) public onlyOwner{
        burnWalletRWASTE = newBurner;
    }
    bool public DMTReady = false;
    bool public RWASTEReady = false;
    bool public MammothReady = true;

    function mammothApprove(bool newState) public onlyOwner{
        MammothReady = newState;
    }
    function DMTApprove(bool newState) public onlyOwner{
        DMTReady = newState;
    }
    function RWASTEApprove(bool newState) public onlyOwner{
        RWASTEReady = newState;
    }

    function rerollMammoth(uint256 tokenID) public{
        require(primalHandler.ownerOf(tokenID) == msg.sender, "Must own token");
        require(MammothReady, "Rerolls not active");
        if (((primalHandler.calcNewReward(msg.sender) + primalHandler.claimableReward(msg.sender) - claimedReward[msg.sender])) > rerollCost){
            claimedReward[msg.sender] += rerollCost;
        }
        else{
        mammothHandler.burn(msg.sender, rerollCost);
        }
        emit mammothRerollEmit(tokenID);
    }

    function rerollDMT(uint256 tokenID) public{
        require(primalHandler.ownerOf(tokenID) == msg.sender, "Must own token");
        require(DMTReady, "Rerolls not active");
        dmtHandler.transferFrom(msg.sender, burnWalletDMT, rerollDMTCost);
        emit dmtRerollEmit(tokenID);
    }

    function rerollrwaste(uint256 tokenID) public{
        require(primalHandler.ownerOf(tokenID) == msg.sender, "Must own token");
         require(RWASTEReady, "Rerolls not active");
        rwasteHandler.transferFrom(msg.sender, burnWalletRWASTE, rerollRWASTECost);
        emit rwasteRerollEmit(tokenID);
    }
}