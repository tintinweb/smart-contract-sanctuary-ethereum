/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// 'Giving Circle' Implementation by tlogs.eth & JakeHomanics for ATXDAO 
// SPDX-License-Identifier: MIT

// The 'Giving Circle' contract allows for periodic token gifting based on proposal voting within circles.

// ~ Contract Initiation Operations ~

// Circle Admin: 
    // deploy contract to set giftToken, giftAmount, beansPerAttendee, & taxThreshold 
        // don't worry all can be updated by Circle Admin
    // contract deployer is first CircleAdmin & CircleLeader
    // call 'newCircleLeader' to elect first circleLeader if seperation of duties is desired
    // call 'newCircleAdmin' to elect a new Circle Admin if desired

// ~ Pre-Circle Operations ~

// Circle Leader: 
    // call 'newCircle' to create a new instance of 'GivingCircle' (step 0)
        // New circles are automatically open for 'Proposals' (step 1) 
    // call closePropWindow to close the circle to new proposals (step 2)
// Circle Admin: 
    // call fundGiftForCircle which sends 'giftPerCircle' to contract and funds the circle (circleFunded = True)
// Proposers:
    // submit proposals
    // KYC with circle admin

// ~ Circle Operations~

// 'Circle Leader: 
    // call disburseBeans which disburses 10 beans each (step 3)
    // call openCirclevoting after presentations (step 4)
    // call closeCirclevoting (step 5) which automatically allocates gifts (step 6) based on each Proposals beansReceived
// Bean Holders:
    // call 'placeBeans' to vote on proposals during (step 4)

// ~ Post-Circle Operations~

// Proposers: 
    // call 'redeemGifts' at will to redeem accumulated gifts from all circles
// Circle Admin:
    // call 'removeBeans' to zero out bean balances for next circle
    // call 'removeGiftTokens' to remove any remaining USDC over 3K USDC per Governance Doc
    // call 'getGiftRecords' as necessary to get an address's gifting history for tax purposes
    // call 'taxableGifts' as neccessary to get all addresses who have withdrawn gifts over tax threhsold
        // ** does not consider one kyc'ed user having multiple addresses which could recieve gifts in excess of tax threshold when combined

pragma solidity ^0.8.17;

    // relevant portions of iERC20 for giftToken transactions

interface giftTokenContract {

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */

    function balanceOf(address account) external view returns (uint256);

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
}

// implement giftToken instead of USDC throughout. allows for easily adding multiple gift tokens.

