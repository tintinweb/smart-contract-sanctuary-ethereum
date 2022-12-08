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
contract IP3 is Ownable {
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
    ManageFee private manageFee;

    event Purchased(
        bytes32 indexed hashedNFT,
        bytes32 indexed hashedAuthorizeCertificate,
        address indexed renterAddress,
        AuthorizedNFT authorizedNFT,
        AuthorizeCertificate authorizeCertificate,
        bool isByDuration
    );

    event ClaimRevenue(address indexed claimAddress, uint256 claimRevenue);

    constructor(IERC20 instanceAddress, address manageFeeAddress) {
        acceptedUSDT = instanceAddress;
        priceParams = PriceDynamicsParams({
            countFactor: 10**6,
            countOrder: 1,
            durationFactor: 10**5,
            durationOrder: 1,
            max_threshold_price: 1000 * 10**6,
            min_threshold_price: 1 * 10**6,
            increment_by_tx: 10**5,
            discountPerTime: 10**5,
            discountDelay: 86400*7
        });

        manageFee = ManageFee({
            basisPoint: 3000,
            feeDecimal: 10**4,
            feeAddress: manageFeeAddress
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
        uint256 latestStartPriceByCountRecord = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByCountInfo
            .latestStartPrice;

        if ((nftOnRecord.contains(hashedNft)) && latestStartPriceByCountRecord !=0 ) {
            // get the latest start price from record on chain
            currentStartPrice = getCurrentStartingPricePerNFT(hashedNft, isByDuration);
        } else {
            // new NFT to be licenced
            // get the start price from the input
            nftOnRecord.add(hashedNft);
            currentStartPrice = authorizedNFTSubmit.authorizedByCountInfo.initialStartPrice;
            
            // input the list start and end time, add the authorizer struct info
            authroizeRecordMap[hashedNft]
                .authorizedNFT
                .authorizedByCountInfo.
                initialStartPrice = authorizedNFTSubmit.authorizedByCountInfo.initialStartPrice;
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
        updatePurchaseState(newAuthorizeCertificate, hashedAuthorizeNFTbyAmount, isByDuration);

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

        uint256 latestStartPriceByDurationRecord = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByDurationInfo
            .latestStartPrice;
        if (nftOnRecord.contains(hashedNft) && latestStartPriceByDurationRecord !=0) {
            // get the latest start price from record on chain
            currentStartPrice = getCurrentStartingPricePerNFT(hashedNft, isByDuration);
        } else {
            // new NFT to be licenced
            // get the start price from the input
            nftOnRecord.add(hashedNft);
            currentStartPrice = authorizedNFTSubmit.authorizedByDurationInfo.initialStartPrice;

            // input the list start and end time, add the authorizer struct info
            authroizeRecordMap[hashedNft]
                .authorizedNFT
                .authorizedByDurationInfo
                .initialStartPrice = authorizedNFTSubmit.authorizedByDurationInfo.initialStartPrice;
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
        updatePurchaseState(newAuthorizeCertificate, hashedAuthorizeNFTbyDuration, isByDuration);

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
        bytes32 hashedAuthorizeNFT,
        bool isByDuration
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

        // to management address
        uint256 fee = calculateFee(termedPrice);

        // received for authroizer after decution fee
        uint256 authorizerOwn = termedPrice - fee;

        claimableMap[
            manageFee.feeAddress
        ] += fee;

        AuthorizedNFT memory authorizedNFT = newAuthorizeCertificate
            .authorizedNFT;

        bytes32 hashedNft = hashNftInfo(authorizedNFT.nft);
        
        // update AuthroizedNFT record
        if (isByDuration) {
        authroizeRecordMap[hashedNft].authorizeRecord.durationRecord.totalAuthorizedCount += 1;
        
        authroizeRecordMap[hashedNft]
            .authorizeRecord
            .durationRecord
            .totalTransactionRevenue += termedPrice;
        // update authorizeCertificateMap
        authorizeCertificateMap[hashedCertificate] = newAuthorizeCertificate;

        // update claimable address
        // to authorizer address
        claimableMap[
            authroizeRecordMap[hashedNft].authorizedNFT.authorizer.claimAddress
        ] += authorizerOwn;



        } else {
        authroizeRecordMap[hashedNft].authorizeRecord.amountRecord.totalAuthorizedCount += 1;
        
        authroizeRecordMap[hashedNft]
            .authorizeRecord
            .amountRecord
            .totalTransactionRevenue += termedPrice;
        // update authorizeCertificateMap
        authorizeCertificateMap[hashedCertificate] = newAuthorizeCertificate;

        // update claimable address
        claimableMap[
            authroizeRecordMap[hashedNft].authorizedNFT.authorizer.claimAddress
        ] += authorizerOwn;

        }

        emit Purchased(
            hashedNft,
            hashedCertificate,
            msg.sender,
            authorizedNFT,
            newAuthorizeCertificate,
            isByDuration
        );

    }

    /*//////////////////////////////////////////////////////////////
                    SETTER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function setPriceParams(PriceDynamicsParams memory _priceParams) public onlyOwner {
        priceParams = _priceParams;
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

    function getCurrentStartPriceAllNFT()
        public
        view
        returns (bytes32[] memory, uint256[][] memory)
    {
        uint256 size = nftOnRecord.length();
        bytes32[] memory hashedNfts = new bytes32[](size);
        uint256[][] memory prices = new uint256[][](size);

        for (uint256 i = 0; i < size; i++) {
            hashedNfts[i] = nftOnRecord.at(i);
            uint256[] memory singleNFTPriceforBoth = new uint256[](2);

            singleNFTPriceforBoth= getCurrentStartPrice(hashedNfts[i]);
            prices[i] = singleNFTPriceforBoth;
        }

        return (hashedNfts, prices);
    }

    function getCurrentStartPrice(bytes32 hashedNft) public view returns (uint256[] memory) {
        uint256 [] memory priceBothOptions = new uint256[](2);
        // first index for byDuration option
        priceBothOptions[0] = getCurrentStartingPricePerNFT(hashedNft, true);
        priceBothOptions[1] = getCurrentStartingPricePerNFT(hashedNft, false);

        return priceBothOptions;

    }

    function getCurrentStartingPricePerNFT(bytes32 hashedNft, bool isByDuration)
        internal
        view
        returns (uint256)
    {
        uint256 latestTimeStamp;
        uint256 latestStartPrice;
        uint256 currentTxNum;
        uint256 initialStartPrice;

        if (isByDuration) {
            
            currentTxNum = authroizeRecordMap[hashedNft]
            .authorizeRecord
            .durationRecord
            .totalAuthorizedCount;

            latestTimeStamp = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByDurationInfo
            .lastActive;

            latestStartPrice = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByDurationInfo
            .latestStartPrice;

            initialStartPrice = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByDurationInfo
            .initialStartPrice;
        } else {
            
            currentTxNum = authroizeRecordMap[hashedNft]
            .authorizeRecord
            .amountRecord
            .totalAuthorizedCount;
            
            
            latestTimeStamp = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByCountInfo
            .lastActive;

            latestStartPrice = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByCountInfo
            .latestStartPrice;

            initialStartPrice = authroizeRecordMap[hashedNft]
            .authorizedNFT
            .authorizedByCountInfo
            .initialStartPrice;
        }
        

        //  function updateStartingPrice(uint256 currentTxNum, uint256 latestTimeStamp, uint256 latestStartPrice, uint256 discountPerTime, uint256 increment_by_tx, uint256 min_threshold_price )
        uint256 currentStartPrice = SmartPriceEngine.updateStartingPrice(
            currentTxNum,
            latestTimeStamp,
            latestStartPrice,
            priceParams.discountPerTime,
            priceParams.increment_by_tx,
            initialStartPrice,
            priceParams.discountDelay
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

    function getNftHash(NFT memory nft) external pure returns (bytes32) {
        
        return hashNftInfo(nft);
    }


    function getclaimableAmount(address user) external view returns (uint256) {
        return claimableMap[user];
    }

    /*//////////////////////////////////////////////////////////////
                    Transaction Fee
    //////////////////////////////////////////////////////////////*/
    function calculateFee(uint256 _amount) internal view returns (uint256) {
        uint256 fee = manageFee.basisPoint * _amount / manageFee.feeDecimal;
        return fee;
    }

    function setManageFee(ManageFee memory _managefee) public onlyOwner {
        manageFee = _managefee;
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
    uint256 initialStartPrice;
    uint256 lastActive; // last active timestamp
}

struct AuthorizedByDurationInfo {
    uint256 listStartTime;
    uint256 listEndTime;
    uint256 latestStartPrice;
    uint256 initialStartPrice;
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

struct DurationRecord {
    uint256 totalAuthorizedCount;
    uint256 totalTransactionRevenue;
}

struct AmountRecord {
    uint256 totalAuthorizedCount;
    uint256 totalTransactionRevenue;
}

struct AuthorizeRecord {
    DurationRecord durationRecord;
    AmountRecord amountRecord;
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
    uint256 discountDelay; // discount factor not take effect before
}

struct ManageFee {
    uint256 basisPoint;
    uint256 feeDecimal;
    address feeAddress;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";



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
        
        uint256 authorizedPrice = currentStartPrice + Math.log2(count**countOrder) * countFactor;

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
        uint256 authorizedPrice = currentStartPrice + Math.log2(duration**durationOrder) * durationFactor / TIME_INTERVAL;

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
        uint256 min_threshold_price,
        uint256 discountDelay
    ) internal view returns (uint256) {
        
        // since for NFT on record, it possible that start price is 0 byDuration option, or byAmoun options
        // due to no transcation yet
        if (latestStartPrice == 0) {
            return 0;
        }

        uint256 timeDiff = block.timestamp - latestTimeStamp;
        uint256 flag;
        
        flag = timeDiff > discountDelay ? 1 : 0;

        
        // TODO: not sure if save to cast the price here
        int256 currentLatestStartPrice = int256(latestStartPrice -
            (flag * timeDiff * discountPerTime) /
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
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