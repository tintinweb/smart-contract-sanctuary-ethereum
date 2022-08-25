// SPDX-License-Identifier: UNLICENSED

/*
 ___    ___    _____  ___    _     _  ___
(  _`\ |  _`\ (  _  )(  _`\ ( )   ( )(  _`\
| | ) || (_) )| ( ) || |_) )`\`\_/'/'| (_(_)
| | | )| ,  / | | | || ,__/'  `\ /'  `\__ \
| |_) || |\ \ | (_) || |       | |   ( )_) |
(____/'(_) (_)(_____)(_)       (_)   `\____)

Start your airdrop: https://dropys.com/

*/
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC1155 } from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract Dropys is Ownable {
    using SafeMath for uint256;

    uint256 public rate;
    uint256 public dropUnitPrice;
    uint256 public commission;

    mapping (string => uint256) public airdropFeeDiscount;

    event RateChanged(uint256 from, uint256 to);

    event TokenAirdrop(address indexed by, address indexed tokenAddress, uint256 totalTransfers);
    event EthAirdrop(address indexed by, uint256 totalTransfers, uint256 ethValue);
    event NFTAirdrop(address indexed by, address indexed tokenAddress, uint256 totalTransfers);

    event CommissionChanged(uint256 oldValue, uint256 newValue);
    event CommissionPaid(address indexed to, uint256 value);

    event ERC20TokensWithdrawn(address token, address sentTo, uint256 value);

    constructor() {
        rate = 50000000000000000;
        dropUnitPrice = 1e14;
        commission = 3;
    }

    /**
     * Allows for the distribution of Ether to be transferred to multiple recipients at
     * a time. This function only facilitates batch transfers of constant values (i.e., all recipients
     * will receive the same amount of tokens).
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _value The amount of tokens all addresses will receive.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNativeTokenS(address[] memory _recipients, uint256 _value, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        uint256 price = _recipients.length.mul(dropUnitPrice);
        uint256 totalCost = _value.mul(_recipients.length).add(price);

        require(
            msg.value >= totalCost,
            "Not enough ETH sent with transaction!"
        );

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        giveChange(totalCost);

        for(uint i=0; i<_recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                payable(_recipients[i]).transfer(_value);
            }
        }

        emit EthAirdrop(msg.sender, _recipients.length, _value.mul(_recipients.length));

        return true;
    }

    function _getTotalEthValue(uint256[] memory _values) internal pure returns(uint256) {
        uint256 totalVal = 0;

        for(uint i = 0; i < _values.length; i++) {
            totalVal = totalVal.add(_values[i]);
        }

        return totalVal;
    }

    /**
     * Allows for the distribution of Ether to be transferred to multiple recipients at
     * a time.
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _values The corresponding amounts that the recipients will receive
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNativeToken(address[] memory _recipients, uint256[] memory _values, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        require(_recipients.length == _values.length, "Total number of recipients and values are not equal");

        uint256 totalEthValue = _getTotalEthValue(_values);
        uint256 price = _recipients.length.mul(dropUnitPrice);
        uint256 totalCost = totalEthValue.add(price);

        require(
            msg.value >= totalCost,
            "Not enough ETH sent with transaction!"
        );

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        giveChange(totalCost);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0) && _values[i] > 0) {
                payable(_recipients[i]).transfer(_values[i]);
            }
        }

        emit EthAirdrop(msg.sender, _recipients.length, totalEthValue);

        return true;
    }


    /**
     * Allows for the distribution of an ERC20 token to be transferred to multiple recipients at
     * a time. This function only facilitates batch transfers of constant values (i.e., all recipients
     * will receive the same amount of tokens).
     *
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipients The list of addresses which will receive tokens.
     * @param _value The amount of tokens all addresses will receive.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropTokenS(address _addressOfToken,  address[] memory _recipients, uint256 _value, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        IERC20 token = IERC20(_addressOfToken);

        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                token.transferFrom(msg.sender, _recipients[i], _value);
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length);

        return true;
    }


    /**
     * Allows for the distribution of an ERC20 token to be transferred to multiple recipients at
     * a time. This function facilitates batch transfers of differing values (i.e., all recipients
     * can receive different amounts of tokens).
     *
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipients The list of addresses which will receive tokens.
     * @param _values The corresponding values of tokens which each address will receive.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropToken(address _addressOfToken,  address[] memory _recipients, uint256[] memory _values, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        IERC20 token = IERC20(_addressOfToken);
        require(_recipients.length == _values.length, "Total number of recipients and values are not equal");

        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0) && _values[i] > 0) {
                token.transferFrom(msg.sender, _recipients[i], _values[i]);
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length);

        return true;
    }

    /**
     * Allows for the distribution of an ERC721 token to be transferred to multiple recipients at
     * a time.
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _nftContract The NFT collection contract where tokens are sent from.
     * @param _startingTokenId The starting token id to begin incrementing from
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNftI(address[] memory _recipients, address _nftContract, uint256 _startingTokenId, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                IERC721(_nftContract).safeTransferFrom(msg.sender, _recipients[i], _startingTokenId + i);
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit NFTAirdrop(msg.sender, _nftContract, _recipients.length);
        return true;
    }

    /**
     * Allows for the distribution of an ERC721 token to be transferred to multiple recipients at
     * a time.
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _nftContract The NFT collection contract where tokens are sent from.
     * @param _tokenIds The list of ids being sent.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNft(address[] memory _recipients, address _nftContract, uint256[] memory _tokenIds, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                IERC721(_nftContract).safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i]);
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit NFTAirdrop(msg.sender, _nftContract, _recipients.length);
        return true;
    }

    /**
     * Allows for the distribution of an ERC721 token to be transferred to multiple recipients at
     * a time.
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _nftContract The NFT collection contract where tokens are sent from.
     * @param _tokenId The id being sent.
     * @param _amount The amount being sent.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNftsS(address[] memory _recipients, address _nftContract, uint256 _tokenId, uint256 _amount, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        uint256 price = _recipients.length.mul(dropUnitPrice);

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                IERC1155(_nftContract).safeTransferFrom(msg.sender, _recipients[i], _tokenId, _amount, "");
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit NFTAirdrop(msg.sender, _nftContract, _recipients.length);
        return true;
    }

    /**
     * Allows for the distribution of an ERC721 token to be transferred to multiple recipients at
     * a time.
     *
     * @param _recipients The list of addresses which will receive tokens.
     * @param _nftContract The NFT collection contract where tokens are sent from.
     * @param _tokenIds The list of ids being sent.
     * @param _amounts The amounts being sent.
     * @param _affiliateAddress The affiliate address that is paid a commission.affiliated with a partner, they will provide this code so that
     * the parter is paid commission.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function dropysAirdropNfts(address[] memory _recipients, address _nftContract, uint256[] memory _tokenIds, uint256[] memory _amounts, address _affiliateAddress, string memory _discountCode) public payable returns(bool) {
        uint256 price = _recipients.length.mul(dropUnitPrice);

        if (!stringsAreEqual(_discountCode, "") && airdropFeeDiscount[_discountCode] > 0) {
            price = price * airdropFeeDiscount[_discountCode] / 100;
        }

        require(
            msg.value >= price,
            "Not enough ETH sent with transaction!"
        );

        giveChange(price);

        for(uint i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
                IERC1155(_nftContract).safeTransferFrom(msg.sender, _recipients[i], _tokenIds[i], _amounts[i], "");
            }
        }

        distributeCommission(_recipients.length, _affiliateAddress, _discountCode);

        emit NFTAirdrop(msg.sender, _nftContract, _recipients.length);
        return true;
    }

    /**
     * Allows for the price of drops to be changed by the owner of the contract. Any attempt made by
     * any other account to invoke the function will result in a loss of gas and the price will remain
     * untampered.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function setRate(uint256 _newRate) public onlyOwner returns(bool) {
        require(
            _newRate != rate
            && _newRate > 0
        );

        emit RateChanged(rate, _newRate);

        rate = _newRate;
        uint256 eth = 1 ether;
        dropUnitPrice = eth.div(rate);

        return true;
    }

    /**
     * Allows users to query the discount for a code. This is useful to verify that a discount has been set.
     *
     * @param _discountCode The code associated with the discount.
     *
     * @return fee The discount for the code.
     * */
    function getDiscountForCode(string memory _discountCode) public view returns(uint256 fee) {
        if (airdropFeeDiscount[_discountCode] > 0) {
            return airdropFeeDiscount[_discountCode];
        }
        return 0;
    }

    /**
     * Allows the owner of the contract to set a discount for a specified address.
     *
     * @param _discountCode The code that will receive the discount.
     * @param _discount The discount that will be applied.
     *
     * @return success True if function executes successfully, false otherwise.
     * */
    function setAirdropFeeDiscount(string memory _discountCode, uint256 _discount) public onlyOwner returns(bool success) {
        airdropFeeDiscount[_discountCode] = _discount;
        return true;
    }

    /**
    * Send the owner and affiliates commissions.
    **/
    function distributeCommission(uint256 _drops, address _affiliateAddress, string memory _discountCode) internal {
        uint256 price = dropUnitPrice;

        if (!stringsAreEqual(_discountCode, "") && airdropFeeDiscount[_discountCode] > 0) {
            price = price * airdropFeeDiscount[_discountCode] / 100;
        }

        if (_affiliateAddress != address(0) && _affiliateAddress != msg.sender) {
            uint256 profitSplit = _drops.mul(price).div(commission);
            uint256 remaining = _drops.mul(price).sub(profitSplit);

            payable(owner()).transfer(remaining);
            payable(_affiliateAddress).transfer(profitSplit);

            emit CommissionPaid(_affiliateAddress, profitSplit);
        } else {
            payable(owner()).transfer(_drops.mul(price));
        }
    }

    /**
     * Allows for any ERC20 tokens which have been mistakenly  sent to this contract to be returned
     * to the original sender by the owner of the contract. Any attempt made by any other account
     * to invoke the function will result in a loss of gas and no tokens will be transferred out.
     *
     * @param _addressOfToken The contract address of an ERC20 token.
     * @param _recipient The address which will receive tokens.
     * @param _value The amount of tokens to refund.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function withdrawERC20Tokens(address _addressOfToken,  address _recipient, uint256 _value) public onlyOwner returns(bool){
        require(
            _addressOfToken != address(0)
            && _recipient != address(0)
            && _value > 0
        );

        IERC20 token = IERC20(_addressOfToken);
        token.transfer(_recipient, _value);

        emit ERC20TokensWithdrawn(_addressOfToken, _recipient, _value);

        return true;
    }

    /**
    * Used to give change to users who accidentally send too much ETH to payable functions.
    *
    * @param _price The service fee the user has to pay for function execution.
    **/
    function giveChange(uint256 _price) internal {
        if (msg.value > _price) {
            uint256 change = msg.value.sub(_price);
            payable(msg.sender).transfer(change);
        }
    }

    /**
     * Allows for the affiliate commission to be changed by the owner of the contract. Any attempt made by
     * any other account to invoke the function will result in a loss of gas and the price will remain
     * untampered.
     *
     * @return true if function executes successfully, false otherwise.
     * */
    function setCommission(uint256 _newCommission) public onlyOwner returns(bool) {
        require(
            _newCommission != commission
        );

        emit CommissionChanged(commission, _newCommission);

        commission = _newCommission;

        return true;
    }

    /**
     * Allows for the allowance of a token from its owner to this contract to be queried.
     *
     * As part of the ERC20 standard all tokens which fall under this category have an allowance
     * function which enables owners of tokens to allow (or give permission) to another address
     * to spend tokens on behalf of the owner. This contract uses this as part of its protocol.
     * Users must first give permission to the contract to transfer tokens on their behalf, however,
     * this does not mean that the tokens will ever be transferrable without the permission of the
     * owner. This is a security feature which was implemented on this contract. It is not possible
     * for the owner of this contract or anyone else to transfer the tokens which belong to others.
     *
     * @param _addr The address of the token's owner.
     * @param _addressOfToken The contract address of the ERC20 token.
     *
     * @return The ERC20 token allowance from token owner to this contract.
     * */
    function getTokenAllowance(address _addr, address _addressOfToken) public view returns(uint256) {
        IERC20 token = IERC20(_addressOfToken);
        return token.allowance(_addr, address(this));
    }

    /**
    * Checks if two strings are the same.
    *
    * @param _a String 1
    * @param _b String 2
    *
    * @return True if both strings are the same. False otherwise.
    **/
    function stringsAreEqual(string memory _a, string memory _b) internal pure returns(bool) {
        bytes32 hashA = keccak256(abi.encodePacked(_a));
        bytes32 hashB = keccak256(abi.encodePacked(_b));
        return hashA == hashB;
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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