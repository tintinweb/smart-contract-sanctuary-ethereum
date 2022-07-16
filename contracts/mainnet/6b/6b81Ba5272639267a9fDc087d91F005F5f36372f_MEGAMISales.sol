// SPDX-License-Identifier: MIT

// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxdol:;,''....'',;:lodxxxxxxxxxxxxxxxxxxxxxdlc;,''....'',;:codxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxdc;'.                .';ldxxxxxxxxxxxxxxdl;'.                ..;cdxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxdl;.                        .;ldxxxxxxxxxo;.                        .;ldxxxxxxxxxxxxxx
// xxxxxxxxxxxxxl,.                            .,lxxxxxxo;.                            .'ldxxxxxxxxxxxx
// xxxxxxxxxxxo;.                                .,lddo;.                                .;oxxxxxxxxxxx
// xxxxxxxxxxo'                                    ....                                    'lxxxxxxxxxx
// xxxxxxxxxl'                             .                   .                            .lxxxxxxxxx
// xxxxxxxxo,                             'c,.              .,c'                             'oxxxxxxxx
// xxxxxxxxc.                             .lxl,.          .,ldo.                             .:xxxxxxxx
// xxxxxxxd,                              .:xxxl,.      .,ldxxc.                              'oxxxxxxx
// xxxxxxxo'                               ,dxxxxl,.  .,ldxxxd;                               .lxxxxxxx
// xxxxxxxo.                               .oxxxxxxl::ldxxxxxo'                               .lxxxxxxx
// xxxxxxxd,                               .cxxxxxxxxxxxxxxxxl.                               'oxxxxxxx
// xxxxxxxx:.           ..                  ;xxxxxxxxxxxxxxxx:                  ..            ;dxxxxxxx
// xxxxxxxxo'           ''                  'oxxxxxxxxxxxxxxd,                  .'           .lxxxxxxxx
// xxxxxxxxxc.          ;,                  .lxxxxxxxxxxxxxxo.                  ';.         .cxxxxxxxxx
// xxxxxxxxxxc.        .c,                  .:xxxxxxxxxxxxxxc.                  'c.        .cdxxxxxxxxx
// xxxxxxxxxxxl'       'l,       ..          ,dxxxxxxxxxxxxd;          ..       'l,       'lxxxxxxxxxxx
// xxxxxxxxxxxxd:.     ;o,       .'          .oxxxxxxxxxxxxo'          ..       'o:.    .:dxxxxxxxxxxxx
// xxxxxxxxxxxxxxd:.  .cd,       .;.         .cxxxxxxxxxxxxl.         .,'       'ol.  .:oxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxo:.,od,       .:.          ;xxxxxxxxxxxx:          .:'       'oo,.:oxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxdodd,       .l,          'dxxxxxxxxxxd,          'l'       'oxodxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxd;       .l:.         .lxxxxxxxxxxo.          :o'       ,dxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxd:.     .ol.         .:xxxxxxxxxxc.         .co'     .:oxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxd:.   .oo'          ;dxxxxxxxxd;          .oo'   .:oxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxo:. .od;          'oxxxxxxxxo'          ,do' .:oxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxd::oxc.         .cxxxxxxxxl.         .:xd::oxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxl.          ;xxxxxxxx:.         .lxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd;          'dxxxxxxd,          ,dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.        .lxxxxxxo.        .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.      .cxxxxxxc.      .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:.     ;dxxxxd;     .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd:.   'oxxxxo'   .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:. .cxxxxl. .:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxo:'cxxxxc,:oxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddxxxxddxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
//
// MEGAMI https://www.megami.io/

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/IMEGAMI.sol";

/**
 * @dev Implementation of the MEGAMI's sales contract.
 */
