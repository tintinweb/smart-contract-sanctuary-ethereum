pragma solidity 0.6.5;


contract TheSandbox712 {
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,address verifyingContract)");
    bytes32 public immutable DOMAIN_SEPARATOR;

    constructor() public {
        DOMAIN_SEPARATOR = keccak256(abi.encode(EIP712DOMAIN_TYPEHASH, keccak256("The Sandbox"), keccak256("1"), address(this)));
    }
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../common/BaseWithStorage/Admin.sol";
import "../common/Libraries/SigUtil.sol";
import "../common/Libraries/PriceUtil.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";
import "../common/Interfaces/ERC721.sol";
import "../common/Interfaces/ERC20.sol";
import "../common/Interfaces/ERC1271.sol";
import "../common/Interfaces/ERC1271Constants.sol";
import "../common/Interfaces/ERC1654.sol";
import "../common/Interfaces/ERC1654Constants.sol";
import "../common/Libraries/SafeMathWithRequire.sol";

import "../Base/TheSandbox712.sol";


contract P2PERC721Sale is Admin, ERC1654Constants, ERC1271Constants, TheSandbox712, MetaTransactionReceiver {
    using SafeMathWithRequire for uint256;

    enum SignatureType {DIRECT, EIP1654, EIP1271}

    mapping(address => mapping(uint256 => uint256)) public claimed;

    uint256 private constant MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    ERC20 internal _sand;
    uint256 internal _fee;
    address internal _feeCollector;

    struct Auction {
        uint256 id;
        address tokenAddress; // TODO support bundle : tokenAddress and tokenId should be arrays
        uint256 tokenId;
        address seller;
        uint256 startingPrice; // TODO support any ERC20 or ethereum as payment
        uint256 endingPrice;
        uint256 startedAt;
        uint256 duration;
    }

    event OfferClaimed(
        address indexed seller,
        address indexed buyer,
        uint256 indexed offerId,
        address tokenAddress,
        uint256 tokenId,
        uint256 pricePaid,
        uint256 feePaid
    );

    event OfferCancelled(address indexed seller, uint256 indexed offerId);

    event FeeSetup(address feeCollector, uint256 fee10000th);

    constructor(
        address sand,
        address admin,
        address feeCollector,
        uint256 fee,
        address initialMetaTx
    ) public {
        _sand = ERC20(sand);
        _admin = admin;

        _fee = fee;
        _feeCollector = feeCollector;
        emit FeeSetup(feeCollector, fee);

        _setMetaTransactionProcessor(initialMetaTx, true);
    }

    function setFee(address feeCollector, uint256 fee) external {
        require(msg.sender == _admin, "Sender not admin");
        _feeCollector = feeCollector;
        _fee = fee;
        emit FeeSetup(feeCollector, fee);
    }

    function _verifyParameters(address buyer, Auction memory auction) internal view {
        require(buyer == msg.sender || _metaTransactionContracts[msg.sender], "not authorized"); // if support any ERC20 :(token != address(0) &&

        require(claimed[auction.seller][auction.id] != MAX_UINT256, "Auction canceled");

        require(auction.startedAt <= now, "Auction has not started yet");

        require(auction.startedAt.add(auction.duration) > now, "Auction finished");
    }

    function claimSellerOffer(
        address buyer,
        address to,
        Auction calldata auction,
        bytes calldata signature,
        SignatureType signatureType,
        bool eip712
    ) external {
        _verifyParameters(buyer, auction);
        _ensureCorrectSigner(auction, signature, signatureType, eip712);
        _executeDeal(auction, buyer, to);
    }

    function _executeDeal(
        Auction memory auction,
        address buyer,
        address to
    ) internal {
        uint256 offer = PriceUtil.calculateCurrentPrice(
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            now.sub(auction.startedAt)
        );

        claimed[auction.seller][auction.id] = offer;

        uint256 fee = 0;

        if (_fee > 0) {
            fee = PriceUtil.calculateFee(offer, _fee);
        }

        require(_sand.transferFrom(buyer, auction.seller, offer.sub(fee)), "Funds transfer failed"); // TODO feeCollector

        ERC721 token = ERC721(auction.tokenAddress);

        token.safeTransferFrom(auction.seller, to, auction.tokenId); // TODO test safeTransferFrom fail
    }

    function cancelSellerOffer(uint256 id) external {
        claimed[msg.sender][id] = MAX_UINT256;
        emit OfferCancelled(msg.sender, id);
    }

    function _ensureCorrectSigner(
        Auction memory auction,
        bytes memory signature,
        SignatureType signatureType,
        bool eip712
    ) internal view returns (address) {
        bytes memory dataToHash;

        if (eip712) {
            dataToHash = abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, _hashAuction(auction));
        } else {
            dataToHash = _encodeBasicSignatureHash(auction);
        }

        if (signatureType == SignatureType.EIP1271) {
            require(
                ERC1271(auction.seller).isValidSignature(dataToHash, signature) == ERC1271_MAGICVALUE,
                "Invalid 1271 sig"
            );
        } else if (signatureType == SignatureType.EIP1654) {
            require(
                ERC1654(auction.seller).isValidSignature(keccak256(dataToHash), signature) == ERC1654_MAGICVALUE,
                "Invalid 1654 sig"
            );
        } else {
            address signer = SigUtil.recover(keccak256(dataToHash), signature);
            require(signer == auction.seller, "Invalid sig");
        }
    }

    function _encodeBasicSignatureHash(Auction memory auction) internal view returns (bytes memory) {
        return
            SigUtil.prefixed(
                keccak256(
                    abi.encodePacked(
                        address(this),
                        auction.id,
                        auction.tokenAddress,
                        auction.tokenId,
                        auction.seller,
                        auction.startingPrice,
                        auction.endingPrice,
                        auction.startedAt,
                        auction.duration
                    )
                )
            );
    }

    function _hashAuction(Auction memory auction) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    auction.id,
                    auction.tokenAddress,
                    auction.tokenId,
                    auction.seller,
                    auction.startingPrice,
                    auction.endingPrice,
                    auction.startedAt,
                    auction.duration
                )
            );
    }
}

pragma solidity 0.6.5;


contract Admin {
    address internal _admin;

    /// @dev emitted when the contract administrator is changed.
    /// @param oldAdmin address of the previous administrator.
    /// @param newAdmin address of the new administrator.
    event AdminChanged(address oldAdmin, address newAdmin);

    /// @dev gives the current administrator of this contract.
    /// @return the current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev change the administrator to be `newAdmin`.
    /// @param newAdmin address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "only admin can change admin");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "only admin allowed");
        _;
    }
}

pragma solidity 0.6.5;


library SigUtil {
    function recover(bytes32 hash, bytes memory sig) internal pure returns (address recovered) {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        require(v == 27 || v == 28);

        recovered = ecrecover(hash, v, r, s);
        require(recovered != address(0));
    }

    function recoverWithZeroOnFailure(bytes32 hash, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) {
            return (address(0));
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 hash) internal pure returns (bytes memory) {
        return abi.encodePacked("\x19Ethereum Signed Message:\n32", hash);
    }
}

pragma solidity 0.6.5;

import "./SafeMathWithRequire.sol";


library PriceUtil {
    using SafeMathWithRequire for uint256;

    function calculateCurrentPrice(
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 secondsPassed
    ) internal pure returns (uint256) {
        if (secondsPassed > duration) {
            return endingPrice;
        }
        if (endingPrice == startingPrice) {
            return endingPrice;
        } else if (endingPrice > startingPrice) {
            return startingPrice.add((endingPrice.sub(startingPrice)).mul(secondsPassed).div(duration));
        } else {
            return startingPrice.sub((startingPrice.sub(endingPrice)).mul(secondsPassed).div(duration));
        }
    }

    function calculateFee(uint256 price, uint256 fee10000th) internal pure returns (uint256) {
        // _fee < 10000, so the result will be <= price
        return (price.mul(fee10000th)) / 10000;
    }
}

pragma solidity 0.6.5;

import "./Admin.sol";


contract MetaTransactionReceiver is Admin {
    mapping(address => bool) internal _metaTransactionContracts;

    /// @dev emiited when a meta transaction processor is enabled/disabled
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    event MetaTransactionProcessor(address metaTransactionProcessor, bool enabled);

    /// @dev Enable or disable the ability of `metaTransactionProcessor` to perform meta-tx (metaTransactionProcessor rights).
    /// @param metaTransactionProcessor address that will be given/removed metaTransactionProcessor rights.
    /// @param enabled set whether the metaTransactionProcessor is enabled or disabled.
    function setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) public {
        require(msg.sender == _admin, "only admin can setup metaTransactionProcessors");
        _setMetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    function _setMetaTransactionProcessor(address metaTransactionProcessor, bool enabled) internal {
        _metaTransactionContracts[metaTransactionProcessor] = enabled;
        emit MetaTransactionProcessor(metaTransactionProcessor, enabled);
    }

    /// @dev check whether address `who` is given meta-transaction execution rights.
    /// @param who The address to query.
    /// @return whether the address has meta-transaction execution rights.
    function isMetaTransactionProcessor(address who) external view returns (bool) {
        return _metaTransactionContracts[who];
    }
}

pragma solidity 0.6.5;

import "./ERC165.sol";
import "./ERC721Events.sol";


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */

interface ERC721 is ERC165, ERC721Events {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    //   function exists(uint256 tokenId) external view returns (bool exists);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity 0.6.5;


/// @dev see https://eips.ethereum.org/EIPS/eip-20
interface ERC20 {
    /// @notice emitted when tokens are transfered from one address to another.
    /// @param from address from which the token are transfered from (zero means tokens are minted).
    /// @param to destination address which the token are transfered to (zero means tokens are burnt).
    /// @param value amount of tokens transferred.
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice emitted when owner grant transfer rights to another address
    /// @param owner address allowing its token to be transferred.
    /// @param spender address allowed to spend on behalf of `owner`
    /// @param value amount of tokens allowed.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice return the current total amount of tokens owned by all holders.
    /// @return supply total number of tokens held.
    function totalSupply() external view returns (uint256 supply);

    /// @notice return the number of tokens held by a particular address.
    /// @param who address being queried.
    /// @return balance number of token held by that address.
    function balanceOf(address who) external view returns (uint256 balance);

    /// @notice transfer tokens to a specific address.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transfer(address to, uint256 value) external returns (bool success);

    /// @notice transfer tokens from one address to another.
    /// @param from address tokens will be sent from.
    /// @param to destination address receiving the tokens.
    /// @param value number of tokens to transfer.
    /// @return success whether the transfer succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool success);

    /// @notice approve an address to spend on your behalf.
    /// @param spender address entitled to transfer on your behalf.
    /// @param value amount allowed to be transfered.
    /// @param success whether the approval succeeded.
    function approve(address spender, uint256 value) external returns (bool success);

    /// @notice return the current allowance for a particular owner/spender pair.
    /// @param owner address allowing spender.
    /// @param spender address allowed to spend.
    /// @return amount number of tokens `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender) external view returns (uint256 amount);
}

pragma solidity 0.6.5;


interface ERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param data Arbitrary length data signed on the behalf of address(this)
     * @param signature Signature byte array associated with _data
     * @return magicValue
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes calldata data, bytes calldata signature) external view returns (bytes4 magicValue);
}

pragma solidity 0.6.5;


contract ERC1271Constants {
    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;
}

pragma solidity 0.6.5;


interface ERC1654 {
    /**
     * @dev Should return whether the signature provided is valid for the provided hash
     * @param hash 32 bytes hash to be signed
     * @param signature Signature byte array associated with hash
     * @return magicValue 0x1626ba7e if valid else 0x00000000
     */
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bytes4 magicValue);
}

pragma solidity 0.6.5;


contract ERC1654Constants {
    bytes4 internal constant ERC1654_MAGICVALUE = 0x1626ba7e;
}

pragma solidity 0.6.5;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert
 */
library SafeMathWithRequire {
    using SafeMathWithRequire for uint256;

    uint256 constant DECIMALS_18 = 1000000000000000000;
    uint256 constant DECIMALS_12 = 1000000000000;
    uint256 constant DECIMALS_9 = 1000000000;
    uint256 constant DECIMALS_6 = 1000000;

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        require(c / a == b, "overflow");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "divbyzero");
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "undeflow");
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a, "overflow");
        return c;
    }

    function sqrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_12);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function sqrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_6);
        uint256 tmp = a.add(1) / 2;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            tmp = ((a / tmp) + tmp) / 2;
        }
    }

    function cbrt6(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_18);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
    }

    function cbrt3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_9);
        uint256 tmp = a.add(2) / 3;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpSquare = tmp**2;
            require(tmpSquare > tmp, "overflow");
            tmp = ((a / tmpSquare) + (tmp * 2)) / 3;
        }
        return c;
    }

    // TODO test
    function rt6_3(uint256 a) internal pure returns (uint256 c) {
        a = a.mul(DECIMALS_18);
        uint256 tmp = a.add(5) / 6;
        c = a;
        // tmp cannot be zero unless a = 0 which skip the loop
        while (tmp < c) {
            c = tmp;
            uint256 tmpFive = tmp**5;
            require(tmpFive > tmp, "overflow");
            tmp = ((a / tmpFive) + (tmp * 5)) / 6;
        }
    }
}

pragma solidity 0.6.5;


/**
 * @title ERC165
 * @dev https://eips.ethereum.org/EIPS/eip-165
 */
interface ERC165 {
    /**
     * @notice Query if a contract implements interface `interfaceId`
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity 0.6.5;


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface ERC721Events {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
}

pragma solidity 0.6.5;
import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/BaseWithStorage/Ownable.sol";
import "../common/Interfaces/ERC20.sol";


contract ERC20Impl is ERC20 {
    using SafeMathWithRequire for uint256;

    mapping(address => uint256) public _balances;

    mapping(address => mapping(address => uint256)) public _allowances;

    uint256 public _totalSupply;

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}


contract MintableToken is ERC20Impl, Ownable {
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    constructor() public Ownable(msg.sender) {}
}


contract MockERC20 is MintableToken {
    string public constant name = "Mock Token";
    string public constant symbol = "MCK";
    uint8 public constant decimals = 18;
}

pragma solidity 0.6.5;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor(address payable _owner) public {
        owner = _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // /**
    // * @dev Allows the current owner to relinquish control of the contract.
    // * @notice Renouncing to ownership will leave the contract without an owner.
    // * It will not be possible to call the functions with the `onlyOwner`
    // * modifier anymore.
    // */
    // function renounceOwnership() public onlyOwner {
    //     emit OwnershipRenounced(owner);
    //     owner = address(0);
    // }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address payable _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/Interfaces/ERC20.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";
import "../common/Interfaces/Medianizer.sol";
import "../common/BaseWithStorage/Admin.sol";
import "../Catalyst/ERC20GroupCatalyst.sol";
import "../Catalyst/ERC20GroupGem.sol";
import "./PurchaseValidator.sol";


/// @title StarterPack contract that supports SAND, DAI and ETH as payment
/// @notice This contract manages the purchase and distribution of StarterPacks (bundles of Catalysts and Gems)
contract StarterPackV1 is Admin, MetaTransactionReceiver, PurchaseValidator {
    using SafeMathWithRequire for uint256;
    uint256 internal constant DAI_PRICE = 44000000000000000;
    uint256 private constant DECIMAL_PLACES = 1 ether;

    ERC20 internal immutable _sand;
    Medianizer private immutable _medianizer;
    ERC20 private immutable _dai;
    ERC20Group internal immutable _erc20GroupCatalyst;
    ERC20Group internal immutable _erc20GroupGem;

    bool _sandEnabled;
    bool _etherEnabled;
    bool _daiEnabled;

    uint256[] private _starterPackPrices;
    uint256[] private _previousStarterPackPrices;
    uint256 private _gemPrice;
    uint256 private _previousGemPrice;

    // The timestamp of the last pricechange
    uint256 private _priceChangeTimestamp;

    address payable internal _wallet;

    // The delay between calling setPrices() and when the new prices come into effect.
    // Minimizes the effect of price changes on pending TXs
    uint256 private constant PRICE_CHANGE_DELAY = 1 hours;

    event Purchase(address indexed buyer, Message message, uint256 price, address token, uint256 amountPaid);

    event SetPrices(uint256[] prices, uint256 gemPrice);

    struct Message {
        uint256[] catalystIds;
        uint256[] catalystQuantities;
        uint256[] gemIds;
        uint256[] gemQuantities;
        uint256 nonce;
    }

    // ////////////////////////// Functions ////////////////////////

    /// @notice Set the wallet receiving the proceeds
    /// @param newWallet Address of the new receiving wallet
    function setReceivingWallet(address payable newWallet) external {
        require(newWallet != address(0), "WALLET_ZERO_ADDRESS");
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _wallet = newWallet;
    }

    /// @notice Enable / disable DAI payment for StarterPacks
    /// @param enabled Whether to enable or disable
    function setDAIEnabled(bool enabled) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _daiEnabled = enabled;
    }

    /// @notice Return whether DAI payments are enabled
    /// @return Whether DAI payments are enabled
    function isDAIEnabled() external view returns (bool) {
        return _daiEnabled;
    }

