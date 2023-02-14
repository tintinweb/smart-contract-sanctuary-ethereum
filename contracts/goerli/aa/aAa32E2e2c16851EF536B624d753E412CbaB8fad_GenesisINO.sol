// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

interface IGenesisNFT {
    function mint(address to) external;
}

struct Stage{
    uint256 amount;
    uint256 quantity;
    uint256 maxBuy;
    uint256 startTime;
    uint256 endTime;
    bool isWhitelist;
}

contract GenesisINO is Ownable, Pausable {
    IGenesisNFT public genesisNFT;

    uint256 public nTotalJoined;
    uint256 public currentStage;
    mapping (uint256 => Stage) public stages; // stage_id => State struct
    mapping (uint256 => mapping (address => bool)) public stageWhiteList; // stage_id => address => whitelist?
    mapping (uint256 => uint256) public nStateJoined; // stage_id => joined quantity
    mapping (uint256 => mapping (address => uint256)) public stageBought; // stage_id => address => bought
    
    event Join(address user, uint256 state, uint256 quantity, uint256 amount);

    modifier isNotContract(address user) {
        require(_checkIsNotCallFromContract());
		require(_isNotContract(user));
		_;
	}

    modifier openToBuy() {
        require(block.timestamp >= stages[currentStage].startTime, "GenesisINO::not buy time yet");
        require(block.timestamp <= stages[currentStage].endTime, "GenesisINO::closed to buy");
        _;
    }

    constructor(address _genesisNFT) {
        genesisNFT = IGenesisNFT(_genesisNFT);
    }

    function joinINO(uint256 _quantity) external isNotContract(_msgSender()) whenNotPaused openToBuy payable {
        address sender = _msgSender();
        Stage memory _state = stages[currentStage];

        /* CHECK */
        require (isJoinable(sender, _quantity), "GenesisINO::user cannot join");
        require (msg.value >= _state.amount * _quantity, "GenesisINO::transfer Coin failed");
        
        /* INTERACTION */
        for (uint256 i = 0; i < _quantity; i++) {
            genesisNFT.mint(sender);
        }

        /* EFFECT */
        nTotalJoined += _quantity;
        stageBought[currentStage][sender] += _quantity;
        nStateJoined[currentStage] += _quantity;

        emit Join(msg.sender, currentStage, _quantity, msg.value);
    }

     /// SALE CONFIG
    function updateWhitelist(uint256 _state, address [] calldata _whitelists) external onlyOwner {
        for (uint i; i < _whitelists.length; i++) {
            stageWhiteList[_state][_whitelists[i]] = true;
        }
	}

    function removeWhitelist(uint256 _state, address [] calldata _whitelists) external onlyOwner {
        for (uint i; i < _whitelists.length; i++) {
            stageWhiteList[_state][_whitelists[i]] = false;
        }
	}

    function setGenesisNFT(address _genesisNFT) external onlyOwner {
        genesisNFT = IGenesisNFT(_genesisNFT);
	}

    function setStage(uint stageId, uint256 amount, uint256 quantity, uint256 maxBuy, uint256 startTime, uint256 endTime, bool isWhitelist) external onlyOwner {
        stages[stageId] = Stage(amount, quantity, maxBuy, startTime, endTime, isWhitelist);
	}

    function setCurrentStage(uint stageId) external onlyOwner {
        currentStage = stageId;
	}

    function withdrawBalance(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }

     /// ADMINISTATION
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// CONDITIONAL CHECKS

    function isJoinable(address buyer, uint256 _quantity) public view returns (bool) {
        if(currentStage == 0 || paused()) {
            return false;
        }
        
        Stage memory _state = stages[currentStage];

        // check NFT quantity for Stage
        if(nStateJoined[currentStage] + _quantity > _state.quantity) {
            return false;
        }

        // check max buy for each address
        if(
            _state.maxBuy == 0 ||
            stageBought[currentStage][buyer] + _quantity <= _state.maxBuy
        ){

            // check Stage is whitelist or not
            if(_state.isWhitelist) {
                return stageWhiteList[currentStage][buyer];
            } else {
                return true;
            }  
        }
 
        return false; 
    }

    function _isNotContract(address _addr) internal view returns (bool){
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size == 0);
    }

    function _checkIsNotCallFromContract() internal view returns (bool){
	    if (msg.sender == tx.origin){
		    return true;
	    } else{
	        return false;
	    }
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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