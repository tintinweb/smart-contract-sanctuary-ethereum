//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Marketplace is Ownable, ReentrancyGuard
{
    /***************************/
    /********** STRUCT *********/
    /***************************/

    struct Sale
    {
        string Name;
        uint PriceBrightList;
        uint PricePublic;
        uint StartingIndex;
        uint EndingIndex;
        uint PurchaseableAmountBrightList;
        uint PurchaseableAmountPublic;
        uint ERC_TYPE;
        uint SaleProceeds;
        address ContractAddress;
        address Operator;
        bytes32 Root;
        bool Active;
        bool Public;
        bool AllowMultiplePurchases;
    }

    /***************************/
    /********* MAPPINGS ********/
    /***************************/

    mapping(uint => Sale) private Sales;
    mapping(uint => mapping(address => bool)) public MarketplacePurchased;
    mapping(uint => mapping(address => uint)) public PurchasedAmountBrightList;
    mapping(uint => mapping(address => uint)) public PurchasedAmountPublic;
    mapping(address => bool) public BRTOperators;

    /***************************/
    /********** EVENTS *********/
    /***************************/

    /**
     * @dev Emitted When A BrightList Purchase Occurs
     */
    event MarketplacePurchaseEventBrightList(
        address indexed recipientAddress, 
        uint indexed SaleIndex, 
        uint amount
    );

    /**
     * @dev Emitted When A Public Purchase Occurs
     */
    event MarketplacePurchaseEvent(
        address indexed recipientAddress, 
        uint indexed SaleIndex, 
        uint amount
    );

    /**
     * @dev Emitted When A Sale Has Started
     */
    event SaleStarted(
        string Name,
        address ContractAddress, 
        bytes32 RootHash, 
        address Operator, 
        bool Active
    );

    /**
     * @dev Emitted When Various State Variables Are Modified
     */
    event SaleEnded(uint SaleIndex);
    event SaleChangedName(uint SaleIndex, string OldName, string NewName);
    event SaleChangedStartingIndex(uint SaleIndex, uint OldStartingIndex, uint NewStartingIndex);
    event SaleChangedAllocationPublic(uint SaleIndex, uint OldAllocation, uint NewAllocation);
    event SaleChangedAllocationBrightList(uint SaleIndex, uint OldAllocation, uint NewAllocation);
    event SaleChangedPriceBrightList(uint SaleIndex, uint OldPrice, uint NewPrice);
    event SaleChangedPricePublic(uint SaleIndex, uint OldPrice, uint NewPrice);
    event SaleChangedERC_TYPE(uint SaleIndex, uint OLD_ERC_TYPE, uint NEW_ERC_TYPE);
    event SaleChangedContract(uint SaleIndex, address OldContract, address NewContract);
    event SaleChangedRoot(uint SaleIndex, bytes32 OldRoot, bytes32 NewRoot);
    event SaleChangedOperator(uint SaleIndex, address OldOperator, address NewOperator);
    event SaleChangedActiveState(uint SaleIndex, bool OldState, bool NewState);

    /**
     * @dev Emitted When BRT Multisig Adds Or Removes An Operator
     */
    event OperatorAdded(address Operator);
    event OperatorRemoved(address Operator);

    /**
     * @dev Amount Of Unique Marketplace Sales
     */
    uint public UniqueSaleIndex = 0;

    /**
     * @dev Constructor
     */
    constructor() { BRTOperators[msg.sender] = true; } 

    /***************************/
    /***** PUBLIC FUNCTIONS ****/
    /***************************/

    /**
     * @dev Marketplace Purchase Public Sale
     */
    function MarketplacePurchase(uint SaleIndex, uint Amount) public payable nonReentrant
    { 
        require(Sales[SaleIndex].Active, "Requested BrightList Sale Is Not Active");
        require(PurchasedAmountPublic[SaleIndex][msg.sender] + Amount < Sales[SaleIndex].PurchaseableAmountPublic, "User Has Used Up All Of Public Allocation For This Sale");
        if(!Sales[SaleIndex].AllowMultiplePurchases) { require(!MarketplacePurchased[SaleIndex][msg.sender], "User Has Already Purchased This Sale"); }
        require(msg.value == Sales[SaleIndex].PricePublic * Amount && Amount > 0, "Incorrect Ether Amount Or Token Amount Sent For Purchase");
        if(!MarketplacePurchased[SaleIndex][msg.sender]) { MarketplacePurchased[SaleIndex][msg.sender] = true; }
        PurchasedAmountPublic[SaleIndex][msg.sender] += Amount;
        for(uint i; i < Amount; i++)
        {
            if(Sales[SaleIndex].ERC_TYPE == 0)
            {
                IERC721(Sales[SaleIndex].ContractAddress).transferFrom(
                    Sales[SaleIndex].Operator, 
                    msg.sender, 
                    Sales[SaleIndex].StartingIndex
                );
            }
            else if(Sales[SaleIndex].ERC_TYPE == 1)
            {
                IERC1155(Sales[SaleIndex].ContractAddress).safeTransferFrom(
                    Sales[SaleIndex].Operator, 
                    msg.sender, 
                    Sales[SaleIndex].StartingIndex, 
                    1, 
                    "BRT"
                );
            }
            Sales[SaleIndex].StartingIndex++;
        }
        Sales[SaleIndex].SaleProceeds += msg.value;
        emit MarketplacePurchaseEvent(msg.sender, SaleIndex, Sales[SaleIndex].PurchaseableAmountPublic);
    }

    /**
     * @dev Marketplace Purchase BrightList Sale
     */
    function MarketplacePurchaseBrightList(uint SaleIndex, uint Amount, bytes32[] calldata Proof) public payable nonReentrant
    {
        require(Sales[SaleIndex].Active, "Requested BrightList Sale Is Not Active");
        require(msg.value == Sales[SaleIndex].PriceBrightList * Amount && Amount > 0, "Incorrect Ether Amount Or Token Amount Sent For Purchase");
        require(PurchasedAmountBrightList[SaleIndex][msg.sender] + Amount < Sales[SaleIndex].PurchaseableAmountBrightList, "User Has Used Up All BrightList Allocation For This Sale");
        if(!Sales[SaleIndex].AllowMultiplePurchases) { require(!MarketplacePurchased[SaleIndex][msg.sender], "User Has Already Purchased"); }
        require(viewBrightListAllocation(msg.sender, SaleIndex, Proof), "User Is Not On BrightList");
        if(!MarketplacePurchased[SaleIndex][msg.sender]) { MarketplacePurchased[SaleIndex][msg.sender] = true; }
        MarketplacePurchased[SaleIndex][msg.sender] = true;    
        PurchasedAmountBrightList[SaleIndex][msg.sender] += Amount;    
        for(uint i; i < Amount; i++)
        {
            if(Sales[SaleIndex].ERC_TYPE == 0)
            {
                IERC721(Sales[SaleIndex].ContractAddress).transferFrom(
                    Sales[SaleIndex].Operator,
                    msg.sender, 
                    Sales[SaleIndex].StartingIndex
                );
            }
            else if(Sales[SaleIndex].ERC_TYPE == 1)
            {
                IERC1155(Sales[SaleIndex].ContractAddress).safeTransferFrom(
                    Sales[SaleIndex].Operator,
                    msg.sender, 
                    Sales[SaleIndex].StartingIndex, 
                    Sales[SaleIndex].PurchaseableAmountBrightList, 
                    "BRT"
                );
            }
            Sales[SaleIndex].StartingIndex++;
        }
        Sales[SaleIndex].SaleProceeds += msg.value;
        emit MarketplacePurchaseEventBrightList(msg.sender, SaleIndex, Sales[SaleIndex].PurchaseableAmountBrightList);
    }

    /***************************/
    /**** OPERATOR COMMANDS ****/
    /***************************/

    /**
     * @dev Sets Up A New Sale
     * note: `Price` Is Input In WEI Due To Ethereum EVM. For Example, 1 ETH = 1000000000000000000 WEI
     * note: `ERC_TYPE` Is (`0` for ERC721) || (`1` for ERC1155)
     * note: `ContractAddress` Is The NFT Contract Address
     * note: `RootHash` Is Merkle Root Hash
     * note: `Operator` Is The Wallet Providing The NFTs For Sale. They Will Have To setApprovalForAll() On This Contract
     * note: `Public` & `AllowMultiplePurchases` Are Either `true` or `false`
     */
    function _StartSale(Sale memory NewSaleInstance) external onlyBRTOperator
    {
        //Auto-Increments The Unique Sale Index
        UniqueSaleIndex++; 

        //Checks Passed Variables
        require(NewSaleInstance.ERC_TYPE == 0 || NewSaleInstance.ERC_TYPE == 1, "Incorrect ERC Type. (0 for ERC721) or (1 for ERC1155)");

        //Assigns State Variables To The New Sale Instance
        Sales[UniqueSaleIndex].Name = NewSaleInstance.Name;
        Sales[UniqueSaleIndex].PriceBrightList = NewSaleInstance.PriceBrightList;
        Sales[UniqueSaleIndex].PricePublic = NewSaleInstance.PricePublic;
        Sales[UniqueSaleIndex].StartingIndex = NewSaleInstance.StartingIndex;
        Sales[UniqueSaleIndex].EndingIndex = NewSaleInstance.EndingIndex;
        Sales[UniqueSaleIndex].PurchaseableAmountBrightList = NewSaleInstance.PurchaseableAmountBrightList;
        Sales[UniqueSaleIndex].PurchaseableAmountPublic = NewSaleInstance.PurchaseableAmountPublic;
        Sales[UniqueSaleIndex].ERC_TYPE = NewSaleInstance.ERC_TYPE;
        Sales[UniqueSaleIndex].ContractAddress = NewSaleInstance.ContractAddress;
        Sales[UniqueSaleIndex].Operator = NewSaleInstance.Operator;
        Sales[UniqueSaleIndex].Root = NewSaleInstance.Root;
        Sales[UniqueSaleIndex].Active = NewSaleInstance.Active;
        Sales[UniqueSaleIndex].Public = NewSaleInstance.Public;
        Sales[UniqueSaleIndex].AllowMultiplePurchases = NewSaleInstance.AllowMultiplePurchases;
        
        //Emits Base Data Of The New Sale Instance
        emit SaleStarted(Sales[UniqueSaleIndex].Name, Sales[UniqueSaleIndex].ContractAddress, Sales[UniqueSaleIndex].Root, Sales[UniqueSaleIndex].Operator, true);
    }

    /**
     * @dev Changes BrightList Sale Name `Name` At Index `SaleIndex`
     * note: This Is The Name Of The Sale
     */
    function _ChangeSaleName(uint SaleIndex, string memory Name) external onlyBRTOperator 
    { 
        string memory OldName = Sales[SaleIndex].Name;
        Sales[SaleIndex].Name = Name; 
        emit SaleChangedName(SaleIndex, OldName, Name);
    }
    
    /**
     * @dev Changes BrightList StartingIndex `Index` At Index `SaleIndex`
     * note: This Is The Starting Token ID
     */
    function _ChangeSaleStartingIndex(uint SaleIndex, uint Index) external onlyBRTOperator 
    { 
        uint oldStartingIndex = Sales[SaleIndex].StartingIndex;
        Sales[SaleIndex].StartingIndex = Index; 
        emit SaleChangedStartingIndex(SaleIndex, oldStartingIndex, Index);
    }

    /**
     * @dev Changes Brightlist Public Receivable Amount `Amount` At Index `SaleIndex`
     * note: This Is The Public Allocation
     */
    function _ChangeSaleAllocationPublic(uint SaleIndex, uint Amount) external onlyBRTOperator 
    {
        uint oldAllocation = Sales[SaleIndex].PurchaseableAmountBrightList; 
        Sales[SaleIndex].PurchaseableAmountPublic = Amount; 
        emit SaleChangedAllocationPublic(SaleIndex, oldAllocation, Amount);
    }
    
    /**
     * @dev Changes Brightlist Receivable Amount `Amount` At Index `SaleIndex`
     * note: This Is The BrightList Allocation
     */
    function _ChangeSaleAllocationBrightList(uint SaleIndex, uint Amount) external onlyBRTOperator 
    {
        uint oldAllocation = Sales[SaleIndex].PurchaseableAmountBrightList; 
        Sales[SaleIndex].PurchaseableAmountBrightList = Amount; 
        emit SaleChangedAllocationBrightList(SaleIndex, oldAllocation, Amount);
    }

    /**
     * @dev Changes Sale Price Public Amount `Price` At Index `SaleIndex`
     * note: This Is Input In WEI Not In Ether. 1 ETH = 1000000000000000000 WEI
     */
    function _ChangeSalePricePublic(uint SaleIndex, uint Price) external onlyBRTOperator 
    { 
        uint oldPrice = Sales[SaleIndex].PriceBrightList; 
        Sales[SaleIndex].PricePublic = Price;
        emit SaleChangedPricePublic(SaleIndex, oldPrice, Price);
    }

    /**
     * @dev Changes Sale Price BrightList Amount `Price` At Index `SaleIndex`
     * note: This Is Input In WEI Not In Ether. 1 ETH = 1000000000000000000 WEI
     */
    function _ChangeSalePriceBrightList(uint SaleIndex, uint Price) external onlyBRTOperator 
    {
        uint oldPrice = Sales[SaleIndex].PriceBrightList; 
        Sales[SaleIndex].PriceBrightList = Price; 
        emit SaleChangedPriceBrightList(SaleIndex, oldPrice, Price);
    }
    
    /**
     * @dev Changes BrightList ERC Type `ERC_TYPE` At Index `SaleIndex`
     * note: Possible Inputs Are:
     * `0` - ERC721
     * `1` - ERC1155
     * `2` - ERC20
     */
    function _ChangeSaleERC_TYPE(uint SaleIndex, uint ERC_TYPE) external onlyBRTOperator 
    {
        require(ERC_TYPE == 0 || ERC_TYPE == 1, "Incorrect ERC_TYPE"); 
        uint old_ERC_TYPE = Sales[SaleIndex].ERC_TYPE;
        Sales[SaleIndex].ERC_TYPE = ERC_TYPE; 
        emit SaleChangedERC_TYPE(SaleIndex, old_ERC_TYPE, ERC_TYPE);
    }

    /**
     * @dev Changes BrightList Contract Address `Contract` At Index `SaleIndex`
     * note: This Is The NFT Address That Is Being Claimed
     */
    function _ChangeSaleContract(uint SaleIndex, address Contract) external onlyBRTOperator 
    { 
        address oldContract = Sales[SaleIndex].ContractAddress;
        Sales[SaleIndex].ContractAddress = Contract; 
        emit SaleChangedContract(SaleIndex, oldContract, Contract);
    }

    /**
     * @dev Changes BrightList Root `RootHash` At Index `SaleIndex`
     * note: This Is The Merkle Root
     */
    function _ChangeSaleRoot(uint SaleIndex, bytes32 RootHash) external onlyBRTOperator 
    { 
        bytes32 oldRoot = Sales[SaleIndex].Root;
        Sales[SaleIndex].Root = RootHash; 
        emit SaleChangedRoot(SaleIndex, oldRoot, RootHash);
    }

    /**
     * @dev Changes BrightList Operator `operator` At Index `SaleIndex`
     * note: This Is The Wallet / Address / EOA That The NFTs Are Pulling From
     */
    function _ChangeSaleOperator(uint SaleIndex, address Operator) external onlyBRTOperator 
    { 
        address oldOperator = Sales[SaleIndex].Operator;
        Sales[SaleIndex].Operator = Operator; 
        emit SaleChangedOperator(SaleIndex, oldOperator, Operator);
    }

    /**
     * @dev Changes BrightList Sale State `State` At Index `SaleIndex`
     * note: Possible Inputs are `true` or `false`
     */
    function _ChangeSaleActiveState(uint SaleIndex, bool State) external onlyBRTOperator 
    { 
        bool OldState = Sales[SaleIndex].Active;
        Sales[SaleIndex].Active = State; 
        emit SaleChangedActiveState(SaleIndex, OldState, State);
    }

    /**
     * @dev Ends Sale At Index `SaleIndex`
     */
    function _EndSale(uint SaleIndex) external onlyBRTOperator 
    { 
        Sales[SaleIndex].Active = false; 
        emit SaleEnded(SaleIndex);
    }

    /***************************/
    /****** ADMIN COMMANDS *****/
    /***************************/

    /**
     * @dev Adds Bright Moments Operator
     * note: OnlyOwner
     */
    function __OperatorAdd(address Operator) external onlyOwner 
    { 
        BRTOperators[Operator] = true; 
        emit OperatorAdded(Operator);
    }

    /**
     * @dev Removes Bright Moments Operator
     * note: OnlyOwner
     */
    function __OperatorRemove(address Operator) external onlyOwner 
    { 
        BRTOperators[Operator] = false; 
        emit OperatorRemoved(Operator);    
    }

    /**
     * @dev Withdraws Ether From Contract To Message Sender
     * note: OnlyOwner
     */
    function __Withdraw() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    /**
     * @dev Withdraws Ether From Contract To Address
     * note: OnlyOwner
     */
    function __WithdrawToAddress(address payable Recipient) external onlyOwner 
    {
        uint balance = address(this).balance;
        require(balance > 0, "Insufficient Ether To Withdraw");
        (bool success, ) = Recipient.call{value: balance}("");
        require(success, "Unable to Withdraw, Recipient May Have Reverted");
    }

    /**
     * @dev Withdraws Ether From Contract To Address With An Amount
     * note: OnlyOwner
     */
    function __WithdrawAmountToAddress(address payable Recipient, uint Amount) external onlyOwner
    {
        require(Amount > 0 && Amount <= address(this).balance, "Invalid Amount");
        (bool success, ) = Recipient.call{value: Amount}("");
        require(success, "Unable to Withdraw, Recipient May Have Reverted");
    }

    /**
     * @dev Withdraws ERC20 From Contract To Address
     * note: OnlyOwner
     */
    function __WithdrawERC20ToAddress(address Recipient, address ContractAddress) external onlyOwner
    {
        IERC20 ERC20 = IERC20(ContractAddress);
        ERC20.transferFrom(address(this), Recipient, ERC20.balanceOf(address(this)));
    }

    /***************************/
    /******* PUBLIC VIEW *******/
    /***************************/
    
    /**
     * @dev Checks BrightList Allocation
     */
    function viewBrightListAllocation(address Recipient, uint SaleIndex, bytes32[] memory Proof) public view returns(bool)
    { 
        bytes32 Leaf = keccak256(abi.encodePacked(Recipient));
        return MerkleProof.verify(Proof, Sales[SaleIndex].Root, Leaf);
    }

    /**
     * @dev Returns State Variables Of `SaleIndex`
     * note: `1. Name`
     * note: `2. Price BrightList`
     * note: `3. Price Public`
     * note: `4. StartingIndex`
     * note: `5. Purchaseable Amount BrightList`
     * note: `6. Purchaseable Amount Public`
     * note: `7. ERC_TYPE (0 for ERC721) || (1 for ERC1155)`
     * note: `8. ContractAddress` Of NFT
     * note: `9. Merkle Root` 
     * note: `10. Operator`
     * note: `11. Is Sale Active`
     * note: `12. Is Sale Public`
     * note: `13. Allow Multiple Purchases`
     */
    function viewSaleState(uint SaleIndex) external view returns(Sale memory) { return Sales[SaleIndex]; }

    /***************************/
    /******** MODIFIER *********/
    /***************************/

    /**
     * @dev Restricts Certain Functions To Bright Moments Operators Only
     */
    modifier onlyBRTOperator
    {
        require(BRTOperators[msg.sender], "User Is Not A Valid BRT Operator");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/utils/SafeERC20.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 */
contract PaymentSplitter is Context {
    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;

    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _released;
    address[] private _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     */
    constructor(address[] memory payees, uint256[] memory shares_) payable {
        require(payees.length == shares_.length, "PaymentSplitter: payees and shares length mismatch");
        require(payees.length > 0, "PaymentSplitter: no payees");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }
    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(account, totalReceived, released(account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _released[account] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) public virtual {
        require(_shares[account] > 0, "PaymentSplitter: account has no shares");

        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        uint256 payment = _pendingPayment(account, totalReceived, released(token, account));

        require(payment != 0, "PaymentSplitter: account is not due payment");

        _erc20Released[token][account] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        address account,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "PaymentSplitter: account is the zero address");
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(_shares[account] == 0, "PaymentSplitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares = _totalShares + shares_;
        emit PayeeAdded(account, shares_);
    }
}

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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