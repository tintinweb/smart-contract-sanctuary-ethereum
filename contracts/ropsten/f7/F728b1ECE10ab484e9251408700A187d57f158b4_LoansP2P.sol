// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract LoansP2P is Ownable, ReentrancyGuard {

    address public collateralToken; // Platform's collateral token address
    uint256 public standartFee; // Fee (in BPs) for standart offers 
    uint256 public topFee;  // Fee (in BPs) for top offers 
    address public signerAddress;   // Signer address
    uint256 public untilGetCollateral = 3600 * 24 * 30;   // The amount of time which must pass between loan expiration and collateral return

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;   // Mock ETH address for ERC20 compatibility

    enum OfferType {BORROW, LEND}
    enum Status {NONE, CREATED, ACCEPTED, GIVEN, EXPIRED, CANCELED}

    struct LoanInfo {
        OfferType offerType;     
        address maker;
        address currency;
        uint256 amount;
        uint256 minAmountOther;
        uint256 duration;
        uint256 interests; 
        int256 minRating;
        bool isTopOffer;
        uint256 takeDate;
        address taker;
        uint256 collateralAmount;
        Status offerStatus;
    }

    struct CreateOfferParameters {
        uint8 offerType;
        address currency;
        uint256 amount;
        uint256 duration;
        uint256 deadline;
        uint256 interests;
        uint256 minRating;
        bool isTopOffer;
    }

    mapping(address => bool) public supportedCurrencies;    // If the specified currency is supported or not
    mapping(address => uint256) public availableTokensForOwner; // Amounts of accumulated fees (in different tokens) available for owner to claim
    mapping(address => int256) public userRatings;  // The rating of the specified user

    LoanInfo[] public allLoansInfo; // The list of all LoanInfo structures

    event OfferCreated(
        uint8 offerType,
        address maker,
        address currency, 
        uint256 amount,
        uint256 duration, 
        uint256 minAmountOther,
        uint256 interests,
        int256 minRating,
        bool isTopOffer,
        uint256 offerId
    );

    event OfferAccepted(
        uint256 offerId, 
        uint256 amount,
        address taker
    );

    event Retrieved(uint256 offerId);
    event CollateralClaimed(uint256 offerId);
    event Canceled(uint256 offerId);

    constructor(
        address _collateralToken, 
        uint256 _standartFee, 
        uint256 _topFee,
        address _signerAddress
    ) {
        collateralToken = _collateralToken;
        require(_standartFee <= 10000 && _topFee <= 10000, "incorrect fee");
        standartFee = _standartFee;
        topFee = _topFee;
        signerAddress = _signerAddress;
    }

    /**
     * @notice Creates the offer. The platform comission will be claimed
     * @param offerType - The type of the offer (0 - BORROW, 1 - LEND)
     * @param currency - The address of the loan token 
     * @param amount - The amount of the loan token in case of LEND and amount of collateral token in case of BORROW
     * @param minAmountOther - The minimum amount of the collateral token in case of LEND and the minimum amoumt of the loan token in case of BORROW 
     * @param duration - The term of the loan
     * @param interests - The amount of interests to be payed to lender
     * @param minRating - The minimal rating of the taker
     * @param isTopOffer - Is this offer should be marked as 'top' or not (requires higher fee)
     */
    function createOffer(
        OfferType offerType, 
        address currency, 
        uint256 amount, 
        uint256 minAmountOther, 
        uint256 duration,
        uint256 interests,
        int256 minRating,
        bool isTopOffer
    ) public payable nonReentrant {
        require(supportedCurrencies[currency], "Currency is not supported");
        require(amount != 0, "Zero amount");

        LoanInfo memory loanInfo_;
        loanInfo_.offerType = offerType;
        loanInfo_.maker = msg.sender;
        loanInfo_.currency = currency;
        loanInfo_.minAmountOther = minAmountOther;
        loanInfo_.duration = duration;
        loanInfo_.interests = interests;
        loanInfo_.minRating = minRating;
        loanInfo_.isTopOffer = isTopOffer;
        loanInfo_.offerStatus = Status.CREATED;

        uint256 feePercentage = isTopOffer ? topFee : standartFee;
        address currencyToClaim = offerType == OfferType.BORROW ? collateralToken : currency;
        // claim the fee 
        uint256 amountAfterFee = amount * (10000 - feePercentage) / 10000;
        if (offerType == OfferType.BORROW) {
            // if the type of the offer is BORROW, transfer collateral and write it into the structure
            loanInfo_.collateralAmount = amountAfterFee;
            IERC20(currencyToClaim).transferFrom(msg.sender, address(this), amount); 
        } else { 
            // if the type of the offer is LEND, transfer lend token (or ETH) and write it into the structure
            loanInfo_.amount = amountAfterFee;
            if (currencyToClaim == ETH) {
                require(msg.value >= amount, "Not enough ETH");
            } else {
                IERC20(currencyToClaim).transferFrom(msg.sender, address(this), amount); 
            }
        }
        // add the fee to the owner's map
        availableTokensForOwner[currencyToClaim] += amount - amountAfterFee;

        allLoansInfo.push(loanInfo_);

        emit OfferCreated(
            offerType == OfferType.BORROW ? 0 : 1, 
            msg.sender, 
            currency, 
            amountAfterFee, 
            duration, 
            minAmountOther,
            interests, 
            minRating, 
            isTopOffer,
            allLoansInfo.length - 1
        );
    }

    /**
     * @notice Accepts a created offer. The platform comission will be claimed
     * @param offerId - The offer ID
     * @param amount - The amount of the loan token in case of BORROW and amount of collateral token in case of LEND
     * @param deadline - The deadline of the signature
     * @param signature - The backend's signature
     */
    function acceptOffer(
        uint256 offerId, 
        uint256 amount,
        uint256 deadline,
        bytes memory signature
    ) public payable nonReentrant {
        LoanInfo memory loanInfo = allLoansInfo[offerId];
        require(msg.sender != loanInfo.maker, "Address is maker");
        require(loanInfo.offerStatus == Status.CREATED, "Offer not created");
        require(userRatings[msg.sender] >= loanInfo.minRating, "Not enough rating");
        require(block.timestamp <= deadline, "Time is over");
        require(verifySignatureForAcceptOffer(offerId, deadline, amount, signature), "Invalid signature");

        address currencyToClaim = loanInfo.offerType == OfferType.BORROW ? loanInfo.currency : collateralToken;

        // always claim the standart fee
        uint256 amountAfterFee = amount * (10000 - standartFee) / 10000;
        require(amountAfterFee >= loanInfo.minAmountOther, "The amount is below min amount");
        if (loanInfo.offerType == OfferType.BORROW) {
            // if offer type is BORROW send the loan token (or ETH) from the taker to the maker, 
            // claiming fee and writing the amount to the structure
            if (currencyToClaim == ETH) {
                require(msg.value >= amount, "Not enough funds");
                payable(loanInfo.maker).transfer(amountAfterFee);
            } else {
                IERC20(currencyToClaim).transferFrom(msg.sender, address(this), amount - amountAfterFee);
                IERC20(currencyToClaim).transferFrom(msg.sender, loanInfo.maker, amountAfterFee);
            }
            allLoansInfo[offerId].amount = amountAfterFee;
        } else {
            // if offer type is LEND claim the collateral token, send the loan token (or ETH) to the taker
            // claiming fee and writing the amount to the structure

            IERC20(currencyToClaim).transferFrom(msg.sender, address(this), amount);
            if (loanInfo.currency == ETH) {
                payable(msg.sender).transfer(loanInfo.amount);
            } else {
                IERC20(loanInfo.currency).transfer(msg.sender, loanInfo.amount);
            }
            allLoansInfo[offerId].collateralAmount = amountAfterFee;
        }
        availableTokensForOwner[currencyToClaim] += amount - amountAfterFee;

        allLoansInfo[offerId].takeDate = block.timestamp;
        allLoansInfo[offerId].taker = msg.sender;
        allLoansInfo[offerId].offerStatus = Status.ACCEPTED;

        emit OfferAccepted(offerId, amount, msg.sender);

    }

    
    /**
     * @notice Cancels a created offer
     * @dev Can be called only by maker if nobody accepted the offer
     * @param offerId - The offer ID
     */
    function cancelOrder(uint256 offerId) public nonReentrant {
        LoanInfo memory loanInfo = allLoansInfo[offerId];
        require(loanInfo.offerStatus == Status.CREATED, "Order doesn't exist or accepted");
        require(msg.sender == loanInfo.maker, "You are not the maker");

        if (loanInfo.offerType == OfferType.BORROW) {
            // if the offer type is BORROW, transfer the collateral back
            IERC20(collateralToken).transfer(msg.sender, loanInfo.collateralAmount);
        } else {
            // if the offer type is LEND, transfer the loan token (or ETH) back
            if (loanInfo.currency == ETH) {
                payable(msg.sender).transfer(loanInfo.amount);
            } else {
                IERC20(loanInfo.currency).transfer(msg.sender, loanInfo.amount);
            }
        }
        allLoansInfo[offerId].offerStatus = Status.CANCELED;  
        emit Canceled(offerId); 
    }

    /**
     * @notice Refunds a loan
     * @param offerId - The offer ID
     * @param user - An address of the user who calls the function
     * @param ratingChange - The absolute value of the user rating change (will be added to the borrower's rating)
     * @param signatureDeadline - The deadline of the signature
     * @param signature - The backend's signature
     */
    function refund(
        uint256 offerId, 
        address user, 
        uint256 ratingChange, 
        uint256 signatureDeadline, 
        bytes memory signature
    ) public payable nonReentrant {
        LoanInfo memory loanInfo = allLoansInfo[offerId];
        require(loanInfo.offerStatus == Status.ACCEPTED, "Order is not accepted");
        require(block.timestamp <= signatureDeadline, "Signature is expired");
        require(block.timestamp <= loanInfo.takeDate + loanInfo.duration, "Loan is expired");
        // the address of the borrower (in case of BORROW type it's a maker, otherwise taker)
        address sender = loanInfo.offerType == OfferType.BORROW ? loanInfo.maker : loanInfo.taker;
        // the address of the lender
        address receiver = loanInfo.offerType == OfferType.LEND ? loanInfo.maker : loanInfo.taker;
        require(msg.sender == sender && msg.sender == user, "Access denied");
        require(
            verifySignatureForRatingChange(
                offerId, 
                user, 
                ratingChange, 
                signatureDeadline, 
                signature
            ), "Invalid signature"
        );

        uint256 amountToRefund = loanInfo.amount + loanInfo.interests;
        if (loanInfo.currency == ETH) {
            require(msg.value >= amountToRefund, "not enough ETH");
            payable(receiver).transfer(amountToRefund);
        } else {
            IERC20(loanInfo.currency).transferFrom(msg.sender, receiver, amountToRefund);
        } 
        // increase borrower's rating
        userRatings[msg.sender] += int256(ratingChange);

        IERC20(collateralToken).transfer(msg.sender, loanInfo.collateralAmount);     

        allLoansInfo[offerId].offerStatus = Status.GIVEN;   

        emit Retrieved(offerId);
    }


    /**
     * @notice Returns the collateral token if the loan is expired
     * @param offerId - The offer ID
     * @param user - An address of the user who calls the function
     * @param ratingChange - The absolute value of the user rating change (will be decreased from the borrower's rating)
     * @param signatureDeadline - The deadline of the signature
     * @param signature - The backend's signature
     */
    function getCollateral(
        uint256 offerId, 
        address user, 
        uint256 ratingChange, 
        uint256 signatureDeadline, 
        bytes memory signature
    ) public nonReentrant {
        LoanInfo memory loanInfo = allLoansInfo[offerId];
        require(block.timestamp >= loanInfo.takeDate + loanInfo.duration + untilGetCollateral, "Not enough time has passed");
        // the receiver of the collateral token (taker in case of BORROW type, maker otherwise)
        address receiver = loanInfo.offerType == OfferType.BORROW ? loanInfo.taker : loanInfo.maker;
        require(msg.sender == receiver && msg.sender == user, "Access denied");
        require(block.timestamp >= signatureDeadline, "Signature expired");
        require(
            verifySignatureForRatingChange(
                offerId, 
                user, 
                ratingChange, 
                signatureDeadline, 
                signature
            ), "Invalid signature"
        );

        IERC20(collateralToken).transfer(msg.sender, loanInfo.collateralAmount);     
        // the address of borrower (maker in case of BORROW type, taker otherwise)       
        address defaultedBorrower = loanInfo.offerType == OfferType.BORROW ? loanInfo.maker : loanInfo.taker;
        // we decrease the borrower's rating      
        userRatings[defaultedBorrower] -= int256(ratingChange);
        allLoansInfo[offerId].offerStatus = Status.EXPIRED;

        emit CollateralClaimed(offerId);
    }

    /**
     * @notice Transfers all the fees accumulated in specified token to owner
     * @param token - The address of the token to transfer
     */
    function transferFees(address token) public onlyOwner {
        if (token == ETH) {
            payable(msg.sender).transfer(availableTokensForOwner[token]);
        } else {
            IERC20(token).transfer(msg.sender, availableTokensForOwner[token]); 
        }
    }

    /**
     * @notice Updates the rating of the specified user
     * @dev Only backend can call it
     * @param _user - The user to update rating to
     * @param _newRating - The new user rating
     */
    function updateRating(address _user, int256 _newRating) public {
        require(msg.sender == signerAddress, "Access denied");
        userRatings[_user] = _newRating;
    }

    /**
     * @notice Sets the standart fee
     * @dev Only owner can call it
     * @param _standartFee - New standart fee
     */
    function setStandartFee(uint256 _standartFee) public onlyOwner {
        require(_standartFee <= 10000, "incorrect fee");
        standartFee = _standartFee;
    }

    /**
     * @notice Sets the top fee
     * @dev Only owner can call it
     * @param _topFee - New top fee
     */
    function setTopFee(uint256 _topFee) public onlyOwner {
        require(_topFee <= 10000, "incorrect fee");
        topFee = _topFee;
    }

    /**
     * @notice Sets the new time delay for returning collateral
     * @dev Only owner can call it
     * @param _newUntilGetCollateral - New delay
     */
    function setUntilGetCollateral(uint256 _newUntilGetCollateral) public onlyOwner {
        untilGetCollateral = _newUntilGetCollateral;
    }

    /**
     * @notice Sets the new signer's address
     * @dev Only owner can call it
     * @param _signerAddress - New signer address
     */
    function setSignerAddress(address _signerAddress) public onlyOwner {
        signerAddress = _signerAddress;
    }

    /**
     * @notice Adds a currency to lend
     * @dev Only owner can call it
     * @param currency - New currency address
     */
    function addSupportedCurrencies(address currency) public onlyOwner {
        require(!supportedCurrencies[currency], "!new");
        supportedCurrencies[currency] = true;
    }

    /**
     * @notice Removes a currency form lend currencies list
     * @dev Only owner can call it
     * @param currency - Currency address
     */
    function removeSupportedCurrencies(address currency) public onlyOwner {
        require(supportedCurrencies[currency], "Not in the list");
        supportedCurrencies[currency] = false;
    }
    

    function verifySignatureForAcceptOffer(
        uint256 offerId,
        uint256 amount, 
        uint256 deadline, 
        bytes memory signature
    ) public view returns (bool) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        offerId,
                        deadline,
                        amount
                    )
                ), signature
            ) == signerAddress;
    }

    function verifySignatureForRatingChange(
        uint256 offerId, 
        address user, 
        uint256 ratingChange, 
        uint256 signatureDeadline,
        bytes memory signature
    ) public view returns (bool) {
        return
            ECDSA.recover(
                keccak256(
                    abi.encodePacked(
                        offerId,
                        user,
                        ratingChange,
                        signatureDeadline
                    )
                ), signature
            ) == signerAddress;
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}