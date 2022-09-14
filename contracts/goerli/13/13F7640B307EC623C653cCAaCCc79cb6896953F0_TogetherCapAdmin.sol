// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "AssetRegistry.sol";
import "IssuerRegistry.sol";
import "InvestorRegistry.sol";
import "Ownable.sol";
import "TCapSecurityRegSToken.sol";
import "StringUtils.sol";


contract TogetherCapAdmin is Ownable {

    AssetRegistry private assetRegistry;
    IssuerRegistry private issuerRegistry;
    InvestorRegistry private investorRegistry;

    struct TokenReference {
        address tokenAddress;
        string assetSymbol;
        address issuerAddress;
    }

    struct TokenCreationInput {
        string _assetId;
        string _name;
        string _symbol;
        uint _maxSupply;
        address payable _tcapRevAdmin;
        address payable _issuer;
        uint _faceValue;
        address _investorRegistryAddress;
        address _assetRegistryAddress;
        address _issuerRegistryAddress;
        string regType;
    }

    mapping(string => TokenReference) tokens;

    event TokenMintingComplete(address tokenAddress, string tokenSymbol, uint256 amount);
    event TokenReleasedForSale(address tokenAddress, string tokenSymbol);


    function deployTokenForAsset(TokenCreationInput memory _tokenData) uniqueAssetId(_tokenData._assetId) external onlyOwner returns (address) {
        if (StringUtils.equal(_tokenData.regType, "RegS")) {
            TCapSecurityRegSToken regSToken = new TCapSecurityRegSToken(_tokenData._assetId,
                _tokenData._name,
                _tokenData._symbol,
                _tokenData._maxSupply,
                _tokenData._tcapRevAdmin,
                _tokenData._issuer,
                _tokenData._faceValue,
                _tokenData._investorRegistryAddress,
                _tokenData._assetRegistryAddress,
                _tokenData._issuerRegistryAddress);
            tokens[_tokenData._assetId].assetSymbol = _tokenData._symbol;
            tokens[_tokenData._assetId].issuerAddress = _tokenData._issuer;
            tokens[_tokenData._assetId].tokenAddress = address(regSToken);
            return address(regSToken);
        } else {
            revert("Only RegS is supported");
        }
    }

    function tokenOwner(string calldata _assetId) external view returns (address){
        TCapSecurityRegSToken token = TCapSecurityRegSToken(tokens[_assetId].tokenAddress);
        return token.owner();
    }

    function tcapAdminOwner() external view returns (address){
        return owner();
    }

    function balanceOf(string calldata _assetId, address _addressToCheck) external view returns (uint256) {
        TCapSecurityRegSToken token = TCapSecurityRegSToken(tokens[_assetId].tokenAddress);
        return token.balanceOf(_addressToCheck);
    }

    function totalMintedTokens(string calldata _assetId) external view returns (uint256){
        TCapSecurityRegSToken token = TCapSecurityRegSToken(tokens[_assetId].tokenAddress);
        return token.totalSupply();
    }


    function mintTokens(string calldata _assetId, uint256 amount) external onlyOwner {
        TCapSecurityRegSToken token = TCapSecurityRegSToken(tokens[_assetId].tokenAddress);
        token.mint(tokens[_assetId].issuerAddress, amount);
        emit TokenMintingComplete(tokens[_assetId].tokenAddress, _assetId, amount);
    }

    function releaseTokens(string calldata _assetId) external onlyOwner {
        TCapSecurityRegSToken token = TCapSecurityRegSToken(tokens[_assetId].tokenAddress);
        token.releaseTokens();
        emit TokenReleasedForSale(tokens[_assetId].tokenAddress, _assetId);
    }

    function burnTokens(string calldata _assetId, uint256 amount) external onlyOwner {
        TCapSecurityRegSToken token = TCapSecurityRegSToken(tokens[_assetId].tokenAddress);
        token.burn(tokens[_assetId].issuerAddress, amount);

    }

    function pauseTransfer(string calldata _assetId) external onlyOwner {
        TCapSecurityRegSToken token = TCapSecurityRegSToken(tokens[_assetId].tokenAddress);
        token.pause();

    }

    function unpauseTransfer(string calldata _assetId) external onlyOwner {
        TCapSecurityRegSToken token = TCapSecurityRegSToken(tokens[_assetId].tokenAddress);
        token.unpause();
    }

    function faceValue(string calldata _assetId) external view returns (uint){
        TCapSecurityRegSToken token = TCapSecurityRegSToken(tokens[_assetId].tokenAddress);
        return token.tokenFaceValue();
    }

    modifier uniqueAssetId(string memory _assetId){
        bytes memory assetSymbolBytes = bytes(tokens[_assetId].assetSymbol);
        require(assetSymbolBytes.length == 0, "Duplicate Asset Id, cannot create a token");
        _;
    }


}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "Ownable.sol";
import "Version.sol";

