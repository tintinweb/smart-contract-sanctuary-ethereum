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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: GNU
pragma solidity >=0.8.0;

interface INFTRegistry {

    // Enums
    enum NamingCurrency {
        Ether,
        RNM,
        NamingCredits
    }
   
    function changeName(address nftAddress, uint256 tokenId, string calldata newName, NamingCurrency namingCurrency) external payable;
    function namingPriceEther() external view returns (uint256);
    function namingPriceRNM() external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface INamingCredits {
    function credits(address sender) external view returns (uint256);
    function reduceNamingCredits(address sender, uint256 numberOfCredits) external;
    function assignNamingCredits(address user, uint256 numberOfCredits) external;
    function shutOffAssignments() external;
    function shutOffAssignerAssignments() external;
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IRNM is IERC20 {
    function SUPPLY_CAP() external view returns (uint256);

    function mint(address account, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./IWETH.sol";
import "./INamingCredits.sol";
import "./INFTRegistry.sol";
import "./IRNM.sol";

/**
 * @title NamingCredits
 * @notice Allows naming credits to be bought in bulk, and later consumed by NFTRegistry contract to name. Proceeds are forwarded to a protocol fee receiver contract. Owner is the NFTRegistry contract
 */
contract NamingCredits is ReentrancyGuard, Ownable, INamingCredits {

    // Enums
    enum AssignmentsAllowed {
        NO,
        YES
    }  

    enum BuyWithETH { 
        NO, 
        YES
    }

    AssignmentsAllowed public assignmentsAllowed;
    AssignmentsAllowed public assignerAssignmentsAllowed;
    bool public allowUpdatingFeeRecipient = true;

    uint256 public constant MAX_CREDITS_ASSIGNED = 10; // number of credits
    uint256 public constant MAX_BULK_ASSIGNMENT = 50; // number of addresses
    uint256 public constant MAX_ASSIGNER_CREDITS = 100; // number of credits

    // Credit balances
    mapping (address => uint256) public override credits;

    // Relevant addresses
    INFTRegistry public immutable nftrAddress;
    address public protocolFeeRecipient;
    address public immutable WETH;
    mapping (address => uint256) public assigners;
    address private tempAdmin;
    IRNM public rnmAddress;

    // Events
    event RNMAddressSet(address rnmAddress);   
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    event CreditsBought(address indexed sender, uint256 numberOfCredits, BuyWithETH buyWithETH, uint256 totalCost);
    event CreditsConsumed(address indexed sender, uint256 numberOfCredits);
    event AssignerCreditsAdded(address indexed assigner, uint256 numberOfCredits);
    event CreditsAssigned(address indexed assigner, address indexed receiver, uint256 numberOfCredits);
    event AssignmentsShutOff();    
    event AssignerAssignmentsShutOff();   

    /**
     * @notice Constructor
     * @param _protocolFeeRecipient protocol fee recipient
     * @param _WETH address of the WETH contract. It's input to constructor to allow for testing.
     * @param _nftrAddress address of the NFT Registry contract
     */
    constructor(address _protocolFeeRecipient, address _WETH, address _nftrAddress) {
        protocolFeeRecipient = _protocolFeeRecipient;
        WETH = _WETH;
        assignmentsAllowed = AssignmentsAllowed.YES;
        assignerAssignmentsAllowed = AssignmentsAllowed.YES;
        nftrAddress = INFTRegistry(_nftrAddress);
        tempAdmin = msg.sender;
        transferOwnership(_nftrAddress);
    }  

    /**
     * @notice Transfer tempAdmin status to another address
     * @param newAdmin address of the new tempAdmin address
     */
    function transferTempAdmin(address newAdmin) external {
        require(msg.sender == tempAdmin, "NamingCredits: Only tempAdmin can transfer");
        
        tempAdmin = newAdmin;
    }        

    /**
     * @notice Set the address of the RNM contract. Can only be set once.
     * @param _rnmAddress address of the RNM contract
     */
    function setRNMAddress(address _rnmAddress) public {
        require(msg.sender == tempAdmin, "NamingCredits: Only tempAdmin can set RNM Address");
        require(address(rnmAddress) == address(0), "NamingCredits: RNM address can only be set once");
        
        rnmAddress = IRNM(_rnmAddress);

        emit RNMAddressSet(address(rnmAddress));
    }       

    /**
     * @notice Update the recipient of protocol (naming credit) fees in WETH
     * @param _protocolFeeRecipient protocol fee recipient
     */
    function updateProtocolFeeRecipient(address _protocolFeeRecipient) public override onlyOwner {
         require(allowUpdatingFeeRecipient, "NFTRegistry: Updating the protocol fee recipient has been shut off");
        require(protocolFeeRecipient != _protocolFeeRecipient, "NamingCredits: Setting protocol recipient to the same value isn't allowed");
        protocolFeeRecipient = _protocolFeeRecipient;

        emit NewProtocolFeeRecipient(protocolFeeRecipient);
    }        

    /**
     * @notice Shut off protocol fee recipient updates
     */
    function shutOffFeeRecipientUpdates() external {
        require(msg.sender == tempAdmin, "NamingCredits: Only tempAdmin can shut off recipient updates");
        allowUpdatingFeeRecipient = false;
    }        

    /**
     * @notice Buy naming credits
     * @param numberOfCredits number of credits to buy
     * @param buyWithETH whether to by with ETH or RNM
     * @param currencyQuantity quantity of naming currency to spend. This disables the NFTRegistry contract owner from being able to front-run naming to extract unintended quantiy of assets (WETH or RNM)
     */
    function buyNamingCredits(uint256 numberOfCredits, BuyWithETH buyWithETH, uint256 currencyQuantity) external payable nonReentrant {
        if (buyWithETH == BuyWithETH.YES) {
            require(currencyQuantity == (numberOfCredits * INFTRegistry(nftrAddress).namingPriceEther()), "NamingCredits: when purchasing with Ether, currencyQuantity must be equal to namingPriceEther multiplied by number of credits"); 
        }
        else { // namingCurrency is RNM
            require(address(rnmAddress) != address(0), "NamingCredits: RNM address hasn't been set yet");
            require(currencyQuantity == (numberOfCredits * INFTRegistry(nftrAddress).namingPriceRNM()), "NamingCredits: when purchasing with RNM, currencyQuantity must be equal to namingPriceRNM multiplied by number of credits");                         
        }        

        uint256 totalCost; // in wei or RNM

        if (buyWithETH == BuyWithETH.YES) {

            // If not enough ETH to cover the price, use WETH
            if ((numberOfCredits * INFTRegistry(nftrAddress).namingPriceEther()) > msg.value) {
                require(IERC20(WETH).balanceOf(msg.sender) >= ((numberOfCredits * INFTRegistry(nftrAddress).namingPriceEther()) - msg.value), "NFTRegistry: Not enough ETH sent or WETH available");
                IERC20(WETH).transferFrom(msg.sender, address(this), ((numberOfCredits * INFTRegistry(nftrAddress).namingPriceEther()) - msg.value));
            } else {
                require((numberOfCredits * INFTRegistry(nftrAddress).namingPriceEther()) == msg.value, "NFTRegistry: Too much Ether sent");
            }

            // Wrap ETH sent to this contract
            IWETH(WETH).deposit{value: msg.value}();
            totalCost = (numberOfCredits * INFTRegistry(nftrAddress).namingPriceEther());
            IERC20(WETH).transfer(protocolFeeRecipient, totalCost);

        }
        else { // Buying with RNM

            totalCost = nftrAddress.namingPriceRNM() * numberOfCredits;

            IERC20(rnmAddress).transferFrom(msg.sender, address(this), totalCost);
            IRNM(rnmAddress).burn(totalCost);

        }

        // Add credits
        credits[msg.sender] += numberOfCredits;

        emit CreditsBought(msg.sender, numberOfCredits, buyWithETH, totalCost);
    }

    /**
     * @notice Assign naming credits as incentives. There is the ability to shut this down and never bring it back.
     * @param user the address to which naming credits will be assigned
     * @param numberOfCredits number of credits to assign
     */
    function assignNamingCredits(address user, uint256 numberOfCredits) external override nonReentrant  {

        require((msg.sender == owner()) || (assigners[msg.sender] >= numberOfCredits && assignerAssignmentsAllowed == AssignmentsAllowed.YES), "NamingCredits: Only owner (until maxed out) or assigner (temporarily) can assign credits.");
        require(numberOfCredits <= MAX_CREDITS_ASSIGNED, "NamingCredits: Too many credits to assign");
        require(assignmentsAllowed == AssignmentsAllowed.YES, "NamingCredits: Assigning naming credits has been shut off forever");

        // Add credits
        if (msg.sender != owner()) {
            assigners[msg.sender] -= numberOfCredits;
        }
        credits[user]+=numberOfCredits;

        emit CreditsAssigned(msg.sender, user, numberOfCredits);
    } 

    /**
     * @notice Assign naming credits as incentives in bulk. There is the ability to shut this down and never bring it back.
     * @param numberOfCredits number of credits to assign
     */
    function assignNamingCreditsBulk(address[] memory user, uint256[] memory numberOfCredits) external nonReentrant {

        require((msg.sender == owner()) || (assigners[msg.sender] > 0 && assignerAssignmentsAllowed == AssignmentsAllowed.YES), "NamingCredits: Only owner (until maxed out) or assigner (temporarily) can assign credits.");
        require(assignmentsAllowed == AssignmentsAllowed.YES, "NamingCredits: Assigning naming credits has been shut off forever");    
        require(user.length == numberOfCredits.length, "NamingCredits: Assignment arrays must have the same length");   
        require(user.length <= MAX_BULK_ASSIGNMENT, "NamingCredits: Can't assign to so many addresses in bulk");
        for (uint i = 0; i < user.length; i++) {
            require(numberOfCredits[i] <= MAX_CREDITS_ASSIGNED, "NamingCredits: Too many credits to assign");

            // Add credits
            if (msg.sender != owner()) {
                require(assigners[msg.sender] >= numberOfCredits[i], "NamingCredits: Not enough credits left to assign by this assigner");
                assigners[msg.sender] -= numberOfCredits[i];
            }            
            credits[user[i]]+=numberOfCredits[i];

            emit CreditsAssigned(msg.sender, user[i], numberOfCredits[i]);
        }
    }     

    /**
     * @notice Add assignment credit to an assigner
     * @param assigner new assigner
     * @param numberOfCredits number of credits to assign to assigner
     */
     function addAssignerCredits(address assigner, uint256 numberOfCredits) external {
        require(msg.sender == tempAdmin, "NamingCredits: Only tempAdmin can add assigners");
        require(numberOfCredits <= MAX_ASSIGNER_CREDITS, "NamingCredits: Can't assign that many credits to an assigner");
        assigners[assigner] += numberOfCredits;
        emit AssignerCreditsAdded(assigner, numberOfCredits);
     }     

    /**
     * @notice Null an assigner's assignment allowance
     * @param assigner credit assigner
     */
     function nullAssignerCredits(address assigner) external {
        require(msg.sender == tempAdmin, "NamingCredits: Only tempAdmin can null assigners");
        assigners[assigner] = 0;
     }        

    /**
     * @notice Shut off naming credit assignments by assigner. It can't be turned back on.
     */
    function shutOffAssignerAssignments() external override {

        require(msg.sender == tempAdmin, "NamingCredits: Only callable by tempAdmin");        

        assignerAssignmentsAllowed = AssignmentsAllowed.NO;

        emit AssignerAssignmentsShutOff();
    }        

    /**
     * @notice Shut off naming credit assignments. It can't be turned back on.
     */
    function shutOffAssignments() external override onlyOwner {

        assignmentsAllowed = AssignmentsAllowed.NO;

        emit AssignmentsShutOff();
    }        

    /**
     * @notice Consume naming credits. Meant to be consumed by the owner which is the NFTRegistry contract.
     * @param sender the account naming the NFT
     * @param numberOfCredits number of credits to consume
     */
    function reduceNamingCredits(address sender, uint256 numberOfCredits) external override onlyOwner {
        require(credits[sender] >= numberOfCredits, "NamingCredits: Not enough credits");
        credits[sender] -= numberOfCredits;
        
        emit CreditsConsumed(sender, numberOfCredits);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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