// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Hub.sol";
import "./interfaces/IHub.sol";
import "./interfaces/IAgrop.sol";

contract AgropAlphaV2 is IAgrop, IHub {
    // agrop owner
    address public owner;

    // hubs and hub counter
    mapping(uint256 => address) public hubs;
    uint256 public counter;

    // subscription fees
    mapping(string => mapping(string => uint256)) public fees;

    modifier onlyOwner() {
        require(owner == msg.sender, "Owner: caller must be agrop owner");
        _;
    }

    /// @dev
    constructor(
        uint256 _monthlyFee,
        uint256 _quarterlyFee,
        uint256 _yearlyFee
    ) {
        // set owner(deployer) to msg.sender and counter to 0
        owner = msg.sender;
        counter = 0;

        // set subscription fee
        // monthly
        fees["monthly"]["fee"] = _monthlyFee;
        fees["monthly"]["duration"] = 30 days;
        // quarterly
        fees["quarterly"]["fee"] = _quarterlyFee;
        fees["quarterly"]["duration"] = 90 days;
        // yearly
        fees["yearly"]["fee"] = _yearlyFee;
        fees["yearly"]["duration"] = 365 days;
    }

    /// @dev
    /// create new hub for farmer.
    function createHub(HubOptions memory _hub)
        external
        payable
        returns (address)
    {
        // when _hub.plan = 'mon' or anything then the fee will equal to 0 leading to paying zero fee for creating hub
        // since this is a dapp, anybody can call createHub with _hub.plan = 'mon' or anything, we can prevent the
        // creation of hub when _hub.plan is not monthly, quarterly, yearly.
        bool plan = keccak256(bytes(_hub.plan)) ==
            keccak256(bytes("monthly")) ||
            keccak256(bytes(_hub.plan)) == keccak256(bytes("quarterly")) ||
            keccak256(bytes(_hub.plan)) == keccak256(bytes("yearly"));

        // _hub.plan must be monthly, quarterly, yearly
        require(plan, "Agrop: _hub.plan must be monthly, quarterly, yearly");

        // get plan fee
        uint256 _fee = fees[_hub.plan]["fee"];

        // ensure msg.value is greater than zero to pay subscription fee
        require(
            msg.value == _fee,
            "Agrop: msg.value must be equal to _hub.plan when creating new hub."
        );

        emit Debugger(fees[_hub.plan]["duration"]);

        // create new hub
        Hub hub = new Hub(
            IAgrop.HubOptions(
                _hub.name,
                _hub.description,
                _hub.digit,
                _hub.location,
                _hub.thumbnails,
                _hub.documents,
                _hub.plan
            ),
            fees[_hub.plan]["duration"]
        );

        // increment counter
        counter++;

        hubs[counter] = address(hub);

        // emit log event
        emit Log("HubCreated", "Hub created successfully");

        // return hub address
        return address(hub);
    }

    /// @dev
    /// add crop to farmers' hub
    function addCropToHub(address _hubAddress, CropOptions memory _crop)
        external
        returns (bool)
    {
        Hub _hub = Hub(_hubAddress);

        // is hub exist?
        require(_hub.agrop() != address(0), "Agrop: Hub not exist");

        // emit log event
        emit Log("CropAdded", "Crop added successfully");

        // add crop to hub
        return _hub.addCrop(_crop);
    }

    /// @dev
    /// view single farmer hub in agrop
    function viewHub(address _hubAddress)
        public
        view
        returns (
            address,
            string memory,
            string memory,
            string memory,
            string memory,
            string[] memory,
            string[] memory,
            string memory,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        Hub _hub = Hub(_hubAddress);

        // is hub exist?
        require(_hub.agrop() != address(0), "Agrop: Hub not exist");

        // return details
        return _hub.details();
    }

    /// @dev
    /// paginate all farmers' hub in agrop
    function paginateHubs(uint256 _from, uint256 _to)
        public
        view
        returns (HubInfo[] memory)
    {
        require(
            _from > _to,
            "Agrop: `from` must be greater or equals to `to` for DESC pagination order"
        );

        require(
            (_from - _to) <= 10,
            "Agrop: page length can't be more than 10 for DESC pagination order"
        );

        HubInfo[] memory _hubs = new HubInfo[]((_from - _to) + 1);
        uint256 k = 0;

        for (uint256 i = _from; i >= _to; i--) {
            // get hub details
            (
                address _contract,
                string memory _name,
                string memory _description,
                string memory _digit,
                string memory _location,
                string[] memory _thumbnails,
                string[] memory _documents,
                string memory _plan,
                uint256 _subscriptionExpiresAt,
                uint256 _cropCounter,
                bool _verified,
                bool _freezed
            ) = viewHub(hubs[i]);

            // assign to array
            _hubs[k]._contract = _contract;
            _hubs[k]._name = _name;
            _hubs[k]._description = _description;
            _hubs[k]._digit = _digit;
            _hubs[k]._location = _location;
            _hubs[k]._thumbnails = _thumbnails;
            _hubs[k]._documents = _documents;
            _hubs[k]._plan = _plan;
            _hubs[k]._subscriptionExpiresAt = _subscriptionExpiresAt;
            _hubs[k]._cropCounter = _cropCounter;
            _hubs[k]._verified = _verified;
            _hubs[k]._freezed = _freezed;

            k++;
        }

        // return result
        return _hubs;
    }

    /// @dev
    /// renew farmers' hub subscription
    function renewHubSubscription(address _hubAddress, string memory _plan)
        external
        payable
    {
        Hub _hub = Hub(_hubAddress);

        // is hub exist?
        require(_hub.agrop() != address(0), "Agrop: Hub not exist");

        // when _plan = 'mon' or anything then the fee will equal to 0 leading to paying zero fee for creating hub
        // since this is a dapp, anybody can call createHub with _plan = 'mon' or anything, we can prevent the
        // creation of hub when _plan is not monthly, quarterly, yearly.
        bool plan = keccak256(bytes(_plan)) == keccak256(bytes("monthly")) ||
            keccak256(bytes(_plan)) == keccak256(bytes("quarterly")) ||
            keccak256(bytes(_plan)) == keccak256(bytes("yearly"));

        // _plan must be monthly, quarterly, yearly
        require(plan, "Agrop: _plan must be monthly, quarterly, yearly");

        // get plan fee
        uint256 _fee = fees[_plan]["fee"];

        // ensure msg.value is greater than zero to pay subscription fee
        require(
            msg.value == _fee,
            "Agrop: msg.value must be equal to _plan when creating new hub."
        );

        // renew subscription
        _hub.renewSubscription(_plan, fees[_plan]["duration"]);

        // emit log event
        emit Log("SubscriptionRenewed", "Subscription renewed successfully");
    }

    /// @dev
    /// freeze hub
    function freezeHub(address _hubAddress) external onlyOwner {
        Hub _hub = Hub(_hubAddress);

        // is hub exist?
        require(_hub.agrop() != address(0), "Agrop: Hub not exist");

        // freeze hub
        _hub.freeze();

        // emit log event
        emit Log("HubFreezed", "Hub freezed successfully");
    }

    /// @dev
    /// freeze hub
    function unfreezeHub(address _hubAddress) external onlyOwner {
        Hub _hub = Hub(_hubAddress);

        // is hub exist?
        require(_hub.agrop() != address(0), "Agrop: Hub not exist");

        // unfreeze hub
        _hub.unfreeze();

        // emit log event
        emit Log("HubUnfreezed", "Hub unfreezed successfully");
    }

    /// @dev
    /// verify hub
    function verifyHub(address _hubAddress) external onlyOwner {
        Hub _hub = Hub(_hubAddress);

        // is hub exist?
        require(_hub.agrop() != address(0), "Agrop: Hub not exist");

        // verify hub
        _hub.verify();

        // emit log event
        emit Log("HubVerified", "Hub verified successfully");
    }

    /// @dev
    /// unverify hub
    function unverifyHub(address _hubAddress) external onlyOwner {
        Hub _hub = Hub(_hubAddress);

        // is hub exist?
        require(_hub.agrop() != address(0), "Agrop: Hub not exist");

        // unverify hub
        _hub.unverify();

        // emit log event
        emit Log("HubUnverified", "Hub unverified successfully");
    }

    /// @dev
    function changeSubscriptionFee(string memory _plan, uint256 _amount)
        external
        onlyOwner
    {
        // _plan must monthly, quarterly, yearly
        bool plan = keccak256(bytes(_plan)) == keccak256(bytes("monthly")) ||
            keccak256(bytes(_plan)) == keccak256(bytes("quarterly")) ||
            keccak256(bytes(_plan)) == keccak256(bytes("yearly"));

        // _plan must be monthly, quarterly, yearly
        require(plan, "Agrop: _plan must be monthly, quarterly, yearly");

        require(_amount > 0, "Agrop: subscription fee must be more than zero");

        fees[_plan]["fee"] = _amount;

        // emit log event
        emit Log(
            "SubscriptionFeeChanged",
            "Subscription fee changed successfully"
        );
    }

    /// @dev
    function changeSubscriptionDuration(string memory _plan, uint256 _days)
        external
        onlyOwner
    {
        // _plan must monthly, quarterly, yearly
        bool plan = keccak256(bytes(_plan)) == keccak256(bytes("monthly")) ||
            keccak256(bytes(_plan)) == keccak256(bytes("quarterly")) ||
            keccak256(bytes(_plan)) == keccak256(bytes("yearly"));

        // _plan must be monthly, quarterly, yearly
        require(plan, "Agrop: _plan must be monthly, quarterly, yearly");

        require(
            _days > 0,
            "Agrop: subscription fee duration must be more than zero"
        );

        fees[_plan]["duration"] = _days * 1 days;

        // emit log event
        emit Log(
            "SubscriptionDurationChanged",
            "Subscription duration changed successfully"
        );
    }

    /// @dev
    /// withdraw amount of funds to owner (deployer) address
    function withdraw(uint256 _amount) external onlyOwner {
        require(
            _amount > 0,
            "Agrop: withdrawal amount must be greater than zero"
        );

        payable(owner).transfer(_amount);

        // emit log event
        emit Log("FundWithdrawn", "Funds withdrawn successfully");
    }

    /// @dev
    /// set new Agrop contract ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: Agrop owner can't the zero addresss"
        );

        owner = newOwner;

        // emit log event
        emit Log("OwnerChanged", "Ownership transfered successfully");
    }

    /// @dev
    /// renounce Agrop contract and set ownership to zero address
    function renounceOwnership() external onlyOwner {
        owner = address(0);

        // emit log event
        emit Log("OwnerRenounced", "Ownership renounced successfully");
    }

    /// @dev
    /// return ETH to sender if blindly sent to Agrop contract.
    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IHub {
    struct HubInfo {
        address _contract;
        string _name;
        string _description;
        string _digit;
        string _location;
        string[] _thumbnails;
        string[] _documents;
        string _plan;
        uint256 _subscriptionExpiresAt;
        uint256 _cropCounter;
        bool _verified;
        bool _freezed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IAgrop {
    struct HubOptions {
        string name;
        string description;
        string digit;
        string location;
        string[] thumbnails;
        string[] documents;
        string plan;
    }

    struct CropOptions {
        string name;
        string description;
    }

    event Log(string eventName, string message);
    event Debugger(uint256 duration);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Hub.sol";

import "./interfaces/IHub.sol";
import "./interfaces/IAgrop.sol";

contract Hub is IHub, IAgrop {
    // agrop contract address
    address public agrop;

    // hub details
    string public name;
    string public description;
    string public digit;
    string public location;
    string[] public thumbnails;
    string[] public documents;
    string public plan;

    // subscriptionExpiresAt - hub subscription ends at
    uint256 public subscriptionExpiresAt;

    // verified - for toggling hub verification.
    // freezed - for toggling hub freezing.
    bool public verified;
    bool public freezed;

    // cropCounter - total numbers of crop in farmer's hub
    uint256 public cropCounter;

    modifier onlyAgrop() {
        require(agrop == msg.sender, "Agrop: caller must be agrop contract");
        _;
    }

    modifier isSubscriptionActive() {
        require(
            subscriptionExpiresAt >= block.timestamp,
            "Agrop: Hub subscription has expired"
        );
        _;
    }

    // modifiers for freezed
    modifier ifNotFreezed() {
        require(freezed == false);
        _;
    }
    modifier ifFreezed() {
        require(freezed == true);
        _;
    }

    // modifiers for verified
    modifier ifNotVerified() {
        require(verified == false);
        _;
    }
    modifier ifVerified() {
        require(verified == true);
        _;
    }

    /// @dev
    /// constructor
    constructor(HubOptions memory _hub, uint256 _duration) {
        // set deployer to agrop
        agrop = msg.sender;

        // hub
        name = _hub.name;
        description = _hub.description;
        digit = _hub.digit;
        location = _hub.location;
        thumbnails = _hub.thumbnails;
        documents = _hub.documents;
        plan = _hub.plan;
        subscriptionExpiresAt = block.timestamp + _duration;
        cropCounter = 0;

        // verified | freezed
        verified = false;
        freezed = false;
    }

    /// @dev
    /// get hub details
    function details()
        public
        view
        onlyAgrop
        isSubscriptionActive
        returns (
            address,
            string memory,
            string memory,
            string memory,
            string memory,
            string[] memory,
            string[] memory,
            string memory,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        return (
            address(this),
            name,
            description,
            digit,
            location,
            thumbnails,
            documents,
            plan,
            subscriptionExpiresAt,
            cropCounter,
            verified,
            freezed
        );
    }

    /// @dev
    /// add crop to hub
    function addCrop(CropOptions memory _crop)
        external
        onlyAgrop
        ifNotFreezed
        isSubscriptionActive
        returns (bool)
    {}

    /// @dev
    /// renew subscription
    function renewSubscription(string memory _plan, uint256 _duration)
        external
        onlyAgrop
        ifNotFreezed
    {
        // set plan and subscriptionExpiresAt
        plan = _plan;
        subscriptionExpiresAt = block.timestamp + _duration;
    }

    // @dev
    /// freeze hub
    function freeze() external onlyAgrop ifNotFreezed {
        // freezed hub
        freezed = true;
    }

    // @dev
    /// unfreeze hub
    function unfreeze() external onlyAgrop ifFreezed {
        // unfreezed hub
        freezed = false;
    }

    // @dev
    /// verify hub
    function verify() external onlyAgrop ifNotVerified {
        // verified hub
        verified = true;
    }

    // @dev
    /// unverify hub
    function unverify() external onlyAgrop ifVerified {
        // unverified hub
        verified = false;
    }
}