// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

contract Escrow {
    address public nftAddress;
    address payable public seller;
    address public inspector;
    address public lender;

    modifier onlySeller() {
        require(msg.sender == seller, "Only seller can call this function");
        _;
    }

    modifier onlyBuyer(uint256 _nftID) {
        require(msg.sender == buyer[_nftID], "Only buyer can call this function");
        _;
    }

    modifier onlyInspector() {
        require(msg.sender == inspector, "Only inspector can call this function");
        _;
    }

    mapping(uint256 => bool) public isListed;                       // mapping for getting list status
    mapping(uint256 => uint256) public purchasePrice;               // mapping for getting purchase price
    mapping(uint256 => uint256) public escrowAmount;                // mapping for getting escrow amount
    mapping(uint256 => address) public buyer;                       // mapping for getting the buyer
    mapping(uint256 => bool) public inspectionPassed;               // mapping for getting inspection status
    mapping(uint256 => mapping(address => bool)) public approval;   // mapping for getting approval status

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

    receive() external payable {}

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }    

    // Seller lists property
    function list(
        uint256 _nftID,
        address _buyer,
        uint256 _purchasePrice,
        uint256 _escrowAmount
    ) public payable onlySeller {
        // Transfer NFT from seller to this contract
        IERC721(nftAddress). transferFrom(msg.sender, address(this), _nftID);

        // Update mapping
        isListed[_nftID] = true;     
        purchasePrice[_nftID] = _purchasePrice;
        escrowAmount[_nftID] = _escrowAmount;
        buyer[_nftID] = _buyer;
    }

    // Buyer deposits earnest
    function depositEarnest(uint256 _nftID) public payable onlyBuyer(_nftID) {
        require(msg.value >= escrowAmount[_nftID]);
    }

    // Appraisal
    function updateInspectionStatus(uint256 _nftID, bool _passed) public onlyInspector {
        inspectionPassed[_nftID] = _passed;
    }

    // Sale approval
    function approveSale(uint256 _nftID) public {
        approval[_nftID][msg.sender] = true;
    }

    // Finalize sale
    // -> Require inspection status (add more items here, like appraisal)
    // -> Require sale to be authozied 
    // -> Require funds to be correct amount
    // -> Transfer NFT to buyer
    // -> Transfer Funds to Seller
    function finalizeSale(uint256 _nftID) public {
        require(inspectionPassed[_nftID], "Inspection status must be passed");
        require(approval[_nftID][buyer[_nftID]], "Buyer must approve before proceed");
        require(approval[_nftID][seller], "Seller must approve before proceed");
        require(approval[_nftID][lender], "Lender must approve before proceed");
        require(address(this).balance >= purchasePrice[_nftID], "Not enough fund to purchase");

        // Send the amount to seller
        (bool success, ) = payable(seller).call{value: address(this).balance}("");
        require(success, "Send amount to seller fail");

        // Transfer NFT to buyer
        IERC721(nftAddress). transferFrom(address(this), buyer[_nftID], _nftID);

        // Set listed status to false since it is transferred to the buyer already
        isListed[_nftID] = false;
    }

    // Cancel Sale (handle earnest deposit)
    // -> if inpsection status is not approved, then refund, otherwise send to seller
    function cancelSale(uint256 _nftID) public {
        if(inspectionPassed[_nftID] == false) {
            payable(buyer[_nftID]).transfer(address(this).balance);
        } else {
            payable(seller).transfer(address(this).balance);
        }
    }
}