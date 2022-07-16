/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}




            
pragma solidity ^0.8.3;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct FeeInfo {
    address collectionAddress;
    uint32 feeBasisPoints;
    uint32 bullaTokenThreshold; //# of BULLA tokens held to get fee reduction
    uint32 reducedFeeBasisPoints; //reduced fee for BULLA token holders
}

interface IBullaManager {
    event FeeChanged(
        address indexed bullaManager,
        uint256 prevFee,
        uint256 newFee,
        uint256 blocktime
    );
    event CollectorChanged(
        address indexed bullaManager,
        address prevCollector,
        address newCollector,
        uint256 blocktime
    );
    event OwnerChanged(
        address indexed bullaManager,
        address prevOwner,
        address newOwner,
        uint256 blocktime
    );
    event BullaTokenChanged(
        address indexed bullaManager,
        address prevBullaToken,
        address newBullaToken,
        uint256 blocktime
    );
    event FeeThresholdChanged(
        address indexed bullaManager,
        uint256 prevFeeThreshold,
        uint256 newFeeThreshold,
        uint256 blocktime
    );
    event ReducedFeeChanged(
        address indexed bullaManager,
        uint256 prevFee,
        uint256 newFee,
        uint256 blocktime
    );

    function setOwner(address _owner) external;

    function setFee(uint32 _feeBasisPoints) external;

    function setCollectionAddress(address _collectionAddress) external;

    function setbullaThreshold(uint32 _threshold) external;

    function setReducedFee(uint32 reducedFeeBasisPoints) external;

    function setBullaTokenAddress(address _bullaTokenAddress) external;

    function getBullaBalance(address _holder) external view returns (uint256);

    function getFeeInfo(address _holder)
        external
        view
        returns (uint32, address);
    
    function getTransactionFee(address _holder, uint paymentAmount) external view returns(address sendFeesTo, uint transactionFee);
}



pragma solidity ^0.8.7;

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "./interfaces/IBullaManager.sol";

error NotContractOwner(address _sender);
error ZeroAddress();
error ValueMustBeGreaterThanZero();

contract BullaManager is IBullaManager {
    bytes32 public immutable description;
    FeeInfo public feeInfo;
    IERC20 public bullaToken;
    address public owner;

    modifier onlyOwner() {
        if (owner != msg.sender) revert NotContractOwner(msg.sender);
        _;
    }

    constructor(
        bytes32 _description,
        address payable _collectionAddress,
        uint32 _feeBasisPoints
    ) {
        owner = msg.sender;
        feeInfo.collectionAddress = _collectionAddress;
        description = _description;
        feeInfo.feeBasisPoints = _feeBasisPoints;

        emit FeeChanged(address(this), 0, _feeBasisPoints, block.timestamp);
        emit CollectorChanged(
            address(this),
            address(0),
            _collectionAddress,
            block.timestamp
        );
        emit OwnerChanged(
            address(this),
            address(0),
            msg.sender,
            block.timestamp
        );
    }

    function setOwner(address _newOwner) external override onlyOwner {
        if(_newOwner == address(0)) revert ZeroAddress();
        owner = _newOwner;
        emit OwnerChanged(address(this), owner, _newOwner, block.timestamp);
    }

    function setFee(uint32 _feeBasisPoints) external override onlyOwner {
        if(_feeBasisPoints == 0) revert ValueMustBeGreaterThanZero();
        uint32 oldFee = feeInfo.feeBasisPoints;
        feeInfo.feeBasisPoints = _feeBasisPoints;
        emit FeeChanged(
            address(this),
            oldFee,
            feeInfo.feeBasisPoints,
            block.timestamp
        );
    }

    function setCollectionAddress(address _collectionAddress)
        external
        override
        onlyOwner
    {
        if(_collectionAddress == address(0)) revert ZeroAddress();
        feeInfo.collectionAddress = _collectionAddress;
        emit CollectorChanged(
            address(this),
            feeInfo.collectionAddress,
            _collectionAddress,
            block.timestamp
        );
    }

    //Set threshold of BULLA tokens owned that are required to receive reduced fee
    function setbullaThreshold(uint32 _threshold) external override onlyOwner {
        feeInfo.bullaTokenThreshold = _threshold;
        emit FeeThresholdChanged(
            address(this),
            feeInfo.bullaTokenThreshold,
            _threshold,
            block.timestamp
        );
    }

    //reduced fee if threshold of BULLA tokens owned is met
    function setReducedFee(uint32 reducedFeeBasisPoints)
        external
        override
        onlyOwner
    {
        if(reducedFeeBasisPoints == 0) revert ValueMustBeGreaterThanZero();
        uint32 oldFee = feeInfo.reducedFeeBasisPoints;
        feeInfo.reducedFeeBasisPoints = reducedFeeBasisPoints;
        emit FeeChanged(
            address(this),
            oldFee,
            feeInfo.feeBasisPoints,
            block.timestamp
        );
    }

    //set the contract address of BULLA ERC20 token
    function setBullaTokenAddress(address _bullaTokenAddress)
        external
        override
        onlyOwner
    {
        if(_bullaTokenAddress == address(0)) revert ZeroAddress();
        bullaToken = IERC20(_bullaTokenAddress);
        emit BullaTokenChanged(
            address(this),
            address(bullaToken),
            _bullaTokenAddress,
            block.timestamp
        );
    }

    //get the amount of BULLA tokens held by a given address
    function getBullaBalance(address _holder)
        public
        view
        override
        returns (uint256)
    {
        uint256 balance = address(bullaToken) == address(0)
            ? 0
            : bullaToken.balanceOf(_holder);
        return balance;
    }

    function getFeeInfo(address _holder)
        public
        view
        override
        returns (uint32, address)
    {
        uint256 bullaTokenBalance = getBullaBalance(_holder);
        uint32 fee = feeInfo.bullaTokenThreshold > 0 &&
            bullaTokenBalance >= feeInfo.bullaTokenThreshold
            ? feeInfo.reducedFeeBasisPoints
            : feeInfo.feeBasisPoints;

        return (fee, feeInfo.collectionAddress);
    }

    function getTransactionFee(address _holder, uint paymentAmount) external view override returns(address sendFeesTo, uint transactionFee){
        (uint32 fee, address collectionAddress ) = getFeeInfo(_holder);
        sendFeesTo = collectionAddress;
        transactionFee = fee > 0 ? (paymentAmount * fee) / 10000 : 0;
    }
}