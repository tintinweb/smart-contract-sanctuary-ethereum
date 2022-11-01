/**
 *Submitted for verification at Etherscan.io on 2022-11-01
*/

/*
 * Crypto stamp On-Chain Shop
 * Selling NFTs directly and handling shipping of connected physical assets
 *
 * Developed by capacity.at
 * for post.at
 */

// File: openzeppelin-solidity\contracts\token\ERC721\IERC721Receiver.sol

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

// File: node_modules\openzeppelin-solidity\contracts\introspection\IERC165.sol

pragma solidity ^0.5.0;

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\IERC721.sol

pragma solidity ^0.5.0;


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\IERC721Enumerable.sol

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\IERC721Metadata.sol

pragma solidity ^0.5.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: openzeppelin-solidity\contracts\token\ERC721\IERC721Full.sol

pragma solidity ^0.5.0;




/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract IERC721Full is IERC721, IERC721Enumerable, IERC721Metadata {
    // solhint-disable-previous-line no-empty-blocks
}

// File: openzeppelin-solidity\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.5.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity\contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// File: contracts\OracleRequest.sol

/*
Interface for requests to the rate oracle (for EUR/ETH)
Copy this to projects that need to access the oracle.
See rate-oracle project for implementation.
*/
pragma solidity ^0.5.0;


contract OracleRequest {

    uint256 public EUR_WEI; //number of wei per EUR

    uint256 public lastUpdate; //timestamp of when the last update occurred

    function ETH_EUR() public view returns (uint256); //number of EUR per ETH (rounded down!)

    function ETH_EURCENT() public view returns (uint256); //number of EUR cent per ETH (rounded down!)

}

// File: contracts\PricingStrategy.sol

pragma solidity ^0.5.0;


contract PricingStrategy {

    function adjustPrice(uint256 oldprice, uint256 remainingPieces) public view returns (uint256); //returns the new price

}

// File: contracts\Last100PricingStrategy.sol

/*

*/
pragma solidity ^0.5.0;




contract Last100PricingStrategy is PricingStrategy {

    /**
    calculates a new price based on the old price and other params referenced
    */
    function adjustPrice(uint256 _oldPrice, uint256 _remainingPieces) public view returns (uint256){
        if (_remainingPieces < 100) {
            return _oldPrice * 110 / 100;
        } else {
            return _oldPrice;
        }
    }
}

// File: contracts\OnChainShop.sol

/*
Implements an on-chain shop for crypto stamp
*/
pragma solidity ^0.5.0;








