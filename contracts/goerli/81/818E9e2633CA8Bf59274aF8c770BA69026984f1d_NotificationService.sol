// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

error Notification__ChannelAlreadyCreated();
error NotificationService__ChannelDoesNotExist();
error NotificationService__NotAdmin();
error NotificationService__NotADelegate();
error NotificationService__UserNotSubscribed();
error NotificationService__NeitherAdminNorDelegate();
error NotificationService__UserAlreadySubscribed();

contract NotificationService {
    enum ChannelState {
        ACTIVE,
        MUTED,
        DELETED
    }

    struct Channel {
        address admin;
        string channelName;
        string channelDescription;
        // address[] delegates;
        // address[] subsribers;
        ChannelState channelState;
        uint256 channelId;
    }

    struct User {
        mapping(address => bool) isSubscribed;
    }

    struct NotificationMessage {
        uint256 channelId;
        address admin;
        address recipient;
        string message;
    }

    mapping(uint256 => address) private channelIdToAdmin;
    mapping(address => Channel) private adminToChannel;
    mapping(address => address) private delegateToAdmin;
    mapping(address => User) private addressToUser;
    uint256 public channelCounter;

    event ChannelCreated(
        uint256 indexed channelId,
        address indexed admin,
        string channelName,
        string channelDescription
    );
    event DelegateAdded(address indexed admin, address indexed delegate);
    event DelegateRemoved(address indexed admin, address indexed delegate);
    event ChannelMuted(address indexed admin);
    event ChannelUnmuted(address indexed admin);
    event ChannelDeleted(address indexed admin);
    event NotificationEvent(NotificationMessage notification);
    event UserSubscribed(uint256 indexed _channelId, address indexed subscriber);
    event UserUnsubscribed(uint256 indexed _channelId, address indexed subscriber);

    modifier notAlreadyCreated(address admin) {
        if (adminToChannel[admin].admin != address(0)) {
            revert Notification__ChannelAlreadyCreated();
        }
        _;
    }

    modifier channelExists(address _admin) {
        if (adminToChannel[_admin].admin == address(0)) {
            revert NotificationService__ChannelDoesNotExist();
        }
        _;
    }

    modifier onlyAdmin(address caller) {
        if (caller != adminToChannel[caller].admin) {
            revert NotificationService__NotAdmin();
        }
        _;
    }

    modifier isDelegate(address admin, address delegate) {
        if (delegateToAdmin[delegate] == address(0)) {
            revert NotificationService__NotADelegate();
        }
        _;
    }

    modifier isSubscribed(address _recipient, address _admin) {
        if (!addressToUser[_recipient].isSubscribed[_admin]) {
            revert NotificationService__UserNotSubscribed();
        }
        _;
    }

    modifier onlyAdminOrDelegate(uint256 _channelId, address caller) {
        if (
            !(caller == channelIdToAdmin[_channelId] ||
                delegateToAdmin[caller] == channelIdToAdmin[_channelId])
        ) {
            revert NotificationService__NeitherAdminNorDelegate();
        }
        _;
    }

    modifier notAlreadySubscribed(uint256 _channelId, address caller) {
        if (addressToUser[caller].isSubscribed[channelIdToAdmin[_channelId]]) {
            revert NotificationService__UserAlreadySubscribed();
        }
        _;
    }

    function createChannel(string memory _channelName, string memory _channelDescription)
        external
        notAlreadyCreated(msg.sender)
    {
        Channel memory newChannel = Channel(
            msg.sender,
            _channelName,
            _channelDescription,
            ChannelState.ACTIVE,
            channelCounter
        );
        channelIdToAdmin[channelCounter] = msg.sender;
        adminToChannel[msg.sender] = newChannel;
        emit ChannelCreated(channelCounter, msg.sender, _channelName, _channelDescription);
        channelCounter++;
    }

    function addDelegate(address delegate)
        external
        channelExists(msg.sender)
        onlyAdmin(msg.sender)
    {
        delegateToAdmin[delegate] = msg.sender;
        emit DelegateAdded(msg.sender, delegate);
    }

    function removeDelegate(address delegate)
        external
        channelExists(msg.sender)
        onlyAdmin(msg.sender)
        isDelegate(msg.sender, delegate)
    {
        delete delegateToAdmin[delegate];
        emit DelegateRemoved(msg.sender, delegate);
    }

    function muteChannel() external channelExists(msg.sender) onlyAdmin(msg.sender) {
        adminToChannel[msg.sender].channelState = ChannelState.MUTED;
        emit ChannelMuted(msg.sender);
    }

    function unmuteChannel() external channelExists(msg.sender) onlyAdmin(msg.sender) {
        adminToChannel[msg.sender].channelState = ChannelState.ACTIVE;
        emit ChannelUnmuted(msg.sender);
    }

    function deleteChannel() external channelExists(msg.sender) onlyAdmin(msg.sender) {
        delete adminToChannel[msg.sender];
        emit ChannelDeleted(msg.sender);
    }

    function sendNotification(
        uint256 _channelId,
        address _recipient,
        string memory _message
    )
        external
        channelExists(channelIdToAdmin[_channelId])
        isSubscribed(_recipient, channelIdToAdmin[_channelId])
        onlyAdminOrDelegate(_channelId, msg.sender)
    {
        NotificationMessage memory notif = NotificationMessage(
            _channelId,
            channelIdToAdmin[_channelId],
            _recipient,
            _message
        );
        emit NotificationEvent(notif);
    }

    //////////////////////////////
    ////// User Functions ////////
    /////////////////////////////
    function subscribe(uint256 _channelId)
        external
        channelExists(channelIdToAdmin[_channelId])
        notAlreadySubscribed(_channelId, msg.sender)
    {
        addressToUser[msg.sender].isSubscribed[channelIdToAdmin[_channelId]] = true;
        emit UserSubscribed(_channelId, msg.sender);
    }

    function unsubscribe(uint256 _channelId)
        external
        channelExists(channelIdToAdmin[_channelId])
        isSubscribed(msg.sender, channelIdToAdmin[_channelId])
    {
        addressToUser[msg.sender].isSubscribed[channelIdToAdmin[_channelId]] = false;
        emit UserUnsubscribed(_channelId, msg.sender);
    }
}