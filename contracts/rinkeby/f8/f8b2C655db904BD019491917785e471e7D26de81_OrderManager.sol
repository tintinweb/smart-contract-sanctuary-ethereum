// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/// @title Order Manager Contract
/// @author Amarandei Matei Alexandru (@Alex-Amarandei)
/// @notice Simulates Order Management for a Platform providing arbitrage services
/**
 * @dev The contract is responsible with managing the in/outflow of funds
 * Its functions are used to provide the following logic:
 * - User places an order and pays a fee for covering gas costs
 * - The order's status will be set to PENDING
 * - A script belonging to the Platform executes profitable orders
 * - On Success, changes the status to COMPLETED and sends
 *   to the Platform's wallet the corresponding funds
 *   from the user's "account"
 * - On Failure, marks the order as REJECTED
 * - A user may cancel its order, which will set its status
 *   to DELETED and issue a refund
 * The logic is a rudimentary meta-transaction & relayer scenario
 */
contract OrderManager {
    enum Status {
        PENDING,
        COMPLETED,
        REJECTED,
        DELETED
    }

    struct Order {
        uint256 id;
        uint256 fee;
        Status status;
        address userAddress;
        address token0Address;
        address token1Address;
        bytes32 txHash;
    }

    address payable private owner;
    uint256 public fee;
    uint256 public currentId;
    mapping(address => uint256) public userGasAmounts;
    mapping(uint256 => Order) public userOrdersById;
    mapping(address => uint256) public userOrderCount;

    /// @param _fee The fee to be paid when an order is placed by a user
    /// @notice The id of the next order will be initially 1
    /// @dev The owner address for the later funding of the platform's wallet
    constructor(uint256 _fee) {
        fee = _fee;
        currentId = 1;
        owner = payable(msg.sender);
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @param _userAddress The address that paid the fee
     * when creating an order on the platform
     */
    /// @notice The corresponding "account" will be "credited"
    function fundWithGas(address _userAddress) internal {
        userGasAmounts[_userAddress] += fee;
    }

    /**
     * @param _id The id of the order that needs to be deleted
     * @param _all Whether or not the user wishes
     * to cancel all existing orders
     */
    /**
     * @notice Called by a user when cancelling an order
     * Issues a refund and calls another function to update
     * the status of the order(s) to DELETED
     */
    function refundGas(uint256 _id, bool _all) public {
        require(
            userOrdersById[_id].userAddress == msg.sender,
            "You do not have authority over another user's account."
        );
        require(
            userOrdersById[_id].status == Status.PENDING ||
                userOrdersById[_id].status == Status.REJECTED,
            "You cannot get a refund for a successful or an already retracted order."
        );

        address payable user = payable(msg.sender);

        if (_all) {
            user.transfer(userGasAmounts[msg.sender]);
            userGasAmounts[msg.sender] = 0;
        } else {
            require(
                userGasAmounts[msg.sender] >= userOrdersById[_id].fee,
                "This account has no associated funds left or not enough for the fee to be refunded!"
            );

            user.transfer(userOrdersById[_id].fee);
            userGasAmounts[msg.sender] -= userOrdersById[_id].fee;
        }

        cancelOrders(msg.sender, _id, _all);
    }

    /**
     * @param _userAddress The address of the user cancelling
     * @param _id The id of the order to be cancelled
     * Disregarded if _all is true
     * @param _all Whether or not the user wishes
     * to cancel all existing orders
     */
    /// @notice Updates the status of the order(s) to DELETED
    function cancelOrders(
        address _userAddress,
        uint256 _id,
        bool _all
    ) internal {
        if (_all) {
            for (uint256 i = 1; i < currentId; i++) {
                if (userOrdersById[i].userAddress == _userAddress) {
                    userOrdersById[i].status = Status.DELETED;
                }
            }
        } else {
            userOrdersById[_id].status = Status.DELETED;
        }
    }

    /// @param _id The id of the order that was fulfilled
    /**
     * @notice Called in case of successful completion of an order
     * Sends the fee paid by the user to the Platform's Wallet
     */
    function useGas(uint256 _id) internal {
        require(
            userGasAmounts[userOrdersById[_id].userAddress] >=
                userOrdersById[_id].fee,
            "This account has no associated funds left or not enough for the fee to be used!"
        );

        owner.transfer(userOrdersById[_id].fee);
        userGasAmounts[userOrdersById[_id].userAddress] -= userOrdersById[_id]
            .fee;
    }

    /// @param _newFee The new fee of placing an order
    /**
     * @notice Updates the fee charged by the platform
     * in order to cover the gas fees of executing an order
     */
    function updateFee(uint256 _newFee) external ownerOnly {
        fee = _newFee;
    }

    /**
     * @param _token0Address The address of the first token
     * @param _token1Address The address of the second token
     */
    /**
     * @notice Creates an order object representing the wish
     * of the user for the platform to
     * follow arbitrage opportunities on this specific pair
     * along with the necessary data such as id, fee etc.
     */
    function createOrder(address _token0Address, address _token1Address)
        external
        payable
    {
        require(msg.value == fee, "You need to send exactly the fee in ETH!");

        fundWithGas(msg.sender);

        userOrdersById[currentId] = Order({
            id: currentId,
            fee: fee,
            status: Status.PENDING,
            userAddress: msg.sender,
            token0Address: _token0Address,
            token1Address: _token1Address,
            txHash: keccak256("0")
        });

        userOrderCount[msg.sender] += 1;
        currentId += 1;
    }

    /**
     * @param _id The id of the order to be updated
     * @param _status The status with which to update it
     * @param _txHash The hash of the transaction marking
     * the successful completion of the order, else 0x0...0
     */
    /// @notice Updates the status of an order
    function updateOrder(
        uint256 _id,
        uint8 _status,
        bytes32 _txHash
    ) external ownerOnly {
        if (_status == uint256(Status.COMPLETED)) {
            useGas(_id);
        }
        userOrdersById[_id].status = Status(_status);
        userOrdersById[_id].txHash = _txHash;
    }

    /// @param _userAddress The address for which to retrieve orders
    /// @return An array of order objects
    /**
     * @notice Returns a user's orders or all orders
     * if _userAddress is 0x0...0 (the zero address)
     */
    function getOrders(address _userAddress)
        external
        view
        returns (Order[] memory)
    {
        if (_userAddress == address(0)) {
            Order[] memory orders = new Order[](currentId - 1);

            for (uint256 i = 1; i < currentId; i++) {
                orders[i - 1] = userOrdersById[i];
            }

            return orders;
        } else {
            uint256 orderCount = 0;
            Order[] memory orders = new Order[](userOrderCount[_userAddress]);

            for (uint256 i; i < currentId; i++) {
                if (orderCount == orders.length) {
                    break;
                }

                if (userOrdersById[i].userAddress == _userAddress) {
                    orders[orderCount] = userOrdersById[i];
                    orderCount++;
                }
            }

            return orders;
        }
    }
}