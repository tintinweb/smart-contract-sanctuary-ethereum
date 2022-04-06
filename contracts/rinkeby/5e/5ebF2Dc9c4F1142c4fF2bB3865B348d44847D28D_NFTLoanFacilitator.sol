// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.12;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeTransferLib, ERC20} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {INFTLoanFacilitator} from './interfaces/INFTLoanFacilitator.sol';
import {IERC721Mintable} from './interfaces/IERC721Mintable.sol';
import {ILendTicket} from './interfaces/ILendTicket.sol';

contract NFTLoanFacilitator is Ownable, INFTLoanFacilitator {
    using SafeTransferLib for ERC20;

    // ==== constants ====

    /** 
     * See {INFTLoanFacilitator-INTEREST_RATE_DECIMALS}.     
     * @dev lowest non-zero APR possible = (1/10^3) = 0.001 = 0.1%
     */
    uint8 public constant override INTEREST_RATE_DECIMALS = 3;

    /// See {INFTLoanFacilitator-SCALAR}.
    uint256 public constant override SCALAR = 10 ** INTEREST_RATE_DECIMALS;

    
    // ==== state variables ====

    /// See {INFTLoanFacilitator-originationFeeRate}.
    /// @dev starts at 1%
    uint256 public override originationFeeRate = 10 ** (INTEREST_RATE_DECIMALS - 2);

    /// See {INFTLoanFacilitator-requiredImprovementRate}.
    /// @dev starts at 10%
    uint256 public override requiredImprovementRate = 10 ** (INTEREST_RATE_DECIMALS - 1);

    /// See {INFTLoanFacilitator-lendTicketContract}.
    address public override lendTicketContract;

    /// See {INFTLoanFacilitator-borrowTicketContract}.
    address public override borrowTicketContract;

    /// See {INFTLoanFacilitator-loanInfo}.
    mapping(uint256 => Loan) public loanInfo;

    /// @dev tracks loan count
    uint256 private _nonce = 1;

    
    // ==== modifiers ====

    modifier notClosed(uint256 loanId) { 
        require(!loanInfo[loanId].closed, "NFTLoanFacilitator: loan closed");
        _; 
    }


    // ==== constructor ====

    constructor(address _manager) {
        transferOwnership(_manager);
    }

    
    // ==== state changing external functions ====

    /// See {INFTLoanFacilitator-createLoan}.
    function createLoan(
        uint256 collateralTokenId,
        address collateralContractAddress,
        uint16 maxPerAnumInterest,
        uint128 minLoanAmount,
        address loanAssetContractAddress,
        uint32 minDurationSeconds,
        address mintBorrowTicketTo
    )
        external
        override
        returns (uint256 id) 
    {
        require(minDurationSeconds != 0, 'NFTLoanFacilitator: 0 duration');
        require(minLoanAmount != 0, 'NFTLoanFacilitator: 0 loan amount');
        require(collateralContractAddress != lendTicketContract,
        'NFTLoanFacilitator: cannot use tickets as collateral');
        require(collateralContractAddress != borrowTicketContract, 
        'NFTLoanFacilitator: cannot use tickets as collateral');
        
        IERC721(collateralContractAddress).transferFrom(msg.sender, address(this), collateralTokenId);

        unchecked {
            id = _nonce++;
        }

        Loan storage loan = loanInfo[id];
        loan.loanAssetContractAddress = loanAssetContractAddress;
        loan.loanAmount = minLoanAmount;
        loan.collateralTokenId = collateralTokenId;
        loan.collateralContractAddress = collateralContractAddress;
        loan.perAnumInterestRate = maxPerAnumInterest;
        loan.durationSeconds = minDurationSeconds;
        
        IERC721Mintable(borrowTicketContract).mint(mintBorrowTicketTo, id);
        emit CreateLoan(
            id,
            msg.sender,
            collateralTokenId,
            collateralContractAddress,
            maxPerAnumInterest,
            loanAssetContractAddress,
            minLoanAmount,
            minDurationSeconds
        );
    }

    /// See {INFTLoanFacilitator-closeLoan}.
    function closeLoan(uint256 loanId, address sendCollateralTo) external override notClosed(loanId) {
        require(IERC721(borrowTicketContract).ownerOf(loanId) == msg.sender,
        "NFTLoanFacilitator: borrow ticket holder only");

        Loan storage loan = loanInfo[loanId];
        require(loan.lastAccumulatedTimestamp == 0, "NFTLoanFacilitator: has lender, use repayAndCloseLoan");
        
        loan.closed = true;
        IERC721(loan.collateralContractAddress).transferFrom(address(this), sendCollateralTo, loan.collateralTokenId);
        emit Close(loanId);
    }

    /// See {INFTLoanFacilitator-lend}.
    function lend(
        uint256 loanId,
        uint16 interestRate,
        uint128 amount,
        uint32 durationSeconds,
        address sendLendTicketTo
    )
        external
        override
        notClosed(loanId)
    {
        Loan storage loan = loanInfo[loanId];
        
        if (loan.lastAccumulatedTimestamp == 0) {
            address loanAssetContractAddress = loan.loanAssetContractAddress;
            require(loanAssetContractAddress != address(0), "NFTLoanFacilitator: invalid loan");

            require(interestRate <= loan.perAnumInterestRate, 'NFTLoanFacilitator: rate too high');
            require(durationSeconds >= loan.durationSeconds, 'NFTLoanFacilitator: duration too low');
            require(amount >= loan.loanAmount, 'NFTLoanFacilitator: amount too low');
        
            loan.perAnumInterestRate = interestRate;
            loan.lastAccumulatedTimestamp = uint40(block.timestamp);
            loan.durationSeconds = durationSeconds;
            loan.loanAmount = amount;

            ERC20(loanAssetContractAddress).safeTransferFrom(msg.sender, address(this), amount);
            uint256 facilitatorTake = amount * originationFeeRate / SCALAR;
            ERC20(loanAssetContractAddress).safeTransfer(
                IERC721(borrowTicketContract).ownerOf(loanId),
                amount - facilitatorTake
            );
            IERC721Mintable(lendTicketContract).mint(sendLendTicketTo, loanId);
        } else {
            uint256 previousLoanAmount = loan.loanAmount;
            // will underflow if amount < previousAmount
            uint256 amountIncrease = amount - previousLoanAmount;

            {
                uint256 previousInterestRate = loan.perAnumInterestRate;
                uint256 previousDurationSeconds = loan.durationSeconds;

                require(interestRate <= previousInterestRate, 'NFTLoanFacilitator: rate too high');
                require(durationSeconds >= previousDurationSeconds, 'NFTLoanFacilitator: duration too low');

                require((previousLoanAmount * requiredImprovementRate / SCALAR) <= amountIncrease
                || previousDurationSeconds + (previousDurationSeconds * requiredImprovementRate / SCALAR) <= durationSeconds 
                || (previousInterestRate != 0 // do not allow rate improvement if rate already 0
                    && previousInterestRate - (previousInterestRate * requiredImprovementRate / SCALAR) >= interestRate), 
                "NFTLoanFacilitator: proposed terms must be better than existing terms");
            }

            uint256 accumulatedInterest = _interestOwed(
                previousLoanAmount,
                loan.lastAccumulatedTimestamp,
                loan.perAnumInterestRate,
                loan.accumulatedInterest
            );

            require(accumulatedInterest <= type(uint128).max,
            "NFTLoanFacilitator: accumulated interest exceeds uint128");

            loan.perAnumInterestRate = interestRate;
            loan.lastAccumulatedTimestamp = uint40(block.timestamp);
            loan.durationSeconds = durationSeconds;
            loan.loanAmount = amount;
            loan.accumulatedInterest = uint128(accumulatedInterest);

            address currentLoanOwner = IERC721(lendTicketContract).ownerOf(loanId);
            if (amountIncrease > 0) {
                address loanAssetContractAddress = loan.loanAssetContractAddress;
                ERC20(loanAssetContractAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    amount + accumulatedInterest
                );
                ERC20(loanAssetContractAddress).safeTransfer(
                    currentLoanOwner,
                    accumulatedInterest + previousLoanAmount
                );
                uint256 facilitatorTake = (amountIncrease * originationFeeRate / SCALAR);
                ERC20(loanAssetContractAddress).safeTransfer(
                    IERC721(borrowTicketContract).ownerOf(loanId),
                    amountIncrease - facilitatorTake
                );
            } else {
                ERC20(loan.loanAssetContractAddress).safeTransferFrom(
                    msg.sender,
                    currentLoanOwner,
                    accumulatedInterest + previousLoanAmount
                );
            }
            ILendTicket(lendTicketContract).loanFacilitatorTransfer(currentLoanOwner, sendLendTicketTo, loanId);
            
            emit BuyoutLender(loanId, msg.sender, currentLoanOwner, accumulatedInterest, previousLoanAmount);
        }

        emit Lend(loanId, msg.sender, interestRate, amount, durationSeconds);
    }

    /// See {INFTLoanFacilitator-repayAndCloseLoan}.
    function repayAndCloseLoan(uint256 loanId) external override notClosed(loanId) {
        Loan storage loan = loanInfo[loanId];

        uint256 interest = _interestOwed(
            loan.loanAmount,
            loan.lastAccumulatedTimestamp,
            loan.perAnumInterestRate,
            loan.accumulatedInterest
        );
        address lender = IERC721(lendTicketContract).ownerOf(loanId);
        loan.closed = true;
        ERC20(loan.loanAssetContractAddress).safeTransferFrom(msg.sender, lender, interest + loan.loanAmount);
        IERC721(loan.collateralContractAddress).safeTransferFrom(
            address(this),
            IERC721(borrowTicketContract).ownerOf(loanId),
            loan.collateralTokenId
        );

        emit Repay(loanId, msg.sender, lender, interest, loan.loanAmount);
        emit Close(loanId);
    }

    /// See {INFTLoanFacilitator-seizeCollateral}.
    function seizeCollateral(uint256 loanId, address sendCollateralTo) external override notClosed(loanId) {
        require(IERC721(lendTicketContract).ownerOf(loanId) == msg.sender, 
        "NFTLoanFacilitator: lend ticket holder only");

        Loan storage loan = loanInfo[loanId];
        require(block.timestamp > loan.durationSeconds + loan.lastAccumulatedTimestamp,
        "NFTLoanFacilitator: payment is not late");

        loan.closed = true;
        IERC721(loan.collateralContractAddress).safeTransferFrom(
            address(this),
            sendCollateralTo,
            loan.collateralTokenId
        );

        emit SeizeCollateral(loanId);
        emit Close(loanId);
    }

    
    // === owner state changing ===

    /**
     * @notice Sets lendTicketContract to _contract
     * @dev cannot be set if lendTicketContract is already set
     */
    function setLendTicketContract(address _contract) external onlyOwner {
        require(lendTicketContract == address(0), 'NFTLoanFacilitator: already set');

        lendTicketContract = _contract;
    }

    /**
     * @notice Sets borrowTicketContract to _contract
     * @dev cannot be set if borrowTicketContract is already set
     */
    function setBorrowTicketContract(address _contract) external onlyOwner {
        require(borrowTicketContract == address(0), 'NFTLoanFacilitator: already set');

        borrowTicketContract = _contract;
    }

    /// @notice Transfers `amount` of loan origination fees for `asset` to `to`
    function withdrawOriginationFees(address asset, uint256 amount, address to) external onlyOwner {
        ERC20(asset).safeTransfer(to, amount);

        emit WithdrawOriginationFees(asset, amount, to);
    }

    /**
     * @notice Updates originationFeeRate the faciliator keeps of each loan amount
     * @dev Cannot be set higher than 5%
     */
    function updateOriginationFeeRate(uint32 _originationFeeRate) external onlyOwner {
        require(_originationFeeRate <= 5 * (10 ** (INTEREST_RATE_DECIMALS - 2)), "NFTLoanFacilitator: max fee 5%");
        
        originationFeeRate = _originationFeeRate;

        emit UpdateOriginationFeeRate(_originationFeeRate);
    }

    /**
     * @notice updates the percent improvement required of at least one loan term when buying out lender 
     * a loan that already has a lender. E.g. setting this value to 10 means duration or amount
     * must be 10% higher or interest rate must be 10% lower. 
     * @dev Cannot be 0.
     */
    function updateRequiredImprovementRate(uint256 _improvementRate) external onlyOwner {
        require(_improvementRate > 0, 'NFTLoanFacilitator: 0 improvement rate');

        requiredImprovementRate = _improvementRate;

        emit UpdateRequiredImprovementRate(_improvementRate);
    }

    
    // ==== external view ====

    /// See {INFTLoanFacilitator-loanInfoStruct}.
    function loanInfoStruct(uint256 loanId) external view override returns (Loan memory) {
        return loanInfo[loanId];
    }

    /// See {INFTLoanFacilitator-totalOwed}.
    function totalOwed(uint256 loanId) external view override returns (uint256) {
        Loan storage loan = loanInfo[loanId];
        if (loan.closed || loan.lastAccumulatedTimestamp == 0) return 0;

        return loanInfo[loanId].loanAmount + _interestOwed(
            loan.loanAmount,
            loan.lastAccumulatedTimestamp,
            loan.perAnumInterestRate,
            loan.accumulatedInterest
        );
    }

    /// See {INFTLoanFacilitator-interestOwed}.
    function interestOwed(uint256 loanId) external view override returns (uint256) {
        Loan storage loan = loanInfo[loanId];
        if(loan.closed || loan.lastAccumulatedTimestamp == 0) return 0;

        return _interestOwed(
            loan.loanAmount,
            loan.lastAccumulatedTimestamp,
            loan.perAnumInterestRate,
            loan.accumulatedInterest
        );
    }

    /// See {INFTLoanFacilitator-loanEndSeconds}.
    function loanEndSeconds(uint256 loanId) external view override returns (uint256) {
        Loan storage loan = loanInfo[loanId];
        return loan.durationSeconds + loan.lastAccumulatedTimestamp;
    }

    
    // === private ===

    /// @dev Returns the total interest owed on loan
    function _interestOwed(
        uint256 loanAmount,
        uint256 lastAccumulatedTimestamp,
        uint256 perAnumInterestRate,
        uint256 accumulatedInterest
    ) 
        internal 
        view 
        returns (uint256) 
    {
        return loanAmount
            * (block.timestamp - lastAccumulatedTimestamp)
            * (perAnumInterestRate * 1e18 / 365 days)
            / 1e21 // SCALAR * 1e18
            + accumulatedInterest;
    }
}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
pragma solidity 0.8.12;

