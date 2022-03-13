// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct LandInfo {
    address currentLender;
    uint256 currentPricePerDay;
    uint256 currentCollateral; // this is consuming
    uint256 lastAccountTime; // The last checkpoint that the current lender's fee is calculated
    uint256 graceUntil; // before this is grace period, 0 = N/A // TODO: check if this is consistent
    address pendingLender;
    uint256 pendingPricePerDay;
    uint256 pendingCollateral;
}

interface Land {
    function transferFrom(
        address from,
        address to,
        uint256 assetId
    ) external;

    function setUpdateOperator(uint256 assetId, address operator) external;
}

contract RadicalMarket {
    Land private _land;
    address private _admin = msg.sender;

    mapping(uint256 => LandInfo) public landInfos; // tokenId => LandInfo
    mapping(address => uint256) public refunds; // user => refundTokenNum
    mapping(uint256 => bool) public registeredLands; // tokenId => whether _land is owned by this contract

    // TODO: set functions
    uint256 private _minimalPricePerDay = 1e14; // 0.0001 eth / day
    uint256 private _minimalPeriod = 1; // days
    uint256 private _gracePeriod = 200; // s

    uint256 private _cumulatedFees = 0;

    event LandRegistered(uint256 indexed tokenId);
    event LandUnregistered(uint256 indexed tokenId);
    event CurrentLenderUpdated(
        uint256 indexed tokenId,
        address indexed currentLender
    );
    event PendingLenderUpdated(
        uint256 indexed tokenId,
        address indexed pendingLender,
        bool winning
    );

    // TODO: use ownable
    modifier onlyOwner() {
        require(msg.sender == _admin, "not _admin");
        _;
    }

    constructor(address land) {
        _land = Land(land);
    }

    // set tokenids to registeredLands
    function registerLands(uint256[] calldata tokenids) external onlyOwner {
        for (uint256 i = 0; i < tokenids.length; i++) {
            _registerLand(tokenids[i]);
        }
    }

    // TODO: shuold refund to the current owner and get the _land immediately?
    function deregisterLands(uint256[] calldata tokenids) external onlyOwner {}

    // give a specific parcel an acessment price and try to get the right to use it
    // if there is no current lender, becomes the current lender (no minimal bid required), otherwise becomes the pending lender if outbid the existing pending lender. (need to provide enough collateral)
    function bid(uint256 tokenid, uint256 pricePerDay) external payable {
        require(registeredLands[tokenid], "_land not available!");

        // TODO: check minimal price

        LandInfo storage landInfo = landInfos[tokenid];

        // defensively add collateral and/or raise price
        if (msg.sender == landInfo.currentLender) {
            _updateCurrentStatus(landInfo);
            require(
                pricePerDay >= landInfo.currentPricePerDay,
                "can not lower price"
            );
            require(
                pricePerDay > landInfo.pendingPricePerDay,
                "need to outbid the competitor"
            );
            require(
                pricePerDay * _minimalPeriod <=
                    msg.value + landInfo.currentCollateral,
                "not enough collateral"
            );

            landInfo.currentPricePerDay = pricePerDay;
            landInfo.currentCollateral += msg.value;
            landInfo.graceUntil = 0;

            // TODO: event?
        } else {
            // msg.sender is not current lender or there is no current lender
            require(
                pricePerDay * _minimalPeriod <= msg.value,
                "not enough collateral"
            );

            // there is a current lender
            if (landInfo.currentLender != address(0)) {
                require(
                    pricePerDay > landInfo.pendingPricePerDay,
                    "need to outbid the competitor"
                );
                _updateCurrentStatus(landInfo);

                // TODO: this two branch can be merged, but lose readibility
                if (pricePerDay > landInfo.currentPricePerDay) {
                    // TODO: in case current collateral is 0, replace current lender directly?

                    // TODO: whether deal with the case that pending lender == msg.sender?
                    refunds[landInfo.pendingLender] += landInfo
                        .pendingCollateral;

                    landInfo.pendingLender = msg.sender;
                    landInfo.pendingPricePerDay = pricePerDay;
                    landInfo.pendingCollateral = msg.value;
                    if (landInfo.graceUntil == 0) {
                        landInfo.graceUntil = block.timestamp + _gracePeriod;
                    }
                    emit PendingLenderUpdated(tokenid, msg.sender, true);
                } else {
                    refunds[landInfo.pendingLender] += landInfo
                        .pendingCollateral;
                    landInfo.pendingLender = msg.sender;
                    landInfo.pendingPricePerDay = pricePerDay;
                    landInfo.pendingCollateral = msg.value;
                    emit PendingLenderUpdated(tokenid, msg.sender, false);
                }
            } else {
                // no current lender, become the _land's current lender
                landInfo.currentLender = msg.sender;
                landInfo.currentPricePerDay = pricePerDay;
                landInfo.currentCollateral = msg.value;
                landInfo.lastAccountTime = block.timestamp;
                _land.setUpdateOperator(tokenid, msg.sender);
                emit CurrentLenderUpdated(tokenid, msg.sender);
            }
        }
    }

    // called by anyone (bots) when requirements are met
    // the pending lender replaces the current lender / or the _land operator is reset
    function take(uint256 tokenid) external {
        require(registeredLands[tokenid], "_land not available!");
        LandInfo storage landInfo = landInfos[tokenid];
        require(landInfo.pendingLender != address(0), "none can take");
        _updateCurrentStatus(landInfo);
        // TODO: seems this two can be combined, but lose readibility
        if (landInfo.currentCollateral == 0) {
            landInfo.currentCollateral = landInfo.pendingCollateral;
            landInfo.currentLender = landInfo.pendingLender;
            landInfo.currentPricePerDay = landInfo.pendingPricePerDay;
            landInfo.graceUntil = 0;
            landInfo.lastAccountTime = block.timestamp;
            landInfo.pendingCollateral = 0;
            landInfo.pendingLender = address(0);
            landInfo.pendingPricePerDay = 0;
            _land.setUpdateOperator(tokenid, landInfo.currentLender);
            emit CurrentLenderUpdated(tokenid, landInfo.currentLender);
        } else if (
            (landInfo.currentPricePerDay < landInfo.pendingPricePerDay) &&
            (landInfo.graceUntil <= block.timestamp)
        ) {
            refunds[landInfo.currentLender] += landInfo.currentCollateral;
            landInfo.currentCollateral = landInfo.pendingCollateral;
            landInfo.currentLender = landInfo.pendingLender;
            landInfo.currentPricePerDay = landInfo.pendingPricePerDay;
            landInfo.graceUntil = 0;
            landInfo.lastAccountTime = block.timestamp;
            landInfo.pendingCollateral = 0;
            landInfo.pendingLender = address(0);
            landInfo.pendingPricePerDay = 0;
            _land.setUpdateOperator(tokenid, landInfo.currentLender);
            emit CurrentLenderUpdated(tokenid, landInfo.currentLender);
        }
    }

    // get refund by a replaced "current lender" or a replaced "pending lender"
    function refund() external {
        uint256 fund = refunds[msg.sender];
        require(fund != 0, "no refund available");
        refunds[msg.sender] = 0;
        payable(msg.sender).transfer(fund);
    }

    function _registerLand(uint256 tokenid) internal onlyOwner {
        _land.transferFrom(msg.sender, address(this), tokenid);
        registeredLands[tokenid] = true;
        emit LandRegistered(tokenid);
    }

    function _updateCurrentStatus(LandInfo storage landInfo) internal {
        uint256 fee = (landInfo.currentPricePerDay *
            (block.timestamp - landInfo.lastAccountTime)) / 1 days;
        if (fee > landInfo.currentCollateral) {
            fee = landInfo.currentCollateral;

            // TODO: if need an event in this case?
        }

        landInfo.currentCollateral -= fee;
        landInfo.lastAccountTime = block.timestamp;

        _cumulatedFees += fee;
    }
}