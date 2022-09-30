// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./4_VipPass.sol";

/**
 * @title VipPassSale
 * @dev A medium to sell Digital VIP Passes
 */
contract VipPassSale {

    struct Sale {
        uint price; // Price of one pass in Wei
        uint supplyLeft; // Amount of passes unsold
        address seller; // The account that made the sale
    }

    uint256 salesIdCounter;

    // (salesId => sales)
    mapping(uint => Sale) public sales;

    // VIP Pass Contract
    VipPass vipPass;

    // A new sale has been created
    event SaleCreation(uint256 indexed supply, uint256 indexed price, address indexed seller);
    //A purchase has occured
    event SaleTransacted(uint256 saleQuantity, uint256 indexed saleId, uint256 indexed supplyLeft, address indexed seller);

    /**
     * @dev Sets the VIP Pass Contract 
     * @param vipPassContract the address of the deployed VIP Pass Contract
     */
    constructor(address vipPassContract) {
        vipPass = VipPass(vipPassContract);
    }

    /**
     * @dev Creates a new VIP Pass sale
     * @param supply the amount of VIP Passes to sell
     * @param price the price of one VIP Pass
     */
    function createSale(uint256 supply, uint256 price) public {
        vipPass.transfer(msg.sender, address(this), supply);
        salesIdCounter += 1;
        sales[salesIdCounter] = Sale({
            price: price,
            supplyLeft: supply,
            seller: msg.sender
        });

        emit SaleCreation(supply, price, msg.sender);
    }

    /**
     * @dev Buy an amount of VIP Passes from a sale
     * @param salesId the sales id to be purchased from
     * @param buyAmt the amount of VIP Passes to buy
     */
    function buyFromSale(uint256 salesId, uint256 buyAmt) public payable {
        require(sales[salesId].supplyLeft >= buyAmt, "No VIP Passes in this sale");
        require(msg.value >= sales[salesId].price * buyAmt, "Not enough ETH sent");

        sales[salesIdCounter].supplyLeft -= buyAmt;

        vipPass.transfer(address(this), msg.sender, buyAmt);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title VipPass
 * @dev Digital VIP Pass
 */
contract VipPass {

    address public admin;

    // (minter => isMinter)
    mapping(address => bool) public isMinter;

    // (holder => balance)
    mapping(address => uint256) public balanceOf;

    // (account => (approvedSpender => isApproved))
    mapping(address => mapping(address => bool)) public isApproved;

    event Transfer(address indexed sender, address indexed receiver, uint256 indexed amt);

    /**
     * @dev Sets the admin that manages the VIP Passes
     * @param _admin the admin who manages the VIP Passes
     */
    constructor(address _admin) {
        admin = _admin;
        isMinter[admin] = true;
    }

    /**
     * @dev Mints new VIP Passes to an account
     * @param receiver the account that receives the newly minted VIP Passes
     * @param mintAmt the amount of VIP Passes to mint
     */
    function mint(address receiver, uint256 mintAmt) public {
        require(isMinter[msg.sender], "Caller does not have minting rights");

        balanceOf[receiver] += mintAmt;

        emit Transfer(address(0), receiver, mintAmt);
    }

    /**
     * @dev Transfer VIP Passes from the caller's account to another account
     * @param receiver the receiver of the VIP Pass transfer
     * @param transferAmt the amount of VIP Passes to transfer
     */
    function transfer(address sender, address receiver, uint256 transferAmt) public {
        require(sender == msg.sender || isApproved[sender][msg.sender], "Transfer not allowed");

        balanceOf[sender] -= transferAmt;
        balanceOf[receiver] += transferAmt;

        emit Transfer(sender, receiver, transferAmt);
    }

    /**
     * @dev Set Minter permissions
     * @param minter the target minter
     * @param _isMinter whether or not to give the minter minting rights
     */
    function manageMinters(address minter, bool _isMinter) public {
        require(msg.sender == admin, "Caller is not admin");

        isMinter[minter] = _isMinter;
    }

    /**
     * @dev Set the approval permission of tranferring VIP Passes for caller's account
     * @param spender the target account that can have perssion to transfer caller's VIP Passes
     * @param _isApproved whether or not the spender is approved
     */
    function approveSpender(address spender, bool _isApproved) public {
        isApproved[msg.sender][spender] = _isApproved;
    }

}