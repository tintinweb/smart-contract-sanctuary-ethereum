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

interface IXEN {
    function claimRank(uint256 term) external;

    function claimMintRewardAndShare(address other, uint256 pct) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IXENProxying {
    function callClaimRank(uint256 term) external;

    function callClaimMintReward(address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IXENTorrent {
    event BulkClaimRank(address indexed user, uint256 users, uint256 term);
    event BulkClaimMintReward(address indexed user, uint256 users);
    event BulkClaimMintRewardIndex(
        address indexed,
        uint256 _userIndex,
        uint256 _userEnd
    );

    function bulkClaimRank(uint256 users, uint256 term) external;

    function bulkClaimMintReward(uint256 users) external;

    function bulkClaimMintRewardIndex(
        uint256 _userIndex,
        uint256 _userEnd
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IXEN.sol";
import "./interfaces/IXENTorrent.sol";
import "./interfaces/IXENProxying.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SweetXen is Ownable, IXENTorrent, IXENProxying {
    address private immutable _original;

    address public immutable xenCrypto;

    bytes private _miniProxy;

    mapping(address => uint256) public countBulkClaimRank;

    mapping(address => uint256) public countBulkClaimMintReward;

    uint256 public totalSupplyBulkClaimRank;

    uint256 public totalSupplyBulkClaimMintReward;

    constructor(address xenCrypto_) {
        require(xenCrypto_ != address(0));
        _original = address(this);
        xenCrypto = xenCrypto_;
        _miniProxy = bytes.concat(
            bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
            bytes20(address(this)),
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
    }

    /**
        @dev function callable only in proxy contracts from the original one => XENCrypto.claimRank(term)
     */
    function callClaimRank(uint256 term) external {
        require(msg.sender == _original, "unauthorized");
        IXEN(xenCrypto).claimRank(term);
    }

    /**
        @dev function callable only in proxy contracts from the original one => XENCrypto.claimMintRewardAndShare()
     */
    function callClaimMintReward(address to) external {
        require(msg.sender == _original, "unauthorized");
        IXEN(xenCrypto).claimMintRewardAndShare(to, uint256(100));
        if (address(this) != _original) {
            selfdestruct(payable(tx.origin));
        }
    }

    /**
        @dev main torrent interface. initiates Bulk Mint (Torrent) Operation
     */
    function bulkClaimRank(uint256 users, uint256 term) public {
        require(users > 0, "Illegal count");
        require(term > 0, "Illegal term");
        bytes memory bytecode = _miniProxy;
        bytes memory callData = abi.encodeWithSignature(
            "callClaimRank(uint256)",
            term
        );
        address proxy;
        bool succeeded;
        uint256 cbcr = countBulkClaimRank[msg.sender];
        for (uint256 i = cbcr; i < cbcr + users; i++) {
            bytes32 salt = keccak256(abi.encodePacked(msg.sender, i));
            assembly {
                proxy := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
                succeeded := call(
                    gas(),
                    proxy,
                    0,
                    add(callData, 0x20),
                    mload(callData),
                    0,
                    0
                )
            }
            require(succeeded, "Error while claiming rank");
        }
        countBulkClaimRank[msg.sender] = cbcr + users;
        totalSupplyBulkClaimRank = totalSupplyBulkClaimRank + users;
        emit BulkClaimRank(msg.sender, users, term);
    }

    function proxyFor(
        address sender,
        uint256 i
    ) public view returns (address proxy) {
        bytes32 salt = keccak256(abi.encodePacked(sender, i));
        bytes32 hash = keccak256(
            abi.encodePacked(
                hex"ff",
                address(this),
                salt,
                keccak256(_miniProxy)
            )
        );
        proxy = address(uint160(uint256(hash)));
    }

    /**
        @dev main torrent interface. initiates Mint Reward claim and collection and terminates Torrent Operation
     */
    function bulkClaimMintReward(uint256 users) external {
        require(
            countBulkClaimRank[msg.sender] > 0,
            "No BulkClaimRank record yet"
        );
        bytes memory callData = abi.encodeWithSignature(
            "callClaimMintReward(address)",
            msg.sender
        );
        uint256 bcr = countBulkClaimRank[msg.sender];
        uint256 bcmr = countBulkClaimMintReward[msg.sender];
        uint256 sc = bcmr + users < bcr ? bcmr + users : bcr;
        uint256 rsi;
        for (uint256 i = bcmr; i < sc; i++) {
            address proxy = proxyFor(msg.sender, i);
            if (!_contractExists(proxy)) {
                continue;
            }
            bool succeeded;
            assembly {
                succeeded := call(
                    gas(),
                    proxy,
                    0,
                    add(callData, 0x20),
                    mload(callData),
                    0,
                    0
                )
            }
            require(succeeded, "Error while claiming rewards");
            rsi++;
        }
        countBulkClaimMintReward[msg.sender] = sc;
        totalSupplyBulkClaimMintReward = totalSupplyBulkClaimMintReward + rsi;
        emit BulkClaimMintReward(msg.sender, users);
    }

    function bulkClaimMintRewardIndex(
        uint256 _userIndex,
        uint256 _userEnd
    ) external {
        require(_userIndex < _userEnd, "Illegal UserIndex");
        require(
            countBulkClaimRank[msg.sender] > 0,
            "No BulkClaimRank record yet"
        );
        require(
            _userEnd <= countBulkClaimRank[msg.sender],
            "Illegal UserIndex"
        );
        bytes memory callData = abi.encodeWithSignature(
            "callClaimMintReward(address)",
            msg.sender
        );
        uint256 rsi;
        for (uint i = _userIndex; i <= _userEnd; i++) {
            address proxy = proxyFor(msg.sender, i);
            if (!_contractExists(proxy)) {
                continue;
            }
            bool succeeded;
            assembly {
                succeeded := call(
                    gas(),
                    proxy,
                    0,
                    add(callData, 0x20),
                    mload(callData),
                    0,
                    0
                )
            }
            require(succeeded, "Error while claiming rewards");
            rsi++;
        }
        totalSupplyBulkClaimMintReward = totalSupplyBulkClaimMintReward + rsi;
        emit BulkClaimMintRewardIndex(msg.sender, _userIndex, _userEnd);
    }

    function _contractExists(address proxy) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(proxy)
        }
        return size > 0;
    }

    function withdraw(address _token) external onlyOwner {
        if (_token == address(0x0)) {
            uint256 balance = address(this).balance;
            require(balance > 0, "No balance to withdraw");
            (bool success, ) = payable(msg.sender).call{value: balance}("");
            require(success, "Failed to withdraw payment");
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 _ercBalance = erc20token.balanceOf(address(this));
        require(_ercBalance > 0, "No balance to withdraw");
        bool _ercSuccess = erc20token.transfer(owner(), _ercBalance);
        require(_ercSuccess, "Failed to withdraw payment");
    }

    receive() external payable virtual {}
}