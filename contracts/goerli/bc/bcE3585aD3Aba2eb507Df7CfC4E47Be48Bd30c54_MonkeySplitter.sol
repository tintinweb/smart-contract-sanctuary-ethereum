/**
 *Submitted for verification at Etherscan.io on 2023-02-12
*/

// SPDX-License-Identifier: MIT

// File: contracts/TnmtLibrary.sol



/// @title TNMT Structs

pragma solidity ^0.8.18;

library ITnmtLibrary {

    struct Tnmt {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 noColors;
        ColorDec[11] colors;
        string evento;
        uint8 rotations;
        bool hFlip;
        bool vFlip;
        bool updated;
    }

    struct Attributes {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 noColors;
        uint8 rotations;
        bool hFlip;
        bool vFlip;
        string evento;
    }

    struct Edit {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 manyEdits;
        uint8 rotations;
        ColorDec[3] colors;
        address editor;
    }

    struct Bid {
        address bidder;
        uint256 amount;
    }

    struct ColorDec {
        uint8 colorId;
        uint8 color_R;
        uint8 color_G;
        uint8 color_B;
        uint8 color_A;
    }

}
// File: contracts/ITnmtToken.sol



/// @title Interface for tnmt Auction House


pragma solidity ^0.8.18;

interface ITnmtToken {

    function ownerOf(uint256 a) external returns (address);

    function mint(address _to,
        uint256 _auctionId,
        uint256 _monkeyId,
        uint8 _rotations,
        address _editor,
        uint8 _manyEdits,
        ITnmtLibrary.ColorDec[3] memory editColors) external returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function getCurrentTnmtId() external returns (uint256);
    
}
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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

// File: contracts/MonkeySplitter.sol






pragma solidity ^0.8.18;