    /// @notice Enable / disable ETH payment for StarterPacks
    /// @param enabled Whether to enable or disable
    function setETHEnabled(bool enabled) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _etherEnabled = enabled;
    }

    /// @notice Return whether ETH payments are enabled
    /// @return Whether ETH payments are enabled
    function isETHEnabled() external view returns (bool) {
        return _etherEnabled;
    }

    /// @dev Enable / disable the specific SAND payment for StarterPacks
    /// @param enabled Whether to enable or disable
    function setSANDEnabled(bool enabled) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _sandEnabled = enabled;
    }

    /// @notice Return whether SAND payments are enabled
    /// @return Whether SAND payments are enabled
    function isSANDEnabled() external view returns (bool) {
        return _sandEnabled;
    }

    /// @notice Purchase StarterPacks with SAND
    /// @param buyer The destination address for the purchased Catalysts and Gems and the address that will pay for the purchase; if not metaTx then buyer must be equal to msg.sender
    /// @param message A message containing information about the Catalysts and Gems to be purchased
    /// @param signature A signed message specifying tx details

    function purchaseWithSand(
        address buyer,
        Message calldata message,
        bytes calldata signature
    ) external {
        require(msg.sender == buyer || _metaTransactionContracts[msg.sender], "INVALID_SENDER");
        require(_sandEnabled, "SAND_IS_NOT_ENABLED");
        require(buyer != address(0), "DESTINATION_ZERO_ADDRESS");
        require(
            isPurchaseValid(buyer, message.catalystIds, message.catalystQuantities, message.gemIds, message.gemQuantities, message.nonce, signature),
            "INVALID_PURCHASE"
        );

        uint256 amountInSand = _calculateTotalPriceInSand(message.catalystIds, message.catalystQuantities, message.gemQuantities);
        _handlePurchaseWithERC20(buyer, _wallet, address(_sand), amountInSand);
        _erc20GroupCatalyst.batchTransferFrom(address(this), buyer, message.catalystIds, message.catalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), buyer, message.gemIds, message.gemQuantities);
        emit Purchase(buyer, message, amountInSand, address(_sand), amountInSand);
    }

    /// @notice Purchase StarterPacks with Ether
    /// @param buyer The destination address for the purchased Catalysts and Gems and the address that will pay for the purchase; if not metaTx then buyer must be equal to msg.sender
    /// @param message A message containing information about the Catalysts and Gems to be purchased
    /// @param signature A signed message specifying tx details
    function purchaseWithETH(
        address buyer,
        Message calldata message,
        bytes calldata signature
    ) external payable {
        require(msg.sender == buyer || _metaTransactionContracts[msg.sender], "INVALID_SENDER");
        require(_etherEnabled, "ETHER_IS_NOT_ENABLED");
        require(buyer != address(0), "DESTINATION_ZERO_ADDRESS");
        require(buyer != address(this), "DESTINATION_STARTERPACKV1_CONTRACT");
        require(
            isPurchaseValid(buyer, message.catalystIds, message.catalystQuantities, message.gemIds, message.gemQuantities, message.nonce, signature),
            "INVALID_PURCHASE"
        );

        uint256 amountInSand = _calculateTotalPriceInSand(message.catalystIds, message.catalystQuantities, message.gemQuantities);
        uint256 ETHRequired = getEtherAmountWithSAND(amountInSand);
        require(msg.value >= ETHRequired, "NOT_ENOUGH_ETHER_SENT");

        _wallet.transfer(ETHRequired);
        _erc20GroupCatalyst.batchTransferFrom(address(this), buyer, message.catalystIds, message.catalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), buyer, message.gemIds, message.gemQuantities);
        emit Purchase(buyer, message, amountInSand, address(0), ETHRequired);

        if (msg.value - ETHRequired > 0) {
            // refund extra
            (bool success, ) = msg.sender.call{value: msg.value - ETHRequired}("");
            require(success, "REFUND_FAILED");
        }
    }

    /// @notice Purchase StarterPacks with DAI
    /// @param buyer The destination address for the purchased Catalysts and Gems and the address that will pay for the purchase; if not metaTx then buyer must be equal to msg.sender
    /// @param message A message containing information about the Catalysts and Gems to be purchased
    /// @param signature A signed message specifying tx details
    function purchaseWithDAI(
        address buyer,
        Message calldata message,
        bytes calldata signature
    ) external {
        require(msg.sender == buyer || _metaTransactionContracts[msg.sender], "INVALID_SENDER");
        require(_daiEnabled, "DAI_IS_NOT_ENABLED");
        require(buyer != address(0), "DESTINATION_ZERO_ADDRESS");
        require(buyer != address(this), "DESTINATION_STARTERPACKV1_CONTRACT");
        require(
            isPurchaseValid(buyer, message.catalystIds, message.catalystQuantities, message.gemIds, message.gemQuantities, message.nonce, signature),
            "INVALID_PURCHASE"
        );

        uint256 amountInSand = _calculateTotalPriceInSand(message.catalystIds, message.catalystQuantities, message.gemQuantities);
        uint256 DAIRequired = amountInSand.mul(DAI_PRICE).div(DECIMAL_PLACES);
        _handlePurchaseWithERC20(buyer, _wallet, address(_dai), DAIRequired);
        _erc20GroupCatalyst.batchTransferFrom(address(this), buyer, message.catalystIds, message.catalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), buyer, message.gemIds, message.gemQuantities);
        emit Purchase(buyer, message, amountInSand, address(_dai), DAIRequired);
    }

    /// @notice Enables admin to withdraw all remaining tokens
    /// @param to The destination address for the purchased Catalysts and Gems
    /// @param catalystIds The IDs of the catalysts to be transferred
    /// @param gemIds The IDs of the gems to be transferred
    function withdrawAll(
        address to,
        uint256[] calldata catalystIds,
        uint256[] calldata gemIds
    ) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");

        address[] memory catalystAddresses = new address[](catalystIds.length);
        for (uint256 i = 0; i < catalystIds.length; i++) {
            catalystAddresses[i] = address(this);
        }
        address[] memory gemAddresses = new address[](gemIds.length);
        for (uint256 i = 0; i < gemIds.length; i++) {
            gemAddresses[i] = address(this);
        }
        uint256[] memory unsoldCatalystQuantities = _erc20GroupCatalyst.balanceOfBatch(catalystAddresses, catalystIds);
        uint256[] memory unsoldGemQuantities = _erc20GroupGem.balanceOfBatch(gemAddresses, gemIds);

        _erc20GroupCatalyst.batchTransferFrom(address(this), to, catalystIds, unsoldCatalystQuantities);
        _erc20GroupGem.batchTransferFrom(address(this), to, gemIds, unsoldGemQuantities);
    }

    /// @notice Enables admin to change the prices of the StarterPack bundles
    /// @param prices Array of new prices that will take effect after a delay period
    /// @param gemPrice New price for gems that will take effect after a delay period

    function setPrices(uint256[] calldata prices, uint256 gemPrice) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _previousStarterPackPrices = _starterPackPrices;
        _starterPackPrices = prices;
        _previousGemPrice = _gemPrice;
        _gemPrice = gemPrice;
        _priceChangeTimestamp = now;
        emit SetPrices(prices, gemPrice);
    }

    /// @notice Get current StarterPack prices
    /// @return pricesBeforeSwitch Array of prices before price change
    /// @return pricesAfterSwitch Array of prices after price change
    /// @return gemPriceBeforeSwitch Gem price before price change
    /// @return gemPriceAfterSwitch Gem price after price change
    /// @return switchTime The time the latest price change will take effect, being the time of the price change plus the price change delay

    function getPrices()
        external
        view
        returns (
            uint256[] memory pricesBeforeSwitch,
            uint256[] memory pricesAfterSwitch,
            uint256 gemPriceBeforeSwitch,
            uint256 gemPriceAfterSwitch,
            uint256 switchTime
        )
    {
        switchTime = 0;
        if (_priceChangeTimestamp != 0) {
            switchTime = _priceChangeTimestamp + PRICE_CHANGE_DELAY;
        }
        return (_previousStarterPackPrices, _starterPackPrices, _previousGemPrice, _gemPrice, switchTime);
    }

    /// @notice Returns the amount of ETH for a specific amount of SAND
    /// @param sandAmount An amount of SAND
    /// @return The amount of ETH
    function getEtherAmountWithSAND(uint256 sandAmount) public view returns (uint256) {
        uint256 ethUsdPair = _getEthUsdPair();
        return sandAmount.mul(DAI_PRICE).div(ethUsdPair);
    }

    // ////////////////////////// Internal ////////////////////////

    /// @dev Gets the ETHUSD pair from the Medianizer contract
    /// @return The pair as an uint256
    function _getEthUsdPair() internal view returns (uint256) {
        bytes32 pair = _medianizer.read();
        return uint256(pair);
    }

    /// @dev Function to calculate the total price in SAND of the StarterPacks to be purchased
    /// @dev The price of each StarterPack relates to the catalystId
    /// @param catalystIds Array of catalystIds to be purchase
    /// @param catalystQuantities Array of quantities of those catalystIds to be purchased
    /// @return Total price in SAND
    function _calculateTotalPriceInSand(
        uint256[] memory catalystIds,
        uint256[] memory catalystQuantities,
        uint256[] memory gemQuantities
    ) internal returns (uint256) {
        require(catalystIds.length == catalystQuantities.length, "INVALID_INPUT");
        (uint256[] memory prices, uint256 gemPrice) = _priceSelector();
        uint256 totalPrice;
        for (uint256 i = 0; i < catalystIds.length; i++) {
            uint256 id = catalystIds[i];
            uint256 quantity = catalystQuantities[i];
            totalPrice = totalPrice.add(prices[id].mul(quantity));
        }
        for (uint256 i = 0; i < gemQuantities.length; i++) {
            uint256 quantity = gemQuantities[i];
            totalPrice = totalPrice.add(gemPrice.mul(quantity));
        }
        return totalPrice;
    }

    /// @dev Function to determine whether to use old or new prices
    /// @return Array of prices

    function _priceSelector() internal returns (uint256[] memory, uint256) {
        uint256[] memory prices;
        uint256 gemPrice;
        // No price change:
        if (_priceChangeTimestamp == 0) {
            prices = _starterPackPrices;
            gemPrice = _gemPrice;
        } else {
            // Price change delay has expired.
            if (now > _priceChangeTimestamp + PRICE_CHANGE_DELAY) {
                _priceChangeTimestamp = 0;
                prices = _starterPackPrices;
                gemPrice = _gemPrice;
            } else {
                // Price change has occured:
                prices = _previousStarterPackPrices;
                gemPrice = _previousGemPrice;
            }
        }
        return (prices, gemPrice);
    }

    /// @dev Function to handle purchase with SAND or DAI
    function _handlePurchaseWithERC20(
        address buyer,
        address payable paymentRecipient,
        address tokenAddress,
        uint256 amount
    ) internal {
        ERC20 token = ERC20(tokenAddress);
        uint256 amountForDestination = amount;
        require(token.transferFrom(buyer, paymentRecipient, amountForDestination), "PAYMENT_TRANSFER_FAILED");
    }

    // /////////////////// CONSTRUCTOR ////////////////////

    constructor(
        address starterPackAdmin,
        address sandContractAddress,
        address initialMetaTx,
        address payable initialWalletAddress,
        address medianizerContractAddress,
        address daiTokenContractAddress,
        address erc20GroupCatalystAddress,
        address erc20GroupGemAddress,
        address initialSigningWallet,
        uint256[] memory initialStarterPackPrices,
        uint256 initialGemPrice
    ) public PurchaseValidator(initialSigningWallet) {
        _setMetaTransactionProcessor(initialMetaTx, true);
        _wallet = initialWalletAddress;
        _admin = starterPackAdmin;
        _sand = ERC20(sandContractAddress);
        _medianizer = Medianizer(medianizerContractAddress);
        _dai = ERC20(daiTokenContractAddress);
        _erc20GroupCatalyst = ERC20Group(erc20GroupCatalystAddress);
        _erc20GroupGem = ERC20Group(erc20GroupGemAddress);
        _starterPackPrices = initialStarterPackPrices;
        _previousStarterPackPrices = initialStarterPackPrices;
        _gemPrice = initialGemPrice;
        _previousGemPrice = initialGemPrice;
        _sandEnabled = true; // Sand is enabled by default
        _etherEnabled = true; // Ether is enabled by default
    }
}

pragma solidity 0.6.5;


/**
 * @title Medianizer contract
 * @dev From MakerDAO (https://etherscan.io/address/0x729D19f657BD0614b4985Cf1D82531c67569197B#code)
 */
interface Medianizer {
    function read() external view returns (bytes32);
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../BaseWithStorage/ERC20Group.sol";
import "./CatalystDataBase.sol";
import "../BaseWithStorage/ERC20SubToken.sol";
import "./CatalystValue.sol";


contract ERC20GroupCatalyst is CatalystDataBase, ERC20Group {
    /// @dev add Catalyst, if one of the catalyst to be added in the batch need to have a value override, all catalyst added in that batch need to have override
    /// if this is not desired, they can be added in a separated batch
    /// if no override are needed, the valueOverrides can be left emopty
    function addCatalysts(
        ERC20SubToken[] memory catalysts,
        MintData[] memory mintData,
        CatalystValue[] memory valueOverrides
    ) public {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        require(catalysts.length == mintData.length, "INVALID_INCONSISTENT_LENGTH");
        for (uint256 i = 0; i < mintData.length; i++) {
            uint256 id = _addSubToken(catalysts[i]);
            _setMintData(id, mintData[i]);
            if (valueOverrides.length > i) {
                _setValueOverride(id, valueOverrides[i]);
            }
        }
    }

    function addCatalyst(
        ERC20SubToken catalyst,
        MintData memory mintData,
        CatalystValue valueOverride
    ) public {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        uint256 id = _addSubToken(catalyst);
        _setMintData(id, mintData);
        _setValueOverride(id, valueOverride);
    }

    function setConfiguration(
        uint256 id,
        uint16 minQuantity,
        uint16 maxQuantity,
        uint256 sandMintingFee,
        uint256 sandUpdateFee
    ) external {
        // CatalystMinter hardcode the value for efficiency purpose, so a change here would require a new deployment of CatalystMinter
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        _setConfiguration(id, minQuantity, maxQuantity, sandMintingFee, sandUpdateFee);
    }

    constructor(
        address metaTransactionContract,
        address admin,
        address initialMinter
    ) public ERC20Group(metaTransactionContract, admin, initialMinter) {}
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../BaseWithStorage/ERC20Group.sol";


contract ERC20GroupGem is ERC20Group {
    function addGems(ERC20SubToken[] calldata catalysts) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        for (uint256 i = 0; i < catalysts.length; i++) {
            _addSubToken(catalysts[i]);
        }
    }

    constructor(
        address metaTransactionContract,
        address admin,
        address initialMinter
    ) public ERC20Group(metaTransactionContract, admin, initialMinter) {}
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../common/Libraries/SigUtil.sol";
import "../common/BaseWithStorage/Admin.sol";


contract PurchaseValidator is Admin {
    address private _signingWallet;

    // A parallel-queue mapping to nonces.
    mapping(address => mapping(uint128 => uint128)) public queuedNonces;

    /// @notice Function to get the nonce for a given address and queue ID
    /// @param _buyer The address of the starterPack purchaser
    /// @param _queueId The ID of the nonce queue for the given address.
    /// The default is queueID=0, and the max is queueID=2**128-1
    /// @return uint128 representing the requestied nonce
    function getNonceByBuyer(address _buyer, uint128 _queueId) external view returns (uint128) {
        return queuedNonces[_buyer][_queueId];
    }

    /// @notice Check if a purchase message is valid
    /// @param buyer The address paying for the purchase & receiving tokens
    /// @param catalystIds The catalyst IDs to be purchased
    /// @param catalystQuantities The quantities of the catalysts to be purchased
    /// @param gemIds The gem IDs to be purchased
    /// @param gemQuantities The quantities of the gems to be purchased
    /// @param nonce The current nonce for the user. This is represented as a
    /// uint256 value, but is actually 2 packed uint128's (queueId + nonce)
    /// @param signature A signed message specifying tx details
    /// @return True if the purchase is valid
    function isPurchaseValid(
        address buyer,
        uint256[] memory catalystIds,
        uint256[] memory catalystQuantities,
        uint256[] memory gemIds,
        uint256[] memory gemQuantities,
        uint256 nonce,
        bytes memory signature
    ) public returns (bool) {
        require(_checkAndUpdateNonce(buyer, nonce), "INVALID_NONCE");
        bytes32 hashedData = keccak256(abi.encodePacked(catalystIds, catalystQuantities, gemIds, gemQuantities, buyer, nonce));

        address signer = SigUtil.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedData)), signature);
        return signer == _signingWallet;
    }

    /// @notice Get the wallet authorized for signing purchase-messages.
    /// @return the address of the signing wallet
    function getSigningWallet() external view returns (address) {
        return _signingWallet;
    }

    /// @notice Update the signing wallet address
    /// @param newSigningWallet The new address of the signing wallet
    function updateSigningWallet(address newSigningWallet) external {
        require(_admin == msg.sender, "SENDER_NOT_ADMIN");
        _signingWallet = newSigningWallet;
    }

    /// @dev Function for validating the nonce for a user.
    /// @param _buyer The address for which we want to check the nonce
    /// @param _packedValue The queueId + nonce, packed together.
    /// EG: for queueId=42 nonce=7, pass: "0x0000000000000000000000000000002A00000000000000000000000000000007"
    function _checkAndUpdateNonce(address _buyer, uint256 _packedValue) private returns (bool) {
        uint128 queueId = uint128(_packedValue / 2**128);
        uint128 nonce = uint128(_packedValue % 2**128);
        uint128 currentNonce = queuedNonces[_buyer][queueId];
        if (nonce == currentNonce) {
            queuedNonces[_buyer][queueId] = currentNonce + 1;
            return true;
        }
        return false;
    }

    constructor(address initialSigningWallet) public {
        _signingWallet = initialSigningWallet;
    }
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "./ERC20SubToken.sol";
import "../common/Libraries/SafeMath.sol";
import "../common/Libraries/AddressUtils.sol";
import "../common/Libraries/ObjectLib32.sol";
import "../common/Libraries/BytesUtil.sol";

import "../common/BaseWithStorage/SuperOperators.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";


