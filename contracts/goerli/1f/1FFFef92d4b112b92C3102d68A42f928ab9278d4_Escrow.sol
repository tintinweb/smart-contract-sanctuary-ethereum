// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;
}

contract Escrow {
    address public nftAddress;
    uint256 public nftID;
    uint256 public purchasePrice;
    uint256 public escrowAmount;
    address payable seller;
    address payable buyer;
    address inspector;
    address lender;
    bool public inspetionPassed = false;
    mapping(address => bool) public approval;

    receive() external payable {}

    constructor(
        address _nftAddress,
        uint256 _nftID,
        uint256 _purchasePrice,
        address payable _seller,
        uint256 _ecrowAmount
    ) {
        nftAddress = _nftAddress;
        nftID = _nftID;
        purchasePrice = _purchasePrice;
        seller = _seller;
        escrowAmount = _ecrowAmount;
    }

    function setBuyer(address payable _buyer) public onlySeller {
        buyer = _buyer;
    }

    function setInspector(address _inspector) public onlySeller {
        inspector = _inspector;
    }

    function setLender(address _lender) public onlySeller {
        lender = _lender;
    }

    function depositEarnest() public payable onlyBuyer {
        require(
            msg.value >= escrowAmount,
            "Escrow amount must be less than purchase value"
        );
    }

    function updateInspectionPassed(bool _passed) public onlyInspector {
        inspetionPassed = _passed;
    }

    function approveSale() public {
        approval[msg.sender] = true;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function calcelSale() public {
        if (!inspetionPassed) {
            payable(buyer).transfer(address(this).balance);
        } else {
            payable(seller).transfer(address(this).balance);
        }
    }

    function finalizeSale() public onlyBuyer {
        require(inspetionPassed, "must pass inspection");
        require(approval[buyer], "Must be approved by buyer");
        require(approval[seller], "Must be approved by seller");
        require(approval[lender], "Must be approved by lender");
        require(
            address(this).balance >= purchasePrice,
            "Must have enough ether for sale"
        );

        (bool success, ) = payable(seller).call{value: address(this).balance}(
            ""
        );
        require(success);
        // Transfer oweership of property
        IERC721(nftAddress).transferFrom(seller, buyer, nftID);
    }

    modifier onlyBuyer() {
        require(msg.sender == buyer, "Only buyer can call this function");
        _;
    }

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this function");
        _;
    }

    modifier onlyInspector() {
        require(
            msg.sender == inspector,
            "Only inspector can call this function"
        );
        _;
    }
}