contract OnChainShop is IERC721Receiver {
    using SafeMath for uint256;

    IERC721Full internal cryptostamp;
    OracleRequest internal oracle;
    PricingStrategy internal pricingStrategy;

    address payable public beneficiary;
    address public shippingControl;
    address public tokenAssignmentControl;

    uint256 public priceEurCent;

    bool internal _isOpen = true;

    enum Status{
        Initial,
        Sold,
        ShippingSubmitted,
        ShippingConfirmed
    }

    event AssetSold(address indexed buyer, uint256 indexed tokenId, uint256 priceWei);
    event ShippingSubmitted(address indexed owner, uint256 indexed tokenId, string deliveryInfo);
    event ShippingFailed(address indexed owner, uint256 indexed tokenId, string reason);
    event ShippingConfirmed(address indexed owner, uint256 indexed tokenId);

    mapping(uint256 => Status) public deliveryStatus;

    constructor(OracleRequest _oracle,
        uint256 _priceEurCent,
        address payable _beneficiary,
        address _shippingControl,
        address _tokenAssignmentControl)
    public
    {
        oracle = _oracle;
        require(address(oracle) != address(0x0), "You need to provide an actual Oracle contract.");
        beneficiary = _beneficiary;
        require(address(beneficiary) != address(0x0), "You need to provide an actual beneficiary address.");
        tokenAssignmentControl = _tokenAssignmentControl;
        require(address(tokenAssignmentControl) != address(0x0), "You need to provide an actual tokenAssignmentControl address.");
        shippingControl = _shippingControl;
        require(address(shippingControl) != address(0x0), "You need to provide an actual shippingControl address.");
        priceEurCent = _priceEurCent;
        require(priceEurCent > 0, "You need to provide a non-zero price.");
        pricingStrategy = new Last100PricingStrategy();
    }

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only the current benefinicary can call this function.");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "tokenAssignmentControl key required for this function.");
        _;
    }

    modifier onlyShippingControl() {
        require(msg.sender == shippingControl, "shippingControl key required for this function.");
        _;
    }

    modifier requireOpen() {
        require(isOpen() == true, "This call only works when the shop is open.");
        _;
    }

    modifier requireCryptostamp() {
        require(address(cryptostamp) != address(0x0), "You need to provide an actual Cryptostamp contract.");
        _;
    }

    /*** Enable adjusting variables after deployment ***/

    function setCryptostamp(IERC721Full _newCryptostamp)
    public
    onlyBeneficiary
    {
        require(address(_newCryptostamp) != address(0x0), "You need to provide an actual Cryptostamp contract.");
        cryptostamp = _newCryptostamp;
    }

    function setPrice(uint256 _newPriceEurCent)
    public
    onlyBeneficiary
    {
        require(_newPriceEurCent > 0, "You need to provide a non-zero price.");
        priceEurCent = _newPriceEurCent;
    }

    function setBeneficiary(address payable _newBeneficiary)
    public
    onlyBeneficiary
    {
        beneficiary = _newBeneficiary;
    }

    function setOracle(OracleRequest _newOracle)
    public
    onlyBeneficiary
    {
        require(address(_newOracle) != address(0x0), "You need to provide an actual Oracle contract.");
        oracle = _newOracle;
    }

    function setPricingStrategy(PricingStrategy _newPricingStrategy)
    public
    onlyBeneficiary
    {
        require(address(_newPricingStrategy) != address(0x0), "You need to provide an actual PricingStrategy contract.");
        pricingStrategy = _newPricingStrategy;
    }

    function openShop()
    public
    onlyBeneficiary
    requireCryptostamp
    {
        _isOpen = true;
    }

    function closeShop()
    public
    onlyBeneficiary
    {
        _isOpen = false;
    }

    /*** Actual shopping functionality ***/

    // return true if shop is currently open for purchases.
    function isOpen()
    public view
    requireCryptostamp
    returns (bool)
    {
        return _isOpen;
    }

    // Calculate current asset price in wei.
    // Note: Price in EUR cent is available from public var getter priceEurCent().
    function priceWei()
    public view
    returns (uint256)
    {
        return priceEurCent.mul(oracle.EUR_WEI()).div(100);
    }

    // For buying a single asset, just send enough ether to this contract.
    function()
    external payable
    requireOpen
    {
        //get from eurocents to wei
        uint256 curPriceWei = priceWei();
        //update the price according to the strategy for the following buyer.
        uint256 remaining = cryptostamp.balanceOf(address(this));
        priceEurCent = pricingStrategy.adjustPrice(priceEurCent, remaining);

        require(msg.value >= curPriceWei, "You need to send enough currency to actually pay the item.");
        // Transfer the actual price to the beneficiary
        beneficiary.transfer(curPriceWei);
        // Find the next stamp and transfer it.
        uint256 tokenId = cryptostamp.tokenOfOwnerByIndex(address(this), 0);
        cryptostamp.safeTransferFrom(address(this), msg.sender, tokenId);
        emit AssetSold(msg.sender, tokenId, curPriceWei);
        deliveryStatus[tokenId] = Status.Sold;

        /*send back change money. last */
        if (msg.value > curPriceWei) {
            msg.sender.transfer(msg.value.sub(curPriceWei));
        }
    }

    /*** Handle physical shipping ***/

    // For token owner (after successful purchase): Request shipping.
    // _deliveryInfo is a postal address encrypted with a public key on the client side.
    function shipToMe(string memory _deliveryInfo, uint256 _tokenId)
    public
    requireOpen
    {
        require(cryptostamp.ownerOf(_tokenId) == msg.sender, "You can only request shipping for your own tokens.");
        require(deliveryStatus[_tokenId] == Status.Sold, "Shipping was already requested for this token or it was not sold by this shop.");
        emit ShippingSubmitted(msg.sender, _tokenId, _deliveryInfo);
        deliveryStatus[_tokenId] = Status.ShippingSubmitted;
    }

    // For shipping service: Mark shipping as completed/confirmed.
    function confirmShipping(uint256 _tokenId)
    public
    onlyShippingControl
    requireCryptostamp
    {
        deliveryStatus[_tokenId] = Status.ShippingConfirmed;
        emit ShippingConfirmed(cryptostamp.ownerOf(_tokenId), _tokenId);
    }

    // For shipping service: Mark shipping as failed/rejected (due to invalid address).
    function rejectShipping(uint256 _tokenId, string memory _reason)
    public
    onlyShippingControl
    requireCryptostamp
    {
        deliveryStatus[_tokenId] = Status.Sold;
        emit ShippingFailed(cryptostamp.ownerOf(_tokenId), _tokenId, _reason);
    }

    /*** Make sure currency or NFT doesn't get stranded in this contract ***/

    // Override ERC721Receiver to special-case receiving ERC721 tokens:
    // We will prevent accepting a cryptostamp from others,
    // so we can make sure that we only sell physically shippable items.
    // We make an exception for "beneficiary", in case we decide to increase its stock in the future.
    // Also, comment out all params that are in the interface but not actually used, to quiet compiler warnings.
    function onERC721Received(address /*_operator*/, address _from, uint256 /*_tokenId*/, bytes memory /*_data*/)
    public
    requireCryptostamp
    returns (bytes4)
    {
        require(_from == beneficiary, "Only the current benefinicary can send assets to the shop.");
        return this.onERC721Received.selector;
    }

    // If this contract gets a balance in some ERC20 contract after it's finished, then we can rescue it.
    function rescueToken(IERC20 _foreignToken, address _to)
    external
    onlyTokenAssignmentControl
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }
}