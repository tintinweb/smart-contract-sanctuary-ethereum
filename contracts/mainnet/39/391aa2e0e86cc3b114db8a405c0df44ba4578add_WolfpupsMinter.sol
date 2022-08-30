/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-30
*/

/**
 *Submitted for verification at BscScan.com on 2022-08-30
*/

// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;



pragma solidity  ^0.8.1;


    
contract WolfpupsMinter is Ownable, ReentrancyGuard {
     
     address public nftaddress; 
     bool public claimenabled = false; 
     address public wolf = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
     uint256 public wolflimit;
     uint256 public redeemstarttingrange;
     uint256 public redeemendrange;
     uint256 public claimIndex;
     address public nftAdmin = 0x8fFAeBAcbc3bA0869098Fc0D20cA292dC1e94a73;
     uint256 public price;
     mapping (address => uint256) public userinvested;
     address[] public investors;
     mapping (address => bool) public existinguser;
     mapping (address => bool) public iswhitelist;
     uint256 public maxInvestment;   
     uint public icoTarget;
     uint public receivedFund=0;
     enum Round {Whitelistround, PublicRound}
     Round public round;

     event Claim(address indexed user, uint256 indexed tokenid);
   
   
    function getRound() external view returns(Round) {
        return round;
    }

   function startWhitelistinground() external onlyOwner {
        round = Round.Whitelistround;
    }

   function startPublicround() external onlyOwner {
        round = Round.PublicRound;
    }

    function trade(uint _noofnfts) public payable nonReentrant {
        
        require (claimenabled == true, "Claim not enabled");   
        require (_noofnfts>0, "nonzero value not accepted");

        if (round == Round.Whitelistround) {
           require(iswhitelist[msg.sender], "not whitelised");
        }
         uint256 _amount = price * _noofnfts;
          
         require(_amount == msg.value, "incorrect amount");
           
          // check wolf balance 
          require (IERC20(wolf).balanceOf(msg.sender) >= wolflimit, "Hold wolf to Participate");
    
          //check for hard cap
          require(icoTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
     
          //  require(_amount > 0 , "min Investment not zero");
          uint256 checkamount = userinvested[msg.sender] + _amount;
     
          //check maximum investment        
           require(checkamount <= maxInvestment, "Already max Invested"); 
     
          // check for existinguser
          if (!existinguser[msg.sender]) {
            existinguser[msg.sender] = true;
            investors.push(msg.sender);
          }
     
           userinvested[msg.sender] += _amount; 
           receivedFund = receivedFund + _amount;
             
           IERC721 nft = IERC721(nftaddress); 
           
           uint256 nftidstart = redeemstarttingrange + claimIndex;  
           uint nftidend = nftidstart + _noofnfts;       
           assert (nftidend <= redeemendrange);   
           claimIndex += _noofnfts;

           for ( uint i = nftidstart; i < nftidend; i++ ) {   
               nft.safeTransferFrom(nftAdmin, msg.sender, i);
               emit Claim(msg.sender,i);
           }
     }

    function remainigContribution(address _owner) public view returns (uint256) {
        uint256 remaining = maxInvestment - userinvested[_owner];
        return remaining;
    }
     
    function withdarw(address payable _admin) public onlyOwner{
       uint256 raisedamount = address(this).balance;
       (bool sent,) = _admin.call{value: raisedamount}("");
       require(sent, "ETH Transfer Failed: ");
    }
    
    function setclaimStatus(bool _status) external onlyOwner {
       claimenabled = _status;
    }
    
    function setwolflimit(uint256 _newlimit) public onlyOwner {
        wolflimit = _newlimit;   
    }
              
    function changenftadmin(address _add) public onlyOwner  {
        nftAdmin = _add; 
    }
    
    function changeIcotarget(uint256 _newvalue) public onlyOwner {
        icoTarget = _newvalue; 
    }
    
    function changeredeemeendlimit(uint256 _newvalue) public onlyOwner {
        redeemendrange = _newvalue; 
    }
    
    function changeredeemstartlimit(uint256 _newvalue) public onlyOwner {
        redeemstarttingrange = _newvalue; 
    }
    
    function changenftaddress(address _add) public onlyOwner {
        nftaddress = _add;
    }
       
    function changetokenaddress(address _add) public onlyOwner {
        wolf = _add;
    }

    function changeMaxInvestment(uint _newmax) external onlyOwner {
        require (icoTarget > _newmax, "Incorrect maxinvestment value");
        require (_newmax > maxInvestment, "Incorrect maxinvestment value");
        maxInvestment = _newmax;
    }
       
    function resetICO() public onlyOwner {
        
         for (uint256 i = 0; i < investors.length; i++) {
            if (existinguser[investors[i]]==true)
            {
                  existinguser[investors[i]]=false;
                  userinvested[investors[i]] = 0;
            }
        }
        
        icoTarget = 0;
        receivedFund = 0;
        maxInvestment = 0;
        nftaddress =   0x0000000000000000000000000000000000000000;
        claimenabled = false;
        redeemstarttingrange = 0;
        redeemendrange = 0;
        claimIndex = 0;
        price = 0 ; 
        delete investors;
    }

    function changePrice(uint _newprice) external onlyOwner {
        price = _newprice;
    }

    function Whitelist(address _add, bool _value ) external onlyOwner {
        iswhitelist[_add] = _value;
    }

    function addMultipleWhitelist(address[] memory _add) external onlyOwner {
        require (_add.length <=100, "too many users");
        for (uint i=0; i<_add.length; i++) {
            iswhitelist[_add[i]] = true;
        }
    }     
    
    function initializeICO(uint256 _price, address _nftaddress, uint256 _icotarget, uint256 _maxinvestment, uint256 _nftstartingrange, uint256 _nftendrange) public onlyOwner 
    {
        require (_nftendrange>_nftstartingrange, "incorrect range") ;  
        nftaddress = _nftaddress;
        icoTarget = _icotarget;
        redeemstarttingrange = _nftstartingrange;
        redeemendrange = _nftendrange;
        price  =_price;
        require (icoTarget > _maxinvestment, "Incorrect maxinvestment value");
        maxInvestment = _maxinvestment;
    }
}