interface INFTLoanFacilitator {
    /// @notice See loanInfo
    struct Loan {
        bool closed;
        uint16 perAnumInterestRate;
        uint32 durationSeconds;
        uint40 lastAccumulatedTimestamp;
        address collateralContractAddress;
        address loanAssetContractAddress;
        uint128 accumulatedInterest;
        uint128 loanAmount;
        uint256 collateralTokenId;
    }

    /**
     * @notice The magnitude of SCALAR
     * @dev 10^INTEREST_RATE_DECIMALS = 1 = 100%
     */
    function INTEREST_RATE_DECIMALS() external returns (uint8);

    /**
     * @notice The SCALAR for all percentages in the loan facilitator contract
     * @dev Any interest rate passed to a function should already been multiplied by SCALAR
     */
    function SCALAR() external returns (uint256);

    /**
     * @notice The percent of the loan amount that the facilitator will take as a fee, scaled by SCALAR
     * @dev Starts set to 1%. Can only be set to 0 - 5%. 
     */
    function originationFeeRate() external returns (uint256);

    /**
     * @notice The lend ticket contract associated with this loan faciliator
     * @dev Once set, cannot be modified
     */
    function lendTicketContract() external returns (address);

    /**
     * @notice The borrow ticket contract associated with this loan faciliator
     * @dev Once set, cannot be modified
     */
    function borrowTicketContract() external returns (address);

