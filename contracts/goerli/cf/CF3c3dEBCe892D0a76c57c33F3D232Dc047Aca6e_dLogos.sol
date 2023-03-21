/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
 
/* OPEN QUESTIONS 
    1. Does there need to be a dedicated contribution address for each conversation?
    2. May be useful to have a mapping from conversation ID to convo metadata.
    3. Does all the conversatio metadata need to be stored in SC?
    4. Convo Array vs mapping (looks like best practice is separate for metadata)
    5. createDelegatedConvo (onlyOwner can create on behalf of an address)
    6. Separate gov address from revenue address
    7. Reentrancy guard on critical functions
*/

/// @title Core dLogos contract
/// @author Ankit Bhatia
contract dLogos {

    struct Backer {
        address addr;
        uint256 amount; // ETH Contribution
    }

    /// @notice All on-chain information for a Convo.
    struct Logo {
        // Meta
        uint256 id;
        string title;
    
        // Roles
        address creator;

        uint scheduleAt;

        // Crowdfunding Attributes
        uint crowdfundStartAt;
        uint crowdfundEndAt;
        bool isCrowdfunding;

        uint numBackers;
        uint256 totalRaised;

        /*
        address[] speakers;
        address[] backers;      // BackerInfo[] backers;

        

        // Scheduling Attributes
        uint scheduleAt;
        uint scheduleFailedRefundAt; // Date to allow refund if conversation is not scheduled.
        bool isScheduled;
        
        // Media Upload Attributes
        uint uploadFailureRefundAt; // Date to allow refund if conversation is not uploaded.
        
        */
        string mediaAssetURL;
        bool isUploaded;
    }
    
    // Global Logo ID starting from 1
    uint256 public logoID = 1;
    // Mapping of Owner addresses to Logo ID to Logo info
    mapping(address => mapping(uint256 => Logo)) public logos;
    // Mapping of Logo ID to list of Backers
    mapping(uint256 => Backer[]) public logoBackers;
    // Mapping of Logo ID to Logo
    mapping(uint256 => Logo) public idToLogo;
    // Mapping of owner to all Logos
    mapping(address => Logo[]) allLogosByOwner;

    // dLogos fees in BPS (3%)
    uint16 public dLogosServiceFee = 300;

    /* Events */
    event LogUpdateFee(uint16 indexed _fee);
    event LogoCreated(address indexed _owner, uint indexed _logoID);
    event CrowdfundOpened(address indexed _owner, uint indexed _crowdfundStartAt, uint indexed _crowdfundEndAt);
    event Crowdfund(uint indexed _logoID, uint indexed _numBackers, uint indexed _totalRaised);

    function setServiceFee(uint16 _dLogosServiceFee) external {
        /* TODO: (1) onlyOwner */
        require(_dLogosServiceFee > 0 && _dLogosServiceFee <= 10000, "dLogos: DLOGOS_SERVICE_FEE_INVALID");
        dLogosServiceFee = _dLogosServiceFee;
        emit LogUpdateFee(dLogosServiceFee);
    }

    // Returns logoID
    function createLogo(
        string calldata _title,
        string calldata _mediaAssetURL
    ) external returns (uint256) {
        /* TODO: (1) Requires (2) right role */
        Logo memory l = Logo({
            id: logoID,
            title: _title,
            creator: msg.sender,
            scheduleAt: 0, // TODO: Correct default
            mediaAssetURL: _mediaAssetURL,
            isUploaded: false,
            isCrowdfunding: false,
            crowdfundStartAt: 0,
            crowdfundEndAt: 0,
            numBackers: 0,
            totalRaised: 0
        });

        logos[msg.sender][logoID] = l;
        idToLogo[logoID] = l;
        allLogosByOwner[msg.sender].push(l);

        emit LogoCreated(msg.sender, logoID);

        return logoID++; // Return and Increment Global Convo ID
    }

    /**
    * @dev Open crowdfund for Logo. Only the owner of the Logo is allowed to open a crowdfund.
    * returns if successful.
    */
    function openCrowdfund(
        uint256 _logoID,
        uint _crowdfundNumberOfDays
    ) external returns (bool) { 
        Logo memory l = logos[msg.sender][_logoID];
        // Todo: Add checks for _crowdfundNumberOfDays
        l.crowdfundStartAt = block.timestamp;
        l.crowdfundEndAt = block.timestamp + _crowdfundNumberOfDays * 1 days;
        l.isCrowdfunding = true;
        logos[msg.sender][_logoID] = l;

        emit CrowdfundOpened(msg.sender, l.crowdfundStartAt, l.crowdfundEndAt);

        return true;
    }

    function crowdfund(
        uint256 _logoID
    ) payable external {
        
        // TODO: Requires and Roles

        // Record the value sent to the address.
        Backer memory b = Backer({
            addr: msg.sender,
            amount: msg.value
        });

        logoBackers[_logoID].push(b);

        Logo memory l = idToLogo[_logoID];
        l.numBackers += 1;
        l.totalRaised += msg.value;

        emit Crowdfund(_logoID, l.numBackers, l.totalRaised);
    }

    /**
    * @dev Return the list of convos for a creator.
    */
    // function getConvo(address _creator) external view returns(Convo[] memory) {
    //     return conversations[_creator][];
    // }

    /**
    * @dev Set date for a conversation.
    */
    function setDateForLogo(
        uint256 _logoID, 
        uint _scheduleAt
    ) external {
    /* TODO: (1) Requires (2) right role `onlyCreator` */
        Logo memory l = logos[msg.sender][_logoID];
        l.scheduleAt = _scheduleAt;
        // c.isScheduled = true;
        logos[msg.sender][_logoID] = l;
    }

    /*
    * @dev Links media URl for a logo.
    * returns if link was successful
    */
    function linkMediaAsset(
        uint256 _convoID,
        string calldata _mediaAssetURL
    ) external returns (bool) {
        Logo memory l = logos[msg.sender][_convoID];
        l.mediaAssetURL = _mediaAssetURL;
        logos[msg.sender][_convoID] = l; // add check prior to this
        return true;
    }

}