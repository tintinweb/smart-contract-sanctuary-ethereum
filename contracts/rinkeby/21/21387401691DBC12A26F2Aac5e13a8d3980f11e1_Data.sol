// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
pragma abicoder v2;

/**
 * @dev Interface of the OpenOracleFramework contract
 */
interface IOOF {
    /**
     * @dev getFeeds function lets anyone call the oracle to receive data (maybe pay an optional fee)
     *
     * @param feedIDs the array of feedIds
     */
    function getFeeds(uint256[] memory feedIDs)
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );

    /**
     * @dev getFeed function lets anyone call the oracle to receive data (maybe pay an optional fee)
     *
     * @param feedID the array of feedId
     */
    function getFeed(uint256 feedID)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev getFeedList function returns the metadata of a feed
     *
     * @param feedIDs the array of feedId
     */
    function getFeedList(uint256[] memory feedIDs)
        external
        view
        returns (
            string[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );

    function subscribeToFeed(
        uint256[] memory feedIDs,
        uint256[] memory durations,
        address buyer
    ) external payable;

    /**
     * @dev buys a subscription pass for the oracle
     *
     * @param buyer the address which owns the pass
     * @param duration the duration to subscribe
     */
    function buyPass(address buyer, uint256 duration) external payable;

    /**
     * @dev supports given Feeds
     *
     * @param feedIds the array of feeds to supportBounty
     * @param values the array of amounts of ETH to send to support.s
     */
    function supportFeeds(uint256[] memory feedIds, uint256[] memory values)
        external
        payable;
}

contract Data {
    IOOF public OOF;
    event feedRequested(
        address _OOFaddress,
        uint256[] feedid,
        string[] _endpoint,
        string[] _path,
        string[] _name,
        uint256[] _freq,
        uint256[] _dec,
        uint256[] _amountETH
    );

    constructor(address _OOF) {
        OOF = IOOF(_OOF);
    }

    mapping(uint256 => string) public requestsName;
    mapping(uint256 => uint256) public bountyETH;
    mapping(uint256 => string) public APIendpoints;
    mapping(uint256 => string) public path;
    mapping(uint256 => string) public name;
    mapping(uint256 => uint256) public feedIDs;
    mapping(uint256 => uint256) public freq;
    mapping(uint256 => uint256) public dec;
    mapping(uint256 => uint256) public IDsToPosition;
    uint256 feedsSubmitted;
    mapping(address => mapping(uint256 => uint256)) public supportAddrs;
    event feedSupported(uint256[] feedid, uint256[] _amountETH);

    function requestFeed(
        uint256[] memory IDs,
        string[] memory _APIendpoint,
        string[] memory _path,
        string[] memory _name,
        uint256[] memory _freq,
        uint256[] memory _dec,
        uint256[] memory amountETH
    ) public payable {
        uint256 totals;
        for (uint256 n; n < IDs.length; n++) {
            require(IDsToPosition[IDs[n]] == 0, "feedIDs already requested");
            totals += amountETH[n];
            feedsSubmitted++;
            feedIDs[feedsSubmitted] = IDs[n];
            IDsToPosition[IDs[n]] = feedsSubmitted;
            name[IDs[n]] = _name[n];
            APIendpoints[IDs[n]] = _APIendpoint[n];
            path[IDs[n]] = _path[n];
            freq[IDs[n]] = _freq[n];
            dec[IDs[n]] = _dec[n];
            bountyETH[IDs[n]] = amountETH[n];
        }
        require(totals == msg.value);
        emit feedRequested(
            address(OOF),
            IDs,
            _APIendpoint,
            _path,
            _name,
            _freq,
            _dec,
            amountETH
        );
    }

    function feedsFilled(uint256[] memory IDs) public {
        uint256[] memory feeds;
        uint256[] memory amounts;
        uint256 totalETH;
        (, feeds, ) = OOF.getFeeds(IDs);
        for (uint256 n; n < IDs.length; n++) {
            require(feeds[n] != 0, "feeds not filled");
            totalETH += bountyETH[IDs[n]];
            amounts[n] = bountyETH[IDs[n]];
            bountyETH[IDs[n]] = 0;
        }
        OOF.supportFeeds(feeds, amounts);
    }

    function check(uint256[] memory IDs)
        public
        view
        returns (uint256[] memory, uint256)
    {
        uint256[] memory feeds;
        uint256 totalETH;
        (, feeds, ) = OOF.getFeeds(IDs);
        for (uint256 n; n < IDs.length; n++) {
            totalETH += bountyETH[IDs[n]];
        }
        return (feeds, totalETH);
    }


    function feedData(uint256[] memory IDs)
        public
        view
        returns (
            uint256[] memory _feeds,
            string[] memory _name,
            string[] memory _apiendpoint,
            string[] memory _paths,
            uint256[] memory _freq,
            uint256[] memory _dec,
            uint256[] memory _bounty
        )
    {
        for (uint256 n; n < IDs.length; n++) {
            _feeds[n] = IDs[n];
            _name[n] = name[IDs[n]];
            _apiendpoint[n] = APIendpoints[IDs[n]];
            _paths[n] = path[IDs[n]];
            _freq[n] = freq[IDs[n]];
            _dec[n] = dec[IDs[n]];
            _bounty[n] = bountyETH[IDs[n]];
        }
        //return (_feeds, _name, _apiendpoint, _paths, _freq, _dec, _bounty);
    }

    function withdraw(uint256[] memory IDs) public {
        uint256 total;
        for (uint256 n; n < IDs.length; n++) {
            total += supportAddrs[msg.sender][IDs[n]];
            bountyETH[IDs[n]] -= supportAddrs[msg.sender][IDs[n]];
            supportAddrs[msg.sender][IDs[n]] = 0;
        }
        payable(msg.sender).transfer(total);
    }

    function supportBounty(uint256[] memory IDs, uint256[] memory amount)
        public
        payable
    {
        uint256 total;
        uint256[] memory bountys;
        for (uint256 n; n < IDs.length; n++) {
            total += amount[n];
            bountyETH[IDs[n]] += amount[n];
            supportAddrs[msg.sender][IDs[n]] += amount[n];
            bountys[n] = bountyETH[IDs[n]];
        }
        require(total == msg.value);

        emit feedSupported(IDs, bountys);
    }
}