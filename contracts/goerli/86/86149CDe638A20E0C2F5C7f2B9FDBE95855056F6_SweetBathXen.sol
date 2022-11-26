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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
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
pragma solidity ^0.8.17;


interface IMiniProxySweet {

    function sweetClaimRank(uint _term) external;

    function sweetClaimRewardTo(address _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IXEN {
    function claimRank(uint256 term) external;

    function claimMintRewardAndShare(address other, uint256 pct) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IXEN.sol";
import "./IMiniProxySweet.sol";

contract MiniProxySweetMiner is IMiniProxySweet {

    address public immutable sweetBathOriginal;

    address public immutable original;

    address public immutable xen;

    constructor(address _sweetBatch, address _xen){
        sweetBathOriginal = _sweetBatch;
        original = address(this);
        xen = _xen;
    }

    /**
      * @dev Throws if called by any miner other than the owner.
     */
    modifier onlySweetBathOriginal(){
        _sweetOriginal();
        _;
    }

    /**
     * @dev Throws if the sender is not the original.
     */
    function _sweetOriginal() internal view virtual {
        require(msg.sender == sweetBathOriginal, "Insufficient permissions");
    }

    function sweetClaimRank(uint _term) external onlySweetBathOriginal {
        IXEN(xen).claimRank(_term);
    }

    function sweetClaimRewardTo(address _to) external onlySweetBathOriginal {
        IXEN(xen).claimMintRewardAndShare(_to, 100);
        if (address(this) != original) {
            selfdestruct(payable(tx.origin));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./MiniProxySweetMiner.sol";
import "./IMiniProxySweet.sol";


contract SweetBathXen is Ownable {

    address private immutable original;

    address private immutable deployer;

    address public immutable _miniProxy;

    mapping(address => uint256) public countSweetMint;

    mapping(address => uint256) public countSweetReward;

    mapping(address => bool) public miners;

    uint256 public initializeMinerFee;

    uint256 public totalSupplySweetMint;

    uint256 public totalSupplySweetReward;

    constructor(uint256 _initMinerFee, address _xenAddress){
        original = address(this);
        deployer = msg.sender;
        miners[msg.sender] = true;
        initializeMinerFee = _initMinerFee;
        _miniProxy = address(new MiniProxySweetMiner(original, _xenAddress));
    }

    event SweetBatchMint(address miner, uint256 users, uint256 term);

    event SweetBatchReward (address miner, uint256 users);

    event SweetBatchRewardIndex(address miner, uint256 start, uint256 end);

    event PaymentReceived(address from, uint256 amount);

    event InitializeMiner(address miner);


    /**
     * @dev Throws if called by any miner other than the owner.
     */
    modifier onlyMiner() {
        _checkMiner();
        _;
    }


    /**
     * @dev Throws if the sender is not the miner.
     */
    function _checkMiner() internal view virtual {
        require(miners[_msgSender()], "Not yet miner");
    }


    function setMiner(address[] calldata _miners) external
    onlyOwner {
        for (uint256 i; i < _miners.length; i++) {
            _setMiner(_miners[i]);
        }
    }

    function _setMiner(address _miner) internal {
        miners[_miner] = true;
    }

    function setInitializeMinerFee(uint256 _initializeMinerFee) external
    onlyOwner {
        initializeMinerFee = _initializeMinerFee;
    }


    function initializeMiner() external payable {
        require(msg.value == initializeMinerFee, "Initialize batch miner failed");
        require(!miners[_msgSender()], "Miner repeated initialize");
        _setMiner(_msgSender());
        require(miners[_msgSender()], "Failed to initialize Miner!");
        emit InitializeMiner(_msgSender());
    }

    function sweetMint(uint256 users, uint256 term) external onlyMiner {
        require(users > 0, "users Greater than 0");
        require(term > 0, "Term Greater than 0");
        uint256 sm = countSweetMint[msg.sender];
        for (uint i = sm; i < sm + users; i++) {
            bytes32 salt = keccak256(abi.encodePacked(msg.sender, i));
            address proxy = Clones.cloneDeterministic(_miniProxy, salt);
            IMiniProxySweet(proxy).sweetClaimRank(term);
        }
        countSweetMint[msg.sender] = sm + users;
        totalSupplySweetMint = totalSupplySweetMint + users;
        emit SweetBatchMint(msg.sender, users, term);
    }


    function proxyFor(address sender, uint256 i) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        return Clones.predictDeterministicAddress(_miniProxy, salt);
    }

    function sweetReward(uint256 users) external onlyMiner {
        require(countSweetMint[msg.sender] > 0, "No mint record yet");
        require(users > 0, "Users Greater than 0");
        uint256 sm = countSweetMint[msg.sender];
        uint256 sr = countSweetReward[msg.sender];
        uint256 s = sr + users < sm ? sr + users : sm;
        uint256 rsi;
        for (uint i = sr; i < s; i++) {
            address proxy = proxyFor(msg.sender, i);
            if (!_contractExists(proxy)) {
                continue;
            }
            IMiniProxySweet(proxy).sweetClaimRewardTo(msg.sender);
            rsi++;
        }
        countSweetReward[msg.sender] = s;
        totalSupplySweetReward = totalSupplySweetReward + rsi;
        emit SweetBatchReward(msg.sender, users);
    }

    function _contractExists(address proxy) internal view returns (bool){
        uint size;
        assembly {
            size := extcodesize(proxy)
        }
        return size > 0;
    }


    function sweetBatchRewardIndex(uint256 _userSI, uint256 _userEI) external onlyMiner {
        require(_userSI < _userEI, "_userSI greater than _userEI");
        require(countSweetMint[msg.sender] > 0, "No mint record yet");
        require(_userEI <= countSweetMint[msg.sender], "Claim Reward Limit Exceeded");
        uint256 rsi;
        for (uint i = _userSI; i <= _userEI; i++) {
            address proxy = proxyFor(msg.sender, i);
            if (!_contractExists(proxy)) {
                continue;
            }
            IMiniProxySweet(proxy).sweetClaimRewardTo(msg.sender);
            rsi++;
        }
        totalSupplySweetReward = totalSupplySweetReward + rsi;
        emit SweetBatchRewardIndex(msg.sender, _userSI, _userEI);
    }

    function withdraw(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            uint256 balance = address(this).balance;
            require(balance > 0, "No balance to withdraw");
            (bool success,) = payable(msg.sender).call{value : balance}("");
            require(success, "Failed to withdraw payment");
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 _ercBalance = erc20token.balanceOf(address(this));
        require(_ercBalance > 0, "No balance to withdraw");
        bool _ercSuccess = erc20token.transfer(owner(), _ercBalance);
        require(_ercSuccess, "Failed to withdraw payment");
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }
}