// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./libraries/SmartPriceEngine.sol";
import "./Ip3Struct.sol";


interface IERC20 {
    //Some interface non-implemented functions here
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
    mapping(bytes32 => NFTipOverall) authroizeRecordMap; // hash of NFT => record
    mapping(bytes32 => AuthorizeCertificate) authorizeCertificateMap; // hash of AuthorizeCertificate => certificate
    mapping(address => uint256) claimableMap; // address to claim the authroization revenue

    event Purchased(
        bytes32 indexed hashedNFT,
        bytes32 indexed hashedAuthorizeCertificate,
        address indexed renterAddress,
        AuthorizedNFT authorizedNFT,
        AuthorizeCertificate authorizeCertificate
    );

    event ClaimRevenue(address indexed claimAddress, uint256 claimRevenue);

    constructor(IERC20 instanceAddress) {
        acceptedUSDT = instanceAddress;
    }

    /*//////////////////////////////////////////////////////////////
                    PURCHASING CERTIFICATE
    //////////////////////////////////////////////////////////////*/

    /**
     *@dev purchase authorization certificate
     *@param term, the term the NFT can be authorized
     */
    function purchaseAuthorization(
        AuthorizedNFT memory authorizedNFT,
        Term memory term
    ) external {
        ///@dev
      

        // DurationOnly
        if (authorizedNFT.rentalType == RentalType.DurationOnly) {
            purchaseByDuration(
                authorizedNFT,
                term.authorizedStartTime,
                term.authorizedEndTime,
                msg.sender
            );

            // Countonly
        } else {
            // purchaseByAmount(authorizedNFT, term.count, msg.sender);
            // TODO: implement later
            revert("not implememnt yet");
        }
    }

    /*//////////////////////////////////////////////////////////////
                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable {
        //not accepting unsolicited ether
        revert("Reason");
    }

    // TODO: update this function later
    // function purchaseByAmount(
    //     AuthorizedNFT memory authorizedNFT,
    //     uint256 count,
    //     address renterAddress
    // ) private {
    //     // first get approved amount from USDT approve, then can purchase this
    //     bytes32 hashedAuthorizeNFT = hashAuthorizeNFT(authorizedNFT);

    //     //https://ethereum.stackexchange.com/questions/1511/how-to-initialize-a-struct
    //     Term memory newTerm = Term(0, 0, count);
    //     bytes32 singature = hashedAuthorizeNFT; //TODO: authrizednft

    //     //use IERC20 instance to perform the exchange here
    //     uint256 termedPrice;

    //     // get the latestStartPrice price
    //     uint256 price = authorizedNFT.latestStartPrice;

    //     // put transfer at the end to prevent the reentry attack
    //     if (price == 0) {
    //         price = 10**6;
    //     }

    //     termedPrice = price;
    //     authorizedNFT.latestStartPrice = price;
    //     authorizedNFT.lastActive = block.timestamp;

    //     updatePurchaseState(
    //         authorizedNFT,
    //         newTerm,
    //         renterAddress,
    //         termedPrice,
    //         hashedAuthorizeNFT,
    //         singature
    //     );

    //     // put transfer at the end to prevent the reentry attack
    //     acceptedUSDT.transferFrom(msg.sender, address(this), termedPrice);
    // }

    /**
     * @dev purchase by duration
     * @param authorizedNFTSubmit, user purchase the license to submit in AuthorizedNFT format
     * @param authorizedStartTime, user input the start authorization time
     * @param authorizedEndTime, user input the end authorization time
     * @param renterAddress, user wallet address
     */
    function purchaseByDuration(
        AuthorizedNFT memory authorizedNFTSubmit,
        uint256 authorizedStartTime,
        uint256 authorizedEndTime,
        address renterAddress
    ) private {
        // first get approved amount from USDT approve, then can purchase this
        bytes32 hashedAuthorizeNFT = hashAuthorizeNFT(authorizedNFTSubmit);

        ///@dev temporary use Count option and count=1, will update the options later.
        //https://ethereum.stackexchange.com/questions/1511/how-to-initialize-a-struct
        require(authorizedEndTime>authorizedStartTime, "NEG TIMEWINDOW");
        Term memory newTerm = Term(authorizedStartTime, authorizedEndTime, 0);
        bytes32 singature = hashedAuthorizeNFT; // TODO: Tempoary set to be hashed NFT
        
        bytes32 hashedNft = hashNftInfo(authorizedNFTSubmit.nft);


        // TODO: check if latestStartPriceOnRecord == 0 (means no transactional record, then use input starting price)
       //retreive the latestStartPrice
       uint256 latestStartPriceOnRecord = authroizeRecordMap[hashedNft]
                .authorizedNFT
                .latestStartPrice;


        uint256 currentStartPrice;
        // check if has record on-chain, if not default is 0
        // if has record on-chain
        if (latestStartPriceOnRecord !=0) {
            // get the latest start price from record on chain
            currentStartPrice = getCurrentStartingPrice(hashedNft);
        } else { 
            // new NFT to be licenced
            // get the start price from the input
            currentStartPrice = authorizedNFTSubmit.latestStartPrice;
            // input the list start and end time, add the authorizer struct info
            authroizeRecordMap[hashedNft].authorizedNFT.listStartTime = authorizedNFTSubmit.listStartTime;
            authroizeRecordMap[hashedNft].authorizedNFT.listEndTime = authorizedNFTSubmit.listEndTime;
            authroizeRecordMap[hashedNft].authorizedNFT.authorizer = authorizedNFTSubmit.authorizer;
            authroizeRecordMap[hashedNft].authorizedNFT.nft = authorizedNFTSubmit.nft;
        }

        uint256 duration = authorizedEndTime - authorizedStartTime;
        
        // incrementByDuration: for example 0.1 erc20 / 3600 sec
        //TODO: could be NFT specific feature
        uint256 incrementByDuration = 10**5;

        // compute the current termPrice by smart price engine
        // function computeAuthroizedPriceByDuration(uint256 duration, uint256 incrementByDuration, uint256 currentStartPrice )
        uint256 termedPrice = SmartPriceEngine.computeAuthroizedPriceByDuration(
            duration,
            incrementByDuration,
            currentStartPrice
        );

        // update the authorizedNFT info
        authroizeRecordMap[hashedNft].authorizedNFT.latestStartPrice = currentStartPrice;
        authroizeRecordMap[hashedNft].authorizedNFT.lastActive = block.timestamp;

        
        AuthorizedNFT memory tempAuthorizedNFT = authroizeRecordMap[hashedNft].authorizedNFT;
        AuthorizeCertificate memory newAuthorizeCertificate =  AuthorizeCertificate(tempAuthorizedNFT, newTerm, renterAddress, termedPrice, singature);
        // function updatePurchaseState(AuthorizedNFT memory newAuthorizeCertificate, bytes32 hashedAuthorizeNFT, bytes32 singature )
        updatePurchaseState(
            newAuthorizeCertificate,
            hashedAuthorizeNFT
        );

        // put transfer at the end to prevent the reentry attack
        acceptedUSDT.transferFrom(msg.sender, address(this), termedPrice);
    }

