// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Ip3Struct.sol";

interface IERC20 {
    //Some interface non-implemented functions here
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);


    function balanceOf(address account) external returns (uint256);


}

/**
 *@title IP3 for lend NFT IP
 *@notice Contract demo
 */
contract IP3 {
    using SafeMath for uint256;
    /*//////////////////////////////////////////////////////////////
                           PRICING PARAMETERS
    //////////////////////////////////////////////////////////////*/

    IERC20 acceptedUSDT;
    mapping(bytes32 => AuthorizeRecord) authroizeRecordMap; // hash of NFT => record
    mapping(bytes32 => AuthorizeCertificate) authorizeCertificateMap; // hash of AuthorizeCertificate => certificate
    mapping(address => uint256) claimableMap; // address to claim the authroization revenue

    event Purchased(
        bytes32 indexed hashedAuthorizeNFT,
        bytes32 indexed hashedAuthorizeCertificate,
        address indexed renterAddress,
        AuthorizedNFT authorizedNFT,
        AuthorizeCertificate authorizeCertificate
    );

    event ClaimRevenue(
        address indexed claimAddress,
        uint256 claimRevenue
    );

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
    ) external {
        ///@dev

        // DurationOnly
        if (_authorizedNFT.rentalType == RentalType.DurationOnly) {
            purchaseByDuration(
                _authorizedNFT,
                _term.authorizedStartTime,
                _term.authorizedEndTime,
                msg.sender
            );

            // Countonly
        } else {
            purchaseByAmount(_authorizedNFT, _term.count, msg.sender);
        }
    }

    /*//////////////////////////////////////////////////////////////
                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        //not accepting unsolicited ether
        revert("Reason");
    }

    function purchaseByAmount(
        AuthorizedNFT memory _authorizedNFT,
        uint256 _count,
        address _renterAddress
    ) private {
        // first get approved amount from USDT approve, then can purchase this
        bytes32 hashedAuthorizeNFT = hashAuthorizeNFT(_authorizedNFT);

        //https://ethereum.stackexchange.com/questions/1511/how-to-initialize-a-struct
        Term memory newTerm = Term(0, 0, _count);
        bytes32 singature = hashedAuthorizeNFT; //TODO: authrizednft

        //use IERC20 instance to perform the exchange here
        uint256 termedPrice;

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
        authroizeRecordMap[hashedNft].totalTransactionRevenue += termedPrice;

        // update authorizeCertificateMap
        authorizeCertificateMap[hashedCertificate] = newAuthorizeCertificate;

        // update claimable address
        claimableMap[_authorizedNFT.authorizer.claimAddress] += termedPrice;

        
        // get the current price
        uint256 price = _authorizedNFT.currentPrice;

        // put transfer at the end to prevent the reentry attack 
        if (price == 0) {
            price = 10**6;
            termedPrice = price;
            acceptedUSDT.transferFrom(msg.sender, address(this), price);
        } else {
            termedPrice = price;
            price *= 2;
            acceptedUSDT.transferFrom(msg.sender, address(this), price);
        }


        emit Purchased(
            hashedNft,
            hashedCertificate,
            msg.sender,
            _authorizedNFT,
            newAuthorizeCertificate
        );
    }

    function purchaseByDuration(
        AuthorizedNFT memory _authorizedNFT,
        uint256 _startTime,
        uint256 _endTime,
        address _renterAddress
    ) private {
     
        // first get approved amount from USDT approve, then can purchase this
        bytes32 hashedAuthorizeNFT = hashAuthorizeNFT(_authorizedNFT);

        ///@dev temporary use Count option and count=1, will update the options later.
        //https://ethereum.stackexchange.com/questions/1511/how-to-initialize-a-struct
        Term memory newTerm = Term(_startTime, _endTime, 0);
        bytes32 singature = hashedAuthorizeNFT; // TODO: Tempoary set to be hashed NFT
        
        //use IERC20 instance to perform the exchange here
        uint256 termedPrice;

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
        authroizeRecordMap[hashedNft].totalTransactionRevenue += termedPrice;

        // update authorizeCertificateMap
        authorizeCertificateMap[hashedCertificate] = newAuthorizeCertificate;

        // update claimable address
        claimableMap[_authorizedNFT.authorizer.claimAddress] += termedPrice;
        
        // get the current price
        uint256 price = _authorizedNFT.currentPrice;


        // put transfer at the end to prevent the reentry attack 
        if (price == 0) {
            price = 10**6;
            termedPrice = price;
            acceptedUSDT.transferFrom(msg.sender, address(this), price);
        } else {
            termedPrice = price;
            price *= 2;
            acceptedUSDT.transferFrom(msg.sender, address(this), price);
        }


        emit Purchased(
            hashedNft,
            hashedCertificate,
            msg.sender,
            _authorizedNFT,
            newAuthorizeCertificate
        );
    }

    function hashNftInfo(NFT memory _nft) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_nft.chainId, _nft.NFTAddress, _nft.tokenId)
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
                    _authorizedNFT.currentPrice,
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
                abi.encodePacked(
                    _term.authorizedStartTime,
                    _term.authorizedEndTime,
                    _term.count
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                    CLAIM REVENUE
    //////////////////////////////////////////////////////////////*/
    function claimRevnue(address _address) external {
        require(claimableMap[_address]!=0, "ZERO BALANCE");
        uint256 totalBalance = acceptedUSDT.balanceOf(_address);
        acceptedUSDT.transferFrom(address(this), _address, totalBalance);

        emit ClaimRevenue(_address, totalBalance);
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

    function getCurrentPrice(uint256 _lastActive, uint256 _currentPrice) external view returns(uint256) {
        uint256 currentBlockTime = block.timestamp;
        
        // decrease by 1 uint a second  until to the floor price of 1, 1 fake usdc = 10**6 
        uint256 estimatePrice = _currentPrice.sub(currentBlockTime.sub(_lastActive).mul(1));

        // 1 erc 20 = 10**6
        uint256 floorPrice = 1*10**6;
        return estimatePrice >= floorPrice ? estimatePrice : floorPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

enum RentalType {
    DurationOnly,
    CountOnly
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
}

struct AuthorizedNFT {
    NFT nft;
    RentalType rentalType;
    Authorizer authorizer;
    uint256 listStartTime;
    uint256 listEndTime;
    uint256 currentPrice;
    uint256 lastActive; // last active timestamp
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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