contract MonkeySplitter is Ownable, ReentrancyGuard {
    
    struct editBalances {
        address editor;
        uint256 amount;
    }
    
    event PaymentReleased(address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event EditPaymentApproved(address _editor, uint256 _auctionId);
    event EditPaymentDenied(address _editor, uint256 _auctionId);
    event GenesisHolderUpdated(address _holder, uint256 _monkeyId);
    event UpdateCheckOn();
    event UpdateCheckOff();
    event SharesDistributionUpdated(
        uint256 _simpleSaleMonkeyShares,
        uint256 _simpleSaleHoldersShares,
        uint256 _editSaleMonkeyShares,
        uint256 _editSaleHoldersShares,
        uint256 _editSaleEditorShares);

    // The tnmt ERC721 contract
    address private tnmt;

    // The tnmt ERC721 contract
    address private oldTnmt;

    // Community address
    address private community;

    // Project address
    address private monkey;

    // Monkey Auction House address
    address private monkeyAuctionHouse;

    // ETH amount left to split
    uint256 public splitableETH;

    // Shares for Monkey in simple sale
    uint256 simpleSaleMonkeyShares;

    // Shares for Holders in simple sale
    uint256 simpleSaleHoldersShares;

    // shares for Monkey in edit sale
    uint256 editSaleMonkeyShares;

    // shares for holders in edit sale
    uint256 editSaleHoldersShares;

    // shares for Editor in edit sale
    uint256 editSaleEditorShares;

    //mapping address to balance
    mapping(address => uint256) balances;

    //mapping address to owed Edits balance
    mapping(uint256 => editBalances) owedEdits;

    // checkIfHolderHasUpdated
    bool public holdersUpdateCheck;

    /**
     *   @notice Check that only Tnmt
     */
    modifier onlyTnmtToken() {
        require(msg.sender == tnmt, "Only TnmtToken can approve >.<");
        _;
    }

    /**
     *   @notice Require that sender is minter or Owner
     */
    modifier onlyAuctionHouseOrOwner() {
        require(msg.sender == monkeyAuctionHouse || msg.sender == owner(), "Caller is not the Auction House or Owner");
        _;
    }

    constructor(
        address _tnmtToken,
        address _oldTnmtToken,
        address _community,
        address _monkey
    ) {
        tnmt = _tnmtToken;
        oldTnmt = _oldTnmtToken;
        community = _community;
        monkey = _monkey;

        simpleSaleMonkeyShares = 300;
        simpleSaleHoldersShares = 300;
        editSaleMonkeyShares = 200;
        editSaleHoldersShares = 200;
        editSaleEditorShares = 200;
    }

    /**
     * The received ETH from monkeyAuctionHouse will be logged with PaymentReceived event, event is not fully reliable.
     *      this affeect only the receiving event, splitting among holders and editor takes places in separate function.
     */
    receive() external payable virtual {
        splitableETH += msg.value;
        emit PaymentReceived(msg.sender, msg.value);
    }

    /**
     * Updates shares distribution
     */
     function updateSharesDistribution (
         uint256 _simpleSaleMonkeyShares,
         uint256 _simpleSaleHoldersShares,
         uint256 _editSaleMonkeyShares,
         uint256 _editSaleHoldersShares,
         uint256 _editSaleEditorShares
     ) external onlyOwner {
        simpleSaleMonkeyShares = _simpleSaleMonkeyShares;
        simpleSaleHoldersShares = _simpleSaleHoldersShares;
        editSaleMonkeyShares = _editSaleMonkeyShares;
        editSaleHoldersShares = _editSaleHoldersShares;
        editSaleEditorShares = _editSaleEditorShares;
        
     }
    /**
     * Turns on Update Check
     */
    function unpauseUpdateCheck() external onlyOwner {
        holdersUpdateCheck = true;
        emit UpdateCheckOn();
    }

    /**
     * Turns off Update Check
     */
    function pauseUpdateCheck() external onlyOwner {
        holdersUpdateCheck = false;
        emit UpdateCheckOff();
    }
    
    /**
     * Sets the community account addresss
     */
    function setcommunity(address _community) external onlyOwner {
        community = _community;
    }

    /**
     * Easy get contract balance, lazy
     */
    function getBalance() public view onlyOwner returns (uint) {
  	    return address(this).balance;
    }

    /**
     * Sets the monkeyAuctionHouse account addresss
     */
    function setmonkeyAuctionHouse(address _monkeyAuctionHouse) external onlyOwner {
        monkeyAuctionHouse = _monkeyAuctionHouse;
    }

    /**
     * Sets the Monkey address 
     */
    function setMonkey(address _monkey) external onlyOwner {
        monkey = _monkey;
    }

    /**
     * Sets the new tnmt (Token Address) address 
     */
    function setTnmt(address _tnmt) external onlyOwner {
        tnmt = _tnmt;
    }

    /**
     * Spliting a simple sale
     */
    function splitSimpleSale() external onlyAuctionHouseOrOwner returns (bool) {

        uint256 toSplit = splitableETH;
        splitableETH = 0;
  
        uint256 monkeyAmount = (toSplit / 1000) * simpleSaleMonkeyShares;
        uint256 shared = 0;
        address _toHolder = community;

        uint256 maxId = ITnmtToken(tnmt).getCurrentTnmtId();

        if( maxId > 151) {maxId = 151 ;}

        uint256 holdersAmount = ((toSplit / 1000) * simpleSaleHoldersShares) / maxId;

        for (uint256 i = 1; i <= maxId; i++) {
            _toHolder = ITnmtToken(tnmt).ownerOf(i);


            // Checks if Old Tnmt Holder has transfered Old Tnmt
            if(holdersUpdateCheck == true && i < 6 && ITnmtToken(oldTnmt).ownerOf(i) != monkey){
                _toHolder = community;
            }            

            balances[_toHolder] += holdersAmount;
            shared += holdersAmount;
        }

        balances[monkey] += monkeyAmount;
        balances[community] += toSplit - shared - monkeyAmount;
        return true;
    }

    /**
     * Spliting a edit
     */
    function splitEditorSale(address _editor, uint _auctionId) external onlyAuctionHouseOrOwner returns (bool) {
        require(_editor != address(0),"Editor can not be address Zero");

        uint256 toSplit = splitableETH;
        splitableETH = 0;

        uint256 monkeyAmount = (toSplit / 1000) * editSaleMonkeyShares;
        uint256 editorAmount = (toSplit / 1000) * editSaleEditorShares;
        uint256 shared = 0;
        address _toHolder = community;

        uint256 maxId = ITnmtToken(tnmt).getCurrentTnmtId();

        if( maxId > 151) {maxId = 151 ;}

        uint256 holdersAmount = ((toSplit / 1000) * editSaleHoldersShares) / maxId;

        for (uint8 i = 1; i <= maxId; i++) {
            _toHolder = ITnmtToken(tnmt).ownerOf(i);

            // Checking if Old Tnmt Holder has transfered Old Tnmt
            if(holdersUpdateCheck == true && i < 6 && ITnmtToken(oldTnmt).ownerOf(i) != monkey){
                _toHolder = community;
            }  

            balances[_toHolder] += holdersAmount;
            shared += holdersAmount;
        }

        editBalances memory edit;
        edit.editor = _editor;
        edit.amount = editorAmount;
        owedEdits[_auctionId] = edit;
        balances[monkey] += monkeyAmount;
        balances[community] +=
            toSplit -
            shared -
            monkeyAmount -
            editorAmount;
        return true;
    }


    /**
     * When Token gets updated, if colors are valid Editors payment is released
     */
    function approveEditorPay(uint _auctionId, address _editor) public onlyTnmtToken returns (bool) {
        require(owedEdits[_auctionId].editor == _editor, "Auction editor does not match");
        
        uint amount = owedEdits[_auctionId].amount;
        owedEdits[_auctionId].amount = 0;
        balances[_editor] += amount;
        emit EditPaymentApproved(_editor,_auctionId);
        return true;
    }

    /**
     * When Token gets updated, if colors are not valid Editors payment is re distributed among Monkey and Holders
     */
    function denyEditorPay(uint _auctionId, address _editor) public onlyTnmtToken returns (bool) {
        require(owedEdits[_auctionId].editor == _editor, "Auction editor does not match");
        
        uint amount = owedEdits[_auctionId].amount;
        owedEdits[_auctionId].amount = 0;

        uint256 shared = 0;
        address _toHolder = community;

        uint256 maxId = ITnmtToken(tnmt).getCurrentTnmtId();

        if( maxId > 151) {maxId = 151 ;}

        uint256 holdersAmount = (amount / 2) / maxId;

        for (uint256 i = 1; i <= maxId; i++) {
            _toHolder = ITnmtToken(tnmt).ownerOf(i);

            // Checking if Old Tnmt Holder has transfered Old Tnmt
            if(holdersUpdateCheck == true && i < 6 && ITnmtToken(oldTnmt).ownerOf(i) != monkey){
                _toHolder = community;
            }  

            balances[_toHolder] += holdersAmount;
            shared += holdersAmount;
        }
        balances[monkey] += amount - shared;
        emit EditPaymentDenied(_editor,_auctionId);
        return true;
    }

    /**
     * Check your own balance
     */
    function myBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    /**
     * Pulls your full payment
     */
    function pullPayment() public nonReentrant {
        require( balances[msg.sender] > 0,"No ETH to pull");
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount, gas: 30_000}(new bytes(0));
        require(success,"Failed to send Ether");
    }
}