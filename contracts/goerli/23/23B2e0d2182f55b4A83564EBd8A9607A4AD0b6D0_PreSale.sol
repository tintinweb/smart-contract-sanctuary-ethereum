// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ERC20 {
    function name() external view returns (string memory);

    function totalSupply() external view returns (uint);

    function decimals() external view returns (uint);

    function owner() external view returns (address);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract PreSale is Ownable {
    enum CreateMode {
        And,
        Or
    }
    struct FunderData {
        uint campaignId;
        address buyer;
        uint amount;
        uint date;
        uint saler_wage;
        uint buyer_wage;
    }

    struct InfoData {
        string logo;
        string website;
        string twitter;
        string telegram;
    }
    struct NewData {
        uint price;
        uint supply;
        uint minInvest;
        uint maxInvest;
        uint startTime;
        uint durationDays;
    }

    struct CampaignData {
        uint id;
        address owner;
        address token;
        uint price;
        uint supply;
        uint balance;
        uint minInvest;
        uint maxInvest;
        uint startTime;
        uint256 value;
        uint durationDays;
        bool isCompleted;
        InfoData info;
    }
    struct SettingData {
        bool only_owner_can_create_campaign;
        uint minimum_balance_for_create_campaign;
        CreateMode create_campaign_mode;
        uint minimum_supply_for_create_campaign;
        uint wage_for_saler;
        uint wage_for_buyer;
        uint maxduration;
        uint minduration;
        uint256 maxmarketcap;
        address wageWallet;
        bool onmaintrance;
    }

    event StartCampaign(
        uint campaignId,
        address token,
        uint price,
        uint supply,
        uint durationDays
    );
    event RescissionCampaign(uint campaignId);
    event BuyToken(
        uint campaignId,
        uint amount,
        uint price,
        uint saler_wage,
        uint buyer_wage
    );
    event CompleteCampaign(uint campaignId);

    mapping(uint => CampaignData) internal campaigns;
    mapping(address => uint) internal activeCampaigns;
    mapping(address => uint[]) internal campaignsList;
    mapping(address => uint[]) internal campaignsOwner;

    mapping(uint => FunderData) funders;
    mapping(uint => uint[]) campaignFunders;
    mapping(address => uint[]) fundersOwner;

    mapping(address => bool) blackList;

    SettingData configs;

    uint numCampaigns;
    uint numFunders;

    constructor() {
        configs.only_owner_can_create_campaign = true;
        configs.minimum_balance_for_create_campaign = 20;
        configs.create_campaign_mode = CreateMode.Or;
        configs.minimum_supply_for_create_campaign = 10;
        configs.wage_for_saler = 5;
        configs.wage_for_buyer = 5;
        configs.maxduration = 30;
        configs.minduration = 30;
        configs.maxmarketcap = 700 ether;
        configs.onmaintrance = false;
        configs.wageWallet = msg.sender;
    }

    function newCampaign(
        address token,
        NewData memory data,
        InfoData memory info
    ) public enable returns (uint campaignId) {
        (bool check, ) = address(token).call(abi.encodeWithSignature("name()"));
        address campaignowner = _msgSender();

        require(check, "Address not token contract!");
        require(!blackList[token], "Address is banned!");
        require(!blackList[campaignowner], "Owner is banned!");
        require(data.price > 0, "Price is zero!");
        require(data.supply > 0, "Supply is zero!");
        require(data.minInvest > 0, "Min invest is zero!");
        require(data.maxInvest > 0, "Max invest is zero!");
        require(data.durationDays > 0, "Duration days is zero!");
        require(
            data.durationDays <= configs.maxduration,
            "Duration days is large!"
        );
        require(
            data.durationDays >= configs.minduration,
            "Duration days is small!"
        );
        require(
            data.startTime > block.timestamp - 3600000,
            "Start date too past!"
        );

        if (activeCampaigns[token] > 0) {
            require(
                campaigns[activeCampaigns[token]].isCompleted == true,
                "Current campaign not completed!"
            );
        }

        ERC20 tokencontract = ERC20(token);
        uint totalsupply = tokencontract.totalSupply();

        require(
            tokencontract.balanceOf(campaignowner) >= data.supply,
            "Owner balance insufficient!"
        );

        require(
            data.supply <= totalsupply,
            "Supply larger than of token total supply!"
        );

        require(
            tokencontract.allowance(campaignowner, address(this)) >=
                data.supply,
            "Owner allowance not enough!"
        );

        if (configs.maxmarketcap > 0) {
            require(
                (totalsupply / 10**tokencontract.decimals()) * data.price <=
                    configs.maxmarketcap,
                "Price too high!"
            );
        }
        if (configs.minimum_supply_for_create_campaign > 0) {
            require(
                data.supply >=
                    ((totalsupply *
                        configs.minimum_supply_for_create_campaign) / 100),
                "Supply less than the minimum!"
            );
        }
        address contractowner;
        if (configs.only_owner_can_create_campaign) {
            (bool success, bytes memory result) = address(token).call(
                abi.encodeWithSignature("owner()")
            );

            if (success) {
                contractowner = bytesToAddress(result);
            } else {
                (success, result) = address(token).call(
                    abi.encodeWithSignature("getOwner()")
                );
                if (success) {
                    contractowner = bytesToAddress(result);
                }
            }
        }

        if (
            configs.only_owner_can_create_campaign ||
            configs.minimum_balance_for_create_campaign > 0
        ) {
            bool checkbalance = tokencontract.balanceOf(campaignowner) >
                ((totalsupply * configs.minimum_balance_for_create_campaign) /
                    100);

            if (configs.create_campaign_mode == CreateMode.And) {
                require(
                    contractowner == campaignowner && checkbalance,
                    contractowner != campaignowner && !checkbalance
                        ? "Only contract owner can create campaign and wallet balance not enough!"
                        : contractowner == campaignowner
                        ? "Wallet balance not enough!"
                        : "Only contract owner can create campaign!"
                );
            } else {
                require(
                    contractowner == campaignowner || checkbalance,
                    "Contract owner can create campaign or wallet balance enough!"
                );
            }
        }

        require(
            data.price > getLastCampaignByAddress(token).price,
            "Price must larger than of previous campaign!"
        );

        tokencontract.transferFrom(campaignowner, address(this), data.supply);
        require(
            tokencontract.balanceOf(address(this)) >= data.supply,
            "Supply transfer failed!"
        );

        campaignId = ++numCampaigns;

        CampaignData storage c = campaigns[campaignId];
        c.id = campaignId;
        c.startTime = data.startTime;
        c.owner = campaignowner;
        c.token = token;
        c.price = data.price;
        c.supply = data.supply;
        c.balance = data.supply;
        c.minInvest = data.minInvest;
        c.maxInvest = data.maxInvest;
        c.durationDays = data.durationDays;
        c.info = info;

        activeCampaigns[token] = campaignId;
        campaignsList[token].push(campaignId);
        campaignsOwner[campaignowner].push(campaignId);

        emit StartCampaign(
            campaignId,
            token,
            data.price,
            data.supply,
            data.durationDays
        );
    }

    function buyToken(address token, uint amount)
        public
        payable
        enable
        returns (bool)
    {
        address buyer = _msgSender();
        CampaignData storage c = campaigns[activeCampaigns[token]];
        _checkCampaign(c);

        require(
            block.timestamp > c.startTime,
            "Current campaign not start yet!"
        );
		require(
            block.timestamp <= c.startTime + c.durationDays * 1 days,
            "Current campaign has ended!"
        );

        ERC20 tokencontract = ERC20(c.token);
        require(
            c.balance >= tokencontract.balanceOf(address(this)),
            "Campaign token balance has conflict!"
        );
        require(c.balance > 0, "Campaign token balance has finished!");
        require(amount <= c.maxInvest, "Amount is high!");
        require(amount >= c.minInvest, "Amount is low!");
        require(amount <= c.balance, "Amount is more than of token balance!");

        uint price = (c.price * amount) / (10**tokencontract.decimals());
        uint wage_saler = 0;
        uint wage_buyer = 0;

        if (configs.wage_for_saler > 0) {
            wage_saler = (price * configs.wage_for_saler) / 1000;
        }

        if (configs.wage_for_buyer > 0) {
            wage_buyer = (price * configs.wage_for_buyer) / 1000;
        }

        require(msg.value == price + wage_buyer, "Paid value is incorrect!");

        c.balance -= amount;

        tokencontract.transfer(buyer, amount);

        c.value += price;

        payable(c.owner).transfer(price - wage_saler);

        if (wage_saler + wage_buyer > 0)
            payable(configs.wageWallet).transfer(wage_saler + wage_buyer);
        uint funderId = numFunders++;
        funders[funderId] = FunderData(
            c.id,
            buyer,
            amount,
            block.timestamp,
            wage_saler,
            wage_buyer
        );

        campaignFunders[c.id].push(funderId);
        fundersOwner[buyer].push(funderId);

        emit BuyToken(c.id, amount, price, wage_saler, wage_buyer);
        return true;
    }

    function completeCampaign(uint campaignId) public enable returns (bool) {
        CampaignData storage c = campaigns[campaignId];
        _checkCampaign(c);

        require(
            c.owner == _msgSender() || owner() == _msgSender(),
            "Only campaign owner can complete!"
        );

        ERC20 tokencontract = ERC20(c.token);

        if (c.balance > 1 * 10**tokencontract.decimals()) {
            require(
                block.timestamp <= c.startTime + c.durationDays * 1 days,
                "Campaign duration not passed!"
            );
        }
        require(
            c.balance >= tokencontract.balanceOf(address(this)),
            "Campaign token balance has conflict!"
        );

        tokencontract.transfer(c.owner, c.balance);

        c.isCompleted = true;

        delete activeCampaigns[c.token];
        emit CompleteCampaign(campaignId);

        return true;
    }

    function rescissionCampaign(
        uint campaignId,
        bool banContract,
        bool banOwner
    ) public onlyOwner enable returns (bool) {
        CampaignData memory c = campaigns[campaignId];
        _checkCampaign(c);

        ERC20 tokencontract = ERC20(c.token);
        uint remainbalance = tokencontract.balanceOf(address(this));
        if (c.balance >= remainbalance) {
            tokencontract.transfer(c.owner, c.balance);
        } else if (remainbalance > 0) {
            tokencontract.transfer(c.owner, remainbalance);
        }
        if (banContract) blackList[c.token] = true;
        if (banOwner) blackList[c.owner] = true;

        delete activeCampaigns[c.token];
        delete campaignsList[c.token];
        delete campaignsOwner[c.owner];

        delete campaigns[campaignId];

        emit RescissionCampaign(campaignId);

        return true;
    }

    function updateInfo(uint campaignId, InfoData memory info)
        public
        enable
        returns (bool)
    {
        CampaignData storage c = campaigns[campaignId];
        _checkCampaign(c);

        require(
            c.owner == _msgSender() || owner() == _msgSender(),
            "Only campaign owner can update!"
        );

        c.info = info;

        return true;
    }

    function getCampaignById(uint campaignID)
        public
        view
        returns (CampaignData memory)
    {
        return campaigns[campaignID];
    }

    function getActiveCampaignByAddress(address token)
        public
        view
        returns (CampaignData memory)
    {
        return getCampaignById(activeCampaigns[token]);
    }

    function getLastCampaignByAddress(address token)
        public
        view
        returns (CampaignData memory last)
    {
        if (campaignsList[token].length > 0)
            last = getCampaignById(
                campaignsList[token][campaignsList[token].length - 1]
            );
    }

    function getCampaignsIdByAddress(address token)
        public
        view
        returns (uint256[] memory)
    {
        return campaignsList[token];
    }

    function getOwnerCampaigns(address owner)
        public
        view
        returns (uint[] memory)
    {
        return campaignsOwner[owner];
    }

    function getFunderById(uint funderID)
        public
        view
        returns (FunderData memory)
    {
        return funders[funderID];
    }

    function getFundersIdByCampaign(uint campaignId)
        public
        view
        returns (uint256[] memory)
    {
        return campaignFunders[campaignId];
    }

    function getConfigs() public view returns (SettingData memory) {
        return configs;
    }

    function updateConfigs(SettingData memory newconfig)
        public
        onlyOwner
        returns (bool)
    {
        configs = newconfig;
        return true;
    }

    function removeFromBlackList(address addr) public onlyOwner returns (bool) {
        blackList[addr] = false;
        return true;
    }

    function isBanned(address addr) public view returns (bool) {
        return blackList[addr];
    }

    function getCampaignCount() public view returns (uint) {
        return numCampaigns;
    }

    function getFunderCount() public view returns (uint) {
        return numFunders;
    }

    modifier enable() {
        require(!configs.onmaintrance, "System On Maintrance!");

        _;
    }

    function _checkCampaign(CampaignData memory c) internal pure {
        require(c.id > 0, "Campaign not exists!");
        require(c.isCompleted == false, "Current campaign is completed!");
    }

    function bytesToAddress(bytes memory bys)
        private
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 32))
        }
    }
}