// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

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
        address txHash;
    }

    address payable private owner;
    uint256 public fee;
    uint256 public currentId;
    mapping(address => uint256) public userGasAmounts;
    mapping(uint256 => Order) public userOrdersById;
    mapping(address => uint256) public userOrderCount;

    constructor(uint256 _fee) {
        owner = payable(msg.sender);
        fee = _fee;
        currentId = 1;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    function fundWithGas(address _userAddress) internal {
        userGasAmounts[_userAddress] += fee;
    }

    function refundGas(uint256 _id, bool _all) public {
        require(
            userOrdersById[_id].userAddress == msg.sender,
            "You do not have authority over another user's account."
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

    function updateFee(uint256 _newFee) external ownerOnly {
        fee = _newFee;
    }

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
            txHash: address(0)
        });

        userOrderCount[msg.sender] += 1;
        currentId += 1;
    }

    function updateOrder(
        uint256 _id,
        uint8 _status,
        address _txHash
    ) external ownerOnly {
        if (_status == uint256(Status.COMPLETED)) {
            useGas(_id);
        }
        userOrdersById[_id].status = Status(_status);
        userOrdersById[_id].txHash = _txHash;
    }

    function getOrders(address _userAddress)
        external
        view
        returns (Order[] memory)
    {
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