contract ERC20Group is SuperOperators, MetaTransactionReceiver {
    uint256 internal constant MAX_UINT256 = ~uint256(0);

    /// @notice emitted when a new Token is added to the group.
    /// @param subToken the token added, its id will be its index in the array.
    event SubToken(ERC20SubToken subToken);

    /// @notice emitted when `owner` is allowing or disallowing `operator` to transfer tokens on its behalf.
    /// @param owner the address approving.
    /// @param operator the address being granted (or revoked) permission to transfer.
    /// @param approved whether the operator is granted transfer right or not.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event Minter(address minter, bool enabled);

    /// @notice Enable or disable the ability of `minter` to mint tokens
    /// @param minter address that will be given/removed minter right.
    /// @param enabled set whether the minter is enabled or disabled.
    function setMinter(address minter, bool enabled) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        _setMinter(minter, enabled);
    }

    /// @notice check whether address `who` is given minter rights.
    /// @param who The address to query.
    /// @return whether the address has minter rights.
    function isMinter(address who) public view returns (bool) {
        return _minters[who];
    }

    /// @dev mint more tokens of a specific subToken .
    /// @param to address receiving the tokens.
    /// @param id subToken id (also the index at which it was added).
    /// @param amount of token minted.
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external {
        require(_minters[msg.sender], "NOT_AUTHORIZED_MINTER");
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        mapping(uint256 => uint256) storage toPack = _packedTokenBalance[to];
        toPack[bin] = toPack[bin].updateTokenBalance(index, amount, ObjectLib32.Operations.ADD);
        _packedSupplies[bin] = _packedSupplies[bin].updateTokenBalance(index, amount, ObjectLib32.Operations.ADD);
        _erc20s[id].emitTransferEvent(address(0), to, amount);
    }

    /// @dev mint more tokens of a several subToken .
    /// @param to address receiving the tokens.
    /// @param ids subToken ids (also the index at which it was added).
    /// @param amounts for each token minted.
    function batchMint(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        require(_minters[msg.sender], "NOT_AUTHORIZED_MINTER");
        require(ids.length == amounts.length, "INVALID_INCONSISTENT_LENGTH");
        _batchMint(to, ids, amounts);
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 lastBin = MAX_UINT256;
        uint256 bal = 0;
        uint256 supply = 0;
        mapping(uint256 => uint256) storage toPack = _packedTokenBalance[to];
        for (uint256 i = 0; i < ids.length; i++) {
            if (amounts[i] != 0) {
                (uint256 bin, uint256 index) = ids[i].getTokenBinIndex();
                if (lastBin == MAX_UINT256) {
                    lastBin = bin;
                    bal = toPack[bin].updateTokenBalance(index, amounts[i], ObjectLib32.Operations.ADD);
                    supply = _packedSupplies[bin].updateTokenBalance(index, amounts[i], ObjectLib32.Operations.ADD);
                } else {
                    if (bin != lastBin) {
                        toPack[lastBin] = bal;
                        bal = toPack[bin];
                        _packedSupplies[lastBin] = supply;
                        supply = _packedSupplies[bin];
                        lastBin = bin;
                    }
                    bal = bal.updateTokenBalance(index, amounts[i], ObjectLib32.Operations.ADD);
                    supply = supply.updateTokenBalance(index, amounts[i], ObjectLib32.Operations.ADD);
                }
                _erc20s[ids[i]].emitTransferEvent(address(0), to, amounts[i]);
            }
        }
        if (lastBin != MAX_UINT256) {
            toPack[lastBin] = bal;
            _packedSupplies[lastBin] = supply;
        }
    }

    /// @notice return the current total supply of a specific subToken.
    /// @param id subToken id.
    /// @return supply current total number of tokens.
    function supplyOf(uint256 id) external view returns (uint256 supply) {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        return _packedSupplies[bin].getValueInBin(index);
    }

    /// @notice return the balance of a particular owner for a particular subToken.
    /// @param owner whose balance it is of.
    /// @param id subToken id.
    /// @return balance of the owner
    function balanceOf(address owner, uint256 id) public view returns (uint256 balance) {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        return _packedTokenBalance[owner][bin].getValueInBin(index);
    }

    /// @notice return the balances of a list of owners / subTokens.
    /// @param owners list of addresses to which we want to know the balance.
    /// @param ids list of subTokens's addresses.
    /// @return balances list of balances for each request.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory balances) {
        require(owners.length == ids.length, "INVALID_INCONSISTENT_LENGTH");
        balances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }
    }

    /// @notice transfer a number of subToken from one address to another.
    /// @param from owner to transfer from.
    /// @param to destination address that will receive the tokens.
    /// @param id subToken id.
    /// @param value amount of tokens to transfer.
    function singleTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) external {
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        ERC20SubToken erc20 = _erc20s[id];
        require(
            from == msg.sender ||
                msg.sender == address(erc20) ||
                _metaTransactionContracts[msg.sender] ||
                _superOperators[msg.sender] ||
                _operatorsForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        mapping(uint256 => uint256) storage fromPack = _packedTokenBalance[from];
        mapping(uint256 => uint256) storage toPack = _packedTokenBalance[to];
        fromPack[bin] = fromPack[bin].updateTokenBalance(index, value, ObjectLib32.Operations.SUB);
        toPack[bin] = toPack[bin].updateTokenBalance(index, value, ObjectLib32.Operations.ADD);
        erc20.emitTransferEvent(from, to, value);
    }

    /// @notice transfer a number of different subTokens from one address to another.
    /// @param from owner to transfer from.
    /// @param to destination address that will receive the tokens.
    /// @param ids list of subToken ids to transfer.
    /// @param values list of amount for eacg subTokens to transfer.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external {
        require(ids.length == values.length, "INVALID_INCONSISTENT_LENGTH");
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(
            from == msg.sender || _superOperators[msg.sender] || _operatorsForAll[from][msg.sender] || _metaTransactionContracts[msg.sender],
            "NOT_AUTHORIZED"
        );
        _batchTransferFrom(from, to, ids, values);
    }

    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal {
        uint256 lastBin = MAX_UINT256;
        uint256 balFrom;
        uint256 balTo;
        mapping(uint256 => uint256) storage fromPack = _packedTokenBalance[from];
        mapping(uint256 => uint256) storage toPack = _packedTokenBalance[to];
        for (uint256 i = 0; i < ids.length; i++) {
            if (values[i] != 0) {
                (uint256 bin, uint256 index) = ids[i].getTokenBinIndex();
                if (lastBin == MAX_UINT256) {
                    lastBin = bin;
                    balFrom = ObjectLib32.updateTokenBalance(fromPack[bin], index, values[i], ObjectLib32.Operations.SUB);
                    balTo = ObjectLib32.updateTokenBalance(toPack[bin], index, values[i], ObjectLib32.Operations.ADD);
                } else {
                    if (bin != lastBin) {
                        fromPack[lastBin] = balFrom;
                        toPack[lastBin] = balTo;
                        balFrom = fromPack[bin];
                        balTo = toPack[bin];
                        lastBin = bin;
                    }
                    balFrom = balFrom.updateTokenBalance(index, values[i], ObjectLib32.Operations.SUB);
                    balTo = balTo.updateTokenBalance(index, values[i], ObjectLib32.Operations.ADD);
                }
                ERC20SubToken erc20 = _erc20s[ids[i]];
                erc20.emitTransferEvent(from, to, values[i]);
            }
        }
        if (lastBin != MAX_UINT256) {
            fromPack[lastBin] = balFrom;
            toPack[lastBin] = balTo;
        }
    }

    /// @notice grant or revoke the ability for an address to transfer token on behalf of another address.
    /// @param sender address granting/revoking the approval.
    /// @param operator address being granted/revoked ability to transfer.
    /// @param approved whether the operator is revoked or approved.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(msg.sender == sender || _metaTransactionContracts[msg.sender] || _superOperators[msg.sender], "NOT_AUTHORIZED");
        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice grant or revoke the ability for an address to transfer token on your behalf.
    /// @param operator address being granted/revoked ability to transfer.
    /// @param approved whether the operator is revoked or approved.
    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice return whether an oeprator has the ability to transfer on behalf of another address.
    /// @param owner address who would have granted the rights.
    /// @param operator address being given the ability to transfer.
    /// @return isOperator whether the operator has approval rigths or not.
    function isApprovedForAll(address owner, address operator) external view returns (bool isOperator) {
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    function isAuthorizedToTransfer(address owner, address sender) external view returns (bool) {
        return _metaTransactionContracts[sender] || _superOperators[sender] || _operatorsForAll[owner][sender];
    }

    function isAuthorizedToApprove(address sender) external view returns (bool) {
        return _metaTransactionContracts[sender] || _superOperators[sender];
    }

    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external {
        require(from != address(0), "INVALID_FROM_ZERO_ADDRESS");
        require(
            from == msg.sender || _metaTransactionContracts[msg.sender] || _superOperators[msg.sender] || _operatorsForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        _batchBurnFrom(from, ids, amounts);
    }

    /// @notice burn token for a specific owner and subToken.
    /// @param from fron which address the token are burned from.
    /// @param id subToken id.
    /// @param value amount of tokens to burn.
    function burnFrom(
        address from,
        uint256 id,
        uint256 value
    ) external {
        require(
            from == msg.sender || _superOperators[msg.sender] || _operatorsForAll[from][msg.sender] || _metaTransactionContracts[msg.sender],
            "NOT_AUTHORIZED"
        );
        _burn(from, id, value);
    }

    /// @notice burn token for a specific subToken.
    /// @param id subToken id.
    /// @param value amount of tokens to burn.
    function burn(uint256 id, uint256 value) external {
        _burn(msg.sender, id, value);
    }

    // ///////////////// INTERNAL //////////////////////////

    function _batchBurnFrom(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 balFrom = 0;
        uint256 supply = 0;
        uint256 lastBin = MAX_UINT256;
        mapping(uint256 => uint256) storage fromPack = _packedTokenBalance[from];
        for (uint256 i = 0; i < ids.length; i++) {
            if (amounts[i] != 0) {
                (uint256 bin, uint256 index) = ids[i].getTokenBinIndex();
                if (lastBin == MAX_UINT256) {
                    lastBin = bin;
                    balFrom = fromPack[bin].updateTokenBalance(index, amounts[i], ObjectLib32.Operations.SUB);
                    supply = _packedSupplies[bin].updateTokenBalance(index, amounts[i], ObjectLib32.Operations.SUB);
                } else {
                    if (bin != lastBin) {
                        fromPack[lastBin] = balFrom;
                        balFrom = fromPack[bin];
                        _packedSupplies[lastBin] = supply;
                        supply = _packedSupplies[bin];
                        lastBin = bin;
                    }

                    balFrom = balFrom.updateTokenBalance(index, amounts[i], ObjectLib32.Operations.SUB);
                    supply = supply.updateTokenBalance(index, amounts[i], ObjectLib32.Operations.SUB);
                }
                _erc20s[ids[i]].emitTransferEvent(from, address(0), amounts[i]);
            }
        }
        if (lastBin != MAX_UINT256) {
            fromPack[lastBin] = balFrom;
            _packedSupplies[lastBin] = supply;
        }
    }

    function _burn(
        address from,
        uint256 id,
        uint256 value
    ) internal {
        ERC20SubToken erc20 = _erc20s[id];
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        mapping(uint256 => uint256) storage fromPack = _packedTokenBalance[from];
        fromPack[bin] = ObjectLib32.updateTokenBalance(fromPack[bin], index, value, ObjectLib32.Operations.SUB);
        _packedSupplies[bin] = ObjectLib32.updateTokenBalance(_packedSupplies[bin], index, value, ObjectLib32.Operations.SUB);
        erc20.emitTransferEvent(from, address(0), value);
    }

    function _addSubToken(ERC20SubToken subToken) internal returns (uint256 id) {
        id = _erc20s.length;
        require(subToken.groupAddress() == address(this), "INVALID_GROUP");
        require(subToken.groupTokenId() == id, "INVALID_ID");
        _erc20s.push(subToken);
        emit SubToken(subToken);
    }

    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(!_superOperators[operator], "INVALID_SUPER_OPERATOR");
        _operatorsForAll[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    function _setMinter(address minter, bool enabled) internal {
        _minters[minter] = enabled;
        emit Minter(minter, enabled);
    }

    // ///////////////// UTILITIES /////////////////////////
    using AddressUtils for address;
    using ObjectLib32 for ObjectLib32.Operations;
    using ObjectLib32 for uint256;
    using SafeMath for uint256;

    // ////////////////// DATA ///////////////////////////////
    mapping(uint256 => uint256) internal _packedSupplies;
    mapping(address => mapping(uint256 => uint256)) internal _packedTokenBalance;
    mapping(address => mapping(address => bool)) internal _operatorsForAll;
    ERC20SubToken[] internal _erc20s;
    mapping(address => bool) internal _minters;

    // ////////////// CONSTRUCTOR ////////////////////////////

    struct SubTokenData {
        string name;
        string symbol;
    }

    constructor(
        address metaTransactionContract,
        address admin,
        address initialMinter
    ) internal {
        _admin = admin;
        _setMetaTransactionProcessor(metaTransactionContract, true);
        _setMinter(initialMinter, true);
    }
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "./CatalystValue.sol";


contract CatalystDataBase is CatalystValue {
    event CatalystConfiguration(uint256 indexed id, uint16 minQuantity, uint16 maxQuantity, uint256 sandMintingFee, uint256 sandUpdateFee);

    function _setMintData(uint256 id, MintData memory data) internal {
        _data[id] = data;
        _emitConfiguration(id, data.minQuantity, data.maxQuantity, data.sandMintingFee, data.sandUpdateFee);
    }

    function _setValueOverride(uint256 id, CatalystValue valueOverride) internal {
        _valueOverrides[id] = valueOverride;
    }

    function _setConfiguration(
        uint256 id,
        uint16 minQuantity,
        uint16 maxQuantity,
        uint256 sandMintingFee,
        uint256 sandUpdateFee
    ) internal {
        _data[id].minQuantity = minQuantity;
        _data[id].maxQuantity = maxQuantity;
        _data[id].sandMintingFee = uint88(sandMintingFee);
        _data[id].sandUpdateFee = uint88(sandUpdateFee);
        _emitConfiguration(id, minQuantity, maxQuantity, sandMintingFee, sandUpdateFee);
    }

    function _emitConfiguration(
        uint256 id,
        uint16 minQuantity,
        uint16 maxQuantity,
        uint256 sandMintingFee,
        uint256 sandUpdateFee
    ) internal {
        emit CatalystConfiguration(id, minQuantity, maxQuantity, sandMintingFee, sandUpdateFee);
    }

    ///@dev compute a random value between min to 25.
    //. example: 1-25, 6-25, 11-25, 16-25
    function _computeValue(
        uint256 seed,
        uint256 gemId,
        bytes32 blockHash,
        uint256 slotIndex,
        uint32 min
    ) internal pure returns (uint32) {
        return min + uint16(uint256(keccak256(abi.encodePacked(gemId, seed, blockHash, slotIndex))) % (26 - min));
    }

    function getValues(
        uint256 catalystId,
        uint256 seed,
        GemEvent[] calldata events,
        uint32 totalNumberOfGemTypes
    ) external override view returns (uint32[] memory values) {
        CatalystValue valueOverride = _valueOverrides[catalystId];
        if (address(valueOverride) != address(0)) {
            return valueOverride.getValues(catalystId, seed, events, totalNumberOfGemTypes);
        }
        values = new uint32[](totalNumberOfGemTypes);

        uint32 numGems;
        for (uint256 i = 0; i < events.length; i++) {
            numGems += uint32(events[i].gemIds.length);
        }
        require(numGems <= MAX_UINT32, "TOO_MANY_GEMS");
        uint32 minValue = (numGems - 1) * 5 + 1;

        uint256 numGemsSoFar = 0;
        for (uint256 i = 0; i < events.length; i++) {
            numGemsSoFar += events[i].gemIds.length;
            for (uint256 j = 0; j < events[i].gemIds.length; j++) {
                uint256 gemId = events[i].gemIds[j];
                uint256 slotIndex = numGemsSoFar - events[i].gemIds.length + j;
                if (values[gemId] == 0) {
                    // first gem : value = roll between ((numGemsSoFar-1)*5+1) and 25
                    values[gemId] = _computeValue(seed, gemId, events[i].blockHash, slotIndex, (uint32(numGemsSoFar) - 1) * 5 + 1);
                    // bump previous values:
                    if (values[gemId] < minValue) {
                        values[gemId] = minValue;
                    }
                } else {
                    // further gem, previous roll are overriden with 25 and new roll between 1 and 25
                    uint32 newRoll = _computeValue(seed, gemId, events[i].blockHash, slotIndex, 1);
                    values[gemId] = (((values[gemId] - 1) / 25) + 1) * 25 + newRoll;
                }
            }
        }
    }

    function getMintData(uint256 catalystId)
        external
        view
        returns (
            uint16 maxGems,
            uint16 minQuantity,
            uint16 maxQuantity,
            uint256 sandMintingFee,
            uint256 sandUpdateFee
        )
    {
        maxGems = _data[catalystId].maxGems;
        minQuantity = _data[catalystId].minQuantity;
        maxQuantity = _data[catalystId].maxQuantity;
        sandMintingFee = _data[catalystId].sandMintingFee;
        sandUpdateFee = _data[catalystId].sandUpdateFee;
    }

    struct MintData {
        uint88 sandMintingFee;
        uint88 sandUpdateFee;
        uint16 minQuantity;
        uint16 maxQuantity;
        uint16 maxGems;
    }

    uint32 internal constant MAX_UINT32 = 2**32 - 1;

    mapping(uint256 => MintData) internal _data;
    mapping(uint256 => CatalystValue) internal _valueOverrides;
}

pragma solidity 0.6.5;

import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/BaseWithStorage/SuperOperators.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";

import "./ERC20Group.sol";


contract ERC20SubToken {
    // TODO add natspec, currently blocked by solidity compiler issue
    event Transfer(address indexed from, address indexed to, uint256 value);

    // TODO add natspec, currently blocked by solidity compiler issue
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice A descriptive name for the tokens
    /// @return name of the tokens
    function name() public view returns (string memory) {
        return _name;
    }

    /// @notice An abbreviated name for the tokens
    /// @return symbol of the tokens
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @notice the tokenId in ERC20Group
    /// @return the tokenId in ERC20Group
    function groupTokenId() external view returns (uint256) {
        return _index;
    }

    /// @notice the ERC20Group address
    /// @return the address of the group
    function groupAddress() external view returns (address) {
        return address(_group);
    }

    function totalSupply() external view returns (uint256) {
        return _group.supplyOf(_index);
    }

    function balanceOf(address who) external view returns (uint256) {
        return _group.balanceOf(who, _index);
    }

    function decimals() external pure returns (uint8) {
        return uint8(0);
    }

    function transfer(address to, uint256 amount) external returns (bool success) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success) {
        if (msg.sender != from && !_group.isAuthorizedToTransfer(from, msg.sender)) {
            uint256 allowance = _mAllowed[from][msg.sender];
            if (allowance != ~uint256(0)) {
                // save gas when allowance is maximal by not reducing it (see https://github.com/ethereum/EIPs/issues/717)
                require(allowance >= amount, "NOT_AUTHOIZED_ALLOWANCE");
                _mAllowed[from][msg.sender] = allowance - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool success) {
        _approveFor(msg.sender, spender, amount);
        return true;
    }

    function approveFor(
        address from,
        address spender,
        uint256 amount
    ) external returns (bool success) {
        require(msg.sender == from || _group.isAuthorizedToApprove(msg.sender), "NOT_AUTHORIZED");
        _approveFor(from, spender, amount);
        return true;
    }

    function emitTransferEvent(
        address from,
        address to,
        uint256 amount
    ) external {
        require(msg.sender == address(_group), "NOT_AUTHORIZED_GROUP_ONLY");
        emit Transfer(from, to, amount);
    }

    // /////////////////// INTERNAL ////////////////////////

    function _approveFor(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0) && spender != address(0), "INVALID_FROM_OR_SPENDER");
        _mAllowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function allowance(address owner, address spender) external view returns (uint256 remaining) {
        return _mAllowed[owner][spender];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        _group.singleTransferFrom(from, to, _index, amount);
    }

    // ///////////////////// UTILITIES ///////////////////////
    using SafeMathWithRequire for uint256;

    // //////////////////// CONSTRUCTOR /////////////////////
    constructor(
        ERC20Group group,
        uint256 index,
        string memory tokenName,
        string memory tokenSymbol
    ) public {
        _group = group;
        _index = index;
        _name = tokenName;
        _symbol = tokenSymbol;
    }

    // ////////////////////// DATA ///////////////////////////
    ERC20Group internal immutable _group;
    uint256 internal immutable _index;
    mapping(address => mapping(address => uint256)) internal _mAllowed;
    string internal _name;
    string internal _symbol;
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface CatalystValue {
    struct GemEvent {
        uint256[] gemIds;
        bytes32 blockHash;
    }

    function getValues(
        uint256 catalystId,
        uint256 seed,
        GemEvent[] calldata events,
        uint32 totalNumberOfGemTypes
    ) external view returns (uint32[] memory values);
}

pragma solidity 0.6.5;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

pragma solidity 0.6.5;


library AddressUtils {
    function toPayable(address _address) internal pure returns (address payable _payable) {
        return address(uint160(_address));
    }

    function isContract(address addr) internal view returns (bool) {
        // for accounts without code, i.e. `keccak256('')`:
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        bytes32 codehash;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            codehash := extcodehash(addr)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

pragma solidity 0.6.5;

import "./SafeMathWithRequire.sol";


library ObjectLib32 {
    using SafeMathWithRequire for uint256;
    enum Operations {ADD, SUB, REPLACE}
    // Constants regarding bin or chunk sizes for balance packing
    uint256 constant TYPES_BITS_SIZE = 32; // Max size of each object
    uint256 constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256

    //
    // Objects and Tokens Functions
    //

    /**
     * @dev Return the bin number and index within that bin where ID is
     * @param tokenId Object type
     * @return bin Bin number
     * @return index ID's index within that bin
     */
    function getTokenBinIndex(uint256 tokenId) internal pure returns (uint256 bin, uint256 index) {
        bin = (tokenId * TYPES_BITS_SIZE) / 256;
        index = tokenId % TYPES_PER_UINT256;
        return (bin, index);
    }

    /**
     * @dev update the balance of a type provided in binBalances
     * @param binBalances Uint256 containing the balances of objects
     * @param index Index of the object in the provided bin
     * @param amount Value to update the type balance
     * @param operation Which operation to conduct :
     *     Operations.REPLACE : Replace type balance with amount
     *     Operations.ADD     : ADD amount to type balance
     *     Operations.SUB     : Substract amount from type balance
     */
    function updateTokenBalance(
        uint256 binBalances,
        uint256 index,
        uint256 amount,
        Operations operation
    ) internal pure returns (uint256 newBinBalance) {
        uint256 objectBalance = 0;
        if (operation == Operations.ADD) {
            objectBalance = getValueInBin(binBalances, index);
            newBinBalance = writeValueInBin(binBalances, index, objectBalance.add(amount));
        } else if (operation == Operations.SUB) {
            objectBalance = getValueInBin(binBalances, index);
            require(objectBalance >= amount, "can't substract more than there is");
            newBinBalance = writeValueInBin(binBalances, index, objectBalance.sub(amount));
        } else if (operation == Operations.REPLACE) {
            newBinBalance = writeValueInBin(binBalances, index, amount);
        } else {
            revert("Invalid operation"); // Bad operation
        }

        return newBinBalance;
    }

    /*
     * @dev return value in binValue at position index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index index at which to retrieve value
     * @return Value at given index in bin
     */
    function getValueInBin(uint256 binValue, uint256 index) internal pure returns (uint256) {
        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 rightShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue >> rightShift) & mask;
    }

    /**
     * @dev return the updated binValue after writing amount at index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index Index at which to retrieve value
     * @param amount Value to store at index in bin
     * @return Value at given index in bin
     */
    function writeValueInBin(
        uint256 binValue,
        uint256 index,
        uint256 amount
    ) internal pure returns (uint256) {
        require(amount < 2**TYPES_BITS_SIZE, "Amount to write in bin is too large");

        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 leftShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue & ~(mask << leftShift)) | (amount << leftShift);
    }
}

pragma solidity 0.6.5;


library BytesUtil {
    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function pointerToBytes(uint256 src, uint256 len) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, src, len);
        return ret;
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }

    function uint256ToBytes(uint256 a) internal pure returns (bytes memory b) {
        assembly {
            let m := mload(0x40)
            mstore(add(m, 32), a)
            mstore(0x40, add(m, 64))
            b := m
        }
    }

    function doFirstParamEqualsAddress(bytes memory data, address _address) internal pure returns (bool) {
        if (data.length < (36 + 32)) {
            return false;
        }
        uint256 value;
        assembly {
            value := mload(add(data, 36))
        }
        return value == uint256(_address);
    }

    function doParamEqualsUInt256(
        bytes memory data,
        uint256 i,
        uint256 value
    ) internal pure returns (bool) {
        if (data.length < (36 + (i + 1) * 32)) {
            return false;
        }
        uint256 offset = 36 + i * 32;
        uint256 valuePresent;
        assembly {
            valuePresent := mload(add(data, offset))
        }
        return valuePresent == value;
    }

    function overrideFirst32BytesWithAddress(bytes memory data, address _address) internal pure returns (bytes memory) {
        uint256 dest;
        assembly {
            dest := add(data, 48)
        } // 48 = 32 (offset) + 4 (func sig) + 12 (address is only 20 bytes)

        bytes memory addressBytes = addressToBytes(_address);
        uint256 src;
        assembly {
            src := add(addressBytes, 32)
        }

        memcpy(dest, src, 20);
        return data;
    }

    function overrideFirstTwo32BytesWithAddressAndInt(
        bytes memory data,
        address _address,
        uint256 _value
    ) internal pure returns (bytes memory) {
        uint256 dest;
        uint256 src;

        assembly {
            dest := add(data, 48)
        } // 48 = 32 (offset) + 4 (func sig) + 12 (address is only 20 bytes)
        bytes memory bbytes = addressToBytes(_address);
        assembly {
            src := add(bbytes, 32)
        }
        memcpy(dest, src, 20);

        assembly {
            dest := add(data, 68)
        } // 48 = 32 (offset) + 4 (func sig) + 32 (next slot)
        bbytes = uint256ToBytes(_value);
        assembly {
            src := add(bbytes, 32)
        }
        memcpy(dest, src, 32);

        return data;
    }
}

pragma solidity 0.6.5;

import "./Admin.sol";


contract SuperOperators is Admin {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address superOperator, bool enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external {
        require(msg.sender == _admin, "only admin is allowed to add super operators");
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}

/* solhint-disable not-rely-on-time, func-order */
pragma solidity 0.6.5;

import "../common/Libraries/SigUtil.sol";
import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/Interfaces/ERC20.sol";
import "../common/BaseWithStorage/Admin.sol";


/// @dev This contract verifies if a referral is valid
contract ReferralValidator is Admin {
    address private _signingWallet;
    uint256 private _maxCommissionRate;

    mapping(address => uint256) private _previousSigningWallets;
    uint256 private _previousSigningDelay = 60 * 60 * 24 * 10;

    event ReferralUsed(
        address indexed referrer,
        address indexed referee,
        address indexed token,
        uint256 amount,
        uint256 commission,
        uint256 commissionRate
    );

    constructor(address initialSigningWallet, uint256 initialMaxCommissionRate) public {
        _signingWallet = initialSigningWallet;
        _maxCommissionRate = initialMaxCommissionRate;
    }

    /**
     * @dev Update the signing wallet
     * @param newSigningWallet The new address of the signing wallet
     */
    function updateSigningWallet(address newSigningWallet) external {
        require(_admin == msg.sender, "Sender not admin");
        _previousSigningWallets[_signingWallet] = now + _previousSigningDelay;
        _signingWallet = newSigningWallet;
    }

    /**
     * @dev signing wallet authorized for referral
     * @return the address of the signing wallet
     */
    function getSigningWallet() external view returns (address) {
        return _signingWallet;
    }

    /**
     * @notice the max commision rate
     * @return the maximum commision rate that a referral can give
     */
    function getMaxCommisionRate() external view returns (uint256) {
        return _maxCommissionRate;
    }

    /**
     * @dev Update the maximum commission rate
     * @param newMaxCommissionRate The new maximum commission rate
     */
    function updateMaxCommissionRate(uint256 newMaxCommissionRate) external {
        require(_admin == msg.sender, "Sender not admin");
        _maxCommissionRate = newMaxCommissionRate;
    }

    function handleReferralWithETH(
        uint256 amount,
        bytes memory referral,
        address payable destination
    ) internal {
        uint256 amountForDestination = amount;

        if (referral.length > 0) {
            (bytes memory signature, address referrer, address referee, uint256 expiryTime, uint256 commissionRate) = decodeReferral(referral);

            uint256 commission = 0;

            if (isReferralValid(signature, referrer, referee, expiryTime, commissionRate)) {
                commission = SafeMathWithRequire.div(SafeMathWithRequire.mul(amount, commissionRate), 10000);

                emit ReferralUsed(referrer, referee, address(0), amount, commission, commissionRate);
                amountForDestination = SafeMathWithRequire.sub(amountForDestination, commission);
            }

            if (commission > 0) {
                payable(referrer).transfer(commission);
            }
        }

        destination.transfer(amountForDestination);
    }

    function handleReferralWithERC20(
        address buyer,
        uint256 amount,
        bytes memory referral,
        address payable destination,
        address tokenAddress
    ) internal {
        ERC20 token = ERC20(tokenAddress);
        uint256 amountForDestination = amount;

        if (referral.length > 0) {
            (bytes memory signature, address referrer, address referee, uint256 expiryTime, uint256 commissionRate) = decodeReferral(referral);

            uint256 commission = 0;

            if (isReferralValid(signature, referrer, referee, expiryTime, commissionRate)) {
                commission = SafeMathWithRequire.div(SafeMathWithRequire.mul(amount, commissionRate), 10000);

                emit ReferralUsed(referrer, referee, tokenAddress, amount, commission, commissionRate);
                amountForDestination = SafeMathWithRequire.sub(amountForDestination, commission);
            }

            if (commission > 0) {
                require(token.transferFrom(buyer, referrer, commission), "commision transfer failed");
            }
        }

        require(token.transferFrom(buyer, destination, amountForDestination), "payment transfer failed");
    }

    /**
     * @notice Check if a referral is valid
     * @param signature The signature to check (signed referral)
     * @param referrer The address of the referrer
     * @param referee The address of the referee
     * @param expiryTime The expiry time of the referral
     * @param commissionRate The commissionRate of the referral
     * @return True if the referral is valid
     */
    function isReferralValid(
        bytes memory signature,
        address referrer,
        address referee,
        uint256 expiryTime,
        uint256 commissionRate
    ) public view returns (bool) {
        if (commissionRate > _maxCommissionRate || referrer == referee || now > expiryTime) {
            return false;
        }

        bytes32 hashedData = keccak256(abi.encodePacked(referrer, referee, expiryTime, commissionRate));

        address signer = SigUtil.recover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedData)), signature);

        if (_previousSigningWallets[signer] >= now) {
            return true;
        }

        return _signingWallet == signer;
    }

    function decodeReferral(bytes memory referral)
        public
        pure
        returns (
            bytes memory,
            address,
            address,
            uint256,
            uint256
        )
    {
        (bytes memory signature, address referrer, address referee, uint256 expiryTime, uint256 commissionRate) = abi.decode(
            referral,
            (bytes, address, address, uint256, uint256)
        );

        return (signature, referrer, referee, expiryTime, commissionRate);
    }
}

