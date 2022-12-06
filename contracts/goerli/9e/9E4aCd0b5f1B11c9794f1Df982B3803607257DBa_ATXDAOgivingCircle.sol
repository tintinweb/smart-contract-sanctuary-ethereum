/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// ATXDAO Giving Circle by tlogs.eth via Crypto Learn Lab
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface giftContract {

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

contract ATXDAOgivingCircle {

// STATE VARIABLES & STRUCTS

    // interface variables

giftContract public USDC; // implement USDC ERC20 interface with USDC contract address in constructor

    // utility variables

uint public weiMultiplier; // utilized in various calcs to convert to ERC20 decimals

address public circleleader; //needed to start first circle, set in constructor, used in all modifiers

    // gift variables

uint public totalUSDCgifted; // decimals = 0

uint public totalUSDCpending; // decimals = 0

    // bean variables

uint public totalBeans; // decimals = 0

    // circle variables & struct

uint[] public checkforCircle; // array of circle numbers utilized to check if giving cricle exists. array of all circle numbers

uint public USDCperCircle; // initially 1000 USDC per circle. decmials = 0 (multiplied by weiMultiplier in all calcs)

struct GivingCircle {
    bool propWindowOpen; // set to true in newCircle function, closePropWindow sets propWindowOpen to false
    uint USDCperBean; // 
    bool votingOpen; // set to false in newCircle function, set to true at end of beansDisbursed function, set to false with closeCirclevoting.
    bool beansDisbursed; // set to false in newCircle function, set to true when disburseBeans function is run.
    address circleLeader; // set to current circleleader per utility variable when newCircle function is run.
}

    // proposal variables & struct

uint[] public checkforProp; // array or prop numbers for various 'for' loops

struct Proposal {
    uint beansReceived;
    address payable giftAddress;
}

// MAPPINGS

    // gift mappings

mapping (address => uint) public USDCgiftPending; // beanBalances have decimals of 10**18, always mirror changes in totalUSDCpending when changing mapping.

mapping (address => uint) public USDCgiftsReceived; // tracks total gifts withdrawn by proposers, decimals = 0

    // bean mappings

mapping (address => uint) beanBalances; // beanBalances have decimals of 0. tracks outstanding votes from all circles attended.

mapping (address => uint[]) circlesAttended; // to track the circle numbers each DAO member has attended.

    // circle mappings

mapping (uint => GivingCircle) public circleNumbers; // give each circle a number. uint replicated in checkforCircle array.

mapping (uint => uint[]) proposalsInCircle; // circle > proposals one-to-many. 

    // proposal mappings

mapping (uint => Proposal) public proposalNumbers; // give each proposal a number. uint replicated in checkforProp array.

mapping (uint => uint) proposalincircle; // proposal number > circle number, one-to-one, check which proposal a circle is in for USDCperBean lookup

// EVENTS 

// *** all 'emit' elements for events to be added throughout contract

    // gift events

event GiftsAllocated(uint indexed circleNumb, address[] indexed giftrecipients, uint[] indexed giftamounts);  // emitted in _allocateGifts

event GiftRedeemed(uint indexed giftwithdrawn, address indexed withdrawee);  // emitted in redeemGift

    // bean events

event BeansDisbursed(uint indexed circleNumb, address[] indexed circleattendees, uint indexed beansdisbursedforcircle); // emitted in disburseBeans

event BeansPlaced(uint indexed propNumb, uint indexed beansplaced, address indexed beanplacer); // emitted in placeBeans

event BeansRemoved(address indexed beanhorder, uint indexed beansremoved); // emitted in removeBeans

    // circle events

event CircleCreated(uint indexed circleNumb); // emitted in newCircle

event ProposalWindowClosed(uint indexed circleNumb, uint[] indexed finalproplist); // emitted in closePropWindow

event VotingClosed(uint indexed circleNumb); // emitted in closeCircleVoting

    // proposal events

event ProposalCreated(uint indexed propNumb, uint indexed circleNumb, address indexed giftrecipient); // emitted by proposeGift

// CONSTRUCTOR 

    constructor(address _usdc, address _circleleader) {
    USDC = giftContract(_usdc); // set usdc contract address
    circleleader = _circleleader; // set the first circle leader
    weiMultiplier = 10**18;  // set weiMultiplier to convert between ERC-20 decimal = 10**18 and decimal 0
    USDCperCircle = 1000; // set initial USDCperCircle. to be multiplied by weiMultiplier in all ERC20 calls
    }

// UTILITY FUNCTIONS

    // @tlogs: Returns the address of the circleLeader for a given circleNumber.
    // IMPLEMENT a version of the below which searchs array of circle numbers for all circles an address was circleLeader

    function circleLeader(uint _circle) public view virtual returns (address) {
        return circleNumbers[_circle].circleLeader;
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

    // quickly determine which circle a proposal is in for getgiftrecords calcs needing each circle's unique USDCperBean

    function returnCircleforProp (uint prop) public virtual returns (uint circle) {
        return proposalincircle[prop];
    }

// add a for loop so proposalWindowOpen can receive all proposalNumbers from a circle in uint[] array then check if any exist in proposalNumbers mapping

    function proposalWindowOpen (uint _checkcircle) public virtual returns (bool) {
        require (
            circleNumbers[_checkcircle].propWindowOpen == true, "Giving Circle is not open for proposal submission"
        );
        return true;
    }

// ADMIN FUNCTIONS

    // @tlogs: will return total USDC gifts withdrawn in decimal=0 in addition to an array of all props submitted

    function getgiftrecords (address recipient) public returns (uint totalgifted, uint[] memory propssubmitted, uint[] memory USDCallocs) {
        uint[] memory propsposted = new uint[](checkforProp.length);
        uint[] memory votes = new uint[](checkforProp.length);
        uint recipientGifts = USDCgiftPending[recipient];
    for (uint i = 0; i < checkforProp.length; i++) {
        if (proposalNumbers[checkforProp[i]].giftAddress == recipient) {        // checks for props where address is gift recipient
            propsposted[i] = checkforProp[i];
            votes[i] = proposalNumbers[i].beansReceived * circleNumbers[returnCircleforProp(i)].USDCperBean;
            // insert call for circle's USDC per bean and move the
            }
    }
        return (recipientGifts, propsposted, votes);   
    }

// CIRCLE LEADER FUNCTIONS

    // @tlogs: only the current circle leader can set a new circle leader for currently open circle,
    //        else, the current circle leader becomes circle leader for next circle.
    //            add an event emission for change in circle leader

    function newCircleLeader(address newLeader) external returns (address) {
        require (
            circleleader == msg.sender, "only circle leader can elect new leader"
        );
        circleleader = newLeader;
        return circleleader;
    }

    // @tlogs: create event emission for creating a new circle
    // true:false established for propWindowOoen:votingOpen upon Giving Circle creation (redemption conditions not met)

    function newCircle(uint _circlenumber) public payable returns (bool) {
        require(
           circleleader == msg.sender, "only circle leader can start a new circle"
        );
        require(
            circleExists(_circlenumber) == false, "giving circle already exists" // runs a for loop on checkforCircle array, will return true if duplicate
        );

        checkforCircle.push(_circlenumber); // add the circle number to the checkforCircle array.
        GivingCircle storage g = circleNumbers[_circlenumber]; 
        g.USDCperBean = _calcUSDCperBean(_circlenumber); // run the _setUSDCperBean internal command 
        g.propWindowOpen = true; // set propWindowOpen to true in order to allow for proposals to be submitted to the new giving circle.
        g.votingOpen = false; // prevent voting while proposal submission window is open.
        g.beansDisbursed = false;
        g.circleLeader = circleleader; // record circle leader at the time of the circle. 
        emit CircleCreated(_circlenumber);
        return (true); // need an else false statement?

    }

    // called by Circle Leader to close a Giving Circle to additional propositions. Triggers votingOpen in preparation for bean distribution. 
    // It doesn't matter if people start voting with accrued beans before distribution when new beansPerUSDC is set, as long as USDCperBean is set before gifts are redeemed are enabled.
    // false:true established for propWindowOoen:votingOpen upon Giving Circle creation (redemption conditions not met)

    function closePropWindow(uint closeCircleNumber) public returns (bool) {
        uint[] memory finalproposals = proposalsInCircle[closeCircleNumber];

        require(
           circleleader == msg.sender, "only circle leader can start a new circle"
        );
        require(
           circleNumbers[closeCircleNumber].propWindowOpen == true , "circle has already been closed to proposals"
        );    
        circleNumbers[closeCircleNumber].propWindowOpen = false;
        emit ProposalWindowClosed(closeCircleNumber, finalproposals);
        return true;
    }

    // @tlogs: cleanup function for circle leader to delete unallocated bean balances after a circle

    function removeBeanBalances(address beanhorder) public returns (bool) {
        require(
           circleleader == msg.sender, "only circle leader can remove bean balances"
        );  
        uint deletedbalance = beanBalances[beanhorder];
        delete beanBalances[beanhorder];
        emit BeansRemoved(beanhorder, deletedbalance);
        return true;
    }

    // @tlogs:      needs work, considering making an intern
    //        need a modifier to restrict disburseBeans to onlyOwner & open circles
    //       consider making this an internal function called by closePropWindow
    //     disburseBeans is the only function that should affect USDCperBea 

    // does disburse beans need to open voting for a circle?

    function disburseBeans(uint disburseforCircleNumber, address[] memory attendees) public payable virtual returns (bool) {
            require (
                circleleader == msg.sender, "only circle cleader can disburse beans"    // only the circle leader can disburse beans
            );
            require (
                circleNumbers[disburseforCircleNumber].beansDisbursed == false, "beans already disbursed!" // beans can only be disbursed once per circle
            );
            require (
                circleNumbers[disburseforCircleNumber].propWindowOpen == false, "circleLeader must close proposal window before disbursing beans for circle"
            );
            require (
                circleNumbers[disburseforCircleNumber].votingOpen == false, "circle leader must close proposal window"
            );
            require (
                USDC.balanceOf(msg.sender) >= (USDCperCircle * weiMultiplier), "not enough USDC to start circle" // checks if circle leader has at least USDCperCircle 
            );

            USDC.approve(msg.sender, (USDCperCircle * weiMultiplier)); // insure approve increases circle leader allowance

            // input a check to await confirmation of approve function before calling transferFrom.

            USDC.transferFrom(msg.sender, address(this), USDCperCircle * weiMultiplier); // transfer USDC to the contract
       
            // input a check that awaits transfer event before allowing for circle to be created.

            address[] memory disburseTo = attendees;
            for (uint i = 0; i < disburseTo.length; i++) // for loop to allocate attendee addresses +10 beans
            beanBalances[disburseTo[i]] += 10; // change to beanBalances should be mirrored by totalbeans change below
            totalBeans += (10 * disburseTo.length); // affects USDCperBean.
            circleNumbers[disburseforCircleNumber].beansDisbursed = true; // set beansDisbursed to true for disburseforCircleNumber
            _calcUSDCperBean(disburseforCircleNumber); // make sure this is correct
            circleNumbers[disburseforCircleNumber].votingOpen = true; // last step is to open voting
            emit BeansDisbursed(disburseforCircleNumber,attendees, (10 * disburseTo.length));
            return true;
    }

    // used by circleLeader to end giving circle after all beans have been placed
    // triggers _allocateGifts internal function
    // false:false established for propWindowOoen:votingOpen upon Giving Circle creation (redemption condition met)

    function closeCirclevoting(uint endcirclenumber) public virtual returns (bool) {
        require (
            circleLeader(endcirclenumber) == msg.sender, "caller is not CircleLeader"
        );
        require (
            circleNumbers[endcirclenumber].votingOpen == true, "giving circle voting is not open"
        );
        circleNumbers[endcirclenumber].votingOpen = false;
        _allocateGifts(endcirclenumber);
        emit VotingClosed(endcirclenumber);
        return true;
    }

// PROPOSER FUNCTIONS

    function proposeGift(uint propNumber, uint proposeInCircle, address payable giftRecipient) public virtual returns (bool) {
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

    //**
    // * @tlogs: consider adding an event for a gift redemption.
            /* since USDCgiftPending mapping is 10**18, redemptionqty is 10**18
            /* only redeem whole number USDC
            /* consider adding a return element
     */
    // double false required on proposalWindowOpen & votingOpen.

    function redeemGift(uint proposedincirclenumber, uint proposal) external virtual {
        require (
            proposalNumbers[proposal].giftAddress == msg.sender, "this is not your gift!"
        );
        require( 
            proposalWindowOpen(proposedincirclenumber) == false, "selected giving circle is still accepting proposals" // proposalsInCircle returns uint[] of return circle
        );
        require(
            circleNumbers[proposedincirclenumber].votingOpen == false, "selected giving circle is still accepting votes"
        );
        
        uint256 redemptionqty = USDCgiftPending[msg.sender]; // will be 10**18
        USDCgiftPending[msg.sender] = 0;
        address payable giftee = proposalNumbers[proposal].giftAddress;
        totalUSDCpending -= redemptionqty / weiMultiplier; // reduce pending gifts by redeemed amount
        totalUSDCgifted += redemptionqty / weiMultiplier; // divide by weiMultiplier to give whole number totalUSDCgifted metric
        USDCgiftsReceived[msg.sender] += redemptionqty / weiMultiplier; // updates mapping to track total gifts withdrawn from contract
        USDC.transferFrom(address(this), giftee, redemptionqty); // USDCgiftPending mapping is 10**18, thus so is redemptionqty
        emit GiftRedeemed(redemptionqty, giftee);
    }

// BEAN HOLDER FUNCTIONS

    function checkbeanBalance (address beanholder) external virtual returns (uint) {
        return beanBalances[beanholder];
    }

    //**
    // * @tlogs: consider adding an event for beans placed.
    // */

    function placeBeans (uint circlenumb, uint propnumber, uint beanqty) external virtual returns (bool) {
        require (
            circleNumbers[circlenumb].votingOpen == true, "giving circle is closed to voting"
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

     // @tlogs: availableUSDC multiplies denominator by weiMultiplier to mitigate rounding errors due to uint

    function _calcUSDCperBean (uint256 circle_) internal virtual returns (uint) {
        uint256 availableUSDC = USDC.balanceOf(address(this)) - (totalUSDCpending * weiMultiplier); // availableUSDC is 10**18
        uint256 newusdcperbean = (availableUSDC) / totalBeans; // numberator is large due to weiMultipler, total beans is decimal = 0.
        circleNumbers[circle_].USDCperBean = newusdcperbean;
        return newusdcperbean; // availableUSDC is 10**18, thus minimizing rounding with small totalBeans uint (not 10**18).
    }

    // @tlogs: 
    //         USDCperBean is 10**18 
    //         thus allocate will be 10**18 
    //         thus USDCgiftPending mapping will be 10**18

    function _allocateGifts (uint allocateCircle) internal virtual returns (bool) { 
            uint256 useUSDCperBean = circleNumbers[allocateCircle].USDCperBean;
            address[] memory giftees = new address[](proposalsInCircle[allocateCircle].length);
            uint[] memory allocations = new uint[](proposalsInCircle[allocateCircle].length);

        for (uint i = 0; i < proposalsInCircle[allocateCircle].length; i++) {
            uint256 allocate = proposalNumbers[i].beansReceived * useUSDCperBean; // beans received is decimal 0, USDCperBean is decimal 10**18, thus allocate is 10**18

            USDCgiftPending[proposalNumbers[i].giftAddress] += allocate; // utilizes 10**18
            totalUSDCpending += allocate / weiMultiplier; // ensure proper decimal usage here, desired is decimals = 0 

            giftees[i] = proposalNumbers[i].giftAddress;
    
            allocations[i] = allocate;
        }

            emit GiftsAllocated(allocateCircle, giftees, allocations);

            return true;
    }

    }