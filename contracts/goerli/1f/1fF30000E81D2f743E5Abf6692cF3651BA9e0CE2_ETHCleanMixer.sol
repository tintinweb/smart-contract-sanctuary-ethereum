//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./CleanMixer.sol";

contract ETHCleanMixer is CleanMixer {
    constructor(
        IVerifier _verifier,
        IBlacklistControl _blacklistControl,
        ITwoLevelReferral _twoLevelReferral,
        uint256 _denomination,
        uint32 _merkleTreeHieght,
        Hasher _hasher
    ) CleanMixer(_verifier, _blacklistControl, _twoLevelReferral, _denomination, _merkleTreeHieght, _hasher) {}

    function _processDeposit(address _referrer) internal override {
        require(msg.value >= denomination, "Please send `mixDenomination` ETH along with transaction");
        _payReferral(msg.sender, _referrer, denomination);
    }

    function _payReferral(
        address _depositor,
        address _referrerAddress,
        uint256 _denomination
    ) internal {
        bool success = false;
        address rootOwner = owner();
        uint16 decimal = twoLevelReferral.getDecimal();
        uint8 rootOwnerPercentage0 = twoLevelReferral.getRootOwnerPercentage(0);
        uint8 rootOwnerPercentage1 = twoLevelReferral.getRootOwnerPercentage(1);
        uint8 rootOwnerPercentage2 = twoLevelReferral.getRootOwnerPercentage(2);

        if (_referrerAddress != address(0)) {
            // save depositor first
            twoLevelReferral.saveDepositor(_depositor, _referrerAddress);

            uint256 firstLevelPayAmount = twoLevelReferral.calculateFirstLevelPay(_denomination);

            // check second level
            address secondLevelRef = twoLevelReferral.getSecondLevel(_referrerAddress);

            if (secondLevelRef != address(0)) {
                // existing second level
                uint256 secLevelPayAmount = twoLevelReferral.calculateSecondLevelPay(_denomination);

                // Send 0.1% to the second level refferer if decimal is 1000
                (success, ) = secondLevelRef.call{value: secLevelPayAmount}("");
                require(success, "Transfer Failed");

                // Send 0.5% to firstLevel
                (success, ) = _referrerAddress.call{value: firstLevelPayAmount}("");
                require(success, "Transfer Failed");

                // Send 0.4% to the root owner if decimal is 1000
                (success, ) = rootOwner.call{value: (_denomination * rootOwnerPercentage0) / decimal}("");
                require(success, "Transfer Failed");
            } else {
                // no second level
                // Send 0.5% to firstLevel
                (success, ) = _referrerAddress.call{value: firstLevelPayAmount}("");
                require(success, "Transfer Failed");

                (success, ) = rootOwner.call{value: (_denomination * rootOwnerPercentage1) / decimal}("");
                require(success, "Transfer Failed");
            }
        } else {
            // send 1% direct to owner
            (success, ) = rootOwner.call{value: (_denomination * rootOwnerPercentage2) / decimal}("");
            require(success, "Transfer Failed");
        }
    }

    function _payGasToRelayer(uint256 _withdrawGasPrice) internal {
        bool success = false;
        (success, ) = msg.sender.call{value: _withdrawGasPrice}("");
        require(success, "_payGasToRelayer did not go thru");
    }

    function _processWithdraw(address payable _recipient, uint256 _relayGasFee) internal override {
        require(denomination != 0, "denomination must not be equal to zero");
        require(msg.value == 0, "msg.value is supposed to be zero for ETH instance");
        bool success = false;
        uint256 twoLvfee = (denomination * twoLevelReferral.getTotalFee()) / twoLevelReferral.getDecimal();

        (success, ) = _recipient.call{value: denomination - twoLvfee - _relayGasFee}("");
        if (_relayGasFee > 0) {
            //send gas to relayer
            _payGasToRelayer(_relayGasFee);
        }

        require(success, "_processWithdraw did not go thru");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./MerkleTree.sol";

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external view returns (bool r);
}

interface IBlacklistControl {
    function isAddressBlacklisted(address _address) external returns (bool);
}

interface ITwoLevelReferral {
    function payReferral(
        address _depositor,
        address _referrerAddress,
        uint256 _denomination
    ) external;

    function getTotalFee() external returns (uint8);

    function getDecimal() external returns (uint16);

    function saveDepositor(address _depositor, address _referrerAddress) external;

    function getSecondLevel(address _referrerAddress) external returns (address);

    function calculateFirstLevelPay(uint256 _denomination) external returns (uint256);

    function calculateSecondLevelPay(uint256 _denomination) external returns (uint256);

    function getRootOwnerPercentage(uint256 _index) external returns (uint8);
}

abstract contract CleanMixer is MerkleTree, Ownable, ReentrancyGuard {
    IVerifier public verifier;
    IBlacklistControl public blacklistControl;
    ITwoLevelReferral public twoLevelReferral;

    uint256 public denomination;

    address public relayerAddress;
    address public officialMirrorSiteAddress;

    // we store all commitments just to prevent accidental deposits with the same commitment
    mapping(bytes32 => bool) public commitments;
    mapping(bytes32 => bool) public nullifierHashes;

    event Deposit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);
    event Withdrawal(address to, bytes32 nullifierHashes, address indexed relayer, uint256 fee);

    constructor(
        IVerifier _verifier,
        IBlacklistControl _blacklistControl,
        ITwoLevelReferral _twoLevelReferral,
        uint256 _denomination,
        uint32 _merkleTreeHieght,
        Hasher _hasher
    ) MerkleTree(_merkleTreeHieght, _hasher) {
        require(_denomination > 0, "denomination should be greater than zero");
        verifier = _verifier;
        blacklistControl = _blacklistControl;
        twoLevelReferral = _twoLevelReferral;
        denomination = _denomination;
        relayerAddress = owner();
    }

    function deposit(bytes32 _commitment, address _referrer) public payable nonReentrant {
        require(!commitments[_commitment], "The commitment has been submitted");
        require(!blacklistControl.isAddressBlacklisted(msg.sender), "Banned address");

        uint32 insertedIndex = _insert(_commitment);
        commitments[_commitment] = true;
        _processDeposit(_referrer);

        emit Deposit(_commitment, insertedIndex, block.timestamp);
    }

    function _processDeposit(address _referrer) internal virtual;

    function withdraw(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _relayerGasfee,
        uint256 _refund
    ) external payable nonReentrant {
        require(_relayerGasfee <= denomination, "Fee exceeds transfer value");
        require(!nullifierHashes[_nullifierHash], "The note has been already spent");
        require(isKnownRoot(_root), "Cannot find your merkle root");
        require(verifier.verifyProof(a, b, c, input), "Invalid withdraw proof");

        nullifierHashes[_nullifierHash] = true;
        _processWithdraw(_recipient, _relayerGasfee);

        emit Withdrawal(_recipient, _nullifierHash, _relayer, _relayerGasfee);
    }

    function _processWithdraw(address payable _recipient, uint256 _relayGasFee) internal virtual;

    function isSpent(bytes32 _nullifierHash) public view returns (bool) {
        return nullifierHashes[_nullifierHash];
    }

    function updateRelayerAddress(address _address) external onlyOwner {
        relayerAddress = _address;
    }

    function updateBlackListControlAddress(IBlacklistControl _blacklistControl) external onlyOwner {
        blacklistControl = _blacklistControl;
    }

    // officialMirrorSiteAddress
    function updateMirrorSiteAddress(address _address) external onlyOwner {
        officialMirrorSiteAddress = _address;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Hasher {
    function MiMCSponge(
        uint256 xL_in,
        uint256 xR_in,
        uint256 k
    ) external pure returns (uint256 xL, uint256 xR);
}

contract MerkleTree {
    uint256 public constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 public constant ZERO_VALUE = 21663839004416932945382355908790599225266501822907911457504978515578255421292; // = keccak256("tornado") % FIELD_SIZE

    uint32 public levels;
    Hasher public hasher;

    // for insert calculation
    bytes32[] public zeros;
    bytes32[] public filledSubtrees;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;
    uint32 public constant ROOT_HISTORY_SIZE = 100;
    bytes32[ROOT_HISTORY_SIZE] public roots;

    constructor(uint32 _levels, Hasher _hasher) {
        require(_levels > 0, "_level should be greater than zero");
        require(_levels < 32, "_level should be less than 32");
        levels = _levels;
        hasher = _hasher;

        // fill zeros and filledSubtrees depend on levels
        bytes32 currentZero = bytes32(ZERO_VALUE);
        zeros.push(currentZero);
        filledSubtrees.push(currentZero);
        for (uint32 i = 1; i < levels; i++) {
            currentZero = hashLeftRight(currentZero, currentZero);
            zeros.push(currentZero);
            filledSubtrees.push(currentZero);
        }

        roots[0] = hashLeftRight(currentZero, currentZero);
    }

    function hashLeftRight(bytes32 _left, bytes32 _right) public view returns (bytes32) {
        require(uint256(_left) < FIELD_SIZE, "_left should be inside the field");
        require(uint256(_right) < FIELD_SIZE, "_right should be inside the field");
        uint256 R = uint256(_left);
        uint256 C = 0;
        uint256 k = 0;
        (R, C) = hasher.MiMCSponge(R, C, k);
        R = addmod(R, uint256(_right), FIELD_SIZE);
        (R, C) = hasher.MiMCSponge(R, C, k);
        return bytes32(R);
    }

    function _insert(bytes32 _leaf) internal returns (uint32 index) {
        uint32 currentIndex = nextIndex;
        require(currentIndex < uint32(2)**levels, "Merkle tree is full. No more leaf can be added");
        nextIndex += 1;
        bytes32 currentLevelHash = _leaf;
        bytes32 left;
        bytes32 right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros[i];
                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }

            currentLevelHash = hashLeftRight(left, right);
            currentIndex /= 2;
        }

        currentRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        roots[currentRootIndex] = currentLevelHash;
        return nextIndex - 1;
    }

    function isKnownRoot(bytes32 _root) public view returns (bool) {
        if (uint256(_root) == 0) {
            return false;
        }

        uint32 i = currentRootIndex;
        do {
            if (roots[i] == _root) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != currentRootIndex);
        return false;
    }

    function getLastRoot() public view returns (bytes32) {
        return roots[currentRootIndex];
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