    /**
     * @notice The percent improvement required of at least one loan term when buying out current lender 
     * a loan that already has a lender, scaled by SCALAR. 
     * E.g. setting this value to 100 (10%) means, when replacing a lender, the new loan terms must have
     * at least 10% greater duration or loan amount or at least 10% lower interest rate. 
     * @dev Starts at 100 = 10%. Only owner can set. Cannot be set to 0.
     */
    function requiredImprovementRate() external returns (uint256);
    
    /**
     * @notice Emitted when the loan is created
     * @param id The id of the new loan, matches the token id of the borrow ticket minted in the same transaction
     * @param minter msg.sender
     * @param collateralTokenId The token id of the collateral NFT
     * @param collateralContract The contract address of the collateral NFT
     * @param maxInterestRate The max per anum interest rate, scaled by SCALAR
     * @param loanAssetContract The contract address of the loan asset
     * @param minLoanAmount mimimum loan amount
     * @param minDurationSeconds minimum loan duration in seconds
    */
    event CreateLoan(
        uint256 indexed id,
        address indexed minter,
        uint256 collateralTokenId,
        address collateralContract,
        uint256 maxInterestRate,
        address loanAssetContract,
        uint256 minLoanAmount,
        uint256 minDurationSeconds
        );

    /** 
     * @notice Emitted when ticket is closed
     * @param id The id of the ticket which has been closed
     */
    event Close(uint256 indexed id);