/* solhint-disable not-rely-on-time, func-order */
pragma solidity 0.6.5;

import "../common/Libraries/SafeMathWithRequire.sol";
import "./LandToken.sol";
import "../common/Interfaces/ERC1155.sol";
import "../common/Interfaces/ERC20.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";
import "../ReferralValidator/ReferralValidator.sol";


/// @title Estate Sale contract with referral
/// @notice This contract manages the sale of our lands as Estates
contract EstateSaleWithFee is MetaTransactionReceiver, ReferralValidator {
    using SafeMathWithRequire for uint256;

    event LandQuadPurchased(
        address indexed buyer,
        address indexed to,
        uint256 indexed topCornerId,
        uint256 size,
        uint256 price,
        address token,
        uint256 amountPaid
    );

    /// @notice set the wallet receiving the proceeds
    /// @param newWallet address of the new receiving wallet
    function setReceivingWallet(address payable newWallet) external {
        require(newWallet != address(0), "ZERO_ADDRESS");
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _wallet = newWallet;
    }

    function rebalanceSand(uint256 newMultiplier) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _multiplier = newMultiplier;
    }

    function getSandMultiplier() external view returns (uint256) {
        return _multiplier;
    }

    /// @notice buy Land with SAND using the merkle proof associated with it
    /// @param buyer address that perform the payment
    /// @param to address that will own the purchased Land
    /// @param reserved the reserved address (if any)
    /// @param x x coordinate of the Land
    /// @param y y coordinate of the Land
    /// @param size size of the pack of Land to purchase
    /// @param priceInSand price in SAND to purchase that Land
    /// @param proof merkleProof for that particular Land
    function buyLandWithSand(
        address buyer,
        address to,
        address reserved,
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 priceInSand,
        uint256 adjustedPriceInSand,
        bytes32 salt,
        uint256[] calldata assetIds,
        bytes32[] calldata proof,
        bytes calldata referral
    ) external {
        _checkPrices(priceInSand, adjustedPriceInSand);
        _checkValidity(buyer, reserved, x, y, size, priceInSand, salt, assetIds, proof);
        _handleFeeAndReferral(buyer, adjustedPriceInSand, referral);
        _mint(buyer, to, x, y, size, adjustedPriceInSand, address(_sand), adjustedPriceInSand);
        _sendAssets(to, assetIds);
    }

    /// @notice Gets the expiry time for the current sale
    /// @return The expiry time, as a unix epoch
    function getExpiryTime() external view returns (uint256) {
        return _expiryTime;
    }

    /// @notice Gets the Merkle root associated with the current sale
    /// @return The Merkle root, as a bytes32 hash
    function getMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    /// @notice enable Admin to withdraw remaining assets from EstateSaleWithFee contract
    /// @param to intended recipient of the asset tokens
    /// @param assetIds the assetIds to be transferred
    /// @param values the quantities of the assetIds to be transferred
    function withdrawAssets(
        address to,
        uint256[] calldata assetIds,
        uint256[] calldata values
    ) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        // require(block.timestamp > _expiryTime, "SALE_NOT_OVER"); // removed to recover in case of misconfigured sales
        _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");
    }

    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return 0xbc197c81;
    }

    function _sendAssets(address to, uint256[] memory assetIds) internal {
        uint256[] memory values = new uint256[](assetIds.length);
        for (uint256 i = 0; i < assetIds.length; i++) {
            values[i] = 1;
        }
        _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");
    }

    function _checkPrices(uint256 priceInSand, uint256 adjustedPriceInSand) internal view {
        require(adjustedPriceInSand == priceInSand.mul(_multiplier).div(MULTIPLIER_DECIMALS), "INVALID_PRICE");
    }

    function _checkValidity(
        address buyer,
        address reserved,
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 price,
        bytes32 salt,
        uint256[] memory assetIds,
        bytes32[] memory proof
    ) internal view {
        /* solium-disable-next-line security/no-block-members */
        require(block.timestamp < _expiryTime, "SALE_IS_OVER");
        require(buyer == msg.sender || _metaTransactionContracts[msg.sender], "NOT_AUTHORIZED");
        require(reserved == address(0) || reserved == buyer, "RESERVED_LAND");
        bytes32 leaf = _generateLandHash(x, y, size, price, reserved, salt, assetIds);

        require(_verify(proof, leaf), "INVALID_LAND");
    }

    function _mint(
        address buyer,
        address to,
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 price,
        address token,
        uint256 tokenAmount
    ) internal {
        if (size == 1 || _estate == address(0)) {
            _land.mintQuad(to, size, x, y, "");
        } else {
            _land.mintQuad(_estate, size, x, y, abi.encode(to));
        }
        emit LandQuadPurchased(buyer, to, x + (y * GRID_SIZE), size, price, token, tokenAmount);
    }

    function _generateLandHash(
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 price,
        address reserved,
        bytes32 salt,
        uint256[] memory assetIds
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(x, y, size, price, reserved, salt, assetIds));
    }

    function _verify(bytes32[] memory proof, bytes32 leaf) internal view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == _merkleRoot;
    }

    function _handleFeeAndReferral(
        address buyer,
        uint256 priceInSand,
        bytes memory referral
    ) internal {
        // send 5% fee to a specially configured instance of FeeDistributor.sol
        uint256 remainingAmountInSand = _handleSandFee(buyer, priceInSand);

        // calculate referral based on 95% of original priceInSand
        handleReferralWithERC20(buyer, remainingAmountInSand, referral, _wallet, address(_sand));
    }

    function _handleSandFee(address buyer, uint256 priceInSand) internal returns (uint256) {
        uint256 feeAmountInSand = priceInSand.mul(FEE).div(100);
        require(_sand.transferFrom(buyer, address(_feeDistributor), feeAmountInSand), "FEE_TRANSFER_FAILED");
        return priceInSand.sub(feeAmountInSand);
    }

    uint256 internal constant GRID_SIZE = 408; // 408 is the size of the Land

    ERC1155 internal immutable _asset;
    LandToken internal immutable _land;
    ERC20 internal immutable _sand;
    address internal immutable _estate;
    address internal immutable _feeDistributor;

    address payable internal _wallet;
    uint256 internal immutable _expiryTime;
    bytes32 internal immutable _merkleRoot;

    uint256 private constant FEE = 5; // percentage of land sale price to be diverted to a specially configured instance of FeeDistributor, shown as an integer

    uint256 private _multiplier = 1000; // multiplier used for rebalancing SAND values, 3 decimal places
    uint256 private constant MULTIPLIER_DECIMALS = 1000;

    constructor(
        address landAddress,
        address sandContractAddress,
        address initialMetaTx,
        address admin,
        address payable initialWalletAddress,
        bytes32 merkleRoot,
        uint256 expiryTime,
        address initialSigningWallet,
        uint256 initialMaxCommissionRate,
        address estate,
        address asset,
        address feeDistributor
    ) public ReferralValidator(initialSigningWallet, initialMaxCommissionRate) {
        _land = LandToken(landAddress);
        _sand = ERC20(sandContractAddress);
        _setMetaTransactionProcessor(initialMetaTx, true);
        _wallet = initialWalletAddress;
        _merkleRoot = merkleRoot;
        _expiryTime = expiryTime;
        _admin = admin;
        _estate = estate;
        _asset = ERC1155(asset);
        _feeDistributor = feeDistributor;
    }
}

