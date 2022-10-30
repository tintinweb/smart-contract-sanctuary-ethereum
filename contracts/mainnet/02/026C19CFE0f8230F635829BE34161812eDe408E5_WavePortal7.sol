/// SPDX-License-Identifier: BSL

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
[BSL License]
@title CryptoMarry contract
@notice This is the main contract that sets rules for proxy contract creation, minting ERC20 LOVE tokens,
minting NFT certificates, and other policies for the proxy contract. Description of the methods are provided 
below. 
@author Ismailov Altynbek <[email protected]>
 */

/*Interface for a Proxy Contract Factory*/
interface WaverFactoryC {
    function newMarriage(
        address _addressWaveContract,
        uint256 id,
        address _waver,
        address _proposed,
        uint256 policyDays,
        uint256 cmFee,
        uint256 _minimumDeadline,
        uint256 _divideShare
    ) external returns (address);

    function MarriageID(uint256 id) external returns (address);
}

/*Interface for a NFT Certificate Factory Contract*/
interface NFTContract {
    function mintCertificate(
        address _proposer,
        uint8 _hasensWaver,
        address _proposed,
        uint8 _hasensProposed,
        address _marriageContract,
        uint256 _id,
        uint256 _heartPatternsID,
        uint256 _certBackgroundID,
        uint256 mainID
    ) external;

    function changeStatus(
        address _marriageContract,
        bool _status
    ) external;

    function nftHolder(
        address _marriageContract
    ) external returns(uint);

}

/*Interface for a NFT split contracts*/
interface nftSplitC {
    function addAddresses(address _addAddresses) external;
}

/*Interface for a Proxy contract */
interface waverImplementation1 {
    function _addFamilyMember(address _member) external;

    function agreed() external;

    function declined() external;

    function getFamilyMembersNumber() external view returns (uint);

    function getCMfee() external view returns (uint);
}