    /** 
     * @notice Emitted when the loan is underwritten or re-underwritten
     * @param id The id of the ticket which is being underwritten
     * @param lender msg.sender
     * @param interestRate The per anum interest rate, scaled by SCALAR, for the loan
     * @param loanAmount The loan amount
     * @param durationSeconds The loan duration in seconds 
     */
    event Lend(
        uint256 indexed id,
        address indexed lender,
        uint256 interestRate,
        uint256 loanAmount,
        uint256 durationSeconds
    );

    /**
     * @notice Emitted when a loan is being re-underwritten, the current loan ticket holder is being bought out
     * @param lender msg.sender
     * @param replacedLoanOwner The current loan ticket holder
     * @param interestEarned The amount of interest the loan has accrued from first lender to this buyout
     * @param replacedAmount The loan amount prior to buyout
     */    
    event BuyoutLender(
        uint256 indexed id,
        address indexed lender,
        address indexed replacedLoanOwner,
        uint256 interestEarned,
        uint256 replacedAmount
    );
    
    /**
     * @notice Emitted when loan is repaid
     * @param id The loan id
     * @param repayer msg.sender
     * @param loanOwner The current holder of the lend ticket for this loan, token id matching the loan id
     * @param interestEarned The total interest accumulated on the loan
     * @param loanAmount The loan amount
     */
    event Repay(
        uint256 indexed id,
        address indexed repayer,
        address indexed loanOwner,
        uint256 interestEarned,
        uint256 loanAmount
    );