    function hashNftInfo(NFT memory nft) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(nft.chainId, nft.NFTAddress, nft.tokenId)
            );
    }

    function hashAuthorizeNFT(AuthorizedNFT memory authorizedNFT)
        private
        pure
        returns (bytes32)
    {
        
        bytes32 hashedAuthorization =  keccak256(
                abi.encodePacked(
                    authorizedNFT.nft.chainId,
                    authorizedNFT.nft.NFTAddress,
                    authorizedNFT.nft.tokenId,
                    authorizedNFT.rentalType,
                    authorizedNFT.authorizer.nftHolder,
                    authorizedNFT.authorizer.claimAddress,
                    authorizedNFT.listStartTime,
                    authorizedNFT.listEndTime
                )
            );

            return hashedAuthorization;
    }

    function hashTerm(Term memory term) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    term.authorizedStartTime,
                    term.authorizedEndTime,
                    term.count
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                    CLAIM REVENUE
    //////////////////////////////////////////////////////////////*/
    function claimRevnue(address addressToClaim) external {
        uint256 totalBalance = claimableMap[addressToClaim];
        require(totalBalance > 0, "ZERO BALANCE");
        acceptedUSDT.transfer(addressToClaim, totalBalance);

        emit ClaimRevenue(addressToClaim, totalBalance);
    }

    /*//////////////////////////////////////////////////////////////
                    UPDATE STATE STORAGE
    //////////////////////////////////////////////////////////////*/
    function updatePurchaseState(
        AuthorizeCertificate memory newAuthorizeCertificate,
        bytes32 hashedAuthorizeNFT) 
        private {
   
        uint256 termedPrice = newAuthorizeCertificate.price;
        Term memory newTerm = newAuthorizeCertificate.term;
        bytes32 singature = newAuthorizeCertificate.signature;

        bytes32 hashedCertificate = keccak256(
            abi.encodePacked(
                hashedAuthorizeNFT,
                hashTerm(newTerm),
                newAuthorizeCertificate.renter,
                termedPrice,
                singature
            )
        );
        AuthorizedNFT memory authorizedNFT = newAuthorizeCertificate.authorizedNFT;

        bytes32 hashedNft = hashNftInfo(authorizedNFT.nft);
        // update AuthroizedNFT record
        authroizeRecordMap[hashedNft].authorizeRecord.totalAuthorizedCount += 1;
        authroizeRecordMap[hashedNft]
            .authorizeRecord
            .totalTransactionRevenue += termedPrice;
        // update authorizeCertificateMap
        authorizeCertificateMap[hashedCertificate] = newAuthorizeCertificate;

        // update claimable address
        claimableMap[authroizeRecordMap[hashedNft].authorizedNFT.authorizer.claimAddress] += termedPrice;

        emit Purchased(
            hashedNft,
            hashedCertificate,
            msg.sender,
            authorizedNFT,
            newAuthorizeCertificate
        );
    }

    /*//////////////////////////////////////////////////////////////
                    GETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getAuthroizeRecordMap(bytes32 hashedNFTInfo)
        external
        view
        returns (NFTipOverall memory)
    {
        return authroizeRecordMap[hashedNFTInfo];
    }

    function getAuthroizeCertificateMap(bytes32 hashedCertificate)
        external
        view
        returns (AuthorizeCertificate memory)
    {
        return authorizeCertificateMap[hashedCertificate];
    }

    function getCurrentStartingPrice(bytes32 hashedNft)
        public
        view
        returns (uint256)
    {
        uint256 latestTimeStamp = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .lastActive;
        

        uint256 latestStartPrice = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .latestStartPrice;
         
        uint256 currentTxNum = authroizeRecordMap[hashedNft]
            .authorizeRecord
            .totalAuthorizedCount;

        uint256 discountPerTime = 10**5; //0.1 ERC20 (3600 secs basis)

        uint256 currentStartPrice = SmartPriceEngine.updateStartingPrice(
                currentTxNum,
                latestTimeStamp,
                latestStartPrice,
                discountPerTime
            );

        return currentStartPrice;
            
    }

    function getCurrentClaimable(address addressQuery)
        external
        view
        returns (uint256)
    {
        return claimableMap[addressQuery];
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
    uint256 latestStartPrice;
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

struct NFTipOverall {
    AuthorizedNFT authorizedNFT; 
    AuthorizeRecord authorizeRecord;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev compute the NFT authroization price
 # TODO: Overflow protection, fixed point arithmatics 
 */
