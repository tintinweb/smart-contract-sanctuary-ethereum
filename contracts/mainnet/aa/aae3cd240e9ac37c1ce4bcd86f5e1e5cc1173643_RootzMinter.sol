/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: RootzMinter.sol


pragma solidity ^0.8.0;




abstract contract ROOTZ {
    function mint(uint tokenID, address receiver) external{
    }
}

contract RootzMinter is Ownable {
    //token add
    ROOTZ tokenAddress = ROOTZ(0x2283b61C78Ad57dbe8069f486c771636faCD872e);

    address keyGenerator = 0x777Cb51D6f48636BC0910634B8455d18384737C0;
    address priceSetter = 0x90849f7C67b20785489c8b8f81fBbB4e91E262a8;

    //distros
    address payable receiver1 = payable(0x90849f7C67b20785489c8b8f81fBbB4e91E262a8);
    address payable receiver2 = payable(0xF6D8D0bd097f98b3ba6C2751bff376C3c1517113);

    uint8 receiver1royalty = 45;
    uint8 receiver2royalty = 55;

    //public mint enabled
    bool public isPublic;

    //public mint params
    uint256 public tokenPrice = 230000000000000000;
    uint256 public maxFree = 200;

    mapping(bytes32 => bool) usedCodes;

    
    function VerifyMessage(bytes32 _hashedMessage, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }
    
    function mint(uint256 tokenID, uint8 _v, bytes32 _r, bytes32 _s) external payable{
        //let msg
        bytes32 _hashedMessage = keccak256(bytes(Strings.toString(tokenID)));
        //req price
        require(msg.value >= tokenPrice || tokenID <= maxFree, "Send more ETH");
        //req asset is available
        require(isPublic || VerifyMessage(_hashedMessage, _v, _r, _s) == keyGenerator, "Bad code");
        //mint
        tokenAddress.mint(tokenID, msg.sender);

        //send tokens   
        (bool sent, bytes memory data) = receiver1.call{value: ((msg.value * receiver1royalty) / 100)}("");
        require(sent, "Failed to send Ether");
        (bool sent2, bytes memory data2) = receiver2.call{value: ((msg.value * receiver2royalty) / 100)}("");
        require(sent2, "Failed to send Ether");


    }

    //owner fns
    function setTokenAddress(address _tokenAddress) public onlyOwner{
        tokenAddress = ROOTZ(_tokenAddress);
    }
    function setKeyGenerator(address _keyGenerator) public onlyOwner{
        keyGenerator = _keyGenerator;
    }
    function setPublic(bool _isPublic) public onlyOwner{
        isPublic = _isPublic;
    }
    function setReceiver(address payable _receiver1, address payable _receiver2) external onlyOwner{
        receiver1 = _receiver1;
        receiver2 = _receiver2;
    }
    
    function setPriceSetter(address _tokenPriceSetter) external onlyOwner{
        priceSetter = _tokenPriceSetter;
    }

    function setPrice(uint256 _tokenPrice) external{
        require(msg.sender == priceSetter);
        tokenPrice = _tokenPrice;
    }
    
    function setMaxFree(uint256 _maxFree) external onlyOwner{
        maxFree = _maxFree;
    }
    
    function widthdraw(uint256 amount) public payable onlyOwner{
        (bool sent, bytes memory data) = receiver1.call{value: ((amount * receiver1royalty) / 100)}("");
        require(sent, "Failed to send Ether");
        (bool sent2, bytes memory data2) = receiver2.call{value: ((amount * receiver2royalty) / 100)}("");
        require(sent2, "Failed to send Ether");
    }
}