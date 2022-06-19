/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]



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


// File @openzeppelin/contracts/access/[email protected]



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


// File contracts/proxiableTokenDict.sol



pragma solidity ^0.8.0;

interface tokenJsonProvider{
    function getValue(uint256 tokenId) external view returns(string memory);
}


contract proxiableTokenDict is Ownable, tokenJsonProvider {

    mapping(uint256 => bool) public isTokenValueFinal;
    mapping(uint256 => string) public tokenValue;

    tokenJsonProvider public contractToProxyTo;
    bool isProxyContractFinal = false;

    constructor() {}

    //todo: figure out if return data needs to be passed by memory
    function getValue(uint256 _tokenId) public override view returns(string memory) {
        if (address(0) == address(contractToProxyTo)) {
            return tokenValue[_tokenId];
        } else {
            return contractToProxyTo.getValue(_tokenId);
        }
    }


    //todo: figure out if values should be passed by memory
    function setValues(uint256[] calldata _tokenIds, string[] calldata _values, bool[] calldata _isTokenValueFinal) public onlyOwner  {
        
        require(address(0) == address(contractToProxyTo), "CONTRACT_IS_SET_TO_PROXY");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            
            uint256 tokenId = _tokenIds[i];
            require(!isTokenValueFinal[tokenId], "TOKEN_VALUE_IS_FINAL");


            tokenValue[tokenId] = _values[i];
            isTokenValueFinal[tokenId] = _isTokenValueFinal[i];
        }
    }


    function setProxyContract(tokenJsonProvider _contractToProxyTo, bool _isFinal) public onlyOwner {
        require(!isProxyContractFinal, "PROXY_CONTRACT_IS_FINAL");

        contractToProxyTo = _contractToProxyTo;
        isProxyContractFinal = _isFinal;
    }
}