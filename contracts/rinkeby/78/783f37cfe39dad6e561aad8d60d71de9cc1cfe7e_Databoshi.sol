/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: GPL-3.0                                                                                                                                                     
                        
                                                                                                                                                               
// DDDDDDDDDDDDD                                 tttt                            BBBBBBBBBBBBBBBBB                                    hhhhhhh               iiii  
// D::::::::::::DDD                           ttt:::t                            B::::::::::::::::B                                   h:::::h              i::::i 
// D:::::::::::::::DD                         t:::::t                            B::::::BBBBBB:::::B                                  h:::::h               iiii  
// DDD:::::DDDDD:::::D                        t:::::t                            BB:::::B     B:::::B                                 h:::::h                     
//   D:::::D    D:::::D  aaaaaaaaaaaaa  ttttttt:::::ttttttt      aaaaaaaaaaaaa     B::::B     B:::::B   ooooooooooo       ssssssssss   h::::h hhhhh       iiiiiii 
//   D:::::D     D:::::D a::::::::::::a t:::::::::::::::::t      a::::::::::::a    B::::B     B:::::B oo:::::::::::oo   ss::::::::::s  h::::hh:::::hhh    i:::::i 
//   D:::::D     D:::::D aaaaaaaaa:::::at:::::::::::::::::t      aaaaaaaaa:::::a   B::::BBBBBB:::::B o:::::::::::::::oss:::::::::::::s h::::::::::::::hh   i::::i 
//   D:::::D     D:::::D          a::::atttttt:::::::tttttt               a::::a   B:::::::::::::BB  o:::::ooooo:::::os::::::ssss:::::sh:::::::hhh::::::h  i::::i 
//   D:::::D     D:::::D   aaaaaaa:::::a      t:::::t              aaaaaaa:::::a   B::::BBBBBB:::::B o::::o     o::::o s:::::s  ssssss h::::::h   h::::::h i::::i 
//   D:::::D     D:::::D aa::::::::::::a      t:::::t            aa::::::::::::a   B::::B     B:::::Bo::::o     o::::o   s::::::s      h:::::h     h:::::h i::::i 
//   D:::::D     D:::::Da::::aaaa::::::a      t:::::t           a::::aaaa::::::a   B::::B     B:::::Bo::::o     o::::o      s::::::s   h:::::h     h:::::h i::::i 
//   D:::::D    D:::::Da::::a    a:::::a      t:::::t    tttttta::::a    a:::::a   B::::B     B:::::Bo::::o     o::::ossssss   s:::::s h:::::h     h:::::h i::::i 
// DDD:::::DDDDD:::::D a::::a    a:::::a      t::::::tttt:::::ta::::a    a:::::a BB:::::BBBBBB::::::Bo:::::ooooo:::::os:::::ssss::::::sh:::::h     h:::::hi::::::i
// D:::::::::::::::DD  a:::::aaaa::::::a      tt::::::::::::::ta:::::aaaa::::::a B:::::::::::::::::B o:::::::::::::::os::::::::::::::s h:::::h     h:::::hi::::::i
// D::::::::::::DDD     a::::::::::aa:::a       tt:::::::::::tt a::::::::::aa:::aB::::::::::::::::B   oo:::::::::::oo  s:::::::::::ss  h:::::h     h:::::hi::::::i
// DDDDDDDDDDDDD         aaaaaaaaaa  aaaa         ttttttttttt    aaaaaaaaaa  aaaaBBBBBBBBBBBBBBBBB      ooooooooooo     sssssssssss    hhhhhhh     hhhhhhhiiiiiiii


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

// File: contracts/databoshi.sol


pragma solidity ^0.8.4;


contract Databoshi is Ownable {
    address public benevolentBoshiModerator;
    mapping(uint256 => bool) public isBoshiStolen;
    mapping(uint256 => uint256) public boshiWins;
    mapping(uint256 => uint256) public boshiLosses;

    modifier onlyOwnerOrBenevolentBoshiModerator() {
        require(msg.sender == benevolentBoshiModerator || msg.sender == owner(), "Caller is not the benevolentBoshiModerator nor is it the owner");
        _;
    }

    function changeBenevolentBoshiModerator(address _benevolentBoshiModerator) public onlyOwnerOrBenevolentBoshiModerator {
        benevolentBoshiModerator = _benevolentBoshiModerator;
    }

    function markBoshiStolen(uint256 _boshiID) public onlyOwnerOrBenevolentBoshiModerator {
        isBoshiStolen[_boshiID] = true; 
    }

    function markBoshiReturned(uint256 _boshiID) public onlyOwnerOrBenevolentBoshiModerator {
        isBoshiStolen[_boshiID] = false; 
    }

    function recordBoshiWin(uint256 _boshiID) public {
        boshiWins[_boshiID]++;   
    }

    function recordBoshiLoss(uint256 _boshiID) public {
        boshiLosses[_boshiID]++;   
    } 

    function killanddelete() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}