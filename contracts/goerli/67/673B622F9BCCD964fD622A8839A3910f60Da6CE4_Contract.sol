// Contract version 1.0.0


// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

//togliere renounceOwnership

contract Contract is Ownable {


    enum DocStatus {
        Created,
        Updated,
        Deposited,
        Confirmed,
        Archived
    }

    struct Doc {
        address seller;
        address buyer;
        address validator;
        uint256 saleExpirationDate;
        uint256 requestedAmount;
        uint256 purchaseExpirationDate;
        bool requestedAmountDeposited;
        bool validatorCancelled;
        bool transactionConfirmed;
        string carPlate;
        IERC20 token;
        uint256 lastUpdate;
    }

    event DocCreated   (uint indexed docid, address indexed _address, string indexed _carPlate);
    event DocUpdated   (uint indexed docid, address indexed _address, string indexed _carPlate);
    event DocDeposited (uint indexed docid, address indexed _address, string indexed _carPlate);
    event DocConfirmed (uint indexed docid, address indexed _address, string indexed _carPlate);
    event DocArchived  (uint indexed docid, address indexed _address, string indexed _carPlate);

    DocStatus public status;

    uint256 public commissionPercentage;
    uint256 public fixedCommission;
    uint256 public DocCount;
    uint256 public Erc20Count;

    mapping(uint256 => Doc) public docs;
    mapping(uint256 => uint256) public docsStatus;
    mapping(uint256 => string) public encData;
    mapping(uint256 => address) public erc20Addresses;
    mapping(address => uint256) public erc20Ids;
    mapping(address => bool) public erc20Whitelist;


    constructor(address _ercoAddress)  {
        //change
        commissionPercentage = 10;
        fixedCommission = 100000;
        Erc20Count++;
        erc20Addresses[Erc20Count] = _ercoAddress;
        erc20Ids[_ercoAddress] = Erc20Count;
        erc20Whitelist[_ercoAddress] = true;
    }

    error Overflow(uint x);

    /////////////////////////
    // Doc creation and update
    ////////////////////////

    function createDoc(
        address _buyer,
        address _validator,
        uint256 _saleExpirationDate,
        uint256 _requestedAmount,
        address _tokenAddress,
        string memory _carPlate,
        string memory _encData
    ) external {
        require(
            block.timestamp < _saleExpirationDate,
            "1|createDoc|dt not valid. block.timestamp must be < expiration date "
        );
        require(
            erc20Whitelist[_tokenAddress] == true,
            "2|createDoc|the erc20 is not in the whitelist"
        );

        DocCount++;
        Doc storage newDoc = docs[DocCount];

        newDoc.token = IERC20(_tokenAddress);
        newDoc.seller = msg.sender;
        newDoc.buyer = _buyer;
        newDoc.validator = _validator;
        newDoc.saleExpirationDate = _saleExpirationDate;
        newDoc.requestedAmount = _requestedAmount;
        newDoc.carPlate = _carPlate;
        newDoc.requestedAmountDeposited = false;

        newDoc.lastUpdate = block.timestamp;
        docsStatus[DocCount] = uint(DocStatus.Created);
        encData[DocCount] = _encData;

        emit DocCreated(DocCount, msg.sender, _carPlate);

    }

    function update(
        uint _docId,
        address _buyer,
        address _validator,
        uint256 _saleExpirationDate,
        uint256 _requestedAmount,
        address _tokenAddress,
        string memory _carPlate,
        string memory _encData
    ) external {
        require(
            block.timestamp < _saleExpirationDate,
            "3|update|dt not valid. block.timestamp must be < expiration date "
        );
        require(
            erc20Whitelist[_tokenAddress] == true,
            "4|update|the erc20 is not in the whitelist"
        );

        Doc storage currentDoc = docs[_docId];

        currentDoc.token = IERC20(_tokenAddress);
        currentDoc.buyer = _buyer;
        currentDoc.validator = _validator;
        currentDoc.saleExpirationDate = _saleExpirationDate;
        currentDoc.requestedAmount = _requestedAmount;
        currentDoc.carPlate = _carPlate;
        currentDoc.requestedAmountDeposited = false;

        currentDoc.lastUpdate = block.timestamp;

        docsStatus[_docId] = uint(DocStatus.Updated);
        encData[_docId] = _encData;

        emit DocUpdated(_docId, msg.sender, _carPlate);
    }


    /////////////////////////
    // Workflow functions
    ////////////////////////

    function deposit(uint256 _docId) external {
        Doc storage currentDoc = docs[_docId];
        require(
            msg.sender == currentDoc.buyer,
            "5|deposit|Only buyer can deposit"
        );
        require(
            currentDoc.requestedAmountDeposited == false,
            "6|deposit|The  amount is already deposited"
        );

        unchecked {
            if (commissionPercentage == 0) {
                revert  Overflow(commissionPercentage);
            }
            uint256 commissionAmount = (currentDoc.requestedAmount *
                commissionPercentage) / 10000;

            uint256 totalDepositAmount = currentDoc.requestedAmount +
            commissionAmount +
            fixedCommission;

            currentDoc.token.transferFrom(msg.sender, address(this), totalDepositAmount);
            currentDoc.requestedAmountDeposited = true;
            docsStatus[_docId] = uint(DocStatus.Deposited);
        }
        emit DocDeposited(_docId, msg.sender, currentDoc.carPlate);
    }

    function confirm(uint256 _docId) external {
        Doc storage currentDoc = docs[_docId];
        require(
            msg.sender == currentDoc.validator,
            "7|confirm|Only validator can confirm"
        );
        require(
            currentDoc.requestedAmountDeposited == true,
            "8|confirm|The the amount is not deposited"
        );

        require(
            block.timestamp < currentDoc.saleExpirationDate,
            "9|confirm|The sale is expired. Create a new one."
        );

        currentDoc.transactionConfirmed = true;

        withdrawSeller(_docId);
        docsStatus[_docId] = uint(DocStatus.Confirmed);
        emit DocConfirmed(_docId, msg.sender, currentDoc.carPlate);

    }

    function withdrawSeller(uint256 DocId) internal {
        Doc storage currentDoc = docs[DocId];
        //        require(
        //            msg.sender == address(this),
        //            "10|withdrawSeller|Only seller can withdraw"
        //            );
        require(
            currentDoc.transactionConfirmed == true,
            "11|withdrawSeller|Transaction not confirmed by validator"
        );
        unchecked {
            if (commissionPercentage == 0) {
                revert  Overflow(commissionPercentage);
            }
            uint256 commissionAmount = (currentDoc.requestedAmount *
                commissionPercentage) / 10000;
            uint256 totalDepositAmount = currentDoc.requestedAmount +
            commissionAmount +
            fixedCommission;


            currentDoc.token.transfer(currentDoc.seller, currentDoc.requestedAmount);
            if(totalDepositAmount>currentDoc.requestedAmount) {
                currentDoc.token.transfer(owner(), totalDepositAmount - currentDoc.requestedAmount );
            }


        }
    }

    function withdrawBuyer(uint256 _docId) internal {
        Doc storage currentDoc = docs[_docId];
        require(
            msg.sender == currentDoc.buyer,
            "12|withdrawBuyer|Only buyer can withdraw"
        );
        require(
            currentDoc.transactionConfirmed == false,
            "13|withdrawBuyer|Transaction not confirmed by validator"
        );
        currentDoc.requestedAmountDeposited == false;
        unchecked {
            if (commissionPercentage == 0) {
                revert  Overflow(commissionPercentage);
            }
            uint256 commissionAmount = (currentDoc.requestedAmount *
                commissionPercentage) / 10000;
            uint256 totalDepositAmount = currentDoc.requestedAmount +
            commissionAmount +
            fixedCommission;

            currentDoc.token.transfer(currentDoc.buyer, currentDoc.requestedAmount);
            if(totalDepositAmount>currentDoc.requestedAmount) {
                currentDoc.token.transfer(owner(), totalDepositAmount - currentDoc.requestedAmount );
            }
        }

        docsStatus[_docId] = uint(DocStatus.Archived);
        emit DocArchived(_docId, msg.sender, currentDoc.carPlate);
    }

    /////////////////////////
    // Contract Management functions
    /////////////////////////

    function setupFee(uint256 _commissionPercentage, uint256 _fixedCommission) external onlyOwner {
        require(
            _commissionPercentage > 0,
            "14|setupFee|Percentage should be equal to or less than 100"
        );
        require(
            _commissionPercentage <= 10000,
            "15|setupFee|Percentage should be equal to or less than 100"
        );
        commissionPercentage = _commissionPercentage;
        fixedCommission = _fixedCommission;
    }

    function changeVariableFee(uint256 newCommissionPercentage) external onlyOwner {
        require(
            newCommissionPercentage > 0,
            "16|changeVariableFee|Percentage should be equal to or less than 100"
        );
        require(
            newCommissionPercentage <= 10000,
            "17|changeVariableFee|Percentage should be equal to or less than 100"
        );
        commissionPercentage = newCommissionPercentage;
    }

    function changeFixedFee(uint256 newFixedCommission) external onlyOwner {
        require(
            newFixedCommission > 0,
            "18|changeFixedFee|Value has to be > 0"
        );
        fixedCommission = newFixedCommission;
    }

    function addErc20InWhiteList(address _address) external onlyOwner {

        erc20Addresses[Erc20Count] = _address;
        erc20Whitelist[_address] = true;
    }
    /////////////////////////
    // Query functions
    ////////////////////////

    function getDocRole(uint256 DocId) external view returns (string memory) {
        Doc storage currentDoc = docs[DocId];
        if (msg.sender == currentDoc.seller) {
            return "SELLER";
        } else if (msg.sender == currentDoc.buyer) {
            return "BUYER";
        } else if (msg.sender == currentDoc.validator) {
            return "VALIDATOR";
        } else if (msg.sender == owner()) {
            return "ADMIN";
        } else {
            return "NONE";
        }
    }

    function getdocsByValidator() external view returns (uint256[] memory) {
        uint256[] memory validatordocs = new uint256[](DocCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= DocCount; i++) {
            if (docs[i].validator == msg.sender) {
                validatordocs[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = validatordocs[i];
        }
        return result;
    }

    function getdocsBySeller() external view returns (uint256[] memory) {
        uint256[] memory sellerdocs = new uint256[](DocCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= DocCount; i++) {
            if (docs[i].seller == msg.sender) {
                sellerdocs[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = sellerdocs[i];
        }
        return result;
    }

    function getdocsByBuyer() external view returns (uint256[] memory) {
        uint256[] memory buyerdocs = new uint256[](DocCount);
        uint256 count = 0;
        for (uint256 i = 1; i <= DocCount; i++) {
            if (docs[i].buyer == msg.sender) {
                buyerdocs[count] = i;
                count++;
            }
        }
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = buyerdocs[i];
        }
        return result;
    }

    /////////////////////////
    // Utility functions
    ////////////////////////

    function calcTotalValue(uint256 _requestedAmount) external view returns (uint256){
        uint256 commissionAmount = (_requestedAmount *
            commissionPercentage) / 10000;
        uint256 totalDepositAmount = _requestedAmount +
        commissionAmount +
        fixedCommission;

        return totalDepositAmount;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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