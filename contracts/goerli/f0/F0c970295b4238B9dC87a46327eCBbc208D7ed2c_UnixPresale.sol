// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interfaces/IUnixVesting.sol";

contract UnixPresale is Ownable {

    event SetSeedSaleTreeRoot(bytes32 root);
    event SetPublicSaleTreeRoot(bytes32 root);
    event SetStartTime(uint256 _startTime);
    event SetEndTime(uint256 _endTime);
    event SetMinContribution(uint256 _minContribution);
    event SetMaxContribution(uint256 _maxContribution);
    event SetVestingContract(address vesting);
    event Contribute(address contributor, uint256 usdcAmount, uint256 tokenAmount);
    event Withdraw(address receiver, address token, uint256 amount);

    IERC20 public usdcToken;
    IERC20 public unixToken;

    bytes32 public seedSaleTreeRoot;
    bytes32 public publicSaleTreeRoot;
    
    uint256 public minContribution = 500 * 10 ** 6;
    uint256 public maxContribution = 2500 * 10 * 6;

    uint256 public currentStep = 0; /// 0: not started, 1: seed, 2: wl, 3: public
    uint256 public constant seedSalePrice = 150000;
    uint256 public constant wlSalePrice = 200000;

    /// @dev once currentStep is setted, presale period needs to be set again.
    uint256 public startTime;
    uint256 public endTime;

    address public vestingContract;

    mapping (address => uint256) public contributors;

    constructor(address _usdc, address _unix) {
        usdcToken = IERC20(_usdc);
        unixToken = IERC20(_unix);
    }

    function setSeedSaleTreeRoot(bytes32 _root) external onlyOwner {
        seedSaleTreeRoot = _root;
        emit SetSeedSaleTreeRoot(_root);
    }

    function setPublicSaleTreeRoot(bytes32 _root) external onlyOwner {
        publicSaleTreeRoot = _root;
        emit SetPublicSaleTreeRoot(_root);
    }

    function setStartTime(uint256 _startTime) external onlyOwner {
        startTime = _startTime;
        emit SetStartTime(_startTime);
    }

    function setEndTime(uint256 _endTime) external onlyOwner {
        endTime = _endTime;
        emit SetEndTime(_endTime);
    }

    function setMinContribution(uint256 _minContribution) external onlyOwner {
        minContribution = _minContribution;
        emit SetMinContribution(_minContribution);
    }

    function setMaxContribution(uint256 _maxContribution) external onlyOwner {
        maxContribution = _maxContribution;
        emit SetMaxContribution(_maxContribution);
    }

    function setVestingContract(address _vesting) external onlyOwner {
        vestingContract = _vesting;
        emit SetVestingContract(_vesting);
    }

    function setCurrentStep(uint256 _step) external onlyOwner{
        require(_step > currentStep, "UnixPresale: Wrong parameter for step");
        currentStep = _step;
    }

    function contribute(uint256 _usdcAmount, bytes32[] memory proof) external {
        require(currentStep != 0 && block.timestamp >= startTime && block.timestamp <= endTime, "UnixPresale: Not presale period");
        bool isWhiteList = false;
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if(currentStep == 1) {
            isWhiteList = MerkleProof.verify(proof, seedSaleTreeRoot, leaf);
        } else if(currentStep == 2) {
            isWhiteList = MerkleProof.verify(proof, publicSaleTreeRoot, leaf);
        }

        require (isWhiteList || currentStep == 3, "Unable to contribute");
        require(_usdcAmount >= minContribution, "UnixPresale: Should be deposit more than minContribution=500");
        require(_usdcAmount <= maxContribution, "UnixPresale: Should be deposit less than maxContribution=2500");
        require(contributors[msg.sender] == 0, "UnixPresale: Already contributed");
        
        _contribute(msg.sender, _usdcAmount);
    }

    function _contribute(address user, uint256 _usdcAmount) internal {
        uint256 _tokenAmount = 0;
        if(currentStep == 1) {
            _tokenAmount = _usdcAmount / seedSalePrice * 10 ** 18;
        } else if(currentStep == 2) {
            _tokenAmount = _usdcAmount / wlSalePrice * 10 ** 18;
        }
        // Receive USDC to the contract
        usdcToken.transferFrom(user, address(this), _usdcAmount);
        contributors[user] = _tokenAmount;
        IUnixVesting(vestingContract).addContribution(user, _tokenAmount, currentStep);
        emit Contribute(user, _usdcAmount, _tokenAmount);
    }

    function withdraw(address to, address token) external onlyOwner {
        uint256 _amount;
        if (token == address(0)) {
            _amount = address(this).balance;
            require(_amount > 0, "No ETH to withdraw");

            (bool success, ) = payable(to).call{value: _amount}("");
            require(success, "Unable to withdraw");
        } else {
            _amount = IERC20(token).balanceOf(address(this));
            require (_amount > 0, "Nothing to withdraw");
            bool success = IERC20(token).transfer(to, _amount);
            require(success, "Unable to withdraw");
        }

        emit Withdraw(to, token, _amount);
    }

    receive() payable external {}

    fallback() payable external {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

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
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUnixVesting {
    function addContribution(address _contributor, uint256 _tokenAmount, uint256 _saleType) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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