contract WavePortal7 is ERC20, ERC2771Context, Ownable {
   
    address public addressNFT; // Address of NFT certificate factory
    address public addressNFTSplit; // Address of NFT splitting contract
    address public waverFactoryAddress; // Address of Proxy contract factory
    address public withdrawaddress; //Address to where comissions are withdrawed/

    uint256 internal id; //IDs of a marriage
    

    uint256 public claimPolicyDays; //Cooldown for claiming LOVE tokens;
    uint256 public promoDays; //promoDays for free 
    uint256 public saleCap; //Maximum cap of a LOVE token Sale
    uint256 public minPricePolicy; //Minimum price for NFTs
    uint256 public cmFee; // Small percentage paid by users for incoming and outgoing transactions.
    uint256 public exchangeRate; // Exchange rate for LOVE tokens for 1 ETH


    //Structs

    enum Status {
        Declined,
        Proposed,
        Cancelled,
        Accepted,
        Processed,
        Divorced,
        WaitingConfirmation,
        MemberInvited,
        InvitationAccepted,
        InvitationDeclined,
        MemberDeleted,
        PartnerAddressChanged
    }

    struct Wave {
        uint256 id;
        uint256 stake;
        address proposer;
        address proposed;
        Status ProposalStatus;
        address marriageContract;
    }

    struct Pause {
        address ContractAddress;
        uint Status;
    }

    mapping(address => uint256) internal proposers; //Marriage ID of proposer partner
    mapping(address => uint256) internal proposedto; //Marriage ID of proposed partner
    mapping(address => mapping(uint8 => uint256)) public member; //Stores family member IDs
    mapping(address => uint8) internal hasensName; //Whether a partner wants to display ENS address within the NFT
    mapping(uint256 => Wave) internal proposalAttributes; //Attributes of the Proposal of each marriage
    mapping(address => string) public messages; //stores messages of CM users
    mapping(address => uint8) internal authrizedAddresses; //Tracks whether a proxy contract addresses is authorized to interact with this contract.
    mapping(address => address[]) internal familyMembers; // List of family members addresses
    mapping(address => uint256) public claimtimer; //maps addresses to when the last time LOVE tokens were claimed.
    mapping(address => string) public nameAddress; //For giving Names for addresses. 
    mapping(address => uint) public pauseAddresses; //Addresses that can be paused.
    mapping(address => uint) public rewardAddresses; //Addresses that may claim reward. 
    mapping(address => string) public contactDetails; //Details of contact to send notifications

    /* An event to track status changes of the contract*/
    event NewWave(
        uint256 id,
        address sender,
        address indexed marriageContract,
        Status vid
    );


    /* A contructor that sets initial conditions of the Contract*/
    constructor(
        MinimalForwarder forwarder,
        address _nftaddress,
        address _waveFactory,
        address _withdrawaddress
    ) payable ERC20("CryptoMarry", "LOVE") ERC2771Context(address(forwarder)) {
        claimPolicyDays = 30 days;
        addressNFT = _nftaddress;
        saleCap = 1e25;
        minPricePolicy = 1e16 ;
        waverFactoryAddress = _waveFactory;
        //cmFee = 100;
        exchangeRate = 1000;
        withdrawaddress = _withdrawaddress;
        promoDays = 60 days;
    }

    error CONTRACT_NOT_AUTHORIZED(address contractAddress);

    /*This modifier check whether an address is authorised proxy contract*/
    modifier onlyContract() {
        if (authrizedAddresses[msg.sender] != 1) {revert CONTRACT_NOT_AUTHORIZED(msg.sender);}
        _;
    }

    /*These two below functions are to reconcile minimal Forwarder and ERC20 contracts for MSGSENDER */
    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return ERC2771Context._msgSender();
    }

    /** Errors replated to propose function */
     error YOU_CANNOT_PROPOSE_YOURSELF(address proposed);
     error USER_ALREADY_EXISTS_IN_CM(address user);
     error INALID_SHARE_PROPORTION(uint share);
     error PLATFORM_TEMPORARILY_PAUSED();
    /**
     * @notice Proposal and separate contract is created with given params.
     * @dev Proxy contract is created for each proposal. Most functions of the proxy contract will be available if proposal is accepted.
     * @param _proposed Address of the one whom proposal is send.
     * @param _message String message that will be sent to the proposed Address
     * @param _hasensWaver preference whether Proposer wants to display ENS on the NFT certificate
     */

    function propose(
        address _proposed,
        string memory _message,
        uint8 _hasensWaver,
        uint _policyDays,
        uint _minimumDeadline,
        uint _divideShare
    ) public payable {
        id += 1;
        if (pauseAddresses[address(this)]==1) {revert PLATFORM_TEMPORARILY_PAUSED();}
        if (msg.sender == _proposed) {revert YOU_CANNOT_PROPOSE_YOURSELF(msg.sender);}
        if (isMember(_proposed) != 0){revert USER_ALREADY_EXISTS_IN_CM(_proposed);}
        if (isMember(msg.sender) != 0){revert USER_ALREADY_EXISTS_IN_CM(msg.sender);}
        if (_divideShare > 10) {revert INALID_SHARE_PROPORTION (_divideShare);}

        proposers[msg.sender] = id;
        proposedto[_proposed] = id;
    

        hasensName[msg.sender] = _hasensWaver;
        messages[msg.sender] = _message;

        WaverFactoryC factory = WaverFactoryC(waverFactoryAddress);

        address _newMarriageAddress;

        /*Creating proxy contract here */
        _newMarriageAddress = factory.newMarriage(
            address(this),
            id,
            msg.sender,
            _proposed,
            _policyDays,
            cmFee,
            _minimumDeadline,
            _divideShare
        );

    
        nftSplitC nftsplit = nftSplitC(addressNFTSplit);
        nftsplit.addAddresses(_newMarriageAddress);

        authrizedAddresses[_newMarriageAddress] = 1;

        proposalAttributes[id] = Wave({
            id: id,
            stake: msg.value,
            proposer: msg.sender,
            proposed: _proposed,
            ProposalStatus: Status.Proposed,
            marriageContract: _newMarriageAddress
        });

        processtxn(payable(_newMarriageAddress), msg.value);

        emit NewWave(id, msg.sender,_newMarriageAddress, Status.Proposed);
    }


    error PROPOSAL_STATUS_CHANGED();
    /**
     * @notice Response is given from the proposed Address.
     * @dev Updates are made to the proxy contract with respective response. ENS preferences will be checked onchain.
     * @param _agreed Response sent as uint. 1 - Agreed, anything else will trigger Declined status.
     * @param _hasensProposed preference whether Proposed wants to display ENS on the NFT certificate
     */

    function response(
        uint8 _agreed,
        uint8 _hasensProposed
    ) public {
        address msgSender_ = _msgSender();
        uint256 _id = proposedto[msgSender_];

        Wave storage waver = proposalAttributes[_id];
        if (waver.ProposalStatus != Status.Proposed) {revert PROPOSAL_STATUS_CHANGED();}
      
        waverImplementation1 waverImplementation = waverImplementation1(
            waver.marriageContract
        );

        if (_agreed == 1) {
            waver.ProposalStatus = Status.Processed;
            hasensName[msgSender_] = _hasensProposed;
            waverImplementation.agreed();
        } else {
            waver.ProposalStatus = Status.Declined;
            proposedto[msgSender_] = 0;
            waverImplementation.declined();
        }
        emit NewWave(_id, msgSender_, waver.marriageContract, waver.ProposalStatus);
    }

    /**
     * @notice Updates statuses from the main contract on the marriage status
     * @dev Helper function that is triggered from the proxy contract. Requirements are checked within the proxy.
     * @param _id The id of the partnership recorded within the main contract.
     */

    function cancel(uint256 _id) external onlyContract {
        Wave storage waver = proposalAttributes[_id];
        waver.ProposalStatus = Status.Cancelled;
        proposers[waver.proposer] = 0;
        proposedto[waver.proposed] = 0;
    emit NewWave(_id, tx.origin, msg.sender, Status.Cancelled);
    }

    error FAMILY_ACCOUNT_NOT_ESTABLISHED();
    error CLAIM_TIMOUT_NOT_PASSED();
    /**
     * @notice Users claim LOVE tokens depending on the proxy contract's balance and the number of family members.
     * @dev LOVE tokens are distributed once within policyDays defined by the owner.
     */

    function claimToken() external {
        (address msgSender_, uint256 _id) = checkAuth();
        Wave storage waver = proposalAttributes[_id];
        if (waver.ProposalStatus != Status.Processed) {revert FAMILY_ACCOUNT_NOT_ESTABLISHED();}

        if (claimtimer[msgSender_] + claimPolicyDays > block.timestamp) {revert CLAIM_TIMOUT_NOT_PASSED();}
        
          waverImplementation1 waverImplementation = waverImplementation1(
            waver.marriageContract
        );
        claimtimer[msgSender_] = block.timestamp;
        uint amount;
        uint fee = waverImplementation.getCMfee();
        if ( fee == 0) { amount = 5*1e18; } 
        else if (fee < 50 && fee>0) { 
            amount = (waver.marriageContract.balance * exchangeRate) / (20 * waverImplementation.getFamilyMembersNumber());
        } else if (fee>50) { amount = (waver.marriageContract.balance * exchangeRate) / (10 * waverImplementation.getFamilyMembersNumber());} 
        _mint(msgSender_, amount);
    }

    /**
     * @notice Users can buy LOVE tokens depending on the exchange rate. There is a cap for the Sales of the tokens.
     * @dev Only registered users within the proxy contracts can buy LOVE tokens. Sales Cap is universal for all users.
     */

    function buyLovToken() external payable {
        (address msgSender_, uint256 _id) = checkAuth();
        Wave storage waver = proposalAttributes[_id];
       if (waver.ProposalStatus != Status.Processed) {revert FAMILY_ACCOUNT_NOT_ESTABLISHED();}
        uint256 issued = msg.value * exchangeRate;
        saleCap -= issued;
        _mint(msgSender_, issued);
    }

    error PAYMENT_NOT_SUFFICIENT(uint requiredPayment);
    /**
     * @notice Users can mint tiered NFT certificates. 
     * @dev The tier of the NFT is identified by the passed params. The cost of mint depends on minPricePolicy. 
     depending on msg.value user also automatically mints LOVE tokens depending on the Exchange rate. 
     * @param logoID the ID of logo to be minted.
     * @param BackgroundID the ID of Background to be minted.
     * @param MainID the ID of other details to be minted.   
     */

    function MintCertificate(
        uint256 logoID,
        uint256 BackgroundID,
        uint256 MainID
    ) external payable {
        //getting price and NFT address
        if (msg.value < minPricePolicy) {revert PAYMENT_NOT_SUFFICIENT(minPricePolicy);}

        (, uint256 _id) = checkAuth();
        Wave storage waver = proposalAttributes[_id];
      if (waver.ProposalStatus != Status.Processed) {revert FAMILY_ACCOUNT_NOT_ESTABLISHED();}
        uint256 issued = msg.value * exchangeRate;

        saleCap -= issued;
       
        NFTContract NFTmint = NFTContract(addressNFT);

        if (BackgroundID >= 1000) {
            if (msg.value < minPricePolicy * 100) {revert PAYMENT_NOT_SUFFICIENT(minPricePolicy * 100);}
        } else if (logoID >= 100) {
            if (msg.value < minPricePolicy * 10) {revert PAYMENT_NOT_SUFFICIENT(minPricePolicy * 10);}
        }

        NFTmint.mintCertificate(
            waver.proposer,
            hasensName[waver.proposer],
            waver.proposed,
            hasensName[waver.proposed],
            waver.marriageContract,
            waver.id,
            logoID,
            BackgroundID,
            MainID
        );

        _mint(waver.proposer, issued / 2);
        _mint(waver.proposed, issued / 2);
    }

    /* Adding Family Members*/

    error MEMBER_NOT_INVITED(address member);
    /**
     * @notice When an Address has been added to a Proxy contract as a family member, 
     the owner of the Address have to accept the invitation.  
     * @dev The system checks whether the msg.sender has an invitation, if it is i.e. id>0, it adds the member to 
     corresponding marriage id. It also makes pertinent adjustments to the proxy contract. 
     * @param _response Bool response of the owner of Address.    
     */

    function joinFamily(uint8 _response) external {
        address msgSender_ = _msgSender();
        if (member[msgSender_][0] == 0) {revert MEMBER_NOT_INVITED(msgSender_);}
        uint256 _id = member[msgSender_][0];
        Wave storage waver = proposalAttributes[_id];
        Status status;

        if (_response == 2) {
            member[msgSender_][1] = _id;
            member[msgSender_][0] = 0;
            
            waverImplementation1 waverImplementation = waverImplementation1(
                waver.marriageContract
            );
            waverImplementation._addFamilyMember(msgSender_);
            status = Status.InvitationAccepted;
        } else {
            member[msgSender_][0] = 0;
            status = Status.InvitationDeclined;
        }

      emit NewWave(_id, msgSender_, waver.marriageContract, status);
    }

    
    /**
     * @notice A proxy contract adds a family member through this method. A family member is first invited,
     and added only if the indicated Address accepts the invitation.   
     * @dev invited user preliminary received marriage _id and is added to a list of family Members of the contract.
     Only marriage partners can add a family member. 
     * @param _familyMember Address of a member being invited.    
     * @param _id ID of the marriage.
     */

    function addFamilyMember(address _familyMember, uint256 _id)
        external
        onlyContract
    {
        if (isMember(_familyMember) != 0) {revert USER_ALREADY_EXISTS_IN_CM(_familyMember);}
        member[_familyMember][0] = _id;
        familyMembers[msg.sender].push(_familyMember);
        emit NewWave(_id, _familyMember,msg.sender,Status.MemberInvited);
    }
  
    /**
     * @notice A family member can be deleted through a proxy contract. A family member can be deleted at any stage.
     * @dev the list of a family members per a proxy contract is not updated to keep history of members. Deleted 
     members can be added back. 
     * @param _familyMember Address of a member being deleted.    
     */

    function deleteFamilyMember(address _familyMember, uint id_) external onlyContract {
        if (member[_familyMember][1] > 0) {
            member[_familyMember][1] = 0;
        } else {
            if (member[_familyMember][0] == 0) {revert MEMBER_NOT_INVITED(_familyMember);}
            member[_familyMember][0] = 0;
        }
    emit NewWave(id_, _familyMember, msg.sender, Status.MemberDeleted);
    }

      /**
     * @notice A function to add string name for an Address 
     * @dev Names are used for better UI/UX. 
     * @param _name String name
     */

    function addName(string memory _name) external {
        nameAddress[msg.sender] = _name;
    }

      /**
     * @notice A function to add contact for notifications 
     * @dev It is planned to send notifications using webhooks
     * @param _contact String name
     */

    function addContact(string memory _contact) external {
        contactDetails[msg.sender] = _contact;
    }

    /**
     * @notice A view function to get the list of family members per a Proxy Contract.
     * @dev the list is capped by a proxy contract to avoid unlimited lists.
     * @param _instance Address of a Proxy Contract.
     */

    function getFamilyMembers(address _instance)
        external
        view
        returns (address[] memory)
    {
        return familyMembers[_instance];
    }

    /**
     * @notice If a Dissalution is initiated and accepted, this method updates the status of the partnership as Divorced.
     It also updates the last NFT Certificates Status.  
     * @dev this method is triggered once settlement has happened within the proxy contract. 
     * @param _id ID of the marriage.   
     */

    function divorceUpdate(uint256 _id) external onlyContract {
        Wave storage waver = proposalAttributes[_id];
      if (waver.ProposalStatus != Status.Processed) {revert FAMILY_ACCOUNT_NOT_ESTABLISHED();}
        waver.ProposalStatus = Status.Divorced;
        NFTContract NFTmint = NFTContract(addressNFT);

        if (NFTmint.nftHolder(waver.marriageContract)>0) {
            NFTmint.changeStatus(waver.marriageContract, false);
        }
    emit NewWave(_id, msg.sender, msg.sender, Status.Divorced);
    }

    error COULD_NOT_PROCESS(address _to, uint amount);

    /**
     * @notice Internal function to process payments.
     * @dev call method is used to keep process gas limit higher than 2300.
     * @param _to Address that will be reveiving payment
     * @param _amount the amount of payment
     */

    function processtxn(address payable _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}("");
        if (!success) {revert COULD_NOT_PROCESS(_to,_amount);}
    }

    /**
     * @notice internal view function to check whether msg.sender has marriage ID.
     * @dev for a family member that was invited, temporary id is given.
     */

    function isMember(address _partner) public view returns (uint256 _id) {
        if (proposers[_partner] > 0) {
            return proposers[_partner];
        } else if (proposedto[_partner] > 0) {
            return proposedto[_partner];
        } else if (member[_partner][1] > 0) {
            return member[_partner][1];
        } else if (member[_partner][0] > 0) {
            return 1e9;
        }
    }

    function checkAuth()
        internal
        view
        returns (address __msgSender, uint256 _id)
    {
        address msgSender_ = _msgSender();
        uint256 uid = isMember(msgSender_);
        return (msgSender_, uid);
    }

    /**
     * @notice  public view function to check whether msg.sender has marriage struct Wave with proxy contract..
     * @dev if msg.sender is a family member that was invited, temporary id is sent. If id>0 not found, empty struct is sent.
     */
  

    function checkMarriageStatus() external view returns (Wave memory) {
        // Get the tokenId of the user's character NFT
        (address msgSender_, uint256 _id) = checkAuth();
        // If the user has a tokenId in the map, return their character.
        if (_id > 0 && _id < 1e9) {
            return proposalAttributes[_id];
        }
        if (_id == 1e9) {
            uint __id = member[msgSender_][0]; 
             Wave memory waver = proposalAttributes[__id];
            return
                Wave({
                    id: _id,
                    stake: waver.stake,
                    proposer: waver.proposer,
                    proposed: waver.proposed,
                    ProposalStatus: Status.WaitingConfirmation,
                    marriageContract: waver.marriageContract
                });
        }

        Wave memory emptyStruct;
        return emptyStruct;
    }

    /**
     * @notice Proxy contract can burn LOVE tokens as they are being used.
     * @dev only Proxy contracts can call this method/
     * @param _to Address whose LOVE tokens are to be burned.
     * @param _amount the amount of LOVE tokens to be burned.
     */

    function burn(address _to, uint256 _amount) external onlyContract {
        _burn(_to, _amount);
    }

    /* Parameters that are adjusted by the contract owner*/

    /**
     * @notice Tuning policies related to CM functioning
     * @param _claimPolicyDays The number of days required before claiming next LOVE tokens
     * @param _minPricePolicy Minimum price of minting NFT certificate of family account
     */

    function changePolicy(uint256 _claimPolicyDays, uint256 _minPricePolicy) external onlyOwner {
        claimPolicyDays = _claimPolicyDays;
        minPricePolicy = _minPricePolicy;
    }


    /**
     * @notice Changing Policies in terms of Sale Cap, Fees and the Exchange Rate
     * @param _saleCap uint is set in Wei.
     * @param _exchangeRate uint is set how much Love Tokens can be bought for 1 Ether.
     */

    function changeTokenPolicy(uint256 _saleCap, uint256 _exchangeRate, uint256 _promoDays) external onlyOwner {
        saleCap = _saleCap;
        exchangeRate = _exchangeRate;
        promoDays = _promoDays;
    }

    /**
     * @notice A fee that is paid by users for incoming and outgoing transactions.
     * @param _cmFee uint is set in Wei.*/
     
    function changeFee(uint256 _cmFee) external onlyOwner {
       cmFee = _cmFee;
    }

    /**
     * @notice A reference contract address of NFT Certificates factory and NFT split.
     * @param _addressNFT an Address of the NFT Factort.
     * @param _addressNFTSplit an Address of the NFT Split. 
     */

    function changeaddressNFT(address _addressNFT, address _addressNFTSplit ) external onlyOwner {
        addressNFT = _addressNFT;
        addressNFTSplit = _addressNFTSplit;
    }

    /**
     * @notice Changing contract addresses of Factory and Forwarder
     * @param _addressFactory an Address of the New Factory.
     */

    function changeSystemAddresses(address _addressFactory, address _withdrawaddress)
        external
        onlyOwner
    {
        waverFactoryAddress = _addressFactory;
        withdrawaddress = _withdrawaddress;
    }

 
   /**
     * @notice A functionality for "Social Changing" of a partner address. 
     * @dev can be called only by the Partnership contract 
     * @param _partner an Address to be changed.
     * @param _newAddress an address to be changed to.
     * @param id_ Address of the partnership.
     */

    function changePartnerAddress(address _partner, address _newAddress, uint id_) 
        external
    {
         Wave storage waver = proposalAttributes[id_];
         if (msg.sender != waver.marriageContract) {revert CONTRACT_NOT_AUTHORIZED(msg.sender);}
         if (proposers[_partner] > 0) {
            proposers[_partner] = 0;
            proposers[_newAddress] = id_;
            waver.proposer =  _newAddress;
        } else if (proposedto[_partner] > 0) {
            proposedto[_partner] = 0;
            proposedto[_newAddress] = id_; 
            waver.proposed = _newAddress;
        } 
    emit NewWave(id_, _newAddress, msg.sender, Status.PartnerAddressChanged);
    }

    /**
     * @notice A function that resets indexes of users 
     * @dev A user will not be able to access proxy contracts if triggered from the CM FrontEnd
     */

    function forgetMe() external {
        proposers[msg.sender] = 0;
        proposedto[msg.sender] = 0;
        member[msg.sender][1] = 0;
    }
    error ACCOUNT_PAUSED(address sender);
    /**
     * @notice A method to withdraw comission that is accumulated within the main contract. 
     Withdraws the whole balance.
     */

    function withdrawcomission() external {
        if (msg.sender != withdrawaddress) {revert CONTRACT_NOT_AUTHORIZED(msg.sender);}
        if (pauseAddresses[msg.sender] == 1){revert ACCOUNT_PAUSED(msg.sender);}
        processtxn(payable(withdrawaddress), address(this).balance);
    }

    /**
     * @notice A method to withdraw comission that is accumulated within ERC20 contracts.  
     Withdraws the whole balance.
     * @param _tokenID the address of the ERC20 contract.
     */
    function withdrawERC20(address _tokenID) external {
        if (msg.sender != withdrawaddress) {revert CONTRACT_NOT_AUTHORIZED(msg.sender);}
        if (pauseAddresses[msg.sender] == 1){revert ACCOUNT_PAUSED(msg.sender);}
        uint256 amount;
        amount = IERC20(_tokenID).balanceOf(address(this));
        bool success =  IERC20(_tokenID).transfer(withdrawaddress, amount);
        if (!success) {revert COULD_NOT_PROCESS(withdrawaddress,amount);}
    }

    /**
     * @notice A method to pause withdrawals from the this and proxy contracts if threat is detected.
     * @param pauseData an List of addresses to be paused/unpaused
     */
    function pause(Pause[] calldata pauseData) external {
        if (msg.sender != withdrawaddress) {revert CONTRACT_NOT_AUTHORIZED(msg.sender);}
        for (uint i; i<pauseData.length; i++) {
            pauseAddresses[pauseData[i].ContractAddress] = pauseData[i].Status;
        }   
    }

     /**
     * @notice A method to mint LOVE tokens who participated in Reward Program
     * @param mintData an List of addresses to be rewarded
     */
    function reward(Pause[] calldata mintData) external onlyOwner{
        for (uint i; i<mintData.length; i++) {
            rewardAddresses[mintData[i].ContractAddress] = mintData[i].Status;
        }   
    }
    error REWARD_NOT_FOUND(address claimer);
    function claimReward() external {
        if (rewardAddresses[msg.sender] == 0) {revert REWARD_NOT_FOUND(msg.sender);}
        uint amount = rewardAddresses[msg.sender];
        rewardAddresses[msg.sender] = 0;
        _mint(msg.sender, amount);
        saleCap-= amount;
    }

  /**
     * @notice A view function to monitor balance
     */

    function balance() external view returns (uint ETHBalance) {
       return address(this).balance;
    }

    receive() external payable {
        if (pauseAddresses[msg.sender] == 1){revert ACCOUNT_PAUSED(msg.sender);}
        require(msg.value > 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/MinimalForwarder.sol)

pragma solidity ^0.8.0;

import "../utils/cryptography/ECDSA.sol";
import "../utils/cryptography/draft-EIP712.sol";

/**
 * @dev Simple minimal forwarder to be used together with an ERC2771 compatible contract. See {ERC2771Context}.
 */
contract MinimalForwarder is EIP712 {
    using ECDSA for bytes32;

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
    }

    bytes32 private constant _TYPEHASH =
        keccak256("ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data)");

    mapping(address => uint256) private _nonces;

    constructor() EIP712("MinimalForwarder", "0.0.1") {}

    function getNonce(address from) public view returns (uint256) {
        return _nonces[from];
    }

    function verify(ForwardRequest calldata req, bytes calldata signature) public view returns (bool) {
        address signer = _hashTypedDataV4(
            keccak256(abi.encode(_TYPEHASH, req.from, req.to, req.value, req.gas, req.nonce, keccak256(req.data)))
        ).recover(signature);
        return _nonces[req.from] == req.nonce && signer == req.from;
    }

    function execute(ForwardRequest calldata req, bytes calldata signature)
        public
        payable
        returns (bool, bytes memory)
    {
        require(verify(req, signature), "MinimalForwarder: signature does not match request");
        _nonces[req.from] = req.nonce + 1;

        (bool success, bytes memory returndata) = req.to.call{gas: req.gas, value: req.value}(
            abi.encodePacked(req.data, req.from)
        );

        // Validate that the relayer has sent enough gas for the call.
        // See https://ronan.eth.link/blog/ethereum-gas-dangers/
        if (gasleft() <= req.gas / 63) {
            // We explicitly trigger invalid opcode to consume all gas and bubble-up the effects, since
            // neither revert or assert consume all gas since Solidity 0.8.0
            // https://docs.soliditylang.org/en/v0.8.0/control-structures.html#panic-via-assert-and-error-via-require
            assembly {
                invalid()
            }
        }

        return (success, returndata);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}