/*
@@author Satish Terala
Registry service to hold assets registered with tcap
*/

contract AssetRegistry is Ownable, Version {
    //capture the basic information required for the asset.
    struct Asset {
        address issuer;
        string assetSymbol;
        string assetShortURL;
        string assetId;
    }

    uint[] private assetIds;
    mapping(string => Asset) private records;

    event AssetDeletedFromRegistry(address indexed owner, string indexed assetSymbol);
    event AssetAddedToRegistry(string indexed assetId, string indexed assetSymbol, address owner);

    function addAsset(string calldata _assetSymbol, string calldata _assetShortURL, address _issuer, string calldata _assetId) assetNotExists(_assetId) external onlyOwner returns (bool){
        records[_assetId].assetId = _assetId;
        records[_assetId].issuer = _issuer;
        records[_assetId].assetSymbol = _assetSymbol;
        records[_assetId].assetShortURL = _assetShortURL;
        emit AssetAddedToRegistry(_assetId, _assetSymbol, _issuer);
        return true;

    }

    function removeAsset(string calldata _assetId) assetExists(_assetId) external onlyOwner {
        bytes memory assetSymBytes = bytes(records[_assetId].assetSymbol);
        if (assetSymBytes.length != 0) {
            address owner = records[_assetId].issuer;
            string memory symbol = records[_assetId].assetSymbol;
            delete records[_assetId];
            emit AssetDeletedFromRegistry(owner, symbol);
        }

    }

    function getAssetIssuer(string calldata _assetId) assetExists(_assetId) public view returns (address){
        return records[_assetId].issuer;
    }

    function getAssetSymbol(string calldata _assetId) assetExists(_assetId) public view returns (string memory){
        return records[_assetId].assetSymbol;
    }

    function getAssetShortURL(string calldata _assetId) assetExists(_assetId) public view returns (string memory){
        return records[_assetId].assetShortURL;
    }

    function assetIdExists(string calldata _assetId) view public returns (bool){
        bytes memory assetSymBytes = bytes(records[_assetId].assetSymbol);
        return assetSymBytes.length > 0;
    }



    modifier assetExists(string calldata _assetId) {
        bytes memory assetSymBytes = bytes(records[_assetId].assetSymbol);
        require(assetSymBytes.length > 0, "Invalid asset id");
        _;
    }

    modifier assetNotExists(string calldata _assetId) {
        bytes memory assetSymBytes = bytes(records[_assetId].assetSymbol);
        require(assetSymBytes.length == 0, "Duplicate asset Id");
        _;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "Ownable.sol";

contract Version is Ownable {

    string private  version = "0.0.1";

    function setContractVersion(string calldata _version) public onlyOwner {
        version = _version;
    }

    function getContractVersion() public returns (string memory){
        return version;
    }


}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "Ownable.sol";
import "CertificateHolder.sol";


/*
* @author Satish Terala
*@@dev Registry implementation that holds the list of authorized issuers.
*/
contract IssuerRegistry is Ownable {
    struct Issuer {
        address payable issuerAddress;
        bool isKYCComplete;
        string issuerName;
    }

    mapping(address => Issuer)issuers;
    event IssuerAddedToRegistry(address _investorAddress);
    event IssuerRemovedFromRegistry(address indexed issuerAddress);

    function addIssuerToRegistry(address payable _issuerAddress, bool _isKycComplete, string calldata _name) external onlyOwner() {
        issuers[_issuerAddress].issuerName = _name;
        issuers[_issuerAddress].issuerAddress = _issuerAddress;
        issuers[_issuerAddress].isKYCComplete = _isKycComplete;
        emit IssuerAddedToRegistry(_issuerAddress);
    }

    function issuerExists(address _issuerAddress) public view returns (bool){
        return issuers[_issuerAddress].issuerAddress != address(0);
    }

    function deleteIssuerFromRegistry(address _issuerAddress) external onlyOwner onlyIfIssuerExistsInRegistry(_issuerAddress) {
        delete issuers[_issuerAddress];
        emit IssuerRemovedFromRegistry(_issuerAddress);
    }



    function updateKYCStatusForIssuer(address _issuerAddress, bool _kycStatus) public onlyOwner onlyIfIssuerExistsInRegistry(_issuerAddress) {
        issuers[_issuerAddress].isKYCComplete = _kycStatus;
    }

    function issuerKYCStatus(address _issuerAddress) external view onlyIfIssuerExistsInRegistry(_issuerAddress)  returns (bool){
        return issuers[_issuerAddress].isKYCComplete;
    }


    modifier onlyIfIssuerExistsInRegistry(address _issuerAddress){
        require(issuerExists(_issuerAddress) == true, "Unknown Issuer");
        _;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";

contract CertificateHolder is Ownable {

    struct Cert {
        address recipient;
        bool confirmed;
    }

    mapping(bytes32 => Cert)public certs;
    bytes32[] public certLists;

    function isCert(bytes32 cert)  view internal returns (bool) {
        if (cert == 0) return false;
        return certs[cert].recipient != address(0);
    }

    function createCert(bytes32 cert, address recipient) internal onlyOwner {
        require(recipient != address(0),"recipient cannot be zero address");
        require(!isCert(cert));
        Cert storage c = certs[cert];
        c.recipient = recipient;
        c.confirmed =true;
        certLists.push(cert);
    }


//    function confirmCert(bytes32 cert,address recipient) public onlyOwner{
//        require(certs[cert].recipient == msg.sender);
//        require(certs[cert].confirmed == false);
//        certs[cert].confirmed = true;
//
//    }

    function isUserCertified(bytes32 cert, address user) internal view returns (bool){
        if (!isCert(cert)) return false;
        if (certs[cert].recipient != user) return false;
        return certs[cert].confirmed;
    }

    function removeCertificate(bytes32 cert) internal  onlyOwner{
        require(cert != 0,"Invalid certificate to remove");
        delete certs[cert];

    }

    function updateCertificate(bytes32 _newCert,bytes32 _oldCert) internal {
        require(_newCert != 0,"Invalid certificate to update");
        address existing_recipient=certs[_oldCert].recipient;
        removeCertificate(_oldCert);
        createCert(_newCert,existing_recipient);

}


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "SafeMath.sol";
import "StringUtils.sol";
import "Ownable.sol";
import "CertificateHolder.sol";



/*
Registry that contains the investors and their KYC status.
This is only a registry and does not contain the balances.
An Investor's status is maintained by the KYC status and the certificate issued based on the KYC json that was issued.
Any authentication requires that the investor send in his KYC Certificate along with the address.
@author Satish Terala
*/
contract InvestorRegistry is Ownable {

    struct Investor {
        address payable investorAddress;
        bool isKYCComplete;
        string domicileCountry;
    }

    mapping(address => Investor)investors;

    event InvestorAddedToRegistry(address _investorAddress);
    event InvestorRemovedFromRegistry(address _investorAddress);

    function addInvestorToRegistry(address payable _investorAddress, bool _isKycComplete,string calldata _domicileCountry) external onlyOwner() {
        investors[_investorAddress].investorAddress = _investorAddress;
        investors[_investorAddress].isKYCComplete = _isKycComplete;
        investors[_investorAddress].domicileCountry = _domicileCountry;
        emit InvestorAddedToRegistry(_investorAddress);
    }

    function isThisRegSEnabledInvestor(address _investorAddress) onlyIfInvestorExistsInRegistry(_investorAddress) onlyOwner public returns (bool){
        string memory investorCurrentDomicile = investors[_investorAddress].domicileCountry;
        string memory notAllowedCountry = "USA";
        if (!StringUtils.equal(investorCurrentDomicile, notAllowedCountry) && investors[_investorAddress].isKYCComplete) {
            return true;
        }
        return false;
    }

    function removeInvestorFromRegistry(address _investorAddress) public onlyOwner onlyIfInvestorExistsInRegistry(_investorAddress) {
        delete investors[_investorAddress];
        emit InvestorRemovedFromRegistry(_investorAddress);
    }

    function updateKYCStatusForInvestor(address _investorAddress, bool _kycStatus) public onlyOwner onlyIfInvestorExistsInRegistry(_investorAddress) {
        investors[_investorAddress].isKYCComplete = _kycStatus;
    }

    function updateDomicileCountryForInvestor(address _investorAddress, string calldata _domicile) public onlyOwner onlyIfInvestorExistsInRegistry(_investorAddress) {
        investors[_investorAddress].domicileCountry = _domicile;
    }

    function investorExists(address _investorAddress) view public onlyOwner returns (bool){
        return investors[_investorAddress].investorAddress != address(0);
    }

    function investorDomicile(address _investorAddress) external view onlyIfInvestorExistsInRegistry(_investorAddress) onlyOwner returns (string memory){
        return investors[_investorAddress].domicileCountry;
    }

    function investorKYCStatus(address _investorAddress) external view onlyIfInvestorExistsInRegistry(_investorAddress) onlyOwner returns (bool){
        return investors[_investorAddress].isKYCComplete;
    }

    modifier onlyIfInvestorExistsInRegistry(address _investorAddress) {
        require(investorExists(_investorAddress) == true, "Unknown investor");
        _;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library StringUtils {
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) internal returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) internal returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) internal returns (int)
    {
    	bytes memory h = bytes(_haystack);
    	bytes memory n = bytes(_needle);
    	if(h.length < 1 || n.length < 1 || (n.length > h.length))
    		return -1;
    	else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
    		return -1;
    	else
    	{
    		uint subindex = 0;
    		for (uint i = 0; i < h.length; i ++)
    		{
    			if (h[i] == n[0]) // found the first char of b
    			{
    				subindex = 1;
    				while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
    				{
    					subindex++;
    				}
    				if(subindex == n.length)
    					return int(i);
    			}
    		}
    		return -1;
    	}
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "TCapSecurityToken.sol";

contract TCapSecurityRegSToken is TCapSecurityToken {

    constructor(string memory _assetId,
        string memory _name,
        string memory _symbol,
        uint _maxSupply,
        address payable _tcapOperationalAdmin,
        address payable _issuer,
        uint _faceValue,
        address _investorRegistry,
        address _assetRegistryAddress,
        address _issuerRegistryAddress
)
    TCapSecurityToken(_assetId, _name, _symbol, _maxSupply, _tcapOperationalAdmin, _issuer, _faceValue, _investorRegistry,_assetRegistryAddress,_issuerRegistryAddress){
    }

    ///Methods to allow issuers buy tokens
    function buy() payable override public onlyAfterTokensReleased() validDomicile(msg.sender) {
        super.buy();
    }

    function runPreTransferChecks(address from, address to) internal override {
    }


    function runPostTransferNotifications(address from, address to, uint256 amount) internal override {
    }

    modifier validDomicile(address _buyerAddress) {
        require(investorRegistry.isThisRegSEnabledInvestor(_buyerAddress) == true, "Not a valid REG-S token investor,Domicile is not outside US ");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "ITCapToken.sol";
import "InvestorRegistry.sol";
import "IssuerRegistry.sol";
import "AssetRegistry.sol";
import "Ownable.sol";
import "ERC20.sol";
import "ERC20Snapshot.sol";
import "ERC20Pausable.sol";
import "ERC20Burnable.sol";
import "ERC20Capped.sol";
import "Version.sol";


abstract contract TCapSecurityToken is ITCapToken, ERC20Capped, ERC20Snapshot, ERC20Pausable, ERC20Burnable, Ownable, Version {

    string assetId;
    address payable private tcapOperationalAdmin;
    address payable private issuer;
    uint private price;
    uint private faceValue;
    bool private released;
    bool private initialTokenOfferingEnded;
    uint public availableTokens;
    InvestorRegistry internal investorRegistry;
    AssetRegistry internal assetRegistry;
    IssuerRegistry internal issuerRegistry;

    //uint public maxPurchase;
    //uint public minPurchase;


    struct MappingUnit {
        bool exists;
        uint index;
    }
    //contains address indexes in _investors array for optimized lookup.
    mapping(address => MappingUnit) private _investorIndexes;
    address[] private investors;

    event PaymentReceived(address from, uint256 amount);


    constructor(string memory _assetId,
        string memory _name,
        string memory _symbol,
        uint _maxSupply,
        address payable _tcapOperationalAdmin,
        address payable _issuer,
        uint _faceValue,
        address _investorRegistryAddress,
        address _assetRegistryAddress,
        address _issuerRegistryAddress
    ) ERC20(_name, _symbol) ERC20Capped(_maxSupply) {

        assetId = _assetId;
        tcapOperationalAdmin = _tcapOperationalAdmin;
        issuer = _issuer;
        faceValue = _faceValue;
        released = false;
        investorRegistry = InvestorRegistry(_investorRegistryAddress);
        assetRegistry = AssetRegistry(_assetRegistryAddress);
        issuerRegistry = IssuerRegistry(_issuerRegistryAddress);

    }

    /**
    * Tokens are released into ICO offering only after this is set to true.
    **/
    function releaseTokens() external onlyOwner {
        released = true;
    }

    function endInitialTokenOfferingPeriod() external onlyOwner {
        initialTokenOfferingEnded = true;
    }

    /**
    * @dev External mint method after a token ccontract has been deployed to allow for minting of tokens for the issuer by TogetherCap.
    * Minting of the tokens will not exceed capped limit set in the token constructor.
    */
    function mint(address account, uint256 amount) external onlyOwner {
        //check if the issuer exists in issuerRegistry
        require(issuerRegistry.issuerExists(account), "Invalid issuer,not registered in Tcap Issuer Registry");
        //check if the owner of the assset is the issuer.require
        address assetOwner = assetRegistry.getAssetIssuer(assetId);
        require(assetOwner == account, "Issuer is not same as the asset owner.");
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped) {
        ERC20Capped._mint(account, amount);
    }


    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }


    /*
    *@dev external burn method to burn a set of tokens from an issuers account.
    */
    function burn(address account, uint256 amount) public onlyOwner {
        ERC20._burn(account, amount);
    }


    ///Methods to allow issuers buy tokens
    function buy() payable public virtual onlyAfterTokensReleased() {
        require(msg.value % price == 0, "Have to pay a multiple of price");
        uint quantity = msg.value / price;
        require(quantity <= availableTokens, "Not enough tokens left for sale");
        super.transfer(msg.sender, quantity);

    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Pausable, ERC20, ERC20Snapshot) {
        //check if a particular transfer is allowed. Either amount exceeds the number of tokens an address is allowed to hold
        super._beforeTokenTransfer(from, to, amount);
        runPreTransferChecks(from, to);

    }


    /**
  * @dev after token transfer => update list/mapping of addresses with
        *
    */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if (balanceOf(to) == amount && !_investorIndexes[to].exists) {
            //first time seeing this investor, so add them to the mapping
            investors.push(to);
            _investorIndexes[to] = MappingUnit(true, investors.length - 1);
        }
        if (balanceOf(from) == 0 && _investorIndexes[from].exists) {
            uint index = _investorIndexes[from].index;
            investors[index] = investors[investors.length - 1];
            investors.pop();
            delete _investorIndexes[from];
        }
        runPostTransferNotifications(from, to, amount);
    }

    function tokenFaceValue() public view returns (uint){
        return faceValue;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account);
    }


    function runPreTransferChecks(address from, address to) internal virtual;


    function runPostTransferNotifications(address from, address to, uint256 amount) internal virtual;


    function snapshot() external onlyOwner returns (uint256) {
        return _snapshot();
    }

    function getCurrentSnapshotId() view external onlyOwner returns (uint256){
        return _getCurrentSnapshotId();
    }


    function getAllCurrentInvestors() view external onlyOwner returns (address [] memory){
        return investors;
    }

    modifier onlyIssuer(){
        require(msg.sender == issuer, "Only issuers can transfer");
        _;
    }

    modifier onlyAfterTokensReleased(){
        require(released == true, "Tokens have to be released for public purchase");
        _;
    }

    modifier onlyBeforeTokensReleased(){
        require(released == false, "Can only be called before tokens have been released");
        _;
    }

    modifier onlyAfterInitialTokenOfferingEnded(){
        require(initialTokenOfferingEnded == true, "Initial Token offering period has ended");
        _;
    }

    modifier onlyBeforeInitialTokenOfferingEnds(){
        require(initialTokenOfferingEnded == false, "Requires initial token offering be open");
        _;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ITCapToken  {

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/ERC20Snapshot.sol)

pragma solidity ^0.8.0;

import "ERC20.sol";
import "Arrays.sol";
import "Counters.sol";

/**
 * @dev This contract extends an ERC20 token with a snapshot mechanism. When a snapshot is created, the balances and
 * total supply at the time are recorded for later access.
 *
 * This can be used to safely create mechanisms based on token balances such as trustless dividends or weighted voting.
 * In naive implementations it's possible to perform a "double spend" attack by reusing the same balance from different
 * accounts. By using snapshots to calculate dividends or voting power, those attacks no longer apply. It can also be
 * used to create an efficient ERC20 forking mechanism.
 *
 * Snapshots are created by the internal {_snapshot} function, which will emit the {Snapshot} event and return a
 * snapshot id. To get the total supply at the time of a snapshot, call the function {totalSupplyAt} with the snapshot
 * id. To get the balance of an account at the time of a snapshot, call the {balanceOfAt} function with the snapshot id
 * and the account address.
 *
 * NOTE: Snapshot policy can be customized by overriding the {_getCurrentSnapshotId} method. For example, having it
 * return `block.number` will trigger the creation of snapshot at the beginning of each new block. When overriding this
 * function, be careful about the monotonicity of its result. Non-monotonic snapshot ids will break the contract.
 *
 * Implementing snapshots for every block using this method will incur significant gas costs. For a gas-efficient
 * alternative consider {ERC20Votes}.
 *
 * ==== Gas Costs
 *
 * Snapshots are efficient. Snapshot creation is _O(1)_. Retrieval of balances or total supply from a snapshot is _O(log
 * n)_ in the number of snapshots that have been created, although _n_ for a specific account will generally be much
 * smaller since identical balances in subsequent snapshots are stored as a single entry.
 *
 * There is a constant overhead for normal ERC20 transfers due to the additional snapshot bookkeeping. This overhead is
 * only significant for the first transfer that immediately follows a snapshot for a particular account. Subsequent
 * transfers will have normal cost until the next snapshot, and so on.
 */

abstract contract ERC20Snapshot is ERC20 {
    // Inspired by Jordi Baylina's MiniMeToken to record historical balances:
    // https://github.com/Giveth/minimd/blob/ea04d950eea153a04c51fa510b068b9dded390cb/contracts/MiniMeToken.sol

    using Arrays for uint256[];
    using Counters for Counters.Counter;

    // Snapshotted values have arrays of ids and the value corresponding to that id. These could be an array of a
    // Snapshot struct, but that would impede usage of functions that work on an array.
    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping(address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;

    // Snapshot ids increase monotonically, with the first value being 1. An id of 0 is invalid.
    Counters.Counter private _currentSnapshotId;

    /**
     * @dev Emitted by {_snapshot} when a snapshot identified by `id` is created.
     */
    event Snapshot(uint256 id);

    /**
     * @dev Creates a new snapshot and returns its snapshot id.
     *
     * Emits a {Snapshot} event that contains the same id.
     *
     * {_snapshot} is `internal` and you have to decide how to expose it externally. Its usage may be restricted to a
     * set of accounts, for example using {AccessControl}, or it may be open to the public.
     *
     * [WARNING]
     * ====
     * While an open way of calling {_snapshot} is required for certain trust minimization mechanisms such as forking,
     * you must consider that it can potentially be used by attackers in two ways.
     *
     * First, it can be used to increase the cost of retrieval of values from snapshots, although it will grow
     * logarithmically thus rendering this attack ineffective in the long term. Second, it can be used to target
     * specific accounts and increase the cost of ERC20 transfers for them, in the ways specified in the Gas Costs
     * section above.
     *
     * We haven't measured the actual numbers; if this is something you're interested in please reach out to us.
     * ====
     */
    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _getCurrentSnapshotId();
        emit Snapshot(currentId);
        return currentId;
    }

    /**
     * @dev Get the current snapshotId
     */
    function _getCurrentSnapshotId() internal view virtual returns (uint256) {
        return _currentSnapshotId.current();
    }

    /**
     * @dev Retrieves the balance of `account` at the time `snapshotId` was created.
     */
    function balanceOfAt(address account, uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }

    /**
     * @dev Retrieves the total supply at the time `snapshotId` was created.
     */
    function totalSupplyAt(uint256 snapshotId) public view virtual returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }

    // Update balance and/or total supply snapshots before the values are modified. This is implemented
    // in the _beforeTokenTransfer hook, which is executed for _mint, _burn, and _transfer operations.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) {
            // mint
            _updateAccountSnapshot(to);
            _updateTotalSupplySnapshot();
        } else if (to == address(0)) {
            // burn
            _updateAccountSnapshot(from);
            _updateTotalSupplySnapshot();
        } else {
            // transfer
            _updateAccountSnapshot(from);
            _updateAccountSnapshot(to);
        }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots) private view returns (bool, uint256) {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");
        require(snapshotId <= _getCurrentSnapshotId(), "ERC20Snapshot: nonexistent id");

        // When a valid snapshot is queried, there are three possibilities:
        //  a) The queried value was not modified after the snapshot was taken. Therefore, a snapshot entry was never
        //  created for this id, and all stored snapshot ids are smaller than the requested one. The value that corresponds
        //  to this id is the current one.
        //  b) The queried value was modified after the snapshot was taken. Therefore, there will be an entry with the
        //  requested id, and its value is the one to return.
        //  c) More snapshots were created after the requested one, and the queried value was later modified. There will be
        //  no entry for the requested id: the value that corresponds to it is that of the smallest snapshot id that is
        //  larger than the requested one.
        //
        // In summary, we need to find an element in an array, returning the index of the smallest value that is larger if
        // it is not found, unless said value doesn't exist (e.g. when all values are smaller). Arrays.findUpperBound does
        // exactly this.

        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _getCurrentSnapshotId();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Arrays.sol)

pragma solidity ^0.8.0;

import "Math.sol";

/**
 * @dev Collection of functions related to array types.
 */
library Arrays {
    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value greater or equal to `element`. If no such index exists (i.e. all
     * values in the array are strictly less than `element`), the array length is
     * returned. Time complexity O(log n).
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound. We will return the inclusive upper bound.
        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "ERC20.sol";
import "Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "ERC20.sol";
import "Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Capped.sol)

pragma solidity ^0.8.0;

import "ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}