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
    mapping(bytes32 => uint256) priceMap; // hash of AuthorizedNFT => price in USDT

    modifier validOption(
        AuthorizedNFT memory _authorizedNFT,
        RentalType rentalOption
    ) {
        require(
            _authorizedNFT.rentalType == rentalOption ||
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
     *@param _authorizedNFT, the NFT colections and token id that can be authorized
     *@param rentalOption, "DurationOnly", "CountOnly" or "SupportBoth"
     */
    function purchaseAuthorization(
        AuthorizedNFT memory _authorizedNFT,
        RentalType rentalOption
    ) external validOption(_authorizedNFT, rentalOption) {
        ///@dev temporary purchase with CountOnly, will update more options.

        // DurationOnly
        if (rentalOption == RentalType.DurationOnly) {
            purchase(_authorizedNFT, msg.sender);

            // Countonly
        } else {
            purchase(_authorizedNFT, msg.sender);
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

    function purchase(
        AuthorizedNFT memory _authorizedNFT,
        address _renterAddress
    ) private {
        //use IERC20 instance to perform the exchange here
        uint256 termedPrice;
        // first get approved amount from USDT approve, then can purchase this
        bytes32 hashedAuthorizeNFT = hashAuthorizeNFT(_authorizedNFT);
        uint256 price = priceMap[hashedAuthorizeNFT];
        if (price == 0) {
            price = 1;
            termedPrice = price;
            acceptedUSDT.transferFrom(msg.sender, address(this), price);
            priceMap[hashedAuthorizeNFT] += 2;
        } else {
            termedPrice = price;
            price *= 2;
            acceptedUSDT.transferFrom(msg.sender, address(this), price);
            priceMap[hashedAuthorizeNFT] += price;
        }

        //     struct Term {
        //     uint256 startTime;
        //     uint256 endTime;
        //     uint256 count;
        // }

        // struct AuthorizeCertificate {
        // AuthorizedNFT authorizedNFT;
        // Term term;
        // address renter;
        // uint256 price;
        // }

        // struct AuthorizeRecord {
        //     uint256 totalAuthorizedCount;
        //     uint256 totalTransactionRevenue;
        // }

        ///@dev temporary use Count option and count=1, will update the options later.
        //https://ethereum.stackexchange.com/questions/1511/how-to-initialize-a-struct
        Term memory newTerm = Term(0, 0, 1);

        AuthorizeCertificate
            memory newAuthorizeCertificate = AuthorizeCertificate(
                _authorizedNFT,
                newTerm,
                _renterAddress,
                termedPrice
            );

        bytes32 hashedCertificate = keccak256(
            abi.encodePacked(
                hashedAuthorizeNFT,
                hashTerm(newTerm),
                _renterAddress,
                termedPrice
            )
        );

        // update AuthroizedNFT record
        authroizeRecordMap[hashedAuthorizeNFT].totalAuthorizedCount += 1;
        authroizeRecordMap[hashedAuthorizeNFT]
            .totalTransactionRevenue += termedPrice;

        // update authorizeCertificateMap
        authorizeCertificateMap[hashedCertificate] = newAuthorizeCertificate;
    }

    function hashAuthorizeNFT(AuthorizedNFT memory _authorizedNFT)
        private
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    _authorizedNFT.NFTAddress,
                    _authorizedNFT.tokenId,
                    _authorizedNFT.rentalType,
                    _authorizedNFT.authorizer.nftHolder,
                    _authorizedNFT.authorizer.claimAddress
                )
            );
    }

    function hashTerm(Term memory _term) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_term.startTime, _term.endTime, _term.count)
            );
    }

    /*//////////////////////////////////////////////////////////////
                    GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getAuthroizeRecordMap(bytes32 _hashedAuthorizeNFT)
        external
        view
        returns (AuthorizeRecord memory)
    {
        return authroizeRecordMap[_hashedAuthorizeNFT];
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

struct AuthorizedNFT {
    address NFTAddress;
    string tokenId;
    RentalType rentalType;
    Authorizer authorizer;
}

struct Term {
    uint256 startTime;
    uint256 endTime;
    uint256 count;
}

struct AuthorizeCertificate {
  AuthorizedNFT authorizedNFT;
  Term term;
  address renter;
  uint256 price;
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