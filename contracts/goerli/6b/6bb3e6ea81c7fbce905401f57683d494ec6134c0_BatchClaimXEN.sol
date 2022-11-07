/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


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

contract BatchClaimXEN is Ownable {
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1167.md
    bytes miniProxy;              // = 0x363d3d373d3d3d363d73bebebebebebebebebebebebebebebebebebebebe5af43d82803e903d91602b57fd5bf3;

    bool  constant MINER_START = true;

    address private immutable original;

    address private immutable deployer;

    address private constant XEN = 0xca41f293A32d25c2216bC4B30f5b0Ab61b6ed2CB;

    mapping(address => uint) public countClaimRank;

    mapping(address => uint) public countClaimMint;

    mapping(address => bool) public miners;

    constructor() {
        miniProxy = bytes.concat(bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73), bytes20(address(this)), bytes15(0x5af43d82803e903d91602b57fd5bf3));
        original = address(this);
        deployer = msg.sender;
        miners[msg.sender] = MINER_START;
    }

    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    function setMiner(address miner) external
    onlyOwner {
        miners[miner] = MINER_START;
    }

    function removeMiner(address miner) external
    onlyOwner {
        delete miners[miner];
    }

    function batchClaimRank(uint times, uint term) external {
        bytes memory bytecode = miniProxy;
        address proxy;
        uint N = countClaimRank[msg.sender];
        for (uint i = N; i < N + times; i++) {
            bytes32 salt = keccak256(abi.encodePacked(msg.sender, i));
            assembly {
                proxy := create2(0, add(bytecode, 32), mload(bytecode), salt)
            }
            BatchClaimXEN(proxy).claimRank(term);
        }
        countClaimRank[msg.sender] = N + times;
    }

    function claimRank(uint term) external {
        IXEN(XEN).claimRank(term);
    }


    function userMint(address account) public view returns (MintInfo memory) {
        IXEN.MintInfo memory _mt = IXEN(XEN).userMints(account);
        return MintInfo({
        user : _mt.user,
        term : _mt.term,
        maturityTs : _mt.maturityTs,
        rank : _mt.rank,
        amplifier : _mt.amplifier,
        eaaRate : _mt.eaaRate
        });
    }


    function proxyFor(address sender, uint i) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        proxy = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                address(this),
                salt,
                keccak256(abi.encodePacked(miniProxy))
            )))));
    }

    function batchClaimMintReward(uint times) external {
        uint M = countClaimMint[msg.sender];
        uint N = countClaimRank[msg.sender];
        N = M + times < N ? M + times : N;
        for (uint i = M; i < N; i++) {
            address proxy = proxyFor(msg.sender, i);
            BatchClaimXEN(proxy).claimMintRewardTo(msg.sender);
        }
        countClaimMint[msg.sender] = N;
    }

    function claimMintRewardTo(address to) external {
        require(miners[msg.sender] == MINER_START);
        IXEN(XEN).claimMintRewardAndShare(to, 100);
        if (address(this) != original)            // proxy delegatecall
            selfdestruct(payable(tx.origin));
    }

}

interface IXEN {

    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    function claimRank(uint term) external;

    function claimMintReward() external;

    function claimMintRewardAndShare(address other, uint256 pct) external;

    function transfer(address recipient, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function userMints(address account) external view returns (MintInfo memory);

}