contract MEGAMISales is ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    /**
     * @dev The struct holding the status of each sale
     */
    struct SalesActiveStatus {
        bool auctionActive;
        bool privateSaleActive;
        bool publicSaleActive;
    }

    /**
     * @dev Minimum token ID of MEGAMI.
     */ 
    uint256 private constant START_TOKEN_ID = 1;

    /**
     * @notice Total supply of MEGAMI tokens.
     */
    uint256 public constant MAX_SUPPLY = 10000;

    /**
     * @notice Reserved MEGAMI tokens reserved for the team.
     */
    uint256 public constant RESERVED_TOKENS_FOR_TEAM = 450;

    /**
     * @notice Length of the auction (seconds)
     */
    uint256 public constant AUCTION_LENGTH = 48 * 60 * 60; // DA finishes after 48 hours

    /**
     * @notice Start price of Origins in the auction.
     */ 
    uint256 public constant AUCTION_STARTING_PRICE_ORIGIN    = 10 ether;

    /**
     * @notice Start price of Alters in the auction.
     */ 
    uint256 public constant AUCTION_STARTING_PRICE_ALTER     = 5 ether;

    /**
     * @notice Start price of Generateds in the auction.
     */ 
    uint256 public constant AUCTION_STARTING_PRICE_GENERATED = 0.2 ether;

    /**
     * @notice Lowest price of MEGAMI tokens in the auction.
     */
    uint256 public constant AUCTION_LOWEST_PRICE = 0.08 ether;

    /**
     * @notice Price drop unit of Origins in the auction. Price reaches the lowest price after 24 hours.
     */
    uint256 public constant AUCTION_PRICE_DROP_UNIT_ORIGIN    = 0.21 ether; 

    /**
     * @notice Price drop unit of Alters in the auction. Price reaches the lowest price after 24 hours.
     */
    uint256 public constant AUCTION_PRICE_DROP_UNIT_ALTER     = 0.1025 ether;

    /**
     * @notice Price drop unit of Generateds in the auction. Price reaches the lowest price after 24 hours.
     */
    uint256 public constant AUCTION_PRICE_DROP_UNIT_GENERATED = 0.0025 ether;

    /**
     * @notice Price drop frequency (seconds).
     */
    uint256 public constant AUCTION_PRICE_DROP_FREQUENCY = 30 * 60;

    /**
     * @notice Total release waves. 
     */
    uint256 public constant TOTAL_RELEASE_WAVES = 5;

    /**
     * @notice Number of Origins in a wave.
     */
    uint256 public constant NUMBER_OF_ORIGINS_IN_WAVE = 6;  // 30 origins divided by 5 waves

    /**
     * @notice Release interval (seconds.)
     */
    uint256 public constant RELEASE_WAVE_TIME_INTERVAL = 60 * 60 * 1; // Relese new wave every 1 hour

    /**
     * @notice Starting time (seconds) of the auction.
     * @dev To convert into readable time https://www.unixtimestamp.com/
     */
    uint256 public auctionStartingTimestamp;

    /**
     * @notice The status of each sale
     */
    SalesActiveStatus public salesStatus = SalesActiveStatus(false, false, false);

    /**
     * @notice The price of MEGAMI tokens in the private/public sale. 
     */
    uint256 public fixedSalePrice = 0.08 ether;

    /**
     * @notice Total number of MEGAMI tokens sold so far.
     */
    uint256 public totalSold = 0;

    /**
     * @dev Address of the fund manager contract.
     */
    address private fundManager;

    /**
     * @dev Address of the MEGAMI token contract.
     */
    IMEGAMI private megamiToken;
    
    /**
     * @dev Signer of the ML management signature.
     */
    address private mlSigner;

    /**
     * @dev Map to manage consumed ML spots per minter.
     */
    mapping(address => uint256) private userToUsedMLs;

    /**
     * @dev Constractor of MEGAMI's sales contract. Setting the MEGAMI token and fund manager.
     * @param megamiContractAddress Address of the MEGAMI token contract.
     * @param fundManagerContractAddress Address of the contract managing funds.
     */
    constructor(address megamiContractAddress, address fundManagerContractAddress){
        megamiToken = IMEGAMI(payable(megamiContractAddress));
        fundManager = payable(fundManagerContractAddress);
    }

    /**
     * @dev The modifier allowing the function access only for real humans.
     */
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    /**
     * @dev For receiving fund in case someone try to send it.
     */
    receive() external payable {}
    
    /**
     * @dev Set the address of the signer being used for validating Mintlist signatures.
     */
    function setSigner(address signer) external onlyOwner {
        mlSigner = signer;
    }

    /**
     * @dev Mint the specified MEGAMI token with auction price. 
     * @param signature Signature being used for validating the Mintlist spots of the minter.
     * @param mlSpots Total number of mintlist spots allocated to the minter.
     * @param tokenId Token ID being minted.
     */
    function mintDA(bytes calldata signature, uint8 mlSpots, uint256 tokenId) external payable callerIsUser nonReentrant {
        require(salesStatus.auctionActive, "DA isnt active");
        
        //Require DA started
        require(
            block.timestamp >= auctionStartingTimestamp,
            "DA has not started!"
        );        

        require(block.timestamp <= getAuctionEndTime(), "DA is finished");

        // Validate Mintlist
        require(verifySignature(signature, mlSpots), "Signer address mismatch.");

        // Check number of ML spots
        require(
            userToUsedMLs[msg.sender] < mlSpots,
            "All ML spots have been consumed"
        );

        // Check total sold
        require(totalSold < (MAX_SUPPLY - RESERVED_TOKENS_FOR_TEAM), "sold out");

        // Get current mint price
        uint256 _currentPrice = currentPrice(tokenId);

        // Validate the paid amount
        require(msg.value >= _currentPrice, "Did not send enough eth.");

        // Send back overpaid amount if minter sent more than _currentPrice
        if (msg.value > _currentPrice) {
            (bool sent, ) = msg.sender.call{value: msg.value - _currentPrice}("");
            require(sent, "failed to send back fund");
        }

        // Increment used ML spots
        unchecked { ++userToUsedMLs[msg.sender]; }

        // Increment total sold
        unchecked { ++totalSold; }

        megamiToken.mint(tokenId, msg.sender);
    }

    /**
     * @dev Returns the used ML spots of the user
     * @param user The address of a user being checked
     */
    function getUsedMLs(address user) external view returns(uint256) {
        return userToUsedMLs[user];
    }

    /**
     * @dev Set the price of the private/public sale.
     * @param newPrice The new price of the private/public sale.
     */
    function setFixedSalePrice(uint256 newPrice) external onlyOwner {
        fixedSalePrice = newPrice;
    }

    /**
     * @dev Mint the specified MEGAMI token with public price.  
     * @param tokenId Token ID being minted.
     */
    function mintPrivate(bytes calldata signature, uint8 mlSpots, uint256 tokenId) external payable callerIsUser nonReentrant {
        require(salesStatus.privateSaleActive, "Private sale isn't active");

        // Validate eligibility. 
        // Since we don't check the number of mlSpots in Private sale, 
        // mlSpots = 0 works as a waitlist which can mint in private sale.
        require(verifySignature(signature, mlSpots), "Signer address mismatch.");

        require(msg.value == fixedSalePrice, "Incorrect amount of eth.");

        // Check total sold
        require(totalSold < (MAX_SUPPLY - RESERVED_TOKENS_FOR_TEAM), "sold out");

        // Increment total sold
        unchecked { ++totalSold; }

        megamiToken.mint(tokenId, msg.sender);
    }

    /**
     * @dev Mint the specified MEGAMI token with public price.  
     * @param tokenId Token ID being minted.
     */
    function mintPublic(uint256 tokenId) external payable callerIsUser nonReentrant {
        require(salesStatus.publicSaleActive, "Public sale isn't active");
        require(msg.value == fixedSalePrice, "Incorrect amount of eth.");

        // Check total sold
        require(totalSold < (MAX_SUPPLY - RESERVED_TOKENS_FOR_TEAM), "sold out");

        // Increment total sold
        unchecked { ++totalSold; }

        megamiToken.mint(tokenId, msg.sender);
    }

    /**
     * @dev Mint the specified MEGAMI tokens and send to the specified recipient. Mainly used for giving Free MEGAMIs.
     * @param recipient Recipient whom minted tokens are transfered to.
     * @param tokenIds Token IDs being minted.
     */
    function mintTeam(address recipient, uint256[] calldata tokenIds) external onlyOwner {
        require(address(recipient) != address(0), "recipient address is necessary");
        uint256 count = tokenIds.length;
        for (uint256 i = 0; i < count;) {
            // Increment total sold
            unchecked { ++totalSold; }

            megamiToken.mint(tokenIds[i], recipient);
            unchecked { ++i; }
        }
    }

    /**
     * @dev Set the active status of auction.
     */
    function setDutchActionActive(bool isActive) external onlyOwner {
        require(mlSigner != address(0), "Mintlist signer must be set before starting auction");
        salesStatus.auctionActive = isActive;
    }

    /**
     * @dev Returns the active status of the auction
     */
    function getDutchAuctionActive() external view returns (bool) {
        return salesStatus.auctionActive;
    }

    /**
     * @dev Set the active status of private sale.
     */
    function setPrivateSaleActive(bool isActive) external onlyOwner {
        salesStatus.privateSaleActive = isActive;
    }

    /**
     * @dev Returns the active status of the private sale
     */
    function getPrivateSaleActive() external view returns (bool) {
        return salesStatus.privateSaleActive;
    }

    /**
     * @dev Set the active status of public sale.
     */
    function setPublicSaleActive(bool isActive) external onlyOwner {
        salesStatus.publicSaleActive = isActive;
    }

    /**
     * @dev Returns the active status of the public sale
     */
    function getPublicSaleActive() external view returns (bool) {
        return salesStatus.publicSaleActive;
    }
    
    /**
     * @dev Set the address of the fund manager contract.
     * @param contractAddr Address of the contract managing funds.
     */
    function setFundManagerContract(address contractAddr)
        external
        onlyOwner
    {
        require(contractAddr != address(0), "invalid address");
        fundManager = contractAddr;
    } 

    /**
     * @dev Return the address of the fund manager contarct.
     */
    function getFundManagerContract() external view returns (address) {
        return fundManager;
    }

    /**
     * @dev Allow owner to send funds directly to recipient. This is for emergency purpose and use moveFundToManager for regular withdraw.
     * @param recipient The address of the recipinet.
     */
    function emergencyWithdraw(address recipient) external onlyOwner {
        require(recipient != address(0), "recipient shouldn't be 0");

        (bool sent, ) = recipient.call{value: address(this).balance}("");
        require(sent, "failed to withdraw");
    }

    /**
     * @dev Move all of funds to the fund manager contract.
     */
    function moveFundToManager() external onlyOwner {
        require(fundManager != address(0), "fundManager shouldn't be 0");
        
        (bool sent, ) = fundManager.call{value: address(this).balance}("");
        require(sent, "failed to move fund to FundManager contract");
    }

    /**
     * @dev ERC20s should not be sent to this contract, but if someone does, it's nice to be able to recover them.
     *      Copied from ForgottenRunesWarriorsGuild. Thank you dotta ;)
     * @param token IERC20 the token address
     * @param amount uint256 the amount to send
     */
    function forwardERC20s(IERC20 token, uint256 amount) public onlyOwner {
        token.transfer(msg.sender, amount);
    }

    /**
     * @dev Return the current price of the specified token.
     * @param tokenId Token ID the price is being returned for.
     */
    function currentPrice(uint256 tokenId) public view returns (uint256) {
        require(tokenId >= START_TOKEN_ID && tokenId < START_TOKEN_ID + MAX_SUPPLY, "invalid token id");

        uint256 currentTimestamp = block.timestamp;
        uint256 wave = getWave(tokenId);
        uint256 waveDAStartedTimestamp = auctionStartingTimestamp + (RELEASE_WAVE_TIME_INTERVAL * wave);

        require(
            currentTimestamp >= waveDAStartedTimestamp,
            "wave mint yet"
        );

        //Seconds since we started
        uint256 timeSinceStart = currentTimestamp - waveDAStartedTimestamp;

        //How many decrements should've happened since that time
        uint256 decrementsSinceStart = timeSinceStart / AUCTION_PRICE_DROP_FREQUENCY;

        // Check the type of Megami and setting staring price and price drop
        uint256 startingPrice = AUCTION_STARTING_PRICE_GENERATED;
        uint256 priceDecrement = AUCTION_PRICE_DROP_UNIT_GENERATED;

        // Since the range of tokenId is 1 to 10000, we need to convert it to 0 to 9999 for getting the expected sequence id
        uint256 sequenceIdInWave = (tokenId - 1) % getSupplyPerWave();
        if(sequenceIdInWave < NUMBER_OF_ORIGINS_IN_WAVE + getNumberOfAlters(wave)) {
            if(sequenceIdInWave < NUMBER_OF_ORIGINS_IN_WAVE) {
                // Origin
                startingPrice = AUCTION_STARTING_PRICE_ORIGIN;
                priceDecrement = AUCTION_PRICE_DROP_UNIT_ORIGIN;
            } else {
                // Alter
                startingPrice = AUCTION_STARTING_PRICE_ALTER;
                priceDecrement = AUCTION_PRICE_DROP_UNIT_ALTER;
            }
        }

        // How much eth to remove
        uint256 totalDecrement = decrementsSinceStart * priceDecrement;

        //If how much we want to reduce is greater or equal to the range, return the lowest value
        if (totalDecrement >= startingPrice - AUCTION_LOWEST_PRICE) {
            return AUCTION_LOWEST_PRICE;
        }

        //If not, return the starting price minus the decrement.
        return startingPrice - totalDecrement;
    }

    /**
     * @dev Return the wave the specified token is being released.
     * @param tokenId Token ID the release wave is being returned for.
     */
    function getWave(uint256 tokenId) public pure returns (uint256) {
        // Since the range of tokenId is 1 to 10000, we need to convert it to 0 to 9999 for getting the expected wave number
        return (tokenId - 1) / getSupplyPerWave();
    }

    /**
     * @dev Set the start time of the auction. 
     * @param startTime Start time in unix timestamp format.
     */
    function setAuctionStartTime(uint256 startTime) public onlyOwner {
        auctionStartingTimestamp = startTime;
    }

    /**
     * @dev Returns the end time of the auction in unix timestamp format.
     */
    function getAuctionEndTime() public view returns (uint256) {
        return auctionStartingTimestamp + AUCTION_LENGTH;
    }
    
    /**
     * @dev Do nothing for disable renouncing ownership.
     */ 
    function renounceOwnership() public override onlyOwner {}     

    /**
     * @dev Returns the release waves where extra Alter are released. 
     *      Since there are 24 Alters and we can't evenly release them in each release wave, we need to release extra Alter in some waves.
     * @param wave Relase wave that this function checks if extra Alter is relased or not.
     */
    function getNumberOfAlters(uint256 wave) private pure returns (uint256) {
        // Since there are only 24 alters, it runs short of them in the 5th wave.
        return wave == 4 ? 4 : 5;
    }

    /**
     * @dev Return the amount of tokens being released in each release wave.
     */
    function getSupplyPerWave() private pure returns (uint256) {
        return MAX_SUPPLY / TOTAL_RELEASE_WAVES;
    }

    /**
     * @dev Verify the signature passed to the auction/private mint functions
     */
    function verifySignature(bytes calldata signature, uint8 mlSpots) private view returns (bool) {
        // Message format is 1 byte shifted address + number of MLs (1 byte)
        uint256 message = (uint256(uint160(msg.sender)) << 8) + mlSpots;
        
        return
            mlSigner ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(message)
                    )
                ).recover(signature);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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

/// @title Interface for MEGAMI ERC721 token

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMEGAMI is IERC721 {
    function mint(uint256 _tokenId, address _address) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}