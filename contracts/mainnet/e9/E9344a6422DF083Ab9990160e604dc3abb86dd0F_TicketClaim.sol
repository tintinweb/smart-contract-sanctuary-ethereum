/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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

pragma solidity 0.8.7;

interface INonki {
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
}

interface IRegularTicket {
    function mint(address _to, uint256 _amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IPlatiumTicket {
    function mint(address _to, uint256 _amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract TicketClaim is Ownable {
    address public ticketNonkiAddress;

    mapping(address => bool) public isSpecialWallet;

    INonki public nonkiToken;
    IRegularTicket public regularTicket;
    IPlatiumTicket public platiumTicket;

    uint256 public maxRegularTicket;
    uint256 public maxPlatiumTicket;

    uint256 public nonkiPerRegularTicket;
    uint256 public nonkiPerPlatiumTicket;

    uint256 public ticketTotal;

    constructor () {
        maxRegularTicket = 3;
        maxPlatiumTicket = 2;

        nonkiPerRegularTicket = 450;
        nonkiPerPlatiumTicket = 1000;

        ticketTotal = 1111;
    }

    function getTicketRemaining() public view returns (uint256) {
        return ticketTotal - regularTicket.totalSupply() - platiumTicket.totalSupply();
    }

    function setTicketTotal(uint256 _total) public onlyOwner {
        ticketTotal = _total;
    }
 
    function setTicketNonkiAddress(address _address) public onlyOwner {
        ticketNonkiAddress = _address;
    }

    function setSpecialWallet(address _address) public onlyOwner {
        isSpecialWallet[_address] = true;
    }

    function setMaxTicketPerWallet(uint256 _regular, uint256 _platium) public onlyOwner {
        maxRegularTicket = _regular;
        maxPlatiumTicket = _platium;
    }

    function setNonkiPerTicket(uint256 _nonkiRegular, uint256 _nonkiPlatium) public onlyOwner {
        nonkiPerRegularTicket = _nonkiRegular;
        nonkiPerPlatiumTicket = _nonkiPlatium;
    }

    function setNonkiToken(address _nonkiToken) public onlyOwner {
        nonkiToken = INonki(_nonkiToken);
    }

    function setRegularTicket(address _regularTicket) public onlyOwner {
        regularTicket = IRegularTicket(_regularTicket);
    }

    function setPlatiumTicket(address _platiumTicket) public onlyOwner {
        platiumTicket = IPlatiumTicket(_platiumTicket);
    }

    function claimTickets(uint256 _regularAmount, uint256 _platiumAmount) public {
        uint256 numberOfRegularTickets = regularTicket.balanceOf(msg.sender) + _regularAmount;
        uint256 numberOfPlatiumTickets = platiumTicket.balanceOf(msg.sender) + _platiumAmount;

        require(getTicketRemaining() > 0, "Tickets reach to the limit");
        require(_regularAmount <= maxRegularTicket && _platiumAmount <= maxPlatiumTicket, "Can't claim tickets over max");

        require(numberOfRegularTickets <= maxRegularTicket && numberOfPlatiumTickets <= maxPlatiumTicket, "Can't claim tickets over max per wallet");
        require(_regularAmount > 0 || _platiumAmount > 0, "Can't claim 0");

        nonkiToken.transferFrom(msg.sender, ticketNonkiAddress, _regularAmount * nonkiPerRegularTicket * 10**18 + _platiumAmount * nonkiPerPlatiumTicket * 10**18);

        if(_regularAmount > 0) regularTicket.mint(msg.sender, _regularAmount);
        if(_platiumAmount > 0) platiumTicket.mint(msg.sender, _platiumAmount);
    }

    function claimUnlimited(uint256 _regularAmount, uint256 _platiumAmount) public {
        require(getTicketRemaining() > 0, "Tickets reach to the limit");
        require(isSpecialWallet[msg.sender], "Can't claim unlimited with this wallet");
        require(_regularAmount > 0 || _platiumAmount > 0, "Can't claim 0");

        nonkiToken.transferFrom(msg.sender, ticketNonkiAddress, _regularAmount * nonkiPerRegularTicket * 10**18 + _platiumAmount * nonkiPerPlatiumTicket * 10**18);

        if(_regularAmount > 0) regularTicket.mint(msg.sender, _regularAmount);
        if(_platiumAmount > 0) platiumTicket.mint(msg.sender, _platiumAmount);
    }

}