    /**
     * @notice Emitted when loan NFT collateral is seized 
     * @param id The ticket id
     */
    event SeizeCollateral(uint256 indexed id);

     /**
      * @notice Emitted when origination fees are withdrawn
      * @dev only owner can call
      * @param asset the ERC20 asset withdrawn
      * @param amount the amount withdrawn
      * @param to the address the withdrawn amount was sent to
      */
     event WithdrawOriginationFees(address asset, uint256 amount, address to);

      /**
      * @notice Emitted when originationFeeRate is updated
      * @dev only owner can call, value is scaled by SCALAR, 100% = SCALAR
      * @param feeRate the new origination fee rate
      */
     event UpdateOriginationFeeRate(uint32 feeRate);

     /**
      * @notice Emitted when requiredImprovementRate is updated
      * @dev only owner can call, value is scaled by SCALAR, 100% = SCALAR
      * @param improvementRate the new required improvementRate
      */
     event UpdateRequiredImprovementRate(uint256 improvementRate);

    /**
     * @notice (1) transfers the collateral NFT to the loan facilitator contract 
     * (2) creates the loan, populating loanInfo in the facilitator contract,
     * and (3) mints a Borrow Ticket to mintBorrowTicketTo
     * @dev loan duration or loan amount cannot be 0, 
     * this is done to protect borrowers from accidentally passing a default value
     * and also because it creates odd lending and buyout behavior: possible to lend
     * for 0 value or 0 duration, and possible to buyout with no improvement because, for example
     * previousDurationSeconds + (previousDurationSeconds * requiredImprovementRate / SCALAR) <= durationSeconds
     * evaluates to true if previousDurationSeconds is 0 and durationSeconds is 0.
     * loanAssetContractAddress cannot be address(0), we check this because Solmate SafeTransferLib
     * does not revert with address(0) and this could cause odd behavior.
     * collateralContractAddress cannot be address(borrowTicket) or address(lendTicket).
     * @param collateralTokenId The token id of the collateral NFT 
     * @param collateralContractAddress The contract address of the collateral NFT
     * @param maxPerAnumInterest The maximum per anum interest rate for this loan, scaled by SCALAR
     * @param minLoanAmount The minimum acceptable loan amount for this loan
     * @param loanAssetContractAddress The address of the loan asset
     * @param minDurationSeconds The minimum duration for this loan
     * @param mintBorrowTicketTo An address to mint the Borrow Ticket corresponding to this loan to
     * @return id of the created loan
     */
    function createLoan(
            uint256 collateralTokenId,
            address collateralContractAddress,
            uint16 maxPerAnumInterest,
            uint128 minLoanAmount,
            address loanAssetContractAddress,
            uint32 minDurationSeconds,
            address mintBorrowTicketTo
    ) external returns (uint256 id);

    /**
     * @notice Closes the loan, sends the NFT collateral to sendCollateralTo
     * @dev Can only be called by the holder of the Borrow Ticket with tokenId
     * matching the loanId. Can only be called if loan has not be underwritten,
     * i.e. lastAccumulatedInterestTimestamp = 0
     * @param loanId The loan id
     * @param sendCollateralTo The address to send the collateral NFT to
     */
    function closeLoan(uint256 loanId, address sendCollateralTo) external;

