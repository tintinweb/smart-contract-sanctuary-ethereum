// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/LoanInterface.sol";
import "../interfaces/PledgeInterface.sol";
import "../interfaces/CapitalPoolInterface.sol";
import "../interfaces/NFTInterface.sol";
import "../interfaces/FTInterface.sol";
import "./LoanStructs.sol";
import "./Manageable.sol";
import "./Ecrecovery.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Loan
 * @author lixin
 * @notice Loan Handle all FT related operations in the pledged loan module
 */
contract Loan is LoanStructs, LoanInterface, Manageable, ReentrancyGuard {

    // Accuracy of loan charge ratio
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    // pledge conteact address
    address public pledge;

    // Capital pool for storing FT
    address public loanCapitalPool;

    // loan FT min amount
    uint256 public minLoanFTAmount;

    // // The Proportion of liquidated damages
    // uint256 public damageRatio;

    // NFTAddr => NFTId => LoanLiat
    mapping(address => mapping(uint256 => LoanList)) public loanList;

    /**
     * @notice Constructor of loan FT module
     */
    constructor(address newPledge, address newCapitalPool) {
        setLoanCapitalPool(newCapitalPool);
        setPledge(newPledge);
        // setDamageRatio(newDamageRatio);
    }

    /**
     * @notice setPledge Set the pledge contract address 
     *
     * @param newPledge The new pledge contract address 
     */
    function setPledge(address newPledge) public onlyManager {
        address oldPledge = pledge;
        pledge = newPledge;
        emit PledgeChanged(oldPledge, newPledge);
    }

    /**
     * @notice setCapitalPool Set the capital pool contract address for storing NFT
     *
     * @param newCapitalPool The new capital pool contract address for storing NFT
     */
    function setLoanCapitalPool(address newCapitalPool) public onlyManager {
        address oldCapitalPool = loanCapitalPool;
        loanCapitalPool = newCapitalPool;
        emit CapitalPoolChanged(oldCapitalPool, newCapitalPool);
    }

    //function getCapitalPool() external view virtual override returns(address){}

    function setMinLoanFTAmount(
        uint256 newMinLoanFTAmount
    ) public onlyManager {
        uint256 oldMinLoanFTAmount = minLoanFTAmount;
        minLoanFTAmount = newMinLoanFTAmount;
        emit MinLoanFTAmountChanged(oldMinLoanFTAmount, newMinLoanFTAmount);
    }


    /**
     * @notice Inject funds into the capital pool.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function injectFT(
        string calldata businessId,
        address[] calldata tokenAddr,
        uint256[] calldata tokenAmount
    ) external nonReentrant returns (bool){
        uint256 len = tokenAddr.length;
        if (len != tokenAmount.length) {
            revert ArrayLengthMismatch();
        }

        for (uint i = 0; i < len; ++i) {
            require(FTInterface(tokenAddr[i]).transferFrom(_msgSender(), loanCapitalPool, tokenAmount[i]), "FT transfer failed");
            CapitalPoolInterface(loanCapitalPool).depositFT(businessId, tokenAddr[i], tokenAmount[i]);
        }
        emit InjectFT(businessId, tokenAddr, tokenAmount);
        return true;
    }



    /**
     * @notice Only manager withdraw a NFT. Only manager can use call this function.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenAmount The id of ERC721 tokens.
     */
    function withdrawFTManager(
        string calldata businessId,
        address[] calldata tokenAddr,
        uint256[] calldata tokenAmount
    ) external onlyManager nonReentrant returns (bool){
        uint256 len = tokenAddr.length;
        if (len != tokenAmount.length) {
            revert ArrayLengthMismatch();
        }

        for (uint i = 0; i < len; ++i) {
            require(CapitalPoolInterface(loanCapitalPool).withdrawFTManager(businessId, tokenAddr[i], tokenAmount[i], _txOrigin()), "FT transfer failed");
        }
        emit WithdrawFT(businessId, tokenAddr, tokenAmount);
        return true;
    }

    /**
     * @notice User loan FT from the capital pool.
     *
     * @param businessId Used as business differentiation.
     * @param NFTAddr The ERC721 contract address.
     * @param baseInfo [NFTId, FTAmount, serviceRatio, creationTimestamp, interval]
     *              NFTId The id of ERC721 tokens.
     *              FTAmount The amount of ERC20 tokens.
     *              serviceRatio the  Ratio of Service.
     *              creationTimestamp The loan list creation time in seconds.
     *              interval The Interval of each repayment in seconds.
     * @param eachAmounts Amount to be repaid for each loan.
     * @param managerSign Manager's signature on and call parameters.
     */
    function loan(
        string calldata businessId,
        address NFTAddr,
        uint256[] calldata baseInfo,
        uint256[] calldata eachAmounts,
        bytes calldata managerSign
    ) external nonReentrant returns (bool){

        LoanList storage list = loanList[NFTAddr][baseInfo[0]];
        PledgeInterface.Note memory note = PledgeInterface(pledge).checkMortgageNote(NFTAddr, baseInfo[0]);

        if (list.billInfo[businessId].creationTimestamp != 0) {
            revert BusinessIdExists();
        }

        if (note.mortgagor != _msgSender()) {
            revert NOTYOURNFT();
        }

        if (list.loanAmount + baseInfo[1] > note.NFTPrice * note.loanRatio / INVERSE_BASIS_POINT) {
            revert LoanAmountUpperLimit();
        }

        if (minLoanFTAmount > note.NFTPrice * note.loanRatio / INVERSE_BASIS_POINT - (list.loanAmount + baseInfo[1])) {
            revert LoanAmountLowerLimit();
        }

        list.borrower = _msgSender();
        list.NFTAddr = NFTAddr;
        list.NFTId = baseInfo[0];
        list.FTAddr = note.FTAddr;
        list.NFTPrice = note.NFTPrice;
        list.loanRatio = note.loanRatio;
        list.loanAmount += baseInfo[1];
        list.billInfo[businessId].FTAmount = baseInfo[1];
        list.billInfo[businessId].serviceRatio = baseInfo[2];
        list.billInfo[businessId].creationTimestamp = baseInfo[3];
        list.billInfo[businessId].interval = baseInfo[4];
        list.businessIds.push(businessId);

        require(verify(businessId, list, eachAmounts, managerSign));


        require(bookKeep(businessId, NFTAddr, baseInfo, eachAmounts));

        uint256 loanAmount = baseInfo[1] * (INVERSE_BASIS_POINT - baseInfo[2]) / INVERSE_BASIS_POINT;

        CapitalPoolInterface(loanCapitalPool).withdrawFT(businessId, list.FTAddr, loanAmount, _msgSender());

        emit Loan(businessId, NFTAddr, baseInfo[0], note.FTAddr, loanAmount);
        return true;
    }

    function bookKeep(
        string calldata businessId,
        address NFTAddr,
        uint256[] calldata baseInfo,
        uint256[] calldata eachAmounts
    ) internal returns (bool){
        // uint256 NFTId = baseInfo[0];
        // uint256 FTAmount = baseInfo[1];
        // uint256 creationTimestamp = baseInfo[3];
        // uint256 interval = baseInfo[4];

        uint256 len = eachAmounts.length;
        LoanList storage list = loanList[NFTAddr][baseInfo[0]];

        if (list.deadline == 0) {
            list.creationTimestamp = baseInfo[3];
            list.interval = baseInfo[4];
            list.periods = len;
            list.deadline = baseInfo[3] + baseInfo[4] * len;
        } else {
            if (((list.deadline - baseInfo[3]) / list.interval) > len || baseInfo[4] != list.interval) {
                revert IllegalRepayment();
            }
        }

        list.billInfo[businessId].periods = len;
        uint256 total;
        for (uint256 i = 0; i < len; ++i) {
            list.bill[businessId][i + 1].amount = eachAmounts[i];
            total += eachAmounts[i];
        }
        list.billInfo[businessId].total = total;
        list.repaymentTotal += total;
        return true;
    }

    function verify(
        string memory businessId,
        LoanList storage list,
        uint256[] memory eachAmounts,
        bytes memory managerSign
    ) internal view returns (bool) {

        uint256 deadline = NFTInterface(list.NFTAddr).checkRepurchaseDeadline();
        if (deadline < _blockTimestamp()) {
            revert RepurchasePeriodExpired();
        }

        uint256 loanDeadline = list.billInfo[businessId].creationTimestamp + list.billInfo[businessId].interval * eachAmounts.length;
        if (loanDeadline > deadline) {
            revert RepaymentPeriodExceedsRepurchasePeriod();
        }

        bytes32 hash = keccak256(abi.encode(businessId, list.NFTAddr, list.NFTId, list.billInfo[businessId].FTAmount, list.billInfo[businessId].serviceRatio, list.billInfo[businessId].creationTimestamp, list.billInfo[businessId].interval, eachAmounts, _msgSender()));
        if (Ecrecovery.ecrecovery(hash, managerSign) != manager()) {
            revert IllegalManagerSign();
        }
        return true;
    }


    /**
     * @notice Repayment of loan to the capital pool.
     *
     * @param businessIds Used as business differentiation.
     * @param NFTAddrs The ERC721 contract address.
     * @param NFTIds The id of ERC721 tokens.
     * @param loanPeriods period number of the loan order.
     */
    function repayment(
        string[] calldata businessIds,
        address[] calldata NFTAddrs,
        uint256[] calldata NFTIds,
        uint256[] calldata loanPeriods
    ) external nonReentrant returns (bool){

        uint256 len = businessIds.length;
        if (len != NFTAddrs.length || len != NFTIds.length || len != loanPeriods.length) {
            revert ArrayLengthMismatch();
        }
        for (uint i = 0; i < len; ++i) {
            address NFTAddr = NFTAddrs[i];
            uint256 NFTId = NFTIds[i];

            if (!checkLoanStatus(NFTAddr, NFTId)) {
                revert OverdueLoan();
            }

            string memory businessId = businessIds[i];

            uint256 period = loanPeriods[i];

            require(checkLoanTime(businessId, NFTAddr, NFTId, period));

            LoanList storage list = loanList[NFTAddr][NFTId];
            address FTAddr = list.FTAddr;
            uint256 FTAmount = list.bill[businessId][period].amount;

            require(FTInterface(FTAddr).transferFrom(_msgSender(), loanCapitalPool, FTAmount), "FT transfer failed");

            CapitalPoolInterface(loanCapitalPool).depositFT(businessId, FTAddr, FTAmount);
            list.bill[businessId][period].status = true;
            list.repaymentAmount += FTAmount;
            list.billInfo[businessId].total -= FTAmount;

            if (list.billInfo[businessId].total == 0) {
                emit RepaymentCompleted(businessId, NFTAddr, NFTId);
            }

            if (list.repaymentAmount == list.repaymentTotal) {
                emit LoanCompleted(NFTAddr, NFTId);
            }
        }

        emit Repayment(businessIds, NFTAddrs, NFTIds, loanPeriods);

        return true;
    }

    function checkLoanStatus(
        address NFTAddr,
        uint256 NFTId
    ) public view returns (bool status){
        LoanList storage list = loanList[NFTAddr][NFTId];

        uint256 LoanTimes = list.businessIds.length;
        for (uint256 i = 0; i < LoanTimes; ++i) {
            string memory businessId = list.businessIds[i];
            uint256 loanPeriods = list.billInfo[businessId].periods;
            for (uint256 j = 1; j <= loanPeriods; ++j) {
                if (!list.bill[businessId][j].status) {
                    uint256 endTime = list.deadline - (list.billInfo[businessId].periods - j) * list.interval;
                    if (_blockTimestamp() > endTime) {
                        return false;
                    } else {
                        break;
                    }
                }
            }
        }
        return true;
    }


    function checkLoanTime(
        string memory businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 period
    ) public view returns (bool status){

        LoanList storage list = loanList[NFTAddr][NFTId];

        if (list.billInfo[businessId].creationTimestamp == 0) {
            revert BusinessIdNOTExists();
        }

        if (period == 0 || period > list.billInfo[businessId].periods) {
            revert PeriodNOTExists();
        }


        // 从前往后算
        // uint256 startTime = list.billInfo[businessId].creationTimestamp + list.billInfo[businessId].interval * (period - 1);
        // uint256 endTime = list.billInfo[businessId].creationTimestamp + list.billInfo[businessId].interval * period;

        // 从后往前算
        uint256 endTime = list.deadline - (list.billInfo[businessId].periods - period) * list.interval;
        uint256 startTime = endTime - list.interval;

        //require(_blockTimestamp() > startTime && _blockTimestamp() < endTime);
        if (_blockTimestamp() > endTime) {
            revert RepaymentExpires();
        }

        if (_blockTimestamp() < startTime) {
            revert RepaymentNotDue();
        }

        if (period == 1 && list.bill[businessId][period].status == false) {
            return true;
        } else if (list.bill[businessId][period].status == false && list.bill[businessId][period - 1].status == true) {
            return true;
        } else {
            revert OverdueLoan();
        }

    }

    /**
     * @notice Early cancellation of loan.
     *
     * @param businessIds Used as business differentiation.
     * @param NFTAddrs The ERC721 contract address.
     * @param NFTIds The id of ERC721 tokens.
     */
    function CancellationLoan(
        string[] calldata businessIds,
        address[] calldata NFTAddrs,
        uint256[] calldata NFTIds,
        uint256[] calldata damageRatios,
        bytes calldata managerSign
    ) external nonReentrant returns (bool){

        require(verify(businessIds, NFTAddrs, NFTIds, damageRatios, managerSign));

        uint256 len = businessIds.length;
        if (len != NFTAddrs.length || len != NFTIds.length) {
            revert ArrayLengthMismatch();
        }
        for (uint i = 0; i < len; ++i) {
            require(CancellationLoan(businessIds[i], NFTAddrs[i], NFTIds[i], damageRatios[i]));
        }

        emit Cancellation(businessIds, NFTAddrs, NFTIds);

        return true;
    }

    function CancellationLoan(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 damageRatio
    ) internal returns (bool){
        if (!checkLoanStatus(NFTAddr, NFTId)) {
            revert OverdueLoan();
        }
        LoanList storage list = loanList[NFTAddr][NFTId];

        uint256 ratio = damageRatio;
        address FTAddr = list.FTAddr;
        uint256 FTAmount = list.billInfo[businessId].FTAmount * (ratio + INVERSE_BASIS_POINT) / INVERSE_BASIS_POINT;

        require(FTInterface(FTAddr).transferFrom(_msgSender(), loanCapitalPool, FTAmount), "FT transfer failed");
        CapitalPoolInterface(loanCapitalPool).depositFT(businessId, FTAddr, FTAmount);

        delete loanList[NFTAddr][NFTId];
        return true;
    }

    function verify(
        string[] calldata businessIds,
        address[] calldata NFTAddrs,
        uint256[] calldata NFTIds,
        uint256[] calldata damageRatios,
        bytes calldata managerSign
    ) internal view returns (bool){
        bytes32 hash = keccak256(abi.encode(businessIds, NFTAddrs, NFTIds, damageRatios, _msgSender()));
        if (Ecrecovery.ecrecovery(hash, managerSign) != manager()) {
            revert IllegalManagerSign();
        }
        return true;
    }

    function getLoanAmount(
        address NFTAddr,
        uint256 NFTId
    ) external view returns (
        uint256 loanAmount,
        uint256 loanTotal,
        uint256 repaymentAmount
    ){
        return (loanList[NFTAddr][NFTId].loanAmount,
        loanList[NFTAddr][NFTId].repaymentTotal,
        loanList[NFTAddr][NFTId].repaymentAmount);
    }

    function getPeriodAmount(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 loanPeriod
    ) external view returns (
        uint256 PeriodAmount,
        bool status
    ){
        return (loanList[NFTAddr][NFTId].bill[businessId][loanPeriod].amount,
        loanList[NFTAddr][NFTId].bill[businessId][loanPeriod].status);
    }

    function getPeriodInfo(
        address NFTAddr,
        uint256 NFTId
    ) external view returns (
        address borrower,
        address FTAddr,
        uint256 loanRatio,
        string[] memory businessIds
    ){
        return (loanList[NFTAddr][NFTId].borrower,
        loanList[NFTAddr][NFTId].FTAddr,
        loanList[NFTAddr][NFTId].loanRatio,
        loanList[NFTAddr][NFTId].businessIds);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    error ReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        //require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        if(_status == _ENTERED){
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Ecrecovery{

function ecrecovery(
        bytes32 hash,
        bytes memory sig
    )
    internal
    pure
    returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        /* prefix might be needed for geth only
        * https://github.com/ethereum/go-ethereum/issues/3731
        */
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        bytes32 Hash = keccak256(abi.encodePacked(prefix, hash));

        return ecrecover(Hash, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Manageable is Ownable {
    address private _manager;

    event ManagershipTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    constructor() {
        _transferManagership(_txOrigin());
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        _checkManager();
        _;
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if the sender is not the manager.
     */
    function _checkManager() internal view virtual {
        require(manager() == _txOrigin(), "Managerable: caller is not the manager");
    }

    /**
     * @dev Transfers managership of the contract to a new account (`newManager`).
     * Can only be called by the current owner.
     */
    function transferManagership(address newManager) public virtual onlyOwner {
        require(newManager != address(0), "Managerable: new manager is the zero address");
        _transferManagership(newManager);
    }

    /**
     * @dev Transfers Managership of the contract to a new account (`newManager`).
     * Internal function without access restriction.
     */
    function _transferManagership(address newManager) internal virtual {
        address oldManager = _manager;
        _manager = newManager;
        emit ManagershipTransferred(oldManager, newManager);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @title LoanStructs
 * @author lixin
 * @notice LoamStructs contains all structs, enums for Loan contracts.
 */
interface LoanStructs {
    struct LoanList {

        address borrower; //borrower
        address NFTAddr; //Loan NFT contract address
        uint256 NFTId; // NFT Id of loan
        uint256 NFTPrice;//Price of pledged NFT
        address FTAddr;

        uint256 loanRatio;//Limit ratio of loan NFT
        uint256 loanAmount;// 抵押一个NFT后，已经借的金额
        uint256 repaymentTotal;//  抵押一个NFT后，需要还的金额
        uint256 repaymentAmount;//  抵押一个NFT后，已经还的金额

        uint256 creationTimestamp;// 第一笔贷款的创建时间
        uint256 interval;// 第一笔贷款的还款间隔期
        uint256 periods;// 第一笔贷款的还款周期
        uint256 deadline;// 第一笔贷款的截止期，也是所有贷款的截至期

        string[] businessIds;

        // businessId => period => LoanStatus
        // period start with 1
        mapping(string => mapping(uint256 => LoanStatus)) bill;
        //businessID => billInfo
        mapping(string => LoanDate) billInfo;

    }

    struct LoanStatus{
        uint256 amount;
        bool status;
    } 

    struct LoanDate{
        uint256 creationTimestamp;
        uint256 FTAmount;
        uint256 serviceRatio;
        uint256 total;//该笔贷款需要还的金额
        uint256 interval;
        uint256 periods;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface FTInterface {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface NFTInterface {
    function loanRatio() external returns (uint256 loanRatio);

    function repurchaseRatio() external view returns (uint256 repurchaseRatio);

    function checkRepurchaseDeadline() external view returns (uint256 deadline);

    function checkPrice(uint256 tokenId) external view returns (address tokenAddr, uint256 tokenAmount);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC721Receiver.sol";

/**
 * @title CapitalPoolInterface
 * @author lixin
 * @notice CapitalPoolInterface contains all external function interfaces, events,
 *         and errors for CapitalPool contracts.
 */

interface CapitalPoolInterface is IERC721Receiver {

    /**
     * @dev Emit an event when receive a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    event ReceiveFT(string businessId, address tokenAddr, uint256 tokenAmount);

    /**
     * @dev Emit an event when Withdraw a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     * @param recipient The Address to receive FT.
     */
    event WithdrawFT(string businessId, address tokenAddr, uint256 tokenAmount, address recipient);

    /**
     * @dev Emit an event when receive a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     */
    event ReceiveNFT(string businessId, address tokenAddr, uint256 tokenId);

    /**
     * @dev Emit an event when Withdraw a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     * @param recipient The Address to receive NFT.
     */
    event WithdrawNFT(string businessId, address tokenAddr, uint256 tokenId, address recipient);

    /**
     * @dev Emit an event when pledge contract changed.
     *
     * @param oldPledge The old pledge contract address.
     * @param newPledge The new pledge contract address.
     */
    event PledgeChanged(address oldPledge, address newPledge);

    /**
     * @dev Emit an event when pledge loan changed.
     *
     * @param oldLoan The old loan contract address.
     * @param newLoan The new loan contract address.
     */
    event LoanChanged(address oldLoan, address newLoan);

    error NoFTReceived();

    error BusinessIdUsed();

    /**
     * @dev Revert with an error when run failed.
     */
    error failed();

    /**
     * @notice receive a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function depositFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount
    )external returns (bool);

    /**
     * @notice Only loan contract can withdraw a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     * @param recipient The Address to receive FT.
     */
    function withdrawFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount,
        address recipient
    )external returns (bool);

    /**
     * @notice Only manager can withdraw a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     * @param recipient The Address to receive FT.
     */
    function withdrawFTManager(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount,
        address recipient
    )external returns (bool);

    // /**
    //  * @notice receive a NFT.
    //  *
    //  * @param businessId Used as business differentiation.
    //  * @param tokenAddr The ERC721 contract address.
    //  * @param tokenId The id of ERC721 tokens.
    //  */
    // function depositNFT(
    //     string calldata businessId,
    //     address tokenAddr,
    //     uint256 tokenId
    // )external returns (bool);

    /**
     * @notice Only pledge can withdraw a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     * @param recipient The Address to receive FT.
     */
    function withdrawNFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenId,
        address recipient
    )external returns (bool);

    /**
     * @notice Only manager withdraw a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     * @param recipient The Address to receive NFT.
     */
    function withdrawNFTManager(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenId,
        address recipient
    )external returns (bool);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/PledgeStructs.sol";
import "./CommonInterface.sol";

/**
 * @title PledgeInterface
 * @author lixin
 * @notice PledgeInterface contains all external function interfaces, events,
 *         and errors for Pledge contracts.
 */
interface PledgeInterface is CommonInterface, PledgeStructs{


    /**
     * @dev Emit an event when receive a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param NFTAddr The ERC721 contract address.
     * @param NFTId The ID of ERC721 NFT.
     * @param FTAddr The ERC20 contract address to borrow.
     */
    event PledgeNFT(string businessId, address NFTAddr, uint256 NFTId, address FTAddr, address capitalPool);

    /**
     * @dev Emit an event when release the user's NFT by the user. 
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The ID of ERC721 NFT.
     * @param recipient The address recipient NFT.
     */
    event ReleaseNFT(string businessId, address tokenAddr, uint256 tokenId, address recipient);

    /**
     * @dev Emit an event when force to close out the user's NFT by the platform party.
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The ID of ERC721 NFT.
     * @param recipient The address recipient NFT.
     */
    event CloseOutNFT(string businessId, address tokenAddr, uint256 tokenId, address recipient);


    /**
     * @dev Emit an event when pledge loan changed.
     *
     * @param oldLoan The old loan contract address.
     * @param newLoan The new loan contract address.
     */
    event LoanChanged(address oldLoan, address newLoan);


    /**
    * @dev Revert with an error when ERC721 NFT transfer failed.
     */
    error NFTTransferFailed();

    /**
     * @dev Revert with an error when Overdue loan.
     */
    error OverdueLoan();

    /**
     * @dev Revert with an error when The loan is not overdue
     */
    error NOTOverdueLoan();

    /**
     * @dev Revert with an error when Outstanding loan
     */
    error LoanNotFinished();





    /**
     * @notice Receive NFT pledged by users and transfer NFT to capitalPool contract.
     *
     * @param businessId Used as business differentiation.
     * @param NFTAddr The ERC721 contract address.
     * @param NFTId The ID of ERC721 NFT.
     * @param FTAddr The ERC20 contract address to borrow.
     *
     * @return bool Whether the user's NFT is successfully received.
     */
    function pledgeNFT(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        address FTAddr
    ) external returns (bool);


    /**
     * @notice Release the user's NFT and return it to the address provided by the user. 
     *         Use the safeTransferFrom method of ERC721.
     *
     * @param businessId Used as business differentiation.
     * @param NFTAddr The ERC721 contract address.
     * @param NFTId The ID of ERC721 NFT.
     * @param managerSign Manager's signature on and call parameters.
     *
     * @return bool Whether the user's NFT is successfully released.
     */
    function releaseNFT(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        bytes memory managerSign
    ) external returns (bool);

    /**
     * @notice Force to close out the user's NFT and transfer it to the address specified by the platform party.
     *         Use the safeTransferFrom method of ERC721.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The ID of ERC721 NFT.
     * @param recipient The Address to receive NFT.
     *
     * @return bool Whether the user's NFT is forced to close.
     */
    function closeOutNFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenId,
        address recipient
    ) external returns (bool);

    function checkMortgageNote(
        address NFTAddr_,
        uint256 NFTId_
    ) external returns (
        Note memory
    );



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CommonInterface.sol";
import "../lib/LoanStructs.sol";
/**
 * @title LoanInterface
 * @author lixin
 * @notice LoanInterface contains all external function interfaces, events,
 *         and errors for Loan contracts.
 */
interface LoanInterface is CommonInterface {

    /**
     * @dev Emit an event when inject a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddrs The ERC20 contract address.
     * @param tokenAmounts The amount of ERC20 tokens.
     */
    event InjectFT(string businessId, address[] tokenAddrs, uint256[] tokenAmounts);

    /**
     * @dev Emit an event when Withdraw a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    event WithdrawFT(string businessId, address[] tokenAddr, uint256[] tokenAmount);

    /**
     * @dev Emit an event when user loan FT.
     *
     * @param businessId Used as business differentiation.
     * @param NFTAddr The ERC721 contract address.
     * @param NFTId The id of ERC721 tokens.
     * @param FTAddr The amount of ERC20 tokens.
     * @param FTAmount The amount of ERC20 tokens.
     */
    event Loan(string businessId, address NFTAddr, uint256 NFTId, address FTAddr, uint256 FTAmount);

    /**
     * @dev Emit an event when user repayment FT.
     *
     * @param businessIds Used as business differentiation.
     * @param NFTAddrs The ERC721 contract address.
     * @param NFTIds The id of ERC721 tokens.
     * @param loanPeriods period number of the loan order.
     */
    event Repayment(string[] businessIds, address[] NFTAddrs, uint256[] NFTIds, uint256[] loanPeriods);

    event RepaymentCompleted(string businessId, address NFTAddr, uint256 NFTId);


    event LoanCompleted(address NFTAddr, uint256 NFTId);

    /**
     * @dev Emit an event when user cancel loan.
     *
     * @param businessIds Used as business differentiation.
     * @param NFTAddrs The ERC721 contract address.
     * @param NFTIds The id of ERC721 tokens.
     */
    event Cancellation(string[] businessIds, address[] NFTAddrs, uint256[] NFTIds);

    /**
     * @dev Emit an event when pledge contract changed.
     *
     * @param oldPledge The old pledge contract address.
     * @param newPledge The new pledge contract address.
     */
    event PledgeChanged(address oldPledge, address newPledge);

    /**
     * @dev Emit an event when capital pool contract changed.
     *
     * @param oldDamageRatio The old damage ratio.
     * @param newDamageRatio The new damage ratio.
     */
    event DamageRatioChanged(uint256 oldDamageRatio, uint256 newDamageRatio);


    event MinLoanFTAmountChanged(uint256 oldMinLoanFTAmount, uint256 newMinLoanFTAmount);


    /**
     * @dev Revert with an error when ERC20 Insufficient authorization.
     */
    error InsufficientApprove();

    /**
     * @dev Revert with an error when Insufficient ERC20 balance of payment account.
     */
    error InsufficientBalance();


    /**
     * @dev Revert with an error when businessId ID already exists
     */
    error BusinessIdExists();

    /**
     * @dev Revert with an error when businessId ID not exists
     */
    error BusinessIdNOTExists();

    error PeriodNOTExists();


    error RepaymentExpires();

    error RepaymentNotDue();




    /**
     * @dev Revert with an error when exceeding the upper limit of loan amount
     */
    error LoanAmountUpperLimit();

    /**
     * @dev Revert with an error when exceeding the lower limit of loan amount
     */
    error LoanAmountLowerLimit();

    /**
     * @dev Revert with an error when array length mismatch
     */
    error ArrayLengthMismatch();

    /**
     * @dev Revert with an error when Overdue loan
     */
    error OverdueLoan();

    error RepaymentPeriodExceedsRepurchasePeriod();

    error IllegalRepayment();


    function setPledge(address newPledge) external;

    /**
    * @notice Inject funds into the capital pool.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function injectFT(
        string calldata businessId,
        address[] calldata tokenAddr,
        uint256[] calldata tokenAmount
    ) external returns (bool);


    /**
     * @notice Only manager withdraw a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenAmount The id of ERC721 tokens.
     */
    function withdrawFTManager(
        string calldata businessId,
        address[] calldata tokenAddr,
        uint256[] calldata tokenAmount
    ) external returns (bool);

    /**
     * @notice User loan FT from the capital pool.
     *
     * @param businessId Used as business differentiation.
     * @param NFTAddr The ERC721 contract address.
     * @param baseInfo [NFTId, FTAmount, serviceRatio, creationTimestamp, interval]
     *              NFTId The id of ERC721 tokens.
     *              FTAmount The amount of ERC20 tokens.
     *              serviceRatio the  Ratio of Service.
     *              creationTimestamp The loan list creation time in seconds.
     *              interval The Interval of each repayment in seconds.
     * @param eachAmounts Amount to be repaid for each loan.
     * @param managerSign Manager's signature on and call parameters.
     */
    function loan(
        string calldata businessId,
        address NFTAddr,
        uint256[] calldata baseInfo,
        uint256[] calldata eachAmounts,
        bytes calldata managerSign
    ) external returns (bool);

    /**
     * @notice Repayment of loan to the capital pool.
     *
     * @param businessIds Used as business differentiation.
     * @param NFTAddrs The ERC721 contract address.
     * @param NFTIds The id of ERC721 tokens.
     * @param loanPeriods period number of the loan order.
     */
    function repayment(
        string[] calldata businessIds,
        address[] calldata NFTAddrs,
        uint256[] calldata NFTIds,
        uint256[] calldata loanPeriods
    ) external returns (bool);

    /**
     * @notice Early cancellation of loan.
     *
     * @param businessIds Used as business differentiation.
     * @param NFTAddrs The ERC721 contract address.
     * @param NFTIds The id of ERC721 tokens.
     * @param damageRatios The damage Ratio of cancellation.
     * @param managerSign manager Sign.
     */
    function CancellationLoan(
        string[] calldata businessIds,
        address[] calldata NFTAddrs,
        uint256[] calldata NFTIds,
        uint256[] calldata damageRatios,
        bytes calldata managerSign
    ) external  returns (bool);

    function checkLoanStatus(
        address NFTAddr,
        uint256 NFTId
    ) external returns (bool status);

    function getLoanAmount(
        address NFTAddr,
        uint256 NFTId
    ) external returns (
        uint256 loanAmount,
        uint256 loanTotal,
        uint256 repaymentAmount
    );

    function getPeriodAmount(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 loanPeriod
    ) external view returns (
        uint256 PeriodAmount,
        bool status
    );

    function getPeriodInfo(
        address NFTAddr,
        uint256 NFTId
    ) external view returns (
        address borrower,
        address FTAddr,
        uint256 loanRatio,
        string[] memory businessIds
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _transferOwnership(_txOrigin());
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
        require(owner() == _txOrigin(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.0;

interface CommonInterface {

    /**
     * @dev Emit an event when capitalPool contract changed.
     * @param oldCapitalPool The old capitalPool.
     * @param newCapitalPool The new capitalPool.
     */
    event CapitalPoolChanged(address oldCapitalPool, address newCapitalPool);

    /**
     * @dev Revert with an error when manager signature is incorrect.
     */
    error IllegalManagerSign();

    /**
     * @dev Revert with an error when Loan other
     */
    error NOTYOURNFT();

    error RepurchasePeriodExpired();
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @title PledgeStructs
 * @author lixin
 * @notice PledgeStructs contains all structs, enums for Pledge contracts.
 */
interface PledgeStructs {
    struct MortgageNote{
        address mortgagor; //mortgagor
        address NFTAddr; //Mortgaged NFT contract address
        uint256 NFTId;//NFT Id of mortgage
        uint256 NFTPrice;//Price of pledged NFT
        address FTAddr;//Currency of pledged NFT
        address capitalPool;//Address of capital pool contract receiving NFT
        uint256 loanRatio;//Limit ratio of loan NFT
    }

    struct Note{
        address mortgagor; //mortgagor
        uint256 NFTPrice;//Price of pledged NFT
        address FTAddr;//Currency of pledged NFT
        uint256 loanRatio;//Limit ratio of loan NFT
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

}