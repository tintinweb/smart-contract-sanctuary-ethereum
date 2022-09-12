/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

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

// File: IArtcryptionFactory.sol



pragma solidity ^0.8.16;

interface IArtcryptionFactory {
    function isArtcryptionNFT(address _contract) external view returns (bool);

    function getOwner(address _contract) external view returns (address);
}

// File: IArtcryptionRoyalties.sol


pragma solidity ^0.8.16;

interface IArtcryptionRoyalties {
    function setRoyalty(
        address _contract,
        address receiver,
        uint96 royaltyFraction
    ) external;

    function getRoyalty(address _contract, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: ArtcryptionRoyalties.sol


pragma solidity ^0.8.16;




contract ArtcryptionRoyalties is IArtcryptionRoyalties, Ownable {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    address _factory;
    mapping(address => RoyaltyInfo) private _tokenRoyaltyInfo;
    uint96 public maxRoyalty;
    mapping(address => bool) _royaltyExceptions;

    modifier _onlyOwner(address _contract) {
        bool check = false;
        if (IArtcryptionFactory(_factory).isArtcryptionNFT(_contract)) {
            if (IArtcryptionFactory(_factory).getOwner(_contract) == msg.sender)
                check = true;
        } else {
            Ownable Contract = Ownable(_contract);
            try Contract.owner() returns (address owner) {
                if (owner != address(0)) check = owner == msg.sender;
            } catch {}
        }
        require(check, "Sender Not Owner");
        _;
    }

    constructor(address factory) {
        _factory = factory;
    }

    function setRoyalty(
        address _contract,
        address receiver,
        uint96 royaltyFraction
    ) external override _onlyOwner(_contract) {
        require(royaltyFraction < 10000, "Royalty fee will exceed salePrice");
        if (!_royaltyExceptions[_contract])
            if (maxRoyalty != 0)
                require(
                    royaltyFraction <= maxRoyalty,
                    "Royalty fee will exceed salePrice"
                );
        require(receiver != address(0), "Invalid parameters");

        _tokenRoyaltyInfo[_contract] = RoyaltyInfo(receiver, royaltyFraction);
    }

    function getRoyalty(address _contract, uint256 _salePrice)
        external
        view
        override
        returns (address, uint256)
    {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_contract];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / 10000;

        return (royalty.receiver, royaltyAmount);
    }

    function createRoyaltyException(address _contract) external onlyOwner {
        _royaltyExceptions[_contract] = true;
    }

    function setRoyaltyCap(uint96 royalty) external onlyOwner {
        require(royalty < 10000, "Royalty fee will exceed salePrice");
        maxRoyalty = royalty;
    }
}