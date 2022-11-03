// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./library/Ip3Struct.sol";

interface IERC20 {
    //Some interface non-implemented functions here
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

/**
 *@title IP3 for lend NFT IP
 *@notice Contract demo
 */
contract IP3 {
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    IERC20 acceptedUSDT;
    mapping(bytes32 => AuthorizeRecord) authroizeRecordMap; // hash of AuthorizedNFT => record
    mapping(bytes32 => AuthorizeCertificate) authorizeCertificateMap; // hash of AuthorizeCertificate => certificate

    event Purchased(
        bytes32 indexed hashedAuthorizeNFT,
        bytes32 indexed hashedAuthorizeCertificate,
        address indexed renterAddress,
        AuthorizedNFT authorizedNFT,
        AuthorizeCertificate authorizeCertificate
    );

    modifier validOption(
        AuthorizedNFT memory _authorizedNFT) {
        require(
                _authorizedNFT.rentalType == RentalType.BothSupported,
            "NOT VALID RENTAL OPTION"
        );
        _;
    }

    constructor(IERC20 instanceAddress) {
        acceptedUSDT = instanceAddress;
    }

    /*//////////////////////////////////////////////////////////////
                    PURCHASING CERTIFICATE
    //////////////////////////////////////////////////////////////*/

    /**
     *@dev purchase authorization certificate
     *@param _term, the term the NFT can be authorized
     */
    function purchaseAuthorization(
        AuthorizedNFT memory _authorizedNFT,
        Term memory _term
    ) external validOption(_authorizedNFT) {
        ///@dev temporary purchase with CountOnly, will update more options.

        // DurationOnly
        if (_authorizedNFT.rentalType == RentalType.DurationOnly) {
            purchaseDuration(_authorizedNFT, _term.authorizedStartTime, _term.authorizedEndTime, msg.sender);
            // purchase(_authorizedNFT, msg.sender);

            // Countonly
        } else {
            purchaseCount(_authorizedNFT, _term.count, msg.sender);
            // purchase(_authorizedNFT, msg.sender);
            // support both Duration and Count options
        }
        
    }

    /*//////////////////////////////////////////////////////////////
                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        //not accepting unsolicited ether
        revert("Reason");
    }

    function purchaseCount(
        AuthorizedNFT memory _authorizedNFT,
        uint256 _count,
        address _renterAddress
    ) private {
        //use IERC20 instance to perform the exchange here
        uint256 termedPrice;
        // first get approved amount from USDT approve, then can purchase this
        bytes32 hashedAuthorizeNFT = hashAuthorizeNFT(_authorizedNFT);
        uint256 price = _authorizedNFT.nft.currentPrice;
        if (price == 0) {
            price = 1;
            termedPrice = price;
            acceptedUSDT.transferFrom(msg.sender, address(this), price);
        } else {
            termedPrice = price;
            price *= 2;
            acceptedUSDT.transferFrom(msg.sender, address(this), price);
        }

        ///@dev temporary use Count option and count=1, will update the options later.
        //https://ethereum.stackexchange.com/questions/1511/how-to-initialize-a-struct
        Term memory newTerm = Term(0, 0, _count);
        bytes32 singature = "0x";
        AuthorizeCertificate
            memory newAuthorizeCertificate = AuthorizeCertificate(
                _authorizedNFT,
                newTerm,
                _renterAddress,
                termedPrice,
                singature
            );

        bytes32 hashedCertificate = keccak256(
            abi.encodePacked(
                hashedAuthorizeNFT,
                hashTerm(newTerm),
                _renterAddress,
                termedPrice,
                singature
            )
        );

        bytes32 hashedNft = hashNftInfo(_authorizedNFT.nft);
        // update AuthroizedNFT record
        authroizeRecordMap[hashedNft].totalAuthorizedCount += 1;
        authroizeRecordMap[hashedNft]
            .totalTransactionRevenue += termedPrice;

        // update authorizeCertificateMap
        authorizeCertificateMap[hashedCertificate] = newAuthorizeCertificate;

        emit Purchased(hashedNft,hashedCertificate, msg.sender, _authorizedNFT, newAuthorizeCertificate);
    }


    function purchaseDuration(    AuthorizedNFT memory _authorizedNFT,
        uint256 _startTime,
        uint256 _endTime,
        address _renterAddress) private {
        
    }



    function hashNftInfo(NFT memory _nft) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _nft.chainId,
                    _nft.NFTAddress,
                    _nft.tokenId
                )
            );
    }

    function hashAuthorizeNFT(AuthorizedNFT memory _authorizedNFT)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    _authorizedNFT.nft.chainId,
                    _authorizedNFT.nft.NFTAddress,
                    _authorizedNFT.nft.tokenId,
                    _authorizedNFT.nft.currentPrice,
                    _authorizedNFT.rentalType,
                    _authorizedNFT.authorizer.nftHolder,
                    _authorizedNFT.authorizer.claimAddress,
                    _authorizedNFT.listStartTime,
                    _authorizedNFT.listEndTime
                )
            );
    }

    function hashTerm(Term memory _term) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_term.authorizedStartTime, _term.authorizedEndTime, _term.count)
            );
    }

    /*//////////////////////////////////////////////////////////////
                    GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getAuthroizeRecordMap(bytes32 _hashedNFTInfo)
        external
        view
        returns (AuthorizeRecord memory)
    {
        return authroizeRecordMap[_hashedNFTInfo];
    }

    function getAuthroizeCertificateMap(bytes32 _hashedCertificate)
        external
        view
        returns (AuthorizeCertificate memory)
    {
        return authorizeCertificateMap[_hashedCertificate];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

enum RentalType {
    DurationOnly,
    CountOnly,
    BothSupported
}

struct Authorizer {
    address nftHolder;
    address claimAddress;
}
// TODO: initial price; list start time, and list end time

struct NFT {
    string chainId;
    address NFTAddress;
    string tokenId;
    uint256 currentPrice;
}

struct AuthorizedNFT {
    NFT nft;
    RentalType rentalType;
    Authorizer authorizer;
    uint256 listStartTime;
    uint256 listEndTime;
}

struct Term {
    uint256 authorizedStartTime;
    uint256 authorizedEndTime;
    uint256 count;
}

struct AuthorizeCertificate {
  AuthorizedNFT authorizedNFT;
  Term term;
  address renter;
  uint256 price;
  bytes32 signature;
}

struct AuthorizeRecord {
    uint256 totalAuthorizedCount;
    uint256 totalTransactionRevenue;
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