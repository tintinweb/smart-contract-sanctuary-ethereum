/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDeal {
    function approve(string memory _gistId, string memory _gistHash) external;
}

contract DealFactory {
    event DealCreated(
        address issuer,
        address dealAddress,
        address[] _participants,
        uint256 _price,
        string _gistId,
        string _gistHash
    );

    //создаёт и хранит разные виды сделок
    address[] deals;

    function issue(
        address[] memory _participants,
        uint256 _price,
        string memory _gistId,
        string memory _gistHash
    ) external {
        IDeal deal;

        if (_participants.length == 1) {
           deal = new PrivateDeal(
                _participants[0],
                _price,
                _gistId,
                _gistHash
            );

            deals.push(address(deal));
        } else {
           deal = new PublicDeal(
                _participants,
                _price,
                _gistId,
                _gistHash
            );

            deals.push(address(deal));
        }

        emit DealCreated(msg.sender, address(deal), _participants, _price, _gistId, _gistHash);
    }

    function issuedDeals() public view returns (address[] memory) {
        return deals;
    }
}

contract PrivateDeal is IDeal {
    // создаёт прииватную сделку. для это нужен адрес билдера, адрес покупателя, цена, id и хэш гиста
    address issuer;
    address participant;

    uint256 public price;

    bytes32 gistId;
    bytes32 gistHash;

    uint256 public payed;

    bool public approvedByParticipant;

    constructor(
        address _participant,
        uint256 _price,
        string memory _gistId,
        string memory _gistHash
    ) {
        require(_participant != address(0), "GistId is not equals");

        issuer = msg.sender;
        participant = _participant;
        price = _price;
        gistId = keccak256(abi.encodePacked(_gistId));
        gistHash = keccak256(abi.encodePacked(_gistHash));
    }

    function approve(string memory _gistId, string memory _gistHash)
    external
    override
    onlyParticipant
    {
        require(
            gistId == keccak256(abi.encodePacked(_gistId)),
            "GistId is not equals"
        );
        require(
            gistHash == keccak256(abi.encodePacked(_gistHash)),
            "GistHash is not equals"
        );

        require(approvedByParticipant != true, "Deal has been approved");
        require(payed == price, "Deal hasn`t been paid");

        approvedByParticipant = true;

        (bool success,) = issuer.call{value : payed}("");
        require(success, "Transfer not successfuly executed");
    }

    receive() external payable onlyParticipant {
        require(price == msg.value, "You should pay exact value of deal");

        payed = msg.value;
    }

    modifier onlyParticipant() {
        require(
            participant == msg.sender,
            "Only Participant: caller is not the participant"
        );
        _;
    }
}

contract PublicDeal is IDeal {
    address issuer;

    mapping(address => bool) public participants;
    mapping(address => bool) public approvedByParticipants;
    mapping(address => uint256) public paid;

    uint256 public dealPrice;
    bytes32 public gistId;
    bytes32 public gistHash;

    modifier onlyParticipant() {
        require(
            participants[msg.sender], "You are not participant");
        _;
    }

    constructor(address[] memory _participants, uint256 _price, string memory _gistId, string memory _gistHash) {
        issuer = msg.sender;
        dealPrice = _price;
        gistId = keccak256(abi.encodePacked(_gistId));
        gistHash = keccak256(abi.encodePacked(_gistHash));

        for (uint256 i = 0; i < _participants.length; i++) {
            address participant = _participants[i];

            approvedByParticipants[participant] = false;
            participants[participant] = true;
        }
    }

    function approve(string memory _gistId, string memory _gistHash) external override onlyParticipant {

        require(
            gistId == keccak256(abi.encodePacked(_gistId)),
            "GistId is not equals"
        );
        require(gistHash == keccak256(abi.encodePacked(_gistHash)), "GistHash is not equals");
        require(approvedByParticipants[msg.sender] != true, "Deal has been approved");
        require(paid[msg.sender] == dealPrice, "Deal hasn`t been paid");

        //payable(issuer).transfer(paid[msg.sender]);
        approvedByParticipants[msg.sender] = true;
        (bool success,) = issuer.call{value : paid[msg.sender]}("");
        require(success, "Transfer not successfuly executed");
    }

    receive() external payable onlyParticipant {
        require(dealPrice == msg.value, "You should pay exact value of deal");
        paid[msg.sender] = uint256(msg.value);
    }
}