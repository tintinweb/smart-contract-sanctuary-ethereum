// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "../interfaces/IServiceFee.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Service Fee Proxy to communicate service fee contract
 */
contract ServiceFeeProxy is Ownable {
    /// @notice service fee contract
    IServiceFee private serviceFeeContract;

    event ServiceFeeContractUpdated(address serviceFeeContract);

    /**
     * @notice Let admin set the service fee contract
     * @param _serviceFeeContract address of serviceFeeContract
     */
    function setServiceFeeContract(address _serviceFeeContract) onlyOwner external {
        require(
            _serviceFeeContract != address(0),
            "ServiceFeeProxy.setServiceFeeContract: Zero address"
        );
        serviceFeeContract = IServiceFee(_serviceFeeContract);
        emit ServiceFeeContractUpdated(_serviceFeeContract);
    }

    /**
     * @notice Set seller service fee
     * @param _sellerFee seller service fee
     */
    function setSellServiceFee(uint256 _sellerFee) external onlyOwner {
        require(
            _sellerFee != 0,
            "ServiceFee.setSellServiceFee: Zero value"
        );
        
        serviceFeeContract.setSellServiceFee(_sellerFee);
    }

    /**
     * @notice Set buyer service fee
     * @param _buyerFee buyer service fee
     */
    function setBuyServiceFee(uint256 _buyerFee) external onlyOwner {
        require(
            _buyerFee != 0,
            "ServiceFee.setBuyServiceFee: Zero value"
        );
        
        serviceFeeContract.setBuyServiceFee(_buyerFee);
    }

    /**
     * @notice Fetch sell service fee bps from service fee contract
     */
    function getSellServiceFeeBps() external view returns (uint256) {
        return serviceFeeContract.getSellServiceFeeBps();
    }

    /**
     * @notice Fetch buy service fee bps from service fee contract
     */
    function getBuyServiceFeeBps() external view returns (uint256) {
        return serviceFeeContract.getBuyServiceFeeBps();
    }

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() external view returns (address) {
        return serviceFeeContract.getServiceFeeRecipient();
    }

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address _serviceFeeRecipient) external onlyOwner {
        require(
            _serviceFeeRecipient != address(0),
            "ServiceFeeProxy.setServiceFeeRecipient: Zero address"
        );

        serviceFeeContract.setServiceFeeRecipient(_serviceFeeRecipient);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

/**
 * @notice Service Fee interface for Ikonic NFT Marketplace 
 */
interface IServiceFee {

    /**
     * @notice Lets admin set the Ikonic token contract
     * @param _ikonicTokenContract address of Ikonic token contract
     */
    function setIkonicTokenContract(address _ikonicTokenContract) external;

    /**
     * @notice Admin can add proxy address
     * @param _proxyAddr address of proxy
     */
    function addProxy(address _proxyAddr) external;

    /**
     * @notice Admin can remove proxy address
     * @param _proxyAddr address of proxy
     */
    function removeProxy(address _proxyAddr) external;

    /**
     * @notice Calculate the seller service fee
     */
    function getSellServiceFeeBps() external view returns (uint256);

    /**
     * @notice Calculate the buyer service fee
     */
    function getBuyServiceFeeBps() external view returns (uint256);

    /**
     * @notice Get service fee recipient address
     */
    function getServiceFeeRecipient() external view returns (address);

    /**
     * @notice Set service fee recipient address
     * @param _serviceFeeRecipient address of recipient
     */
    function setServiceFeeRecipient(address _serviceFeeRecipient) external;

    /**
     * @notice Set seller service fee
     * @param _sellerFee seller service fee
     */
    function setSellServiceFee(uint256 _sellerFee) external;

    /**
     * @notice Set buyer service fee
     * @param _buyerFee buyer service fee
     */
    function setBuyServiceFee(uint256 _buyerFee) external; 
}

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

// SPDX-License-Identifier: MIT

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