contract ATXDAOgivingCircle {

// STATE VARIABLES & STRUCTS

    // interface variables

giftTokenContract public giftToken; // defines ERC20 giftToken for contract

    // utility variables

uint public weiMultiplier; // utilized in various calcs to convert to ERC20 decimals

address public circleleader; // needed to start first circle, set in constructor

address public circleAdmin; // funder of circle gifts, can withdraw giftTokens from contract at any time

    // gift variables

uint public totalTokensgifted; // decimals = 0

uint public totalGiftTokensPending; // decimals = 0

uint public taxThreshold; // configurable to find all addresses with taxable amounts. 

    // bean variables

uint public totalBeans; // decimals = 0

    // circle variables & struct

uint[] public checkforCircle; // array of circle numbers utilized to check if giving cricle exists. array of all circle numbers

uint public giftTokensperCircle; // initially 1000 USDC per circle. decmials = 0 (multiplied by weiMultiplier in all calcs)

uint public beansPerAttendee; // how many 'votes' each attendee gets in a circle

struct GivingCircle {
    uint giftTokensPerBean; // decimal 0
    address circleLeader; // set to current circleleader per utility variable when newCircle function is run.
    address circleAdmin; 
    uint256 step;  // tlogs: we need to write out the steps here in the descriptions
                            // step 1 = proposal window open. circle created with newCircle function
                            // step 2 = proposal window closed. ready to disburse beans...
                            // step 3 = beansDisbursed requires 'circleFunded' = true in GivingCircle struct
                            // step 4 = votingOpen. set in beansDisbursed after _calcGiftTokensPerBean
                            // step 5 = votingClosed
                            // step 6 = circleGiftsAllocated
    bool circleFunded; // required to disburse beans and activate step 3 
}

    // proposal variables & struct

uint[] public checkforProp; // array or prop numbers for various 'for' loops

struct Proposal {
    uint beansReceived;
    address payable giftAddress;
}

// MAPPINGS

    // gift mappings

mapping (address => uint) public giftPending; // decimals = 0

mapping (address => uint) public totalGiftsWithdrawn; // tracks total gifts withdrawn by proposers, decimals = 0

    // bean mappings

mapping (address => uint) beanBalances; // beanBalances have decimals of 0. tracks outstanding votes from all circles attended.

mapping (address => uint[]) circlesAttended; // to track the circle numbers each DAO member has attended.

    // circle mappings

mapping (uint => GivingCircle) public circleNumbers; // give each circle a number. uint replicated in checkforCircle array.

mapping (uint => uint[]) proposalsInCircle; // circle > proposals one-to-many. 

    // proposal mappings

mapping (uint => Proposal) public proposalNumbers; // give each proposal a number. uint replicated in checkforProp array.

mapping (uint => uint) proposalincircle; // proposal number > circle number, one-to-one, check which proposal a circle is in for USDCperBean lookup

mapping (address => bool) isKYCed; // must be set to true in order for redemptions

// EVENTS 

event NewCircleLeader(address indexed newLeader);

event NewCircleAdmin(address indexed newAdmin);

event NewTaxThreshold(uint indexed newTheshold);

    // gift events

event GiftsAllocated(uint indexed circleNumb, address[] indexed giftrecipients, uint[] indexed giftamounts);  // emitted in _allocateGifts

event GiftRedeemed(uint indexed giftwithdrawn, address indexed withdrawee);  // emitted in redeemGift

event GiftsRemoved(uint indexed giftTokensRemoved); // emitted in removeGiftTokens

    // bean events

event BeansDisbursed(uint indexed circleNumb, address[] indexed circleattendees, uint indexed beansdisbursedforcircle); // emitted in disburseBeans

event BeansPlaced(uint indexed propNumb, uint indexed beansplaced, address indexed beanplacer); // emitted in placeBeans

event BeansRemoved(address indexed beanhorder, uint indexed beansremoved); // emitted in removeBeans

    // circle events

event CircleCreated(uint indexed circleNumb); // emitted in newCircle

event ProposalWindowClosed(uint indexed circleNumb, uint[] indexed finalproplist); // emitted in closePropWindow

event VotingOpened(uint indexed circleNumb); // emitted in closeCircleVoting

event VotingClosed(uint indexed circleNumb); // emitted in closeCircleVoting

    // proposal events

event ProposalCreated(uint indexed propNumb, uint indexed circleNumb, address indexed giftrecipient); // emitted by proposeGift

event FundedCircle(uint indexed circleNumb, uint256 amount); // emitted by proposeGift

// CONSTRUCTOR 

    constructor(address _giftToken, uint _giftTokensperCircle, uint _beansPerAttendee, uint _taxThreshold) {

    circleleader = msg.sender; // set the first circle leader to contract deployer
    circleAdmin = msg.sender; // set the first circle admin to contract deployer
    
    weiMultiplier = 10**18;  // set weiMultiplier to convert between ERC-20 decimal = 10**18 and decimal 0
    
    giftToken = giftTokenContract(_giftToken); // set giftToken ERC20 contract address
    giftTokensperCircle = _giftTokensperCircle; // set initial giftTokensperCircle. to be multiplied by weiMultiplier in all ERC20 calls, decimal = 0
    beansPerAttendee = _beansPerAttendee; // votes for each Circle attendee. To be zeroed out be admin after each circle
    taxThreshold = _taxThreshold; // sets the minimum gift token qty withdrawn for admin tax search
    }

// UTILITY FUNCTIONS

    // @tlogs: Returns the address of the circleLeader for a given circleNumber

    function circleLeader(uint _circle) public view virtual returns (address) {
        return circleNumbers[_circle].circleLeader;
    }

    // @tlogs: Returns an array of circle numbes for which an address was circle leader

    function wasCircleLeader(address checkforLeader) public view virtual returns (uint[] memory circlesLed) {
        uint[] memory circlesled = new uint[](checkforCircle.length);
        for (uint i = 0; i < checkforCircle.length; i++) {
            if (circleNumbers[checkforCircle[i]].circleLeader == checkforLeader) {
            circlesled[i] = checkforCircle[i];
            }
        }
        return circlesled;
    }

    // @tlogs: Returns the address of the circleLeader for a given circleNumber

    function returnCircleAdmin(uint _circle) public view virtual returns (address) {
        return circleNumbers[_circle].circleAdmin;
    }

    // @tlogs: Returns an array of circle numbes for which an address was circle leader

    function wasCircleAdmin(address checkforAdmin) public view virtual returns (uint[] memory adminForCircles) {
        uint[] memory adminforcircles = new uint[](checkforCircle.length);
        for (uint i = 0; i < checkforCircle.length; i++) {
            if (circleNumbers[checkforCircle[i]].circleAdmin == checkforAdmin) {
            adminforcircles[i] = checkforCircle[i];
            }
        }
        return adminforcircles;
    }

    // @tlogs: Check if a proposal exists, used before allowing for new proposal creation via proposeGift

    function proposalExists(uint propnum) public view returns (bool) {
        for (uint i = 0; i < checkforProp.length; i++) {
            if (checkforProp[i] == propnum) {
            return true;
            }
        }
        return false;
    }

    // @tlogs: Check if a Giving Circle already exists at creation

    function circleExists(uint circlenum) public view returns (bool) {
        for (uint i = 0; i < checkforCircle.length; i++) {
            if (checkforCircle[i] == circlenum) {
            return true;
            }
        }
        return false;
    }

    // tlogs: quickly determine which circle a proposal is in for getgiftrecords calcs needing each circle's unique USDCperBean

    function returnCircleforProp (uint prop) public virtual returns (uint circle) {
        return proposalincircle[prop];
    }

    // tlogs: called in newProposal to ensure giving cirlce is open to proposals

    function proposalWindowOpen (uint _checkcircle) public virtual returns (bool) {
        require (
            circleNumbers[_checkcircle].step < 2, "Giving Circle is not open for proposal submission"
        );
        return true;
    }

    function getCircleStep(uint256 circleIndex) public view returns(uint256) {
        return circleNumbers[circleIndex].step;
    }

// ADMIN FUNCTIONS

    // @tlogs: only the current circle leader can set a new circle 
    //        else, the current circle leader becomes circle leader for next circle.

    function newCircleLeader(address newLeader) external returns (address) {
        require (
            circleleader == msg.sender, "only circle leader can elect new leader"
        );
        circleleader = newLeader;
        emit NewCircleLeader(newLeader);
        return circleleader;
    }

    // @tlogs: only the current circle leader can set a new circle leader for currently open circle,
    //        else, the current circle leader becomes circle leader for next circle.

    function newCircleAdmin(address newAdmin) external returns (address) {
        require (
            circleAdmin == msg.sender, "only circle leader can elect new leader"
        );
        circleAdmin = newAdmin;
        emit NewCircleAdmin(newAdmin);
        return circleAdmin;
    }

    function updateTaxThreshold(uint newThreshold) external returns (uint) {
        require (
            circleAdmin == msg.sender, "only circle leader can elect new leader"
        );
        taxThreshold = newThreshold;
        emit NewTaxThreshold(newThreshold);
        return taxThreshold;
    }

    // tlogs: circle admin kyc's giftees per off-chain methods then calls below
        // ** gifts can't be redeemed till below is called for an address

    function kycUser(address kycAddress) external returns (bool) {
          require (
            circleAdmin == msg.sender, "only circle leader can kyc users"
        );      
        isKYCed[kycAddress] = true;
        return true;
    }

    // tlogs: circleFunded = true is required to disburseBeans (step 3)

    function fundGiftForCircle(uint disburseforCircleNumber) public payable {
            
            require(
                circleNumbers[disburseforCircleNumber].circleFunded == false, "Circle has already been funded!"
            );

            require (
                circleAdmin == msg.sender, "only circle admin can fund circles"    // only the circle leader can disburse beans
            );

            require (
                giftToken.balanceOf(msg.sender) >= (giftTokensperCircle * weiMultiplier), "not enough USDC to fund circle" // checks if circle leader has at least giftTokensperCircle 
            );

            giftToken.approve(msg.sender, (giftTokensperCircle * weiMultiplier)); // insure approve increases circle leader allowance
            giftToken.transferFrom(msg.sender, address(this), giftTokensperCircle * weiMultiplier); // transfer USDC to the contract

            circleNumbers[disburseforCircleNumber].circleFunded = true;
            emit FundedCircle(disburseforCircleNumber, giftTokensperCircle * weiMultiplier);
    }

    // @tlogs: cleanup function for circle leader to delete unallocated bean balances after a circle

    function removeBeanBalances(address beanhorder) public returns (bool) {
        require(
           circleAdmin == msg.sender, "only circle admin can remove bean balances"
        );  
        uint deletedbalance = beanBalances[beanhorder];
        delete beanBalances[beanhorder];
        totalBeans -= deletedbalance; // reduce totalBeans supply
        emit BeansRemoved(beanhorder, deletedbalance);
        return true;
    }

     // @tlogs: cleanup function for circle admin to remove gift tokens if above total allocated for Giving Circles

    function removeGiftTokens(uint giftTokenstoRemove) public returns (uint) {
        require(
           circleAdmin == msg.sender, "only circle admin can remove gift tokens"
        );  
        uint256 removetokens = giftTokenstoRemove * weiMultiplier; // get ERC-20 decimals for transferFrom
        giftToken.approve(address(this), removetokens);
        giftToken.transferFrom(address(this), msg.sender, removetokens); // gift tokens transferred back to admin
        emit GiftsRemoved(giftTokenstoRemove);
        return giftTokenstoRemove;
    }   

// ADMIN RECORD KEEPING VIEW FUNCTION 

    // @tlogs: will return total USDC gifts withdrawn in decimal=0 in addition to an array of all props submitted and related gifts allocated

    function getgiftrecords (address recipient) public returns (uint totalgifted, uint[] memory propssubmitted, uint[] memory giftTokenAllocs) {
        uint[] memory propsposted = new uint[](checkforProp.length);
        uint[] memory giftTokensAllocated = new uint[](checkforProp.length); // decimal 0 
        uint recipientGiftsWithdrawn = totalGiftsWithdrawn[recipient];
    for (uint i = 0; i < checkforProp.length; i++) {
        if (proposalNumbers[checkforProp[i]].giftAddress == recipient) {        // checks for props where address is gift recipient
            propsposted[i] = checkforProp[i];
            giftTokensAllocated[i] = proposalNumbers[i].beansReceived * circleNumbers[returnCircleforProp(i)].giftTokensPerBean; // giftTokensAllocated decimals = 0 
            }
    }
        return (recipientGiftsWithdrawn, propsposted, giftTokensAllocated);   
    }

        // tlogs: will return *total* gift tokens withdrawn for each prop's giftee address
            // do not sum total on address since some addresses will be giftee for multiple proposals
            // can do count on address for submitted proposal count for each address
            // ** multiple addresses may belong to one kyced user

    function taxableGifts () public view returns (address[] memory taxableGiftees, uint[] memory giftsWithdrawn) {
        address[] memory gifteesForProps = new address[](checkforProp.length);
        uint[] memory recipientGiftsWithdrawn = new uint[](checkforProp.length);
    for (uint i = 0; i < checkforProp.length; i++) {
        if (totalGiftsWithdrawn[proposalNumbers[i].giftAddress] >= taxThreshold) {        // checks for props where address is gift recipient
            gifteesForProps[i] = proposalNumbers[i].giftAddress;
            recipientGiftsWithdrawn[i] = totalGiftsWithdrawn[proposalNumbers[i].giftAddress];
            }
    }
        return (gifteesForProps, recipientGiftsWithdrawn);   
    }

// CIRCLE LEADER FUNCTIONS

    // @tlogs: circle leader uses to create a new circle

    function newCircle(uint _circlenumber) public returns (bool) {
        require(
           circleleader == msg.sender, "only circle leader can start a new circle"
        );
        require(
            circleExists(_circlenumber) == false, "giving circle already exists" // runs a for loop on checkforCircle array, will return true if duplicate
        );

        checkforCircle.push(_circlenumber); // add the circle number to the checkforCircle array.
        GivingCircle storage g = circleNumbers[_circlenumber]; 
        g.step = 1; // set propWindowOpen to true in order to allow for proposals to be submitted to the new giving circle.
        g.circleLeader = circleleader; // record circle leader at the time of the circle
        g.circleAdmin = circleAdmin; // record cirlce admin at the time of the circle
        emit CircleCreated(_circlenumber);
        return (true); // need an else false statement?
    }

    // tlogs: called by Circle Leader to close a Giving Circle to additional propositions.
    
    function closePropWindow(uint closeCircleNumber) public returns (bool) {
        uint[] memory finalproposals = proposalsInCircle[closeCircleNumber];

        require(
           circleleader == msg.sender, "only circle leader can start a new circle"
        );
        require(
           circleNumbers[closeCircleNumber].step == 1 , "circle has already been closed to proposals"
        );    

        circleNumbers[closeCircleNumber].step = 2;

        emit ProposalWindowClosed(closeCircleNumber, finalproposals);
        return true;
    }

        // tlogs: since disburseBeans calls _calcGiftTokensPerBean, a require is used to make sure circleFunded = true

    function disburseBeans(uint disburseforCircleNumber, address[] memory attendees) public virtual returns (bool) {
            require (
                circleleader == msg.sender, "only circle leader can disburse beans"    // only the circle leader can disburse beans
            );

            require (
                circleNumbers[disburseforCircleNumber].step == 2, "circleLeader must closePropWindow to initate step 2" // beans can only be disbursed once per circle
            );

            require (
                circleNumbers[disburseforCircleNumber].circleFunded == true, "Circle Admin must fund circle to disburse beans!" // beans can only be disbursed once per circle
            );

            address[] memory disburseTo = attendees;
            for (uint i = 0; i < disburseTo.length; i++) // for loop to allocate attendee addresses +10 beans
            beanBalances[disburseTo[i]] += beansPerAttendee; // change to beanBalances should be mirrored by totalbeans change below
            totalBeans += (beansPerAttendee * disburseTo.length); // affects USDCperBean.
            _calcGiftTokensPerBean(disburseforCircleNumber); // make sure this is correct
            
            circleNumbers[disburseforCircleNumber].step = 3; //beans disbursed
            emit BeansDisbursed(disburseforCircleNumber,attendees, (beansPerAttendee * disburseTo.length));
            return true;
    }

    //tlogs: circle leader calls after presentations & bean disbursal

    function openCirclevoting(uint startcirclenumber) public virtual returns (bool) {
        require (
            circleLeader(startcirclenumber) == msg.sender, "caller is not CircleLeader"
        );
        require (
            circleNumbers[startcirclenumber].step == 3, "beans have not been disbursed for this circle"
        );
        
        circleNumbers[startcirclenumber].step = 4;

        emit VotingOpened(startcirclenumber);
        return true;
    }

    // used by circleLeader to end giving circle after all beans have been placed
    // automatically triggers _allocateGifts internal function
    
    function closeCirclevoting(uint endcirclenumber) public virtual returns (bool) {
        require (
            circleLeader(endcirclenumber) == msg.sender, "caller is not CircleLeader"
        );
        require (
            circleNumbers[endcirclenumber].step == 4, "giving circle voting is not open"
        );
        
        circleNumbers[endcirclenumber].step =  5;

        _allocateGifts(endcirclenumber);
        emit VotingClosed(endcirclenumber);
        return true;
    }

// PROPOSER FUNCTIONS

//propNumber = prop
//proposeInCircle = circle
//giftRecipient = payableAddress

    function newProposal(uint propNumber, uint proposeInCircle, address payable giftRecipient) public virtual returns (bool) {
        require(
            proposalExists(propNumber) == false, "selected gift proposal number already exists."
        );
        require(
            proposalWindowOpen(proposeInCircle) == true, "selected giving circle is not open for gift proposals" // requires a circle's propWindowOpen boolean to be true
        );

        checkforProp.push(propNumber); // add the gift proposal number to overall gift proposal check
        proposalincircle[propNumber] = proposeInCircle; // sets mapping of 1-to-1 proposalincircle for quick lookup of what circle a proposal is in
        proposalsInCircle[proposeInCircle].push(propNumber); // add the gift proposal to array within proposalsInCircle array within Giving Circle struct
        Proposal storage p = proposalNumbers[propNumber]; // used to push Proposal Struct elements to proposalNumbers mapping below
        p.beansReceived = 0;
        p.giftAddress = giftRecipient;
        emit ProposalCreated(propNumber, proposeInCircle, giftRecipient);
        return true;   
    }

    // @tlogs: redeem gift tokens after kyc'ing with circle admin

    function redeemGift(uint redeemQty) external virtual returns (uint) {
        require (
            giftPending[msg.sender] > 0, "no pending gift tokens for redemption"
        );
        require( 
            isKYCed[address(msg.sender)] == true, "must KYC before redeeming your gift" 
        );
        require (
            giftPending[msg.sender] > redeemQty, "not enough pending gift tokens for redeemQty"
        );
        
        uint256 redemptionqty = redeemQty * weiMultiplier; // will be 10**18
        address payable giftee = payable(msg.sender);

        giftPending[msg.sender] -= redeemQty; // decimal = 0 mapping 

        totalGiftTokensPending -= redeemQty; // decimal = 0 variable
        totalTokensgifted += redeemQty; // decimal = 0 variable
        totalGiftsWithdrawn[msg.sender] += redeemQty; // updates mapping to track total gifts withdrawn from contract
        giftToken.transferFrom(address(this), giftee, redemptionqty); // redemptionqty is used for 10 ** 18 ERC20 decimals
        emit GiftRedeemed(redeemQty, giftee);
        return redeemQty;
    }

// BEAN HOLDER FUNCTIONS

    function checkbeanBalance (address beanholder) external virtual returns (uint) {
        return beanBalances[beanholder];
    }

    //**
    // * @tlogs: beans can only be placed during step 4, voting open
    // */

    function placeBeans (uint circlenumb, uint propnumber, uint beanqty) external virtual returns (bool) {
        require (
            circleNumbers[circlenumb].step == 4, "giving circle is not open to voting"
        );
        require (
            beanBalances[msg.sender] >= beanqty, "not enough beans held to place beanqty"
        );
        beanBalances[msg.sender] -= beanqty;
        totalBeans -= beanqty;
        proposalNumbers[propnumber].beansReceived += beanqty;
        emit BeansPlaced(propnumber, beanqty, msg.sender);
        return true;
    }

// INTERNAL FUNCTIONS

     // @tlogs: availableGiftTokens multiplies totalGiftTokensPending by weiMultiplier to set availableGiftTokens as 10**18

    function _calcGiftTokensPerBean (uint256 circle_) internal virtual returns (uint) {
        uint256 availableGiftTokens = giftToken.balanceOf(address(this)) - (totalGiftTokensPending * weiMultiplier); // availableGiftTokens is 10**18
        uint256 _newGiftTokensPerbean = (availableGiftTokens) / totalBeans; // stays 10 ** 18 to minimize uint rounding error
        uint256 newGiftTokensPerbean = _newGiftTokensPerbean / weiMultiplier; // to bring newGiftTokensPerbean back to decimal = 0
        circleNumbers[circle_].giftTokensPerBean = newGiftTokensPerbean; // decimal 0 for giftTokensPerBean
        return newGiftTokensPerbean; // availableGiftTokens is 10**18, thus minimizing rounding with small totalBeans uint (not 10**18).
    }
    // @tlogs: called in closeCircleVoting

    function _allocateGifts (uint allocateCircle) internal virtual returns (bool) { 
            uint256 useGiftTokensPerBean = circleNumbers[allocateCircle].giftTokensPerBean; // decimals = 0
            address[] memory giftees = new address[](proposalsInCircle[allocateCircle].length);
            uint[] memory allocations = new uint[](proposalsInCircle[allocateCircle].length);

        for (uint i = 0; i < proposalsInCircle[allocateCircle].length; i++) {
            uint256 allocate = proposalNumbers[i].beansReceived * useGiftTokensPerBean; // beans received is decimal 0, GiftTokensPerBean is decimal 0, thus allocate is 0
            giftPending[proposalNumbers[i].giftAddress] += allocate; // giftPending is decimal = 0
            totalGiftTokensPending += allocate ; // decimals = 0 

            giftees[i] = proposalNumbers[i].giftAddress;
    
            allocations[i] = allocate; // decimals = 0
        }
            circleNumbers[allocateCircle].step = 6; // final state of circle
            
            emit GiftsAllocated(allocateCircle, giftees, allocations);

            return true;
    }

    }