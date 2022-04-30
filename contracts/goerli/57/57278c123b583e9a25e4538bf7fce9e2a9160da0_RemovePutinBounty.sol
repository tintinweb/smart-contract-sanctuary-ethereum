/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Remove Putin Bounty
 * @dev This contract is made to incentivize Russians to remove Putin from power by any mean necessary.
 * It is also made to incentivize Putin to stop his agression against Ukraine.
 * It is not affiliated with the state of Ukraine nor any other nation state.
 * This contract is made only as a legitimate defense mean (see a discussion on this right of legitimate defense: https://scholarship.law.cornell.edu/cgi/viewcontent.cgi?article=2562&context=facpub).
 * - The fear of harm is geniune. Putin already attacked Ukraine leading to thousands of deaths.
 * - The threat is imminent. The bounty shall be cancelled if Putin recalls its troop or if he is removed from power during a ceasefire.
 * - The response is proportional. Thousands people (in both sides) already died.
 *   One could argue that heads of state are special and "worth" more than regular citizens, we do not share this point of view, but for those who do, Putin already tried to eliminate the president of Ukraine multiple times https://www.msn.com/en-us/news/world/volodymyr-zelensky-survives-three-assassination-attempts-in-one-week/ar-AAUBwac 
 *   The bounty only targets the individual responsible.
 *   This individual is a military target: The Supreme Commander-in-Chief of the Russian Armed Forces (https://en.wikipedia.org/wiki/Supreme_Commander-in-Chief_of_the_Russian_Armed_Forces).
 *   The bounty is neutral about whether violence should be used or not (any mean to remove him from power would fullfill the bounty).
 *   The bounty provides a way out to Putin as it would be cancelled if he were to recall his troops.
 */
contract RemovePutinBounty {


    /* Owner */
    // The DAO or multisig which will report the events.
    address public owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; 
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        owner = newOwner;
    }

    /* ERC20 */
    // Contributors get a token representing their contribution.
    // In case the bounty is cancelled (Putin recalls his troops or is removed from power during a ceasefire), those tokens can be redeemed for the ETH.
    // In case the bounty is paid out. The tokens will end up as collectibles, or maybe even used in the Guardians of the Galaxy organisation.
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Putin Bounty";
    string public symbol = "PBTY";
    uint8 public decimals = 14;

    /**
     * @dev Transfer tokens.
     * @param recipient The recipient of the tokens.
     * @param amount The amount to transfer.
     */
    function transfer(address recipient, uint amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Approve another account to spend tokens.
     * @param spender The account to be allowed the spending of tokens.
     * @param amount The amount of tokens which can be spent.
     */
    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfer tokens on behalf of another account.
     * @param sender The account the tokens should be sent from.
     * @param recipient The account to receive the tokens.
     * @param amount The amount of tokens to send.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /* General constants */

    uint constant public ACTION_ERROR_MARGIN = 36 hours;
    uint constant public PREDICTION_ACTIVATION = 12 hours;
    uint constant public REDEEM_TIME = 100 days;
    uint constant public REVEAL_TIME = 100 days;

    /* General state variables */
    enum State{ initial, cancelled, executed }
    State public state; // State of the contract.
    uint public executionTime; // Time the contract was executed.
    uint public cancellationTime; // Time the bounty was cancelled.
    uint public totalPredictionShares; // The amount of ETH used for correct predictions.
    mapping(address => uint) public predictionShares; // The amount of correct prediction shares an address has.
    uint public totalBounty; // The total amount of ETH as a bounty. Set when the bounty is executed.

    struct Prediction { 
        address payable predictor; // The predictor which would be paid.
        uint value; // The amount paid by the predictor.
        uint time; // The time the prediction was made. Should be at least 12h before the action.
        bytes32 commitment; // keccak256(timestamp,salt), where timestamp is the predicted time of the action and salt a random value.
    }
    Prediction[] public predictions;

    /* General functions */
    /**
     * @dev Contribute to the bounty and receive some tokens which may be redeemed to ETH if the bounty is cancelled and use in the Guardian of the Galaxy organisation.
     * Contributors may want to contribute:
     * - Making a charitable donation to stop the war.
     * - Making a charitable donation for democracy.
     * - In order to receive tokens.
     * - In order to remove Putin which is bad for their buisness (sanctions and cie).
     * - For any other reason they see fit.
     */
    receive() external payable {
        require(state == State.initial); // Can only contribute if the bounty is not cancelled nor executed.
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }


    /**
     * @dev Predict the time that Putin will be removed from power. Also counts as a contribution.
     * Only use it from an anonymous address (you may want to use tornado.cash).
     * The prediction needs to be accurate +/- 36h. This is to handle uncertainty with the time of the action and potential inacurracy in the report.
     * The prediction must be done at least 12 hours before the action. This is to prevent people "predicting" after the action is done.
     * If you are unsure about the exact time the action would be taken, we encourage you to make multiple predictions covering all the potential times.
     * A payment should be made (this is to prevent people from "predicting" for everyday for free). In case multiple predictions are correct, the payout would be split in proportion of their payments.
     * This can be used by:
     * - Russians planning to remove Putin from power. Because they will be the ones doing the action, they should know the date in advance and get the payout.
     * - Anyone who believe they know when Putin would be removed from power.
     * - Anyone wanting to contribute. Contributing this way increases privacy as it makes it hard for external observers to distinguishes between contributors and predictors. It also allows predictors to claim they are only making predictions and not participating in a bounty.
     * @param commitment A commitment of the timestamp where Putin would be removed from power: keccak256(timestamp,salt) where timestamp is the time of removal and the salt a random value.
     */
    function predictRemoval(bytes32 commitment) external payable {
        require(state == State.initial); // Can only predict if the bounty is not cancelled nor executed.
        predictions.push(Prediction({
            predictor: payable(msg.sender),
            value: msg.value,
            time: block.timestamp,
            commitment: commitment
        }));
        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    /**
     * @dev Cancel the bounty. This can happen if:
     * - Putin recalls his troops from Ukraine.
     * - Putin is removed from power during a ceasefire.
     * - Putin is removed from power directly by foreigners (in order to prevent escalation, only Russians taking the action can lead to a bounty).
     * Note that Putin being removed from power by people of unknown nationality would not result in the cancellation of the bounty.
     *
     * In this case, the tokens become redeemable for ETH for at least 100 days.
     */
    function cancel() external isOwner {
        require(state == State.initial);
        state = State.cancelled;
        cancellationTime = block.timestamp;
    }

    /**
     * @dev Burn all your tokens to redeem the equivalent amount of ETH.
     * Can only be done if the bounty is cancelled.
     */
    function redeem() external {
        require(state == State.cancelled);
        uint toGive = balanceOf[msg.sender];
        emit Transfer(msg.sender, address(0), balanceOf[msg.sender]);
        totalSupply -= toGive;
        balanceOf[msg.sender] = 0;
        payable(msg.sender).transfer(toGive);
    }

    /**
     * @dev Report that the bounty has been executed: Putin removed from power by Russian (or unknown nationality) individuals outside of a ceasefire.
     * @param time The time Putin was removed from power.
     */
    function report(uint time) external isOwner {
        require(state == State.initial);
        state = State.executed;
        executionTime = time; // The time the action was taken.
        totalBounty = address(this).balance; // The amount of ETH to be paid out.
    }

    /**
     * @dev Reveal a prediction. Shall be done within 100 days of the execution time.
     * We encourage predictors to put themselves to safety before revealing.
     * We hope that 100 days is enough to do so.
     * @param id The id of the prediction.
     * @param predictedTime The date of the prediction.
     * @param salt The random value which was used.
     */
    function reveal(uint id, uint predictedTime, uint salt) external {
        Prediction storage prediction = predictions[id];
        require(state == State.executed);
        require(block.timestamp < executionTime + REVEAL_TIME); // Cannot reveal more than 100 days after the execution time.
        require(keccak256(abi.encodePacked(predictedTime,salt)) == prediction.commitment); // Check that it matches the commitment.
        require(prediction.time < executionTime - PREDICTION_ACTIVATION); // The prediction was made at least 12 hours before the action.
        require((predictedTime > executionTime - ACTION_ERROR_MARGIN) && (predictedTime < executionTime + ACTION_ERROR_MARGIN)); // The predicted time should be less than 36 hours away from the execution time.

        totalPredictionShares += prediction.value; // Increase the total amount of correct prediction shares. 
        predictionShares[prediction.predictor] += prediction.value; // Increase the amount of correct prediction shares for the predictor. 
        prediction.value = 0; // Set the value to 0 to prevent further reveals.
    }

    /**
     * @dev Cancel the bounty despite its execution if no one revealed a correct prediction within the 100 days.
     */
    function cancelNoWinner() external {
        require(state == State.executed);
        require(block.timestamp >= executionTime + REVEAL_TIME); // At least 100 days after execution.
        require(totalPredictionShares == 0); // No prediction was correct.
        state = State.cancelled;
        cancellationTime = block.timestamp;
    }


    /**
     * @dev Withdraw prediction payout.
     * Need to wait at least 100 days after the exection time to let the time for everyone to reveal.
     */
    function withdraw() external {
        require(state == State.executed);
        require(block.timestamp >= executionTime + REVEAL_TIME); // At least 100 days after execution.
        uint toGive = (predictionShares[msg.sender] * totalBounty) / totalPredictionShares; // Share of ETH.
        predictionShares[msg.sender] = 0; 
        payable(msg.sender).transfer(toGive);
    }

    /**
     * @dev Withdraw the remaining funds.
     * Need to wait at least 100 days after the cancellation time to let the time for everyone who wants to withdraw.
     * This can be used to automatically reasign the contributions of users who do not wish to withdraw to other actions.
     */
    function withdrawRemaining() external isOwner {
        require(state == State.cancelled); // Only if bounty is cancelled.
        require(block.timestamp > cancellationTime + REDEEM_TIME); // Only after 100 days.
        payable(owner).transfer(address(this).balance);
    }

    /**
     * @dev Helper to get the commitment. Should only be called locally.
     * @param time The time the action should take place.
     * @param salt A random salt. Care should be made to have 256 bits of randomness to prevent rainbow table attacks.
     */
    function getCommitment(uint time, uint salt) pure external returns(bytes32) {
        return keccak256(abi.encodePacked(time,salt));
    }

}