pragma solidity 0.6.5;


interface LandToken {
    function mintQuad(
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;
}

pragma solidity 0.6.5;


/**
    @title ERC-1155 Multi Token Standard
    @dev See https://eips.ethereum.org/EIPS/eip-1155
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface ERC1155 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /**
        @notice Transfers `value` amount of an `id` from  `from` to `to`  (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if balance of holder for token `id` is lower than the `value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param id      ID of the token type
        @param value   Transfer amount
        @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    /**
        @notice Transfers `values` amount(s) of `ids` from the `from` address to the `to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `from` account (see "Approval" section of the standard).
        MUST revert if `to` is the zero address.
        MUST revert if length of `ids` is not the same as length of `values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param from    Source address
        @param to      Target address
        @param ids     IDs of each token type (order and length must match _values array)
        @param values  Transfer amounts per token type (order and length must match _ids array)
        @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    /**
        @notice Get the balance of an account's tokens.
        @param owner  The address of the token holder
        @param id     ID of the token
        @return        The _owner's balance of the token type requested
     */
    function balanceOf(address owner, uint256 id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param owners The addresses of the token holders
        @param ids    ID of the tokens
        @return        The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param operator  Address to add to the set of authorized operators
        @param approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address operator, bool approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param owner     The owner of the tokens
        @param operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

pragma solidity 0.6.5;

import "../common/Libraries/AddressUtils.sol";
import "../common/Interfaces/ERC721.sol";
import "../common/Interfaces/ERC721TokenReceiver.sol";
import "../common/Interfaces/ERC721MandatoryTokenReceiver.sol";
import "../common/BaseWithStorage/SuperOperators.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";


contract MockERC721 is ERC721, SuperOperators, MetaTransactionReceiver {
    using AddressUtils for address;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant _ERC721_BATCH_RECEIVED = 0x4b808c46;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;
    bytes4 internal constant ERC721_MANDATORY_RECEIVER = 0x5e8bf644;

    mapping(address => uint256) public _numNFTPerAddress;
    mapping(uint256 => uint256) public _owners;
    mapping(address => mapping(address => bool)) public _operatorsForAll;
    mapping(uint256 => address) public _operators;

    constructor(address metaTransactionContract, address admin) internal {
        _admin = admin;
        _setMetaTransactionProcessor(metaTransactionContract, true);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        _numNFTPerAddress[from]--;
        _numNFTPerAddress[to]++;
        _owners[id] = uint256(to);
        emit Transfer(from, to, id);
    }

    function balanceOf(address owner) public override view returns (uint256) {
        require(owner != address(0), "owner is zero address");
        return _numNFTPerAddress[owner];
    }

    function _ownerOf(uint256 id) internal view returns (address) {
        return address(_owners[id]);
    }

    function _ownerAndOperatorEnabledOf(uint256 id) internal view returns (address owner, bool operatorEnabled) {
        uint256 data = _owners[id];
        owner = address(data);
        operatorEnabled = (data / 2**255) == 1;
    }

    function ownerOf(uint256 id) public override view returns (address owner) {
        // TODO: does not return owner
        owner = _ownerOf(id);
        require(owner != address(0), "token does not exist");
    }

    function _approveFor(
        address owner,
        address operator,
        uint256 id
    ) internal {
        if (operator == address(0)) {
            _owners[id] = uint256(owner); // no need to resset the operator, it will be overriden next time
        } else {
            _owners[id] = uint256(owner) + 2**255;
            _operators[id] = operator;
        }
        emit Approval(owner, operator, id);
    }

    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) public {
        address owner = _ownerOf(id);
        require(sender != address(0), "sender is zero address");
        require(
            msg.sender == sender || _metaTransactionContracts[msg.sender] || _superOperators[msg.sender] || _operatorsForAll[sender][msg.sender],
            "not authorized to approve"
        );
        require(owner == sender, "owner != sender");
        _approveFor(owner, operator, id);
    }

    function approve(address operator, uint256 id) public override {
        address owner = _ownerOf(id);
        require(owner != address(0), "token does not exist");
        require(owner == msg.sender || _superOperators[msg.sender] || _operatorsForAll[owner][msg.sender], "not authorized to approve");
        _approveFor(owner, operator, id);
    }

    function getApproved(uint256 id) public override view returns (address) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "token does not exist");
        if (operatorEnabled) {
            return _operators[id];
        } else {
            return address(0);
        }
    }

    function _checkTransfer(
        address from,
        address to,
        uint256 id
    ) internal view returns (bool isMetaTx) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "token does not exist");
        require(owner == from, "not owner in _checkTransfer");
        require(to != address(0), "can't send to zero address");
        isMetaTx = msg.sender != from && _metaTransactionContracts[msg.sender];
        if (msg.sender != from && !isMetaTx) {
            require(
                _superOperators[msg.sender] || _operatorsForAll[from][msg.sender] || (operatorEnabled && _operators[id] == msg.sender),
                "not approved to transfer"
            );
        }
    }

    function _checkInterfaceWith10000Gas(address _contract, bytes4 interfaceId) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory call_data = abi.encodeWithSelector(ERC165ID, interfaceId);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let call_ptr := add(0x20, call_data)
            let call_size := mload(call_data)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        bool metaTx = _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            require(_checkOnERC721Received(metaTx ? from : msg.sender, from, to, id, ""), "erc721 transfer rejected by to");
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override {
        bool metaTx = _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract()) {
            require(_checkOnERC721Received(metaTx ? from : msg.sender, from, to, id, data), "ERC721: transfer rejected by to");
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        safeTransferFrom(from, to, id, "");
    }

    function batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data
    ) public {
        _batchTransferFrom(from, to, ids, data, false);
    }

    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data,
        bool safe
    ) internal {
        bool metaTx = msg.sender != from && _metaTransactionContracts[msg.sender];
        bool authorized = msg.sender == from || metaTx || _superOperators[msg.sender] || _operatorsForAll[from][msg.sender];

        require(from != address(0), "from is zero address");
        require(to != address(0), "can't send to zero address");

        uint256 numTokens = ids.length;
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 id = ids[i];
            (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
            require(owner == from, "not owner in batchTransferFrom");
            require(authorized || (operatorEnabled && _operators[id] == msg.sender), "not authorized");
            _owners[id] = uint256(to);
            emit Transfer(from, to, id);
        }
        if (from != to) {
            _numNFTPerAddress[from] -= numTokens;
            _numNFTPerAddress[to] += numTokens;
        }

        if (to.isContract() && (safe || _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER))) {
            require(_checkOnERC721BatchReceived(metaTx ? from : msg.sender, from, to, ids, data), "erc721 batch transfer rejected by to");
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data
    ) public {
        _batchTransferFrom(from, to, ids, data, true);
    }

    function supportsInterface(bytes4 id) public override view returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd;
    }

    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) public {
        require(sender != address(0), "Invalid sender address");
        require(msg.sender == sender || _metaTransactionContracts[msg.sender] || _superOperators[msg.sender], "not authorized to approve for all");

        _setApprovalForAll(sender, operator, approved);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(!_superOperators[operator], "super operator can't have their approvalForAll changed");
        _operatorsForAll[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public override view returns (bool isOperator) {
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    function _burn(
        address from,
        address owner,
        uint256 id
    ) public {
        require(from == owner, "not owner");
        _owners[id] = 2**160; // cannot mint it again
        _numNFTPerAddress[from]--;
        emit Transfer(from, address(0), id);
    }

    function burn(uint256 id) public {
        _burn(msg.sender, _ownerOf(id), id);
    }

    function burnFrom(address from, uint256 id) public {
        require(from != address(0), "Invalid sender address");
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(
            msg.sender == from ||
                _metaTransactionContracts[msg.sender] ||
                (operatorEnabled && _operators[id] == msg.sender) ||
                _superOperators[msg.sender] ||
                _operatorsForAll[from][msg.sender],
            "not authorized to burn"
        );
        _burn(from, owner, id);
    }

    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = ERC721TokenReceiver(to).onERC721Received(operator, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _checkOnERC721BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = ERC721MandatoryTokenReceiver(to).onERC721BatchReceived(operator, from, ids, _data);
        return (retval == _ERC721_BATCH_RECEIVED);
    }

    function mint(address to, uint256 tokenId) public {
        require(to != address(0), "to is zero address");
        require(_owners[tokenId] == 0, "Already minted");
        emit Transfer(address(0), to, tokenId);
        _owners[tokenId] = uint256(to);
        _numNFTPerAddress[to] += 1;
    }
}


contract MockLand is MockERC721 {
    constructor(address metaTransactionContract, address admin) public MockERC721(metaTransactionContract, admin) {}

    function name() external pure returns (string memory) {
        return "Mock LANDs";
    }

    function symbol() external pure returns (string memory) {
        return "MOCKLAND";
    }
}

/* This Source Code Form is subject to the terms of the Mozilla external
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
// solhint-disable-next-line compiler-fixed
pragma solidity 0.6.5;


interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity 0.6.5;


/// @dev Note: The ERC-165 identifier for this interface is 0x5e8bf644.
interface ERC721MandatoryTokenReceiver {
    function onERC721BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x4b808c46

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x150b7a02

    // needs to implements EIP-165
    // function supportsInterface(bytes4 interfaceId)
    //     external
    //     view
    //     returns (bool);
}

/* solhint-disable func-order, code-complexity */
pragma solidity 0.6.5;

import "../common/Libraries/AddressUtils.sol";
import "../common/Interfaces/ERC721TokenReceiver.sol";
import "../common/Interfaces/ERC721Events.sol";
import "../common/BaseWithStorage/SuperOperators.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";
import "../common/Interfaces/ERC721MandatoryTokenReceiver.sol";


contract ERC721BaseToken is ERC721Events, SuperOperators, MetaTransactionReceiver {
    using AddressUtils for address;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant _ERC721_BATCH_RECEIVED = 0x4b808c46;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;
    bytes4 internal constant ERC721_MANDATORY_RECEIVER = 0x5e8bf644;

    mapping(address => uint256) internal _numNFTPerAddress;
    mapping(uint256 => uint256) internal _owners;
    mapping(address => mapping(address => bool)) internal _operatorsForAll;
    mapping(uint256 => address) internal _operators;

    constructor(address metaTransactionContract, address admin) internal {
        _admin = admin;
        _setMetaTransactionProcessor(metaTransactionContract, true);
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        _numNFTPerAddress[from]--;
        _numNFTPerAddress[to]++;
        _owners[id] = uint256(to);
        emit Transfer(from, to, id);
    }

    /**
     * @notice Return the number of Land owned by an address
     * @param owner The address to look for
     * @return The number of Land token owned by the address
     */
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "owner is zero address");
        return _numNFTPerAddress[owner];
    }

    function _ownerOf(uint256 id) internal virtual view returns (address) {
        uint256 data = _owners[id];
        if ((data & (2**160)) == 2**160) {
            return address(0);
        }
        return address(data);
    }

    function _ownerAndOperatorEnabledOf(uint256 id) internal view returns (address owner, bool operatorEnabled) {
        uint256 data = _owners[id];
        if ((data & (2**160)) == 2**160) {
            owner = address(0);
        } else {
            owner = address(data);
        }
        operatorEnabled = (data / 2**255) == 1;
    }

    /**
     * @notice Return the owner of a Land
     * @param id The id of the Land
     * @return owner The address of the owner
     */
    function ownerOf(uint256 id) external view returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "token does not exist");
    }

    function _approveFor(
        address owner,
        address operator,
        uint256 id
    ) internal {
        if (operator == address(0)) {
            _owners[id] = _owners[id] & (2**255 - 1); // no need to resset the operator, it will be overriden next time
        } else {
            _owners[id] = _owners[id] | (2**255);
            _operators[id] = operator;
        }
        emit Approval(owner, operator, id);
    }

    /**
     * @notice Approve an operator to spend tokens on the sender behalf
     * @param sender The address giving the approval
     * @param operator The address receiving the approval
     * @param id The id of the token
     */
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external {
        address owner = _ownerOf(id);
        require(sender != address(0), "sender is zero address");
        require(
            msg.sender == sender || _metaTransactionContracts[msg.sender] || _superOperators[msg.sender] || _operatorsForAll[sender][msg.sender],
            "not authorized to approve"
        );
        require(owner == sender, "owner != sender");
        _approveFor(owner, operator, id);
    }

    /**
     * @notice Approve an operator to spend tokens on the sender behalf
     * @param operator The address receiving the approval
     * @param id The id of the token
     */
    function approve(address operator, uint256 id) external {
        address owner = _ownerOf(id);
        require(owner != address(0), "token does not exist");
        require(owner == msg.sender || _superOperators[msg.sender] || _operatorsForAll[owner][msg.sender], "not authorized to approve");
        _approveFor(owner, operator, id);
    }

    /**
     * @notice Get the approved operator for a specific token
     * @param id The id of the token
     * @return The address of the operator
     */
    function getApproved(uint256 id) external view returns (address) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "token does not exist");
        if (operatorEnabled) {
            return _operators[id];
        } else {
            return address(0);
        }
    }

    function _checkTransfer(
        address from,
        address to,
        uint256 id
    ) internal view returns (bool isMetaTx) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "token does not exist");
        require(owner == from, "not owner in _checkTransfer");
        require(to != address(0), "can't send to zero address");
        isMetaTx = msg.sender != from && _metaTransactionContracts[msg.sender];
        if (msg.sender != from && !isMetaTx) {
            require(
                _superOperators[msg.sender] || _operatorsForAll[from][msg.sender] || (operatorEnabled && _operators[id] == msg.sender),
                "not approved to transfer"
            );
        }
    }

    function _checkInterfaceWith10000Gas(address _contract, bytes4 interfaceId) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory call_data = abi.encodeWithSelector(ERC165ID, interfaceId);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let call_ptr := add(0x20, call_data)
            let call_size := mload(call_data)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }

    /**
     * @notice Transfer a token between 2 addresses
     * @param from The sender of the token
     * @param to The recipient of the token
     * @param id The id of the token
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external {
        bool metaTx = _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            require(_checkOnERC721Received(metaTx ? from : msg.sender, from, to, id, ""), "erc721 transfer rejected by to");
        }
    }

    /**
     * @notice Transfer a token between 2 addresses letting the receiver knows of the transfer
     * @param from The sender of the token
     * @param to The recipient of the token
     * @param id The id of the token
     * @param data Additional data
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public {
        bool metaTx = _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract()) {
            require(_checkOnERC721Received(metaTx ? from : msg.sender, from, to, id, data), "ERC721: transfer rejected by to");
        }
    }

    /**
     * @notice Transfer a token between 2 addresses letting the receiver knows of the transfer
     * @param from The send of the token
     * @param to The recipient of the token
     * @param id The id of the token
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external {
        safeTransferFrom(from, to, id, "");
    }

    /**
     * @notice Transfer many tokens between 2 addresses
     * @param from The sender of the token
     * @param to The recipient of the token
     * @param ids The ids of the tokens
     * @param data additional data
     */
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external {
        _batchTransferFrom(from, to, ids, data, false);
    }

    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data,
        bool safe
    ) internal {
        bool metaTx = msg.sender != from && _metaTransactionContracts[msg.sender];
        bool authorized = msg.sender == from || metaTx || _superOperators[msg.sender] || _operatorsForAll[from][msg.sender];

        require(from != address(0), "from is zero address");
        require(to != address(0), "can't send to zero address");

        uint256 numTokens = ids.length;
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 id = ids[i];
            (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
            require(owner == from, "not owner in batchTransferFrom");
            require(authorized || (operatorEnabled && _operators[id] == msg.sender), "not authorized");
            _owners[id] = uint256(to);
            emit Transfer(from, to, id);
        }
        if (from != to) {
            _numNFTPerAddress[from] -= numTokens;
            _numNFTPerAddress[to] += numTokens;
        }

        if (to.isContract() && (safe || _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER))) {
            require(_checkOnERC721BatchReceived(metaTx ? from : msg.sender, from, to, ids, data), "erc721 batch transfer rejected by to");
        }
    }

    /**
     * @notice Transfer many tokens between 2 addresses ensuring the receiving contract has a receiver method
     * @param from The sender of the token
     * @param to The recipient of the token
     * @param ids The ids of the tokens
     * @param data additional data
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external {
        _batchTransferFrom(from, to, ids, data, true);
    }

    /**
     * @notice Check if the contract supports an interface
     * 0x01ffc9a7 is ERC-165
     * 0x80ac58cd is ERC-721
     * @param id The id of the interface
     * @return True if the interface is supported
     */
    function supportsInterface(bytes4 id) public virtual pure returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd;
    }

    /**
     * @notice Set the approval for an operator to manage all the tokens of the sender
     * @param sender The address giving the approval
     * @param operator The address receiving the approval
     * @param approved The determination of the approval
     */
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(sender != address(0), "Invalid sender address");
        require(msg.sender == sender || _metaTransactionContracts[msg.sender] || _superOperators[msg.sender], "not authorized to approve for all");

        _setApprovalForAll(sender, operator, approved);
    }

    /**
     * @notice Set the approval for an operator to manage all the tokens of the sender
     * @param operator The address receiving the approval
     * @param approved The determination of the approval
     */
    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(!_superOperators[operator], "super operator can't have their approvalForAll changed");
        _operatorsForAll[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    /**
     * @notice Check if the sender approved the operator
     * @param owner The address of the owner
     * @param operator The address of the operator
     * @return isOperator The status of the approval
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool isOperator) {
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    function _burn(
        address from,
        address owner,
        uint256 id
    ) internal {
        require(from == owner, "not owner");
        _owners[id] = (_owners[id] & (2**255 - 1)) | (2**160); // record as non owner but keep track of last owner
        _numNFTPerAddress[from]--;
        emit Transfer(from, address(0), id);
    }

    /// @notice Burns token `id`.
    /// @param id token which will be burnt.
    function burn(uint256 id) external virtual {
        _burn(msg.sender, _ownerOf(id), id);
    }

    /// @notice Burn token`id` from `from`.
    /// @param from address whose token is to be burnt.
    /// @param id token which will be burnt.
    function burnFrom(address from, uint256 id) external virtual {
        require(from != address(0), "Invalid sender address");
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(
            msg.sender == from ||
                _metaTransactionContracts[msg.sender] ||
                (operatorEnabled && _operators[id] == msg.sender) ||
                _superOperators[msg.sender] ||
                _operatorsForAll[from][msg.sender],
            "not authorized to burn"
        );
        _burn(from, owner, id);
    }

    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = ERC721TokenReceiver(to).onERC721Received(operator, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    function _checkOnERC721BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = ERC721MandatoryTokenReceiver(to).onERC721BatchReceived(operator, from, ids, _data);
        return (retval == _ERC721_BATCH_RECEIVED);
    }
}

pragma solidity 0.6.5;

import "@openzeppelin/contracts-0.6/math/Math.sol";
import "@openzeppelin/contracts-0.6/access/Ownable.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";
import "./IRewardDistributionRecipient.sol";
import "../common/Interfaces/ERC721.sol";
import "../common/Libraries/SafeMathWithRequire.sol";

contract LPTokenWrapper {
    using SafeMathWithRequire for uint256;
    using SafeERC20 for IERC20;

    uint256 internal constant DECIMALS_18 = 1000000000000000000;

    IERC20 internal immutable _stakeToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(IERC20 stakeToken) public {
        _stakeToken = stakeToken;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _stakeToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _stakeToken.safeTransfer(msg.sender, amount);
    }
}

///@notice Reward Pool based on unipool contract : https://github.com/Synthetixio/Unipool/blob/master/contracts/Unipool.sol
//with the addition of NFT multiplier reward
contract LandWeightedSANDRewardPool is LPTokenWrapper, IRewardDistributionRecipient {
    using SafeMathWithRequire for uint256;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    uint256 public immutable duration;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 internal constant DECIMALS_9 = 1000000000;
    uint256 internal constant MIDPOINT_9 = 500000000;
    uint256 internal constant NFT_FACTOR_6 = 10000;
    uint256 internal constant NFT_CONSTANT_3 = 9000;
    uint256 internal constant ROOT3_FACTOR = 697;

    IERC20 internal immutable _rewardToken;
    ERC721 internal immutable _multiplierNFToken;

    uint256 internal _totalContributions;
    mapping(address => uint256) internal _contributions;

    constructor(
        IERC20 stakeToken,
        IERC20 rewardToken,
        ERC721 multiplierNFToken,
        uint256 rewardDuration
    ) public LPTokenWrapper(stakeToken) {
        _rewardToken = rewardToken;
        _multiplierNFToken = multiplierNFToken;
        duration = rewardDuration;
    }

    function totalContributions() public view returns (uint256) {
        return _totalContributions;
    }

    function contributionOf(address account) public view returns (uint256) {
        return _contributions[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();

        if (block.timestamp >= periodFinish || _totalContributions != 0) {
            // ensure reward past the first staker do not get lost
            lastUpdateTime = lastTimeRewardApplicable();
        }
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalContributions() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e24).div(totalContributions())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            contributionOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e24).add(
                rewards[account]
            );
    }

    function computeContribution(uint256 amountStaked, uint256 numLands) public pure returns (uint256) {
        if (numLands == 0) {
            return amountStaked;
        }
        uint256 nftContrib = NFT_FACTOR_6.mul(NFT_CONSTANT_3.add(numLands.sub(1).mul(ROOT3_FACTOR).add(1).cbrt3()));
        if (nftContrib > MIDPOINT_9) {
            nftContrib = MIDPOINT_9.add(nftContrib.sub(MIDPOINT_9).div(10));
        }
        return amountStaked.add(amountStaked.mul(nftContrib).div(DECIMALS_9));
    }

    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        uint256 contribution = computeContribution(amount, _multiplierNFToken.balanceOf(msg.sender));
        _totalContributions = _totalContributions.add(contribution);
        _contributions[msg.sender] = _contributions[msg.sender].add(contribution);
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        uint256 balance = balanceOf(msg.sender);
        uint256 ratio = amount.mul(DECIMALS_18).div(balance);
        uint256 currentContribution = contributionOf(msg.sender);
        uint256 contributionReduction = currentContribution.mul(ratio).div(DECIMALS_18);
        _contributions[msg.sender] = currentContribution.sub(contributionReduction);
        _totalContributions = _totalContributions.sub(contributionReduction);
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            _rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    ///@notice to be called after the amount of reward tokens (specified by the reward parameter) has been sent to the contract
    // Note that the reward should be divisible by the duration to avoid reward token lost
    ///@param reward number of token to be distributed over the duration
    function notifyRewardAmount(uint256 reward) external override onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(duration);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.6.5;

import "@openzeppelin/contracts-0.6/access/Ownable.sol";

abstract contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external virtual;

    modifier onlyRewardDistribution() {
        require(_msgSender() == rewardDistribution, "Caller is not reward distribution");
        _;
    }

    function setRewardDistribution(address _rewardDistribution) external onlyOwner {
        rewardDistribution = _rewardDistribution;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

pragma solidity 0.6.5;

import "../LiquidityMining/LandWeightedSANDRewardPool.sol";


contract LandWeightedSANDRewardPoolNFTTest is LandWeightedSANDRewardPool {
    constructor(
        address stakeTokenContract,
        address rewardTokenContract,
        address nftContract,
        uint256 rewardDuration
    ) public LandWeightedSANDRewardPool(IERC20(stakeTokenContract), IERC20(rewardTokenContract), ERC721(nftContract), rewardDuration) {}
}

pragma solidity 0.6.5;

import "@openzeppelin/contracts-0.6/math/Math.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/access/Ownable.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";
import "../IRewardDistributionRecipient.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public _uniTest; // deploy a Rinkeby Uniswap SAND-ETH pair

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _uniTest.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _uniTest.safeTransfer(msg.sender, amount);
    }
}

contract RinkebySANDRewardPool is LPTokenWrapper, IRewardDistributionRecipient {
    constructor(address uniTest) public {
        _uniTest = IERC20(uniTest); // constructor for Rinkeby UniswapPair address
    }

    IERC20 public sand = IERC20(0xCc933a862fc15379E441F2A16Cb943D385a4695f); // Reward token: Rinkeby SAND
    uint256 public constant DURATION = 30 days; // Reward period

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(
                rewards[account]
            );
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            sand.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward) external override onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}

pragma solidity 0.6.5;

import "@openzeppelin/contracts-0.6/math/Math.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/access/Ownable.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";
import "../IRewardDistributionRecipient.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public uni = IERC20(0x3dd49f67E9d5Bc4C5E6634b3F70BfD9dc1b6BD74); // lpToken contract address, currently set to the SAND-ETH pool contract address

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        uni.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        uni.safeTransfer(msg.sender, amount);
    }
}

contract SANDRewardPool is LPTokenWrapper, IRewardDistributionRecipient {
    IERC20 public sand = IERC20(0x3845badAde8e6dFF049820680d1F14bD3903a5d0); // Reward token: SAND
    uint256 public constant DURATION = 30 days; // Reward period

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(
                rewards[account]
            );
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            sand.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward) external override onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}

pragma solidity 0.6.5;

import "@openzeppelin/contracts-0.6/math/Math.sol";
import "@openzeppelin/contracts-0.6/math/SafeMath.sol";
import "@openzeppelin/contracts-0.6/access/Ownable.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";
import "../IRewardDistributionRecipient.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public _uniTest; // deploy a Goerli Uniswap SAND-ETH pair

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _uniTest.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _uniTest.safeTransfer(msg.sender, amount);
    }
}

contract GoerliSANDRewardPool is LPTokenWrapper, IRewardDistributionRecipient {
    constructor(address uniTest) public {
        _uniTest = IERC20(uniTest); // constructor for Goerli UniswapPair address
    }

    IERC20 public sand = IERC20(0x200814fe1B8F947084D810C099176685496e5d14); // Reward token: Goerli SAND
    uint256 public constant DURATION = 1 hours; // Reward period

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account).mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(
                rewards[account]
            );
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            sand.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function notifyRewardAmount(uint256 reward) external override onlyRewardDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;
import "./FeeDistributor.sol";
import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/BaseWithStorage/Ownable.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/// @title Fee Time Vault
/// @notice Holds tokens collected from fees in a locked state for a certain period of time
contract FeeTimeVault is Ownable {
    using SafeERC20 for IERC20;
    mapping(uint256 => uint256) public accumulatedAmountPerDay;
    FeeDistributor public feeDistributor;

    /// @notice Updates the total amount of fees collected alongside with the due date
    function sync() external returns (uint256) {
        uint256 timestamp = now;
        uint256 day = ((timestamp - _startTime) / 1 days);
        uint256 amount = feeDistributor.withdraw(_sandToken, address(this));
        accumulatedAmountPerDay[day] = accumulatedAmountPerDay[_lastDaySaved].add(amount);
        _lastDaySaved = day;
        return amount;
    }

    /// @notice Enables fee holder to withdraw its share after lock period expired
    /// @param beneficiary the address that will receive fees
    function withdraw(address payable beneficiary) external onlyOwner returns (uint256) {
        uint256 day = ((now - _startTime) / 1 days);
        uint256 lockPeriod = _lockPeriod;
        uint256 amount = lockPeriod > day ? 0 : accumulatedAmountPerDay[day - lockPeriod];
        if (amount != 0) {
            uint256 withdrawnAmount = _withdrawnAmount;
            amount = amount.sub(withdrawnAmount);
            _withdrawnAmount = withdrawnAmount.add(amount);
            _sandToken.safeTransfer(beneficiary, amount);
        }
        return amount;
    }

    /// @notice Enables fee holder to withdraw token fees with no time-lock for tokens other than SAND
    /// @param token the token that fees are collected in
    /// @param beneficiary the address that will receive fees
    function withdrawNoTimeLock(IERC20 token, address payable beneficiary) external onlyOwner returns (uint256) {
        require(token != _sandToken, "SAND_TOKEN_WITHDRWAL_NOT_ALLOWED");
        uint256 amount = feeDistributor.withdraw(token, beneficiary);
        return amount;
    }

    function setFeeDistributor(FeeDistributor _feeDistributor) external onlyOwner {
        require(address(feeDistributor) == address(0), "FEE_DISTRIBUTOR_ALREADY_SET");
        require(address(_feeDistributor) != address(0), "FEE_DISTRIBUTOR_ZERO_ADDRESS");
        feeDistributor = _feeDistributor;
    }

    receive() external payable {}

    // /////////////////// UTILITIES /////////////////////
    using SafeMathWithRequire for uint256;
    // //////////////////////// DATA /////////////////////

    uint256 private _lockPeriod;
    IERC20 private _sandToken;
    uint256 private _lastDaySaved;
    uint256 private _withdrawnAmount;
    uint256 private _startTime;

    // /////////////////// CONSTRUCTOR ////////////////////
    /// @param lockPeriod lockPeriod measured in days, e.g. lockPeriod = 10 => 10 days
    /// @param token sand token contract address
    /// @param owner the account that can make a withdrawal
    constructor(
        uint256 lockPeriod,
        IERC20 token,
        address payable owner
    ) public Ownable(owner) {
        _lockPeriod = lockPeriod;
        _sandToken = token;
        _startTime = now;
    }
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../common/Libraries/SafeMathWithRequire.sol";
import "@openzeppelin/contracts-0.6/token/ERC20/SafeERC20.sol";

/// @title Fee distributor
/// @notice Distributes all fees collected from platform activities to stakeholders
contract FeeDistributor {
    using SafeERC20 for IERC20;
    event Deposit(address token, address from, uint256 amount);
    event Withdrawal(IERC20 token, address to, uint256 amount);
    mapping(address => uint256) public recipientsShares;

    /// @notice Enables fee holder to withdraw its share
    /// @notice Zero address reserved for ether withdrawal
    /// @param token the token that fee should be distributed in
    /// @param beneficiary the address that will receive fees
    /// @return amount had withdrawn
    function withdraw(IERC20 token, address payable beneficiary) external returns (uint256 amount) {
        if (address(token) == address(0)) {
            amount = _etherWithdrawal(beneficiary);
        } else {
            amount = _tokenWithdrawal(token, beneficiary);
        }
        if (amount != 0) {
            emit Withdrawal(token, msg.sender, amount);
        }
    }

    receive() external payable {
        emit Deposit(address(0), msg.sender, msg.value);
    }

    // //////////////////// INTERNALS ////////////////////
    function _etherWithdrawal(address payable beneficiary) private returns (uint256) {
        uint256 amount = _calculateWithdrawalAmount(address(this).balance, address(0));
        if (amount > 0) {
            beneficiary.transfer(amount);
        }
        return amount;
    }

    function _tokenWithdrawal(IERC20 token, address payable beneficiary) private returns (uint256) {
        uint256 amount = _calculateWithdrawalAmount(token.balanceOf(address(this)), address(token));
        if (amount > 0) {
            token.safeTransfer(beneficiary, amount);
        }
        return amount;
    }

    function _calculateWithdrawalAmount(uint256 currentBalance, address token) private returns (uint256) {
        uint256 totalReceived = _tokensState[token].totalReceived;
        uint256 lastBalance = _tokensState[token].lastBalance;
        uint256 amountAlreadyGiven = _tokensState[token].amountAlreadyGiven[msg.sender];
        uint256 _currentBalance = currentBalance;
        totalReceived = totalReceived.add(_currentBalance.sub(lastBalance));
        _tokensState[token].totalReceived = totalReceived;
        uint256 amountDue = ((totalReceived.mul(recipientsShares[msg.sender])).div(10**DECIMALS)).sub(
            amountAlreadyGiven
        );
        if (amountDue == 0) {
            return amountDue;
        }
        amountAlreadyGiven = amountAlreadyGiven.add(amountDue);
        _tokensState[token].amountAlreadyGiven[msg.sender] = amountAlreadyGiven;
        _tokensState[token].lastBalance = _currentBalance.sub(amountDue);
        return amountDue;
    }

    // /////////////////// UTILITIES /////////////////////
    using SafeMathWithRequire for uint256;

    // //////////////////////// DATA /////////////////////
    struct TokenState {
        uint256 totalReceived;
        mapping(address => uint256) amountAlreadyGiven;
        uint256 lastBalance;
    }
    mapping(address => TokenState) private _tokensState;
    uint256 private constant DECIMALS = 4;

    // /////////////////// CONSTRUCTOR ////////////////////
    /// @notice Assign each recipient with its corresponding share.
    /// @notice Percentages are 4 decimal points, e.g. 1 % = 100
    /// @param recipients fee recipients
    /// @param shares the corresponding share (from total fees held by the contract) for a recipient
    constructor(address payable[] memory recipients, uint256[] memory shares) public {
        require(recipients.length == shares.length, "ARRAYS_LENGTHS_SHOULD_BE_EQUAL");
        uint256 totalPercentage = 0;
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipientsShares[recipients[i]] == 0, "NO_DUPLICATE_ADDRESSES");
            uint256 share = shares[i];
            recipientsShares[recipients[i]] = share;
            totalPercentage = totalPercentage.add(share);
        }
        require(totalPercentage == 10**DECIMALS, "PERCENTAGES_ARRAY_SHOULD_SUM_TO_100%");
    }
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "./Interfaces/AssetToken.sol";
import "./common/Interfaces/ERC20.sol";
import "./Interfaces/ERC20Extended.sol";
import "./common/BaseWithStorage/MetaTransactionReceiver.sol";
import "./common/Libraries/SafeMathWithRequire.sol";
import "./Catalyst/GemToken.sol";
import "./Catalyst/CatalystToken.sol";
import "./CatalystRegistry.sol";
import "./BaseWithStorage/ERC20Group.sol";


/// @notice Gateway to mint Asset with Catalyst, Gems and Sand
contract CatalystMinter is MetaTransactionReceiver {
    /// @dev emitted when fee collector (that receive the sand fee) get changed
    /// @param newCollector address of the new collector, address(0) means the fee will be burned
    event FeeCollector(address newCollector);

    function setFeeCollector(address newCollector) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        _setFeeCollector(newCollector);
    }

    event GemAdditionFee(uint256 newFee);

    function setGemAdditionFee(uint256 newFee) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        _setGemAdditionFee(newFee);
    }

    /// @notice mint one Asset token.
    /// @param from address creating the Asset, need to be the tx sender or meta tx signer.
    /// @param packId unused packId that will let you predict the resulting tokenId.
    /// @param metadataHash cidv1 ipfs hash of the folder where 0.json file contains the metadata.
    /// @param catalystId address of the Catalyst ERC20 token to burn.
    /// @param gemIds list of gem ids to burn in the catalyst.
    /// @param quantity asset supply to mint
    /// @param to destination address receiving the minted tokens.
    /// @param data extra data.
    function mint(
        address from,
        uint40 packId,
        bytes32 metadataHash,
        uint256 catalystId,
        uint256[] calldata gemIds,
        uint256 quantity,
        address to,
        bytes calldata data
    ) external returns (uint256) {
        _checkAuthorization(from, to);
        _burnCatalyst(from, catalystId);
        uint16 maxGems = _checkQuantityAndBurnSandAndGems(from, catalystId, gemIds, quantity);
        uint256 id = _asset.mint(from, packId, metadataHash, quantity, 0, to, data);
        _catalystRegistry.setCatalyst(id, catalystId, maxGems, gemIds);
        return id;
    }

    /// @notice associate a catalyst to a fungible Asset token by extracting it as ERC721 first.
    /// @param from address from which the Asset token belongs to.
    /// @param assetId tokenId of the Asset being extracted.
    /// @param catalystId address of the catalyst token to use and burn.
    /// @param gemIds list of gems to socket into the catalyst (burned).
    /// @param to destination address receiving the extracted and upgraded ERC721 Asset token.
    function extractAndChangeCatalyst(
        address from,
        uint256 assetId,
        uint256 catalystId,
        uint256[] calldata gemIds,
        address to
    ) external returns (uint256 tokenId) {
        _checkAuthorization(from, to);
        tokenId = _asset.extractERC721From(from, assetId, from);
        _changeCatalyst(from, tokenId, catalystId, gemIds, to);
    }

    /// @notice associate a new catalyst to a non-fungible Asset token.
    /// @param from address from which the Asset token belongs to.
    /// @param assetId tokenId of the Asset being updated.
    /// @param catalystId address of the catalyst token to use and burn.
    /// @param gemIds list of gems to socket into the catalyst (burned).
    /// @param to destination address receiving the Asset token.
    function changeCatalyst(
        address from,
        uint256 assetId,
        uint256 catalystId,
        uint256[] calldata gemIds,
        address to
    ) external returns (uint256 tokenId) {
        _checkAuthorization(from, to);
        _changeCatalyst(from, assetId, catalystId, gemIds, to);
        return assetId;
    }

    /// @notice add gems to a fungible Asset token by extracting it as ERC721 first.
    /// @param from address from which the Asset token belongs to.
    /// @param assetId tokenId of the Asset being extracted.
    /// @param gemIds list of gems to socket into the existing catalyst (burned).
    /// @param to destination address receiving the extracted and upgraded ERC721 Asset token.
    function extractAndAddGems(
        address from,
        uint256 assetId,
        uint256[] calldata gemIds,
        address to
    ) external returns (uint256 tokenId) {
        _checkAuthorization(from, to);
        tokenId = _asset.extractERC721From(from, assetId, from);
        _addGems(from, tokenId, gemIds, to);
    }

    /// @notice add gems to a non-fungible Asset token.
    /// @param from address from which the Asset token belongs to.
    /// @param assetId tokenId of the Asset to which the gems will be added to.
    /// @param gemIds list of gems to socket into the existing catalyst (burned).
    /// @param to destination address receiving the extracted and upgraded ERC721 Asset token.
    function addGems(
        address from,
        uint256 assetId,
        uint256[] calldata gemIds,
        address to
    ) external {
        _checkAuthorization(from, to);
        _addGems(from, assetId, gemIds, to);
    }

    struct AssetData {
        uint256[] gemIds;
        uint256 quantity;
        uint256 catalystId;
    }

    /// @notice mint multiple Asset tokens.
    /// @param from address creating the Asset, need to be the tx sender or meta tx signer.
    /// @param packId unused packId that will let you predict the resulting tokenId.
    /// @param metadataHash cidv1 ipfs hash of the folder where 0.json file contains the metadata.
    /// @param gemsQuantities quantities of gems to be used for each id in order
    /// @param catalystsQuantities quantities of catalyst to be used for each id in order
    /// @param assets contains the data to associate catalyst and gems to the assets.
    /// @param to destination address receiving the minted tokens.
    /// @param data extra data.
    function mintMultiple(
        address from,
        uint40 packId,
        bytes32 metadataHash,
        uint256[] memory gemsQuantities,
        uint256[] memory catalystsQuantities,
        AssetData[] memory assets,
        address to,
        bytes memory data
    ) public returns (uint256[] memory ids) {
        require(assets.length != 0, "INVALID_0_ASSETS");
        _checkAuthorization(from, to);
        return _mintMultiple(from, packId, metadataHash, gemsQuantities, catalystsQuantities, assets, to, data);
    }

    // //////////////////// INTERNALS ////////////////////

    function _checkQuantityAndBurnSandAndGems(
        address from,
        uint256 catalystId,
        uint256[] memory gemIds,
        uint256 quantity
    ) internal returns (uint16) {
        (uint16 maxGems, uint16 minQuantity, uint16 maxQuantity, uint256 sandMintingFee, ) = _getMintData(catalystId);
        require(minQuantity <= quantity && quantity <= maxQuantity, "INVALID_QUANTITY");
        require(gemIds.length <= maxGems, "INVALID_GEMS_TOO_MANY");
        _burnSingleGems(from, gemIds);
        _chargeSand(from, quantity.mul(sandMintingFee));
        return maxGems;
    }

    function _mintMultiple(
        address from,
        uint40 packId,
        bytes32 metadataHash,
        uint256[] memory gemsQuantities,
        uint256[] memory catalystsQuantities,
        AssetData[] memory assets,
        address to,
        bytes memory data
    ) internal returns (uint256[] memory) {
        (uint256 totalSandFee, uint256[] memory supplies, uint16[] memory maxGemsList) = _handleMultipleCatalysts(
            from,
            gemsQuantities,
            catalystsQuantities,
            assets
        );

        _chargeSand(from, totalSandFee);

        return _mintAssets(from, packId, metadataHash, assets, supplies, maxGemsList, to, data);
    }

    function _chargeSand(address from, uint256 sandFee) internal {
        address feeCollector = _feeCollector;
        if (feeCollector != address(0) && sandFee != 0) {
            if (feeCollector == address(BURN_ADDRESS)) {
                // special address for burn
                _sand.burnFor(from, sandFee);
            } else {
                _sand.transferFrom(from, _feeCollector, sandFee);
            }
        }
    }

    function _extractMintData(uint256 data)
        internal
        pure
        returns (
            uint16 maxGems,
            uint16 minQuantity,
            uint16 maxQuantity,
            uint256 sandMintingFee,
            uint256 sandUpdateFee
        )
    {
        maxGems = uint16(data >> 240);
        minQuantity = uint16((data >> 224) % 2**16);
        maxQuantity = uint16((data >> 208) % 2**16);
        sandMintingFee = uint256((data >> 120) % 2**88);
        sandUpdateFee = uint256(data % 2**88);
    }

    function _getMintData(uint256 catalystId)
        internal
        view
        returns (
            uint16,
            uint16,
            uint16,
            uint256,
            uint256
        )
    {
        if (catalystId == 0) {
            return _extractMintData(_common_mint_data);
        } else if (catalystId == 1) {
            return _extractMintData(_rare_mint_data);
        } else if (catalystId == 2) {
            return _extractMintData(_epic_mint_data);
        } else if (catalystId == 3) {
            return _extractMintData(_legendary_mint_data);
        }
        return _catalysts.getMintData(catalystId);
    }

    function _handleMultipleCatalysts(
        address from,
        uint256[] memory gemsQuantities,
        uint256[] memory catalystsQuantities,
        AssetData[] memory assets
    )
        internal
        returns (
            uint256 totalSandFee,
            uint256[] memory supplies,
            uint16[] memory maxGemsList
        )
    {
        _burnCatalysts(from, catalystsQuantities);
        _burnGems(from, gemsQuantities);

        supplies = new uint256[](assets.length);
        maxGemsList = new uint16[](assets.length);

        for (uint256 i = 0; i < assets.length; i++) {
            require(catalystsQuantities[assets[i].catalystId] != 0, "INVALID_CATALYST_NOT_ENOUGH");
            catalystsQuantities[assets[i].catalystId]--;
            gemsQuantities = _checkGemsQuantities(gemsQuantities, assets[i].gemIds);
            (uint16 maxGems, uint16 minQuantity, uint16 maxQuantity, uint256 sandMintingFee, ) = _getMintData(assets[i].catalystId);
            require(minQuantity <= assets[i].quantity && assets[i].quantity <= maxQuantity, "INVALID_QUANTITY");
            require(assets[i].gemIds.length <= maxGems, "INVALID_GEMS_TOO_MANY");
            maxGemsList[i] = maxGems;
            supplies[i] = assets[i].quantity;
            totalSandFee = totalSandFee.add(sandMintingFee.mul(assets[i].quantity));
        }
    }

    function _checkGemsQuantities(uint256[] memory gemsQuantities, uint256[] memory gemIds) internal pure returns (uint256[] memory) {
        for (uint256 i = 0; i < gemIds.length; i++) {
            require(gemsQuantities[gemIds[i]] != 0, "INVALID_GEMS_NOT_ENOUGH");
            gemsQuantities[gemIds[i]]--;
        }
        return gemsQuantities;
    }

    function _burnCatalysts(address from, uint256[] memory catalystsQuantities) internal {
        uint256[] memory ids = new uint256[](catalystsQuantities.length);
        for (uint256 i = 0; i < ids.length; i++) {
            ids[i] = i;
        }
        _catalysts.batchBurnFrom(from, ids, catalystsQuantities);
    }

    function _burnGems(address from, uint256[] memory gemsQuantities) internal {
        uint256[] memory ids = new uint256[](gemsQuantities.length);
        for (uint256 i = 0; i < ids.length; i++) {
            ids[i] = i;
        }
        _gems.batchBurnFrom(from, ids, gemsQuantities);
    }

    function _mintAssets(
        address from,
        uint40 packId,
        bytes32 metadataHash,
        AssetData[] memory assets,
        uint256[] memory supplies,
        uint16[] memory maxGemsList,
        address to,
        bytes memory data
    ) internal returns (uint256[] memory tokenIds) {
        tokenIds = _asset.mintMultiple(from, packId, metadataHash, supplies, "", to, data);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _catalystRegistry.setCatalyst(tokenIds[i], assets[i].catalystId, maxGemsList[i], assets[i].gemIds);
        }
    }

    function _changeCatalyst(
        address from,
        uint256 assetId,
        uint256 catalystId,
        uint256[] memory gemIds,
        address to
    ) internal {
        require(assetId & IS_NFT != 0, "INVALID_NOT_NFT"); // Asset (ERC1155ERC721.sol) ensure NFT will return true here and non-NFT will return false
        _burnCatalyst(from, catalystId);
        (uint16 maxGems, , , , uint256 sandUpdateFee) = _getMintData(catalystId);
        require(gemIds.length <= maxGems, "INVALID_GEMS_TOO_MANY");
        _burnGems(from, gemIds);
        _chargeSand(from, sandUpdateFee);

        _catalystRegistry.setCatalyst(assetId, catalystId, maxGems, gemIds);

        _transfer(from, to, assetId);
    }

    function _addGems(
        address from,
        uint256 assetId,
        uint256[] memory gemIds,
        address to
    ) internal {
        require(assetId & IS_NFT != 0, "INVALID_NOT_NFT"); // Asset (ERC1155ERC721.sol) ensure NFT will return true here and non-NFT will return false
        _catalystRegistry.addGems(assetId, gemIds);
        _chargeSand(from, gemIds.length.mul(_gemAdditionFee));
        _transfer(from, to, assetId);
    }

    function _transfer(
        address from,
        address to,
        uint256 assetId
    ) internal {
        if (from != to) {
            _asset.safeTransferFrom(from, to, assetId);
        }
    }

    function _checkAuthorization(address from, address to) internal view {
        require(to != address(0), "INVALID_TO_ZERO_ADDRESS");
        require(from == msg.sender || _metaTransactionContracts[msg.sender], "NOT_SENDER");
    }

    function _burnSingleGems(address from, uint256[] memory gemIds) internal {
        uint256[] memory amounts = new uint256[](gemIds.length);
        for (uint256 i = 0; i < gemIds.length; i++) {
            amounts[i] = 1;
        }
        _gems.batchBurnFrom(from, gemIds, amounts);
    }

    function _burnCatalyst(address from, uint256 catalystId) internal {
        _catalysts.burnFrom(from, catalystId, 1);
    }

    function _setFeeCollector(address newCollector) internal {
        _feeCollector = newCollector;
        emit FeeCollector(newCollector);
    }

    function _setGemAdditionFee(uint256 newFee) internal {
        _gemAdditionFee = newFee;
        emit GemAdditionFee(newFee);
    }

    // /////////////////// UTILITIES /////////////////////
    using SafeMathWithRequire for uint256;

    // //////////////////////// DATA /////////////////////
    uint256 private constant IS_NFT = 0x0000000000000000000000000000000000000000800000000000000000000000;
    address private constant BURN_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

    ERC20Extended internal immutable _sand;
    AssetToken internal immutable _asset;
    GemToken internal immutable _gems;
    CatalystToken internal immutable _catalysts;
    CatalystRegistry internal immutable _catalystRegistry;
    address internal _feeCollector;

    uint256 internal immutable _common_mint_data;
    uint256 internal immutable _rare_mint_data;
    uint256 internal immutable _epic_mint_data;
    uint256 internal immutable _legendary_mint_data;

    uint256 internal _gemAdditionFee;

    // /////////////////// CONSTRUCTOR ////////////////////
    constructor(
        CatalystRegistry catalystRegistry,
        ERC20Extended sand,
        AssetToken asset,
        GemToken gems,
        address metaTx,
        address admin,
        address feeCollector,
        uint256 gemAdditionFee,
        CatalystToken catalysts,
        uint256[4] memory bakedInMintdata
    ) public {
        _catalystRegistry = catalystRegistry;
        _sand = sand;
        _asset = asset;
        _gems = gems;
        _catalysts = catalysts;
        _admin = admin;
        _setGemAdditionFee(gemAdditionFee);
        _setFeeCollector(feeCollector);
        _setMetaTransactionProcessor(metaTx, true);
        _common_mint_data = bakedInMintdata[0];
        _rare_mint_data = bakedInMintdata[1];
        _epic_mint_data = bakedInMintdata[2];
        _legendary_mint_data = bakedInMintdata[3];
    }
}

pragma solidity 0.6.5;


interface AssetToken {
    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        uint8 rarity,
        address owner,
        bytes calldata data
    ) external returns (uint256 id);

    function mintMultiple(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256[] calldata supplies,
        bytes calldata rarityPack,
        address owner,
        bytes calldata data
    ) external returns (uint256[] memory ids);

    // fails on non-NFT or nft who do not have collection (was a mistake)
    function collectionOf(uint256 id) external view returns (uint256);

    function balanceOf(address owner, uint256 id) external view returns (uint256);

    // return true for Non-NFT ERC1155 tokens which exists
    function isCollection(uint256 id) external view returns (bool);

    function collectionIndexOf(uint256 id) external view returns (uint256);

    function extractERC721From(
        address sender,
        uint256 id,
        address to
    ) external returns (uint256 newId);

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

pragma solidity 0.6.5;

import "../common/Interfaces/ERC20.sol";


interface ERC20Extended is ERC20 {
    function burnFor(address from, uint256 amount) external;

    function burn(uint256 amount) external;

    function approveFor(
        address owner,
        address spender,
        uint256 amount
    ) external returns (bool success);
}

pragma solidity 0.6.5;


interface GemToken {
    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;


interface CatalystToken {
    function getMintData(uint256 catalystId)
        external
        view
        returns (
            uint16 maxGems,
            uint16 minQuantity,
            uint16 maxQuantity,
            uint256 sandMintingFee,
            uint256 sandUpdateFee
        );

    function batchBurnFrom(
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;

    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external;
}

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "./Interfaces/AssetToken.sol";
import "./common/BaseWithStorage/Admin.sol";
import "./Catalyst/CatalystValue.sol";


contract CatalystRegistry is Admin, CatalystValue {
    event Minter(address indexed newMinter);
    event CatalystApplied(uint256 indexed assetId, uint256 indexed catalystId, uint256 seed, uint256[] gemIds, uint64 blockNumber);
    event GemsAdded(uint256 indexed assetId, uint256 seed, uint256[] gemIds, uint64 blockNumber);

    function getCatalyst(uint256 assetId) external view returns (bool exists, uint256 catalystId) {
        CatalystStored memory catalyst = _catalysts[assetId];
        if (catalyst.set != 0) {
            return (true, catalyst.catalystId);
        }
        if (assetId & IS_NFT != 0) {
            catalyst = _catalysts[_getCollectionId(assetId)];
            return (catalyst.set != 0, catalyst.catalystId);
        }
        return (false, 0);
    }

    function setCatalyst(
        uint256 assetId,
        uint256 catalystId,
        uint256 maxGems,
        uint256[] calldata gemIds
    ) external {
        require(msg.sender == _minter, "NOT_AUTHORIZED_MINTER");
        require(gemIds.length <= maxGems, "INVALID_GEMS_TOO_MANY");
        uint256 emptySockets = maxGems - gemIds.length;
        _catalysts[assetId] = CatalystStored(uint64(emptySockets), uint64(catalystId), 1);
        uint64 blockNumber = _getBlockNumber();
        emit CatalystApplied(assetId, catalystId, assetId, gemIds, blockNumber);
    }

    function addGems(uint256 assetId, uint256[] calldata gemIds) external {
        require(msg.sender == _minter, "NOT_AUTHORIZED_MINTER");
        require(assetId & IS_NFT != 0, "INVALID_NOT_NFT");
        require(gemIds.length != 0, "INVALID_GEMS_0");
        (uint256 emptySockets, uint256 seed) = _getSocketData(assetId);
        require(emptySockets >= gemIds.length, "INVALID_GEMS_TOO_MANY");
        emptySockets -= gemIds.length;
        _catalysts[assetId].emptySockets = uint64(emptySockets);
        uint64 blockNumber = _getBlockNumber();
        emit GemsAdded(assetId, seed, gemIds, blockNumber);
    }

    /// @dev Set the Minter that will be the only address able to create Estate
    /// @param minter address of the minter
    function setMinter(address minter) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        require(minter != _minter, "INVALID_MINTER_SAME_ALREADY_SET");
        _minter = minter;
        emit Minter(minter);
    }

    /// @dev return the current minter
    function getMinter() external view returns (address) {
        return _minter;
    }

    function getValues(
        uint256 catalystId,
        uint256 seed,
        GemEvent[] calldata events,
        uint32 totalNumberOfGemTypes
    ) external override view returns (uint32[] memory values) {
        return _catalystValue.getValues(catalystId, seed, events, totalNumberOfGemTypes);
    }

    // ///////// INTERNAL ////////////

    uint256 private constant IS_NFT = 0x0000000000000000000000000000000000000000800000000000000000000000;
    uint256 private constant NOT_IS_NFT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFFFFFFFFFF;
    uint256 private constant NOT_NFT_INDEX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF800000007FFFFFFFFFFFFFFF;

    function _getSocketData(uint256 assetId) internal view returns (uint256 emptySockets, uint256 seed) {
        seed = assetId;
        CatalystStored memory catalyst = _catalysts[assetId];
        if (catalyst.set != 0) {
            // the gems are added to an asset who already get a specific catalyst.
            // the seed is its id
            return (catalyst.emptySockets, seed);
        }
        // else the asset is only adding gems while keeping the same seed (that of the original assetId)
        seed = _getCollectionId(assetId);
        catalyst = _catalysts[seed];
        return (catalyst.emptySockets, seed);
    }

    function _getBlockNumber() internal view returns (uint64 blockNumber) {
        blockNumber = uint64(block.number + 1);
    }

    function _getCollectionId(uint256 assetId) internal pure returns (uint256) {
        return assetId & NOT_NFT_INDEX & NOT_IS_NFT; // compute the same as Asset to get collectionId
    }

    // CONSTRUCTOR ////
    constructor(CatalystValue catalystValue, address admin) public {
        _admin = admin;
        _catalystValue = catalystValue;
    }

    /// DATA ////////

    struct CatalystStored {
        uint64 emptySockets;
        uint64 catalystId;
        uint64 set;
    }
    address internal _minter;
    CatalystValue internal immutable _catalystValue;
    mapping(uint256 => CatalystStored) internal _catalysts;
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.6.5;
import "../Interfaces/ERC20Extended.sol";

contract MockSandPredicate {
    event LockedERC20(
        address indexed depositor,
        address indexed depositReceiver,
        address indexed rootToken,
        uint256 amount
    );

    function lockTokens(
        address depositor,
        address depositReceiver,
        address rootToken,
        bytes calldata depositData
    ) external {
        uint256 amount = abi.decode(depositData, (uint256));
        emit LockedERC20(depositor, depositReceiver, rootToken, amount);
        ERC20Extended(rootToken).transferFrom(depositor, address(this), amount);
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.6.5;
import "./MockSandPredicate.sol";

contract MockRootChainManager {
    address internal immutable _predicateAddress;

    constructor(address predicateAddress) public {
        _predicateAddress = predicateAddress;
    }

    function depositFor(
        address user,
        address rootToken,
        bytes calldata depositData
    ) external {
        MockSandPredicate(_predicateAddress).lockTokens(msg.sender, user, rootToken, depositData);
    }
}

/* solhint-disable not-rely-on-time, func-order */
pragma solidity 0.6.5;

import "../common/Libraries/SafeMathWithRequire.sol";
import "./LandToken.sol";
import "../common/Interfaces/ERC1155.sol";
import "../common/Interfaces/ERC20.sol";
import "../common/BaseWithStorage/MetaTransactionReceiver.sol";
import "../ReferralValidator/ReferralValidator.sol";
import "./AuthValidator.sol";

/// @title Estate Sale contract with referral
/// @notice This contract manages the sale of our lands as Estates
contract EstateSaleWithAuth is MetaTransactionReceiver, ReferralValidator {
    using SafeMathWithRequire for uint256;

    event LandQuadPurchased(
        address indexed buyer,
        address indexed to,
        uint256 indexed topCornerId,
        uint256 size,
        uint256 price,
        address token,
        uint256 amountPaid
    );

    /// @notice set the wallet receiving the proceeds
    /// @param newWallet address of the new receiving wallet
    function setReceivingWallet(address payable newWallet) external {
        require(newWallet != address(0), "ZERO_ADDRESS");
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        _wallet = newWallet;
    }

    /// @notice buy Land with SAND using the merkle proof associated with it
    /// @param buyer address that perform the payment
    /// @param to address that will own the purchased Land
    /// @param reserved the reserved address (if any)
    /// @param info [X_INDEX=0] x coordinate of the Land [Y_INDEX=1] y coordinate of the Land [SIZE_INDEX=2] size of the pack of Land to purchase [PRICE_INDEX=3] price in SAND to purchase that Land
    /// @param proof merkleProof for that particular Land
    function buyLandWithSand(
        address buyer,
        address to,
        address reserved,
        uint256[] calldata info,
        bytes32 salt,
        uint256[] calldata assetIds,
        bytes32[] calldata proof,
        bytes calldata referral,
        bytes calldata signature
    ) external {
        _checkAddressesAndExpiryTime(buyer, reserved);
        _checkAuthAndProofValidity(to, reserved, info, salt, assetIds, proof, signature);
        _handleFeeAndReferral(buyer, info[PRICE_INDEX], referral);
        _mint(buyer, to, info);
        _sendAssets(to, assetIds);
    }

    /// @notice Gets the expiry time for the current sale
    /// @return The expiry time, as a unix epoch
    function getExpiryTime() external view returns (uint256) {
        return _expiryTime;
    }

    /// @notice Gets the Merkle root associated with the current sale
    /// @return The Merkle root, as a bytes32 hash
    function getMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    /// @notice enable Admin to withdraw remaining assets from EstateSaleWithFee contract
    /// @param to intended recipient of the asset tokens
    /// @param assetIds the assetIds to be transferred
    /// @param values the quantities of the assetIds to be transferred
    function withdrawAssets(
        address to,
        uint256[] calldata assetIds,
        uint256[] calldata values
    ) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED");
        // require(block.timestamp > _expiryTime, "SALE_NOT_OVER"); // removed to recover in case of misconfigured sales
        _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");
    }

    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*ids*/
        uint256[] calldata, /*values*/
        bytes calldata /*data*/
    ) external pure returns (bytes4) {
        return 0xbc197c81;
    }

    function _sendAssets(address to, uint256[] memory assetIds) internal {
        uint256[] memory values = new uint256[](assetIds.length);
        for (uint256 i = 0; i < assetIds.length; i++) {
            values[i] = 1;
        }
        _asset.safeBatchTransferFrom(address(this), to, assetIds, values, "");
    }

    // NOTE: _checkAddressesAndExpiryTime & _checkAuthAndProofValidity were split due to a stack too deep issue
    function _checkAddressesAndExpiryTime(address buyer, address reserved) internal view {
        /* solium-disable-next-line security/no-block-members */
        require(block.timestamp < _expiryTime, "SALE_IS_OVER");
        require(buyer == msg.sender || _metaTransactionContracts[msg.sender], "NOT_AUTHORIZED");
        require(reserved == address(0) || reserved == buyer, "RESERVED_LAND");
    }

    // NOTE: _checkAddressesAndExpiryTime & _checkAuthAndProofValidity were split due to a stack too deep issue
    function _checkAuthAndProofValidity(
        address to,
        address reserved,
        uint256[] memory info,
        bytes32 salt,
        uint256[] memory assetIds,
        bytes32[] memory proof,
        bytes memory signature
    ) internal view {
        bytes32 hashedData = keccak256(
            abi.encodePacked(
                to,
                reserved,
                info[X_INDEX],
                info[Y_INDEX],
                info[SIZE_INDEX],
                info[PRICE_INDEX],
                salt,
                keccak256(abi.encodePacked(assetIds)),
                keccak256(abi.encodePacked(proof))
            )
        );
        require(_authValidator.isAuthValid(signature, hashedData), "INVALID_AUTH");

        bytes32 leaf = _generateLandHash(
            info[X_INDEX],
            info[Y_INDEX],
            info[SIZE_INDEX],
            info[PRICE_INDEX],
            reserved,
            salt,
            assetIds
        );
        require(_verify(proof, leaf), "INVALID_LAND");
    }

    function _mint(
        address buyer,
        address to,
        uint256[] memory info
    ) internal {
        if (info[SIZE_INDEX] == 1 || _estate == address(0)) {
            _land.mintQuad(to, info[SIZE_INDEX], info[X_INDEX], info[Y_INDEX], "");
        } else {
            _land.mintQuad(_estate, info[SIZE_INDEX], info[X_INDEX], info[Y_INDEX], abi.encode(to));
        }
        emit LandQuadPurchased(
            buyer,
            to,
            info[X_INDEX] + (info[Y_INDEX] * GRID_SIZE),
            info[SIZE_INDEX],
            info[PRICE_INDEX],
            address(_sand),
            info[PRICE_INDEX]
        );
    }

    function _generateLandHash(
        uint256 x,
        uint256 y,
        uint256 size,
        uint256 price,
        address reserved,
        bytes32 salt,
        uint256[] memory assetIds
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(x, y, size, price, reserved, salt, assetIds));
    }

    function _verify(bytes32[] memory proof, bytes32 leaf) internal view returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == _merkleRoot;
    }

    function _handleFeeAndReferral(
        address buyer,
        uint256 priceInSand,
        bytes memory referral
    ) internal {
        // send 5% fee to a specially configured instance of FeeDistributor.sol
        uint256 remainingAmountInSand = _handleSandFee(buyer, priceInSand);

        // calculate referral based on 95% of original priceInSand
        handleReferralWithERC20(buyer, remainingAmountInSand, referral, _wallet, address(_sand));
    }

    function _handleSandFee(address buyer, uint256 priceInSand) internal returns (uint256) {
        uint256 feeAmountInSand = priceInSand.mul(FEE).div(100);
        require(_sand.transferFrom(buyer, address(_feeDistributor), feeAmountInSand), "FEE_TRANSFER_FAILED");
        return priceInSand.sub(feeAmountInSand);
    }

    uint256 internal constant GRID_SIZE = 408; // 408 is the size of the Land

    ERC1155 internal immutable _asset;
    LandToken internal immutable _land;
    ERC20 internal immutable _sand;
    address internal immutable _estate;
    address internal immutable _feeDistributor;

    address payable internal _wallet;
    AuthValidator internal _authValidator;
    uint256 internal immutable _expiryTime;
    bytes32 internal immutable _merkleRoot;

    uint256 private constant FEE = 5; // percentage of land sale price to be diverted to a specially configured instance of FeeDistributor, shown as an integer
    // buyLandWithSand info indexes
    uint256 private constant X_INDEX = 0;
    uint256 private constant Y_INDEX = 1;
    uint256 private constant SIZE_INDEX = 2;
    uint256 private constant PRICE_INDEX = 3;

    constructor(
        address landAddress,
        address sandContractAddress,
        address initialMetaTx,
        address admin,
        address payable initialWalletAddress,
        bytes32 merkleRoot,
        uint256 expiryTime,
        address initialSigningWallet,
        uint256 initialMaxCommissionRate,
        address estate,
        address asset,
        address feeDistributor,
        address authValidator
    ) public ReferralValidator(initialSigningWallet, initialMaxCommissionRate) {
        _land = LandToken(landAddress);
        _sand = ERC20(sandContractAddress);
        _setMetaTransactionProcessor(initialMetaTx, true);
        _wallet = initialWalletAddress;
        _merkleRoot = merkleRoot;
        _expiryTime = expiryTime;
        _admin = admin;
        _estate = estate;
        _asset = ERC1155(asset);
        _feeDistributor = feeDistributor;
        _authValidator = AuthValidator(authValidator);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.5; // TODO: update once upgrade is complete

import "../common/Libraries/SigUtil.sol";
import "../common/Libraries/SafeMathWithRequire.sol";
import "../common/BaseWithStorage/Admin.sol";

contract AuthValidator is Admin {
    address public _signingAuthWallet;

    event SigningWallet(address indexed signingWallet);

    constructor(address adminWallet, address initialSigningWallet) public {
        _admin = adminWallet;
        _updateSigningAuthWallet(initialSigningWallet);
    }

    function updateSigningAuthWallet(address newSigningWallet) external onlyAdmin {
        _updateSigningAuthWallet(newSigningWallet);
    }

    function _updateSigningAuthWallet(address newSigningWallet) internal {
        require(newSigningWallet != address(0), "INVALID_SIGNING_WALLET");
        _signingAuthWallet = newSigningWallet;
        emit SigningWallet(newSigningWallet);
    }

    function isAuthValid(bytes memory signature, bytes32 hashedData) public view returns (bool) {
        address signer = SigUtil.recover(keccak256(SigUtil.prefixed(hashedData)), signature);
        return signer == _signingAuthWallet;
    }
}

/* This Source Code Form is subject to the terms of the Mozilla external
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
// solhint-disable-next-line compiler-fixed
pragma solidity 0.6.5;

import "./ERC20.sol";


interface ERC20WithMetadata is ERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity 0.6.5;

import "./SafeMathWithRequire.sol";


library ObjectLib64 {
    using SafeMathWithRequire for uint256;
    enum Operations {ADD, SUB, REPLACE}
    // Constants regarding bin or chunk sizes for balance packing
    uint256 constant TYPES_BITS_SIZE = 64; // Max size of each object
    uint256 constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256

    //
    // Objects and Tokens Functions
    //

    /**
     * @dev Return the bin number and index within that bin where ID is
     * @param _tokenId Object type
     * @return bin Bin number
     * @return index ID's index within that bin
     */
    function getTokenBinIndex(uint256 _tokenId) internal pure returns (uint256 bin, uint256 index) {
        bin = (_tokenId * TYPES_BITS_SIZE) / 256;
        index = _tokenId % TYPES_PER_UINT256;
        return (bin, index);
    }

    /**
     * @dev update the balance of a type provided in _binBalances
     * @param _binBalances Uint256 containing the balances of objects
     * @param _index Index of the object in the provided bin
     * @param _amount Value to update the type balance
     * @param _operation Which operation to conduct :
     *     Operations.REPLACE : Replace type balance with _amount
     *     Operations.ADD     : ADD _amount to type balance
     *     Operations.SUB     : Substract _amount from type balance
     */
    function updateTokenBalance(
        uint256 _binBalances,
        uint256 _index,
        uint256 _amount,
        Operations _operation
    ) internal pure returns (uint256 newBinBalance) {
        uint256 objectBalance = 0;
        if (_operation == Operations.ADD) {
            objectBalance = getValueInBin(_binBalances, _index);
            newBinBalance = writeValueInBin(_binBalances, _index, objectBalance.add(_amount));
        } else if (_operation == Operations.SUB) {
            objectBalance = getValueInBin(_binBalances, _index);
            newBinBalance = writeValueInBin(_binBalances, _index, objectBalance.sub(_amount));
        } else if (_operation == Operations.REPLACE) {
            newBinBalance = writeValueInBin(_binBalances, _index, _amount);
        } else {
            revert("Invalid operation"); // Bad operation
        }

        return newBinBalance;
    }

    /*
     * @dev return value in _binValue at position _index
     * @param _binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param _index index at which to retrieve value
     * @return Value at given _index in _bin
     */
    function getValueInBin(uint256 _binValue, uint256 _index) internal pure returns (uint256) {
        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 rightShift = 256 - TYPES_BITS_SIZE * (_index + 1);
        return (_binValue >> rightShift) & mask;
    }

    /**
     * @dev return the updated _binValue after writing _amount at _index
     * @param _binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param _index Index at which to retrieve value
     * @param _amount Value to store at _index in _bin
     * @return Value at given _index in _bin
     */
    function writeValueInBin(
        uint256 _binValue,
        uint256 _index,
        uint256 _amount
    ) internal pure returns (uint256) {
        require(_amount < 2**TYPES_BITS_SIZE, "Amount to write in bin is too large");

        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 leftShift = 256 - TYPES_BITS_SIZE * (_index + 1);
        return (_binValue & ~(mask << leftShift)) | (_amount << leftShift);
    }
}

