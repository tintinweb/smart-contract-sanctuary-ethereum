// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./_CloneFactory.sol";
import "./Escrow.sol";
import "./ReentrancyGuard.sol";

// test
import "./IERC20.sol";


contract EscrowFactory is ReentrancyGuard {

    address public admin;
    address public implementation;
    mapping (uint256 => address) clonedContracts;
    uint256 public clonedContractsIndex = 0;

    //Declaring Events
    event OfferCreated(uint256 indexed clonedContractsIndex, address indexed _seller, uint256 indexed _price, address[] _personalizedOffer, address[] _arbiters);
    // buyer
    event OfferAccepted(uint256 indexed clonedContractsIndex, address indexed _buyer);
    event DisputeStarted(uint256 indexed clonedContractsIndex, address indexed _buyer);
    event DeliveryConfirmed(uint256 indexed clonedContractsIndex, address indexed _buyer);
    // seller
    event FundsClaimed(uint256 indexed clonedContractsIndex, address indexed _seller);
    event PaymentReturned(uint256 indexed clonedContractsIndex, address indexed _seller);
    // dispute handling
    event DisputeVoted(uint256 indexed clonedContractsIndex, address indexed _arbiter, bool indexed _returnFundsToBuyer);
    event DisputeClosed(uint256 indexed clonedContractsIndex, bool indexed _FundsReturnedToBuyer);



    constructor (address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    function SetImplementation (address _implementation) onlyAdmin public {
        implementation = _implementation;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin);
        _;
    }


    function CreateEscrow (
        
        address[] calldata arbiters,
        uint256 price,
        address tokenContractAddress,
        uint256 timeToDeliver,
        string memory hashOfDescription,
        uint256 offerValidUntil,
        address[] calldata personalizedOffer
        
        // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, 
        // ["0xdD870fA1b7C4700F2BD7f44238821C26f7392148", "0x583031D1113aD414F02576BD6afaBfb302140225", "0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB"], 100000000000000000, "0x0000000000000000000000000000000000000000", 1, a23e5fdcd7b276bdd81aa1a0b7b963101863dd3f61ff57935f8c5ba462681ea6, 1657634353, ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]
        // ["0xdD870fA1b7C4700F2BD7f44238821C26f7392148", "0x583031D1113aD414F02576BD6afaBfb302140225", "0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB"], 100000000000000000, "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", 1, a23e5fdcd7b276bdd81aa1a0b7b963101863dd3f61ff57935f8c5ba462681ea6, 1657634353, ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"]
        // 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 - USDC
        // 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174 - USDC on Polygon
        // 0x0000000000000000000000000000000000000000 - ETH


        // ["0xdD870fA1b7C4700F2BD7f44238821C26f7392148", "0x583031D1113aD414F02576BD6afaBfb302140225", "0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB"], 100000000000000000, "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", 1, a23e5fdcd7b276bdd81aa1a0b7b963101863dd3f61ff57935f8c5ba462681ea6, 1657634353, []



    ) external {
        address clone = Clones.clone(implementation);

        Escrow(clone).Initialize(
            payable(address(this)),         // the Factory contract
            payable(msg.sender),            // seller,
            arbiters,
            price,
            tokenContractAddress,
            timeToDeliver,
            hashOfDescription,
            offerValidUntil,
            personalizedOffer
        );

        clonedContracts[clonedContractsIndex] = clone;
        clonedContractsIndex++;

        emit OfferCreated(clonedContractsIndex, msg.sender, price, personalizedOffer, arbiters);
    }



    // ---------------------------------------------------------------------------
    //                  API functions to the escrow contracts
    // ---------------------------------------------------------------------------

    // GENERAL - READ
    function GetAddress(uint256 index) view public returns(address) {
        return clonedContracts[index];
    }

    function GetBalance(uint256 index) view external returns(uint256){
        return address(GetAddress(index)).balance;
    }

    function GetTimeLeftToDeadline(uint256 index) view external returns(uint256){
        if(GetState(index) == Escrow.State.await_payment){   // before agreement is made 
            return 0;
        } else {
            return (GetDeadline(index) - block.timestamp);
        }
    }

    function GetArbiters(uint256 index) view external returns(address[] memory){
        return Escrow(clonedContracts[index]).getArbiters();
    }

    function GetArbitersVote(uint256 index) view external returns(uint256[3] memory){
        return Escrow(clonedContracts[index]).getArbitersVote();
    }

    function GetBuyer(uint256 index) view external returns(address){
        return Escrow(clonedContracts[index]).buyer();
    }

    function GetSeller(uint256 index) view external returns(address) {
        return Escrow(clonedContracts[index]).seller();
    }

    function GetState(uint256 index) view public returns(Escrow.State) {
        return Escrow(clonedContracts[index]).state();
    }

    function GetPrice(uint256 index) view external returns(uint256) {
        return Escrow(clonedContracts[index]).price();
    }

    function GetTokenContractAddress(uint256 index) view external returns(address) {
        return Escrow(clonedContracts[index]).tokenContractAddress();
    }

    function GetDeadline(uint256 index) view public returns(uint256) {
        return Escrow(clonedContracts[index]).deadline();
    }

    function GetHashOfDescription(uint256 index) view external returns(string memory) {
        return Escrow(clonedContracts[index]).hashOfDescription();
    }

    function GetGracePeriod(uint256 index) view external returns(uint256) {
        return Escrow(clonedContracts[index]).gracePeriod();
    }

    function GetIsOfferStillValid(uint256 index) view public returns(bool){
        return Escrow(clonedContracts[index]).isOfferValid();
    }

    function GetIsWalletEligibleToAcceptOffer(uint256 index, address wallet) view public returns(bool) {
    return Escrow(clonedContracts[index]).isWalletEligibleToAcceptOffer(wallet);
    }

    function GetIsWalletABuyerDelegate(uint256 index, address wallet) view public returns(bool) {
        return Escrow(clonedContracts[index]).isWalletBuyerDelegate(wallet);
    }

    function GetIsWalletASellerDelegate(uint256 index, address wallet) view public returns(bool) {
        return Escrow(clonedContracts[index]).isWalletSellerDelegate(wallet);
    }

    function GetValidUntil(uint256 index) view public returns(uint256){
        return Escrow(clonedContracts[index]).offerValidUntil();
    }

    function GetCommision(uint256 index) view public returns(uint256){
        return Escrow(clonedContracts[index]).GetCommision();
    }




    // WRITE FUNCTIONS

    // new buyer accepts the agreement
    function AcceptOffer(uint256 index) external payable {
        Escrow(clonedContracts[index]).acceptOffer{value: msg.value}(payable(msg.sender));        // forward the buyers address
        emit OfferAccepted(clonedContractsIndex, msg.sender);
    } 

    function AcceptOffer_ERC20(uint256 index) external {
        Escrow(clonedContracts[index]).acceptOffer_ERC20(payable(msg.sender));        // forward the buyers address
        emit OfferAccepted(clonedContractsIndex, msg.sender);
    } 


    // test
    function PayERC20_transferFrom(address erc20TokenAddress, uint256 amount) external {
        IERC20 tokenContract = IERC20(erc20TokenAddress);
        bool transferred = tokenContract.transferFrom(msg.sender, address(this), amount);
        require(transferred, "ERC20 tokens failed to transfer to contract wallet");
    }

    function PayERC20_transfer(address erc20TokenAddress, uint256 amount) external {
        IERC20 tokenContract = IERC20(erc20TokenAddress);
        bool transferred = tokenContract.transfer(address(this), amount);
        require(transferred, "ERC20 tokens failed to transfer to contract wallet");
    }


    // NOTE:
    // test if we can use `erc20TokenAddress` as the actual argument for `recipient`, so that we can transfer any token
    // best if we can rename the argument, if not -> we will just use supply the ERC20TokenAddress for the recipient argument (it will look weird, but it should do the job)

    // 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174
    function transfer(address recipient, uint256 amount) public returns (bool) {

        IERC20 tokenContract = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);          // USDC on polygon
        bool transferred = tokenContract.transferFrom(msg.sender, address(this), amount);
        // bool transferred = tokenContract.transfer(address(this), amount);                // same behaviour as 'transferFrom'
        require(transferred, "ERC20 tokens failed to transfer to contract wallet");

        return transferred;
    }

    function decimals() public view virtual returns (uint8) {
        return 6;
    }

    //-------------------------------------------------------------------------------------------------------------------------------------


    // ONLY SELLER
    function ReturnPayment(uint256 index) external payable {
        Escrow(clonedContracts[index]).returnPayment(msg.sender);
        emit PaymentReturned(clonedContractsIndex, msg.sender);
    } 

    function ClaimFunds(uint256 index) external payable {
        Escrow(clonedContracts[index]).claimFunds(msg.sender);
        emit FundsClaimed(clonedContractsIndex, msg.sender);
    } 

    // ONLY SELLER - DELEGATES
    function AddSellerDelegates(uint256 index, address[] calldata delegates) external {
        Escrow(clonedContracts[index]).addSellerDelegates(msg.sender, delegates);
    }
    function RemoveSellerDelegates(uint256 index, address[] calldata delegates) external {
        Escrow(clonedContracts[index]).removeSellerDelegates(msg.sender, delegates);
    }
    function UpdateSellerDelegates(uint256 index, address[] calldata delegatesToAdd, address[] calldata delegatesToRemove) external {
        Escrow(clonedContracts[index]).removeSellerDelegates(msg.sender, delegatesToRemove);
        Escrow(clonedContracts[index]).addSellerDelegates(msg.sender, delegatesToAdd);        
    }




    // ONLY BUYER
    function StartDispute(uint256 index) external {
        Escrow(clonedContracts[index]).startDispute(msg.sender);
        emit DisputeStarted(clonedContractsIndex, msg.sender);
    } 

    function ConfirmDelivery(uint256 index) external payable {
        Escrow(clonedContracts[index]).confirmDelivery(msg.sender);
        emit DeliveryConfirmed(clonedContractsIndex, msg.sender);
    } 

    // ONLY BUYER - DELEGATES
    function AddBuyerDelegates(uint256 index, address[] calldata delegates) external {
        Escrow(clonedContracts[index]).addBuyerDelegates(msg.sender, delegates);
    }
    function RemoveBuyerDelegates(uint256 index, address[] calldata delegates) external {
        Escrow(clonedContracts[index]).removeBuyerDelegates(msg.sender, delegates);
    }
    function UpdateBuyerDelegates(uint256 index, address[] calldata delegatesToAdd, address[] calldata delegatesToRemove) external {
        Escrow(clonedContracts[index]).removeBuyerDelegates(msg.sender, delegatesToRemove);
        Escrow(clonedContracts[index]).addBuyerDelegates(msg.sender, delegatesToAdd);
    }





    // ONLY ARBITER
    function HandleDispute(uint256 index, bool returnFundsToBuyer) external payable {

        bool caseClosed = Escrow(clonedContracts[index]).handleDispute(msg.sender, returnFundsToBuyer);
        emit DisputeVoted(clonedContractsIndex, msg.sender, returnFundsToBuyer);

        if(caseClosed){
            // emit event that case is closed and money was transferred
            emit DisputeClosed(clonedContractsIndex, returnFundsToBuyer);
        }
    }

}