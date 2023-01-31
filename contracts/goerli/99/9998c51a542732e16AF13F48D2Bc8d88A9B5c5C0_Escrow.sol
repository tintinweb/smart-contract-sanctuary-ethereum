//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

contract Escrow {
    address payable public seller;
    address public lender;
    address public inspector;
    address public nftAddress;

    mapping(uint256 => bool) public isListed;
    mapping(uint256 => uint256) public purchasePrice;
    mapping(uint256 => uint256) public escrowAmount;
    mapping(uint256 => address) public buyer;
    mapping(uint256 => bool) public inspectionPassed;
    mapping(uint256 => mapping(address => bool)) public approvals;

    modifier onlySeller() {
        require(msg.sender == seller, "only seller can call this method");
        _;
    }
    modifier onlyBuyer(uint256 _nftId) {
        require(msg.sender == buyer[_nftId], "only buyer can call this method");
        _;
    }
    modifier onlyInspector() {
        require(msg.sender == inspector, "only inspector can call this method");
        _;
    }

    constructor(
        address _nftAddress,
        address payable _seller,
        address _inspector,
        address _lender
    ) {
        nftAddress = _nftAddress;
        seller = _seller;
        inspector = _inspector;
        lender = _lender;
    }

    function list(
        uint256 _nftId,
        uint256 _purchasePrice,
        address _buyer,
        uint256 _escrowAmount
    ) public payable onlySeller {
        IERC721(nftAddress).transferFrom(msg.sender, address(this), _nftId);
        isListed[_nftId] = true;
        purchasePrice[_nftId] = _purchasePrice;
        escrowAmount[_nftId] = _escrowAmount;
        buyer[_nftId] = _buyer;
    }

    function depositEarnest(uint256 _nftId) public payable onlyBuyer(_nftId) {
        require(msg.value >= escrowAmount[_nftId]);
    }

    function updateInspectionStatus(uint256 _nftId, bool _passed)
        public
        onlyInspector
    {
        inspectionPassed[_nftId] = _passed;
    }

    function approveSale(uint256 _nftId) public {
        approvals[_nftId][msg.sender] = true;
    }

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function finalizeSale(uint256 _nftId) public {
        require(inspectionPassed[_nftId]);
        require(approvals[_nftId][buyer[_nftId]]);
        require(approvals[_nftId][seller]);
        require(approvals[_nftId][lender]);
        require(address(this).balance >= purchasePrice[_nftId]);
        isListed[_nftId] = false;

        (bool success, ) = payable(seller).call{value: address(this).balance}(
            ""
        );
        require(success);
        IERC721(nftAddress).transferFrom(address(this), buyer[_nftId], _nftId);
    }

    function cancelSale(uint256 _nftId) public {
        if (inspectionPassed[_nftId] == false) {
            payable(buyer[_nftId]).transfer(address(this).balance);
        } else {
            payable(seller).transfer(address(this).balance);
        }
    }
}