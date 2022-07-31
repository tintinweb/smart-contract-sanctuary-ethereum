// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract Service {
    event Transfer(
        bytes32 sub,
        address indexed token,
        address indexed user,
        address indexed boss,
        uint256 amount
    );

    event Subscription(
        bytes32 sub,
        bytes32 plan,
        address indexed token,
        address indexed user,
        address indexed boss,
        uint256 cost
    );

    event Close(bytes32 sub);

    struct subStruct {
        bytes32 sub;
        bytes32 plan;
        address token;
        address user;
        address boss;
        uint256 cost;
    }

    uint256 private constant secondsInDay = 1 days;

    mapping(bytes32 => subStruct) public subscriptions;

    mapping(bytes32 => uint256) public lastPaid;

    bytes32[] public store;

    // get Store Length
    function storeLength() public view returns (uint256) {
        return store.length;
    }

    function getTokenSymbol(address _token)
        public
        view
        returns (string memory)
    {
        return IERC20(_token).symbol();
    }

    function getTokenName(address _token) public view returns (string memory) {
        return IERC20(_token).name();
    }

    function getTokenDecimal(address _token) public view returns (uint8) {
        return IERC20(_token).decimals();
    }

    // get user allowance for token
    function userAllowance(address _user, address _token)
        public
        view
        returns (uint256)
    {
        return IERC20(_token).allowance(_user, address(this));
    }

    // get user balance of token
    function userBalance(address _user, address _token)
        public
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(_user);
    }

    // check if the user has enough tokens to pay for the subscription
    function canUserPay(bytes32 _hash) public view returns (bool) {
        subStruct memory subscription = subscriptions[_hash];

        uint256 _days = unpaidDays(_hash);

        if (
            subscription.cost * _days <
            userAllowance(subscription.user, subscription.token) &&
            subscription.cost * _days <
            userBalance(subscription.user, subscription.token)
        ) {
            return true;
        }

        return false;
    }

    //check If subscription is active
    function subscriptionAlive(bytes32 _hash) public view returns (bool) {
        subStruct memory subscription = subscriptions[_hash];

        if (subscription.sub == bytes32(0)) {
            return false;
        }

        return true;
    }

    // get the number of seconds unpaid in the subscription
    function unpaidSeconds(bytes32 _hash) public view returns (uint256) {
        if (block.timestamp > lastPaid[_hash] && subscriptionAlive(_hash)) {
            return block.timestamp - lastPaid[_hash];
        } else {
            return 0;
        }
    }

    // get the number of days unpaid in the subscription
    function unpaidDays(bytes32 _hash) public view returns (uint256) {
        if (block.timestamp > lastPaid[_hash] && subscriptionAlive(_hash)) {
            return (block.timestamp - lastPaid[_hash]) / secondsInDay;
        } else {
            return 0;
        }
    }

    // get Amount unpaid in the subscription
    function unpaidCost(bytes32 _hash) public view returns (uint256) {
        subStruct storage subscription = subscriptions[_hash];

        if (subscriptionAlive(_hash)) {
            return unpaidDays(_hash) * subscription.cost;
        } else {
            return 0;
        }
    }

    //get hash for sub
    function subscriptionHash(
        address _token,
        address _user,
        address _boss,
        uint256 _cost
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_token, _user, _boss, _cost));
    }

    //get hash for sub
    function planHash(
        address _token,
        address _boss,
        uint256 _cost
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_token, _boss, _cost));
    }

    // internal function - pays the merchent for the subscription
    function _safePay(
        bytes32 _hash,
        address _token,
        address _user,
        address _boss,
        uint256 _amount
    ) internal {
        require(subscriptionAlive(_hash), "Subscription Not Alive ");

        require(_amount > 0, "Amount must be greater than 0");

        require(_amount < userAllowance(_user, _token), "No Allowance");

        require(_amount < userBalance(_user, _token), "No Balance");

        IERC20(_token).transferFrom(_user, _boss, _amount);

        emit Transfer(_hash, _token, _user, _boss, _amount);
    }

    // initialize the subscription service /// _initdays should be 0 if no advance payment
    function subscriptionCreate(
        address _token,
        address _boss,
        uint256 _cost,
        uint256 _initdays
    ) external {
        require(_cost > 0, "Cost must be greater than 0");

        bytes32 sub_hash = subscriptionHash(_token, msg.sender, _boss, _cost);
        bytes32 plan_hash = planHash(_token, _boss, _cost);

        subStruct memory newSubscription = subStruct({
            sub: sub_hash,
            plan: plan_hash,
            token: _token,
            user: msg.sender,
            boss: _boss,
            cost: _cost
        });

        subscriptions[sub_hash] = newSubscription;

        if (lastPaid[sub_hash] < 100) {
            store.push(sub_hash);
        }

        if (_initdays > 0) {
            _safePay(sub_hash, _token, msg.sender, _boss, _cost * _initdays);
        }

        emit Subscription(
            sub_hash,
            plan_hash,
            _token,
            msg.sender,
            _boss,
            _cost
        );

        lastPaid[sub_hash] = block.timestamp;
    }

    // close subscription
    function subscriptionCancel(bytes32 _hash) external {
        require(subscriptionAlive(_hash), "Subscription is not active");

        subStruct storage subscription = subscriptions[_hash];

        require(
            (subscription.user == msg.sender) ||
                (subscription.boss == msg.sender),
            "Only Boss or User can close subscription"
        );

        emit Close(subscription.sub);

        delete subscriptions[_hash];
    }

    // Collect subscription
    function subscriptionCollect(bytes32 _hash) external {
        subStruct memory subscription = subscriptions[_hash];

        uint256 _days = unpaidDays(_hash);

        require(_days > 0, "Days must be greater than 0");

        require(
            (lastPaid[_hash] + (secondsInDay * _days) <= block.timestamp),
            "Subscription not timed"
        );

        _safePay(
            subscription.sub,
            subscription.token,
            subscription.user,
            subscription.boss,
            subscription.cost * _days
        );

        lastPaid[_hash] = lastPaid[_hash] + (secondsInDay * _days);
    }
}