// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Custome errors
error NotificationService__ZeroAddress();
error NotificationService__ChannelAlreadyCreated();
error NotificationService__ChannelDoesNotExist();
error NotificationService__NotAdmin();
error NotificationService__NotADelegate();
error NotificationService__ChannelNotActive();
error NotificationService__ChannelNotMuted();
error NotificationService__UserNotSubscribed();
error NotificationService__NeitherAdminNorDelegate();
error NotificationService__UserAlreadySubscribed();

contract NotificationService {
    //enum and struct definitions
    enum ChannelState {
        ACTIVE,
        MUTED,
        DELETED
    }

    struct Channel {
        address channelAddress;
        address admin;
        string channelName;
        string channelDescription;
        ChannelState channelState;
        address[] delegates;
        address[] subsribers;
    }

    struct Subscription {
        address channelAddress;
        address user;
        uint256 subscriberIndex;
    }

    struct Delegate {
        address channelAddress;
        address delegate;
        uint256 delegateIndex;
    }

    struct Notification {
        address channelAddress;
        address recipient;
        string message;
    }

    // state variables
    mapping(address => mapping(address => Subscription)) channelAddressToUserSubscription;
    mapping(address => mapping(address => Delegate)) channelAddressToDelegate;
    mapping(address => Channel) private channelAddressToChannel;
    uint256 public channelCounter;

    // Events
    event ChannelCreated(
        address indexed channelAddress,
        address indexed admin,
        string channelName,
        string channelDescription
    );
    event DelegateAdded(address indexed channelAddress, address indexed delegate);
    // event DelegateRemoved(address indexed channelAddress, address indexed delegate);
    event ChannelMuted(address indexed channelAddress);
    // event ChannelUnmuted(address indexed channelAddress);
    event ChannelDeleted(address indexed channelAddress);
    event NotificationGenerated(
        address indexed channelAddress,
        address indexed recipient,
        Notification notification
    );
    event UserSubscribed(address indexed channelAddress, address indexed subscriber);
    event UserUnsubscribed(address indexed channelAddress, address indexed subscriber);

    // Modifiers
    modifier nonZeroAddress(address addr) {
        if (addr == address(0)) {
            revert NotificationService__ZeroAddress();
        }
        _;
    }

    modifier notAlreadyCreated(address _channelAddress) {
        if (channelAddressToChannel[_channelAddress].admin != address(0)) {
            revert NotificationService__ChannelAlreadyCreated();
        }
        _;
    }

    modifier channelExists(address _channelAddress) {
        if (channelAddressToChannel[_channelAddress].admin == address(0)) {
            revert NotificationService__ChannelDoesNotExist();
        }
        _;
    }

    modifier onlyAdmin(address _channelAddress, address caller) {
        if (caller != channelAddressToChannel[_channelAddress].admin) {
            revert NotificationService__NotAdmin();
        }
        _;
    }

    modifier isDelegate(address _channelAddress, address delegate) {
        if (channelAddressToDelegate[_channelAddress][delegate].channelAddress == address(0)) {
            revert NotificationService__NotADelegate();
        }
        _;
    }

    modifier isActive(address _channelAddress) {
        if (channelAddressToChannel[_channelAddress].channelState != ChannelState.ACTIVE) {
            revert NotificationService__ChannelNotActive();
        }
        _;
    }

    modifier isMuted(address _channelAddress) {
        if (channelAddressToChannel[_channelAddress].channelState != ChannelState.MUTED) {
            revert NotificationService__ChannelNotMuted();
        }
        _;
    }

    modifier isSubscribed(address _recipient, address _channelAddress) {
        if (
            channelAddressToUserSubscription[_channelAddress][_recipient].channelAddress ==
            address(0)
        ) {
            revert NotificationService__UserNotSubscribed();
        }
        _;
    }

    modifier onlyAdminOrDelegate(address _channelAddress, address caller) {
        if (
            !(caller == channelAddressToChannel[_channelAddress].admin ||
                caller == channelAddressToDelegate[_channelAddress][caller].delegate)
        ) {
            revert NotificationService__NeitherAdminNorDelegate();
        }
        _;
    }

    modifier notAlreadySubscribed(address _channelAddress, address caller) {
        if (
            channelAddressToUserSubscription[_channelAddress][caller].channelAddress != address(0)
        ) {
            revert NotificationService__UserAlreadySubscribed();
        }
        _;
    }

    ///////////////////////
    /// Admin Functions///
    //////////////////////
    function createChannel(
        address _channelAddress,
        string memory _channelName,
        string memory _channelDescription
    ) external nonZeroAddress(_channelAddress) notAlreadyCreated(_channelAddress) {
        Channel memory newChannel = Channel(
            _channelAddress,
            msg.sender,
            _channelName,
            _channelDescription,
            ChannelState.ACTIVE,
            new address[](0),
            new address[](0)
        );
        channelAddressToChannel[_channelAddress] = newChannel;
        channelCounter++;
        emit ChannelCreated(_channelAddress, msg.sender, _channelName, _channelDescription);
    }

    function addDelegate(
        address _channelAddress,
        address delegate
    )
        external
        nonZeroAddress(delegate)
        nonZeroAddress(_channelAddress)
        channelExists(_channelAddress)
        onlyAdmin(_channelAddress, msg.sender)
    {
        uint256 delegateIndex = channelAddressToChannel[_channelAddress].delegates.length;
        channelAddressToChannel[_channelAddress].delegates.push(delegate);
        Delegate memory newDelegate = Delegate(_channelAddress, delegate, delegateIndex);
        channelAddressToDelegate[_channelAddress][delegate] = newDelegate;
        emit DelegateAdded(_channelAddress, delegate);
    }

    function removeDelegate(
        address _channelAddress,
        address delegate
    )
        external
        nonZeroAddress(delegate)
        nonZeroAddress(_channelAddress)
        channelExists(_channelAddress)
        onlyAdmin(_channelAddress, msg.sender)
        isDelegate(_channelAddress, delegate)
    {
        uint256 _delegateIndex = channelAddressToDelegate[_channelAddress][delegate].delegateIndex;
        address[] memory newDelegates = removeElementFromArray(
            channelAddressToChannel[_channelAddress].delegates,
            _delegateIndex
        );
        channelAddressToChannel[_channelAddress].delegates = newDelegates;
        delete channelAddressToDelegate[_channelAddress][delegate];
        // emit DelegateRemoved(_channelAddress, delegate);
    }

    function muteChannel(
        address _channelAddress
    )
        external
        channelExists(_channelAddress)
        onlyAdmin(_channelAddress, msg.sender)
        isActive(_channelAddress)
    {
        channelAddressToChannel[_channelAddress].channelState = ChannelState.MUTED;
        emit ChannelMuted(_channelAddress);
    }

    function unmuteChannel(
        address _channelAddress
    )
        external
        channelExists(_channelAddress)
        onlyAdmin(_channelAddress, msg.sender)
        isMuted(_channelAddress)
    {
        channelAddressToChannel[_channelAddress].channelState = ChannelState.ACTIVE;
        // emit ChannelUnmuted(_channelAddress);
    }

    function deleteChannel(
        address _channelAddress
    ) external channelExists(_channelAddress) onlyAdmin(_channelAddress, msg.sender) {
        // update channelAddressToDelegate mapping
        for (uint256 i = 0; i < channelAddressToChannel[_channelAddress].delegates.length; i++) {
            delete channelAddressToDelegate[_channelAddress][
                channelAddressToChannel[_channelAddress].delegates[i]
            ];
        }
        // update channelAddressToUserSubscription mapping
        for (uint256 i = 0; i < channelAddressToChannel[_channelAddress].subsribers.length; i++) {
            delete channelAddressToUserSubscription[_channelAddress][
                channelAddressToChannel[_channelAddress].subsribers[i]
            ];
        }
        delete channelAddressToChannel[_channelAddress];
        emit ChannelDeleted(_channelAddress);
    }

    //////////////////////////////////
    // Admin or Delegate Functions //
    /////////////////////////////////
    function sendNotification(
        address _channelAddress,
        address _recipient,
        string memory _message
    )
        public
        channelExists(_channelAddress)
        onlyAdminOrDelegate(_channelAddress, msg.sender)
        isSubscribed(_recipient, _channelAddress)
    {
        Notification memory notification = Notification(_channelAddress, _recipient, _message);
        emit NotificationGenerated(_channelAddress, _recipient, notification);
    }

    function broadcastNotification(
        address _channelAddress,
        string memory _message
    ) public channelExists(_channelAddress) onlyAdminOrDelegate(_channelAddress, msg.sender) {
        for (uint256 i = 0; i < channelAddressToChannel[_channelAddress].subsribers.length; i++) {
            sendNotification(
                _channelAddress,
                channelAddressToChannel[_channelAddress].subsribers[i],
                _message
            );
        }
    }

    //////////////////////////////
    ////// User Functions ////////
    /////////////////////////////
    function subscribe(
        address _channelAddress
    ) external channelExists(_channelAddress) notAlreadySubscribed(_channelAddress, msg.sender) {
        uint256 subscriberIndex = channelAddressToChannel[_channelAddress].subsribers.length;
        channelAddressToChannel[_channelAddress].subsribers.push(msg.sender);
        Subscription memory newSubscription = Subscription(
            _channelAddress,
            msg.sender,
            subscriberIndex
        );
        channelAddressToUserSubscription[_channelAddress][msg.sender] = newSubscription;
        emit UserSubscribed(_channelAddress, msg.sender);
    }

    function unsubscribe(
        address _channelAddress
    ) external channelExists(_channelAddress) isSubscribed(msg.sender, _channelAddress) {
        uint256 _subscriberIndex = channelAddressToUserSubscription[_channelAddress][msg.sender]
            .subscriberIndex;
        address[] memory newSubscribers = removeElementFromArray(
            channelAddressToChannel[_channelAddress].subsribers,
            _subscriberIndex
        );
        channelAddressToChannel[_channelAddress].subsribers = newSubscribers;
        delete channelAddressToUserSubscription[_channelAddress][msg.sender];
        emit UserUnsubscribed(_channelAddress, msg.sender);
    }

    // view or pure functions

    function removeElementFromArray(
        address[] memory arr,
        uint256 index
    ) private pure returns (address[] memory) {
        address[] memory result = new address[](arr.length - 1);
        uint256 i = 0;
        uint256 j = 0;
        for (; i < arr.length; i++) {
            if (i == index) {
                continue;
            }
            result[j] = arr[i];
            j++;
        }
        return result;
    }
}