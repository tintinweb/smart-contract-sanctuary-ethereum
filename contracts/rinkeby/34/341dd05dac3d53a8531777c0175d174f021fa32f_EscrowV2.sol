//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// import "hardhat/console.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";

/// @title EscrowV1
/// @author garyb9
contract EscrowV2 is ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                 DEFINITIONS
    //////////////////////////////////////////////////////////////*/
    address public operator; // @audit-info consider adding more operator? maybe role-based access (use open zeppelin's `AccessControl.sol`)
    
    mapping(address => bool) public blockedAssets;
 
    enum Status{ NULL, SUBMITTED, RESOLVED, TIMEDOUT }

    struct Swap {
        Status status;
        uint256 deadline;
        address asset;
        address sender;
        address recipient;
        uint256 amount;
        bytes32 secretHashed;
    }

    mapping(bytes32 => Swap) public swaps;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
 
    error AddressNotOperator();
    error BlockedAsset();
    error SwapExists();
    error SwapNotSubmitted();
    error DeadlineLowerThanMinimum();
    error IncorrectSecret();
    error IncorrectRecipient();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OperatorChanged(address indexed op);
    event BlockedAssetAdded(address indexed asset);
    event BlockedAssetRemoved(address indexed asset);
    event SwapSubmitted(bytes32 indexed swapID, address indexed sender, address indexed asset);
    event SwapResolved(bytes32 indexed swapID, address indexed recipient, address indexed asset);
    event SwapTimedout(bytes32 indexed swapID, address indexed recipient, address indexed asset);

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /** @notice Only operator addresses can call functions that use this modifier
      */
    modifier onlyOperator() {
        if(msg.sender != operator)
            revert AddressNotOperator();
        _;
    }

    /** @notice Only operator addresses can call functions that use this modifier
      */
    modifier verifyAllowedAsset(address asset) {
        if(blockedAssets[asset] == true)
            revert BlockedAsset();
        _;
    }

    /** @notice Verifies if swap is executable
      * @param swapID unique hash for this swap
      */
    modifier verifyNullSwap(bytes32 swapID) {
        if(swaps[swapID].status != Status.NULL)
            revert SwapExists();
        _;
    }

    /** @notice Verifies if swap iks submitted
      * @param swapID unique hash for this swap
      */
    modifier verifySubmittedSwap(bytes32 swapID) {
        if(swaps[swapID].status != Status.SUBMITTED)
            revert SwapNotSubmitted();
        _;
    }

    /** @notice Verifies deadline
      * @param deadline unique hash for this swap
      */
    modifier verifyDeadline(uint256 deadline) {
        if(deadline < block.timestamp + 3 hours)
            revert DeadlineLowerThanMinimum();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /** @notice Contract constructor
      * @param _operator Operator (Swift) address
      */
    constructor(address _operator) {
        operator = _operator;
        emit OperatorChanged(_operator);
    }


    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/
 
    /** @notice Set a new opeartor (only current operator can change)
      * @param _operator Operator address
      */

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
        emit OperatorChanged(_operator);
    }

    /** @notice Add a new blocked asset (only operator)
      * @param _asset Asset address
      */

    function addBlockedAsset(address _asset) external onlyOperator {
        blockedAssets[_asset] = true;
        emit BlockedAssetAdded(_asset);
    }


    /** @notice Remove a blocked asset (only operator)
      * @param _asset Asset address
      */
    function removeBlockedAsset(address _asset) external onlyOperator {
        blockedAssets[_asset] = false;
        emit BlockedAssetRemoved(_asset);
    }

    /** @notice Submit swap with details
      * @param swapID unique hash for this swap
      * @param asset Asset address
      * @param recipient Recipient address
      * @param amount Amount of assets submitted for swap
      * @param deadline Unix timestamp of the swap deadline
      * @param secretHashed hash of the secret key
      */
    function submitSwap(
        bytes32 swapID,
        address asset,
        address recipient,
        uint256 amount,
        uint256 deadline,
        bytes32 secretHashed
    ) external nonReentrant verifyNullSwap(swapID) verifyDeadline(deadline) {
        require(
            IERC20(asset).allowance(msg.sender, address(this)) >= amount,
            "Insufficient allowance"
        );

        swaps[swapID] = Swap({
            status: Status.SUBMITTED,
            asset: asset,
            sender: msg.sender,
            recipient: recipient,
            amount: amount,
            deadline: deadline,
            secretHashed: secretHashed
        });

        bool success = IERC20(asset).transferFrom(
            msg.sender, 
            address(this), 
            amount
        );
        require(success == true, "Transfer failed");

        emit SwapSubmitted(swapID, msg.sender, asset);
    }

    /** @notice Resolve a swap
      * @param swapID unique hash for this swap
      * @param secretKey string of secret key
      */

    function resolveSwap(
        bytes32 swapID,
        string memory secretKey
    ) external nonReentrant verifySubmittedSwap(swapID) {
        Swap memory sw = swaps[swapID];

        if(keccak256(abi.encodePacked(secretKey)) != sw.secretHashed) {
            revert IncorrectSecret();
        }
        if(sw.recipient != msg.sender){ // MEV protection
            revert IncorrectRecipient();
        }

        require(
            IERC20(sw.asset).balanceOf(address(this)) >= sw.amount,
            "Insufficient balance"
        );
        
        if (sw.deadline < block.timestamp){
            sw.status = Status.TIMEDOUT;
            swaps[swapID] = sw;
            bool success = IERC20(sw.asset).transfer(sw.sender, sw.amount);
            require(success == true, "Transfer failed"); 
            emit SwapTimedout(swapID, sw.sender, sw.asset);
        }
        else {
            sw.status = Status.RESOLVED;
            swaps[swapID] = sw;
            bool success = IERC20(sw.asset).transfer(sw.recipient, sw.amount);
            require(success == true, "Transfer failed"); 
            emit SwapResolved(swapID, sw.recipient, sw.asset);
        }
    }


    // @audit-info these two functions are for withdrawing and depositing ETH
    /**
     * @dev allow withdrawals of ETH (only by Operator)
     */
    function withdraw (address payable _to, uint256 _amount) external onlyOperator {
        // Call returns a boolean value indicating success or failure.
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = _to.call{value: _amount}(""); // second arg: `bytes memory data`
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev allow deposits of ETH (fallback guard for ETH transfers)
     * executes on calls to the contract with no calldata
     */
    // solhint-disable-next-line no-empty-blocks
    receive () external payable {}
}