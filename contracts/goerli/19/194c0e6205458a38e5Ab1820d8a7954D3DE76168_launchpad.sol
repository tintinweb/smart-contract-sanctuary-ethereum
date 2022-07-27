// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

interface NFTcontract {
    function mint(address _to, uint256 _id) external;

    function getTotalMinted() external view returns (uint256);
}

contract launchpad is Ownable {
    NFTcontract public tokenContract;

    address payable public NXTLab_wallet;
    address payable public Stanley_wallet;
    address payable public Treasury_wallet;

    struct AllowedUsers {
        address user;
        uint16 maxCount;
    }

    uint16 public maxTotalSupply;
    uint256 public mintPrice;

    uint256 public startAt;
    uint256 public expiresAt;

    // addresses that can participate in the presale evenе
    AllowedUsers[] public whitelistUsers;

    event LaunchpadStarting(
        uint256 expiresAt,
        uint16 maxTotalSupply,
        uint256 mintPrice
    );

    constructor(
        address payable _NXTLab,
        address payable _Stanley,
        address payable _Treasury
    ) {
        NXTLab_wallet = _NXTLab;
        Stanley_wallet = _Stanley;
        Treasury_wallet = _Treasury;
    }

    // modifer function --------------------------------------------

    function checkWhitelistLimit(address _user) public view returns (uint16) {
        for (uint16 i = 0; i < whitelistUsers.length; i++) {
            if (whitelistUsers[i].user == _user) {
                return whitelistUsers[i].maxCount;
            }
        }
        return 0;
    }

    // external ----------------------------------------------------

    function privateMint(address to, uint16 count) external payable {
        require(block.timestamp < expiresAt, "Launchpad time has expired");
        require(
            msg.value == mintPrice * count,
            "Value is not equal to price * count"
        );
        require(checkWhitelistLimit(to) >= count, "Whitelist mint limit");

        _mintToken(to, count);

        for (uint16 i = 0; i < whitelistUsers.length; i++) {
            if (whitelistUsers[i].user == to) {
                whitelistUsers[i].maxCount = whitelistUsers[i].maxCount - count;
            }
        }

        _withdraw(msg.value);
    }

    // internal ----------------------------------------------------

    function _mintToken(address _to, uint16 _count) internal {
        require(_count > 0, "Min amount is 1");
        require(
            maxTotalSupply - _count >= 0,
            "Limit: launchpad NFT has ended or too much count"
        );

        for (uint16 i = 0; i < _count; i++) {
            uint256 totalMinted = tokenContract.getTotalMinted();

            tokenContract.mint(_to, totalMinted + 1);
        }

        maxTotalSupply -= _count;
    }

    function _withdraw(uint256 funds) internal {
        if (mintPrice <= 0.33 ether) {
            Stanley_wallet.transfer(funds / 3);
            Treasury_wallet.transfer((funds / 3) * 2);
        }
        if (mintPrice > 0.33 ether && funds <= 0.66 ether) {
            uint256 nxt = funds - 0.33 ether;

            NXTLab_wallet.transfer(nxt);
            Stanley_wallet.transfer(0.33 ether / 3);
            Treasury_wallet.transfer((0.33 ether / 3) * 2);
        }
        if (mintPrice > 0.66 ether) {
            uint256 pwt = funds - 0.33 ether;

            NXTLab_wallet.transfer(0.33 ether);
            Stanley_wallet.transfer(pwt / 3);
            Treasury_wallet.transfer((pwt / 3) * 2);
        }
    }

    // admin -------------------------------------------------------

    function setLaunchpadStart(
        uint16 _maxTotalSupply,
        uint256 _mintPrice,
        uint256 _duration
    ) external onlyOwner {
        require(block.timestamp + _duration > block.timestamp, "Invalid input");

        delete whitelistUsers;
        maxTotalSupply = _maxTotalSupply;
        mintPrice = _mintPrice;
        startAt = block.timestamp;
        expiresAt = startAt + _duration;

        emit LaunchpadStarting(expiresAt, maxTotalSupply, mintPrice);
    }

    function addWhitelistUsers(AllowedUsers[] calldata _users)
        external
        onlyOwner
    {
        for (uint16 i = 0; i < _users.length; i++) {
            whitelistUsers.push(
                AllowedUsers(_users[i].user, _users[i].maxCount)
            );
        }
    }

    // set ERC721 deployed contract address
    function setTokenContract(NFTcontract _tokenContract) external onlyOwner {
        tokenContract = _tokenContract;
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