    /**
     * @notice Lends, meeting or beating the proposed loan terms, 
     * transferring `amount` of the loan asset 
     * to the facilitator contract. If the loan has not yet been underwritten, 
     * a Lend Ticket is minted to `sendLendTicketTo`. If the loan has already been 
     * underwritten, then this is a buyout, and the Lend Ticket will be transferred
     * from the current holder to `sendLendTicketTo`. Also in the case of a buyout, interestOwed()
     * is transferred from the caller to the facilitator contract, in addition to `amount`, and
     * totalOwed() is paid to the current Lend Ticket holder.
     * @dev Loan terms must meet or beat loan terms. If a buyout, at least one loan term
     * must be improved by at least 10%. E.g. 10% longer duration, 10% lower interest, 
     * 10% higher amount
     * @param loanId The loan id
     * @param interestRate The per anum interest rate, scaled by SCALAR
     * @param amount The loan amount
     * @param durationSeconds The loan duration in seconds
     * @param sendLendTicketTo The address to send the Lend Ticket to
     */
    function lend(
            uint256 loanId,
            uint16 interestRate,
            uint128 amount,
            uint32 durationSeconds,
            address sendLendTicketTo
    ) external;

    /**
     * @notice repays and closes the loan, transferring totalOwed() to the current Lend Ticket holder
     * and transferring the collateral NFT to the Borrow Ticket holder.
     * @param loanId The loan id
     */
    function repayAndCloseLoan(uint256 loanId) external;

    /**
     * @notice Transfers the collateral NFT to `sendCollateralTo` and closes the loan.
     * @dev Can only be called by Lend Ticket holder. Can only be called 
     * if block.timestamp > loanEndSeconds()
     * @param loanId The loan id
     * @param sendCollateralTo The address to send the collateral NFT to
     */
    function seizeCollateral(uint256 loanId, address sendCollateralTo) external;

    /**
     * @notice returns the info for this loan
     * @param loanId The id of the loan
     * @return closed Whether or not the ticket is closed
     * @return perAnumInterestRate The per anum interest rate, scaled by SCALAR
     * @return durationSeconds The loan duration in seconds
     
     * @return lastAccumulatedTimestamp The timestamp (in seconds) when interest was last accumulated, 
     * i.e. the timestamp of the most recent underwriting
     * @return collateralContractAddress The contract address of the NFT collateral 
     * @return loanAssetContractAddress The contract address of the loan asset.
     * @return accumulatedInterest The amount of interest accumulated on the loan prior to the current lender
     * @return loanAmount The loan amount
     * @return collateralTokenId The token ID of the NFT collateral
     */
    function loanInfo(uint256 loanId)
        external 
        view 
        returns (
            bool closed,
            uint16 perAnumInterestRate,
            uint32 durationSeconds,
            uint40 lastAccumulatedTimestamp,
            address collateralContractAddress,
            address loanAssetContractAddress,
            uint128 accumulatedInterest,
            uint128 loanAmount,
            uint256 collateralTokenId
        );

    /**
     * @notice returns the info for this loan
     * @dev this is a convenience method for other contracts that would prefer to have the 
     * Loan object not decomposed. 
     * @param loanId The id of the loan
     * @return Loan struct corresponding to loanId
     */
    function loanInfoStruct(uint256 loanId) external view returns (Loan memory);

    /**
     * @notice returns the total amount owed for the loan, i.e. principal + interest
     * @param loanId The loan id
     */
    function totalOwed(uint256 loanId) view external returns (uint256);

    /**
     * @notice returns the interest owed on the loan, in loan asset units
     * @param loanId The loan id
     */
    function interestOwed(uint256 loanId) view external returns (uint256);

    /**
     * @notice returns the unix timestamp (seconds) of the loan end
     * @param loanId The loan id
     */
    function loanEndSeconds(uint256 loanId) view external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IERC721Mintable {
    /**
     * @notice mints an ERC721 token of tokenId to the to address
     * @dev only callable by nft loan facilitator
     * @param to The address to send the token to
     * @param tokenId The id of the token to mint
     */
    function mint(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface ILendTicket {
    /**
     * @notice Transfers a lend ticket
     * @dev can only be called by nft loan facilitator
     * @param from The current holder of the lend ticket
     * @param to Address to send the lend ticket to
     * @param loanId The lend ticket token id, which is also the loan id in the facilitator contract
     */
    function loanFacilitatorTransfer(address from, address to, uint256 loanId) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}