pragma solidity 0.6.5;

import "./SafeMathWithRequire.sol";


library ObjectLib {
    using SafeMathWithRequire for uint256;
    enum Operations {ADD, SUB, REPLACE}
    // Constants regarding bin or chunk sizes for balance packing
    uint256 constant TYPES_BITS_SIZE = 16; // Max size of each object
    uint256 constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256

    //
    // Objects and Tokens Functions
    //

    /**
     * @dev Return the bin number and index within that bin where ID is
     * @param _tokenId Object type
     * @return bin Bin number
     * @return index ID's index within that bin
     */
    function getTokenBinIndex(uint256 _tokenId) internal pure returns (uint256 bin, uint256 index) {
        bin = (_tokenId * TYPES_BITS_SIZE) / 256;
        index = _tokenId % TYPES_PER_UINT256;
        return (bin, index);
    }

    /**
     * @dev update the balance of a type provided in _binBalances
     * @param _binBalances Uint256 containing the balances of objects
     * @param _index Index of the object in the provided bin
     * @param _amount Value to update the type balance
     * @param _operation Which operation to conduct :
     *     Operations.REPLACE : Replace type balance with _amount
     *     Operations.ADD     : ADD _amount to type balance
     *     Operations.SUB     : Substract _amount from type balance
     */
    function updateTokenBalance(
        uint256 _binBalances,
        uint256 _index,
        uint256 _amount,
        Operations _operation
    ) internal pure returns (uint256 newBinBalance) {
        uint256 objectBalance = 0;
        if (_operation == Operations.ADD) {
            objectBalance = getValueInBin(_binBalances, _index);
            newBinBalance = writeValueInBin(_binBalances, _index, objectBalance.add(_amount));
        } else if (_operation == Operations.SUB) {
            objectBalance = getValueInBin(_binBalances, _index);
            newBinBalance = writeValueInBin(_binBalances, _index, objectBalance.sub(_amount));
        } else if (_operation == Operations.REPLACE) {
            newBinBalance = writeValueInBin(_binBalances, _index, _amount);
        } else {
            revert("Invalid operation"); // Bad operation
        }

        return newBinBalance;
    }

    /*
     * @dev return value in _binValue at position _index
     * @param _binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param _index index at which to retrieve value
     * @return Value at given _index in _bin
     */
    function getValueInBin(uint256 _binValue, uint256 _index) internal pure returns (uint256) {
        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 rightShift = 256 - TYPES_BITS_SIZE * (_index + 1);
        return (_binValue >> rightShift) & mask;
    }

    /**
     * @dev return the updated _binValue after writing _amount at _index
     * @param _binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param _index Index at which to retrieve value
     * @param _amount Value to store at _index in _bin
     * @return Value at given _index in _bin
     */
    function writeValueInBin(
        uint256 _binValue,
        uint256 _index,
        uint256 _amount
    ) internal pure returns (uint256) {
        require(_amount < 2**TYPES_BITS_SIZE, "Amount to write in bin is too large");

        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 leftShift = 256 - TYPES_BITS_SIZE * (_index + 1);
        return (_binValue & ~(mask << leftShift)) | (_amount << leftShift);
    }
}