library SmartPriceEngine {
    uint256 constant ERC20RESOLUTION = 10**6;
    uint256 constant MAX_THRESHOLD_PRICE = 2000 * ERC20RESOLUTION; // 2000 ERC20
    uint256 constant MIN_THRESHOLD_PRICE = 1 * ERC20RESOLUTION; // 1 ERC20
    uint256 constant INCREMENT_BY_TX = 10**5; // new traction will autoamally increment by this amount, 0.1 ERC20 now
    uint256 constant TIME_INTERVAL = 3600;
 

    function computeAuthroizedPriceByCount(
        uint256 count,
        uint256 incrementByCount,
        uint256 currentStartPrice
    ) internal pure returns (uint256) {
        
        uint256 authorizedPrice = currentStartPrice + count * incrementByCount;

        if (authorizedPrice > MAX_THRESHOLD_PRICE) {
            return MAX_THRESHOLD_PRICE;
        }

        return authorizedPrice;
        
    }


    function computeAuthroizedPriceByDuration(
        uint256 duration,
        uint256 incrementByDuration,
        uint256 currentStartPrice
    ) internal pure returns (uint256) {
        
        // incrementByDuration: for example 0.1 erc20 / 3600 sec
        uint256 authorizedPrice = currentStartPrice + duration * incrementByDuration / TIME_INTERVAL;

        if (authorizedPrice > MAX_THRESHOLD_PRICE) {
            return MAX_THRESHOLD_PRICE;
        }

        return authorizedPrice;
        
    }

       /**
     * @dev update the latest start price
     * @param latestTimeStamp, timestamp of latest NFT authorized
     * @param latestStartPrice, latest start price of NFT authorized
     * @param discountPerTime, price discount with time pass, for example 0.1 usdc / 3600 secs
     * @return updated latest price
     */
    function updateStartingPrice(
        uint256 currentTxNum,
        uint256 latestTimeStamp,
        uint256 latestStartPrice,
        uint256 discountPerTime
    ) internal view returns (uint256) {
        
        // TODO: not sure if save to cast the price here
        int256 currentLatestStartPrice = int256(latestStartPrice -
            ((block.timestamp - latestTimeStamp) * discountPerTime) /
            TIME_INTERVAL + INCREMENT_BY_TX*currentTxNum);

        if (currentLatestStartPrice < int256(MIN_THRESHOLD_PRICE)) {
            return MIN_THRESHOLD_PRICE;
        }
        // TODO: how to safely deal with this?
        return uint256(currentLatestStartPrice);
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