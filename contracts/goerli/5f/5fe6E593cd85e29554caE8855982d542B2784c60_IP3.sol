// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
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

    using EnumerableSet for EnumerableSet.Bytes32Set;
    EnumerableSet.Bytes32Set private nftOnRecord; // set for NFT have transactional record (hash nft)

    PriceDynamicsParams private priceParams;

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
        priceParams = PriceDynamicsParams({
            countFactor: 10**5,
            countOrder: 1,
            durationFactor: 10**5,
            durationOrder: 1,
            max_threshold_price: 1000 * 10**6,
            min_threshold_price: 1 * 10**6,
            increment_by_tx: 10**5,
            discountPerTime: 10**5
        });
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
        if (term.isByDuration) {
            purchaseByDuration(
                authorizedNFT,
                term.authorizedStartTime,
                term.authorizedEndTime,
                term.isByDuration,
                msg.sender
            );

            // Countonly
        } else {
            purchaseByAmount(authorizedNFT, term.count, term.isByDuration, msg.sender);
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
        AuthorizedNFT memory authorizedNFTSubmit,
        uint256 count,
        bool isByDuration,
        address renterAddress
    ) private {
        // first get approved amount from USDT approve, then can purchase this
        bytes32 hashedAuthorizeNFTbyAmount = hashAuthorizeNFT(authorizedNFTSubmit, isByDuration);

        ///@dev temporary use Count option and count=1, will update the options later.
        //https://ethereum.stackexchange.com/questions/1511/how-to-initialize-a-struct
        require(count > 0, "NOT POSITIVE COUNT");
        Term memory newTerm = Term(0, 0, count, isByDuration);
        bytes32 singature = hashedAuthorizeNFTbyAmount; // TODO: Tempoary set to be hashed NFT

        bytes32 hashedNft = hashNftInfo(authorizedNFTSubmit.nft);

        uint256 currentStartPrice;
        // check if has record on-chain, if not default is 0
        // if has record on-chain
        if (nftOnRecord.contains(hashedNft)) {
            // get the latest start price from record on chain
            currentStartPrice = getCurrentStartingPricePerNFT(hashedNft, isByDuration);
        } else {
            // new NFT to be licenced
            // get the start price from the input
            nftOnRecord.add(hashedNft);
            currentStartPrice = authorizedNFTSubmit.authorizedByCountInfo.latestStartPrice;
            // input the list start and end time, add the authorizer struct info
            authroizeRecordMap[hashedNft]
                .authorizedNFT
                .authorizedByCountInfo.
                listStartTime = authorizedNFTSubmit.authorizedByCountInfo.listStartTime;
            
            authroizeRecordMap[hashedNft]
                .authorizedNFT
                .authorizedByCountInfo.
                listEndTime = authorizedNFTSubmit.authorizedByCountInfo.listEndTime;
            
            authroizeRecordMap[hashedNft]
                .authorizedNFT
                .authorizer = authorizedNFTSubmit.authorizer;
            
            authroizeRecordMap[hashedNft]
                .authorizedNFT
                .nft = authorizedNFTSubmit.nft;
        }


        // compute the current termPrice by smart price engine
        // function computeAuthroizedPriceByCount(uint256 count, uint256 countFactor, uint256 countOrder, uint256 currentStartPrice, uint256 max_threshold_price )
        uint256 termedPrice = SmartPriceEngine.computeAuthroizedPriceByCount(
            count,
            priceParams.countFactor,
            priceParams.countOrder,
            currentStartPrice,
            priceParams.max_threshold_price
        );

        // update the authorizedNFT info
        authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByCountInfo
            .latestStartPrice = currentStartPrice;

        authroizeRecordMap[hashedNft].authorizedNFT.authorizedByCountInfo.lastActive = block
            .timestamp;

        AuthorizedNFT memory tempAuthorizedNFT = authroizeRecordMap[hashedNft]
            .authorizedNFT;

        AuthorizeCertificate
            memory newAuthorizeCertificate = AuthorizeCertificate(
                tempAuthorizedNFT,
                newTerm,
                renterAddress,
                termedPrice,
                singature
            );
        // function updatePurchaseState(AuthorizedNFT memory newAuthorizeCertificate, bytes32 hashedAuthorizeNFT, bytes32 singature )
        updatePurchaseState(newAuthorizeCertificate, hashedAuthorizeNFTbyAmount);

        // put transfer at the end to prevent the reentry attack
        acceptedUSDT.transferFrom(msg.sender, address(this), termedPrice);
    }

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
        bool isByDuration,
        address renterAddress
    ) private {
        // first get approved amount from USDT approve, then can purchase this
        bytes32 hashedAuthorizeNFTbyDuration = hashAuthorizeNFT(authorizedNFTSubmit, isByDuration);

        ///@dev temporary use Count option and count=1, will update the options later.
        //https://ethereum.stackexchange.com/questions/1511/how-to-initialize-a-struct
        require(authorizedEndTime > authorizedStartTime, "NEG TIMEWINDOW");
        Term memory newTerm = Term(authorizedStartTime, authorizedEndTime, 0, isByDuration);
        bytes32 singature = hashedAuthorizeNFTbyDuration; // TODO: Tempoary set to be hashed NFT

        bytes32 hashedNft = hashNftInfo(authorizedNFTSubmit.nft);

        uint256 currentStartPrice;
        // check if has record on-chain, if not default is 0
        // if has record on-chain
        if (nftOnRecord.contains(hashedNft)) {
            // get the latest start price from record on chain
            currentStartPrice = getCurrentStartingPricePerNFT(hashedNft, isByDuration);
        } else {
            // new NFT to be licenced
            // get the start price from the input
            nftOnRecord.add(hashedNft);
            currentStartPrice = authorizedNFTSubmit.authorizedByDurationInfo.latestStartPrice;
            // input the list start and end time, add the authorizer struct info
            authroizeRecordMap[hashedNft]
                .authorizedNFT
                .authorizedByDurationInfo
                .listStartTime = authorizedNFTSubmit.authorizedByDurationInfo.listStartTime;
            
            authroizeRecordMap[hashedNft]
                .authorizedNFT
                .authorizedByDurationInfo
                .listEndTime = authorizedNFTSubmit.authorizedByDurationInfo.listEndTime;
            
            authroizeRecordMap[hashedNft]
                .authorizedNFT
                .authorizer = authorizedNFTSubmit.authorizer;
            
            authroizeRecordMap[hashedNft]
                .authorizedNFT
                .nft = authorizedNFTSubmit.nft;
        }

        uint256 duration = authorizedEndTime - authorizedStartTime;

        // compute the current termPrice by smart price engine
        // function computeAuthroizedPriceByDuration(uint256 duration, uint256 durationFactor, uint256 durationOrder, uint256 currentStartPrice, uint256 max_threshold_price )
        uint256 termedPrice = SmartPriceEngine.computeAuthroizedPriceByDuration(
            duration,
            priceParams.durationFactor,
            priceParams.durationOrder,
            currentStartPrice,
            priceParams.max_threshold_price
        );

        // update the authorizedNFT info
        authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByDurationInfo
            .latestStartPrice = currentStartPrice;

        authroizeRecordMap[hashedNft].authorizedNFT.authorizedByDurationInfo.lastActive = block
            .timestamp;

        AuthorizedNFT memory tempAuthorizedNFT = authroizeRecordMap[hashedNft]
            .authorizedNFT;
        AuthorizeCertificate
            memory newAuthorizeCertificate = AuthorizeCertificate(
                tempAuthorizedNFT,
                newTerm,
                renterAddress,
                termedPrice,
                singature
            );
        // function updatePurchaseState(AuthorizedNFT memory newAuthorizeCertificate, bytes32 hashedAuthorizeNFT, bytes32 singature )
        updatePurchaseState(newAuthorizeCertificate, hashedAuthorizeNFTbyDuration);

        // put transfer at the end to prevent the reentry attack
        acceptedUSDT.transferFrom(msg.sender, address(this), termedPrice);
    }

    function hashNftInfo(NFT memory nft) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(nft.chainId, nft.NFTAddress, nft.tokenId)
            );
    }

    function hashAuthorizeNFT(AuthorizedNFT memory authorizedNFT, bool isByDuration)
        private
        pure
        returns (bytes32)
    {
        bytes32 hashedAuthorization = keccak256(
            abi.encodePacked(
                authorizedNFT.nft.chainId,
                authorizedNFT.nft.NFTAddress,
                authorizedNFT.nft.tokenId,
                authorizedNFT.authorizer.nftHolder,
                authorizedNFT.authorizer.claimAddress,
                isByDuration ? authorizedNFT.authorizedByDurationInfo.listStartTime : authorizedNFT.authorizedByCountInfo.listStartTime,
                isByDuration ? authorizedNFT.authorizedByDurationInfo.listEndTime : authorizedNFT.authorizedByCountInfo.listEndTime
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
        bytes32 hashedAuthorizeNFT
    ) private {
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
        AuthorizedNFT memory authorizedNFT = newAuthorizeCertificate
            .authorizedNFT;

        bytes32 hashedNft = hashNftInfo(authorizedNFT.nft);
        // update AuthroizedNFT record
        authroizeRecordMap[hashedNft].authorizeRecord.totalAuthorizedCount += 1;
        authroizeRecordMap[hashedNft]
            .authorizeRecord
            .totalTransactionRevenue += termedPrice;
        // update authorizeCertificateMap
        authorizeCertificateMap[hashedCertificate] = newAuthorizeCertificate;

        // update claimable address
        claimableMap[
            authroizeRecordMap[hashedNft].authorizedNFT.authorizer.claimAddress
        ] += termedPrice;

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

    function getCurrentStartingPriceAllNFTt(bool isByDuration)
        public
        view
        returns (bytes32[] memory, uint256[] memory)
    {
        uint256 size = nftOnRecord.length();
        bytes32[] memory hashedNfts = new bytes32[](size);
        uint256[] memory prices = new uint256[](size);

        for (uint256 i = 0; i < size; i++) {
            hashedNfts[i] = nftOnRecord.at(i);
            prices[i] = getCurrentStartingPricePerNFT(hashedNfts[i], isByDuration);
        }

        return (hashedNfts, prices);
    }

    function getCurrentStartingPricePerNFT(bytes32 hashedNft, bool isByDuration)
        public
        view
        returns (uint256)
    {
        uint256 latestTimeStamp;
        uint256 latestStartPrice;
        uint256 currentTxNum;

        currentTxNum = authroizeRecordMap[hashedNft]
        .authorizeRecord
        .totalAuthorizedCount;

        if (isByDuration) {
            
            latestTimeStamp = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByDurationInfo
            .lastActive;

            latestStartPrice = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByDurationInfo
            .latestStartPrice;
        } else {
            latestTimeStamp = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByCountInfo
            .lastActive;

            latestStartPrice = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByCountInfo
            .latestStartPrice;
        }
        

        //  function updateStartingPrice(uint256 currentTxNum, uint256 latestTimeStamp, uint256 latestStartPrice, uint256 discountPerTime, uint256 increment_by_tx, uint256 min_threshold_price )
        uint256 currentStartPrice = SmartPriceEngine.updateStartingPrice(
            currentTxNum,
            latestTimeStamp,
            latestStartPrice,
            priceParams.discountPerTime,
            priceParams.increment_by_tx,
            priceParams.min_threshold_price
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


    function getPriceParams() external view returns (PriceDynamicsParams memory) {
        return priceParams;
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

struct AuthorizedByCountInfo {
    uint256 listStartTime;
    uint256 listEndTime;
    uint256 latestStartPrice;
    uint256 lastActive; // last active timestamp
}

struct AuthorizedByDurationInfo {
    uint256 listStartTime;
    uint256 listEndTime;
    uint256 latestStartPrice;
    uint256 lastActive; // last active timestamp
}

struct AuthorizedNFT {
    NFT nft;
    Authorizer authorizer;
    AuthorizedByCountInfo authorizedByCountInfo;
    AuthorizedByDurationInfo authorizedByDurationInfo;
}

struct Term {
    uint256 authorizedStartTime;
    uint256 authorizedEndTime;
    uint256 count;
    bool isByDuration;
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

struct PriceDynamicsParams {
    uint256 countFactor;
    uint256 countOrder;
    uint256 durationFactor;
    uint256 durationOrder;
    uint256 max_threshold_price;
    uint256 min_threshold_price;
    uint256 increment_by_tx; 
    uint256 discountPerTime; // per day
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @dev compute the NFT authroization price
 # TODO: Overflow protection, fixed point arithmatics 
 */
library SmartPriceEngine {
    uint256 constant TIME_INTERVAL = 86400; // 1 day = 86400 sec
 

    function computeAuthroizedPriceByCount(
        uint256 count,
        uint256 countFactor,
        uint256 countOrder,
        uint256 currentStartPrice,
        uint256 max_threshold_price
    ) internal pure returns (uint256) {
        
        uint256 authorizedPrice = currentStartPrice + count**countOrder * countFactor;

        if (authorizedPrice > max_threshold_price) {
            return max_threshold_price;
        }

        return authorizedPrice;
        
    }


    function computeAuthroizedPriceByDuration(
        uint256 duration,
        uint256 durationFactor,
        uint256 durationOrder,
        uint256 currentStartPrice,
        uint256 max_threshold_price
    ) internal pure returns (uint256) {
        
        // incrementByDuration: for example 0.1 erc20 / 3600 sec
        uint256 authorizedPrice = currentStartPrice + duration**durationOrder * durationFactor / TIME_INTERVAL;

        if (authorizedPrice > max_threshold_price) {
            return max_threshold_price;
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
        uint256 discountPerTime,
        uint256 increment_by_tx,
        uint256 min_threshold_price
    ) internal view returns (uint256) {
        
        // since for NFT on record, it possible that start price is 0 byDuration option, or byAmoun options
        // due to no transcation yet
        if (latestStartPrice == 0) {
            return 0;
        }

        // TODO: not sure if save to cast the price here
        int256 currentLatestStartPrice = int256(latestStartPrice -
            ((block.timestamp - latestTimeStamp) * discountPerTime) /
            TIME_INTERVAL + increment_by_tx*currentTxNum);

        if (currentLatestStartPrice < int256(min_threshold_price)) {
            return min_threshold_price;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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