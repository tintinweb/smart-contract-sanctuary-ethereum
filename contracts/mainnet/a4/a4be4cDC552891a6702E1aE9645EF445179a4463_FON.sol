// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract FON is ERC20 {
    address public admin;
    address public receiver;
    address public fon721maker;
    address public stake;
    address public distributor;
    address public fon721;
    address public auction;
    address public ticket;

    uint public stakeFeePercentage;
    uint public fon721Fee;
    uint public ownPercentage;
    uint public exitPercentage;
    uint public auctionFeePercentage;
    uint public auctionMinterFeePercentage;

    mapping(address => bool) public minters;
    mapping(address => bool) public allowed721;
    mapping(address => bool) public auctionMinters;

    event NewAdmin(address indexed newAdmin);
    event NewReceiver(address indexed newReceiver);
    event NewFON721Maker(address indexed newFON721Maker);
    event NewStake(address indexed newStake);
    event NewDistributor(address indexed newDistributor);
    event NewFON721(address indexed newFON721);
    event NewAllowed721(address indexed newAllowed721, bool isAllowed);
    event NewMinter(address indexed newMinter, bool isMinter);
    event NewAuction(address indexed newAuction);
    event NewTicket(address indexed newTicket);
    event NewAuctionMinter(address indexed newAuctionMinter);
    event NewAuctionMinterFeePercentage(uint newAuctionMinterFeePercentage);
    event NewStakeFeePercentage(uint newStakeFeePercentage);
    event NewFON721Fee(uint newFON721Fee);
    event NewOwnPercentage(uint newOwnPercentage);
    event NewExitPercentage(uint newExitPercentage);
    event NewAuctionFeePercentage(uint newAuctionFeePercentage);

    constructor(
        address newAdmin,
        address newReceiver,
        string memory name,
        string memory symbol,
        uint newOwnPercentage,
        uint newExitPercentage,
        uint newStakeFeePercentage,
        uint newAuctionFeePercentage,
        uint newAuctionMinterFeePercentage,
        uint newFON721Fee
    ) ERC20(name, symbol) {
        require(newAdmin != address(0) && newReceiver != address(0), "FON: zero address");
        admin = newAdmin;
        receiver = newReceiver;

        ownPercentage = newOwnPercentage;
        exitPercentage = newExitPercentage;
        stakeFeePercentage = newStakeFeePercentage;
        auctionFeePercentage = newAuctionFeePercentage;
        auctionMinterFeePercentage = newAuctionMinterFeePercentage;
        fon721Fee = newFON721Fee;
    }

    function setOwnPercentage(uint newOwnPercentage) external {
        require(msg.sender == admin, "FON: admin");
        require(
            newOwnPercentage > 0.5e18 && newOwnPercentage < exitPercentage,
            "FON: own percentage"
        );

        ownPercentage = newOwnPercentage;

        emit NewOwnPercentage(ownPercentage);
    }

    function setStakeFeePercentage(uint newStakeFeePercentage) external {
        require(msg.sender == admin, "FON: admin");

        stakeFeePercentage = newStakeFeePercentage;

        emit NewStakeFeePercentage(stakeFeePercentage);
    }

    function setAuctionFeePercentage(uint newAuctionFeePercentage) external {
        require(msg.sender == admin, "FON: admin");

        auctionFeePercentage = newAuctionFeePercentage;

        emit NewAuctionFeePercentage(auctionFeePercentage);
    }

    function setAuctionMinterFeePercentage(uint newAuctionMinterFeePercentage) external {
        require(msg.sender == admin, "FON: admin");

        auctionMinterFeePercentage = newAuctionMinterFeePercentage;

        emit NewAuctionMinterFeePercentage(auctionMinterFeePercentage);
    }

    function setFON721Fee(uint newFON721Fee) external {
        require(msg.sender == admin, "FON: admin");

        fon721Fee = newFON721Fee;

        emit NewFON721Fee(newFON721Fee);
    }

    function setMinter(address minterAddress) public {
        require(msg.sender == admin, "FON: admin");

        minters[minterAddress] = !minters[minterAddress];

        emit NewMinter(minterAddress, minters[minterAddress]);
    }

    function setAuctionMinter(address newAuctionMinter) external {
        require(msg.sender == admin, "FON: admin");
        require(newAuctionMinter != address(0), "FON: zero address");

        auctionMinters[newAuctionMinter] = !auctionMinters[newAuctionMinter];

        emit NewAuctionMinter(newAuctionMinter);
    }

    function setAllowed721(address allowed721Address) public {
        require(msg.sender == admin, "FON: admin");

        allowed721[allowed721Address] = !allowed721[allowed721Address];

        emit NewAllowed721(allowed721Address, allowed721[allowed721Address]);
    }

    function setExitPercentage(uint newExitPercentage) external {
        require(msg.sender == admin, "FON: admin");
        require(newExitPercentage > ownPercentage, "FON: exit percentage");

        exitPercentage = newExitPercentage;

        emit NewExitPercentage(exitPercentage);
    }

    function setAdmin(address newAdmin) external {
        require(msg.sender == admin, "FON: admin");
        require(newAdmin != address(0), "FON: zero address");
        admin = newAdmin;

        emit NewAdmin(admin);
    }

    function setReceiver(address newReceiver) external {
        require(msg.sender == admin, "FON: admin");
        require(newReceiver != address(0), "FON: zero address");
        receiver = newReceiver;

        emit NewReceiver(receiver);
    }

    function setFON721Maker(address newFON721Maker) external {
        require(msg.sender == admin, "FON: admin");
        require(newFON721Maker != address(0), "FON: zero address");

        setMinter(fon721maker);
        fon721maker = newFON721Maker;
        setMinter(fon721maker);

        emit NewFON721Maker(fon721maker);
    }

    function setStake(address newStake) external {
        require(msg.sender == admin, "FON: admin");
        require(newStake != address(0), "FON: zero address");
        stake = newStake;

        emit NewStake(stake);
    }

    function setDistributor(address newDistributor) external {
        require(msg.sender == admin, "FON: admin");
        require(newDistributor != address(0), "FON: zero address");

        setMinter(distributor);
        distributor = newDistributor;
        setMinter(distributor);

        emit NewDistributor(distributor);
    }

    function setFON721(address newFON721) external {
        require(msg.sender == admin, "FON: admin");
        require(newFON721 != address(0), "FON: zero address");

        setAllowed721(fon721);
        fon721 = newFON721;
        setAllowed721(fon721);

        emit NewFON721(fon721);
    }

    function setAuction(address newAuction) external {
        require(msg.sender == admin, "FON: admin");
        require(newAuction != address(0), "FON: zero address");

        setMinter(auction);
        auction = newAuction;
        setMinter(auction);

        emit NewAuction(auction);
    }

    function setTicket(address newTicket) external {
        require(msg.sender == admin, "FON: admin");
        require(newTicket != address(0), "FON: zero address");

        setMinter(ticket);
        ticket = newTicket;
        setMinter(ticket);

        emit NewTicket(ticket);
    }

    function mint(address to, uint amount) external {
        require(minters[msg.sender], "FON: minter");
        _mint(to, amount);
    }
}